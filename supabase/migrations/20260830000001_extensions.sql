-- P0.1 - Fundament.
-- Nur Erweiterungen; das eigentliche Schema entsteht in P0.2
-- (siehe docs/06-data-model.md).

-- Umkreissuche fuer resolve_city() und die Orts-Vorschlaege.
create extension if not exists cube with schema extensions;
create extension if not exists earthdistance with schema extensions;

-- Namensaehnlichkeit fuer Bier- und Orts-Dedupe (Schwelle 0.6).
create extension if not exists pg_trgm with schema extensions;

-- Case-insensitive Text fuer username und clan.name.
create extension if not exists citext with schema extensions;

-- Konfiguration: alle XP-Werte, Caps und Faktoren liegen hier, damit
-- Balancing ohne App-Update moeglich ist (docs/06-data-model.md §2.10).
create table if not exists public.app_config (
  key   text primary key,
  value jsonb not null
);

insert into public.app_config (key, value) values
  ('xp.new_beer',            '50'::jsonb),
  ('xp.new_venue',           '50'::jsonb),
  ('xp.new_city',            '150'::jsonb),
  ('xp.new_country',         '300'::jsonb),
  ('xp.repeat_checkin',      '10'::jsonb),
  ('xp.friendship',          '25'::jsonb),
  ('xp.invited_reached_l2',  '100'::jsonb),
  ('xp.daily_cap',           '500'::jsonb),
  ('xp.max_scoring_repeats', '6'::jsonb),
  ('clan.xp_ratio',          '0.6'::jsonb),
  ('level.xp_per_level',     '500'::jsonb),
  ('quests.max_active',      '3'::jsonb)
on conflict (key) do nothing;

-- app_config ist fuer alle Eingeloggten lesbar und fuer niemanden schreibbar.
-- Schreibzugriffe laufen ausschliesslich ueber SECURITY DEFINER-Funktionen -
-- deshalb gibt es hier bewusst keine insert/update-Policy.
alter table public.app_config enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'app_config'
      and policyname = 'app_config_read'
  ) then
    create policy app_config_read on public.app_config
      for select to authenticated using (true);
  end if;
end $$;
