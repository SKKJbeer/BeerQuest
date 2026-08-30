# 🍺 Beer Quest

Gamifizierte Social-App für Bierliebhaber (iOS). Aktueller Stand:
**Product Discovery abgeschlossen, Spezifikation fertig, Implementierung noch
nicht begonnen.**

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [`docs/00-product-vision.md`](docs/00-product-vision.md) | Product Vision & MVP Specification v0.1 (Quelldokument, §1–§36) |
| [`docs/01-analysis.md`](docs/01-analysis.md) | **STEP 1** — Kritische Analyse: Widersprüche, fehlende Anforderungen, Risiken, UX, App Store, Vereinfachungen, offene Entscheidungen |
| [`docs/02-architecture.md`](docs/02-architecture.md) | **STEP 2a** — Architektur, Stack, Auth, Location/Maps, Deep Links, State, Navigation, Security, Datenschutz |
| [`docs/03-data-model.md`](docs/03-data-model.md) | **STEP 2b** — Datenmodell (DDL), Spielökonomie, Quest-DSL, Badges, API-Oberfläche, RLS, Seeds |
| [`docs/04-user-flows.md`](docs/04-user-flows.md) | **STEP 3** — Alle MVP User Flows inkl. Fehler- und Offline-Pfade |
| [`docs/05-screens.md`](docs/05-screens.md) | **STEP 4** — 43 Views mit Elementen, Aktionen, Loading-/Empty-/Error-States, Navigation |
| [`docs/06-implementation-plan.md`](docs/06-implementation-plan.md) | **STEP 5** — Phasenplan P0–P12, ~65 Entwicklertage, Meilensteine M1–M6 |

## Kurzfassung der Entscheidungen

- **Client:** iOS 17+, SwiftUI, MapKit, modulares Swift Package
- **Backend:** Supabase (Postgres + RLS + Auth + RPC-Funktionen), gesamte
  Spiel-Logik serverseitig und transaktional
- **Auth:** ausschließlich Sign in with Apple
- **XP:** append-only Ledger, Tages-Cap, keine Belohnung von Trinkmenge
- **Referenzdaten:** kanonische Städte (GeoNames), nutzergenerierte Venues mit
  Dedupe, kuratierter Bier-Seed + freie Anlage

Offene Entscheidungen für den Product Owner stehen am Ende von
[`docs/01-analysis.md`](docs/01-analysis.md) (D1–D10). Zwei davon sind echte
Blocker für spätere Phasen: eine Domain für Universal Links (D9) und ein
aktives Apple Developer Program (D10).

## Nächster Schritt

STEP 6 — Implementierung, beginnend mit Phase P0/P1 aus dem Implementierungsplan.
