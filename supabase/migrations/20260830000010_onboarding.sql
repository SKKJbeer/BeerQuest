-- P0.3 (Serverteil) - Onboarding.
-- Alterspruefung, Username-Vergabe, Erst-Quest und Invite-Einloesung
-- laufen serverseitig in einer Transaktion.

insert into public.app_config (key, value) values
  ('age.min_years', '18'::jsonb),
  ('invite.valid_days', '30'::jsonb)
on conflict (key) do nothing;

-- Wortfilter. Bewusst eine Tabelle statt einer Konstante im Code: Die Liste
-- ist Redaktionsarbeit und muss ohne App-Update pflegbar sein.
-- Der hier eingetragene Satz ist ein Grundstock; die vollstaendige Liste
-- (~200 Begriffe, mehrsprachig) ist ein offener Punkt vor dem externen Test.
create table if not exists public.banned_terms (
  term text primary key,
  note text
);

insert into public.banned_terms (term, note) values
  ('admin','Rollenanmassung'), ('administrator','Rollenanmassung'),
  ('moderator','Rollenanmassung'), ('support','Rollenanmassung'),
  ('beerquest','Markenschutz'),   ('beer_quest','Markenschutz'),
  ('official','Rollenanmassung'), ('staff','Rollenanmassung'),
  ('system','reserviert'),        ('null','reserviert'),
  ('undefined','reserviert'),     ('anonymous','reserviert')
on conflict (term) do nothing;

alter table public.banned_terms enable row level security;
-- Bewusst ohne select-Policy: Die Liste ist fuer Clients unsichtbar.

create or replace function public.is_term_allowed(p_text text)
returns boolean
language sql stable security definer set search_path = public, extensions as $$
  select not exists (
    select 1 from public.banned_terms b
    where public.norm_name(p_text) = b.term
       or public.norm_name(p_text) like '%' || b.term || '%'
  )
$$;

-- Live-Pruefung im Onboarding. Gibt einen Grund zurueck, damit die UI
-- "taken" von "not allowed" unterscheiden kann.
create or replace function public.check_username(p_username text)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare v_norm text := lower(trim(coalesce(p_username, '')));
begin
  if v_norm !~ '^[a-z0-9_]{3,20}$' then
    return jsonb_build_object('available', false, 'reason', 'format');
  end if;
  if not public.is_term_allowed(v_norm) then
    return jsonb_build_object('available', false, 'reason', 'not_allowed');
  end if;
  if exists (select 1 from public.profiles where username = v_norm::extensions.citext) then
    return jsonb_build_object('available', false, 'reason', 'taken');
  end if;
  return jsonb_build_object('available', true, 'reason', null);
end $$;

-- Legt das Profil an. Der Client kann die Altersgrenze nicht umgehen:
-- die Pruefung passiert hier, nicht im Age-Gate-Screen.
create or replace function public.complete_onboarding(
  p_username     text,
  p_birth_year   int,
  p_avatar_key   text default 'mug_01',
  p_avatar_color text default 'amber',
  p_country      char(2) default null,
  p_invite_code  text default null
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v_check jsonb;
  v_min_age int := public.cfg_int('age.min_years', 18);
  v_age int;
  v_quest uuid;
  v_invite record;
  v_inviter uuid;
  v_friend boolean := false;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  if exists (select 1 from public.profiles where id = v_user) then
    raise exception 'PROFILE_EXISTS' using errcode = 'unique_violation';
  end if;

  -- Alterspruefung. Aus dem Geburtsjahr, nicht aus dem vollen Datum -
  -- Datenminimierung (docs/05-architecture.md §11). Die Jahresrechnung ist
  -- damit um bis zu ein Jahr konservativ, was hier die richtige Richtung ist.
  if p_birth_year is null then
    raise exception 'BIRTH_YEAR_REQUIRED' using errcode = 'check_violation';
  end if;
  v_age := extract(year from now())::int - p_birth_year;
  if v_age < v_min_age then
    raise exception 'UNDERAGE' using errcode = 'check_violation';
  end if;
  if v_age > 120 then
    raise exception 'BIRTH_YEAR_IMPLAUSIBLE' using errcode = 'check_violation';
  end if;

  v_check := public.check_username(p_username);
  if not (v_check->>'available')::boolean then
    raise exception 'USERNAME_%', upper(v_check->>'reason')
      using errcode = 'check_violation';
  end if;

  insert into public.profiles
    (id, username, avatar_key, avatar_color, birth_year, country_code)
  values
    (v_user, lower(trim(p_username))::extensions.citext,
     coalesce(p_avatar_key,'mug_01'), coalesce(p_avatar_color,'amber'),
     p_birth_year, p_country);

  -- Erst-Quest sofort annehmen. Der Nutzer soll auf Home ein Ziel sehen,
  -- nicht eine leere Liste.
  insert into public.quests
    (template_code, kind, owner_id, title, goal, xp_reward, ends_at)
  select t.code, t.kind, v_user, t.title, t.goal, t.xp_reward,
         now() + make_interval(hours => t.duration_hours)
  from public.quest_templates t where t.code = 'first_beer'
  returning id into v_quest;
  if v_quest is not null then
    insert into public.quest_participants (quest_id, user_id) values (v_quest, v_user);
  end if;

  -- Invite einloesen, falls einer mitkam.
  if nullif(trim(coalesce(p_invite_code,'')), '') is not null then
    select * into v_invite from public.invites
     where code = upper(trim(p_invite_code))
       and expires_at > now() and use_count < max_uses;
    if found and v_invite.inviter_id <> v_user then
      v_inviter := v_invite.inviter_id;
      insert into public.friendships (user_low, user_high)
      values (least(v_user, v_inviter), greatest(v_user, v_inviter))
      on conflict do nothing;
      if found then
        v_friend := true;
        update public.invites set use_count = use_count + 1 where code = v_invite.code;
        update public.profiles set invited_by = v_inviter where id = v_user;
        perform public.award_xp(v_user, public.cfg_int('xp.friendship', 25),
          'friendship', 'user', v_inviter::text,
          'friend:' || v_user::text || ':' || v_inviter::text);
        perform public.award_xp(v_inviter, public.cfg_int('xp.friendship', 25),
          'friendship', 'user', v_user::text,
          'friend:' || v_inviter::text || ':' || v_user::text);
      end if;
    end if;
  end if;

  perform public.check_badges(v_user);

  insert into public.app_events (user_id, name, props)
  values (v_user, 'onboarding_completed',
          jsonb_build_object('invited', v_friend, 'country', p_country));

  return jsonb_build_object(
    'profile_id', v_user,
    'username', lower(trim(p_username)),
    'first_quest_id', v_quest,
    'friend_added', v_friend,
    'next_goal', public.next_goal(v_user));
end $$;

grant execute on function public.check_username(text) to authenticated;
grant execute on function public.complete_onboarding(
  text, int, text, text, char, text) to authenticated;
