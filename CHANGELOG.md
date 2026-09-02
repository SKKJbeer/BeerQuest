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
