---
name: home-assistant
description: Configure, clean up and prettify a live Home Assistant instance over its REST and WebSocket APIs — automations, entity/device registry work, Lovelace dashboards, Mushroom cards — then verify the result in a real headless browser instead of guessing. Use for any Home Assistant task: editing or deleting automations, renaming or removing entities/devices, building or restyling dashboards, diagnosing a card that looks wrong, or checking why an entity reads unavailable.
---

# Home Assistant

Distilled from working against a live instance (HA 2026.9.3, `hass.home.5kw.li` → saturn Caddy → `172.25.74.192:8123`). Two rules shape everything below:

1. **Look at the render** before calling a UI change done. The DOM and the API will both lie to you by omission.
2. **Trust the registry, not the YAML** — entities you cannot find in `configuration.yaml` are usually UI-created (config entry / retained MQTT discovery).

## Setup

```bash
export HA_URL=http://172.25.74.192:8123     # hass box; see home-network.toml
export HA_TOKEN_FILE=/tmp/ha-token           # chmod 600, or pass HA_TOKEN
mkdir -p /tmp/pw && (cd /tmp/pw && npm i playwright-core)   # browser harness; no browser download
export PW_PATH=/tmp/pw/node_modules/playwright-core
export CHROME_PATH=$(command -v chromium)    # system chromium is fine
```

Node 22+ (global `WebSocket`). Never echo the token into output.

## Which API has what

| Task | Endpoint |
|---|---|
| States, services, history, logbook | REST `/api/states`, `/api/services`, `/api/history/period`; WS `history/history_during_period`, `logbook/get_events` |
| Render a template | **REST** `POST /api/template` (`{"template": "..."}`). WS `render_template` is a stub returning `null` |
| Automation create/update/delete | REST `POST|DELETE /api/config/automation/config/{unique_id}` |
| Config entry delete / reload | REST `DELETE /api/config/config_entries/entry/{entry_id}`, `POST .../{entry_id}/reload`. No WS command exists |
| Entity/device registry read + write | **WS only**: `config/entity_registry/{list,get,update,remove}`, `config/device_registry/{list,update,remove}` |
| Dashboards (Lovelace) | **WS only**: `lovelace/config`, `lovelace/config/save`, `lovelace/dashboards/{list,create,delete}`, `lovelace/resources`, `frontend/get_themes` |
| Anything else | `node scripts/ha-api.mjs ws <type> '{...}'` |

## Scripts

```bash
node scripts/ha-api.mjs states 'qrevo'          # grep states + friendly names
node scripts/ha-api.mjs template '{{ states("sun.sun") }}'
node scripts/ha-api.mjs ws config/entity_registry/list
node scripts/ha-api.mjs entity-rename sensor.x 'Bedroom humidity'   # or null to revert
node scripts/ha-api.mjs automation put 1789899581370 /tmp/a.json
node scripts/ha-api.mjs dash get my-home --file /tmp/dash.json      # read, then patch on disk
node scripts/ha-api.mjs dash save my-home /tmp/dash.json
node scripts/ha-api.mjs missing /tmp/dash.json                      # every referenced entity exists?

node scripts/hass-shot.mjs my-home/overview --scheme both --assert   # screenshots + DOM assertions
```

`hass-shot.mjs` writes `*-full.png`, `*-top.png` and per-section clips, and fails (`--assert`) on `hui-error-card`s, console errors, unmounted custom cards, or unrendered `{{ }}`. **Read the PNGs with the image-capable read tool** — that is the whole point.

## The loop that works

1. **Read** current config (`dash get` / `automation get`) to a file on disk.
2. **Patch** the file (write tool + a small node script beats hand-editing JSON).
3. **Save** through the API, then **read it back** and diff expectations (section/card counts, `dense`, header present).
4. **Shoot** and look. Assert error cards / console errors / custom elements mounted.
5. Only then report — with the numbers you actually saw.

## Don't relearn these

- **Entities card has no graph row.** Rows are only `attribute|button|buttons|cast|conditional|divider|section|weblink`. Sparklines = a `sensor` card with `graph: line` + `hours_to_show`.
- **`secondary_info`** accepts `entity-id|last_changed|last_updated|area_name|floor_name|device_name|state` or **any attribute**. `last-triggered` is invalid; automations use `secondary_info: last_triggered` (the attribute).
- **Sections view:** `max_columns` and `dense_section_placement` are *view* keys; `column_span` works on *sections*; cards inside a grid section size to their content, so tiles/Mushroom cards render **half a column wide** while `entities`/`markdown`/`history-graph` cards take the full column. Rows align to the tallest section in the row, so a single tall section leaves a large hole → **split tall sections** (this took Overview from 1665px to 1183px).
- **Header + badges** (`header.card` = a markdown card, templated; `badges` = entity badges) is the native hero. Entity badges default to `show_name: false`, so set it or you get a bare "Off".
- **`picture-entity`** accepts `aspect_ratio` (`133%`, `16:9`) and `fit_mode` (`cover|contain`). Without them a portrait vacuum map renders ~740px tall.
- **Mushroom**: check `lovelace/resources` first — the resource must be registered as `module` before any `custom:mushroom-*` card renders. Use `collapsible_controls: true` on light/fan cards so an off entity shows a power icon instead of a dead slider. Chips (`alignment: start|justify`) are the compact way to show status; `entity` chips with `content_info: name` read better than six light chips saying "Off".
- **Native `tile` cards lie about fans**: an off fan with a stale `percentage` displays "33%" instead of "Off". `custom:mushroom-fan-card` shows the real state.
- **Cards that are in the registry but named oddly**: the *visible* name may live in `name_by_user` (devices) rather than `name` — match `(name_by_user || name)`. Revert with `"name": null`.
- **Automations via API** need top-level `alias`/`trigger`/`action`; blueprints cannot be written this way. Make them manually runnable: no `trigger.id` gating — use state-based `choose` branches. Suppression conditions must be `!= 'on'` (not `== 'off'`) so `unknown` can never leave a room dark.
- **Deleting devices**: a Tasmota/ESP device that reappears after deletion is being recreated by a **retained MQTT discovery topic** — publish `""` with `retain: true` to `tasmota/discovery/<MAC>/config` and the integration removes the device itself. Nagging `unavailable` + `restored: true` registry entries are orphans: remove via `config/entity_registry/remove`.

## Environment gotchas

- **`!` in bash heredocs** gets mangled to `\!` and breaks Node (`!==`, `!x` → `SyntaxError`). Use the `write` tool for scripts instead of heredocs.
- **Shadow DOM everywhere**: `document.body.innerText` is empty on the HA frontend. Walk `shadowRoot`s (see `hass-shot.mjs`'s `__deep`) or use Playwright locators, which pierce.
- **Frontend auth**: inject `localStorage.hassTokens` with a **non-empty** `refresh_token` — an empty one bounces you to `/auth/authorize`. A long-lived token cannot be exchanged with `grant_type=refresh_token` (400 `invalid_grant`), so inject it as the `access_token` with a far-future `expires`.
- **Registries**: areas are keyed by `area_id` (not `id`); `config_entries/get` is read-only-ish, deletion is REST-only.

## Conventions worth copying

- Global names stay **generic and function-only** ("Chandelier", "Battery", "Total energy"); device name and area supply the context. Disambiguate per card with `{"entity": "...", "name": "..."}` instead of renaming globally.
- Prefer native cards; reach for Mushroom for single-entity pretties (lights, fans, vacuum, select, update, person) and keep `entities`/`history-graph`/`markdown` where labels and density matter.
- Themes are settable per **view** and per **section**, so a dashboard change does not depend on each user's profile.

Deep reference: [references/api-notes.md](references/api-notes.md) (registry/automation/deletion recipes) and [references/dashboard-notes.md](references/dashboard-notes.md) (card schema, layout mechanics, Mushroom inventory, themes).
