# STEP 1 — Kritische Analyse des Konzepts

Status: Product Discovery · Bezug: Product Vision & MVP Specification v0.1

> **Hinweis (v0.2):** Dieses Dokument ist die Analyse der ersten Session und
> bleibt inhaltlich gültig — die Befunde (fehlendes Age Gate, nicht berechenbarer
> Prozent-Fortschritt, Widerspruch um die Bierdatenbank, undefinierte Clan-XP)
> sind unverändert richtig. **Die Scope- und Kostenentscheidungen darin sind
> jedoch überholt.** Maßgeblich sind `02-product-gate.md` (Neuschnitt auf einen
> Vertical Slice), `03-feature-matrix.md` (P0/P1/P2) und `04-cost-analysis.md`
> (0-€-Anforderung). Wo dieses Dokument „MVP" sagt, ist heute meist **P0 + P1**
> gemeint. Die offenen Entscheidungen D1–D10 am Ende sind in
> `HANDOFF.md` fortgeschrieben.

Die Analyse ist bewusst hart. Das Konzept ist stark — der Core Loop trägt, die
Abgrenzung gegen "mehr trinken = mehr Punkte" ist richtig und verkaufbar. Die
Probleme liegen fast alle in drei Bereichen: **fehlende Referenzdaten**,
**undefinierte Fortschritts-Nenner** und **Compliance-Themen, die kein
Nice-to-have sind, sondern App-Store-Blocker**.

Legende der Schweregrade:
- 🔴 **Blocker** — muss vor Implementierungsbeginn entschieden sein
- 🟠 **Wichtig** — muss im MVP gelöst sein, Lösung ist aber offensichtlich
- 🟡 **Beobachten** — kann nach dem ersten TestFlight-Feedback entschieden werden

---

## 1. Widersprüche im Dokument

### 1.1 🔴 "Keine komplexe Bierdatenbank" vs. Beer Passport & Bier-Discovery

§27 schließt eine Bierdatenbank explizit aus. §6, §9 und §10 setzen aber
voraus, dass die App weiß, ob ein Bier **neu** ist ("Neues Bier entdecken +50",
"Erstes Entdecken gibt Collection-Bonus"). Ohne kanonische Bier-Entität gibt es
kein "neu": `Peroni`, `peroni`, `Peroni Nastro Azzuro` (Tippfehler) und
`Nastro Azzurro` wären vier verschiedene Biere — und damit 200 XP statt 50.

**Auflösung:** Es braucht eine *einfache* Bier-Entität (Name + Brauerei +
Normalisierung), keine kuratierte Weltdatenbank. Vorschlag in STEP 2:
Seed-Katalog (~300–500 der häufigsten Biere der Zielmärkte) + Free-Text-Anlage
durch Nutzer mit Fuzzy-Matching und serverseitiger Merge-Möglichkeit.
"Keine komplexe Bierdatenbank" wird umgedeutet zu: *keine Integration einer
externen Bierdatenbank, keine Styles/ABV/Ratings-Pflege im MVP.*

### 1.2 🔴 "% explored" hat keinen Nenner

§7 (`42% explored`), §20 (`24% explored`) und §21 (`18% explored`) setzen
voraus, dass die App weiß, wie viele Locations/Biere es in Rom *insgesamt*
gibt. Diese Zahl existiert nicht und wird auch nie stabil existieren — sie
würde bei jedem neuen User-generierten Ort sinken. Ein Fortschrittsbalken, der
rückwärts läuft, wenn man etwas entdeckt, ist ein UX-Desaster.

**Auflösung:** Prozentanzeige im MVP streichen. Ersatz: **City Level** aus den
eigenen XP in dieser Stadt (gleiche Kurve wie User-Level) plus absolute
Zähler. Das ist ehrlich, monoton steigend und liefert dasselbe Gefühl.
§20 nennt bereits "Beer Quest Level 7" für Berlin — das ist der bessere
Mechanismus, die Prozentzahl daneben ist redundant.

### 1.3 🟠 XP-Werte widersprechen sich

- §10: "Neues Bier entdecken +50"
- §12: "Solo Quest: Discover 2 new beers → +200 XP"
- §29: "Your First Quest: Discover your first beer → +100 XP"

Der Nutzer bekommt für zwei neue Biere also 100 (Discovery) + 200 (Quest) =
300 XP, für das erste Bier aber 50 + 100 = 150 XP. Quests zahlen 2–4× mehr als
die Aktion selbst. Das ist grundsätzlich in Ordnung (Quests sollen der
Haupt-XP-Kanal sein), muss aber **eine bewusste Entscheidung mit einer Regel**
sein, sonst ist die Kurve nach dem ersten Balancing-Durchlauf Chaos.

**Auflösung:** Eine Ökonomie-Regel in STEP 2, alle Werte zentral serverseitig
konfiguriert (nicht im Client hartcodiert), damit Balancing ohne App-Update
möglich ist.

### 1.4 🔴 Personal XP vs. Clan XP ist nicht definiert

§17 fordert getrennte Speicherung und zeigt `+500 Personal / +300 Clan`. Es
fehlt die Regel, *wie* Clan-XP entstehen: Nur aus Quests? Aus jeder Aktion?
Anteilig? Ohne Regel ist das Clan-Leaderboard nicht implementierbar.

**Auflösung:** Eine einzige, tunbare Konstante: Clan-XP = `CLAN_XP_RATIO ×
Personal XP` bei jeder XP-Vergabe, solange der User Clan-Mitglied ist.
Vorschlag `0.6`. Das Beispiel aus §17 (500/300) entspricht exakt 0.6 — die
Vision meint offenbar genau das.

### 1.5 🟠 "Wer hat die meisten *relevanten* XP?" (§19)

"Relevant" ist undefiniert. Wenn das Friends-Leaderboard All-Time-XP zeigt,
ist es für neue Nutzer tot: Der Freund, der drei Monate früher angefangen hat,
ist uneinholbar. Genau die Nutzer, die das Leaderboard motivieren soll, werden
demotiviert.

**Auflösung:** Friends-Leaderboard mit Standard-Tab **"Diese Woche"**
(rollierend, Montag 00:00 lokal) und optionalem Tab "Gesamt". Das erfordert
ein XP-Ledger statt eines Zählers — siehe Datenmodell.

### 1.6 🟡 Clan-Leaderboard ist strukturell unfair

Clan-XP absolut zu ranken bedeutet: Der größte Clan gewinnt immer. Ein
5-Personen-Clan hat keine Chance und keinen Grund zu spielen.

**Auflösung MVP:** Zwei Tabs — "Gesamt-XP" und "XP pro Mitglied". Billig zu
bauen, rettet die Motivation kleiner Clans. Clan-Größenklassen erst mit Clan
Wars (V1.1).

### 1.7 🟡 §27 schließt "komplizierte Notifications" aus, §14/§15 brauchen sie

Freundschaftsanfrage, Quest-Einladung und Clan-Beitritt sind asynchrone
Ereignisse. Ohne *irgendeine* Benachrichtigung bemerkt sie niemand, und der
virale Loop aus §31 bricht an der Stelle "Freund tritt bei".

**Auflösung:** Keine Push-Infrastruktur im MVP, aber **In-App-Badges** auf Tab
und Zeilen (roter Punkt auf Profil/Clan) plus ein "Aktivität"-Bereich auf Home.
Push erst nach TestFlight-Feedback, dann genau drei Typen.

---

## 2. Fehlende Anforderungen

### 2.1 🔴 Age Gate

Eine Alkohol-App ohne Altersabfrage bekommt kein App-Store-Review. Fehlt im
Dokument vollständig. Muss in den Onboarding-Flow (§29), was dessen "innerhalb
weniger Sekunden" leicht verlängert.

### 2.2 🔴 Account-Löschung in der App

App Store Guideline 5.1.1(v): Wer einen Account anlegen kann, muss ihn in der
App löschen können. Kein "Mail an Support". Fehlt vollständig, betrifft
Datenmodell (Soft-Delete, Anonymisierung, was passiert mit Clan-XP eines
gelöschten Mitglieds?).

### 2.3 🔴 Moderation: Melden & Blockieren

Usernames, Avatare, Clan-Namen und Clan-Beschreibungen sind User Generated
Content. Guideline 1.2 verlangt dafür zwingend: Filter, Melde-Funktion,
Blockieren, Reaktion innerhalb 24h, veröffentlichte EULA. Fehlt vollständig
und ist der wahrscheinlichste Ablehnungsgrund beim ersten Review.

### 2.4 🟠 Rechtliches & Datenschutz

Privacy Policy, Terms/EULA, Impressum, Privacy Manifest, App-Privacy-Labels,
DSGVO-Auskunft/Export. Standortdaten sind personenbezogene Daten.

### 2.5 🟠 Sprache & Lokalisierung

Das Produkt ist international gedacht, die Vision-Screens sind englisch, das
Dokument deutsch. Eine Entscheidung fehlt.
**Empfehlung MVP:** UI komplett **Englisch**, aber von Tag 1 durch
`String Catalog` (.xcstrings) geführt, damit Deutsch später ein reiner
Übersetzungsvorgang ist. Kein deutsch/englisch-Mischmasch.

### 2.6 🟠 Offline & Netzfehler

Check-in passiert in Kneipen und Kellern. Kein Netz ist der Normalfall, nicht
der Sonderfall. Ohne Offline-Queue verliert der Nutzer genau in dem Moment
Daten, in dem die App ihren Wert beweisen müsste.

### 2.7 🟠 Zeitzonen & "Datum" eines Check-ins

§8 speichert ein Datum. Bei Reisenden (Kernzielgruppe!) ist unklar, welcher
Tag gemeint ist. Braucht `timestamptz` + separat gespeichertes lokales Datum,
sonst springen Tages-Caps, Streaks und Wochen-Leaderboards.

### 2.8 🟠 Duplikate von Locations

Zwei Nutzer legen im selben Biergarten "Augustiner Keller" und "Augustiner-Keller
München" an. Ohne Dedupe zerfällt die Karte in Karteileichen und beide
bekommen +50 XP für "dieselbe" Entdeckung.

### 2.9 🟡 Cheating

Ohne jede Verifikation (§23, bewusst) kann man 20 Länder in fünf Minuten
eintippen. Für ein Freundes-MVP egal, für ein Leaderboard nicht.
**Minimalmaßnahmen im MVP** (billig, keine echte Verification): XP nur
serverseitig, Tages-Caps, Plausibilitätsprüfung Geräteposition ↔ gewählte
Location (nur flaggen, nicht blocken), Rate-Limits.

### 2.10 🟡 Was fehlt sonst
Analytics/Crash-Reporting (ohne Daten kein Balancing), Empty States als
Erstkontakt, Onboarding-Wiederholung, Zurücksetzen/Löschen eines Check-ins
(Vertippen ist häufig!), Username-Änderung, Clan-Auflösung wenn der Owner geht.

---

## 3. Technische Risiken

| # | Risiko | Schwere | Gegenmaßnahme |
|---|---|---|---|
| R1 | **Kanonische Städte/Länder.** Der gesamte Sammelmechanismus hängt daran, dass "Rom" für alle Nutzer dieselbe Entität ist. Reverse-Geocoding-Ergebnisse sind uneinheitlich (Ortsteile, Sprachen, Stadtgrenzen). | 🔴 | Eigenes, serverseitiges Städte-Gazetteer (GeoNames-Auszug, Städte > 5.000 Einwohner, ~130k Zeilen) + Nearest-City-Zuordnung per Koordinate. Client geocodiert nie selbst. |
| R2 | **Apple-MapKit-Nutzungsbedingungen.** POI-Ergebnisse aus `MKLocalSearch` dürfen nicht dauerhaft in einer eigenen Datenbank gespeichert und außerhalb einer Apple-Karte weiterverwendet werden. Genau das täte ein Venue-Katalog. | 🔴 | POI-Suche nur als **Eingabehilfe** (Name/Koordinate werden vom Nutzer bestätigt und als *eigene* Venue-Entität mit eigener ID angelegt), keine Bulk-Importe, keine Apple-IDs speichern. Rechtlich vor Launch prüfen lassen. |
| R3 | **Deferred Deep Links.** §14/§31 hängen daran, dass der Invite-Link nach *Neuinstallation* noch wirkt. Universal Links überleben den App-Store-Umweg nicht. | 🟠 | Landing-Page zeigt den Invite-Code sichtbar an; Onboarding hat ein "Invite-Code eingeben"-Feld. Kein Drittanbieter-SDK (Branch etc.) im MVP. |
| R4 | **XP-Konsistenz.** Discovery, XP, Quest-Fortschritt, Clan-XP, City-Stats und Badges müssen bei *einem* Check-in atomar aktualisiert werden. Client-seitig verteilt = garantierte Inkonsistenz. | 🟠 | Ein einziger transaktionaler Server-Call (`create_check_in`), der das Reward-Paket zurückgibt. Client rechnet nie XP. |
| R5 | **Doppelte Check-ins** durch Retry/Offline-Queue. | 🟠 | Client-generierte UUID als Idempotenzschlüssel, unique je User. |
| R6 | Backend-Skalierung Leaderboards | 🟡 | Inkrementell gepflegte `user_city_stats`, Indizes; Materialized Views erst ab echtem Traffic. |
| R7 | Solo-Entwickler, iOS + Backend + Content | 🟠 | BaaS statt Eigenbau-Backend, striktes Phasenmodell, kein Feature aus V1.1. |

---

## 4. UX-Probleme

1. 🟠 **Der Check-in-Flow aus §8 ist zu lang.** Bier → Location → Stadt → Land →
   Speichern sind vier Entscheidungen. Stadt und Land sind aber **immer**
   ableitbar aus der Location. Sie dürfen nie separat abgefragt werden, nur
   angezeigt und in Ausnahmefällen korrigierbar sein. Ziel: **zwei Taps + ein
   Feld**, unter 15 Sekunden, in einer lauten Bar mit einer Hand.
2. 🟠 **Fünf Tabs + prominenter Add-Button** ist auf iPhone-Breite eng. Der
   Add-Beer-Button gehört nicht in die Tab-Leiste als sechster Punkt, sondern
   als hervorgehobenes Element in der Mitte, das ein Sheet öffnet.
3. 🟠 **Der erste Start ist leer.** Karte leer, Passport leer, Clan leer,
   Leaderboard leer. Empty States sind hier keine Randnotiz, sondern der
   eigentliche Onboarding-Content — jeder muss genau eine Handlungsaufforderung
   haben.
4. 🟡 **Reward-Feedback fehlt in der Spec.** Der Moment "+50 XP, neue Stadt
   entdeckt, Quest 1/2" ist der emotionale Kern des Loops. Braucht einen
   eigenen Screen/Overlay, sonst fühlt sich der Check-in wie ein Formular an.
5. 🟡 **Clan im MVP ohne Chat** ist ein Leaderboard mit Namen. Erwartungs-
   management: Clan-Aktivitätsfeed (wer hat was entdeckt) ist billig und macht
   den Clan lebendig — empfohlen als kleiner Zusatz statt Chat.
6. 🟡 **Social Quest mit 0 Freunden** (Tag 1) ist frustrierend. Social Quests
   erst anbieten, wenn ≥1 Freund vorhanden ist; vorher an der Stelle die
   Invite-CTA zeigen.

---

## 5. Skalierungsprobleme

- **Nicht kritisch für das MVP.** Bei realistischen TestFlight-Zahlen
  (< 1.000 Nutzer) trägt jede Standardarchitektur.
- Die zwei Stellen, die man *jetzt* richtig bauen muss, weil ein späterer Umbau
  teuer wird: **(a)** XP als append-only Ledger statt als Integer-Zähler —
  ohne Ledger sind Wochen-Leaderboards, Seasons und Korrekturen unmöglich;
  **(b)** kanonische Referenzdaten (Stadt/Land/Venue/Beer) mit stabilen IDs und
  Merge-Fähigkeit — nachträgliches Deduplizieren von 100k Check-ins ist Hölle.
- Alles andere (Materialized Views, Caching, Sharding, Regionen) ist bewusst
  *nicht* jetzt zu bauen.

---

## 6. App-Store-Probleme

| Thema | Regel | Konsequenz |
|---|---|---|
| Alkoholbezug | Age Rating "Frequent/Intense Alcohol References" → 17+/18+ | Age Gate im Onboarding, korrekte Rating-Angaben, keine Bewerbung von Rauschtrinken |
| Gamification von Alkohol | Guideline 1.1.6 / 1.4 | Die Nicht-Belohnung von Menge ist ein **Feature für das Review**: In den Review-Notes explizit erklären. Zusätzlich Tages-Cap und ein Responsible-Drinking-Hinweis. |
| UGC | 1.2 | Melden, Blockieren, Wortfilter für Username/Clan-Name, EULA — **MVP-Pflicht** |
| Account-Löschung | 5.1.1(v) | In-App-Löschung — **MVP-Pflicht** |
| Sign in with Apple | 4.8 | Sobald ein anderer Social Login existiert, ist SiwA Pflicht. Einfachste Lösung: **nur** Sign in with Apple im MVP. |
| Standort | 5.1.1 | Purpose String, Berechtigung erst im Moment des Check-ins anfragen, App muss ohne Standort funktionieren |
| Minimale Funktionalität | 4.2 | Ein "Bier-Tagebuch" allein ist grenzwertig; Quests/Clans/Karte lösen das |
| TestFlight extern | Beta App Review | Demo-Account + Erklärtext bereitstellen |

---

## 7. Sinnvolle Vereinfachungen (Empfehlungen)

Alle folgenden Punkte sind **Empfehlungen zu MUST-HAVE-Positionen aus §26** —
Entscheidung liegt beim Product Owner. Keine wurde eigenmächtig gestrichen.

| # | Vorschlag | Begründung | Ersparnis |
|---|---|---|---|
| V1 | **City-Leaderboard auf "Top 20 in dieser Stadt" reduzieren**, kein globales Städte-Ranking, erreichbar nur aus der City-Detail-Ansicht | Eigener Tab lohnt bei < 1.000 Nutzern nicht; die Daten liegen ohnehin vor | ~1 Screen |
| V2 | **Prozent-Fortschritt streichen** (siehe 1.2), City-Level stattdessen | Nicht seriös berechenbar | Konzeptschuld |
| V3 | **Karte als Marker-Karte, keine "Fog of War"-Aufdeckung** | Custom-Overlay-Rendering ist ein eigenes Projekt | mehrere Tage |
| V4 | **Nur Sign in with Apple**, kein Google/Mail im MVP | Spart Auth-Flows, erfüllt 4.8 automatisch | ~2 Tage |
| V5 | **Ein Clan pro Nutzer**, Owner-Rolle nicht übertragbar (Clan wird bei Löschung des Owners aufgelöst bzw. an ältestes Mitglied übergeben) | Rollen-/Rechtemodell entfällt | ~1 Tag |
| V6 | **Quests nicht dynamisch generiert**, sondern kleiner serverseitiger Katalog + Ablauf per Zeitstempel (kein Cron/Scheduler) | Spart komplette Job-Infrastruktur | ~2 Tage |
| V7 | **Avatare: keine Foto-Uploads**, sondern Auswahl aus ~24 vorgefertigten Illustrationen + Farbe | Kein Storage, keine Bildmoderation, kein Zuschneiden — beseitigt das größte UGC-Risiko | ~3 Tage + Moderationsaufwand |
| V8 | **Badges als reine Server-Regeln über bestehende Zähler**, keine eigene Badge-Engine | 6 Badges brauchen keine DSL | ~1 Tag |

---

## 8. Offene Entscheidungen für den Product Owner

Diese Punkte sind in STEP 2–5 mit der **jeweils empfohlenen Variante**
ausgearbeitet, damit die Arbeit nicht blockiert. Ein Veto ändert nur begrenzt
Code, wenn es *vor* der jeweiligen Phase kommt.

| ID | Frage | Empfehlung |
|---|---|---|
| D1 | UI-Sprache im MVP | Englisch, lokalisierbar aufgesetzt |
| D2 | Login-Verfahren | Nur Sign in with Apple |
| D3 | Backend | Supabase (Postgres + Auth + RLS + Edge Functions) |
| D4 | Avatare | Kuratierte Auswahl statt Foto-Upload (V7) |
| D5 | Prozent-Fortschritt | Streichen, City-Level stattdessen (V2) |
| D6 | Clan-XP-Regel | 60 % der Personal-XP (§17-Beispiel entspricht dem) |
| D7 | Friends-Leaderboard-Zeitraum | Woche als Default, Gesamt als zweiter Tab |
| D8 | Tages-XP-Cap aus Check-ins | 500 XP/Tag, max. 6 XP-wirksame Check-ins/Tag |
| D9 | Domain für Universal Links | wird benötigt (z. B. `beerquest.app`) — **echter Blocker für Phase 7** |
| D10 | Apple Developer Program aktiv? | **Blocker für TestFlight**, sollte früh geklärt werden |
