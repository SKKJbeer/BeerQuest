# Changelog

Jede Änderung mit Begründung, neueste oben. Der **laufende Zustand** steht
dagegen in `docs/HANDOFF.md` — diese Datei ist die Historie, jene die Auskunft.

Versionsschema: `docs/16-engineering-standard.md` §5.

---

## Unveröffentlicht

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
