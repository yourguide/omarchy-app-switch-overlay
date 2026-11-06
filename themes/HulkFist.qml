import QtQuick

// A Hulk-green fist drawn with Canvas (no emoji/glyph, so it is always green).
// Drawn knuckles-DOWN with the forearm going up out of the top. Rotate 180
// for an uppercut coming from below. Knuckle row sits at the bottom edge.
Canvas {
    id: fist
    width: 104
    height: 132
    antialiasing: true
    property color light: "#8be04f"
    property color mid: "#3fae2a"
    property color dark: "#1f5f1f"
    property color ink: "#0b2a0b"
    property color highlight: "#c6ff8f"
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        var W = width, H = height;
        function rr(x, y, w, h, r) {
            ctx.beginPath();
            ctx.moveTo(x + r, y);
            ctx.lineTo(x + w - r, y); ctx.quadraticCurveTo(x + w, y, x + w, y + r);
            ctx.lineTo(x + w, y + h - r); ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
            ctx.lineTo(x + r, y + h); ctx.quadraticCurveTo(x, y + h, x, y + h - r);
            ctx.lineTo(x, y + r); ctx.quadraticCurveTo(x, y, x + r, y);
            ctx.closePath();
        }
        function shade(x0, x1) {
            var g = ctx.createLinearGradient(x0, 0, x1, 0);
            g.addColorStop(0, fist.light); g.addColorStop(0.45, fist.mid); g.addColorStop(1, fist.dark);
            return g;
        }
        ctx.lineJoin = "round";
        ctx.strokeStyle = fist.ink;
        ctx.lineWidth = 3;

        // Forearm (flares out toward the top, off the edge)
        ctx.beginPath();
        ctx.moveTo(W * 0.20, -2); ctx.lineTo(W * 0.80, -2);
        ctx.lineTo(W * 0.76, H * 0.46); ctx.lineTo(W * 0.24, H * 0.46); ctx.closePath();
        ctx.fillStyle = shade(W * 0.2, W * 0.8); ctx.fill(); ctx.stroke();
        // forearm veins / muscle lines
        ctx.strokeStyle = fist.dark; ctx.lineWidth = 2;
        ctx.beginPath(); ctx.moveTo(W * 0.38, 4); ctx.quadraticCurveTo(W * 0.46, H * 0.18, W * 0.40, H * 0.36); ctx.stroke();
        ctx.beginPath(); ctx.moveTo(W * 0.62, 8); ctx.quadraticCurveTo(W * 0.56, H * 0.2, W * 0.63, H * 0.34); ctx.stroke();
        ctx.strokeStyle = fist.ink; ctx.lineWidth = 3;

        // Back of the hand
        rr(W * 0.07, H * 0.34, W * 0.86, H * 0.38, 14);
        ctx.fillStyle = shade(W * 0.07, W * 0.93); ctx.fill(); ctx.stroke();

        // Four curled fingers, knuckles pointing down
        var fw = W * 0.205, fx0 = W * 0.085, fy = H * 0.58, fh = H * 0.40;
        for (var i = 0; i < 4; i++) {
            var fx = fx0 + i * (fw + W * 0.003);
            var drop = (i === 1 || i === 2) ? 0 : -H * 0.025;
            rr(fx, fy + drop, fw, fh, fw * 0.45);
            ctx.fillStyle = shade(fx, fx + fw); ctx.fill(); ctx.stroke();
            // finger crease
            ctx.strokeStyle = fist.dark; ctx.lineWidth = 2;
            ctx.beginPath(); ctx.moveTo(fx + fw * 0.2, fy + drop + fh * 0.48); ctx.quadraticCurveTo(fx + fw * 0.5, fy + drop + fh * 0.56, fx + fw * 0.8, fy + drop + fh * 0.48); ctx.stroke();
            // knuckle highlight
            ctx.fillStyle = fist.highlight; ctx.globalAlpha = 0.75;
            ctx.beginPath(); ctx.ellipse(fx + fw * 0.22, fy + drop + fh * 0.66, fw * 0.42, fh * 0.16); ctx.fill();
            ctx.globalAlpha = 1;
            ctx.strokeStyle = fist.ink; ctx.lineWidth = 3;
        }

        // Thumb wrapped across the fingers
        ctx.beginPath();
        ctx.moveTo(W * 0.04, H * 0.46);
        ctx.quadraticCurveTo(W * 0.02, H * 0.66, W * 0.18, H * 0.70);
        ctx.lineTo(W * 0.52, H * 0.70);
        ctx.quadraticCurveTo(W * 0.62, H * 0.66, W * 0.56, H * 0.60);
        ctx.lineTo(W * 0.22, H * 0.56);
        ctx.quadraticCurveTo(W * 0.16, H * 0.50, W * 0.18, H * 0.42);
        ctx.closePath();
        var tg = ctx.createLinearGradient(0, H * 0.5, 0, H * 0.72);
        tg.addColorStop(0, fist.light); tg.addColorStop(1, fist.mid);
        ctx.fillStyle = tg; ctx.fill(); ctx.stroke();
        // thumbnail
        ctx.fillStyle = fist.dark; ctx.globalAlpha = 0.8;
        rr(W * 0.40, H * 0.61, W * 0.11, H * 0.06, 4); ctx.fill();
        ctx.globalAlpha = 1;
        // rim light on the back of the hand
        ctx.strokeStyle = fist.highlight; ctx.lineWidth = 2; ctx.globalAlpha = 0.6;
        ctx.beginPath(); ctx.moveTo(W * 0.14, H * 0.37); ctx.lineTo(W * 0.66, H * 0.37); ctx.stroke();
        ctx.globalAlpha = 1;
    }
    Component.onCompleted: requestPaint()
}
