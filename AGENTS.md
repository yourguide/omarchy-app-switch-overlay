# AGENTS.md: building a theme for Dynamic App Switch Overlay

You are a coding agent asked to add a theme to this Omarchy plugin. Read this
whole file first. Work only inside `themes/` and `sounds/` unless the user asks
for more. Don't change the plugin ID, IPC name, settings file path, or the
user's Hyprland config.

## How the plugin works

`Service.qml` watches Hyprland focus and workspace changes. On a change it
updates `host.apps` and calls the selected theme:

- `show()` when the overlay is not showing yet.
- `pulse()` when it is already showing and the user switches again. This can
  happen many times per second.
- `hide()` when the display time is over. Animate out, then make `active` false.

One theme instance exists per monitor. Only the instance with `primary: true`
gets `show()`/`pulse()`; every instance gets `hide()`.

## Files, naming, and discovery

A theme is two files in `themes/`, with the same base name in PascalCase:

- `themes/MyTheme.json`: the descriptor. This is what discovery scans
  (`themes/*.json`), so it's read without loading the QML.
- `themes/MyTheme.qml`: the component (or set `"qml"` in the descriptor).

Helper components without a `.json` (for example `HulkFist.qml`) are not
listed as themes. Use a lowercase kebab-case `id` (`my-theme`) that is unique.
The theme appears in the settings panel picker as soon as the files exist.

## Descriptor and settings schema

```json
{
  "id": "my-theme",
  "name": "My Theme",
  "description": "One friendly sentence for the theme picker.",
  "panelAccent": "#ff8800",
  "settings": [
    { "key": "glow", "label": "Glow", "type": "bool", "default": true },
    { "key": "size", "label": "Size", "type": "number", "default": 1,
      "min": 0.5, "max": 2, "step": 0.1, "decimals": 1, "suffix": "×" },
    { "key": "style", "label": "Style", "type": "choice", "default": "soft",
      "choices": [ { "label": "Soft", "value": "soft" }, { "label": "Hard", "value": "hard" } ] },
    { "key": "tint", "label": "Tint", "type": "color", "default": "",
      "help": "Leave empty to use the Omarchy accent." }
  ]
}
```

- Required: `id`, `name`. Recommended: `description`. Optional: `qml`,
  `panelAccent` (section title color), `settings`.
- Entry fields: `key` (unique), `label`, `type`, `default`, optional `help`.
- `bool`: `default` true/false.
- `number` (alias `slider`): `min`, `max`, `step`, optional `decimals`, `suffix`.
- `choice` (alias `enum`): `choices` as `{label, value}` objects or plain values;
  `default` must be one of the values.
- `color`: `#rrggbb` or `#aarrggbb`; `""` means "use the theme's default color".
- Keep labels short (they sit in a 150 px column) and keep the list small.

The panel builds controls from this list. Values are saved per theme in
`~/.config/djk/app-switch-overlay.json` under `themes["<id>"]`. The service
validates them against your schema and passes the result as `options`, so
`options` always has every key with a valid value. Never read the settings file
yourself.

## The theme contract

Your root `Item` must declare:

| Member | Direction | Meaning |
| --- | --- | --- |
| `property var host` | set by service | `host.apps` (`[{name, count, focused}]`, focused first), `host.appName`, `host.workspaceName`, `host.settings` |
| `property var options` | set by service | resolved values from your schema |
| `property bool primary` | set by service | this monitor shows the overlay |
| `readonly property bool active` | read by service | true while anything is visible or animating |
| `function show()` | called | first appearance |
| `function pulse()` | called | repeat switch while visible |
| `function hide()` | called | leave; `active` must become false when done |

Global settings in `host.settings`: `soundEnabled`, `volume` (0–1),
`animationSpeed` (multiplier; divide your durations by it), `showDuration`
(ms, handled by the service), `position` (`"top"` or `"center"`). Respect
`position`: top means about 52 px from the top; center means vertically
centered in the layer.

The layer is 820 px wide; it's 480 px tall for top and full screen height for
center. Stay inside it.

## Sounds

- Put `.wav` files (16-bit PCM, short, quiet, with no silence at the start) in
  `sounds/`. Only ship sounds you made or may redistribute under MIT.
- Play them with `Sfx` from the plugin root:

  ```qml
  Sfx { id: hit; sound: "my-theme-hit.wav"; volume: Number(theme.s.volume)
        enabled: theme.s.soundEnabled !== false
        onPlayed: if (theme.host) theme.host.soundPlays++ }
  ```

- Call `hit.play()` only when `primary` is true, so multi-monitor setups don't
  play it twice. `Sfx` preloads and round-robins three players, so fast
  retriggers each get their own sound. Don't spawn processes yourself.

## Performance and rapid retriggers

- `pulse()` must be cheap and restartable: stop running animations, reset
  transforms, start again. Never queue animations or create objects per pulse.
- Keep the first visible frame within about 16 ms of `show()`; start sounds in
  the same call so they line up with the motion.
- Animate `opacity`, `scale`, `x`, `y`, `rotation` and transforms. Avoid
  per-frame JavaScript, `Canvas` repaints in loops, shaders, or large images.
- A fixed, small number of items (Repeater with a constant model is fine).
  Hulk Smash uses at most 20 shards.
- After `hide()`, all animations must stop and `active` must turn false, so the
  layer is removed. Never leave a timer or animation running while hidden.

## Click-through and focus

The service creates the window: a click-through layer-shell overlay with no
keyboard focus. Don't add `MouseArea`, `TextInput`, `Keys` handlers, or
windows of your own. Don't change the layer, mask, or focus settings.

## Colors

Import `qs.Commons as Commons` and use `Commons.Color.background`,
`Commons.Color.foreground` and `Commons.Color.accent`, and
`Commons.Style.font.family` for text, so the theme follows the user's Omarchy
theme. Fixed brand colors are fine when they are the point (Hulk green), but
keep text readable. Use `textFormat: Text.PlainText` for app names.

## Skeleton

`themes/MyTheme.json`:

```json
{
  "id": "my-theme",
  "name": "My Theme",
  "description": "A simple fading card.",
  "settings": [
    { "key": "tint", "label": "Border color", "type": "color", "default": "" },
    { "key": "bounce", "label": "Bounce", "type": "bool", "default": true }
  ]
}
```

`themes/MyTheme.qml`:

```qml
import QtQuick
import qs.Commons as Commons
import ".."

// Theme interface: host, options, primary, active, show(), pulse(), hide().
Item {
    id: theme
    anchors.fill: parent
    property var host: null
    property var options: ({})
    property bool primary: false
    readonly property var s: host ? host.settings : ({})
    readonly property real speed: Math.max(0.25, Number(s.animationSpeed) || 1)
    function d(ms) { return Math.max(1, Math.round(ms / speed)); }

    property bool shown: false
    readonly property bool active: shown || card.opacity > 0

    function show() { bump.stop(); card.scale = 1; shown = true; if (primary) tick.play(); }
    function pulse() {
        if (!shown) { show(); return; }
        if (primary) tick.play();
        if (options.bounce) bump.restart();
    }
    function hide() { shown = false; }

    Sfx { id: tick; sound: "swoosh.wav"; volume: Number(theme.s.volume)
          enabled: theme.s.soundEnabled !== false
          onPlayed: if (theme.host) theme.host.soundPlays++ }

    Rectangle {
        id: card
        x: Math.round((theme.width - width) / 2)
        y: theme.s.position === "center" ? Math.round((theme.height - height) / 2) : 52
        width: Math.min(420, label.implicitWidth + 48); height: 56; radius: 12
        color: Commons.Color.background
        border.color: theme.options.tint ? theme.options.tint : Commons.Color.accent
        border.width: 1
        opacity: theme.shown ? 0.96 : 0
        Behavior on opacity { NumberAnimation { duration: theme.d(160) } }
        Text {
            id: label
            anchors.centerIn: parent
            text: theme.host ? theme.host.appName : ""
            textFormat: Text.PlainText
            color: Commons.Color.foreground
            font.family: Commons.Style.font.family
            font.pixelSize: 18
        }
        SequentialAnimation {
            id: bump
            NumberAnimation { target: card; property: "scale"; to: 1.05; duration: theme.d(60) }
            NumberAnimation { target: card; property: "scale"; to: 1; duration: theme.d(90) }
        }
    }
}
```

## Validate

From the installed plugin directory
(`~/.config/omarchy/plugins/djk.app-switch-overlay`) or the repo:

```bash
node tests/theme-schemas.test.cjs        # descriptor, contract and sound checks
node tests/workspace-apps.test.cjs
omarchy plugin validate .
omarchy restart shell                    # or wait for hot reload; windows stay open
omarchy-shell app-switch-overlay status  # "themes" should list your id
omarchy-shell app-switch-overlay preview
omarchy-shell app-switch-overlay settings   # pick your theme, try each option
journalctl --user --since "-2 min" | grep -iE "app-switch|\.qml:|TypeError|ReferenceError"
```

The last command should print nothing about your theme. Also switch apps
quickly several times and confirm each switch animates and plays its sound, and
that the overlay disappears completely afterwards.

## Checklist

- [ ] `themes/<Name>.json` and `themes/<Name>.qml`, unique kebab-case `id`.
- [ ] Every schema entry has `key`, `label`, `type`, `default` and valid ranges or choices.
- [ ] The QML declares `host`, `options`, `primary`, `active`, `show()`, `pulse()`, `hide()`.
- [ ] `pulse()` restarts cleanly under fast switching; `active` goes false after `hide()`.
- [ ] Respects `position`, `animationSpeed`, `soundEnabled` and `volume`.
- [ ] Sounds live in `sounds/`, play through `Sfx` only when `primary`, and may be redistributed.
- [ ] No mouse or keyboard handling, no extra windows, no processes, no network.
- [ ] Uses Omarchy colors and fonts for text and surfaces.
- [ ] Tests, `omarchy plugin validate .`, preview and the log check all pass.
- [ ] README's theme list mentions the new theme if you're contributing it upstream.
