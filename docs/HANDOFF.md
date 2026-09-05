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

## Session 14 — Stabilisierung, UX-Slice, erste echte Screens

**Auftrag:** Phase 1 den Unterbau stabilisieren, Phase 2 einen durchgehenden
UX-Slice mit Onboarding, Phase 3 Review-Gate. Danach auf Zuruf weiter:
P0.4, erste Runde — das Onboarding als echte SwiftUI-Screens.

```
BUILD:   GRÜN — belegt, nicht behauptet. GitHub-Lauf 33673637210,
         macOS, Commit fed3fab, mit --streng. Das Protokoll sagt
         wörtlich: "23 Tests ausgefuehrt, keine Fehler."
         Das neue SwiftUI-Modul kompiliert beim ersten Versuch.
TESTS:   PASS — 91/91 Prototyp (gezählt vom Lauf), 11/11 SQL-Regeltests,
         14/14 Design-Tokens. Swift: 23 Testfunktionen (11 Progression,
         12 Onboarding-Regeln).
PREVIEW: `docs/prototype/index.html` — Datei im Chat, Zweig `prototype`.
         Version v0.5.0.
```

---

## Wo das Projekt steht

| Bereich | Zustand | Bewertung |
|---|---|---|
| Spezifikation (`docs/`, 20 nummerierte Dokumente) | vollständig | REAL |
| Datenbank (16 Migrationen, 35 RPCs) | vollständig, 11 Testdateien grün | REAL |
| Prüf- und CI-Werkzeug | in dieser Session repariert und belegt | REAL |
| Klickbarer Prototyp | Onboarding + Core Loop + Passport + Clan | PROTOTYPE |
| **iOS: Onboarding** | drei Schritte, 12 Regeltests, Build grün | **REAL** |
| iOS: alles andere | Gerüst mit Navigation und Tokens | PLACEHOLDER |
| Supabase-Projekt (echte Instanz) | **existiert nicht** | offen |

**Version:** v0.5.0 · **Zweig:** `claude/beer-quest-mvp-spec-dpjh2i` ·
Alle Arbeit liegt auf dem Zweig; `main` enthält nur „Initial commit".

---

# PM REVIEW NEEDED

### 1. Was hat sich verändert?

**Phase 1 — Werkzeug.** Der Auftrag lautete „prüfe die Prüfmechanismen".
Das Ergebnis ist unbequem: **sie hatten selbst sieben Fehler**, und die
meisten hätten genau dann zugeschlagen, wenn man sich auf sie verlässt.
Details unter „Was Phase 1 gefunden hat".

**Phase 2 — Produkt.** Onboarding (fehlte ganz), Passport statt
Zählerliste, Clan-Woche als Orte statt Meldungen, Clan-Vorschau auf Home.

**Danach P0.4, erste Runde — die ersten echten Screens.** Das Onboarding
in SwiftUI, weil es der einzige Weg in die App ist. Dabei fiel der Abgleich
mit dem Server an, und der deckte auf, dass **der Prototyp etwas anderes
versprach, als der Server tut** — siehe „Was der Abgleich aufdeckte".

### 2. Was kannst du anklicken?

Den ganzen Weg, ohne Sackgasse:

```
Onboarding (3 Schritte) → Home → Discover a beer → Check-in (1 Tap)
   → Reward → Beer World (4 Ebenen) → nächste Quest
Home → Clan-Vorschau → Clan
Home → Profile → Passport
```

Probier bitte ausdrücklich auch: im zweiten Schritt nach einem Jahr suchen,
in dem du **17 wärst** (es steht nicht in der Liste), und im dritten den
Namen **`admin`** sowie **`Steffen M.`** (wird zu `@steffen_m`).

### 3. Wo ist die Preview?

- **Die Datei kommt im Chat** — das ist der Weg, der bei dir funktioniert hat.
- Im Repository: `docs/prototype/index.html`, eine einzige Datei ohne
  Abhängigkeiten. Herunterladen, doppelklicken.
- Zweig `prototype` (nur was die Prüfung besteht, landet dort).

### 4. Was ist REAL, was PROTOTYPE, was PLACEHOLDER?

| | |
|---|---|
| **REAL** | Die Datenbank. 35 RPCs, gegen echtes Postgres 15 geprüft. XP-Regeln, Tages-Cap, Erst-Check-in-Ausnahme, Dedupe, Quests, Clan-XP, Passport, Karte — alles serverseitig fertig. |
| **PROTOTYPE** | Alles, was du anklickst. HTML mit Mock-Daten. Die XP-Regeln darin spiegeln den Server, die Bierliste ist erfunden. |
| **REAL, neu** | Das **Onboarding in der iOS-App** (`BQOnboarding`). Drei echte SwiftUI-Screens, dieselben Regeln wie der Server, 12 Tests, Build auf macOS grün. Nur der Abschluss ist noch eine Attrappe: Es entsteht kein Account, weil es weder Sign in with Apple noch eine Supabase-Instanz gibt (P0.5). |
| **PLACEHOLDER** | Der Rest der iOS-App. Ein Gerüst mit Navigation und Design-Tokens; Home, World, Quests, Clan und Profile sind leere Hüllen. |

> **Sehen kannst du die App noch nicht** — dafür braucht es einen Mac mit
> Xcode. Was der Prototyp zeigt, ist die Vorlage, nach der sie gebaut ist;
> die Design-Tokens werden zwischen beiden automatisch abgeglichen.

### 5. Welche Design-Entscheidungen stecken drin?

- **Das Onboarding verspricht nur, was der Server kann.** Es bildet
  `07_onboarding.sql` nach: Altersgrenze, Namenswahl, Wortfilter, erste
  Quest. Kein Foto-Upload, kein Freundeimport, nichts, was danach
  eingelöst werden müsste.
- **Vier Zeilen statt Fließtext.** Discover / Collect / Progress / Compete.
  Wer sie nicht in drei Sekunden liest, liest sie nicht.
- **„Not yet" führt nicht weiter.** Eine Frage, die man beliebig
  beantworten kann, ist Deko.
- **Der Wortfilter meldet sich beim Tippen**, nicht nach „weiter". Wer ihn
  erst danach erfährt, tippt zweimal.
- **Passport: `Florence — Waiting`, nicht „12 von 187.000".** Das gesperrte
  Feld zeigt, *was* dort wartet, nie *wie viel* fehlt. Eine Prüfung verbietet
  das Muster „n von m" im Passport.
- **Clan zeigt Orte, keine Meldungen.** „Lisa discovered Verona" ist eine
  Nachricht; „Verona — 14" ist ein Ort, an dem etwas los ist.
- **Die Home-Vorschau zeigt dieselbe Zeile wie der Clan-Schirm**, nicht eine
  zweite Formulierung — die würde früher oder später etwas anderes behaupten.

### 6. Was solltest du testen?

1. Der Weg von ganz vorn bis „nächste Quest" — **fühlt er sich wie ein
   Produkt an oder wie fünf Screens?**
2. Das Passport. Ist ein gesperrtes Feld eine **Einladung**? Oder liest es
   sich doch wie eine Bilanz?
3. Die Clan-Woche. Erzeugt `Verona — 14` den Sog, dorthin zu wollen?
4. Das Onboarding: Ist es zu kurz? Zu lang? Fehlt eine Frage, die die App
   später braucht?
5. **Neu:** Das Geburtsjahr statt Ja/Nein. Es ist ein Schritt mehr Arbeit
   für den Nutzer — aber der einzige, den der Server verwerten kann. Wenn du
   das anders willst, muss `complete_onboarding` mit geändert werden, nicht
   nur der Screen.

### 7. Welche Produktfragen sind offen?

| | Frage | Meine Neigung |
|---|---|---|
| P1 | Die **Badges** zeigen weiter `1/5` und `1/10`. Ist das dieselbe Bilanz, die wir im Passport verbannt haben? | Nein — ein Badge hat ein **endliches, sichtbares** Ziel, und das motiviert. Die Regel gilt der unbekannten Welt, nicht einem konkreten Ziel. Aber es ist eine Ermessensentscheidung; wenn du sie anders siehst, ändere ich es. |
| P2 | Das Onboarding fragt **nicht** nach dem Heimatort. | Bewusst. Der Ort kommt vom Gerät. Eine Frage, deren Antwort man ohnehin hat, ist eine Hürde. |
| P3 | Der Clan ist im Onboarding **kein** Schritt. | Bewusst: erst spielen, dann beitreten. Ein Clan vor dem ersten Check-in ist ein leeres Versprechen. |
| P4 | „Mastered" heißt aktuell: 3 Biere **und** 2 Orte in einer Stadt. Zahlen frei erfunden. | Braucht deine Meinung, sobald echte Daten da sind. |

---

## Was der Abgleich aufdeckte

Beim Bauen der echten Screens musste ich `complete_onboarding` Zeile für
Zeile lesen. Zwei Stellen liefen auseinander — und **beide hätten den
Nutzer erst nach dem letzten Schritt in eine Absage laufen lassen**:

**Der Server will ein Geburtsjahr, der Prototyp fragte Ja/Nein.**
`complete_onboarding` nimmt `p_birth_year` und rechnet damit. Ein Häkchen
liefert kein Jahr. Beide fragen jetzt das Jahr — und nur das Jahr, nie das
volle Datum. Die Auswahl bietet außerdem **nur Jahre an, die der Server
annimmt**: ein 17-Jähriger findet sein Jahr gar nicht erst.

**Der Server will `^[a-z0-9_]{3,20}$`, der Prototyp erlaubte alles.**
Statt zu korrigieren wird jetzt vorgeschlagen: „Steffen M." wird sichtbar
zu `@steffen_m`. Der Wortfilter prüft wie `is_term_allowed` auf Gleichheit
**und** Enthaltensein — `xadminx` ist gesperrt.

Das ist genau Risiko **R7** aus dem letzten Handoff („der Prototyp bildet
den Server von Hand nach"), eingetreten binnen einer Session. Die Antwort
darauf ist keine Mahnung, sondern eine Prüfung: `OnboardingRules` in
`BQCore` sagt im Dateikopf, dass sie eine **Kopie** ist und im selben
Commit mitzuändern ist, und 12 Tests halten sie gegen die Fälle aus dem
SQL.

---

## Was Phase 1 gefunden hat

Sieben Befunde. Der Reihe nach, mit dem, was jetzt dagegen steht.

**1. Der macOS-Build ist grün — der Nachweis fehlte.**
Lauf 33510952452, Commit 9e4ab6b, 80 s Testphase, erfolgreich. Damit ist die
seit Session 9 offene Frage beantwortet. *Aber:* Der Lauf lief mit `-quiet`
und belegte nirgends, dass auch nur **ein** Test ausgeführt wurde — ein
Schema ohne Testziel wäre genauso grün gewesen. `verify.sh` zählt jetzt und
wird **rot bei null**. Lauf 33596688860 bestätigt es auf dem echten Runner:
„11 Tests ausgefuehrt, keine Fehler."

**2. `verify.sh` wäre auf jedem Mac abgestürzt.**
Bash-Arrays; `/bin/bash` auf macOS ist Version 3.2 von 2007 und bricht bei
`${#ARRAY[@]}` mit leerem Array unter `set -u` ab. Rot geworden wäre
ausgerechnet der **einzige Rechner, der den Xcode-Build ausführen kann** —
ohne dass am Projekt etwas falsch gewesen wäre. Jetzt ohne Arrays.

**3. Das Melden in den Zweig `pruefungen` lief auf Linux nie.**
`[ "$WOHER" = "Darwin" ] && WOHER="Mac"` beendet unter `set -e` das Skript,
sobald der Test falsch ist — also in **jeder Cloud-Sitzung**, wortlos. Der
Mechanismus, der Mac und Cloud verbinden soll, war auf einer Seite tot.
**Das ist der Grund, warum der Zweig bis heute leer ist** — es war nicht
Nachlässigkeit.

**4. Der Branch-Schutz hätte jeden Pull Request blockiert.**
GitHub meldet für einen Ablauf, der wegen eines **Pfadfilters** gar nicht
startet, *keinen* Status — nicht „bestanden", sondern gar nichts. Als
„required status check" bliebe er ewig ausstehend; ein Pull Request, der nur
Dokumentation ändert, ließe sich **nie mehr zusammenführen**. Aufgefallen
wäre es erst nach dem Einschalten. Filter bleibt beim `push`, fällt beim
`pull_request`.

**5. Zwei Zahlen stimmten nicht.**
Die Übergabe sagte „39 Prototyp-Prüfungen"; tatsächlich liefen 47 (heute 82).
Die Zahl wird jetzt **vom Lauf gezählt und ausgegeben**, nicht in ein
Dokument geschrieben. Und `project.yml` stand seit P0.1 auf `0.1.0`, während
der Changelog bei `0.3.0` war — `verify.sh` hält beide jetzt gegeneinander.

**6. `scripts/**` löste den iOS-Build nicht aus**, obwohl der Lauf
`verify.sh` aufruft. Eine Änderung am Prüfskript, die den Build bricht, wäre
erst beim nächsten Swift-Commit aufgefallen — und dann beim falschen
Verdächtigen.

**7. Keine einzige Versionsmarke ist je am Remote angekommen.**
`git ls-remote --tags origin` liefert **nichts**. Der Push scheitert
reproduzierbar mit `HTTP 403`. `v0.1.0` bis `v0.3.0` existierten nur lokal,
in einem Container, der beim Sitzungsende verschwindet. Drei Sessions lang
meldete die Übergabe eine Version, von der am Repository nichts zu sehen war.
Die Version lebt jetzt in `CHANGELOG.md` und `project.yml`, gegeneinander
geprüft.

**Neu dazu:** `--streng` — in der CI zählt Übersprungenes als Fehler. Ein
grüner Haken, hinter dem nichts geprüft wurde, ist schlimmer als ein roter.
Lokal bleibt es beim alten Verhalten.

---

## FÜR DEN REVIEW

**Commit-Bereich:** `af08be6..HEAD` auf `claude/beer-quest-mvp-spec-dpjh2i`
(4 Commits)

| Datei | Was |
|---|---|
| `docs/prototype/index.html` | Onboarding, Passport, Clan-Woche, Home-Vorschau |
| `scripts/check-prototype.mjs` | 47 → 82 Prüfungen; zählt sich selbst |
| `scripts/verify.sh` | ohne Arrays, Testzählung, `--streng`, Versionsabgleich |
| `scripts/melden.sh` | `[ ] &&` → `if` |
| `.github/workflows/*.yml` | Pfadfilter beim PR raus, `--streng`, `scripts/**` |
| `project.yml` | Version 0.1.0 → 0.4.0 |
| `docs/19-branch-protection.md` | neu — zum Abhaken |
| `docs/HANDOFF-ARCHIV.md` | neu — Sessions 1–13 wortgleich |
| `.claude/skills/release-discipline/SKILL.md` | Marken sind nicht der Träger |
| `BQCore/OnboardingRules.swift` | **neu** — die Regeln als testbare Kopie des SQL |
| `BQOnboarding/OnboardingFlow.swift` | **neu** — drei SwiftUI-Schritte |
| `BQCoreTests/OnboardingRulesTests.swift` | **neu** — 12 Tests gegen die SQL-Fälle |
| `App/RootView.swift` | schaltet auf den Sitzungszustand |
| `App/BeerQuestApp.swift`, `BQSession` | Attrappe bis P0.5, benannt als solche |

**Selbst nachprüfen:**
```bash
./scripts/verify.sh schnell                             # 82 + 14, ~35 s
su postgres -c './supabase/ci/run_local.sh bq_verify'   # 11 SQL-Dateien
./scripts/verify.sh sql --streng; echo $?               # muss 1 sein
git ls-remote --tags origin                             # leer: Befund 7
```

**Was sich aus dem Repository NICHT beurteilen lässt:**
- Ob `verify.sh` auf einem echten Mac durchläuft. Befund 2 ist behoben, aber
  **niemand hat das Skript je auf macOS gestartet.** Der Zweig `pruefungen`
  ist leer.
- Ob der Branch-Schutz wirkt. Er ist beschrieben, nicht eingeschaltet.
- Ob sich der Prototyp gut anfühlt. Das entscheidest du am Gerät.

---

## RISKS / PM DECISIONS NEEDED

| # | Sache | Meine Einschätzung | Was ich brauche |
|---|---|---|---|
| **R1** | `main` enthält nur „Initial commit"; die gesamte Arbeit liegt auf dem Arbeitszweig | Ein Branch-Schutz auf leerem `main` schützt nichts. Und wer das Repository auf `main` öffnet, sieht ein leeres Projekt. | **Entscheidung: Arbeitszweig nach `main` zusammenführen?** Ich tue das nicht ungefragt. Vorschlag: ja, per Pull Request — dann laufen die drei Prüfungen einmal an einem echten PR und sind danach als „required" eintragbar. |
| **R2** | `verify.sh` lief nie auf macOS | Der einzige Rechner, der Xcode ausführen kann, ist der einzige, auf dem das Skript nie lief — und genau dort steckte Befund 2. | Einmal `./scripts/verify.sh --melden` auf dem Mac. Danach steht eine Zeile im Zweig `pruefungen`, und die Behauptung wird ein Beleg. |
| **R3** | Kein Supabase-Projekt | 35 RPCs sind gegen lokales Postgres geprüft, nie gegen die echte Instanz. Sign in with Apple ist ungetestet. | Blockiert P0.4. Anlegen dauert ~15 min, kostet nichts. |
| **R4** | GitHub Pages für Zweig `prototype` nicht eingeschaltet | Der Prototyp ist nur als Datei zugänglich. Das hat schon einmal einen Review gekostet. | Ein Schalter in den Repository-Einstellungen. |
| **R5** | Die XP-Kurve steht **zweimal** — in SQL und in Swift — ohne Abgleich | Fehlerklasse 4. Heute stimmen sie; das ist keine Eigenschaft, sondern ein Zufall. | Kein Beschluss nötig. Ich merke einen Test vor, der beide gegeneinander hält, sobald es eine echte Instanz gibt (R3). |
| **R6** | Versionsmarken lassen sich nicht schieben (403) | Behoben, indem die Version dorthin gezogen wurde, wo sie mitgeschoben wird. | Nichts zu entscheiden. Marken auf dem Mac: `git tag -a v0.4.0 -m "..." && git push origin v0.4.0`. |
| **R7** | Der Prototyp bildet den Server nach — von Hand. **Eingetreten.** | Zwei Divergenzen gefunden und behoben (Geburtsjahr, Handle-Format). Die Regeln liegen jetzt in `BQCore.OnboardingRules`, ausdrücklich als Kopie markiert, mit 12 Tests gegen die SQL-Fälle. Das entschärft es, beseitigt es aber nicht: Der HTML-Prototyp bleibt eine dritte Stelle. | Kein Beschluss nötig. Ich prüfe bei jedem weiteren Screen zuerst die zugehörige RPC — dieser Abgleich hat gerade zwei Fehler gefunden, die sonst erst im TestFlight aufgefallen wären. |
| **R8** | In dieser Umgebung steht **kein Swift-Compiler**. Die macOS-CI ist die einzige Gegenprobe. | Diesmal ging es beim ersten Versuch grün durch, aber das ist kein Verfahren, sondern Glück plus Sorgfalt. Ein Tippfehler kostet einen vollen CI-Zyklus. | Nichts zu entscheiden, solange R2 offen ist. Sobald du einmal auf dem Mac `./scripts/verify.sh --melden` laufen lässt, gibt es wieder eine schnelle Schleife. |

---

## Vorschläge und Themen von mir

1. **R1 zuerst entscheiden.** Ein Pull Request nach `main` ist zugleich der
   Belastungstest für Befund 4: Die drei Prüfungen müssen an einem echten PR
   sichtbar werden, sonst lassen sie sich gar nicht als „required" eintragen.
2. **Der Zweig `pruefungen` ist der wunde Punkt.** Solange dort nichts steht,
   weiß eine Cloud-Sitzung nie, ob je ein echter Xcode-Build lief. Befund 3
   zeigt, dass das ein Werkzeugfehler war, keine Nachlässigkeit.
3. **Nach deinem Review wäre P0.4 dran**: die ersten echten SwiftUI-Screens,
   und zwar in derselben Reihenfolge wie im Prototyp — Onboarding zuerst,
   weil es der einzige Weg in die App ist. Ein Bereich pro Runde.
4. **Redaktionelle Arbeit liegt weiter bei dir**: die Wortfilterliste
   (~200 Begriffe) und die Durchsicht der Bier-Seeds. Beides ist
   Voraussetzung für einen externen Test, nicht für P0.
5. **Selbstkritisch:** Diese Session hat mehr Zeit im Werkzeug verbracht als
   im Produkt. Das war der Auftrag, und die sieben Befunde rechtfertigen es —
   aber die nächste Session sollte wieder am Produkt arbeiten, sonst pflegen
   wir eine Werkbank, auf der nichts liegt.

---

## Was als Nächstes passiert

Ein Bereich pro Runde, in der Reihenfolge des Prototyps. Als Nächstes
**Home** — Hero, Fortschritt, nächstes Ziel, Weltausschnitt, Clan-Vorschau.

Vorher aber, und das ist wichtiger: **R1 und R3.** Ohne Supabase-Instanz
bleibt jeder weitere Screen an einer Attrappe hängen, und ohne einen
Zusammenführen-Entscheid steht `main` weiter leer.
