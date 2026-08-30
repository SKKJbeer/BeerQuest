# SQL-Tests

Hier liegen die Tests fuer die Spielregeln: Discovery-Eindeutigkeit,
XP-Cap, Idempotenz, Level-Kurve, ein-Clan-pro-Nutzer.

Sie laufen in der CI auf einem Linux-Runner gegen ein frisches Postgres 15
(kostenlos, siehe `docs/04-cost-analysis.md` §1). Jede Datei ist reines SQL
und schlaegt fehl, wenn eine Regel verletzt ist.

Konvention: `NN_thema.sql`, aufsteigend nummeriert. Eine Datei bricht mit
`raise exception` ab, wenn eine Erwartung nicht erfuellt ist.

**Offen fuer P0.2:** Das Schema referenziert `auth.users`, das es in einem
nackten Postgres nicht gibt. Vor den Migrationen muss die CI deshalb ein
minimales `auth`-Schema anlegen (nur `auth.users(id uuid primary key)` und
eine `auth.uid()`-Stub-Funktion). Das wird mit dem Schema in P0.2 ergaenzt.
