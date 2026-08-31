---
name: handoff
description: Session-Zusammenfassung für den externen Projektmanager (ChatGPT) schreiben. Am Ende JEDER Arbeitssession in diesem Repo anwenden — auch ohne explizite Aufforderung. Aktualisiert docs/HANDOFF.md und gibt dieselbe Zusammenfassung im Chat aus.
---

# Handoff an den Projektmanager

Im Beer-Quest-Projekt arbeitet ein zweiter Assistent (ChatGPT) als
Projektmanager. Er hat **keinen Zugriff auf diesen Chatverlauf**, liest aber
immer das Repository. Alles, was er wissen muss, muss deshalb **im Repo
stehen** — nicht nur im Chat.

## Regel

Am Ende jeder Session mit inhaltlichen Änderungen:

1. **`docs/HANDOFF.md` aktualisieren** — neuer Eintrag **oben** (neueste Session
   zuerst), alte Einträge bleiben als Verlauf stehen.
2. Denselben Text zusätzlich **im Chat ausgeben**, damit er direkt kopierbar ist.
3. Den Handoff **mit committen**, im selben Commit wie die Arbeit.

## Format

```markdown
## Session YYYY-MM-DD — <Kurztitel>

**Auftrag:** <1–2 Sätze, was verlangt war>

**Ergebnis:** <2–4 Sätze, was jetzt existiert>

```
BUILD:   PASS | FAIL | NICHT AUSGEFÜHRT (mit Grund)
TESTS:   PASS | FAIL | TEILWEISE (welche)
PREVIEW: <Link> | ENTFÄLLT (reine Backend-Arbeit)
```

### Entscheidungen
| # | Entscheidung | Begründung | Umkehrbar? |

### Geänderte Dateien
| Datei | Was |

### Offene Punkte für den PM
<Nummerierte Liste. Jeweils: Frage, Empfehlung, wann sie spätestens
beantwortet sein muss.>

### Bewusst NICHT gemacht
<Liste mit Begründung — verhindert Doppelarbeit und Rückfragen.>

### Nächster Schritt
<Genau ein Satz.>

### PM REVIEW NEEDED
<Nur bei UI-/UX-/Game-Flow-Änderungen. Enthält: Link zur Preview · Was soll
ich ausprobieren? · Welche Screens/Flows sind neu? · Welche Entscheidungen
brauchst du von mir? · Was ist bewusst noch Platzhalter? · Welche
Designfragen sind offen? Jeder Bereich mit REAL / PROTOTYPE / PLACEHOLDER
gekennzeichnet.>

### Offene Risiken
<Was könnte später weh tun. Leer lassen ist erlaubt, weglassen nicht.>

### Vorschläge und Themen von mir
<Alles, was ich dem Auftraggeber im Chat vorschlagen oder zu bedenken geben
würde, gehört auch hierher — Ideen, Bedenken, Beobachtungen, mögliche
nächste Schritte, Dinge die mir aufgefallen sind. Der PM soll genau das
sehen, was der Auftraggeber sieht. Nichts nur im Chat lassen.>
```

## Qualitätsregeln

- **Entscheidungen mit Begründung**, nicht nur Ergebnis. Der PM muss
  widersprechen können, ohne den Code zu lesen.
- **Annahmen explizit machen.** Wo etwas ohne Rückfrage entschieden wurde,
  gehört das unter „Offene Punkte", nicht versteckt in den Fließtext.
- **Keine Erfolgsmeldungen ohne Deckung.** Was nicht getestet ist, wird als
  ungetestet benannt. Was übersprungen wurde, steht unter „Bewusst NICHT
  gemacht". `BUILD:` und `TESTS:` sind Pflicht — „nicht ausgeführt" ist eine
  zulässige Angabe, eine unbelegte Erfolgsmeldung nicht.
- **Selbsterklärend.** Keine Verweise auf „wie besprochen" oder auf
  Chat-Kontext. Dateipfade statt „das Dokument von vorhin".
- **Kurz.** Ziel: unter einer Bildschirmseite pro Session, plus Tabellen.
- **Keine Asymmetrie zwischen Chat und Repo.** Was im Chat als Vorschlag,
  Bedenken oder Beobachtung steht, steht auch im Handoff. Der PM liest nur
  das Repo — er darf nie weniger wissen als der Auftraggeber.
