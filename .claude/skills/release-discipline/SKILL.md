---
name: release-discipline
description: Version, Changelog-Eintrag und Tests als Pflicht je Änderung. Bei jeder inhaltlichen Änderung in diesem Repo anwenden — auch bei kleinen, auch ohne Aufforderung.
---

# Version, Changelog, Tests — je Änderung

Übernommen aus Zählora/PulseMeter. Der Grund, warum das eine Regel ist und
keine Empfehlung: Ohne sie sammeln sich Änderungen zu Mega-Commits, und wenn
etwas bricht, ist nicht mehr feststellbar, welche davon es war.

## Die drei Pflichten

1. **Version.** Jede Änderung, die am Produkt etwas ändert, bekommt eine
   Versionsnummer nach `docs/16-engineering-standard.md` §5.
2. **Changelog-Eintrag** in `CHANGELOG.md`, neueste oben, **mit Begründung** —
   nicht nur was, sondern warum.
3. **Tests.** Neue Spielregel ⇒ neuer Test. Behobener Fehler ⇒ Regressionstest,
   der dauerhaft bleibt.

## Wo die Version steht — und wo nicht

Die Version steht an **zwei** Orten, und `verify.sh` hält sie gegeneinander:

- `CHANGELOG.md` — die oberste `## vX.Y.Z`-Überschrift
- `project.yml` — `MARKETING_VERSION`

**Eine Git-Marke ist nicht der Träger.** Aus der Cloud-Umgebung lässt sich
kein Tag schieben (`HTTP 403`); die Marken `v0.1.0` bis `v0.3.0` existierten
drei Sessions lang nur lokal und waren am Repository nie zu sehen, während
die Übergabe sie als Zustand meldete. Wer eine Marke setzen will, tut das auf
dem Mac — als Zugabe, nicht als Beleg.

> Ursache, damit die Regel ihre Behebung nicht überlebt: Was nur lokal
> existiert, existiert für den Projektmanager nicht. Er liest das Repository.

## Was nicht den ganzen Weg geht

Eine Änderung, die nur Dokumente, Prüfskripte oder den Prototyp anfasst, endet
im Arbeitszweig. Alles, was am App-Bau etwas ändert — `App/`, `BeerQuestKit/`,
`project.yml` —, geht bis zu einem grünen CI-Lauf.

## Commit-Zuschnitt

Klein und thematisch. **Ein Commit pro sinnvollem Schritt, nicht einer pro
Session.** Schema, dann Funktionen, dann Rechte, dann Seeds — jeweils mit den
zugehörigen Tests.

> Selbstkritik aus diesem Projekt: „P0.2 Datenbank-Fundament" umfasste 8
> Migrationen, 3 Seeds und 5 Tests in einem Commit. Wenn davon etwas bricht,
> hilft `git bisect` nicht weiter.

## Vor dem Push

```bash
./scripts/verify.sh            # alles, was hier möglich ist
./scripts/verify.sh schnell    # Sekunden
```

Erst wenn das grün ist, pushen. **Die CI ist die Gegenprobe auf einem frischen
Rechner, nicht der erste Durchgang.** Wer auf die CI wartet, wartet auf ein
Ergebnis, das er längst haben könnte.

## Nach dem Push

Angefangenes wird zu Ende gebracht, ohne Nachfrage:

- **Grün** → melden, weiterarbeiten.
- **Rot** → Begründung aus dem Protokoll holen, einordnen (Prüf- oder
  Produktfehler), **beheben** und von vorn. Melden, was los war, statt auf eine
  Freigabe zu warten.
- **Noch offen** → nachsehen, aber **nichts** melden. Eine Zwischenmeldung ohne
  Ergebnis ist eine Störung.

Nie mit `sleep` blockieren, nie auf eine Erinnerung warten.
