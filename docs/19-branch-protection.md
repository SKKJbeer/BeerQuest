# 19 — Branch-Schutz für `main`

> Status: **vorbereitet, nicht aktiviert.** Das Aktivieren braucht Admin-
> Rechte am Repository und geht nur über die GitHub-Oberfläche oder ein
> Admin-Token. Diese Sitzung hat beides nicht. Was hier steht, ist genau
> abgehakt einzugeben — nicht zu erinnern.

## Warum das jetzt und nicht später

Ein Schutz, der erst kommt, wenn schon jemand direkt auf `main` geschoben
hat, schützt nichts mehr. Und ein Schutz, der die falschen Prüfungen
verlangt, blockiert jeden Pull Request auf ewig — siehe „Die Falle" unten.

## Die Falle, die vorher entschärft wurde

GitHub meldet für einen Arbeitsablauf, der wegen eines **Pfadfilters** gar
nicht startet, **keinen Status** — nicht „bestanden", sondern gar nichts.
Steht dieser Ablauf als „required status check" im Branch-Schutz, bleibt er
auf ewig ausstehend. Ein Pull Request, der nur Dokumentation ändert, ließe
sich dann nie zusammenführen, und niemand sieht auf Anhieb, warum.

Deshalb haben alle drei Abläufe seit v0.3.1 **keinen Pfadfilter mehr beim
`pull_request`**. Beim `push` bleibt er — dort kommen die meisten Läufe her,
und dort geht es um Kosten, nicht um das Zusammenführen.

Ein Auftrag, der innerhalb eines gestarteten Ablaufs per `if:` übersprungen
wird, gilt dagegen als bestanden. Der Unterschied ist: **Ablauf gar nicht
gestartet = blockiert. Auftrag übersprungen = grün.**

## Einzugebende Einstellung

`Settings → Branches → Add branch ruleset` (oder klassisch
`Add rule` für `main`):

| Einstellung | Wert | Grund |
|---|---|---|
| Branch name pattern | `main` | |
| Require a pull request before merging | ✅ | Kein direkter Schub auf `main` |
| — Required approvals | `0` | Einzelperson; ein Selbst-Review wäre eine Formalie ohne Wert |
| Require status checks to pass | ✅ | |
| — Require branches to be up to date | ✅ | Sonst prüft die CI einen Stand, den es nach dem Zusammenführen nicht gibt |
| Do not allow bypassing | ❌ (aus) | Bei einer Einzelperson wäre eine Sperre ohne Notausgang ein Selbstschuss |
| Allow force pushes | ❌ | |
| Allow deletions | ❌ | |

### Die drei verlangten Prüfungen

Als „required status checks" **exakt** diese Namen eintragen. Es sind die
Namen der Aufträge, nicht der Abläufe:

```
build                            (aus: iOS build & tests)
sql                              (aus: SQL tests)
pruefen-und-veroeffentlichen     (aus: Prototyp veröffentlichen)
```

GitHub bietet nur Namen zur Auswahl an, die es **schon einmal gesehen** hat.
Sind sie nicht in der Liste, zuerst einen Pull Request öffnen, die Abläufe
einmal laufen lassen, danach eintragen.

## Prüfung, dass der Schutz wirkt

Er wirkt erst, wenn er einmal etwas verhindert hat:

1. Zweig anlegen, in `BeerQuestKit/Sources/BQCore/Progression.swift` eine
   Konstante absichtlich falsch setzen (z. B. Tages-Cap auf 5000).
2. Pull Request öffnen. Erwartung: `build` wird rot — `ProgressionTests`
   hält den Cap gegen Product Vision §2.
3. Erwartung: Der Zusammenführen-Knopf ist gesperrt.
4. Zweig verwerfen.

Bis dieser Durchgang einmal gelaufen ist, gilt der Schutz als
**behauptet, nicht belegt**.

## Offene Vorbedingung

`main` enthält derzeit nur „Initial commit". Die gesamte Arbeit liegt auf
`claude/beer-quest-mvp-spec-dpjh2i`. Ein Schutz auf einem leeren `main`
schützt nichts. Die Entscheidung, wann der Arbeitszweig nach `main`
zusammengeführt wird, liegt beim Auftraggeber — siehe `docs/HANDOFF.md`,
Abschnitt „RISKS / PM DECISIONS NEEDED".
