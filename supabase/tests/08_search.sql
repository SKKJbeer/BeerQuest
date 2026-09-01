-- P0.4 - Suche.
-- Die erste Pruefung ist die wichtigste: Sie bildet die PM-Anforderung
-- woertlich ab. Wer "Peroni" tippt, muss die Varianten sehen, sonst legt er
-- eine Dublette an.
do $$
declare
  u uuid := 'aaaaaaaa-0000-0000-0000-000000000001';
  r jsonb;
  namen text;
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u, 'tester_suche', 1990) on conflict (id) do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);

  -- === Die PM-Anforderung: "Peroni" findet alle drei Varianten
  r := public.search_beers('Peroni');
  select string_agg(x->>'name', ' | ') into namen from jsonb_array_elements(r) x;
  if jsonb_array_length(r) < 3 then
    raise exception 'Suche nach "Peroni" muss mindestens 3 Varianten liefern, war %: %',
      jsonb_array_length(r), namen;
  end if;
  if namen not like '%Peroni Nastro Azzurro%'
     or namen not like '%Peroni Gran Riserva%'
     or namen not like '%0.0%' then
    raise exception 'Nicht alle Peroni-Varianten gefunden: %', namen;
  end if;
  raise notice '  "Peroni" -> %', namen;

  -- Der kuerzeste, exakteste Treffer steht oben - nicht der laengste.
  if (r->0->>'name') not like 'Peroni Nastro Azzurro%' then
    raise exception 'Der Praefix-Treffer muss oben stehen, oben stand: %', r->0->>'name';
  end if;

  -- === Tippfehler werden aufgefangen
  r := public.search_beers('Peronni');
  if jsonb_array_length(r) = 0 then
    raise exception 'Ein Tippfehler darf nicht zu null Treffern fuehren';
  end if;

  -- === Zu kurze Eingabe liefert nichts, statt den halben Katalog
  if jsonb_array_length(public.search_beers('P')) <> 0 then
    raise exception 'Ein einzelner Buchstabe darf keine Treffer liefern';
  end if;

  -- === Suche in der Brauerei-Schreibweise
  if jsonb_array_length(public.search_beers('Augustiner')) = 0 then
    raise exception 'Suche nach "Augustiner" liefert nichts';
  end if;

  -- === Orte im Umkreis, mit Entfernung
  perform public.create_check_in(gen_random_uuid(), '{"name":"Ichnusa"}'::jsonb,
    '{"name":"Bar Aurora","category":"bar","lat":43.3070,"lon":10.5170}'::jsonb,
    now(), 'Europe/Rome');

  r := public.search_venues_nearby(43.3071, 10.5171);
  if jsonb_array_length(r) = 0 then
    raise exception 'Der eben angelegte Ort wird im Umkreis nicht gefunden';
  end if;
  if (r->0->>'entfernung')::numeric > 50 then
    raise exception 'Entfernung unplausibel: % m', r->0->>'entfernung';
  end if;
  if (r->0->>'city') <> 'Cecina' then
    raise exception 'Stadt fehlt am Ort-Treffer, war: %', r->0->>'city';
  end if;

  -- Weit weg: kein Treffer. Sonst waere der Umkreis wirkungslos.
  if jsonb_array_length(public.search_venues_nearby(52.52, 13.40)) <> 0 then
    raise exception 'Ein Ort 900 km entfernt darf nicht im Umkreis auftauchen';
  end if;

  -- === Zuletzt getrunken
  r := public.recent_beers();
  if jsonb_array_length(r) <> 1 or (r->0->>'name') <> 'Ichnusa' then
    raise exception 'recent_beers liefert nicht das eben getrunkene Bier: %', r;
  end if;

  raise notice 'Suche ok: Peroni-Varianten, Tippfehler, Umkreis, zuletzt getrunken';
end $$;
