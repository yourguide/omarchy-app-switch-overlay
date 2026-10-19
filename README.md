# App Switch Overlay for Omarchy

Know which app you switched to, even when every window is fullscreen.

![App Switch Overlay preview](preview.png)

Briefly lists the apps on your current workspace at the top center of the
focused monitor, then fades away. Includes windows hidden behind a fullscreen
app. Works with your existing navigation and shortcuts.

- Puts the focused app first and marks it with an accent-colored dot.
- Groups multiple windows of the same app, with a count such as `Kitty ×2`.
- Stays for 1.05 seconds for a single app, or 2.1–4.5 seconds for multiple apps,
  then fades out over 240 milliseconds.
- Appears above fullscreen windows without reserving screen space.
- Lets mouse clicks pass through and never requests keyboard focus.
- Follows Omarchy's foreground, background, and accent colors.
- Shows on workspace changes, even when the newly focused app has the same name.
- Stays quiet on title changes and switches between windows of the same named
  app on the same workspace.
- Recognizes Factory and Microsoft Teams browser windows by title suffix.

No extra background process, polling, keybindings, network calls, or packages.

## Requirements

Omarchy Quattro with `omarchy-shell` and Hyprland. Qt Quick, Quickshell's Wayland
and Hyprland modules, and the Omarchy theme modules are supplied by the desktop.
No extra external dependencies. Older Waybar-based Omarchy versions and
standalone Hyprland installations are not supported.

## Install

```bash
omarchy plugin add https://github.com/yourguide/omarchy-app-switch-overlay.git --enable
```

## Install from a downloaded copy

From the directory containing this README:

```bash
plugin_dir="$HOME/.config/omarchy/plugins/djk.app-switch-overlay"
if [ -e "$plugin_dir" ]; then
  echo "Already installed; follow the update instructions below."
else
  mkdir -p "$plugin_dir"
  cp manifest.json Service.qml AppNames.js "$plugin_dir/"
  omarchy plugin validate "$plugin_dir"
  omarchy-shell shell rescanPlugins
fi
```

Once discovery completes, enable it:

```bash
omarchy plugin enable djk.app-switch-overlay
```

No desktop restart required.

## Preview, disable, and remove

```bash
omarchy-shell app-switch-overlay preview
omarchy-shell app-switch-overlay status
omarchy plugin disable djk.app-switch-overlay
omarchy plugin remove djk.app-switch-overlay
```

Removal affects only this plugin's files and enabled-state entry. There are no
application settings or keybindings to restore.

## Customize and update

Installed files live in `~/.config/omarchy/plugins/djk.app-switch-overlay/`.
Back up before editing. Saved plugin code hot-reloads.

- `AppNames.js`: friendly names and browser title suffixes. The default agent
  window is called "Agent" because users choose different coding agents.
- `Service.qml`: `hideTimer.interval` sets display duration (longer for a list);
  `NumberAnimation.duration` sets fading; `margins.top` sets placement.

Unrecognized apps use their desktop entry name, or app ID as a fallback.
Other web apps may need a mapping. Apps sharing an ID are treated as the same
app unless a friendly-name rule distinguishes them.

For a manual update, disable, back up the installed directory, replace the three
runtime files, and enable again. Git-installed copies can use
`omarchy plugin update djk.app-switch-overlay`.

When upgrading from 1.0.0, if the shell still shows the old one-app label,
run `omarchy restart shell` to clear cached QML. Application windows stay open.

## Privacy and verification

Reads workspace windows' app IDs and titles in memory to choose labels. Stores
no titles and sends no telemetry. Does not access credentials or execute shell
commands. Shows app names rather than full document or conversation titles.
Omarchy plugins run inside the shell without sandboxing.

Validated on the author's desktop: fullscreen Factory and ChatGPT, normal
Microsoft Teams, correct labels, unchanged keyboard focus during preview,
timer expiry, layer removal after fading, and clean Hyprland configuration.
Version 1.1.0 was also checked with three temporary background windows behind
a fullscreen app: all appeared, duplicate windows were counted, and other
workspaces' apps were excluded. Temporary windows were removed afterward.
The preview was visually inspected. Multi-monitor routing is implemented but
has not been exercised on multiple monitors. Browser naming rules are best effort.

## Development checks

```bash
node tests/workspace-apps.test.cjs
omarchy plugin validate .
```

## License

MIT. See [LICENSE](LICENSE).
