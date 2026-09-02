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
#   ./scripts/verify.sh --streng   Uebersprungenes zaehlt als Fehler (fuer die CI)
#   ./scripts/verify.sh --melden   zusaetzlich eine Zeile in den Zweig pruefungen
#
# KEINE Bash-Arrays in diesem Skript. Auf einem Mac ist /bin/bash die
# Version 3.2 von 2007, und dort bricht `${#ARRAY[@]}` bei leerem Array
# unter `set -u` mit "unbound variable" ab. Das Skript waere also
# ausgerechnet auf dem einzigen Rechner rot geworden, der den Xcode-Build
# ueberhaupt ausfuehren kann - ohne dass etwas am Projekt falsch gewesen
# waere. Eine Zeichenkette mit Zeilenumbruechen kann das nicht.
set -uo pipefail
cd "$(dirname "$0")/.."

UMFANG="alles"; MELDEN=0; STRENG=0
for a in "$@"; do
  case "$a" in
    --melden) MELDEN=1 ;;
    --streng) STRENG=1 ;;
    schnell|sql|ios|alles) UMFANG="$a" ;;
    *) echo "Unbekannt: $a"; exit 2 ;;
  esac
done

START=$(date +%s)
UEBERSPRUNGEN=""
FEHLER=0
schritt(){ printf '\n\033[1m== %s\033[0m\n' "$1"; }
uebersprungen(){
  UEBERSPRUNGEN="${UEBERSPRUNGEN}${1}
"
  printf '   uebersprungen: %s\n' "$1"
}

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

    # Nicht `-quiet`: Ein stiller Lauf beweist nicht, dass ein einziger Test
    # ausgefuehrt wurde. Ein Schema ohne Testziel ist genauso gruen wie eines
    # mit bestandenen Tests, und das ist der Unterschied zwischen "vorhanden"
    # und "wirkt". Die Ausgabe geht in eine Datei, hierher kommt nur die
    # Bilanz.
    mkdir -p .build
    PROTOKOLL=.build/xcodebuild.log
    xcodebuild test -project BeerQuest.xcodeproj -scheme BeerQuest \
      -destination "platform=iOS Simulator,name=$SIM" \
      CODE_SIGNING_ALLOWED=NO > "$PROTOKOLL" 2>&1 || FEHLER=1

    ANZAHL=$(grep -oE 'Executed [0-9]+ test' "$PROTOKOLL" 2>/dev/null \
             | grep -oE '[0-9]+' | sort -rn | head -1)
    ANZAHL="${ANZAHL:-0}"
    if [ "$FEHLER" -ne 0 ]; then
      echo "   Build oder Tests fehlgeschlagen. Letzte Zeilen:"
      grep -E 'error:|failed|FAILED|\*\* TEST' "$PROTOKOLL" | tail -20 | sed 's/^/   /'
      echo "   Vollstaendig: $PROTOKOLL"
    elif [ "$ANZAHL" -eq 0 ]; then
      # Gruen ohne einen einzigen Test ist kein Ergebnis, sondern eine
      # Luecke. Lieber hier rot und die Ursache nachsehen, als monatelang
      # ein Haekchen, hinter dem nichts steht.
      echo "   ROT: Build gruen, aber kein ausgefuehrter Test nachweisbar."
      echo "   Entweder haengt kein Testziel im Schema BeerQuest (project.yml),"
      echo "   oder xcodebuild formuliert seine Bilanz anders als erwartet."
      echo "   Nachsehen: grep -i 'test' $PROTOKOLL | tail -40"
      FEHLER=1
    else
      echo "   $ANZAHL Tests ausgefuehrt, keine Fehler."
    fi
  else
    uebersprungen "iOS-Build und Swift-Tests (kein xcodebuild - kein macOS)"
  fi
fi

# ---------------------------------------------- Ergebnis
DAUER=$(( $(date +%s) - START ))

# --streng: In der CI steht das Werkzeug fest. Faellt dort etwas aus, ist das
# keine Umgebungseigenheit, sondern ein kaputter Ablauf - und ein gruener
# Haken, hinter dem nichts geprueft wurde, ist schlimmer als ein roter.
if [ $STRENG -eq 1 ] && [ -n "$UEBERSPRUNGEN" ]; then
  echo
  echo "   --streng: Uebersprungenes zaehlt hier als Fehler."
  FEHLER=1
fi

ERGEBNIS=$([ $FEHLER -eq 0 ] && echo GRUEN || echo ROT)
printf '\n\033[1m== ERGEBNIS\033[0m\n'
echo "Umfang:  $UMFANG"
echo "Dauer:   ${DAUER}s"
echo "Status:  $ERGEBNIS"
if [ -n "$UEBERSPRUNGEN" ]; then
  echo "Nicht geprueft:"
  printf '%s' "$UEBERSPRUNGEN" | while IFS= read -r u; do
    [ -n "$u" ] && echo "  - $u"
  done
fi
echo
echo "Fuer den Handoff:"
echo "  BUILD:  $(command -v xcodebuild >/dev/null && echo "$ERGEBNIS" || echo 'NICHT AUSGEFUEHRT (kein macOS)')"
echo "  TESTS:  $ERGEBNIS"

if [ $MELDEN -eq 1 ]; then
  # Ein fehlgeschlagenes Melden darf nicht stillschweigend untergehen -
  # sonst sieht der Mac aus wie ein Rechner, der nie geprueft hat.
  scripts/melden.sh "$ERGEBNIS" "$UMFANG" "$DAUER" \
    "$(printf '%s' "${UEBERSPRUNGEN:-nichts}" | tr '\n' ',' | sed 's/,$//')" \
    || echo "   Achtung: Melden in den Zweig pruefungen ist fehlgeschlagen."
fi

exit $FEHLER
