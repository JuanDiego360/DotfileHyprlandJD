import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    Scaler {
        id: scaler
        currentWidth: Screen.width
    }
    function s(val) { return scaler.s(val); }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color mauve: _theme.mauve
    readonly property color blue: _theme.blue
    readonly property color pink: _theme.pink

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
                        text: (lyricsComponent.activePlayer && lyricsComponent.activePlayer.isPlaying) ? "󰏤" : "󰐊"
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
                    text: lyricsComponent.rawTrackTitle ? (lyricsComponent.rawTrackArtist + " — " + lyricsComponent.rawTrackTitle) : "Sin pista activa"
                    font.family: "Inter"
                    font.pixelSize: root.s(13)
                    color: root.subtext0
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Main Lyrics View
            LyricsView {
                id: lyricsComponent
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
