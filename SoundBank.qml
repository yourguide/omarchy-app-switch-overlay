import QtQuick
import QtMultimedia

// Preloaded low-latency sound. Three instances round-robin so rapid
// triggers each get their own play without cutting the previous one off.
Item {
    id: bank
    property url source
    property real volume: 0.3
    property int nextIndex: 0
    SoundEffect { id: s0; source: bank.source; volume: bank.volume }
    SoundEffect { id: s1; source: bank.source; volume: bank.volume }
    SoundEffect { id: s2; source: bank.source; volume: bank.volume }
    readonly property bool ready: s0.status === SoundEffect.Ready
    function play() {
        var s = [s0, s1, s2][nextIndex];
        nextIndex = (nextIndex + 1) % 3;
        s.stop();
        s.play();
    }
}
