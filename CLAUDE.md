# Beer Quest — Arbeitsanweisungen

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
3. **Release-Gates** nach `docs/11-release-gates.md`. Interner TestFlight
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

## Arbeitsweise

- Planungsdokumente in `docs/` sind die Wahrheit. Weicht der Code ab, wird das
  Dokument mit aktualisiert — nicht stillschweigend anders gebaut.
- Deutsche Dokumentation und Commit-Nachrichten, englische UI-Texte,
  englische Bezeichner im Code.
- Entwicklungsbranch: `claude/beer-quest-mvp-spec-dpjh2i`.
- Kein Pull Request ohne ausdrückliche Aufforderung.
