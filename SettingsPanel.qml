import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons as Commons

// Dark, simple settings panel. Global options on top, then a section built
// from the selected theme's schema (themes/<Name>.json). Every change applies
// live and is written to ~/.config/djk/app-switch-overlay.json. Esc or × closes it.
PanelWindow {
    id: win
    property var host: null
    readonly property var s: host ? host.settings : ({})
    readonly property var theme: host ? host.activeTheme : null
    readonly property var schema: theme ? theme.settings : []
    readonly property var opts: host ? host.themeOptions : ({})
    screen: {
        var m = Hyprland.focusedMonitor;
        var list = Quickshell.screens;
        for (var i = 0; m && i < list.length; i++) if (list[i].name === m.name) return list[i];
        return list[0];
    }
    implicitWidth: 560
    implicitHeight: body.implicitHeight + 40
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "djk-app-switch-overlay-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property color bg: Qt.darker(Commons.Color.background, 1.05)
    readonly property color fg: Commons.Color.foreground
    readonly property color accent: Commons.Color.accent
    readonly property color dim: Qt.rgba(fg.r, fg.g, fg.b, 0.55)
    readonly property color line: Qt.rgba(fg.r, fg.g, fg.b, 0.12)
    readonly property string font: Commons.Style.font.family

    function set(patch) { if (host) host.updateSettings(patch); }
    function setOption(key, value) { if (host) host.updateThemeOption(key, value); }

    component Label: Text {
        color: win.fg; font.family: win.font; font.pixelSize: 13
        width: 150; verticalAlignment: Text.AlignVCenter; height: 30
    }
    component Pills: Row {
        id: pills
        property var options: []      // [{label, value}]
        property var current
        signal picked(var value)
        spacing: 6
        Repeater {
            model: pills.options
            Rectangle {
                required property var modelData
                readonly property bool on: modelData.value === pills.current
                width: pillText.implicitWidth + 24; height: 28; radius: 14
                color: on ? win.accent : "transparent"
                border.color: on ? win.accent : win.line; border.width: 1
                Text { id: pillText; anchors.centerIn: parent; text: modelData.label
                       color: parent.on ? Commons.Color.background : win.fg; font.family: win.font; font.pixelSize: 12
                       font.weight: parent.on ? Font.DemiBold : Font.Normal }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: pills.picked(modelData.value) }
            }
        }
    }
    component Toggle: Rectangle {
        id: tg
        property bool checked: false
        signal toggled(bool value)
        width: 44; height: 24; radius: 12
        color: checked ? win.accent : win.line
        Rectangle { width: 18; height: 18; radius: 9; y: 3; x: tg.checked ? tg.width - 21 : 3; color: tg.checked ? Commons.Color.background : win.fg
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: tg.toggled(!tg.checked) }
    }
    component Slider: Item {
        id: sl
        property real from: 0
        property real to: 1
        property real step: 0.05
        property real value: 0
        property string suffix: ""
        property int decimals: 2
        property real live: value
        signal moved(real value)
        width: 300; height: 30
        onValueChanged: if (!ma.pressed) live = value
        Rectangle { id: track; x: 0; width: parent.width - 70; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter; color: win.line
            Rectangle { width: Math.max(0, Math.min(1, (sl.live - sl.from) / (sl.to - sl.from))) * parent.width; height: parent.height; radius: 2; color: win.accent }
            Rectangle { width: 16; height: 16; radius: 8; color: win.fg; border.color: win.accent; border.width: 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(1, (sl.live - sl.from) / (sl.to - sl.from))) * parent.width - 8 }
        }
        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 60; horizontalAlignment: Text.AlignRight
               text: sl.live.toFixed(sl.decimals) + sl.suffix; color: win.dim; font.family: win.font; font.pixelSize: 12 }
        MouseArea {
            id: ma
            x: -8; width: track.width + 16; height: parent.height
            cursorShape: Qt.PointingHandCursor
            function at(mx) {
                var f = Math.max(0, Math.min(1, (mx - 8) / track.width));
                var v = sl.from + f * (sl.to - sl.from);
                return Math.round(v / sl.step) * sl.step;
            }
            onPressed: (m) => { sl.live = at(m.x); }
            onPositionChanged: (m) => { if (pressed) { sl.live = at(m.x); sl.moved(sl.live); } }
            onReleased: sl.moved(sl.live)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: win.bg
        border.color: win.line
        border.width: 1
        focus: true
        Keys.onEscapePressed: if (win.host) win.host.settingsOpen = false

        Column {
            id: body
            x: 22; y: 18
            width: parent.width - 44
            spacing: 8

            Item {
                width: parent.width; height: 34
                Text { id: titleText; text: "Dynamic App Switch Overlay"; color: win.fg; font.family: win.font; font.pixelSize: 17; font.weight: Font.DemiBold; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "Settings"; color: win.accent; font.family: win.font; font.pixelSize: 11; font.weight: Font.DemiBold
                       anchors.verticalCenter: parent.verticalCenter; anchors.left: titleText.right; anchors.leftMargin: 10 }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 14; color: closeMa.containsMouse ? win.line : "transparent"
                    Text { anchors.centerIn: parent; text: "×"; color: win.fg; font.pixelSize: 18 }
                    MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: if (win.host) win.host.settingsOpen = false }
                }
            }
            Rectangle { width: parent.width; height: 1; color: win.line }

            Row { spacing: 10
                Label { text: "Theme" }
                Pills { anchors.verticalCenter: parent.verticalCenter; current: win.host ? win.host.activeThemeId : ""
                        options: win.host ? win.host.themeList.map(function(t) { return {label: t.name, value: t.id}; }) : []
                        onPicked: (v) => win.set({theme: v}) } }
            Text { x: 160; width: parent.width - 160; visible: text !== ""; wrapMode: Text.WordWrap
                   text: win.theme ? win.theme.description : ""; color: win.dim; font.family: win.font; font.pixelSize: 11 }
            Row { spacing: 10
                Label { text: "Sound" }
                Toggle { anchors.verticalCenter: parent.verticalCenter; checked: win.s.soundEnabled === true
                         onToggled: (v) => win.set({soundEnabled: v}) } }
            Row { spacing: 10
                Label { text: "Volume" }
                Slider { from: 0; to: 1; step: 0.05; value: Number(win.s.volume); opacity: win.s.soundEnabled ? 1 : 0.45
                         onMoved: (v) => win.set({volume: v}) } }
            Row { spacing: 10
                Label { text: "Animation speed" }
                Slider { from: 0.5; to: 2; step: 0.1; decimals: 1; suffix: "×"; value: Number(win.s.animationSpeed)
                         onMoved: (v) => win.set({animationSpeed: v}) } }
            Row { spacing: 10
                Label { text: "Show for" }
                Slider { from: 500; to: 3000; step: 50; decimals: 0; suffix: " ms"; value: Number(win.s.showDuration)
                         onMoved: (v) => win.set({showDuration: v}) } }
            Row { spacing: 10
                Label { text: "Position" }
                Pills { anchors.verticalCenter: parent.verticalCenter; current: win.s.position
                        options: [{label: "Top", value: "top"}, {label: "Center", value: "center"}]
                        onPicked: (v) => win.set({position: v}) } }

            // ---- Theme options, generated from the selected theme's schema ----
            Rectangle { width: parent.width; height: 1; color: win.line }
            Text { text: win.theme ? win.theme.name.toUpperCase() : "THEME"
                   color: win.theme && win.theme.panelAccent ? win.theme.panelAccent : win.accent
                   font.family: win.font; font.pixelSize: 12; font.weight: Font.Bold; font.letterSpacing: 2 }
            Text { visible: win.schema.length === 0; text: "This theme has no extra options."
                   color: win.dim; font.family: win.font; font.pixelSize: 12 }
            Repeater {
                model: win.schema
                Row {
                    id: optRow
                    required property var modelData
                    readonly property var entry: modelData
                    readonly property var value: win.opts[entry.key]
                    spacing: 10
                    Label { text: optRow.entry.label }
                    Loader {
                        anchors.verticalCenter: parent.verticalCenter
                        sourceComponent: optRow.entry.type === "bool" ? boolEditor
                                       : optRow.entry.type === "number" ? numberEditor
                                       : optRow.entry.type === "choice" ? choiceEditor
                                       : colorEditor
                    }
                    Component { id: boolEditor
                        Toggle { checked: optRow.value === true; onToggled: (v) => win.setOption(optRow.entry.key, v) } }
                    Component { id: numberEditor
                        Slider { from: optRow.entry.min; to: optRow.entry.max; step: optRow.entry.step
                                 decimals: optRow.entry.decimals; suffix: optRow.entry.suffix; value: Number(optRow.value)
                                 onMoved: (v) => win.setOption(optRow.entry.key, v) } }
                    Component { id: choiceEditor
                        Pills { options: optRow.entry.choices; current: optRow.value
                                onPicked: (v) => win.setOption(optRow.entry.key, v) } }
                    Component { id: colorEditor
                        Row { spacing: 8
                            Rectangle { width: 24; height: 24; radius: 6; anchors.verticalCenter: parent.verticalCenter
                                        color: optRow.value ? optRow.value : win.accent; border.color: win.line; border.width: 1 }
                            Rectangle { width: 110; height: 28; radius: 6; color: "transparent"; border.color: win.line; border.width: 1
                                TextInput { id: hex; anchors.fill: parent; anchors.margins: 6; verticalAlignment: TextInput.AlignVCenter
                                            text: optRow.value || ""; color: win.fg; font.family: win.font; font.pixelSize: 12
                                            selectByMouse: true; maximumLength: 9
                                            onEditingFinished: {
                                                var t = text.trim();
                                                if (t === "" || /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(t)) win.setOption(optRow.entry.key, t);
                                                else text = optRow.value || "";
                                            } }
                                Text { anchors.fill: parent; anchors.margins: 6; verticalAlignment: Text.AlignVCenter
                                       visible: hex.text === "" && !hex.activeFocus; text: "default"; color: win.dim
                                       font.family: win.font; font.pixelSize: 12 } }
                            Text { anchors.verticalCenter: parent.verticalCenter; visible: optRow.entry.help !== ""
                                   width: 180; wrapMode: Text.WordWrap; text: optRow.entry.help; color: win.dim
                                   font.family: win.font; font.pixelSize: 10 } } }
                }
            }

            Rectangle { width: parent.width; height: 1; color: win.line }
            Item {
                width: parent.width; height: 40
                Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130; elide: Text.ElideMiddle
                       text: win.host && win.host.settingsError ? win.host.settingsError : "~/.config/djk/app-switch-overlay.json"
                       color: win.host && win.host.settingsError ? "#ff6b6b" : win.dim; font.family: win.font; font.pixelSize: 11 }
                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 110; height: 32; radius: 8
                    color: prevMa.pressed ? Qt.darker(win.accent, 1.2) : win.accent
                    Text { anchors.centerIn: parent; text: "Preview"; color: Commons.Color.background; font.family: win.font; font.pixelSize: 13; font.weight: Font.DemiBold }
                    MouseArea { id: prevMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (win.host) win.host.showWorkspace() }
                }
            }
        }
    }
}
