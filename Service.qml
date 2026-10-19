import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons as Commons
import "AppNames.js" as AppNames

Item {
    id: root
    property var shell: null
    readonly property var active: ToplevelManager.activeToplevel
    property string appName: ""
    property string lastAppName: ""
    property string outputName: ""
    property bool opened: false
    property bool ready: false
    property int switchCount: 0

    function nameFor(window) {
        return window ? AppNames.label(window.appId, window.title,
            DesktopEntries.applications.values || []) : "";
    }

    function showName(name) {
        var monitor = Hyprland.focusedMonitor;
        outputName = monitor ? monitor.name : "";
        appName = name;
        opened = true;
        hideTimer.restart();
    }

    // Debounce rapid focus transitions; never react to typing, changing a tab,
    // or a terminal updating its title while its window stays focused.
    onActiveChanged: if (ready) settleTimer.restart()
    Component.onCompleted: {
        lastAppName = nameFor(active);
        ready = true;
    }
    Timer {
        id: settleTimer
        interval: 70
        onTriggered: {
            if (!root.active) {
                root.opened = false;
                return;
            }
            var name = root.nameFor(root.active);
            if (name && name !== root.lastAppName) {
                root.lastAppName = name;
                root.switchCount++;
                root.showName(name);
            }
        }
    }
    Timer {
        id: hideTimer
        interval: 1050
        onTriggered: root.opened = false
    }

    // Small diagnostic surface for verification and an optional manual preview.
    IpcHandler {
        target: "app-switch-overlay"
        function preview(): string {
            root.showName(root.nameFor(root.active) || "Application");
            return root.appName;
        }
        function status(): string {
            return JSON.stringify({name: root.appName, opened: root.opened,
                switches: root.switchCount, output: root.outputName});
        }
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            visible: card.opacity > 0 &&
                (root.outputName === "" || modelData.name === root.outputName)
            anchors { top: true }
            margins { top: 52 }
            implicitWidth: Math.min(420, label.implicitWidth + 48)
            implicitHeight: 48
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "djk-app-switch-overlay"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            mask: Region {}

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 12
                color: Commons.Color.background
                border.color: Commons.Color.accent
                border.width: 1
                opacity: root.opened ? 0.96 : 0
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.opened ? 100 : 240
                        easing.type: Easing.OutCubic
                    }
                }
                Text {
                    id: label
                    anchors.centerIn: parent
                    width: Math.min(372, implicitWidth)
                    text: root.appName
                    textFormat: Text.PlainText
                    color: Commons.Color.foreground
                    font.family: Commons.Style.font.family
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
