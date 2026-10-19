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
    readonly property var workspace: Hyprland.focusedWorkspace
    property var apps: []
    property string workspaceName: ""
    readonly property string appName: apps.length ? apps[0].name : "No apps"
    property string lastContext: ""
    property string outputName: ""
    property bool opened: false
    property bool ready: false
    property int switchCount: 0

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
        return (workspace ? String(workspace.id) : "") + ":" + nameFor(active);
    }

    function showWorkspace() {
        var monitor = Hyprland.focusedMonitor;
        outputName = monitor ? monitor.name : "";
        workspaceName = workspace ? workspace.name : "";
        apps = workspaceApps();
        opened = true;
        hideTimer.restart();
    }

    // Debounce rapid focus transitions; never react to typing, changing a tab,
    // or a terminal updating its title while its window stays focused.
    onActiveChanged: if (ready) settleTimer.restart()
    onWorkspaceChanged: if (ready) settleTimer.restart()
    Component.onCompleted: {
        lastContext = contextKey();
        ready = true;
    }
    Connections {
        target: root.workspace ? root.workspace.toplevels : null
        function onValuesChanged() {
            if (root.opened) settleTimer.restart();
        }
    }
    Timer {
        id: settleTimer
        interval: 70
        onTriggered: {
            var context = root.contextKey();
            if (context !== root.lastContext) {
                root.lastContext = context;
                root.switchCount++;
                root.showWorkspace();
            } else if (root.opened) {
                // Keep an already visible list accurate after an open/close/move,
                // without extending the time it remains on screen.
                root.apps = root.workspaceApps();
            }
        }
    }
    Timer {
        id: hideTimer
        interval: root.apps.length > 1 ? Math.min(4500, 1600 + root.apps.length * 250) : 1050
        onTriggered: root.opened = false
    }

    // Small diagnostic surface for verification and an optional manual preview.
    IpcHandler {
        target: "app-switch-overlay"
        function preview(): string {
            root.showWorkspace();
            return root.appName;
        }
        function status(): string {
            return JSON.stringify({name: root.appName, opened: root.opened,
                switches: root.switchCount, output: root.outputName,
                workspace: root.workspaceName, apps: root.apps});
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
            implicitWidth: root.apps.length > 1 ? 340 : Math.min(420, singleMetrics.width + 48)
            implicitHeight: content.implicitHeight + 24
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
                Column {
                    id: content
                    anchors.centerIn: parent
                    width: parent.width - 40
                    spacing: 8
                    Text {
                        visible: root.apps.length > 1
                        width: parent.width
                        text: "Workspace " + root.workspaceName
                        textFormat: Text.PlainText
                        color: Commons.Color.foreground
                        opacity: 0.65
                        font.family: Commons.Style.font.family
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                    Repeater {
                        model: root.apps.length ? root.apps : [{name: "No apps", count: 0, focused: false}]
                        Text {
                            required property var modelData
                            width: content.width
                            text: (root.apps.length > 1 && modelData.focused ? "●  " : "") +
                                modelData.name + (modelData.count > 1 ? "  ×" + modelData.count : "")
                            textFormat: Text.PlainText
                            color: modelData.focused && root.apps.length > 1 ? Commons.Color.accent : Commons.Color.foreground
                            font.family: Commons.Style.font.family
                            font.pixelSize: 18
                            font.weight: modelData.focused ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            horizontalAlignment: root.apps.length > 1 ? Text.AlignLeft : Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
    TextMetrics {
        id: singleMetrics
        text: root.appName + (root.apps.length === 1 && root.apps[0].count > 1 ? "  ×" + root.apps[0].count : "")
        font.family: Commons.Style.font.family
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }
}
