# Changelog

Jede Änderung mit Begründung, neueste oben. Der **laufende Zustand** steht
dagegen in `docs/HANDOFF.md` — diese Datei ist die Historie, jene die Auskunft.

Versionsschema: `docs/16-engineering-standard.md` §5.

---

## Unveröffentlicht

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
