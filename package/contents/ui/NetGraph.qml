import QtQuick
import org.kde.kirigami as Kirigami

// A tiny rolling sparkline of recent network throughput.
// Two lines: download (highlight colour, filled) and upload (positive colour).
// History is kept only while the popup is open (~samples * sampleInterval).
Item {
    id: g

    property real downValue: 0          // bytes/s
    property real upValue: 0            // bytes/s
    property int samples: 90
    property int sampleInterval: 1000   // ms

    property var _down: []
    property var _up: []

    implicitHeight: Kirigami.Units.gridUnit * 2.4

    Timer {
        interval: g.sampleInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var d = g._down.slice();
            var u = g._up.slice();
            d.push(Math.max(0, Number(g.downValue) || 0));
            u.push(Math.max(0, Number(g.upValue) || 0));
            while (d.length > g.samples) d.shift();
            while (u.length > g.samples) u.shift();
            g._down = d;
            g._up = u;
            canvas.requestPaint();
        }
    }

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: 3
        color: Qt.rgba(Kirigami.Theme.textColor.r,
                       Kirigami.Theme.textColor.g,
                       Kirigami.Theme.textColor.b, 0.06)
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r,
                              Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.25)
    }

    Canvas {
        id: canvas
        anchors.fill: frame
        anchors.margins: 2
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        Component.onCompleted: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            if (!ctx)
                return;
            ctx.reset();
            var w = width, h = height;

            // baseline
            ctx.strokeStyle = Qt.rgba(Kirigami.Theme.textColor.r,
                                      Kirigami.Theme.textColor.g,
                                      Kirigami.Theme.textColor.b, 0.2);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(0, h - 0.5);
            ctx.lineTo(w, h - 0.5);
            ctx.stroke();

            var n = Math.max(g._down.length, g._up.length);
            if (n < 2)
                return;

            var peak = 1;
            for (var i = 0; i < g._down.length; i++)
                peak = Math.max(peak, g._down[i]);
            for (var j = 0; j < g._up.length; j++)
                peak = Math.max(peak, g._up[j]);

            var step = w / (g.samples - 1);

            function trace(arr) {
                var startX = w - (arr.length - 1) * step;
                for (var k = 0; k < arr.length; k++) {
                    var x = startX + k * step;
                    var y = h - (arr[k] / peak) * (h - 2) - 1;
                    if (k === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                }
                return startX;
            }

            // download: filled area + stroke
            var dc = Kirigami.Theme.highlightColor;
            ctx.beginPath();
            var sx = trace(g._down);
            ctx.lineTo(w, h);
            ctx.lineTo(sx, h);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(dc.r, dc.g, dc.b, 0.20);
            ctx.fill();

            ctx.beginPath();
            trace(g._down);
            ctx.strokeStyle = Qt.rgba(dc.r, dc.g, dc.b, 1);
            ctx.lineWidth = 1.5;
            ctx.stroke();

            // upload: stroke only
            var uc = Kirigami.Theme.positiveTextColor;
            ctx.beginPath();
            trace(g._up);
            ctx.strokeStyle = Qt.rgba(uc.r, uc.g, uc.b, 1);
            ctx.lineWidth = 1.5;
            ctx.stroke();
        }
    }
}
