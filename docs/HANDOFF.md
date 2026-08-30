# Handoff-Protokoll

Für den Projektmanager (ChatGPT). Neueste Session oben. Format und Regeln:
`.claude/skills/handoff/SKILL.md`.

---

## Session 2026-08-30 (4) — Gates nachkontrolliert, Release-Gate-Regel verankert

**Auftrag:** Die beiden offenen Gates aus dem v0.2-Handoff schließen
(Live-Verifikation der Free-Tier-Bedingungen, finale Backend-Entscheidung)
und die Release-Gate-Regel für internen vs. externen Test festhalten.
Danach den P0.1-Startplan ausgeben.

**Ergebnis:** Beide Gates waren bereits in Session (3) geschlossen — der
Auftrag bezog sich auf den v0.2-Handoff, der neuere Eintrag lag zu diesem
Zeitpunkt offenbar noch nicht vor. Ich habe die Zahlen für Supabase und
GitHub Actions **erneut direkt bei den Anbietern abgerufen: unverändert.**
Die Backend-Entscheidung ist jetzt als eigener §0 in der Kostenanalyse
dokumentiert statt nur in einer Alternativentabelle. Neu und inhaltlich der
eigentliche Zugewinn dieser Session: die **Release-Gate-Regel** als eigenes,
verbindliches Dokument.

**Wichtig zum Stand:** P0.1 ist **bereits umgesetzt** (Session 3, unter der
damaligen Freigabe „wenn beide Gates grün sind, beginne mit P0.1"). Der
Anweisung, jetzt nicht mit der Implementierung zu beginnen, folge ich: P0.2
ist **nicht** angefangen.

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Supabase Free final als P0-Backend bestätigt**, jetzt als `04-cost-analysis.md` §0 mit Kriterientabelle | Nachkontrolle bestätigt alle Werte: 500 MB DB, 5 GB Egress, 50.000 MAU, 1 GB Storage, 2 aktive Projekte, Pause nach 1 Woche, Pro ab 25 $/Monat. Auslastung bei 100 Nutzern ~5 %. | Ja, Ausstieg 3–5 Tage |
| 2 | **CloudKit endgültig geschlossen**, keine weitere Untersuchung | Wie vom PM freigegeben. Sachgrund unverändert: keine server-autoritative Logik möglich. | — |
| 3 | **Release-Gate-Regel als eigenes Dokument `docs/11-release-gates.md`**, nicht als Absatz im Plan | Eine Regel, die im Fließtext steht, wird beim nächsten Terminwunsch übersehen. Als eigenes Dokument mit 17-Zeilen-Checkliste und Nachweispflicht ist sie abhakbar. Verlinkt aus Plan, Feature-Matrix, README und `CLAUDE.md`. | Nein — bewusst bindend |
| 4 | **Stufe 2 umfasst 17 Punkte, nicht nur die vier genannten** | Der PM nannte Privacy Policy, Account-Löschung, Moderation und „alle relevanten Apple-Anforderungen". Letzteres habe ich ausbuchstabiert: zusätzlich Terms/EULA, Datenexport, Blockieren, Wortfilter, 24-Stunden-Reaktionsprozess, Privacy Manifest, App-Privacy-Labels, Age Rating, Review-Notes, Demo-Account, GeoNames-Attribution. Unausgesprochene Anforderungen sind die, an denen Reviews scheitern. | — |
| 5 | **Age Gate bleibt auch für den internen Test Pflicht** | Steht bereits in der Definition of Done P0. Eine Alkohol-App ohne Altersabfrage verteilen wir auch im eigenen Team nicht. | — |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `docs/11-release-gates.md` | **neu** — Stufe 1 (intern, reduziert zulässig) und Stufe 2 (extern, 17 Pflichtpunkte mit Grundlage und Status), plus vier Anwendungsregeln |
| `docs/04-cost-analysis.md` | neuer §0 mit der finalen Backend-Entscheidung; Nachkontroll-Vermerk im Kopf |
| `docs/09-implementation-plan.md` | Release-Gate-Regel als Kasten ganz oben; Hinweis bei der P1-Reihenfolge |
| `docs/03-feature-matrix.md` | Erklärung der ⚖️-Markierung mit Verweis |
| `CLAUDE.md` | Release-Gates als dritte harte Rahmenbedingung |
| `README.md` | Dokumentindex ergänzt |

### Was tatsächlich geprüft ist

| Teil | Status |
|---|---|
| Supabase Free, GitHub Actions Free | ✅ **Erneut direkt beim Anbieter abgerufen, Werte unverändert** |
| Alle übrigen Kostenpositionen | ✅ in Session (3) verifiziert, Quellen mit Abrufdatum in `04-cost-analysis.md` §8 |
| Release-Gate-Dokument | Redaktionell — die Guideline-Nummern stammen aus meiner Kenntnis der App Review Guidelines, nicht aus einem Abruf in dieser Session. Vor der externen Verteilung ist die Liste einmal gegen die dann gültigen Guidelines zu prüfen; das ist als Regel 3 im Dokument selbst hinterlegt. |

### Offene Punkte für den PM

Unverändert die drei aus Session (3) — alle drei brauchen deine Accounts,
ich kann sie nicht selbst erledigen:

1. **`xcodegen generate` und einmal bauen**, Fehler zurückspielen. Der
   Swift-Code aus P0.1 ist ungetestet, weil diese Umgebung weder Swift noch
   Xcode hat. *Blockiert P0.2 nicht — das ist reines SQL.*
2. **Supabase-Projekt in der EU-Region anlegen**, gleich als `dev` und `test`
   planen (nur 2 kostenlose Projekte). *Vor P0.2.*
3. **GitHub-Secrets `SUPABASE_URL` und `SUPABASE_ANON_KEY` setzen**, sonst
   pausiert das Projekt nach 7 Tagen. *Sobald das Projekt existiert.*
4. Redaktionsarbeit: Wortfilter-Blocklist (~200 Begriffe) vor P0.3,
   Bier-Seed (~60 Einträge) vor P0.2.
5. **Neu:** Der Übergang von Stufe 1 auf Stufe 2 ist deine Entscheidung.
   Sobald der Testkreis über das eigene Team hinausgeht, gilt Stufe 2 sofort
   und vollständig (~5 Tage Vorlauf einplanen).

### Bewusst NICHT gemacht

- **P0.2 nicht begonnen**, wie angewiesen. Das Schema existiert weiterhin
  nur als Spezifikation in `06-data-model.md`.
- **P0.1 nicht rückgängig gemacht.** Es wurde unter der vorherigen Freigabe
  umgesetzt und bleibt bestehen.
- **Guideline-Nummern nicht live abgerufen** — siehe Tabelle oben.
- **Keine erneute Verifikation der übrigen Services** (MapKit, TestFlight,
  GeoNames, Apple Developer Program). Sie wurden am selben Tag geprüft; ein
  zweiter Abruf innerhalb weniger Stunden hätte keinen Erkenntniswert.

### Nächster Schritt

Auf dein Startsignal: **P0.2** — Schema, Seeds und die spielentscheidenden
SQL-Funktionen samt Regeltests. In dieser Umgebung vollständig ausführbar
und damit verifizierbar.

---

## Session 2026-08-30 (3) — Gates verifiziert, P0.1 umgesetzt

**Auftrag:** Vor der Implementierung zwei Gates schließen — Free-Tier-Zahlen
live bei den Anbietern verifizieren und Supabase endgültig bestätigen. Danach
P0.1 (Projekt-Setup) umsetzen, keine P1/P2-Features.

**Ergebnis:** **Beide Gates grün.** Alle Free-Tier-Angaben wurden direkt bei den
Anbietern geprüft (Quellenliste in `04-cost-analysis.md` §8); der 0-€-Plan trägt
mit großem Abstand — wir nutzen ~5 % des Supabase-Kontingents bei 100 Nutzern.
Supabase bleibt die P0-Architektur, CloudKit ist geschlossen. P0.1 ist umgesetzt
und die SQL-Seite **verifiziert lauffähig**; der Swift-Teil ist geschrieben,
aber ungetestet (kein Xcode in dieser Umgebung, Details unten).

**Bei der Prüfung ist ein Problem aufgefallen, das nichts mit Kosten zu tun
hat — siehe Entscheidung 3. Es ist gelöst, kostet aber eine Streichung.**

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Gate 1 grün.** Supabase Free bestätigt mit 500 MB DB, 5 GB + 5 GB cached Egress, 50.000 MAU, 1 GB Storage, 2 aktive Projekte. Unser Bedarf bei 100 Nutzern: ~25 MB und ~240 MB Egress. | Verifiziert auf supabase.com/pricing. Rechnerisch trägt der Free Tier 1.000–2.000 aktive Nutzer. | — |
| 2 | **Gate 2 grün. Supabase bleibt, CloudKit geschlossen.** | Wie vom PM vorgegeben: Bedingungen sind mit dem 0-€-Ziel vereinbar. | — |
| 3 | ⚠️ **`MKLocalSearch` ersatzlos aus P0 gestrichen** — aus rechtlichen Gründen, nicht aus Kostengründen | Die Apple Maps Terms of Use §1.3 (vi) verbieten wörtlich die *creation of any databases based upon data or content provided through the Service*. Die Planung sah vor, aus einem bestätigten POI-Vorschlag eine dauerhafte, für alle Nutzer sichtbare Venue-Entität anzulegen — genau das ist untersagt. Die Bestätigung durch den Nutzer heilt das nicht. Apple selbst verweist auf die Frage nur auf *consult your legal counsel*, es gibt also keine Freigabe. **Ersatz:** Ortsname wird getippt, Koordinate kommt aus CoreLocation (eigene Gerätedaten), Vorschläge ausschließlich aus unseren eigenen Orten. Die Anzeige der Apple-Karte bleibt zulässig. | Ja — P1-Option wäre OpenStreetMap/Overpass (ODbL), bringt aber eine externe Abhängigkeit zurück |
| 4 | **Keep-alive läuft täglich statt alle 3 Tage** | Supabase verlangt *a few user requests to the database each day over the previous week*. Ein 3-Tages-Rhythmus wäre zu knapp gewesen. Kosten: ~30 Linux-Minuten von 2.000. | — |
| 5 | **Keine macOS-CI in P0** | Neu gefunden: macOS-Runner kosten 0,062 $/min gegen 0,006 $/min Linux (Faktor ~10) ⇒ nur ~200 macOS-Minuten im Freikontingent eines privaten Repos. **Das ist der einzige Posten, der das 0-€-Ziel kippen könnte.** Auf GitHub laufen nur Linux-Jobs; der Xcode-Build läuft lokal. | Ja — bei öffentlichem Repo sind macOS-Runner kostenlos |
| 6 | **Risiko R3 herabgestuft** (🟠 → 🟡) | Pausierte Projekte sind 90 Tage wiederherstellbar, Daten bleiben erhalten. Das Risiko ist Ausfallzeit, nicht Datenverlust. | — |
| 7 | **`.xcodeproj` wird nicht eingecheckt**, sondern per XcodeGen aus `project.yml` erzeugt | Vermeidet Merge-Konflikte in der `project.pbxproj`. Kostet einen zusätzlichen Werkzeug-Installationsschritt. | Ja |
| 8 | **`BQCore` bleibt frei von SwiftUI und Apple-Frameworks** | Die Spielökonomie ist damit plattformunabhängig testbar — und genau diese Regeln müssen stimmen. | — |

**Aufwandsänderung:** P0.4 von 6,0 auf 5,5 Tage (POI-Suche entfällt).
P0-Summe jetzt **35,5 Tage**, mit Puffer ~44.

### Geänderte Dateien

| Datei | Was |
|---|---|
| `docs/04-cost-analysis.md` | Verifizierte Werte, neuer §7 (Apple-Maps-Konflikt mit Wortlaut), neuer §8 (10 Quellen mit Abrufdatum) |
| `docs/10-risks.md` | R2 bestätigt und gelöst, R3 und R8 aktualisiert, **R16 neu** (macOS-CI-Kosten) |
| `docs/05-architecture.md`, `08-screens.md`, `03-feature-matrix.md` | POI-Suche entfernt, Ort-Anlage neu beschrieben |
| `docs/09-implementation-plan.md` | Kostencheck als erledigt, P0.4 −0,5 Tage, CI- und Keep-alive-Vorgaben |
| `docs/SETUP.md` | **neu** — Xcode, XcodeGen, Supabase, GitHub-Secrets, Teststrategie |
| `BeerQuestKit/` | **neu** — Package mit 7 Modulen; `Progression.swift` (XP-/Level-Regeln), Domänenmodelle, Routen, Design-Tokens und -Komponenten, `ViewState`/`BQError`, `SessionStore` |
| `BeerQuestKit/Tests/BQCoreTests/` | **neu** — 11 Tests auf die Spielökonomie |
| `App/`, `project.yml`, `Config.xcconfig.example` | **neu** — App-Target mit 5 Tabs und Add-Button, Info.plist, Sign-in-with-Apple-Entitlement, XcodeGen-Spezifikation |
| `supabase/` | **neu** — `config.toml` (Storage bewusst deaktiviert), erste Migration mit Erweiterungen und `app_config`, erster SQL-Regeltest |
| `.github/workflows/` | **neu** — SQL-Tests (Linux, Postgres 15) und täglicher Keep-alive |

### Was tatsächlich getestet ist — und was nicht

| Teil | Status |
|---|---|
| Migration `20260830000001_extensions.sql` | ✅ **Gegen echtes Postgres angewendet, läuft durch.** Zweiter Durchlauf ebenfalls grün (Idempotenz geprüft). |
| SQL-Regeltest `01_app_config.sql` | ✅ **Ausgeführt, grün** (`P0.1 Fundament ok`) |
| Swift-Code (Package, App-Target, Tests) | ⚠️ **Nicht kompiliert.** In dieser Umgebung gibt es weder Swift noch Xcode. Der Code ist sorgfältig geschrieben, aber ein Tippfehler würde sich erst bei dir zeigen. |
| XcodeGen-Spezifikation | ⚠️ **Nicht ausgeführt.** `xcodegen generate` ist ungeprüft. |
| Keep-alive-Workflow | ⚠️ **Nicht ausgeführt** — braucht die GitHub-Secrets, die nur du setzen kannst. |

Einschränkung zur SQL-Verifikation: lokal lief **Postgres 16**, die CI und
Supabase nutzen **15**. Alle verwendeten Erweiterungen sind in beiden
identisch; ein Unterschied ist nicht zu erwarten, aber auch nicht bewiesen.

### Offene Punkte für den PM

1. **Bitte einmal `xcodegen generate` und den Build ausführen** und mir
   Fehlermeldungen zurückspielen. Das ist die einzige Lücke in P0.1, die ich
   nicht selbst schließen kann. *Vor P0.2 nicht zwingend — P0.2 ist reines SQL.*
2. **GitHub-Secrets `SUPABASE_URL` und `SUPABASE_ANON_KEY` setzen.** Ohne den
   Keep-alive pausiert das Projekt nach 7 Tagen. Anleitung: `docs/SETUP.md` §4.
   *Spätestens sobald das Supabase-Projekt existiert.*
3. **Supabase-Projekt in der EU-Region anlegen** (`docs/SETUP.md` §3) und daran
   denken: nur **2 aktive kostenlose Projekte**, also gleich als `dev` und
   `test` planen. *Vor P0.2.*
4. **Die gestrichene POI-Suche ist eine spürbare UX-Verschlechterung beim
   allerersten Check-in an einem Ort** (zwei Wörter tippen statt antippen).
   Wenn sich das im Test als Bremse erweist, ist OpenStreetMap/Overpass die
   P1-Antwort. *Beobachten, nicht jetzt entscheiden.*
5. Unverändert offen aus Session 2: Wortfilter-Blocklist (~200 Begriffe) vor
   P0.3, Bier-Seed (~60 Einträge) vor P0.2 — beides Redaktionsarbeit.

### Bewusst NICHT gemacht

- **Kein P0.2-Schema.** Die Migration enthält nur Erweiterungen und
  `app_config`. Tabellen, Seeds und Spiel-Funktionen sind P0.2.
- **Keine Feature-Implementierung.** Die drei Feature-Module enthalten
  Platzhalter-Views, damit die App startet und die Navigationsstruktur steht.
- **Kein Illustrations-Set für Avatare.** `AvatarView` nutzt vorerst
  Emoji-Platzhalter; die Bundle-Assets kommen in P0.11.
- **Keine macOS-CI** — bewusst, siehe Entscheidung 5.
- **Keine rechtliche Prüfung.** Der Apple-Maps-Befund stützt sich auf den
  Wortlaut der Terms of Use und Apples eigene Forumsantwort. Die gewählte
  Lösung vermeidet das Problem vollständig, statt es auszulegen — deshalb
  ist keine juristische Bewertung nötig.

### Nächster Schritt

P0.2 — Schema, Seeds und die spielentscheidenden SQL-Funktionen
(`create_check_in`, `resolve_city`, `award_xp`) samt Regeltests. Reines SQL,
in dieser Umgebung vollständig ausführbar und damit verifizierbar.

---

## Session 2026-08-30 (2) — Product-/Architecture-Gate, v0.2

**Auftrag:** Planung überarbeiten unter zwei neuen harten Anforderungen —
0 € laufende Infrastrukturkosten und P0 als Vertical Slice statt
Feature-Sammlung. Zusätzlich: Handoff-Konvention dauerhaft im Repo verankern.
Noch keine Implementierung.

**Ergebnis:** Die Planung aus v0.1 war eine gute Zielarchitektur und ein
schlechter erster Schritt (43 Screens, 65 Tage, mehrere kostenpflichtige
Abhängigkeitspfade). v0.2 schneidet P0 auf **28 Screens und 36 Entwicklertage**
(mit Puffer ~45) und kommt auf **0 €/Monat bei 10 wie bei 100 Nutzern**. Der
vom PM vorgegebene Vertical Slice wurde geprüft und **kein Schritt gestrichen**
— gespart wird in der Tiefe jedes Schritts, nicht in der Anzahl. Der Clan
bleibt vollständig in P0. Ergänzt wurden drei kleine Features, die die App
spielerischer machen (unten, Entscheidung 6).

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Supabase Free bleibt**, trotz Vorgabe „Apple-nativ zuerst" | CloudKit wäre Apple-nativ und dauerhaft 0 €, kann aber **keine server-autoritative Logik**: XP, Level und Leaderboards wären in der Public Database frei fälschbar. Das kollidiert mit Anforderung 7 („manipulationsarm"). Postgres ist zudem ohne Lock-in — Ausstieg in 3–5 Tagen. | Ja, Plan B ist Cloudflare Workers + D1 (+8–10 Tage) |
| 2 | **Kein Geocoding-Anbieter, dauerhaft.** Stadt-/Landzuordnung aus eigener GeoNames-Tabelle per SQL | Der einzige Posten, der sonst pro Check-in Geld kostet — also für immer. Einmalig ~15 MB Daten statt eines dauerhaften Preises pro Anfrage. | Nein (und soll es nicht sein) |
| 3 | **Kein Storage, keine Uploads.** Avatare sind Bundle-Assets | Nutzergenerierte Bilder sind der einzige Posten, der mit Nutzung *und* Nutzerzahl skaliert — plus Bildmoderation. Entfällt vollständig. | Ja, P2 |
| 4 | **Invite per Code statt Universal Link in P0** | Universal Links brauchen Domain, Web-Hosting, AASA, Entitlements und einen Workaround für den App-Store-Umweg — für Tester, die sich persönlich kennen. Spart ~3 Tage und löst den v0.1-Blocker „Domain" ersatzlos auf. P1 setzt später auf dieselbe Server-Logik auf. | Ja, P1, ~2 Tage |
| 5 | **Social Quests, City Quests, Clan-/City-Leaderboard, City-/Country-Detail → P1** | Mit 10 Testern gibt es genau einen Clan; ein Clan-vs-Clan-Ranking mit einem Eintrag testet nichts. Solo-Quests testen dieselbe Frage wie Social Quests. ~9 Tage und 8 Screens gespart. | Ja, jederzeit |
| 6 | **Drei kleine Features ergänzt: Daily Quest, „Nächstes Ziel" auf Home, Wochen-Leaderboard** (zusammen ~1,5 Tage) | Der Planung v0.1 fehlte ein Grund, morgen wiederzukommen, und ein sichtbares Ziel jenseits von XP. Beides fällt ohne Scheduler aus dem vorhandenen XP-Ledger heraus. **Bewusst kein Check-in-Streak** — ein Streak, den man nur durch tägliches Trinken hält, ist genau das, was Vision §2 verbietet. | Ja |
| 7 | **Moderation, Account-Löschung, Privacy Policy → P1 (⚖️)** | Ein **interner** TestFlight-Kreis (bis 100 Personen im eigenen Team) durchläuft **kein Beta App Review**. Vor jedem *externen* Test bzw. App-Store-Release sind diese Punkte zwingend. Das Age Gate bleibt trotzdem in P0. | Ja — aber ⚖️ ist ein hartes Tor |
| 8 | **Keine Drittanbieter-SDKs.** Analytics = eigene `app_events`-Tabelle, Crash-Reports = Xcode/App Store Connect | 0 €, keine zusätzlichen Privacy-Labels, keine Abhängigkeit. Kostet ~30 Zeilen Code statt einer Integration. | Ja |
| 9 | **Keep-alive-Workflow** (GitHub Actions, alle 3 Tage) | Supabase pausiert kostenlose Projekte nach 7 Tagen Inaktivität — ein Tester würde eine tote App öffnen. Das reale Betriebsrisiko des Free Tiers. | — |
| 10 | **Bier-Seed von 300–500 auf ~60 reduziert** | Kuratierung auf Verdacht ist Arbeit ohne Erkenntnis. Was die Tester selbst eintragen, zeigt uns den tatsächlich nötigen Katalog. | Ja |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `CLAUDE.md` | **neu** — verankert beide Rahmenbedingungen (0 €, Vertical Slice) und die Handoff-Pflicht |
| `.claude/skills/handoff/SKILL.md` | **neu** — Format und Qualitätsregeln für dieses Protokoll |
| `docs/HANDOFF.md` | **neu** — dieses Protokoll |
| `docs/02-product-gate.md` | **neu** — Product Review A–F, geprüfter Vertical Slice, Definition of Done P0 (16 Kriterien) |
| `docs/03-feature-matrix.md` | **neu** — P0/P1/P2 über alle Features, plus Bilanz der Streichungen |
| `docs/04-cost-analysis.md` | **neu** — Kostentabelle, Free-Tier-Grenzen, geprüfte Alternativen, Ausstiegsplan |
| `docs/10-risks.md` | **neu** — 15 Risiken, plus die aus v0.1 entfallenen |
| `docs/05-architecture.md` | überarbeitet (war `02-`) — 0-€-Begründung je Komponente, 7 statt 11 Module, kein Web-Hosting/Storage/Edge Functions in P0 |
| `docs/06-data-model.md` | überarbeitet (war `03-`) — P0/P1-Markierung je Tabelle, 5 Tabellen weniger, `app_events`, Daily-Quest ohne Scheduler |
| `docs/07-user-flows.md` | überarbeitet (war `04-`) — nur P0-Flows, Invite per Code |
| `docs/08-screens.md` | überarbeitet (war `05-`) — 28 statt 43 Views |
| `docs/09-implementation-plan.md` | überarbeitet (war `06-`) — P0.1–P0.11 mit 36 Tagen, danach P1-Reihenfolge |
| `docs/01-analysis.md` | Hinweiskopf: Befunde gültig, Scope-Entscheidungen überholt |
| `README.md` | neuer Index |

### Offene Punkte für den PM

1. **Free-Tier-Zahlen sind Stand Mai 2026** und in P0.1 zu verifizieren. Sie
   sind der Boden der gesamten Kostenrechnung. *Spätestens: vor P0.1.*
2. **CloudKit wurde gegen die Vorgabe „Apple-nativ zuerst" abgelehnt.** Das ist
   die einzige Stelle, an der ich von der vorgegebenen Priorisierung abweiche —
   begründet in `04-cost-analysis.md` §4. *Wenn Widerspruch, dann jetzt: die
   Entscheidung bestimmt das gesamte Datenmodell.*
3. **Apple Developer Program** wird ab P0.6 gebraucht (TestFlight), nicht zum
   Start. *Spätestens: in ~4 Wochen Kalenderzeit.*
4. **Der interne TestFlight-Kreis** (bis 100 Personen) muss aus dem eigenen
   Team-Account bestückt werden. Ist der Kreis größer oder extern, greift
   sofort das P1-Paket ⚖️ (Moderation, Löschung, Privacy Policy, +5 Tage).
   *Entscheidung vor P0.11.*
5. **Wortfilter-Blocklist** (~200 Begriffe) muss inhaltlich befüllt werden —
   das ist Redaktionsarbeit, keine Entwicklung. *Vor P0.3.*
6. **Bier-Seed (~60 Einträge)** braucht eine Auswahl für DE/AT/IT/CZ/UK/US.
   *Vor P0.2.*
7. Aus v0.1 weiterhin offen, aber unkritisch: UI-Sprache Englisch (D1),
   nur Sign in with Apple (D2), Tages-Cap 500 XP (D8). Alle drei sind so
   umgesetzt; Widerspruch ist bis zur jeweiligen Phase folgenlos.

### Bewusst NICHT gemacht

- **Kein Code.** Der Auftrag lautete ausdrücklich, vor der Implementierung zu
  planen. Es existiert weiterhin kein Xcode-Projekt und kein SQL.
- **Free-Tier-Limits nicht live geprüft** — die Zahlen stammen aus meinem
  Wissensstand (Mai 2026), nicht aus einem Abruf der Anbieterseiten. Als
  Aufgabe in P0.1 hinterlegt, siehe offener Punkt 1.
- **Keine rechtliche Prüfung** der MapKit-Nutzungsbedingungen (Risiko R2). Die
  gewählte Umsetzung ist so gebaut, dass sie die Bedingungen einhalten sollte —
  bestätigen kann das nur eine juristische Prüfung vor App-Store-Einreichung.
- **`docs/00-product-vision.md` unverändert** — das ist das Quelldokument des
  PM und wird nicht von mir überschrieben.
- **Keine Pull Requests** — nicht angefordert. Alles liegt auf
  `claude/beer-quest-mvp-spec-dpjh2i`.

### Nächster Schritt

Freigabe der offenen Punkte 1–2, danach Beginn der Implementierung mit
P0.1 (Projekt-Setup + Verifikation der Free-Tier-Zahlen).

---

## Session 2026-08-30 (1) — Erste Spezifikation, v0.1

**Auftrag:** STEP 1–5 der Product Vision (kritische Analyse, technische
Spezifikation, User Flows, Screens, Implementierungsplan), ohne Code.

**Ergebnis:** Vollständige MVP-Spezifikation mit 43 Screens und ~65
Entwicklertagen. **Durch v0.2 im Scope überholt**, in den Befunden gültig.

**Wichtigste Befunde (weiterhin gültig):** Age Gate, In-App-Account-Löschung
und UGC-Moderation fehlten vollständig und sind App-Store-Pflicht ·
„% explored" ist nicht berechenbar und würde rückwärts laufen · „keine
komplexe Bierdatenbank" widerspricht „neues Bier entdecken +50" · Clan-XP war
undefiniert (Vision §17 impliziert Faktor 0,6) · XP als Ledger und kanonische
Referenzdaten müssen von Anfang an stimmen.

**Dateien:** `docs/00-product-vision.md` bis `docs/06-implementation-plan.md`
(letztere in v0.2 umnummeriert und überarbeitet).
