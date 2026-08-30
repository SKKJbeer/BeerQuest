-- P0.2 - Anlage und Dedupe von Bieren und Orten.
--
-- Wichtig: Orte entstehen ausschliesslich aus Nutzereingabe plus der
-- Geraetekoordinate. Es werden KEINE Apple-POI-Daten uebernommen -
-- Apple Maps ToS §1.3 (vi), siehe docs/10-risks.md R2.

create or replace function public.find_or_create_beer(
  p_name text, p_brewery text default null, p_user uuid default null)
returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_name_norm text := public.norm_name(p_name);
  v_brew_norm text := nullif(public.norm_name(p_brewery), '');
  v_id uuid;
begin
  if length(v_name_norm) < 2 then
    raise exception 'BEER_NAME_TOO_SHORT' using errcode = 'check_violation';
  end if;
  if length(p_name) > 80 then
    raise exception 'BEER_NAME_TOO_LONG' using errcode = 'check_violation';
  end if;

  -- Exakter Treffer auf der normalisierten Identitaet.
  select id into v_id from public.beers
   where name_norm = v_name_norm
     and coalesce(brewery_norm,'') = coalesce(v_brew_norm,'')
     and status = 'active';
  if v_id is not null then return v_id; end if;

  -- Ohne Brauereiangabe: ein bestehendes Bier gleichen Namens uebernehmen,
  -- statt eine Dublette anzulegen.
  if v_brew_norm is null then
    select id into v_id from public.beers
     where name_norm = v_name_norm and status = 'active'
     order by created_at limit 1;
    if v_id is not null then return v_id; end if;
  end if;

  insert into public.beers (name, name_norm, brewery_name, brewery_norm, created_by)
  values (trim(p_name), v_name_norm, nullif(trim(coalesce(p_brewery,'')),''),
          v_brew_norm, p_user)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.find_or_create_venue(
  p_name text,
  p_category public.venue_category,
  p_lat double precision,
  p_lon double precision,
  p_user uuid default null)
returns uuid
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_name_norm text := public.norm_name(p_name);
  v_id uuid;
  v_city uuid;
  v_country char(2);
begin
  if length(v_name_norm) < 2 then
    raise exception 'VENUE_NAME_TOO_SHORT' using errcode = 'check_violation';
  end if;
  if p_lat is null or p_lon is null
     or p_lat not between -90 and 90 or p_lon not between -180 and 180 then
    raise exception 'VENUE_COORDS_INVALID' using errcode = 'check_violation';
  end if;

  -- Dedupe: aehnlicher Name innerhalb von 150 m gilt als derselbe Ort.
  -- Ohne diese Regel zerfaellt die Karte in Karteileichen und zwei Nutzer
  -- bekommen zweimal XP fuer denselben Biergarten (docs/10-risks.md R7).
  select v.id into v_id
  from public.venues v
  where v.status = 'active'
    and extensions.earth_box(extensions.ll_to_earth(p_lat, p_lon), 150)
        operator(extensions.@>) extensions.ll_to_earth(v.lat, v.lon)
    and extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                  extensions.ll_to_earth(v.lat, v.lon)) <= 150
    and (
      -- Tippfehler und Varianten
      extensions.similarity(v.name_norm, v_name_norm) >= 0.6
      -- Zusatzwoerter: "Augustiner Keller" vs "Augustiner Keller Muenchen".
      -- word_similarity ist asymmetrisch, deshalb in beide Richtungen.
      -- Die Mindestlaenge verhindert, dass ein Ort namens "Bar" mit jedem
      -- "Bar Irgendwas" verschmilzt.
      or (length(v_name_norm) >= 5 and length(v.name_norm) >= 5
          and greatest(extensions.word_similarity(v.name_norm, v_name_norm),
                       extensions.word_similarity(v_name_norm, v.name_norm)) >= 0.9)
    )
  order by greatest(extensions.similarity(v.name_norm, v_name_norm),
                    extensions.word_similarity(v.name_norm, v_name_norm),
                    extensions.word_similarity(v_name_norm, v.name_norm)) desc
  limit 1;
  if v_id is not null then return v_id; end if;

  v_city := public.resolve_city(p_lat, p_lon);
  if v_city is not null then
    select country_code into v_country from public.cities where id = v_city;
  end if;
  if v_country is null then
    -- Ohne Stadt keine Landzuordnung: naechstgelegenes Landzentrum.
    -- Grob, aber besser als ein Check-in ohne Land.
    select code into v_country from public.countries
     order by extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                        extensions.ll_to_earth(lat, lon))
     limit 1;
  end if;
  if v_country is null then
    raise exception 'NO_COUNTRY_DATA' using errcode = 'no_data_found';
  end if;

  insert into public.venues
    (city_id, country_code, name, name_norm, category, lat, lon, geohash7, created_by)
  values
    (v_city, v_country, trim(p_name), v_name_norm, coalesce(p_category,'bar'),
     round(p_lat::numeric, 5), round(p_lon::numeric, 5),
     public.geohash7(p_lat, p_lon), p_user)
  returning id into v_id;
  return v_id;
end $$;
