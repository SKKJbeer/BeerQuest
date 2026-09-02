# Handoff — der aktuelle Stand

Für den Projektmanager (ChatGPT). **Diese Datei beschreibt nur, wo das Projekt
jetzt steht.** Sie wird je Session überschrieben, nicht ergänzt. Wer hier
Verlauf sucht, sucht am falschen Ort.

Drei Dateien, drei Fragen. Eine Frage wird an genau einer Stelle beantwortet —
sonst steht sie früher oder später an zwei Stellen verschieden:

| Frage | Datei |
|---|---|
| Wo stehen wir **jetzt**? | **diese Datei** |
| Was hat sich je **Version** geändert, und warum? | `CHANGELOG.md` |
| **Wie** kam es dazu (Sessions 1–13)? | `docs/HANDOFF-ARCHIV.md` |

Format und Regeln: `.claude/skills/handoff/SKILL.md`.

---

## Session 14 — Stabilisierung der Prüfungen (Phase 1)

**Auftrag:** Vor dem nächsten UX-Schritt den technischen Unterbau
stabilisieren: Ist der Stand reproduzierbar? Ist der macOS-Build
*nachweisbar* grün? Taugen die Prüfmechanismen etwas? Branch-Schutz für
`main` vorbereiten. Und die Übergabedatei entrümpeln.

```
BUILD:   GRÜN — belegt, nicht behauptet: GitHub-Lauf 33510952452,
         macOS, Commit 9e4ab6b, 80 s Testphase, Ergebnis "success".
         In DIESER Session wurde kein Swift geändert; der Nachweis
         gilt dem Stand 9e4ab6b.
TESTS:   PASS — 47/47 Prototyp (gezählt vom Lauf), 11/11 SQL-Regeltests,
         14/14 Design-Tokens. Swift: 11 Testfunktionen, zuletzt auf dem
         macOS-Runner ausgeführt.
PREVIEW: unverändert seit Session 13 — Zweig `prototype`,
         `docs/prototype/index.html`. In dieser Session wurde nichts an
         der Oberfläche geändert.
```

---

## Wo das Projekt steht

**Phase:** P0 ist serverseitig fertig und geprüft. Die iOS-App ist ein
Gerüst. Der Prototyp V2 ist der einzige Ort, an dem das Produkt zu sehen ist.

| Bereich | Zustand | Bewertung |
|---|---|---|
| Spezifikation (`docs/`, 20 nummerierte Dokumente) | vollständig | REAL |
| Datenbank (16 Migrationen, 35 RPCs) | vollständig, 11 Testdateien grün | REAL |
| Prüf- und CI-Werkzeug | vollständig, in dieser Session repariert | REAL |
| Klickbarer Prototyp V2 | Core Loop ohne Onboarding | PROTOTYPE |
| iOS-App (14 Swift-Dateien) | Gerüst, baut und testet grün | PLACEHOLDER |
| Supabase-Projekt (echte Instanz) | **existiert nicht** | offen |

**Version:** v0.3.1 · **Zweig:** `claude/beer-quest-mvp-spec-dpjh2i` ·
22 Commits · `main` enthält nur „Initial commit".

---

## Was in dieser Session geprüft wurde — und was dabei herauskam

Der Auftrag lautete „prüfe die Prüfmechanismen". Das Ergebnis ist
unbequem: **die Prüfungen hatten selbst vier Fehler**, und drei davon
hätten genau dann zugeschlagen, wenn man sich auf sie verlässt.

### 1. Der macOS-Build ist grün — der Nachweis fehlte

Lauf 33510952452 auf `macos-latest`, Commit 9e4ab6b: erfolgreich, mit einer
echten Testphase von 80 Sekunden. Damit ist die seit drei Sessions offene
Frage beantwortet.

**Aber:** Das Protokoll lief mit `-quiet`. Es belegte nirgends, dass auch nur
ein einziger Test *ausgeführt* wurde. Ein Schema ohne Testziel wäre genauso
grün gewesen. Das ist der Unterschied zwischen „vorhanden" und „wirkt", und
er stand hier ein halbes Dutzend Sessions unbemerkt offen.
`verify.sh` zählt jetzt die ausgeführten Tests und wird **rot, wenn es
null sind** — mit Hinweis, wo nachzusehen ist.

### 2. `verify.sh` wäre auf dem Mac abgestürzt

Das Skript benutzte Bash-Arrays. Auf einem Mac ist `/bin/bash` die Version
3.2 von 2007, und dort bricht `${#ARRAY[@]}` bei leerem Array unter `set -u`
mit „unbound variable" ab. Das Skript wäre also ausgerechnet auf dem
**einzigen Rechner rot geworden, der den Xcode-Build überhaupt ausführen
kann** — ohne dass am Projekt etwas falsch gewesen wäre. Jetzt ohne Arrays.

### 3. Das Melden in den Zweig `pruefungen` lief nie

`melden.sh` enthielt `[ "$WOHER" = "Darwin" ] && WOHER="Mac"` unter `set -e`.
Ist der Test falsch — also auf jedem Linux, also in **jeder Cloud-Sitzung** —
beendet diese Zeile das Skript. Wortlos, ohne eine Zeile zu schreiben.
Der Mechanismus, der Mac und Cloud verbinden soll, war auf einer Seite tot.
Jetzt ein `if`; und `verify.sh` meldet, wenn das Melden scheitert.

### 4. Der Branch-Schutz hätte jeden Pull Request blockiert

Alle drei Abläufe hatten Pfadfilter auch beim `pull_request`. GitHub meldet
für einen Ablauf, der wegen eines Pfadfilters **gar nicht startet**, keinen
Status — nicht „bestanden", sondern gar nichts. Als „required status check"
wäre er ewig ausstehend geblieben: ein Pull Request, der nur Dokumentation
ändert, hätte sich **nie mehr zusammenführen lassen**. Die Falle wäre erst
aufgefallen, nachdem der Schutz eingeschaltet ist.
Pfadfilter jetzt nur noch beim `push` (dort geht es um Kosten), nicht beim
Pull Request (dort geht es ums Zusammenführen).

### 5. Zwei Zahlen stimmten nicht

- Die Übergabe sagte seit Session 13 „39 Prototyp-Prüfungen". Tatsächlich
  laufen **47** — einige Prüfungen stehen in Schleifen. Die Zahl wird jetzt
  vom Lauf **gezählt und ausgegeben**, nicht mehr in ein Dokument
  geschrieben. Eine Zahl in einem Dokument veraltet still.
- `project.yml` stand auf `MARKETING_VERSION 0.1.0`, während der Changelog
  bei `v0.3.0` war. Die App-Version wurde seit P0.1 nie mitgezogen.
  Jetzt `0.3.1`, und `verify.sh` hält die beiden Orte ab sofort gegeneinander.

### 7. Keine einzige Versionsmarke ist je am Remote angekommen

`git ls-remote --tags origin` liefert **nichts**. Die Marken `v0.1.0` bis
`v0.3.1` existieren nur lokal, in einem Container, der beim Sitzungsende
verschwindet. Der Push scheitert reproduzierbar mit `HTTP 403` — diese
Umgebung darf Zweige schieben, aber keine Marken.

Das heißt: **die Versionshistorie hing an etwas, das es nicht gibt.** Drei
Sessions lang stand in der Übergabe „Version v0.3.0", und am Repository war
davon nichts zu sehen.

Konsequenz statt Reparaturversuch: Die Version lebt dort, wo sie ohnehin
mitgeschoben wird — in `CHANGELOG.md` und `project.yml`. Beide werden jetzt
von `verify.sh` gegeneinander gehalten. Marken sind eine Zugabe, die du auf
dem Mac setzen kannst (`git tag -a v0.3.1 && git push origin v0.3.1`), kein
Träger der Wahrheit.

### 6. Neu: `--streng`

In der CI steht das Werkzeug fest. Fällt dort etwas aus, ist das kein
Umgebungsproblem, sondern ein kaputter Ablauf. `./scripts/verify.sh ios
--streng` macht Übersprungenes zum Fehler — ein grüner Haken, hinter dem
nichts geprüft wurde, ist schlimmer als ein roter. Lokal bleibt es beim
alten Verhalten: Übersprungenes wird benannt, nicht bestraft.

---

## PM REVIEW NEEDED

### Was sich verändert hat
Nur Werkzeug und Dokumentation. **Kein Produktcode, keine Oberfläche, keine
Datenbankregel.** Wer den Prototyp anschaut, sieht denselben Stand wie nach
Session 13.

### Was du anklicken kannst
Nichts Neues. Der Prototyp ist unverändert; die UX-Arbeit ist Phase 2 und
folgt in der nächsten Session.

### Was du prüfen solltest
1. `docs/19-branch-protection.md` — die Tabelle ist zum Abhaken gedacht.
   **Die Entscheidung „0 Approvals" ist meine Annahme** (Einzelperson; ein
   Selbst-Review wäre eine Formalie). Wenn du das anders willst, sag es.
2. Die Aufteilung in drei Dateien (oben). Sie widerspricht der früheren
   Vorgabe „alles in HANDOFF.md" und wurde in dieser Session ausdrücklich
   freigegeben. Prüf bitte, ob du so noch findest, was du suchst.

---

## FÜR DEN REVIEW

**Commit-Bereich:** `af08be6..HEAD` auf `claude/beer-quest-mvp-spec-dpjh2i`

| Datei | Was | Warum |
|---|---|---|
| `scripts/verify.sh` | Arrays raus, Testzählung, `--streng` | Befunde 1, 2, 6 |
| `scripts/melden.sh` | `[ ] &&` → `if` | Befund 3 |
| `scripts/check-prototype.mjs` | zählt die Prüfungen selbst | Befund 5 |
| `.github/workflows/ios-build.yml` | Pfadfilter beim PR raus, `--streng` | Befunde 4, 6 |
| `.github/workflows/sql-tests.yml` | Pfadfilter beim PR raus | Befund 4 |
| `.github/workflows/prototype.yml` | Pfadfilter beim PR raus | Befund 4 |
| `project.yml` | Version 0.1.0 → 0.3.1 | Befund 5 |
| `scripts/verify.sh` | Changelog gegen project.yml | Befund 7 |
| `.claude/skills/release-discipline/SKILL.md` | Marken sind nicht der Träger | Befund 7 |
| `docs/19-branch-protection.md` | neu, 81 Zeilen | Auftrag Phase 1 |
| `docs/HANDOFF.md` | ersetzt: nur noch aktueller Stand | Auftrag Phase 1 |
| `docs/HANDOFF-ARCHIV.md` | neu: Sessions 1–13 wortgleich | Auftrag Phase 1 |

**Selbst nachprüfen:**
```bash
./scripts/verify.sh schnell     # 47 Prototyp- + 14 Token-Prüfungen, ~35 s
su postgres -c './supabase/ci/run_local.sh bq_verify'   # 11 SQL-Dateien
./scripts/verify.sh sql --streng; echo $?               # muss 1 sein
git ls-remote --tags origin                             # leer: siehe Befund 7
```

**Was sich aus dem Repository NICHT beurteilen lässt:**
- Ob `verify.sh` auf einem echten Mac durchläuft. Der Array-Fehler ist
  behoben, aber **niemand hat das Skript je auf macOS gestartet.** Der
  Zweig `pruefungen` ist bis heute leer.
- Ob der Branch-Schutz wirkt. Er ist beschrieben, nicht eingeschaltet.

---

## RISKS / PM DECISIONS NEEDED

| # | Sache | Meine Einschätzung | Was ich brauche |
|---|---|---|---|
| R1 | `main` enthält nur „Initial commit"; 22 Commits liegen auf dem Arbeitszweig | Ein Branch-Schutz auf einem leeren `main` schützt nichts. Und wer das Repository auf `main` öffnet, sieht ein leeres Projekt — auch du, falls du je den Standardzweig liest. | **Entscheidung: Arbeitszweig nach `main` zusammenführen?** Ich tue das nicht ungefragt. Vorschlag: ja, per Pull Request, damit die drei Prüfungen einmal an einem echten PR laufen und danach als „required" eintragbar sind. |
| R2 | `verify.sh` lief nie auf macOS | Der einzige Rechner, der den Xcode-Build ausführen kann, ist der einzige, auf dem das Skript nie lief. Genau dort steckte Befund 2. | Einmal `./scripts/verify.sh --melden` auf dem Mac. Danach steht eine Zeile im Zweig `pruefungen`, und die Behauptung wird ein Beleg. |
| R3 | Kein Supabase-Projekt | Alle 35 RPCs sind gegen lokales Postgres 15 geprüft, nie gegen die echte Instanz. Auth über Sign in with Apple ist ungetestet. | Blockiert P0.4. Anlegen dauert ~15 min, kostet nichts. |
| R4 | GitHub Pages für den Zweig `prototype` nicht eingeschaltet | Der Prototyp ist nur als Datei zugänglich. Das hat schon einmal einen Review gekostet. | Ein Schalter in den Repository-Einstellungen. |
| R6 | Versionsmarken lassen sich aus dieser Umgebung nicht schieben (403) | Keine Marke ist je am Remote angekommen. Die Version steht jetzt in Changelog und `project.yml`, gegeneinander geprüft — das trägt. | Nichts zu entscheiden. Wer auf dem Mac Marken setzen mag: `git tag -a v0.3.1 -m "..." && git push origin v0.3.1`. |
| R5 | Ein Test je Spielregel — auf der **Server**seite. Swift hat 11 Tests, alle für `Progression` | Die Formeln stehen zweimal (SQL und Swift) und werden von niemandem gegeneinander gehalten. Fehlerklasse 4: „Wo etwas zweimal steht, steht es früher oder später verschieden." | Kein Beschluss nötig, aber ich merke es vor: ein Test, der die Swift-Kurve gegen die SQL-Kurve hält, sobald es eine echte Instanz gibt (R3). |

---

## Vorschläge und Themen von mir

1. **Phase 2 beginnt in der nächsten Session**: Onboarding im Prototyp,
   dann der durchgehende Weg Onboarding → Home → Entdecken → Check-in →
   Reward → Beer World → nächste Quest. Nichts davon ist angefangen.
2. **R1 zuerst entscheiden.** Ein Pull Request vom Arbeitszweig nach `main`
   ist zugleich der Belastungstest für Befund 4 — die drei Prüfungen müssen
   an einem echten PR sichtbar werden, sonst lassen sie sich gar nicht als
   „required" eintragen.
3. **Der Zweig `pruefungen` ist der wunde Punkt.** Solange dort nichts
   steht, weiß eine Cloud-Sitzung nie, ob je ein echter Xcode-Build lief.
   Befund 3 zeigt, dass das nicht Nachlässigkeit war, sondern ein Fehler
   im Werkzeug.
4. **Redaktionelle Arbeit liegt weiter bei dir**: die Wortfilterliste
   (~200 Begriffe) und die Durchsicht der Bier-Seeds. Beides ist
   Voraussetzung für einen externen Test, nicht für P0.

---

## Was als Nächstes passiert

1. **Phase 2** — Onboarding und der durchgehende UX-Slice im Prototyp
   (nächste Session).
2. **Phase 3** — PM-Review-Gate, danach Stopp bis zu deiner Rückmeldung.
3. Erst danach wieder Backend oder Swift.
