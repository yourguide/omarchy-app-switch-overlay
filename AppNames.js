.pragma library

function label(appId, title, entries) {
    var id = String(appId || "");
    var key = id.toLowerCase();
    var text = String(title || "");
    // Chromium app windows can share the browser's appId. Match app titles
    // before desktop entries, without displaying conversation or page titles.
    if (/^(factory)(\s|$)/i.test(text) || /[|\-–—] Factory$/i.test(text)) return "Factory";
    if (/Microsoft Teams$/i.test(text)) return "Microsoft Teams";
    var known = {
        "org.omarchy.agent": "Agent",
        "chatgpt": "ChatGPT",
        "grok-bot": "Grok Bot",
        "chromium": "Chromium",
        "google-chrome": "Google Chrome",
        "com.mitchellh.ghostty": "Ghostty",
        "alacritty": "Alacritty",
        "kitty": "Kitty",
        "herdr": "Herdr"
    };
    if (known[key]) return known[key];
    for (var i = 0; i < entries.length; i++) {
        var entry = entries[i];
        if (String(entry.id || "").replace(/\.desktop$/, "").toLowerCase() === key)
            return String(entry.name || id);
    }
    return id || "Application";
}

// Input is already restricted to the selected workspace by the shell model.
// Group equal display names while retaining the focused app and window counts.
function workspaceApps(windows, entries) {
    var apps = [];
    for (var i = 0; i < windows.length; i++) {
        var window = windows[i];
        var name = label(window.appId, window.title, entries);
        var existing = null;
        for (var j = 0; j < apps.length; j++) {
            if (apps[j].name === name) { existing = apps[j]; break; }
        }
        if (existing) {
            existing.count++;
            existing.focused = existing.focused || !!window.focused;
        } else {
            apps.push({ name: name, count: 1, focused: !!window.focused });
        }
    }
    apps.sort(function(a, b) {
        if (a.focused !== b.focused) return a.focused ? -1 : 1;
        return a.name.localeCompare(b.name);
    });
    return apps;
}
