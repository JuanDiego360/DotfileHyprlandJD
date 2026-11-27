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
    signal showNotesRequested(var screen)
    signal openRequested(var screen)
    signal closeRequested(var screen)

    function registerInstance(panel) {
        if (!panel) return;
        let list = controller.instances.slice();
        if (list.indexOf(panel) === -1) {
            list.push(panel);
            controller.instances = list;
        }
    }

    function unregisterInstance(panel) {
        if (!panel) return;
        let list = controller.instances.filter(p => p && p !== panel);
        controller.instances = list;
    }

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
        let panel = instanceFor(screen);
        if (panel) panel.setIndex(index);
    }

    function showTab(id, screen) {
        let panel = instanceFor(screen);
        if (panel) panel.showTab(id, 0);
    }

    function showSystemUsage(screen) {
        showTab("system", screen);
    }

    function showNotes(screen) {
        showTab("notes", screen);
    }

    function open(screen) {
        let panel = instanceFor(screen);
        if (panel) panel.openPanel();
    }

    function close(screen) {
        let closedAny = false;
        for (let i = 0; i < controller.instances.length; i++) {
            let panel = controller.instances[i];
            if (!panel) continue;
            if (!screen || panel.matchesScreen(screen)) {
                if (panel.closePanel()) closedAny = true;
            }
        }
        return closedAny;
    }

    function toggle(indexOrScreen, maybeScreen) {
        if (indexOrScreen === undefined || indexOrScreen === null || (typeof indexOrScreen === "object" && !maybeScreen)) {
            if (!controller.close(null)) controller.open(indexOrScreen || null);
        } else {
            let target = targetScreen(maybeScreen);
            if (target) controller.toggleRequested(target, String(indexOrScreen));
        }
    }

    IpcHandler {
        target: "floating"

        function setIndex(index: string) {
            controller.setIndex(index, null);
        }

        function toggle(index: string) {
            if (index !== undefined && index !== null && index !== "") {
                controller.toggle(index, null);
            } else {
                controller.toggle(null);
            }
        }

        function showSystemUsage() {
            controller.showSystemUsage(null);
        }

        function showNotes() {
            controller.showNotes(null);
        }

        function open() {
            controller.open(null);
        }

        function close() {
            controller.close(null);
        }

        function forceReload() {
            ShellRouter.reload();
        }
    }
}
