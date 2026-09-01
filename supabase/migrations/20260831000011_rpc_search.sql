-- P0.4 - Suche fuer den Check-in-Flow.
--
-- Die Bier-Suche ist keine Bequemlichkeit, sondern die Gegenmassnahme zu
-- Risiko R12: Wer "Peroni" tippt und die Varianten nicht vorgeschlagen
-- bekommt, legt eine Dublette an. Das Dedupe im Server greift nur bei
-- gleicher normalisierter Identitaet - alles davor muss die Suche leisten.

create or replace function public.search_beers(
  p_query text,
  p_limit int default 12
) returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  with q as (select public.norm_name(p_query) as term),
  treffer as (
    select b.id, b.name, b.brewery_name,
           (select count(*) from public.check_ins c where c.beer_id = b.id) as beliebtheit,
           case
             when b.name_norm = q.term then 0                    -- exakt
             when b.name_norm like q.term || ' %' then 1         -- Praefix am Wortanfang
             when b.name_norm like q.term || '%'  then 2         -- Praefix
             when b.name_norm like '% ' || q.term || '%' then 3  -- Wort im Namen
             else 4                                              -- nur aehnlich
           end as rang,
           -- word_similarity statt similarity: Die Eingabe ist kurz, der
           -- Biername lang. similarity('peronni','peroni nastro azzurro')
           -- ist 0,26 und faellt durch jede sinnvolle Schwelle -
           -- word_similarity ist 0,67. Derselbe Fall wie beim Orts-Dedupe.
           extensions.word_similarity(q.term, b.name_norm) as naehe
    from public.beers b, q
    where b.status = 'active'
      and length(q.term) >= 2
      and (b.name_norm like '%' || q.term || '%'
           or extensions.word_similarity(q.term, b.name_norm) >= 0.6)
  )
  select coalesce(jsonb_agg(x order by x.rang, x.beliebtheit desc, x.naehe desc, x.name), '[]'::jsonb)
  from (
    select id, name, brewery_name, rang, beliebtheit, naehe from treffer
    order by rang, beliebtheit desc, naehe desc, name
    limit greatest(1, least(p_limit, 30))
  ) x
$$;

-- Zuletzt getrunkene Biere - der wahrscheinlichste naechste Treffer.
create or replace function public.recent_beers(p_limit int default 5)
returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.zuletzt desc), '[]'::jsonb)
  from (
    select b.id, b.name, b.brewery_name, max(c.happened_at) as zuletzt
    from public.check_ins c
    join public.beers b on b.id = c.beer_id
    where c.user_id = auth.uid() and b.status = 'active'
    group by b.id, b.name, b.brewery_name
    order by max(c.happened_at) desc
    limit greatest(1, least(p_limit, 20))
  ) x
$$;

-- Orte im Umkreis. Ausschliesslich eigene Daten - keine Apple-POI-Vorschlaege
-- (Apple Maps ToS §1.3 vi, siehe docs/10-risks.md R2).
create or replace function public.search_venues_nearby(
  p_lat double precision,
  p_lon double precision,
  p_query text default null,
  p_radius_m int default 1500,
  p_limit int default 12
) returns jsonb
language sql stable security definer set search_path = public, extensions as $$
  select coalesce(jsonb_agg(x order by x.entfernung), '[]'::jsonb)
  from (
    select v.id, v.name, v.category::text as category,
           round(extensions.earth_distance(
             extensions.ll_to_earth(p_lat, p_lon),
             extensions.ll_to_earth(v.lat, v.lon))::numeric) as entfernung,
           (select name from public.cities ci where ci.id = v.city_id) as city,
           v.country_code
    from public.venues v
    where v.status = 'active'
      and extensions.earth_box(extensions.ll_to_earth(p_lat, p_lon), p_radius_m)
          operator(extensions.@>) extensions.ll_to_earth(v.lat, v.lon)
      and extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                    extensions.ll_to_earth(v.lat, v.lon)) <= p_radius_m
      and (nullif(trim(coalesce(p_query,'')),'') is null
           or v.name_norm like '%' || public.norm_name(p_query) || '%'
           or extensions.similarity(v.name_norm, public.norm_name(p_query)) >= 0.4)
    order by extensions.earth_distance(extensions.ll_to_earth(p_lat, p_lon),
                                       extensions.ll_to_earth(v.lat, v.lon))
    limit greatest(1, least(p_limit, 30))
  ) x
$$;

grant execute on function public.search_beers(text, int) to authenticated;
grant execute on function public.recent_beers(int) to authenticated;
grant execute on function public.search_venues_nearby(
  double precision, double precision, text, int, int) to authenticated;
