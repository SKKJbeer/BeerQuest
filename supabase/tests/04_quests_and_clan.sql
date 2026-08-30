-- P0.2 - Quest-Fortschritt und Clan-XP.
-- Die RPCs accept_quest/create_clan folgen in P0.7 bzw. P0.9; hier werden
-- die Zeilen direkt gesetzt, um die Logik in create_check_in zu pruefen.
do $$
declare
  u uuid := '33333333-3333-3333-3333-333333333333';
  c uuid := '44444444-4444-4444-4444-444444444444';
  q uuid;
  r jsonb;
  v_clan_xp int; v_contrib int; v_personal int;
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u, 'tester_clan', 1988) on conflict (id) do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);

  insert into public.clans (id, name, join_code, owner_id, member_count)
  values (c, 'Hop Heads', 'HOPHEAD1', u, 1) on conflict (id) do nothing;
  insert into public.clan_members (user_id, clan_id, role)
  values (u, c, 'owner') on conflict (user_id) do nothing;

  -- Quest: 2 neue Orte entdecken
  insert into public.quests (template_code, kind, owner_id, title, goal, xp_reward, ends_at)
  values ('two_venues','solo', u, 'Place Hunter',
          '{"type":"discover_venue","count":2}'::jsonb, 200, now() + interval '3 days')
  returning id into q;
  insert into public.quest_participants (quest_id, user_id) values (q, u);

  -- --- Erster Check-in: Quest 1/2, noch nicht fertig
  r := public.create_check_in(gen_random_uuid(), '{"name":"Pilsner Urquell"}'::jsonb,
       '{"name":"U Fleku","category":"pub","lat":50.0810,"lon":14.4200}'::jsonb,
       now(), 'Europe/Prague');
  if jsonb_array_length(r->'quests') <> 1 then
    raise exception 'Quest wurde nicht fortgeschrieben';
  end if;
  if (r->'quests'->0->>'progress')::int <> 1 then
    raise exception 'Quest-Fortschritt muss 1 sein, war %', r->'quests'->0->>'progress';
  end if;
  if (r->'quests'->0->>'completed')::boolean is true then
    raise exception 'Quest darf nach einem Ort noch nicht fertig sein';
  end if;

  -- --- Zweiter Check-in am naechsten Tag: Quest fertig, +200 XP
  r := public.create_check_in(gen_random_uuid(), '{"name":"Kozel Cerny"}'::jsonb,
       '{"name":"Lokal Dlouha","category":"pub","lat":50.0900,"lon":14.4250}'::jsonb,
       now() + interval '1 day', 'Europe/Prague');
  if (r->'quests'->0->>'completed')::boolean is not true then
    raise exception 'Quest haette abgeschlossen sein muessen';
  end if;
  if (r->'quests'->0->>'xp')::int <> 200 then
    raise exception 'Quest-Belohnung muss 200 sein, war %', r->'quests'->0->>'xp';
  end if;
  if not exists (select 1 from public.quests where id = q and status = 'completed') then
    raise exception 'Quest-Status wurde nicht auf completed gesetzt';
  end if;

  -- --- Clan-XP: 60 % der persoenlichen XP (Product Vision §17)
  select coalesce(sum(amount),0), coalesce(sum(clan_amount),0)
    into v_personal, v_clan_xp
  from public.xp_events where user_id = u;

  if v_clan_xp <> round(v_personal * 0.6) then
    raise exception 'Clan-XP muss 60%% der persoenlichen XP sein: % von %',
      v_clan_xp, v_personal;
  end if;

  select xp into v_contrib from public.clans where id = c;
  if v_contrib <> v_clan_xp then
    raise exception 'clans.xp (%) weicht vom Ledger (%) ab', v_contrib, v_clan_xp;
  end if;
  select contributed_xp into v_contrib from public.clan_members where user_id = u;
  if v_contrib <> v_clan_xp then
    raise exception 'clan_members.contributed_xp (%) weicht vom Ledger (%) ab',
      v_contrib, v_clan_xp;
  end if;

  -- --- Quest-XP darf NICHT vom Tages-Cap erfasst sein
  if not exists (select 1 from public.xp_events
                 where user_id = u and reason = 'quest_complete' and amount = 200) then
    raise exception 'Quest-XP wurde faelschlich gedeckelt oder nicht vergeben';
  end if;

  raise notice 'Quests und Clan-XP ok: % persoenlich, % Clan', v_personal, v_clan_xp;
end $$;
