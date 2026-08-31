-- P0.3 - Onboarding serverseitig.
-- Die Alterspruefung ist der Kern: sie darf nicht im Client liegen,
-- sonst ist sie wertlos.
do $$
declare
  u1 uuid := '77777777-7777-7777-7777-777777777777';
  u2 uuid := '88888888-8888-8888-8888-888888888888';
  u3 uuid := '99999999-9999-9999-9999-999999999999';
  r jsonb;
  v_code text := 'TESTINV1';
  v_ok boolean;
begin
  insert into auth.users (id) values (u1), (u2), (u3) on conflict do nothing;

  -- === Username-Pruefung
  if (public.check_username('ab')->>'reason') <> 'format' then
    raise exception 'Zu kurzer Username muss als format abgelehnt werden';
  end if;
  if (public.check_username('Bad Name')->>'reason') <> 'format' then
    raise exception 'Leerzeichen im Username muss abgelehnt werden';
  end if;
  if (public.check_username('admin')->>'reason') <> 'not_allowed' then
    raise exception 'Wortfilter greift nicht';
  end if;
  if (public.check_username('beerquest_team')->>'reason') <> 'not_allowed' then
    raise exception 'Wortfilter muss auch Teiltreffer erkennen';
  end if;
  if not (public.check_username('steffen')->>'available')::boolean then
    raise exception 'Gueltiger Username wurde faelschlich abgelehnt';
  end if;

  -- === Minderjaehrig: muss serverseitig scheitern
  perform set_config('request.jwt.claim.sub', u1::text, true);
  begin
    perform public.complete_onboarding('tooyoung',
      extract(year from now())::int - 16);
    raise exception 'Minderjaehriger Nutzer konnte ein Profil anlegen';
  exception when check_violation then
    null;  -- erwartet
  end;
  if exists (select 1 from public.profiles where id = u1) then
    raise exception 'Trotz Abbruch wurde ein Profil angelegt';
  end if;

  -- === Regulaeres Onboarding
  r := public.complete_onboarding('steffen', 1990, 'mug_03', 'copper', 'DE');
  if r->>'username' <> 'steffen' then
    raise exception 'Username falsch gespeichert';
  end if;
  if r->>'first_quest_id' is null then
    raise exception 'Erst-Quest wurde nicht angenommen';
  end if;
  if not exists (select 1 from public.quest_participants
                 where user_id = u1 and quest_id = (r->>'first_quest_id')::uuid) then
    raise exception 'Nutzer ist nicht Teilnehmer der Erst-Quest';
  end if;
  if r->'next_goal' is null then
    raise exception 'Naechstes Ziel fehlt - Home haette nichts anzuzeigen';
  end if;

  -- === Zweiter Aufruf muss scheitern
  begin
    perform public.complete_onboarding('steffen2', 1990);
    raise exception 'Onboarding war zweimal moeglich';
  exception when unique_violation then
    null;  -- erwartet
  end;

  -- === Username-Kollision
  perform set_config('request.jwt.claim.sub', u2::text, true);
  begin
    perform public.complete_onboarding('steffen', 1985);
    raise exception 'Doppelter Username wurde akzeptiert';
  exception when check_violation then
    null;  -- erwartet
  end;

  -- === Invite-Einloesung im Onboarding
  insert into public.invites (code, inviter_id, expires_at)
  values (v_code, u1, now() + interval '30 days');

  perform set_config('request.jwt.claim.sub', u3::text, true);
  r := public.complete_onboarding('lisa', 1994, 'mug_02', 'forest', 'IT', v_code);
  if (r->>'friend_added')::boolean is not true then
    raise exception 'Invite wurde nicht eingeloest';
  end if;
  if not exists (select 1 from public.friendships
                 where user_low = least(u1,u3) and user_high = greatest(u1,u3)) then
    raise exception 'Freundschaft wurde nicht angelegt';
  end if;
  if (select use_count from public.invites where code = v_code) <> 1 then
    raise exception 'use_count wurde nicht hochgezaehlt';
  end if;
  if (select invited_by from public.profiles where id = u3) <> u1 then
    raise exception 'invited_by wurde nicht gesetzt';
  end if;

  -- Beide Seiten bekommen die Freundschafts-XP.
  if (select xp from public.profiles where id = u3) < 25
     or (select xp from public.profiles where id = u1) < 25 then
    raise exception 'Freundschafts-XP fehlt auf einer der beiden Seiten';
  end if;

  -- Das Badge fuer den ersten Freund muss vergeben sein.
  if not exists (select 1 from public.user_badges
                 where user_id = u3 and code = 'first_friend') then
    raise exception 'Badge first_friend wurde nicht vergeben';
  end if;

  raise notice 'Onboarding ok: Alterspruefung, Wortfilter, Erst-Quest, Invite';
end $$;
