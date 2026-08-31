# Kosten- und Free-Tier-Analyse (P0)

**Ziel: 0 € laufende Infrastrukturkosten** bei bis zu ~100 Testnutzern.
Das Apple Developer Program (99 $/Jahr) ist laut Vorgabe ausgenommen.

> ## ✅ Live verifiziert am 2026-08-30
>
> Alle Werte wurden direkt bei den Anbietern geprüft (keine Drittquellen).
> Quellenliste am Ende des Dokuments. **Ergebnis: Gate grün** — der
> 0-€-Plan trägt mit großem Abstand.
>
> Drei Korrekturen gegenüber der Schätzung, alle im Dokument eingearbeitet:
> 1. **Keep-alive muss täglich laufen, nicht alle 3 Tage.** Supabase
>    verlangt „a few user requests to the database each day over the
>    previous week" — ein 3-Tages-Rhythmus ist zu knapp.
> 2. **macOS-CI-Minuten sind der einzige Posten, der 0 € gefährden kann**
>    (Faktor ~10 im privaten Repo). Konsequenz: keine macOS-CI in P0.
> 3. **Supabase-Pausierung ist weniger gefährlich als angenommen:**
>    pausierte Projekte sind 90 Tage lang wiederherstellbar, Daten bleiben
>    erhalten. Das Risiko ist Ausfallzeit, nicht Datenverlust.
>
> **Nachkontrolle am 2026-08-30 (zweiter Abruf, auf PM-Anforderung):**
> Supabase Free und GitHub Actions Free wurden erneut direkt bei den
> Anbietern abgerufen. **Alle Werte unverändert.** Keine Anpassung nötig.

---

## 0. Entscheidung: Backend für P0

**Supabase Free ist als P0-Backend bestätigt.** Grundlage sind die unten
verifizierten Werte, nicht Schätzungen.

| Kriterium | Anforderung | Supabase Free | Bewertung |
|---|---|---|---|
| Laufende Kosten in der frühen Testphase | 0 € | 0 € | ✅ |
| Auslastung bei 100 Nutzern | deutlicher Abstand zum Limit | ~25 MB von 500 MB (5 %), ~240 MB von 5 GB Egress (5 %), 100 von 50.000 MAU | ✅ großer Puffer |
| Server-autoritative XP | zwingend (Anforderung 7) | Postgres-Funktionen mit `SECURITY DEFINER` | ✅ |
| Ausstiegsaufwand | so klein wie möglich | 3–5 Tage (`pg_dump`, Postgres bleibt Postgres) | ✅ kein Lock-in |
| Erster Kostenpunkt | planbar | Pro 25 $/Monat, rechnerisch ab ~1.000–2.000 aktiven Nutzern | ✅ |

**CloudKit ist damit abgeschlossen und wird nicht weiter untersucht.** Die
Begründung bleibt die aus §4: CloudKit wäre Apple-nativ und dauerhaft
kostenlos, kann aber keine server-autoritative Logik — XP, Level und
Leaderboards wären in der Public Database frei fälschbar. Das kollidiert mit
einer harten Produktanforderung, nicht mit einer Vorliebe.

---

## 1. Kostentabelle

| Service | Lösung | Free Tier | Kosten bei 10 Usern | Kosten bei 100 Usern | Späteres Risiko / Migration |
|---|---|---|---|---|---|
| **Auth** | Sign in with Apple über Supabase Auth | ✅ 50.000 MAU | **0 €** | **0 €** | Sehr gering. Apple-Identität bleibt bei einem Backend-Wechsel gültig (`sub` als stabile ID). Migration = Nutzertabelle umziehen. |
| **Database** | Supabase Postgres (Free) | ✅ 500 MB DB, 5 GB Egress + 5 GB cached Egress/Monat, 2 aktive Projekte | **0 €** | **0 €** (gemessene Schätzung ~25 MB, davon 15 MB Städte-Seed) | Gering. Ab Free-Limit 25 $/Monat (Pro, 8 GB DB / 250 GB Egress). `pg_dump` läuft auf Neon, Railway, Fly, Hetzner, RDS. **Kein Lock-in.** |
| **Backend-Logik** | Postgres-Funktionen (RPC) im selben Projekt | inklusive | **0 €** | **0 €** | Gering — reines SQL, portabel. Bewusst **keine** Edge Functions in P0 (Free Tier hätte 500.000 Aufrufe/Monat). |
| **Maps** | MapKit (nativ, SwiftUI) | ✅ keine veröffentlichte Preis- oder Kontingentangabe; Bestandteil des SDK und der Developer-Program-Mitgliedschaft | **0 €** | **0 €** | Kein Kostenrisiko. **Aber ein Nutzungsbedingungs-Risiko — siehe §7.** MapKit **JS** (Web) hat ein Kontingent von 250.000 Map Views + 25.000 Service Calls pro Tag; wird von uns nicht genutzt. |
| **Geocoding** | **Keine API.** Eigene `cities`-Tabelle (GeoNames `cities15000`, ✅ CC BY 4.0, kommerziell nutzbar bei Namensnennung) + SQL-Umkreissuche | entfällt | **0 €** | **0 €** | Keines. Einmaliger Datenimport (~15 MB). Kein Anbieter, kein Preis pro Anfrage — dauerhaft. |
| **POI-Vorschläge** | ~~`MKLocalSearch`~~ **in P0 gestrichen** | — | **0 €** | **0 €** | **Aus den Apple-Nutzungsbedingungen gestrichen, nicht aus Kostengründen — siehe §7 und `10-risks.md` R2.** |
| **Storage** | **Keiner.** Avatare sind Bundle-Assets | entfällt | **0 €** | **0 €** | Keines. Der einzige Posten, der mit Nutzung linear skaliert, existiert schlicht nicht. |
| **Push Notifications** | **Keine in P0** | APNs selbst ist kostenlos | **0 €** | **0 €** | P1: APNs kostenlos, Versand über eine Supabase Edge Function (Free-Tier 500k Aufrufe/Monat). Bleibt 0 €. |
| **Analytics** | Eigene `app_events`-Tabelle + App Store Connect | inklusive | **0 €** | **0 €** | Keines. Kein SDK, kein Drittanbieter, keine zusätzlichen Privacy-Labels. Kostet ~30 Zeilen Code. |
| **Crash Reporting** | Xcode Organizer / App Store Connect (nativ) | unbegrenzt | **0 €** | **0 €** | Keines. Weniger komfortabel als Sentry, aber ausreichend: symbolisierte Stacktraces, aggregiert. |
| **Deep Links** | **Keine in P0.** Invite-**Code** per Share Sheet | entfällt | **0 €** | **0 €** | P1: Universal Links über Cloudflare Pages (Free) auf `*.pages.dev` → weiterhin 0 €. Eigene Domain optional ~12 €/Jahr. |
| **Hosting (Web)** | **Keines in P0** | — | **0 €** | **0 €** | P1: Cloudflare Pages Free (unbegrenzte Sites, 500 Builds/Monat, HTTPS, eigene Header via `_headers` → korrekter Content-Type für AASA). |
| **E-Mail** | **Keine** (nur Sign in with Apple) | entfällt | **0 €** | **0 €** | Keines. Kein Passwort-Reset, keine Verifikationsmail, kein Versender nötig. |
| **CI** | GitHub Actions, Linux **und macOS** | ✅ Standard-Runner sind für **öffentliche** Repositories unbegrenzt kostenlos — macOS eingeschlossen | **0 €** | **0 €** | Keines, solange das Repository öffentlich bleibt. Würde es privat, blieben vom Freikontingent nur ~200 macOS-Minuten im Monat (Faktor ~10 gegenüber Linux) — dann müsste die iOS-CI auf Pull Requests beschränkt werden. Siehe `16-engineering-standard.md` §2. |
| **Externe APIs** | **Keine** | — | **0 €** | **0 €** | Bewusst keine Bierdatenbank-API (Untappd, BreweryDB). |
| | | **Summe** | **0 €/Monat** | **0 €/Monat** | |

**Nicht enthalten (laut Vorgabe ausgenommen):** Apple Developer Program
99 $/Jahr — Voraussetzung für TestFlight, unvermeidbar.

---

## 2. Wo genau liegen die Free-Tier-Grenzen?

Der einzige Dienst mit einem echten Limit ist Supabase. Grobe Abschätzung:

| Ressource | Free-Tier | Verbrauch bei 100 Nutzern | Auslastung |
|---|---|---|---|
| Datenbankgröße | 500 MB | Städte-Seed ~15 MB + Biere <1 MB + 100 Nutzer × 100 Check-ins ≈ 5 MB inkl. Index ⇒ **~25 MB** | **5 %** |
| Egress | 5 GB/Monat | 100 Nutzer × 30 Sitzungen × ~80 KB ⇒ **~240 MB** | **5 %** |
| Monatlich aktive Nutzer | 50.000 | 100 | **0,2 %** |
| Datei-Storage | 1 GB | **0** (nicht genutzt) | 0 % |

Rechnerisch trägt der Free Tier grob **1.000–2.000 aktive Nutzer**, bevor
Egress zum Engpass wird. Bis dahin ist die Frage der Monetarisierung ohnehin
beantwortet.

**Ab Free-Tier:** Supabase Pro 25 $/Monat (8 GB DB, 250 GB Egress).
Das ist der erste und einzige geplante Kostenpunkt.

---

## 3. Das reale Risiko im Free Tier: Projekt-Pausierung ✅ verifiziert

Supabase pausiert kostenlose Projekte **nach 7 Tagen geringer Aktivität**.
Die Dokumentation ist dabei präziser als erwartet:

> „A Free plan project is considered inactive if it does not receive
> sufficient user database activity over the past week … typically a few
> user requests to the database each day over the previous week is enough
> to keep the project from being paused."

**Korrektur gegenüber der Schätzung:** Gefordert sind Anfragen **an jedem
Tag**, nicht alle paar Tage. Der Keep-alive-Workflow läuft deshalb
**täglich**, nicht alle 3 Tage. Kosten: ~30 Linux-Minuten/Monat von 2.000.

**Entwarnung bei den Folgen:** Ein pausiertes Projekt ist **90 Tage lang
wiederherstellbar**, inklusive Daten und Konfiguration. Danach steht immer
noch ein logisches Backup zum Download bereit. Das Risiko ist also
**Ausfallzeit für den Tester, nicht Datenverlust** — deutlich harmloser
als in v0.2 angenommen.

Zweite Einschränkung, unverändert bestätigt: **maximal 2 aktive kostenlose
Projekte**. Wir brauchen genau zwei (Entwicklung + TestFlight). Das passt,
aber ohne Spielraum. Alternative bei Bedarf: lokale Entwicklung über die
Supabase CLI, dann genügt ein Cloud-Projekt.

---

## 4. Geprüfte Alternativen und warum sie es nicht geworden sind

| Option | 0 €? | Warum nicht |
|---|---|---|
| **Apple CloudKit** (Public Database) | Ja, dauerhaft, Apple-nativ — formal die erste Priorität der Vorgabe | **Kein server-autoritativer Code.** Jeder Client kann in der Public Database schreiben, was er will; XP, Level und Leaderboards wären frei fälschbar. Anforderung 7 („manipulationsarm") wäre nicht erfüllbar. Dazu: keine Joins, keine Aggregate, keine Transaktionen über mehrere Records, Leaderboards nur über clientseitiges Zusammensuchen, iCloud-Login zwingend. Ein späterer Wechsel wäre ein Rewrite der gesamten Datenschicht plus Datenmigration ohne guten Exportpfad. **Empfehlung: nicht verwenden**, trotz Apple-Priorität — die Priorität kollidiert hier mit einer harten Produktanforderung. |
| **Firebase (Spark)** | Teilweise | Cloud Functions erfordern den Blaze-Plan (hinterlegte Kreditkarte). Firestore-Datenmodell passt schlecht zu Freundschaften, Clans, Leaderboards und Ledger (Fan-out statt Joins). Starker Lock-in. |
| **Cloudflare Workers + D1** | Ja, robust (keine Pausierung) | Technisch reizvoll und dauerhaft kostenlos. Aber: Auth komplett selbst bauen, kein RLS, kein PostGIS/`earthdistance`, SQLite-Limitierungen. Schätzung **+8–10 Entwicklertage** für dieselbe Funktionalität. Für ein Nebenprojekt der falsche Tausch. **Bester Plan B**, falls Supabase seine Konditionen ändert. |
| **Oracle Cloud Always Free / eigener VPS** | Ja | Volle Betriebsverantwortung: Updates, Backups, Monitoring, TLS, Ausfälle. Berichte über Kündigung wenig genutzter Free-Instanzen. Falsches Risiko für ein Nebenprojekt. |
| **Neon / Railway / Fly.io** | Teilweise | Gute Postgres-Free-Tiers, aber ohne Auth und ohne RLS — der Supabase-Vorteil sind die *mitgelieferten* Teile, nicht die Datenbank. Sinnvolle Migrationsziele **später**. |
| **Mapbox** | Free Tier vorhanden | Kostet ab Limit Geld, braucht Token-Verwaltung, SDK-Größe, zusätzliche Privacy-Labels. MapKit ist nativ, kostenlos und unbegrenzt. |
| **TelemetryDeck / PostHog / Sentry** | Free Tiers vorhanden | Für den Umfang von P0 unnötig. Eine eigene Ereignistabelle kostet weniger Aufwand als die Integration und erzeugt keine neue Abhängigkeit. |

---

## 5. Ausstiegsplan (falls Supabase-Konditionen sich ändern)

Der Grund, warum Postgres gewählt wurde: Der Ausstieg ist ein Dump, kein Rewrite.

1. `pg_dump` des kompletten Schemas inklusive Funktionen.
2. Einspielen bei Neon/Railway/Hetzner (Postgres bleibt Postgres).
3. Ersatz für Supabase Auth: Sign in with Apple direkt verifizieren
   (Apple-JWT prüfen) — ein Tagewerk, da die Apple-`sub` als Nutzer-ID bereits
   die stabile Identität ist.
4. Ersatz für PostgREST: dünne API-Schicht vor den bestehenden RPC-Funktionen.

Geschätzter Aufwand eines vollständigen Umzugs: **3–5 Tage.** Genau deshalb
ist die Entscheidung für Supabase vertretbar.

---

## 6. Regel für alle künftigen Entscheidungen

Jede neue Abhängigkeit muss vor der Einführung diese vier Fragen beantworten:

1. Was kostet sie bei 10, 100 und 1.000 Nutzern?
2. Skaliert der Preis mit *Nutzung* (gefährlich) oder mit *Nutzerzahl* (planbar)?
3. Was ist der Ausstiegsaufwand in Tagen?
4. Gibt es eine Apple-native oder Open-Source-Alternative, die 80 % leistet?

Wird eine dieser Fragen nicht beantwortet, wird die Abhängigkeit nicht
eingeführt. Diese Regel steht auch in `CLAUDE.md`.

---

## 7. ⚠️ Befund außerhalb der Kostenfrage: Apple-Maps-Nutzungsbedingungen

Bei der Prüfung der MapKit-Bedingungen ist ein **Konflikt mit der geplanten
Architektur** aufgefallen. Er betrifft nicht die Kosten, wohl aber die
Zulässigkeit — und ist deshalb hier dokumentiert und in `10-risks.md` (R2)
hochgestuft.

**Die Klauseln (Apple Maps Terms of Use, wörtlich):**

> §1.3 (vi) — „copy, extract, scrape or reutilize any portion of the Service,
> including, but not limited to, unauthorized bulk downloads of content or
> data, **creation of any databases based upon data or content provided
> through the Service**"

> §1.3 (xiii) — „cache, pre-fetch or store any part of the Service in any
> unauthorized manner"

**Der Konflikt:** Die Planung v0.2 sah vor, `MKLocalSearch`-Vorschläge als
Eingabehilfe anzuzeigen und aus dem vom Nutzer bestätigten Treffer eine
**eigene, dauerhafte, für alle Nutzer sichtbare Venue-Entität** anzulegen.
Genau das ist „creation of a database based upon data provided through the
Service" — die Nutzerbestätigung ändert daran nichts.

Auf die identische Frage im Apple Developer Forum (Thread 708672) antwortete
Apple ausweichend und verwies auf das Developer Program License Agreement und
auf „consult your legal counsel". Es gibt also **keine Freigabe**, auf die man
sich stützen könnte.

**Entscheidung: `MKLocalSearch` entfällt in P0 ersatzlos.** Der Ort wird
eingegeben, die Koordinate kommt aus **CoreLocation** (eigene Gerätedaten,
kein Map Data). Vorschläge kommen ausschließlich aus **unseren eigenen**
bereits erfassten Orten im Umkreis. Die Anzeige einer Apple-Karte bleibt
selbstverständlich zulässig — das ist ihr bestimmungsgemäßer Zweck.

**Auswirkung:** −0,5 Tage Aufwand, ein Abschnitt weniger auf Screen S21, ein
rechtliches Risiko weniger. Der Preis ist etwas mehr Tipparbeit beim
allerersten Check-in an einem Ort; ab dem zweiten Mal schlägt die App den Ort
aus eigenen Daten vor.

**Option für P1**, falls sich die Ortseingabe im Test als zu mühsam erweist:
OpenStreetMap/Overpass (ODbL, kostenlos, Namensnennung nötig). Bringt eine
externe Abhängigkeit zurück und ist deshalb nicht die erste Wahl.

---

## 8. Quellen der Verifikation (abgerufen 2026-08-30)

| Angabe | Quelle |
|---|---|
| Supabase Free: 500 MB DB, 5 GB Egress, 50.000 MAU, 1 GB Storage, 2 aktive Projekte, 500.000 Edge-Function-Aufrufe, Pausierung nach 1 Woche; Pro ab 25 $/Monat | <https://supabase.com/pricing> |
| Pausierung: Kriterium „a few user requests each day", 90 Tage wiederherstellbar, Daten bleiben erhalten | <https://supabase.com/docs/guides/platform/free-project-pausing> · <https://supabase.com/changelog/27497-paused-free-plan-projects-are-restorable-for-90-days> |
| GitHub Actions Free: 2.000 Min/Monat + 500 MB, öffentliche Repos kostenlos | <https://docs.github.com/en/billing/concepts/product-billing/github-actions> |
| Runner-Preise Linux 0,006 $/min vs. macOS 0,062 $/min (Faktor ~10) | <https://docs.github.com/en/billing/reference/actions-minute-multipliers> |
| TestFlight: 100 interne Tester ohne Beta App Review, 10.000 externe mit Beta App Review | <https://developer.apple.com/testflight/> |
| Apple Developer Program: 99 $/Jahr, TestFlight enthalten | <https://developer.apple.com/programs/> |
| MapKit JS: 250.000 Map Views + 25.000 Service Calls pro Tag kostenlos | <https://developer.apple.com/maps/web/> |
| Apple Maps Terms of Use §1.3 (vi) und (xiii) | <https://www.apple.com/legal/internet-services/maps/terms-en.html> |
| Apple-Antwort zur Speicherung von Map-Daten | <https://developer.apple.com/forums/thread/708672> |
| GeoNames: CC BY 4.0, kommerziell nutzbar bei Namensnennung | <https://www.geonames.org/about.html> |

**Nächste Verifikation:** vor dem externen TestFlight bzw. vor der
App-Store-Einreichung.
