# STEP 4 — Screen-Spezifikation (MVP)

Jeder Screen ist gegen `ViewState = idle | loading | loaded | empty | failed`
spezifiziert. Konventionen für die ganze App:

- **Loading:** Skeletons in der Form des späteren Inhalts, kein Vollbild-Spinner.
  Ausnahme: blockierende Aktionen (Save, Accept) → Button-Spinner + Deaktivierung.
- **Error:** Inline-Karte mit Klartext + [Try again]. Nie ein technischer Code,
  nie ein leerer Screen. Offline hat eine eigene Formulierung ("You're offline").
- **Empty:** Icon + ein Satz + **genau eine** Handlungsaufforderung.
- **Refresh:** Pull-to-Refresh auf jeder Liste.
- Sprache: Englisch (D1), lokalisierbar über String Catalog.

Screen-Inventar: 6 Auth/Onboarding · 5 Tabs · 5 Check-in · 6 Passport/Map ·
4 Quests · 5 Social · 4 Clan · 3 Leaderboard · 5 Settings/Legal = **43 Views**,
davon 24 mit eigenem Datenzustand.

---

## A. Auth & Onboarding

### S01 — Welcome
- **Elemente:** Logo, Claim ("Explore the world. Collect the beers. Play with your crew."), Illustration, Button [Continue with Apple], Fußzeile mit Links *Terms* und *Privacy*.
- **States:** `idle`; `loading` = Button-Spinner während Apple-Sheet; `failed` = Inline-Hinweis "Sign-in failed. Please try again." (Abbruch durch den Nutzer erzeugt **keinen** Fehler).
- **Navigation:** Erfolg → S02 (kein Profil) oder S10 (Profil vorhanden).

### S02 — Age Gate
- **Elemente:** Titel "One quick thing", Jahres-Picker (Default: leer), Erklärsatz, Button [Continue].
- **Aktionen:** Continue prüft gegen Mindestalter (Default 18).
- **States:** Blockiert → S03. Kein Netz nötig (lokale Prüfung), Server prüft erneut in `complete_onboarding`.
- **Navigation:** → S04.

### S03 — Age Blocked
- Titel "Sorry — Beer Quest is 18+", Erklärung, Button [Close]. Session wird verworfen, Entscheidung lokal gemerkt.

### S04 — Username
- **Elemente:** Feld (3–20 Zeichen, `a-z0-9_`), Live-Status (⏳ prüft / ✓ available / ✗ taken / ✗ not allowed), Button [Continue] (disabled bis ✓).
- **States:** `loading` = Debounce-Prüfung (400 ms); `failed` = "Couldn't check right now" + Continue trotzdem möglich (Server entscheidet final).

### S05 — Avatar
- Grid 24 Illustrationen, darunter Farb-Chips (6), Live-Vorschau, [Continue].
- Kein Foto-Upload (D4).

### S06 — Invite Code (optional)
- Feld (8 Zeichen, auto-uppercase), [Continue], [Skip].
- **States:** `failed` = "That code isn't valid or has expired" — blockiert nie, [Skip] bleibt.
- **Navigation:** → `complete_onboarding` → S10 mit Erst-Quest.

---

## B. Haupt-Tabs

### S10 — HOME
- **Elemente (von oben):**
  1. Kopf: Avatar, Username, `LEVEL 7`, XP-Bar `2,840 / 3,500`.
  2. Primäraktion [+ ADD BEER] (groß, immer sichtbar).
  3. Karte "Your next quest" — aktive Quest mit Fortschrittspunkten, oder Vorschlag, wenn keine aktiv.
  4. Passport-Streifen: `🌍 3 · 🏙️ 8 · 📍 17 · 🍺 21` (tappbar → S30).
  5. Clan-Karte: Name, Clan-Level, eigener Beitrag — oder [Join a clan].
  6. "Recent activity": letzte 5 Ereignisse von Freunden/Clan (ersetzt Push im MVP, 1.7).
  7. Sync-Banner, falls Offline-Queue nicht leer (F3).
- **States:** `loading` = Skeleton für alle Karten (ein Call `get_home`); `empty` gibt es nicht — stattdessen Erstnutzer-Variante mit Erst-Quest und nur zwei Karten; `failed` = Fehlerkarte oben, gecachte Daten bleiben sichtbar.
- **Navigation:** Quest → S40, Passport → S30, Clan → S60/S63, Aktivität → S52.

### S11 — MAP
- **Elemente:** Vollbildkarte, Zähler-Chip oben (🌍🏙️📍🍺), Button "Locate me", Zoom-abhängige Pins (Land → Stadt → Venue, geclustert), Bottom-Sheet bei Pin-Auswahl.
- **States:** `loading` = Karte sichtbar, Pins per Shimmer; `empty` = zentrierte Karte mit Overlay "Your world is empty — add your first beer" + [+ ADD BEER]; `failed` = Toast + [Retry]; Sonderfall *keine Standortberechtigung*: "Locate me" zeigt Hinweis-Sheet mit [Open Settings].
- **Navigation:** Stadtpin → S32, Venue-Pin → S34.

### S12 — QUESTS
- **Elemente:** Segment [Active] [Available] [Completed]; Quest-Karten (Icon, Titel, Fortschrittspunkte, XP, Restzeit); Button [Start a group quest].
- **States:** `loading` = 3 Karten-Skeletons; `empty` (Active) = "No active quests — pick one below" + Sprung zu *Available*; `empty` (Completed) = "Your finished quests will show up here"; `failed` = Fehlerkarte + [Try again].
- **Navigation:** Karte → S40; Group Quest → S42.

### S13 — CLAN
- Zwei Zustände: **ohne Clan** = S60, **mit Clan** = S63.

### S14 — PROFILE
- **Elemente:** Kopf (Avatar, Username, Level, XP-Bar), Stat-Grid (Beers · Locations · Cities · Countries · Quests · Check-ins), Passport-Einstieg, Badge-Reihe (verdiente zuerst, nicht verdiente ausgegraut), Einstiege *Friends*, *History*, *Settings*.
- **States:** `loading` = Skeleton; `failed` = Fehlerkarte mit Cache.
- **Navigation:** → S30, S35, S50, S53, S70.

---

## C. Check-in (Sheet-Stack)

### S20 — Add Beer · Schritt 1 "Which beer?"
- **Elemente:** Suchfeld (Autofokus), Abschnitte *Recent* / *Popular near you* / *Search results*, Zeile "Add \"<Eingabe>\"" wenn kein exakter Treffer, [Cancel].
- **States:** `idle` = Recent + Popular; `loading` = Zeilen-Skeletons ab 2 Zeichen (Debounce 250 ms); `empty` = nur die Anlage-Zeile; `failed` = "Search unavailable — you can still add it manually".
- **Navigation:** Auswahl → S21; "Add …" → S22.

### S21 — Add Beer · Schritt 2 "Where?"
- **Elemente:** Statuszeile (📍 Ortung läuft / Ort gefunden / kein Standort), Suchfeld, Abschnitt *Nearby on Beer Quest* (mit Distanz), Abschnitt *Suggestions* (Kartensuche, klar als Vorschlag markiert), Zeile "Add a place", Zurück.
- **States:** `loading` = Ortung + Suche parallel, Skeletons; `empty` = "No places nearby" + [Add a place]; `failed` = manuelle Suche bleibt möglich; *Berechtigung verweigert* = Hinweiszeile mit [Enable] und reiner Textsuche.
- **Navigation:** Auswahl → S23; "Add a place" → S22.

### S22 — Neue Entität anlegen (Bier **oder** Ort)
- **Bier:** Name (vorbelegt), optional Brauerei, Info "You're adding this beer for everyone — please spell it correctly".
- **Ort:** Name, Kategorie (Chips: Bar · Pub · Biergarten · Brewery · Restaurant · Other), Kartenvorschau mit verschiebbarem Pin.
- **States:** `failed` = Validierungsfehler inline (Länge, Wortfilter); Duplikat-Erkennung serverseitig → Hinweis "We matched this to an existing place" auf dem Reward-Screen.

### S23 — Add Beer · Bestätigen
- **Elemente:** Zusammenfassungskarte (🍺 Bier · 📍 Ort · Stadt · 🇮🇹 Land), Datumszeile (Default *Today*, max. 7 Tage zurück), optionales Notizfeld (140 Zeichen), Button [SAVE].
- **States:** `loading` = Button-Spinner, Sheet nicht schließbar; `failed` = Inline-Fehler + [Try again], Eingaben bleiben; *offline* = "Saved — will sync when you're back online" und Sheet schließt.
- **Navigation:** → S24.

### S24 — Reward
- **Elemente:** Große XP-Zahl, Discovery-Karten (Bier/Ort/Stadt/Land mit XP), optional Quest-Fortschritt, Level-Up-Karte, Badge-Karte, Button [Done], sekundär [Share] (System-Share, MVP: nur bei Level-Up und Quest-Abschluss).
- **States:** kein Ladezustand — der Screen rendert ausschließlich die Antwort von `create_check_in`. Cap-Fall: Hinweiszeile statt XP-Zahl.
- **Navigation:** [Done] → schließt den gesamten Sheet-Stack → Home.

---

## D. Passport, Karte, Detailansichten

### S30 — Passport Übersicht
- Vier große Karten (Countries · Cities · Locations · Beers) mit Zählern und Vorschau-Icons.
- `empty` = "Nothing collected yet" + [+ ADD BEER].

### S31 — Passport-Liste (generisch, 4 Ausprägungen)
- Suchleiste, Sortierung (Neueste / A–Z), Zeilen mit Icon, Name, Kontext (Stadt/Land), Datum der Entdeckung.
- `empty` = typspezifischer Satz + [+ ADD BEER]; `failed` = Fehlerkarte.
- **Navigation:** Land → S33, Stadt → S32, Ort → S34, Bier → S36.

### S32 — City Detail (§20)
- **Elemente:** Kopf (Flagge, Stadtname, **City Level** + XP-Bar — kein Prozentwert, V2), Zähler (Beers · Locations · Quests), Abschnitte *Your places here*, *Your beers here*, *Top explorers* (Top 5 mit Einstieg in S82).
- **States:** `loading` Skeleton; `failed` Fehlerkarte. `empty` existiert nicht (der Screen ist nur über gesammelte Städte erreichbar).

### S33 — Country Detail (§21)
- Kopf (Flagge, Name), Zähler (Cities · Locations · Beers), Liste der besuchten Städte.

### S34 — Venue Detail
- Kopf (Name, Kategorie, Stadt, Land), Mini-Karte, "Your visits: 4", Liste der dort getrunkenen Biere, Aktionen [Check in here] (springt in S20 mit vorbelegtem Ort), Overflow: *Report*.

### S35 — History (Check-in-Liste)
- Chronologische Liste (Bier, Ort, Stadt, Datum, XP), Wisch-Aktion *Delete* nur < 24 h.
- `empty` = "No check-ins yet"; Löschung → Bestätigungsdialog mit XP-Hinweis.

### S36 — Beer Detail
- Name, Brauerei, "You've had this 3 times", Liste der Orte/Daten.

---

## E. Quests

### S40 — Quest Detail
- **Elemente:** Icon, Titel, Beschreibung, Zielfortschritt (`●●○ 2/3`), XP-Belohnung, Restzeit, bei Social: Teilnehmerliste mit Einzelbeiträgen; Buttons [Accept Quest] / [Abandon] / [Invite friends] (nur Social, nur Owner).
- **States:** `loading` Skeleton; `failed` Fehlerkarte; Sonderzustände *expired* (grau, Button [Accept again]) und *completed* (Häkchen + verdiente XP).
- **Navigation:** [Invite friends] → S41.

### S41 — Invite Sheet
- Vorschau der Nachricht, Code-Anzeige in Großschrift, [Share…] (System-Share), [Copy link].
- `failed` = "Couldn't create an invite" + [Try again].

### S42 — Social Quest erstellen
- Vorlagenauswahl (2 Karten), Info zu Dauer und Belohnung, [Create & invite].
- Sonderzustand *0 Freunde*: Karte "Quests are better with friends" + [Invite a friend] oben, Vorlagen bleiben trotzdem wählbar.

### S43 — Quest-Beitritt (aus Deep Link)
- Sheet: Avatar des Einladenden, Quest-Titel, Ziel, Belohnung, [Join quest] / [Not now].
- `failed`-Varianten mit eigenem Text: abgelaufen · voll · eigene Quest · bereits Teilnehmer.

---

## F. Social

### S50 — Friends
- Segment [Friends] [Requests] [Leaderboard]; Zeilen mit Avatar, Username, Level, Wochen-XP; Kopfzeile [Add friend]; Badge-Punkt auf *Requests* bei offenen Anfragen.
- `empty` (Friends) = "No friends yet — Beer Quest is better together" + [Invite a friend].
- `empty` (Requests) = "No pending requests".

### S51 — Add Friend
- Suchfeld für Username, Ergebnisliste mit [Add], Trenner "or", Karte [Share invite link].
- Zustände je Zeile: *Add* · *Requested* · *Friends* · *Blocked*.
- `empty` = "No user found with that name".

### S52 — Fremdes Profil
- Kopf (Avatar, Username, Level), Stat-Grid, Badges, Buttons [Add friend] / [Remove friend], Overflow: *Block*, *Report*.
- Sichtbarkeit: keine exakten Check-in-Orte von Nicht-Freunden.

### S53 — Invite Link teilen
- Wie S41, Variante `kind = friend`.

### S54 — Report
- Grund-Auswahl (Radio), optionales Textfeld (500 Zeichen), [Submit report].
- `loading` Button-Spinner; Erfolg → Bestätigung "We review reports within 24 hours".

---

## G. Clan

### S60 — Clan (ohne Clan)
- Zwei Karten: [Create a clan] (Erklärsatz) und [Join a clan]; darunter "Popular clans" (offene Clans, Top 10 nach XP).
- `empty` bei "Popular clans" = Karte wird ausgeblendet.

### S61 — Clan erstellen
- Name (Live-Verfügbarkeit), Avatar + Farbe, Beschreibung (optional, 200 Zeichen), Sichtbarkeit (Open / Code only), [Create clan].
- `failed` = "That name is taken" / Wortfilter-Hinweis.

### S62 — Clan beitreten
- Feld für Join-Code + [Join], Trenner, Suchliste offener Clans (Name, Mitglieder, Clan-Level).
- Fehlerfälle mit eigenem Text: ungültig · voll · bereits Mitglied eines Clans.

### S63 — Clan Detail (Mitglied)
- Kopf (Avatar, Name, Clan-Level, Clan-XP, Mitgliederzahl), eigener Beitrag als Karte ("You: 4,120 XP · #3"), Segment [Members] [Ranking], Mitgliederliste (sortiert nach Beitrag), Owner sieht Join-Code + [Share], Overflow: *Leave clan*, *Report clan*.
- `loading` Skeleton; `failed` Fehlerkarte mit Cache.

---

## H. Leaderboards

### S80 — Friends Leaderboard
- Segment [This week] [All time]; Zeilen mit Rang, Avatar, Username, XP; eigene Zeile hervorgehoben und **immer sichtbar** (angepinnt, falls außerhalb der Liste).
- `empty` = "Add friends to see how you compare" + [Add friend].

### S81 — Clan Leaderboard
- Segment [Total XP] [Per member]; Top 50; eigener Clan angepinnt.

### S82 — City Leaderboard
- Kopf mit Stadtname, Top 20, eigene Position angepinnt.
- `empty` = "Be the first to explore <City>".

---

## I. Settings & Legal

### S70 — Settings
- Abschnitte:
  - **Account:** Username (nicht änderbar im MVP — Hinweistext), Display name, Avatar
  - **Permissions:** Standort-Status + [Open Settings]
  - **Privacy:** Blocked users → S71, Export my data
  - **About:** Terms, Privacy Policy, Licenses/Attribution (GeoNames), Version
  - **Responsible drinking:** kurzer Hinweistext + Link
  - **Danger zone:** [Sign out], [Delete account] (rot)

### S71 — Blocked Users
- Liste mit [Unblock]; `empty` = "You haven't blocked anyone".

### S72 — Delete Account
- Warnkarte (was gelöscht/anonymisiert wird), Feld "Type your username to confirm", [Delete my account] (rot, disabled bis Übereinstimmung).
- `loading` = blockierender Spinner; Erfolg → S01.

### S73/S74 — Terms / Privacy Policy
- In-App-WebView auf die statische Website, offline-Hinweis bei Fehler.

---

## J. Übergreifende Komponenten (BQDesign)

| Komponente | Verwendung |
|---|---|
| `XPBar(level, xp, needed)` | Home, Profile, City, Clan |
| `StatChip(icon, value)` | Home-Streifen, Detailköpfe |
| `QuestCard(state)` | Home, Quests, Quest Detail |
| `EmptyState(icon, text, action)` | 14 Screens |
| `ErrorCard(message, retry)` | alle Datenscreens |
| `RewardCard(kind)` | Reward-Screen |
| `AvatarView(key, color, size)` | überall |
| `LeaderboardRow(rank, user, value, isMe)` | 3 Leaderboards |
| `PendingSyncBanner()` | Home |
