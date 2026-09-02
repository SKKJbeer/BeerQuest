# Changelog

Jede Änderung mit Begründung, neueste oben.

Drei Dateien, drei Fragen — eine Frage wird an genau einer Stelle beantwortet:

| Frage | Datei |
|---|---|
| Wo stehen wir **jetzt**? | `docs/HANDOFF.md` |
| Was hat sich je **Version** geändert, und warum? | **diese Datei** |
| **Wie** kam es dazu (Sessions 1–13)? | `docs/HANDOFF-ARCHIV.md` |

Versionsschema: `docs/16-engineering-standard.md` §5.

---

## v0.5.0 — Das Onboarding in SwiftUI, und was der Abgleich aufdeckte

P0.4, erste Runde: **ein Bereich**, nicht zehn. Das Onboarding zuerst, weil
es der einzige Weg in die App ist.

### Behoben — der Prototyp versprach etwas anderes als der Server
Beim Bauen der echten Screens fiel der Abgleich mit
`complete_onboarding` an. Zwei Stellen liefen auseinander, und beide hätten
den Nutzer erst **nach dem letzten Schritt** in eine Absage laufen lassen:

- **Der Server will ein Geburtsjahr, der Prototyp fragte Ja/Nein.**
  `complete_onboarding` nimmt `p_birth_year` und rechnet damit; ein Häkchen
  liefert das nicht. Beide fragen jetzt das Jahr — und nur das Jahr, nie das
  volle Datum (Datenminimierung, `docs/05-architecture.md` §11).
- **Der Server will `^[a-z0-9_]{3,20}$`, der Prototyp erlaubte alles.**
  Statt zu korrigieren wird jetzt vorgeschlagen: „Steffen M." wird sichtbar
  zu `@steffen_m`. Der Wortfilter prüft wie der Server auf Gleichheit **und**
  Enthaltensein (`xadminx` ist gesperrt).
- Die Auswahl bietet nur Jahre an, die der Server annimmt. Ein
  17-Jähriger findet sein Jahr gar nicht erst.

Das ist genau das Risiko R7 aus dem letzten Handoff, eingetreten binnen
einer Session.

### Neu
- **`BQOnboarding`** — neues Modul, drei Schritte in SwiftUI, gebaut nach dem
  validierten Prototyp: Versprechen (vier Zeilen), Geburtsjahr (Rad),
  Explorer-Name (mit lebendem Hinweis).
- **`BQCore.OnboardingRules`** — die Regeln als reine, testbare Logik.
  Sie sind eine **Kopie** des SQL, keine zweite Quelle, und die Datei sagt
  das auch: ändert sich `check_username`, ändert sie sich im selben Commit.
  Der Server bleibt die Instanz, die entscheidet — die App nimmt nur vorweg.
  `taken` erzeugt der Client **nie**: das weiß nur die Datenbank.
- **`RootView` schaltet jetzt auf den Sitzungszustand.** Vorher stand die
  Tab-Leiste unabhängig davon da — das Onboarding wäre gebaut, aber
  unerreichbar gewesen.
- **`SessionStore.applyLocalOnboardingResult`** — eine Attrappe bis P0.5, und
  sie heißt auch so. Sie legt keinen Account an; sobald der echte Aufruf
  kommt, fällt sie ersatzlos weg.

### Geprüft
- **17 neue Swift-Tests** (`OnboardingRulesTests`) halten die Swift-Kopie
  gegen die Fälle, die im SQL stehen: Format, Groß-/Kleinschreibung,
  Wortfilter als Teilzeichenkette, `norm_name`, der Vorschlag, die
  Jahresdifferenz, das Mindestalter und dass die angebotene Auswahl genau
  die angenommene ist.
- **91 Prototyp-Prüfungen** (von 82).
- Beide Seiten prüfen dieselbe Vorgabe für das Standardjahr — zwei Vorgaben
  wären zwei Produkte.

### Offen
Die vollständige Wortfilterliste (~200 Begriffe) bleibt bewusst **nur** auf
dem Server: Sie ist Redaktionsarbeit und muss ohne App-Update pflegbar sein.
Die App fängt nur den Grundstock ab.

---

## v0.4.0 — Onboarding, Passport, Clan-Woche (UX-Slice)

Phase 2 des Stabilisierungsauftrags: **ein durchgehender Weg**, nicht zehn
Screens. Onboarding → Home → Entdecken → Check-in → Reward → Beer World →
nächste Quest, dazu Home → Clan.

### Neu
- **Onboarding, drei Schritte.** Es bildet den Server nach, der schon
  existiert (`supabase/tests/07_onboarding.sql`): Versprechen, Altersgrenze,
  Namenswahl mit Wortfilter. Was der Server nicht kann, steht dort auch
  nicht — sonst verspricht der Prototyp etwas, das niemand einlöst.
  - Die vier Versprechen sind vier Zeilen, kein Fließtext: **Discover,
    Collect, Progress, Compete**. Wer sie nicht in drei Sekunden liest,
    liest sie nicht.
  - „Not yet" auf die Altersfrage führt nicht weiter. Eine Frage, die man
    beliebig beantworten kann, ist Deko.
  - Der Wortfilter meldet sich beim Tippen, nicht danach. Wer ihn erst nach
    „weiter" erfährt, tippt zweimal.
- **Passport statt Sammlung.** Vier Zustände je Stadt: *locked → discovered
  → completed → mastered*. Ein gesperrtes Feld zeigt, **was** dort wartet,
  nie **wie viel** fehlt: „Florence — Waiting", nicht „12 von 187.000". Das
  ist der Unterschied zwischen einer Einladung und einer Bilanz, und er
  entscheidet, ob sich das Ding wie ein Adventure Game anfühlt oder wie ein
  Bier-Tracker (`docs/14-product-dna.md`). Eine Prüfung hält dagegen: kein
  Muster der Form „n von m" im Passport.
- **Clan „This week" zeigt Orte, keine Meldungen.** `Verona — 14`,
  `Berlin — 9`, `Prague — 7`, absteigend, mit Balken. „Lisa discovered
  Verona" ist eine Nachricht; „Verona — 14" ist ein Ort, an dem gerade etwas
  los ist — und genau das erzeugt den Sog. Wer selbst dort war, sieht es
  markiert.
- **Clan-Vorschau auf Home**, ganz unten: erst die eigene Welt, dann die der
  anderen. Sie zeigt **dieselbe** oberste Zeile wie der Clan-Schirm, nicht
  eine zweite Formulierung derselben Sache — die würde früher oder später
  etwas anderes behaupten.

### Behoben
- **Die letzte Karte auf Home lag unter der schwebenden Hauptaktion.** Die
  Scroll-Luft war auf 120 px eingestellt, gebraucht werden 186. Gefunden im
  Screenshot, nicht im Kopf; eine Prüfung scrollt jetzt ganz nach unten und
  misst nach.

### Geprüft
82 Prototyp-Prüfungen (von 47), neu darunter: alle drei Onboarding-Schritte,
die Sperre bei „Not yet", der Wortfilter in beiden Richtungen, die
Passport-Zustände, das Verbot der Bilanz-Formulierung, das Clan-Format samt
Sortierung und die Freiheit der letzten Karte.

---

## v0.3.1 — Die Prüfungen selbst geprüft

Diese Version enthält **keinen Produktcode**. Sie repariert das Werkzeug,
mit dem geprüft wird — und das hatte vier Fehler, von denen drei genau dann
zugeschlagen hätten, wenn man sich darauf verlässt.

### Behoben
- **`verify.sh` wäre auf jedem Mac abgestürzt.** Das Skript benutzte
  Bash-Arrays; `/bin/bash` auf macOS ist Version 3.2 von 2007 und bricht dort
  bei `${#ARRAY[@]}` mit leerem Array unter `set -u` ab. Rot geworden wäre
  also ausgerechnet der einzige Rechner, der den Xcode-Build überhaupt
  ausführen kann — ohne dass am Projekt etwas falsch gewesen wäre. Jetzt ohne
  Arrays, mit der Ursache im Kopf der Datei.
- **`melden.sh` lief auf Linux nie.** `[ "$WOHER" = "Darwin" ] && WOHER="Mac"`
  beendet unter `set -e` das Skript, sobald der Test falsch ist — also in
  jeder Cloud-Sitzung, wortlos und ohne eine Zeile zu schreiben. Der
  Mechanismus, der Mac und Cloud verbinden soll, war auf einer Seite tot.
  Jetzt ein `if`; ein gescheitertes Melden wird von `verify.sh` gemeldet.
- **Pfadfilter hätten jeden Pull Request blockiert.** GitHub meldet für einen
  Ablauf, der wegen eines Pfadfilters gar nicht startet, *keinen* Status —
  nicht „bestanden", sondern gar nichts. Als „required status check" bliebe er
  ewig ausstehend, und ein Pull Request, der nur Dokumentation ändert, ließe
  sich nie zusammenführen. Der Filter bleibt beim `push` (Kosten), er fällt
  beim `pull_request` (Zusammenführen).
- **`MARKETING_VERSION` stand seit P0.1 auf 0.1.0**, während die Marken bei
  v0.3.0 waren. Die App-Version wurde nie mitgezogen.

### Neu
- **Der iOS-Lauf beweist jetzt, dass Tests liefen.** Bisher lief `xcodebuild`
  mit `-quiet`: ein Schema ohne Testziel wäre genauso grün gewesen wie eines
  mit bestandenen Tests. `verify.sh` zählt die ausgeführten Tests und wird
  **rot, wenn es null sind**.
- **`--streng`**: In der CI zählt Übersprungenes als Fehler. Ein grüner Haken,
  hinter dem nichts geprüft wurde, ist schlimmer als ein roter. Lokal bleibt
  es beim alten Verhalten — dort ist ein fehlendes Werkzeug eine
  Umgebungseigenheit, keine Aussage über das Projekt.
- **`docs/19-branch-protection.md`**: die einzugebende Einstellung zum
  Abhaken, samt der Falle oben und einem Versuch, der belegt, dass der Schutz
  wirklich etwas verhindert.
- **Die Prototyp-Prüfung zählt sich selbst.** In der Übergabe stand „39
  Prüfungen"; tatsächlich laufen 47, weil einige in Schleifen stehen. Eine
  Zahl in einem Dokument veraltet still — eine, die der Lauf ausgibt, nicht.

- **Keine Versionsmarke ist je am Remote angekommen.** `git ls-remote --tags
  origin` liefert nichts; der Push scheitert reproduzierbar mit `HTTP 403`.
  Die Marken v0.1.0–v0.3.0 existierten nur lokal, in einem Container, der
  beim Sitzungsende verschwindet — drei Sessions lang meldete die Übergabe
  eine Version, von der am Repository nichts zu sehen war. Die Version lebt
  jetzt in dieser Datei und in `project.yml`, und `verify.sh` hält beide
  gegeneinander. Eine Marke ist eine Zugabe, kein Beleg.

### Belegt
- macOS-Build **grün**: GitHub-Lauf 33510952452, Commit 9e4ab6b, 80 s
  Testphase. Damit ist die seit Session 9 offene Frage beantwortet.

### Geändert
- `docs/HANDOFF.md` enthält nur noch den **laufenden Zustand**; die Sessions
  1–13 stehen wortgleich in `docs/HANDOFF-ARCHIV.md`. Drei Dateien, drei
  Fragen: *wo stehen wir jetzt* (Handoff), *was hat sich je Version geändert*
  (hier), *wie kam es dazu* (Archiv).

---

## v0.3.0-prototyp — Prototyp V2 (in v0.3.1 mit veröffentlicht)

### Prototyp V2 — UI/UX-Validierungssprint
- **Check-in von vier Schritten auf zwei Taps.** Der Bestätigungsschritt
  entschied nichts und ist ersatzlos weg; der Ort steht als *Auskunft* über
  der Bierauswahl statt als eigener Schritt dahinter. Ein Tap auf ein Bier
  checkt sofort ein — der Preis dafür ist ein Rückgängig-Streifen, und der ist
  billiger als eine Bestätigung bei jedem einzelnen Check-in.
- **Eine dominante Hauptaktion je Screen.** Der Test zählt, dass auf Home
  genau *eine* Fläche in Akzentfarbe liegt.
- **Beer World** als vier Ebenen mit Brotkrumen: World → Country → City →
  Location. Keine Standardkarte mit Nadeln, sondern Knoten, die durch die
  eigene Entdeckungsroute verbunden sind. Wartende Städte stehen gestrichelt
  daneben — eine Einladung, keine Bilanz.
- **Reward als Spielmoment**: XP zählen sichtbar hoch, Entdeckungen laufen
  gestaffelt ein, danach der nächste Grund weiterzuspielen. Kein Konfetti.
- **Clan-Vorschau** mit Wochenaktivität, Clan-Quest und Rangliste.
- **Typografische Stimme**: Archivo mit der Breitenachse als Gestaltungsmittel.
  Systemschrift konnte die Frage „wirkt das hochwertig?" nicht beantworten.
  Die Schrift ist in `Tokens.swift` als offene Beschaffungsentscheidung
  vermerkt — die App nutzt bis P0.11 weiter die Systemschrift.
- **Beim Testen gefunden:** Die Länder wurden kleingeschrieben gespeichert
  (`Set` mit normalisiertem Schlüssel). Die Weltkarte fand für „italy" keine
  Position und blieb leer. Jetzt eine `Map`: Schlüssel normalisiert, Wert in
  Anzeigeschreibweise.
- **Prototyp-Prüfungen** (damals als „39" gezählt, tatsächlich 47 — siehe v0.3.1), neu darunter: Tap-Ziele ≥ 32 px, genau eine
  Akzent-Aktion, Navigation mit Text statt nur Symbolen, Bewegungsreduktion.
  Fehlgeschlagene Netzanfragen zählen nicht mehr als Programmfehler, werden
  aber **benannt** — ohne Netz lädt die Schrift nicht.

### P0-Server vollständig
- **35 RPCs** freigegeben, damit ist die in `06-data-model.md` §4
  spezifizierte Oberfläche vollständig. Vier neue Testdateien (08–11),
  insgesamt **11 SQL-Testdateien grün**.
- `search_beers` setzt die Dubletten-Anforderung um: „Peroni" liefert alle
  drei Varianten, Rangfolge exakt → Präfix → Wort → ähnlich, innerhalb eines
  Rangs nach Beliebtheit. `similarity` reichte nicht — „Peronni" gegen
  „Peroni Nastro Azzurro" ergibt 0,26; `word_similarity` ergibt 0,67.
  Derselbe Fall wie beim Orts-Dedupe.
- `get_home` liefert Profil, Passport, nächstes Ziel, Quests, Clan und drei
  Aktivitätszeilen in einem Aufruf. Egress ist das Limit, nicht Rechenzeit.
- **`get_quests` war als STABLE deklariert** — eine solche Funktion darf nicht
  schreiben, und der Quest-Ablauf beim Lesen lief still ins Leere. Jetzt
  VOLATILE, mit der Begründung im Kommentar.
- **`user_discoveries.discovered_at` stand auf der Transaktionszeit** statt
  auf dem Zeitpunkt des Check-ins. Wer einen Besuch von vorgestern nachtrug,
  bekam ihn im Passport an die falsche Stelle. Kommt jetzt aus `happened_at`.
- `delete_check_in` nimmt XP per **Gegenbuchung** zurück, nicht durch Löschen
  der ursprünglichen Buchung — der Ledger bleibt vollständig.
- Sichtbarkeitsregeln geprüft: Ein Fremder sieht Zähler, aber keine
  Bewegungsspur; den Clan-Beitrittscode und die Mitgliederliste sieht nur,
  wer Mitglied ist.
- Invite-Codes ohne I, L, O, U — sie werden diktiert. Ein noch gültiger Code
  wird wiederverwendet, statt fünf in Umlauf zu bringen.

### Prüfungen
- **`verify.sh` unterscheidet jetzt drei Fälle**: kein psql, psql ohne
  Verbindung, und ein echter Fehlschlag. Vorher meldete eine fehlende
  Datenbankverbindung ROT — ein Fehlschlag auf der eigenen Seite ist aber
  keine Auskunft über die Regeln, die geprüft werden sollten.

### Preview
- **Der Artefakt-Link ließ sich nicht öffnen** — derselbe Befund wie in
  Zählora, bei uns schon beim ersten Veröffentlichen. Vermutlich ist ein aus
  einer Remote-Sitzung veröffentlichtes Artefakt an das Konto gebunden.
  Konsequenz: Der Prototyp wird ab sofort **immer als Datei mitgeschickt**,
  und der dauerhafte Weg ist GitHub Pages auf dem Zweig `prototype` — das
  Repository ist öffentlich, diese Adresse braucht keinen Login.
- Zweig `prototype` erstmals gepusht.

### Aus Zählora/PulseMeter übernommen
- **`cancel-in-progress` beim teuren iOS-Auftrag auf `false` korrigiert.** Dort
  hat die umgekehrte Einstellung an einem Tag drei Läufe gekostet — jeden
  abgebrochen kurz vor dem App-Build. Der billige Prototyp-Auftrag bleibt
  abbrechbar.
- **Alle drei CI-Abläufe rufen jetzt dieselben Skripte wie der Entwickler.**
  Zwei Abläufe laufen auseinander, und dann prüft der eine etwas anderes.
- **`scripts/check-tokens.py`** hält die Farben des Prototyps gegen
  `BQDesign/Tokens.swift`. Dieselbe Sache an zwei Orten läuft auseinander —
  bei PulseMeter kostete das zwei Wochen eine öffentlich falsche Preisangabe.
- **`scripts/verify.sh`** nach Kosten sortiert, mit Umfängen, und es **benennt,
  was es überspringt**. Ein Lauf, der schweigt, sieht aus wie ein Lauf, der
  geprüft hat.
- **`scripts/melden.sh` und der Zweig `pruefungen`** verbinden Mac und Cloud,
  die einander nicht sehen. Genau daran lagen bei uns drei Sessions
  ungetesteter Swift-Code übereinander.
- **`.githooks/pre-push`** für die Sekunden-Prüfungen.
- **Skill `release-discipline`** übernommen und angepasst.
- **`docs/18-lessons-adopted.md`** hält fest, was übernommen, angepasst und
  bewusst nicht übernommen wurde — mit Begründung.

## v0.3.0 — P0.3 Serverteil und Engineering-Standard
- Onboarding serverseitig: Altersprüfung, Wortfilter, Erst-Quest,
  Invite-Einlösung. 7 SQL-Testdateien grün.
- Klickbarer Prototyp des Core Loops, 30 Playwright-Prüfungen.
- Erste grüne iOS-CI. Sie fand sofort einen Fehler, der seit P0.1 im Gerüst
  saß: `BQCore.Tab` kollidierte mit `SwiftUI.Tab`.
- Produkt-DNA, Visual Direction, Design System, Monetarisierung als P1.

## v0.2.0 — P0.2 Datenbank-Fundament
- Schema mit 20 Tabellen, Spiel-Logik in `create_check_in`, XP-Ledger mit
  Idempotenz, Bier- und Orts-Dedupe, RLS ohne Schreibrechte für Clients.
- Erster Check-in vom Tages-Cap ausgenommen — der wichtigste Moment der App
  soll nicht mit „XP capped today" enden.

## v0.1.0 — P0.1 Projekt-Setup
- Swift Package mit sieben Modulen, App-Target, Supabase-Grundlage,
  Linux-CI, Keep-alive. Free-Tier-Zahlen live verifiziert.
