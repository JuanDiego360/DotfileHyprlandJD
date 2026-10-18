pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../../"

Item {
    id: controller

    property bool isVisible: false
    property var screen: null

    function getFocusedScreen() {
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

        try {
            if (typeof Quickshell !== "undefined" && Quickshell.screens) {
                let screens = Quickshell.screens;
                let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
                if (len > 0) return screens[0] !== undefined ? screens[0] : screens.get(0);
            }
        } catch (e) {}

        return null;
    }

    function getScreen(scr) {
        if (scr === undefined || scr === null) return getFocusedScreen();
        if (typeof scr === "object") {
            if (typeof Quickshell !== "undefined" && Quickshell.screens) {
                let screens = Quickshell.screens;
                let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
                for (let i = 0; i < len; i++) {
                    let s = screens[i] !== undefined ? screens[i] : screens.get(i);
                    if (s && (s === scr || s.name === scr.name)) return s;
                }
            }
            return scr;
        }
        if (typeof Quickshell !== "undefined" && Quickshell.screens) {
            let screens = Quickshell.screens;
            let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
            if (typeof scr === "number") {
                if (scr >= 0 && scr < len) {
                    return screens[scr] !== undefined ? screens[scr] : screens.get(scr);
                }
            }
            if (typeof scr === "string") {
                for (let i = 0; i < len; i++) {
                    let s = screens[i] !== undefined ? screens[i] : screens.get(i);
                    if (s && s.name === scr) return s;
                }
            }
        }
        return getFocusedScreen() || scr;
    }

    function show(scr) {
        let target = getScreen(scr);
        if (target !== null && target !== undefined) {
            controller.screen = target;
        } else {
            let focused = getFocusedScreen();
            if (focused !== null && focused !== undefined) {
                controller.screen = focused;
            }
        }
        if (!controller.screen && typeof Quickshell !== "undefined" && Quickshell.screens) {
            let screens = Quickshell.screens;
            let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
            if (len > 0) controller.screen = screens[0] !== undefined ? screens[0] : screens.get(0);
        }
        controller.isVisible = true;
    }

    function hide() {
        controller.isVisible = false;
    }

    function toggle(scr) {
        let target = getScreen(scr);
        let resolved = target !== null && target !== undefined ? target : getFocusedScreen();
        if (!resolved && typeof Quickshell !== "undefined" && Quickshell.screens) {
            let screens = Quickshell.screens;
            let len = screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0);
            if (len > 0) resolved = screens[0] !== undefined ? screens[0] : screens.get(0);
        }

        if (controller.isVisible) {
            if (resolved !== undefined && resolved !== null && controller.screen !== resolved) {
                controller.screen = resolved;
            } else {
                hide();
            }
        } else {
            show(resolved);
        }
    }
}
