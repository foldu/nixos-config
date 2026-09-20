#!/usr/bin/env node
// Home Assistant API CLI — REST + WebSocket, no npm dependencies.
// Node 22+ (needs the global WebSocket).
//
//   export HA_URL=http://172.25.74.192:8123
//   export HA_TOKEN_FILE=/tmp/ha-token        (or HA_TOKEN)
//
// Run with no args (or `help`) for the command list.
import { readFileSync, writeFileSync } from 'node:fs';
import { BASE, die, token, headers, rest } from './ha-env.mjs';

if (typeof WebSocket === 'undefined') die('Node 22+ required (no global WebSocket)');

let send = null;
async function connectWs() {
  const url = BASE.replace(/^http/, 'ws') + '/api/websocket';
  return new Promise((resolve) => {
    const ws = new WebSocket(url);
    let id = 0; const pending = new Map();
    const call = (type, extra) => { const i = ++id; ws.send(JSON.stringify({ id: i, type, ...extra })); return new Promise((r) => pending.set(i, r)); };
    ws.onmessage = (m) => {
      const msg = JSON.parse(m.data);
      if (msg.type === 'auth_required') return ws.send(JSON.stringify({ type: 'auth', access_token: token() }));
      if (msg.type === 'auth_invalid') return die('WebSocket auth_invalid — bad token');
      if (msg.type === 'auth_ok') return resolve(call);
      if (msg.id && pending.has(msg.id)) { const r = pending.get(msg.id); pending.delete(msg.id); r(msg); }
    };
    ws.onerror = () => die('WebSocket connection failed: ' + url);
    setTimeout(() => die('WebSocket auth timeout'), 15000);
  });
}
async function ws(type, extra = {}) {
  if (!send) send = await connectWs();
  return send(type, extra);
}
async function wsOk(type, extra = {}) {
  const res = await ws(type, extra);
  if (res.success === false) die(`${type} failed: ${JSON.stringify(res.error)}`);
  return res.result;
}

const argv = process.argv.slice(2);
const flag = (name) => { const i = argv.indexOf(name); return i === -1 ? null : argv[i + 1]; };
// flags that take a value: skip the value too when collecting positionals
const NO_VALUE_FLAGS = new Set(['--assert', '--no-clips']);
const positional = [];
for (let i = 0; i < argv.length; i++) {
  if (argv[i].startsWith('--')) { if (NO_VALUE_FLAGS.has(argv[i]) === false) i++; continue; }
  positional.push(argv[i]);
}
const json = (s) => { try { return JSON.parse(s); } catch (e) { die('invalid JSON: ' + e.message); } };
const out = (v) => console.log(typeof v === 'string' ? v : JSON.stringify(v, null, 2));

const usage = `Home Assistant API CLI

  states [regex]                    entity_id, state, friendly_name (filtered)
  state <entity_id>
  template '<jinja>'                rendered via REST (WS render_template is a stub)
  service <domain>.<service> ['{}']  call a service
  service-fields <domain>.<service>  that service's fields, types and required flags
  related <entity_id>

  ws <type> ['{}']                  raw WebSocket command
  entity-rename <entity_id> <name|null>
  entity-icon <entity_id> <mdi:icon|null>
  entity-update <entity_id> '{...}'  raw config/entity_registry/update payload
  entity-remove <entity_id>
  device-remove <device_id>
  entry list
  entry delete <entry_id>
  entry reload <entry_id>

  automation get <id>
  automation put <id> <file.json>
  automation delete <id>

  dash list
  dash get <url_path> [--file out.json]
  dash save <url_path> <file.json>
  dash create <url_path> <title> [icon]     (url_path MUST contain a hyphen)
  resources
  themes

  missing <dashboard.json>          verify every referenced entity exists
  help`;

const [cmd, a, b, c, d] = positional;
switch (cmd) {
  case undefined:
  case 'help': console.log(usage); break;

  case 'states': {
    const list = await rest('/api/states');
    const re = a ? new RegExp(a, 'i') : null;
    for (const s of list) {
      const name = s.attributes.friendly_name || '';
      if (!re || re.test(s.entity_id) || re.test(name)) console.log(`${s.entity_id.padEnd(58)} ${String(s.state).padEnd(16)} ${name}`);
    }
    break;
  }

  case 'state': out(await rest('/api/states/' + a)); break;

  case 'template': {
    const res = await fetch(`${BASE}/api/template`, { method: 'POST', headers: headers(), body: JSON.stringify({ template: a }) });
    console.log((await res.text()).trim(), `(${res.status})`);
    break;
  }

  case 'service': await rest(`/api/services/${String(a).replace('.', '/')}`, { method: 'POST', body: b || '{}' }); console.log('ok', a); break;

  case 'service-fields': {
    // /api/services is the closest thing Home Assistant has to a schema: every service
    // with its fields, required flags and selector types. Use it instead of guessing.
    const domains = await rest('/api/services');
    const [dom, svc] = String(a).split('.');
    const d = domains.find((x) => x.domain === dom);
    const s = d && d.services[svc];
    if (!s) die(`unknown service ${a}`);
    console.log(`${a} — ${(s.description || s.name || '').trim()}`);
    for (const [f, meta] of Object.entries(s.fields || {})) {
      const sel = meta.selector ? Object.keys(meta.selector).join('/') : (meta.description || '').slice(0, 70);
      console.log(`  ${f}${meta.required ? ' (required)' : ''}: ${sel}`);
    }
    break;
  }

  case 'related': out(await wsOk('search/related', { item_type: 'entity', item_id: a })); break;

  case 'ws': out(await ws(a, b ? json(b) : {})); break;

  case 'entity-rename': out(await wsOk('config/entity_registry/update', { entity_id: a, name: b === 'null' ? null : b })); break;
  case 'entity-icon': out(await wsOk('config/entity_registry/update', { entity_id: a, icon: b === 'null' ? null : b })); break;
  case 'entity-update': out(await wsOk('config/entity_registry/update', { entity_id: a, ...json(b) })); break;
  case 'entity-remove': out(await wsOk('config/entity_registry/remove', { entity_id: a })); break;
  case 'device-remove': out(await wsOk('config/device_registry/remove', { device_id: a })); break;

  case 'entry':
    if (a === 'list') out(await rest('/api/config/config_entries/entry'));
    else if (a === 'delete') out(await rest('/api/config/config_entries/entry/' + b, { method: 'DELETE' }));
    else if (a === 'reload') out(await rest(`/api/config/config_entries/entry/${b}/reload`, { method: 'POST' }));
    else die('entry list|delete|reload');
    break;

  case 'automation':
    if (a === 'get') out(await rest('/api/config/automation/config/' + b));
    else if (a === 'put') {
      const res = await fetch(`${BASE}/api/config/automation/config/${b}`, { method: 'POST', headers: headers(), body: readFileSync(c, 'utf8') });
      console.log(res.status, (await res.text()).slice(0, 200));
    } else if (a === 'delete') out(await rest('/api/config/automation/config/' + b, { method: 'DELETE' }));
    else die('automation get|put|delete');
    break;

  case 'dash':
    if (a === 'list') out(await wsOk('lovelace/dashboards/list'));
    else if (a === 'get') {
      const cfg = await wsOk('lovelace/config', { url_path: b });
      const file = flag('--file');
      if (file) { writeFileSync(file, JSON.stringify(cfg, null, 2) + '\n'); console.log('wrote', file, '| views:', cfg.views.length); }
      else out(cfg);
    } else if (a === 'save') {
      const cfg = JSON.parse(readFileSync(c, 'utf8'));
      await wsOk('lovelace/config/save', { url_path: b, config: cfg });
      console.log('saved', b, '| views:', cfg.views?.length);
    } else if (a === 'create') {
      const url_path = b;
      if (url_path.includes('-') === false) die('url_path must contain a hyphen (HA validates this)');
      const dash = await wsOk('lovelace/dashboards/create', { url_path, title: c, icon: d || 'mdi:view-dashboard', require_admin: false, show_in_sidebar: true, mode: 'storage' });
      console.log('created', JSON.stringify(dash));
    } else die('dash list|get|save|create');
    break;

  case 'resources': out(await wsOk('lovelace/resources')); break;
  case 'themes': out(await wsOk('frontend/get_themes')); break;

  case 'missing': {
    const cfg = JSON.parse(readFileSync(a, 'utf8'));
    const states = await rest('/api/states');
    const live = new Set(states.map((s) => s.entity_id));
    const missing = new Set();
    const seen = new Set();
    (function walk(node) {
      if (Array.isArray(node)) return node.forEach(walk);
      if (node && typeof node === 'object') {
        if (typeof node.entity === 'string' && live.has(node.entity) === false) missing.add(node.entity);
        if (seen.has(node)) return;
        seen.add(node);
        Object.values(node).forEach(walk);
      }
    })(cfg);
    console.log(missing.size ? `missing ${missing.size}: ` + [...missing].join(', ') : 'missing entities: none');
    if (missing.size) process.exit(1);
    break;
  }

  default: die(`unknown command "${cmd}"\n\n${usage}`);
}
process.exit(0);
