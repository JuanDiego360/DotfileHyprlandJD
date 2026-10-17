import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import QtQuick.Window
import "../"

Item {
    id: window

    Caching { id: paths }

    property var notifModel: null
    property var liveNotifs: null
    property real layoutWidth: 500
    property real layoutHeight: 460

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: (typeof masterWindow !== "undefined" && masterWindow.screen) ? masterWindow.screen.width : Screen.width
        currentHeight: (typeof masterWindow !== "undefined" && masterWindow.screen) ? masterWindow.screen.height : Screen.height
    }

    readonly property real sf: scaler.baseScale
    function s(val) { 
        return Math.round(val * window.sf); 
    }

    property real targetMasterHeight: Math.round(580 * window.sf)
    property real targetMasterWidth: Math.round(980 * window.sf)

    onTargetMasterHeightChanged: {
        if (typeof masterWindow !== "undefined") {
            masterWindow.animH = window.targetMasterHeight;
            masterWindow.targetH = window.targetMasterHeight;
        }
    }

    onTargetMasterWidthChanged: {
        if (typeof masterWindow !== "undefined") {
            masterWindow.animW = window.targetMasterWidth;
            masterWindow.targetW = window.targetMasterWidth;
        }
    }

    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve || "#cba6f7"
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color red: _theme.red

    property real introMain: 0
    NumberAnimation on introMain {
        from: 0; to: 1.0; duration: 500; easing.type: Easing.OutExpo
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // --- DATA STATE ---
    property string moonIcon: "🌑"
    property string moonNfIcon: "󰽢"
    property string moonPercentStr: "0%"
    property string moonPhaseEs: "Luna Nueva"
    property string moonriseTime: "--:--"
    property string moonsetTime: "--:--"
    property string moonTransitTime: "--:--"
    property string sunriseTime: "--:--"
    property string sunsetTime: "--:--"
    property string sunTransitTime: "--:--"
    property string moonDistanceStr: "-- km"
    
    // New fields
    property string sunConstellation: "--"
    property string moonConstellation: "--"
    property string sunDistanceEarth: "--"
    property string moonDistanceSun: "--"
    property string sunDeclination: "--"
    property string moonDeclination: "--"
    
    property string sunDistanceEarthUa: "--"
    property string sunDistanceEarthKm: "--"
    property string moonDistanceSunUa: "--"
    property string moonDistanceSunKm: "--"
    
    property string sunDayDuration: "--:--"
    property var planetsData: []

    Process {
        id: moonPoller
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/watchers/moon_data.py"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        window.moonIcon = data.moon_icon || "🌑";
                        window.moonNfIcon = data.moon_nf_icon || "󰽢";
                        window.moonPercentStr = data.illumination || "0%";
                        window.moonPhaseEs = data.phase_name_es || "Luna Nueva";
                        window.moonriseTime = data.moonrise || "--:--";
                        window.moonsetTime = data.moonset || "--:--";
                        window.moonTransitTime = data.moon_transit || "--:--";
                        window.sunriseTime = data.sunrise || "--:--";
                        window.sunsetTime = data.sunset || "--:--";
                        window.sunTransitTime = data.sun_transit || "--:--";
                        window.moonDistanceStr = data.distance || "-- km";
                        
                        window.sunConstellation = data.sun_constellation || "--";
                        window.moonConstellation = data.moon_constellation || "--";
                        window.sunDistanceEarth = data.sun_distance_earth || "--";
                        window.moonDistanceSun = data.moon_distance_sun || "--";
                        window.sunDeclination = data.sun_declination || "--";
                        window.moonDeclination = data.moon_declination || "--";
                        
                        window.sunDistanceEarthUa = data.sun_distance_earth_ua || "--";
                        window.sunDistanceEarthKm = data.sun_distance_earth_km || "--";
                        window.moonDistanceSunUa = data.moon_distance_sun_ua || "--";
                        window.moonDistanceSunKm = data.moon_distance_sun_km || "--";
                        
                        window.sunDayDuration = data.day_duration || "--:--";
                        window.planetsData = data.planets || [];
                    } catch(e) {
                        console.log("Error parsing moon data in popup: ", e);
                    }
                }
            }
        }
    }

    Rectangle {
        id: container
        anchors.fill: parent
        radius: window.s(16)
        color: Qt.rgba(window.base.r, window.base.g, window.base.b, 0.95)
        border.color: window.surface1
        border.width: 1
        clip: true
        opacity: window.introMain

        // Ambient glows
        Rectangle {
            width: parent.width * 0.7; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(80)
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(50)
            opacity: 0.08
            color: window.mauve
        }
        Rectangle {
            width: parent.width * 0.8; height: width; radius: width / 2
            x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle) * window.s(-80)
            y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle) * window.s(-50)
            opacity: 0.06
            color: window.blue
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(20)
            spacing: window.s(15)

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: window.s(12)

                Text {
                    text: window.moonIcon
                    font.pixelSize: window.s(32)
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Detalles Astronómicos"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(19)
                        font.weight: Font.Black
                        color: window.text
                    }
                    Text {
                        text: "Pamplona, Colombia (Lat: 7.37, Lon: -72.65)"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(12)
                        font.weight: Font.Bold
                        color: window.subtext0
                    }
                }
            }

            // Divider line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.5)
            }

            // Detailed Data Grid
            GridLayout {
                columns: 3
                Layout.fillWidth: true
                Layout.fillHeight: true
                columnSpacing: window.s(20)
                rowSpacing: window.s(12)

                // LEFT PANEL: Moon Info Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4)
                    radius: window.s(12)
                    border.color: Qt.rgba(window.surface2.r, window.surface2.g, window.surface2.b, 0.5)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(15)
                        spacing: window.s(6)
                        
                        RowLayout {
                            spacing: window.s(10)
                            Text {
                                text: window.moonIcon
                                font.pixelSize: window.s(38)
                                color: window.mauve
                            }
                            ColumnLayout {
                                spacing: 0
                                Layout.fillWidth: true
                                Text {
                                    text: window.moonPhaseEs
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(16)
                                    font.weight: Font.Black
                                    color: window.text
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "Ilum: " + window.moonPercentStr
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(13)
                                    font.weight: Font.Bold
                                    color: window.mauve
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.3)
                        }

                        // Times
                        ColumnLayout {
                            spacing: window.s(4)
                            Layout.fillWidth: true
                            
                            RowLayout {
                                Text { text: "Sale:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonriseTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Tránsito:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonTransitTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Se pone:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonsetTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Dist. Tierra:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonDistanceStr; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.mauve; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Dist. Sol (UA):"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonDistanceSunUa; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.mauve; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Dist. Sol (km):"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonDistanceSunKm; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.mauve; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Constelación:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonConstellation; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Declinación:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.moonDeclination; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                        }
                    }
                }

                // RIGHT PANEL: Sun Info Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4)
                    radius: window.s(12)
                    border.color: Qt.rgba(window.surface2.r, window.surface2.g, window.surface2.b, 0.5)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(15)
                        spacing: window.s(6)
                        
                        RowLayout {
                            spacing: window.s(10)
                            Text {
                                text: "☀️"
                                font.pixelSize: window.s(38)
                                color: window.yellow
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Sol"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(16)
                                    font.weight: Font.Black
                                    color: window.text
                                }
                                Text {
                                    text: "Localidad"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(13)
                                    font.weight: Font.Bold
                                    color: window.yellow
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.3)
                        }

                        // Times
                        ColumnLayout {
                            spacing: window.s(4)
                            Layout.fillWidth: true
                            
                            RowLayout {
                                Text { text: "Amanecer:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunriseTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Tránsito:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunTransitTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Atardecer:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunsetTime; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Dist. Tierra (UA):"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunDistanceEarthUa; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.yellow; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Dist. Tierra (km):"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunDistanceEarthKm; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.yellow; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Duración Día:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunDayDuration; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.yellow; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Constelación:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunConstellation; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                            RowLayout {
                                Text { text: "Declinación:"; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.subtext0; font.weight: Font.Bold }
                                Item { Layout.fillWidth: true }
                                Text { text: window.sunDeclination; font.family: "JetBrains Mono"; font.pixelSize: window.s(13); color: window.text; font.weight: Font.Black }
                            }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }

                // RIGHT PANEL: Planets Info Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4)
                    radius: window.s(12)
                    border.color: Qt.rgba(window.surface2.r, window.surface2.g, window.surface2.b, 0.5)
                    border.width: 1
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.s(15)
                        spacing: window.s(6)
                        
                        RowLayout {
                            spacing: window.s(10)
                            Text {
                                text: "🪐"
                                font.pixelSize: window.s(38)
                                color: window.mauve
                            }
                            ColumnLayout {
                                spacing: 0
                                Text {
                                    text: "Planetas"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(16)
                                    font.weight: Font.Black
                                    color: window.text
                                }
                                Text {
                                    text: "Visibilidad Local"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(13)
                                    font.weight: Font.Bold
                                    color: window.mauve
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true; height: 1
                            color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.3)
                        }

                        // Planet List
                        ColumnLayout {
                            spacing: window.s(6)
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            
                            Repeater {
                                model: window.planetsData
                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: window.s(48)
                                    color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.2)
                                    radius: window.s(8)
                                    border.color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.2)
                                    border.width: 1
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: window.s(8)
                                        spacing: window.s(8)
                                        
                                        ColumnLayout {
                                            spacing: 0
                                            Layout.fillWidth: true
                                            RowLayout {
                                                spacing: window.s(6)
                                                Rectangle {
                                                    width: window.s(6); height: width; radius: width/2
                                                    color: modelData.color
                                                }
                                                Text {
                                                    text: modelData.name
                                                    font.family: "JetBrains Mono"
                                                    font.pixelSize: window.s(13)
                                                    font.weight: Font.Black
                                                    color: window.text
                                                }
                                            }
                                            Text {
                                                text: modelData.visible === "Sí" ? "Visible: " + modelData.alt : "Bajo horiz."
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: window.s(11)
                                                font.weight: Font.Bold
                                                color: modelData.visible === "Sí" ? window.green : window.subtext0
                                            }
                                        }
                                        
                                        ColumnLayout {
                                            spacing: 0
                                            Layout.alignment: Qt.AlignRight
                                            Text {
                                                text: "Dir: " + modelData.az
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: window.s(11)
                                                font.weight: Font.Bold
                                                color: window.text
                                                horizontalAlignment: Text.AlignRight
                                            }
                                            Text {
                                                text: "󰖕 " + modelData.rise + " | 󰖖 " + modelData.set
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: window.s(10)
                                                font.weight: Font.Bold
                                                color: window.subtext0
                                                horizontalAlignment: Text.AlignRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
