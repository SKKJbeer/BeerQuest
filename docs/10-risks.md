# Technische Risiken (v0.2)

Bewertet für **P0**. Risiken, die erst in P1/P2 relevant werden, sind als
solche gekennzeichnet.

| # | Risiko | Schwere | Gegenmaßnahme | Wann |
|---|---|---|---|---|
| **R1** | **Kanonische Städte.** Der gesamte Sammelmechanismus hängt daran, dass „Rom" für alle Nutzer dieselbe Entität ist. | 🔴 | Eigenes Gazetteer (`cities15000`) + `resolve_city` serverseitig. Der Client geocodiert nie. Kein Anbieter, keine API-Kosten. | P0.2 |
| **R2** | **Apple-Maps-Nutzungsbedingungen — ✅ am 2026-08-30 verifiziert und als echter Konflikt bestätigt.** §1.3 (vi) verbietet ausdrücklich die *creation of any databases based upon data or content provided through the Service*. Unsere `venues`-Tabelle wäre genau das gewesen. Die Bestätigung durch den Nutzer heilt das nicht; Apple selbst verweist nur auf *consult your legal counsel*. | 🔴 → **gelöst** | **`MKLocalSearch` entfällt in P0 ersatzlos.** Ortsname wird eingegeben, die Koordinate kommt aus CoreLocation (eigene Gerätedaten), Vorschläge ausschließlich aus unseren eigenen Orten. Die Anzeige der Apple-Karte bleibt zulässig. Wortlaut und Herleitung: `04-cost-analysis.md` §7. | erledigt |
| **R3** | **Supabase pausiert kostenlose Projekte nach 7 Tagen geringer Aktivität.** ✅ verifiziert. Entwarnung bei den Folgen: 90 Tage wiederherstellbar, Daten bleiben erhalten — das Risiko ist Ausfallzeit, nicht Datenverlust. | 🟡 (herabgestuft) | Keep-alive-Workflow pingt **täglich**, nicht alle 3 Tage: Supabase verlangt Anfragen *each day over the previous week*. ~30 Linux-Minuten/Monat von 2.000. | P0.1 ✅ |
| **R4** | **Nur 2 kostenlose Supabase-Projekte.** Wir brauchen genau zwei (Entwicklung + Test) — kein Spielraum. | 🟡 | Bewusst mit zwei planen. Ein drittes Projekt kostet. Alternativ lokale Entwicklung über die Supabase CLI. | P0.1 |
| **R5** | **XP-Konsistenz.** Entdeckung, XP, Quest-Fortschritt, Clan-XP und Badges müssen bei einem Check-in atomar aktualisiert werden. | 🟠 | Ein einziger transaktionaler Call `create_check_in`, der das Reward-Paket zurückgibt. Der Client rechnet nie XP. | P0.4 |
| **R6** | **Doppelte Check-ins** durch Wiederholungsversuche. | 🟠 | Client-generierte `client_uuid` als Idempotenzschlüssel, unique je Nutzer. Zusätzlich `idem_key` auf jedem Ledger-Eintrag. | P0.4 |
| **R7** | **Ort-Duplikate.** Zwei Nutzer legen „Augustiner Keller" und „Augustiner-Keller München" an — die Karte zerfällt, beide bekommen +50 XP für dasselbe. | 🟠 | Dedupe über Geohash-7-Zelle + Trigram-Ähnlichkeit ≥ 0,6 im Umkreis von 150 m. `merged_into`-Spalte für spätere manuelle Zusammenführung. | P0.4 |
| **R8** | **Free-Tier-Konditionen ändern sich.** | 🟡 | ✅ Alle Angaben am 2026-08-30 direkt bei den Anbietern verifiziert, Quellenliste in `04-cost-analysis.md` §8. Nächste Prüfung vor dem externen TestFlight. Ausstiegsplan §5: vollständiger Umzug in 3–5 Tagen, weil es Postgres ist. | P0.1 ✅ |
| **R9** | **Egress ist das eigentliche Free-Tier-Limit**, nicht Speicher. Ein gesprächiger Client verbrennt 5 GB/Monat schneller als erwartet. | 🟡 | Ein Aggregat-Call `get_home`, Caching mit TTL, **kein Polling**, keine Hintergrund-Refreshes. Als Architekturregel festgehalten. | durchgehend |
| **R10** | **Solo-Entwickler**: iOS, Backend, Daten und Inhalte in einer Person. | 🟠 | BaaS statt Eigenbau, striktes Phasenmodell, P0 auf 36 Tage geschnitten, kein Feature aus P1/P2. | durchgehend |
| **R11** | **Cheating** ohne jede Verifikation: 20 Länder in fünf Minuten eintippbar. | 🟢 (P0) | Im internen Testkreis irrelevant. In P0 nur strukturelle Maßnahmen: XP ausschließlich serverseitig, Tages-Cap, Rate-Limits. Positionsabgleich und Flagging sind P1. | P1 |
| **R12** | **Bier-Katalog verwässert** durch Tippfehler und Dubletten. | 🟡 | Normalisierter Unique-Index `(name_norm, brewery_norm)`, Trigram-Vorschläge vor der Neuanlage, `merged_into` für spätere Bereinigung. Der kleine Seed (~60) ist Absicht: Die Tester zeigen uns, was fehlt. | P0.4 |
| **R13** | **App-Store-Freigabe** einer Alkohol-App mit Gamification. | 🟠 (P1) | Betrifft P0 nicht (interner TestFlight braucht kein Beta App Review). Für P1: Age Gate, Age Rating 17+/18+, Account-Löschung, Melden/Blockieren, EULA, Review-Notes mit Erklärung des XP-Systems (keine Belohnung von Menge, Tages-Cap). | P1 ⚖️ |
| **R14** | **Zeitzonen.** Bei Reisenden ist unklar, welcher Tag gemeint ist — betrifft Tages-Cap, Tagesquest und Wochen-Leaderboard. | 🟡 | `timestamptz` **und** separat gespeichertes `local_date`; die Zeitzone kommt vom Client mit dem Check-in. | P0.4 |
| **R16** | **macOS-CI-Kosten** — ✅ **entschärft am 2026-08-31.** Das Repository ist öffentlich, damit sind Standard-Runner unbegrenzt kostenlos (macOS eingeschlossen). Der Faktor ~10 gegenüber Linux gälte nur für private Repositories. | 🟢 | iOS-CI scharfgeschaltet, Pfadfilter und `cancel-in-progress` bleiben — gegen Wartezeit, nicht gegen Kosten. **Wenn das Repository jemals privat wird, greift das Risiko sofort wieder.** | erledigt |
| **R15** | **GeoNames-Lizenz.** CC BY 4.0 verlangt Namensnennung. | 🟢 | Attribution in den App-Credits (Settings → About). Erledigt in P0.11. | P0.11 |

---

## Nicht mehr relevante Risiken aus v0.1

| Risiko v0.1 | Warum entfallen |
|---|---|
| **Deferred Deep Links** (Invite-Link überlebt den App-Store-Umweg nicht) | P0 nutzt Invite-**Codes** statt Links. Das Problem existiert nicht mehr — und in P1 ist die Code-Eingabe bereits die eingebaute Rückfallebene. |
| **Bildmoderation / Storage-Kosten** | Keine Uploads. Avatare sind Bundle-Assets. |
| **Scheduler-Ausfälle** (Quest-Ablauf, Leaderboard-Reset) | Kein Scheduler. Ablauf wird beim Lesen ausgewertet, die Tagesquest ergibt sich deterministisch aus dem Datum. |
| **Leaderboard-Skalierung** | Ein Leaderboard, eine indizierte Abfrage, dreistellige Nutzerzahl. |

---

## Zwei Blocker aus v0.1, die jetzt keine mehr sind

| Blocker v0.1 | Status |
|---|---|
| **D9 — Domain für Universal Links** | **Aufgelöst für P0.** Invite-Codes brauchen keine Domain. Für P1 genügt eine kostenlose `*.pages.dev`-Subdomain; eine eigene Domain (~12 €/Jahr) ist optional. |
| **D10 — Apple Developer Program** | **Bleibt Voraussetzung** für TestFlight, wird aber erst zu P0.6 gebraucht — nicht zum Start. Laut Vorgabe zählt die Gebühr nicht als laufende Infrastrukturkosten. |
