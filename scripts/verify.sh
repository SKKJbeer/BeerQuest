#!/usr/bin/env bash
# Ein Befehl prueft alles. Derselbe Befehl laeuft lokal und in der CI -
# zwei Ablaeufe wuerden auseinanderlaufen, und dann prueft der eine etwas
# anderes als der andere.
#
# Die Reihenfolge ist nach KOSTEN sortiert, nicht nach Wichtigkeit: Was in
# einer Sekunde brechen kann, soll auch in einer Sekunde brechen - und nicht
# nach zehn Minuten auf einem gemieteten Mac.
#
# Uebersprungenes wird BENANNT, nie verschwiegen. Ein Lauf, der schweigt,
# sieht aus wie ein Lauf, der geprueft hat.
#
#   ./scripts/verify.sh            alles, was hier moeglich ist
#   ./scripts/verify.sh schnell    nur die Sekunden-Pruefungen
#   ./scripts/verify.sh sql        nur die Datenbank
#   ./scripts/verify.sh ios        nur Xcode
#   ./scripts/verify.sh --melden   zusaetzlich eine Zeile in den Zweig pruefungen
set -uo pipefail
cd "$(dirname "$0")/.."

UMFANG="alles"; MELDEN=0
for a in "$@"; do
  case "$a" in
    --melden) MELDEN=1 ;;
    schnell|sql|ios|alles) UMFANG="$a" ;;
    *) echo "Unbekannt: $a"; exit 2 ;;
  esac
done

START=$(date +%s)
declare -a UEBERSPRUNGEN=()
FEHLER=0
schritt(){ printf '\n\033[1m== %s\033[0m\n' "$1"; }
uebersprungen(){ UEBERSPRUNGEN+=("$1"); printf '   uebersprungen: %s\n' "$1"; }

# ---------------------------------------------- 1. Sekunden (immer zuerst)
schritt "Tokens: App gegen Prototyp"
if command -v python3 >/dev/null; then
  python3 scripts/check-tokens.py || FEHLER=1
else
  uebersprungen "Token-Abgleich (kein python3)"
fi

schritt "Arbeitsverzeichnis"
if [ -n "$(git status --porcelain --untracked-files=no)" ]; then
  echo "   Achtung: nicht committete Aenderungen - ein Lauf 'mit Aenderungen'"
  echo "   sagt ueber den committeten Stand nichts."
else
  echo "   sauber"
fi

# ---------------------------------------------- 2. Prototyp (Sekunden)
if [ "$UMFANG" = "alles" ] || [ "$UMFANG" = "schnell" ]; then
  schritt "Prototyp"
  if [ -d node_modules/playwright ] || command -v npx >/dev/null; then
    if CHROMIUM_PATH="${CHROMIUM_PATH:-$( [ -e /opt/pw-browsers/chromium ] && echo /opt/pw-browsers/chromium )}" \
       node scripts/check-prototype.mjs; then :; else FEHLER=1; fi
  else
    uebersprungen "Prototyp-Pruefung (kein node/playwright)"
  fi
fi

# ---------------------------------------------- 3. Datenbank (Sekunden)
if [ "$UMFANG" = "alles" ] || [ "$UMFANG" = "sql" ]; then
  schritt "Datenbank"
  # Drei Faelle, und sie duerfen nicht verwechselt werden:
  #   kein psql          -> uebersprungen
  #   psql, keine Verbindung -> uebersprungen MIT GRUND, nicht rot.
  #     Ein Fehlschlag auf der eigenen Seite ist keine Auskunft ueber die
  #     Regeln, die geprueft werden sollten.
  #   Verbindung, Test faellt -> rot
  if ! command -v psql >/dev/null; then
    uebersprungen "SQL-Regeltests (kein psql)"
  elif ! psql -d postgres -c 'select 1' >/dev/null 2>&1; then
    uebersprungen "SQL-Regeltests (keine Verbindung zur Datenbank als '$(whoami)')"
    echo "   Hinweis: In diesem Container laeuft Postgres unter dem Nutzer 'postgres'."
    echo "   Dann:    su postgres -c './scripts/verify.sh sql'"
  else
    ./supabase/ci/run_local.sh "${BQ_TESTDB:-bq_verify}" || FEHLER=1
  fi
fi

# ---------------------------------------------- 4. Xcode (Minuten, zuletzt)
if [ "$UMFANG" = "alles" ] || [ "$UMFANG" = "ios" ]; then
  schritt "iOS: Build und Tests"
  if command -v xcodebuild >/dev/null; then
    [ -d BeerQuest.xcodeproj ] || { command -v xcodegen >/dev/null && xcodegen generate; }
    [ -f Config.xcconfig ] || cp Config.xcconfig.example Config.xcconfig
    SIM=$(xcrun simctl list devices available -j | python3 -c \
      "import json,sys;d=json.load(sys.stdin)['devices'];print(next(x['name'] for v in d.values() for x in v if 'iPhone' in x['name']))")
    echo "   Simulator: $SIM"
    xcodebuild test -project BeerQuest.xcodeproj -scheme BeerQuest \
      -destination "platform=iOS Simulator,name=$SIM" \
      CODE_SIGNING_ALLOWED=NO -quiet || FEHLER=1
  else
    uebersprungen "iOS-Build und Swift-Tests (kein xcodebuild - kein macOS)"
  fi
fi

# ---------------------------------------------- Ergebnis
DAUER=$(( $(date +%s) - START ))
ERGEBNIS=$([ $FEHLER -eq 0 ] && echo GRUEN || echo ROT)
printf '\n\033[1m== ERGEBNIS\033[0m\n'
echo "Umfang:  $UMFANG"
echo "Dauer:   ${DAUER}s"
echo "Status:  $ERGEBNIS"
if [ ${#UEBERSPRUNGEN[@]} -gt 0 ]; then
  echo "Nicht geprueft:"
  for u in "${UEBERSPRUNGEN[@]}"; do echo "  - $u"; done
fi
echo
echo "Fuer den Handoff:"
echo "  BUILD:  $(command -v xcodebuild >/dev/null && echo "$ERGEBNIS" || echo 'NICHT AUSGEFUEHRT (kein macOS)')"
echo "  TESTS:  $ERGEBNIS"

[ $MELDEN -eq 1 ] && scripts/melden.sh "$ERGEBNIS" "$UMFANG" "$DAUER" \
  "$(IFS=,; echo "${UEBERSPRUNGEN[*]:-nichts}")"

exit $FEHLER
