-- P0.2 - RLS.
-- Wenn dieser Test faellt, sind XP manipulierbar und alle Leaderboards
-- wertlos. Er prueft die Absicherung, nicht die Funktion.
do $$
declare
  u uuid := '55555555-5555-5555-5555-555555555555';
  n int;
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u, 'tester_rls', 1995) on conflict (id) do nothing;

  -- Keine Tabelle darf fuer `authenticated` schreibbar sein.
  select count(*) into n
  from pg_policies
  where schemaname = 'public'
    and cmd in ('INSERT','UPDATE','DELETE','ALL')
    and 'authenticated' = any(roles);
  if n > 0 then
    raise exception 'Es gibt % Schreib-Policy(s) fuer authenticated - XP waeren manipulierbar', n;
  end if;

  -- Auch keine direkten Tabellenrechte zum Schreiben.
  select count(*) into n
  from information_schema.role_table_grants
  where table_schema = 'public' and grantee = 'authenticated'
    and privilege_type in ('INSERT','UPDATE','DELETE');
  if n > 0 then
    raise exception 'authenticated hat % Schreibrechte auf Tabellen', n;
  end if;

  -- RLS muss auf allen spielrelevanten Tabellen aktiv sein.
  select count(*) into n
  from pg_tables t
  join pg_class c on c.relname = t.tablename
  where t.schemaname = 'public'
    and t.tablename in ('profiles','check_ins','xp_events','user_discoveries',
                        'clans','clan_members','quests','friendships')
    and not c.relrowsecurity;
  if n > 0 then
    raise exception 'RLS fehlt auf % spielrelevanten Tabellen', n;
  end if;

  -- Interne Funktionen duerfen fuer Clients nicht aufrufbar sein.
  if has_function_privilege('authenticated',
       'public.award_xp(uuid, int, text, text, text, text)', 'execute') then
    raise exception 'award_xp ist fuer authenticated aufrufbar - freie XP-Vergabe';
  end if;

  -- create_check_in dagegen muss aufrufbar sein.
  if not has_function_privilege('authenticated',
       'public.create_check_in(uuid, jsonb, jsonb, timestamptz, text)', 'execute') then
    raise exception 'create_check_in ist fuer authenticated nicht aufrufbar';
  end if;

  raise notice 'RLS ok: keine Schreibrechte fuer authenticated';
end $$;
