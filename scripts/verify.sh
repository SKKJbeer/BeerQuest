#!/usr/bin/env bash
# Lokales Qualitaetsgate. Fuehrt aus, was auch die CI prueft.
# Vor jedem Push einmal laufen lassen.
#
#   ./scripts/verify.sh          alles
#   ./scripts/verify.sh sql      nur Datenbank
#   ./scripts/verify.sh ios      nur Xcode
set -uo pipefail
cd "$(dirname "$0")/.."

WHAT="${1:-all}"
SQL_RESULT="UEBERSPRUNGEN"
IOS_RESULT="UEBERSPRUNGEN"

if [[ "$WHAT" == "all" || "$WHAT" == "sql" ]]; then
  echo "=============================================="
  echo " DATENBANK"
  echo "=============================================="
  if command -v psql >/dev/null 2>&1; then
    if ./supabase/ci/run_local.sh bq_verify; then SQL_RESULT="PASS"; else SQL_RESULT="FAIL"; fi
  else
    echo "psql nicht gefunden - uebersprungen."
  fi
fi

if [[ "$WHAT" == "all" || "$WHAT" == "ios" ]]; then
  echo
  echo "=============================================="
  echo " iOS BUILD + TESTS"
  echo "=============================================="
  if command -v xcodebuild >/dev/null 2>&1; then
    if [[ ! -d BeerQuest.xcodeproj ]]; then
      echo "-> Projekt fehlt, erzeuge es"
      command -v xcodegen >/dev/null 2>&1 && xcodegen generate
    fi
    if xcodebuild test \
        -project BeerQuest.xcodeproj \
        -scheme BeerQuest \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -quiet CODE_SIGNING_ALLOWED=NO; then
      IOS_RESULT="PASS"
    else
      IOS_RESULT="FAIL"
    fi
  else
    echo "xcodebuild nicht gefunden (kein macOS) - uebersprungen."
  fi
fi

echo
echo "=============================================="
echo " ERGEBNIS"
echo "=============================================="
echo "TESTS (SQL):        $SQL_RESULT"
echo "BUILD/TESTS (iOS):  $IOS_RESULT"
echo
echo "Diese beiden Zeilen gehoeren so in docs/HANDOFF.md."

[[ "$SQL_RESULT" == "FAIL" || "$IOS_RESULT" == "FAIL" ]] && exit 1
exit 0
