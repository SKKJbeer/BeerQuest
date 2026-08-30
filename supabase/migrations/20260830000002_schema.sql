-- P0.2 - Schema nach docs/06-data-model.md.
-- Nur P0-Tabellen. P1-Tabellen (blocks, reports, user_city_stats,
-- user_country_stats) werden bewusst NICHT angelegt.

-- ---------------------------------------------------------------- Typen
do $$ begin
  create type public.venue_category as enum
    ('bar','pub','biergarten','brewery','restaurant','shop','festival','other');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.entity_status as enum ('active','merged','hidden');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.user_tier as enum ('free','plus');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.verification_level as enum ('none','photo','location');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.discovery_kind as enum ('beer','venue','city','country');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.request_status as enum
    ('pending','accepted','declined','cancelled');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.invite_kind as enum ('friend','quest');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.quest_kind as enum ('solo','city','social');
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.quest_status as enum
    ('active','completed','expired','cancelled');
exception when duplicate_object then null; end $$;

-- --------------------------------------------------------- Referenzdaten
create table if not exists public.countries (
  code       char(2) primary key,
  name       text not null,
  flag_emoji text not null,
  lat        double precision not null,
  lon        double precision not null
);

create table if not exists public.cities (
  id           uuid primary key default gen_random_uuid(),
  country_code char(2) not null references public.countries(code),
  name         text not null,
  name_norm    text not null,
  lat          double precision not null,
  lon          double precision not null,
  population   integer not null default 0,
  timezone     text,
  geonames_id  integer unique,
  created_at   timestamptz not null default now()
);
create index if not exists cities_geo_idx
  on public.cities using gist (extensions.ll_to_earth(lat, lon));
create index if not exists cities_norm_idx
  on public.cities (country_code, name_norm);

-- ---------------------------------------------------------------- Nutzer
create table if not exists public.profiles (
  id              uuid primary key references auth.users(id) on delete cascade,
  username        extensions.citext not null unique,
  display_name    text,
  avatar_key      text not null default 'mug_01',
  avatar_color    text not null default 'amber',
  level           integer not null default 1,
  xp              integer not null default 0,
  birth_year      smallint not null,
  country_code    char(2) references public.countries(code),
  tier            public.user_tier not null default 'free',
  invited_by      uuid references public.profiles(id) on delete set null,
  created_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  constraint profiles_username_shape check (username ~ '^[a-z0-9_]{3,20}$'),
  constraint profiles_birth_year_sane check (birth_year between 1900 and 2100)
);
create index if not exists profiles_xp_idx
  on public.profiles (xp desc) where deleted_at is null;

-- ----------------------------------------------------------------- Clans
create table if not exists public.clans (
  id           uuid primary key default gen_random_uuid(),
  name         extensions.citext not null unique,
  avatar_key   text not null default 'mug_01',
  avatar_color text not null default 'amber',
  join_code    text not null unique,
  description  text,
  owner_id     uuid not null references public.profiles(id),
  xp           integer not null default 0,
  level        integer not null default 1,
  member_count integer not null default 0,
  max_members  integer not null default 50,
  created_at   timestamptz not null default now(),
  deleted_at   timestamptz,
  constraint clans_name_length check (length(name::text) between 3 and 24)
);
create index if not exists clans_xp_idx
  on public.clans (xp desc) where deleted_at is null;

-- user_id als Primaerschluessel erzwingt EIN Clan pro Nutzer auf
-- Datenbankebene - kein Anwendungscode noetig.
create table if not exists public.clan_members (
  user_id        uuid primary key references public.profiles(id) on delete cascade,
  clan_id        uuid not null references public.clans(id) on delete cascade,
  role           text not null default 'member',
  contributed_xp integer not null default 0,
  joined_at      timestamptz not null default now(),
  constraint clan_members_role check (role in ('owner','member'))
);
create index if not exists clan_members_clan_idx
  on public.clan_members (clan_id, contributed_xp desc);

-- ------------------------------------------------------------ Katalogdaten
create table if not exists public.venues (
  id           uuid primary key default gen_random_uuid(),
  city_id      uuid references public.cities(id),
  country_code char(2) not null references public.countries(code),
  name         text not null,
  name_norm    text not null,
  category     public.venue_category not null default 'bar',
  lat          double precision not null,
  lon          double precision not null,
  geohash7     text not null,
  status       public.entity_status not null default 'active',
  merged_into  uuid references public.venues(id),
  created_by   uuid references public.profiles(id) on delete set null,
  owner_id     uuid,
  created_at   timestamptz not null default now()
);
create index if not exists venues_geo_idx
  on public.venues using gist (extensions.ll_to_earth(lat, lon));
create index if not exists venues_trgm_idx
  on public.venues using gin (name_norm extensions.gin_trgm_ops);
create index if not exists venues_city_idx
  on public.venues (city_id) where status = 'active';

create table if not exists public.beers (
  id           uuid primary key default gen_random_uuid(),
  name         text not null,
  name_norm    text not null,
  brewery_name text,
  brewery_norm text,
  style        text,
  abv          numeric(4,2),
  country_code char(2) references public.countries(code),
  status       public.entity_status not null default 'active',
  merged_into  uuid references public.beers(id),
  created_by   uuid references public.profiles(id) on delete set null,
  created_at   timestamptz not null default now()
);
create unique index if not exists beers_identity_idx
  on public.beers (name_norm, coalesce(brewery_norm,''))
  where status = 'active';
create index if not exists beers_trgm_idx
  on public.beers using gin (name_norm extensions.gin_trgm_ops);

-- ------------------------------------------------------ Check-ins & Funde
create table if not exists public.check_ins (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid references public.profiles(id) on delete set null,
  client_uuid  uuid not null,
  beer_id      uuid not null references public.beers(id),
  venue_id     uuid not null references public.venues(id),
  city_id      uuid references public.cities(id),
  country_code char(2) not null references public.countries(code),
  happened_at  timestamptz not null default now(),
  local_date   date not null,
  verification public.verification_level not null default 'none',
  created_at   timestamptz not null default now()
);
create unique index if not exists check_ins_idem_idx
  on public.check_ins (user_id, client_uuid);
create index if not exists check_ins_user_time_idx
  on public.check_ins (user_id, happened_at desc);
create index if not exists check_ins_user_day_idx
  on public.check_ins (user_id, local_date);

create table if not exists public.user_discoveries (
  user_id        uuid not null references public.profiles(id) on delete cascade,
  kind           public.discovery_kind not null,
  entity_id      text not null,
  first_check_in uuid references public.check_ins(id) on delete set null,
  discovered_at  timestamptz not null default now(),
  primary key (user_id, kind, entity_id)
);
create index if not exists user_discoveries_kind_idx
  on public.user_discoveries (user_id, kind);
create index if not exists user_discoveries_checkin_idx
  on public.user_discoveries (first_check_in);

-- ------------------------------------------------------------- XP-Ledger
create table if not exists public.xp_events (
  id          bigserial primary key,
  user_id     uuid not null references public.profiles(id) on delete cascade,
  amount      integer not null,
  clan_id     uuid references public.clans(id) on delete set null,
  clan_amount integer not null default 0,
  reason      text not null,
  ref_type    text,
  ref_id      text,
  season_id   uuid,
  idem_key    text not null unique,
  created_at  timestamptz not null default now()
);
create index if not exists xp_events_user_time_idx
  on public.xp_events (user_id, created_at desc);
create index if not exists xp_events_clan_time_idx
  on public.xp_events (clan_id, created_at desc);
create index if not exists xp_events_ref_idx
  on public.xp_events (ref_type, ref_id);

-- ---------------------------------------------------------------- Quests
create table if not exists public.quest_templates (
  code             text primary key,
  kind             public.quest_kind not null,
  title            text not null,
  description      text not null,
  goal             jsonb not null,
  xp_reward        integer not null,
  duration_hours   integer not null default 72,
  is_daily         boolean not null default false,
  min_level        integer not null default 1,
  active           boolean not null default true,
  sort_order       integer not null default 0
);

create table if not exists public.quests (
  id            uuid primary key default gen_random_uuid(),
  template_code text not null references public.quest_templates(code),
  kind          public.quest_kind not null,
  owner_id      uuid not null references public.profiles(id) on delete cascade,
  city_id       uuid references public.cities(id),
  title         text not null,
  goal          jsonb not null,
  xp_reward     integer not null,
  status        public.quest_status not null default 'active',
  starts_at     timestamptz not null default now(),
  ends_at       timestamptz not null,
  completed_at  timestamptz,
  created_at    timestamptz not null default now()
);
create index if not exists quests_owner_idx on public.quests (owner_id, status);

create table if not exists public.quest_participants (
  quest_id     uuid not null references public.quests(id) on delete cascade,
  user_id      uuid not null references public.profiles(id) on delete cascade,
  contributed  integer not null default 0,
  joined_at    timestamptz not null default now(),
  completed_at timestamptz,
  xp_awarded   boolean not null default false,
  primary key (quest_id, user_id)
);
create index if not exists quest_participants_user_idx
  on public.quest_participants (user_id);

-- -------------------------------------------------------------- Soziales
create table if not exists public.friendships (
  user_low   uuid not null references public.profiles(id) on delete cascade,
  user_high  uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_low, user_high),
  constraint friendships_canonical check (user_low < user_high)
);

create table if not exists public.friend_requests (
  id           uuid primary key default gen_random_uuid(),
  from_user    uuid not null references public.profiles(id) on delete cascade,
  to_user      uuid not null references public.profiles(id) on delete cascade,
  status       public.request_status not null default 'pending',
  created_at   timestamptz not null default now(),
  responded_at timestamptz,
  constraint friend_requests_not_self check (from_user <> to_user)
);
create unique index if not exists friend_requests_open_idx
  on public.friend_requests (from_user, to_user) where status = 'pending';

create table if not exists public.invites (
  code       text primary key,
  inviter_id uuid not null references public.profiles(id) on delete cascade,
  kind       public.invite_kind not null default 'friend',
  quest_id   uuid references public.quests(id) on delete cascade,
  expires_at timestamptz not null,
  max_uses   integer not null default 25,
  use_count  integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists invites_inviter_idx
  on public.invites (inviter_id, created_at desc);

-- ---------------------------------------------------------------- Badges
create table if not exists public.badges (
  code        text primary key,
  name        text not null,
  description text not null,
  tier        text not null,
  icon        text not null,
  criteria    jsonb not null
);

create table if not exists public.user_badges (
  user_id   uuid not null references public.profiles(id) on delete cascade,
  code      text not null references public.badges(code),
  earned_at timestamptz not null default now(),
  primary key (user_id, code)
);

-- ------------------------------------------------------------- Ereignisse
create table if not exists public.app_events (
  id         bigserial primary key,
  user_id    uuid references public.profiles(id) on delete set null,
  name       text not null,
  props      jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);
create index if not exists app_events_name_time_idx
  on public.app_events (name, created_at desc);
