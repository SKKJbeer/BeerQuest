# Preview-Workflow: klickbare Prototypen

**Verbindlich ab 2026-08-31.** Ergänzt den Engineering-Standard um die Regel:
Ein UI-Feature ist nicht fertig, wenn der PM es nicht selbst anfassen kann.

```
Build small → make it clickable → test → get feedback → improve → expand
```

---

## 1. Das Vorbild

Übernommen aus **PulseMeter/Zählora**, wo derselbe Ablauf bereits trägt:

| Baustein dort | Hier |
|---|---|
| `docs/prototype/index.html` — eine in sich geschlossene Datei, kein Bauwerkzeug | ✅ identisch |
| `scripts/check-prototype.mjs` — Playwright fährt die Hauptflüsse durch | ✅ identisch |
| Erst prüfen, dann veröffentlichen — nur Geprüftes geht online | ✅ identisch |
| Veröffentlichung über einen eigenen Zweig, **ohne ein einziges Geheimnis** | ✅ Zweig `prototype` |

Der letzte Punkt ist der entscheidende: Cloudflare Pages (oder GitHub Pages)
hängt sich an den Zweig und liest ihn aus. Kein Token, keine Konto-ID, nichts,
was in Repository-Einstellungen einzutragen wäre — und die Prüfung behält
trotzdem das letzte Wort, weil der Zweig nur nach bestandener Prüfung entsteht.

---

## 2. Drei Wege zur Preview — bewusst unterschiedlich

| Weg | Wofür | Aufwand für den PM |
|---|---|---|
| **Artefakt-Link** | Sofortiges Feedback innerhalb einer Session. Ein Klick, kein Setup. | keiner |
| **Zweig `prototype`** | Der dauerhafte Stand unter eigener Adresse, wie bei Zählora | einmalig ein Pages-Projekt anlegen |
| **TestFlight** | Alles, was **echtes iOS-Verhalten** braucht: Standort, Karte, Sign in with Apple, Haptik, Kamera | App-Store-Connect-Einrichtung |

**Wir pressen nicht alles in einen Web-Prototyp.** Ein Web-Prototyp beantwortet
die Frage *„Fühlt sich der Flow richtig an?"*. Er beantwortet **nicht**, ob
sich die Karte flüssig anfühlt oder ob die Standortabfrage im richtigen Moment
kommt — dafür braucht es einen echten Build.

### Faustregel

| Frage | Antwort |
|---|---|
| Reihenfolge, Hierarchie, Wortwahl, „verstehe ich, was ich tun soll?" | Web-Prototyp genügt |
| Reward-Moment, Timing, Rhythmus des Flows | Web-Prototyp genügt |
| Karte, Standort, Kamera, Haptik, Systemdialoge, Performance | TestFlight nötig |

---

## 3. Kennzeichnung: REAL / PROTOTYPE / PLACEHOLDER

Im Handoff **und in der Oberfläche selbst** muss jederzeit erkennbar sein, was
tatsächlich funktioniert.

| Stufe | Bedeutung |
|---|---|
| **REAL** | echte Funktionalität, echtes Backend, echte Daten, echte Persistenz |
| **PROTOTYPE** | UI und Flow funktionieren, Daten oder Backend teilweise simuliert |
| **PLACEHOLDER** | nur visuelle Darstellung, noch keine echte Interaktion |

Der Prototyp trägt oben ein dauerhaftes Band „Prototyp · keine echten Daten",
und jeder Platzhalterschirm ist als solcher ausgezeichnet. Das ist keine
Kosmetik: Ein PM, der eine Stunde lang etwas testet, das gar nicht existiert,
verliert eine Stunde und das Vertrauen in alle weiteren Previews.

---

## 4. Wann ein Prototyp Pflicht ist — und wann nicht

**Pflicht** bei relevanten UI-, UX- und Game-Flow-Änderungen.

**Nicht nötig** bei reiner Backend-Arbeit: SQL-Optimierung, RLS-Tests,
Idempotenz, CI/CD-Konfiguration, Migrationen. Dort ist der Testlauf der
Nachweis.

---

## 5. Definition of Done für UI-Aufgaben

Zusätzlich zur allgemeinen Definition of Done (`16-engineering-standard.md` §6):

- [ ] UI implementiert
- [ ] relevante Interaktionen funktionieren
- [ ] Build erfolgreich
- [ ] relevante Tests erfolgreich
- [ ] **Preview vorhanden**
- [ ] **Preview selbst durchgeklickt**
- [ ] bekannte Platzhalter dokumentiert
- [ ] Handoff aktualisiert, inklusive Abschnitt **PM REVIEW NEEDED**

---

## 6. Nicht zu weit vorbauen

> Wenn ein UI-Feature noch nicht durch einen klickbaren Prototyp validiert
> wurde, werden **keine zehn weiteren Screens auf derselben Annahme** gebaut.

Richtig: Home → Feedback → verbessern → dann der nächste Bereich.
Falsch: Home → Passport → Map → Clan → 15 Screens → dann merken, dass die
Grundrichtung nicht trägt.

Praktisch heißt das: **ein Bereich pro Runde.** Der aktuelle Prototyp deckt
bewusst nur den Core Loop ab (Home → Check-in → Reward); Map, Quests, Clan und
Profile sind ehrliche Platzhalter, bis der Core Loop bestätigt ist.

---

## 7. Was geprüft wird

`scripts/check-prototype.mjs` fährt den Prototyp mit einem echten Browser
durch — 30 Prüfungen, darunter:

- Home zeigt Level, XP-Fortschritt, nächstes Ziel und vier Passport-Zähler
- alle fünf Tabs öffnen sich, Platzhalter sind gekennzeichnet
- Check-in in drei Schritten, Suche nach „Peroni" schlägt die Varianten vor
- Stadt und Land stehen automatisch da — sie werden nie abgefragt
- **der erste Check-in gibt volle 550 XP, ungekürzt** (die Produktentscheidung
  aus Session 6 — fällt dieser Test, ist sie im Prototyp verloren)
- alle vier Entdeckungen einzeln aufgeschlüsselt, Level-Up wird gefeiert
- Home zeigt danach die geänderten Zahlen
- kein horizontaler Überlauf, **keine Emoji in der UI**, keine JS-Fehler

Die Emoji-Prüfung ist Absicht: `14-product-dna.md` verbietet Emoji als
UI-Elemente. Eine Regel, die niemand prüft, hält nicht.

---

## 8. Einmalige Einrichtung (0 €)

Für die dauerhafte Adresse — eine der beiden Varianten genügt:

**Cloudflare Pages** (wie bei Zählora)
1. Bereich „Workers & Pages" → Pages-Projekt anlegen
2. An das Repository hängen, **Produktionszweig `prototype`**
3. Fertig — jeder geprüfte Stand geht von selbst online

**GitHub Pages**
1. Settings → Pages → Source: „Deploy from a branch"
2. Branch `prototype`, Ordner `/`
3. Adresse: `https://skkjbeer.github.io/BeerQuest/`

Beides kostenlos. Solange keines von beiden eingerichtet ist, liefert der
Artefakt-Link die Preview.
