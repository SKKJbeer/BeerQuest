#!/usr/bin/env bash
# Laedt den vollstaendigen Staedte- und Laendersatz von GeoNames.
#
# Lizenz: CC BY 4.0 - die Namensnennung gehoert in die App (Settings -> About).
# Kosten: 0 EUR, einmaliger Download (~15 MB). Es gibt bewusst keinen
# Geocoding-Anbieter, siehe docs/04-cost-analysis.md §1.
#
# Aufruf:  ./import_geonames.sh "postgresql://..."
set -euo pipefail
DB_URL="${1:?Aufruf: ./import_geonames.sh <postgres-url>}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "== Download"
curl -sSfL -o "$WORK/cities15000.zip" https://download.geonames.org/export/dump/cities15000.zip
curl -sSfL -o "$WORK/countryInfo.txt" https://download.geonames.org/export/dump/countryInfo.txt
unzip -q -o "$WORK/cities15000.zip" -d "$WORK"

echo "== Aufbereiten"
# countryInfo.txt: Kommentarzeilen entfernen, Spalten 1 (ISO) und 5 (Name).
grep -v '^#' "$WORK/countryInfo.txt" | awk -F'\t' 'NF>4 && $1!="" {print $1"\t"$5}' \
  > "$WORK/countries.tsv"
# cities15000.txt: geonameid, name, lat, lon, country, population, timezone
awk -F'\t' '$15 >= 15000 {print $1"\t"$2"\t"$5"\t"$6"\t"$9"\t"$15"\t"$18}' \
  "$WORK/cities15000.txt" > "$WORK/cities.tsv"

echo "== Import"
psql "$DB_URL" -v ON_ERROR_STOP=1 <<SQL
create temp table _c (code text, name text);
create temp table _ci (geonames_id int, name text, lat double precision,
                       lon double precision, code text, population int, tz text);
\copy _c  from '$WORK/countries.tsv' with (format csv, delimiter E'\t', quote E'\b')
\copy _ci from '$WORK/cities.tsv'    with (format csv, delimiter E'\t', quote E'\b')

-- Flaggen-Emoji aus dem ISO-Code berechnen: zwei Regional Indicator Symbols.
-- Spart eine gepflegte Datentabelle.
insert into public.countries (code, name, flag_emoji, lat, lon)
select c.code, c.name,
       chr(127462 + ascii(substr(c.code,1,1)) - 65)
       || chr(127462 + ascii(substr(c.code,2,1)) - 65),
       coalesce(avg(ci.lat), 0), coalesce(avg(ci.lon), 0)
from _c c left join _ci ci on ci.code = c.code
where length(c.code) = 2
group by c.code, c.name
on conflict (code) do nothing;

insert into public.cities
  (country_code, name, name_norm, lat, lon, population, timezone, geonames_id)
select ci.code, ci.name, public.norm_name(ci.name), ci.lat, ci.lon,
       ci.population, nullif(ci.tz,''), ci.geonames_id
from _ci ci
where exists (select 1 from public.countries co where co.code = ci.code)
on conflict (geonames_id) do nothing;

select 'Laender: ' || (select count(*) from public.countries)
    || ', Staedte: ' || (select count(*) from public.cities) as ergebnis;
SQL
echo "== Fertig. Attribution nicht vergessen: GeoNames, CC BY 4.0"
