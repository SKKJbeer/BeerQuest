-- Bildet die Teile der Supabase-Umgebung nach, die es in einem nackten
-- Postgres nicht gibt: die Rollen und das auth-Schema.
-- Wird NUR in CI und lokalen Tests ausgefuehrt, nie gegen die Cloud.

do $$ begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then
    create role anon nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then
    create role authenticated nologin;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then
    create role service_role nologin;
  end if;
end $$;

create schema if not exists extensions;
create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key,
  email text
);

-- In Supabase liest auth.uid() den JWT-Claim. Der Stub liest dieselbe
-- Einstellung, damit Tests einen Nutzer setzen koennen:
--   select public.test_login('...uuid...');
create or replace function auth.uid() returns uuid
language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
