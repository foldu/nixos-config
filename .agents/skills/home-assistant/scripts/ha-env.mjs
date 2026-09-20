// Shared environment/token/Playwright resolution for the home-assistant skill scripts.
import { readFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { createRequire } from 'node:module';

export const die = (msg) => { console.error('error: ' + msg); process.exit(1); };

export const BASE = (process.env.HA_URL || '').replace(/\/+$/, '');
if (!BASE) die('set HA_URL, e.g. export HA_URL=http://172.25.74.192:8123');

export function token() {
  if (process.env.HA_TOKEN) return process.env.HA_TOKEN.trim();
  const file = process.env.HA_TOKEN_FILE || '/tmp/ha-token';
  try { return readFileSync(file, 'utf8').trim(); } catch { die(`no token: set HA_TOKEN or HA_TOKEN_FILE (tried ${file})`); }
}

export const headers = () => ({ Authorization: 'Bearer ' + token(), 'Content-Type': 'application/json' });

export async function rest(path, init = {}) {
  const res = await fetch(BASE + path, { headers: headers(), ...init });
  const body = await res.text();
  if (!res.ok) die(`${init.method || 'GET'} ${path} -> ${res.status} ${body.slice(0, 300)}`);
  if (body === '') return null;
  return /^[[{]/.test(body) ? JSON.parse(body) : body;
}

// playwright-core is not vendored here: resolve it from PW_PATH or a scratch install.
export function loadPlaywright() {
  const require = createRequire(import.meta.url);
  const candidates = [process.env.PW_PATH, '/tmp/pw/node_modules/playwright-core', join(process.env.HOME || '/tmp', 'node_modules/playwright-core')];
  for (const c of candidates) {
    if (c && existsSync(c)) { try { return require(c); } catch (e) { die(`failed to load ${c}: ${e.message}`); } }
  }
  die('playwright-core not found — run: mkdir -p /tmp/pw && (cd /tmp/pw && npm i playwright-core), or set PW_PATH');
}

// System chromium is enough; none of these need the Playwright browser download.
export function chromiumPath() {
  if (process.env.CHROME_PATH) return process.env.CHROME_PATH;
  const names = ['chromium', 'chromium-browser', 'google-chrome', 'google-chrome-stable', 'chrome'];
  for (const dir of (process.env.PATH || '').split(':')) {
    for (const n of names) {
      const p = join(dir, n);
      if (dir && existsSync(p)) return p;
    }
  }
  die('no chromium found — install one or set CHROME_PATH');
}
