# Monetarisierung

**Produktentscheidung des PM, 2026-08-30.** Ergänzt und präzisiert
Product Vision §24.

## Das Prinzip

> Beer Quest beweist zuerst: **„Das Spiel macht Spaß."**
> Danach: **„Die Nutzer kommen wieder."**
> Erst danach: **„Wir können damit Geld verdienen."**
>
> Nicht umgekehrt.

Daraus folgt die Reihenfolge: **Ads vor Premium.** Wir sammeln erst Daten
darüber, ob und wofür Nutzer zahlen würden, statt ein Abo-System auf Verdacht
zu bauen.

---

## P0 — keine Monetarisierung

Der MVP enthält **keine Werbung, keine Paywall, kein Premium, keine
Ad-SDKs**. Er konzentriert sich vollständig auf den Core Loop:

```
Check-in → XP → Quest → Passport → Friends → Clan → Competition
```

Das ist keine Verschiebung aus Zeitmangel, sondern eine Entscheidung: Ein
Spiel, das noch nicht beweist, dass es Spaß macht, wird durch Werbung nicht
besser, sondern schlechter messbar.

---

## P1 — erste Monetarisierung testen

In dieser Reihenfolge:

### 1. Dezente Native Ads
Werbung, die sich natürlich in die App einfügt und den Game Loop nicht
unterbricht. Denkbare Orte: eine gekennzeichnete Karte in einer Liste, ein
Platz unterhalb des Passports. **Nie** im Check-in-Flow.

### 2. Rewarded Ads — für Beer Quest besonders interessant

```
QUEST COMPLETE!
+250 XP

⚡ Watch an ad → +50 Bonus XP
NO THANKS
```

Freiwillig, immer mit einer sichtbaren Ablehnen-Option.

> **Harte Kopplungsregel:** Rewarded Ads dürfen **niemals** an Check-ins,
> Trinkmenge oder Discovery-XP gekoppelt werden — nur an **Game- und
> Achievement-Aktivität** (Quest-Abschluss, Badge, Level-Up).
>
> Sonst entsteht über die Hintertür genau das System, das Product Vision §2
> verbietet: mehr trinken ⇒ mehr Gelegenheiten für Bonus-XP ⇒ mehr XP.
> Diese Regel ist nicht verhandelbar und gehört in die Abnahme jedes
> Ad-Features.

### Ausdrücklich nicht gewünscht

- Werbung beim App-Start
- Werbung nach jedem Check-in
- Werbung mitten im Check-in-Flow
- permanente störende Banner
- übermäßige Interstitials
- Paywall für soziale Kernfunktionen (Freunde, Clan, Quests, Passport)

---

## P2 — Beer Quest PRO (Option, nicht beschlossen)

Erst wenn die Ad-Daten zeigen, ob und wofür gezahlt würde. Mögliche Inhalte:

Werbung entfernen · erweiterte Statistiken · zusätzliche
Passport-Auswertungen · kosmetische Profiloptionen · exklusive Badges ·
zusätzliche Questtypen · Custom Quests · erweiterte Clan-Funktionen.

**Nicht implementieren.** Vorbereitet ist lediglich die Spalte
`profiles.tier` (`free` | `plus`), die nichts kostet und nichts festlegt.

---

## P2 — Partnerschaften

Bars, Brauereien, Festivals und Biermarken. Zum Beispiel gesponserte Quests:

```
🍺 PERONI QUEST
Discover 3 participating locations
🏆 Unlock: Peroni Explorer Badge
```

Vorbereitet ist die Spalte `venues.owner_id` (nullable). Mehr nicht.

---

## Technische Vorgaben für P0

Damit die spätere Monetarisierung nicht gegen die Architektur arbeitet — ohne
jetzt etwas dafür zu bauen:

| Vorgabe | Umsetzung in P0 | Status |
|---|---|---|
| Keine UI-Struktur, die spätere Ad-Platzierungen verbaut | Home, Quests und Passport sind **Listen aus Karten**. Eine zusätzliche, gekennzeichnete Karte einzuschieben ist eine Zeile — kein Umbau. | ✅ so gebaut |
| Keine Architektur, die nur mit Premium funktioniert | Es gibt keine Feature-Gates, keine Berechtigungsprüfungen, keinen Entitlement-Zustand. `profiles.tier` existiert, wird aber nirgends abgefragt. | ✅ |
| Monetarisierung als klar getrennte spätere Schicht | Kein Ad-SDK, kein Kaufabwicklungscode, keine Werbe-IDs, kein Tracking. Der Client hat **kein** Drittanbieter-SDK. | ✅ |
| Keine zusätzlichen kostenpflichtigen Dienste in P0 | 0 € laufende Infrastrukturkosten bleiben das Ziel (`04-cost-analysis.md`). | ✅ |

**Vor der SDK-Auswahl zu prüfen:** Werbenetzwerke haben eigene Richtlinien zu
Alkoholinhalten. Die Kombination aus Alkohol-App, Rewarded Ads und einem
Age Rating von 17+/18+ kann die Zahl der verfügbaren Netzwerke einschränken
oder die Erlöse drücken. Das ändert den Plan nicht — aber es gehört geprüft,
**bevor** ein SDK integriert wird, nicht danach.

**Ein Ad-SDK ist eine neue Abhängigkeit** und durchläuft in P1 dieselbe
Prüfung wie jede andere: Kosten bei 10/100/1.000 Nutzern, Preisskalierung,
Ausstiegsaufwand, Alternativen (`04-cost-analysis.md` §6). Dazu kommen dann
Themen, die es heute nicht gibt: Privacy Manifest des SDK, App-Tracking-
Transparency, zusätzliche App-Privacy-Labels und die Frage, ob eine
Alkohol-App Werberichtlinien der Netzwerke erfüllt.

---

## Was das für heute bedeutet

Nichts zu tun. Diese Seite existiert, damit die Entscheidung dokumentiert ist
und niemand — auch kein späterer Beitragender — versehentlich Monetarisierung
nach P0 zieht oder eine Struktur baut, die sie später blockiert.
