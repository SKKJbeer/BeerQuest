#!/usr/bin/env bash
# Legt den geprüften Prototyp in den Zweig `prototype` - als Wurzel, nicht als
# Unterordner, damit ein Hosting-Dienst ihn ohne Pfadangabe ausliefern kann.
#
# Der Zweig trägt immer nur einen Stand und wird überschrieben. Die Historie
# des Prototyps ist die Historie von `docs/prototype/` im Arbeitszweig.
set -euo pipefail
cd "$(dirname "$0")/.."

QUELLE="docs/prototype"
BRANCH="${PROTOTYPE_BRANCH:-prototype}"

[ -d "$QUELLE" ] || { echo "$QUELLE gibt es nicht."; exit 1; }

if [ -n "${GITHUB_TOKEN:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  ZIEL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
  STAND="${GITHUB_SHA:-unbekannt}"
else
  ZIEL=$(git remote get-url origin)
  STAND=$(git rev-parse HEAD)
fi

WORK=$(mktemp -d); trap 'rm -rf "$WORK"' EXIT
cp -R "$QUELLE"/. "$WORK"/

cat > "$WORK/.stand" <<TXT
Beer Quest - klickbarer Prototyp
Stand: $STAND
Erzeugt: $(date -u +"%Y-%m-%d %H:%M UTC")
Quelle: docs/prototype/ im Arbeitszweig
TXT

cd "$WORK"
git init -q
git checkout -q -b "$BRANCH"
git add -A
git -c user.name="Beer Quest CI" -c user.email="ci@beerquest.invalid" \
    commit -q -m "Prototyp, Stand $STAND"
git push -q --force "$ZIEL" "$BRANCH"
echo "Prototyp liegt im Zweig $BRANCH."
