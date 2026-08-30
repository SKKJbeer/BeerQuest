-- Produktaenderung vor P0.3 (PM-Entscheidung 2026-08-30):
-- Der allererste erfolgreiche Check-in eines Nutzers ist vom Tages-Cap
-- ausgenommen und erhaelt seinen vollstaendigen Discovery-Reward.
--
-- Grund: Der erste Check-in ist der wichtigste "Ich habe das Spiel
-- verstanden"-Moment. Wer beim ersten Mal alle vier Entdeckungen macht
-- (Bier + Ort + Stadt + Land = 550 XP), darf dafuer nicht sofort mit
-- "XP capped today" ausgebremst werden.
--
-- Ab dem zweiten Check-in gilt der Tages-Cap unveraendert.
-- Quest-XP und andere Achievement-Rewards waren nie vom Cap erfasst.

insert into public.app_config (key, value)
values ('xp.first_checkin_uncapped', 'true'::jsonb)
on conflict (key) do nothing;

-- Die Hilfsfunktion cfg_bool steht in Migration 0003 bei den uebrigen
-- cfg_-Funktionen, damit create_check_in (0006) nicht von einer spaeteren
-- Migration abhaengt.
