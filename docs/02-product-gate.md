# Product-/Architecture-Gate (v0.2)

Datum: 2026-08-30 · Ersetzt die Scope-Annahmen aus v0.1

Zwei neue harte Anforderungen ändern die Planung aus v0.1 substanziell:

1. **0 € laufende Infrastrukturkosten** zum Start.
2. **P0 ist ein Vertical Slice**, keine Feature-Liste.

Dieses Dokument enthält die kritische Selbstprüfung, die Scope-Schnitte und
die Definition of Done. Die Konsequenzen stehen in
`03-feature-matrix.md`, `04-cost-analysis.md` und den überarbeiteten
Spezifikationen.

---

## 1. Product Review

### A) Was ist aktuell unnötig kompliziert?

Die Planung v0.1 war eine gute **Zielarchitektur** und ein schlechter
**erster Schritt**. 43 Screens sind kein Vertical Slice, sondern eine
V1-Spezifikation. Konkret zu komplex:

| Aus v0.1 | Warum zu komplex für den ersten Test | Konsequenz |
|---|---|---|
| **Social Quests** (S41–S43) | Eigene Einladungsmechanik, Teilnehmerfortschritt, geteilter Zähler, Beitragsregeln, Join-Flow — ein Feature-Komplex, nur um zu testen, ob Quests Spaß machen. Solo-Quests testen dieselbe Frage. | → P1 |
| **Drei Leaderboards** | Mit 10 Testern gibt es genau einen Clan. Ein Clan-vs-Clan-Ranking mit einem Eintrag und ein City-Leaderboard mit drei Nutzern testen nichts. | Nur Friends-Leaderboard + Beitragsranking innerhalb des Clans → P0. Rest P1. |
| **City Detail / Country Detail** (S32/S33) | Zwei Screens, eine eigene Statistik-Tabelle, City-Level-Kurve — für Fortschritt, den der Passport bereits zeigt. | → P1 |
| **Universal Links + AASA + Landing-Page** | Web-Hosting, Domain, Entitlements, Deferred-Deep-Link-Workaround. Für 10 Tester, die sich ohnehin persönlich kennen. | → P1. P0: Invite-**Code** per Share Sheet. |
| **Moderations-Stack** (Melden, Blockieren, Wortfilter, EULA) | Notwendig für den App Store — aber ein **interner** TestFlight-Kreis (bis 100 Personen im eigenen Team) durchläuft **kein Beta App Review**. | → P1, harte Voraussetzung vor jedem externen Test |
| **Offline-Sync-Engine** | Eine Queue mit Konfliktbehandlung und Sammel-Rewards ist ein eigenes Teilprojekt. | P0: minimale persistente Wiederholung eines fehlgeschlagenen Check-ins. Voller Sync → P1 |
| **`user_country_stats`, `verification_level`-Workflow, Anti-Cheat-Flagging** | Infrastruktur für Probleme, die wir mit 10 befreundeten Testern nicht haben. | Tabellen/Spalten bleiben (kosten nichts), Logik → P1 |

**Was NICHT zu komplex war und bleibt:** der eine transaktionale
`create_check_in`-Call, das XP-Ledger, kanonische Städte aus lokalen Daten.
Das sind genau die drei Stellen, an denen ein späterer Umbau teuer wäre.

### B) Welche Architekturentscheidung könnte uns später unnötig Geld kosten?

| Risiko | Warum teuer | Vermeidung in P0 |
|---|---|---|
| **Nutzergenerierte Bilder** (Foto-Avatare, Foto-Check-ins, Verification-Fotos) | Storage + Egress + CDN + Bildmoderation. Der einzige Posten, der mit Nutzerzahl *und* Nutzung linear skaliert. | Bundled Avatar-Illustrationen, keine Fotos. Bereits so entschieden (D4) — jetzt auch ökonomisch begründet. |
| **Geocoding-API pro Anfrage** | Google/Mapbox Geocoding kostet pro Request. Bei einem Check-in-lastigen Produkt ist das ein Posten, der nie wieder verschwindet. | Eigene `cities`-Tabelle aus GeoNames, Zuordnung per SQL. Einmalige Datenmenge, 0 € pro Anfrage, dauerhaft. |
| **Gesprächige Clients** | Free Tiers begrenzen fast immer **Egress**, nicht Rechenzeit. Polling, N+1-Abfragen und ungecachte Listen verbrennen das Kontingent. | Ein Aggregat-Call `get_home`, Caching, kein Polling, keine Hintergrund-Refreshes. |
| **Scheduler/Cron-Abhängigkeit** | Zeitgesteuerte Jobs (Quest-Ablauf, Leaderboard-Reset, Season-Wechsel) zwingen zu einem dauerhaft laufenden Dienst. | Alles **lazy beim Lesen** auswerten. Kein Cron in P0. |
| **Managed Services mit Vendor-Lock** | Ein proprietäres Datenmodell (Firestore, CloudKit) macht den Wechsel zum Rewrite statt zum Dump. | Postgres. `pg_dump` läuft überall. |
| **Firebase Cloud Functions** | Erfordern seit 2024 den Blaze-Plan, also eine hinterlegte Kreditkarte — Freikontingente reichen meist, aber die Kostenkontrolle ist nicht mehr strukturell. | Nicht verwendet. |

### C) Welche externen Services können wir vermeiden?

Vollständig vermieden in P0: Geocoding-API · Mapbox/Google Maps · Branch/
AppsFlyer (Deep-Link-Attribution) · Sentry/Crashlytics · Amplitude/Mixpanel/
PostHog · Bild-CDN · E-Mail-Versender · Bierdatenbank-API (Untappd/BreweryDB) ·
eigene Domain · jeder Push-Dienst.

Übrig bleiben genau zwei: **Supabase Free** (Datenbank + Auth + Logik) und
**Apple** (MapKit, Sign in with Apple, TestFlight, Crash-Reports) — beides 0 €.

### D) Welche Funktionen sind für den ersten Test noch zu groß?

Bereits in A) benannt. Zusätzlich, weniger offensichtlich:

- **City Quests.** Brauchen eine verlässliche Stadt-Auflösung *im Moment des
  Annehmens*, Sonderbehandlung beim Weiterreisen und einen Fehlerpfad ohne
  Standortberechtigung. Der Quest-Mechanismus lässt sich mit Solo-Quests
  vollständig testen. → P1.
- **Prüfung der Geräteposition gegen die gewählte Location.** Anti-Cheat gegen
  Freunde, die man persönlich kennt. → P1.
- **Account-Löschung und Datenexport.** Richtig und notwendig — aber vor dem
  App Store, nicht vor dem internen Test. → P1 (harte Voraussetzung).
- **Ein Bier-Seed-Katalog mit 300–500 Einträgen.** Kuratierungsarbeit ohne
  Erkenntnisgewinn. P0 startet mit ~60 Bieren der Zielmärkte; der Rest entsteht
  durch die Tester selbst — und deren Eingaben zeigen uns, was wir wirklich
  brauchen.

### E) Welche Funktion fehlt, damit sich Beer Quest schon im ersten Durchlauf wie ein echtes Spiel anfühlt?

Drei Dinge fehlten in v0.1 — alle billig, alle in P0 aufgenommen:

1. **Ein sichtbares nächstes Ziel.** Die App zeigte XP und Level, aber nie,
   *worauf* man hinarbeitet. Spiele zeigen immer das nächste Ziel.
   → Home zeigt dauerhaft „Next: 🌍 5 Countries · 3/5" (nächstes Badge oder
   nächster Level-Up, je nachdem was näher ist). **≈ 0,5 Tage.**
2. **Ein Grund, morgen wieder zu öffnen.** v0.1 hatte keinen Rhythmus.
   → **Daily Quest**: eine Solo-Quest, die um lokal Mitternacht wechselt, plus
   ein **wöchentliches Friends-Leaderboard**, das montags neu startet.
   Beides fällt aus dem XP-Ledger heraus, ohne Scheduler. **≈ 1 Tag.**
   > Bewusst **kein** Check-in-Streak. Ein Streak, den man nur durch tägliches
   > Trinken hält, ist genau das System, das §2 der Vision verbietet. Die
   > Daily Quest kann und soll auch nicht-trinkbezogen sein („lade einen
   > Freund ein", „entdecke einen neuen Ort").
3. **Ein spürbarer Reward-Moment.** War geplant, wurde hier aber zur
   Kernanforderung erhoben: Der Screen nach dem Speichern ist das Produkt.
   Wenn er sich wie eine Bestätigungsmeldung anfühlt, ist die App tot.

### F) Wo droht Beer Quest wie Untappd statt wie ein Spiel zu wirken?

Fünf konkrete Gefahrenstellen und die jeweilige Gegenmaßnahme:

| Gefahr | Gegenmaßnahme in P0 |
|---|---|
| Der Check-in wird zum **Formular** (Bewertung, Foto, Notiz, Stil, ABV) | Nur Bier + Ort. Keine Bewertung, kein Foto, kein Stil. Notizfeld optional und eingeklappt. |
| **Die Bierliste** wird zum Hauptinhalt | Der Passport zeigt zuerst die **Karte**, dann Länder/Städte, dann Orte, dann Biere. Das Bier ist die *kleinste* Sammeleinheit, nicht die wichtigste. |
| Der **Feed** wird zum Startbildschirm | Home ist ein **Quest-Board**: Level, aktive Quest, nächstes Ziel, dann erst Aktivität — und die auf 3 Zeilen begrenzt. |
| Fortschritt bleibt eine **Zahlenkolonne** | Jede Entdeckung erzeugt einen sichtbaren Reward. Die Karte füllt sich. Badges sind Bilder, keine Listeneinträge. |
| Es fühlt sich **einzeln** an | Der Clan bleibt in P0 — mitsamt Beitragsranking und Aktivität. Das ist der Unterschied zwischen Tagebuch und Spiel. |

Kurzformel für jede spätere Feature-Entscheidung:
**Untappd dokumentiert, was du getrunken hast. Beer Quest zeigt, wie weit du
gekommen bist.**

---

## 2. Der Vertical Slice

Der vom PM vorgegebene Slice, geprüft Schritt für Schritt:

| Schritt | In P0? | Begründung |
|---|---|---|
| ONBOARDING | ✅ | Auf 4 Schritte gekürzt: Apple-Login → Alter → Username → Avatar |
| HOME | ✅ | Quest-Board, kein Feed |
| FIRST BEER CHECK-IN | ✅ | **Der Kern.** Zwei Taps und ein Feld |
| XP / LEVEL-UP | ✅ | Serverseitig, Ledger |
| PASSPORT / MAP UPDATE | ✅ | Karte + 4 Listen. Ohne City-/Country-Detailseiten |
| QUEST | ✅ | Nur Solo-Quests, inkl. Daily Quest |
| QUEST REWARD | ✅ | Teil des Reward-Screens |
| FRIEND INVITE | ✅ | **Per Code**, nicht per Universal Link |
| CLAN | ✅ | Erstellen, beitreten, Mitglieder, Beitrag, Clan-XP, Ranking |
| LEADERBOARD | ✅ | **Nur Friends** (Woche/Gesamt) + Ranking innerhalb des Clans |

**Kein Schritt wird gestrichen.** Der Slice ist richtig geschnitten — die
Ersparnis liegt in der *Tiefe* jedes Schritts, nicht in der Anzahl.

Ergebnis: **28 Screens statt 43** und **36 Entwicklertage statt 52**
(mit Puffer ~45 statt ~65).

---

## 3. Definition of Done — P0

P0 ist fertig, wenn ein Testnutzer auf einem echten Gerät ohne Anleitung:

| # | Kriterium | Nachweis |
|---|---|---|
| 1 | die App öffnet | TestFlight-Build startet |
| 2 | versteht, was Beer Quest ist | Welcome-Screen; im Test unaufgefordert richtig wiedergegeben |
| 3 | ein Profil erstellt | Onboarding < 60 s |
| 4 | sein erstes Bier einträgt | Check-in < 15 s ab Tap auf ADD |
| 5 | einen Ort auf der Karte sieht | Pin erscheint ohne App-Neustart |
| 6 | XP erhält | Reward-Screen zeigt Aufschlüsselung |
| 7 | Level-Fortschritt sieht | XP-Bar auf Home animiert |
| 8 | eine einfache Quest startet | Quest-Tab, ein Tap |
| 9 | die Quest abschließt | über zwei Check-ins |
| 10 | eine Belohnung erhält | Quest-Karte im Reward-Screen |
| 11 | einen Freund einladen kann | Share Sheet mit Code; Empfänger löst ihn ein |
| 12 | einen Clan erstellen/beitreten kann | über Clan-Code |
| 13 | seinen Clan-Beitrag sieht | Clan-Detail, eigene Zeile hervorgehoben |
| 14 | ein Leaderboard sieht | Friends, Wochenansicht |
| 15 | seinen Passport ansieht | Karte + 4 Listen mit echten Daten |
| 16 | **einen Grund hat, wiederzukommen** | Daily Quest wechselt; Wochen-Leaderboard startet Montag neu; nächstes Ziel sichtbar |

Zusätzlich technisch:

- 0 € Infrastrukturkosten im Testmonat (nachgewiesen an der Supabase-Nutzung)
- XP nicht vom Client manipulierbar
- Ein fehlgeschlagener Check-in geht nicht verloren
- Kein Absturz in einem vollständigen Durchlauf der 16 Kriterien
