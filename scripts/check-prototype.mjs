/**
 * Prueft den klickbaren Prototyp mit einem echten Browser.
 * Nach dem Vorbild aus PulseMeter: erst pruefen, dann veroeffentlichen.
 *
 * Geprueft wird der Core Loop - genau das, was der PM ausprobieren soll:
 * Home -> Check-in -> Reward -> Home mit aktualisierten Zahlen.
 * Dazu: keine JS-Fehler, kein horizontaler Ueberlauf, keine Emoji in der UI.
 */
import { chromium } from 'playwright';
import { fileURLToPath } from 'url';
import { dirname, resolve } from 'path';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const url = 'file://' + resolve(root, process.argv[2] || 'docs/prototype/index.html');

const fails = [];
const note = (ok, text) => { console.log((ok ? '  ok   ' : '  FEHL ') + text); if (!ok) fails.push(text); };

// Auf dem CI-Runner liefert Playwright seinen eigenen Browser mit. In
// Umgebungen mit vorinstalliertem Chromium (z. B. dieser Arbeitscontainer)
// zeigt CHROMIUM_PATH darauf - sonst waeren die Build-Nummern verschieden
// und der Start schlaegt fehl.
const exe = process.env.CHROMIUM_PATH;
const browser = await chromium.launch(exe ? { executablePath: exe } : {});
const page = await browser.newPage({ viewport: { width: 390, height: 844 } });

const jsErrors = [];
page.on('pageerror', e => jsErrors.push(e.message));
page.on('console', m => { if (m.type() === 'error') jsErrors.push(m.text()); });

await page.goto(url);
await page.waitForTimeout(250);

console.log('\nHome');
note(await page.locator('#s-home.on').isVisible(), 'Home ist der Startschirm');
note((await page.locator('#lvl').textContent()) === '1', 'Neuer Nutzer startet auf Level 1');
note((await page.locator('#c-beer').textContent()) === '0', 'Passport startet leer');
const xp0 = await page.locator('#xptext').textContent();
note(/\d+ \/ \d+ XP/.test(xp0), `XP-Fortschritt lesbar ("${xp0}")`);
note(await page.locator('#goal-label').isVisible(), 'Naechstes Ziel ist sichtbar');
note((await page.locator('.strip .stat').count()) === 4, 'Passport-Streifen hat vier Zaehler');
note(await page.locator('#add').isVisible(), 'ADD BEER ist immer erreichbar');

console.log('\nNavigation');
for (const t of ['map', 'quests', 'clan', 'profile']) {
  await page.click(`nav button[data-t="${t}"]`);
  note(await page.locator(`#s-${t}.on`).isVisible(), `Tab "${t}" oeffnet sich`);
}
note((await page.locator('#s-map .tag').textContent()).trim() === 'Platzhalter',
     'Platzhalterschirme sind als solche gekennzeichnet');
await page.click('nav button[data-t="home"]');

console.log('\nCheck-in');
await page.click('#add');
note(await page.locator('#sheet.on').isVisible(), 'Sheet oeffnet sich');
note((await page.locator('#step-label').textContent()) === 'Which beer?', 'Schritt 1: Bier');

await page.fill('#beer-q', 'Peroni');
await page.waitForTimeout(120);
const hits = await page.locator('#beer-list .opt').count();
note(hits >= 1, `Suche nach "Peroni" liefert ${hits} Vorschlag/Vorschlaege`);
note(await page.locator('#beer-list .opt').first().textContent()
       .then(t => /Peroni Nastro Azzurro/.test(t)),
     'Der passende Treffer steht oben - kein Dublettenrisiko durch Abkuerzung');

await page.fill('#beer-q', 'Ichnusa');
await page.waitForTimeout(120);
await page.locator('#beer-list .opt').first().click();
note((await page.locator('#step-label').textContent()) === 'Where?', 'Schritt 2: Ort');
note((await page.locator('#venue-list .opt').count()) >= 2, 'Orte in der Naehe werden vorgeschlagen');

await page.locator('#venue-list .opt').nth(1).click();
note((await page.locator('#step-label').textContent()) === 'Confirm', 'Schritt 3: Bestaetigen');
const sum = await page.locator('#sum-place').textContent();
note(/Cecina/.test(sum) && /Italy/.test(sum),
     'Stadt und Land stehen automatisch da - sie werden nie abgefragt');

console.log('\nReward');
await page.click('#save');
await page.waitForTimeout(300);
note(await page.locator('#reward.on').isVisible(), 'Reward-Screen erscheint');
const gained = await page.locator('#r-xp').textContent();
// Der erste Check-in ist vom Tages-Cap ausgenommen: 50+50+150+300 = 550 XP.
// Faellt dieser Test, ist die wichtigste Produktentscheidung der letzten
// Sessions im Prototyp nicht mehr abgebildet.
note(gained === '+550', `Erster Check-in gibt volle 550 XP, ungekuerzt ("${gained}")`);
const cards = await page.locator('#r-list .disc').count();
note(cards === 4, `Alle vier Entdeckungen einzeln aufgeschluesselt (${cards} Karten)`);
note(await page.locator('#r-extra').textContent().then(t=>/Level up/.test(t)),
     'Level-Up wird gefeiert');

await page.click('#done');
await page.waitForTimeout(300);
note(await page.locator('#s-home.on').isVisible(), 'Zurueck auf Home');
const xp1 = await page.locator('#xptext').textContent();
note(xp1 !== xp0, `XP haben sich sichtbar geaendert ("${xp0}" -> "${xp1}")`);
note((await page.locator('#c-beer').textContent()) === '1', 'Passport-Zaehler Biere ist gestiegen');
note((await page.locator('#c-country').textContent()) === '1', 'Land wurde automatisch mitgezaehlt');
note((await page.locator('#qdots i.done').count()) === 1, 'Quest-Fortschritt ist sichtbar');

console.log('\nQualitaet');
const overflow = await page.evaluate(() =>
  document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
note(!overflow, 'Kein horizontaler Ueberlauf');
const emoji = await page.evaluate(() => {
  const re = /\p{Extended_Pictographic}/u;
  return [...document.querySelectorAll('body *')]
    .filter(el => ![...el.children].length && re.test(el.textContent || '')).length;
});
note(emoji === 0, `Keine Emoji in der UI (gefunden: ${emoji})`);
note(jsErrors.length === 0, `Keine JS-Fehler (${jsErrors.length})`);
if (jsErrors.length) jsErrors.forEach(e => console.log('       ' + e));

await browser.close();
console.log('\n' + (fails.length ? `FEHLGESCHLAGEN: ${fails.length} Pruefung(en)` : 'Alle Pruefungen bestanden'));
process.exit(fails.length ? 1 : 0);
