# Dashboard (Lovelace) notes

Verified by rendering every change in a real browser. Nothing here is from memory.

## Storage dashboards

```js
lovelace/dashboards/list                                   // url_path, title, mode, require_admin
lovelace/dashboards/create { url_path, title, icon, mode: "storage", show_in_sidebar: true }
lovelace/config       { url_path }                         // read
lovelace/config/save  { url_path, config }                 // write
```

- `url_path` **must contain a hyphen** (`home` → `Invalid URL path: home`; `my-home` is fine). The dashboard id then replaces the hyphen with `_` (`my_home`).
- Keep the auto-generated default dashboard untouched and build a separate storage dashboard — the auto overview keeps the ~100 diagnostic entities that you do not want to hand-curate.
- **Dashboard CRUD is lopsided on 2026.9.3**: `lovelace/dashboards/list` and `/create` work, but `/update`, `/delete`, `lovelace/config/delete` all answer `{"code":"unknown_command"}`, and there is no REST route either (`DELETE /api/lovelace/dashboards/<id>` → 404). **Editing, deleting, or setting a dashboard as default is UI-only**: `/config/lovelace/dashboards` → row ⋯ menu (that menu is also where "Set as default" lives). Verify through the API afterwards — never with an in-page text check (see the shadow-DOM note in api-notes.md) — and check the dialog's title before confirming, the row menus are easy to hit on the wrong row ("Delete Home?").
- Keep throwaway test dashboards to a minimum: you cannot delete them from the API.
- `lovelace/resources` tells you which custom cards are actually registered. Check it before using any `custom:*` card; a missing resource renders as an error card, not an exception.

## View keys (sections view)

```jsonc
{
  "title": "Overview", "path": "overview", "icon": "mdi:home",
  "type": "sections",
  "max_columns": 4,                     // upper bound; the grid fits fewer on narrow viewports
  "dense_section_placement": true,      // packs sections to fill horizontal gaps
  "header": { "layout": "responsive", "card": { "type": "markdown", "content": "# Hi {{ user }}" } },
  "badges": [ { "type": "entity", "entity": "sensor.x", "name": "Watch", "show_name": true, "show_state": true, "color": "green" } ],
  "theme": "Catppuccin Mocha",           // per-view theme
  "sections": [ ... ]
}
```

- The **header** is a card rendered above the grid (markdown is templated, so greeting/weather/sun lines belong here). It replaced a "hero section" that looked half-empty.
- **Badges** default to `show_name: false` — an entity badge then renders as a bare `Off` / `76%`. Set `show_name: true`.
- A view-level `theme` / section-level `theme` beats relying on each user's profile setting.

## Section keys

```jsonc
{ "type": "grid", "column_span": 4, "theme": "Catppuccin Latte",
  "background": { "color": "red", "opacity": 80 },
  "visibility": [ { "condition": "state", "entity": "x", "state": "on" } ],
  "cards": [ ... ] }
```

`column_span` works on **sections** (span N columns of the view grid) — it is not a card option.

### How card widths actually behave (measured)

Inside a grid section, a card occupies as many ~200px tracks as its content needs:

| card | width in a 405px section |
|---|---|
| `tile`, `custom:mushroom-*` (light/fan/vacuum/entity/person) | **199px — two fit per row** |
| `entities`, `history-graph`, `markdown`, chips rows | 405px — full column (may wrap) |

So "my tiles are half width" is normal, not a bug. Full-bleed rows come from `entities`/`markdown`/graph cards.

### Row alignment

Sections in the same row are top-aligned and the **next row starts below the tallest section**. One 934px section next to 200px ones therefore leaves a huge hole. `dense_section_placement` only closes horizontal gaps. The fix is structural — **split tall sections** (and keep column heights similar):

| view | before | after splitting tall sections |
|---|---|---|
| Overview | 1665px (1 section held graph + 11 rows) | 1183px |
| Bedroom | 1401px ("Fan & air" = 958px) | 1017px (→ "Fan" + "Air purifier") |
| Cleaning | 1318px | 1242px (→ 6 sections) |

## Card gotchas

- **`entities` card has no graph/sparkline row.** Valid special rows: `attribute`, `button`, `buttons`, `cast`, `conditional`, `divider`, `section`, `weblink`. For a sparkline use a `sensor` card: `{ "type": "sensor", "entity": "...", "graph": "line", "hours_to_show": 24, "detail": 1 }`.
- **`secondary_info`** accepts `entity-id | last_changed | last_updated | area_name | floor_name | device_name | state` (underscores) **or any attribute** — `secondary_info: last_triggered` is how you show when an automation last ran; `last-triggered` is invalid. Great for staleness on infrequently-reporting sensors (`last_changed`).
- **`picture-entity`**: `aspect_ratio` (`"133%"`, `"16:9"`, `"1.78"`) + `fit_mode: cover|contain|fill`. Without it a portrait vacuum map renders ~740px tall; `aspect_ratio: "133%"` + `contain` letterboxes it to ~530px.
- **`history-graph`** is the only native multi-entity time chart; it grows with the number of entities (4 lines ≈ 286px). At 3–4 columns, 6 lines is unreadable mush — move outdoor sensors into an `entities` card instead.
- **You cannot make that graph wider.** A card never exceeds one section track (~380px at 1400px viewport): `column_span` on a card is ignored (verified live — a 2-column section just flows its cards into two side-by-side tracks, graph unchanged). Options instead: give the section a second card to sit beside the graph, or split the series by **value range** (indoor 21–25 °C vs outdoor meters 19–20 °C) so each graph auto-fits its own y-axis.
- **`statistics-graph`** (smooth 5-minute means, kills sensor jitter) needs `state_class: measurement` on every series; check before using it, because it is not settable from the entity registry. A series without it just doesn't render.
- **`mini-graph-card` / `apexcharts-card`** (HACS) are the only way to get smooth thin lines, live-value legends and per-series styling in one card: `entities[].y_axis: secondary` + `show.labels_secondary` + `show_legend_state` puts two different units on one card without flattening either line. **HACS is reachable over WS** — `hacs/repositories/list` and `hacs/info` return real data (an earlier `invalid_format` on every `hacs/*` command was actually the CLI's `ws` dispatch bug, not HACS).
- **Headings**: `{ "type": "heading", "heading": "Lights", "icon": "mdi:lightbulb-group", "heading_style": "title" }` — must be the first card in its section. Appending one blindly during a restructure is how you get an orphaned heading at the bottom of a view.
- `tile` cards lie about **fans** (an off fan with a stale `percentage` shows "33%" instead of "Off").
- Cards ignore unknown keys silently — a typo'd option looks like "the feature doesn't work".

## Mushroom (HACS)

Registered card types (read out of the installed bundle, not guessed):
`chips`, `template`, `entity`, `light`, `fan`, `vacuum`, `select`, `number`, `update`, `person`, `climate`, `cover`, `lock`, `media-player`, `humidifier`, `alarm-control-panel`, `title` (all prefixed `custom:mushroom-`).

Options actually used and confirmed to render:

| card | options |
|---|---|
| `mushroom-light-card` | `collapsible_controls: true`, `show_brightness_control`, `show_color_temp_control`, `use_light_color` |
| `mushroom-fan-card` | `collapsible_controls: true`, `show_percentage_control` |
| `mushroom-vacuum-card` | `commands: ["start_pause","return_home","locate"]` |
| `mushroom-template-card` | `primary`, `secondary`, `multiline_secondary`, `icon`, `icon_color` (all templateable) |
| `mushroom-person-card` / `mushroom-entity-card` / `mushroom-select-card` / `mushroom-number-card` / `mushroom-update-card` | `entity`, `name`, `icon` |
| `mushroom-chips-card` | `alignment: start\|justify`, chips: `{type: entity, entity, content_info: name\|state\|last_changed, tap_action: {action: toggle}}` |

- `collapsible_controls: true` is the single biggest visual win: an off light/fan collapses to a power icon instead of a dead grey slider (and the native gradient colour-temp bar, which looks like a red blob when off).
- Prefer `entity` chips with `content_info: name` over six `light` chips that all read "Off".
- Chips are the compact replacement for a 10-row status list (5 vacuum chips ≈ 80px vs ~400px of rows).
- Mushroom cards have their own palette: fan cards are **green**, not the tile's `color: blue`.

## Themes

- `frontend/get_themes` → `{ themes: {}, default_theme, default_dark_theme }`. Empty means none are installed.
- Install needs `frontend: themes: !include_dir_merge_named themes` in `configuration.yaml` **plus** a restart/reload; then a theme can be selected per user (Profile → Theme) or, better, per view/section in the dashboard config.
- Catppuccin's real theme names (from the release YAML): `Catppuccin Latte`, `Catppuccin Frappe`, `Catppuccin Macchiato`, `Catppuccin Mocha`, and OS-following pairs `Catppuccin Auto Latte Frappe|Macchiato|Mocha`.
- Glassmorphism themes frequently need `card-mod` for real transparency — extra dependency, extra breakage.

## Polish checklist that made dashboards look intentional

1. **Icons on every entity** that lacked one (`config/entity_registry/update {icon}`) — 74 entities in one pass; backup/vacuum/energy rows benefit most.
2. **Generic global names, per-card `name:` overrides** for disambiguation (`Bedroom humidity` next to 5 other humidities) — keeps the auto dashboard and future views tidy.
3. **Hero header** (markdown template + badges) instead of a top "hero section".
4. **Sparklines** for the rooms you watch, or — when you want *every* room and the comparison chart is too cramped for one track — a `grid` card of `sensor` cards: `{"type":"grid","columns":2,"square":false,"cards":[{"type":"sensor","entity":"…","name":"Bedroom","graph":"line","hours_to_show":24,"detail":1}]}`. Six rooms in 2×3 costs ~460px of height and each card is ~180px wide, which is legible: name + big current value + 24h filled line. Grids nest inside a section and don't exceed its one track.
5. **Two metrics in one cell, natively:** a `sensor` card takes exactly one entity, so pair the values in a `custom:mushroom-template-card` instead — `primary` = the room name, `secondary` = `"{{ states('sensor.x_temperature') | float(0) | round(1) }} °C · {{ states('sensor.x_humidity') | float(0) | round(1) }} %"` with `multiline_secondary: true`. Six rooms in a 2-column grid is ~230px, versus ~700px for six sparkline cards plus six value cards, and the explicit `round(1)` evens out sensors that report different precision (one-meter reports `59.68`, another `49`). Trade-off: no trend lines — only reach for `custom:mini-graph-card` (`entities[].y_axis: secondary` + `show.labels_secondary` + `show_legend_state`) when the lines matter.
5. **Freshness** (`secondary_info: last_changed`) on sensors that report rarely — it turns "is this stale?" into a glance.
6. **Chips for status, rows for values, cards for single entities.**
7. **Split tall sections** so rows do not leave holes, then re-shoot and compare page heights.
