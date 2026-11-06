import QtQuick
import ".."

// Hulk Smash: a green fist slams the card down from above, the green card slams down with squash and
// stretch, the card shakes, a shockwave and dust burst out and cracks appear.
// Repeat switches land smaller punches (more cracks each time). On hide the
// card cracks, a second green fist uppercuts through it from below, and it
// shatters into shards that fly out with spin and gravity.
// Theme interface: host, options, primary, active, show(), pulse(), hide().
// Options are declared in HulkSmash.json.
Item {
    id: theme
    anchors.fill: parent
    property var host: null
    property bool primary: false
    readonly property var s: host ? host.settings : ({})
    // Resolved values from HulkSmash.json (defaults + saved settings).
    property var options: ({})
    readonly property var hs: options || ({})
    readonly property real speed: Math.max(0.25, Number(s.animationSpeed) || 1)
    function d(ms) { return Math.max(1, Math.round(ms / speed)); }

    readonly property real shakeAmt: hs.shakeIntensity !== undefined ? Number(hs.shakeIntensity) : 1
    readonly property int shardCount: Number(hs.shardCount) || 12
    readonly property int cols: shardCount <= 6 ? 3 : shardCount <= 12 ? 4 : 5
    readonly property int rows: shardCount <= 6 ? 2 : shardCount <= 12 ? 3 : 4
    readonly property bool useFist: hs.fist !== false
    readonly property bool cracksBuildUp: hs.cracksBuildUp !== false
    readonly property bool usePunch: hs.punchThrough !== false

    // Palette
    readonly property color deep: "#1f5f1f"
    readonly property color gamma: "#3fae2a"
    readonly property color vivid: "#7CFC00"
    readonly property color shorts: "#4b2a6b"
    readonly property color ink: "#0b2a0b"

    property bool shown: false
    property bool entering: false
    property bool impacted: false
    property bool shattering: false
    property bool exiting: false
    property real shakeK: 1
    property real shardT: 0
    property real dustT: 1
    readonly property bool active: shown || entering || exiting || shattering
    readonly property var apps: host ? host.apps : []
    readonly property bool multi: apps.length > 1
    readonly property real restX: Math.round((width - card.width) / 2)
    readonly property real restY: s.position === "center" ? Math.round((height - card.height) / 2) : 52
    readonly property real restRot: -1.5

    Sfx { id: slamSfx; sound: "hulk-slam.wav"
          volume: Number(theme.s.volume); enabled: theme.s.soundEnabled !== false
          onPlayed: if (theme.host) theme.host.soundPlays++ }
    Sfx { id: punchSfx; sound: "hulk-punch.wav"
          volume: Number(theme.s.volume); enabled: theme.s.soundEnabled !== false
          onPlayed: if (theme.host) theme.host.soundPlays++ }
    Sfx { id: shatterSfx; sound: "hulk-shatter.wav"
          volume: Number(theme.s.volume); enabled: theme.s.soundEnabled !== false
          onPlayed: if (theme.host) theme.host.soundPlays++ }

    function stopAll() {
        entranceAnim.stop(); pulseAnim.stop(); shakeAnim.stop(); ringAnim.stop(); ring2Anim.stop();
        dustAnim.stop(); fistInAnim.stop(); fistOutAnim.stop(); fistPopAnim.stop(); flashAnim.stop();
        shatterAnim.stop(); glowAnim.stop(); glow.opacity = 0;
        punchInAnim.stop(); punchOutAnim.stop();
    }
    function settle() {
        cardRoot.scale = 1; cardRoot.rotation = theme.restRot; cardRoot.opacity = 1;
        drop.y = 0; sq.xScale = 1; sq.yScale = 1; shk.x = 0; shk.y = 0;
    }

    function show() {
        stopAll();
        shattering = false; exiting = false; shardT = 0;
        impacted = false;
        cracks.level = 0; cracks.opacity = 0;
        cardRoot.scale = 1.7; cardRoot.rotation = -9; cardRoot.opacity = 0;
        drop.y = -42; sq.xScale = 1; sq.yScale = 1;
        glow.opacity = 0;
        punchFist.opacity = 0; punchFist.lift = 170;
        fist.opacity = 0; fist.lift = -180;
        entering = true; shown = true;
        if (useFist) fistInAnim.start();
        entranceAnim.start();
    }

    function impact(full) {
        if (primary) (full ? slamSfx : punchSfx).play();
        impacted = true;
        shakeK = (full ? 1 : 0.45) * shakeAmt;
        shakeAnim.stop(); shk.x = 0; shk.y = 0; if (shakeK > 0) shakeAnim.start();
        ring.big = full; ringAnim.stop(); ringAnim.start();
        if (full) { ring2Anim.stop(); ring2Anim.start(); }
        burstDust(full);
        flashAnim.stop(); flash.opacity = full ? 0.55 : 0.3; flashAnim.start();
        if (full) {
            cracks.seed = Math.floor(Math.random() * 100000); cracks.level = 1;
            cracks.requestPaint(); cracks.opacity = 0.9;
            glowAnim.stop(); glowAnim.start();
        } else if (cracksBuildUp && cracks.level < 4) {
            cracks.level++; cracks.requestPaint();
        }
        if (useFist) {
            if (full) { fistInAnim.stop(); fistOutAnim.stop(); fistOutAnim.start(); }
            else { fistPopAnim.stop(); fistPopAnim.start(); }
        }
    }

    function pulse() {
        if (shattering || exiting || !shown) { show(); return; }
        if (entering) { entranceAnim.stop(); fistInAnim.stop(); entering = false; settle(); if (!impacted) impact(true); }
        pulseAnim.stop();
        sq.xScale = 1; sq.yScale = 1; cardRoot.scale = 1;
        impact(false);
        pulseAnim.start();
    }

    function hide() {
        if (!shown) return;
        stopAll(); entering = false; settle();
        fist.opacity = 0;
        shown = false;
        exiting = true;
        shatterAnim.start();
    }
    function startShards() {
        for (var i = 0; i < shardRepeater.count; i++) {
            var sh = shardRepeater.itemAt(i);
            if (sh) sh.scatter();
        }
        shardT = 0;
        shattering = true;
        if (primary) shatterSfx.play();
    }

    // ---------- Entrance ----------
    SequentialAnimation {
        id: entranceAnim
        ParallelAnimation {
            NumberAnimation { target: cardRoot; property: "opacity"; to: 1; duration: theme.d(50) }
            NumberAnimation { target: cardRoot; property: "scale"; to: 1; duration: theme.d(130); easing.type: Easing.InQuad }
            NumberAnimation { target: cardRoot; property: "rotation"; to: theme.restRot; duration: theme.d(130); easing.type: Easing.InQuad }
            NumberAnimation { target: drop; property: "y"; to: 0; duration: theme.d(130); easing.type: Easing.InQuad }
        }
        ScriptAction { script: theme.impact(true) }
        ParallelAnimation {
            NumberAnimation { target: sq; property: "xScale"; to: 1.15; duration: theme.d(40); easing.type: Easing.OutQuad }
            NumberAnimation { target: sq; property: "yScale"; to: 0.8; duration: theme.d(40); easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: sq; property: "xScale"; to: 0.96; duration: theme.d(45); easing.type: Easing.InOutQuad }
            NumberAnimation { target: sq; property: "yScale"; to: 1.07; duration: theme.d(45); easing.type: Easing.InOutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: sq; property: "xScale"; to: 1; duration: theme.d(60); easing.type: Easing.OutBack }
            NumberAnimation { target: sq; property: "yScale"; to: 1; duration: theme.d(60); easing.type: Easing.OutBack }
        }
        ScriptAction { script: theme.entering = false }
    }

    // ---------- Repeat punch (155 ms) ----------
    SequentialAnimation {
        id: pulseAnim
        ParallelAnimation {
            NumberAnimation { target: cardRoot; property: "scale"; to: 1.08; duration: theme.d(45); easing.type: Easing.OutQuad }
            NumberAnimation { target: sq; property: "xScale"; to: 1.06; duration: theme.d(45); easing.type: Easing.OutQuad }
            NumberAnimation { target: sq; property: "yScale"; to: 0.9; duration: theme.d(45); easing.type: Easing.OutQuad }
        }
        ParallelAnimation {
            NumberAnimation { target: cardRoot; property: "scale"; to: 1; duration: theme.d(110); easing.type: Easing.OutBack; easing.overshoot: 2 }
            NumberAnimation { target: sq; property: "xScale"; to: 1; duration: theme.d(110); easing.type: Easing.OutBack }
            NumberAnimation { target: sq; property: "yScale"; to: 1; duration: theme.d(110); easing.type: Easing.OutBack }
        }
    }

    // ---------- Card shake (card only, never windows) ----------
    SequentialAnimation {
        id: shakeAnim
        ParallelAnimation { NumberAnimation { target: shk; property: "x"; to: 10 * theme.shakeK; duration: theme.d(18) }
                            NumberAnimation { target: shk; property: "y"; to: -6 * theme.shakeK; duration: theme.d(18) } }
        ParallelAnimation { NumberAnimation { target: shk; property: "x"; to: -8 * theme.shakeK; duration: theme.d(22) }
                            NumberAnimation { target: shk; property: "y"; to: 5 * theme.shakeK; duration: theme.d(22) } }
        ParallelAnimation { NumberAnimation { target: shk; property: "x"; to: 5 * theme.shakeK; duration: theme.d(22) }
                            NumberAnimation { target: shk; property: "y"; to: 3 * theme.shakeK; duration: theme.d(22) } }
        ParallelAnimation { NumberAnimation { target: shk; property: "x"; to: -3 * theme.shakeK; duration: theme.d(22) }
                            NumberAnimation { target: shk; property: "y"; to: -2 * theme.shakeK; duration: theme.d(22) } }
        ParallelAnimation { NumberAnimation { target: shk; property: "x"; to: 0; duration: theme.d(26); easing.type: Easing.OutQuad }
                            NumberAnimation { target: shk; property: "y"; to: 0; duration: theme.d(26); easing.type: Easing.OutQuad } }
    }

    // ---------- Shatter (40 ms crack flash + 340 ms shards) ----------
    SequentialAnimation {
        id: shatterAnim
        ScriptAction { script: {
            cracks.level = 5; cracks.opacity = 1; cracks.requestPaint();
            flashAnim.stop(); flash.opacity = 0.35; flashAnim.start();
            if (theme.usePunch) { punchFist.lift = 170; punchFist.scale = 0.9; punchFist.opacity = 1; punchInAnim.start(); }
        } }
        PauseAnimation { duration: theme.usePunch ? theme.d(85) : theme.d(45) }
        ScriptAction { script: {
            if (theme.usePunch) {
                if (theme.primary) punchSfx.play();
                punchOutAnim.start();
                ring.big = true; ringAnim.stop(); ringAnim.start();
                theme.burstDust(true);
            }
            theme.startShards();
        } }
        NumberAnimation { target: theme; property: "shardT"; from: 0; to: 1; duration: theme.d(340); easing.type: Easing.Linear }
        ScriptAction { script: { theme.shattering = false; theme.exiting = false; cardRoot.opacity = 0; theme.shardT = 0; punchFist.opacity = 0; } }
    }

    Item {
        id: stage
        anchors.fill: parent
        transform: Translate { id: shk; x: 0; y: 0 }

        // Shockwave rings (behind the card)
        Rectangle {
            id: ring
            property bool big: true
            width: card.width + 18; height: card.height + 18
            x: theme.restX - 9; y: theme.restY - 9
            radius: height / 2
            color: "transparent"
            border.color: theme.vivid
            border.width: 4
            opacity: 0
            scale: 1
            ParallelAnimation {
                id: ringAnim
                NumberAnimation { target: ring; property: "scale"; from: 0.92; to: ring.big ? 1.7 : 1.28; duration: ring.big ? theme.d(360) : theme.d(200); easing.type: Easing.OutCubic }
                NumberAnimation { target: ring; property: "opacity"; from: ring.big ? 0.95 : 0.7; to: 0; duration: ring.big ? theme.d(360) : theme.d(200); easing.type: Easing.OutQuad }
                NumberAnimation { target: ring; property: "border.width"; from: ring.big ? 6 : 3; to: 1; duration: ring.big ? theme.d(360) : theme.d(200) }
            }
        }
        Rectangle {
            id: ring2
            width: card.width + 18; height: card.height + 18
            x: theme.restX - 9; y: theme.restY - 9
            radius: height / 2
            color: "transparent"
            border.color: theme.shorts
            border.width: 3
            opacity: 0
            SequentialAnimation {
                id: ring2Anim
                PauseAnimation { duration: theme.d(50) }
                ParallelAnimation {
                    NumberAnimation { target: ring2; property: "scale"; from: 0.95; to: 1.45; duration: theme.d(320); easing.type: Easing.OutCubic }
                    NumberAnimation { target: ring2; property: "opacity"; from: 0.8; to: 0; duration: theme.d(320); easing.type: Easing.OutQuad }
                }
            }
        }

        // Glow behind the card
        Rectangle {
            id: glow
            x: theme.restX - 8; y: theme.restY - 8
            width: card.width + 16; height: card.height + 16
            radius: 16
            color: theme.vivid
            opacity: 0
            rotation: theme.restRot
            SequentialAnimation {
                id: glowAnim
                NumberAnimation { target: glow; property: "opacity"; to: 0.45; duration: theme.d(40) }
                NumberAnimation { target: glow; property: "opacity"; to: 0.14; duration: theme.d(260); easing.type: Easing.OutQuad }
            }
        }

        // Dust burst
        Repeater {
            id: dustRepeater
            model: 14
            Rectangle {
                required property int index
                property real sx: 0
                property real sy: 0
                property real vx: 0
                property real vy: 0
                property real sz: 6
                width: sz; height: sz; radius: sz / 2
                color: index % 3 === 0 ? theme.vivid : index % 3 === 1 ? "#9ccc65" : "#6b8f47"
                x: sx + vx * theme.dustT
                y: sy + vy * theme.dustT + 90 * theme.dustT * theme.dustT
                opacity: theme.dustT >= 1 ? 0 : (1 - theme.dustT) * 0.9
                scale: 1 + theme.dustT * 0.8
            }
        }
        NumberAnimation { id: dustAnim; target: theme; property: "dustT"; from: 0; to: 1; duration: theme.d(420); easing.type: Easing.OutQuad }

        // The card
        Item {
            id: cardRoot
            x: theme.restX
            y: theme.restY
            width: card.width
            height: card.height
            opacity: 0
            rotation: theme.restRot
            transformOrigin: Item.Center
            transform: [
                Translate { id: drop; y: 0 },
                Scale { id: sq; origin.x: cardRoot.width / 2; origin.y: cardRoot.height; xScale: 1; yScale: 1 }
            ]

            Rectangle {
                id: card
                width: theme.multi ? 360 : Math.min(480, metrics.width + 70)
                height: content.implicitHeight + 30
                radius: 10
                color: theme.shorts
                Rectangle {
                    id: face
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: 8
                    clip: true
                    border.color: theme.vivid
                    border.width: 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: theme.gamma }
                        GradientStop { position: 0.55; color: "#2e8a24" }
                        GradientStop { position: 1.0; color: theme.deep }
                    }
                    // purple "shorts" stripe
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 2 }
                        height: 5
                        color: theme.shorts
                    }
                    Canvas {
                        id: cracks
                        anchors.fill: parent
                        property int level: 0
                        property int seed: 1
                        opacity: 0
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            if (level <= 0) return;
                            var r = seed;
                            function rnd() { r = (r * 1103515245 + 12345) % 2147483648; return r / 2147483648; }
                            var w = width, h = height;
                            var ox = w * (0.35 + rnd() * 0.3), oy = h * (0.55 + rnd() * 0.35);
                            var lines = 3 + level * 2;
                            for (var pass = 0; pass < 2; pass++) {
                                ctx.strokeStyle = pass === 0 ? "rgba(11,42,11,0.85)" : "rgba(180,255,120,0.55)";
                                ctx.lineWidth = pass === 0 ? 2.2 : 1;
                                var rr = r;
                                for (var i = 0; i < lines; i++) {
                                    var a = (i / lines) * Math.PI * 2 + rnd() * 0.6;
                                    var len = (0.25 + rnd() * 0.5) * Math.max(w, h);
                                    var x = ox + (pass ? 1 : 0), y = oy + (pass ? 1 : 0);
                                    ctx.beginPath(); ctx.moveTo(x, y);
                                    var steps = 4 + Math.floor(rnd() * 3);
                                    for (var k = 1; k <= steps; k++) {
                                        var t = k / steps;
                                        var ja = a + (rnd() - 0.5) * 0.9;
                                        x = ox + Math.cos(ja) * len * t; y = oy + Math.sin(ja) * len * t * 0.6;
                                        ctx.lineTo(x, y);
                                    }
                                    ctx.stroke();
                                }
                                r = rr;
                            }
                        }
                    }
                    Rectangle {
                        id: flash
                        anchors.fill: parent
                        color: "#eaffd0"
                        opacity: 0
                        NumberAnimation { id: flashAnim; target: flash; property: "opacity"; to: 0; duration: theme.d(140); easing.type: Easing.OutQuad }
                    }
                }
                Column {
                    id: content
                    anchors.centerIn: parent
                    width: parent.width - 44
                    spacing: 6
                    Text {
                        visible: theme.multi
                        width: parent.width
                        text: "WORKSPACE " + (theme.host ? theme.host.workspaceName : "")
                        textFormat: Text.PlainText
                        color: "#e6ffc8"
                        opacity: 0.85
                        font.family: "Liberation Sans"
                        font.bold: true
                        font.pixelSize: 12
                        font.letterSpacing: 2
                    }
                    Repeater {
                        model: theme.apps.length ? theme.apps : [{name: "No apps", count: 0, focused: false}]
                        Text {
                            required property var modelData
                            width: content.width
                            text: (theme.multi && modelData.focused ? "▶ " : "") +
                                modelData.name + (modelData.count > 1 ? "  ×" + modelData.count : "")
                            textFormat: Text.PlainText
                            color: modelData.focused && theme.multi ? theme.vivid : "#f4ffe8"
                            style: Text.Outline
                            styleColor: theme.ink
                            font.family: "Liberation Sans"
                            font.bold: true
                            font.italic: true
                            font.capitalization: Font.AllUppercase
                            font.pixelSize: theme.multi ? 18 : 24
                            font.letterSpacing: 0.5
                            elide: Text.ElideRight
                            horizontalAlignment: theme.multi ? Text.AlignLeft : Text.AlignHCenter
                        }
                    }
                }
            }
        }

        // Slam fist: comes down from above and its knuckles press into the
        // card's top edge, following the card's squash so it drives it down.
        HulkFist {
            id: fist
            property real lift: -180
            readonly property real press: 10
            readonly property real cardTop: theme.restY + drop.y * cardRoot.scale
                + card.height * (1 - sq.yScale) * cardRoot.scale
                + card.height / 2 * (1 - cardRoot.scale)
            x: theme.restX + card.width / 2 - width / 2
            y: cardTop - height + press + lift
            rotation: theme.restRot
            transformOrigin: Item.Bottom
            opacity: 0
            ParallelAnimation {
                id: fistInAnim
                NumberAnimation { target: fist; property: "opacity"; from: 0; to: 1; duration: theme.d(35) }
                NumberAnimation { target: fist; property: "lift"; from: -180; to: 0; duration: theme.d(130); easing.type: Easing.InQuad }
                NumberAnimation { target: fist; property: "scale"; from: 1.5; to: 1; duration: theme.d(130); easing.type: Easing.InQuad }
                NumberAnimation { target: fist; property: "rotation"; from: -14; to: theme.restRot; duration: theme.d(130); easing.type: Easing.InQuad }
            }
            SequentialAnimation {
                id: fistOutAnim
                ScriptAction { script: { fist.opacity = 1; fist.lift = 0; fist.scale = 1; } }
                PauseAnimation { duration: theme.d(150) }
                ParallelAnimation {
                    NumberAnimation { target: fist; property: "lift"; to: -70; duration: theme.d(170); easing.type: Easing.InQuad }
                    NumberAnimation { target: fist; property: "opacity"; to: 0; duration: theme.d(170); easing.type: Easing.InQuad }
                }
            }
            SequentialAnimation {
                id: fistPopAnim
                ScriptAction { script: { fist.opacity = 1; fist.scale = 1.1; fist.rotation = theme.restRot - 6; } }
                ParallelAnimation {
                    NumberAnimation { target: fist; property: "lift"; from: -45; to: 0; duration: theme.d(40); easing.type: Easing.InQuad }
                    NumberAnimation { target: fist; property: "scale"; to: 1; duration: theme.d(40) }
                    NumberAnimation { target: fist; property: "rotation"; to: theme.restRot; duration: theme.d(40) }
                }
                PauseAnimation { duration: theme.d(80) }
                ParallelAnimation {
                    NumberAnimation { target: fist; property: "lift"; to: -50; duration: theme.d(130); easing.type: Easing.InQuad }
                    NumberAnimation { target: fist; property: "opacity"; to: 0; duration: theme.d(130); easing.type: Easing.InQuad }
                }
            }
        }
    }

    function burstDust(full) {
        var n = full ? dustRepeater.count : 6;
        for (var i = 0; i < dustRepeater.count; i++) {
            var p = dustRepeater.itemAt(i);
            if (!p) continue;
            if (i >= n) { p.sx = -100; p.sy = -100; p.vx = 0; p.vy = 0; continue; }
            var side = i % 2 === 0 ? -1 : 1;
            p.sz = 4 + Math.random() * (full ? 7 : 4);
            p.sx = theme.restX + card.width / 2 + side * (card.width * (0.2 + Math.random() * 0.3));
            p.sy = theme.restY + card.height - 6;
            p.vx = side * (40 + Math.random() * (full ? 130 : 60));
            p.vy = -(10 + Math.random() * (full ? 60 : 30));
        }
        dustAnim.stop(); dustAnim.start();
    }

    // ---------- Shards (render the card once, split into pieces) ----------
    Repeater {
        id: shardRepeater
        model: theme.cols * theme.rows
        ShaderEffectSource {
            id: shard
            required property int index
            readonly property int col: index % theme.cols
            readonly property int row: Math.floor(index / theme.cols)
            readonly property real sw: card.width / theme.cols
            readonly property real shh: card.height / theme.rows
            property real vx: 0
            property real vy: 0
            property real vr: 0
            sourceItem: card
            sourceRect: Qt.rect(col * sw, row * shh, sw, shh)
            width: sw
            height: shh
            live: false
            hideSource: theme.shattering
            visible: theme.shattering
            x: theme.restX + col * sw + vx * theme.shardT
            y: theme.restY + row * shh + vy * theme.shardT + 420 * theme.shardT * theme.shardT
            rotation: theme.restRot + vr * theme.shardT
            opacity: 1 - theme.shardT * theme.shardT
            scale: 1 - 0.25 * theme.shardT
            function scatter() {
                var dx = (col + 0.5) / theme.cols - 0.5;
                var dy = (row + 0.5) / theme.rows - 0.5;
                vx = dx * (theme.usePunch ? 380 : 300) + (Math.random() - 0.5) * 90;
                vy = dy * 140 - (theme.usePunch ? 150 : 90) - Math.random() * 70;
                vr = (Math.random() - 0.5) * 420;
                scheduleUpdate();
            }
        }
    }

    // Punch-through fist: uppercuts from below, hits the card's bottom edge as
    // it shatters and drives up through it, then fades with the shards.
    HulkFist {
        id: punchFist
        property real lift: 170
        x: theme.restX + card.width / 2 - width / 2 + 10
        y: theme.restY + card.height - 8 + lift
        rotation: 180 + 6
        transformOrigin: Item.Center
        opacity: 0
        visible: opacity > 0
        NumberAnimation { id: punchInAnim; target: punchFist; property: "lift"; from: 170; to: 0; duration: theme.d(85); easing.type: Easing.InQuad }
        ParallelAnimation {
            id: punchOutAnim
            NumberAnimation { target: punchFist; property: "lift"; to: -(card.height + 70); duration: theme.d(150); easing.type: Easing.OutCubic }
            NumberAnimation { target: punchFist; property: "scale"; to: 1.3; duration: theme.d(150); easing.type: Easing.OutCubic }
            SequentialAnimation {
                PauseAnimation { duration: theme.d(170) }
                NumberAnimation { target: punchFist; property: "opacity"; to: 0; duration: theme.d(190); easing.type: Easing.InQuad }
            }
        }
    }

    TextMetrics {
        id: metrics
        text: theme.host ? String(theme.host.appName).toUpperCase() + (theme.apps.length === 1 && theme.apps[0].count > 1 ? "  ×" + theme.apps[0].count : "") : ""
        font.family: "Liberation Sans"
        font.bold: true
        font.italic: true
        font.pixelSize: 24
    }
}
