-- P0.8/P0.9/P0.10 - Freunde, Invites, Clan, Leaderboard.

-- ------------------------------------------------------------- Invites
-- Crockford-Base32 ohne I, L, O, U: Diese vier verwechselt man beim
-- Abtippen oder Vorlesen mit 1, 0 und V. Der Code wird diktiert.
create or replace function public.new_invite_code()
returns text language plpgsql as $$
declare
  alphabet text := '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
  -- Nicht "code" nennen: Die Tabelle hat eine Spalte gleichen Namens, und
  -- plpgsql bricht dann mit "column reference is ambiguous" ab.
  v_code text;
begin
  loop
    v_code := '';
    for i in 1..8 loop
      v_code := v_code || substr(alphabet, 1 + floor(random() * 32)::int, 1);
    end loop;
    exit when not exists (select 1 from public.invites i where i.code = v_code);
    exit when not exists (select 1 from public.clans c where c.join_code = v_code);
  end loop;
  return v_code;
end $$;

create or replace function public.create_invite()
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v_code text;
  v_offen int;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;

  -- Rate-Limit gegen versehentliche Schleifen im Client.
  select count(*) into v_offen from public.invites
   where inviter_id = v_user and created_at > now() - interval '1 hour';
  if v_offen >= 5 then
    raise exception 'INVITE_RATE_LIMIT' using errcode = 'check_violation';
  end if;

  -- Ein noch gueltiger Code wird wiederverwendet. Sonst haette ein Nutzer
  -- nach fuenf Antippen fuenf Codes im Umlauf und wuesste nicht, welcher gilt.
  select code into v_code from public.invites
   where inviter_id = v_user and kind = 'friend'
     and expires_at > now() + interval '1 day' and use_count < max_uses
   order by created_at desc limit 1;

  if v_code is null then
    v_code := public.new_invite_code();
    insert into public.invites (code, inviter_id, kind, expires_at)
    values (v_code, v_user, 'friend',
            now() + make_interval(days => public.cfg_int('invite.valid_days', 30)));
  end if;

  return jsonb_build_object('code', v_code,
    'expires_at', (select expires_at from public.invites where code = v_code));
end $$;

create or replace function public.redeem_invite(p_code text)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  v public.invites;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;

  select * into v from public.invites where code = upper(trim(p_code));
  if not found then
    raise exception 'INVITE_UNKNOWN' using errcode = 'no_data_found';
  end if;
  if v.expires_at <= now() then
    raise exception 'INVITE_EXPIRED' using errcode = 'check_violation';
  end if;
  if v.use_count >= v.max_uses then
    raise exception 'INVITE_USED_UP' using errcode = 'check_violation';
  end if;
  if v.inviter_id = v_user then
    raise exception 'INVITE_OWN' using errcode = 'check_violation';
  end if;
  if public.is_friend(v_user, v.inviter_id) then
    return jsonb_build_object('already_friends', true,
      'user', (select username from public.profiles where id = v.inviter_id));
  end if;

  insert into public.friendships (user_low, user_high)
  values (least(v_user, v.inviter_id), greatest(v_user, v.inviter_id));
  update public.invites set use_count = use_count + 1 where code = v.code;

  perform public.award_xp(v_user, public.cfg_int('xp.friendship', 25),
    'friendship', 'user', v.inviter_id::text,
    'friend:' || v_user::text || ':' || v.inviter_id::text);
  perform public.award_xp(v.inviter_id, public.cfg_int('xp.friendship', 25),
    'friendship', 'user', v_user::text,
    'friend:' || v.inviter_id::text || ':' || v_user::text);
  perform public.check_badges(v_user);
  perform public.check_badges(v.inviter_id);

  return jsonb_build_object('already_friends', false,
    'user', (select username from public.profiles where id = v.inviter_id));
end $$;

-- -------------------------------------------------------------- Freunde
create or replace function public.search_users(p_query text, p_limit int default 10)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.username), '[]'::jsonb)
  from (
    select p.id, p.username::text, p.avatar_key, p.avatar_color, p.level,
           case
             when public.is_friend(auth.uid(), p.id) then 'friends'
             when exists (select 1 from public.friend_requests r
                          where r.from_user = auth.uid() and r.to_user = p.id
                            and r.status = 'pending') then 'requested'
             when exists (select 1 from public.friend_requests r
                          where r.from_user = p.id and r.to_user = auth.uid()
                            and r.status = 'pending') then 'incoming'
             else 'none'
           end as relation
    from public.profiles p
    where p.deleted_at is null
      and p.id <> auth.uid()
      and length(trim(coalesce(p_query,''))) >= 2
      and p.username::text like lower(trim(p_query)) || '%'
    order by p.username
    limit greatest(1, least(p_limit, 25))
  ) x
$$;

create or replace function public.send_friend_request(p_user uuid)
returns void
language plpgsql security definer set search_path = public, extensions as $$
declare v_user uuid := auth.uid(); v_heute int;
begin
  if v_user is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'insufficient_privilege';
  end if;
  if p_user = v_user then
    raise exception 'FRIEND_SELF' using errcode = 'check_violation';
  end if;
  if not exists (select 1 from public.profiles where id = p_user and deleted_at is null) then
    raise exception 'USER_UNKNOWN' using errcode = 'no_data_found';
  end if;
  if public.is_friend(v_user, p_user) then
    raise exception 'ALREADY_FRIENDS' using errcode = 'unique_violation';
  end if;

  select count(*) into v_heute from public.friend_requests
   where from_user = v_user and created_at > now() - interval '1 day';
  if v_heute >= 20 then
    raise exception 'FRIEND_RATE_LIMIT' using errcode = 'check_violation';
  end if;

  -- Wenn die Gegenseite bereits angefragt hat, ist ein zweiter Antrag
  -- unsinnig - das ist eine Zusage.
  if exists (select 1 from public.friend_requests
             where from_user = p_user and to_user = v_user and status = 'pending') then
    perform public.respond_friend_request(
      (select id from public.friend_requests
        where from_user = p_user and to_user = v_user and status = 'pending'), true);
    return;
  end if;

  insert into public.friend_requests (from_user, to_user)
  values (v_user, p_user)
  on conflict do nothing;
end $$;

create or replace function public.respond_friend_request(p_id uuid, p_accept boolean)
returns void
language plpgsql security definer set search_path = public, extensions as $$
declare v_user uuid := auth.uid(); r public.friend_requests;
begin
  select * into r from public.friend_requests
   where id = p_id and to_user = v_user and status = 'pending';
  if not found then
    raise exception 'REQUEST_NOT_PENDING' using errcode = 'no_data_found';
  end if;

  update public.friend_requests
     set status = case when p_accept then 'accepted' else 'declined' end::public.request_status,
         responded_at = now()
   where id = p_id;

  if p_accept then
    insert into public.friendships (user_low, user_high)
    values (least(v_user, r.from_user), greatest(v_user, r.from_user))
    on conflict do nothing;
    perform public.award_xp(v_user, public.cfg_int('xp.friendship', 25),
      'friendship', 'user', r.from_user::text,
      'friend:' || v_user::text || ':' || r.from_user::text);
    perform public.award_xp(r.from_user, public.cfg_int('xp.friendship', 25),
      'friendship', 'user', v_user::text,
      'friend:' || r.from_user::text || ':' || v_user::text);
    perform public.check_badges(v_user);
    perform public.check_badges(r.from_user);
  end if;
end $$;

create or replace function public.get_friends()
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.week_xp desc, x.username), '[]'::jsonb)
  from (
    select p.id, p.username::text, p.avatar_key, p.avatar_color, p.level, p.xp,
           coalesce((select sum(e.amount) from public.xp_events e
                     where e.user_id = p.id
                       and e.created_at >= date_trunc('week', now())), 0)::int as week_xp
    from public.friendships f
    join public.profiles p
      on p.id = case when f.user_low = auth.uid() then f.user_high else f.user_low end
    where (f.user_low = auth.uid() or f.user_high = auth.uid())
      and p.deleted_at is null
  ) x
$$;

create or replace function public.get_friend_requests()
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id, 'user_id', p.id, 'username', p.username::text,
    'avatar_key', p.avatar_key, 'avatar_color', p.avatar_color,
    'level', p.level, 'created_at', r.created_at) order by r.created_at desc), '[]'::jsonb)
  from public.friend_requests r
  join public.profiles p on p.id = r.from_user
  where r.to_user = auth.uid() and r.status = 'pending' and p.deleted_at is null
$$;

create or replace function public.remove_friend(p_user uuid)
returns void
language sql security definer set search_path = public, extensions as $$
  delete from public.friendships
   where user_low = least(auth.uid(), p_user)
     and user_high = greatest(auth.uid(), p_user)
$$;

-- ----------------------------------------------------------- Leaderboard
-- Voreinstellung ist die Woche. All-Time waere fuer neue Nutzer tot: Wer
-- drei Monate spaeter anfaengt, holt den Vorsprung nie auf (docs/01-analysis.md 1.5).
create or replace function public.get_leaderboard_friends(p_range text default 'week')
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  with mich_und_freunde as (
    select auth.uid() as id
    union
    select case when f.user_low = auth.uid() then f.user_high else f.user_low end
    from public.friendships f
    where f.user_low = auth.uid() or f.user_high = auth.uid()
  ),
  werte as (
    select p.id, p.username::text, p.avatar_key, p.avatar_color, p.level,
           case when p_range = 'all' then p.xp else
             coalesce((select sum(e.amount) from public.xp_events e
                       where e.user_id = p.id
                         and e.created_at >= date_trunc('week', now())), 0)::int
           end as wert
    from mich_und_freunde m
    join public.profiles p on p.id = m.id and p.deleted_at is null
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'rank', rang, 'user_id', id, 'username', username,
    'avatar_key', avatar_key, 'avatar_color', avatar_color,
    'level', level, 'xp', wert, 'is_me', id = auth.uid()) order by rang), '[]'::jsonb)
  from (select *, rank() over (order by wert desc, username) as rang from werte) t
$$;

grant execute on function public.create_invite() to authenticated;
grant execute on function public.redeem_invite(text) to authenticated;
grant execute on function public.search_users(text, int) to authenticated;
grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean) to authenticated;
grant execute on function public.get_friends() to authenticated;
grant execute on function public.get_friend_requests() to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.get_leaderboard_friends(text) to authenticated;
