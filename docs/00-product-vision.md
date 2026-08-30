# 🍺 BEER QUEST — Product Vision & MVP Specification

Version 0.1 — Product Discovery

> Quelldokument des Product Owners. Wird hier unverändert im Inhalt abgelegt,
> damit die Paragraphen-Verweise (§1–§36) in den Spezifikationsdokumenten
> auflösbar sind. Analyse und Ableitungen stehen in `01-analysis.md` ff.

---

## 1. Product Vision

Beer Quest ist eine gamifizierte Social-App für Bierliebhaber. Die App verbindet drei Dinge: 🌍 die Welt entdecken, 🍺 Bier und Orte sammeln, ⚔️ mit Freunden und Teams konkurrieren.

Beer Quest soll sich nicht wie eine Bier-Tracking-App anfühlen. Der Nutzer soll das Gefühl haben: „Die Welt ist mein Beer Quest."

Biere, Städte, Länder, Locations, Quests und gemeinsame Erlebnisse werden gesammelt und in einem spielerischen Fortschrittssystem miteinander verbunden. Die App soll langfristig international skalierbar sein und zunächst als kleines iOS-Nebenprojekt mit einem klar abgegrenzten MVP starten.

## 2. Product Philosophy

Die App soll: einfach zu verstehen sein · schnell Spaß machen · soziale Interaktion fördern · Sammeln und Entdecken belohnen · Wettbewerb ermöglichen · langfristig motivieren · international funktionieren · technisch zunächst bewusst einfach bleiben.

Wichtig: Die App soll **nicht** möglichst hohen Alkoholkonsum belohnen. XP und Fortschritt sollen primär für neue Orte, neue Städte, neue Länder, neue Biere, Quests, soziale Aktivitäten und Team-/Clan-Aktivitäten vergeben werden.

Es soll niemals ein simples System geben wie: „Je mehr Bier du trinkst, desto höher dein Score." Beer Quest dokumentiert und gamifiziert Erlebnisse rund ums Bier.

## 3. Zielgruppe

Junge Erwachsene · Bierliebhaber · Freunde, die gemeinsam unterwegs sind · Reisende · Craft-Beer-Interessierte · Menschen, die Gamification mögen · Nutzer, die gerne sammeln · Nutzer, die sich gerne mit Freunden messen.

Die App soll international funktionieren (🇩🇪 🇮🇹 🇦🇹 🇨🇿 🇺🇸 🇬🇧). Die Architektur darf deshalb nicht auf Deutschland beschränkt sein.

## 4. Core User Fantasy

„Ich sammle meine Bier-Reise durch die Welt." und gleichzeitig „Mein Team will gewinnen."

Das Produkt kombiniert: **EXPLORE** (Orte, Städte und Länder entdecken) · **COLLECT** (Biere, Locations, Städte und Länder sammeln) · **QUEST** (Challenges absolvieren) · **COMPETE** (gegen Freunde und andere Teams antreten) · **BELONG** (Teil eines Clans/Teams sein).

## 5. Core Game Loop

```
EXPLORE → DISCOVER → CHECK-IN → COLLECT → EARN XP → COMPLETE QUEST
       → COMPETE → HELP YOUR CLAN → LEVEL UP → EXPLORE AGAIN
```

Dieser Loop ist wichtiger als einzelne Features. Jede Funktion des MVP sollte diesen Loop unterstützen.

## 6. Beer Passport

Der Beer Passport ist eines der wichtigsten langfristigen Features. Der Nutzer baut eine persönliche Sammlung auf: 🌍 Länder (z. B. 🇩🇪 Germany ✓, 🇮🇹 Italy ✓, 🇨🇿 Czechia 🔒) · 🏙️ Städte (Berlin ✓, Munich ✓, Rome ✓, Prague ✓, Florence 🔒) · 📍 Locations (Bars, Biergärten, Brauereien oder andere relevante Orte) · 🍺 Biere.

## 7. Map

Die App besitzt eine persönliche Weltkarte. Auf der Karte werden besuchte bzw. gesammelte Orte sichtbar (🌍 3 Countries · 🏙️ 8 Cities · 📍 17 Locations · 🍺 21 Beers). Beim Hineinzoomen werden Städte und Locations sichtbar. Eine Stadt kann einen eigenen Fortschritt besitzen (🇮🇹 ROME — 42% explored, 🍺 8 Beers, 📍 6 Locations, 🏆 3 Quests). Das langfristige Ziel ist eine Karte, die sich wie ein persönliches Spielfeld anfühlt.

## 8. Beer Check-In

Das Eintragen eines Bieres muss extrem schnell und unkompliziert sein.

```
ADD BEER → Bier auswählen/eingeben → Location auswählen bzw. aktuelle Location
         → Stadt → Land → SAVE
```

Danach: Bier, Location, Stadt und Land werden gespeichert, die Collection wird aktualisiert und relevante XP werden vergeben.

## 9. Wiederholte Biere

Das Datenmodell muss zwischen einem **Bier** (Peroni Nastro Azzurro) und einem einzelnen **Erlebnis** (Peroni Nastro Azzurro · 📍 Cecina · 🇮🇹 Italy · 📅 Datum) unterscheiden. Das gleiche Bier kann an mehreren Orten bzw. zu mehreren Zeitpunkten eingetragen werden. Das erste Entdecken eines Bieres kann einen größeren Collection-Bonus geben.

## 10. XP-System

XP sollen nicht primär den Alkoholkonsum messen. Beispielwerte für das MVP:

| Aktion | XP |
|---|---|
| Neue Location entdecken | +50 |
| Neues Bier entdecken | +50 |
| Neue Stadt entdecken | +150 |
| Neues Land entdecken | +300 |
| Quest abschließen | +100–1.000 |
| Freund zu Quest einladen | +25 |
| Gemeinsame Quest | Bonus |

Diese Werte sind vorläufig und sollen während des Tests angepasst werden.

## 11. Level-System

Jeder Nutzer besitzt ein Level. Auf dem Profil wird ein Fortschrittsbalken angezeigt (z. B. `LEVEL 7 — 2,840 / 3,500 XP`). Das Level soll langfristig kosmetische oder spielerische Vorteile freischalten können. Im MVP reicht ein einfaches XP-/Level-System.

## 12. Quests

Quests sind der zentrale spielerische Mechanismus. Im MVP zunächst nur wenige Questtypen: **Solo Quest** (🍺 Discover 2 new beers → +200 XP) · **City Quest** (🏙️ Discover 2 beer locations in this city → +300 XP) · **Social Quest** (👥 Complete a quest with a friend → +500 XP). Quest-Inhalte sollen später stark erweitert werden.

## 13. Hidden Quests

Nicht Teil des MVP, aber Teil der Produktvision. Später können standortabhängige Hidden Quests erscheinen („🔓 SECRET QUEST DISCOVERED — You are near a hidden beer challenge."). Hidden Quests sollen Exploration und Überraschung fördern.

## 14. Friends

MVP: Freund hinzufügen · Freundesanfrage · Freund akzeptieren · Freundesliste · gemeinsame Quests.

Besonders wichtig ist ein einfacher Invite-/Deep-Link-Mechanismus („🍺 Join my Beer Quest"). Der Empfänger soll möglichst reibungslos zum Hinzufügen als Freund bzw. zur entsprechenden Quest gelangen. Dieser Mechanismus ist ein wichtiger Bestandteil der organischen Viralität.

## 15. Social Quest

Ein Nutzer kann eine Quest starten und Freunde einladen (🍺 FRIDAY BEER QUEST — Discover 2 new locations, 👥 3 friends invited, JOIN QUEST). Alle Teilnehmer können zum gemeinsamen Fortschritt beitragen.

## 16. Clans / Teams

Clans sind ein wichtiger Bestandteil der langfristigen Produktvision. Ein Nutzer kann einen Clan erstellen oder beitreten (🍺 HOP HEADS — 18 Members, Clan Level 14, 128.420 Clan XP).

## 17. Clan MVP

Im MVP zunächst nur: Clan erstellen · Clan beitreten · Clan verlassen · Mitglieder anzeigen · Clan Name · Clan Avatar · Clan XP · Clan Leaderboard · eigener Beitrag zum Clan-Fortschritt.

Persönliche XP und Clan XP müssen getrennt gespeichert werden (Quest completed → +500 Personal XP, +300 Clan XP).

## 18. Clan Competition

Clan Wars sind langfristig vorgesehen, aber nicht zwingend Bestandteil der allerersten MVP-Version. Langfristige Vision: WEEKLY CLAN WAR — HOP HEADS VS BEER BANDITS, 7 DAYS. Mögliche Kategorien: neue Städte, neue Locations, neue Biere, abgeschlossene Quests, gemeinsame Aktivitäten. Der Wettbewerb soll Teamplay fördern und nicht einfach nur die Anzahl konsumierter Biere zählen.

## 19. Leaderboards

MVP: **Friends Leaderboard** (wer hat die meisten relevanten XP?) · **Clan Leaderboard** (welche Clans sind vorne?) · **City Leaderboard** (welche Nutzer/Clans sind in einer Stadt besonders aktiv?).

Langfristig: Country Leaderboards · Global Leaderboard · Seasonal Leaderboards · Clan Wars · City Battles.

## 20. City Progress

Städte sollen eine eigene Identität bekommen (🏙️ BERLIN — Beer Quest Level 7, 14 Beers discovered, 9 Locations, 4 Quests completed, 24% explored). Langfristig soll eine Stadt ein eigenes Spielfeld darstellen.

## 21. Country Progress

Auch Länder bekommen Fortschritt (🇮🇹 ITALY — 7 Cities, 18 Locations, 24 Beers, 18% explored). Langfristig können Länder miteinander konkurrieren (🇩🇪 GERMANY VS 🇮🇹 ITALY).

## 22. Badges

Badges motivieren zum Sammeln. MVP zunächst wenige.

- **EASY:** 🍺 First Beer · 👥 First Quest · 🌍 First Country
- **MEDIUM:** 🌍 5 Countries · 🏙️ 25 Cities · 🍺 50 Beer Discoveries
- **HARD:** 🌍 20 Countries · 🏙️ 100 Cities · ⚔️ Win 10 Clan Challenges

## 23. Verification / Proof

Normale Beer Check-ins benötigen zunächst keinen Beweis — der Check-in muss schnell und frictionless bleiben. Langfristig können verschiedene Vertrauensstufen entstehen: **NORMAL** (einfacher Check-in) · **VERIFIED** (optionaler Nachweis: Foto, Location, quest-spezifischer Nachweis) · **COMPETITIVE** (strengere Regeln für wichtige Wettbewerbe). Das Verification-System soll erst implementiert werden, wenn der grundlegende Game Loop funktioniert.

## 24. Monetization

**FREE:** Profil · Beer Passport · Map · Freunde · normale Quests · Clan · grundlegende Leaderboards.

**PREMIUM** (Arbeitstitel *Beer Quest+*): erweiterte Statistiken · zusätzliche Questtypen · Custom Quests · erweiterte Clan-Funktionen · zusätzliche Profiloptionen · spezielle kosmetische Inhalte · historische Auswertungen.

Die soziale Kernfunktion soll nicht hinter einer Paywall verschwinden.

## 25. Future B2B Opportunities

Bars (eigene Quests) · Breweries (Challenges/Event-Inhalte) · Festivals (Beer Quest Challenges bei Events) · Sponsored Quests. Diese Funktionen gehören nicht ins MVP.

## 26. MVP — DEFINITIVE SCOPE

🟢 **MUST HAVE**

- **Account/Profile:** Username · Avatar · XP · Level · Badges · Stats
- **Beer Check-In:** Bier · Location · Stadt · Land · Datum · speichern
- **Beer Passport:** Weltkarte · Länder · Städte · Locations · Biere
- **Friends:** hinzufügen · Anfragen · anzeigen · Invite Link
- **Quests:** Solo Quest · City Quest · Social Quest · XP Rewards
- **Clan:** erstellen · beitreten · Mitglieder · Clan XP · Clan Leaderboard
- **Leaderboards:** Friends · Clan · City
- **Navigation:** Home · Map · Quests · Clan · Profile

## 27. NICHT im MVP

Clan Wars · City Control · Country Battles · Seasons · Hidden Quests · komplexes Verification-System · Bar Accounts · Brewery Accounts · AI Beer Recognition · komplexe Bierdatenbank · Chat · öffentlicher Social Feed · komplizierte Notifications · umfangreiche Premium-Funktionen. Diese Funktionen bleiben auf der Roadmap.

## 28. Core Screens

**HOME** (aktuelles Level, XP, nächste Quest, Passport-Fortschritt, Clan-Status, relevante Challenges) · **MAP** (persönliche Beer World) · **QUESTS** (aktive und verfügbare Quests) · **CLAN** (Clan, Mitglieder, XP und Ranking) · **PROFILE** (persönliche Sammlung, Statistiken und Badges). Zusätzlich **ADD BEER** als prominente zentrale Aktion.

## 29. First-Time User Experience

Der Nutzer soll innerhalb weniger Sekunden verstehen, was Beer Quest ist.

```
🍺 BEER QUEST — Explore the world. Collect the beers. Play with your crew.
→ Name / Username → Optional Avatar → Home
→ Erste einfache Quest: 🎯 Your First Quest — Discover your first beer. +100 XP
```

Der Nutzer soll möglichst schnell seinen ersten Erfolg erleben.

## 30. Design Direction

Die App soll sich nicht wie eine nüchterne Datenbank-App anfühlen. Gewünschtes Gefühl: modern · hochwertig · spielerisch · social · leicht · etwas frech · aber nicht kindisch.

Keine überladene UI. Keine unnötigen Animationen. Der Nutzer muss jederzeit verstehen: *Was kann ich jetzt machen?* Gamification soll sichtbar sein, aber nicht die Benutzerfreundlichkeit zerstören.

## 31. Viral Growth Loop

```
User startet Quest → lädt Freunde ein → Freund erhält Invite Link → Freund tritt bei
→ Freund wird User → Freund tritt ggf. einem Clan bei → Freund startet eigene Quest
→ neue Freunde werden eingeladen → Loop wiederholt sich
```

Der Invite-Prozess muss deshalb extrem einfach sein.

## 32. Long-Term Product Vision

- **V1** Personal collection + Friends + Quests + Clans
- **V1.1** Clan Wars + Hidden Quests + Verification
- **V2** Seasons + City Battles + Country Battles
- **V3** Bars + Breweries + Events
- **V4** Globale Beer Quest Community

Die Weltkarte wird langfristig zum globalen Spielfeld.

## 33. Product North Star

Die zentrale Frage bei jeder zukünftigen Funktion lautet: *Macht dieses Feature die Beer-Quest-Erfahrung besser?* Wenn nein: nicht bauen. Wenn ja: prüfen, ob es wirklich notwendig ist.

## 34. Wichtig für die technische Umsetzung

Nicht sofort die gesamte App implementieren. Zuerst: 1. Architektur planen · 2. Datenmodell definieren · 3. User Flows definieren · 4. Screens spezifizieren · 5. Navigation festlegen · 6. MVP abgrenzen · 7. erst danach implementieren.

Die Implementierung soll modular erfolgen. Keine unnötige technische Komplexität. Keine Architektur, die für ein MVP bereits auf Millionen Nutzer optimiert werden muss. Aber: Das Datenmodell und die grundlegende Architektur müssen so gestaltet werden, dass spätere Erweiterungen (Clans, Seasons, Leaderboards, Locations, Quests, Verification, Premium, B2B) möglich sind, ohne die komplette App neu schreiben zu müssen.

## 35. Arbeitsauftrag

- **STEP 1** Konzept kritisch analysieren: Widersprüche, fehlende Anforderungen, technische Risiken, UX-Probleme, Skalierungsprobleme, App-Store-Probleme, sinnvolle Vereinfachungen.
- **STEP 2** Technische MVP-Spezifikation: Architektur, Datenmodell, Entities, Beziehungen, Authentication, Backend-Anforderungen, Location/Maps, Deep Links, State Management, Navigation, benötigte APIs, Security, Datenschutz.
- **STEP 3** Alle MVP User Flows definieren.
- **STEP 4** Jeden MVP Screen definieren: UI-Elemente, Buttons, States, Loading States, Empty States, Error States, Navigation.
- **STEP 5** Realistischer Implementierungsplan in kleinen Phasen.
- **STEP 6** Erst danach mit der eigentlichen Implementierung beginnen.

Wichtig: Keine Features aus der V1.1/V2-Roadmap ungefragt in das MVP ziehen. Das MVP soll klein, stabil und tatsächlich über TestFlight testbar sein.

## 36. Erfolgskriterium des MVP

Das MVP ist erfolgreich, wenn ein neuer Nutzer: 1. die App versteht · 2. sein erstes Bier einträgt · 3. seinen ersten Ort sammelt · 4. XP erhält · 5. eine Quest versteht · 6. eine Quest abschließt · 7. einen Freund einladen kann · 8. einem Clan beitreten kann · 9. seinen persönlichen Fortschritt sieht · 10. einen Grund hat, die App erneut zu öffnen.

Der wichtigste Test ist nicht „Wie viele Features haben wir?", sondern **„Macht der Core Loop Spaß?"**
