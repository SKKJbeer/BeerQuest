# Lokales Setup (P0.1)

Was in diesem Repo liegt, ist vollständig. Was **auf deiner Maschine bzw. in
deinen Accounts** passieren muss, steht hier. Dauer: ~45 Minuten.

---

## 1. Voraussetzungen

| Werkzeug | Zweck | Installation |
|---|---|---|
| Xcode 15+ | iOS-Build | App Store |
| XcodeGen | erzeugt das `.xcodeproj` aus `project.yml` | `brew install xcodegen` |
| Supabase CLI | Migrationen, lokale Datenbank | `brew install supabase/tap/supabase` |
| Docker Desktop | nur für `supabase start` (lokale DB) | optional |

Ein Apple Developer Program-Zugang wird **erst ab Phase P0.6** gebraucht
(TestFlight). Für P0.1–P0.5 genügt ein kostenloser Apple-Account und der
Simulator.

## 2. Xcode-Projekt erzeugen

```bash
cp Config.xcconfig.example Config.xcconfig   # danach ausfüllen, siehe Schritt 3
xcodegen generate
open BeerQuest.xcodeproj
```

Das `.xcodeproj` ist bewusst **nicht** eingecheckt: Ein generiertes Projekt
erzeugt keine Merge-Konflikte in der `project.pbxproj`. Nach jeder Änderung an
`project.yml` oder nach dem Hinzufügen neuer Dateien einfach erneut
`xcodegen generate` laufen lassen.

## 3. Supabase-Projekt anlegen

1. Auf <https://supabase.com> ein Projekt in der **EU-Region** erstellen
   (Datenschutz, siehe `05-architecture.md` §11).
2. Free-Plan wählen. **Achtung: nur 2 aktive kostenlose Projekte** — plane sie
   als `beerquest-dev` und `beerquest-test` ein, ein drittes kostet.
3. Aus *Project Settings → API* übernehmen:
   - Project URL → `SUPABASE_URL`
   - **anon public** Key → `SUPABASE_ANON_KEY`

   Der **service_role**-Key wird nirgends gebraucht und darf die App nie
   erreichen.
4. Werte in `Config.xcconfig` eintragen. Die Datei steht in `.gitignore`.

```bash
supabase link --project-ref <deine-project-ref>
supabase db push          # wendet supabase/migrations/ an
```

## 4. GitHub-Secrets für den Keep-alive setzen

**Nicht optional.** Ohne diesen Workflow pausiert das kostenlose Projekt nach
7 Tagen und deine Tester öffnen eine tote App.

*Repository → Settings → Secrets and variables → Actions → New repository secret*

| Secret | Wert |
|---|---|
| `SUPABASE_URL` | wie oben |
| `SUPABASE_ANON_KEY` | wie oben |

Danach einmal *Actions → Supabase keep-alive → Run workflow* auslösen und auf
`HTTP 200` prüfen.

## 5. Tests

```bash
# Swift (lokal, nicht in der CI - siehe unten)
xcodebuild test -scheme BeerQuest -destination 'platform=iOS Simulator,name=iPhone 15'

# SQL gegen eine lokale Datenbank
supabase start
for f in supabase/migrations/*.sql; do psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" -v ON_ERROR_STOP=1 -f "$f"; done
for f in supabase/tests/*.sql;      do psql "$(supabase status -o env | grep DB_URL | cut -d= -f2-)" -v ON_ERROR_STOP=1 -f "$f"; done
```

### Warum kein Swift-Build in der CI?

macOS-Runner kosten bei GitHub 0,062 $/min gegen 0,006 $/min für Linux — das
Freikontingent von 2.000 Minuten schrumpft damit auf rund 200 macOS-Minuten
im Monat. Ein paar Builds pro Tag reißen das, und dann kostet das Projekt
Geld. Deshalb laufen auf GitHub **nur Linux-Jobs** (SQL-Tests, Keep-alive);
der Xcode-Build läuft lokal.

Sollte das Repository später öffentlich werden, sind auch macOS-Runner
kostenlos — dann kann eine Build-CI ergänzt werden.

## 6. Struktur

```
App/                    dünnes App-Target (Entry, Tabs, Info.plist)
BeerQuestKit/           Swift Package mit 7 Modulen
  Sources/BQCore/       Domäne, XP-/Level-Regeln - ohne SwiftUI, voll testbar
  Sources/BQAPI/        ViewState, Fehler, Konfiguration
  Sources/BQDesign/     Farben, Typo, wiederverwendbare Komponenten
  Sources/BQSession/    "wer bin ich"
  Sources/BQCheckIn/    Check-in-Flow          (ab P0.4)
  Sources/BQWorld/      Karte und Passport     (ab P0.5/P0.6)
  Sources/BQPlay/       Quests, Clan, Freunde  (ab P0.7)
  Tests/BQCoreTests/    Regeltests der Spielökonomie
supabase/migrations/    Schema, aufsteigend nummeriert
supabase/tests/         Regeltests in SQL
project.yml             XcodeGen-Spezifikation
```

**Modulregel:** Feature-Module importieren nur `BQCore`, `BQAPI`, `BQDesign`
und `BQSession` — niemals einander. Cross-Feature-Navigation läuft über die
Routen-Enums in `BQCore`.

## 7. Offene Punkte für P0.2

- Die CI braucht ein minimales `auth`-Schema (`auth.users`, `auth.uid()`),
  bevor das echte Schema angewendet werden kann — in nacktem Postgres gibt es
  das nicht. Vermerkt in `supabase/tests/README.md`.
- Der Städte-Seed (GeoNames `cities15000`, ~15 MB) wird nicht ins Repo
  eingecheckt, sondern über ein Import-Skript geladen. Attribution nach
  CC BY 4.0 gehört in Settings → About.
