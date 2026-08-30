-- P0.2 - Idempotenz und Dedupe.
-- Diese beiden Regeln sind der Grund, warum die RetryQueue im Client
-- ueberhaupt sicher ist und warum die Karte nicht in Dubletten zerfaellt.
do $$
declare
  u uuid := '22222222-2222-2222-2222-222222222222';
  cid uuid := gen_random_uuid();
  r1 jsonb; r2 jsonb;
  v_xp_after_first int; v_xp_after_retry int;
  v_venues_before int; v_venues_after int;
  v_beers_before int; v_beers_after int;
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u, 'tester_two', 1992) on conflict (id) do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);

  -- === Idempotenz: derselbe client_uuid darf nie zweimal XP erzeugen
  r1 := public.create_check_in(cid, '{"name":"Duvel"}'::jsonb,
        '{"name":"Cafe Belge","category":"bar","lat":50.8504,"lon":4.3488}'::jsonb,
        now(), 'Europe/Brussels');
  select xp into v_xp_after_first from public.profiles where id = u;

  r2 := public.create_check_in(cid, '{"name":"Duvel"}'::jsonb,
        '{"name":"Cafe Belge","category":"bar","lat":50.8504,"lon":4.3488}'::jsonb,
        now(), 'Europe/Brussels');
  select xp into v_xp_after_retry from public.profiles where id = u;

  if v_xp_after_first <> v_xp_after_retry then
    raise exception 'Wiederholung hat XP verdoppelt: % -> %',
      v_xp_after_first, v_xp_after_retry;
  end if;
  if (r2->>'duplicate')::boolean is not true then
    raise exception 'Wiederholung wurde nicht als duplicate markiert';
  end if;
  if (r2->>'check_in_id') <> (r1->>'check_in_id') then
    raise exception 'Wiederholung hat einen zweiten Check-in erzeugt';
  end if;
  if (r2->>'xp_awarded')::int <> (r1->>'xp_awarded')::int then
    raise exception 'Rekonstruiertes Reward-Paket weicht ab: % vs %',
      r2->>'xp_awarded', r1->>'xp_awarded';
  end if;

  -- === Ort-Dedupe: aehnlicher Name innerhalb von 150 m ist derselbe Ort
  select count(*) into v_venues_before from public.venues;
  perform public.find_or_create_venue('Cafe Belge Brussels', 'bar', 50.85045, 4.34885, u);
  select count(*) into v_venues_after from public.venues;
  if v_venues_after <> v_venues_before then
    raise exception 'Dedupe hat versagt: aus einem Ort wurden zwei';
  end if;

  -- Gleicher Name, aber 2 km entfernt: das ist ein anderer Ort.
  perform public.find_or_create_venue('Cafe Belge', 'bar', 50.8700, 4.3488, u);
  select count(*) into v_venues_after from public.venues;
  if v_venues_after <> v_venues_before + 1 then
    raise exception 'Ein Ort in 2 km Entfernung wurde faelschlich zusammengelegt';
  end if;

  -- === Bier-Dedupe ueber die normalisierte Identitaet
  select count(*) into v_beers_before from public.beers;
  perform public.find_or_create_beer('  DUVEL!! ', null, u);
  select count(*) into v_beers_after from public.beers;
  if v_beers_after <> v_beers_before then
    raise exception 'Bier-Dedupe hat versagt: "DUVEL!!" wurde neu angelegt';
  end if;

  raise notice 'Idempotenz und Dedupe ok';
end $$;
