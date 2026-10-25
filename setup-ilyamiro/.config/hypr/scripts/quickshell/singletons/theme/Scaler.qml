pragma Singleton
import QtQuick
import QtQuick.Window
import Quickshell
import "../../"

Item {
    id: root
    visible: false

    property string screenName: Screen.name
    property real currentWidth: 1920.0
    property real currentHeight: 1080.0

    property real uiScale: {
        var displayConf = Config.getSetting("display", null);
        if (displayConf && displayConf.monitors && displayConf.monitors[screenName] && displayConf.monitors[screenName].scale !== undefined) {
            return displayConf.monitors[screenName].scale;
        }
        var general = Config.getSetting("general", null);
        if (general && general.uiScale !== undefined) {
            return general.uiScale;
        }
        var rootScale = Config.getSetting("uiScale", null);
        if (rootScale !== null && rootScale !== undefined && !isNaN(Number(rootScale))) {
            return Number(rootScale);
        }
        return 1.0;
    }

    property real baseScale: uiScale

    function s(val) {
        return val * uiScale;
    }
}
