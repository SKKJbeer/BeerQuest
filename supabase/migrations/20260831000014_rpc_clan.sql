-- P0.9 - Clan. Bewusst einfach: erstellen, beitreten, verlassen, Mitglieder,
-- Beitrag, Ranking, Aktivitaet. Kein Chat, keine Rollen ausser Owner, keine
-- Clan Wars (docs/03-feature-matrix.md).

create or replace function public.create_clan(
  p_name text,
  p_avatar_key text default 'clan_01',
  p_avatar_color text default 'amber'
) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v_id uuid;
  v_code text;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  -- Ein Clan pro Nutzer wird vom Primaerschluessel erzwungen; die
  -- verstaendliche Meldung kommt trotzdem von hier.
  if exists (select 1 from public.clan_members where user_id = v_user) then
    raise exception 'ALREADY_IN_CLAN' using errcode = 'unique_violation';
  end if;
  if length(trim(coalesce(p_name,''))) not between 3 and 24 then
    raise exception 'CLAN_NAME_LENGTH' using errcode = 'check_violation';
  end if;
  if not public.is_term_allowed(p_name) then
    raise exception 'CLAN_NAME_NOT_ALLOWED' using errcode = 'check_violation';
  end if;
  if exists (select 1 from public.clans
             where name = trim(p_name)::extensions.citext and deleted_at is null) then
    raise exception 'CLAN_NAME_TAKEN' using errcode = 'unique_violation';
  end if;

  v_code := public.new_invite_code();
  insert into public.clans (name, avatar_key, avatar_color, join_code, owner_id, member_count)
  values (trim(p_name)::extensions.citext, coalesce(p_avatar_key,'clan_01'),
          coalesce(p_avatar_color,'amber'), v_code, v_user, 1)
  returning id into v_id;

  insert into public.clan_members (user_id, clan_id, role) values (v_user, v_id, 'owner');
  perform public.check_badges(v_user);

  return jsonb_build_object('id', v_id, 'name', trim(p_name), 'join_code', v_code);
end $$;

create or replace function public.join_clan_by_code(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare v_user uuid := auth.uid(); c public.clans;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  if exists (select 1 from public.clan_members where user_id = v_user) then
    raise exception 'ALREADY_IN_CLAN' using errcode = 'unique_violation';
  end if;

  select * into c from public.clans
   where join_code = upper(trim(p_code)) and deleted_at is null;
  if not found then
    raise exception 'CLAN_UNKNOWN' using errcode = 'no_data_found';
  end if;
  if c.member_count >= c.max_members then
    raise exception 'CLAN_FULL' using errcode = 'check_violation';
  end if;

  insert into public.clan_members (user_id, clan_id) values (v_user, c.id);
  update public.clans set member_count = member_count + 1 where id = c.id;
  perform public.check_badges(v_user);

  return jsonb_build_object('id', c.id, 'name', c.name);
end $$;

create or replace function public.leave_clan()
returns void
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  m public.clan_members;
  v_nachfolger uuid;
begin
  select * into m from public.clan_members where user_id = v_user;
  if not found then
    raise exception 'NOT_IN_CLAN' using errcode = 'no_data_found';
  end if;

  delete from public.clan_members where user_id = v_user;
  update public.clans set member_count = greatest(0, member_count - 1) where id = m.clan_id;

  -- Der Owner geht: Die Rolle wandert an das dienstaelteste Mitglied.
  -- Geht das letzte Mitglied, wird der Clan stillgelegt - die eingebrachten
  -- XP bleiben beim Clan, sie werden niemandem zurueckgegeben.
  if m.role = 'owner' then
    select user_id into v_nachfolger from public.clan_members
     where clan_id = m.clan_id order by joined_at limit 1;
    if v_nachfolger is not null then
      update public.clan_members set role = 'owner' where user_id = v_nachfolger;
      update public.clans set owner_id = v_nachfolger where id = m.clan_id;
    else
      update public.clans set deleted_at = now() where id = m.clan_id;
    end if;
  end if;
end $$;

create or replace function public.get_clan(p_clan uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  c public.clans;
  v_mitglied boolean;
begin
  if p_clan is null then
    select cl.* into c from public.clans cl
      join public.clan_members m on m.clan_id = cl.id
     where m.user_id = v_user and cl.deleted_at is null;
  else
    select * into c from public.clans where id = p_clan and deleted_at is null;
  end if;
  if not found then return null; end if;

  v_mitglied := exists (select 1 from public.clan_members
                        where user_id = v_user and clan_id = c.id);

  return jsonb_build_object(
    'id', c.id, 'name', c.name, 'avatar_key', c.avatar_key,
    'avatar_color', c.avatar_color, 'level', c.level, 'xp', c.xp,
    'member_count', c.member_count, 'max_members', c.max_members,
    'is_member', v_mitglied,
    'is_owner', c.owner_id = v_user,
    -- Der Beitrittscode geht nur an Mitglieder. Sonst waere jeder Clan
    -- fuer jeden offen, der einmal seine Seite gesehen hat.
    'join_code', case when v_mitglied then c.join_code else null end,
    'my_contribution', (select contributed_xp from public.clan_members
                        where user_id = v_user and clan_id = c.id),
    -- Der Rang wird in einer Unterabfrage berechnet: Eine Fensterfunktion
    -- darf nicht innerhalb von jsonb_agg stehen.
    'members', case when not v_mitglied then null else coalesce((
      select jsonb_agg(jsonb_build_object(
        'user_id', t.id, 'username', t.username,
        'avatar_key', t.avatar_key, 'avatar_color', t.avatar_color,
        'level', t.level, 'contributed_xp', t.contributed_xp,
        'role', t.role, 'is_me', t.id = v_user, 'rank', t.rang)
        order by t.rang)
      from (
        select p.id, p.username::text as username, p.avatar_key, p.avatar_color,
               p.level, mm.contributed_xp, mm.role,
               rank() over (order by mm.contributed_xp desc, p.username) as rang
        from public.clan_members mm
        join public.profiles p on p.id = mm.user_id and p.deleted_at is null
        where mm.clan_id = c.id
      ) t), '[]'::jsonb) end
  );
end $$;

create or replace function public.get_clan_activity(p_limit int default 10)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.at desc), '[]'::jsonb)
  from (
    select p.username::text as "user", p.avatar_key, p.avatar_color,
           d.kind::text as kind, d.discovered_at as at,
           case d.kind
             when 'beer'  then (select name from public.beers    where id = d.entity_id::uuid)
             when 'venue' then (select name from public.venues   where id = d.entity_id::uuid)
             when 'city'  then (select name from public.cities   where id = d.entity_id::uuid)
             else (select name from public.countries where code = d.entity_id) end as name
    from public.user_discoveries d
    join public.clan_members m on m.user_id = d.user_id
    join public.profiles p on p.id = d.user_id and p.deleted_at is null
    where m.clan_id = (select clan_id from public.clan_members where user_id = auth.uid())
    order by d.discovered_at desc
    limit greatest(1, least(p_limit, 30))
  ) x
$$;

grant execute on function public.create_clan(text, text, text) to authenticated;
grant execute on function public.join_clan_by_code(text) to authenticated;
grant execute on function public.leave_clan() to authenticated;
grant execute on function public.get_clan(uuid) to authenticated;
grant execute on function public.get_clan_activity(int) to authenticated;
