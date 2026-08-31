# Produkt-DNA

**Verbindliche Ergänzung der Product Vision, PM 2026-08-30.** Dieses Dokument
beantwortet Fragen, die noch niemand gestellt hat — es ist der Maßstab für
Entscheidungen, für die es keine Spezifikation gibt.

---

## Das eine Prinzip

> **Macht diese Entscheidung Beer Quest mehr zu einem Adventure Game — oder
> mehr zu einem Bier-Tracker?**
>
> Wenn sie Richtung Tracker zieht, muss kritisch geprüft werden, ob sie
> wirklich notwendig ist.

Das Fernziel: **Discover the world. One beer at a time.**

Der Nutzer soll am Ende nicht denken „Ich habe 237 Biere getrunken", sondern
**„Ich habe 12 Länder, 43 Städte und 187 Biere entdeckt."**

Das ist derselbe Datensatz. Es ist ein völlig anderes Produkt.

---

## Was Beer Quest ist

```
Adventure Game + Social Game + Beer Culture + Travel + Discovery
```

Der Nutzer sammelt nicht Getränke. Er sammelt **Biere, Locations, Städte,
Länder, Erlebnisse und Geschichten**. Das Bier ist der rote Faden, der die
Welt verbindet — nicht der Gegenstand.

Gefühl: *„Ich spiele ein Spiel und entdecke dabei die Bierwelt."*
Nicht: *„Ich führe eine Liste darüber, was ich getrunken habe."*

---

## Der Abstand zu Untappd

Untappd-artige Elemente sind **nicht** unser USP und gehören nicht ins
Zentrum:

| Nicht unser Zentrum | Unser Zentrum |
|---|---|
| Bier bewerten, Sterne vergeben | Entdecken und sammeln |
| Vollständige Bierdatenbank | Die eigene Weltkarte |
| „Was habe ich getrunken?" | „Wie weit bin ich gekommen?" |
| Feed als Startseite | Quest-Board als Startseite |

Bier-Tracking ist die **Grundlage** des Spiels, nicht sein Inhalt.

Fünf konkrete Gefahrenstellen und die Gegenmaßnahmen stehen in
`02-product-gate.md` §1 F. Sie gelten unverändert.

---

## Die Weltkarte

Signature Feature. Die Hierarchie muss langfristig durchgängig tragen:

```
World → Country → City → Location → Beer
```

Gesammelt wird auf **allen vier Ebenen** — nicht nur Länder:

```
Germany          Italy
→ München        → Cecina
→ Berlin         → Florence
→ Hamburg        → Rome
```

Ziel: *„Das ist meine Beer World."*

In P0 darf die Karte technisch und visuell einfach sein — Marker und Cluster,
kein Fog of War. **Aber das Datenmodell trägt die Hierarchie bereits
vollständig** (`countries → cities → venues → check_ins`, plus
`user_discoveries` über alle vier Ebenen). Eine spätere Aufwertung ist reine
Darstellungsarbeit, kein Umbau.

---

## Passport und Sammelzustände

Der Passport soll sich wie ein **Sammelobjekt** anfühlen, nicht wie eine
Tabellenansicht. Vier Zustände, zentral definiert
(`BQCore.CollectionState`, `BQDesign.CollectibleTile`):

| Zustand | Bedeutung | Material |
|---|---|---|
| `locked` | bekannt, noch nicht erreicht | entsättigt |
| `discovered` | entdeckt | Kupfer |
| `completed` | zugehöriges Ziel erfüllt | Messing |
| `mastered` | besondere Leistung | Silber |

Badges sind hochwertige Sammelobjekte — geprägte Medaillen, keine Kreise mit
Emoji.

### ⚠️ Ein Widerspruch, der aufgelöst werden muss

`07-user-flows.md` F4 sagt bisher: *„Es wird nur Gesammeltes gezeigt — keine
Locked-Listen, sonst entsteht das Gefühl eines unendlichen Katalogs."*
Das steht gegen den Wunsch nach einem `locked`-Zustand.

**Vorgeschlagene Auflösung — Entscheidung des PM:**

`locked` wird nur auf **endliche, überschaubare Mengen** angewendet:

- ✅ Badges (heute 4, später vielleicht 40) — hier motiviert `locked`
- ✅ Städte **innerhalb eines bereits besuchten Landes** — „du warst in Rom,
  aber noch nicht in Florenz" ist eine gute Einladung
- ✅ Quest-Ketten und Season-Ziele (später)
- ❌ **Nie** der offene Bierkatalog — „12 von 187.000 Bieren" demotiviert
- ❌ Nie alle Länder der Welt — 12 von 249 sieht nach Scheitern aus

Faustregel: `locked` ist eine **Einladung**, keine Bilanz. Wenn die Zahl
rechts vom Bruchstrich entmutigt, ist der Zustand falsch angewendet.

Bis zur Entscheidung bleibt P0 bei „nur Gesammeltes anzeigen" — der Typ ist
vorhanden, wird aber nur für Badges genutzt.

---

## Clans

Eigene Identität, langfristig ein eigenes Progressionssystem:
Name, **Emblem**, Level, XP, Ranking, später freischaltbare Kosmetik.

Das Emblem ist bewusst als kombinierbares System gedacht (Form + Muster +
Farbe) — daraus kann selbst ein Sammelsystem werden.

**P0 bleibt einfach:** erstellen, beitreten, Mitglieder, Clan-XP, eigener
Beitrag, Ranking. Kein Chat, keine Rollen, keine Clan Wars, keine
Moderationsplattform. Der Activity Feed (10 Zeilen aus vorhandenen Daten) ist
enthalten, weil er ohne nennenswerten Aufwand möglich ist und den Clan
lebendig macht.

Langfristig: Clan Wars, City Battles, Country Battles, Seasons, Team Quests,
Clan Challenges. Alles P2.

---

## Gamification

Kern: XP · Level · Fortschrittsbalken · Quests · Rewards · Badges · Passport ·
Collection · Leaderboards · Clan-Fortschritt.

**Keine große Gamification-Engine.** P0 bleibt einfach und verständlich; die
Systeme müssen erweiterbar sein, nicht vollständig.

Der **Server ist die Quelle der Wahrheit** für XP, Level, Leaderboards und
alle relevanten Rewards. Das ist bereits so umgesetzt: `create_check_in`
entscheidet transaktional, der Client rechnet nie.

---

## Daydrinking — als Abenteuer, nicht als Menge

Aufgenommen in die Produktvision. **P1/P2, keine Implementierung in P0.**

> **Daydrinking bedeutet ausdrücklich nicht „mehr Alkohol = mehr Punkte".**

Belohnt werden **Discovery und Abenteuer**, nie die konsumierte Menge.
Mögliche spätere Questtypen:

| Quest | Parameter |
|---|---|
| **Day Drifter** — entdecke ein neues Bier zwischen 12:00 und 16:00 | Uhrzeit |
| **Sunday Session** — schließe eine Entdeckung an einem Sonntagnachmittag ab | Wochentag + Uhrzeit |
| **First Pour** — sei unter den Ersten, die an diesem Tag einen Ort entdecken | Reihenfolge |
| **Golden Hour** — entdecke einen Ort im Zeitfenster der goldenen Stunde | Sonnenstand |
| **Beach → Beer** — entdecke ein Bier an einem Ort nahe der Küste | Geografie |

Später mögliche Questparameter: Zeit, Wochentag, Tageslicht, Reise, Location,
Wetter, Events.

**Warum das trägt:** Jede dieser Quests verlangt **eine** Entdeckung unter
einer *Bedingung* — nicht *mehr* Entdeckungen. Die Bedingung ist der
Spielinhalt. Wer zehn Biere trinkt, erfüllt „Day Drifter" kein zweites Mal.

**Technisch vorbereitet, ohne etwas zu bauen:** `check_ins.happened_at` ist
`timestamptz`, `local_date` ist separat gespeichert, und `quest_templates.goal`
ist `jsonb`. Zeit-, Wochentags- und Geobedingungen sind damit später
zusätzliche Felder im Goal-Objekt — keine Migration des Kerns.

**Prüfregel für jede Daydrinking-Quest:** Lässt sie sich durch *mehr Trinken*
schneller erfüllen? Dann ist sie falsch entworfen.

---

## Keine Emoji-UI

Die Emoji in allen bisherigen Konzepten sind **Text-Platzhalter**. In der
App haben sie nichts verloren.

**Ausgeschlossen:** Emoji-Kacheln, Emoji-Badges, Emoji-Navigation, Emoji als
primäre UI-Icons, generische Emoji-Gamification.

**Stattdessen:** eigene Iconography, hochwertige grafische Symbole,
Typografie, Illustrationen, geprägte Badges, echte Kartenvisualisierung,
gezielte Motion, klare visuelle Hierarchie, eigenständige Brand-Elemente.

Beer Quest darf nicht wirken wie eine schnell zusammengebaute App.

### Umsetzungsstand

| Ort | Vorher | Jetzt |
|---|---|---|
| `AvatarView` | Emoji-Glyphen | Monogramm auf gefärbter Fläche |
| Badge-Icons in der Datenbank | Emoji-Codepoints (`1F37A`) | semantische Namen (`badge.first-beer`) |
| Tab-Leiste, Buttons, Empty States | teils fest verdrahtete Symbolnamen | zentral über `BQIcon` |
| Alle Icon-Namen | verstreut in Views | **eine Datei**, austauschbar |

**Bewusste Ausnahme, zur Entscheidung gestellt:** `countries.flag_emoji`.
Landesflaggen als Unicode sind eine etablierte, sofort verständliche
Darstellung und plattformübergreifend gepflegt. Alternative wären eigene
Flaggen-Assets für 249 Länder. **Empfehlung: als Daten behalten**, die
UI-Entscheidung später im Passport-Design treffen.

---

## Visuelle Identität

Wirkung: **modern, premium, spielerisch, abenteuerlich, social, international,
etwas frech.**

Ausgeschlossen: rustikal, Oktoberfest, Brauerei-Klischee, Holzoptik,
Braun/Beige, „Bierkrug-App".

Beer Quest muss in Italien, Deutschland, Japan, den USA, Spanien und
Großbritannien gleichermaßen selbstverständlich wirken.

**Dark-first** — Beer Quest findet abends statt, in Bars, unterwegs, auf
Reisen. Nicht komplett schwarz: dunkle Grundfläche, eine starke Akzentfarbe,
hochwertige Typografie, sichtbare Spielelemente.

Die drei ausgearbeiteten Richtungen und die Empfehlung:
**`13-visual-direction.md`**. Die Umsetzung als Token-System:
**`15-design-system.md`**.

---

## Monetarisierung

Zusammengefasst: **erst Spaß, dann Wiederkehr, dann Geld.** P0 ohne Werbung,
P1 dezente Native Ads und freiwillige Rewarded Ads, P2 Beer Quest PRO und
Partnerschaften. Vollständig in **`12-monetization.md`**.
