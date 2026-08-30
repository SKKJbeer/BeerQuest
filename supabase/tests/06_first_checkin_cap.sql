-- Produktregel: Der allererste Check-in eines Nutzers ist vom Tages-Cap
-- ausgenommen, ab dem zweiten greift er unveraendert.
-- Diese beiden Aussagen zusammen sind die Regel - eine allein genuegt nicht.
do $$
declare
  u uuid := '66666666-6666-6666-6666-666666666666';
  r jsonb;
  d1 timestamptz := now() - interval '2 days';
  d2 timestamptz := now() - interval '1 day';
begin
  insert into auth.users (id) values (u) on conflict do nothing;
  insert into public.profiles (id, username, birth_year)
  values (u, 'tester_cap', 1991) on conflict (id) do nothing;
  perform set_config('request.jwt.claim.sub', u::text, true);

  -- === Tag 1: allererster Check-in - vier Entdeckungen, 550 XP, ungekuerzt
  r := public.create_check_in(gen_random_uuid(), '{"name":"Augustiner Helles"}'::jsonb,
       '{"name":"Augustiner Keller","category":"biergarten","lat":48.1440,"lon":11.5540}'::jsonb,
       d1, 'Europe/Berlin');

  if (r->>'xp_awarded')::int <> 550 then
    raise exception 'Erster Check-in muss 550 XP geben (ungekuerzt), war %',
      r->>'xp_awarded';
  end if;
  if (r->>'xp_capped')::boolean is not false then
    raise exception 'Erster Check-in darf nicht als gedeckelt markiert sein';
  end if;
  if (r->>'xp_awarded')::int <= public.cfg_int('xp.daily_cap', 500) then
    raise exception 'Der erste Check-in muss den Tages-Cap uebersteigen duerfen';
  end if;

  -- === Tag 2, Check-in A: neues Bier + neuer Ort + neue Stadt = 250 XP.
  --     Nicht mehr der erste, also gilt der Cap - 250 liegt darunter.
  r := public.create_check_in(gen_random_uuid(), '{"name":"Tegernseer Hell"}'::jsonb,
       '{"name":"Zum Schneider","category":"pub","lat":52.5100,"lon":13.4300}'::jsonb,
       d2, 'Europe/Berlin');
  if (r->>'xp_awarded')::int <> 250 then
    raise exception 'Check-in A an Tag 2 muss 250 XP geben, war %', r->>'xp_awarded';
  end if;
  if (r->>'xp_capped')::boolean is not false then
    raise exception 'Check-in A liegt unter dem Cap und darf nicht gedeckelt sein';
  end if;

  -- === Tag 2, Check-in B: wieder eine neue Stadt (Hamburg), also nochmal
  --     250 XP - das Tageskonto steht dann exakt auf dem Cap von 500.
  --     Muenchen waere hier falsch: die Stadt ist von Tag 1 schon entdeckt.
  r := public.create_check_in(gen_random_uuid(), '{"name":"Astra Urtyp"}'::jsonb,
       '{"name":"Zum Silbersack","category":"pub","lat":53.5500,"lon":9.9600}'::jsonb,
       d2, 'Europe/Berlin');
  if (r->>'xp_awarded')::int <> 250 then
    raise exception 'Check-in B an Tag 2 muss 250 XP geben, war %', r->>'xp_awarded';
  end if;
  if public.capped_xp_today(u, (d2 at time zone 'Europe/Berlin')::date) <> 500 then
    raise exception 'Tageskonto muss nach A und B genau 500 sein, war %',
      public.capped_xp_today(u, (d2 at time zone 'Europe/Berlin')::date);
  end if;

  -- === Tag 2, Check-in C: Cap ist erreicht - 0 XP, aber als gedeckelt markiert.
  --     Zurueck in Muenchen: neues Bier + neuer Ort waeren 100 XP wert.
  r := public.create_check_in(gen_random_uuid(), '{"name":"Erdinger Weissbier"}'::jsonb,
       '{"name":"Weisses Braeuhaus","category":"pub","lat":48.1370,"lon":11.5790}'::jsonb,
       d2, 'Europe/Berlin');
  if (r->>'xp_awarded')::int <> 0 then
    raise exception 'Nach Erreichen des Caps darf es 0 XP geben, war %',
      r->>'xp_awarded';
  end if;
  if (r->>'xp_capped')::boolean is not true then
    raise exception 'Check-in C haette als gedeckelt markiert sein muessen';
  end if;
  -- Der Check-in zaehlt trotzdem fuer den Passport - das ist die Zusage
  -- aus dem Reward-Screen.
  if jsonb_array_length(r->'discoveries') < 1 then
    raise exception 'Trotz Cap muessen Entdeckungen weiter gezaehlt werden';
  end if;

  -- === Quest-XP bleibt vom Discovery-Cap unberuehrt.
  --     (Geprueft in Test 04; hier nur die Abgrenzung dokumentiert.)

  raise notice 'Cap-Regel ok: erster Check-in 550 ungekuerzt, ab dem zweiten greift 500';
end $$;
