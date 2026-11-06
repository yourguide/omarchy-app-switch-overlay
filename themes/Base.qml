import QtQuick
import qs.Commons as Commons
import ".."

// Base theme: the original swoosh card. Slides down with a small overshoot,
// nudges on repeat switches, slides up and fades out.
// Theme interface: host, options, primary, active, show(), pulse(), hide().
// Options are declared in Base.json.
Item {
    id: theme
    anchors.fill: parent
    property var host: null
    property bool primary: false
    readonly property var s: host ? host.settings : ({})
    // Resolved values from Base.json (defaults + saved settings).
    property var options: ({})
    readonly property real speed: Math.max(0.25, Number(s.animationSpeed) || 1)
    function d(ms) { return Math.max(1, Math.round(ms / speed)); }

    property bool shown: false
    readonly property bool active: shown || card.opacity > 0
    readonly property var apps: host ? host.apps : []
    readonly property bool multi: apps.length > 1
    readonly property real restY: s.position === "center" ? Math.round((height - card.height) / 2) : 52

    function sound() { if (primary) swoosh.play(); }
    function resetPulse() { nudge.y = 0; nscale.xScale = 1; nscale.yScale = 1; }
    function show() { pulseAnim.stop(); resetPulse(); shown = true; sound(); }
    function pulse() { if (!shown) { show(); return; } sound(); pulseAnim.stop(); resetPulse(); pulseAnim.start(); }
    function hide() { shown = false; }

    Sfx {
        id: swoosh
        sound: "swoosh.wav"
        volume: Number(theme.s.volume)
        enabled: theme.s.soundEnabled !== false
        onPlayed: if (theme.host) theme.host.soundPlays++
    }

    Rectangle {
        id: card
        width: theme.multi ? 340 : Math.min(420, metrics.width + 48)
        height: content.implicitHeight + 24
        x: Math.round((theme.width - width) / 2)
        y: theme.shown ? theme.restY : theme.restY - 12
        scale: theme.shown ? 1 : 0.96
        transformOrigin: Item.Top
        opacity: theme.shown ? 0.96 : 0
        radius: theme.options.cornerRadius !== undefined ? theme.options.cornerRadius : 12
        color: Commons.Color.background
        border.color: theme.options.accentColor ? theme.options.accentColor : Commons.Color.accent
        border.width: 1
        Behavior on y { NumberAnimation { duration: theme.d(180); easing.type: theme.shown ? Easing.OutBack : Easing.InCubic; easing.overshoot: 1.2 } }
        Behavior on scale { NumberAnimation { duration: theme.shown ? theme.d(160) : theme.d(180); easing.type: theme.shown ? Easing.OutCubic : Easing.InCubic } }
        Behavior on opacity { NumberAnimation { duration: theme.shown ? theme.d(120) : theme.d(180); easing.type: theme.shown ? Easing.OutCubic : Easing.InCubic } }
        transform: [
            Translate { id: nudge; y: 0 },
            Scale { id: nscale; origin.x: card.width / 2; origin.y: 0; xScale: 1; yScale: 1 }
        ]
        SequentialAnimation {
            id: pulseAnim
            ParallelAnimation {
                NumberAnimation { target: nudge; property: "y"; from: 0; to: 7; duration: theme.d(55); easing.type: Easing.OutQuad }
                NumberAnimation { target: nscale; properties: "xScale,yScale"; from: 1; to: 1.03; duration: theme.d(55); easing.type: Easing.OutQuad }
            }
            ParallelAnimation {
                NumberAnimation { target: nudge; property: "y"; to: 0; duration: theme.d(95); easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                NumberAnimation { target: nscale; properties: "xScale,yScale"; to: 1; duration: theme.d(95); easing.type: Easing.OutCubic }
            }
        }
        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - 40
            spacing: 8
            Text {
                visible: theme.multi
                width: parent.width
                text: "Workspace " + (theme.host ? theme.host.workspaceName : "")
                textFormat: Text.PlainText
                color: Commons.Color.foreground
                opacity: 0.65
                font.family: Commons.Style.font.family
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            Repeater {
                model: theme.apps.length ? theme.apps : [{name: "No apps", count: 0, focused: false}]
                Text {
                    required property var modelData
                    width: content.width
                    text: (theme.multi && modelData.focused ? "●  " : "") +
                        modelData.name + (modelData.count > 1 ? "  ×" + modelData.count : "")
                    textFormat: Text.PlainText
                    color: modelData.focused && theme.multi ? Commons.Color.accent : Commons.Color.foreground
                    font.family: Commons.Style.font.family
                    font.pixelSize: 18
                    font.weight: modelData.focused ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    horizontalAlignment: theme.multi ? Text.AlignLeft : Text.AlignHCenter
                }
            }
        }
    }
    TextMetrics {
        id: metrics
        text: theme.host ? theme.host.appName + (theme.apps.length === 1 && theme.apps[0].count > 1 ? "  ×" + theme.apps[0].count : "") : ""
        font.family: Commons.Style.font.family
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }
}
