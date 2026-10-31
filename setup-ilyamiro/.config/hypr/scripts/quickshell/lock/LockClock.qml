import QtQuick
import "../"
import "redactor"

Item {
    id: clockModule
    required property var screenRoot

    property var currentTime: new Date()
    readonly property bool concealed: screenRoot.inputActive || screenRoot.centerReveal > 0.02
    readonly property real lockScaleMultiplier: {
        var ls = Config.getSetting("lockscreen", {});
        if (ls && ls.scale !== undefined && Number(ls.scale) > 0) {
            return Number(ls.scale);
        }
        var rootScale = Config.getSetting("uiScale", null);
        var gen = Config.getSetting("general", null);
        var generalScale = (gen && gen.uiScale !== undefined) ? Number(gen.uiScale) : (rootScale !== null ? Number(rootScale) : 1.0);
        return Math.max(1.45, generalScale * 1.2);
    }
    readonly property real rawFit: Math.min(width / LockLayoutStore.refW, height / LockLayoutStore.refH)
    readonly property real maxAllowedFit: Math.min(
        (width - screenRoot.s(32)) / LockLayoutStore.panelW,
        (height - screenRoot.s(72)) / LockLayoutStore.panelH
    )
    readonly property real fit: Math.min(maxAllowedFit, rawFit * lockScaleMultiplier)

    anchors.fill: parent
    opacity: clockModule.concealed ? 0.0 : 1.0
    scale: clockModule.concealed ? 0.92 : 1.0
    visible: opacity > 0.01

    Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    Item {
        width: LockLayoutStore.refW
        height: LockLayoutStore.refH
        anchors.centerIn: parent
        scale: clockModule.fit

        LockLayoutView {
            anchors.fill: parent
            scope: "screen"
            ctx: clockModule.screenRoot
        }
    }
}
