# 🍺 Beer Quest

Gamifizierte iOS-Social-App für Bierliebhaber. Stand: **P0.1 und P0.2
abgeschlossen** — Datenbank und Spiel-Logik stehen und sind getestet.

Zwei harte Rahmenbedingungen binden jede Entscheidung:
**0 € laufende Infrastrukturkosten** und **P0 als Vertical Slice**.

## Für den Einstieg

| Wenn du wissen willst … | lies |
|---|---|
| was zuletzt passiert ist und was offen ist | [`docs/HANDOFF.md`](docs/HANDOFF.md) |
| was in den ersten Test kommt und was nicht | [`docs/03-feature-matrix.md`](docs/03-feature-matrix.md) |
| warum das nichts kostet | [`docs/04-cost-analysis.md`](docs/04-cost-analysis.md) |
| wann was gebaut wird | [`docs/09-implementation-plan.md`](docs/09-implementation-plan.md) |
| wie du das Projekt zum Laufen bringst | [`docs/SETUP.md`](docs/SETUP.md) |

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
| [`10-risks.md`](docs/10-risks.md) | 16 technische Risiken mit Gegenmaßnahmen |
| [`11-release-gates.md`](docs/11-release-gates.md) | **Verbindlich:** was intern reichen darf und was vor jeder externen Verteilung vollständig sein muss |
| [`12-monetization.md`](docs/12-monetization.md) | Ads in P1, Premium in P2 — und was in P0 bewusst fehlt |
| [`SETUP.md`](docs/SETUP.md) | Lokales Setup: Xcode, Supabase, GitHub-Secrets |

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

## Stand der Umsetzung

| Phase | Status |
|---|---|
| Kosten-Gate (Free-Tier live verifiziert) | ✅ 2026-08-30, Quellen in `04-cost-analysis.md` §8 |
| Architektur-Gate (Supabase bestätigt) | ✅ vom PM freigegeben |
| **P0.1** Projekt-Setup | ✅ Gerüst, CI, Keep-alive, erste Migration |
| **P0.2** Datenbank-Fundament | ✅ Schema, Spiel-Logik, RLS, Seeds — 5 Regeltests grün |
| P0.3 Auth & Onboarding | ⏭️ als Nächstes |

## Nächster Schritt

Phase **P0.3** — Sign in with Apple und Onboarding (Meilenstein M1).
Offene Punkte für den Projektmanager stehen in [`docs/HANDOFF.md`](docs/HANDOFF.md).
