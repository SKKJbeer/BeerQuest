-- P0.2 - Ende-zu-Ende-Test des Core Loops.
-- Prueft genau die Regeln, an denen das Produkt haengt.
do $$
declare
  u1 uuid := '11111111-1111-1111-1111-111111111111';
  r jsonb; r2 jsonb;
  v_beer uuid;
  v_xp int; v_level int;
begin
  insert into auth.users (id) values (u1) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u1, 'tester_one', 1990) on conflict (id) do nothing;
  perform set_config('request.jwt.claim.sub', u1::text, true);

  select id into v_beer from public.beers where name_norm = 'peroni nastro azzurro';

  -- === Erster Check-in: neues Bier + neuer Ort + neue Stadt + neues Land
  r := public.create_check_in(
        gen_random_uuid(),
        jsonb_build_object('id', v_beer),
        '{"name":"Bar Aurora","category":"bar","lat":43.3070,"lon":10.5170}'::jsonb,
        now(), 'Europe/Rome');

  -- Der allererste Check-in ist vom Tages-Cap ausgenommen (PM-Entscheidung):
  -- 50 Bier + 50 Ort + 150 Stadt + 300 Land = 550 XP, ungekuerzt.
  if (r->>'xp_awarded')::int <> 550 then
    raise exception 'Erster Check-in muss volle 550 XP geben. War: %',
      r->>'xp_awarded';
  end if;
  if (r->>'xp_capped')::boolean is not false then
    raise exception 'Der erste Check-in darf nicht als gedeckelt gelten';
  end if;
  if jsonb_array_length(r->'discoveries') <> 4 then
    raise exception 'Erwartet 4 Entdeckungen, war %', jsonb_array_length(r->'discoveries');
  end if;
  if (r->>'level_after')::int <> 2 then
    raise exception 'Nach 500 XP muss Level 2 erreicht sein, war %', r->>'level_after';
  end if;

  -- Stadt und Land muessen automatisch aus dem Ort abgeleitet worden sein.
  if not exists (select 1 from public.check_ins c
                 join public.cities ci on ci.id = c.city_id
                 where c.user_id = u1 and ci.name = 'Cecina'
                   and c.country_code = 'IT') then
    raise exception 'Stadt/Land wurden nicht automatisch aus dem Ort abgeleitet';
  end if;

  -- === Ab dem zweiten Check-in greift der Cap. Das Tageskonto steht bereits
  --     bei 550, also gibt es am selben Tag nichts mehr.
  r2 := public.create_check_in(
        gen_random_uuid(),
        '{"name":"Ichnusa"}'::jsonb,
        '{"name":"Bar Marina","category":"bar","lat":43.3100,"lon":10.5200}'::jsonb,
        now(), 'Europe/Rome');
  if (r2->>'xp_awarded')::int <> 0 then
    raise exception 'Tages-Cap verletzt: zweiter Check-in gab % XP', r2->>'xp_awarded';
  end if;

  -- Der Check-in zaehlt trotzdem fuer den Passport - das ist die Zusage
  -- aus dem Reward-Screen.
  if jsonb_array_length(r2->'discoveries') <> 2 then
    raise exception 'Trotz Cap muessen Entdeckungen gezaehlt werden, waren %',
      jsonb_array_length(r2->'discoveries');
  end if;

  select xp, level into v_xp, v_level from public.profiles where id = u1;
  if v_xp <> 550 then
    raise exception 'Profil-XP muss 550 sein, war %', v_xp;
  end if;

  raise notice 'Core Loop ok: % XP, Level %, erster Check-in ungekuerzt', v_xp, v_level;
end $$;
