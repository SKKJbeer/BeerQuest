# 🍺 Beer Quest

Gamifizierte iOS-Social-App für Bierliebhaber. Stand: **Planung abgeschlossen
(v0.2), Implementierung noch nicht begonnen.**

Zwei harte Rahmenbedingungen binden jede Entscheidung:
**0 € laufende Infrastrukturkosten** und **P0 als Vertical Slice**.

## Für den Einstieg

| Wenn du wissen willst … | lies |
|---|---|
| was zuletzt passiert ist und was offen ist | [`docs/HANDOFF.md`](docs/HANDOFF.md) |
| was in den ersten Test kommt und was nicht | [`docs/03-feature-matrix.md`](docs/03-feature-matrix.md) |
| warum das nichts kostet | [`docs/04-cost-analysis.md`](docs/04-cost-analysis.md) |
| wann was gebaut wird | [`docs/09-implementation-plan.md`](docs/09-implementation-plan.md) |

## Dokumentation

| Dokument | Inhalt |
|---|---|
| [`00-product-vision.md`](docs/00-product-vision.md) | Product Vision & MVP Specification v0.1 (Quelldokument, §1–§36) |
| [`01-analysis.md`](docs/01-analysis.md) | Kritische Analyse der Vision — Befunde gültig, Scope-Entscheidungen durch v0.2 überholt |
| [`02-product-gate.md`](docs/02-product-gate.md) | **Product-/Architecture-Gate:** Review A–F, Vertical Slice, Definition of Done P0 |
| [`03-feature-matrix.md`](docs/03-feature-matrix.md) | **P0 / P1 / P2** über alle Features, Bilanz der Streichungen |
| [`04-cost-analysis.md`](docs/04-cost-analysis.md) | Kostentabelle, Free-Tier-Grenzen, geprüfte Alternativen, Ausstiegsplan |
| [`05-architecture.md`](docs/05-architecture.md) | Stack, Module, Auth, Location/Maps, Invites, State, Navigation, Security, Datenschutz |
| [`06-data-model.md`](docs/06-data-model.md) | DDL mit P0/P1-Markierung, Spielökonomie, Quest-DSL, Badges, RPC-API, RLS, Seeds |
| [`07-user-flows.md`](docs/07-user-flows.md) | P0-Flows inkl. Fehler- und Wiederholungspfaden |
| [`08-screens.md`](docs/08-screens.md) | 28 Views mit Loading-, Empty- und Error-States |
| [`09-implementation-plan.md`](docs/09-implementation-plan.md) | P0.1–P0.11 (36 Tage) und die P1-Reihenfolge danach |
| [`10-risks.md`](docs/10-risks.md) | 15 technische Risiken mit Gegenmaßnahmen |

## Die Entscheidungen in Kurzform

- **Client:** iOS 17+, SwiftUI, MapKit, modulares Swift Package, **kein
  Drittanbieter-SDK**
- **Backend:** Supabase Free (Postgres + RLS + Auth), gesamte Spiel-Logik
  serverseitig und transaktional
- **Auth:** ausschließlich Sign in with Apple
- **Geocoding:** keine API — eigene GeoNames-Tabelle, dauerhaft 0 €
- **Storage:** keiner — Avatare sind Bundle-Assets
- **Invites:** Code per Share Sheet; Universal Links erst in P1
- **XP:** append-only Ledger, Tages-Cap, keine Belohnung von Trinkmenge
- **Laufende Kosten:** 0 €/Monat bei 10 wie bei 100 Nutzern

## Nächster Schritt

Phase **P0.1** — Projekt-Setup und Verifikation der Free-Tier-Zahlen.
Offene Punkte für den Projektmanager stehen in [`docs/HANDOFF.md`](docs/HANDOFF.md).
