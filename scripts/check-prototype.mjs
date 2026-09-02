/**
 * Prueft den klickbaren Prototyp mit einem echten Browser.
 * Vorbild: PulseMeter - erst pruefen, dann veroeffentlichen.
 *
 * Geprueft wird der Core Loop, die Beer World, der Clan-Flow und die
 * Regeln, die sonst niemand zaehlt: keine Emoji, Tap-Ziele gross genug,
 * kein Ueberlauf, keine JS-Fehler.
 */
import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const url = 'file://' + resolve(root, process.argv[2] || 'docs/prototype/index.html');

// Die Zahl der Pruefungen wird GEZAEHLT, nicht aufgeschrieben. In der
// Uebergabe stand lange "39 Pruefungen"; tatsaechlich laufen mehr, weil
// einige note()-Aufrufe in Schleifen stehen. Eine Zahl in einem Dokument
// veraltet still - eine, die der Lauf selbst ausgibt, kann das nicht.
let gezaehlt = 0;
const fails = [];
const note = (ok, text) => { gezaehlt++; console.log((ok?'  ok   ':'  FEHL ')+text); if(!ok) fails.push(text); };
const head = t => console.log('\n' + t);

const exe = process.env.CHROMIUM_PATH;
const browser = await chromium.launch(exe ? { executablePath: exe } : {});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

const jsErrors = [], netFails = [];
page.on('pageerror', e => jsErrors.push(e.message));
page.on('requestfailed', r => netFails.push(r.url()));
// Eine fehlgeschlagene Netzanfrage ist kein Programmfehler. Sie wird
// getrennt gezaehlt und benannt - verschwiegen wird sie nicht.
page.on('console', m => {
  if (m.type() !== 'error') return;
  if (/Failed to load resource/.test(m.text())) return;
  jsErrors.push(m.text());
});

await page.goto(url);
await page.waitForTimeout(400);

head('Onboarding — drei Schritte bis zur ersten Quest');
note(await page.locator('#onboard').isVisible(), 'Das Onboarding steht vor der App');
// Nicht `isVisible()` auf dem Hero fragen: Playwright kennt keine
// Verdeckung, das Element ist gerendert und gilt als sichtbar. Die Frage,
// auf die es ankommt, ist eine andere - deckt das Onboarding den Schirm
// wirklich ab, oder blitzt Home darunter durch?
{
  const ob = await page.locator('#onboard').boundingBox();
  const ph = await page.locator('#phone').boundingBox();
  note(ob.width >= ph.width - 1 && ob.height >= ph.height - 1,
       'Es deckt den ganzen Schirm ab - Home blitzt nicht durch');
  // Erreichbarkeit heisst: Was liegt an dieser Stelle wirklich oben?
  // Das beantwortet der Browser, nicht eine Rechnung mit Rechtecken.
  const verdeckt = await page.evaluate(() => {
    const b = document.querySelector('#primary').getBoundingClientRect();
    const oben = document.elementFromPoint(b.x + b.width/2, b.y + b.height/2);
    return !!oben && !!oben.closest('#onboard');
  });
  note(verdeckt, 'Die Hauptaktion von Home ist waehrenddessen nicht erreichbar');
}

// Die vier Versprechen. Sie sind der Grund, warum jemand weitertippt.
for (const w of ['Discover', 'Collect', 'Progress', 'Compete']) {
  note(await page.locator(`.promise .headline:text-is("${w}")`).isVisible(),
       `Versprechen sichtbar: ${w}`);
}
note((await page.locator('.ob-step.on .display').textContent()).includes('Discover'),
     'Der erste Schirm sagt, worum es geht, nicht wer wir sind');
note(await page.locator('.ob-step.on .btn').count() === 1,
     'Genau eine Hauptaktion im ersten Schritt');

await page.locator('#ob-go').click();
await page.waitForTimeout(200);
note((await page.locator('.ob-step.on .display').textContent()).includes('born'),
     'Schritt 2 fragt das Geburtsjahr - genau das nimmt complete_onboarding');

// Die Auswahl darf nur anbieten, was der Server annimmt. Sonst tippt
// jemand etwas ein und bekommt die Absage nach dem letzten Schritt.
{
  const jahre = (await page.locator('#ob-year option').allTextContents()).map(Number);
  const jetzt = new Date().getFullYear();
  note(Math.max(...jahre) === jetzt - 18,
       `Das juengste angebotene Jahr ist genau 18 Jahre her (${Math.max(...jahre)})`);
  note(Math.min(...jahre) === jetzt - 120,
       `Das aelteste ist 120 Jahre her (${Math.min(...jahre)})`);
  note(!jahre.includes(jetzt - 17), 'Ein 17-Jaehriger findet sein Jahr gar nicht erst');
  note(!await page.locator('#ob-age-next').isDisabled(),
       'Mit einer gueltigen Vorauswahl geht es weiter');
  // Dieselbe Vorgabe wie OnboardingRules.defaultBirthYear in BQCore.
  // Zwei Vorgaben waeren zwei Produkte.
  const vorgabe = Number(await page.locator('#ob-year').inputValue());
  note(vorgabe === jetzt - 25,
       `Die Vorauswahl steht in der Mitte des Erwartbaren (${vorgabe})`);
}

await page.locator('#ob-age-next').click();
await page.waitForTimeout(200);
note(await page.locator('[data-ob="2"].on').isVisible(), 'Schritt 3 ist die Namenswahl');
note(await page.locator('#ob-done').isDisabled(), 'Ohne Namen geht es nicht weiter');

// Der Wortfilter des Servers, hier vorweggenommen: wer ihn erst nach dem
// Tippen erfaehrt, tippt zweimal. is_term_allowed prueft auf Gleichheit
// UND auf Enthaltensein.
for (const boese of ['admin', 'xadminx', 'beerquest', 'the_moderator']) {
  await page.locator('#ob-name').fill(boese);
  await page.waitForTimeout(100);
  note(await page.locator('#ob-done').isDisabled(), `Gesperrt blockiert: ${boese}`);
}
note((await page.locator('#ob-name-hint').textContent()).length > 0,
     'Und er sagt auch, warum');

// Der Server will ^[a-z0-9_]{3,20}$. Statt zu korrigieren, wird
// vorgeschlagen - und der Vorschlag steht da, bevor er gespeichert wird.
await page.locator('#ob-name').fill('Steffen M.');
await page.waitForTimeout(120);
note((await page.locator('#ob-handle').textContent()).includes('@steffen_m'),
     'Aus "Steffen M." wird sichtbar der Handle @steffen_m');
note(!await page.locator('#ob-done').isDisabled(), 'Und er gibt frei');

await page.locator('#ob-name').fill('ab');
await page.waitForTimeout(120);
note(await page.locator('#ob-done').isDisabled(), 'Zwei Zeichen sind zu wenig');

await page.locator('#ob-name').fill('steffen');
await page.waitForTimeout(120);
note(!await page.locator('#ob-done').isDisabled(), 'Ein gueltiger Name gibt frei');
await page.locator('#ob-done').click();
await page.waitForTimeout(300);
note(!await page.locator('#onboard').isVisible(), 'Nach dem Onboarding ist es weg');
note((await page.locator('#uname').textContent()).trim() === 'steffen',
     'Der gewaehlte Name steht auf Home');

head('Home — eine dominante Hauptaktion');
note(await page.locator('#s-home.on').isVisible(), 'Home ist der Startschirm');
const primary = page.locator('#primary');
note(await primary.isVisible(), 'Die Hauptaktion ist sichtbar');
note((await primary.textContent()).trim().includes('DISCOVER'),
     'Die Hauptaktion heisst nach dem, was sie tut');
const pBox = await primary.boundingBox();
note(pBox.height >= 48, `Die Hauptaktion ist gross genug (${Math.round(pBox.height)} px)`);
// Genau ein Element in Akzentfarbe als Flaeche - sonst konkurrieren zwei
// Aktionen um denselben Blick.
const accentFilled = await page.evaluate(() => {
  const acc = getComputedStyle(document.documentElement).getPropertyValue('--accent').trim();
  const hex = c => { const m = c.match(/\d+/g);
    return m ? '#'+m.slice(0,3).map(n=>(+n).toString(16).padStart(2,'0')).join('') : ''; };
  return [...document.querySelectorAll('#s-home button, #primary')]
    .filter(b => b.offsetParent !== null && hex(getComputedStyle(b).backgroundColor) === acc).length;
});
note(accentFilled === 1, `Genau eine gefuellte Akzent-Aktion auf Home (${accentFilled})`);
note((await page.locator('#hero-title').textContent()).includes('Discover'),
     'Der Hero stellt die Frage, was es zu entdecken gibt');

head('Navigation');
for (const t of ['world','quests','clan','profile']) {
  await page.click(`nav button[data-t="${t}"]`);
  note(await page.locator(`#s-${t}.on`).isVisible(), `Tab "${t}" oeffnet sich`);
}
note(!(await page.locator('#primary').isVisible()),
     'Die Hauptaktion gehoert zu Home und folgt nicht in andere Tabs');
await page.click('nav button[data-t="home"]');

head('Check-in — so wenige Schritte wie moeglich');
await page.click('#primary');
note(await page.locator('#sheet.on').isVisible(), 'Das Sheet oeffnet sich');
note(await page.locator('#placeline').isVisible(),
     'Der Ort steht als Auskunft neben der Auswahl, nicht als eigener Schritt');
const place = await page.locator('#place-sub').textContent();
note(/Cecina/.test(place) && /Italy/.test(place),
     `Stadt und Land kommen automatisch ("${place.trim()}")`);
note(await page.locator('#tiles .tile').count() >= 2,
     'Vorschlaege stehen als grosse Kacheln bereit');
const tileBox = await page.locator('#tiles .tile').first().boundingBox();
note(tileBox.height >= 44 && tileBox.width >= 44,
     `Kacheln sind gross genug (${Math.round(tileBox.width)}x${Math.round(tileBox.height)} px)`);

// Die Zaehlung, die zaehlt: vom Home bis zum Reward.
await page.locator('#tiles .tile').first().click();
await page.waitForTimeout(900);
note(await page.locator('#reward.on').isVisible(),
     'Zwei Taps ab Home fuehren zum Reward — Sheet oeffnen, Bier tippen');

head('Reward — ein Spielmoment, keine Bestaetigungsmeldung');
note((await page.locator('#r-kicker').textContent()).trim() === 'Discovery complete',
     'Der Reward heisst nicht "gespeichert"');
const xp = await page.locator('#r-xp').textContent();
note(xp === '550', `Erster Check-in gibt volle 550 XP, ungekuerzt ("${xp}")`);
note(await page.locator('#r-list .disc').count() === 4,
     'Alle vier Entdeckungen einzeln aufgeschluesselt');
note(/Level up/.test(await page.locator('#r-extra').textContent()), 'Level-Up wird gefeiert');
note(await page.locator('#r-next').isVisible(),
     'Der Reward bietet den naechsten Schritt an, statt nur zu schliessen');

head('Beer World');
await page.click('#r-next');
await page.waitForTimeout(500);
note(await page.locator('#s-world.on').isVisible(), 'Der Weg fuehrt in die eigene Welt');
note(await page.locator('#world-svg .node').count() >= 1, 'Das entdeckte Land ist ein Knoten');
note((await page.locator('#world-count').textContent()).includes('1'), 'Der Zaehler stimmt');
await page.locator('#world-svg .node').first().click();
await page.waitForTimeout(300);
note((await page.locator('#world-title').textContent()) === 'Italy',
     'Ein Land laesst sich oeffnen (World -> Country)');
note(await page.locator('#world-svg .node.open').count() >= 1,
     'Offene Staedte warten sichtbar — eine Einladung, keine Bilanz');
const panel = await page.locator('#world-panel').textContent();
note(/waiting/.test(panel) && !/187/.test(panel),
     `Der Text lockt, statt zu bilanzieren ("${panel.trim().slice(0,60)}")`);
await page.locator('#world-svg .node:not(.open)').first().click();
await page.waitForTimeout(300);
note((await page.locator('#world-title').textContent()) === 'Cecina',
     'Eine Stadt laesst sich oeffnen (Country -> City)');
note(/Bar Aurora/.test(await page.locator('#world-panel').textContent()),
     'In der Stadt stehen die eigenen Orte');
note(await page.locator('#crumbs .crumb').count() >= 3, 'Der Weg zurueck ist sichtbar');
await page.locator('#crumbs .crumb').first().click();
await page.waitForTimeout(200);
note((await page.locator('#world-title').textContent()) === 'Beer World',
     'Die Brotkrumen fuehren zurueck');

head('Clan — warum sollte ich beitreten?');
await page.click('nav button[data-t="clan"]');
await page.waitForTimeout(300);
const clan = await page.locator('#s-clan').textContent();
note(/Hop Hunters/.test(clan) && /1\.284|1,284/.test(clan), 'Clan mit Level und XP');
note(/Discover 10 new places/.test(clan), 'Eine Clan-Quest gibt dem Clan einen Zweck');
note(/7/.test(clan) && /10/.test(clan), 'Der Fortschritt der Clan-Quest ist sichtbar');
note(await page.locator('#clan-members .card').count() >= 3, 'Mitglieder mit Rangliste');
note(/You/.test(clan), 'Die eigene Zeile ist markiert');

// THIS WEEK zeigt Orte mit Zahlen, keine Meldungen. "Verona - 14" ist ein
// Ort, an dem etwas los ist; "Lisa discovered Verona" ist eine Nachricht.
{
  const zeilen = await page.locator('#clan-week .headline').allTextContents();
  const zahlen = (await page.locator('#clan-week .num').allTextContents())
                   .map(t => parseInt(t, 10));
  note(zeilen.length >= 3, `THIS WEEK zeigt mehrere Orte (${zeilen.length})`);
  note(zeilen[0] === 'Verona' && zahlen[0] === 14,
       `Der Kopf der Liste ist ein Ort mit Zahl (${zeilen[0]} - ${zahlen[0]})`);
  note(zahlen.every((n, i) => i === 0 || n <= zahlen[i-1]),
       'Die Liste ist absteigend sortiert - oben steht, wo am meisten los ist');
  note(!/discovered/i.test(clan),
       'Keine Aktivitaetsmeldungen mehr - Orte, keine Nachrichten');
  note((await page.locator('#clan-week-hint').textContent()).includes('Verona'),
       'Eine Zeile sagt, was die Zahlen bedeuten');
}

head('Home → Clan — die Vorschau zeigt dasselbe wie der Clan-Schirm');
await page.click('nav button[data-t="home"]');
await page.waitForTimeout(250);
{
  const stadt = (await page.locator('#home-clan-city').textContent()).trim();
  const zahl  = (await page.locator('#home-clan-n').textContent()).trim();
  note(stadt === 'Verona' && zahl === '14',
       `Die Vorschau zeigt den Kopf der Clan-Woche (${stadt} - ${zahl})`);
  note((await page.locator('#home-clan-line').textContent()).length > 10,
       'Und sagt, was das mit mir zu tun hat');
  // Die schwebende Hauptaktion liegt UEBER dem Inhalt. Die letzte Karte lag
  // darunter und war halb verdeckt - im Kopf faellt das nicht auf, im
  // Screenshot sofort.
  {
    // Ganz nach unten scrollen - nur dort stellt sich die Frage ueberhaupt.
    await page.evaluate(() => {
      const sc = document.querySelector('#s-home .scroll');
      sc.scrollTop = sc.scrollHeight;
    });
    await page.waitForTimeout(200);
    const karte = await page.locator('#feed .card').boundingBox();
    const knopf = await page.locator('#primary').boundingBox();
    note(karte.y + karte.height <= knopf.y + 1,
         'Ganz unten gescrollt liegt die letzte Karte ueber der Hauptaktion');
    await page.evaluate(() => { document.querySelector('#s-home .scroll').scrollTop = 0; });
    await page.waitForTimeout(150);
  }
  await page.locator('#home-clan-city').click();
  await page.waitForTimeout(250);
  note(await page.locator('#s-clan.on').isVisible(),
       'Ein Tap auf die Vorschau fuehrt in den Clan');
}

head('Passport — Sammelzustaende statt Zaehlerstaende');
await page.click('nav button[data-t="profile"]');
await page.waitForTimeout(300);
{
  const stamps = page.locator('#passport .stamp');
  const n = await stamps.count();
  note(n >= 4, `Das Passport zeigt Felder (${n})`);
  note(await page.locator('#passport .stamp.discovered, #passport .stamp.completed, #passport .stamp.mastered').count() >= 1,
       'Was entdeckt wurde, traegt einen Stempel');
  const gesperrt = page.locator('#passport .stamp.locked');
  note(await gesperrt.count() >= 1, 'Und es gibt Felder, die noch warten');

  // Der Kern der Produkt-DNA: Ein gesperrtes Feld zeigt, WAS dort wartet -
  // nie, wie viel fehlt. "Waiting" statt "0 von 187.000".
  const ersterGesperrt = (await gesperrt.first().textContent()).trim();
  note(/Waiting/.test(ersterGesperrt), `Gesperrt heisst "Waiting" (${ersterGesperrt.replace(/\s+/g,' ')})`);
  note(!/\d+\s*(of|\/)\s*\d+/i.test(await page.locator('#passport').textContent()),
       'Nirgends eine Bilanz der Art "12 von 187.000"');
  note(/[A-Z][a-z]+/.test(ersterGesperrt.replace('Waiting','')),
       'Ein gesperrtes Feld nennt den Ort - eine Einladung, kein Platzhalter');
  note((await page.locator('#passport-hint').textContent()).length > 10,
       'Eine Zeile sagt, welcher Ort als Naechstes drankaeme');
}

head('Naechster Grund weiterzuspielen');
await page.click('nav button[data-t="home"]');
await page.waitForTimeout(300);
// aria-label statt textContent: Im Markup steht ein <br>, und textContent
// klebt die Zeilen zu "morebeers" zusammen. Das las sich in der Ausgabe wie
// ein Textfehler in der App, war aber einer im Test - die Stelle, an der
// wirklich der Satz steht, ist das Label fuer Sprachausgabe.
const hero = await page.locator('#hero-title').getAttribute('aria-label');
note(/Discover 2 more beers/.test(hero), `Nach dem Check-in steht ein neues Ziel da ("${hero.trim()}")`);
note(/Cecina/.test(hero), 'Das Ziel knuepft an den Ort an, an dem der Nutzer gerade war');
note((await page.locator('#c-country').textContent()) === '1', 'Die Zaehler sind gestiegen');

head('Qualitaet');
const overflow = await page.evaluate(() =>
  document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
note(!overflow, 'Kein horizontaler Ueberlauf');

const emoji = await page.evaluate(() => {
  const re = /\p{Extended_Pictographic}/u;
  return [...document.querySelectorAll('body *')]
    .filter(el => !el.children.length && re.test(el.textContent || '')).length;
});
note(emoji === 0, `Keine Emoji in der UI (gefunden: ${emoji})`);

// Tap-Ziele. Eine Hand, schlechtes Licht, laute Bar.
const small = await page.evaluate(() => {
  return [...document.querySelectorAll('button, [role="button"], input')]
    .filter(b => b.offsetParent !== null)
    .map(b => ({ t:(b.textContent||b.getAttribute('aria-label')||b.id||'?').trim().slice(0,24),
                 h:b.getBoundingClientRect().height, w:b.getBoundingClientRect().width }))
    .filter(b => b.h > 0 && (b.h < 32 || b.w < 32));
});
note(small.length === 0, `Alle sichtbaren Tap-Ziele mindestens 32 px (${small.length} zu klein)`);
if (small.length) small.slice(0,5).forEach(b =>
  console.log(`       "${b.t}" ${Math.round(b.w)}x${Math.round(b.h)}`));

// Keine Aussage darf allein an der Farbe haengen.
const labelled = await page.evaluate(() =>
  [...document.querySelectorAll('nav button')].every(b => (b.textContent||'').trim().length > 0));
note(labelled, 'Die Navigation traegt Text, nicht nur Symbole');

note(jsErrors.length === 0, `Keine JS-Fehler (${jsErrors.length})`);
if (jsErrors.length) jsErrors.forEach(e => console.log('       ' + e));

// Die Schrift kommt von Google Fonts. Ohne Netz greift die Ersatzkette -
// die Datei bleibt lesbar, sieht aber anders aus als beabsichtigt.
const fontFails = netFails.filter(u => /fonts\.(googleapis|gstatic)/.test(u));
if (fontFails.length) {
  console.log(`  hinweis  Schrift nicht geladen (${fontFails.length} Anfrage(n), kein Netz).`);
  console.log('           Die Ersatzkette traegt, aber die Typografie ist nicht die beabsichtigte.');
}
const fallback = await page.evaluate(() =>
  getComputedStyle(document.documentElement).getPropertyValue('--font'));
note(/Helvetica|system/i.test(fallback),
     'Die Schrift hat eine echte Ersatzkette, falls sie nicht laedt');

// Bewegungsreduktion respektieren
const reduced = await browser.newContext({ reducedMotion:'reduce', viewport:{width:390,height:844} });
const p2 = await reduced.newPage();
await p2.goto(url); await p2.waitForTimeout(300);
note(await p2.locator('#s-home.on').isVisible(), 'Die App traegt auch ohne Bewegung');
await reduced.close();

await browser.close();
console.log('\n' + (fails.length
  ? `FEHLGESCHLAGEN: ${fails.length} von ${gezaehlt} Pruefung(en)`
  : `Alle ${gezaehlt} Pruefungen bestanden`));
process.exit(fails.length ? 1 : 0);
