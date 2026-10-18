import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../reusables"
import "../../../"

Item {
    id: root
    property var module: null
    property var widget: module

    readonly property var activeTarget: widget || module

    property string orientation: activeTarget && activeTarget.orientation !== undefined ? activeTarget.orientation : "horizontal"
    readonly property bool isVertical: orientation === "vertical"

    readonly property bool isCompact: activeTarget ? Boolean(activeTarget.isCompact) : false
    readonly property var barWindow: activeTarget ? activeTarget.barWindow : null
    readonly property bool isPreview: activeTarget ? Boolean(activeTarget.isPreview) : false
    readonly property bool showLayout: (barWindow && !isPreview) ? Boolean(barWindow.isStartupReady) : true
    readonly property real barOpacity: ThemeBackend.elementOpacity

    function s(val) {
        if (barWindow && typeof barWindow.cs === "function") return barWindow.cs(val);
        if (activeTarget && typeof activeTarget.s === "function") return activeTarget.s(val);
        return val;
    }

    property int configRevision: 0

    Connections {
        target: (typeof Config !== "undefined") ? Config : null
        function onSettingsLoaded() { root.configRevision++; }
        function onRawSettingsChanged() { root.configRevision++; }
    }

    property string menuStyle: {
        if (widget && widget !== root && widget.menuStyle !== undefined) return widget.menuStyle;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.menuStyle) return Config.rawSettings.bar.menuStyle;
        return "button";
    }

    property bool showSettings: {
        if (widget && widget !== root && widget.menuShowSettings !== undefined) return widget.menuShowSettings;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.menuShowSettings !== undefined) return Boolean(Config.rawSettings.bar.menuShowSettings);
        return true;
    }

    property bool showLauncher: {
        if (widget && widget !== root && widget.menuShowLauncher !== undefined) return widget.menuShowLauncher;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.menuShowLauncher !== undefined) return Boolean(Config.rawSettings.bar.menuShowLauncher);
        return true;
    }

    property bool showUpdater: {
        if (widget && widget !== root && widget.menuShowUpdater !== undefined) return widget.menuShowUpdater;
        let dummy = configRevision;
        if (typeof Config !== "undefined" && Config.rawSettings && Config.rawSettings.bar && Config.rawSettings.bar.menuShowUpdater !== undefined) return Boolean(Config.rawSettings.bar.menuShowUpdater);
        return true;
    }

    property bool updateAvailable: false

    Process {
        id: updatePoller
        command: ["bash", "-c", "if [ -f " + Caching.getCacheDir("updater") + "/update_pending ]; then echo '1'; else echo '0'; fi"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.updateAvailable = (this.text.trim() === "1");
            }
        }
    }

    Process {
        id: updateWatcher
        running: true
        command: ["bash", "-c", "inotifywait -qq -e create,delete,close_write " + Caching.getCacheDir("updater") + "/ 2>/dev/null || sleep 5"]
        onExited: {
            updatePoller.running = false;
            updatePoller.running = true;
            running = false;
            running = true;
        }
    }

    readonly property bool effectiveShowSettings: showSettings || !showLauncher
    readonly property bool iconOnly: menuStyle === "icon"

    readonly property var helpButton: effectiveShowSettings ? settingsBtn : launcherBtn

    property real targetLength: (!module || module.moduleActive) ? ((isVertical ? buttonsFlow.implicitHeight : buttonsFlow.implicitWidth) + s(isCompact ? 6 : 8)) : 0

    implicitWidth: isVertical ? (parent ? parent.width : 0) : targetLength
    implicitHeight: isVertical ? targetLength : (parent ? parent.height : 0)

    component MenuButton: Item {
        id: menuBtn
        property string glyph: ""
        property bool hasUpdate: false
        signal clicked()

        width: root.isVertical ? root.s(root.isCompact ? 28 : 30) : root.s(root.isCompact ? 30 : 32)
        height: root.s(root.isCompact ? 28 : 30)

        opacity: (root.isVertical || root.showLayout) ? 1.0 : 0.0
        transform: Translate {
            y: (root.isVertical || root.showLayout) ? 0 : root.s(15)
            Behavior on y { NumberAnimation { duration: 620; easing.type: Easing.OutQuint } }
        }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Math.max(0, ThemeBackend.borderRadius - root.s(2))
            color: ThemeBackend.green
            z: -1
            visible: menuBtn.hasUpdate && !root.iconOnly

            SequentialAnimation on scale {
                running: menuBtn.hasUpdate
                loops: Animation.Infinite
                NumberAnimation { from: 1.0; to: 1.25; duration: 2000; easing.type: Easing.OutCubic }
            }
            SequentialAnimation on opacity {
                running: menuBtn.hasUpdate
                loops: Animation.Infinite
                NumberAnimation { from: 0.35; to: 0.0; duration: 2000; easing.type: Easing.OutCubic }
            }
        }

        IconButton {
            anchors.fill: parent
            visible: !root.iconOnly
            cornerRadius: Math.max(0, ThemeBackend.borderRadius - root.s(2))
            buttonIcon: menuBtn.glyph
            iconFontSize: root.s(root.isCompact ? 14 : 15)
            accentColor: menuBtn.hasUpdate ? Qt.rgba(ThemeBackend.green.r, ThemeBackend.green.g, ThemeBackend.green.b, 0.20) : (root.isCompact ? Qt.lighter(ThemeBackend.surface0, 1.18) : ThemeBackend.surface0)
            bgOpacity: root.barOpacity
            textColor: menuBtn.hasUpdate ? ThemeBackend.green : (isHoveredOrHighlighted ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2))
            onClicked: menuBtn.clicked()
        }

        Text {
            anchors.centerIn: parent
            visible: root.iconOnly
            text: menuBtn.glyph
            font.family: ThemeBackend.iconFont
            font.pixelSize: root.s(root.isCompact ? 15 : 16)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: menuBtn.hasUpdate ? ThemeBackend.green : (iconMouse.containsMouse ? ThemeBackend.text : (root.isCompact ? ThemeBackend.subtext0 : ThemeBackend.overlay2))
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        MouseArea {
            id: iconMouse
            anchors.fill: parent
            visible: root.iconOnly
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: menuBtn.clicked()
        }
    }

    AxisFlow {
        id: buttonsFlow
        vertical: root.isVertical
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        spacing: root.s(root.isCompact ? 2 : 4)
        anchors.centerIn: root.isVertical ? parent : undefined
        anchors.verticalCenter: root.isVertical ? undefined : parent.verticalCenter
        anchors.left: root.isVertical ? undefined : parent.left
        anchors.leftMargin: root.isVertical ? 0 : root.s(root.isCompact ? 3 : 4)

        MenuButton {
            id: settingsBtn
            visible: root.effectiveShowSettings
            glyph: "󰒓"
            onClicked: if (!root.isPreview) Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
        }

        MenuButton {
            id: updateBtn
            visible: root.showUpdater
            glyph: "󰚰"
            hasUpdate: root.updateAvailable
            onClicked: {
                if (!root.isPreview) {
                    root.updateAvailable = false;
                    Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle updater"]);
                }
            }
        }

        MenuButton {
            id: launcherBtn
            visible: root.showLauncher
            glyph: "󰍉"
            onClicked: if (!root.isPreview) Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle launcher"])
        }
    }
}
