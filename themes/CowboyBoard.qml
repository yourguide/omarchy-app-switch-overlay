import QtQuick
import qs.Commons as Commons

// One reusable plank. Fixed instances keep rapid switching allocation-free.
Item {
    id: board
    property var themeHost: null
    property int rowIndex: 0
    property string kind: "app"
    property var app: ({name: "", count: 0, focused: false})
    property string caption: ""
    property real baseY: 0
    property real shiftX: 0
    property real shiftY: 0
    property real turn: 0
    property real destinationX: 0
    property real destinationY: 0
    property real destinationTurn: 0
    readonly property color lettering: Qt.tint(Commons.Color.foreground, "#ccefdab1")
    width: parent ? parent.width : 420
    height: kind === "header" ? 52 : kind === "footer" ? 28 : 42
    x: shiftX; y: baseY + shiftY
    rotation: turn

    function reset() {
        departure.stop();
        shiftX = 0; shiftY = 0; turn = 0; opacity = 1;
    }
    function scatter() {
        reset();
        destinationX = (rowIndex % 2 === 0 ? -1 : 1) * (38 + (rowIndex * 13) % 45);
        destinationY = Math.min(48 + rowIndex * 3,
            Math.max(0, themeHost.height - themeHost.restY - baseY - height - 54));
        destinationTurn = (rowIndex % 2 === 0 ? -1 : 1) * (8 + rowIndex % 5);
        departure.start();
    }
    ParallelAnimation {
        id: departure
        NumberAnimation { target: board; property: "shiftX"; to: board.destinationX; duration: board.themeHost ? board.themeHost.d(340) : 340; easing.type: Easing.OutCubic }
        NumberAnimation { target: board; property: "shiftY"; to: board.destinationY; duration: board.themeHost ? board.themeHost.d(340) : 340; easing.type: Easing.InQuad }
        NumberAnimation { target: board; property: "turn"; to: board.destinationTurn; duration: board.themeHost ? board.themeHost.d(340) : 340; easing.type: Easing.OutQuad }
        SequentialAnimation {
            PauseAnimation { duration: board.themeHost ? board.themeHost.d(70) : 70 }
            NumberAnimation { target: board; property: "opacity"; to: 0; duration: board.themeHost ? board.themeHost.d(270) : 270; easing.type: Easing.InQuad }
        }
    }

    Image {
        anchors.fill: parent
        anchors.topMargin: 3
        source: "CowboyWood.svg"
        opacity: 0.55
        layer.enabled: false
        // The small shadow follows the shell's palette.
        Rectangle { anchors.fill: parent; z: -1; color: Commons.Color.background; opacity: 0.5 }
    }
    Image {
        anchors.fill: parent
        source: "CowboyWood.svg"
        mirror: board.rowIndex % 2 !== 0
    }
    Rectangle {
        visible: board.kind === "app" && board.app.focused
        x: 30; y: 7
        width: parent.width - 60; height: parent.height - 14; radius: 2
        color: "#201208"; opacity: 0.28
        border.width: 1; border.color: Commons.Color.accent
    }
    Column {
        visible: board.kind === "header"
        anchors.centerIn: parent
        spacing: 1
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "★  FRONTIER  ★"
            color: "#f4d99a"
            style: Text.Outline; styleColor: "#422b17"
            font.family: "Liberation Serif"; font.bold: true
            font.pixelSize: 20; font.letterSpacing: 2
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: board.caption
            textFormat: Text.PlainText
            color: board.lettering
            font.family: Commons.Style.font.family
            font.pixelSize: 9; font.letterSpacing: 1.4
            width: Math.min(320, implicitWidth)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }
    }
    Text {
        visible: board.kind === "app" && board.app.focused
        x: 34; anchors.verticalCenter: parent.verticalCenter
        text: "★"
        color: "#e8c16e"
        style: Text.Outline; styleColor: "#4b3019"
        font.pixelSize: 15
    }
    Text {
        visible: board.kind === "app"
        x: 58; anchors.verticalCenter: parent.verticalCenter
        width: parent.width - x - (countText.visible ? countText.width + 38 : 32)
        text: board.app.name
        textFormat: Text.PlainText
        color: board.lettering
        style: Text.Outline; styleColor: "#402917"
        font.family: Commons.Style.font.family
        font.pixelSize: board.app.focused ? 19 : 17
        font.weight: board.app.focused ? Font.Bold : Font.Normal
        elide: Text.ElideRight
    }
    Text {
        id: countText
        visible: board.kind === "app" && board.app.count > 1
        anchors.right: parent.right; anchors.rightMargin: 32
        anchors.verticalCenter: parent.verticalCenter
        text: "×" + board.app.count
        color: board.lettering
        style: Text.Outline; styleColor: "#402917"
        font.family: Commons.Style.font.family; font.pixelSize: 12
    }
    Text {
        visible: board.kind === "footer"
        anchors.centerIn: parent
        width: parent.width - 60
        text: board.caption
        textFormat: Text.PlainText
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: board.lettering; opacity: 0.8
        font.family: Commons.Style.font.family
        font.pixelSize: 10; font.letterSpacing: 1.8
    }
}
