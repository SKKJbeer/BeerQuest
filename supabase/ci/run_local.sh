#!/usr/bin/env bash
# Vollstaendiger Durchlauf gegen eine frische Datenbank:
# Bootstrap -> Migrationen -> Migrationen erneut (Idempotenz) -> Seeds -> Tests.
# Genau das, was auch die CI macht.
set -euo pipefail
DB="${1:-bq_test}"
PSQL="psql -q -v ON_ERROR_STOP=1 -d $DB"

echo "== Datenbank $DB neu anlegen"
psql -q -d postgres -c "drop database if exists $DB" -c "create database $DB"

echo "== Bootstrap (nur lokal/CI, bildet Supabase-Rollen und auth nach)"
$PSQL -f supabase/ci/bootstrap.sql

echo "== Migrationen"
for f in supabase/migrations/*.sql; do echo "   $f"; $PSQL -f "$f"; done

echo "== Migrationen erneut (Idempotenz)"
for f in supabase/migrations/*.sql; do $PSQL -f "$f" > /dev/null; done

echo "== Seeds"
for f in supabase/seed/*.sql; do echo "   $f"; $PSQL -f "$f"; done

echo "== Tests"
for f in supabase/tests/*.sql; do echo "   $f"; $PSQL -f "$f"; done

echo "== Alle Pruefungen bestanden"
