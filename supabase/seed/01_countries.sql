-- Zielmaerkte P0. Der vollstaendige ISO-Satz kommt ueber
-- supabase/seed/import_geonames.sh; diese Liste genuegt fuer Tests und
-- den ersten TestFlight.
insert into public.countries (code, name, flag_emoji, lat, lon) values
  ('DE','Germany',       U&'\D83C\DDE9' || U&'\D83C\DDEA', 51.1657, 10.4515),
  ('AT','Austria',       U&'\D83C\DDE6' || U&'\D83C\DDF9', 47.5162, 14.5501),
  ('CH','Switzerland',   U&'\D83C\DDE8' || U&'\D83C\DDED', 46.8182,  8.2275),
  ('IT','Italy',         U&'\D83C\DDEE' || U&'\D83C\DDF9', 41.8719, 12.5674),
  ('CZ','Czechia',       U&'\D83C\DDE8' || U&'\D83C\DDFF', 49.8175, 15.4730),
  ('BE','Belgium',       U&'\D83C\DDE7' || U&'\D83C\DDEA', 50.5039,  4.4699),
  ('NL','Netherlands',   U&'\D83C\DDF3' || U&'\D83C\DDF1', 52.1326,  5.2913),
  ('GB','United Kingdom',U&'\D83C\DDEC' || U&'\D83C\DDE7', 55.3781, -3.4360),
  ('IE','Ireland',       U&'\D83C\DDEE' || U&'\D83C\DDEA', 53.1424, -7.6921),
  ('ES','Spain',         U&'\D83C\DDEA' || U&'\D83C\DDF8', 40.4637, -3.7492),
  ('FR','France',        U&'\D83C\DDEB' || U&'\D83C\DDF7', 46.2276,  2.2137),
  ('US','United States', U&'\D83C\DDFA' || U&'\D83C\DDF8', 37.0902,-95.7129)
on conflict (code) do nothing;
