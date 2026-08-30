-- P0.2 - create_check_in: der zentrale Call.
-- Legt bei Bedarf Bier und Ort an, schreibt den Check-in, ermittelt
-- Entdeckungen, vergibt XP mit Tages-Cap, wertet Quests aus, prueft Badges -
-- alles in EINER Transaktion - und gibt das komplette Reward-Paket zurueck.
-- Der Client rechnet nie XP (docs/06-data-model.md §4).

-- Zaehler fuer Badge-Kriterien und die "Naechstes Ziel"-Anzeige.
create or replace function public.user_metric(p_user uuid, p_metric text)
returns int
language sql stable security definer set search_path = public, extensions as $$
  select case p_metric
    when 'check_ins' then (select count(*) from public.check_ins where user_id = p_user)
    when 'friends'   then (select count(*) from public.friendships
                            where user_low = p_user or user_high = p_user)
    when 'quests'    then (select count(*) from public.quest_participants
                            where user_id = p_user and completed_at is not null)
    else (select count(*) from public.user_discoveries
           where user_id = p_user
             and kind::text = case p_metric
                   when 'beers' then 'beer' when 'venues' then 'venue'
                   when 'cities' then 'city' when 'countries' then 'country'
                   else p_metric end)
  end::int
$$;

create or replace function public.check_badges(p_user uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  r record;
  v_new jsonb := '[]'::jsonb;
begin
  for r in
    select b.code, b.name, b.icon, b.criteria
    from public.badges b
    where not exists (select 1 from public.user_badges ub
                       where ub.user_id = p_user and ub.code = b.code)
  loop
    if public.user_metric(p_user, r.criteria->>'metric')
       >= (r.criteria->>'gte')::int then
      insert into public.user_badges (user_id, code) values (p_user, r.code)
        on conflict do nothing;
      if found then
        v_new := v_new || jsonb_build_object('code', r.code, 'name', r.name,
                                             'icon', r.icon);
      end if;
    end if;
  end loop;
  return v_new;
end $$;

-- Das sichtbare naechste Ziel. Ohne diese Anzeige arbeitet der Nutzer auf
-- nichts hin (docs/02-product-gate.md §1 E).
create or replace function public.next_goal(p_user uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  r record;
  v_best jsonb;
  v_best_frac numeric := -1;
  v_have int; v_need int; v_frac numeric;
  v_xp int; v_level int;
begin
  for r in
    select b.code, b.name, b.icon, b.criteria
    from public.badges b
    where not exists (select 1 from public.user_badges ub
                       where ub.user_id = p_user and ub.code = b.code)
  loop
    v_need := (r.criteria->>'gte')::int;
    v_have := public.user_metric(p_user, r.criteria->>'metric');
    v_frac := case when v_need > 0 then v_have::numeric / v_need else 0 end;
    if v_frac > v_best_frac then
      v_best_frac := v_frac;
      v_best := jsonb_build_object('kind','badge','label', r.name,
                                   'icon', r.icon, 'have', v_have, 'need', v_need);
    end if;
  end loop;

  if v_best is not null then return v_best; end if;

  -- Alle Badges verdient: dann ist der naechste Level-Up das Ziel.
  select xp, level into v_xp, v_level from public.profiles where id = p_user;
  return jsonb_build_object('kind','level',
    'label', 'Level ' || (v_level + 1),
    'have', v_xp - public.total_xp_to_reach(v_level),
    'need', 500 * v_level);
end $$;

create or replace function public.create_check_in(
  p_client_uuid uuid,
  p_beer        jsonb,   -- {"id":uuid} oder {"name":text,"brewery":text|null}
  p_venue       jsonb,   -- {"id":uuid} oder {"name":text,"category":text,"lat":n,"lon":n}
  p_happened_at timestamptz default now(),
  p_timezone    text default 'UTC'
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v_existing public.check_ins;
  v_beer uuid; v_venue uuid; v_city uuid; v_country char(2);
  v_local_date date;
  v_checkin uuid;
  v_discoveries jsonb := '[]'::jsonb;
  v_raw_xp int := 0;
  v_xp int := 0;
  v_capped boolean := false;
  v_cap int; v_today int;
  v_level_before int; v_level_after int;
  v_clan_xp int := 0;
  v_quests jsonb := '[]'::jsonb;
  v_badges jsonb := '[]'::jsonb;
  v_new_beer boolean := false; v_new_venue boolean := false;
  v_count_today int;
  q record;
  v_inc int;
  v_total int;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  if p_client_uuid is null then
    raise exception 'CLIENT_UUID_REQUIRED' using errcode = 'check_violation';
  end if;

  -- Idempotenz: derselbe client_uuid darf nie zweimal XP erzeugen.
  select * into v_existing from public.check_ins
   where user_id = v_user and client_uuid = p_client_uuid;
  if found then
    return public.checkin_reward(v_existing.id) || jsonb_build_object('duplicate', true);
  end if;

  v_local_date := (p_happened_at at time zone coalesce(p_timezone,'UTC'))::date;

  -- Rate-Limit. Kein Anti-Cheat-Anspruch, nur ein Deckel gegen Unfaelle.
  select count(*) into v_count_today from public.check_ins
   where user_id = v_user and local_date = v_local_date;
  if v_count_today >= 30 then
    raise exception 'DAILY_CHECKIN_LIMIT' using errcode = 'check_violation';
  end if;

  -- --- Bier
  if p_beer ? 'id' then
    select id into v_beer from public.beers
     where id = (p_beer->>'id')::uuid and status = 'active';
    if v_beer is null then
      raise exception 'BEER_NOT_FOUND' using errcode = 'no_data_found';
    end if;
  else
    v_beer := public.find_or_create_beer(p_beer->>'name', p_beer->>'brewery', v_user);
  end if;

  -- --- Ort
  if p_venue ? 'id' then
    select id into v_venue from public.venues
     where id = (p_venue->>'id')::uuid and status = 'active';
    if v_venue is null then
      raise exception 'VENUE_NOT_FOUND' using errcode = 'no_data_found';
    end if;
  else
    v_venue := public.find_or_create_venue(
      p_venue->>'name',
      coalesce((p_venue->>'category')::public.venue_category, 'bar'),
      (p_venue->>'lat')::double precision,
      (p_venue->>'lon')::double precision,
      v_user);
  end if;

  select city_id, country_code into v_city, v_country
    from public.venues where id = v_venue;

  select level into v_level_before from public.profiles where id = v_user;

  insert into public.check_ins
    (user_id, client_uuid, beer_id, venue_id, city_id, country_code,
     happened_at, local_date)
  values
    (v_user, p_client_uuid, v_beer, v_venue, v_city, v_country,
     p_happened_at, v_local_date)
  returning id into v_checkin;

  -- --- Entdeckungen. Der Primaerschluessel verhindert Doppelvergabe
  --     strukturell, nicht durch Anwendungslogik.
  insert into public.user_discoveries (user_id, kind, entity_id, first_check_in)
  values (v_user, 'beer', v_beer::text, v_checkin) on conflict do nothing;
  if found then
    v_new_beer := true;
    v_raw_xp := v_raw_xp + public.cfg_int('xp.new_beer', 50);
    v_discoveries := v_discoveries || jsonb_build_object('kind','beer',
      'name', (select name from public.beers where id = v_beer),
      'xp', public.cfg_int('xp.new_beer', 50));
  end if;

  insert into public.user_discoveries (user_id, kind, entity_id, first_check_in)
  values (v_user, 'venue', v_venue::text, v_checkin) on conflict do nothing;
  if found then
    v_new_venue := true;
    v_raw_xp := v_raw_xp + public.cfg_int('xp.new_venue', 50);
    v_discoveries := v_discoveries || jsonb_build_object('kind','venue',
      'name', (select name from public.venues where id = v_venue),
      'xp', public.cfg_int('xp.new_venue', 50));
  end if;

  if v_city is not null then
    insert into public.user_discoveries (user_id, kind, entity_id, first_check_in)
    values (v_user, 'city', v_city::text, v_checkin) on conflict do nothing;
    if found then
      v_raw_xp := v_raw_xp + public.cfg_int('xp.new_city', 150);
      v_discoveries := v_discoveries || jsonb_build_object('kind','city',
        'name', (select name from public.cities where id = v_city),
        'xp', public.cfg_int('xp.new_city', 150));
    end if;
  end if;

  insert into public.user_discoveries (user_id, kind, entity_id, first_check_in)
  values (v_user, 'country', v_country, v_checkin) on conflict do nothing;
  if found then
    v_raw_xp := v_raw_xp + public.cfg_int('xp.new_country', 300);
    v_discoveries := v_discoveries || jsonb_build_object('kind','country',
      'name', (select name from public.countries where code = v_country),
      'xp', public.cfg_int('xp.new_country', 300));
  end if;

  -- Nichts Neues: kleine Gutschrift, aber nur begrenzt oft pro Tag.
  if v_raw_xp = 0
     and v_count_today < public.cfg_int('xp.max_scoring_repeats', 6) then
    v_raw_xp := public.cfg_int('xp.repeat_checkin', 10);
  end if;

  -- --- Tages-Cap. Setzt Product Vision §2 technisch um: Menge zahlt nicht.
  v_cap := public.cfg_int('xp.daily_cap', 500);
  v_today := public.capped_xp_today(v_user, v_local_date);
  v_xp := greatest(0, least(v_raw_xp, v_cap - v_today));
  v_capped := v_xp < v_raw_xp;

  if v_xp > 0 then
    perform public.award_xp(v_user, v_xp, 'check_in', 'check_in',
                            v_checkin::text, 'checkin:' || v_checkin::text);
    select clan_amount into v_clan_xp from public.xp_events
     where idem_key = 'checkin:' || v_checkin::text;
  end if;

  -- --- Quests. Fortschritt entsteht ausschliesslich hier.
  for q in
    select qu.id, qu.goal, qu.xp_reward, qu.title, qp.contributed
    from public.quests qu
    join public.quest_participants qp
      on qp.quest_id = qu.id and qp.user_id = v_user
    where qu.status = 'active' and qu.ends_at > now() and qp.completed_at is null
  loop
    v_inc := case q.goal->>'type'
      when 'discover_beer'  then (case when v_new_beer then 1 else 0 end)
      when 'discover_venue' then (case when v_new_venue then 1 else 0 end)
      when 'check_in'       then 1
      else 0 end;

    if v_inc > 0 then
      update public.quest_participants
         set contributed = contributed + v_inc
       where quest_id = q.id and user_id = v_user
       returning contributed into v_total;

      if v_total >= (q.goal->>'count')::int then
        update public.quest_participants
           set completed_at = now(), xp_awarded = true
         where quest_id = q.id and user_id = v_user;
        update public.quests
           set status = 'completed', completed_at = now()
         where id = q.id;
        perform public.award_xp(v_user, q.xp_reward, 'quest_complete',
                                'quest', q.id::text, 'quest:' || q.id::text);
      end if;

      v_quests := v_quests || jsonb_build_object(
        'id', q.id, 'title', q.title, 'progress', v_total,
        'goal', (q.goal->>'count')::int,
        'completed', v_total >= (q.goal->>'count')::int,
        'xp', case when v_total >= (q.goal->>'count')::int then q.xp_reward else 0 end);
    end if;
  end loop;

  v_badges := public.check_badges(v_user);
  select level into v_level_after from public.profiles where id = v_user;

  insert into public.app_events (user_id, name, props)
  values (v_user, 'checkin_saved',
          jsonb_build_object('xp', v_xp, 'discoveries', jsonb_array_length(v_discoveries),
                             'capped', v_capped));

  return jsonb_build_object(
    'check_in_id', v_checkin,
    'xp_awarded', v_xp,
    'xp_capped', v_capped,
    'discoveries', v_discoveries,
    'level_before', v_level_before,
    'level_after', v_level_after,
    'clan_xp_awarded', coalesce(v_clan_xp, 0),
    'quests', v_quests,
    'badges', v_badges,
    'next_goal', public.next_goal(v_user),
    'duplicate', false);
end $$;

-- Rekonstruiert das Reward-Paket eines bestehenden Check-ins.
-- Wird beim Wiederholungsversuch der RetryQueue gebraucht - deshalb muss
-- der Payload nicht zusaetzlich gespeichert werden.
create or replace function public.checkin_reward(p_checkin uuid)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  v record;
  v_disc jsonb;
  v_xp int; v_clan int;
begin
  select * into v from public.check_ins where id = p_checkin;
  if not found then
    raise exception 'CHECKIN_NOT_FOUND' using errcode = 'no_data_found';
  end if;

  select coalesce(jsonb_agg(jsonb_build_object('kind', d.kind, 'name',
    case d.kind
      when 'beer' then (select name from public.beers where id = d.entity_id::uuid)
      when 'venue' then (select name from public.venues where id = d.entity_id::uuid)
      when 'city' then (select name from public.cities where id = d.entity_id::uuid)
      else (select name from public.countries where code = d.entity_id)
    end)), '[]'::jsonb)
  into v_disc
  from public.user_discoveries d
  where d.first_check_in = p_checkin;

  select coalesce(sum(amount),0)::int, coalesce(sum(clan_amount),0)::int
    into v_xp, v_clan
  from public.xp_events
  where ref_type = 'check_in' and ref_id = p_checkin::text;

  return jsonb_build_object(
    'check_in_id', p_checkin,
    'xp_awarded', v_xp,
    'xp_capped', false,
    'discoveries', v_disc,
    'level_before', (select level from public.profiles where id = v.user_id),
    'level_after', (select level from public.profiles where id = v.user_id),
    'clan_xp_awarded', v_clan,
    'quests', '[]'::jsonb,
    'badges', '[]'::jsonb,
    'next_goal', public.next_goal(v.user_id));
end $$;
