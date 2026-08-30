-- P0.2 - Row Level Security.
--
-- Grundsatz: Fuer die Rolle `authenticated` gibt es auf KEINER Tabelle eine
-- insert-, update- oder delete-Policy. Jeder Schreibvorgang laeuft durch eine
-- SECURITY DEFINER-Funktion mit auth.uid()-Pruefung. Das ist der Grund,
-- warum XP nicht manipulierbar sind, ohne dass wir eine eigene API-Schicht
-- betreiben muessten (docs/05-architecture.md §10).

do $$
declare t text;
begin
  foreach t in array array[
    'countries','cities','venues','beers','profiles','check_ins',
    'user_discoveries','xp_events','quest_templates','quests',
    'quest_participants','friendships','friend_requests','invites',
    'clans','clan_members','badges','user_badges','app_events'
  ] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Hilfsfunktion: sind zwei Nutzer befreundet?
create or replace function public.is_friend(a uuid, b uuid)
returns boolean language sql stable security definer
set search_path = public, extensions as $$
  select exists (select 1 from public.friendships
                 where user_low = least(a, b) and user_high = greatest(a, b))
$$;

-- ---------------------------------------------------------- Referenzdaten
-- Fuer alle Eingeloggten lesbar, fuer niemanden schreibbar.
drop policy if exists countries_read on public.countries;
create policy countries_read on public.countries
  for select to authenticated using (true);

drop policy if exists cities_read on public.cities;
create policy cities_read on public.cities
  for select to authenticated using (true);

drop policy if exists venues_read on public.venues;
create policy venues_read on public.venues
  for select to authenticated using (status = 'active');

drop policy if exists beers_read on public.beers;
create policy beers_read on public.beers
  for select to authenticated using (status = 'active');

drop policy if exists badges_read on public.badges;
create policy badges_read on public.badges
  for select to authenticated using (true);

drop policy if exists quest_templates_read on public.quest_templates;
create policy quest_templates_read on public.quest_templates
  for select to authenticated using (active);

-- ---------------------------------------------------------------- Profile
-- Oeffentlich sichtbar sind nur Username, Avatar, Level und XP - das
-- Leaderboard braucht sie. Geburtsjahr und E-Mail werden nie ausgeliefert
-- (der Client fragt gezielte Spalten ab, RPCs geben nur Erlaubtes zurueck).
drop policy if exists profiles_read on public.profiles;
create policy profiles_read on public.profiles
  for select to authenticated using (deleted_at is null);

-- --------------------------------------------------------------- Eigenes
drop policy if exists check_ins_read on public.check_ins;
create policy check_ins_read on public.check_ins
  for select to authenticated
  using (user_id = auth.uid() or public.is_friend(auth.uid(), user_id));

drop policy if exists user_discoveries_read on public.user_discoveries;
create policy user_discoveries_read on public.user_discoveries
  for select to authenticated
  using (user_id = auth.uid() or public.is_friend(auth.uid(), user_id));

drop policy if exists xp_events_read on public.xp_events;
create policy xp_events_read on public.xp_events
  for select to authenticated using (user_id = auth.uid());

drop policy if exists user_badges_read on public.user_badges;
create policy user_badges_read on public.user_badges
  for select to authenticated using (true);

drop policy if exists quests_read on public.quests;
create policy quests_read on public.quests
  for select to authenticated
  using (owner_id = auth.uid()
         or exists (select 1 from public.quest_participants p
                    where p.quest_id = quests.id and p.user_id = auth.uid()));

drop policy if exists quest_participants_read on public.quest_participants;
create policy quest_participants_read on public.quest_participants
  for select to authenticated
  using (user_id = auth.uid()
         or exists (select 1 from public.quests q
                    where q.id = quest_participants.quest_id
                      and q.owner_id = auth.uid()));

drop policy if exists friendships_read on public.friendships;
create policy friendships_read on public.friendships
  for select to authenticated
  using (user_low = auth.uid() or user_high = auth.uid());

drop policy if exists friend_requests_read on public.friend_requests;
create policy friend_requests_read on public.friend_requests
  for select to authenticated
  using (from_user = auth.uid() or to_user = auth.uid());

drop policy if exists invites_read on public.invites;
create policy invites_read on public.invites
  for select to authenticated using (inviter_id = auth.uid());

-- ------------------------------------------------------------------ Clan
-- Clans sind oeffentlich auffindbar (Leaderboard, Beitritt); die
-- Mitgliederliste sieht nur, wer selbst Mitglied ist.
drop policy if exists clans_read on public.clans;
create policy clans_read on public.clans
  for select to authenticated using (deleted_at is null);

drop policy if exists clan_members_read on public.clan_members;
create policy clan_members_read on public.clan_members
  for select to authenticated
  using (clan_id in (select clan_id from public.clan_members
                     where user_id = auth.uid()));

-- app_events ist reine Telemetrie: schreibt nur der Server, liest niemand.
-- Bewusst ohne select-Policy - damit ist die Tabelle fuer Clients unsichtbar.

grant usage on schema public to authenticated;
grant select on public.countries, public.cities, public.venues, public.beers,
                public.badges, public.quest_templates, public.profiles,
                public.check_ins, public.user_discoveries, public.xp_events,
                public.user_badges, public.quests, public.quest_participants,
                public.friendships, public.friend_requests, public.invites,
                public.clans, public.clan_members, public.app_config
  to authenticated;

-- Funktionsrechte: Postgres vergibt EXECUTE standardmaessig an PUBLIC, und
-- `authenticated` erbt davon. Ein `revoke ... from authenticated` allein
-- wirkt deshalb nicht. Richtig ist: erst allen alles entziehen, dann gezielt
-- freigeben. Sonst waere award_xp fuer jeden Client aufrufbar - also freie
-- XP-Vergabe.
do $$
declare f record;
begin
  for f in
    select p.oid::regprocedure as sig
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
  loop
    execute format('revoke all on function %s from public, anon, authenticated', f.sig);
  end loop;
end $$;

-- Nur diese vier Funktionen darf der Client aufrufen.
grant execute on function public.create_check_in(uuid, jsonb, jsonb, timestamptz, text)
  to authenticated;
grant execute on function public.checkin_reward(uuid) to authenticated;
grant execute on function public.next_goal(uuid) to authenticated;
grant execute on function public.daily_quest_code(date) to authenticated;

-- is_friend wird von den RLS-Policies aufgerufen und muss deshalb fuer die
-- Rolle ausfuehrbar bleiben, die die Policy auswertet.
grant execute on function public.is_friend(uuid, uuid) to authenticated;
