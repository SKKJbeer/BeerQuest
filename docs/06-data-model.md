# Datenmodell, Spielökonomie und API (v0.2 — P0-Schnitt)

> ## Umsetzungsstand P0.2 (2026-08-30)
>
> Das Schema, die Spiel-Logik und die RLS-Policies sind **implementiert und
> gegen eine echte Postgres-Instanz getestet** (`supabase/ci/run_local.sh`).
> Fünf Abweichungen von diesem Dokument, alle bewusst und ohne
> Scope-Ausweitung:
>
> 1. **Ort-Dedupe erweitert.** Die Spezifikation nannte nur
>    `similarity ≥ 0.6`. Damit wäre „Augustiner Keller" vs.
>    „Augustiner Keller München" **nicht** zusammengelegt worden (gemessen:
>    0,68 knapp darüber, aber „Cafe Belge" vs. „Cafe Belge Brussels" nur
>    0,58). Ergänzt um `word_similarity ≥ 0.9` in beide Richtungen, mit
>    Mindestlänge 5 — sonst würde ein Ort namens „Bar" mit jedem
>    „Bar Irgendwas" verschmelzen.
> 2. **`norm_name` ohne `unaccent`.** Die Erweiterung ist nicht überall
>    verfügbar; `pg_trgm` fängt Umlaut-Varianten in der Praxis ab.
> 3. **Landfallback ohne Stadt:** nächstgelegenes Länderzentrum statt
>    Bounding-Box. Grob, aber besser als ein Check-in ohne Land.
> 4. **Quest-Vorlage `beer_and_place` ersetzt** durch `three_beers` —
>    Begründung bei §3.5.
> 5. **Hilfsfunktionen** über die Spezifikation hinaus: `cfg_int`, `cfg_num`,
>    `norm_name`, `geohash7`, `level_for_xp`, `total_xp_to_reach`,
>    `user_metric`, `check_badges`, `next_goal`, `checkin_reward`,
>    `is_friend`, `daily_quest_code`. Alles Implementierung, keine neuen
>    Features.
>
> Nicht implementiert (spätere Phasen): `accept_quest`, `get_home`,
> `get_quests`, alle Freundes-, Invite- und Clan-RPCs, `delete_check_in`,
> Passport- und Leaderboard-Abfragen.

PostgreSQL 15 (Supabase Free). Alle Schreibpfade laufen über
`SECURITY DEFINER`-Funktionen; RLS verweigert direkte Writes.

Jede Tabelle ist mit **P0** oder **P1** markiert. P1-Tabellen werden jetzt
**nicht** angelegt — sie stehen hier, damit erkennbar ist, dass das Modell
sie ohne Umbau aufnimmt.

Änderungen gegenüber v0.1 sind mit **[v0.2]** markiert.

---

## 1. Entity-Überblick (P0)

```
              ┌───────────┐
              │ countries │
              └─────┬─────┘
                    │
              ┌─────▼─────┐        ┌────────┐
              │  cities   │        │ beers  │
              └─────┬─────┘        └────┬───┘
                    │                   │
              ┌─────▼─────┐             │
              │  venues   │             │
              └─────┬─────┘             │
                    └─────────┬─────────┘
                              │
     ┌───────────┐      ┌─────▼──────┐
     │ profiles  │─────<│ check_ins  │
     └─┬──┬──┬───┘      └─────┬──────┘
       │  │  │                │ ein transaktionaler Call
       │  │  │          ┌─────▼──────────────────────────┐
       │  │  │          │ user_discoveries · xp_events   │
       │  │  │          │ quest_participants · user_badges│
       │  │  │          └────────────────────────────────┘
       │  │  └──< friendships · friend_requests · invites
       │  └─────< clan_members >── clans
       └────────< quest_participants >── quests ──> quest_templates
```

**[v0.2] Entfallen in P0:** `user_city_stats`, `user_country_stats`, `blocks`,
`reports`, `invite_redemptions` (aufgegangen in einer Spalte), `breweries`.
Die Passport-Zähler kommen aus `user_discoveries` per `count(*) group by kind` —
bei den erwarteten Datenmengen sind das Millisekunden, und wir sparen zwei
Tabellen samt Pflegelogik.

**Kernunterscheidung (Vision §9):** `beers` = Katalog, `check_ins` = Erlebnis.
Ob etwas „neu" ist, steht ausschließlich in `user_discoveries`.

---

## 2. DDL

> Fachlich gruppiert, nicht in Migrationsreihenfolge. Vorwärtsreferenzen
> (`venues.created_by` → `profiles`) werden in den Migrationen per
> `alter table … add constraint` nachgezogen.

### 2.1 Referenzdaten — **P0**

```sql
create table countries (
  code char(2) primary key, name text not null, flag_emoji text not null,
  lat double precision not null, lon double precision not null
);

create table cities (
  id uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  name text not null, name_norm text not null,
  lat double precision not null, lon double precision not null,
  population integer not null default 0,
  timezone text, geonames_id integer unique,
  created_at timestamptz not null default now()
);
create index cities_geo_idx on cities using gist (ll_to_earth(lat, lon));

create type venue_category as enum
  ('bar','pub','biergarten','brewery','restaurant','shop','festival','other');
create type entity_status as enum ('active','merged','hidden');

create table venues (
  id uuid primary key default gen_random_uuid(),
  city_id uuid references cities(id),
  country_code char(2) not null references countries(code),
  name text not null, name_norm text not null,
  category venue_category not null default 'bar',
  lat double precision not null, lon double precision not null,
  geohash7 text not null,
  status entity_status not null default 'active',
  merged_into uuid references venues(id),
  created_by uuid references profiles(id) on delete set null,
  owner_id uuid,                              -- reserviert (P2, B2B)
  created_at timestamptz not null default now()
);
create index venues_geo_idx  on venues using gist (ll_to_earth(lat, lon));
create index venues_trgm_idx on venues using gin (name_norm gin_trgm_ops);

create table beers (
  id uuid primary key default gen_random_uuid(),
  name text not null, name_norm text not null,
  brewery_name text, brewery_norm text,
  style text, abv numeric(4,2),               -- reserviert (P1)
  country_code char(2) references countries(code),
  status entity_status not null default 'active',
  merged_into uuid references beers(id),
  created_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now()
);
create unique index beers_identity_idx
  on beers (name_norm, coalesce(brewery_norm,'')) where status = 'active';
create index beers_trgm_idx on beers using gin (name_norm gin_trgm_ops);
```

### 2.2 Nutzer — **P0**

```sql
create type user_tier as enum ('free','plus');   -- 'plus' reserviert (P2)

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username citext not null unique,
  display_name text,
  avatar_key text not null default 'mug_01',    -- Bundle-Asset, kein Upload
  avatar_color text not null default 'amber',
  level integer not null default 1,
  xp integer not null default 0,                -- Cache über xp_events
  birth_year smallint not null,                 -- minimiert, kein volles Datum
  country_code char(2) references countries(code),
  tier user_tier not null default 'free',       -- reserviert (P2)
  invited_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index profiles_xp_idx on profiles (xp desc) where deleted_at is null;
```

### 2.3 Check-ins & Discovery — **P0**

```sql
create type verification_level as enum ('none','photo','location'); -- P1/P2

create table check_ins (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete set null,
  client_uuid uuid not null,                    -- Idempotenz
  beer_id uuid not null references beers(id),
  venue_id uuid not null references venues(id),
  city_id uuid references cities(id),           -- denormalisiert
  country_code char(2) not null references countries(code),
  happened_at timestamptz not null default now(),
  local_date date not null,                     -- Tag in der Zeitzone des Nutzers
  verification verification_level not null default 'none',
  created_at timestamptz not null default now()
);
create unique index check_ins_idem_idx on check_ins (user_id, client_uuid);
create index check_ins_user_time_idx on check_ins (user_id, happened_at desc);

create type discovery_kind as enum ('beer','venue','city','country');

create table user_discoveries (
  user_id uuid not null references profiles(id) on delete cascade,
  kind discovery_kind not null,
  entity_id text not null,                      -- uuid oder Ländercode
  first_check_in uuid references check_ins(id) on delete set null,
  discovered_at timestamptz not null default now(),
  primary key (user_id, kind, entity_id)
);
create index user_discoveries_kind_idx on user_discoveries (user_id, kind);
```

**[v0.2]** `note` und `distance_m` entfallen in P0 (Notizfeld → P1,
Positionsabgleich → P1). Der Primärschlüssel von `user_discoveries` verhindert
doppelte XP **strukturell**, nicht durch Anwendungslogik — das ist die
wichtigste Einzelentscheidung im ganzen Modell.

### 2.4 XP-Ledger — **P0**

```sql
create table xp_events (
  id bigserial primary key,
  user_id uuid not null references profiles(id) on delete cascade,
  amount integer not null,
  clan_id uuid references clans(id) on delete set null,
  clan_amount integer not null default 0,
  reason text not null,          -- 'discover_beer','quest_complete','friend', …
  ref_type text, ref_id text,
  season_id uuid,                -- reserviert (P2)
  idem_key text not null unique,
  created_at timestamptz not null default now()
);
create index xp_events_user_time_idx on xp_events (user_id, created_at desc);
create index xp_events_clan_time_idx on xp_events (clan_id, created_at desc);
```

Trigger `after insert` schreibt `profiles.xp`, `profiles.level`, `clans.xp`
und `clan_members.contributed_xp` fort. Der Ledger ist die Wahrheit, die Zähler
sind jederzeit neu berechenbare Caches.

Aus dem Ledger fallen ohne Zusatzaufwand ab: das **Wochen-Leaderboard**
(`where created_at >= date_trunc('week', now())`), Clan-Beiträge, spätere
Seasons und rückwirkende Korrekturen.

### 2.5 Quests — **P0**

```sql
create type quest_kind   as enum ('solo','city','social');   -- city/social = P1
create type quest_status as enum ('active','completed','expired','cancelled');

create table quest_templates (
  code text primary key,
  kind quest_kind not null,
  title text not null, description text not null,
  goal jsonb not null,
  xp_reward integer not null,
  duration_hours integer not null default 72,
  is_daily boolean not null default false,     -- [v0.2] Daily-Quest-Pool
  min_level integer not null default 1,
  active boolean not null default true,
  sort_order integer not null default 0
);

create table quests (
  id uuid primary key default gen_random_uuid(),
  template_code text not null references quest_templates(code),
  kind quest_kind not null,
  owner_id uuid not null references profiles(id) on delete cascade,
  city_id uuid references cities(id),          -- P1 (City Quests)
  title text not null,                          -- Snapshot
  goal jsonb not null,                          -- Snapshot
  xp_reward integer not null,                   -- Snapshot
  status quest_status not null default 'active',
  starts_at timestamptz not null default now(),
  ends_at timestamptz not null,
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index quests_owner_idx on quests (owner_id, status);

create table quest_participants (
  quest_id uuid not null references quests(id) on delete cascade,
  user_id uuid not null references profiles(id) on delete cascade,
  contributed integer not null default 0,
  joined_at timestamptz not null default now(),
  completed_at timestamptz,
  xp_awarded boolean not null default false,
  primary key (quest_id, user_id)
);
```

**Snapshot-Prinzip:** `title`, `goal` und `xp_reward` werden beim Annehmen
kopiert. Balancing-Änderungen berühren laufende Quests nie.

**[v0.2] Daily Quest ohne Scheduler:** Welche Quest heute die Tagesquest ist,
ergibt sich deterministisch aus dem Datum:
`daily_template(d) = pool[ hashtext(d::text) % count(pool) ]` über alle
Templates mit `is_daily = true`. Kein Cron, kein Job, kein Zustand — jeder
Client sieht dieselbe Tagesquest, und sie wechselt um Mitternacht.

### 2.6 Soziales — **P0**

```sql
create table friendships (
  user_low uuid not null references profiles(id) on delete cascade,
  user_high uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_low, user_high),
  check (user_low < user_high)      -- kanonisch geordnet, keine Duplikate
);

create type request_status as enum ('pending','accepted','declined','cancelled');

create table friend_requests (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references profiles(id) on delete cascade,
  to_user   uuid not null references profiles(id) on delete cascade,
  status request_status not null default 'pending',
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (from_user <> to_user)
);
create unique index friend_requests_open_idx
  on friend_requests (from_user, to_user) where status = 'pending';

create type invite_kind as enum ('friend','quest');   -- 'quest' = P1

create table invites (
  code text primary key,                        -- 8× Crockford-Base32
  inviter_id uuid not null references profiles(id) on delete cascade,
  kind invite_kind not null default 'friend',
  quest_id uuid references quests(id) on delete cascade,  -- P1
  expires_at timestamptz not null,
  max_uses integer not null default 25,
  use_count integer not null default 0,
  created_at timestamptz not null default now()
);
```

**[v0.2]** `invite_redemptions` entfällt in P0 — wer einen Code eingelöst hat,
steht bereits in `profiles.invited_by` bzw. ergibt sich aus `friendships`.
`blocks` und `reports` sind **P1 ⚖️** (vor App-Store-Release).

### 2.7 Clans — **P0**

```sql
create table clans (
  id uuid primary key default gen_random_uuid(),
  name citext not null unique,
  avatar_key text not null default 'clan_01',
  avatar_color text not null default 'amber',
  join_code text not null unique,
  description text,                             -- P1
  owner_id uuid not null references profiles(id),
  xp integer not null default 0,
  level integer not null default 1,
  member_count integer not null default 0,
  max_members integer not null default 50,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index clans_xp_idx on clans (xp desc) where deleted_at is null;

create table clan_members (
  user_id uuid primary key references profiles(id) on delete cascade,
  clan_id uuid not null references clans(id) on delete cascade,
  role text not null default 'member',          -- 'owner' | 'member'
  contributed_xp integer not null default 0,
  joined_at timestamptz not null default now()
);
create index clan_members_clan_idx on clan_members (clan_id, contributed_xp desc);
```

`user_id` als Primärschlüssel erzwingt **ein Clan pro Nutzer** auf
Datenbankebene — kein Anwendungscode nötig.

### 2.8 Badges — **P0**

```sql
create table badges (
  code text primary key, name text not null, description text not null,
  tier text not null, icon text not null,
  criteria jsonb not null      -- {"metric":"countries","gte":5}
);
create table user_badges (
  user_id uuid not null references profiles(id) on delete cascade,
  code text not null references badges(code),
  earned_at timestamptz not null default now(),
  primary key (user_id, code)
);
```

### 2.9 Ereignisse — **P0 [v0.2]**

```sql
create table app_events (
  id bigserial primary key,
  user_id uuid references profiles(id) on delete set null,
  name text not null,          -- 'checkin_saved','quest_completed','invite_sent', …
  props jsonb not null default '{}',
  created_at timestamptz not null default now()
);
create index app_events_name_time_idx on app_events (name, created_at desc);
```

Ersetzt ein Analytics-SDK: ~30 Zeilen Client-Code, 0 €, keine zusätzlichen
Privacy-Labels, und die Daten gehören uns. Reicht vollständig für das
Balancing nach dem ersten Test.

### 2.10 Konfiguration — **P0**

```sql
create table app_config (key text primary key, value jsonb not null);
```

Alle XP-Werte, Caps und Faktoren liegen hier. Balancing ohne App-Update.

---

## 3. Spielökonomie

### 3.1 XP-Tabelle (P0)

| Ereignis | XP | Bemerkung |
|---|---|---|
| Neues Bier entdeckt | +50 | einmalig je Bier |
| Neuer Ort entdeckt | +50 | einmalig je Ort |
| Neue Stadt entdeckt | +150 | einmalig je Stadt |
| Neues Land entdeckt | +300 | einmalig je Land |
| Check-in ohne Neuentdeckung | +10 | max. 6/Tag XP-wirksam |
| Quest abgeschlossen | +100 … +300 | aus Template |
| Freundschaft geschlossen | +25 | beide Seiten, einmalig je Freund |
| Eingeladener erreicht Level 2 | +100 | einmalig, Anti-Farming |

**Tages-Cap: 500 XP/Tag aus Check-ins und Entdeckungen.** Quest- und
Sozial-XP sind ausgenommen.

Der Cap ist die technische Umsetzung von Vision §2: Wer an einem Abend zehn
Biere einträgt, kommt nicht weiter als jemand, der drei neue Orte besucht.
Bei Erreichen zeigt die App
*„Nice pace! XP are maxed for today — check-ins still count for your passport."*

### 3.2 Clan-XP

```
clan_amount = round(0.6 × personal_amount)     -- nur bei Clan-Mitgliedschaft
```
Entspricht exakt dem Beispiel aus Vision §17 (500 Personal → 300 Clan).

### 3.3 Level-Kurve

```
xp_needed_for_level(n) = 500 × n            -- Level n → n+1
total_xp_to_reach(n)   = 250 × n × (n − 1)
```
Level 7 → 3.500 XP für den nächsten Aufstieg, identisch zum Beispiel aus
Vision §11. Clan-Level nutzt dieselbe Kurve mit Faktor 8.

### 3.4 Quest-Goal-DSL (P0)

```json
{"type": "discover_beer",  "count": 2}
{"type": "discover_venue", "count": 2}
{"type": "check_in",       "count": 3}
```
`scope` (für City Quests) ist P1. Drei Zieltypen reichen für den gesamten
P0-Katalog.

### 3.5 Quest-Katalog (P0-Seed)

| Code | Ziel | XP | Laufzeit | Daily? |
|---|---|---|---|---|
| `first_beer` | 1 Bier entdecken | 100 | unbegrenzt | – |
| `two_beers` | 2 neue Biere | 200 | 72 h | ✅ |
| `two_venues` | 2 neue Orte | 200 | 72 h | ✅ |
| `three_checkins` | 3 Check-ins | 150 | 72 h | ✅ |
| `three_beers` | 3 neue Biere | 300 | 72 h | ✅ |

> **Korrektur in P0.2:** Ursprünglich stand hier `beer_and_place`
> („1 neues Bier **und** 1 neuer Ort"). Die Goal-DSL kennt keine
> zusammengesetzten Ziele, und sie dafür zu erweitern wäre eine
> Scope-Ausweitung gewesen. Die Vorlage wurde deshalb durch `three_beers`
> ersetzt, das innerhalb der DSL liegt.

Regeln: max. **3 aktive Quests**; `first_beer` wird im Onboarding automatisch
angenommen; Ablauf wird beim Lesen ausgewertet (kein Scheduler); die Tagesquest
wechselt um lokal Mitternacht und ist zusätzlich zu den 3 Slots annehmbar.

### 3.6 Badges (P0)

| Code | Bedingung |
|---|---|
| `first_beer` | 1 Check-in |
| `first_country` | 1 Land entdeckt |
| `first_friend` | 1 Freundschaft |
| `explorer_5_countries` | 5 Länder |

**[v0.2]** Von 8 auf 4 reduziert. Vier Badges reichen, um die Mechanik zu
testen; jedes weitere ist eine Zeile im Seed. Sie speisen zugleich die
„Nächstes Ziel"-Anzeige auf Home.

---

## 4. API (P0)

Alle Aufrufe sind authentifiziert; der Nutzer ergibt sich aus `auth.uid()` und
wird **nie** als Parameter übergeben.

### Account
| Funktion | Zweck |
|---|---|
| `check_username(username)` | Live-Verfügbarkeit im Onboarding |
| `complete_onboarding(username, avatar_key, avatar_color, birth_year, country, invite_code?)` | Profil anlegen, Alter prüfen, Erst-Quest starten, ggf. Code einlösen |
| `get_home()` | **Ein Aggregat-Call:** Profil, XP/Level, aktive Quests + Tagesquest, Passport-Zähler, nächstes Ziel, Clan-Kurzinfo, 3 Aktivitätszeilen |
| `get_profile(user_id?)` | Profil + Stats + Badges |

### Check-in
| Funktion | Zweck |
|---|---|
| `search_beers(query, limit)` | Trigram-Suche |
| `search_venues_nearby(lat, lon, query?, radius_m)` | Orte im Umkreis |
| `create_check_in(client_uuid, beer_ref, venue_ref, lat?, lon?, happened_at, tz)` | **Der zentrale Call.** Legt bei Bedarf Bier/Ort an (mit Dedupe), schreibt den Check-in, ermittelt Entdeckungen, vergibt XP mit Cap, aktualisiert Quests, Clan-XP und Badges — in **einer** Transaktion, und liefert das komplette Reward-Paket zurück. |
| `delete_check_in(id)` | Korrektur < 24 h, XP per Gegenbuchung im Ledger |

`beer_ref`/`venue_ref` sind entweder `{id}` oder `{name, …}`. Ein Call, kein
mehrstufiges Anlegen.

**Antwort von `create_check_in`:**
```json
{
  "check_in_id": "…",
  "xp_awarded": 200, "xp_capped": false,
  "discoveries": [{"kind":"beer","name":"Peroni"},
                  {"kind":"city","name":"Cecina"}],
  "level_before": 6, "level_after": 7,
  "quests": [{"id":"…","title":"Discover 2 new beers",
              "progress":1,"goal":2,"completed":false}],
  "badges": [{"code":"first_country","name":"First Country"}],
  "clan_xp_awarded": 120,
  "next_goal": {"kind":"badge","label":"5 Countries","have":3,"need":5}
}
```
Der Reward-Screen rendert exakt dieses Objekt. Kein Nachladen, keine
Client-Berechnung, kein Zustand, der auseinanderlaufen kann.

### Passport & Karte
`get_passport_summary()`, `get_passport(kind)` (`country|city|venue|beer`),
`get_map_pins(bbox, zoom)`, `get_venue_detail(venue_id)`.

### Quests
`get_quests()` (aktiv + verfügbar + Tagesquest, Ablauf lazy),
`accept_quest(template_code)`, `abandon_quest(quest_id)`.

### Freunde
`search_users(query)`, `send_friend_request(user_id)`,
`respond_friend_request(id, accept)`, `get_friends()`, `get_friend_requests()`,
`remove_friend(user_id)`, `create_invite()`, `redeem_invite(code)`.

### Clan
`create_clan(name, avatar_key, avatar_color)`, `join_clan_by_code(code)`,
`leave_clan()`, `get_clan(clan_id?)`, `get_clan_activity(clan_id, limit)`.

### Leaderboard
`get_leaderboard_friends(range)` — `range` ∈ `week` | `all`.

**[v0.2] Nicht in P0:** alle City-/Country-Detail-Funktionen, Clan- und
City-Leaderboards, Social-Quest-Funktionen, `block_user`, `report`,
`delete_account`, `export_my_data`.

---

## 5. RLS-Grundsätze

```sql
-- Referenzdaten: lesbar für alle Eingeloggten, nie schreibbar
alter table beers enable row level security;
create policy beers_read on beers for select to authenticated using (true);
-- kein insert/update → Writes ausschließlich über SECURITY DEFINER

-- Eigene Check-ins und die von Freunden
create policy check_ins_read on check_ins for select to authenticated
using (
  user_id = auth.uid()
  or exists (select 1 from friendships f
             where f.user_low  = least(auth.uid(), check_ins.user_id)
               and f.user_high = greatest(auth.uid(), check_ins.user_id))
);

-- Clan-interne Daten nur für Mitglieder
create policy clan_members_read on clan_members for select to authenticated
using (clan_id in (select clan_id from clan_members where user_id = auth.uid()));
```

Für **keine** Tabelle existiert eine `insert`- oder `update`-Policy für die
Rolle `authenticated`. Das ist der einfachste und zugleich sicherste Weg — und
der Grund, warum XP nicht manipulierbar sind, ohne dass wir eine eigene
API-Schicht betreiben müssten.

---

## 6. Seed-Daten (P0)

| Datensatz | Umfang | Quelle |
|---|---|---|
| `countries` | 249 | ISO-3166-1 |
| `cities` | ~29.000 (≥ 15.000 Einwohner, ~15 MB) | GeoNames `cities15000`, CC BY 4.0 — Attribution in den App-Credits |
| `beers` | **~60** **[v0.2]** | Manuell: die verbreitetsten Biere in DE/AT/IT/CZ/UK/US |
| `venues` | 0 | entstehen ausschließlich durch Nutzer |
| `quest_templates` | 5 | siehe 3.5 |
| `badges` | 4 | siehe 3.6 |
| `app_config` | ~12 Schlüssel | XP-Werte, Caps, Faktoren |

Der Bier-Seed wurde von 300–500 auf ~60 reduziert: Die Tester legen ihre
eigenen Biere an, und genau diese Eingaben zeigen uns, welchen Katalog wir
wirklich brauchen. Kuratierung auf Verdacht ist Arbeit ohne Erkenntnis.
