-- ~60 verbreitete Biere der Zielmaerkte. Bewusst klein gehalten:
-- Was die Tester selbst eintragen, zeigt uns den tatsaechlich noetigen
-- Katalog. Kuratierung auf Verdacht ist Arbeit ohne Erkenntnis.
insert into public.beers (name, name_norm, brewery_name, brewery_norm, country_code)
select v.name, public.norm_name(v.name), v.brewery, public.norm_name(v.brewery), v.cc
from (values
  -- Deutschland
  ('Augustiner Helles','Augustiner-Bräu','DE'),
  ('Tegernseer Hell','Tegernseer','DE'),
  ('Paulaner Hefe-Weißbier','Paulaner','DE'),
  ('Weihenstephaner Hefeweissbier','Weihenstephan','DE'),
  ('Erdinger Weissbier','Erdinger','DE'),
  ('Beck''s','Beck''s','DE'),
  ('Krombacher Pils','Krombacher','DE'),
  ('Jever Pilsener','Jever','DE'),
  ('Bitburger Premium Pils','Bitburger','DE'),
  ('Warsteiner Premium','Warsteiner','DE'),
  ('Rothaus Tannenzäpfle','Rothaus','DE'),
  ('Flensburger Pilsener','Flensburger','DE'),
  ('Astra Urtyp','Astra','DE'),
  ('Schlenkerla Rauchbier Märzen','Schlenkerla','DE'),
  ('Kölsch Früh','Früh','DE'),
  ('Radeberger Pilsner','Radeberger','DE'),
  ('Berliner Kindl Weisse','Berliner Kindl','DE'),
  ('Franziskaner Weissbier','Franziskaner','DE'),
  ('Veltins Pilsener','Veltins','DE'),
  ('Störtebeker Bernstein-Weizen','Störtebeker','DE'),
  -- Oesterreich / Schweiz
  ('Stiegl Goldbräu','Stiegl','AT'),
  ('Gösser Märzen','Gösser','AT'),
  ('Ottakringer Helles','Ottakringer','AT'),
  ('Zipfer Urtyp','Zipfer','AT'),
  ('Feldschlösschen Original','Feldschlösschen','CH'),
  ('Calanda Edelbräu','Calanda','CH'),
  -- Tschechien
  ('Pilsner Urquell','Plzeňský Prazdroj','CZ'),
  ('Budweiser Budvar','Budějovický Budvar','CZ'),
  ('Kozel Černý','Velkopopovický Kozel','CZ'),
  ('Staropramen Ležák','Staropramen','CZ'),
  ('Gambrinus Originál','Gambrinus','CZ'),
  ('Bernard Světlý Ležák','Bernard','CZ'),
  -- Italien
  ('Peroni Nastro Azzurro','Birra Peroni','IT'),
  ('Moretti','Birra Moretti','IT'),
  ('Ichnusa Non Filtrata','Ichnusa','IT'),
  ('Menabrea Bionda','Menabrea','IT'),
  ('Baladin Nazionale','Baladin','IT'),
  ('Forst Kronen','Forst','IT'),
  -- Belgien / Niederlande
  ('Duvel','Duvel Moortgat','BE'),
  ('Chimay Bleue','Chimay','BE'),
  ('Orval','Orval','BE'),
  ('Westmalle Tripel','Westmalle','BE'),
  ('Rochefort 10','Rochefort','BE'),
  ('Leffe Blonde','Leffe','BE'),
  ('Hoegaarden Witbier','Hoegaarden','BE'),
  ('Stella Artois','Stella Artois','BE'),
  ('Heineken','Heineken','NL'),
  ('Grolsch Premium Pilsner','Grolsch','NL'),
  ('La Trappe Tripel','La Trappe','NL'),
  -- UK / Irland
  ('Guinness Draught','Guinness','IE'),
  ('Murphy''s Irish Stout','Murphy''s','IE'),
  ('BrewDog Punk IPA','BrewDog','GB'),
  ('Fuller''s London Pride','Fuller''s','GB'),
  ('Camden Hells','Camden Town Brewery','GB'),
  ('Timothy Taylor''s Landlord','Timothy Taylor','GB'),
  ('Beavertown Neck Oil','Beavertown','GB'),
  -- Spanien / Frankreich
  ('Estrella Damm','Damm','ES'),
  ('Mahou Cinco Estrellas','Mahou','ES'),
  ('Alhambra Reserva 1925','Alhambra','ES'),
  ('Kronenbourg 1664','Kronenbourg','FR'),
  -- USA
  ('Sierra Nevada Pale Ale','Sierra Nevada','US'),
  ('Lagunitas IPA','Lagunitas','US'),
  ('Samuel Adams Boston Lager','Boston Beer Company','US'),
  ('Anchor Steam Beer','Anchor Brewing','US'),
  ('Brooklyn Lager','Brooklyn Brewery','US')
) as v(name, brewery, cc)
on conflict do nothing;
