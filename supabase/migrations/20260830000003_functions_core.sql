-- P0.2 - Hilfsfunktionen der Spieloekonomie.
-- Alle spielrelevanten Werte kommen aus app_config, damit Balancing ohne
-- App-Update moeglich ist (docs/06-data-model.md §3).

create or replace function public.cfg_int(p_key text, p_default int)
returns int language sql stable as $$
  select coalesce((select (value #>> '{}')::int from public.app_config
                   where key = p_key), p_default)
$$;

create or replace function public.cfg_num(p_key text, p_default numeric)
returns numeric language sql stable as $$
  select coalesce((select (value #>> '{}')::numeric from public.app_config
                   where key = p_key), p_default)
$$;

create or replace function public.cfg_bool(p_key text, p_default boolean)
returns boolean language sql stable as $$
  select coalesce((select (value #>> '{}')::boolean from public.app_config
                   where key = p_key), p_default)
$$;

-- Normalisierung fuer Dedupe von Bier- und Ortsnamen.
-- Bewusst ohne unaccent: die Erweiterung ist nicht ueberall verfuegbar und
-- pg_trgm faengt Umlaut-Varianten in der Praxis gut genug ab.
create or replace function public.norm_name(p_text text)
returns text language sql immutable as $$
  select trim(regexp_replace(lower(coalesce(p_text,'')), '[^a-z0-9]+', ' ', 'g'))
$$;

-- Level-Kurve, identisch zu Progression.swift:
--   xp fuer Level n  = 500 * n
--   Summe bis Level n = 250 * n * (n-1)
create or replace function public.total_xp_to_reach(p_level int)
returns int language sql immutable as $$
  select 250 * p_level * (p_level - 1)
$$;

create or replace function public.level_for_xp(p_xp int)
returns int language plpgsql immutable as $$
declare
  v_per_level numeric := 500;
  v_level int;
begin
  if p_xp is null or p_xp <= 0 then return 1; end if;
  -- Geschlossene Form, danach Korrektur gegen Gleitkomma-Ungenauigkeit.
  v_level := greatest(1, floor((v_per_level/2 + sqrt((v_per_level/2)^2
              + 2 * v_per_level * p_xp)) / v_per_level)::int);
  while public.total_xp_to_reach(v_level + 1) <= p_xp loop
    v_level := v_level + 1;
  end loop;
  while v_level > 1 and public.total_xp_to_reach(v_level) > p_xp loop
    v_level := v_level - 1;
  end loop;
  return v_level;
end $$;

-- Geohash (7 Zeichen) fuer die Dedupe-Zelle bei Orten.
create or replace function public.geohash7(p_lat double precision,
                                           p_lon double precision)
returns text language plpgsql immutable as $$
declare
  base32 text := '0123456789bcdefghjkmnpqrstuvwxyz';
  lat_min double precision := -90;  lat_max double precision := 90;
  lon_min double precision := -180; lon_max double precision := 180;
  mid double precision;
  is_lon boolean := true;
  bit int := 0; ch int := 0;
  result text := '';
begin
  while length(result) < 7 loop
    if is_lon then
      mid := (lon_min + lon_max) / 2;
      if p_lon > mid then ch := ch * 2 + 1; lon_min := mid;
      else ch := ch * 2; lon_max := mid; end if;
    else
      mid := (lat_min + lat_max) / 2;
      if p_lat > mid then ch := ch * 2 + 1; lat_min := mid;
      else ch := ch * 2; lat_max := mid; end if;
    end if;
    is_lon := not is_lon;
    bit := bit + 1;
    if bit = 5 then
      result := result || substr(base32, ch + 1, 1);
      bit := 0; ch := 0;
    end if;
  end loop;
  return result;
end $$;

-- Naechstgelegene Stadt im Umkreis, gewichtet nach Einwohnerzahl.
-- Ausschliesslich eigene Daten - kein Geocoding-Anbieter, dauerhaft 0 EUR
-- (docs/04-cost-analysis.md §1).
create or replace function public.resolve_city(p_lat double precision,
                                               p_lon double precision,
                                               p_radius_m int default 60000)
returns uuid language sql stable as $$
  select c.id
  from public.cities c
  -- earth_box nutzt den GiST-Index, earth_distance prueft exakt nach.
  -- Der Operator wird explizit qualifiziert, weil das Schema 'extensions'
  -- nicht im search_path der Funktion liegt.
  where extensions.earth_box(extensions.ll_to_earth(p_lat, p_lon), p_radius_m)
        operator(extensions.@>) extensions.ll_to_earth(c.lat, c.lon)
    and extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                  extensions.ll_to_earth(c.lat, c.lon)) <= p_radius_m
  -- Gewichtung nach Einwohnerzahl: ein Vorort verliert gegen die Kernstadt,
  -- auch wenn er ein paar Kilometer naeher liegt.
  order by extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                     extensions.ll_to_earth(c.lat, c.lon))
           / greatest(1.0, log(greatest(c.population, 10)::numeric)) asc
  limit 1
$$;
