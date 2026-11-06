import QtQuick
import qs.Commons as Commons
import ".."

// Finite, restartable animations only: the circuit rests between switches.
// Theme interface: host, options, primary, active, show(), pulse(), hide().
Item {
    id: theme
    anchors.fill: parent
    property var host: null
    property var options: ({})
    property bool primary: false
    readonly property var s: host ? host.settings : ({})
    readonly property real speed: Math.max(0.25, Number(s.animationSpeed) || 1)
    readonly property color accent: options.tint ? options.tint : Commons.Color.accent
    readonly property real glowStrength: options.glow !== undefined ? Number(options.glow) : 1
    readonly property var apps: host ? host.apps : []
    readonly property var listedApps: apps.length ? apps.slice(0, 6) : [{name: "No apps", count: 0, focused: false}]
    readonly property int extraApps: Math.max(0, apps.length - 6)
    readonly property real restY: s.position === "center" ? Math.round((height - frame.height) / 2) : 52
    property bool shown: false
    readonly property bool active: shown || frame.opacity > 0 || exitAnim.running
    property real charge: 0
    property real traceExtent: 0
    property real lift: 0

    function d(ms) { return Math.max(1, Math.round(ms / speed)); }
    function alpha(color, amount) { return Qt.rgba(color.r, color.g, color.b, amount); }
    function stopAll() {
        entranceAnim.stop(); pulseAnim.stop(); exitAnim.stop(); scanAnim.stop();
    }
    function scanAndSound() {
        scanBeam.x = -64;
        if (options.scan !== false) scanAnim.start();
        if (primary) connectSfx.play();
    }
    function show() {
        stopAll();
        shown = true;
        frame.opacity = 0.2; frame.scale = 0.97; lift = 7;
        charge = 1; traceExtent = 0.05;
        entranceAnim.start();
        scanAndSound();
    }
    function pulse() {
        if (!shown) { show(); return; }
        stopAll();
        frame.opacity = 1; frame.scale = 1; lift = 0;
        charge = 1; traceExtent = 1;
        pulseAnim.start();
        scanAndSound();
    }
    function hide() {
        if (!shown) return;
        stopAll();
        shown = false;
        scanBeam.x = -64;
        exitAnim.start();
    }

    Sfx {
        id: connectSfx
        sound: "neon-circuit.wav"
        volume: Number(theme.s.volume)
        enabled: theme.s.soundEnabled !== false
        onPlayed: if (theme.host) theme.host.soundPlays++
    }

    ParallelAnimation {
        id: entranceAnim
        NumberAnimation { target: frame; property: "opacity"; to: 1; duration: theme.d(100) }
        NumberAnimation { target: frame; property: "scale"; to: 1; duration: theme.d(220); easing.type: Easing.OutCubic }
        NumberAnimation { target: theme; property: "lift"; to: 0; duration: theme.d(220); easing.type: Easing.OutCubic }
        NumberAnimation { target: theme; property: "traceExtent"; to: 1; duration: theme.d(280); easing.type: Easing.OutCubic }
        NumberAnimation { target: theme; property: "charge"; to: 0; duration: theme.d(450); easing.type: Easing.OutQuad }
    }
    ParallelAnimation {
        id: pulseAnim
        SequentialAnimation {
            NumberAnimation { target: frame; property: "scale"; to: 1.012; duration: theme.d(55); easing.type: Easing.OutQuad }
            NumberAnimation { target: frame; property: "scale"; to: 1; duration: theme.d(125); easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: theme; property: "charge"; to: 0; duration: theme.d(320); easing.type: Easing.OutQuad }
    }
    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation { target: frame; property: "opacity"; to: 0; duration: theme.d(170); easing.type: Easing.InQuad }
            NumberAnimation { target: frame; property: "scale"; to: 0.98; duration: theme.d(170); easing.type: Easing.InQuad }
            NumberAnimation { target: theme; property: "lift"; to: -5; duration: theme.d(170) }
            NumberAnimation { target: theme; property: "traceExtent"; to: 0; duration: theme.d(120) }
            NumberAnimation { target: theme; property: "charge"; to: 0; duration: theme.d(120) }
        }
        ScriptAction { script: { frame.opacity = 0; frame.scale = 1; theme.lift = 0; } }
    }
    NumberAnimation {
        id: scanAnim
        target: scanBeam; property: "x"; from: -64; to: card.width + 64
        duration: theme.d(420); easing.type: Easing.OutCubic
    }

    Item {
        id: frame
        width: Math.min(420, theme.width - 180)
        height: content.implicitHeight + 36
        x: Math.round((theme.width - width) / 2)
        y: theme.restY + theme.lift
        opacity: 0

        // Three fixed-size border halos, not a blur/shader or a painted canvas.
        Repeater {
            model: 3
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: frame.width + 8 + index * 8
                height: frame.height + 8 + index * 8
                radius: 15 + index * 4
                color: "transparent"
                border.width: 2
                border.color: theme.accent
                opacity: theme.glowStrength * (0.055 - index * 0.013) * (0.35 + theme.charge)
            }
        }

        // Mirrored PCB traces grow out from the card and end in solder pads.
        Repeater {
            model: 2
            Item {
                id: wing
                required property int index
                width: 70; height: 72
                x: index === 0 ? -width : frame.width
                y: Math.round((frame.height - height) / 2)
                visible: theme.options.traces !== false
                opacity: 0.5 + theme.charge * 0.5
                transform: Scale {
                    origin.x: wing.index === 0 ? wing.width : 0
                    xScale: theme.traceExtent
                }
                Repeater {
                    model: 3
                    Item {
                        required property int index
                        readonly property real reach: 60 - index * 14
                        readonly property real bend: index === 0 ? -12 : index === 2 ? 12 : 0
                        x: wing.index === 0 ? wing.width : 0
                        y: 18 + index * 18
                        Rectangle {
                            width: parent.reach - 14; height: 2
                            x: wing.index === 0 ? -width : 0
                            color: theme.accent; opacity: 0.65
                        }
                        Rectangle {
                            width: 2; height: Math.abs(parent.bend) + 2
                            x: wing.index === 0 ? -parent.reach + 14 : parent.reach - 16
                            y: Math.min(0, parent.bend)
                            color: theme.accent; opacity: 0.65
                        }
                        Rectangle {
                            width: 16; height: 2
                            x: wing.index === 0 ? -parent.reach : parent.reach - 16
                            y: parent.bend
                            color: theme.accent; opacity: 0.65
                        }
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            x: wing.index === 0 ? -parent.reach - 4 : parent.reach - 2
                            y: parent.bend - 2
                            color: Commons.Color.background
                            border.width: 1; border.color: theme.accent
                        }
                    }
                }
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 12
            color: theme.alpha(Commons.Color.background, 0.97)
            border.width: 1
            border.color: theme.alpha(theme.accent, 0.5 + theme.charge * 0.45)

            Item {
                anchors.fill: parent
                anchors.margins: 2
                clip: true
                Rectangle {
                    id: scanBeam
                    x: -64; width: 52; height: parent.height
                    visible: theme.options.scan !== false && scanAnim.running
                    color: theme.alpha(theme.accent, 0.035)
                    Rectangle {
                        anchors.right: parent.right
                        width: 2; height: parent.height
                        color: theme.alpha(theme.accent, 0.3)
                    }
                }
            }
            Rectangle {
                x: 22; y: 0; width: 68; height: 2; radius: 1
                color: theme.accent
                opacity: 0.65 + theme.charge * 0.35
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 22
                y: parent.height - 2; width: 38; height: 2; radius: 1
                color: theme.accent
                opacity: 0.4 + theme.charge * 0.5
            }
        }

        Column {
            id: content
            x: 20; y: 18
            width: frame.width - 40
            spacing: 12
            Item {
                width: parent.width; height: 16
                Row {
                    spacing: 7
                    Rectangle {
                        width: 6; height: 6; radius: 3; y: 5
                        color: theme.accent
                    }
                    Text {
                        text: "NEON / CIRCUIT"
                        color: Commons.Color.foreground
                        opacity: 0.8
                        font.family: Commons.Style.font.family
                        font.pixelSize: 10; font.letterSpacing: 1.4
                    }
                }
                Text {
                    anchors.right: parent.right
                    width: 128
                    text: "WS " + (theme.host ? theme.host.workspaceName : "—")
                    textFormat: Text.PlainText
                    color: Commons.Color.foreground; opacity: 0.55
                    font.family: Commons.Style.font.family
                    font.pixelSize: 10; font.letterSpacing: 1
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                }
            }
            Rectangle {
                width: parent.width; height: 1
                color: theme.alpha(theme.accent, 0.18)
            }
            Column {
                width: parent.width
                spacing: 5
                Repeater {
                    model: theme.listedApps
                    Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index
                        width: content.width; height: 34; radius: 5
                        color: modelData.focused ? theme.alpha(theme.accent, 0.09) : "transparent"
                        Rectangle {
                            x: 0; y: 8; width: 2; height: 18; radius: 1
                            color: theme.accent; visible: appRow.modelData.focused
                        }
                        Text {
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            text: String(appRow.index + 1).padStart(2, "0")
                            color: Commons.Color.foreground; opacity: 0.4
                            font.family: Commons.Style.font.family; font.pixelSize: 10
                        }
                        Text {
                            x: 38; anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - x - (countBadge.visible ? countBadge.width + 16 : 10)
                            text: appRow.modelData.name
                            textFormat: Text.PlainText
                            color: Commons.Color.foreground
                            opacity: appRow.modelData.focused ? 1 : 0.75
                            font.family: Commons.Style.font.family
                            font.pixelSize: 17
                            font.weight: appRow.modelData.focused ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }
                        Rectangle {
                            id: countBadge
                            visible: appRow.modelData.count > 1
                            anchors.right: parent.right; anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: countText.implicitWidth + 12; height: 22; radius: 4
                            color: theme.alpha(theme.accent, 0.1)
                            Text {
                                id: countText
                                anchors.centerIn: parent
                                text: "×" + appRow.modelData.count
                                color: Commons.Color.foreground
                                font.family: Commons.Style.font.family; font.pixelSize: 11
                            }
                        }
                    }
                }
            }
            Text {
                visible: theme.extraApps > 0
                width: parent.width
                text: "+" + theme.extraApps + " more apps"
                color: Commons.Color.foreground; opacity: 0.55
                font.family: Commons.Style.font.family; font.pixelSize: 11
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
