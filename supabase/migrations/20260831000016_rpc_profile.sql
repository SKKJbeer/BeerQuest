-- P0.5 - Profil, eigenes und fremdes.

create or replace function public.get_profile(p_user uuid default null)
returns jsonb
language plpgsql stable security definer set search_path = public, extensions as $$
declare
  v_me uuid := auth.uid();
  v_id uuid := coalesce(p_user, v_me);
  p public.profiles;
  v_selbst boolean := (v_id = v_me);
  v_freund boolean;
begin
  select * into p from public.profiles where id = v_id and deleted_at is null;
  if not found then
    raise exception 'USER_UNKNOWN' using errcode = 'no_data_found';
  end if;
  v_freund := v_selbst or public.is_friend(v_me, v_id);

  return jsonb_build_object(
    'id', p.id, 'username', p.username::text, 'display_name', p.display_name,
    'avatar_key', p.avatar_key, 'avatar_color', p.avatar_color,
    'level', p.level, 'xp', p.xp,
    'xp_in_level', p.xp - public.total_xp_to_reach(p.level),
    'xp_needed', 500 * p.level,
    'is_me', v_selbst,
    'relation', case
      when v_selbst then 'self'
      when public.is_friend(v_me, v_id) then 'friends'
      when exists (select 1 from public.friend_requests r
                   where r.from_user = v_me and r.to_user = v_id
                     and r.status = 'pending') then 'requested'
      when exists (select 1 from public.friend_requests r
                   where r.from_user = v_id and r.to_user = v_me
                     and r.status = 'pending') then 'incoming'
      else 'none' end,

    -- Zaehler sind oeffentlich: Sie tragen das Leaderboard und verraten
    -- nichts darueber, WO jemand war.
    'stats', jsonb_build_object(
      'countries', public.user_metric(v_id, 'countries'),
      'cities',    public.user_metric(v_id, 'cities'),
      'venues',    public.user_metric(v_id, 'venues'),
      'beers',     public.user_metric(v_id, 'beers'),
      'quests',    public.user_metric(v_id, 'quests'),
      'check_ins', public.user_metric(v_id, 'check_ins')),

    'badges', coalesce((
      select jsonb_agg(jsonb_build_object(
        'code', bd.code, 'name', bd.name, 'description', bd.description,
        'tier', bd.tier, 'icon', bd.icon,
        'earned_at', ub.earned_at,
        'earned', ub.user_id is not null,
        'have', public.user_metric(v_id, bd.criteria->>'metric'),
        'need', (bd.criteria->>'gte')::int)
        order by (ub.user_id is null), bd.code)
      from public.badges bd
      left join public.user_badges ub on ub.code = bd.code and ub.user_id = v_id), '[]'::jsonb),

    'clan', (select jsonb_build_object('id', c.id, 'name', c.name, 'level', c.level)
             from public.clans c
             join public.clan_members m on m.clan_id = c.id
             where m.user_id = v_id and c.deleted_at is null),

    -- Die letzten Orte sieht nur, wer befreundet ist. Ein Fremder bekommt
    -- Zaehler, aber keine Bewegungsspur.
    'recent', case when not v_freund then null else coalesce((
      select jsonb_agg(jsonb_build_object(
        'beer', b.name, 'venue', v.name, 'at', c.happened_at)
        order by c.happened_at desc)
      from (select * from public.check_ins ci
             where ci.user_id = v_id order by ci.happened_at desc limit 5) c
      join public.beers b on b.id = c.beer_id
      join public.venues v on v.id = c.venue_id), '[]'::jsonb) end
  );
end $$;

grant execute on function public.get_profile(uuid) to authenticated;
