#!/usr/bin/env node
// Screenshot + DOM-assert Home Assistant views in a real headless browser.
//
//   node hass-shot.mjs my-home/overview --scheme both --assert
//   node hass-shot.mjs my-home/bedroom my-home/office --width 1920 --out /tmp/shots
//
// Writes <out>/<view>-<scheme>-full.png, -top.png and per-section clips (-s0, -s1, ...),
// and reports what the DOM actually did: custom cards mounted, hui-error-card contents,
// console errors, unrendered {{ }}.
import { mkdirSync } from 'node:fs';
import { BASE, token, die, loadPlaywright, chromiumPath } from './ha-env.mjs';

const argv = process.argv.slice(2);
const flagVal = (name, dflt) => { const i = argv.indexOf(name); return i === -1 ? dflt : argv[i + 1]; };
const paths = argv.filter((a, i) => a.startsWith('--') === false && (i === 0 || argv[i - 1].startsWith('--') === false));
if (paths.length === 0) {
  die('usage: hass-shot.mjs <dashboard/view> [...] [--scheme light|dark|both] [--width 1600] [--out /tmp/shots] [--assert] [--no-clips]');
}
const schemeArg = flagVal('--scheme', 'light');
const schemes = schemeArg === 'both' ? ['light', 'dark'] : [schemeArg];
const width = Number(flagVal('--width', 1600));
const outDir = flagVal('--out', '/tmp/shots');
const assertMode = argv.includes('--assert');
const wantClips = argv.includes('--no-clips') === false;

const { chromium } = loadPlaywright();
const executablePath = chromiumPath();
mkdirSync(outDir, { recursive: true });
const problems = [];

for (const scheme of schemes) {
  const browser = await chromium.launch({ executablePath, args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--font-render-hinting=none'] });
  const ctx = await browser.newContext({ viewport: { width, height: 1000 }, colorScheme: scheme, deviceScaleFactor: 1 });
  // The frontend reads localStorage.hassTokens; refresh_token must be non-empty or HA bounces to /auth/authorize.
  await ctx.addInitScript(([t, h]) => {
    localStorage.setItem('hassTokens', JSON.stringify({
      access_token: t, token_type: 'Bearer', expires_in: 315360000,
      refresh_token: 'x', clientId: h, hassUrl: h, expires: Date.now() + 315360000000,
    }));
  }, [token(), BASE]);
  const page = await ctx.newPage();
  // Shadow-DOM helpers: the HA frontend renders everything inside shadow roots, so
  // document.body.innerText is empty and querySelector sees almost nothing.
  await page.addInitScript(() => {
    window.__deep = (sel, root) => {
      const found = [];
      // include the root's OWN shadow root too: a non-document root hides its children there
      const walk = (r) => {
        found.push(...r.querySelectorAll(sel));
        if (r.shadowRoot) walk(r.shadowRoot);
        for (const e of r.querySelectorAll('*')) if (e.shadowRoot) walk(e.shadowRoot);
      };
      walk(root || document);
      return found;
    };
    window.__deepText = (el) => {
      let text = el.textContent || '';
      if (el.shadowRoot) {
        text += ' ' + window.__deepText(el.shadowRoot);
        for (const child of el.shadowRoot.querySelectorAll('*')) if (child.shadowRoot) text += ' ' + window.__deepText(child);
      }
      return text;
    };
  });
  const errors = [];
  page.on('console', (m) => { if (m.type() === 'error') errors.push(m.text().slice(0, 240)); });
  page.on('pageerror', (e) => errors.push('PAGEERROR ' + String(e).slice(0, 240)));

  for (const path of paths) {
    const name = path.replace(/[^a-zA-Z0-9]+/g, '-').replace(/^-|-$/g, '');
    await page.goto(`${BASE}/${path}`, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(1200);
    try {
      await page.waitForSelector('hui-section, hui-view', { timeout: 30000 });
    } catch {
      problems.push(`${path}: view never rendered (no hui-section/hui-view)`);
      console.log(`!!! ${path}: view did not render — check the path and the token`);
    }
    await page.waitForTimeout(3500); // let cards + custom elements settle

    const info = await page.evaluate(() => {
      const custom = {};
      for (const el of window.__deep('*')) {
        const tag = el.tagName.toLowerCase();
        if (tag.startsWith('mushroom-')) custom[tag] = (custom[tag] || 0) + 1;
      }
      const root = document.querySelector('hui-view') || document.body;
      const text = window.__deepText(root);
      return {
        path: location.pathname,
        custom,
        errCards: window.__deep('hui-error-card').map((e) => window.__deepText(e).replace(/\s+/g, ' ').trim().slice(0, 160)),
        literalBraces: text.includes('{{'),
        configError: /configuration error|custom element doesn/i.test(text),
        sections: window.__deep('hui-section').length,
        height: document.documentElement.scrollHeight,
      };
    });

    console.log(`--- ${path} ${info.path} | ${scheme} | sections=${info.sections} height=${info.height}`);
    if (Object.keys(info.custom).length) console.log('    custom cards: ' + JSON.stringify(info.custom));
    if (info.errCards.length) { console.log('    ERROR CARDS: ' + JSON.stringify(info.errCards)); problems.push(`${path}: ${info.errCards.length} hui-error-card(s)`); }
    if (info.literalBraces) { console.log('    !! unrendered {{ }} in rendered text'); problems.push(`${path}: literal {{ }}`); }
    if (info.configError) { console.log('    !! "configuration error" text present'); problems.push(`${path}: configuration error`); }
    if (info.sections === 0) console.log('    note: no hui-section — not a sections view?');

    await page.evaluate(() => window.scrollTo(0, 0));
    await page.waitForTimeout(300);
    await page.screenshot({ path: `${outDir}/${name}-${scheme}-full.png`, fullPage: true });
    await page.screenshot({ path: `${outDir}/${name}-${scheme}-top.png` });
    if (wantClips) {
      const count = await page.locator('hui-section').count();
      for (let i = 0; i < count; i++) {
        try { await page.locator('hui-section').nth(i).screenshot({ path: `${outDir}/${name}-${scheme}-s${i}.png` }); } catch { /* zero-size section */ }
      }
    }
  }

  const unique = [...new Set(errors)];
  console.log(`--- console errors (${scheme}): ` + (unique.length ? '\n    ' + unique.slice(0, 10).join('\n    ') : 'none'));
  if (unique.length) problems.push(`${scheme}: ${unique.length} console error(s)`);
  await browser.close();
}

console.log(problems.length ? `\nFAIL: ${problems.length} problem(s)\n  ` + problems.join('\n  ') : `\nOK: ${paths.length} view(s) x ${schemes.length} scheme(s) rendered clean — now LOOK at the PNGs in ${outDir}`);
process.exit(problems.length && assertMode ? 1 : 0);
