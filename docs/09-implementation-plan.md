# Implementierungsplan (v0.2 — P0)

Prinzip: Jede Phase endet mit etwas, das **auf einem echten Gerät benutzbar**
ist. Keine Phase baut Infrastruktur auf Vorrat.

Aufwände sind **Entwicklertage** für eine Person, die Swift und SQL kann.
Nebenprojekt mit ~10 h/Woche ⇒ grob Faktor 4 in Kalenderzeit.

---

## Übersicht

| # | Phase | Tage | Meilenstein |
|---|---|---|---|
| P0.1 | Projekt-Setup + Kostencheck | 2,0 | Build läuft |
| P0.2 | Datenbank-Fundament | 4,0 | Schema, Seeds, XP-Ledger |
| P0.3 | Auth & Onboarding | 3,5 | **M1** — Account anlegbar |
| P0.4 | Check-in-Kern | 5,5 | **M2** — Core Loop spielbar |
| P0.5 | Home, Profile, Passport | 3,5 | Fortschritt sichtbar |
| P0.6 | Karte | 3,0 | **M3** — Solo-Erfahrung komplett |
| P0.7 | Quests + Daily Quest | 3,5 | Spielziel vorhanden |
| P0.8 | Freunde + Invite-Code | 3,0 | **M4** — sozialer Loop |
| P0.9 | Clan + Aktivität | 2,5 | |
| P0.10 | Friends-Leaderboard | 1,0 | Wettbewerb |
| P0.11 | Politur, Balancing, TestFlight | 4,0 | **M5** — interner Test |
| | **Summe P0** | **35,5** | |

Mit 25 % Puffer: **~44 Entwicklertage** (v0.1 lag bei ~65).

**Laufende Kosten über die gesamte Laufzeit: 0 €.**

---

## P0.1 — Projekt-Setup + Kostencheck (2,0)

- Xcode-Projekt, iOS 17, Signing; lokales Swift Package `BeerQuestKit` mit den
  sieben Modulen aus `05-architecture.md` §4.
- `BQDesign`: Palette, Typo-Skala, `PrimaryButton`, `Card`, `EmptyState`,
  `ErrorCard`, `XPBar`, `AvatarView`. Richtung nach Vision §30: warm, dunkel,
  ein kräftiger Bernstein-Akzent, keine Dauer-Animationen.
- Supabase-Projekt (EU-Region), Migrationskette über die Supabase CLI.
- ✅ **Kostencheck erledigt** (2026-08-30): alle Free-Tier-Angaben direkt bei
  den Anbietern verifiziert, Quellen in `04-cost-analysis.md` §8.
- GitHub-Actions-Workflows: **nur Linux-Runner** — SQL-Tests und ein
  **täglicher** Keep-alive-Ping. Keine macOS-CI (Faktor ~10 auf das
  Freikontingent, siehe `10-risks.md` R16); der Xcode-Build läuft lokal.

**Fertig, wenn:** App startet mit Platzhalter-Tabs, `supabase db reset` läuft
reproduzierbar, der Keep-alive-Workflow ist grün.

## P0.2 — Datenbank-Fundament (4,0)

- Alle P0-Tabellen aus `06-data-model.md`.
- Seeds: 249 Länder, ~29.000 Städte (GeoNames), ~60 Biere, 5 Quest-Templates,
  4 Badges, `app_config`.
- Funktionen: `resolve_city`, `find_or_create_venue`, `find_or_create_beer`,
  `award_xp` (idempotent, mit Cap), `recalc_level`, Trigger auf `xp_events`.
- RLS-Policies; **keine** Schreibrechte für `authenticated`.
- SQL-Tests: Discovery-Eindeutigkeit, XP-Cap, Idempotenz, Level-Kurve,
  ein-Clan-pro-Nutzer.

**Fertig, wenn:** `create_check_in` per `curl` gegen die lokale Datenbank einen
korrekten Reward-Payload liefert — ohne App.

## P0.3 — Auth & Onboarding (3,5) → **M1**

- Sign in with Apple, `SessionStore`, Keychain.
- S01–S06 inkl. Live-Username-Prüfung und Basis-Blocklist (~200 Einträge in
  der Datenbank).
- `complete_onboarding` mit serverseitiger Altersprüfung und Code-Einlösung.
- Routing: kein Token → S01 · Token ohne Profil → S02 · sonst → S10.

**Fertig, wenn:** Ein neuer Nutzer legt auf einem echten Gerät in unter
60 Sekunden ein Profil an. Fehlerpfade (Abbruch, Name vergeben, zu jung)
laufen sauber.

## P0.4 — Check-in-Kern (5,5) → **M2, das wichtigste Zwischenziel**

- `create_check_in` vollständig: Entdeckungen, XP mit Cap, Badges,
  Quest-Hooks (in P0.7 aktiviert).
- S20–S24, CoreLocation. **Keine Apple-POI-Suche** (R2) — Ortsvorschläge
  kommen ausschließlich aus eigenen Daten.
- Ort-Dedupe (Geohash + Trigram), Bier-Matching.
- RetryQueue mit `client_uuid`-Idempotenz.
- `app_events`-Logging ab hier mitlaufend.

**Fertig, wenn:** Ein Bier ist in unter 15 Sekunden eingetragen; ein Check-in
im Flugmodus geht nicht verloren; dieselbe Entdeckung gibt nie zweimal XP.

> **Hier steht der erste ehrliche Test an: Macht der Loop Spaß?**
> Wenn nicht, ist jetzt der richtige Zeitpunkt umzusteuern — nicht nach P0.11.

## P0.5 — Home, Profile, Passport (3,5)

- `get_home` als ein Aggregat-Call; S10, S14, S31, S33.
- „Nächstes Ziel"-Anzeige, Level-Up-Darstellung, Badge-Vergabe sichtbar,
  Check-in-Löschung mit Gegenbuchung.

**Fertig, wenn:** Fortschritt nach jedem Check-in ohne App-Neustart sichtbar ist.

## P0.6 — Karte (3,0) → **M3**

- S11 mit zoomabhängigen Pins und Clustering, S32.
- Verhalten ohne Standortberechtigung vollständig.
- App-Icon, Launch Screen, erster TestFlight-Build für den eigenen Gebrauch.

## P0.7 — Quests + Daily Quest (3,5)

- Quest-Engine in `create_check_in` (Goal-DSL, Lazy-Expiry beim Lesen),
  `accept_quest`, `abandon_quest`, `get_quests`.
- Tagesquest deterministisch aus dem Datum (kein Scheduler).
- S12, S40; `first_beer` wird im Onboarding automatisch angenommen.

**Fertig, wenn:** Eine Quest schreitet über zwei Check-ins fort, schließt ab,
zahlt XP und erscheint im Reward-Screen. Die Tagesquest wechselt um
Mitternacht.

## P0.8 — Freunde + Invite-Code (3,0) → **M4**

- `create_invite`, `redeem_invite`, Freundschafts-RPCs.
- S41–S44, Einlösung auch im Onboarding.
- **Keine Domain, kein Web-Hosting, keine Entitlements nötig.**

**Fertig, wenn:** Ein Code, auf einem zweiten Gerät eingegeben, erzeugt eine
Freundschaft und beidseitig XP. Abgelaufene, ausgeschöpfte und eigene Codes
liefern jeweils eine verständliche Meldung.

## P0.9 — Clan + Aktivität (2,5)

- Clan-RPCs inkl. Owner-Nachfolge und Auflösung, Clan-XP im Ledger,
  Aktivitätsabfrage über `check_ins` + `xp_events`.
- S45–S47.

## P0.10 — Friends-Leaderboard (1,0)

- `get_leaderboard_friends(week|all)` aus dem Ledger, Segment in S42,
  eigene Zeile angepinnt.

## P0.11 — Politur, Balancing, TestFlight (4,0) → **M5**

- Durchlauf über **jeden** der 28 Screens gegen Loading/Empty/Error/Offline.
  Erfahrungsgemäß der größte Einzelposten — deshalb eine eigene Phase.
- Balancing anhand der `app_events`-Daten aus dem Eigengebrauch: nur
  `app_config` und `quest_templates` ändern, kein Code.
- Barrierefreiheit: Dynamic Type, VoiceOver auf den Primäraktionen, Kontraste.
- Verifikation der Definition of Done (16 Kriterien, `02-product-gate.md` §3).
- **Interner TestFlight-Kreis** (bis 100 Personen im eigenen Team) —
  **kein Beta App Review erforderlich.**

---

## P1 — vor jedem externen Test (Reihenfolge, ~14 Tage)

Sobald der Core Loop bestätigt ist. Die mit ⚖️ markierten Punkte sind
**zwingende Voraussetzung** für externes TestFlight bzw. App-Store-Einreichung.

| Reihenfolge | Inhalt | Tage |
|---|---|---|
| 1 ⚖️ | Account-Löschung, Datenexport | 1,5 |
| 2 ⚖️ | Melden, Blockieren, vollständiger Wortfilter, EULA | 2,0 |
| 3 ⚖️ | Terms + Privacy Policy (Cloudflare Pages, 0 €), Privacy Manifest, App-Privacy-Labels, Age-Rating-Fragebogen, Review-Notes | 1,5 |
| 4 | City Quests + City-Detail + City-Leaderboard | 3,0 |
| 5 | Social Quests + Quest-Einladungen | 3,0 |
| 6 | Universal Links (`*.pages.dev`, 0 €) | 2,0 |
| 7 | Push (APNs über Edge Function, 0 €) | 1,5 |
| 8 | Vollständiger Offline-Sync, Clan-vs-Clan-Leaderboard, Country-Detail | nach Bedarf |

**Reihenfolge ist nicht beliebig:** 1–3 sind Freigabevoraussetzungen, alles
andere ist Produktarbeit.

---

## Teststrategie (mitlaufend, keine eigene Phase)

| Ebene | Umfang |
|---|---|
| SQL | Spielregeln: Discovery-Eindeutigkeit, XP-Cap, Idempotenz, Quest-Abschluss, Clan-XP, Löschkaskaden |
| Unit (Swift) | Level-/XP-Formeln, RetryQueue, DTO-Mapping, Tagesquest-Auswahl |
| Manuell | Eine Checkliste pro Flow aus `07-user-flows.md`, vor jedem TestFlight-Build |
| Nicht in P0 | UI-Automation, Snapshot-Tests, Lasttests |

---

## Reihenfolge-Alternativen

- **P0.9 (Clan) vor P0.7 (Quests)** ist möglich, falls die ersten Tester
  primär in festen Gruppen unterwegs sind. Beide hängen nur an P0.4.
- **P0.6 (Karte) nach hinten** schieben ginge technisch, kostet aber die
  Demo-Wirkung — die Karte ist das, was Menschen beim Herzeigen überzeugt.

Nicht verschiebbar: P0.2 → P0.4 → alles Weitere.

---

## Was in P0 bewusst fehlt

Alles aus P1 und P2 der Feature-Matrix. Insbesondere: Social Quests,
City Quests, Clan- und City-Leaderboards, Universal Links, Push,
Moderationswerkzeuge, Account-Löschung, vollständiger Offline-Sync,
City-/Country-Detailseiten, Foto-Avatare, Bewertungen.

Jedes davon wird erst nach dem Erfolgskriterium aus Vision §36 bewertet:
**Macht der Core Loop Spaß?**
