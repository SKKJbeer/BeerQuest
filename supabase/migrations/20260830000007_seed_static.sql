-- P0.2 - statische Seeds, die zum Schema gehoeren und deshalb in die
-- Migration wandern (im Gegensatz zu Staedten und Bieren, die ueber
-- Importskripte kommen).

insert into public.quest_templates
  (code, kind, title, description, goal, xp_reward, duration_hours, is_daily, sort_order)
values
  ('first_beer','solo','Your First Quest','Discover your first beer.',
   '{"type":"discover_beer","count":1}'::jsonb, 100, 8760, false, 0),
  ('two_beers','solo','Beer Explorer','Discover 2 new beers.',
   '{"type":"discover_beer","count":2}'::jsonb, 200, 72, true, 1),
  ('two_venues','solo','Place Hunter','Discover 2 new places.',
   '{"type":"discover_venue","count":2}'::jsonb, 200, 72, true, 2),
  ('three_checkins','solo','Keep It Going','Check in 3 times.',
   '{"type":"check_in","count":3}'::jsonb, 150, 72, true, 3),
  -- Abweichung von docs/06-data-model.md §3.5, bewusst und dokumentiert:
  -- Dort stand 'beer_and_place' mit dem Ziel "1 neues Bier UND 1 neuer Ort".
  -- Die freigegebene Goal-DSL kennt keine zusammengesetzten Ziele. Statt sie
  -- zu erweitern (Scope-Ausweitung) wird die Vorlage durch eine ersetzt, die
  -- innerhalb der DSL liegt.
  ('three_beers','solo','Beer Hunter','Discover 3 new beers.',
   '{"type":"discover_beer","count":3}'::jsonb, 300, 72, true, 4)
on conflict (code) do update set
  title = excluded.title, description = excluded.description,
  goal = excluded.goal, xp_reward = excluded.xp_reward,
  duration_hours = excluded.duration_hours, is_daily = excluded.is_daily;

-- Falls eine frühere Version die Vorlage 'beer_and_place' angelegt hat:
-- deaktivieren statt loeschen, damit laufende Quests ihren Fremdschluessel
-- behalten. Snapshot-Prinzip - laufende Quests aendern sich nie.
update public.quest_templates set active = false where code = 'beer_and_place';

-- icon sind **semantische Namen**, keine Emoji-Codepoints.
-- Der Client bildet sie auf sein Icon-Set ab (BQIcon); solange das eigene
-- Set fehlt, auf SF Symbols. Emoji sind als UI-Icons ausgeschlossen
-- (docs/14-product-dna.md).
-- tier steuert die Materialstufe der Medaille: copper < brass < silver.
insert into public.badges (code, name, description, tier, icon, criteria) values
  ('first_beer','First Beer','Log your first check-in.','copper','badge.first-beer',
   '{"metric":"check_ins","gte":1}'::jsonb),
  ('first_country','First Country','Discover your first country.','copper','badge.first-country',
   '{"metric":"countries","gte":1}'::jsonb),
  ('first_friend','First Friend','Add your first friend.','copper','badge.first-friend',
   '{"metric":"friends","gte":1}'::jsonb),
  ('explorer_5_countries','Globetrotter','Discover 5 countries.','brass','badge.globetrotter',
   '{"metric":"countries","gte":5}'::jsonb)
on conflict (code) do update set
  name = excluded.name, description = excluded.description,
  tier = excluded.tier, icon = excluded.icon, criteria = excluded.criteria;

-- Die Tagesquest ergibt sich deterministisch aus dem Datum - kein Scheduler,
-- keine Jobs, kein Zustand (docs/06-data-model.md §2.5).
create or replace function public.daily_quest_code(p_date date default current_date)
returns text language sql stable as $$
  select code from (
    select code, row_number() over (order by sort_order, code) - 1 as idx,
           count(*) over () as total
    from public.quest_templates
    where is_daily and active
  ) t
  where idx = abs(hashtext(p_date::text)) % greatest(total, 1)
$$;
