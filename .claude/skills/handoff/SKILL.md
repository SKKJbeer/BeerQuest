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
```

## Qualitätsregeln

- **Entscheidungen mit Begründung**, nicht nur Ergebnis. Der PM muss
  widersprechen können, ohne den Code zu lesen.
- **Annahmen explizit machen.** Wo etwas ohne Rückfrage entschieden wurde,
  gehört das unter „Offene Punkte", nicht versteckt in den Fließtext.
- **Keine Erfolgsmeldungen ohne Deckung.** Was nicht getestet ist, wird als
  ungetestet benannt. Was übersprungen wurde, steht unter „Bewusst NICHT
  gemacht".
- **Selbsterklärend.** Keine Verweise auf „wie besprochen" oder auf
  Chat-Kontext. Dateipfade statt „das Dokument von vorhin".
- **Kurz.** Ziel: unter einer Bildschirmseite pro Session, plus Tabellen.
