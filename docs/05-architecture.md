# Architektur (v0.2 — P0-Schnitt)

Ersetzt die Architektur aus v0.1. Änderungen gegenüber v0.1 sind mit
**[v0.2]** markiert und ergeben sich aus der 0-€-Anforderung und dem
Vertical-Slice-Schnitt (`02-product-gate.md`).

## 1. Leitplanken

1. **0 € laufende Kosten.** Jede Komponente muss Apple-nativ oder dauerhaft
   kostenfrei sein. Kostenanalyse: `04-cost-analysis.md`. **[v0.2]**
2. Ein Solo-Entwickler muss das bauen **und betreiben** können.
3. Der Server ist die Wahrheit für alles, was zählt (XP, Level, Discovery,
   Quest-Fortschritt, Clan-XP, Badges). Der Client rendert nur.
4. Referenzdaten (Land, Stadt, Ort, Bier) sind kanonisch, mit stabilen IDs.
5. Keine Infrastruktur ohne P0-Feature dahinter. **Kein Cron, kein Storage,
   kein Web-Hosting, kein Push, kein Drittanbieter-SDK.** **[v0.2]**
6. Erweiterbar heißt: neue Spalte/Tabelle, nicht Rewrite.

---

## 2. Stack

### Client
| Bereich | Wahl | Kosten |
|---|---|---|
| Plattform | iOS 17+, iPhone only | — |
| UI | Swift 5.9+, SwiftUI, `@Observable` | — |
| Karte | **MapKit** (SwiftUI `Map`, iOS 17) | 0 € |
| Ortssuche | **Keine Apple-POI-Suche** (Nutzungsbedingungen, siehe `10-risks.md` R2). Vorschläge nur aus eigenen Orten | 0 € |
| Standort | CoreLocation, `WhenInUse`, kontextuell | — |
| Persistenz | Nur Cache + Wiederholungs-Queue (Codable → Datei) | — |
| Analytics | Eigene Ereignisse → `app_events`-Tabelle **[v0.2]** | 0 € |
| Crash-Reports | Xcode Organizer / App Store Connect **[v0.2]** | 0 € |

**Kein Drittanbieter-SDK in P0.** Kein Firebase, Sentry, Mapbox, Branch,
Amplitude. Das ist keine Ideologie, sondern der direkte Weg zu 0 € und zu
minimalen Privacy-Labels.

### Backend — Supabase Free

| Baustein | Nutzung in P0 |
|---|---|
| Postgres | Alle Daten inkl. Referenzdaten und XP-Ledger |
| Auth | Sign in with Apple |
| Row Level Security | Leserechte; Schreibrechte gibt es faktisch nicht |
| Postgres-Funktionen (RPC) | **Die gesamte Spiel-Logik**, transaktional |
| PostgREST | Transport, kein eigener Code |
| Edge Functions | **Nicht in P0.** **[v0.2]** Erst P1 (Account-Löschung, Push) |
| Storage | **Nicht genutzt.** Avatare sind Bundle-Assets **[v0.2]** |
| `earthdistance` / `pg_trgm` | Umkreissuche und Namensabgleich |

Warum Supabase und nicht CloudKit, Firebase oder Cloudflare: ausführlich in
`04-cost-analysis.md` §4. Kurz: CloudKit kann keine server-autoritative Logik
(XP wäre fälschbar), Firebase passt nicht zum relationalen Modell und braucht
für Functions eine Kreditkarte, Cloudflare D1 kostet ~8–10 Tage Mehrarbeit
für Auth und Geo-Funktionen.

---

## 3. Systemüberblick (P0)

```
┌────────────────────────────────────────┐
│ iOS App (SwiftUI)                      │
│  Home · Map · Quests · Clan · Profile  │
│  ┌──────────────────────────────────┐  │
│  │ SessionStore · Router            │  │
│  │ BQAPI (typisierte RPC-Aufrufe)   │  │
│  │ RetryQueue (Check-ins)           │  │
│  └──────────────────────────────────┘  │
└──────────────┬─────────────────────────┘
               │ HTTPS (JWT)
┌──────────────▼─────────────────────────┐
│ Supabase Free                          │
│  Auth (Sign in with Apple)             │
│  PostgREST → RPC-Funktionen            │
│  Postgres + RLS + Seeds (cities/beers) │
└────────────────────────────────────────┘
               ▲
      GitHub Actions (alle 3 Tage Ping,
      verhindert Projekt-Pausierung)  [v0.2]
```

**Kein Web-Hosting, keine Domain, keine Edge Functions in P0.** **[v0.2]**

---

## 4. Modul-Struktur

Ein Xcode-Projekt, ein lokales Swift Package. **[v0.2]** Gegenüber v0.1 auf
sieben Module reduziert — `BQPassport` und `BQMap` verschmelzen, `BQSocial`
und `BQClan` ebenfalls.

```
BeerQuest/                 App-Target (Entry, Tabs, DI)
BeerQuestKit/Sources/
  BQCore/       Domain-Modelle, XP-/Level-Formeln, Routen-Enums
  BQAPI/        Supabase-Client, DTOs, RPC-Wrapper, Fehlermapping, RetryQueue
  BQDesign/     Farben, Typo, Buttons, Cards, XPBar, Empty/Error, Avatare
  BQSession/    Auth-Status, Profil, Onboarding-Status
  BQCheckIn/    Add-Beer-Flow, Picker, Reward-Screen
  BQWorld/      Karte, Passport-Listen, Ort-Detail
  BQPlay/       Quests, Clan, Freunde, Leaderboard
```

Regel: Feature-Module (`BQCheckIn`, `BQWorld`, `BQPlay`) importieren nur
`BQCore`, `BQAPI`, `BQDesign`, `BQSession` — nie einander. Cross-Feature-
Navigation läuft über den `Router` mit Enums aus `BQCore`.

---

## 5. Authentication

- Ausschließlich **Sign in with Apple**. Kein Passwort, kein Mail-Versand,
  kein Reset-Flow, kein E-Mail-Dienstleister — und Guideline 4.8 ist
  automatisch erfüllt.
- Supabase Auth verwaltet `auth.users`; die Spielidentität liegt in
  `public.profiles` mit derselben UUID.
- Kein anonymer Modus (soziale Features brauchen stabile Identität).
- Kein Profil vorhanden → Onboarding. Sonst → Home.
- Account-Löschung ist **P1** (⚖️ vor App-Store-Release) — für einen internen
  TestFlight-Kreis nicht erforderlich. **[v0.2]**

---

## 6. Location & Maps

### Rollenverteilung
- **Client:** Koordinate ermitteln, Karte zeigen, POI-Vorschläge anbieten.
- **Server:** entscheidet, zu welcher **Stadt** und welchem **Land** eine
  Koordinate gehört. Ausschließlich der Server, ausschließlich aus eigenen
  Daten. **Keine Geocoding-API — dauerhaft 0 €.**

### Stadt-Auflösung
- `cities` = GeoNames-Auszug `cities15000` (~29.000 Orte ≥ 15.000 Einwohner,
  CC BY 4.0, Attribution in den App-Credits, ~15 MB).
- `resolve_city(lat, lon)`: nächstgelegene Stadt im Umkreis von 60 km,
  gewichtet nach Einwohnerzahl. Kein Treffer → Check-in bleibt landgenau.
- Das Ergebnis wird **einmalig auf dem Ort** gespeichert; Check-ins erben
  Stadt und Land vom Ort. Historisch stabil, keine Neuberechnung.

### Ort-Anlage & Dedupe **[v0.3]**
1. Vorschläge kommen **ausschließlich aus unseren eigenen** bereits erfassten
   Orten im Umkreis von 1 km.
2. Bestehender Ort → dessen ID wird verwendet.
3. Sonst tippt der Nutzer den Namen; die Koordinate kommt aus **CoreLocation**
   (eigene Gerätedaten). `find_or_create_venue` legt die Entität an, Dedupe über
   Geohash-7-Zelle + Namensähnlichkeit (`pg_trgm` ≥ 0.6) im Umkreis von 150 m.
4. **Keine Apple-POI-Daten, in keiner Form.** Die Apple Maps Terms of Use
   §1.3 (vi) verbieten die *creation of any databases based upon data or
   content provided through the Service* — unsere `venues`-Tabelle wäre genau
   das. Die Anzeige der Apple-Karte bleibt selbstverständlich zulässig.
   Herleitung: `04-cost-analysis.md` §7, Risiko R2.

Praktische Folge: Der **erste** Nutzer an einem Ort tippt zwei Wörter. Ab dem
zweiten Mal schlägt die App den Ort aus eigenen Daten vor — und genau diese
Daten gehören uns, ohne Lizenzrisiko.

### Karte in P0
Marker für eigene Orte mit MapKit-Clustering; auf Weltebene Länder-Pins mit
Zählern. **Kein Fog of War, keine Custom-Overlays, keine City-Detailseite.**

---

## 7. Invites — Code statt Deep Link **[v0.2]**

Universal Links erfordern Domain, Web-Hosting, AASA-Datei, Entitlements und
einen Workaround für den App-Store-Umweg. Für einen Kreis von Testern, die
sich persönlich kennen, ist das Aufwand ohne Nutzen.

**P0:**
- `create_invite()` liefert einen 8-stelligen Code (Crockford-Base32,
  kryptografisch zufällig, 30 Tage gültig, 25 Einlösungen).
- Teilen über das System-Share-Sheet als Text:
  `„🍺 Join my Beer Quest — my code is K7QF2M9A. Get the app: <TestFlight-Link>"`
- Einlösen an zwei Stellen: im Onboarding („Have an invite code?") und unter
  Freunde → „Enter a code".
- Server prüft: existiert, nicht abgelaufen, nicht ausgeschöpft, nicht der
  eigene. Einlösung ist idempotent.
- Clans nutzen denselben Mechanismus mit einem eigenen `join_code`.

**P1:** Universal Links über Cloudflare Pages (`*.pages.dev`, 0 €) — die
Code-Logik bleibt unverändert, der Link löst nur denselben Code automatisch ein.
Der Umbau kostet später ~2 Tage und wird durch nichts erschwert, was wir jetzt
tun.

---

## 8. State Management & Fehlertoleranz

- `SessionStore` — Auth, Profil, Onboarding-Status. Einziger Ort für „wer bin ich".
- Pro Screen ein `@Observable` ViewModel mit
  `ViewState<T> = idle | loading | loaded(T) | empty | failed(BQError)`.
- Server ist Wahrheit. In-Memory-Cache mit TTL, Pull-to-Refresh überall,
  **kein Polling** (Egress-Schonung, siehe Gate B).
- **RetryQueue statt Sync-Engine [v0.2]:** Ein fehlgeschlagener Check-in wird
  mit seiner `client_uuid` persistiert und beim nächsten App-Start oder
  Netzwechsel erneut gesendet. Idempotenz verhindert Doppelbuchungen. Kein
  Konfliktmodell, keine Sammel-Rewards, keine Hintergrundsynchronisation —
  das ist P1.
- XP werden **nie** lokal geschätzt. Bis zur Bestätigung heißt der Zustand
  „pending", nicht „+50".

---

## 9. Navigation

```
TabView
├── Home      NavigationStack(HomeRoute)
├── Map       NavigationStack(MapRoute)
├── [ + ADD ] → Sheet (Check-in-Flow, eigener NavigationStack)
├── Quests    NavigationStack(QuestRoute)
├── Clan      NavigationStack(ClanRoute)
└── Profile   NavigationStack(ProfileRoute)
```

Der Add-Button ist optisch hervorgehoben und öffnet ein Sheet — kein Tab, weil
er keinen Zustand hat, den man verlassen möchte.

`Router` (Environment) mappt interne Sprünge auf `Tab + Route`. Routen sind
`Hashable`-Enums in `BQCore`. In P1 nutzt die Deep-Link-Behandlung genau
denselben Pfad — deshalb wird der Router bereits jetzt so gebaut.

---

## 10. Security

| Maßnahme | Umsetzung in P0 |
|---|---|
| Schreibrechte | **Keine** `insert`/`update`-Policy für die Rolle `authenticated`. Jeder Schreibvorgang läuft durch eine `SECURITY DEFINER`-Funktion mit `auth.uid()`-Prüfung. XP sind damit strukturell nicht manipulierbar. |
| Leserechte | Profile öffentlich (Username, Avatar, Level, XP); Check-ins nur eigene + Freunde; Clan-Daten nur für Mitglieder; Referenzdaten öffentlich lesbar |
| Rate Limits | In SQL: 30 Check-ins/Tag, 20 Freundschaftsanfragen/Tag, 5 Invite-Codes/Stunde, 3 Ortsanlagen/Stunde |
| Tages-XP-Cap | 500 XP/Tag aus Check-ins — zugleich Anti-Cheat und Umsetzung von Vision §2 |
| Eingaben | Längenlimits + Basis-Blocklist auf Username, Clan-Name, Bier- und Ortsnamen |
| Secrets | Nur der Supabase-Anon-Key im Client, abgesichert durch RLS |
| Positionsabgleich, Flagging, Melden, Blockieren | **P1** — im internen Testkreis ohne Nutzen |

---

## 11. Datenschutz

- **Erhoben:** Apple-Identifier, optional Relay-E-Mail, Username,
  Avatar-Auswahl, **Geburtsjahr** (nicht das volle Datum), Check-ins mit
  gerundeter Koordinate (5 Nachkommastellen ≈ 1 m), soziale Beziehungen,
  XP-Ledger, anonyme App-Ereignisse.
- **Nicht erhoben:** Kontakte, Fotos, Werbe-ID, Hintergrundstandort,
  App-übergreifendes Tracking → **kein ATT-Prompt**, keine Drittanbieter-SDKs.
- Standort nur im Moment des Check-ins, `WhenInUse`, mit Purpose String.
- Supabase-Projekt in der EU-Region.
- Privacy Manifest, App-Privacy-Labels, Privacy Policy und Terms: **P1 ⚖️**,
  zwingend vor externem TestFlight bzw. App-Store-Einreichung.

---

## 12. Bewusst vorbereitet, nicht gebaut

| Zukunft | Vorbereitung in P0 | Kosten heute |
|---|---|---|
| Seasons, Wochen-/Monatswertungen | XP als Ledger mit Zeitstempel | 0 |
| Verification | `check_ins.verification` (Default `none`) | 1 Spalte |
| Clan Wars | Clan-XP ebenfalls im Ledger | 1 Spalte |
| City Quests, Hidden Quests | `quests.city_id`, `goal jsonb` | 0 |
| Premium | `profiles.tier` (Default `free`) | 1 Spalte |
| B2B-Orte | `venues.owner_id` (nullable) | 1 Spalte |
| Universal Links | Invite-Code-Logik serverseitig, Router client-seitig | 0 |

Alles andere aus P2 wird **nicht** vorbereitet.
