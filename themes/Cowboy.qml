import QtQuick
import qs.Commons as Commons
import ".."

// Theme interface: host, options, primary, active, show(), pulse(), hide().
// One shot on exit, never on rapid focus changes. All fragments are prebuilt.
Item {
    id: theme
    anchors.fill: parent
    property var host: null
    property var options: ({})
    property bool primary: false
    readonly property var s: host ? host.settings : ({})
    readonly property real speed: Math.max(0.25, Number(s.animationSpeed) || 1)
    readonly property real swing: options.swing !== undefined ? Number(options.swing) : 1
    readonly property var apps: host ? host.apps : []
    readonly property var listedApps: apps.length ? apps.slice(0, 6) : [{name: "No apps", count: 0, focused: false}]
    readonly property int extraApps: Math.max(0, apps.length - 6)
    readonly property int boardCount: listedApps.length + 2
    readonly property real restY: s.position === "center" ? Math.round((height - sign.height) / 2) : 52
    readonly property real hitX: sign.width * 0.76
    readonly property real hitY: sign.height * 0.48
    property bool shown: false
    property bool exiting: false
    readonly property bool active: shown || exiting
    property real lift: 0
    property real sway: 0
    property real ropeOpacity: 1
    property real holeOpacity: 0
    property real flashOpacity: 0

    function d(ms) { return Math.max(1, Math.round(ms / speed)); }
    function resetPieces() {
        for (var i = 0; i < boards.count; i++) boards.itemAt(i).reset();
        for (var j = 0; j < splinters.count; j++) splinters.itemAt(j).reset();
    }
    function stopAll() {
        entranceAnim.stop(); pulseAnim.stop(); shotAnim.stop();
        resetPieces();
    }
    function settle() {
        lift = 0; sway = 0; ropeOpacity = 1;
        holeOpacity = 0; flashOpacity = 0; sign.opacity = 1;
    }
    function show() {
        stopAll(); settle();
        exiting = false; shown = true;
        lift = s.position === "top" ? 0 : -16;
        sway = -6 * swing; sign.opacity = 0.35;
        entranceAnim.start();
        if (primary) creakSfx.play();
    }
    function pulse() {
        if (!shown || exiting) { show(); return; }
        stopAll(); settle();
        pulseAnim.start();
        if (primary) creakSfx.play();
    }
    function hide() {
        if (!shown) return;
        stopAll(); settle();
        shown = false; exiting = true;
        holeOpacity = 1; flashOpacity = 0.85;
        if (primary) shotSfx.play();
        shotAnim.start();
    }
    function scatter() {
        // Recoil ends before planks rotate, keeping the burst inside the layer.
        sway = 0; lift = 0;
        for (var i = 0; i < boardCount; i++) boards.itemAt(i).scatter();
        if (options.splinters !== false)
            for (var j = 0; j < splinters.count; j++) splinters.itemAt(j).launch();
    }
    function finish() {
        resetPieces();
        sign.opacity = 0; holeOpacity = 0; flashOpacity = 0;
        ropeOpacity = 0; exiting = false;
    }

    Sfx {
        id: creakSfx
        sound: "cowboy-creak.wav"
        volume: Number(theme.s.volume) * 0.55
        enabled: theme.s.soundEnabled !== false
        onPlayed: if (theme.host) theme.host.soundPlays++
    }
    Sfx {
        id: shotSfx
        sound: "cowboy-shot.wav"
        volume: Number(theme.s.volume) * (theme.options.shotVolume !== undefined ? Number(theme.options.shotVolume) : 0.65)
        enabled: theme.s.soundEnabled !== false
        onPlayed: if (theme.host) theme.host.soundPlays++
    }

    ParallelAnimation {
        id: entranceAnim
        NumberAnimation { target: sign; property: "opacity"; to: 1; duration: theme.d(100) }
        NumberAnimation { target: theme; property: "lift"; to: 0; duration: theme.d(180); easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: theme; property: "sway"; to: 3 * theme.swing; duration: theme.d(130); easing.type: Easing.OutQuad }
            NumberAnimation { target: theme; property: "sway"; to: -1.2 * theme.swing; duration: theme.d(120); easing.type: Easing.InOutQuad }
            NumberAnimation { target: theme; property: "sway"; to: 0; duration: theme.d(130); easing.type: Easing.OutQuad }
        }
    }
    SequentialAnimation {
        id: pulseAnim
        NumberAnimation { target: theme; property: "sway"; to: 2.2 * theme.swing; duration: theme.d(55); easing.type: Easing.OutQuad }
        NumberAnimation { target: theme; property: "sway"; to: -1 * theme.swing; duration: theme.d(75); easing.type: Easing.InOutQuad }
        NumberAnimation { target: theme; property: "sway"; to: 0; duration: theme.d(100); easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: shotAnim
        ParallelAnimation {
            NumberAnimation { target: theme; property: "sway"; to: -3; duration: theme.d(45); easing.type: Easing.OutQuad }
            NumberAnimation { target: theme; property: "flashOpacity"; to: 0; duration: theme.d(85) }
        }
        PauseAnimation { duration: theme.d(65) }
        ScriptAction { script: theme.scatter() }
        ParallelAnimation {
            NumberAnimation { target: theme; property: "ropeOpacity"; to: 0; duration: theme.d(180) }
            NumberAnimation { target: theme; property: "holeOpacity"; to: 0; duration: theme.d(100) }
            PauseAnimation { duration: theme.d(350) }
        }
        ScriptAction { script: theme.finish() }
    }

    Item {
        id: sign
        width: Math.min(420, theme.width - 120)
        height: 52 + theme.listedApps.length * 42 + 28
        x: Math.round((theme.width - width) / 2)
        y: theme.restY + theme.lift
        rotation: theme.sway
        transformOrigin: Item.Top
        opacity: 0

        Repeater {
            model: 2
            Item {
                required property int index
                x: index === 0 ? 95 : sign.width - 101
                y: -30; width: 6; height: 48
                opacity: theme.ropeOpacity
                Rectangle { anchors.fill: parent; radius: 3; color: "#70502e"; border.width: 1; border.color: "#3e2b18" }
                Repeater {
                    model: 8
                    Rectangle {
                        required property int index
                        x: 1; y: index * 6; width: 4; height: 2
                        rotation: -28; color: "#c7a570"; opacity: 0.8
                    }
                }
                Rectangle {
                    x: -3; y: 35; width: 12; height: 12; radius: 6
                    color: "#604728"; border.width: 2; border.color: "#b29560"
                    Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: "#2f2115" }
                }
            }
        }
        Repeater {
            id: boards
            model: 8
            CowboyBoard {
                required property int index
                themeHost: theme
                rowIndex: index
                visible: index < theme.boardCount
                kind: index === 0 ? "header" : index === theme.boardCount - 1 ? "footer" : "app"
                app: theme.listedApps[index - 1] || ({name: "", count: 0, focused: false})
                caption: kind === "header" ? "WORKSPACE " + (theme.host ? theme.host.workspaceName : "—")
                    : theme.extraApps ? "+" + theme.extraApps + " MORE APPS" : "HAPPY TRAILS"
                baseY: index === 0 ? 0 : 52 + (index - 1) * 42
            }
        }
        Image {
            x: theme.hitX - width / 2; y: theme.hitY - height / 2
            width: 46; height: 46
            source: "CowboyHole.svg"
            visible: theme.options.bulletHole !== false
            opacity: theme.holeOpacity
        }
        Rectangle {
            x: theme.hitX - width / 2; y: theme.hitY - height / 2
            width: 26; height: 26; radius: 13
            color: "#fff0b4"; opacity: theme.flashOpacity
            Rectangle { anchors.centerIn: parent; width: 46; height: 3; rotation: -22; color: "#ffe1a0" }
            Rectangle { anchors.centerIn: parent; width: 3; height: 42; rotation: 25; color: "#ffe1a0" }
        }

        Repeater {
            id: splinters
            model: 12
            Rectangle {
                id: chip
                required property int index
                width: 3 + index % 3; height: 9 + (index * 5) % 13; radius: 1
                color: index % 2 === 0 ? "#c79a59" : "#6e4728"
                opacity: 0
                property real destinationX: 0
                property real destinationY: 0
                function reset() { flight.stop(); opacity = 0; rotation = 0; }
                function launch() {
                    reset();
                    x = theme.hitX; y = theme.hitY; opacity = 1;
                    destinationX = theme.hitX + (index % 2 === 0 ? -1 : 1) * (30 + (index * 23) % 100);
                    destinationY = Math.max(8 - theme.restY,
                        Math.min(theme.height - theme.restY - height - 20,
                            theme.hitY + (index % 3 === 0 ? -1 : 1) * (24 + (index * 17) % 74)));
                    flight.start();
                }
                ParallelAnimation {
                    id: flight
                    NumberAnimation { target: chip; property: "x"; to: chip.destinationX; duration: theme.d(300); easing.type: Easing.OutCubic }
                    NumberAnimation { target: chip; property: "y"; to: chip.destinationY; duration: theme.d(300); easing.type: Easing.OutQuad }
                    NumberAnimation { target: chip; property: "rotation"; to: chip.index % 2 === 0 ? -160 : 180; duration: theme.d(300) }
                    NumberAnimation { target: chip; property: "opacity"; to: 0; duration: theme.d(300); easing.type: Easing.InQuad }
                }
            }
        }
    }
}
