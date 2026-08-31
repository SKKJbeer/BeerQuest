# Übernommen aus Zählora/PulseMeter

Gelesen am 2026-08-31: `docs/06-uebergabe.md`, `CLAUDE.md` und
`.claude/skills/projekt-baukasten/SKILL.md` aus `SKKJbeer/PulseMeter`.
Was dort steht, ist an einem echten Produkt bezahlt worden. Dieses Dokument
hält fest, **was wir übernommen haben, was wir angepasst haben, und was wir
bewusst nicht übernehmen** — mit Begründung, damit niemand es später
versehentlich „nachbessert".

Der Kernsatz, an dem sich alles ausrichtet:

> **Eine Regel, die aus einem Schaden entstand, gilt nicht weiter, weil der
> Schaden einmal echt war. Sie gilt, solange die Ursache steht. Wer sie
> aufschreibt, schreibt die Ursache dazu — sonst überlebt sie ihre Behebung.**

---

## 1. Sofort korrigiert — wir haben denselben Fehler gemacht

### `cancel-in-progress` stand beim teuren Auftrag auf `true`

Dort hat genau das an **einem einzigen Tag drei Läufe gekostet** — jeden
abgebrochen kurz vor dem App-Build, also nach der teuersten Minute und ohne je
ein Ergebnis.

Unser `ios-build.yml` hatte dieselbe Einstellung. **Korrigiert:** Der teure
macOS-Auftrag steht jetzt auf `cancel-in-progress: false` und reiht sich an.
Der billige Prototyp-Auftrag darf weiter abgebrochen werden — er läuft gleich
wieder.

Beachtenswert ist dabei die *zweite* Hälfte ihrer Lehre: Aus dem Schaden war
bei ihnen die Regel „nie pushen, solange ein Lauf läuft" geworden. Behoben war
das längst, die Regel blieb stehen und kostete danach nur noch Wartezeit.
Deshalb steht bei uns die **Ursache** im Kommentar über der Einstellung.

### Drei CI-Abläufe prüften anderes als der Entwickler

„Ein Befehl prüft alles, und es ist **dasselbe** Skript wie in der
CI-Beschreibung. Zwei Abläufe laufen auseinander."

Bei uns hatten `sql-tests.yml` und `ios-build.yml` ihre Schritte selbst
ausformuliert. **Korrigiert:** Beide rufen jetzt dasselbe Skript auf, das auch
lokal läuft.

### Die Tokens standen an zwei Orten, ungeprüft

Ihre teuerste Instanz dieses Musters: Ein Kaufpreis stand im Quelltext und auf
zwei Seiten der Website. Der Preis sank, die Preisseite zog mit, die Hilfeseite
nicht — und bot das Feature **zwei Wochen lang öffentlich als kostenlos an**.

> Wo etwas zweimal steht, steht es früher oder später verschieden.

Unsere Farben stehen in `BQDesign/Tokens.swift` **und** in
`docs/prototype/index.html`. Ein Ort wäre besser; den gibt es nicht, Swift
liest kein CSS. Also die zweitbeste Bauart, die sie beschreiben: eine Prüfung,
die die Quelle liest und den anderen Ort dagegenhält.

**Neu:** `scripts/check-tokens.py` — 14 Tokens, läuft in einer Sekunde, ist
Teil jedes Laufs.

---

## 2. Übernommen

### Der Zweig `pruefungen` — zwei Orte, die einander nicht sehen

Das ist die wertvollste Einzelübernahme. Ihr Problem ist wörtlich unseres:
Der Mac des Gründers und die Cloud-Sitzung sehen einander nicht. Eine
Cloud-Sitzung kann keinen Xcode-Build ausführen und erfährt sonst nie, ob einer
gelaufen ist.

**Bei uns hat genau das drei Sessions lang ungetesteten Swift-Code
aufeinandergestapelt** — bis die CI beim ersten Lauf sofort einen Fehler fand,
der seit P0.1 im Gerüst saß.

Verbunden werden die Orte über git:

```bash
git fetch origin pruefungen && git show origin/pruefungen:README.md | tail -5
```

Eine Zeile je Lauf: Zeitpunkt, Stand, Ergebnis, Umfang, Dauer, Rechner, und
**was übersprungen wurde**. Geschrieben von `scripts/melden.sh`, ausgelöst
durch `./scripts/verify.sh --melden`.

### Ein Befehl, nach Kosten sortiert, der Übersprungenes benennt

`scripts/verify.sh` ist nach ihrem Vorbild umgebaut:

- **Nach Kosten sortiert, nicht nach Wichtigkeit.** Token-Abgleich und
  Prototyp brauchen zusammen drei Sekunden; der Xcode-Build steht zuletzt.
  Was in einer Sekunde brechen kann, soll auch in einer Sekunde brechen.
- **Übersprungenes wird benannt.** Ein Lauf, der schweigt, sieht aus wie ein
  Lauf, der geprüft hat. Am Ende steht eine Liste „Nicht geprüft".
- **Umfänge:** `schnell`, `sql`, `ios`, alles.
- Am Ende gibt er die Zeilen aus, die in den Handoff gehören.

### Haken vor dem Push

`.githooks/pre-push` fährt die Sekunden-Prüfungen. Einmalig aktivieren:
`git config core.hooksPath .githooks`.

### Der Prototyp ist Pflicht, nicht Kür

Ihre Regel 1: *„Keine Produktänderung wird nur beschrieben. Wenn sie nicht
anklickbar ist, ist sie nicht fertig."* Das hatten wir bereits in
`17-preview-workflow.md` — jetzt mit ihrer Begründung untermauert: Bei ihnen
hat **jede Runde am Prototyp einen echten Fehler im Rechenkern aufgedeckt, den
kein ausgedachter Unit-Test gefunden hätte.**

### Die Fehlerklassen als Prüffragen

Aufgenommen in `CLAUDE.md`, weil sie bei jeder Recherche gelten:

| Regel | Ihr Anlass |
|---|---|
| **„Vorhanden" ist nicht „wirkt".** Jedes Nachlesen stellt zwei Fragen: Ist es da, und wirkt es? | Fünf Käufe standen in der Liste, keiner wurde ausgeliefert |
| **„Vorhanden" ist auch nicht „richtig".** | „Bau hängt dran" hieß nicht „der richtige Bau hängt dran" |
| **Ein Fehlschlag auf der eigenen Seite ist keine Auskunft über die Gegenseite.** | „In 0 Ländern verkäuflich" war eine 400er-Antwort auf einen Filter, den es nicht gibt |
| **Zählen ist nicht wissen.** | Dreimal in einer Woche stand eine Anzahl für eine Tatsache |
| **Eine Prüfung, die anschlägt, hat meistens recht — auch gegen den Auftrag.** | — |
| **Wer nur dort sucht, wo der Fehler auftritt, findet ihn nicht.** | Drei Tage Suche, während ein `try?` die Antwort verdeckte |

Die letzte hatten wir gerade selbst: Der fehlgeschlagene Prototyp-Test
(„Level wird angezeigt") war nicht der Fehler — der Fehler war ein
inkonsistenter Startzustand eine Ebene darüber.

### Version, Changelog und Tests je Änderung

Skill `release-discipline` übernommen und auf Beer Quest angepasst.

---

## 3. Angepasst

### `docs/HANDOFF.md` wird geteilt — gegen unsere eigene frühere Regel

Ihre Warnung ist eindeutig:

> Sie wird bei jeder Übergabe **überschrieben**, nicht fortgeschrieben — eine
> Übergabedatei, die wächst, ist nach dem dritten Mal ein Archiv und keine
> Auskunft mehr.

**Unsere `HANDOFF.md` ist bei zehn Sessions angekommen.** Genau der beschriebene
Zustand. Ein PM, der wissen will, wo es steht, liest sich durch zehn Einträge,
von denen neun überholt sind.

Gleichzeitig hat der PM ausdrücklich verlangt: „neueste Session oben, alte
bleiben als Verlauf". Beides lässt sich erfüllen, aber nicht in einer Datei:

| Datei | Inhalt | Verhalten |
|---|---|---|
| **`docs/HANDOFF.md`** | Der **laufende Zustand**: wo die Arbeit steht, was blockiert, was als Nächstes dran ist, BUILD/TESTS/PREVIEW, PM REVIEW NEEDED | wird **überschrieben** |
| **`CHANGELOG.md`** | Jede Änderung mit Begründung | wächst, neueste oben |

Der Verlauf geht damit nicht verloren — er wandert dorthin, wo er hingehört.
**Das ist eine Abweichung von einer PM-Vorgabe und braucht seine Zustimmung.**
Bis dahin bleibt die alte Datei vollständig erhalten.

### Sprachregeln: sinngemäß, nicht wörtlich

Zählora spricht Deutsch mit dem Nutzer, Beer Quest spricht Englisch. Die
konkreten Wortlisten sind deshalb nicht übertragbar — die **Haltung** schon:

- Nicht „ermöglicht", „bietet", „verfügt über" → „macht", „zeigt", „rechnet"
- Keine Dreierketten („Verbrauch. Kosten. Kontrolle.")
- Keine Werbewörter: smart, seamless, effortless, discover, experience
- Nicht jeder Satz begründet sich selbst mit einem Gedankenstrich
- Konkrete Dinge tragen den Text, nicht Adjektive

Und ihr härtester Befund dazu: **„Eine Regel, die niemand zählt, wird nicht
befolgt."** Die Gedankenstrich-Regel stand wochenlang da — die Website hatte
trotzdem 25 auf 1150 Wörter. Behoben wurde es erst durch einen Zähler in der
Prüfung.

Wir haben denselben Mechanismus bereits bei den Emoji: `check-prototype.mjs`
zählt sie im gerenderten DOM. Sobald englische UI-Texte entstehen, kommt eine
Ton-Prüfung dazu.

### „Selbstsprechend"

Ihr Prinzip: *Wenn ein Text erklären muss, was daneben steht, stimmt die
Beschriftung nicht. Erst die Beschriftung richtig machen, dann den Text
streichen.* Gilt unverändert, unabhängig von der Sprache — aufgenommen in
`14-product-dna.md`.

---

## 4. Bewusst nicht übernommen

| Was | Warum nicht |
|---|---|
| **Jede Veröffentlichung ein neues Artifact** | Bei ihnen ließ sich ein erneutes Veröffentlichen auf denselben Pfad nicht öffnen. Bei uns hat es funktioniert. **Wenn du beim nächsten Mal eine Anmeldemaske siehst, sag Bescheid** — dann übernehmen wir ihr Verfahren sofort. |
| **GitHub Pages scheidet aus (privates Repo)** | Ihr Repo ist privat, unseres öffentlich. Für uns ist Pages eine gültige Option. |
| Der Zweig `screenshots` | Wir haben noch keine Screenshots — es gibt keine Screens. Kommt mit P0.3-UI. |
| `check-strings.py`, `check-namen.py`, `check-trefferflaechen.py`, `check-aktualisierung.py` | Setzen SwiftUI-Views bzw. Python-Skripte voraus, die wir noch nicht haben. **Vorgemerkt für P0.3** — dann sind sie sofort wertvoll. |
| `check-versprechen.py` | Wir haben noch keine Verkaufsseite. Sobald es eine gibt, ist das die erste Prüfung, die dazukommt: Bei ihnen waren von dreißig Zusagen drei falsch — bei grüner Prüfsuite. |
| Skill `selbstsprechend` als Datei | Das Prinzip ist übernommen, die deutschen Beispiele passen nicht. |
| Skill `xcode-workflow` | Setzt einen Mac voraus. Übernehmen, sobald lokal auf einem Mac gearbeitet wird. |
| TestFlight-Automatik, App Store Connect über die Schnittstelle | Wir sind in P0.2/P0.3, nicht vor einem Release. Der Baukasten §4 und §5 ist die Anleitung, wenn es so weit ist — dann ungelesen zu starten wäre Verschwendung. |

---

## 5. Was ich mir für später notiert habe

Aus dem Baukasten, noch nicht relevant, aber teuer bezahlt und deshalb hier
festgehalten, damit es zum richtigen Zeitpunkt gefunden wird:

- **Jedes Store-Feld hat eine Zeichengrenze, und Apple prüft sie zuletzt** —
  eine Beschreibung mit 4152 von 4000 Zeichen fiel erst am Ende einer
  Einreichung auf.
- **Ein Zeitplan bei GitHub ist keine Zusage.** Ein `schedule`-Ablauf feuerte
  an einem Nachmittag einmal statt sechsmal. Betrifft direkt unseren
  **Keep-alive** — falls das Supabase-Projekt trotz Workflow pausiert, ist das
  die erste Vermutung, nicht die letzte.
- **Ein Schritt, der nur mit Apple spricht, darf nicht an einem Bau hängen.**
- **Nie nach einem Feld sortieren, das bei den Gesuchten leer ist.**
- **Eine vollständige Liste beweist nur, dass alle Punkte darauf abgehakt
  sind** — nicht, dass die Liste vollständig war.
