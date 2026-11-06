# Themes

Each theme is a pair of files: `<Name>.json` (id, name, description and its
settings list) and `<Name>.qml` (the animation). The plugin finds themes by
scanning this folder for `*.json` files; `.qml` files without a JSON, such as
`HulkFist.qml`, are helper parts.

- `Base`: the original card with a swoosh.
- `HulkSmash`: slam, shake, cracks, punch-through and shatter.
- `Cowboy`: a weathered wooden frontier sign with rope hangers, brass
  fasteners, and a gentle swing. A shot punches through it on exit, knocking
  the planks apart with flying wood splinters. Options: swing strength, bullet
  hole, splinters, and gunshot volume. Shows up to six app groups plus an
  overflow count. Rebuild its original assets with
  `python3 themes/make-cowboy-assets.py` and
  `python3 sounds/make-cowboy-sounds.py` from the repo root. Run its asset and
  audio checks with `node themes/Cowboy.test.cjs`.
- `NeonCircuit`: illuminated circuit traces, an electric scan on each switch,
  and a short synthesized connection sound. Options: circuit color (empty
  follows Omarchy), glow strength, traces, and scan. Shows up to six app groups,
  with an overflow count for larger workspaces. Generate its original sound
  with `python3 sounds/make-neon-circuit.py` from the repo root.

After installing a new theme, run `omarchy restart shell` once before selecting
it. Quickshell can discover the new JSON descriptor while its cached directory
listing still prevents the new QML file from loading. Editing an existing theme
does not require this new-file refresh.

To build your own, see "Make your own theme" in the [README](../README.md), or
ask your AI coding agent to read [AGENTS.md](../AGENTS.md) and make one.
