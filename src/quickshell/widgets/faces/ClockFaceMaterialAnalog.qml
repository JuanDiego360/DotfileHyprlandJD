import QtQuick
import "../../"

Item {
    id: root
    anchors.fill: parent
    clip: true

    property real minWidth: 100
    property real minHeight: 100
    property real maxWidth: 800
    property real maxHeight: 800
    property real minAspect: 1.0
    property real maxAspect: 1.0
    property bool isRound: true

    property bool showSeconds: false

    property var currentTime: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = new Date()
    }

    function resolveColor(token, fallback) {
        if (ThemeBackend.matugenColors) {
            var val = ThemeBackend.matugenColors[token];
            if (val) {
                if (typeof val === "string") return Qt.color(val);
                if (typeof val === "object") {
                    if (val.hex) return Qt.color(val.hex);
                    if (val.color) return Qt.color(val.color);
                    if (val.default && val.default.hex) return Qt.color(val.default.hex);
                }
            }
        }
        return fallback;
    }

    readonly property color dialColor: resolveColor("primary_container", ThemeBackend.surface0)
    readonly property color hourHandColor: resolveColor("secondary", ThemeBackend.peach)
    readonly property color minuteHandColor: resolveColor("primary", ThemeBackend.mauve)
    readonly property color secondHandColor: resolveColor("tertiary", ThemeBackend.teal)
    readonly property color indicatorColor: resolveColor("tertiary", resolveColor("secondary", ThemeBackend.peach))

    Item {
        anchors.fill: parent

        Canvas {
            id: dialCanvas
            anchors.fill: parent
            antialiasing: true

            property color fillColor: root.dialColor

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onFillColorChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var cx = width / 2;
                var cy = height / 2;
                var size = Math.min(width, height);
                var lobes = 12;
                var rMid = size * 0.46;
                var rAmp = size * 0.012;
                var steps = 240;

                ctx.beginPath();
                for (var i = 0; i <= steps; i++) {
                    var a = (i / steps) * Math.PI * 2;
                    var r = rMid + rAmp * Math.cos(lobes * a);
                    var x = cx + r * Math.sin(a);
                    var y = cy - r * Math.cos(a);

                    if (i === 0) {
                        ctx.moveTo(x, y);
                    } else {
                        ctx.lineTo(x, y);
                    }
                }
                ctx.closePath();
                ctx.fillStyle = fillColor;
                ctx.fill();
            }
        }

        Rectangle {
            id: indicatorDot
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.075
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width, parent.height) * 0.085
            height: width
            radius: width / 2
            color: root.indicatorColor
            antialiasing: true
        }

        Item {
            id: hourPivot
            anchors.centerIn: parent
            z: 1
            rotation: (root.currentTime.getHours() % 12) * 30 + root.currentTime.getMinutes() * 0.5 + root.currentTime.getSeconds() * (0.5 / 60)

            Behavior on rotation {
                RotationAnimation {
                    duration: 350
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                width: Math.min(root.width, root.height) * 0.076
                height: Math.min(root.width, root.height) * 0.24
                radius: width / 2
                color: root.hourHandColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -width / 2
                antialiasing: true
            }
        }

        Item {
            id: minutePivot
            anchors.centerIn: parent
            z: 2
            rotation: root.currentTime.getMinutes() * 6 + root.currentTime.getSeconds() * 0.1

            Behavior on rotation {
                RotationAnimation {
                    duration: 350
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                width: Math.min(root.width, root.height) * 0.082
                height: Math.min(root.width, root.height) * 0.36
                radius: width / 2
                color: root.minuteHandColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -width / 2
                antialiasing: true
            }
        }

        Item {
            id: secondPivot
            visible: root.showSeconds
            anchors.centerIn: parent
            z: 3
            rotation: root.currentTime.getSeconds() * 6

            Behavior on rotation {
                RotationAnimation {
                    duration: 1000
                    direction: RotationAnimation.Clockwise
                    easing.type: Easing.Linear
                }
            }

            Rectangle {
                width: Math.min(root.width, root.height) * 0.02
                height: Math.min(root.width, root.height) * 0.39
                radius: width / 2
                color: root.secondHandColor
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.top
                anchors.bottomMargin: -width / 2
                antialiasing: true
            }
        }
    }
}
