-- P0.5/P0.7 - Home als EIN Aggregat-Call, und die Quest-Verwaltung.
--
-- get_home ist bewusst ein einziger Aufruf: Egress ist das eigentliche
-- Limit des Free Tiers (docs/10-risks.md R9), und ein Home-Screen, der
-- sechs Anfragen stellt, verbrennt es sechsmal so schnell.

-- Quest-Ablauf wird beim Lesen ausgewertet - kein Scheduler, kein Job.
create or replace function public.expire_quests(p_user uuid)
returns void
language sql security definer set search_path = public, extensions as $$
  update public.quests set status = 'expired'
   where owner_id = p_user and status = 'active' and ends_at <= now()
$$;

-- Bewusst VOLATILE, nicht STABLE: Die Funktion wertet den Quest-Ablauf beim
-- Lesen aus und schreibt dabei. Eine STABLE-Funktion darf das nicht - der
-- Ablauf lief dann still ins Leere, und abgelaufene Quests blieben aktiv.
-- Das ist der Preis dafuer, keinen Scheduler zu betreiben.
create or replace function public.get_quests()
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v_max int := public.cfg_int('quests.max_active', 3);
  v_daily text := public.daily_quest_code();
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  perform public.expire_quests(v_user);

  return jsonb_build_object(
    'max_active', v_max,
    'daily_code', v_daily,

    'active', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id, 'code', q.template_code, 'title', q.title,
        'goal', (q.goal->>'count')::int, 'progress', qp.contributed,
        'xp', q.xp_reward, 'ends_at', q.ends_at,
        'is_daily', q.template_code = v_daily)
        order by q.ends_at)
      from public.quests q
      join public.quest_participants qp on qp.quest_id = q.id and qp.user_id = v_user
      where q.owner_id = v_user and q.status = 'active'), '[]'::jsonb),

    -- Verfuegbar ist, was aktiv nicht laeuft. Die Tagesquest steht dabei
    -- immer oben, auch wenn sie sonst weiter unten sortiert waere.
    'available', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', t.code, 'title', t.title, 'description', t.description,
        'goal', (t.goal->>'count')::int, 'xp', t.xp_reward,
        'duration_hours', t.duration_hours,
        'is_daily', t.code = v_daily)
        order by (t.code = v_daily) desc, t.sort_order)
      from public.quest_templates t
      where t.active
        and t.code <> 'first_beer'
        and not exists (select 1 from public.quests q
                        where q.owner_id = v_user and q.template_code = t.code
                          and q.status = 'active')), '[]'::jsonb),

    'completed', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id', q.id, 'title', q.title, 'xp', q.xp_reward,
        'completed_at', q.completed_at) order by q.completed_at desc)
      from public.quests q
      where q.owner_id = v_user and q.status = 'completed'), '[]'::jsonb)
  );
end $$;

create or replace function public.accept_quest(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  t public.quest_templates;
  v_aktiv int;
  v_id uuid;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  perform public.expire_quests(v_user);

  select * into t from public.quest_templates where code = p_code and active;
  if not found then
    raise exception 'QUEST_UNKNOWN' using errcode = 'no_data_found';
  end if;

  if exists (select 1 from public.quests
             where owner_id = v_user and template_code = p_code and status = 'active') then
    raise exception 'QUEST_ALREADY_ACTIVE' using errcode = 'unique_violation';
  end if;

  select count(*) into v_aktiv from public.quests
   where owner_id = v_user and status = 'active';
  if v_aktiv >= public.cfg_int('quests.max_active', 3) then
    raise exception 'QUEST_LIMIT_REACHED' using errcode = 'check_violation';
  end if;

  -- Snapshot: Ziel, Titel und Belohnung werden kopiert. Eine spaetere
  -- Balancing-Aenderung veraendert laufende Quests nie.
  insert into public.quests
    (template_code, kind, owner_id, title, goal, xp_reward, ends_at)
  values (t.code, t.kind, v_user, t.title, t.goal, t.xp_reward,
          now() + make_interval(hours => t.duration_hours))
  returning id into v_id;
  insert into public.quest_participants (quest_id, user_id) values (v_id, v_user);

  return jsonb_build_object('id', v_id, 'title', t.title,
    'goal', (t.goal->>'count')::int, 'xp', t.xp_reward);
end $$;

create or replace function public.abandon_quest(p_quest uuid)
returns void
language plpgsql security definer set search_path = public, extensions as $$
declare v_user uuid := auth.uid();
begin
  update public.quests set status = 'cancelled'
   where id = p_quest and owner_id = v_user and status = 'active';
  if not found then
    raise exception 'QUEST_NOT_ACTIVE' using errcode = 'no_data_found';
  end if;
end $$;

-- ------------------------------------------------------------------ Home
-- Ebenfalls VOLATILE, weil get_quests aufgerufen wird.
create or replace function public.get_home()
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  p public.profiles;
  v_clan public.clans;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  select * into p from public.profiles where id = v_user;
  if not found then
    raise exception 'NO_PROFILE' using errcode = 'no_data_found';
  end if;

  select c.* into v_clan from public.clans c
    join public.clan_members m on m.clan_id = c.id
   where m.user_id = v_user and c.deleted_at is null;

  return jsonb_build_object(
    'profile', jsonb_build_object(
      'id', p.id, 'username', p.username, 'display_name', p.display_name,
      'avatar_key', p.avatar_key, 'avatar_color', p.avatar_color,
      'level', p.level, 'xp', p.xp,
      'xp_in_level', p.xp - public.total_xp_to_reach(p.level),
      'xp_needed', 500 * p.level),

    'passport', jsonb_build_object(
      'countries', public.user_metric(v_user, 'countries'),
      'cities',    public.user_metric(v_user, 'cities'),
      'venues',    public.user_metric(v_user, 'venues'),
      'beers',     public.user_metric(v_user, 'beers')),

    'next_goal', public.next_goal(v_user),

    'quests', (public.get_quests()->'active'),

    'clan', case when v_clan.id is null then null else jsonb_build_object(
      'id', v_clan.id, 'name', v_clan.name, 'level', v_clan.level,
      'xp', v_clan.xp, 'member_count', v_clan.member_count,
      'my_contribution', (select contributed_xp from public.clan_members
                          where user_id = v_user)) end,

    -- Aktivitaet aus vorhandenen Daten: Freunde und Clan-Mitglieder.
    -- Kein eigener Feed, keine zusaetzliche Tabelle.
    'activity', coalesce((
      select jsonb_agg(a order by a->>'at' desc)
      from (
        select jsonb_build_object(
          'user', pr.username, 'avatar_key', pr.avatar_key,
          'avatar_color', pr.avatar_color,
          'kind', d.kind::text, 'at', d.discovered_at,
          'name', case d.kind
            when 'beer'  then (select name from public.beers    where id = d.entity_id::uuid)
            when 'venue' then (select name from public.venues   where id = d.entity_id::uuid)
            when 'city'  then (select name from public.cities   where id = d.entity_id::uuid)
            else (select name from public.countries where code = d.entity_id) end) as a
        from public.user_discoveries d
        join public.profiles pr on pr.id = d.user_id
        where d.user_id <> v_user
          and (public.is_friend(v_user, d.user_id)
               or (v_clan.id is not null and exists (
                     select 1 from public.clan_members m
                      where m.user_id = d.user_id and m.clan_id = v_clan.id)))
        order by d.discovered_at desc
        limit 3
      ) t), '[]'::jsonb)
  );
end $$;

grant execute on function public.get_quests() to authenticated;
grant execute on function public.accept_quest(text) to authenticated;
grant execute on function public.abandon_quest(uuid) to authenticated;
grant execute on function public.get_home() to authenticated;
