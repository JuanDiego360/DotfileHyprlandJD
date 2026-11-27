.pragma library

var SURFACES = {
    "network": {
        id: "network",
        aliases: ["wifi", "bt", "bluetooth", "ethernet"],
        host: "master",
        comp: "network/NetworkPopup.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: 720,
        h: 600,
        pos: {
            "top": { anchor: "top-right", mt: 52, mr: 4 },
            "bottom": { anchor: "bottom-right", mb: 52, mr: 4 },
            "left": { anchor: "bottom-left", ml: 52, mb: 4 },
            "right": { anchor: "bottom-right", mr: 52, mb: 4 }
        }
    },
    "volume": {
        id: "volume",
        aliases: ["audio"],
        host: "master",
        comp: "volume/VolumePopup.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: 410,
        h: 580,
        pos: {
            "top": { anchor: "top-right", mt: 52, mr: 5 },
            "bottom": { anchor: "bottom-right", mb: 52, mr: 5 },
            "left": { anchor: "bottom-left", ml: 52, mb: 5 },
            "right": { anchor: "bottom-right", mr: 52, mb: 5 }
        }
    },
    "guide": {
        id: "guide",
        aliases: ["settings"],
        host: "master",
        comp: "guide/GuidePopup.qml",
        barRelative: false,
        draggable: true,
        preservePosition: true,
        exclusiveGroup: "popover",
        w: 1200,
        h: 750,
        pos: {
            "top": { anchor: "center" },
            "bottom": { anchor: "center" },
            "left": { anchor: "center" },
            "right": { anchor: "center" }
        }
    },
    "wallpaper": {
        id: "wallpaper",
        aliases: [],
        host: "master",
        comp: "wallpaper/WallpaperPicker.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: "fill",
        h: 650,
        pos: {
            "top": { anchor: "center-left" },
            "bottom": { anchor: "center-left" },
            "left": { anchor: "center-left" },
            "right": { anchor: "center-left" }
        }
    },
    "music": {
        id: "music",
        aliases: ["media"],
        host: "master",
        comp: "media/MusicPopup.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: 625,
        h: 565,
        pos: {
            "top": { anchor: "top-left", mt: 52, ml: 5 },
            "bottom": { anchor: "bottom-left", mb: 52, ml: 5 },
            "left": { anchor: "top-left", mt: 5, ml: 52 },
            "right": { anchor: "top-right", mt: 5, mr: 52 }
        }
    },
    "notifications": {
        id: "notifications",
        aliases: [],
        host: "master",
        comp: "notifications/NotificationCenter.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: 500,
        h: "fill",
        pos: {
            "top": { anchor: "left" },
            "bottom": { anchor: "left" },
            "left": { anchor: "left" },
            "right": { anchor: "left" }
        }
    },
    "system": {
        id: "system",
        aliases: ["syspanel"],
        host: "master",
        comp: "syspanel/SystemPanel.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover",
        w: 500,
        h: "fill",
        pos: {
            "top": { anchor: "right" },
            "bottom": { anchor: "right" },
            "left": { anchor: "right" },
            "right": { anchor: "left" }
        }
    },
    "hidden": {
        id: "hidden",
        aliases: [],
        host: "master",
        comp: "",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "none",
        w: 1,
        h: 1,
        pos: {
            "top": { anchor: "hidden" },
            "bottom": { anchor: "hidden" },
            "left": { anchor: "hidden" },
            "right": { anchor: "hidden" }
        }
    },
    "launcher": {
        id: "launcher",
        aliases: ["applauncher"],
        host: "standalone",
        comp: "launcher/Launcher.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "clipboard": {
        id: "clipboard",
        aliases: ["clip"],
        host: "standalone",
        comp: "clipboard/Clipboard.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "calendar": {
        id: "calendar",
        aliases: ["dashboard"],
        host: "standalone",
        comp: "calendar/Dashboard.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "desktopmenu": {
        id: "desktopmenu",
        aliases: [],
        host: "standalone",
        comp: "popouts/DesktopMenu.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "dockappmenu": {
        id: "dockappmenu",
        aliases: [],
        host: "standalone",
        comp: "popouts/DockAppMenu.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "traymenu": {
        id: "traymenu",
        aliases: [],
        host: "standalone",
        comp: "popouts/TrayBase.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "sidemusic": {
        id: "sidemusic",
        aliases: [],
        host: "standalone",
        comp: "popouts/SideMusicPopout.qml",
        barRelative: true,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "popover"
    },
    "floating": {
        id: "floating",
        aliases: ["quickactions"],
        host: "standalone",
        comp: "quickactions/Floating.qml",
        barRelative: false,
        draggable: false,
        preservePosition: false,
        exclusiveGroup: "none"
    }
};

function resolveId(rawId) {
    if (rawId === undefined || rawId === null) return "";
    let key = String(rawId).trim().toLowerCase();
    if (key === "") return "";
    if (SURFACES[key]) return key;
    for (let id in SURFACES) {
        let aliases = SURFACES[id].aliases;
        if (aliases && aliases.indexOf(key) !== -1) return id;
    }
    return "";
}

function getSurface(rawId) {
    let id = resolveId(rawId);
    return id !== "" ? SURFACES[id] : null;
}

function surfacesInGroup(group) {
    let out = [];
    if (!group || group === "none") return out;
    for (let id in SURFACES) {
        if (SURFACES[id].exclusiveGroup === group) out.push(SURFACES[id]);
    }
    return out;
}

function getScale(mw, mh, userScale) {
    return (userScale !== undefined && userScale !== null) ? userScale : 1.0;
}

function s(val, scale) {
    return Math.round(val * scale);
}

function getWidgetLauncherEntries(i18n) {
    function tr(key, fallback) {
        if (i18n && typeof i18n.t === "function") {
            let res = i18n.t(key);
            if (res && res !== key) return res;
        }
        return fallback;
    }

    return [
        {
            id: "wallpaper",
            name: tr("widgets.wallpaper.name", "Wallpaper picker"),
            description: tr("widgets.wallpaper.desc", "Browse and set desktop wallpaper"),
            icon: "preferences-desktop-wallpaper",
            fontIcon: "󰸉"
        },
        {
            id: "network",
            name: tr("widgets.network.name", "Network settings"),
            description: tr("widgets.network.desc", "Manage WiFi, Ethernet, and network connections"),
            icon: "network-wireless",
            fontIcon: "󰤨"
        },
        {
            id: "volume",
            name: tr("widgets.volume.name", "Volume & audio"),
            description: tr("widgets.volume.desc", "Manage sound devices and volume levels"),
            icon: "audio-volume-high",
            fontIcon: "󰕾"
        },
        {
            id: "calendar",
            name: tr("widgets.calendar.name", "Calendar & clock"),
            description: tr("widgets.calendar.desc", "View date, time, and schedule"),
            icon: "x-office-calendar",
            fontIcon: "󰸗"
        },
        {
            id: "music",
            name: tr("widgets.music.name", "Media player"),
            description: tr("widgets.music.desc", "Control music and media playback"),
            icon: "multimedia-audio-player",
            fontIcon: "󰝚"
        },
        {
            id: "system",
            name: tr("widgets.system.name", "System controls"),
            description: tr("widgets.system.desc", "Performance monitor, power, and quick settings"),
            icon: "preferences-system",
            fontIcon: "󰒓"
        }
    ];
}

function getLayout(name, mx, my, mw, mh, userScale, barPosition) {
    let scale = (userScale !== undefined && userScale !== null) ? userScale : 1.0;
    if (!barPosition) barPosition = "top";

    let base = {
        "network": { 
            w: 720, h: 600, comp: "network/NetworkPopup.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 52, mr: 4 }, 
                "bottom": { anchor: "bottom-right", mb: 52, mr: 4 }, 
                "left": { anchor: "bottom-left", ml: 52, mb: 4 }, 
                "right": { anchor: "bottom-right", mr: 52, mb: 4 } 
            } 
        },
        "volume": { 
            w: 410, h: 580, comp: "volume/VolumePopup.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 52, mr: 5 }, 
                "bottom": { anchor: "bottom-right", mb: 52, mr: 5 }, 
                "left": { anchor: "bottom-left", ml: 52, mb: 5 }, 
                "right": { anchor: "bottom-right", mr: 52, mb: 5 } 
            } 
        },
        "guide": { 
            w: 1200, h: 750, comp: "guide/GuidePopup.qml", draggable: true,
            pos: { 
                "top": { anchor: "center" }, 
                "bottom": { anchor: "center" }, 
                "left": { anchor: "center" }, 
                "right": { anchor: "center" } 
            } 
        },
        "wallpaper": { 
            w: "fill", h: 650, comp: "wallpaper/WallpaperPicker.qml", 
            pos: { 
                "top": { anchor: "center-left" }, 
                "bottom": { anchor: "center-left" }, 
                "left": { anchor: "center-left" }, 
                "right": { anchor: "center-left" } 
            } 
        },
        "music": { 
            w: 625, h: 565, comp: "media/MusicPopup.qml", 
            pos: { 
                "top": { anchor: "top-left", mt: 52, ml: 5 }, 
                "bottom": { anchor: "bottom-left", mb: 52, ml: 5 }, 
                "left": { anchor: "top-left", mt: 5, ml: 52 }, 
                "right": { anchor: "top-right", mt: 5, mr: 52 } 
            } 
        },
        "notifications": { 
            w: 500, h: "fill", comp: "notifications/NotificationCenter.qml", 
            pos: { 
                "top": { anchor: "left" }, 
                "bottom": { anchor: "left" }, 
                "left": { anchor: "left" }, 
                "right": { anchor: "left" } 
            } 
        },
        "system": { 
            w: 500, h: "fill", comp: "syspanel/SystemPanel.qml", 
            pos: { 
                "top": { anchor: "right" }, 
                "bottom": { anchor: "right" }, 
                "left": { anchor: "right" }, 
                "right": { anchor: "left" } 
            } 
        },
        "settings": { 
            w: 1200, h: 750, comp: "guide/GuidePopup.qml", draggable: true,
            pos: { 
                "top": { anchor: "center" }, 
                "bottom": { anchor: "center" }, 
                "left": { anchor: "center" }, 
                "right": { anchor: "center" } 
            } 
        },
        "productivity": { 
            w: 400, h: 580, comp: "productivity/ProductivityPopup.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 52, mr: 5 }, 
                "bottom": { anchor: "bottom-right", mb: 52, mr: 5 }, 
                "left": { anchor: "bottom-left", ml: 52, mb: 5 }, 
                "right": { anchor: "bottom-right", mr: 52, mb: 5 } 
            } 
        },
        "focustime": { 
            w: 900, h: 700, comp: "focustime/FocusTimePopup.qml", 
            pos: { 
                "top": { anchor: "center" }, 
                "bottom": { anchor: "center" }, 
                "left": { anchor: "center" }, 
                "right": { anchor: "center" } 
            } 
        },
        "movies": { 
            w: 1370, h: 850, comp: "movies/MovieWidget.qml", 
            pos: { 
                "top": { anchor: "bottom-center", mb: 20 }, 
                "bottom": { anchor: "bottom-center", mb: 52 }, 
                "left": { anchor: "bottom-center", mb: 20 }, 
                "right": { anchor: "bottom-center", mb: 20 } 
            } 
        },
        "stewart": { 
            w: 800, h: 650, comp: "stewart/stewart.qml", 
            pos: { 
                "top": { anchor: "center" }, 
                "bottom": { anchor: "center" }, 
                "left": { anchor: "center" }, 
                "right": { anchor: "center" } 
            } 
        },
        "moon": { 
            w: 980, h: 580, comp: "calendar/MoonPopup.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 52, mr: 5 }, 
                "bottom": { anchor: "bottom-right", mb: 52, mr: 5 }, 
                "left": { anchor: "bottom-left", ml: 52, mb: 5 }, 
                "right": { anchor: "bottom-right", mr: 52, mb: 5 } 
            } 
        },
        "lyrics": { 
            w: 720, h: 680, comp: "music/LyricsPopup.qml", 
            pos: { 
                "top": { anchor: "top-left", mt: 52, ml: 5 }, 
                "bottom": { anchor: "bottom-left", mb: 52, ml: 5 }, 
                "left": { anchor: "top-left", mt: 5, ml: 52 }, 
                "right": { anchor: "top-right", mt: 5, mr: 52 } 
            } 
        },
        "updater": { 
            w: 950, h: 850, comp: "updater/UpdaterPopup.qml", 
            pos: { 
                "top": { anchor: "center" }, 
                "bottom": { anchor: "center" }, 
                "left": { anchor: "center" }, 
                "right": { anchor: "center" } 
            } 
        },
        "battery": { 
            w: 800, h: 760, comp: "battery/BatteryPopupAlt.qml", 
            pos: { 
                "top": { anchor: "top-right", mt: 52, mr: 5 }, 
                "bottom": { anchor: "bottom-right", mb: 52, mr: 5 }, 
                "left": { anchor: "bottom-left", ml: 52, mb: 5 }, 
                "right": { anchor: "bottom-right", mr: 52, mb: 5 } 
            } 
        },
        "hidden": { 
            w: 1, h: 1, comp: "", 
            pos: { 
                "top": { anchor: "hidden" }, 
                "bottom": { anchor: "hidden" }, 
                "left": { anchor: "hidden" }, 
                "right": { anchor: "hidden" } 
            } 
        }
    };

    let p = t.pos[barPosition] || t.pos["top"];

    // uiScale is now applied by the Scaler singleton inside each popup's QML
    // (function s(val) = val * uiScale), so the PanelWindow itself stays at
    // the design size and children scale relative to it. This avoids the previous
    // double-scaling that made e.g. the calendar balloon to 1632x612 on a 1.2x
    // uiScale and overflow the 1280x1024 DP-2 monitor.
    let finalW = t.w === "fill" ? mw : t.w;
    let finalH = t.h === "fill" ? mh : t.h;

    // Clamp to fit the screen size with a margin so popups (e.g. 1360x510 calendar)
    // never overflow smaller monitors like DP-2 (1280x1024) or shorter ones like HDMI-A-1 (1366x768).
    let margin = 24;
    finalW = Math.min(finalW, mw - margin);
    finalH = Math.min(finalH, mh - margin);

    let rx = 0;
    let ry = 0;

    switch (p.anchor) {
        case "center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "top-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "top-left":
            rx = s(p.ml || 0, scale);
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-left":
            rx = s(p.ml || 0, scale);
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "top-center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = s(p.mt || 0, scale);
            break;
        case "bottom-center":
            rx = Math.floor((mw / 2) - (finalW / 2));
            ry = mh - finalH - s(p.mb || 0, scale);
            break;
        case "left":
            rx = s(p.ml || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "center-left":
            rx = s(p.ml || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "center-right":
            rx = mw - finalW - s(p.mr || 0, scale);
            ry = Math.floor((mh / 2) - (finalH / 2));
            break;
        case "fill":
            rx = 0;
            ry = 0;
            break;
        case "hidden":
            rx = -5000;
            ry = -5000;
            break;
    }

    return {
        id: t.id,
        host: t.host,
        w: finalW,
        h: finalH,
        rx: mx + rx,
        ry: my + ry,
        comp: t.comp,
        draggable: Boolean(t.draggable),
        barRelative: Boolean(t.barRelative),
        preservePosition: Boolean(t.preservePosition),
        exclusiveGroup: t.exclusiveGroup || "none"
    };
}

function getPopupLayout(mw, mh, userScale) {
    let scale = (userScale !== undefined && userScale !== null) ? userScale : 1.0;
    return {
        w: s(350, scale),
        marginTop: s(52, scale),
        marginRight: s(20, scale),
        spacing: s(12, scale),
        radius: s(14, scale),
        padding: s(12, scale)
    };
}
