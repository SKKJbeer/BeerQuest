# MVP User Flows (v0.2 — P0)

Notation: `→` Schritt · `⤷` Verzweigung/Fehlerfall · **fett** = Server-Call

Enthält ausschließlich P0-Flows. Was gestrichen wurde und wohin, steht in
`03-feature-matrix.md`.

---

## F1 — Erststart (Ziel: < 90 Sekunden bis zum ersten Erfolg)

```
App-Start ohne Token
 → WELCOME
   „BEER QUEST — Explore the world. Collect the beers. Play with your crew."
   [Continue with Apple]
 → Sign in with Apple (System-Sheet)
   ⤷ Abbruch → zurück, kein Fehler
   ⤷ Fehler → Hinweis + [Try again]
 → AGE GATE: „What year were you born?"
   ⤷ unter 18 → Blocking-Screen, Session verworfen, Entscheidung lokal gemerkt
 → USERNAME (live geprüft, 3–20 Zeichen, Basis-Blocklist)
 → AVATAR (24 Illustrationen × 6 Farben, aus dem App-Bundle)
 → „Have an invite code?" [Feld] [Skip]
 → **complete_onboarding(…)**
 → HOME mit aktiver Erst-Quest:
   🎯 Your First Quest — „Discover your first beer" · +100 XP
   Primäraktion: [ + ADD BEER ]
 → F2
```

---

## F2 — Beer Check-in (der Kernflow)

**Designziel: zwei Taps und ein Feld.** Stadt und Land werden **nie** abgefragt
— sie ergeben sich serverseitig aus dem Ort und werden nur angezeigt.

```
[ + ADD BEER ]  (Mitte der Tab-Leiste, öffnet ein Sheet)

 → Schritt 1: WHICH BEER?
   Suchfeld mit Autofokus
   Reihenfolge: zuletzt getrunken · verbreitet in der Nähe · Suchtreffer
   ⤷ kein Treffer → Zeile „Add \"Nastro Azzurro\""

 → Schritt 2: WHERE?
   Standortabfrage nur beim ersten Mal, mit Erklärtext
   ⤷ verweigert → reine Textsuche, Flow läuft weiter
   ⤷ Ortung läuft → Skeleton-Liste
   Abschnitt „Nearby on Beer Quest" (mit Entfernung)
   Abschnitt „Suggestions" (Kartensuche, als Vorschlag gekennzeichnet)
   ⤷ nichts passend → „Add a place" (Name + Kategorie, Koordinate = aktuell)

 → Bestätigungszeile: 🍺 Peroni · 📍 Bar Aurora · Cecina · 🇮🇹 · Today
   (Datum antippbar, max. 7 Tage zurück)

 → [SAVE] → **create_check_in(…)**   (ein Call, eine Transaktion)
   ⤷ Fehler/offline → Eintrag in die RetryQueue, Sheet schließt,
      Home zeigt „1 check-in waiting" (F3)

 → REWARD (Overlay, rendert ausschließlich die Server-Antwort)
   „+200 XP"
   🍺 New beer discovered   +50
   📍 New location          +50
   🏙️ New city: Cecina      +150
   Quest: Discover 2 new beers  ●●○  1/2
   ⤷ Level-Up  → zusätzliche Karte
   ⤷ Badge     → zusätzliche Karte
   ⤷ Quest fertig → Quest-Complete-Karte mit XP
   ⤷ Tages-Cap → Hinweiszeile statt XP-Zahl
   Fußzeile: „Next: 🌍 5 Countries · 3/5"
 → [Done] → Home, Zähler und Fortschritt aktualisiert
```

---

## F3 — Fehlgeschlagener Check-in (RetryQueue)

```
create_check_in schlägt fehl
 → lokale Ablage (client_uuid + Eingaben + Zeitzone)
 → Home zeigt Banner „1 check-in waiting to sync"
 → erneuter Versuch bei App-Start und bei Netzwechsel
 → Erfolg → Reward-Screen wird nachgereicht
 ⤷ dauerhafter Fachfehler → Banner antippbar, Nutzer kann korrigieren
   oder verwerfen
```
XP werden **nie** lokal geschätzt. Bis zur Bestätigung heißt es „pending".
Vollständige Offline-Synchronisation ist P1.

---

## F4 — Passport & Karte

```
Tab MAP
 → Weltansicht: Länder-Pins mit Zählern (🌍 3 · 🏙️ 8 · 📍 17 · 🍺 21)
 → Zoom → geclusterte Orts-Pins
 → Tap Pin → Ort-Detail (Besuche, dort getrunkene Biere, [Check in here])

Tab PROFILE → Passport
 → Vier Listen: Countries · Cities · Locations · Beers
 → Es wird nur Gesammeltes gezeigt — keine „Locked"-Listen, sonst entsteht
   das Gefühl eines unendlichen Katalogs statt einer eigenen Sammlung.
```
City- und Country-Detailseiten sind P1.

---

## F5 — Quest annehmen und abschließen

```
Tab QUESTS
 → Oben: TODAY'S QUEST (wechselt um Mitternacht, zusätzlich zu den 3 Slots)
 → Segmente [Active] [Available] [Done]
 → Tap → Quest-Detail: Ziel, Belohnung, Restzeit, Fortschritt
 → [Accept Quest] → **accept_quest(code)**
   ⤷ bereits 3 aktive → Hinweis + Vorschlag, eine aufzugeben
 → Fortschritt entsteht ausschließlich über F2
 → Ziel erreicht → Quest-Complete-Karte im Reward-Screen, XP gutgeschrieben
 ⤷ Zeit abgelaufen → Status 'expired', erneut annehmbar
```
City- und Social-Quests sind P1.

---

## F6 — Freund einladen (Code, nicht Deep Link)

```
Profile → Friends → [Invite a friend]
 → **create_invite()** → Code, 30 Tage gültig
 → System-Share-Sheet mit Text:
   „🍺 Join my Beer Quest — my code is K7QF2M9A. Get the app: <TestFlight-Link>"

Empfänger:
 ⤷ noch keine App → installiert, gibt den Code im Onboarding ein (F1)
 ⤷ App vorhanden → Friends → [Enter a code] → **redeem_invite(code)**
 → Freundschaft entsteht sofort, beide erhalten +25 XP
 ⤷ abgelaufen / ausgeschöpft / eigener Code → jeweils eigener Klartexthinweis
```
Universal Links sind P1 — sie lösen später denselben Code automatisch ein,
die Serverlogik bleibt unverändert.

---

## F7 — Freund über Username hinzufügen

```
Profile → Friends → [Add friend] → Username suchen
 → [Add] → **send_friend_request**
 → Empfänger: Punkt auf dem Profil-Tab, Segment „Requests"
   [Accept] → **respond_friend_request(id, true)** → beide +25 XP
   [Decline] → still, kein Hinweis an den Absender
 → Freundesliste: Avatar, Username, Level, Wochen-XP
   Kontextmenü: View profile · Remove friend
```
Blockieren und Melden sind P1 ⚖️.

---

## F8 — Clan

```
Tab CLAN (ohne Clan) → zwei Karten

CREATE  → Name (live geprüft) → Avatar + Farbe → **create_clan(…)**
        → Clan-Detail, Nutzer ist Owner, Join-Code sichtbar und teilbar

JOIN    → Code eingeben → **join_clan_by_code(code)**
        ⤷ ungültig / voll (50) / bereits in einem Clan → eigener Hinweis

CLAN-DETAIL (Mitglied)
   Kopf: Avatar, Name, Clan-Level, Clan-XP, Mitgliederzahl
   Karte: „You: 4,120 XP · #3 of 8"
   Segmente [Members] [Activity]
     Members  → nach Beitrag sortiert
     Activity → letzte 10 Ereignisse:
                „Steffen discovered a new beer"
                „Lisa completed a quest"
                „Max discovered Prague"
   Owner: Join-Code + [Share]
   Overflow: Leave clan

LEAVE  → Bestätigung, Hinweis: eingebrachte Clan-XP bleiben beim Clan
       ⤷ Owner geht → Rolle an das dienstälteste Mitglied
       ⤷ letztes Mitglied geht → Clan wird soft-deleted
```
Offene Clans durchsuchen, Beschreibung und Sichtbarkeit sind P1.

---

## F9 — Leaderboard

```
Profile → Friends → Segment [Leaderboard]
 → [This week] (Default) · [All time]
 → Rang, Avatar, Username, XP
 → Die eigene Zeile ist hervorgehoben und **immer sichtbar** —
   auch außerhalb der Liste angepinnt.
 ⤷ keine Freunde → „Add friends to see how you compare" + [Invite a friend]
```
Das Wochen-Leaderboard startet montags neu und ist damit einer der beiden
Gründe wiederzukommen (der andere ist die Tagesquest).

Clan-vs-Clan- und City-Leaderboards sind P1.

---

## F10 — Nebenflows

| Flow | Verhalten |
|---|---|
| Level-Up | Karte im Reward-Screen, nie ein eigener Screen; XP-Bar auf Home animiert einmalig |
| Standort verweigert | Alle Flows bleiben nutzbar; Ortssuche per Text; Karte zentriert auf den zuletzt entdeckten Ort |
| Check-in korrigieren | Profile → History → Zeile wischen → Delete (nur < 24 h); XP per Gegenbuchung |
| Tages-Cap erreicht | Reward zeigt Hinweis statt Zahl; der Check-in zählt weiter für Passport und Quests |
| Session abgelaufen | Stiller Refresh; scheitert er → Welcome mit Hinweis |
| Tagesquest-Wechsel | Beim Öffnen nach Mitternacht: neue Quest oben im Quest-Tab, dezent markiert |
