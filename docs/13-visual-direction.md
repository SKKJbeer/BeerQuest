# Visual Direction — drei Konzepte und eine Empfehlung

**Auftrag des PM (§20):** Drei visuelle Richtungen beschreiben, bevor größere
UI-Arbeit beginnt, und eine Empfehlung abgeben. Noch kein Redesign — es geht
um eine Produktentscheidung.

---

## Die Messlatte

Jede Richtung wird gegen fünf Fragen geprüft:

1. **Adventure Game oder Bier-Tracker?** (Product Principle §21)
2. **Funktioniert sie in Rom, München, Tokio und Portland gleichermaßen?**
3. **Überlebt sie den Vergleich mit Untappd** — oder sieht sie aus wie eine
   dunkle Variante davon?
4. **Wirkt sie wie ein Produkt oder wie ein Wochenendprojekt?**
5. **Skaliert sie** auf Clan-Embleme, Badge-Sets, Kartenstile und Seasons —
   ohne Neuanfang?

Zwei Vorgaben gelten für alle drei: **dark-first** (§11) und **keine
Emoji-UI** (§9).

---

## Direction A — „Dark Adventure"

**Grundgefühl.** Eine Expeditionskarte bei Nacht. Ruhig, ernsthaft,
entdeckerisch. Der Nutzer ist Reisender, nicht Konsument. Nächster Verwandter:
Kartenwerk und Reisetagebuch — nicht Spiel-HUD.

**Farbwelt.** Tiefes, entsättigtes Nachtblau-Anthrazit als Grund (nie reines
Schwarz). Ein einziger warmer Akzent: gebranntes Bernstein/Kupfer. Zustände
über Sättigung statt über neue Farben — Unentdecktes ist entsättigt, nicht
grau überlagert.

**Typografie.** Eine geometrische Grotesk mit Charakter für Überschriften und
Zahlen (Space Grotesk, Archivo, General Sans), eine neutrale für Fließtext.
XP-Zahlen groß, tabular, selbstbewusst.

**UI-Stil.** Karten mit sehr weichen Kanten, dünne Trennlinien, viel Ruhe.
Wenig Rahmen, Tiefe über Flächenhelligkeit statt Schatten.

**Map-Stil.** Der Kern der Richtung. Dunkles, entsättigtes Kartenbild;
entdeckte Orte leuchten warm, alles andere tritt zurück. Länder mit
Fortschritt bekommen eine leichte Einfärbung. Langfristig ausbaubar in
Richtung „Fog of War", ohne den Stil zu brechen.

**Passport-Stil.** Wie ein Reisepass: Seiten pro Land, gestempelte Einträge,
Prägeoptik statt Kacheln. Zustände sind Stempel-Zustände.

**Badge-Stil.** Geprägte Metallmedaillen — Kupfer, Messing, Silber. Eine Form,
drei Materialstufen, unterschiedliche Symbole. Sehr gut skalierbar.

**Clan-Stil.** Wappen mit Schild-Silhouette, kombinierbar aus Form + Muster +
Farbe. Das ist der Kern eines späteren Sammelsystems.

**Motion.** Sparsam. Der Reward-Moment ist die eine Stelle mit echter
Animation: XP zählt hoch, der Stempel setzt auf.

**Vorteile.** Passt exakt zu „Discover the world, one beer at a time".
International vollkommen neutral. Die Metapher Karte/Pass/Stempel trägt jedes
zukünftige Feature. Am weitesten weg von Untappd.

**Nachteile.** Kann bei schlechter Umsetzung *seriös bis langweilig* wirken.
Braucht gute Illustration, sonst wirkt sie leer. Weniger sofortige
„Spiel"-Signale — das Spielgefühl entsteht über Progression, nicht über Optik.

**Skalierbarkeit.** Sehr hoch. Stempel, Wappen, Medaillen, Kartenebenen und
Seasons fügen sich alle in die Metapher.

**Gefahr, generisch zu wirken.** Gering — aber nur mit eigener Iconography.
Mit Standard-Icons wird daraus eine beliebige dunkle App.

---

## Direction B — „Premium Beer Culture"

**Grundgefühl.** Ein sehr gut gemachtes Magazin über Bierkultur. Editorial,
erwachsen, kuratiert. Der Nutzer ist Kenner.

**Farbwelt.** Warmes Dunkelbraun-Schwarz, cremefarbener Text, ein
zurückhaltendes Gold. Sehr wenig Farbe insgesamt.

**Typografie.** Der Träger der ganzen Richtung. Eine Display-Serif für
Überschriften, eine saubere Grotesk für alles andere. Große Typo-Kontraste,
großzügiger Weißraum.

**UI-Stil.** Redaktionelles Layout, klare Raster, Bilder groß und ruhig.

**Map-Stil.** Zurückhaltend, fast beiläufig — die Karte ist eine Ansicht unter
mehreren, nicht das Zentrum.

**Passport-Stil.** Eine gedruckte Sammlung, Seiten wie in einem Katalog.

**Badge-Stil.** Feine Linien-Embleme, monochrom, Gold auf Dunkel.

**Clan-Stil.** Wortmarken und Monogramme statt Wappen.

**Motion.** Nahezu keine. Übergänge, keine Effekte.

**Vorteile.** Wirkt sofort hochwertig und erwachsen. Sehr gut für
Partnerschaften mit Brauereien und Marken (Geschäftsmodell C). Am
schwierigsten billig aussehen zu lassen.

**Nachteile.** **Das größte Problem: Sie ist kaum ein Spiel.** XP-Balken,
Level-Ups, Clan-Rankings und Quests wirken in einem Magazin-Layout wie
Fremdkörper. Sie zieht das Produkt genau in die Richtung, die Product
Principle §21 vermeiden will. Zusätzlich: Dunkelbraun und Gold sind
gefährlich nah an der ausgeschlossenen „Brauerei-Klischee"-Optik (§10) — der
Unterschied liegt allein in der Ausführungsqualität.

**Skalierbarkeit.** Mittel. Clan Wars, Seasons und City Battles bräuchten
einen zweiten, spielerischen Modus — also faktisch ein zweites Designsystem.

**Gefahr, generisch zu wirken.** Gering im Stil, hoch im Konzept: Es entstünde
ein sehr schönes Untappd.

---

## Direction C — „Social Game / Neon Adventure"

**Grundgefühl.** Ein modernes Mobile Game. Laut, bunt, sofort verständlich,
sozial. Der Nutzer ist Spieler.

**Farbwelt.** Sehr dunkler Grund, zwei bis drei kräftige Akzente
(Elektrisch-Cyan, Magenta, Limette), Verläufe, Glüheffekte.

**Typografie.** Fette, runde Grotesk. Zahlen dominieren.

**UI-Stil.** Kräftige Karten mit Verläufen, deutliche Schatten, große Buttons,
viel Rundung.

**Map-Stil.** Spielfeld: leuchtende Pins, Pulseffekte, sichtbare Cluster.

**Passport-Stil.** Kachelraster mit Seltenheitsstufen, wie ein Karten-Sammelspiel.

**Badge-Stil.** Bunte Formen mit Verlauf und Glow, Seltenheitsrahmen.

**Clan-Stil.** Bunte Embleme, Team-Farben, Ranglisten mit starker Hierarchie.

**Motion.** Viel: Konfetti beim Level-Up, Zähler, Pulsieren, Übergänge.

**Vorteile.** Kommuniziert „Spiel" sofort und ohne Erklärung. Passt am besten
zu Clan Wars, Seasons und Leaderboards. Rewarded Ads fügen sich später
natürlich ein. Wirkt jung und sozial.

**Nachteile.** **Genau das ist die von §10 ausgeschlossene Wirkung von
„schnell zusammengebaut".** Neon-Verläufe und Glow sind der visuelle
Standardgriff der letzten Jahre — das Risiko, wie eine beliebige generierte
App auszusehen, ist hier am höchsten. Die Bierkultur verschwindet vollständig.
Für Erwachsene über 30 schnell kindisch. Kollidiert mit dem Age Rating 18+:
Eine Alkohol-App im Neon-Spielzeug-Look ist im App Review ein unnötiges
Risiko.

**Skalierbarkeit.** Hoch für Spielmechanik, niedrig für Bierkultur und
Partnerschaften. Eine Brauerei wird darin nicht auftreten wollen.

**Gefahr, generisch zu wirken.** **Am höchsten von allen dreien.**

---

## Vergleich

| | A — Dark Adventure | B — Premium Beer Culture | C — Neon Social Game |
|---|:--:|:--:|:--:|
| Adventure statt Tracker (§21) | ●●● | ● | ●●● |
| International tragfähig | ●●● | ●●● | ●● |
| Abstand zu Untappd | ●●● | ● | ●●● |
| Wirkt wie ein Produkt | ●●● | ●●● | ● |
| Skaliert auf Clans, Seasons, Karte | ●●● | ●● | ●● |
| Passt zu 18+ und Alkoholthema | ●●● | ●●● | ● |
| Trägt Partnerschaften (P2) | ●● | ●●● | ● |
| Aufwand bis „sieht gut aus" | ●● | ●●● | ● |
| Risiko, generisch zu wirken | gering | gering | **hoch** |

---

## Empfehlung: **Direction A — Dark Adventure**, mit einer Anleihe aus C

**Warum A.** Sie ist die einzige Richtung, die alle fünf Prüffragen besteht.
Vor allem trägt ihre **Metapher**: Karte, Pass, Stempel, Wappen, Medaille.
Eine Metapher ist mehr wert als eine Farbpalette — sie beantwortet
Gestaltungsfragen, die noch niemand gestellt hat. Wenn in einem Jahr Seasons
dazukommen, ist klar, wie sie aussehen: eine neue Passseite. Bei B und C
müsste man das jedes Mal neu erfinden.

A ist außerdem die einzige Richtung, in der der **Passport** — unser
Signature Feature — nicht wie eine Liste aussieht, sondern wie ein
Sammelobjekt (§13).

**Was wir aus C übernehmen.** A hat eine echte Schwäche: Sie signalisiert
„Spiel" nicht sofort. Deshalb übernehmen wir aus C gezielt **drei Elemente**,
nicht den Stil:

1. **Den Reward-Moment.** Er darf laut sein — Zahlen zählen hoch, der Stempel
   setzt mit Wucht auf. Das ist die eine Stelle, an der Beer Quest sich wie
   ein Spiel anfühlen muss.
2. **Progressionsanzeigen, die man nicht übersehen kann.** XP-Balken und
   „Nächstes Ziel" gehören prominent nach oben, nicht in eine Fußzeile.
3. **Seltenheitsstufen** bei Badges — aber als Materialstufen (Kupfer,
   Messing, Silber), nicht als Neonrahmen.

**Was wir aus B übernehmen.** Genau eines: **typografische Disziplin.** Große
Kontraste, wenig Farben, viel Ruhe zwischen den lauten Momenten.

**Was wir ausdrücklich nicht tun.** Keine Verläufe als Flächen. Kein Glow.
Kein Holz, kein Beige, keine Bierkrüge. Keine Emoji.

---

## Konsequenz für den Code

Der bestehende `BQDesign`-Entwurf aus P0.1 (warmes Dunkel, Bernstein-Akzent)
liegt bereits in Richtung A und muss nicht verworfen werden — er wird in
P0.3 zu einem echten Token-System ausgebaut (`docs/15-design-system.md`).

**Offen und bewusst nicht jetzt entschieden:** die konkreten Schriften (Lizenz
prüfen, 0 € bevorzugt — Google Fonts oder OFL), das Icon-Set und die
Illustrationen. Das sind Beschaffungsentscheidungen, keine Richtungsfragen.

---

## Entscheidung erbeten

Bitte eine der drei Richtungen bestätigen oder ablehnen. **Bis dahin wird
keine Onboarding-UI gebaut** — sechs Screens auf einer unbestätigten
Richtung wären sechs Screens zum Wegwerfen.
