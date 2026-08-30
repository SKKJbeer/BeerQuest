# STEP 2a — Technische MVP-Spezifikation: Architektur

## 1. Leitplanken

1. Ein Solo-Entwickler muss das MVP in überschaubarer Zeit bauen **und
   betreiben** können.
2. Der Server ist die einzige Wahrheit für alles, was zählt (XP, Level,
   Discovery, Quest-Fortschritt, Clan-XP, Badges). Der Client rendert nur.
3. Referenzdaten (Land, Stadt, Location, Bier) sind kanonisch und haben stabile
   IDs. Alles andere darf später umgebaut werden — das hier nicht.
4. Keine Infrastruktur, die nicht mindestens ein MVP-Feature trägt. Kein Cron,
   kein Redis, kein Message-Bus, kein Kubernetes, keine Microservices.
5. Erweiterbar heißt: neue Spalte/Tabelle, nicht Rewrite. Konkret vorbereitet
   werden (ohne implementiert zu werden): Seasons, Verification, Premium,
   B2B-Owner von Venues.

---

## 2. Stack-Entscheidung

### Client
| Bereich | Wahl | Begründung |
|---|---|---|
| Plattform | iOS 17+, iPhone only (kein iPad-spezifisches Layout) | Zielgruppe, Aufwand, TestFlight |
| Sprache/UI | Swift 5.9+, SwiftUI | Solo-Tempo, Karten/Listen/Sheets nativ |
| State | `@Observable` (Observation) + Environment-Stores | Kein Redux-Framework nötig |
| Navigation | `TabView` + `NavigationStack` mit typisierten Routen | Deep-Link-fähig |
| Karte | **MapKit** (`Map` SwiftUI, iOS 17 API) | Kostenlos, nativ, keine Keys, kein SDK |
| Standort | CoreLocation, `WhenInUse`, kontextuell angefragt | Guideline 5.1.1 |
| Persistenz lokal | Nur Cache + Offline-Queue (Codable → Files/`SwiftData`) | Keine zweite Wahrheit |
| Tests | XCTest (Unit für Stores/Mapping), Snapshot optional | |

**Kein Mapbox/Google Maps im MVP:** Kosten, Keys, SDK-Größe, Privacy-Labels.
**Kein React Native/Flutter:** Ein Zielsystem, native Map/Location/SiwA-Anbindung.

### Backend — Empfehlung: **Supabase** (D3)

| Baustein | Nutzung |
|---|---|
| Postgres | Alle Daten, inkl. Referenzdaten und XP-Ledger |
| Auth | Sign in with Apple (Provider Apple), JWT im Client |
| Row Level Security | Lesezugriff-Regeln, Schreibzugriff faktisch nur über RPCs |
| Postgres Functions (RPC) | Die gesamte Spiel-Logik, transaktional |
| Edge Functions (Deno) | Nur wo HTTP nötig: Invite-Landing, Account-Löschung, Report-Webhook |
| Storage | Nur falls D4 zugunsten von Foto-Avataren entschieden wird — im MVP ungenutzt |
| `postgis` / `earthdistance` | Nearest-City- und Venue-Umkreissuche |

**Warum Supabase statt Firebase:** Das Datenmodell ist relational
(Freundschaften, Clans, Quests, Ledger, Leaderboards mit Joins und
Aggregaten). In Firestore wären Friends-/City-Leaderboards und Discovery-
Eindeutigkeit ein Fan-out-Albtraum. Postgres liefert Unique Constraints,
Transaktionen und `ORDER BY` gratis. Migrationspfad zu selbst gehostetem
Postgres bleibt offen.

**Warum kein eigenes Backend (Vapor/Node):** Auth, RLS, Hosting, Deployment und
Betrieb kosten einen Solo-Entwickler mehrere Wochen ohne Produktwert.

---

## 3. Systemüberblick

```
┌──────────────────────────────────────────┐
│ iOS App (SwiftUI)                        │
│  Features: Home Map Quests Clan Profile  │
│  ┌────────────────────────────────────┐  │
│  │ Stores: Session / Profile / Router │  │
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │ BQAPI  (typed RPC client)          │  │
│  │ OfflineQueue (Check-ins)           │  │
│  └────────────────────────────────────┘  │
└───────────────┬──────────────────────────┘
                │ HTTPS (JWT)
┌───────────────▼──────────────────────────┐
│ Supabase                                 │
│  Auth (Sign in with Apple)               │
│  PostgREST  →  RPC Functions (Spiel-     │
│                Logik, transaktional)     │
│  Postgres + RLS                          │
│  Edge Functions: /i/{code}, delete-account│
└──────────────────────────────────────────┘
                │
        ┌───────▼────────┐
        │ Static Web     │  Invite-Landing + AASA
        │ (Vercel/Pages) │  Privacy Policy, EULA
        └────────────────┘
```

---

## 4. Modul-Struktur des Clients

Ein Xcode-Projekt, ein lokales Swift Package `BeerQuestKit` mit Modulen. Die
App-Targets bleiben dünn.

```
BeerQuest/                 App target (nur App-Entry, Tabs, DI)
BeerQuestKit/
  Sources/
    BQCore/               Domain-Modelle, XP-/Level-Formeln, Formatter
    BQAPI/                Supabase-Client, DTOs, RPC-Wrapper, Fehlermapping
    BQDesign/             Farben, Typo, Buttons, Cards, XP-Bar, Empty/Error Views
    BQSession/            Auth-Status, Profil-Cache, Onboarding-Status
    BQCheckIn/            Add-Beer-Flow, Beer-/Venue-Picker, Reward-Screen
    BQPassport/           Passport-Listen, City-/Country-Detail
    BQMap/                Karte, Cluster, Marker
    BQQuests/             Quest-Liste, Detail, Social-Quest-Erstellung
    BQSocial/             Freunde, Anfragen, Invites, Leaderboards
    BQClan/               Clan-Erstellung, Beitritt, Detail, Mitglieder
    BQProfile/            Profil, Badges, Stats, Settings
  Tests/
```

Regeln: Feature-Module dürfen nur `BQCore`, `BQAPI`, `BQDesign`, `BQSession`
importieren, nie einander. Cross-Feature-Navigation läuft über `Router` mit
Route-Enums aus `BQCore`.

---

## 5. Authentication

- **Verfahren:** ausschließlich **Sign in with Apple** (D2). Erfüllt 4.8
  automatisch, kein Passwort-Handling, kein Mail-Versand, kein Passwort-Reset.
- Supabase Auth verwaltet `auth.users`; die App-Identität liegt in
  `public.profiles` (gleiche UUID als PK).
- **Kein anonymer Modus im MVP.** Begründung: Alles Soziale (Freunde, Clan,
  Leaderboard) braucht eine stabile Identität, und Account-Migration von
  anonym → SiwA ist ein eigenes Projekt.
- Token: Access-Token im Keychain, Refresh automatisch durch das SDK.
- Nutzer ohne `profiles`-Zeile landen im Onboarding (Age Gate → Username →
  Avatar), erst danach existiert ein spielfähiger Account.
- **Löschung:** Edge Function `delete-account` → Soft-Delete des Profils
  (Username freigeben, Anzeige als "Deleted user"), Entfernen aus Clan &
  Freundschaften, Hard-Delete des Auth-Users, Check-ins werden anonymisiert
  (`user_id` → NULL) statt gelöscht, damit Venue-/Beer-Katalog konsistent bleibt.
  Dieser Kompromiss ist in der Privacy Policy zu benennen.

---

## 6. Location & Maps

### 6.1 Rollenverteilung
- **Client:** ermittelt Koordinate (`CLLocationManager`, `WhenInUse`), zeigt
  Karte (MapKit), bietet POI-Vorschläge (`MKLocalSearch`) **nur als Tipphilfe**.
- **Server:** entscheidet, zu welcher **Stadt** und welchem **Land** eine
  Koordinate gehört. Ausschließlich der Server. Kein Reverse-Geocoding im Client
  für Datenzwecke.

### 6.2 Stadt-Auflösung (R1)
- Tabelle `cities` als Gazetteer-Auszug (GeoNames, `cities5000`, CC-BY 4.0 —
  Attribution in den App-Credits nötig), Felder: Name, Land, Koordinate,
  Zeitzone, Einwohner.
- Funktion `resolve_city(lat, lon)`: nächstgelegene Stadt innerhalb 60 km,
  Gewichtung nach Einwohnerzahl, sonst `NULL` → Check-in ist dann nur
  land-genau (Fallback über `countries`-Bounding oder explizite Nutzerangabe).
- Ergebnis wird auf der Venue **einmalig** gespeichert; Check-ins erben Stadt
  und Land von der Venue (denormalisiert, historisch stabil).

### 6.3 Venue-Anlage & Dedupe (2.8, R2)
1. Nutzer sucht/tippt Namen. Vorschläge kommen aus **zwei** Quellen, klar
   getrennt dargestellt: (a) bereits existierende Beer-Quest-Venues im Umkreis
   von 1 km, (b) Apple-POI-Vorschläge als Eingabehilfe.
2. Wählt der Nutzer (a), wird die bestehende Venue-ID verwendet.
3. Wählt er (b) oder tippt frei, legt der Server per `find_or_create_venue`
   eine **eigene** Entität an: normalisierter Name + Geohash-7-Zelle als
   Dedupe-Schlüssel; existiert im Umkreis von 150 m eine Venue mit stark
   ähnlichem Namen (`pg_trgm` ≥ 0.6), wird diese zurückgegeben statt einer neuen.
4. Keine Apple-Identifier, keine Adress-Bulkdaten, kein Import-Job — nur Name +
   Koordinate + Kategorie, vom Nutzer bestätigt. (Rechtlicher Check vor Launch.)

### 6.4 Karte
- Marker für eigene Venues, geclustert über MapKit-Annotation-Clustering.
- Zoom-abhängig: Weltebene → Länder-Pins mit Zählern; Stadtebene → Venue-Pins.
- **Kein Fog of War, keine Custom-Overlays** im MVP (V3).
- Ohne Standortberechtigung: Karte zentriert auf die zuletzt entdeckte Venue.

---

## 7. Deep Links & Invites

- **Universal Links** auf `https://<domain>/i/{code}` (D9) mit
  `apple-app-site-association`, zusätzlich Custom Scheme `beerquest://i/{code}`
  als Fallback.
- Ein Code, zwei Bedeutungen — der Server entscheidet: `kind = friend`
  (Freundschaft) oder `kind = quest` (Quest-Beitritt + Freundschaft).
- Codes: 8 Zeichen Crockford-Base32, kryptografisch zufällig, ablaufend
  (Friend-Invite 30 Tage, Quest-Invite = Quest-Ende), Nutzungslimit.
- **Deferred-Deep-Link-Lösung (R3):** Die Landing-Page zeigt den Code groß an
  ("Your invite code: `K7QF2M9A`") und verlinkt in den App Store. Das
  Onboarding hat als letzten Schritt "Have an invite code?" mit vorbelegtem
  Pasteboard-Vorschlag. Kein Drittanbieter-SDK.
- Einlösung ist immer serverseitig (`redeem_invite`) und idempotent;
  Selbst-Einlösung wird abgelehnt.

---

## 8. State Management & Offline

- `SessionStore` — Auth-Status, Profil, Onboarding-Status. Einziger Ort, an dem
  "wer bin ich" steht.
- Pro Feature ein `@Observable` ViewModel mit explizitem
  `ViewState<T> = .idle | .loading | .loaded(T) | .empty | .failed(BQError)`.
  Jeder Screen in STEP 4 wird gegen genau dieses Enum spezifiziert.
- Server ist Wahrheit; Caching per einfacher In-Memory-Schicht mit
  Time-to-Live, Pull-to-Refresh überall.
- **Offline-Queue (2.6):** Check-ins werden lokal mit `client_uuid`
  gespeichert und beim nächsten Foreground/Netz gesendet. UI zeigt "Pending"
  und erst nach Serverantwort die tatsächlichen XP. XP werden nie lokal
  geschätzt und dann korrigiert — das würde Vertrauen kosten.
- Idempotenz garantiert, dass eine Retry-Schleife keine doppelten XP erzeugt (R5).

---

## 9. Navigation

Fünf Tabs (§28) + zentrale Aktion:

```
TabView
├── Home      NavigationStack(HomeRoute)
├── Map       NavigationStack(MapRoute)
├── [ + ADD ] → Sheet (voller Check-in-Flow, eigener NavigationStack)
├── Quests    NavigationStack(QuestRoute)
├── Clan      NavigationStack(ClanRoute)
└── Profile   NavigationStack(ProfileRoute)
```

Der Add-Button ist optisch hervorgehoben (Bier-Icon, Akzentfarbe) und öffnet
ein Sheet statt eines Tabs — er hat keinen Zustand, den man verlassen möchte.

`Router` (Environment): `func handle(_ url: URL)` → mappt Deep Links auf
`Tab + Route`, z. B. `beerquest://quest/{id}` → Tab `.quests` +
`QuestRoute.detail(id)`. Alle Routen sind `Hashable`-Enums in `BQCore`, damit
Deep Links und interne Navigation denselben Pfad nutzen.

---

## 10. Security

| Maßnahme | Umsetzung |
|---|---|
| Schreibrechte | RLS erlaubt Clients **keine** direkten Writes auf `xp_events`, `profiles.xp/level`, `quest_participants`, `clans.xp`, `user_badges`, `check_ins`. Alles läuft über `SECURITY DEFINER`-RPCs mit `auth.uid()`-Prüfung. |
| Leserechte | Profile öffentlich lesbar (nur Username/Avatar/Level/XP), Check-ins nur eigene + Freunde, Clan-Daten für Mitglieder, Referenzdaten öffentlich lesbar |
| Rate Limits | Postgres-seitig: max. 30 Check-ins/Tag, max. 20 Freundschaftsanfragen/Tag, max. 5 Invite-Codes/Stunde, max. 3 Venue-Neuanlagen/Stunde |
| Anti-Cheat (2.9) | Tages-XP-Cap (D8); `check_ins.distance_m` zwischen Geräteposition und Venue wird gespeichert und ab > 50 km geflaggt (nur Flag, keine Blockade); Invite-XP erst wenn der Eingeladene Level 2 erreicht |
| Blocking | `blocks`-Tabelle wird in allen Sozial-Queries berücksichtigt |
| Secrets | Nur der Supabase-**Anon-Key** im Client (durch RLS abgesichert). Service-Role-Key ausschließlich in Edge Functions. |
| Transport | TLS, Certificate Pinning nicht im MVP |
| Eingaben | Längenlimits + Wortfilter auf Username, Clan-Name, Clan-Beschreibung, Beer-/Venue-Namen |

---

## 11. Datenschutz / DSGVO

- **Erhoben:** Apple-User-Identifier, optional E-Mail (Relay), Username,
  Avatar-Auswahl, Geburtsjahr (nur Jahr, nicht volles Datum), Check-ins mit
  Koordinate/Venue/Zeit, soziale Beziehungen, XP-Ledger.
- **Nicht erhoben:** Kontakte, Fotos, Werbe-ID, Hintergrundstandort, Tracking
  über Apps hinweg → **kein ATT-Prompt**.
- Rechtsgrundlage: Vertragserfüllung (Art. 6 (1) b) für Kernfunktionen.
- Standort nur im Moment des Check-ins, `WhenInUse`, Purpose String erklärt den
  Zweck. Genaue Koordinate wird auf ~11 m gerundet gespeichert (5 Nachkommastellen).
- Auskunft/Export: Edge Function `export-my-data` (JSON) — kleiner Aufwand,
  große rechtliche Absicherung.
- Löschung: siehe §5. Aufbewahrung von Report-Datensätzen 12 Monate.
- Privacy Manifest (`PrivacyInfo.xcprivacy`) + App-Privacy-Labels:
  "Location — Linked to You (App Functionality)", "User Content", "Identifiers".
- Auftragsverarbeitung: Supabase-DPA, EU-Region wählen.
- Minderjährige: Age Gate; die App ist **nicht** für Kinder und darf nicht in
  die Kids-Kategorie.

---

## 12. Für später bewusst vorbereitet (aber nicht gebaut)

| Zukunft | Vorbereitung heute | Aufwand heute |
|---|---|---|
| Seasons | XP als Ledger mit Zeitstempel | 0 |
| Verification (§23) | `check_ins.verification_level` (Default `none`) | 1 Spalte |
| Clan Wars | Clan-XP ebenfalls im Ledger | 1 Spalte |
| Hidden Quests | `quests.city_id` + `quest_templates.goal jsonb` | 0 |
| Premium | `profiles.tier` (Default `free`) | 1 Spalte |
| B2B-Venues | `venues.owner_id` (nullable) | 1 Spalte |
| Bier-Metadaten | `beers.style`, `beers.abv` nullable | 2 Spalten |

Alles andere aus V1.1–V4 wird **nicht** vorbereitet.
