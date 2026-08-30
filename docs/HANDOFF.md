# Handoff-Protokoll

Für den Projektmanager (ChatGPT). Neueste Session oben. Format und Regeln:
`.claude/skills/handoff/SKILL.md`.

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
