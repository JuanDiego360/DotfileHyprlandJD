pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

Item {
    id: controller

    signal setIndexRequested(var screen, string index)
    signal toggleRequested(var screen, string index)
    signal showSystemUsageRequested(var screen)

    function targetScreen(screen) {
        if (screen) return screen;
        try {
            if (typeof Hyprland !== "undefined" && Hyprland.focusedMonitor) {
                let monName = Hyprland.focusedMonitor.name;
                let screens = Quickshell.screens || [];
                let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
                for (let i = 0; i < len; i++) {
                    let s = screens[i] !== undefined ? screens[i] : screens.get(i);
                    if (s && s.name === monName) return s;
                }
            }
        } catch (e) {}
        if (Quickshell.cursorScreen) return Quickshell.cursorScreen;
        let screens = Quickshell.screens || [];
        return (screens[0] !== undefined ? screens[0] : (screens.get ? screens.get(0) : null));
    }

    function setIndex(index, screen) {
        let target = targetScreen(screen);
        if (target) controller.setIndexRequested(target, index);
    }

    function toggle(index, screen) {
        let target = targetScreen(screen);
        if (target) controller.toggleRequested(target, index);
    }

    function showSystemUsage(screen) {
        let target = targetScreen(screen);
        if (target) controller.showSystemUsageRequested(target);
    }

    IpcHandler {
        target: "floating"

        function setIndex(index: string) {
            controller.setIndex(index, null);
        }

        function toggle(index: string) {
            controller.toggle(index, null);
        }

        function showSystemUsage() {
            controller.showSystemUsage(null);
        }

        function forceReload() {
            Quickshell.reload(true)
        }
    }
}
