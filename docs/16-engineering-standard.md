# Engineering-Standard: Versionierung, Tests, CI/CD

**Verbindlich ab 2026-08-30.** Ergänzt die Produktanforderungen um
Qualitätssicherung. Grundsatz aus §11 des Auftrags: *professionell, aber
nicht over-engineered.* Die Infrastruktur wächst mit dem Produkt.

---

## 1. Bestandsaufnahme

Was heute schon da ist — und was fehlt.

| Bereich | Stand | Bewertung |
|---|---|---|
| **SQL-Tests** | 7 Dateien, decken Core Loop, Cap, Idempotenz, Dedupe, Quests, Clan-XP, RLS, Onboarding ab | ✅ gut — hier liegt die Geschäftslogik, und sie ist abgesichert |
| **SQL-CI** | `sql-tests.yml`, Linux, Postgres 15, mit Pfadfiltern, prüft auch Migrations-Idempotenz | ✅ läuft |
| **Lokaler SQL-Durchlauf** | `supabase/ci/run_local.sh` — von Null bis Tests | ✅ |
| **Swift-Unit-Tests** | 1 Datei, 11 Testfunktionen (nur `Progression`) | 🔶 dünn, aber deckt die einzige Logik ab, die es in Swift gibt |
| **Swift-Build in CI** | ✅ scharf seit 2026-08-31 (`ios-build.yml`) | ✅ Lücke geschlossen |
| **Integrationstests** (App ↔ Backend) | **fehlen** | 🔶 sinnvoll erst mit echtem API-Client (P0.4) |
| **UI-Tests** | keine | ✅ richtig so — erst für kritische Journeys, nicht jetzt |
| **Versionierung / Tags** | **0 Tags**, keine Release-Strategie | 🔴 Lücke |
| **Regression-Regel** | informell befolgt, nicht dokumentiert | 🔶 |
| **Definition of Done** | für P0 als Produktkriterien vorhanden, nicht als Engineering-Gate | 🔶 |

**Die ehrliche Kernaussage:** Die Backend-Logik ist gut abgesichert — sie ist
in dieser Umgebung ausführbar. Der Swift-Code ist es **nicht**: 1.005 Zeilen
in drei aufeinander gestapelten Änderungen sind bis heute nie kompiliert
worden. Genau diese Lücke schließt dieses Dokument.

---

## 2. macOS-Runner: die Kostenanalyse

**Verifiziert am 2026-08-30 direkt bei GitHub** (Quellen unten).

### Verfügbare Standard-Runner

| Label | Architektur | Kerne | RAM |
|---|---|---|---|
| `macos-latest`, `macos-15`, `macos-26` | ARM64 (M1) | 3 | 7 GB |
| `macos-15-intel`, `macos-26-intel` | x64 | 4 | 14 GB |

`macos-latest` zeigt auf Apple Silicon. **Für unser Projekt völlig
ausreichend** — ein SwiftUI-Projekt mit ~1.000 Zeilen und einem lokalen Swift
Package braucht keine größere Maschine. Larger Runners sind für Team- und
Enterprise-Pläne und für uns weder nötig noch verfügbar.

### Die entscheidende Zahl

| Runner | Preis/Minute | Faktor gegenüber Linux |
|---|---|---|
| Linux 2-Kerne | $0,006 | 1× |
| Windows 2-Kerne | $0,010 | ~1,7× |
| **macOS 3–4 Kerne** | **$0,062** | **~10×** |

Free-Plan-Kontingent: **2.000 Minuten/Monat** für private Repositories.
Bei Faktor 10 sind das **~200 macOS-Minuten pro Monat**.

Ein Xcode-Build mit Tests für dieses Projekt: geschätzt **4–6 Minuten** kalt,
2–3 warm. Das bedeutet:

> **Auf einem privaten Repository reicht das Freikontingent für etwa
> 3 bis 6 vollständige iOS-Builds pro Monat.**

Das ist für „jeder Push wird gebaut" nicht ansatzweise genug.

### ✅ Entschieden am 2026-08-31: Das Repository ist öffentlich

Damit ist die Frage beantwortet, bevor sie gestellt werden musste — **das
Repository ist bereits öffentlich, und beim Parallelprojekt laufen die
macOS-Runner auf demselben Weg.** Standard-Runner sind für öffentliche
Repositories unbegrenzt kostenlos, macOS eingeschlossen.

**Konsequenz:** Die iOS-CI ist scharfgeschaltet (`ios-build.yml`), ohne
Rationierung und ohne laufende Kosten. Die Sparmaßnahmen bleiben trotzdem —
nicht wegen der Kosten, sondern weil ein Build, der bei jeder
Dokumentationsänderung anspringt, nur Wartezeit erzeugt.

Ein selbst gehosteter Runner entfällt damit — und das ist gut so: An einem
öffentlichen Repository wäre er ein Sicherheitsrisiko, weil Fremde über Pull
Requests Code darauf ausführen könnten.

### Der Hebel

> **Für öffentliche Repositories sind Standard-Runner kostenlos — macOS
> eingeschlossen.** GitHub formuliert es in der Runner-Dokumentation
> ausdrücklich als „Free for Public, Paid for Private".

Damit gibt es genau drei Wege zu iOS-CI bei 0 €:

| Option | Kosten | Aufwand | Bewertung |
|---|---|---|---|
| **A — Repository öffentlich** | **0 €, unbegrenzt** | — | ✅ **gewählt, war bereits der Fall** |
| **B — Privat bleiben, CI streng rationieren** | 0 €, aber ~4 Builds/Monat | gering | Funktioniert, ist aber ein dauerndes Sparen am falschen Ende |
| **C — Selbst gehosteter Runner auf dem eigenen Mac** | 0 € | mittel, plus Betrieb | Sinnvoll, wenn der Mac ohnehin läuft. Sicherheitshinweis: selbst gehostete Runner sollten nie an einem **öffentlichen** Repo hängen — Fremde könnten Code darauf ausführen. A und C schließen sich also aus. |

**Geklärt:** Beim Parallelprojekt lief der Mac-Runner über ein öffentliches
Repository — derselbe Weg, den wir jetzt nutzen.

### Was gegen „öffentlich" spricht — und was nicht

Im Repository liegen **keine Geheimnisse**: `Config.xcconfig` ist
gitignoriert, der Supabase-Anon-Key ist ohnehin öffentlich (durch RLS
abgesichert), der Service-Role-Key existiert nirgends. GitHub-Secrets bleiben
auch bei öffentlichen Repos geheim.

Öffentlich würde bedeuten: Produktstrategie, Kostenanalyse und
Monetarisierungspläne sind lesbar. Das ist eine **Geschäftsentscheidung**,
keine technische. Für ein Nebenprojekt ohne Wettbewerbsdruck halte ich sie für
vertretbar — aber sie gehört dir.

---

## 3. CI/CD-Strategie

### Prinzip

**Maximale Sicherheit bei minimalem Verbrauch.** Linux ist praktisch gratis,
macOS ist teuer — also läuft auf Linux alles, was dort laufen kann, und macOS
nur, wenn Swift-Code betroffen ist.

### Trigger-Matrix

| Änderung an | Linux: SQL-Tests | macOS: Build + Tests | Begründung |
|---|:--:|:--:|---|
| `supabase/**` | ✅ jeder Push | — | kostet ~1 Minute |
| `BeerQuestKit/**`, `App/**`, `project.yml` | — | ✅ **nur im Pull Request** | der teure Job, nur wenn nötig |
| `docs/**`, `*.md` | — | — | **kein Build.** Dokumentation ändert kein Verhalten |
| `.github/workflows/**` | ✅ | ✅ | der geänderte Job muss sich selbst beweisen |
| Merge nach `main` | ✅ | ✅ | vollständige Prüfung vor einem stabilen Stand |
| Tag `v*` | ✅ | ✅ | Release-Prüfung |

Zusätzliche Sparmaßnahmen, alle ohne Nachteil:

- `concurrency: cancel-in-progress` — ein neuer Push bricht den laufenden
  Build derselben Referenz ab. Spart bei schneller Folge von Commits am meisten.
- `actions/cache` für DerivedData und SPM-Abhängigkeiten — halbiert die
  Buildzeit typischerweise.
- `timeout-minutes: 20` als Notbremse gegen hängende Jobs.
- Build **nur für den Simulator**, kein Signing, kein Archiv.

### Stand

Der macOS-Workflow ist **scharf**. Er baut das Projekt mit XcodeGen, wählt den
Simulator zur Laufzeit (ein fest verdrahteter Gerätename bricht, sobald GitHub
das Runner-Image aktualisiert) und führt die Tests ohne Signing aus.

### Lokales Gate

Unabhängig von CI: **`scripts/verify.sh`** führt aus, was auch die CI prüft —
SQL-Durchlauf plus Xcode-Build und -Tests. Vor jedem Push einmal laufen
lassen. Bei einem Solo-Projekt ist das die wirksamste Absicherung überhaupt,
weil sie sofortiges Feedback gibt und nichts kostet.

---

## 4. Teststrategie (Testpyramide)

| Ebene | Umfang | Wo | Stand |
|---|---|---|---|
| **Database** | SQL-Funktionen, Constraints, RLS, Idempotenz, serverseitige Spielregeln | `supabase/tests/` | ✅ 7 Dateien |
| **Unit** | Reine Logik ohne Netzwerk und UI: XP-/Level-Formeln, RetryQueue, DTO-Mapping, Routen-Parsing | `BeerQuestKit/Tests/` | 🔶 1 Datei, wächst mit den Modulen |
| **Integration** | App ↔ Backend gegen eine lokale Supabase-Instanz | ab P0.4 | ⏭️ geplant |
| **UI** | **Nur** kritische Journeys: Onboarding bis Home, Check-in bis Reward | ab P0.5 | ⏭️ geplant, bewusst sparsam |
| **Build Verification** | Das iOS-Projekt muss reproduzierbar bauen | CI + `verify.sh` | ✅ CI scharf seit 2026-08-31 |

### Pflichtabdeckung der Spielregeln

Diese Regeln dürfen **nie** nur manuell geprüft sein. Stand heute:

| Regel | Test | Status |
|---|---|---|
| XP-Vergabe | `02`, `06` | ✅ |
| Level-Berechnung | `ProgressionTests` + `03` | ✅ |
| Discovery-Rewards | `02` | ✅ |
| Erster Check-in ungekürzt | `06` | ✅ |
| Tages-XP-Cap | `02`, `06` | ✅ |
| Quest-Fortschritt und -Belohnung | `04` | ✅ |
| Bier-Dedupe | `03` | ✅ |
| Orts-Dedupe | `03` | ✅ |
| Stadt-/Land-Erkennung | `02` | ✅ |
| Clan-XP | `04` | ✅ |
| Idempotenz | `03` | ✅ |
| Rechte / RLS | `05` | ✅ |
| Authentifizierung / Onboarding | `07` | ✅ |
| **Leaderboards** | — | ⏭️ mit P0.10 |
| **Offline / Retry** | — | ⏭️ mit P0.4 (Unit-Test der RetryQueue) |

### Regression-Schutz

**Regel: Jeder behobene Fehler bekommt einen Test, der ihn festnagelt.**
Der Test bleibt dauerhaft bestehen, auch wenn der Fehler „längst erledigt" ist.

Das ist keine Theorie — in diesem Projekt ist es bereits zweimal passiert:

| Fehler | Festgenagelt durch |
|---|---|
| Orts-Dedupe griff bei Zusatzwörtern nicht („Cafe Belge" vs. „Cafe Belge Brussels") | `03` prüft beide Richtungen und die Nicht-Zusammenlegung auf 2 km |
| `award_xp` war für Clients aufrufbar (freie XP-Vergabe), weil `EXECUTE` an `PUBLIC` vererbt wird | `05` prüft die Aufrufbarkeit explizit |

---

## 5. Versionierung und Releases

### Branches

- Arbeit findet auf Feature-/Task-Branches statt (`claude/<thema>`).
- `main` ist der stabile Stand. Keine direkten Änderungen daran.
- Zusammenführung über Pull Request, sobald CI läuft.

### SemVer für ein Produkt, das noch kein Publikum hat

Solange Beer Quest vor dem ersten externen Test steht, ist es
`0.MINOR.PATCH` — die führende Null sagt genau das aus: **keine
Stabilitätszusage**.

| Version | Bedeutung | Auslöser |
|---|---|---|
| `v0.1.0` … `v0.9.0` | **MINOR = eine abgeschlossene P0-Phase.** `v0.1.0` = P0.1, `v0.2.0` = P0.2 usw. | Phase fertig, Tests grün, Build grün |
| `v0.x.y` | **PATCH = Korrektur** an einer abgeschlossenen Phase | Bugfix mit Regressionstest |
| `v0.11.0` | P0 vollständig, interner TestFlight | Definition of Done P0 erfüllt |
| **`v1.0.0`** | **Erste externe Verteilung** | Alle 17 Punkte aus `11-release-gates.md` Stufe 2 erfüllt |
| ab `v1.x` | normales SemVer: BREAKING / FEATURE / FIX | |

Der Sprung auf `1.0.0` ist damit an ein **inhaltliches Kriterium** gebunden,
nicht an ein Gefühl: Er passiert genau dann, wenn Fremde die App bekommen.

**Zusätzlich:** Jeder TestFlight-Build bekommt eine monoton steigende
`CURRENT_PROJECT_VERSION` (Build-Nummer). Apple verlangt das ohnehin.

### Tags rückwirkend

P0.1 und P0.2 sind abgeschlossen. Sobald der Build einmal bestätigt ist,
werden `v0.1.0` und `v0.2.0` auf die jeweiligen Commits gesetzt — dann gibt es
von Anfang an nachvollziehbare Stände.

### Commits

Klein und thematisch. Ein Commit pro sinnvollem Schritt, nicht ein Commit pro
Session. Funktionierende Zwischenstände bleiben erhalten.

> **Selbstkritik:** Die bisherigen Commits dieses Projekts sind zu groß.
> „P0.2 Datenbank-Fundament" umfasste 8 Migrationen, 3 Seeds und 5 Tests in
> einem Commit. Nachvollziehbar wäre gewesen: Schema, dann Funktionen, dann
> RLS, dann Seeds, jeweils mit den zugehörigen Tests. Ab sofort kleiner.

---

## 6. Definition of Done

Ein Task ist **DONE**, wenn **alle** Punkte erfüllt sind:

- [ ] Implementierung abgeschlossen
- [ ] relevante Tests vorhanden
- [ ] **Tests erfolgreich**
- [ ] **Build erfolgreich**
- [ ] keine bekannten kritischen Regressionen
- [ ] Commit erstellt
- [ ] `docs/HANDOFF.md` aktualisiert

Bei größeren Features zusätzlich:

- [ ] Produktanforderung erfüllt
- [ ] UX geprüft (States: Loading, Empty, Error, Offline)
- [ ] Rechte und Sicherheit geprüft
- [ ] Kostenfolgen geprüft (`04-cost-analysis.md` §6)

### Handoff-Pflichtangaben

Jeder Handoff-Eintrag nennt ab sofort **explizit**:

```
BUILD:  PASS | FAIL | NICHT AUSGEFÜHRT (mit Grund)
TESTS:  PASS | FAIL | TEILWEISE (welche)
```

„Nicht ausgeführt" ist eine zulässige Angabe — **eine unbelegte
Erfolgsmeldung ist es nicht.**

---

## 7. Was bewusst nicht gebaut wird

Kein Coverage-Gate, keine Mutationstests, keine Matrix über mehrere
iOS-Versionen, kein automatischer TestFlight-Upload, kein Release-Bot, kein
Dependabot (wir haben keine Abhängigkeiten), keine Staging-Umgebung.

Alles davon ist sinnvoll — für ein Produkt mit Nutzern. Wir haben noch keine.

---

## 8. Quellen (abgerufen 2026-08-30)

| Angabe | Quelle |
|---|---|
| Runner-Preise: Linux $0,006 / Windows $0,010 / macOS $0,062 pro Minute | <https://docs.github.com/en/billing/reference/actions-minute-multipliers> |
| macOS-Runner-Labels und Hardware, „Free for Public, Paid for Private" | <https://docs.github.com/en/actions/reference/runners/github-hosted-runners> |
| Free-Plan: 2.000 Minuten/Monat, öffentliche Repos kostenlos | <https://docs.github.com/en/billing/concepts/product-billing/github-actions> |
