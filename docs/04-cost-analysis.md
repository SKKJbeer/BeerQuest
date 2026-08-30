# Kosten- und Free-Tier-Analyse (P0)

**Ziel: 0 € laufende Infrastrukturkosten** bei bis zu ~100 Testnutzern.
Das Apple Developer Program (99 $/Jahr) ist laut Vorgabe ausgenommen.

> **Stand der Angaben: Mai 2026.** Free-Tier-Konditionen ändern sich.
> Vor Projektstart (Phase P0/P1 des Implementierungsplans) sind alle
> Limits einmal gegen die aktuellen Anbieterseiten zu verifizieren; das
> ist eine Aufgabe im Implementierungsplan.

---

## 1. Kostentabelle

| Service | Lösung | Free Tier | Kosten bei 10 Usern | Kosten bei 100 Usern | Späteres Risiko / Migration |
|---|---|---|---|---|---|
| **Auth** | Sign in with Apple über Supabase Auth | 50.000 MAU | **0 €** | **0 €** | Sehr gering. Apple-Identität bleibt bei einem Backend-Wechsel gültig (`sub` als stabile ID). Migration = Nutzertabelle umziehen. |
| **Database** | Supabase Postgres (Free) | 500 MB DB, 5 GB Egress/Monat, 2 Projekte | **0 €** | **0 €** (Schätzung ~40 MB, davon 15 MB Städte-Seed) | Gering. Ab Free-Limit 25 $/Monat (Pro). `pg_dump` läuft auf Neon, Railway, Fly, Hetzner, RDS. **Kein Lock-in.** |
| **Backend-Logik** | Postgres-Funktionen (RPC) im selben Projekt | inklusive | **0 €** | **0 €** | Gering — reines SQL, portabel. Bewusst **keine** Edge Functions in P0. |
| **Maps** | MapKit (nativ, SwiftUI) | unbegrenzt für App-Nutzung | **0 €** | **0 €** | Keines. Nicht zu verwechseln mit MapKit JS (Web, kontingentiert) — wird nicht genutzt. |
| **Geocoding** | **Keine API.** Eigene `cities`-Tabelle (GeoNames `cities15000`, CC BY 4.0) + SQL-Umkreissuche | entfällt | **0 €** | **0 €** | Keines. Einmaliger Datenimport (~15 MB). Kein Anbieter, kein Preis pro Anfrage — dauerhaft. |
| **POI-Vorschläge** | `MKLocalSearch` (nativ, geräteseitig) | unbegrenzt, geräteseitig gedrosselt | **0 €** | **0 €** | Nutzungsbedingungen beachten (nur Eingabehilfe, keine Speicherung von Apple-Daten) — siehe `10-risks.md` R2. |
| **Storage** | **Keiner.** Avatare sind Bundle-Assets | entfällt | **0 €** | **0 €** | Keines. Der einzige Posten, der mit Nutzung linear skaliert, existiert schlicht nicht. |
| **Push Notifications** | **Keine in P0** | APNs selbst ist kostenlos | **0 €** | **0 €** | P1: APNs kostenlos, Versand über eine Supabase Edge Function (Free-Tier 500k Aufrufe/Monat). Bleibt 0 €. |
| **Analytics** | Eigene `app_events`-Tabelle + App Store Connect | inklusive | **0 €** | **0 €** | Keines. Kein SDK, kein Drittanbieter, keine zusätzlichen Privacy-Labels. Kostet ~30 Zeilen Code. |
| **Crash Reporting** | Xcode Organizer / App Store Connect (nativ) | unbegrenzt | **0 €** | **0 €** | Keines. Weniger komfortabel als Sentry, aber ausreichend: symbolisierte Stacktraces, aggregiert. |
| **Deep Links** | **Keine in P0.** Invite-**Code** per Share Sheet | entfällt | **0 €** | **0 €** | P1: Universal Links über Cloudflare Pages (Free) auf `*.pages.dev` → weiterhin 0 €. Eigene Domain optional ~12 €/Jahr. |
| **Hosting (Web)** | **Keines in P0** | — | **0 €** | **0 €** | P1: Cloudflare Pages Free (unbegrenzte Sites, 500 Builds/Monat, HTTPS, eigene Header via `_headers` → korrekter Content-Type für AASA). |
| **E-Mail** | **Keine** (nur Sign in with Apple) | entfällt | **0 €** | **0 €** | Keines. Kein Passwort-Reset, keine Verifikationsmail, kein Versender nötig. |
| **CI** | GitHub Actions | 2.000 Minuten/Monat (privat), unbegrenzt (öffentlich) | **0 €** | **0 €** | Gering. Optional; lokale Builds reichen auch. |
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

## 3. Das reale Risiko im Free Tier: Projekt-Pausierung

Supabase pausiert **kostenlose Projekte nach 7 Tagen ohne Aktivität**. Ein
pausiertes Projekt ist nicht erreichbar und muss manuell reaktiviert werden.
Für eine TestFlight-App mit unregelmäßiger Nutzung ist das ein echtes
Ausfallrisiko — der Tester öffnet die App und sie funktioniert nicht.

**Gegenmaßnahme (0 €):** Ein GitHub-Actions-Workflow ruft alle 3 Tage einen
leichten Health-Endpunkt auf. Kostenlos, ~15 Zeilen YAML, in P0 enthalten.

Zweite Einschränkung: **maximal 2 kostenlose Projekte** pro Organisation.
Wir brauchen genau zwei (Entwicklung + TestFlight). Das passt — aber es ist
kein Spielraum vorhanden. Ein drittes Projekt ist nicht kostenlos.

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
