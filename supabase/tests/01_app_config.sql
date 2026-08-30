-- P0.1 - stellt sicher, dass das Fundament steht.
do $$
declare
  cap int;
  ratio numeric;
begin
  select (value #>> '{}')::int into cap
    from public.app_config where key = 'xp.daily_cap';
  if cap is null or cap <> 500 then
    raise exception 'xp.daily_cap fehlt oder ist nicht 500 (war: %)', cap;
  end if;

  select (value #>> '{}')::numeric into ratio
    from public.app_config where key = 'clan.xp_ratio';
  if ratio is null or ratio <> 0.6 then
    raise exception 'clan.xp_ratio fehlt oder ist nicht 0.6 (war: %)', ratio;
  end if;

  -- Product Vision §2: Der Tages-Cap muss unter vier neuen Laendern liegen,
  -- sonst waere Menge wieder die beste Strategie.
  if cap >= 4 * 300 then
    raise exception 'Tages-Cap % hebelt die Anti-Mengen-Regel aus', cap;
  end if;

  if not exists (select 1 from pg_extension where extname = 'pg_trgm') then
    raise exception 'pg_trgm fehlt - Dedupe von Bier und Ort waere unmoeglich';
  end if;

  if not exists (select 1 from pg_extension where extname = 'earthdistance') then
    raise exception 'earthdistance fehlt - resolve_city waere unmoeglich';
  end if;

  raise notice 'P0.1 Fundament ok';
end $$;
