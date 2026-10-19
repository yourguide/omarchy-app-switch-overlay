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
