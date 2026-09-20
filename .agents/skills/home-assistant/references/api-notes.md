# Home Assistant API notes

All verified against a live instance (HA 2026.9.3). `$BASE` = `$HA_URL`.

## Auth

- Token: long-lived access token, sent as `Authorization: Bearer <token>`. Never echo it.
- WebSocket: `ws://<host>:8123/api/websocket` → first frame `{"type":"auth_required"}` → send `{"type":"auth","access_token":"..."}` → `auth_ok`.
- Node 22+ has a global `WebSocket`, so no dependency is needed (`scripts/ha-api.mjs ws ...`).
- The frontend's own auth is different: it stores `localStorage.hassTokens` (`access_token`, `token_type`, `expires_in`, `refresh_token`, `clientId`, `hassUrl`, `expires`). A long-lived token **cannot** be exchanged: `POST /auth/token` with `grant_type=refresh_token` → `400 {"error":"invalid_grant"}`. Inject it as `access_token` with a far-future `expires` and a **non-empty** `refresh_token`.

## REST

| Method + path | Body / notes |
|---|---|
| `GET /api/states` | all states (entity_id, state, attributes, last_changed) |
| `GET /api/states/<entity_id>` | one state |
| `POST /api/template` | `{"template": "..."}` → rendered text; HTTP 400 + `{"message":"Error rendering template: ..."}` on bad syntax. **Use this**, the WS `render_template` command returns `null` in this version |
| `POST /api/services/<domain>/<service>` | service data; `{"type":"toggle","entity_id":"automation.x"}` |
| `POST /api/config/automation/config/<unique_id>` | full automation config (see below) |
| `DELETE /api/config/automation/config/<unique_id>` | delete automation |
| `GET /api/config/config_entries/entry` | list entries (id, domain, title, state) |
| `DELETE /api/config/config_entries/entry/<entry_id>` | delete an integration entry |
| `POST /api/config/config_entries/entry/<entry_id>/reload` | reload an integration |
| `GET /api/history/period/<iso8601>?filter_entity_id=...` | history |

## WebSocket (no REST equivalent)

```
config/entity_registry/list | get | update | remove
config/device_registry/list | update | remove
config_entries/get
lovelace/config | lovelace/config/save | lovelace/dashboards/list | lovelace/dashboards/create | lovelace/resources
frontend/get_themes
get_states | get_services | call_service
search/related
history/history_during_period | logbook/get_events
```

Missing on purpose (that cost real time): there is **no** `config_entries/remove` WS command (use REST `DELETE`), and `config_entries/reload` does not exist either (use the REST reload).

## Registry recipes

```js
// rename (visible label) / revert
config/entity_registry/update { entity_id, name: "Battery" }      // name: null reverts
// icons
config/entity_registry/update { entity_id, icon: "mdi:brush" }    // icon: null reverts
// hide from the auto-generated dashboard
config/entity_registry/update { entity_id, hidden_by: "user" }
// bulk edits: read once with config/entity_registry/list, update the ones you match
```

- **Devices**: the visible name usually lives in `name_by_user` (base `name` stays the vendor string), e.g. `BILRESA dual button`, `TIMMERFLOTTE temp/hmd sensor`. Match `(name_by_user || name)` when bulk-renaming, or you will silently miss devices.
- **Area assignment is on the device**, not the entity: `config/device_registry/update { device_id, area_id }`.
- **Areas** are keyed by `area_id` (`bathroom`, `office`, …) — not `id`.
- An entity that is `unavailable` **and** `restored: true` with no `config_entry_id` is an orphaned registry entry: `config/entity_registry/remove`.

## Deleting things that come back

- **UI-created device with no YAML trace** (e.g. a `switch.jupiter` from a "Wake on LAN" entry): find the owner with `config_entries/get`, then `DELETE /api/config/config_entries/entry/<entry_id>` and remove the entity from the registry. Reloading core config is *not* enough — YAML core platforms are only re-read on restart.
- **Tasmota/ESPHome device that reappears after deletion**: the driver is a **retained MQTT discovery topic**. Publish an empty payload with retain to the discovery topic and the integration deletes the device + its entities itself:
  ```js
  call_service mqtt.publish { topic: "tasmota/discovery/<MAC-no-colons>/config", payload: "", retain: true }
  ```
  (Find the MAC in the entity `unique_id`s, e.g. `34:5F:45:4E:E4:50` → `345F454EE450`.) A follow-up `device_registry/remove` then answers `Unknown device` because it is already gone.

## Automation payloads (REST)

Top-level keys `alias`, `trigger`, `condition`, `action`, `mode`. Blueprints can **not** be written through the API — replace them with an explicit trigger/action config.

Patterns that survived real use:

```jsonc
{ "mode": "restart", "trigger": [ /* state, numeric_state, device-free */ ],
  "action": [ { "choose": [
      // suppression branch FIRST: "!= 'on'" (never "== 'off'") so unknown/unavailable can't suppress the useful branch
      { "conditions": [ { "condition": "template", "value_template": "{{ states('binary_sensor.x') != 'on' }}" } ],
        "sequence": [ { "action": "light.turn_on", "target": { "entity_id": "light.y" }, "data": { "brightness_pct": 10 } } ] }
  ] } ] }
```

- Keep automations **manually runnable**: avoid `trigger.id`-only gating, use state-based `choose` branches.
- Dimming loops: `repeat: { while: [ { condition: "template", value_template: "{{ repeat.index <= 60 }}" } ], sequence: [ step, { delay: "0.25s" } ] }`.
- Phone/watch notifications: `notify.send_message` targets notify entities and supports `title`; the legacy `notify.mobile_app_*` service is the only one that accepts `data:` (channels, actions, `command_dnd`).
- Watch out for double-tap semantics: a remote's double-press and a single-press on a *different* button within a few seconds will both fire; logbook is the way to see what actually arrived.

## Jinja snippets that earned their place

```jinja
{{ 'Good morning' if now().hour < 12 else ('Good afternoon' if now().hour < 18 else 'Good evening') }}
{{ as_timestamp(states('sensor.sun_next_setting')) | timestamp_custom('%H:%M') }}
{{ relative_time(states.sensor.backup_last_successful_automatic_backup.last_changed) }}
{{ states.update | selectattr('state', 'eq', 'on') | list | count }}      {# updates pending #}
{{ states('sensor.x') | float(0) | round(1) }}                            {# 23.28 -> 23.3 #}
{{ states('sensor.qrevo_status') | replace('_', ' ') | capitalize }}      {# segment_cleaning -> Segment cleaning #}
{{ {'sunny': 'mdi:weather-sunny', 'rainy': 'mdi:weather-rainy'}.get(states('weather.home'), 'mdi:weather-partly-cloudy') }}
```

Render them through `POST /api/template` **before** trusting a dashboard header — a broken template silently renders as the literal `{{ ... }}`.

## Verification snippets

```js
// every entity referenced by a dashboard config exists?
const missing = [];
(function walk(o){ if (Array.isArray(o)) return o.forEach(walk);
  if (o && typeof o === 'object') { if (typeof o.entity === 'string' && !live.has(o.entity)) missing.push(o.entity); Object.values(o).forEach(walk); } })(cfg);
// where is an entity used?
search/related { item_type: 'entity', item_id: 'light.h6008' }   // {} means unreferenced
// what actually happened, in order?
logbook/get_events { start_time, end_time, entity_ids: [...] }
history/history_during_period { start_time, end_time, entity_ids: [...], minimal_response: true }
```

`scripts/ha-api.mjs missing <dashboard.json>` runs the first check; `related` and the two history calls are exposed as `related <entity>` / `ws ...`.

## Shadow DOM traversal

When you pass anything other than `document` as the root of a shadow-walking helper, **include that root's own `shadowRoot`** — otherwise dialogs, table rows and cards look empty:

```js
const walk = (r) => {
  found.push(...r.querySelectorAll(sel));
  if (r.shadowRoot) walk(r.shadowRoot);              // the root's own shadow root
  for (const e of r.querySelectorAll('*')) if (e.shadowRoot) walk(e.shadowRoot);
};
```

`document.body.textContent` / `innerText` never contains sidebar labels, so "is this string still on the page?" checks silently pass while the thing is still there. Assert through the API instead (`dash list`, `states`, `config/entity_registry/list`).

## Two more traps worth knowing

- **Big WS payloads: redirect, don't pipe.** `ha-api.mjs themes | python3 …` died mid-JSON at exactly 65536 bytes, while `ha-api.mjs themes > /tmp/themes.json` wrote all 189637 bytes and parsed fine. Any large dump (themes, HACS repo list, entity registry) goes to a file first.
- **Services are `/api/services/<domain>/<service>`**, slash-separated on the wire even though everything else uses dots. `frontend.reload_themes` is a *service* call, not a WS command, and `frontend/set_theme` does not exist on 2026.9.3 (`unknown_command`) — a user's theme choice is a profile setting that only the UI can change. Per-view `theme:` keys are the API-reachable equivalent.
