# Handoff-Protokoll

Für den Projektmanager (ChatGPT). Neueste Session oben. Format und Regeln:
`.claude/skills/handoff/SKILL.md`.

---

## Session 2026-08-30 (7) — Produkt-DNA, Visual Direction, Design System, P0.3-Server

**Auftrag:** Consolidated Product Direction — XP-Fix, P0.3 starten, Produkt-DNA
und Daydrinking festhalten, keine Emoji-UI, drei Visual Directions mit
Empfehlung, Design System vorbereiten.

**Ergebnis:** Punkt 1 und 2 des Auftrags (XP-Erst-Check-in, Handoff) waren
bereits in Session (6) erledigt — der Auftrag bezog sich auf einen älteren
Stand. Neu in dieser Session: der **Serverteil von P0.3** (implementiert und
getestet, 7 Testdateien grün), die **drei Visual Directions mit Empfehlung**,
das **Design System als Token-Schicht**, die **Produkt-DNA** inklusive
Daydrinking, und die **Entfernung aller Emoji aus der UI-Schicht**.

### Zur Reihenfolge — eine bewusste Abweichung

Der Auftrag nennt P0.3 (Punkt 3) vor der Design-Richtung (Punkt 4). §19 und
§20 desselben Auftrags sagen aber: „bevor viele Screens entstehen" und „bevor
wir große UI-Arbeiten machen". **P0.3 sind sechs Screens.** Sie auf einer
unbestätigten visuellen Richtung zu bauen hieße, sie zweimal zu bauen.

Deshalb: **P0.3-Server jetzt** (unabhängig von jeder Optik, hier vollständig
testbar), **P0.3-UI nach der Design-Entscheidung**. Das ist die einzige
Stelle, an der ich von der vorgegebenen Reihenfolge abweiche.

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Empfehlung: Direction A „Dark Adventure"**, mit drei gezielten Anleihen aus C und typografischer Disziplin aus B | A ist die einzige Richtung, die alle fünf Prüffragen besteht. Entscheidend ist ihre **Metapher** — Karte, Pass, Stempel, Wappen, Medaille. Eine Metapher beantwortet Gestaltungsfragen, die noch niemand gestellt hat: Wenn Seasons kommen, ist klar, wie sie aussehen (eine neue Passseite). B wäre ein sehr schönes Untappd; C hat von allen dreien das höchste Risiko, generisch zu wirken, und kollidiert mit 18+. | **Entscheidung liegt beim PM** |
| 2 | **Alle Emoji aus der UI entfernt.** `AvatarView` nutzt jetzt Monogramme; Badge-Icons in der Datenbank heißen `badge.first-beer` statt `1F37A`; alle Symbolnamen liegen zentral in `BQIcon` | Ein Tausch des Icon-Sets ist damit eine Datei, kein Streifzug durch alle Views. | — |
| 3 | **`countries.flag_emoji` bleibt** — bewusste Ausnahme, zur Entscheidung gestellt | Landesflaggen als Unicode sind etabliert, sofort verständlich und plattformseitig gepflegt. Die Alternative wären 249 eigene Assets. Empfehlung: als Daten behalten, UI-Entscheidung später im Passport-Design. | Ja |
| 4 | **Design System als Token-Schicht** (`BQDesign/Tokens.swift`), alte `Theme.swift` ersetzt | Farben, Typo, Abstände, Radien, Motion und Icons an einer Stelle. Regel in `CLAUDE.md`: kein View definiert eigene Werte. | — |
| 5 | **`CollectionState` als zentraler Typ** in `BQCore`, Materialstufen statt Neonrahmen | Vier Zustände (locked/discovered/completed/mastered) einmal definiert, überall gleich dargestellt. | — |
| 6 | **Alterprüfung serverseitig**, aus dem Geburtsjahr | Der Age-Gate-Screen ist Komfort; die Prüfung passiert in `complete_onboarding`. Die Jahresrechnung ist um bis zu ein Jahr konservativ — hier die richtige Richtung. | — |
| 7 | **Mindestalter global 18** über `app_config['age.min_years']`, keine Länderdifferenzierung | Die USA verlangen 21. Für einen internen TestFlight in Europa ist 18 richtig; die Länderdifferenzierung gehört vor den externen Test und ist in `11-release-gates.md` vermerkt. Ohne Scope-Ausweitung. | Ja, ein Konfigurationswert |
| 8 | **Wortfilter als Tabelle** `banned_terms`, nicht als Konstante im Code | Die Liste ist Redaktionsarbeit und muss ohne App-Update pflegbar sein. 12 Begriffe als Grundstock; die vollen ~200 bleiben offener Punkt. | — |
| 9 | **Daydrinking-Prüfregel formuliert:** „Lässt sich die Quest durch *mehr Trinken* schneller erfüllen? Dann ist sie falsch entworfen." | Alle fünf Beispielquests verlangen **eine** Entdeckung unter einer Bedingung, nicht *mehr* Entdeckungen. Die Bedingung ist der Spielinhalt. Damit ist die Vorgabe aus §8 technisch prüfbar statt nur gut gemeint. | — |

### ⚠️ Ein Widerspruch, der eine Entscheidung braucht

§13 fordert einen `locked`-Zustand im Passport. `07-user-flows.md` F4 sagt
bisher das Gegenteil: keine Locked-Listen, sonst entsteht das Gefühl eines
unendlichen Katalogs.

**Vorschlag:** `locked` nur auf **endliche, überschaubare Mengen** —
Badges ✅, Städte innerhalb eines bereits besuchten Landes ✅, Quest-Ketten ✅.
**Nie** der offene Bierkatalog („12 von 187.000") und nie alle Länder der Welt
(„12 von 249" sieht nach Scheitern aus).

Faustregel: **`locked` ist eine Einladung, keine Bilanz.** Wenn die Zahl
rechts vom Bruchstrich entmutigt, ist der Zustand falsch angewendet.
Bis zur Entscheidung nutzt P0 den Zustand nur für Badges.

### Geänderte Dateien

| Datei | Was |
|---|---|
| `docs/13-visual-direction.md` | **neu** — drei Richtungen, Vergleichsmatrix, Empfehlung |
| `docs/14-product-dna.md` | **neu** — Produktprinzip, Weltkarte, Passport-Zustände, Clans, Daydrinking, keine Emoji, visuelle Identität |
| `docs/15-design-system.md` | **neu** — Tokens, Komponenten, Prüfregeln |
| `supabase/migrations/…0010_onboarding.sql` | **neu** — `check_username`, `complete_onboarding`, `banned_terms`, `is_term_allowed` |
| `supabase/tests/07_onboarding.sql` | **neu** — Alterprüfung, Wortfilter, Erst-Quest, Invite, Kollisionen |
| `BeerQuestKit/…/Tokens.swift` | **neu**, ersetzt `Theme.swift` |
| `BeerQuestKit/…/CollectionState.swift` | **neu** |
| `BeerQuestKit/…/Components.swift` | neu geschrieben: `ScreenBackground`, `NextGoalRow`, `CollectibleTile`, emoji-freier `AvatarView` |
| `…0007_seed_static.sql` | Badge-Icons semantisch, `tier` als Materialstufe |
| `App/RootView.swift`, Platzhalter | nutzen `BQIcon` und `ScreenBackground` |
| `docs/03-feature-matrix.md` | Abschnitte Visuelle Identität und Daydrinking mit P0/P1/P2 |
| `CLAUDE.md` | Produktprinzip und Emoji-/Token-Regel |
| `README.md`, `docs/08-screens.md` | Index und Passport-Zustände |

### Was tatsächlich getestet ist

| Regel | Nachweis |
|---|---|
| Minderjähriger kann kein Profil anlegen — serverseitig | ✅ Test 07 |
| Wortfilter greift, auch bei Teiltreffern (`beerquest_team`) | ✅ Test 07 |
| Username-Format und -Kollision | ✅ Test 07 |
| Onboarding nur einmal möglich | ✅ Test 07 |
| Erst-Quest wird angenommen, `next_goal` ist gefüllt | ✅ Test 07 |
| Invite-Einlösung: Freundschaft, XP auf beiden Seiten, `use_count`, `invited_by`, Badge | ✅ Test 07 |
| Alle bisherigen Regeln unverändert | ✅ Tests 01–06 |

**Ungetestet:** der gesamte Swift-Code, inklusive der neuen Token-Schicht —
diese Umgebung hat kein Xcode. Das ist jetzt die dritte ungetestete
Swift-Änderung in Folge; siehe Vorschlag 1.

### Offene Punkte für den PM

1. **Visual Direction bestätigen oder ablehnen** (`13-visual-direction.md`).
   Solange sie offen ist, baue ich keine Onboarding-UI. **Das ist der einzige
   echte Blocker für P0.3.**
2. **Passport-`locked`-Regel entscheiden** (Widerspruch oben).
3. **`xcodegen generate` und einmal bauen.** Inzwischen dringlich: drei
   Swift-Änderungen sind ungetestet gestapelt.
4. Supabase-Projekt anlegen, `supabase db push`, GitHub-Secrets setzen.
5. Wortfilter-Blocklist (~200 Begriffe) und Bier-Seed-Review — Redaktionsarbeit.
6. `countries.flag_emoji` behalten oder ersetzen (Entscheidung 3).

### Bewusst NICHT gemacht

- **Keine Onboarding-UI** — wartet auf die Design-Entscheidung.
- **Kein Redesign bestehender Screens.** Es gibt nur Platzhalter; die Tokens
  sind vorbereitet, nicht angewendet.
- **Keine Daydrinking-Implementierung** — reine Vision, P1/P2.
- **Keine Länder-Altersgrenzen**, keine Icon-Assets, keine Schriften: das sind
  Beschaffungs- und Freigabeentscheidungen, keine Bauaufgaben.

### Nächster Schritt

Nach Bestätigung der Visual Direction: **P0.3-UI** (S01–S06) auf der
Token-Schicht.

### Vorschläge und Themen von mir

1. **Dringend: einmal bauen lassen.** Es liegen jetzt drei ungetestete
   Swift-Änderungen übereinander (P0.1-Gerüst, Token-Umbau, Komponenten).
   Wenn im Gerüst ein Fehler steckt, finde ich ihn erst, wenn schon die
   Onboarding-Screens darauf stehen. Fünf Minuten deiner Zeit sparen mir und
   dir eine unangenehme Fehlersuche.
2. **Zur Visual Direction, ehrlich gesagt:** Der Text kann eine Richtung
   beschreiben, aber nicht zeigen. Wenn dir die Entscheidung auf dieser
   Grundlage schwerfällt, kann ich zu Direction A **einen einzelnen Screen
   als visuellen Prototyp** bauen (Home mit XP-Bar, Quest-Karte, Passport-
   Streifen) — das macht die Richtung in zehn Minuten greifbarer als drei
   Seiten Prosa. Sag Bescheid, ob du das willst; es ist bewusst kein Redesign.
3. **Beobachtung zu Direction A:** Ihre Schwäche ist real — sie signalisiert
   „Spiel" nicht sofort. Das fangen wir über den Reward-Moment und die
   prominente Progression ab. Wenn du beim ersten Tester merkst, dass die App
   zu ruhig wirkt, ist die Stellschraube **Motion im Reward-Screen**, nicht
   die Farbpalette.
4. **`main` und der Arbeitsbranch laufen weiter auseinander** — inzwischen
   acht Commits. Vorschlag steht: nach dem Build mergen.
5. **Ein Gedanke zu Daydrinking:** „First Pour" (unter den Ersten, die einen
   Ort an einem Tag entdecken) ist die spannendste der fünf Ideen, weil sie
   **echten sozialen Wettbewerb ohne Konsum** erzeugt — und weil sie mit
   unseren Daten schon heute berechenbar wäre. Sie ist aber auch die
   einzige, die einen Anreiz schafft, *früh* zu trinken. Ich würde sie
   entschärfen zu „einer der Ersten **diese Woche**" — gleicher Reiz, kein
   Zeitdruck. Nur ein Vorschlag für P1.

---

## Session 2026-08-30 (6) — Erst-Check-in vom Cap befreit, Monetarisierung als P1 festgelegt

**Auftrag:** Vor P0.3 zwei Dinge: (1) der allererste Check-in eines Nutzers
soll seinen vollen Discovery-Reward bekommen statt auf 500 XP gedeckelt zu
werden, (2) die Monetarisierungsstrategie festhalten — Ads in P1, Premium
in P2, nichts davon in P0. Dazu das Bier-Dedupe als P0.4-UI-Anforderung
schärfen.

**Ergebnis:** Beides umgesetzt. Die Cap-Änderung ist **serverseitig
implementiert und getestet** — alle sechs SQL-Regeltests laufen grün,
inklusive eines neuen Tests, der beide Hälften der Regel prüft. Die
Monetarisierungsentscheidung liegt als eigenes Dokument vor und ist in
`CLAUDE.md` als Leitplanke verankert, damit sie niemand versehentlich nach
P0 zieht.

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Erster Check-in ist vom Tages-Cap befreit**, Schalter `app_config['xp.first_checkin_uncapped']` | Wie vom PM entschieden. Über `app_config` steuerbar statt hartcodiert — die Ausnahme lässt sich ohne App-Update oder Migration abschalten, falls sie sich im Test als falsch erweist. | Ja, ein Konfigurationswert |
| 2 | **Ab dem zweiten Check-in gilt der Cap unverändert — auch am selben Tag** | Die 550 XP des ersten Check-ins zählen auf das Tageskonto. Ein zweiter Check-in am selben Tag gibt daher 0 XP. Das ist die konsequente Lesart von „danach gilt weiterhin 500". | Ja |
| 3 | **Swift-Logik unverändert**, nur Dokumentation und ein Test ergänzt | Der Client rechnet nie XP, er zeigt an, was der Server liefert. Eine Spiegelung der Ausnahme wäre eine zweite Wahrheitsquelle ohne Nutzen. Ergänzt: ein Test, der festhält, dass der volle Erst-Reward (550) über dem Cap (500) liegt — damit fällt auf, wenn jemand die Werte später auseinanderlaufen lässt. | — |
| 4 | **`cfg_bool` in Migration 0003 statt 0009** | Sonst hinge Migration 0006 (`create_check_in`) von einer späteren Migration ab. Migrationen dürfen nur rückwärts referenzieren. | — |
| 5 | **Monetarisierung als eigenes Dokument `docs/12-monetization.md`** statt als Absatz in der Vision | Dieselbe Überlegung wie bei den Release-Gates: eine Regel im Fließtext wird übersehen. Enthält P0/P1/P2, die ausdrücklichen Verbote und die technischen Vorgaben mit Status. | — |
| 6 | **Kopplungsregel für Rewarded Ads als harte Grenze formuliert** und in `CLAUDE.md` aufgenommen | Rewarded Ads an Check-ins zu koppeln würde über die Hintertür genau das System erzeugen, das Product Vision §2 verbietet: mehr trinken ⇒ mehr Ad-Gelegenheiten ⇒ mehr XP. Nur Quest- und Achievement-Aktivität ist zulässig. | Nein — bewusst bindend |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `supabase/migrations/…0009_first_checkin_uncapped.sql` | **neu** — Konfigurationsschalter |
| `…0003_functions_core.sql` | `cfg_bool` ergänzt |
| `…0006_functions_checkin.sql` | Cap-Ausnahme für den ersten Check-in |
| `supabase/tests/06_first_checkin_cap.sql` | **neu** — prüft beide Hälften der Regel |
| `supabase/tests/02_check_in_core.sql` | erwartet jetzt 550 statt 500 |
| `docs/12-monetization.md` | **neu** — die vollständige Entscheidung |
| `docs/03-feature-matrix.md` | Abschnitt Monetarisierung mit P0/P1/P2 und drei „nie"-Zeilen |
| `docs/05-architecture.md` | Ad-Platzierbarkeit in der Vorbereitungstabelle |
| `docs/08-screens.md` | Bier-Vorschlagslogik als harte P0.4-Anforderung, mit dem Peroni-Beispiel |
| `docs/09-implementation-plan.md` | Abnahmekriterium für P0.4 ergänzt |
| `docs/06-data-model.md`, `07-user-flows.md` | Cap-Ausnahme dokumentiert |
| `CLAUDE.md` | Monetarisierung als dritte Leitplanke |
| `BeerQuestKit/…/Progression.swift`, `ProgressionTests.swift` | Dokumentation und ein Test |

### Was tatsächlich getestet ist

| Regel | Nachweis |
|---|---|
| Erster Check-in gibt volle 550 XP, nicht als gedeckelt markiert | ✅ Test 02, Test 06 |
| Der volle Erst-Reward übersteigt den Cap tatsächlich | ✅ Test 06 prüft das explizit gegen `app_config` |
| Zweiter Check-in am selben Tag: 0 XP | ✅ Test 02 |
| Tag 2, zwei Check-ins à 250 XP: exakt 500, beide ungedeckelt | ✅ Test 06 |
| Tag 2, dritter Check-in: 0 XP, als gedeckelt markiert, Entdeckungen zählen weiter | ✅ Test 06 |
| Quest-XP bleibt vom Cap ausgenommen | ✅ Test 04 |
| Alle bisherigen Regeln unverändert grün | ✅ Tests 01–05 |

Beim Schreiben von Test 06 ist mir ein eigener Fehler unterlaufen: Ich hatte
für den zweiten Tag München gewählt, das aber an Tag 1 bereits entdeckt war —
der Test erwartete 250 XP und bekam 100. Die Logik war korrekt, der Test
falsch. Korrigiert auf Hamburg.

**Weiterhin ungetestet:** der gesamte Swift-Code — diese Umgebung hat kein Xcode.

### Offene Punkte für den PM

1. **`xcodegen generate` und Build** — weiterhin offen, blockiert P0.3 aber
   nicht mehr lange: P0.3 ist überwiegend Swift. **Spätestens vor P0.3.**
2. **Supabase-Projekt anlegen** und `supabase db push` — jetzt liegen neun
   Migrationen bereit. Danach die GitHub-Secrets.
3. **Alles liegt auf `claude/beer-quest-mvp-spec-dpjh2i`, nicht auf `main`.**
   Auf `main` steht nur die alte README. Wer das Repo ohne Branch-Angabe
   öffnet, sieht praktisch nichts. Vorschlag unten.
4. Wortfilter-Blocklist (~200 Begriffe) vor P0.3 — Redaktionsarbeit.

### Bewusst NICHT gemacht

- **Kein Ad-SDK, kein Monetarisierungscode.** Nur Dokumentation.
- **Keine Änderung an der Swift-XP-Logik** — siehe Entscheidung 3.
- **P0.3 noch nicht begonnen.** Ich wollte die Cap-Änderung abgeschlossen und
  getestet haben, bevor eine neue Phase beginnt.
- **`profiles.tier` weiterhin nirgends abgefragt** — die Spalte existiert,
  legt aber nichts fest.

### Nächster Schritt

P0.3 — Sign in with Apple, Onboarding S01–S06, `complete_onboarding` mit
serverseitiger Altersprüfung, Ziel 60 Sekunden.

### Vorschläge und Themen von mir

1. **Ich würde P0.3 zweiteilen und mit dem Server anfangen.** Der SQL-Teil
   (`complete_onboarding`, `check_username`, Wortfilter-Blocklist) ist hier
   vollständig testbar; der Swift-Teil ist es nicht. Wenn ich beides in einem
   Zug schreibe, stapeln sich zwei ungetestete Swift-Phasen (P0.1 und P0.3)
   übereinander, und ein Fehler in P0.1 fällt erst auf, wenn schon viel
   darauf aufbaut. **Konkret: gib mir einmal die Rückmeldung, ob
   `xcodegen generate` und der Build durchlaufen** — fünf Minuten für dich,
   und ich kann den Swift-Teil auf gesichertem Grund bauen.
2. **`main` und der Arbeitsbranch laufen auseinander.** Sechs Commits liegen
   nur auf dem Branch. Bei einem Solo-Nebenprojekt ohne Review-Prozess spricht
   wenig dagegen, auf `main` zu mergen — dann sieht der PM ohne Branch-Angabe
   alles. **Vorschlag: nach der Build-Bestätigung mergen.** Sag Bescheid, ich
   mache es oder öffne einen PR, wenn du es dokumentiert haben willst.
3. **Zur Cap-Ausnahme, eine Beobachtung:** Sie wirkt nur beim allerersten
   Check-in **überhaupt**, nicht beim ersten Check-in eines Tages. Ein Nutzer,
   der an einem Reisetag drei neue Länder besucht (900 XP), sieht weiterhin
   den Cap. Das ist meines Erachtens richtig so — die Ausnahme soll den
   Einstiegsmoment schützen, nicht den Cap aushöhlen. Falls du auch den
   Reisefall entschärfen willst, wäre ein Wochen-Cap statt eines Tages-Caps
   die elegantere Lösung. Aber das ist eine echte Produktänderung, keine
   Feinjustierung — deshalb nur als Beobachtung.
4. **Zur Monetarisierung, ein Hinweis für P1:** Werbenetzwerke haben
   Richtlinien zu Alkoholinhalten, und die Kombination „Alkohol-App + Rewarded
   Ads + 17+/18+" kann die Zahl der verfügbaren Netzwerke einschränken oder
   die eCPM drücken. Das ist kein Grund, den Plan zu ändern — aber es lohnt
   sich, das **vor** der SDK-Integration zu prüfen, nicht danach. Als Punkt
   in `12-monetization.md` vermerkt.
5. **Ein Gedanke zum Rewarded-Ad-Beispiel:** „+50 Bonus XP" nach einer Quest
   ist sauber an Achievement-Aktivität gekoppelt. Noch besser fände ich
   Belohnungen, die **gar keine XP** sind — etwa ein kosmetisches Element,
   eine zusätzliche Quest-Slot für einen Tag oder ein Badge-Fortschritt.
   Damit bleibt die XP-Ökonomie vollständig unberührt von Werbung, und das
   Versprechen aus Vision §2 ist auch dann noch wahr, wenn jemand die
   Kopplungsregel später aufweichen wollte. Nur ein Vorschlag für P1.

---

## Session 2026-08-30 (5) — P0.2 Datenbank-Fundament abgeschlossen

**Auftrag:** Mit P0.1 beginnen, 0-€-Anforderung und Vertical Slice einhalten,
nach jeder Phase den Handoff aktualisieren.

**Ergebnis:** P0.1 war bereits fertig (Sessions 3 und 4), deshalb ist
**P0.2 umgesetzt**: Schema, Spiel-Logik, RLS und Seeds. Das ist der Teil, an
dem das Produkt hängt — und er ist **gegen eine echte Postgres-Instanz
getestet**, nicht nur geschrieben. `./supabase/ci/run_local.sh` läuft von Null
durch: Bootstrap → 8 Migrationen → Idempotenzprüfung → 3 Seeds → 5 Regeltests,
alle grün.

Der Core Loop funktioniert nachweislich: Ein Check-in in Cecina mit einem
Peroni ergibt 4 Entdeckungen, 550 rohe XP, gedeckelt auf 500, Level 2 — und
Stadt und Land wurden automatisch aus dem Ort abgeleitet, ohne dass sie
abgefragt wurden.

### Entscheidungen

| # | Entscheidung | Begründung | Umkehrbar? |
|---|---|---|---|
| 1 | **Ort-Dedupe erweitert** um `word_similarity ≥ 0.9` (beidseitig, Mindestlänge 5) zusätzlich zu `similarity ≥ 0.6` | Beim Testen fiel auf: „Cafe Belge" vs. „Cafe Belge Brussels" erreicht nur 0,58 und wäre als zweiter Ort angelegt worden — genau das Szenario aus Risiko R7. Die Mindestlänge verhindert, dass ein Ort namens „Bar" mit jedem „Bar Irgendwas" verschmilzt. | Ja, ein Schwellwert |
| 2 | **Quest-Vorlage `beer_and_place` durch `three_beers` ersetzt** | Die freigegebene Goal-DSL kennt keine zusammengesetzten Ziele („1 Bier **und** 1 Ort"). Sie dafür zu erweitern wäre eine Scope-Ausweitung gewesen — laut deiner Vorgabe erst dokumentieren, nicht eigenmächtig ausweiten. Deshalb die konservative Variante innerhalb der DSL. Die alte Vorlage wird deaktiviert statt gelöscht, damit laufende Quests ihren Fremdschlüssel behalten. | Ja — wenn du das zusammengesetzte Ziel willst, sag Bescheid, dann bauen wir den DSL-Typ |
| 3 | **`norm_name` ohne `unaccent`** | Die Erweiterung ist nicht in jeder Umgebung verfügbar; `pg_trgm` fängt Umlaut-Varianten in der Praxis ab. Eine Abhängigkeit weniger. | Ja |
| 4 | **Landfallback ohne Stadt:** nächstgelegenes Länderzentrum | Grob, aber besser als ein Check-in ohne Land. Betrifft nur Orte weiter als 60 km von jeder bekannten Stadt. | Ja |
| 5 | **Funktionsrechte: erst allen entziehen, dann gezielt freigeben** | Postgres vergibt `EXECUTE` standardmäßig an `PUBLIC`, und `authenticated` erbt davon. Ein `revoke from authenticated` allein wirkt **nicht** — `award_xp` wäre für jeden Client aufrufbar gewesen, also freie XP-Vergabe. Der Test 05 hat genau das aufgedeckt. Client darf jetzt exakt vier Funktionen aufrufen. | Nein |
| 6 | **Reward-Paket wird bei Wiederholung rekonstruiert**, nicht gespeichert | Vermeidet eine zusätzliche Spalte im freigegebenen Datenmodell. Entdeckungen hängen über `first_check_in` am Check-in, XP über `ref_id` — das genügt. | Ja |
| 7 | **Städte-Vollimport per Skript, nicht im Repo** | ~15 MB gehören nicht in die Versionsverwaltung. `supabase/seed/import_geonames.sh` lädt Länder und ~29.000 Städte; die Flaggen-Emoji werden aus dem ISO-Code berechnet statt gepflegt. | — |

### Geänderte Dateien

| Datei | Was |
|---|---|
| `supabase/migrations/…0002_schema.sql` | 20 Tabellen, 9 Enum-Typen, alle Indizes. Nur P0 — keine P1-Tabellen |
| `…0003_functions_core.sql` | `cfg_int`, `norm_name`, Level-Kurve, `geohash7`, `resolve_city` |
| `…0004_functions_xp.sql` | `award_xp` (idempotent), Ledger-Trigger, `capped_xp_today` |
| `…0005_functions_catalog.sql` | `find_or_create_beer`, `find_or_create_venue` mit Dedupe |
| `…0006_functions_checkin.sql` | **`create_check_in`** — der zentrale Call, plus `user_metric`, `check_badges`, `next_goal`, `checkin_reward` |
| `…0007_seed_static.sql` | 5 Quest-Vorlagen, 4 Badges, `daily_quest_code` ohne Scheduler |
| `…0008_rls.sql` | RLS auf 19 Tabellen, Lese-Policies, Funktionsrechte |
| `supabase/seed/01–03` | 12 Länder, 27 Städte, 65 Biere |
| `supabase/seed/import_geonames.sh` | Vollimport für Produktion |
| `supabase/ci/bootstrap.sql`, `run_local.sh` | Rollen- und `auth`-Nachbildung, kompletter Testlauf |
| `supabase/tests/02–05` | Core Loop, Idempotenz und Dedupe, Quests und Clan-XP, RLS |
| `.github/workflows/sql-tests.yml` | Nutzt jetzt Bootstrap und Seeds |
| `docs/06-data-model.md` | Umsetzungsstand mit den 5 Abweichungen im Kopf |
| `docs/09-implementation-plan.md`, `README.md`, `SETUP.md` | Status P0.2 erledigt, Testanleitung |
| `.claude/skills/handoff/SKILL.md`, `CLAUDE.md` | Neu: Vorschläge und Bedenken gehören immer auch in den Handoff |

### Was tatsächlich getestet ist

| Regel | Nachweis |
|---|---|
| Core Loop: 4 Entdeckungen, Stadt/Land automatisch, Level-Up | ✅ Test 02 |
| Tages-Cap greift, Check-in zählt trotzdem für den Passport | ✅ Test 02 |
| Idempotenz: gleicher `client_uuid` verdoppelt nie XP | ✅ Test 03 |
| Ort-Dedupe: 150 m ja, 2 km nein | ✅ Test 03 |
| Bier-Dedupe über normalisierte Identität | ✅ Test 03 |
| Quest-Fortschritt, Abschluss, Belohnung | ✅ Test 04 |
| Clan-XP = 60 % der persönlichen XP, Caches stimmen mit dem Ledger überein | ✅ Test 04 |
| Quest-XP wird **nicht** gedeckelt | ✅ Test 04 |
| Keine Schreibrechte für `authenticated`, `award_xp` gesperrt | ✅ Test 05 |
| Idempotenz der Migrationen | ✅ jeder Lauf wendet sie zweimal an |

**Einschränkung:** Getestet auf Postgres 16 (lokal verfügbar), CI und Supabase
laufen auf 15. Alle verwendeten Erweiterungen sind identisch; die CI wird das
auf 15 bestätigen, sobald du das Repo pusht.

**Weiterhin ungetestet:** der gesamte Swift-Code aus P0.1 — diese Umgebung hat
kein Xcode.

### Offene Punkte für den PM

1. **Zustimmung zu Entscheidung 2** (Quest-Vorlage). Wenn du das
   zusammengesetzte Ziel „1 Bier **und** 1 Ort" willst, ist das ein neuer
   DSL-Typ — kleine Erweiterung, aber ich wollte sie nicht ohne dich machen.
2. **Supabase-Projekt anlegen** — jetzt wird es konkret gebraucht, um die
   Migrationen in die Cloud zu bringen (`supabase db push`). Danach die
   GitHub-Secrets für den Keep-alive.
3. **Bier-Seed geprüft?** Ich habe 65 Biere für DE/AT/CH/IT/CZ/BE/NL/GB/IE/ES/FR/US
   gesetzt. Wenn dir etwas Offensichtliches fehlt, ist das eine Zeile.
4. **`xcodegen generate` und Build** aus P0.1 — weiterhin offen.
5. Wortfilter-Blocklist (~200 Begriffe) vor P0.3.

### Bewusst NICHT gemacht

- **Keine RPCs für Quests, Freunde, Clan, Passport, Leaderboard.** Die stehen
  in P0.5 bis P0.10. `create_check_in` wertet Quests bereits aus, aber
  `accept_quest` gibt es noch nicht — im Test werden die Zeilen direkt gesetzt.
- **Keine P1-Tabellen** (`blocks`, `reports`, `user_city_stats`,
  `user_country_stats`) — bewusst nicht angelegt.
- **Kein Städte-Vollimport ausgeführt** — nur das Skript geschrieben. 15 MB
  Download gehören nicht in eine Testumgebung.
- **Keine Ausweitung der Goal-DSL** — siehe Entscheidung 2.

### Nächster Schritt

P0.3 — Sign in with Apple, Onboarding-Screens S01–S06, `complete_onboarding`
mit serverseitiger Altersprüfung. Meilenstein M1: ein neuer Nutzer legt in
unter 60 Sekunden ein Profil an.

### Vorschläge und Themen von mir

1. **Die Reihenfolge P0.3 → P0.4 lässt sich tauschen.** `create_check_in`
   ist fertig und testbar; man könnte den Check-in-Flow vor dem Onboarding
   bauen und mit einem festen Testnutzer arbeiten. Vorteil: der Core Loop
   wäre eine Woche früher auf dem Gerät erlebbar — und genau daran hängt die
   Frage, ob das Produkt trägt. Nachteil: das Onboarding kommt später und
   fühlt sich beim ersten echten Test roher an. **Meine Empfehlung: bei der
   geplanten Reihenfolge bleiben**, aber es ist eine echte Option, falls du
   früher etwas zeigen willst.
2. **Der Tages-Cap ist mit 500 XP scharf.** Im Test war der allererste
   Check-in bereits gedeckelt (550 roh). Das ist inhaltlich richtig — Menge
   soll sich nicht auszahlen — aber der erste Reward-Screen eines neuen
   Nutzers zeigt dann sofort „XP maxed for today". Das ist ein schlechter
   erster Eindruck. **Vorschlag:** entweder Cap auf 600 anheben oder den
   allerersten Check-in eines Nutzers vom Cap ausnehmen. Beides ist eine
   Zeile in `app_config` bzw. eine Bedingung. Ich habe bewusst nichts
   geändert, weil der Wert freigegeben ist.
3. **`level_for_xp` ist doppelt implementiert** — einmal in SQL, einmal in
   Swift. Beide sind getestet und stimmen überein, aber sie können
   auseinanderlaufen. Alternative wäre, den Client die Werte nur vom Server
   anzeigen zu lassen. Für den Fortschrittsbalken zwischen zwei Serverantworten
   braucht der Client die Formel aber lokal. **Ich halte die Doppelung für
   vertretbar**, wollte sie aber benannt haben.
4. **Beobachtung zum Bier-Dedupe:** Ein Nutzer, der „Peroni" tippt, bekommt
   das bestehende „Peroni Nastro Azzurro" **nicht** automatisch — die
   normalisierten Namen unterscheiden sich. Das ist korrekt (es sind
   verschiedene Biere), aber die Suchoberfläche in P0.4 muss gute Vorschläge
   liefern, sonst entstehen Dubletten durch Abkürzungen. Das ist ein
   UI-Problem, kein Datenproblem — vermerkt für P0.4.
5. **Was mir für später auffällt:** Es gibt aktuell keinen Weg, einen falsch
   angelegten Ort oder ein falsch geschriebenes Bier zu korrigieren. Die
   `merged_into`-Spalten sind da, aber es gibt keine Funktion, die sie nutzt.
   Bei 10 Testern reicht ein manueller SQL-Befehl. Ab dem externen Test
   brauchen wir ein kleines Werkzeug. **Vorschlag: als P1-Punkt aufnehmen**,
   nicht jetzt bauen.

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
