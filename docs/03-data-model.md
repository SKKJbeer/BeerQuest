# STEP 2b — Datenmodell, Spielökonomie und API

Zielsystem: PostgreSQL 15 (Supabase). Alle Schreibpfade laufen über
`SECURITY DEFINER`-Funktionen; RLS verweigert direkte Writes.

---

## 1. Entity-Überblick

```
                 ┌───────────┐
                 │ countries │ (ISO-3166-1 alpha-2)
                 └─────┬─────┘
                       │ 1:n
                 ┌─────▼─────┐        ┌────────┐
                 │  cities   │        │ beers  │
                 └─────┬─────┘        └────┬───┘
                       │ 1:n               │
                 ┌─────▼─────┐             │
                 │  venues   │             │
                 └─────┬─────┘             │
                       │                   │
                       └────────┬──────────┘
                                │ n:1 je Check-in
        ┌───────────┐     ┌─────▼──────┐
        │ profiles  │────<│ check_ins  │
        └─┬───┬───┬─┘     └─────┬──────┘
          │   │   │             │ löst aus
          │   │   │       ┌─────▼───────────────────────────┐
          │   │   │       │ user_discoveries · xp_events ·  │
          │   │   │       │ quest_progress · user_city_stats│
          │   │   │       │ user_badges                     │
          │   │   │       └─────────────────────────────────┘
          │   │   └──< friendships / friend_requests / blocks / invites
          │   └──────< clan_members >── clans
          └──────────< quest_participants >── quests ──> quest_templates
```

**Kernunterscheidung (§9):** `beers` = Katalog-Entität, `check_ins` = einzelnes
Erlebnis. Ob etwas "neu" ist, steht in `user_discoveries` — nicht in `check_ins`.

---

## 2. DDL (MVP-Stand)

> Die Tabellen sind hier **fachlich** gruppiert, nicht in Migrationsreihenfolge.
> Einige Blöcke enthalten daher Vorwärtsreferenzen (`venues.created_by` →
> `profiles`, `xp_events.clan_id` → `clans`). In den tatsächlichen Migrationen
> werden diese Fremdschlüssel entweder in der richtigen Reihenfolge oder
> nachträglich per `alter table … add constraint` angelegt.

### 2.1 Referenzdaten

```sql
create table countries (
  code        char(2) primary key,          -- 'DE'
  name        text not null,
  flag_emoji  text not null,
  lat         double precision not null,    -- Zentroid für Kartenpins
  lon         double precision not null
);

create table cities (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references countries(code),
  name         text not null,
  name_norm    text not null,               -- lower, unaccent
  lat          double precision not null,
  lon          double precision not null,
  population   integer not null default 0,
  timezone     text,
  geonames_id  integer unique,
  created_at   timestamptz not null default now()
);
create index cities_geo_idx on cities using gist (ll_to_earth(lat, lon));
create index cities_norm_idx on cities (country_code, name_norm);

create type venue_category as enum ('bar','pub','biergarten','brewery',
                                    'restaurant','shop','festival','other');
create type entity_status  as enum ('active','merged','hidden');

create table venues (
  id           uuid primary key default gen_random_uuid(),
  city_id      uuid references cities(id),
  country_code char(2) not null references countries(code),
  name         text not null,
  name_norm    text not null,
  category     venue_category not null default 'bar',
  lat          double precision not null,
  lon          double precision not null,
  geohash7     text not null,
  status       entity_status not null default 'active',
  merged_into  uuid references venues(id),
  created_by   uuid references profiles(id) on delete set null,
  owner_id     uuid,                        -- reserviert für B2B (V3)
  created_at   timestamptz not null default now()
);
create index venues_geo_idx  on venues using gist (ll_to_earth(lat, lon));
create index venues_trgm_idx on venues using gin (name_norm gin_trgm_ops);
create index venues_city_idx on venues (city_id) where status = 'active';

create table beers (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  name_norm      text not null,
  brewery_name   text,
  brewery_norm   text,
  style          text,                      -- MVP: ungenutzt, nullable
  abv            numeric(4,2),              -- MVP: ungenutzt, nullable
  country_code   char(2) references countries(code),
  status         entity_status not null default 'active',
  merged_into    uuid references beers(id),
  created_by     uuid references profiles(id) on delete set null,
  created_at     timestamptz not null default now()
);
create unique index beers_identity_idx
  on beers (name_norm, coalesce(brewery_norm,'')) where status = 'active';
create index beers_trgm_idx on beers using gin (name_norm gin_trgm_ops);
```

### 2.2 Nutzer

```sql
create type user_tier as enum ('free','plus');   -- 'plus' reserviert (V?)

create table profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  username      citext not null unique,
  display_name  text,
  avatar_key    text not null default 'mug_01',  -- kuratierte Auswahl (D4)
  avatar_color  text not null default 'amber',
  level         integer not null default 1,
  xp            integer not null default 0,      -- Cache über xp_events
  birth_year    smallint not null,               -- Age Gate, minimiert
  age_verified_at timestamptz not null,
  country_code  char(2) references countries(code),
  tier          user_tier not null default 'free',
  invited_by    uuid references profiles(id) on delete set null,
  created_at    timestamptz not null default now(),
  deleted_at    timestamptz
);
create index profiles_xp_idx on profiles (xp desc) where deleted_at is null;
```

### 2.3 Check-ins & Discovery

```sql
create type verification_level as enum ('none','photo','location'); -- V1.1

create table check_ins (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references profiles(id) on delete set null,
  client_uuid   uuid not null,                 -- Idempotenz (R5)
  beer_id       uuid not null references beers(id),
  venue_id      uuid not null references venues(id),
  city_id       uuid references cities(id),    -- denormalisiert, historisch stabil
  country_code  char(2) not null references countries(code),
  happened_at   timestamptz not null default now(),
  local_date    date not null,                 -- Tag in der Zeitzone des Nutzers
  note          text,
  distance_m    integer,                       -- Geräteposition ↔ Venue, Anti-Cheat
  verification  verification_level not null default 'none',
  created_at    timestamptz not null default now()
);
create unique index check_ins_idem_idx on check_ins (user_id, client_uuid);
create index check_ins_user_time_idx on check_ins (user_id, happened_at desc);
create index check_ins_city_idx on check_ins (city_id, user_id);

create type discovery_kind as enum ('beer','venue','city','country');

create table user_discoveries (
  user_id       uuid not null references profiles(id) on delete cascade,
  kind          discovery_kind not null,
  entity_id     text not null,                 -- uuid oder Ländercode als Text
  first_check_in uuid references check_ins(id) on delete set null,
  city_id       uuid references cities(id),
  country_code  char(2),
  discovered_at timestamptz not null default now(),
  primary key (user_id, kind, entity_id)
);
```

`user_discoveries` ist die einzige Quelle für "neu?" und speist Passport,
Karte, Badges und Quest-Fortschritt. Ein Unique-PK verhindert doppelte XP
strukturell — nicht durch Anwendungslogik.

### 2.4 XP-Ledger

```sql
create table xp_events (
  id           bigserial primary key,
  user_id      uuid not null references profiles(id) on delete cascade,
  amount       integer not null,
  clan_id      uuid references clans(id) on delete set null,
  clan_amount  integer not null default 0,
  reason       text not null,      -- 'discover_beer','quest_complete', ...
  ref_type     text,
  ref_id       text,
  season_id    uuid,               -- reserviert (V2)
  idem_key     text not null unique,
  created_at   timestamptz not null default now()
);
create index xp_events_user_time_idx on xp_events (user_id, created_at desc);
create index xp_events_clan_time_idx on xp_events (clan_id, created_at desc);
```

Trigger `after insert` erhöht `profiles.xp`, berechnet `profiles.level` neu und
schreibt `clans.xp` / `clan_members.contributed_xp` fort. Der Ledger bleibt die
Wahrheit; die Zähler sind Caches und jederzeit neu berechenbar.

### 2.5 Statistiken (für City/Country Progress und City-Leaderboard)

```sql
create table user_city_stats (
  user_id    uuid not null references profiles(id) on delete cascade,
  city_id    uuid not null references cities(id),
  xp         integer not null default 0,
  beers      integer not null default 0,
  venues     integer not null default 0,
  check_ins  integer not null default 0,
  quests     integer not null default 0,
  level      integer not null default 1,
  updated_at timestamptz not null default now(),
  primary key (user_id, city_id)
);
create index user_city_stats_lb_idx on user_city_stats (city_id, xp desc);

create table user_country_stats (
  user_id      uuid not null references profiles(id) on delete cascade,
  country_code char(2) not null references countries(code),
  xp integer not null default 0, cities integer not null default 0,
  venues integer not null default 0, beers integer not null default 0,
  primary key (user_id, country_code)
);
```

Inkrementell im selben Transaktionsschritt wie der Check-in gepflegt. Damit
sind City Progress (§20), Country Progress (§21) und City-Leaderboard (§19)
O(1)-Abfragen ohne Materialized Views.

### 2.6 Soziales

```sql
create table friendships (
  user_low   uuid not null references profiles(id) on delete cascade,
  user_high  uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_low, user_high),
  check (user_low < user_high)          -- kanonisch, keine Duplikate
);

create type request_status as enum ('pending','accepted','declined','cancelled');

create table friend_requests (
  id           uuid primary key default gen_random_uuid(),
  from_user    uuid not null references profiles(id) on delete cascade,
  to_user      uuid not null references profiles(id) on delete cascade,
  status       request_status not null default 'pending',
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  check (from_user <> to_user)
);
create unique index friend_requests_open_idx
  on friend_requests (from_user, to_user) where status = 'pending';

create table blocks (
  blocker_id uuid not null references profiles(id) on delete cascade,
  blocked_id uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id)
);

create table reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid references profiles(id) on delete set null,
  target_type text not null,               -- 'profile','clan','venue','beer'
  target_id   text not null,
  reason      text not null,
  note        text,
  status      text not null default 'open',
  created_at  timestamptz not null default now()
);

create type invite_kind as enum ('friend','quest');

create table invites (
  code       text primary key,              -- 8 Zeichen Crockford-Base32
  inviter_id uuid not null references profiles(id) on delete cascade,
  kind       invite_kind not null,
  quest_id   uuid references quests(id) on delete cascade,
  expires_at timestamptz not null,
  max_uses   integer not null default 25,
  use_count  integer not null default 0,
  created_at timestamptz not null default now()
);

create table invite_redemptions (
  code       text not null references invites(code) on delete cascade,
  user_id    uuid not null references profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (code, user_id)
);
```

### 2.7 Quests

```sql
create type quest_kind   as enum ('solo','city','social');
create type quest_status as enum ('active','completed','expired','cancelled');

create table quest_templates (
  code          text primary key,          -- 'solo_two_beers'
  kind          quest_kind not null,
  title         text not null,
  description   text not null,
  goal          jsonb not null,            -- siehe Goal-DSL
  xp_reward     integer not null,
  duration_hours integer not null default 72,
  min_level     integer not null default 1,
  requires_friends boolean not null default false,
  active        boolean not null default true,
  sort_order    integer not null default 0
);

create table quests (
  id            uuid primary key default gen_random_uuid(),
  template_code text not null references quest_templates(code),
  kind          quest_kind not null,
  owner_id      uuid not null references profiles(id) on delete cascade,
  city_id       uuid references cities(id),     -- Pflicht bei kind='city'
  title         text not null,                  -- Snapshot
  goal          jsonb not null,                 -- Snapshot
  xp_reward     integer not null,               -- Snapshot
  status        quest_status not null default 'active',
  starts_at     timestamptz not null default now(),
  ends_at       timestamptz not null,
  completed_at  timestamptz,
  created_at    timestamptz not null default now()
);
create index quests_owner_idx on quests (owner_id, status);

create table quest_participants (
  quest_id     uuid not null references quests(id) on delete cascade,
  user_id      uuid not null references profiles(id) on delete cascade,
  contributed  integer not null default 0,
  joined_at    timestamptz not null default now(),
  completed_at timestamptz,
  xp_awarded   boolean not null default false,
  primary key (quest_id, user_id)
);
create index quest_participants_user_idx on quest_participants (user_id);
```

**Snapshot-Prinzip:** `goal`, `title` und `xp_reward` werden beim Annehmen aus
dem Template kopiert. Balancing-Änderungen verändern nie laufende Quests.

### 2.8 Clans

```sql
create type clan_visibility as enum ('open','code_only');

create table clans (
  id           uuid primary key default gen_random_uuid(),
  name         citext not null unique,
  description  text,
  avatar_key   text not null default 'clan_01',
  avatar_color text not null default 'amber',
  join_code    text not null unique,
  visibility   clan_visibility not null default 'open',
  owner_id     uuid not null references profiles(id),
  xp           integer not null default 0,
  level        integer not null default 1,
  member_count integer not null default 0,
  max_members  integer not null default 50,
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz
);
create index clans_xp_idx on clans (xp desc) where deleted_at is null;

create table clan_members (
  user_id        uuid primary key references profiles(id) on delete cascade,
  clan_id        uuid not null references clans(id) on delete cascade,
  role           text not null default 'member',   -- 'owner' | 'member'
  contributed_xp integer not null default 0,
  joined_at      timestamptz not null default now()
);
create index clan_members_clan_idx on clan_members (clan_id, contributed_xp desc);
```

`user_id` als Primary Key erzwingt **ein Clan pro Nutzer** (V5) auf
Datenbankebene.

### 2.9 Badges

```sql
create table badges (
  code        text primary key,
  name        text not null,
  description text not null,
  tier        text not null,      -- 'easy' | 'medium' | 'hard'
  icon        text not null,
  criteria    jsonb not null      -- {"metric":"countries","gte":5}
);

create table user_badges (
  user_id   uuid not null references profiles(id) on delete cascade,
  code      text not null references badges(code),
  earned_at timestamptz not null default now(),
  primary key (user_id, code)
);
```

---

## 3. Spielökonomie (löst 1.3, 1.4, 2.9 auf)

Alle Werte liegen in `app_config` (Key-Value-Tabelle) bzw. `quest_templates`
und sind **ohne App-Update** änderbar.

### 3.1 XP-Tabelle MVP

| Ereignis | Personal XP | Bemerkung |
|---|---|---|
| Neues Bier entdeckt | +50 | einmalig je Bier |
| Neue Location entdeckt | +50 | einmalig je Venue |
| Neue Stadt entdeckt | +150 | einmalig je Stadt |
| Neues Land entdeckt | +300 | einmalig je Land |
| Check-in (nichts Neues) | +10 | max. 6 pro Tag XP-wirksam |
| Quest abgeschlossen | +100 … +500 | aus Template |
| Freundschaft geschlossen | +25 | je Freund, einmalig, beide Seiten |
| Eingeladener erreicht Level 2 | +100 | einmalig je eingeladenem Nutzer, Anti-Farming |

**Tages-Cap (D8): 500 XP/Tag aus Check-ins und Discoveries.** Quest- und
Sozial-XP sind vom Cap ausgenommen. Der Cap ist kein Gängelungsinstrument,
sondern die technische Umsetzung der Produktphilosophie aus §2: Wer an einem
Abend zehn Biere einträgt, gewinnt nichts gegen jemanden, der drei neue Städte
besucht. Wird der Cap erreicht, zeigt die App eine freundliche Meldung
("Nice pace! XP for today are maxed — check-ins still count for your passport").

### 3.2 Clan-XP (D6)

```
clan_amount = round(0.6 × personal_amount)     -- nur bei Clan-Mitgliedschaft
```
Das entspricht dem Beispiel aus §17 (500 Personal → 300 Clan) exakt.

### 3.3 Level-Kurve

```
xp_needed_for_level(n) = 500 × n              -- Level n → n+1
total_xp_to_reach(n)   = 250 × n × (n − 1)
```
Level 7 verlangt damit 3.500 XP für den nächsten Level-Up — identisch zum
Beispiel aus §11 ("2,840 / 3,500 XP"). Gesamt bis Level 7: 10.500 XP
(≈ 30 Entdeckungen + einige Quests). Dieselbe Kurve wird für City-Level und
Clan-Level verwendet, mit einem Faktor: City ×0.4, Clan ×8 (skaliert mit
Mitgliederzahl).

### 3.4 Quest-Goal-DSL

```json
{"type": "discover_beer",  "count": 2}
{"type": "discover_venue", "count": 2, "scope": "quest_city"}
{"type": "check_in",       "count": 3}
```
`scope` = `any` (Default) | `quest_city`. Mehr Typen sind im MVP nicht nötig;
die drei decken Solo-, City- und Social-Quest ab.

### 3.5 Quest-Katalog MVP (Seed)

| Code | Kind | Ziel | XP | Laufzeit |
|---|---|---|---|---|
| `first_beer` | solo | 1 Bier entdecken | 100 | unbegrenzt (Onboarding) |
| `solo_two_beers` | solo | 2 neue Biere | 200 | 72 h |
| `solo_three_checkins` | solo | 3 Check-ins | 150 | 72 h |
| `city_two_venues` | city | 2 neue Locations in dieser Stadt | 300 | 72 h |
| `social_two_venues` | social | 2 neue Locations, gemeinsam | 500 | 72 h |
| `social_three_beers` | social | 3 neue Biere, gemeinsam | 500 | 72 h |

Regeln: max. **3 aktive Quests** pro Nutzer; Solo-/City-Quests werden aus dem
Katalog angeboten (kein Scheduler — Ablauf wird beim Lesen ausgewertet, V6);
Social Quests werden vom Nutzer erstellt und per Invite geteilt.

**Social-Quest-Abschluss:** Das Ziel ist ein **gemeinsamer Zähler**. Erreicht
die Gruppe das Ziel, erhalten alle Teilnehmer die volle Belohnung, die
mindestens 1 beigetragen haben; wer 0 beigetragen hat, erhält nichts. Das
verhindert Trittbrettfahren, ohne Rechnerei.

### 3.6 Badges MVP

| Code | Tier | Bedingung |
|---|---|---|
| `first_beer` | easy | 1 Check-in |
| `first_quest` | easy | 1 Quest abgeschlossen |
| `first_country` | easy | 1 Land entdeckt |
| `explorer_5_countries` | medium | 5 Länder |
| `city_hopper_25` | medium | 25 Städte |
| `collector_50_beers` | medium | 50 Biere |
| `first_friend` | easy | 1 Freundschaft |
| `clan_member` | easy | Clan beigetreten |

"100 Cities" und "Win 10 Clan Challenges" (§22) wandern auf die Roadmap —
das eine ist im MVP nicht erreichbar, das andere setzt Clan Wars voraus.

---

## 4. API (RPC-Oberfläche)

Alle Aufrufe sind authentifiziert; der Nutzer ergibt sich aus `auth.uid()`,
wird **nie** als Parameter übergeben.

### Account & Profil
| Funktion | Zweck |
|---|---|
| `complete_onboarding(username, avatar_key, avatar_color, birth_year, country)` | Legt `profiles` an, prüft Alter, Username-Verfügbarkeit und Wortfilter, startet `first_beer`-Quest |
| `check_username(username)` | Verfügbarkeit live im Onboarding |
| `get_home()` | Aggregat für den Home-Screen in **einem** Call: Profil, XP/Level, aktive Quests, Passport-Zähler, Clan-Kurzinfo, letzte Aktivität |
| `get_profile(user_id?)` | Profil + Stats + Badges (eigenes oder fremdes) |
| `update_profile(display_name?, avatar_key?, avatar_color?)` | |
| `delete_account()` (Edge Function) | 5.1.1(v) |
| `export_my_data()` (Edge Function) | DSGVO |

### Check-in
| Funktion | Zweck |
|---|---|
| `search_beers(query, limit)` | Trigram-Suche im Katalog |
| `search_venues_nearby(lat, lon, query?, radius_m)` | Bestehende Venues im Umkreis |
| `create_check_in(client_uuid, beer_ref, venue_ref, lat?, lon?, happened_at, tz, note?)` | **Der zentrale Call.** Legt bei Bedarf Bier/Venue an (Dedupe), schreibt Check-in, ermittelt Discoveries, vergibt XP (mit Cap), aktualisiert Quests, City-/Country-Stats, Clan-XP und Badges — alles in einer Transaktion. Gibt das komplette Reward-Paket zurück. |
| `delete_check_in(id)` | Korrektur; rollt XP über kompensierende Ledger-Einträge zurück (nur innerhalb 24 h) |

`beer_ref` / `venue_ref` sind jeweils entweder `{id}` (bestehend) oder
`{name, ...}` (neu anzulegen). Ein Call, kein mehrstufiges Anlegen.

**Antwort von `create_check_in`:**
```json
{
  "check_in_id": "…",
  "xp_awarded": 200,
  "xp_capped": false,
  "discoveries": [{"kind":"beer","name":"Peroni"},{"kind":"city","name":"Cecina"}],
  "level_before": 6, "level_after": 7,
  "quests": [{"id":"…","title":"Discover 2 new beers","progress":1,"goal":2,
              "completed":false}],
  "badges": [{"code":"first_country","name":"First Country"}],
  "clan_xp_awarded": 120
}
```
Der Reward-Screen rendert exakt dieses Objekt — kein Nachladen, keine
Client-Berechnung.

### Passport & Karte
`get_passport_summary()`, `get_passport_countries()`, `get_passport_cities(country?)`,
`get_passport_venues(city?)`, `get_passport_beers()`, `get_map_pins(bbox, zoom)`,
`get_city_detail(city_id)`, `get_country_detail(code)`.

### Quests
`get_quests()` (aktiv + verfügbar, Ablauf wird lazy ausgewertet),
`accept_quest(template_code, city_id?)`, `abandon_quest(quest_id)`,
`create_social_quest(template_code)` → liefert Quest + Invite-Code,
`get_quest(quest_id)` (inkl. Teilnehmerfortschritt), `join_quest(invite_code)`.

### Freunde & Invites
`search_users(query)`, `send_friend_request(user_id)`,
`respond_friend_request(id, accept)`, `get_friends()`,
`get_friend_requests()`, `remove_friend(user_id)`,
`create_invite(kind, quest_id?)`, `redeem_invite(code)`,
`block_user(user_id)`, `unblock_user(user_id)`, `report(target_type, target_id, reason, note?)`.

### Clan
`create_clan(name, avatar_key, avatar_color, description?, visibility)`,
`join_clan_by_code(code)`, `join_clan(clan_id)` (bei `visibility='open'`),
`leave_clan()`, `get_clan(clan_id?)`, `get_clan_members(clan_id)`,
`search_clans(query)`.

### Leaderboards
`get_leaderboard_friends(range)` — `range` ∈ `week` | `all` (D7),
`get_leaderboard_clans(mode)` — `mode` ∈ `total` | `per_member`,
`get_leaderboard_city(city_id, range)`.

---

## 5. RLS-Grundsätze

```sql
-- Referenzdaten: für alle Eingeloggten lesbar, nie schreibbar
alter table beers enable row level security;
create policy beers_read on beers for select to authenticated using (true);
-- (kein insert/update policy → Writes nur via SECURITY DEFINER RPC)

-- Eigene Check-ins + die von Freunden
create policy check_ins_read on check_ins for select to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1 from friendships f
    where (f.user_low = least(auth.uid(), check_ins.user_id)
       and f.user_high = greatest(auth.uid(), check_ins.user_id))
  )
);

-- Profile öffentlich, aber ohne blockierte Nutzer
create policy profiles_read on profiles for select to authenticated
using (
  deleted_at is null
  and not exists (select 1 from blocks b
                  where b.blocker_id = profiles.id and b.blocked_id = auth.uid())
);

-- Clan-interne Daten nur für Mitglieder
create policy clan_members_read on clan_members for select to authenticated
using (clan_id in (select clan_id from clan_members where user_id = auth.uid()));
```

Für **keine** Tabelle gibt es eine `insert`/`update`-Policy für die Rolle
`authenticated`. Jeder Schreibvorgang läuft durch eine geprüfte Funktion. Das
ist die einfachste und sicherste Variante — und der Grund, warum XP nicht
manipulierbar sind.

---

## 6. Seed-Daten

| Datensatz | Umfang | Quelle |
|---|---|---|
| `countries` | 249 | ISO-3166-1 |
| `cities` | ~55.000 (≥ 15.000 Einwohner) | GeoNames `cities15000`, CC-BY 4.0 (Attribution in App-Credits) |
| `beers` | 300–500 | Manuell kuratiert: meistgetrunkene Biere in DE/AT/IT/CZ/UK/US |
| `venues` | 0 | Entstehen ausschließlich durch Nutzer |
| `quest_templates` | 6 | siehe 3.5 |
| `badges` | 8 | siehe 3.6 |

`cities15000` statt `cities5000` halbiert die Datenmenge und reicht für die
Zielmärkte; ein Ausbau ist eine reine Datenmigration.
