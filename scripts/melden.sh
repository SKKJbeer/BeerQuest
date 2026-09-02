#!/usr/bin/env bash
# Schreibt eine Zeile je Pruefungslauf in den Zweig `pruefungen`.
#
# Uebernommen aus PulseMeter. Der Anlass ist bei uns derselbe: Der Mac des
# Gruenders und die Cloud-Sitzung sehen einander NICHT. Eine Cloud-Sitzung
# kann keinen Xcode-Build ausfuehren und erfaehrt sonst nie, ob einer gelaufen
# ist - in diesem Projekt hat das dazu gefuehrt, dass drei Sitzungen lang
# ungetesteter Swift-Code aufeinandergestapelt wurde.
#
# Nachsehen von ueberall:
#   git fetch origin pruefungen && git show origin/pruefungen:README.md | tail -5
set -euo pipefail
cd "$(dirname "$0")/.."

ERGEBNIS="${1:?}"; UMFANG="${2:?}"; DAUER="${3:?}"; UEBERSPRUNGEN="${4:-nichts}"
STAND=$(git rev-parse --short HEAD)
[ -z "$(git status --porcelain --untracked-files=no)" ] || STAND="$STAND+aenderungen"
# Kein `[ ... ] && ...` als eigenstaendiger Befehl: Unter `set -e` beendet
# eine solche Liste das Skript, sobald der Test falsch ist. Auf Linux - also
# in jeder Cloud-Sitzung - ist `uname -s` eben nicht "Darwin", und das Melden
# brach genau hier ab, ohne eine Zeile zu schreiben und ohne eine Meldung.
WOHER=$(uname -s)
if [ "$WOHER" = "Darwin" ]; then WOHER="Mac"; fi
ZEILE="$(date -u +'%Y-%m-%d %H:%M UTC') | $STAND | $ERGEBNIS | $UMFANG | ${DAUER}s | $WOHER | ohne: $UEBERSPRUNGEN"

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
ZIEL=$(git remote get-url origin)
git clone -q --depth 1 --branch pruefungen "$ZIEL" "$WORK" 2>/dev/null || {
  git init -q "$WORK"; git -C "$WORK" checkout -q -b pruefungen
  printf '# Pruefungslaeufe\n\nEine Zeile je Lauf. Neueste unten.\n\n' > "$WORK/README.md"
  git -C "$WORK" remote add origin "$ZIEL"
}
echo "$ZEILE" >> "$WORK/README.md"
git -C "$WORK" add -A
git -C "$WORK" -c user.name="Beer Quest" -c user.email="ci@beerquest.invalid" \
    commit -q -m "Lauf $STAND: $ERGEBNIS"
git -C "$WORK" push -q origin pruefungen
echo "Gemeldet: $ZEILE"
