# STEP 3 — MVP User Flows

Notation: `→` Schritt · `⤷` Verzweigung/Fehlerfall · **fett** = Server-Call

---

## F1 — First Time User Experience (§29)

**Ziel:** vom App-Start bis zum ersten Erfolgserlebnis in < 90 Sekunden.

```
App-Start (kein Token)
 → Welcome
   "BEER QUEST — Explore the world. Collect the beers. Play with your crew."
   [Continue with Apple]  ·  Links: Terms, Privacy
 → Sign in with Apple (System-Sheet)
   ⤷ Abbruch/Fehler → zurück zu Welcome + Fehlerhinweis
 → Age Gate:  "What year were you born?"  (Picker, Jahre)
   ⤷ unter der Altersgrenze des gewählten Landes (Default 18)
     → Blocking-Screen "Come back when you're older", kein Account,
       Auth-Session wird verworfen. Wahl wird auf dem Gerät gemerkt
       (kein sofortiges Neu-Probieren).
 → Username  (live-Verfügbarkeitsprüfung, 3–20 Zeichen, Wortfilter)
 → Avatar wählen (24 Illustrationen × 6 Farben)
 → "Have an invite code?"  [Feld]  [Skip]        ← Deferred-Deep-Link-Lösung (R3)
 → **complete_onboarding(...)**  (+ ggf. **redeem_invite**)
 → Home mit aktiver Erst-Quest:
   🎯 Your First Quest — "Discover your first beer" · +100 XP
   Primäraktion: [ + ADD BEER ]
 → F2
```

---

## F2 — Beer Check-in (Kernflow, §8)

**Designziel:** zwei Taps und ein Feld. Stadt und Land werden **nie** abgefragt
(UX-Problem 1) — sie ergeben sich aus der Location und werden nur angezeigt.

```
[ + ADD BEER ]  (Tab-Bar-Mitte, öffnet Sheet)
 → Schritt 1: WHICH BEER?
   Suchfeld + Vorschlagsliste
   Reihenfolge: zuletzt getrunken · Favoriten der Region · Katalogtreffer
   ⤷ kein Treffer → Zeile "Add \"Nastro Azzurro\"" (freie Anlage)
 → Schritt 2: WHERE?
   Standortabfrage (nur beim allerersten Mal, mit Erklärtext)
   ⤷ Berechtigung verweigert → manuelle Ortssuche, Flow läuft weiter
   ⤷ Ortung läuft → Skeleton-Liste
   Liste: Beer-Quest-Venues im Umkreis (mit Distanz)
          — getrennter Abschnitt — Vorschläge aus Kartensuche
   ⤷ nichts passend → "Add a place" (Name + Kategorie, Koordinate = aktuell)
 → Bestätigungszeile:  🍺 Peroni · 📍 Bar Aurora · Cecina · 🇮🇹 · heute
   (Datum antippbar → Datepicker, max. 7 Tage zurück)
 → [SAVE]
 → **create_check_in(...)**   (ein Call, transaktional)
   ⤷ offline → lokal in Queue, Sheet schließt, Home zeigt "1 pending"
   ⤷ Fehler → Retry-Sheet, Eingaben bleiben erhalten
 → REWARD-Screen (Overlay), rendert die Server-Antwort:
   "+200 XP"
   🍺 New beer discovered  +50
   📍 New location         +50
   🏙️ New city: Cecina     +150
   Quest: Discover 2 new beers  ●●○  1/2
   ⤷ Level-Up  → zusätzliche Level-Up-Karte
   ⤷ Badge     → zusätzliche Badge-Karte
   ⤷ Quest abgeschlossen → Quest-Complete-Karte mit XP
   ⤷ Tages-Cap erreicht → Hinweis statt XP-Zahl
 → [Done] → Home (Zähler und Fortschritt aktualisiert)
```

---

## F3 — Offline Check-in

```
create_check_in schlägt fehl (kein Netz)
 → lokale Queue (client_uuid, Eingaben, Zeitstempel, Zeitzone)
 → Home zeigt Banner "1 check-in waiting to sync"
 → bei App-Foreground oder Netzwechsel: Queue abarbeiten (sequenziell)
 → Erfolg → Reward-Screen nachgereicht (gesammelt, falls mehrere)
 ⤷ dauerhafter Fachfehler (z. B. Venue gelöscht) → Eintrag im Banner
   antippbar, Nutzer kann korrigieren oder verwerfen
```
XP werden **nie** lokal geschätzt; bis zur Synchronisation zeigt der
Check-in "pending".

---

## F4 — Passport & Karte erkunden

```
Tab MAP
 → Weltansicht: Länderpins mit Zählern (🌍 3 · 🏙️ 8 · 📍 17 · 🍺 21)
 → Zoom → Städte → Venues (geclustert)
 → Tap Venue-Pin → Venue-Karte (Besuche, dort getrunkene Biere)
 → Tap Stadtpin → CITY DETAIL
     🏙️ ROME · City Level 3 · 8 beers · 6 locations · 3 quests
     Abschnitte: Your beers here · Your places here · Top explorers (City-LB)
 → Tab PROFILE → Passport
     Countries / Cities / Locations / Beers als vier Listen
     gesammelt = farbig, gesperrt existiert nicht (nur Gesammeltes wird gezeigt,
     keine "Locked"-Liste — sonst entsteht ein unendliches Katalog-Gefühl)
```

---

## F5 — Solo Quest annehmen und abschließen

```
Tab QUESTS
 → Abschnitt "Active" (max. 3) / "Available"
 → Tap "Discover 2 new beers · +200 XP · 3 days"
 → Quest-Detail: Ziel, Belohnung, Restzeit, Fortschritt
 → [Accept Quest] → **accept_quest(code)**
   ⤷ bereits 3 aktive Quests → Hinweis + Vorschlag, eine aufzugeben
 → Fortschritt entsteht ausschließlich über F2
 → Bei Erreichen des Ziels: Quest-Complete-Karte im Reward-Screen,
   Quest wandert in "Completed", XP werden gutgeschrieben
 ⤷ Ablauf der Zeit → Status 'expired', Quest verschwindet aus "Active",
   erneut annehmbar
```

## F6 — City Quest

```
Tab QUESTS → "Discover 2 beer locations in this city"
 → App kennt die aktuelle Stadt?
   ⤷ nein (kein Standort) → "Enable location to start city quests" + Aktion
 → [Accept] → **accept_quest('city_two_venues', city_id)**
   Die Stadt wird beim Annehmen fixiert und im Quest-Titel angezeigt
   ("Explore Rome"), damit sie beim Weiterreisen eindeutig bleibt.
```

## F7 — Social Quest erstellen und teilen (§15)

```
Tab QUESTS → [Start a group quest]
 ⤷ 0 Freunde → Screen zeigt zuerst Invite-CTA (UX-Problem 6)
 → Vorlage wählen (2 Vorlagen)
 → **create_social_quest(code)** → Quest + Invite-Code
 → Share-Sheet:
   "🍺 Join my Beer Quest — Friday Beer Quest, discover 2 new locations
    https://beerquest.app/i/K7QF2M9A"
 → Quest-Detail zeigt Teilnehmerliste und gemeinsamen Fortschritt
 → Abschluss: gemeinsamer Zähler erreicht → alle mit Beitrag ≥ 1 erhalten XP
```

## F8 — Invite empfangen (§14, §31)

```
Empfänger tippt Link
 ⤷ App installiert → Universal Link → App öffnet
     ⤷ eingeloggt → Bestätigungs-Sheet
        "Anna invited you" [Add friend] / bei Quest-Invite [Join quest]
        → **redeem_invite(code)** → Freundschaft (+25 XP beiden) bzw.
          Quest-Beitritt + Freundschaft
        ⤷ abgelaufen/aufgebraucht/eigener Code → verständlicher Hinweis
     ⤷ nicht eingeloggt → Code merken → F1 → Einlösung nach Onboarding
 ⤷ App nicht installiert → Landing-Page
     zeigt Code groß + [Get Beer Quest] → App Store
     → nach Installation: F1, im Schritt "Have an invite code?" eingeben
```

## F9/F10 — Freunde

```
Profile → Friends → [Add friend]
  Option A: Username suchen → **send_friend_request**
  Option B: [Share invite link] → F8
 → Empfänger: Profile-Tab zeigt Badge, Liste "Requests"
   [Accept] → **respond_friend_request(id, true)** → beide +25 XP
   [Decline] → Status 'declined', kein Hinweis an den Absender
 → Freundesliste: Avatar, Username, Level, Wochen-XP
   Zeilen-Kontextmenü: View profile · Remove friend · Block · Report
```

## F11–F13 — Clan

```
Tab CLAN (ohne Clan)
 → Zwei Karten: [Create a clan] · [Join a clan]

CREATE: Name (unique, Wortfilter) → Avatar/Farbe → optional Beschreibung
 → Sichtbarkeit: Open / Code only
 → **create_clan(...)** → Clan-Detail, Nutzer ist Owner, Join-Code sichtbar

JOIN: Code eingeben oder offene Clans durchsuchen
 → **join_clan_by_code(code)** / **join_clan(id)**
 ⤷ Clan voll (50) / Code ungültig → Fehlermeldung
 ⤷ bereits in einem Clan → "Leave your current clan first" (V5)

LEAVE: Clan-Detail → … → Leave clan (Bestätigung)
 ⤷ Owner verlässt → Owner-Rolle geht an das dienstälteste Mitglied;
   letztes Mitglied verlässt → Clan wird soft-deleted
 Hinweis im Dialog: bereits beigetragene Clan-XP bleiben beim Clan.
```

## F14 — Leaderboards (§19)

```
Erreichbar über: Profile → Friends → Segment "Leaderboard",
                 Clan → Segment "Ranking",
                 City Detail → "Top explorers"
Friends:  [This week] [All time]   ← Default: This week (D7)
Clans:    [Total XP] [Per member]  ← Fairness für kleine Clans (1.6)
City:     Top 20 im Umkreis der Stadt, eigene Position immer sichtbar
          (angepinnte Zeile, auch außerhalb der Top 20)
```

## F15 — Melden & Blockieren (App-Store-Pflicht)

```
Fremdes Profil / Clan / Venue → … → Report
 → Grund wählen (Offensive name · Impersonation · Spam · Other) → optional Text
 → **report(...)** → Bestätigung "Thanks — we review reports within 24 hours"
Block: sofort wirksam, blockierte Nutzer verschwinden aus Suche, Listen,
Leaderboards; bestehende Freundschaft wird aufgelöst.
```

## F16 — Account löschen (App-Store-Pflicht)

```
Profile → Settings → Delete account
 → Warnhinweis: was gelöscht wird, was anonymisiert bleibt (Venue-/Bier-Katalog)
 → Eingabe des eigenen Usernames zur Bestätigung
 → **delete-account** (Edge Function)
 → Abmeldung, zurück zu Welcome
```

## F17 — Nebenflows

| Flow | Verhalten |
|---|---|
| Level-Up | Karte im Reward-Screen, nie ein eigener Screen; Home-XP-Bar animiert einmalig |
| Standort verweigert | Alle Flows bleiben nutzbar; Karte zentriert auf letzte Venue; City-Quests zeigen Hinweis mit Direktlink in die Einstellungen |
| Check-in korrigieren | Profile → History → Zeile wischen → Delete (nur < 24 h); XP werden per Gegenbuchung im Ledger zurückgenommen |
| Tages-Cap erreicht | Reward-Screen zeigt "XP maxed for today" statt Zahl; Check-in zählt weiterhin für Passport und Quests |
| Session abgelaufen | Stiller Refresh; scheitert er → Welcome mit Hinweis |
