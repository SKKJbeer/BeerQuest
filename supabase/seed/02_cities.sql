-- Minimalsatz fuer Tests und den ersten TestFlight.
-- Produktiv kommen ~29.000 Staedte ueber import_geonames.sh;
-- diese Zeilen werden dabei per geonames_id abgeglichen.
insert into public.cities (country_code, name, name_norm, lat, lon, population, timezone, geonames_id) values
  ('DE','Berlin',    'berlin',    52.5244, 13.4105, 3426354,'Europe/Berlin',   2950159),
  ('DE','Munich',    'munich',    48.1374, 11.5755, 1260391,'Europe/Berlin',   2867714),
  ('DE','Hamburg',   'hamburg',   53.5753,  9.9937, 1739117,'Europe/Berlin',   2911298),
  ('DE','Cologne',   'cologne',   50.9333,  6.9500, 963395, 'Europe/Berlin',   2886242),
  ('DE','Bamberg',   'bamberg',   49.8917, 10.8917,  70047, 'Europe/Berlin',   2953417),
  ('AT','Vienna',    'vienna',    48.2085, 16.3721, 1691468,'Europe/Vienna',   2761369),
  ('AT','Salzburg',  'salzburg',  47.7981, 13.0465, 150269, 'Europe/Vienna',   2766824),
  ('CH','Zurich',    'zurich',    47.3667,  8.5500, 341730, 'Europe/Zurich',   2657896),
  ('IT','Rome',      'rome',      41.8931, 12.4828, 2318895,'Europe/Rome',     3169070),
  ('IT','Milan',     'milan',     45.4643,  9.1895, 1236837,'Europe/Rome',     3173435),
  ('IT','Florence',  'florence',  43.7710, 11.2486, 349296, 'Europe/Rome',     3176959),
  ('IT','Cecina',    'cecina',    43.3070, 10.5170,  28000, 'Europe/Rome',     3178229),
  ('CZ','Prague',    'prague',    50.0880, 14.4208, 1165581,'Europe/Prague',   3067696),
  ('CZ','Pilsen',    'pilsen',    49.7475, 13.3776, 164180, 'Europe/Prague',   3068160),
  ('BE','Brussels',  'brussels',  50.8504,  4.3488, 1019022,'Europe/Brussels',  2800866),
  ('BE','Bruges',    'bruges',    51.2093,  3.2247, 117073, 'Europe/Brussels',  2800931),
  ('NL','Amsterdam', 'amsterdam', 52.3740,  4.8897, 741636, 'Europe/Amsterdam', 2759794),
  ('GB','London',    'london',    51.5085, -0.1257, 8961989,'Europe/London',    2643743),
  ('GB','Manchester','manchester',53.4809, -2.2374, 553230, 'Europe/London',    2643123),
  ('GB','Edinburgh', 'edinburgh', 55.9521, -3.1965, 506520, 'Europe/London',    2650225),
  ('IE','Dublin',    'dublin',    53.3331, -6.2489, 1024027,'Europe/Dublin',    2964574),
  ('ES','Madrid',    'madrid',    40.4165, -3.7026, 3255944,'Europe/Madrid',    3117735),
  ('ES','Barcelona', 'barcelona', 41.3888,  2.1590, 1620343,'Europe/Madrid',    3128760),
  ('FR','Paris',     'paris',     48.8534,  2.3488, 2138551,'Europe/Paris',     2988507),
  ('US','New York',  'new york',  40.7143,-74.0060, 8804190,'America/New_York', 5128581),
  ('US','Portland',  'portland',  45.5234,-122.6762, 652503,'America/Los_Angeles',5746545),
  ('US','Denver',    'denver',    39.7392,-104.9847, 715522,'America/Denver',   5419384)
on conflict (geonames_id) do nothing;
