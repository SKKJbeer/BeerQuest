-- P0.5/P0.6 - Passport, Karte, Detailansichten, Historie.

create or replace function public.get_passport_summary()
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select jsonb_build_object(
    'countries', public.user_metric(auth.uid(), 'countries'),
    'cities',    public.user_metric(auth.uid(), 'cities'),
    'venues',    public.user_metric(auth.uid(), 'venues'),
    'beers',     public.user_metric(auth.uid(), 'beers'),
    'check_ins', public.user_metric(auth.uid(), 'check_ins'))
$$;

-- Eine Funktion fuer alle vier Listen. Die Oberflaeche hat vier
-- Ausgestaltungen, aber nur einen Datenpfad (docs/08-screens.md S31).
create or replace function public.get_passport(
  p_kind text,
  p_query text default null,
  p_limit int default 200
) returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.discovered_at desc), '[]'::jsonb)
  from (
    select d.entity_id as id, d.discovered_at,
           case d.kind
             when 'beer'    then (select b.name from public.beers b where b.id = d.entity_id::uuid)
             when 'venue'   then (select v.name from public.venues v where v.id = d.entity_id::uuid)
             when 'city'    then (select ci.name from public.cities ci where ci.id = d.entity_id::uuid)
             else (select co.name from public.countries co where co.code = d.entity_id)
           end as name,
           case d.kind
             when 'beer'  then (select b.brewery_name from public.beers b where b.id = d.entity_id::uuid)
             when 'venue' then (select ci.name from public.cities ci
                                 where ci.id = (select v.city_id from public.venues v
                                                 where v.id = d.entity_id::uuid))
             when 'city'  then (select co.name from public.countries co
                                 where co.code = (select ci.country_code from public.cities ci
                                                   where ci.id = d.entity_id::uuid))
             else null
           end as context,
           case d.kind
             when 'country' then (select co.flag_emoji from public.countries co
                                   where co.code = d.entity_id)
             else null
           end as flag
    from public.user_discoveries d
    where d.user_id = auth.uid()
      and d.kind::text = p_kind
    order by d.discovered_at desc
    limit greatest(1, least(p_limit, 500))
  ) x
  where nullif(trim(coalesce(p_query,'')),'') is null
     or public.norm_name(x.name) like '%' || public.norm_name(p_query) || '%'
$$;

-- Kartenpunkte. Auf Weltebene Laender mit Zaehlern, ab Stadtebene die
-- eigenen Orte - eine Weltkarte mit 200 Ortspunkten ist unlesbar und
-- schickt Daten, die niemand sieht (Egress, docs/10-risks.md R9).
create or replace function public.get_map_pins(p_zoom int default 3)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select case when p_zoom < 6 then
    -- Erst gruppieren, dann verpacken: Aggregate duerfen nicht ineinander
    -- geschachtelt werden.
    coalesce((select jsonb_agg(jsonb_build_object(
        'kind', 'country', 'code', t.code, 'name', t.name,
        'flag', t.flag, 'lat', t.lat, 'lon', t.lon,
        'venues', t.venues, 'beers', t.beers) order by t.name)
      from (
        select co.code, co.name, co.flag_emoji as flag, co.lat, co.lon,
               count(distinct ci.venue_id) as venues,
               count(distinct ci.beer_id) as beers
        from public.check_ins ci
        join public.countries co on co.code = ci.country_code
        where ci.user_id = auth.uid()
        group by co.code, co.name, co.flag_emoji, co.lat, co.lon
      ) t), '[]'::jsonb)
  else
    coalesce((select jsonb_agg(jsonb_build_object(
        'kind', 'venue', 'id', v.id, 'name', v.name,
        'category', v.category::text, 'lat', v.lat, 'lon', v.lon,
        'visits', (select count(*) from public.check_ins c2
                   where c2.user_id = auth.uid() and c2.venue_id = v.id))
        order by v.name)
      from public.venues v
      where v.status = 'active'
        and exists (select 1 from public.check_ins c
                    where c.user_id = auth.uid() and c.venue_id = v.id)), '[]'::jsonb)
  end
$$;

create or replace function public.get_venue_detail(p_venue uuid)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select jsonb_build_object(
    'id', v.id, 'name', v.name, 'category', v.category::text,
    'lat', v.lat, 'lon', v.lon,
    'city', (select ci.name from public.cities ci where ci.id = v.city_id),
    'country', (select co.name from public.countries co where co.code = v.country_code),
    'flag', (select co.flag_emoji from public.countries co where co.code = v.country_code),
    'visits', (select count(*) from public.check_ins c
               where c.user_id = auth.uid() and c.venue_id = v.id),
    'beers', coalesce((
      select jsonb_agg(distinct jsonb_build_object('id', b.id, 'name', b.name))
      from public.check_ins c
      join public.beers b on b.id = c.beer_id
      where c.user_id = auth.uid() and c.venue_id = v.id), '[]'::jsonb))
  from public.venues v
  where v.id = p_venue and v.status = 'active'
$$;

create or replace function public.get_history(p_limit int default 50)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.happened_at desc), '[]'::jsonb)
  from (
    select c.id, c.happened_at, c.local_date,
           b.name as beer, v.name as venue,
           (select ci.name from public.cities ci where ci.id = c.city_id) as city,
           (select co.flag_emoji from public.countries co where co.code = c.country_code) as flag,
           coalesce((select sum(e.amount) from public.xp_events e
                     where e.ref_type = 'check_in' and e.ref_id = c.id::text), 0)::int as xp,
           -- Loeschbar nur innerhalb von 24 Stunden. Danach haengen zu viele
           -- Folgezustaende daran, als dass eine Ruecknahme ehrlich waere.
           (c.created_at > now() - interval '24 hours') as deletable
    from public.check_ins c
    join public.beers b on b.id = c.beer_id
    join public.venues v on v.id = c.venue_id
    where c.user_id = auth.uid()
    order by c.happened_at desc
    limit greatest(1, least(p_limit, 200))
  ) x
$$;

-- Ruecknahme eines Check-ins. Die XP werden per Gegenbuchung im Ledger
-- zurueckgenommen, nicht durch Loeschen der urspruenglichen Buchung -
-- der Ledger bleibt vollstaendig und nachvollziehbar.
create or replace function public.delete_check_in(p_id uuid)
returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_user uuid := auth.uid();
  c public.check_ins;
  v_xp int;
begin
  select * into c from public.check_ins where id = p_id and user_id = v_user;
  if not found then
    raise exception 'CHECKIN_UNKNOWN' using errcode = 'no_data_found';
  end if;
  if c.created_at <= now() - interval '24 hours' then
    raise exception 'CHECKIN_TOO_OLD' using errcode = 'check_violation';
  end if;

  select coalesce(sum(amount), 0)::int into v_xp from public.xp_events
   where ref_type = 'check_in' and ref_id = p_id::text and user_id = v_user;

  if v_xp <> 0 then
    perform public.award_xp(v_user, -v_xp, 'check_in_reverted',
      'check_in', p_id::text, 'revert:' || p_id::text);
  end if;

  -- Entdeckungen, die nur an diesem Check-in hingen, fallen mit ihm weg.
  delete from public.user_discoveries
   where user_id = v_user and first_check_in = p_id;

  delete from public.check_ins where id = p_id;

  return jsonb_build_object('xp_reverted', v_xp);
end $$;

grant execute on function public.get_passport_summary() to authenticated;
grant execute on function public.get_passport(text, text, int) to authenticated;
grant execute on function public.get_map_pins(int) to authenticated;
grant execute on function public.get_venue_detail(uuid) to authenticated;
grant execute on function public.get_history(int) to authenticated;
grant execute on function public.delete_check_in(uuid) to authenticated;
