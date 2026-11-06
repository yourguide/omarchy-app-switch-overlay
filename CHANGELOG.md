# Changelog

## 2.1.1

- Bundle Hulk Smash, its fist helper, theme options, and generated sound files,
  alongside the Base, Cowboy, and Neon Circuit themes.
- Preserve the running desktop's theme-loader fallback and loaded-theme status.

- Show the overlay only when switching desktops. Moving the pointer or keyboard
  focus between tiled windows on the same desktop no longer triggers it.
- Keep the app list current while the overlay is visible without replaying the
  animation or extending its display time on focus changes.
- Expose the workspace-only trigger mode in IPC status for reload verification.
- Restart the shell after upgrading to clear cached QML components.

## 2.1.0

- Renamed to Dynamic App Switch Overlay (same plugin ID, IPC name and settings file).
- Themes declare their own options in `themes/<Name>.json`; the settings panel
  builds a section for the selected theme and switches it with the theme.
- Themes are discovered by scanning `themes/*.json`; the picker shows each
  theme's name and description.
- Theme options are stored per theme under `themes` in the settings file.
  2.0.0's `hulk` block is migrated automatically.
- Base theme options: border color and corner radius.
- Added AGENTS.md, a guide for AI coding agents building new themes.
- Sounds ship in `sounds/` and play from the plugin directory.

## 2.0.0

- Themes: Base (swoosh card) and Hulk Smash (slam fist, shake, cracks,
  punch-through fist and shatter).
- Optional sounds with volume control.
- Settings panel (`omarchy-shell app-switch-overlay settings`) and a watched
  settings file with defaults.
- Retriggers on every switch, including rapid switching.

## 1.1.0

- List all apps on the focused workspace, including windows behind fullscreen.
- Put the focused app first and mark it with an accent-colored dot.
- Group repeated app names with window counts.
- Show workspace context when multiple apps are present.
- Allow more reading time for longer lists.
- Trigger on workspace changes even when both workspaces focus the same app.

## 1.0.0

- Briefly display the focused app name on app switches.
