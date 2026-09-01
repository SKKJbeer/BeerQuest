-- P0.5/P0.7 - Home-Aggregat und Quest-Verwaltung.
do $$
declare
  u uuid := 'aaaaaaaa-0000-0000-0000-000000000002';
  f uuid := 'aaaaaaaa-0000-0000-0000-000000000003';
  r jsonb; q jsonb; v_id uuid;
begin
  insert into auth.users (id) values (u), (f) on conflict do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);
  perform public.complete_onboarding('homer', 1990, 'mug_02', 'brass', 'DE');
  perform set_config('request.jwt.claim.sub', f::text, true);
  perform public.complete_onboarding('freundin', 1991);
  perform set_config('request.jwt.claim.sub', u::text, true);

  -- === Home direkt nach dem Onboarding
  r := public.get_home();
  if (r->'profile'->>'username') <> 'homer' then
    raise exception 'Profil fehlt im Home-Aggregat';
  end if;
  if (r->'profile'->>'xp_needed')::int <> 500 then
    raise exception 'xp_needed muss auf Level 1 genau 500 sein, war %',
      r->'profile'->>'xp_needed';
  end if;
  if (r->'passport'->>'beers')::int <> 0 then
    raise exception 'Passport startet nicht leer';
  end if;
  if r->'next_goal' is null or r->'next_goal' = 'null'::jsonb then
    raise exception 'Ohne naechstes Ziel haette Home nichts anzuzeigen';
  end if;
  if r->>'clan' <> null and (r->'clan') <> 'null'::jsonb then
    raise exception 'Ein Nutzer ohne Clan darf keine Clan-Karte bekommen';
  end if;
  -- Die Erst-Quest wurde beim Onboarding angenommen und muss hier stehen.
  if jsonb_array_length(r->'quests') <> 1 then
    raise exception 'Erst-Quest fehlt auf Home, war: %', r->'quests';
  end if;

  -- === Quest annehmen
  q := public.get_quests();
  if jsonb_array_length(q->'available') = 0 then
    raise exception 'Keine Quest verfuegbar';
  end if;
  -- Die Tagesquest steht oben.
  if (q->'available'->0->>'code') <> (q->>'daily_code') then
    raise exception 'Die Tagesquest muss oben stehen: % vs %',
      q->'available'->0->>'code', q->>'daily_code';
  end if;
  if (q->'available'->0->>'is_daily')::boolean is not true then
    raise exception 'Die Tagesquest ist nicht als solche gekennzeichnet';
  end if;

  r := public.accept_quest(q->'available'->0->>'code');
  v_id := (r->>'id')::uuid;
  if (public.get_quests()->'active') is null
     or jsonb_array_length(public.get_quests()->'active') <> 2 then
    raise exception 'Nach dem Annehmen muessen zwei Quests aktiv sein';
  end if;

  -- === Dieselbe Quest zweimal geht nicht
  begin
    perform public.accept_quest(q->'available'->0->>'code');
    raise exception 'Dieselbe Quest war zweimal annehmbar';
  exception when unique_violation then null;
  end;

  -- === Das Limit von drei aktiven Quests greift
  perform public.accept_quest(
    (select code from public.quest_templates
      where active and code <> 'first_beer'
        and code not in (select template_code from public.quests
                         where owner_id = u and status = 'active')
      order by sort_order limit 1));
  begin
    perform public.accept_quest(
      (select code from public.quest_templates
        where active and code <> 'first_beer'
          and code not in (select template_code from public.quests
                           where owner_id = u and status = 'active')
        order by sort_order limit 1));
    raise exception 'Das Limit von % aktiven Quests hat nicht gegriffen',
      public.cfg_int('quests.max_active', 3);
  exception when check_violation then null;
  end;

  -- === Aufgeben gibt einen Platz frei
  perform public.abandon_quest(v_id);
  if jsonb_array_length(public.get_quests()->'active') <> 2 then
    raise exception 'Nach dem Aufgeben muessen zwei Quests aktiv sein';
  end if;

  -- === Abgelaufene Quests verschwinden beim Lesen, ohne Scheduler
  update public.quests set ends_at = now() - interval '1 hour'
   where owner_id = u and status = 'active';
  if jsonb_array_length(public.get_quests()->'active') <> 0 then
    raise exception 'Abgelaufene Quests wurden beim Lesen nicht ausgewertet';
  end if;

  -- === Aktivitaet: nur von Freunden, nicht von Fremden
  perform set_config('request.jwt.claim.sub', f::text, true);
  perform public.create_check_in(gen_random_uuid(), '{"name":"Duvel"}'::jsonb,
    '{"name":"Cafe Belge","category":"bar","lat":50.8504,"lon":4.3488}'::jsonb,
    now(), 'Europe/Brussels');
  perform set_config('request.jwt.claim.sub', u::text, true);

  if jsonb_array_length(public.get_home()->'activity') <> 0 then
    raise exception 'Ein Fremder darf nicht in der Aktivitaet auftauchen';
  end if;

  insert into public.friendships (user_low, user_high)
  values (least(u,f), greatest(u,f));
  r := public.get_home();
  if jsonb_array_length(r->'activity') = 0 then
    raise exception 'Nach der Freundschaft fehlt die Aktivitaet';
  end if;
  if (r->'activity'->0->>'user') <> 'freundin' then
    raise exception 'Falscher Urheber in der Aktivitaet: %', r->'activity'->0;
  end if;
  if jsonb_array_length(r->'activity') > 3 then
    raise exception 'Home zeigt mehr als drei Aktivitaetszeilen';
  end if;

  raise notice 'Home und Quests ok: Aggregat, Limit, Ablauf, Aktivitaet nur von Freunden';
end $$;
