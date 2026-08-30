# STEP 5 — Implementierungsplan

Prinzip: Jede Phase endet mit etwas, das **auf einem echten Gerät benutzbar**
ist. Keine Phase baut Infrastruktur "auf Vorrat". Reihenfolge ist so gewählt,
dass der Core Loop (§5) so früh wie möglich spielbar ist — er ist das einzige
echte Risiko des Produkts.

Aufwände sind **Entwicklertage** für eine Person, die Swift und SQL kann.
Nebenprojekt mit ~10 h/Woche ⇒ grob Faktor 4 in Kalenderzeit.

---

## Übersicht

| # | Phase | Tage | Meilenstein |
|---|---|---|---|
| P0 | Projekt-Setup | 2 | Build läuft |
| P1 | Datenbank-Fundament | 5 | Schema + Seeds + XP-Ledger |
| P2 | Auth & Onboarding | 4 | **M1** — Account anlegbar |
| P3 | Check-in-Kern | 8 | **M2** — Core Loop spielbar |
| P4 | Home, Profile, Passport | 5 | Fortschritt sichtbar |
| P5 | Karte | 4 | **M3** — interner TestFlight |
| P6 | Quests (Solo + City) | 5 | Spielziel vorhanden |
| P7 | Freunde, Invites, Deep Links | 6 | **M4** — viraler Loop |
| P8 | Social Quests | 2 | |
| P9 | Clans | 4 | |
| P10 | Leaderboards | 3 | Wettbewerb |
| P11 | Compliance & Settings | 4 | **M5** — reviewfähig |
| P12 | Polish, Balancing, Beta-Review | 5 | **M6** — externer TestFlight |
| | **Summe** | **52** | |

Puffer für Unvorhergesehenes: +25 % ⇒ realistisch **~65 Entwicklertage**.

---

## P0 — Projekt-Setup (2 Tage)

- Xcode-Projekt `BeerQuest`, iOS 17, SwiftUI-Lifecycle, Bundle-ID, Signing.
- Lokales Swift Package `BeerQuestKit` mit den Modulen aus Architektur §4
  (zunächst leere Targets + `BQCore`, `BQDesign`).
- `BQDesign`: Farbpalette, Typo-Skala, `PrimaryButton`, `Card`, `EmptyState`,
  `ErrorCard`, `XPBar`, `AvatarView`. Design-Richtung nach §30: warm, dunkel,
  ein kräftiger Bernstein-Akzent, keine Dauer-Animationen.
- Supabase-Projekt (EU-Region), lokale Migrationskette via Supabase CLI,
  `.env`-Handling, Anon-Key im Client.
- SwiftLint + ein GitHub-Actions-Job `build & test`.

**Fertig, wenn:** App startet mit einem Platzhalter-Tab, `supabase db reset`
läuft reproduzierbar durch.

**Nicht in dieser Phase:** Feature-Code, Icons, App-Store-Assets.

---

## P1 — Datenbank-Fundament (5 Tage)

- Migrationen für alle Tabellen aus STEP 2b.
- Seeds: `countries` (249), `cities` (GeoNames `cities15000`),
  `beers` (300 kuratiert), `quest_templates` (6), `badges` (8), `app_config`.
- Funktionen: `resolve_city(lat,lon)`, `find_or_create_venue(...)`,
  `find_or_create_beer(...)`, `award_xp(...)` (idempotent, Cap-Prüfung),
  `recalc_level(user)`, Trigger auf `xp_events`.
- RLS-Policies + `SECURITY DEFINER`-Grants.
- SQL-Tests (pgTAP oder einfache Assert-Skripte) für: Discovery-Eindeutigkeit,
  XP-Cap, Idempotenz, Level-Kurve, ein-Clan-pro-Nutzer.

**Fertig, wenn:** `create_check_in` per `curl` gegen die lokale DB einen
korrekten Reward-Payload liefert — ohne App.

---

## P2 — Auth & Onboarding (4 Tage) → **M1**

- Sign in with Apple (Capability, Supabase Provider), `SessionStore`, Keychain.
- Screens S01–S06 inkl. Live-Username-Prüfung und einfachem Wortfilter
  (Blocklist in der DB, ~200 Einträge, `name_norm`-Match).
- `complete_onboarding` mit serverseitiger Altersprüfung.
- Routing: kein Token → S01; Token ohne Profil → S02; sonst → S10.

**Fertig, wenn:** Ein neuer Nutzer auf einem echten Gerät einen Account anlegt
und Home (Platzhalter) sieht. Fehlerpfade (Abbruch, Name vergeben, zu jung)
laufen sauber.

---

## P3 — Check-in-Kern (8 Tage) → **M2, das wichtigste Zwischenziel**

- `create_check_in` vollständig (Discovery, XP + Cap, Stats, Badges,
  Quest-Hooks als No-op-Schnittstelle für P6).
- Screens S20–S24, CoreLocation-Integration, `MKLocalSearch` als Eingabehilfe.
- Venue-Dedupe (Geohash + Trigram) und Bier-Matching.
- Offline-Queue mit `client_uuid`-Idempotenz, Sync bei Foreground.
- Reward-Screen rendert ausschließlich den Server-Payload.

**Fertig, wenn:** Man ein Bier in unter 15 Sekunden einträgt, im Flugmodus
einträgt und der Eintrag später korrekt synchronisiert, und XP für dieselbe
Entdeckung nie zweimal vergeben werden.

> **Hier wird der erste ehrliche Test fällig:** Fühlt sich der Loop gut an?
> Wenn nicht, ist der richtige Zeitpunkt zum Umsteuern *jetzt* — nicht nach P12.

---

## P4 — Home, Profile, Passport (5 Tage)

- `get_home` als ein Aggregat-Call, Screens S10, S14, S30, S31, S35, S36.
- Level-Up-Darstellung, Badge-Vergabe sichtbar, Check-in-Löschung mit
  Gegenbuchung.

**Fertig, wenn:** Fortschritt nach jedem Check-in ohne App-Neustart sichtbar ist.

---

## P5 — Karte (4 Tage) → **M3 · erster interner TestFlight**

- S11 mit zoomabhängigen Pins und Clustering, S32 (City Detail, City-Level),
  S33, S34.
- Verhalten ohne Standortberechtigung vollständig.
- App-Icon, Launch Screen, TestFlight-Build für den internen Kreis.

---

## P6 — Quests, Solo + City (5 Tage)

- Quest-Engine in `create_check_in` (Goal-DSL, gemeinsamer Zähler,
  Lazy-Expiry beim Lesen), `accept_quest`, `abandon_quest`, `get_quests`.
- Screens S12, S40.
- Erst-Quest `first_beer` wird im Onboarding automatisch angenommen.

**Fertig, wenn:** Eine Quest über zwei Check-ins hinweg fortschreitet,
abschließt, XP zahlt und im Reward-Screen erscheint.

---

## P7 — Freunde, Invites, Deep Links (6 Tage) → **M4**

> **Voraussetzung: Domain (D9) und Apple Developer Team (D10) müssen stehen.**

- Statische Website: Landing-Page `/i/{code}`, AASA-Datei, Terms, Privacy.
- Universal Links + Custom Scheme, `Router.handle(url)`.
- `create_invite`, `redeem_invite`, Freundschafts-RPCs.
- Screens S50–S53.

**Fertig, wenn:** Ein Link auf einem zweiten Gerät installierten wie nicht
installierten Zustand korrekt behandelt (Code-Eingabe als Fallback, R3).

---

## P8 — Social Quests (2 Tage)
- `create_social_quest`, `join_quest`, Screens S41–S43, Teilnehmerfortschritt.

## P9 — Clans (4 Tage)
- Clan-RPCs inkl. Owner-Nachfolge und Auflösung, Clan-XP im Ledger,
  Screens S60–S63.

## P10 — Leaderboards (3 Tage)
- `get_leaderboard_*`, Screens S80–S82, angepinnte eigene Zeile,
  Blocking-Filter in allen drei Listen.

---

## P11 — Compliance & Settings (4 Tage) → **M5**

Diese Phase ist **nicht verhandelbar** vor einem externen TestFlight.

- S70–S74, Blockieren/Entblocken, Melden (S54), Wortfilter auf Clan-Namen.
- Edge Functions `delete-account`, `export-my-data`.
- `PrivacyInfo.xcprivacy`, App-Privacy-Labels, Purpose Strings.
- Terms/EULA + Privacy Policy live, GeoNames-Attribution in den Credits.
- Age-Rating-Fragebogen, Review-Notes ("XP werden nicht für Trinkmenge
  vergeben; Tages-Cap; Age Gate"), Demo-Account.
- Responsible-Drinking-Hinweis in den Settings.

---

## P12 — Polish, Balancing, Beta-Review (5 Tage) → **M6**

- Durchlauf über **jeden** Screen gegen die States aus STEP 4 (Loading, Empty,
  Error, Offline). Erfahrungsgemäß der größte Einzelposten.
- XP-/Quest-Balancing anhand der internen Testdaten (nur `app_config` und
  `quest_templates` ändern, kein Code).
- Crash-Reporting + minimale Ereignis-Analytik (Check-in, Quest-Abschluss,
  Invite gesendet/eingelöst, D1/D7-Retention).
- Barrierefreiheit: Dynamic Type, VoiceOver-Labels auf Primäraktionen,
  Kontrastprüfung.
- Beta App Review einreichen, externer TestFlight-Kreis.

---

## Teststrategie (mitlaufend, keine eigene Phase)

| Ebene | Umfang |
|---|---|
| SQL | Spielregeln: Discovery-Eindeutigkeit, XP-Cap, Idempotenz, Quest-Abschluss, Clan-XP, Löschkaskaden |
| Unit (Swift) | Level-/XP-Formeln, Offline-Queue, Route-Parsing von Deep Links, DTO-Mapping |
| Manuell | Eine Checkliste pro Flow aus STEP 3, vor jedem TestFlight-Build |
| Nicht im MVP | UI-Automation, Snapshot-Tests, Lasttests |

---

## Reihenfolge-Alternativen

- **Clans (P9) vor Quests (P6)** ziehen, falls die ersten Tester primär in
  festen Gruppen unterwegs sind. Kostet nichts, beide hängen nur an P3.
- **Leaderboards (P10) vor Clans (P9)** ziehen, falls Wettbewerb früher
  getestet werden soll — Friends-Leaderboard braucht nur P7.
- **Karte (P5) nach hinten** schieben ist möglich, aber teuer für die
  Demo-Wirkung; die Karte ist das, was Menschen beim Zeigen der App überzeugt.

Nicht verschiebbar: P1 → P3 → alles andere, und P11 vor jedem externen Test.

---

## Was in diesem Plan bewusst fehlt

Alles aus §27 sowie: Push-Benachrichtigungen, Foto-Avatare, Bier-Bewertungen,
Freundes-Feed mit Kommentaren, Android, iPad-Layout, Web-App, Widgets,
Apple Watch, Live Activities, Übersetzungen über Englisch hinaus,
Verification, Premium, Seasons, Clan Wars.

Jedes dieser Themen ist erst nach dem Erfolgskriterium aus §36 zu bewerten:
**Macht der Core Loop Spaß?**
