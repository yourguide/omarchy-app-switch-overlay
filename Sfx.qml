import QtQuick
import Quickshell

// One theme sound. Set `sound` to a file name inside the plugin's sounds/
// directory (or `file` to an absolute path). Uses SoundBank (QtMultimedia
// SoundEffect, preloaded, no process spawn). If QtMultimedia can't load,
// falls back to running `pw-play` (PipeWire) for each play.
Item {
    id: sfx
    property string sound: ""
    property string file: ""
    property real volume: 0.3
    property bool enabled: true
    signal played()
    readonly property url url: file ? ("file://" + file) : (sound ? Qt.resolvedUrl("sounds/" + sound) : "")
    readonly property string path: file ? file : (sound ? decodeURIComponent(String(url).replace(/^file:\/\//, "")) : "")
    Loader {
        id: bankLoader
        source: "SoundBank.qml"
    }
    Binding { target: bankLoader.item; property: "source"; value: sfx.url; when: bankLoader.status === Loader.Ready }
    Binding { target: bankLoader.item; property: "volume"; value: sfx.volume; when: bankLoader.status === Loader.Ready }
    readonly property string method: bankLoader.status === Loader.Ready && bankLoader.item.ready ? "SoundEffect" : "pw-play"
    function play() {
        if (!enabled || !path || volume <= 0) return;
        if (bankLoader.status === Loader.Ready && bankLoader.item.ready) {
            bankLoader.item.play();
        } else {
            Quickshell.execDetached(["pw-play", "--latency=256", "--volume", String(volume), path]);
        }
        played();
    }
}
