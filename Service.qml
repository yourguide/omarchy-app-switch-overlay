import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt.labs.folderlistmodel
import qs.Commons as Commons
import "AppNames.js" as AppNames

// App Switch Overlay service.
// - Shows the focused workspace's apps on desktop changes (retriggers while open).
// - Look and sounds come from a theme in themes/. Each theme is a pair:
//   themes/<Name>.json (id, name, description, settings schema) and
//   themes/<Name>.qml. Themes are discovered by scanning themes/*.json.
// - Settings live in ~/.config/djk/app-switch-overlay.json (watched live;
//   defaults are used when the file doesn't exist).
// - Settings panel: omarchy-shell app-switch-overlay settings
Item {
    id: root
    property var shell: null
    readonly property var active: ToplevelManager.activeToplevel
    readonly property var workspace: Hyprland.focusedWorkspace
    property var apps: []
    property string workspaceName: ""
    readonly property string appName: apps.length ? apps[0].name : "No apps"
    property string lastContext: ""
    property string outputName: ""
    property bool opened: false
    property bool ready: false
    property int switchCount: 0
    property int soundPlays: 0
    property string loadedTheme: ""
    readonly property string home: Quickshell.env("HOME")

    // ---------------- Settings ----------------
    readonly property string settingsPath: home + "/.config/djk/app-switch-overlay.json"
    property string lastSettingsText: ""
    property string settingsError: ""
    property var settings: defaults()

    function defaults() {
        return {
            theme: "base",
            soundEnabled: true,
            volume: 0.3,
            showDuration: 1050,
            animationSpeed: 1.0,
            position: "top",
            themes: {}
        };
    }
    function clamp(v, lo, hi, dflt) {
        var n = Number(v);
        if (v === null || v === undefined || v === "" || typeof v === "boolean" || isNaN(n)) return dflt;
        return Math.max(lo, Math.min(hi, n));
    }
    // Global settings are validated here. Per-theme values are kept as stored
    // (plain values only) and resolved against the theme's schema later.
    property bool migrated: false
    function normalize(o) {
        var d = defaults();
        if (!o || typeof o !== "object") return d;
        var themes = {};
        var src = (o.themes && typeof o.themes === "object") ? o.themes : {};
        for (var id in src) {
            if (!src[id] || typeof src[id] !== "object") continue;
            themes[id] = {};
            for (var k in src[id]) {
                var v = src[id][k];
                if (typeof v === "boolean" || typeof v === "number" || typeof v === "string") themes[id][k] = v;
            }
        }
        // 2.0.0 stored Hulk Smash options in a top-level "hulk" block.
        if (o.hulk && typeof o.hulk === "object" && !themes["hulk-smash"]) {
            themes["hulk-smash"] = {};
            for (var hk in o.hulk) themes["hulk-smash"][hk] = o.hulk[hk];
            migrated = true;
        } else if (o.hulk) {
            migrated = true;
        }
        return {
            theme: (typeof o.theme === "string" && o.theme) ? o.theme : d.theme,
            soundEnabled: typeof o.soundEnabled === "boolean" ? o.soundEnabled : d.soundEnabled,
            volume: clamp(o.volume, 0, 1, d.volume),
            showDuration: Math.round(clamp(o.showDuration, 300, 6000, d.showDuration)),
            animationSpeed: clamp(o.animationSpeed, 0.25, 3, d.animationSpeed),
            position: (o.position === "center" || o.position === "top") ? o.position : d.position,
            themes: themes
        };
    }
    function applySettingsText(t) {
        if (t === lastSettingsText) return;
        lastSettingsText = t;
        try {
            migrated = false;
            settings = normalize(JSON.parse(t));
            settingsError = "";
            if (migrated) { migrated = false; saveTimer.restart(); }
        } catch (e) {
            settings = defaults();
            settingsError = "Bad JSON, using defaults: " + e;
        }
    }
    // Called by the settings panel: apply now, write the file shortly after.
    function updateSettings(patch) {
        var next = JSON.parse(JSON.stringify(settings));
        for (var k in patch) next[k] = patch[k];
        settings = normalize(next);
        saveTimer.restart();
    }
    // Set one option of the selected theme.
    function updateThemeOption(key, value) {
        var next = JSON.parse(JSON.stringify(settings));
        var id = activeThemeId;
        if (!next.themes[id]) next.themes[id] = {};
        if (value === null || value === undefined) delete next.themes[id][key];
        else next.themes[id][key] = value;
        settings = normalize(next);
        saveTimer.restart();
    }
    Timer {
        id: saveTimer
        interval: 150
        onTriggered: {
            var t = JSON.stringify(root.settings, null, 2) + "\n";
            root.lastSettingsText = t;
            settingsFile.setText(t);
        }
    }
    FileView {
        id: settingsFile
        path: root.settingsPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applySettingsText(text())
        onLoadFailed: { root.lastSettingsText = ""; root.settings = root.defaults(); }
    }
    // Backup poll in case file watching is unavailable.
    Timer {
        interval: 2000; repeat: true; running: true
        onTriggered: settingsFile.reload()
    }

    // ---------------- Theme discovery ----------------
    // Every themes/*.json is a theme descriptor; its "qml" (default: same base
    // name) is the component. Read without instantiating the theme.
    property var themeDescriptors: ({})   // fileName -> parsed descriptor
    property var themeList: []            // [{id, name, description, qml, settings, panelAccent}]
    property var themeById: ({})
    function themeIdFromFile(fileName) {
        return fileName.replace(/\.json$/, "").replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();
    }
    function normalizeSchema(list) {
        var out = [];
        if (!Array.isArray(list)) return out;
        for (var i = 0; i < list.length; i++) {
            var e = list[i];
            if (!e || typeof e.key !== "string" || !e.key) continue;
            var type = e.type === "slider" ? "number" : e.type === "enum" ? "choice" : e.type;
            if (["bool", "number", "choice", "color"].indexOf(type) < 0) continue;
            var entry = { key: e.key, label: String(e.label || e.key), type: type, help: e.help ? String(e.help) : "" };
            if (type === "bool") entry.default = e.default === true;
            if (type === "number") {
                entry.min = Number(e.min !== undefined ? e.min : 0);
                entry.max = Number(e.max !== undefined ? e.max : 1);
                entry.step = Number(e.step || (entry.max - entry.min) / 20) || 0.05;
                entry.decimals = e.decimals !== undefined ? Number(e.decimals) : 2;
                entry.suffix = e.suffix ? String(e.suffix) : "";
                entry.default = clamp(e.default, entry.min, entry.max, entry.min);
            }
            if (type === "choice") {
                var choices = Array.isArray(e.choices) ? e.choices : [];
                entry.choices = choices.map(function(c) {
                    return (c && typeof c === "object") ? { label: String(c.label !== undefined ? c.label : c.value), value: c.value }
                                                        : { label: String(c), value: c };
                });
                if (!entry.choices.length) continue;
                entry.default = entry.choices.some(function(c) { return c.value === e.default; }) ? e.default : entry.choices[0].value;
            }
            if (type === "color") entry.default = validColor(e.default) ? String(e.default) : "";
            out.push(entry);
        }
        return out;
    }
    function validColor(v) {
        return typeof v === "string" && (v === "" || /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(v));
    }
    function registerTheme(fileName, text) {
        var next = {};
        for (var f in themeDescriptors) next[f] = themeDescriptors[f];
        try {
            var j = JSON.parse(text);
            next[fileName] = {
                id: (typeof j.id === "string" && j.id) ? j.id : themeIdFromFile(fileName),
                name: String(j.name || fileName.replace(/\.json$/, "")),
                description: String(j.description || ""),
                qml: "themes/" + String(j.qml || fileName.replace(/\.json$/, ".qml")),
                panelAccent: validColor(j.panelAccent) ? j.panelAccent : "",
                settings: normalizeSchema(j.settings)
            };
        } catch (e) {
            console.warn("app-switch-overlay: bad theme descriptor " + fileName + ": " + e);
            delete next[fileName];
        }
        themeDescriptors = next;
        rebuildThemes();
    }
    function forgetTheme(fileName) {
        var next = {};
        for (var f in themeDescriptors) if (f !== fileName) next[f] = themeDescriptors[f];
        themeDescriptors = next;
        rebuildThemes();
    }
    function rebuildThemes() {
        var list = [], byId = {};
        for (var f in themeDescriptors) {
            var t = themeDescriptors[f];
            if (byId[t.id]) continue;
            byId[t.id] = t;
            list.push(t);
        }
        list.sort(function(a, b) {
            if (a.id === "base" || b.id === "base") return a.id === "base" ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        themeById = byId;
        themeList = list;
    }
    FolderListModel {
        id: themeFolder
        folder: Qt.resolvedUrl("themes")
        nameFilters: ["*.json"]
        showDirs: false
        sortField: FolderListModel.Name
    }
    Instantiator {
        model: themeFolder
        delegate: FileView {
            required property string fileName
            required property string filePath
            path: filePath
            watchChanges: true
            printErrors: false
            onFileChanged: reload()
            onLoaded: root.registerTheme(fileName, text())
            Component.onDestruction: root.forgetTheme(fileName)
        }
    }

    readonly property string activeThemeId: themeById[settings.theme] ? settings.theme : "base"
    readonly property var activeTheme: themeById[activeThemeId] || null
    readonly property string themeSource: activeTheme ? activeTheme.qml : (themeList.length ? "" : "themes/Base.qml")
    // Selected theme's options: schema defaults overlaid with valid stored values.
    function resolveOptions(theme, stored) {
        var out = {};
        if (!theme) return out;
        stored = stored || {};
        for (var i = 0; i < theme.settings.length; i++) {
            var e = theme.settings[i], v = stored[e.key];
            if (e.type === "bool") out[e.key] = typeof v === "boolean" ? v : e.default;
            else if (e.type === "number") out[e.key] = clamp(v, e.min, e.max, e.default);
            else if (e.type === "choice") out[e.key] = e.choices.some(function(c) { return c.value === v; }) ? v : e.default;
            else if (e.type === "color") out[e.key] = validColor(v) ? v : e.default;
        }
        return out;
    }
    readonly property var themeOptions: resolveOptions(activeTheme, settings.themes[activeThemeId])

    // ---------------- Workspace tracking ----------------
    function nameFor(window) {
        return window ? AppNames.label(window.appId, window.title,
            DesktopEntries.applications.values || []) : "";
    }
    function workspaceApps() {
        var windows = workspace ? workspace.toplevels.values : [];
        var records = [];
        for (var i = 0; i < windows.length; i++) {
            var window = windows[i];
            var data = window.lastIpcObject || {};
            var handle = window.wayland;
            records.push({
                appId: handle ? handle.appId : (data.class || data.initialClass || ""),
                title: window.title || data.title || "",
                focused: window.activated || (handle !== null && handle === active)
            });
        }
        return AppNames.workspaceApps(records, DesktopEntries.applications.values || []);
    }
    function contextKey() {
        // Focus changes within this desktop only refresh an already visible overlay.
        return workspace ? String(workspace.id) : "";
    }

    // Per-screen theme instances listen for these.
    signal showRequested()
    signal pulseRequested()
    signal hideRequested()

    function showWorkspace() {
        var wasOpen = opened;
        var monitor = Hyprland.focusedMonitor;
        outputName = monitor ? monitor.name : "";
        workspaceName = workspace ? workspace.name : "";
        apps = workspaceApps();
        opened = true;
        if (wasOpen) pulseRequested(); else showRequested();
        hideTimer.restart();
    }

    onActiveChanged: if (ready && opened) apps = workspaceApps()
    onWorkspaceChanged: if (ready) settleTimer.restart()
    // Give Hyprland state a moment to settle after a shell (re)start so the
    // overlay doesn't flash "No apps" on startup.
    Component.onCompleted: lastContext = contextKey()
    Timer {
        interval: 1500; running: true
        onTriggered: { root.lastContext = root.contextKey(); root.ready = true; }
    }
    Connections {
        target: root.workspace ? root.workspace.toplevels : null
        function onValuesChanged() {
            if (root.opened) root.apps = root.workspaceApps();
        }
    }
    Timer {
        id: settleTimer
        interval: 45
        onTriggered: {
            var context = root.contextKey();
            if (context !== root.lastContext) {
                root.lastContext = context;
                root.switchCount++;
                root.showWorkspace();
            } else if (root.opened) {
                root.apps = root.workspaceApps();
            }
        }
    }
    Timer {
        id: hideTimer
        interval: root.apps.length > 1
            ? Math.min(4500, root.settings.showDuration + 550 + root.apps.length * 250)
            : root.settings.showDuration
        onTriggered: { root.opened = false; root.hideRequested(); }
    }

    // ---------------- IPC ----------------
    property bool settingsOpen: false
    IpcHandler {
        target: "app-switch-overlay"
        function preview(): string {
            root.showWorkspace();
            return root.appName;
        }
        function status(): string {
            return JSON.stringify({name: root.appName, opened: root.opened,
                switches: root.switchCount, soundPlays: root.soundPlays,
                triggerMode: "workspace-only", context: root.contextKey(),
                theme: root.activeThemeId, themeSource: root.themeSource, loadedTheme: root.loadedTheme,
                themes: root.themeList.map(function(t) { return t.id; }), themeOptions: root.themeOptions,
                settingsError: root.settingsError, settingsOpen: root.settingsOpen,
                settings: root.settings, output: root.outputName,
                workspace: root.workspaceName, apps: root.apps});
        }
        function settings(): string {
            root.settingsOpen = !root.settingsOpen;
            return root.settingsOpen ? "open" : "closed";
        }
        function closeSettings(): string {
            root.settingsOpen = false;
            return "closed";
        }
    }

    // ---------------- Overlay (one per screen, click-through) ----------------
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            readonly property bool isTarget: root.outputName === "" ? modelData === Quickshell.screens[0] : modelData.name === root.outputName
            visible: themeLoader.status === Loader.Ready && themeLoader.item.active && isTarget
            anchors { top: true }
            implicitWidth: 820
            implicitHeight: root.settings.position === "center" ? modelData.height : 480
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "djk-app-switch-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Loader {
                id: themeLoader
                anchors.fill: parent
                // Qt caches directory listings, so a theme file added while the
                // shell is running may not load until `omarchy restart shell`.
                property bool fallback: false
                source: root.themeSource === "" ? "" : (fallback ? "themes/Base.qml" : root.themeSource)
                onLoaded: {
                    if (panel.isTarget) root.loadedTheme = String(source);
                    item.host = root;
                    if (item.options !== undefined) item.options = Qt.binding(function() { return root.themeOptions; });
                    item.primary = Qt.binding(function() { return panel.isTarget; });
                }
                onStatusChanged: if (status === Loader.Error && !fallback) {
                    console.warn("app-switch-overlay: theme " + root.themeSource
                        + " failed to load, using Base. New theme files need `omarchy restart shell`.");
                    fallback = true;
                }
                Connections {
                    target: root
                    function onThemeSourceChanged() { themeLoader.fallback = false; }
                }
            }
            Connections {
                target: root
                function onShowRequested() { if (panel.isTarget && themeLoader.item) themeLoader.item.show(); }
                function onPulseRequested() { if (panel.isTarget && themeLoader.item) themeLoader.item.pulse(); }
                function onHideRequested() { if (themeLoader.item) themeLoader.item.hide(); }
            }
        }
    }

    // ---------------- Settings panel ----------------
    Loader {
        active: root.settingsOpen
        sourceComponent: Component { SettingsPanel { host: root } }
    }
}
