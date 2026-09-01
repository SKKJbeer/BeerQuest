-- P0.5/P0.6 - Passport, Karte, Historie, Ruecknahme.
do $$
declare
  u uuid := 'cccccccc-0000-0000-0000-000000000001';
  r jsonb; cid uuid; xp_vorher int; xp_nachher int;
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);
  perform public.complete_onboarding('sammler', 1990);

  -- Zwei Check-ins in zwei Laendern
  perform public.create_check_in(gen_random_uuid(), '{"name":"Peroni Nastro Azzurro"}'::jsonb,
    '{"name":"Bar Aurora","category":"bar","lat":43.3070,"lon":10.5170}'::jsonb,
    now() - interval '2 days', 'Europe/Rome');
  perform public.create_check_in(gen_random_uuid(), '{"name":"Augustiner Helles"}'::jsonb,
    '{"name":"Augustiner Keller","category":"biergarten","lat":48.1440,"lon":11.5540}'::jsonb,
    now() - interval '1 day', 'Europe/Berlin');

  -- === Zusammenfassung
  r := public.get_passport_summary();
  if (r->>'countries')::int <> 2 or (r->>'cities')::int <> 2
     or (r->>'venues')::int <> 2 or (r->>'beers')::int <> 2 then
    raise exception 'Passport-Zaehler falsch: %', r;
  end if;

  -- === Die vier Listen, aus einer Funktion
  if jsonb_array_length(public.get_passport('country')) <> 2 then
    raise exception 'Laenderliste unvollstaendig';
  end if;
  r := public.get_passport('country');
  if (r->0->>'flag') is null then
    raise exception 'Der Flagge fehlt am Land-Eintrag';
  end if;
  r := public.get_passport('city');
  if (r->0->>'context') is null then
    raise exception 'Der Stadt fehlt das Land als Kontext';
  end if;
  r := public.get_passport('beer');
  if (r->0->>'context') is null then
    raise exception 'Dem Bier fehlt die Brauerei als Kontext';
  end if;

  -- Neueste zuerst - der zweite Check-in war spaeter.
  if (public.get_passport('venue')->0->>'name') <> 'Augustiner Keller' then
    raise exception 'Passport sortiert nicht nach Entdeckungsdatum';
  end if;

  -- Suche in der Liste
  if jsonb_array_length(public.get_passport('beer', 'peroni')) <> 1 then
    raise exception 'Suche in der Passport-Liste greift nicht';
  end if;

  -- === Karte: Weltebene zeigt Laender, Stadtebene die Orte
  r := public.get_map_pins(3);
  if jsonb_array_length(r) <> 2 or (r->0->>'kind') <> 'country' then
    raise exception 'Weltebene liefert keine Laender: %', r;
  end if;
  if (r->0->>'venues')::int < 1 then
    raise exception 'Am Land fehlen die Zaehler';
  end if;
  r := public.get_map_pins(10);
  if jsonb_array_length(r) <> 2 or (r->0->>'kind') <> 'venue' then
    raise exception 'Stadtebene liefert keine Orte: %', r;
  end if;

  -- === Ort-Detail
  r := public.get_venue_detail((r->0->>'id')::uuid);
  if (r->>'visits')::int <> 1 or jsonb_array_length(r->'beers') <> 1 then
    raise exception 'Ort-Detail unvollstaendig: %', r;
  end if;
  if (r->>'city') is null or (r->>'flag') is null then
    raise exception 'Am Ort fehlen Stadt oder Flagge';
  end if;

  -- === Historie
  r := public.get_history();
  if jsonb_array_length(r) <> 2 then
    raise exception 'Historie unvollstaendig';
  end if;
  if (r->0->>'xp')::int <= 0 then
    raise exception 'Der Historie fehlen die XP je Check-in';
  end if;
  if (r->0->>'deletable')::boolean is not true then
    raise exception 'Ein frischer Check-in muss loeschbar sein';
  end if;
  cid := (r->0->>'id')::uuid;

  -- === Ruecknahme: XP per Gegenbuchung, Ledger bleibt vollstaendig
  select xp into xp_vorher from public.profiles where id = u;
  r := public.delete_check_in(cid);
  select xp into xp_nachher from public.profiles where id = u;

  if xp_nachher <> xp_vorher - (r->>'xp_reverted')::int then
    raise exception 'Ruecknahme hat die XP nicht korrekt gegengebucht: % -> %, zurueck %',
      xp_vorher, xp_nachher, r->>'xp_reverted';
  end if;
  if exists (select 1 from public.check_ins where id = cid) then
    raise exception 'Der Check-in wurde nicht geloescht';
  end if;
  -- Der Ledger behaelt beide Buchungen - Vergabe und Gegenbuchung.
  if (select count(*) from public.xp_events
      where ref_type = 'check_in' and ref_id = cid::text) <> 2 then
    raise exception 'Der Ledger muss Vergabe und Gegenbuchung behalten';
  end if;
  -- Die Entdeckungen dieses Check-ins sind mit weggefallen.
  if (public.get_passport_summary()->>'countries')::int <> 1 then
    raise exception 'Die Entdeckungen des zurueckgenommenen Check-ins blieben stehen';
  end if;

  -- === Zu alt: nicht mehr loeschbar
  update public.check_ins set created_at = now() - interval '2 days' where user_id = u;
  begin
    perform public.delete_check_in((select id from public.check_ins where user_id = u limit 1));
    raise exception 'Ein alter Check-in war loeschbar';
  exception when check_violation then null;
  end;

  raise notice 'Passport ok: Listen, Karte, Historie, Ruecknahme mit Gegenbuchung';
end $$;
