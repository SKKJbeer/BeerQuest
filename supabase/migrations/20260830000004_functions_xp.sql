-- P0.2 - XP-Vergabe, Level- und Clan-Fortschreibung.
-- Der Ledger ist die Wahrheit; profiles.xp, clans.xp und
-- clan_members.contributed_xp sind Caches, die der Trigger pflegt.

create or replace function public.tg_xp_events_apply()
returns trigger language plpgsql as $$
begin
  update public.profiles
     set xp = xp + new.amount,
         level = public.level_for_xp(xp + new.amount)
   where id = new.user_id;

  if new.clan_id is not null and new.clan_amount <> 0 then
    update public.clans
       set xp = xp + new.clan_amount,
           level = public.level_for_xp((xp + new.clan_amount) / 8)
     where id = new.clan_id;

    update public.clan_members
       set contributed_xp = contributed_xp + new.clan_amount
     where user_id = new.user_id;
  end if;

  return new;
end $$;

drop trigger if exists xp_events_apply on public.xp_events;
create trigger xp_events_apply
  after insert on public.xp_events
  for each row execute function public.tg_xp_events_apply();

-- Vergibt XP idempotent. Ein zweiter Aufruf mit demselben idem_key ist ein
-- No-op und gibt 0 zurueck - das ist die strukturelle Absicherung gegen
-- doppelte Gutschriften bei Wiederholungsversuchen.
create or replace function public.award_xp(
  p_user     uuid,
  p_amount   int,
  p_reason   text,
  p_ref_type text,
  p_ref_id   text,
  p_idem_key text
) returns int
language plpgsql security definer set search_path = public, extensions as $$
declare
  v_clan uuid;
  v_clan_amount int := 0;
  v_ratio numeric;
begin
  if p_amount is null or p_amount = 0 then return 0; end if;

  select clan_id into v_clan from public.clan_members where user_id = p_user;
  if v_clan is not null then
    v_ratio := public.cfg_num('clan.xp_ratio', 0.6);
    v_clan_amount := round(p_amount * v_ratio);
  end if;

  insert into public.xp_events
    (user_id, amount, clan_id, clan_amount, reason, ref_type, ref_id, idem_key)
  values
    (p_user, p_amount, v_clan, v_clan_amount, p_reason, p_ref_type, p_ref_id, p_idem_key)
  on conflict (idem_key) do nothing;

  if not found then
    return 0;   -- bereits vergeben
  end if;
  return p_amount;
end $$;

-- Wie viel XP hat der Nutzer heute bereits aus Check-ins und Entdeckungen
-- bekommen? Grundlage des Tages-Caps aus Product Vision §2.
create or replace function public.capped_xp_today(p_user uuid, p_local_date date)
returns int
language sql stable security definer set search_path = public, extensions as $$
  -- Die Filterung auf ref_type steht bewusst in einer eigenen Ebene, damit
  -- der Cast nach uuid nie auf fremde ref_id-Werte angewendet wird.
  with own as (
    select amount, ref_id
    from public.xp_events
    where user_id = p_user and ref_type = 'check_in'
  )
  select coalesce(sum(o.amount), 0)::int
  from own o
  join public.check_ins c on c.id = o.ref_id::uuid
  where c.local_date = p_local_date
$$;
