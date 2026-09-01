-- P0.8/P0.9/P0.10 - Freunde, Invites, Clan, Leaderboard.
do $$
declare
  a uuid := 'bbbbbbbb-0000-0000-0000-000000000001';
  b uuid := 'bbbbbbbb-0000-0000-0000-000000000002';
  c uuid := 'bbbbbbbb-0000-0000-0000-000000000003';
  r jsonb; code text; clan uuid; req uuid;
begin
  insert into auth.users (id) values (a), (b), (c) on conflict do nothing;
  perform set_config('request.jwt.claim.sub', a::text, true);
  perform public.complete_onboarding('anna', 1990);
  perform set_config('request.jwt.claim.sub', b::text, true);
  perform public.complete_onboarding('bernd', 1988);
  perform set_config('request.jwt.claim.sub', c::text, true);
  perform public.complete_onboarding('clara', 1993);

  -- ===================================================== Invite
  perform set_config('request.jwt.claim.sub', a::text, true);
  code := public.create_invite()->>'code';
  if code !~ '^[0-9A-HJKMNP-TV-Z]{8}$' then
    raise exception 'Invite-Code hat die falsche Form: %', code;
  end if;
  -- Verwechselbare Zeichen sind ausgeschlossen - der Code wird diktiert.
  if code ~ '[ILOU]' then
    raise exception 'Code enthaelt ein verwechselbares Zeichen: %', code;
  end if;
  -- Zweimal anfragen gibt denselben Code, nicht fuenf im Umlauf.
  if public.create_invite()->>'code' <> code then
    raise exception 'Ein zweiter Aufruf hat einen zweiten Code erzeugt';
  end if;

  -- Der eigene Code ist nicht einloesbar.
  begin
    perform public.redeem_invite(code);
    raise exception 'Der eigene Invite-Code war einloesbar';
  exception when check_violation then null;
  end;

  perform set_config('request.jwt.claim.sub', b::text, true);
  r := public.redeem_invite(code);
  if (r->>'user') <> 'anna' then
    raise exception 'Einloesung nennt den falschen Einladenden: %', r;
  end if;
  if not public.is_friend(a, b) then
    raise exception 'Nach der Einloesung besteht keine Freundschaft';
  end if;
  -- Beide Seiten bekommen XP.
  if (select xp from public.profiles where id = a) < 25
     or (select xp from public.profiles where id = b) < 25 then
    raise exception 'Freundschafts-XP fehlt auf einer Seite';
  end if;
  -- Nochmal einloesen ist kein Fehler, sondern ein No-op.
  if (public.redeem_invite(code)->>'already_friends')::boolean is not true then
    raise exception 'Zweite Einloesung haette already_friends melden muessen';
  end if;

  -- ===================================================== Freundschaftsanfrage
  perform public.send_friend_request(c);
  perform set_config('request.jwt.claim.sub', c::text, true);
  r := public.get_friend_requests();
  if jsonb_array_length(r) <> 1 or (r->0->>'username') <> 'bernd' then
    raise exception 'Anfrage kommt nicht an: %', r;
  end if;
  req := (r->0->>'id')::uuid;
  perform public.respond_friend_request(req, true);
  if not public.is_friend(b, c) then
    raise exception 'Annahme hat keine Freundschaft erzeugt';
  end if;

  -- Eine Gegenanfrage bei offener Anfrage ist eine Zusage, kein zweiter Antrag.
  perform set_config('request.jwt.claim.sub', a::text, true);
  perform public.send_friend_request(c);
  perform set_config('request.jwt.claim.sub', c::text, true);
  perform public.send_friend_request(a);
  if not public.is_friend(a, c) then
    raise exception 'Gegenseitige Anfrage haette die Freundschaft schliessen muessen';
  end if;

  -- Suche zeigt die Beziehung an.
  perform set_config('request.jwt.claim.sub', a::text, true);
  r := public.search_users('bern');
  if (r->0->>'relation') <> 'friends' then
    raise exception 'Beziehung in der Suche falsch: %', r->0;
  end if;

  -- ===================================================== Leaderboard
  r := public.get_leaderboard_friends('week');
  if jsonb_array_length(r) <> 3 then
    raise exception 'Leaderboard muss mich und zwei Freunde zeigen, war %',
      jsonb_array_length(r);
  end if;
  if not exists (select 1 from jsonb_array_elements(r) x
                 where (x->>'is_me')::boolean) then
    raise exception 'Die eigene Zeile ist nicht markiert';
  end if;
  if (r->0->>'rank')::int <> 1 then
    raise exception 'Der erste Rang ist nicht 1';
  end if;

  -- ===================================================== Clan
  -- Der Name muss ueber alle Testdateien hinweg eindeutig sein: Sie laufen
  -- nacheinander gegen dieselbe Datenbank, und Test 04 legt bereits einen
  -- Clan an. Ein Name, den ein anderer Test schon vergeben hat, sieht wie
  -- ein Fehler in create_clan aus - und ist keiner.
  r := public.create_clan('Beer Bandits');
  clan := (r->>'id')::uuid;
  if (r->>'join_code') is null then
    raise exception 'Clan ohne Beitrittscode';
  end if;

  begin
    perform public.create_clan('Zweiter Clan');
    raise exception 'Ein zweiter Clan war moeglich';
  exception when unique_violation then null;
  end;

  begin
    perform public.create_clan('admin');
    raise exception 'Der Wortfilter greift bei Clan-Namen nicht';
  exception when unique_violation then null;
       when check_violation then null;
  end;

  perform set_config('request.jwt.claim.sub', b::text, true);
  perform public.join_clan_by_code(r->>'join_code');
  if (select member_count from public.clans where id = clan) <> 2 then
    raise exception 'Mitgliederzahl wurde nicht hochgezaehlt';
  end if;

  -- Ein Nicht-Mitglied sieht weder Mitglieder noch den Beitrittscode.
  perform set_config('request.jwt.claim.sub', c::text, true);
  r := public.get_clan(clan);
  if (r->>'join_code') is not null then
    raise exception 'Ein Fremder sieht den Beitrittscode';
  end if;
  if (r->'members') <> 'null'::jsonb then
    raise exception 'Ein Fremder sieht die Mitgliederliste';
  end if;

  -- Ein Mitglied sieht beides, mit Rang.
  perform set_config('request.jwt.claim.sub', b::text, true);
  r := public.get_clan();
  if (r->>'join_code') is null or jsonb_array_length(r->'members') <> 2 then
    raise exception 'Ein Mitglied sieht nicht alles: %', r;
  end if;
  if (r->'members'->0->>'rank')::int <> 1 then
    raise exception 'Mitglieder-Ranking fehlt';
  end if;

  -- ===================================================== Owner geht
  perform set_config('request.jwt.claim.sub', a::text, true);
  perform public.leave_clan();
  if (select owner_id from public.clans where id = clan) <> b then
    raise exception 'Owner-Nachfolge hat nicht gegriffen';
  end if;
  if (select role from public.clan_members where user_id = b) <> 'owner' then
    raise exception 'Der Nachfolger hat die Rolle nicht bekommen';
  end if;

  -- Letztes Mitglied geht: Clan wird stillgelegt, XP bleiben beim Clan.
  perform set_config('request.jwt.claim.sub', b::text, true);
  perform public.leave_clan();
  if (select deleted_at from public.clans where id = clan) is null then
    raise exception 'Der leere Clan wurde nicht stillgelegt';
  end if;

  -- ===================================================== Profil
  perform set_config('request.jwt.claim.sub', a::text, true);
  r := public.get_profile();
  if (r->>'relation') <> 'self' or (r->>'is_me')::boolean is not true then
    raise exception 'Eigenes Profil ist nicht als solches gekennzeichnet';
  end if;
  if jsonb_array_length(r->'badges') < 4 then
    raise exception 'Badges fehlen im Profil';
  end if;
  -- Auch nicht verdiente Badges stehen drin, mit Fortschritt - sonst
  -- wuesste niemand, worauf er hinarbeitet.
  if not exists (select 1 from jsonb_array_elements(r->'badges') x
                 where (x->>'earned')::boolean is false and (x->>'need') is not null) then
    raise exception 'Offene Badges fehlen oder haben kein Ziel';
  end if;

  -- Ein Freund sieht die letzten Orte.
  r := public.get_profile(b);
  if (r->>'relation') <> 'friends' then
    raise exception 'Beziehung im fremden Profil falsch: %', r->>'relation';
  end if;
  if (r->'recent') = 'null'::jsonb then
    raise exception 'Ein Freund muss die letzten Orte sehen';
  end if;

  -- Ein Fremder sieht Zaehler, aber keine Bewegungsspur.
  perform public.remove_friend(b);
  r := public.get_profile(b);
  if (r->'recent') <> 'null'::jsonb then
    raise exception 'Ein Fremder darf die letzten Orte nicht sehen';
  end if;
  if (r->'stats'->>'beers') is null then
    raise exception 'Zaehler muessen auch fuer Fremde sichtbar sein';
  end if;

  raise notice 'Sozial ok: Invite, Anfragen, Leaderboard, Clan samt Nachfolge, Profil';
end $$;
