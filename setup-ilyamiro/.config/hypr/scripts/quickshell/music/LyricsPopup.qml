import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "."
import "../"
import "../reusables/media" as Media

Item {
    id: root

    function s(val) { return (typeof Scaler !== "undefined") ? Scaler.s(val) : val; }

    readonly property color base: (typeof ThemeBackend !== "undefined" && ThemeBackend.base) ? ThemeBackend.base : "#1e1e2e"
    readonly property color surface0: (typeof ThemeBackend !== "undefined" && ThemeBackend.surface0) ? ThemeBackend.surface0 : "#313244"
    readonly property color surface1: (typeof ThemeBackend !== "undefined" && ThemeBackend.surface1) ? ThemeBackend.surface1 : "#45475a"
    readonly property color surface2: (typeof ThemeBackend !== "undefined" && ThemeBackend.surface2) ? ThemeBackend.surface2 : "#585b70"
    readonly property color text: (typeof ThemeBackend !== "undefined" && ThemeBackend.text) ? ThemeBackend.text : "#cdd6f4"
    readonly property color subtext0: (typeof ThemeBackend !== "undefined" && ThemeBackend.subtext0) ? ThemeBackend.subtext0 : "#a6adc8"
    readonly property color mauve: (typeof ThemeBackend !== "undefined" && ThemeBackend.mauve) ? ThemeBackend.mauve : "#cba6f7"
    readonly property color blue: (typeof ThemeBackend !== "undefined" && ThemeBackend.blue) ? ThemeBackend.blue : "#89b4fa"
    readonly property color pink: (typeof ThemeBackend !== "undefined" && ThemeBackend.pink) ? ThemeBackend.pink : "#f5c2e7"

    onVisibleChanged: {
        if (root.visible && typeof Lyrics !== "undefined") {
            Lyrics.subscribe();
        } else if (!root.visible && typeof Lyrics !== "undefined") {
            Lyrics.unsubscribe();
        }
    }

    Component.onCompleted: {
        if (root.visible && typeof Lyrics !== "undefined") {
            Lyrics.subscribe();
        }
    }

    Component.onDestruction: {
        if (typeof Lyrics !== "undefined") {
            Lyrics.unsubscribe();
        }
    }

    // Background Container
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.88)
        radius: root.s(22)
        border.color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.35)
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#000000"
            shadowOpacity: 0.55
            shadowBlur: 0.8
            shadowVerticalOffset: 4
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.s(20)
            spacing: root.s(14)

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(12)

                Text {
                    text: "󰳰"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: root.s(24)
                    color: root.mauve
                }

                Text {
                    text: "Letras en Vivo"
                    font.family: "JetBrains Mono"
                    font.bold: true
                    font.pixelSize: root.s(18)
                    color: root.text
                }

                Item { Layout.fillWidth: true }

                // Quick Play/Pause Control
                Rectangle {
                    width: root.s(32)
                    height: root.s(32)
                    radius: root.s(8)
                    color: playBtnMouse.containsMouse ? root.surface2 : root.surface1

                    Text {
                        anchors.centerIn: parent
                        text: (typeof MprisController !== "undefined" && MprisController.isPlaying) ? "󰏤" : "󰐊"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: root.s(16)
                        color: root.mauve
                    }

                    MouseArea {
                        id: playBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                    }
                }

                // Close Button
                Rectangle {
                    width: root.s(32)
                    height: root.s(32)
                    radius: root.s(8)
                    color: closeBtnMouse.containsMouse ? root.surface2 : root.surface1

                    Text {
                        anchors.centerIn: parent
                        text: "󰅖"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: root.s(16)
                        color: root.text
                    }

                    MouseArea {
                        id: closeBtnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh close"])
                    }
                }
            }

            // Track info subtitle
            RowLayout {
                Layout.fillWidth: true
                spacing: root.s(8)

                Text {
                    text: (typeof MprisController !== "undefined" && MprisController.trackTitle) ? (MprisController.trackArtist + " — " + MprisController.trackTitle) : "Sin pista activa"
                    font.family: "Inter"
                    font.pixelSize: root.s(13)
                    color: root.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Main Lyrics View
            Media.LyricsView {
                id: lyricsComponent
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: true
                animate: true
            }
        }
    }
}
