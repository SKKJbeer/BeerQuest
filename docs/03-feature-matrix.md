# P0 / P1 / P2 — Feature-Matrix

- **P0** — notwendig, um den Core Loop zu testen. Ziel: interner TestFlight.
- **P1** — sehr wahrscheinlich nötig, aber nicht für den ersten Test.
  Enthält alles, was vor einem **externen** TestFlight bzw. App-Store-Release
  zwingend fertig sein muss (mit ⚖️ markiert).
- **P2** — langfristige Vision. Kommt nicht ohne neue Produktentscheidung.

**Regel:** Nichts aus P1/P2 wandert ohne ausdrückliche Entscheidung nach P0.

**Zur Bedeutung von ⚖️:** Diese Punkte sind für den **internen** TestFlight
verzichtbar, für jede **externe** Verteilung dagegen zwingend und vollständig.
Die verbindliche Liste steht in `11-release-gates.md`.

---

## Account & Profil

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Sign in with Apple | ✅ | | |
| Age Gate (Geburtsjahr) | ✅ | | |
| Username (eindeutig) | ✅ | | |
| Avatar aus Bundle-Auswahl | ✅ | | |
| Profil mit XP, Level, Stats | ✅ | | |
| Badges (4 Stück) | ✅ | | |
| Badges (erweitert) | | ✅ | |
| Anzeigename ändern | | ✅ | |
| Username ändern | | ✅ | |
| Account löschen (in-App) | | ⚖️ | |
| Datenexport (DSGVO) | | ⚖️ | |
| Foto-Avatare | | | ✅ |

## Check-in

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Bier suchen / neu anlegen | ✅ | | |
| Ort aus Umkreis wählen / neu anlegen | ✅ | | |
| Stadt + Land automatisch aus dem Ort | ✅ | | |
| Datum (Default heute) | ✅ | | |
| Speichern in einem Server-Call | ✅ | | |
| Reward-Screen | ✅ | | |
| Check-in löschen (< 24 h) | ✅ | | |
| Wiederholungs-Queue bei Fehlschlag | ✅ | | |
| Vollständige Offline-Synchronisation | | ✅ | |
| Notizfeld | | ✅ | |
| ~~POI-Vorschläge über `MKLocalSearch`~~ | ❌ gestrichen (Apple Maps ToS §1.3 vi) | | |
| Bewertung / Sterne | | | ❌ nie |
| Foto zum Check-in | | | ✅ |
| KI-Biererkennung | | | ✅ |

## Passport & Karte

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Weltkarte mit eigenen Orten | ✅ | | |
| Zähler: Länder / Städte / Orte / Biere | ✅ | | |
| Vier Sammel-Listen | ✅ | | |
| Marker-Clustering | ✅ | | |
| Ort-Detail (eigene Besuche) | ✅ | | |
| City-Detail mit City-Level | | ✅ | |
| Country-Detail | | ✅ | |
| Bier-Detail | | ✅ | |
| „Fog of War"-Aufdeckung | | | ✅ |
| Prozent-Fortschritt je Stadt | | | ❌ gestrichen (nicht berechenbar) |

## XP, Level, Rewards

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| XP-Ledger, serverseitig | ✅ | | |
| Level + Fortschrittsbalken | ✅ | | |
| XP für Bier / Ort / Stadt / Land | ✅ | | |
| Tages-XP-Cap | ✅ | | |
| Level-Up-Anzeige | ✅ | | |
| „Nächstes Ziel"-Anzeige auf Home | ✅ | | |
| Clan-XP (60 % der Personal-XP) | ✅ | | |
| Anti-Cheat: Positionsabgleich, Flagging | | ✅ | |
| Seasons | | | ✅ |

## Quests

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Solo-Quests aus Katalog | ✅ | | |
| **Daily Quest** (wechselt täglich) | ✅ | | |
| Quest annehmen / aufgeben | ✅ | | |
| Fortschritt aus Check-ins | ✅ | | |
| Quest-Belohnung im Reward-Screen | ✅ | | |
| Ablauf per Zeitstempel (kein Scheduler) | ✅ | | |
| City Quests | | ✅ | |
| Social Quests (gemeinsame Quests) | | ✅ | |
| Quest-Einladung per Link | | ✅ | |
| Hidden Quests (standortbasiert) | | | ✅ |
| Custom Quests (Premium) | | | ✅ |
| Sponsored Quests (B2B) | | | ✅ |

## Freunde

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Freund per **Invite-Code** einladen | ✅ | | |
| Code per Share Sheet teilen | ✅ | | |
| Code einlösen (auch im Onboarding) | ✅ | | |
| Freundesliste | ✅ | | |
| Freund per Username suchen + anfragen | ✅ | | |
| Anfragen annehmen / ablehnen | ✅ | | |
| Freund entfernen | ✅ | | |
| Fremdes Profil ansehen | ✅ | | |
| Universal Links / Landing-Page | | ✅ | |
| Blockieren | | ⚖️ | |
| Melden (Nutzer, Clan, Ort) | | ⚖️ | |
| Wortfilter (Username, Clan-Name) | ✅ (Basis-Blocklist) | ⚖️ (vollständig) | |
| Chat | | | ❌ nie im aktuellen Konzept |
| Öffentlicher Social Feed | | | ✅ |

## Clan

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Clan erstellen (Name, Avatar) | ✅ | | |
| Clan per Code beitreten | ✅ | | |
| Clan verlassen | ✅ | | |
| Mitgliederliste | ✅ | | |
| Persönlicher Beitrag (XP) | ✅ | | |
| Clan-XP + Clan-Level | ✅ | | |
| Ranking innerhalb des Clans | ✅ | | |
| Clan-Aktivität (letzte 10 Ereignisse) | ✅ | | |
| Offene Clans durchsuchen | | ✅ | |
| Clan-Beschreibung, Sichtbarkeit | | ✅ | |
| Rollen / Rechte / Moderation | | | ✅ |
| Clan Wars | | | ✅ |
| Clan-Chat | | | ❌ |

## Leaderboards

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Friends-Leaderboard (Woche) | ✅ | | |
| Friends-Leaderboard (Gesamt) | ✅ | | |
| Eigene Position immer sichtbar | ✅ | | |
| Ranking innerhalb des Clans | ✅ | | |
| Clan-vs-Clan-Leaderboard | | ✅ | |
| City-Leaderboard | | ✅ | |
| Country- / Global-Leaderboard | | | ✅ |
| Seasonal Leaderboards | | | ✅ |

## Plattform & Betrieb

| Feature | P0 | P1 | P2 |
|---|:--:|:--:|:--:|
| Ereignis-Logging in eigener Tabelle | ✅ | | |
| Crash-Reports über Xcode/App Store Connect | ✅ | | |
| Keep-alive gegen Projekt-Pausierung | ✅ | | |
| Push-Benachrichtigungen | | ✅ | |
| Universal Links + Web-Hosting | | ✅ | |
| Terms / Privacy Policy (Web) | | ⚖️ | |
| Privacy Manifest, App-Privacy-Labels | | ⚖️ | |
| Lokalisierung über Englisch hinaus | | | ✅ |
| iPad-Layout, Widgets, Watch | | | ✅ |
| Android | | | ✅ |

---

## Die Streichungen gegenüber v0.1 im Überblick

| Feature | v0.1 | jetzt | Ersparnis |
|---|---|---|---|
| Social Quests | MVP | P1 | ~3 Tage + 3 Screens |
| City Quests | MVP | P1 | ~1,5 Tage |
| Clan- und City-Leaderboard | MVP | P1 | ~2 Tage + 2 Screens |
| City-/Country-/Bier-Detail | MVP | P1 | ~2,5 Tage + 3 Screens |
| Universal Links + Web-Hosting | MVP | P1 | ~3 Tage |
| Moderation (Melden/Blockieren) | MVP | P1 ⚖️ | ~2 Tage + 2 Screens |
| Account-Löschung, Datenexport | MVP | P1 ⚖️ | ~1,5 Tage + 1 Screen |
| Vollständiger Offline-Sync | MVP | P1 | ~2 Tage |
| Bier-Seed 300–500 Einträge | MVP | 60 in P0 | ~1,5 Tage |
| **Summe** | | | **~19 Tage, 11 Screens** |

## Die Ergänzungen gegenüber v0.1

| Feature | Warum | Aufwand |
|---|---|---|
| Daily Quest | Grund, morgen wiederzukommen (Gate E2) | ~0,5 Tage |
| „Nächstes Ziel" auf Home | Sichtbares Ziel jenseits von XP (Gate E1) | ~0,5 Tage |
| Wöchentliches Friends-Leaderboard | Wiederkehrender Wettbewerb ohne Season-Infrastruktur | ~0,5 Tage |
| Clan-Aktivität (10 Zeilen) | Macht den Clan lebendig statt statisch (Gate F) | ~0,5 Tage |
| Keep-alive-Workflow | Verhindert Ausfall durch Projekt-Pausierung | ~0,2 Tage |
| Ereignis-Logging | Balancing braucht Daten; ersetzt Analytics-SDK | ~0,3 Tage |
| **Summe** | | **~2,5 Tage** |

**Netto: ~16,5 Tage weniger, bei einem spielerisch dichteren Ergebnis.**
