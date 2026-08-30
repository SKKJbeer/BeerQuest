# P0 Screen List (v0.2)

**28 Views statt 43** in v0.1. Gestrichene Screens und ihr Zielrelease:
`03-feature-matrix.md`.

Jeder Screen ist gegen `ViewState = idle | loading | loaded | empty | failed`
spezifiziert.

**Konventionen für die gesamte App**
- **Loading:** Skeletons in der Form des späteren Inhalts, kein Vollbild-Spinner.
  Ausnahme: blockierende Aktionen (Save, Accept) → Spinner im Button.
- **Error:** Inline-Karte mit Klartext + [Try again]. Nie ein technischer Code,
  nie ein leerer Bildschirm. „Offline" hat eine eigene Formulierung.
- **Empty:** Icon + ein Satz + **genau eine** Handlungsaufforderung.
- **Refresh:** Pull-to-Refresh auf jeder Liste. **Kein automatisches Polling.**
- **Sprache:** Englisch, über String Catalog lokalisierbar aufgesetzt.

---

## A. Onboarding (6)

| # | Screen | Elemente | States | Navigation |
|---|---|---|---|---|
| S01 | **Welcome** | Logo, Claim, Illustration, [Continue with Apple] | `idle`; `loading` = Spinner im Button; `failed` = Inline-Hinweis (ein Nutzer-Abbruch ist **kein** Fehler) | → S02 (kein Profil) / S10 |
| S02 | **Age Gate** | „One quick thing", Jahres-Picker, Erklärsatz, [Continue] | lokale Prüfung, kein Netz nötig; Server prüft erneut | → S04 / S03 |
| S03 | **Age Blocked** | „Sorry — Beer Quest is 18+", Erklärung, [Close] | — | Session verworfen |
| S04 | **Username** | Feld (3–20, `a-z0-9_`), Live-Status (⏳ / ✓ available / ✗ taken / ✗ not allowed), [Continue] disabled bis ✓ | `loading` = Debounce 400 ms; `failed` = „Couldn't check right now", Continue bleibt möglich | → S05 |
| S05 | **Avatar** | 24 Illustrationen (Bundle), 6 Farb-Chips, Live-Vorschau, [Continue] | — | → S06 |
| S06 | **Invite Code** | Feld (8 Zeichen, auto-uppercase), [Continue], [Skip] | `failed` = „That code isn't valid or has expired" — blockiert nie | → `complete_onboarding` → S10 |

## B. Tabs (5)

### S10 — HOME (Quest-Board, **kein** Feed)
- **Elemente von oben:** ① Kopf: Avatar, Username, `LEVEL 7`, XP-Bar `2,840 / 3,500` · ② **[+ ADD BEER]** groß · ③ **TODAY'S QUEST** mit Fortschrittspunkten · ④ **„Next: 🌍 5 Countries · 3/5"** (nächstes Badge oder Level-Up, je nachdem was näher ist) · ⑤ Passport-Streifen `🌍 3 · 🏙️ 8 · 📍 17 · 🍺 21` · ⑥ Clan-Karte (Name, Clan-Level, eigener Beitrag) oder [Join a clan] · ⑦ Aktivität, **max. 3 Zeilen** · ⑧ Sync-Banner, falls RetryQueue nicht leer.
- **States:** `loading` = Skeletons aller Karten (ein `get_home`-Call); kein `empty` — stattdessen Erstnutzer-Variante mit Erst-Quest und nur zwei Karten; `failed` = Fehlerkarte oben, gecachte Daten bleiben stehen.
- **Navigation:** Quest → S40 · Passport → S14 · Clan → S13/S47 · Banner → S33.

### S11 — MAP
- Vollbildkarte, Zähler-Chip, [Locate me], zoomabhängige Pins (Land → Ort, geclustert), Bottom-Sheet bei Pin-Auswahl.
- `loading` = Karte sichtbar, Pins per Shimmer · `empty` = Overlay „Your world is empty — add your first beer" + [+ ADD BEER] · `failed` = Toast + [Retry] · **ohne Standortberechtigung:** [Locate me] öffnet Hinweis-Sheet mit [Open Settings].
- → S32 (Ort-Detail).

### S12 — QUESTS
- Oben **TODAY'S QUEST** (abgesetzt), darunter Segment [Active] [Available] [Done]; Quest-Karten (Icon, Titel, Fortschrittspunkte, XP, Restzeit).
- `loading` = 3 Karten-Skeletons · `empty` (Active) = „No active quests — pick one below" + Sprung zu *Available* · `empty` (Done) = „Your finished quests will show up here" · `failed` = Fehlerkarte.
- → S40.

### S13 — CLAN
- Zwei Zustände: **ohne Clan** = zwei Karten [Create a clan] / [Join a clan] mit je einem Erklärsatz · **mit Clan** = S47.

### S14 — PROFILE (zugleich Passport-Übersicht)
- Kopf (Avatar, Username, Level, XP-Bar), Stat-Grid (Beers · Locations · Cities · Countries · Quests · Check-ins), **vier Passport-Karten mit Zählern**, Badge-Reihe (verdiente zuerst, offene ausgegraut), Einstiege *Friends*, *History*, *Settings*.
- `loading` Skeleton · `failed` Fehlerkarte mit Cache.
- → S31, S33, S42, S50.

## C. Check-in (5)

### S20 — Which beer?
- Suchfeld mit Autofokus; Abschnitte *Recent* / *Popular near you* / *Search results*; Zeile „Add \"<Eingabe>\"" wenn kein exakter Treffer; [Cancel].
- `idle` = Recent + Popular · `loading` = Zeilen-Skeletons ab 2 Zeichen (Debounce 250 ms) · `empty` = nur die Anlage-Zeile · `failed` = „Search unavailable — you can still add it manually".
- → S21 / S22.

> **Harte Anforderung an die Vorschlagslogik.** Das Bier-Dedupe im Server
> greift nur bei gleicher normalisierter Identität. Wer „Peroni" tippt,
> findet „Peroni Nastro Azzurro" **nicht** automatisch — die App muss es
> vorschlagen, sonst entstehen Dubletten durch Abkürzungen:
>
> ```
> Sucht: Peroni
> 🍺 Peroni Nastro Azzurro
> 🍺 Peroni Nastro Azzurro 0.0
> 🍺 Peroni Gran Riserva
> ```
>
> Umsetzung: Präfix- und Trigram-Treffer aus `search_beers`, sortiert nach
> Häufigkeit; die Anlage-Zeile steht **unter** den Vorschlägen, nie darüber.
> Reine Such- und Sortierlogik — **keine KI**, das ist für dieses Problem
> überdimensioniert.

### S21 — Where?
- Statuszeile (📍 Ortung / Ort gefunden / kein Standort), Suchfeld, Abschnitt *Nearby on Beer Quest* (eigene Orte, mit Entfernung), Zeile „Add a place". **[v0.3] Kein Abschnitt mit Apple-POI-Vorschlägen** — siehe `10-risks.md` R2.
- `loading` = Ortung + Suche parallel · `empty` = „No places nearby yet — add it" + [Add a place] (der Normalfall beim ersten Besuch) · `failed` = Textsuche bleibt möglich · *Berechtigung verweigert* = Hinweiszeile mit [Enable] und reiner Textsuche.
- → S23 / S22.

### S22 — Neue Entität (Bier **oder** Ort)
- **Bier:** Name (vorbelegt), optional Brauerei, Hinweis „You're adding this beer for everyone — please spell it correctly".
- **Ort:** Name, Kategorie-Chips (Bar · Pub · Biergarten · Brewery · Restaurant · Other), Kartenvorschau mit verschiebbarem Pin.
- `failed` = Validierung inline (Länge, Blocklist). Dedupe passiert serverseitig; ein Treffer wird im Reward-Screen als „We matched this to an existing place" gemeldet.

### S23 — Confirm
- Zusammenfassungskarte (🍺 Bier · 📍 Ort · Stadt · 🇮🇹 Land), Datumszeile (Default *Today*, max. 7 Tage zurück), [SAVE].
- `loading` = Spinner im Button, Sheet nicht schließbar · `failed` = Inline-Fehler + [Try again], Eingaben bleiben · *offline* = „Saved — we'll sync it later", Sheet schließt.
- → S24.

### S24 — Reward
- Große XP-Zahl; Discovery-Karten (Bier/Ort/Stadt/Land mit XP); Quest-Fortschritt; Level-Up-Karte; Badge-Karte; Fußzeile **„Next: …"**; [Done]; sekundär [Share] nur bei Level-Up oder Quest-Abschluss.
- **Kein Ladezustand** — der Screen rendert ausschließlich die Antwort von `create_check_in`. Cap-Fall: Hinweiszeile statt Zahl. Der **allererste** Check-in eines Nutzers kann bis zu 550 XP zeigen und erreicht den Cap-Fall nie.
- [Done] schließt den gesamten Sheet-Stack → S10.

> Dieser Screen ist das Produkt. Wenn er sich wie eine Bestätigungsmeldung
> anfühlt, ist die App eine Datenbank.

## D. Passport & Welt (3)

| # | Screen | Elemente | States |
|---|---|---|---|
| S31 | **Passport-Liste** (eine View, vier Konfigurationen: Countries/Cities/Locations/Beers) | Suchleiste, Sortierung (Neueste / A–Z), Zeilen mit Icon, Name, Kontext, Entdeckungsdatum | `empty` = typspezifischer Satz + [+ ADD BEER] · `failed` = Fehlerkarte |
| S32 | **Ort-Detail** | Name, Kategorie, Stadt, Land, Mini-Karte, „Your visits: 4", dort getrunkene Biere, [Check in here] (springt mit vorbelegtem Ort in S20) | `loading` Skeleton |
| S33 | **History** | Chronologisch (Bier, Ort, Stadt, Datum, XP), Wisch-Aktion *Delete* nur < 24 h, Bestätigungsdialog mit XP-Hinweis; oben die RetryQueue-Einträge | `empty` = „No check-ins yet" |

## E. Spiel & Soziales (8)

| # | Screen | Elemente | States | Navigation |
|---|---|---|---|---|
| S40 | **Quest-Detail** | Icon, Titel, Beschreibung, Fortschritt `●●○ 2/3`, XP, Restzeit, [Accept Quest] / [Abandon] | Sonderzustände *expired* (grau, [Accept again]) und *done* (Häkchen + verdiente XP) | ← S12/S10 |
| S42 | **Friends** | Segment [Friends] [Requests] [Leaderboard]; Zeilen mit Avatar, Username, Level, Wochen-XP; [Invite a friend], [Add friend]; Punkt auf *Requests* | `empty` (Friends) = „No friends yet — Beer Quest is better together" + [Invite a friend] · `empty` (Requests) = „No pending requests" · `empty` (Leaderboard) = „Add friends to see how you compare" | → S41, S43, S44 |
| S42-LB | **Leaderboard** (Segment in S42) | [This week] (Default) [All time]; Rang, Avatar, Username, XP; **eigene Zeile immer sichtbar**, notfalls angepinnt | — | — |
| S41 | **Invite Sheet** | Code in Großschrift, Vorschau der Nachricht, [Share…], [Copy code] | `failed` = „Couldn't create an invite" + [Try again] | — |
| S43 | **Add Friend** | Suchfeld (Username), Ergebnisliste mit Zeilenzustand *Add* / *Requested* / *Friends*; Trenner „or"; [Enter a code]; [Invite a friend] | `empty` = „No user found with that name" | → S41, S44 |
| S44 | **Fremdes Profil** | Avatar, Username, Level, Stat-Grid, Badges, [Add friend] / [Remove friend]. Keine exakten Check-in-Orte von Nicht-Freunden | `loading` Skeleton | — |
| S45 | **Clan erstellen** | Name (live geprüft), Avatar + Farbe, [Create clan] | `failed` = „That name is taken" / Blocklist-Hinweis | → S47 |
| S46 | **Clan beitreten** | Feld für Join-Code, [Join] | Fehler mit eigenem Text: ungültig · voll · bereits in einem Clan | → S47 |
| S47 | **Clan-Detail** | Kopf (Avatar, Name, Clan-Level, Clan-XP, Mitglieder), Karte „You: 4,120 XP · #3 of 8", Segment [Members] [Activity], Mitglieder nach Beitrag sortiert, Activity = letzte 10 Ereignisse, Owner sieht Join-Code + [Share], Overflow *Leave clan* | `loading` Skeleton · `failed` Fehlerkarte mit Cache · `empty` (Activity) = „Nothing yet — be the first" | — |

## F. Settings (1)

### S50 — Settings
- **Account:** Anzeigename, Avatar (Username in P0 nicht änderbar — Hinweistext)
- **Permissions:** Standort-Status + [Open Settings]
- **About:** Version, Licenses/Attribution (GeoNames), Responsible-Drinking-Hinweis
- **Danger zone:** [Sign out]
- *Account löschen, Datenexport, Terms, Privacy Policy, Blockierte Nutzer: **P1 ⚖️***

---

## Wiederverwendbare Komponenten (`BQDesign`)

| Komponente | Verwendung |
|---|---|
| `XPBar(level, xp, needed)` | Home, Profile, Clan |
| `NextGoalRow(label, have, need)` | Home, Reward |
| `StatChip(icon, value)` | Home, Profile, Detailköpfe |
| `QuestCard(state)` | Home, Quests, Quest-Detail |
| `EmptyState(icon, text, action)` | 9 Screens |
| `ErrorCard(message, retry)` | alle Datenscreens |
| `RewardCard(kind)` | Reward |
| `AvatarView(key, color, size)` | überall |
| `LeaderboardRow(rank, user, value, isMe)` | Friends-Leaderboard, Clan-Mitglieder |
| `PendingSyncBanner()` | Home |
