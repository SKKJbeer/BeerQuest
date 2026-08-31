# Beer Quest — Arbeitsanweisungen

> **Sitzung startet kalt? Zuerst `docs/HANDOFF.md`.**
>
> Dort steht der **laufende** Zustand: wo die Arbeit steht, was blockiert, was
> als Nächstes dran ist. Diese Datei hier sagt, *wie* gearbeitet wird; jene
> sagt, *wo es gerade steht*. Die Historie steht in `CHANGELOG.md`.
>
> Der Verweis steht hier, weil ein Dokument, auf das nichts zeigt, nicht
> gelesen und deshalb auch nicht gepflegt wird — teuer gelernt in Zählora.


## Projektkontext

Gamifizierte iOS-Social-App für Bierliebhaber, Nebenprojekt einer Person.
Stand: Planung. Spezifikation in `docs/`, Einstieg über `README.md`.

**Zwei harte Rahmenbedingungen, die jede technische Entscheidung binden:**

1. **0 € laufende Infrastrukturkosten** in P0. Jede Abhängigkeit muss
   entweder Apple-nativ, dauerhaft kostenlos oder in einem ausreichenden
   Free Tier sein. Details und Begründungen: `docs/04-cost-analysis.md`.
   Neue Abhängigkeiten ohne Kostenanalyse werden nicht eingeführt.
2. **P0 ist ein Vertical Slice**, keine Feature-Sammlung. Was nicht zum
   Core Loop gehört, ist P1 oder P2 — siehe `docs/03-feature-matrix.md`.
   Features aus P1/P2 werden nie ungefragt nach P0 gezogen.
3. **Monetarisierung ist P1/P2**, nie P0 — `docs/12-monetization.md`.
   Ads kommen vor Premium. Rewarded Ads dürfen **niemals** an Check-ins
   oder Trinkmenge gekoppelt werden, nur an Quest- und Achievement-
   Aktivität; sonst entsteht über die Hintertür das System, das
   Product Vision §2 verbietet.
4. **Release-Gates** nach `docs/11-release-gates.md`. Interner TestFlight
   darf reduziert sein; vor jeder externen Verteilung müssen Privacy Policy,
   Account-Löschung, Moderation und die Apple-Anforderungen vollständig
   umgesetzt und geprüft sein. Diese Liste wird abgehakt, nicht erinnert.

## Handoff an den Projektmanager — Pflicht in jeder Session

Ein zweiter Assistent (ChatGPT) arbeitet als Projektmanager. Er liest das
Repository, aber **nicht diesen Chat**.

Am Ende jeder Session mit inhaltlichen Änderungen **und nach jeder
abgeschlossenen P0-Phase**: `docs/HANDOFF.md` oben um einen Eintrag ergänzen,
denselben Text im Chat ausgeben, beides im selben Commit. Format und
Qualitätsregeln: `.claude/skills/handoff/SKILL.md`.

**Alles, was im Chat vorgeschlagen oder zu bedenken gegeben wird, gehört
ebenfalls in den Handoff** — Ideen, Bedenken, Beobachtungen, nächste
Schritte. Der Projektmanager liest nur das Repository und darf nie weniger
wissen als der Auftraggeber.

Das gilt auch ohne explizite Aufforderung.

## Das Produktprinzip

Jede Entscheidung gegen diese Frage prüfen:

> **Macht sie Beer Quest mehr zu einem Adventure Game — oder mehr zu einem
> Bier-Tracker?**

Zieht sie Richtung Tracker, kritisch prüfen, ob sie nötig ist. Ziel:
*Discover the world. One beer at a time.* Details, Weltkarte,
Sammelzustände, Daydrinking und die Emoji-Regel: `docs/14-product-dna.md`.

**Keine Emoji als UI-Elemente.** Icons kommen aus `BQIcon`, Farben und
Abstände aus `BQDesign/Tokens.swift` — nie hardcodiert im View
(`docs/15-design-system.md`).

## Engineering-Standard

`docs/16-engineering-standard.md`. Kurzfassung:

- **Feature = Implementierung + Tests + erfolgreicher Build.** Nichts anderes
  gilt als fertig.
- Jede kritische Spielregel braucht einen automatisierten Test. Jeder
  behobene Fehler bekommt einen Regressionstest, der dauerhaft bleibt.
- Vor dem Push `./scripts/verify.sh` ausführen — er ist nach Kosten sortiert
  und **benennt, was er überspringt**. Die CI ist die Gegenprobe, nicht der
  erste Durchgang.
- **Wurde ein Stand schon auf einem Mac geprüft?**
  `git fetch origin pruefungen && git show origin/pruefungen:README.md | tail -5`
- Version, Changelog-Eintrag und Tests je Änderung:
  `.claude/skills/release-discipline/SKILL.md`.
- **UI-Änderungen brauchen eine klickbare Preview** (`docs/17-preview-workflow.md`).
  Ein Bereich pro Runde — nie zehn Screens auf einer unvalidierten Annahme.
  Im Handoff jeden Bereich als REAL / PROTOTYPE / PLACEHOLDER kennzeichnen
  und einen Abschnitt `PM REVIEW NEEDED` ergänzen.
- Commits klein und thematisch, ein Commit pro sinnvollem Schritt.
- Jeder Handoff nennt `BUILD:` und `TESTS:` mit PASS/FAIL/NICHT AUSGEFÜHRT.
- macOS-CI kostet das Zehnfache von Linux — Trigger sparsam halten
  (`16-engineering-standard.md` §3).

## Fehlerklassen, die immer wiederkommen

Aus Zählora übernommen, dort jede mehrfach bezahlt
(`docs/18-lessons-adopted.md`):

1. **„Vorhanden" ist nicht „wirkt", und auch nicht „richtig".** Jedes
   Nachlesen stellt zwei Fragen: Ist es da, und stimmt es?
2. **Ein Fehlschlag auf der eigenen Seite ist keine Auskunft über die
   Gegenseite.** Eine gescheiterte Anfrage darf nie als Aussage über die Welt
   herauskommen.
3. **Zählen ist nicht wissen.** Eine Anzahl steht nie für eine Tatsache.
4. **Wo etwas zweimal steht, steht es früher oder später verschieden.** Ein
   Ort — oder, wo das nicht geht, eine Prüfung, die die Quelle gegen die Kopie
   hält.
5. **Wer nur dort sucht, wo der Fehler auftritt, findet ihn nicht.**
6. **Eine Prüfung, die anschlägt, hat meistens recht — auch gegen den Auftrag.**
7. **Eine Regel, die niemand zählt, wird nicht befolgt.** Wenn eine Regel
   wichtig ist, bekommt sie eine Prüfung.
8. **Eine Regel gilt, solange ihre Ursache steht** — nicht, weil der Schaden
   einmal echt war. Wer sie aufschreibt, schreibt die Ursache dazu.

## Arbeitsweise

- Planungsdokumente in `docs/` sind die Wahrheit. Weicht der Code ab, wird das
  Dokument mit aktualisiert — nicht stillschweigend anders gebaut.
- Deutsche Dokumentation und Commit-Nachrichten, englische UI-Texte,
  englische Bezeichner im Code.
- Entwicklungsbranch: `claude/beer-quest-mvp-spec-dpjh2i`.
- Kein Pull Request ohne ausdrückliche Aufforderung.
