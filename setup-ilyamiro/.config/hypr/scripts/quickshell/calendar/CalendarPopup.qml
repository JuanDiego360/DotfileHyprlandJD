import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import QtQuick.Window
import "../"

Item {
    id: window

    Caching { id: paths }

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        // Pass both width and height so the internal popup scale perfectly synchronizes
        // with the master window's WindowRegistry.js calculations
        currentWidth: (typeof masterWindow !== "undefined" && masterWindow.screen) ? masterWindow.screen.width : Screen.width
        currentHeight: (typeof masterWindow !== "undefined" && masterWindow.screen) ? masterWindow.screen.height : Screen.height
    }
    
    // Expose reactive scale factor for all bindings, capped to fit the screen size (preventing overflow)
    readonly property real sf: {
        let rawSf = scaler.baseScale;
        let scaleX = (scaler.currentWidth - 60) / 1450.0;
        let scaleY = (scaler.currentHeight - 100) / (window.scheduleModuleExists ? 750.0 : 510.0);
        let capScale = Math.min(scaleX, scaleY);
        return Math.min(rawSf, capScale);
    }

    // Keep helper function for backwards compatibility in pure JS blocks
    function s(val) { 
        return Math.round(val * window.sf); 
    }

    // -------------------------------------------------------------------------
    // DYNAMIC MASTER WINDOW SCALING (Fixes Window Clipping)
    // -------------------------------------------------------------------------
    property real targetMasterHeight: Math.round(600 * window.sf)
    property real targetMasterWidth: Math.round(1380 * window.sf)
    
    property bool gcalAuthRequired: false
    property int selectedDay: new Date().getDate()
    property int selectedMonth: new Date().getMonth()
    property int selectedYear: new Date().getFullYear()
    
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
            
            let mw = scaler.currentWidth;
            let scale = window.sf;
            let scale1380 = Math.round(1380 * scale);
            let s20 = Math.round(20 * scale);
            let s80 = Math.round(80 * scale);
            let newX = Math.max(s20, Math.floor((mw / 2) - (scale1380 / 2) - s80));
            console.log("CalendarPopup debug: mw=" + mw + " scale=" + scale + " scale1380=" + scale1380 + " newX=" + newX);
            masterWindow.animX = newX;
        }
    }

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // (Escape is handled by Main.qml now)
    // -------------------------------------------------------------------------
    Shortcut { 
        sequence: "Left"
        onActivated: {
            if (calHover.hovered) {
                window.setMonthOffset(window.targetMonthOffset - 1);
            } else {
                window.setWeatherView(window.targetWeatherView - 1);
            }
        }
    }

    Shortcut { 
        sequence: "Right"
        onActivated: {
            if (calHover.hovered) {
                window.setMonthOffset(window.targetMonthOffset + 1);
            } else {
                window.setWeatherView(window.targetWeatherView + 1);
            }
        }
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext1: _theme.subtext1
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay2: _theme.overlay2
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay0: _theme.overlay0
    readonly property color surface2: _theme.surface2
    readonly property color surface1: _theme.surface1
    readonly property color surface0: _theme.surface0
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color teal: _theme.teal
    readonly property color green: _theme.green
    readonly property color red: _theme.red

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/calendar"

    // -------------------------------------------------------------------------
    // TIME OF DAY DYNAMIC COLORS
    // -------------------------------------------------------------------------
    readonly property color timeColor: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12) return window.peach;      // Morning
        if (h >= 12 && h < 17) return window.sapphire;  // Afternoon
        if (h >= 17 && h < 21) return window.mauve;     // Evening
        return window.blue;                             // Night
    }

    readonly property color timeAccent: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12) return window.yellow;     // Morning Accent
        if (h >= 12 && h < 17) return window.teal;      // Afternoon Accent
        if (h >= 17 && h < 21) return window.pink;      // Evening Accent
        return window.mauve;                            // Night Accent
    }

    readonly property color textAccent: Qt.tint(window.timeAccent, Qt.alpha(window.text, 0.35))

    // -------------------------------------------------------------------------
    // STARTUP ANIMATION STATES
    // -------------------------------------------------------------------------
    property bool startupComplete: false
    property real introMain: 0
    property real introAmbient: 0
    property real introClock: 0
    property real introCalendar: 0
    property real introWeather: 0
    property real introSchedule: 0

    SequentialAnimation {
        running: true
        
        // 50ms buffer to allow the window manager to map the surface before animating
        PauseAnimation { duration: 20 }

        ParallelAnimation {
            // Base window fades and scales slightly
            NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }

            // Ambient background glows and big parallax icon fade in
            SequentialAnimation {
                PauseAnimation { duration: 150 }
                NumberAnimation { target: window; property: "introAmbient"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutSine }
            }

            // Central clock and 3D orbital pop from the center
            SequentialAnimation {
                PauseAnimation { duration: 250 }
                NumberAnimation { target: window; property: "introClock"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            }

            // Left wing (Calendar) slides in from the left
            SequentialAnimation {
                PauseAnimation { duration: 350 }
                NumberAnimation { target: window; property: "introCalendar"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }

            // Right wing (Weather) slides in from the right
            SequentialAnimation {
                PauseAnimation { duration: 400 }
                NumberAnimation { target: window; property: "introWeather"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }

            // Bottom section (Schedule) flows up smoothly
            SequentialAnimation {
                PauseAnimation { duration: 500 }
                NumberAnimation { target: window; property: "introSchedule"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutExpo }
            }
        }
        ScriptAction { script: window.startupComplete = true }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introAmbient"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introClock"; to: 0; duration: 300; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introCalendar"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introWeather"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introSchedule"; to: 0; duration: 200; easing.type: Easing.InQuart }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // -------------------------------------------------------------------------
    // STATE & TIME (WITH SECOND PULSE)
    // -------------------------------------------------------------------------
    property var currentTime: new Date()
    property real currentEpoch: currentTime.getTime() / 1000
    
    property real secondPulse: 1.0
    NumberAnimation on secondPulse { 
        id: pulseReset 
        to: 1.0; duration: 600; easing.type: Easing.OutQuint; running: false 
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            window.currentTime = new Date();
            window.secondPulse = 1.06; // Gentle pulse
            pulseReset.start();        
            
            if (window.currentTime.getHours() === 0 && window.currentTime.getMinutes() === 0 && window.currentTime.getSeconds() === 0) {
                updateCalendarGrid();
            }
        }
    }

    // -------------------------------------------------------------------------
    // WEATHER DATA & ELEGANT TRANSITIONS (3D ORBIT SPIN)
    // -------------------------------------------------------------------------
    property var weatherData: null
    property int weatherView: 0
    property color activeWeatherHex: {
        if (!window.weatherData) return window.mauve;
        if (window.weatherView === 0 && window.weatherData.current_hex) return window.weatherData.current_hex;
        if (window.weatherData.forecast && window.weatherData.forecast[window.weatherView]) return window.weatherData.forecast[window.weatherView].hex;
        return window.mauve;
    }

    // Transition Properties
    property int targetWeatherView: 0
    property real weatherContentOpacity: 1.0
    property real weatherContentOffset: 0.0
    property int weatherAnimDirection: 1
    
    // New 3D Spin Properties
    property real transitionSpin: 0.0
    property real transitionScale: 1.0

    // -------------------------------------------------------------------------
    // TEMPERATURE LOGIC 
    // -------------------------------------------------------------------------
    property real targetTemp: {
        if (!window.weatherData) return 0;
        if (window.targetWeatherView === 0 && window.weatherData.current_temp !== undefined) {
            return Number(window.weatherData.current_temp);
        }
        if (window.weatherData.forecast && window.weatherData.forecast[window.targetWeatherView]) {
            return Number(window.weatherData.forecast[window.targetWeatherView].max);
        }
        return 0;
    }
    
    property real displayedTemp: targetTemp

    Behavior on displayedTemp {
        NumberAnimation {
            id: tempAnim
            duration: 800
            easing.type: Easing.OutQuart
        }
    }

    property bool isTempAnimating: tempAnim.running
    property color tempGlowColor: {
        if (!isTempAnimating || !window.startupComplete) return window.text;
        
        // If the target is higher than the currently ticking number, we are counting up
        if (window.targetTemp > window.displayedTemp) return window.red;
        
        // If the target is lower than the currently ticking number, we are counting down
        if (window.targetTemp < window.displayedTemp) return window.blue;
        
        return window.text; 
    }

    SequentialAnimation {
        id: weatherTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 0.0; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: window; property: "weatherContentOffset"; to: Math.round(-40 * window.sf) * weatherAnimDirection; duration: 250; easing.type: Easing.InSine }
            
            // Spin the 3D orbit out and scale it down for depth
            NumberAnimation { target: window; property: "transitionSpin"; to: 180 * weatherAnimDirection; duration: 300; easing.type: Easing.InBack }
            NumberAnimation { target: window; property: "transitionScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic }
        }
        ScriptAction { 
            script: { 
                window.weatherView = window.targetWeatherView; 
                window.weatherContentOffset = Math.round(40 * window.sf) * weatherAnimDirection; // Move to opposite side while hidden
                
                // Reset the spin to the opposite side so it continues spinning into place seamlessly
                window.transitionSpin = -180 * weatherAnimDirection;
            } 
        }
        ParallelAnimation {
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 1.0; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: window; property: "weatherContentOffset"; to: 0.0; duration: 450; easing.type: Easing.OutQuart }
            
            // Snap the 3D orbit back to 0 degrees and restore full scale
            NumberAnimation { target: window; property: "transitionSpin"; to: 0.0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: window; property: "transitionScale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        }
    }

    function setWeatherView(idx) {
        if (idx < 0 || idx > 4 || !window.weatherData) return;
        if (idx === window.targetWeatherView) return; // Ignore if we are already heading there

        // If an animation is already running, gracefully interrupt it and apply the logical switch
        // before starting the new animation so the data doesn't get desynced.
        if (weatherTransitionAnim.running) {
            weatherTransitionAnim.stop();
            window.weatherView = window.targetWeatherView;
        }

        window.weatherAnimDirection = idx > window.weatherView ? 1 : -1;
        window.targetWeatherView = idx;
        weatherTransitionAnim.start();
    }

    property int activeHourIndex: {
        if (window.weatherView !== 0 || !window.weatherData || !window.weatherData.forecast || !window.weatherData.forecast[0] || !window.weatherData.forecast[0].hourly) return -1;
        
        let ch = window.currentTime.getHours();
        let hrArr = window.weatherData.forecast[0].hourly.slice(0, 8);
        let bestIdx = -1;
        let minDiff = 999;
        
        for (let i = 0; i < hrArr.length; i++) {
            let timeStr = hrArr[i].time || "00:00";
            let h = parseInt(timeStr.split(":")[0]);
            let diff = Math.abs(h - ch);
            if (diff < minDiff) {
                minDiff = diff;
                bestIdx = i;
            }
        }
        return bestIdx !== -1 ? bestIdx : 0;
    }

    Process {
        id: weatherPoller
        command: ["bash", window.scriptsDir + "/weather.sh", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { window.weatherData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }

    Timer {
        interval: 150000 
        running: true; repeat: true
        onTriggered: weatherPoller.running = true
    }

    // -------------------------------------------------------------------------
    // SCHEDULE DATA & CONDITIONAL RENDERING
    // -------------------------------------------------------------------------
    property bool scheduleModuleExists: false
    property var scheduleData: { "header": "Loading Schedule...", "link": "", "lessons": [] }

    // Dynamic offset based on whether the schedule module exists
    property real centerOffset: window.scheduleModuleExists ? Math.round(-100 * window.sf) : 0
    Behavior on centerOffset { NumberAnimation { duration: 600; easing.type: Easing.OutQuart } }

    // Check if the schedule manager script actually exists before doing anything
    Process {
        id: schedulePathChecker
        command: ["bash", "-c", "[ -f '" + window.scriptsDir + "/schedule/schedule_manager.sh' ] && echo 1 || echo 0"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "1") {
                    window.scheduleModuleExists = true;
                    schedulePoller.running = true; // Safe to start polling
                } else {
                    window.scheduleModuleExists = false;
                    // Shrinking is now automatically handled by the onTargetMasterHeightChanged watcher
                }
            }
        }
    }

    Process {
        id: schedulePoller
        command: ["bash", window.scriptsDir + "/schedule/schedule_manager.sh"]
        running: false // Handled by schedulePathChecker
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { window.scheduleData = JSON.parse(txt); } catch(e) { console.log("Schedule Parse Error:", e); }
                }
            }
        }
    }

    Timer {
        interval: 600000 
        // Only run the timer if the module actually exists
        running: window.scheduleModuleExists; repeat: true
        onTriggered: schedulePoller.running = true
    }

    // -------------------------------------------------------------------------
    // CALENDAR GRID LOGIC & TRANSITIONS
    // -------------------------------------------------------------------------
    property int monthOffset: 0
    property int targetMonthOffset: 0
    property string targetMonthName: ""
    ListModel { id: calendarModel }

    property real calendarContentOpacity: 1.0
    property real calendarContentOffset: 0.0
    property int calendarAnimDirection: 1

    SequentialAnimation {
        id: calendarTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 0.0; duration: 200; easing.type: Easing.InSine }
            NumberAnimation { target: window; property: "calendarContentOffset"; to: Math.round(-20 * window.sf) * calendarAnimDirection; duration: 200; easing.type: Easing.InSine }
        }
        ScriptAction {
            script: {
                window.monthOffset = window.targetMonthOffset;
                window.calendarContentOffset = Math.round(20 * window.sf) * calendarAnimDirection;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 1.0; duration: 350; easing.type: Easing.OutQuart }
            NumberAnimation { target: window; property: "calendarContentOffset"; to: 0.0; duration: 350; easing.type: Easing.OutQuart }
        }
    }

    function setMonthOffset(newOffset) {
        if (newOffset === window.targetMonthOffset) return;

        if (calendarTransitionAnim.running) {
            calendarTransitionAnim.stop();
            window.monthOffset = window.targetMonthOffset;
        }

        window.calendarAnimDirection = newOffset > window.targetMonthOffset ? 1 : -1;
        window.targetMonthOffset = newOffset;
        calendarTransitionAnim.start();
    }

    property var googleEvents: []

    Process {
        id: googleEventsFetcher
        command: []
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(this.text);
                    if (parsed.status === "success" && parsed.events) {
                        window.googleEvents = parsed.events;
                        window.gcalAuthRequired = false;
                    } else if (parsed.status === "error" && parsed.error_type === "unauthorized") {
                        window.gcalAuthRequired = true;
                    } else {
                        window.gcalAuthRequired = false;
                    }
                } catch(e) {
                    console.log("Error parsing google events: " + e + " | Raw text was: '" + this.text + "'");
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    console.log("googleEventsFetcher stderr: '" + this.text + "'");
                }
            }
        }
        onExited: (code, status) => {
            console.log("googleEventsFetcher exited with code: " + code + " status: " + status);
        }
    }

    Process {
        id: gcalAuthenticator
        command: [
            "/home/juandiego/.local/state/quickshell/.venv/bin/python",
            "/home/juandiego/.config/quickshell/ii/services/gCloud/gcal_sync.py",
            "auth"
        ]
        running: false
        onExited: (code, status) => {
            console.log("gcalAuthenticator exited with code: " + code + " status: " + status);
            window.fetchGoogleEvents();
        }
    }

    function fetchGoogleEvents() {
        let d = new Date(window.currentTime.getTime());
        d.setMonth(d.getMonth() + window.monthOffset);
        
        let startD = new Date(d.getFullYear(), d.getMonth() - 1, 1);
        let endD = new Date(d.getFullYear(), d.getMonth() + 2, 0);
        
        let startStr = startD.getFullYear() + "-" + (startD.getMonth() + 1).toString().padStart(2, '0') + "-" + startD.getDate().toString().padStart(2, '0');
        let endStr = endD.getFullYear() + "-" + (endD.getMonth() + 1).toString().padStart(2, '0') + "-" + endD.getDate().toString().padStart(2, '0');
        
        let newCommand = [
            "/home/juandiego/.local/state/quickshell/.venv/bin/python",
            "/home/juandiego/.config/quickshell/ii/services/gCloud/gcal_sync.py",
            "list",
            "--start", startStr,
            "--end", endStr
        ];
        
        if (googleEventsFetcher.running && JSON.stringify(googleEventsFetcher.command) === JSON.stringify(newCommand)) {
            return;
        }
        
        googleEventsFetcher.command = newCommand;
        console.log("googleEventsFetcher starting command: " + JSON.stringify(googleEventsFetcher.command));
        googleEventsFetcher.running = false;
        googleEventsFetcher.running = true;
    }

    Timer {
        id: googleEventsRefreshTimer
        interval: 900000 // Refresh every 15 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: fetchGoogleEvents()
    }

    function updateCalendarGrid() {
        let d = new Date(window.currentTime.getTime());
        d.setDate(1); 
        d.setMonth(d.getMonth() + window.monthOffset);

        let targetMonth = d.getMonth();
        let targetYear = d.getFullYear();
        
        let actualToday = new Date();
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
        let todayDate = actualToday.getDate();

        window.targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");

        let firstDay = new Date(targetYear, targetMonth, 1).getDay();
        firstDay = (firstDay === 0) ? 6 : firstDay - 1; 

        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();

        calendarModel.clear();

        for (let i = firstDay - 1; i >= 0; i--) {
            let prevD = new Date(targetYear, targetMonth - 1, daysInPrevMonth - i);
            calendarModel.append({ 
                dayNum: prevD.getDate().toString(), 
                isCurrentMonth: false, 
                isToday: false,
                month: prevD.getMonth(),
                year: prevD.getFullYear()
            });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({ 
                dayNum: i.toString(), 
                isCurrentMonth: true, 
                isToday: (isRealCurrentMonth && i === todayDate),
                month: targetMonth,
                year: targetYear
            });
        }
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            let nextD = new Date(targetYear, targetMonth + 1, i);
            calendarModel.append({ 
                dayNum: nextD.getDate().toString(), 
                isCurrentMonth: false, 
                isToday: false,
                month: nextD.getMonth(),
                year: nextD.getFullYear()
            });
        }
        
        fetchGoogleEvents();
    }

    onMonthOffsetChanged: updateCalendarGrid()

    Component.onCompleted: {
        updateCalendarGrid();
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introMain)
        opacity: introMain

        Rectangle {
            anchors.fill: parent
            radius: Math.round(20 * window.sf)
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // =======================================================
            // AMBIENT WIDGET COLOR BLOBS (Spread Out)
            // =======================================================
            Rectangle {
                width: parent.width * 0.5; height: width; radius: width / 2
                x: (parent.width * 0.75 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * Math.round(350 * window.sf)
                y: (parent.height * 0.3 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * Math.round(200 * window.sf)
                opacity: 0.025 * window.introAmbient
                color: window.activeWeatherHex
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            Rectangle {
                width: parent.width * 0.6; height: width; radius: width / 2
                x: (parent.width * 0.25 - width / 2) + Math.sin(window.globalOrbitAngle * 1.2) * Math.round(-300 * window.sf)
                y: (parent.height * 0.7 - height / 2) + Math.cos(window.globalOrbitAngle * 1.2) * Math.round(-250 * window.sf)
                opacity: 0.02 * window.introAmbient
                color: window.timeColor
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            Rectangle {
                width: parent.width * 0.45; height: width; radius: width / 2
                x: (parent.width * 0.5 - width / 2) + Math.cos(window.globalOrbitAngle * -1.8) * Math.round(400 * window.sf)
                y: (parent.height * 0.5 - height / 2) + Math.sin(window.globalOrbitAngle * -1.8) * Math.round(-350 * window.sf)
                opacity: 0.015 * window.introAmbient
                color: window.timeAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            // Big Parallax Weather Icon (Tied to Weather Transition)
            Text {
                id: parallaxWeatherIcon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: window.centerOffset
                text: {
                    if (!window.weatherData) return "";
                    if (window.weatherView === 0 && window.weatherData.current_icon) return window.weatherData.current_icon;
                    if (window.weatherData.forecast && window.weatherData.forecast[window.weatherView]) return window.weatherData.forecast[window.weatherView].icon;
                    return "";
                }
                font.family: "Iosevka Nerd Font"
                font.pixelSize: Math.round(800 * window.sf)
                color: window.activeWeatherHex
                opacity: (0.03 + (0.01 * Math.sin(window.globalOrbitAngle * 4))) * window.introAmbient * window.weatherContentOpacity
                z: 0
                Behavior on color { ColorAnimation { duration: 1500 } }
                
                property real drift: 0
                SequentialAnimation on drift {
                    loops: Animation.Infinite
                    NumberAnimation { to: Math.round(-20 * window.sf); duration: 6000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 6000; easing.type: Easing.InOutSine }
                }
                
                transform: [
                    Translate { y: parallaxWeatherIcon.drift },
                    Translate { x: window.weatherContentOffset * 2 } // Exaggerated shift for background depth
                ]
            }

            // =======================================================
            // CENTRAL HERO: THE BREATHING TIME HUB & 3D HOURLY ORBIT
            // =======================================================
            Item {
                id: centralHub
                anchors.centerIn: parent
                anchors.verticalCenterOffset: window.centerOffset
                width: Math.round(1 * window.sf); height: Math.round(1 * window.sf) 
                z: 5

                opacity: introClock
                scale: 0.85 + (0.15 * introClock)

                property real levitation: 0
                SequentialAnimation on levitation {
                    loops: Animation.Infinite
                    NumberAnimation { to: Math.round(-15 * window.sf); duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }
                }

                property real orbitBreath: 1.0
                SequentialAnimation on orbitBreath {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3500; easing.type: Easing.InOutSine }
                }

                // 3D Perspective Wobble (Pitch, Yaw, Roll)
                property real pitchBreath: 0
                SequentialAnimation on pitchBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }
                }

                property real yawBreath: 0
                SequentialAnimation on yawBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }
                }

                property real rollBreath: 0
                SequentialAnimation on rollBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }
                }
                
                transform: [
                    Translate { y: Math.round(25 * window.sf) * (1.0 - introClock) },
                    Translate { y: centralHub.levitation },
                    Rotation { axis { x: 1; y: 0; z: 0 } angle: centralHub.pitchBreath },
                    Rotation { axis { x: 0; y: 1; z: 0 } angle: centralHub.yawBreath },
                    Rotation { axis { x: 0; y: 0; z: 1 } angle: centralHub.rollBreath }
                ]

                // OPTIMIZATION: Moved scale property out of the onPaint function to prevent redrawing every frame.
                // It now draws once, and scales using the GPU.
                Canvas {
                    id: orbitCanvas
                    z: -10
                    x: Math.round(-400 * window.sf)   // Widened to prevent clipping when scaled
                    y: Math.round(-200 * window.sf)   // Heightened to prevent clipping when scaled
                    width: Math.round(800 * window.sf)
                    height: Math.round(400 * window.sf)
                    opacity: 0.25

                    scale: centralHub.orbitBreath

                    onWidthChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        var currentRx = Math.round(320 * window.sf);
                        var currentRy = Math.round(140 * window.sf);
                        for (var i = 0; i <= Math.PI * 2; i += 0.05) {
                            var xx = width/2 + Math.cos(i) * currentRx;
                            var yy = height/2 + Math.sin(i) * currentRy;
                            if (i === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);
                        }
                        ctx.strokeStyle = window.textAccent;
                        ctx.lineWidth = Math.max(1, Math.round(1.5 * window.sf));
                        ctx.setLineDash([Math.round(4 * window.sf), Math.round(10 * window.sf)]);
                        ctx.stroke();
                    }
                    Behavior on opacity { NumberAnimation { duration: 1500 } }
                }

                // Core Clock
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    z: 0 
                    scale: 0.95 + (0.05 * window.secondPulse) 
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Math.round(2 * window.sf)
                        Text {
                            text: Qt.formatTime(window.currentTime, "HH:mm")
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(84 * window.sf)
                            color: window.text
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
                        }
                        Text {
                            text: Qt.formatTime(window.currentTime, ":ss")
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: Math.round(32 * window.sf)
                            color: window.textAccent
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: Math.round(15 * window.sf)
                            opacity: window.secondPulse > 1.02 ? 1.0 : 0.6 
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
                            Behavior on color { ColorAnimation { duration: 1000 } }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(window.currentTime, "dddd, MMMM dd")
                        font.family: "JetBrains Mono"
                        font.weight: Font.Bold
                        font.pixelSize: Math.round(16 * window.sf)
                        color: window.subtext0
                        opacity: 0.9
                    }
                }

                // TRUE 3D ORBITAL HOURLY FORECAST (Tied to Spin Transition)
                Item {
                    anchors.fill: parent
                    opacity: window.weatherContentOpacity
                    
                    // Added Scale property to give a z-depth shrink effect when spinning
                    scale: window.transitionScale 
                    transform: Translate { x: window.weatherContentOffset * 1.5 }

                    Repeater {
                        id: hourRepeater
                        model: window.weatherData && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].hourly ? window.weatherData.forecast[window.weatherView].hourly.slice(0, 8) : []
                        
                        delegate: Item {
                            property int mCount: hourRepeater.count
                            property bool isToday: window.weatherView === 0
                            property bool isHighlighted: isToday && index === window.activeHourIndex
                            
                            property real rx: Math.round(320 * window.sf) * centralHub.orbitBreath
                            property real ry: Math.round(140 * window.sf) * centralHub.orbitBreath
                            
                            property int relIdx: isToday ? (index - window.activeHourIndex) : index
                            
                            property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount)))
                            
                            property real orbitOffset: isToday ? 0 : (window.globalOrbitAngle * (180 / Math.PI) * -1.5)
                            property real osc: isToday ? (Math.sin(window.globalOrbitAngle * 10 + index) * 5) : 0 
                            
                            // Integrated window.transitionSpin directly into the final angle calculation
                            property real rad: (targetAngleDeg + orbitOffset + osc + window.transitionSpin) * (Math.PI / 180)

                            x: Math.cos(rad) * rx - width/2
                            y: Math.sin(rad) * ry - height/2
                            z: Math.sin(rad) * Math.round(100 * window.sf) 
                            
                            scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad)))
                            opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2)))

                            width: Math.round(56 * window.sf); height: Math.round(95 * window.sf)
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: Math.round(28 * window.sf)
                                color: isHighlighted ? window.textAccent : (hrMa.containsMouse ? window.surface2 : window.surface0)
                                border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? window.textAccent : window.surface1)
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                ColumnLayout {
                                    anchors.centerIn: parent 
                                    spacing: Math.round(4 * window.sf)
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.time
                                        font.family: "JetBrains Mono"; font.weight: Font.Bold; font.pixelSize: Math.round(12 * window.sf)
                                        color: isHighlighted ? window.base : (hrMa.containsMouse ? window.text : window.overlay1)
                                    }
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon || (window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "")
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
                                        color: isHighlighted ? window.base : (modelData.hex || window.text)
                                        
                                        transform: Translate { y: hrMa.containsMouse ? Math.round(-3 * window.sf) : 0 }
                                        Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    }
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter; text: modelData.temp + "°"
                                        font.family: "JetBrains Mono"; font.weight: Font.Black; font.pixelSize: Math.round(14 * window.sf)
                                        color: isHighlighted ? window.base : window.text 
                                    }
                                }
                            }
                            MouseArea { id: hrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // =======================================================
            // LEFT WING: FLOATING GLASS CALENDAR
            // =======================================================
            Rectangle {
                id: calendarRect
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: Math.round(40 * window.sf)
                width: Math.round(320 * window.sf)
                height: Math.round(320 * window.sf)
                color: Qt.alpha(window.surface0, 0.2) 
                radius: Math.round(14 * window.sf)
                border.color: Qt.alpha(window.surface1, 0.4)
                border.width: 1
                z: 10 

                opacity: introCalendar
                transform: Translate { x: Math.round(-40 * window.sf) * (1.0 - introCalendar) }

                HoverHandler { id: calHover }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(12 * window.sf)
                    spacing: Math.round(6 * window.sf)

                    RowLayout {
                        Layout.fillWidth: true
                        
                        // "Return to Today" Home Button
                        Rectangle {
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: homeMa.containsMouse ? window.surface1 : "transparent"
                            opacity: window.targetMonthOffset !== 0 ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Text { anchors.centerIn: parent; text: "󰃭"; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
                            MouseArea { 
                                id: homeMa; anchors.fill: parent; hoverEnabled: window.targetMonthOffset !== 0; 
                                onClicked: if (window.targetMonthOffset !== 0) window.setMonthOffset(0) 
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: prevMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset - 1) }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: window.targetMonthName.toUpperCase()
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(16 * window.sf)
                            fontSizeMode: Text.Fit
                            minimumPixelSize: Math.round(8 * window.sf)
                            color: window.text
                            horizontalAlignment: Text.AlignHCenter
                            
                            opacity: window.calendarContentOpacity
                            transform: Translate { x: window.calendarContentOffset }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: nextMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: Math.round(16 * window.sf) }
                            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset + 1) }
                        }

                        Rectangle {
                            Layout.preferredWidth: Math.round(32 * window.sf); Layout.preferredHeight: Math.round(32 * window.sf); radius: Math.round(16 * window.sf)
                            color: diaryMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: "+"; font.family: "Iosevka Nerd Font"; color: diaryMa.containsMouse ? window.mauve : window.text; font.pixelSize: Math.round(32 * window.sf) }
                            MouseArea { 
                                id: diaryMa; anchors.fill: parent; hoverEnabled: true; 
                                onClicked: Quickshell.execDetached(["bash", window.scriptsDir + "/diary_manager.sh"]) 
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.family: "JetBrains Mono"
                                font.weight: Font.Black
                                font.pixelSize: Math.round(14 * window.sf)
                                color: window.overlay0
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: Math.round(6 * window.sf)
                        columnSpacing: Math.round(6 * window.sf)

                        opacity: window.calendarContentOpacity
                        transform: Translate { x: window.calendarContentOffset }

                        Repeater {
                            model: calendarModel
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                property bool hasEvents: {
                                    if (window.googleEvents.length === 0 || model.month === undefined || model.year === undefined || !dayNum) return false;
                                    let dayVal = parseInt(dayNum);
                                    if (isNaN(dayVal)) return false;
                                    
                                    let targetTime = new Date(model.year, model.month, dayVal).getTime();
                                    
                                    for (let i = 0; i < window.googleEvents.length; i++) {
                                        let e = window.googleEvents[i];
                                        if (!e.start || !e.end) continue;
                                        
                                        if (e.isAllDay) {
                                            let startTime = new Date(e.start + "T00:00:00").getTime();
                                            let endTime = new Date(e.end + "T00:00:00").getTime();
                                            if (targetTime >= startTime && targetTime < endTime) return true;
                                        } else {
                                            let eventStartDateStr = e.start.substring(0, 10);
                                            let eventEndDateStr = e.end.substring(0, 10);
                                            let eventStartTime = new Date(eventStartDateStr + "T00:00:00").getTime();
                                            let eventEndTime = new Date(eventEndDateStr + "T00:00:00").getTime();
                                            if (targetTime >= eventStartTime && targetTime <= eventEndTime) return true;
                                        }
                                    }
                                    return false;
                                }

                                property bool isSelected: window.selectedDay === parseInt(dayNum) && model.month === window.selectedMonth && model.year === window.selectedYear

                                color: isSelected ? Qt.alpha(window.mauve, 0.3) : (isToday ? window.textAccent : (dayMa.containsMouse ? Qt.alpha(window.surface2, 0.4) : "transparent"))
                                radius: Math.round(10 * window.sf)
                                scale: isSelected || dayMa.containsMouse ? 1.15 : 1.0
                                border.color: isSelected ? window.mauve : (isToday ? window.surface0 : (dayMa.containsMouse ? window.overlay0 : "transparent"))
                                border.width: isSelected || isToday || dayMa.containsMouse ? (isSelected ? 2 : 1) : 0
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: Math.round(4 * window.sf)
                                    text: dayNum
                                    font.family: "JetBrains Mono"
                                    font.weight: isToday ? Font.Black : Font.Bold
                                    font.pixelSize: Math.round(14 * window.sf)
                                    color: isToday ? window.base : (isCurrentMonth ? window.text : window.surface0)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                Rectangle {
                                    id: eventDot
                                    width: Math.round(7 * window.sf)
                                    height: Math.round(7 * window.sf)
                                    radius: width / 2
                                    color: isToday ? window.base : window.mauve
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: Math.round(2 * window.sf)
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: parent.hasEvents
                                }

                                MouseArea { 
                                    id: dayMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        window.selectedDay = parseInt(dayNum);
                                        window.selectedMonth = model.month;
                                        window.selectedYear = model.year;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =======================================================
            // EVENTS LIST DIRECTLY BELOW CALENDAR
            // =======================================================
            Rectangle {
                id: eventListRect
                anchors.left: parent.left
                anchors.top: calendarRect.bottom
                anchors.leftMargin: Math.round(40 * window.sf)
                anchors.topMargin: Math.round(20 * window.sf)
                width: Math.round(320 * window.sf)
                height: Math.round(180 * window.sf)
                color: Qt.alpha(window.surface0, 0.2) 
                radius: Math.round(14 * window.sf)
                border.color: Qt.alpha(window.surface1, 0.4)
                border.width: 1
                z: 10 

                opacity: introCalendar
                transform: Translate { x: Math.round(-40 * window.sf) * (1.0 - introCalendar) }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(15 * window.sf)
                    spacing: Math.round(8 * window.sf)

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Eventos - " + window.selectedDay + "/" + (window.selectedMonth + 1) + "/" + window.selectedYear
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(14 * window.sf)
                            color: window.mauve
                            Layout.fillWidth: true
                        }
                        
                        // ADD EVENT SHORTCUT BUTTON (+)
                        Rectangle {
                            width: Math.round(22 * window.sf)
                            height: Math.round(22 * window.sf)
                            radius: Math.round(6 * window.sf)
                            color: addBtnMa.containsMouse ? window.mauve : window.surface1
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "+"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: Math.round(14 * window.sf)
                                color: addBtnMa.containsMouse ? window.base : window.text
                            }
                            
                            MouseArea {
                                id: addBtnMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: titleInput.forceActiveFocus()
                            }
                        }
                    }

                    ScrollView {
                        visible: !window.gcalAuthRequired
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        ScrollBar.vertical.policy: ScrollBar.AsNeeded

                        Column {
                            width: parent.width
                            spacing: Math.round(6 * window.sf)

                            Repeater {
                                model: {
                                    let targetTime = new Date(window.selectedYear, window.selectedMonth, window.selectedDay).getTime();
                                    let matches = [];
                                    for (let i = 0; i < window.googleEvents.length; i++) {
                                        let e = window.googleEvents[i];
                                        if (!e.start || !e.end) continue;
                                        
                                        if (e.isAllDay) {
                                            let startTime = new Date(e.start + "T00:00:00").getTime();
                                            let endTime = new Date(e.end + "T00:00:00").getTime();
                                            if (targetTime >= startTime && targetTime < endTime) matches.push(e);
                                        } else {
                                            let eventStartDateStr = e.start.substring(0, 10);
                                            let eventEndDateStr = e.end.substring(0, 10);
                                            let eventStartTime = new Date(eventStartDateStr + "T00:00:00").getTime();
                                            let eventEndTime = new Date(eventEndDateStr + "T00:00:00").getTime();
                                            if (targetTime >= eventStartTime && targetTime <= eventEndTime) matches.push(e);
                                        }
                                    }
                                    return matches;
                                }

                                delegate: Rectangle {
                                    width: parent.width
                                    height: Math.round(44 * window.sf)
                                    color: window.surface0
                                    radius: Math.round(6 * window.sf)
                                    border.color: window.surface1
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Math.round(10 * window.sf)
                                        anchors.rightMargin: Math.round(10 * window.sf)
                                        spacing: Math.round(8 * window.sf)

                                        Rectangle {
                                            width: Math.round(3 * window.sf)
                                            height: parent.height - Math.round(12 * window.sf)
                                            color: window.mauve
                                            radius: Math.round(1.5 * window.sf)
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 0
                                            Text {
                                                text: modelData.summary || "Sin título"
                                                font.family: "JetBrains Mono"
                                                font.weight: Font.Bold
                                                font.pixelSize: Math.round(12 * window.sf)
                                                color: window.text
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: modelData.isAllDay ? "Todo el día" : (function() {
                                                    let startPart = modelData.start.split("T");
                                                    let endPart = modelData.end.split("T");
                                                    let sTime = startPart.length > 1 ? startPart[1].substring(0, 5) : "";
                                                    let eTime = endPart.length > 1 ? endPart[1].substring(0, 5) : "";
                                                    return sTime + " - " + eTime;
                                                })()
                                                font.family: "JetBrains Mono"
                                                font.pixelSize: Math.round(10 * window.sf)
                                                color: window.overlay1
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "No hay eventos"
                                font.family: "JetBrains Mono"
                                font.italic: true
                                font.pixelSize: Math.round(12 * window.sf)
                                color: window.overlay0
                                visible: {
                                    let targetTime = new Date(window.selectedYear, window.selectedMonth, window.selectedDay).getTime();
                                    let count = 0;
                                    for (let i = 0; i < window.googleEvents.length; i++) {
                                        let e = window.googleEvents[i];
                                        if (!e.start || !e.end) continue;
                                        if (e.isAllDay) {
                                            let startTime = new Date(e.start + "T00:00:00").getTime();
                                            let endTime = new Date(e.end + "T00:00:00").getTime();
                                            if (targetTime >= startTime && targetTime < endTime) count++;
                                        } else {
                                            let eventStartDateStr = e.start.substring(0, 10);
                                            let eventEndDateStr = e.end.substring(0, 10);
                                            let eventStartTime = new Date(eventStartDateStr + "T00:00:00").getTime();
                                            let eventEndTime = new Date(eventEndDateStr + "T00:00:00").getTime();
                                            if (targetTime >= eventStartTime && targetTime <= eventEndTime) count++;
                                        }
                                    }
                                    return count === 0;
                                }
                            }
                        }

                        // Warning Block
                        ColumnLayout {
                            visible: window.gcalAuthRequired
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Math.round(15 * window.sf)
                            
                            Text {
                                text: "Falta autenticar Google Calendar"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: Math.round(12 * window.sf)
                                color: window.red
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }
                            
                            // Button
                            Rectangle {
                                id: authBtn
                                Layout.alignment: Qt.AlignHCenter
                                width: Math.round(130 * window.sf)
                                height: Math.round(30 * window.sf)
                                radius: Math.round(6 * window.sf)
                                color: authBtnMa.containsMouse ? window.mauve : window.surface1
                                border.color: authBtnMa.containsMouse ? window.mauve : window.surface2
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Autenticar"
                                    font.family: "JetBrains Mono"
                                    font.weight: Font.Bold
                                    font.pixelSize: Math.round(12 * window.sf)
                                    color: authBtnMa.containsMouse ? window.base : window.text
                                }
                                
                                MouseArea {
                                    id: authBtnMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        gcalAuthenticator.running = false;
                                        gcalAuthenticator.running = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // =======================================================
            // RIGHT WING: ORGANIC FLOATING WEATHER STATS
            // =======================================================
            Item {
                id: weatherRect
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Math.round(40 * window.sf)
                width: Math.round(320 * window.sf)
                height: Math.round(320 * window.sf)
                z: 10 

                opacity: introWeather
                transform: Translate { x: Math.round(40 * window.sf) * (1.0 - introWeather) }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Math.round(20 * window.sf)

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        spacing: Math.round(20 * window.sf)
                        
                        MouseArea { 
                            id: wPrevMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView - 1) 
                            
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: Math.round(-3 * window.sf); duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
                                color: wPrevMa.containsMouse ? window.textAccent : window.overlay1
                                transform: Translate { x: wPrevMa.containsMouse ? Math.round(-5 * window.sf) : wPrevMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                        
                        Text {
                            Layout.fillWidth: true 
                            horizontalAlignment: Text.AlignHCenter 
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].day_full.toUpperCase() : "LOADING..."
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(16 * window.sf)
                            fontSizeMode: Text.Fit
                            minimumPixelSize: Math.round(8 * window.sf)
                            color: window.text
                        }
                        
                        MouseArea { 
                            id: wNextMa; Layout.preferredWidth: Math.round(30 * window.sf); Layout.preferredHeight: Math.round(30 * window.sf); hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView + 1)
                            
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: Math.round(3 * window.sf); duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: Math.round(18 * window.sf)
                                color: wNextMa.containsMouse ? window.textAccent : window.overlay1
                                transform: Translate { x: wNextMa.containsMouse ? Math.round(5 * window.sf) : wNextMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight 
                        spacing: Math.round(-5 * window.sf)
                        
                        // BIG TEMPERATURE TEXT - Anchored so it doesn't slide with the wrapper
                        Text {
                            Layout.alignment: Qt.AlignRight 
                            text: Math.round(window.displayedTemp) + "°"
                            font.family: "JetBrains Mono"
                            font.weight: Font.Black
                            font.pixelSize: Math.round(84 * window.sf)
                            color: window.tempGlowColor
                            style: Text.Outline; 
                            styleColor: window.isTempAnimating ? Qt.alpha(window.tempGlowColor, 0.5) : Qt.alpha(window.crust, 0.4)
                            
                            Behavior on color { ColorAnimation { duration: 300 } }
                            Behavior on styleColor { ColorAnimation { duration: 300 } }
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignRight
                            Layout.maximumWidth: Math.round(320 * window.sf)
                            horizontalAlignment: Text.AlignRight
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].desc : ""
                            font.family: "JetBrains Mono"
                            font.weight: Font.Bold
                            font.pixelSize: Math.round(16 * window.sf)
                            wrapMode: Text.WordWrap
                            color: window.textAccent
                            Behavior on color { ColorAnimation { duration: 1000 } }
                            
                            opacity: window.weatherContentOpacity
                            transform: Translate { x: window.weatherContentOffset }
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    // FIX: Replaced explicit widths and manual vertical anchors with flexible ColumnLayout containers
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter 
                        spacing: Math.round(8 * window.sf)

                        Repeater {
                            model: 4

                            Item {
                                id: gaugeWrapper
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.round(100 * window.sf) // Give wrapper bounds that can expand safely
                                
                                scale: gaugeMa.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                property var forecast: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? window.weatherData.forecast[window.targetWeatherView] : null

                                property string gaugeIcon: index === 0 ? "" : index === 1 ? "" : index === 2 ? "" : ""
                                property string gaugeLbl: index === 0 ? "WIND" : index === 1 ? "HUMID" : index === 2 ? "RAIN" : "FEELS"

                                property string gaugeVal: forecast ? (
                                    index === 0 ? forecast.wind + "m/s" :
                                    index === 1 ? forecast.humidity + "%" :
                                    index === 2 ? forecast.pop + "%" :
                                    forecast.feels_like + "°"
                                ) : ""

                                property real gaugeFill: forecast ? (
                                    index === 0 ? Math.min(1.0, forecast.wind / 25.0) :
                                    index === 1 ? forecast.humidity / 100.0 :
                                    index === 2 ? forecast.pop / 100.0 :
                                    Math.max(0.0, Math.min(1.0, (forecast.feels_like + 15) / 55.0))
                                ) : 0.0
                                
                                // FIX: Use ColumnLayout to enforce perfect relative positioning instead of absolute anchors
                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: Math.round(6 * window.sf)
                                    
                                    Item {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.preferredWidth: Math.round(60 * window.sf)
                                        Layout.preferredHeight: Math.round(60 * window.sf)
                                        
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            color: window.textAccent
                                            opacity: gaugeMa.containsMouse ? 0.3 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }

                                        Canvas {
                                            id: gaugeCanvas
                                            anchors.fill: parent
                                            rotation: -90 
                                            
                                            property real animProgress: gaugeWrapper.gaugeFill
                                            
                                            Behavior on animProgress {
                                                NumberAnimation { duration: 1000; easing.type: Easing.OutExpo }
                                            }
                                            
                                            onAnimProgressChanged: requestPaint()
                                            onWidthChanged: requestPaint()
                                            Component.onCompleted: requestPaint()
                                            
                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);
                                                var r = width / 2;
                                                
                                                ctx.beginPath();
                                                ctx.arc(r, r, r - Math.round(4 * window.sf), 0, 2 * Math.PI);
                                                ctx.strokeStyle = Qt.alpha(window.text, 0.1);
                                                ctx.lineWidth = Math.round(3 * window.sf);
                                                ctx.stroke();
                                                
                                                if (animProgress > 0) {
                                                    ctx.beginPath();
                                                    ctx.arc(r, r, r - Math.round(4 * window.sf), 0, animProgress * 2 * Math.PI);
                                                    var grad = ctx.createLinearGradient(0, 0, width, height);
                                                    grad.addColorStop(0, window.timeAccent);
                                                    grad.addColorStop(1, window.sapphire);
                                                    ctx.strokeStyle = grad;
                                                    ctx.lineWidth = Math.round(4 * window.sf);
                                                    ctx.lineCap = "round";
                                                    ctx.stroke();
                                                }
                                            }
                                        }
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: gaugeWrapper.gaugeVal
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Black
                                            font.pixelSize: Math.round(12 * window.sf) // Slightly reduced to guarantee fit inside circle
                                            color: window.text
                                        }
                                    }
                                    
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.fillWidth: true
                                        spacing: Math.round(4 * window.sf)
                                        
                                        Text { 
                                            text: gaugeWrapper.gaugeIcon
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: Math.round(12 * window.sf)
                                            color: gaugeMa.containsMouse ? window.textAccent : window.overlay0
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                        Text { 
                                            text: gaugeWrapper.gaugeLbl
                                            Layout.fillWidth: true
                                            font.family: "JetBrains Mono"
                                            font.weight: Font.Bold
                                            font.pixelSize: Math.round(11 * window.sf)
                                            fontSizeMode: Text.Fit
                                            minimumPixelSize: Math.round(6 * window.sf)
                                            color: window.overlay0 
                                        }
                                    }
                                }
                                
                                MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }

            // =======================================================
            // EVENT CREATOR FORM DIRECTLY BELOW WEATHER
            // =======================================================
            Rectangle {
                id: eventCreatorRect
                anchors.right: parent.right
                anchors.top: weatherRect.bottom
                anchors.rightMargin: Math.round(40 * window.sf)
                anchors.topMargin: Math.round(20 * window.sf)
                width: Math.round(320 * window.sf)
                height: Math.round(180 * window.sf)
                color: Qt.alpha(window.surface0, 0.2) 
                radius: Math.round(14 * window.sf)
                border.color: Qt.alpha(window.surface1, 0.4)
                border.width: 1
                z: 10 

                opacity: introWeather
                transform: Translate { x: Math.round(40 * window.sf) * (1.0 - introWeather) }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Math.round(15 * window.sf)
                    spacing: Math.round(8 * window.sf)

                    Text {
                        text: "Añadir Evento"
                        font.family: "JetBrains Mono"
                        font.weight: Font.Black
                        font.pixelSize: Math.round(14 * window.sf)
                        color: window.mauve
                    }

                    // Title input
                    Rectangle {
                        Layout.fillWidth: true
                        height: Math.round(32 * window.sf)
                        color: window.surface0
                        radius: Math.round(6 * window.sf)
                        border.color: titleInput.activeFocus ? window.mauve : window.surface1
                        border.width: 1

                        TextField {
                            id: titleInput
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(8 * window.sf)
                            anchors.rightMargin: Math.round(8 * window.sf)
                            background: Item {}
                            color: window.text
                            font.family: "JetBrains Mono"
                            font.pixelSize: Math.round(12 * window.sf)
                            placeholderText: "Título del evento"
                            placeholderTextColor: window.overlay0
                            verticalAlignment: TextInput.AlignVCenter
                        }
                    }

                    RowLayout {
                        spacing: Math.round(8 * window.sf)

                        // Start time input
                        Rectangle {
                            Layout.fillWidth: true
                            height: Math.round(32 * window.sf)
                            color: window.surface0
                            radius: Math.round(6 * window.sf)
                            border.color: startTimeInput.activeFocus ? window.mauve : window.surface1
                            border.width: 1

                            TextField {
                                id: startTimeInput
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(6 * window.sf)
                                anchors.rightMargin: Math.round(6 * window.sf)
                                background: Item {}
                                color: window.text
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(12 * window.sf)
                                text: "09:00"
                                placeholderText: "09:00"
                                placeholderTextColor: window.overlay0
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                            }
                        }

                        // End time input
                        Rectangle {
                            Layout.fillWidth: true
                            height: Math.round(32 * window.sf)
                            color: window.surface0
                            radius: Math.round(6 * window.sf)
                            border.color: endTimeInput.activeFocus ? window.mauve : window.surface1
                            border.width: 1

                            TextField {
                                id: endTimeInput
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(6 * window.sf)
                                anchors.rightMargin: Math.round(6 * window.sf)
                                background: Item {}
                                color: window.text
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(12 * window.sf)
                                text: "10:00"
                                placeholderText: "10:00"
                                placeholderTextColor: window.overlay0
                                verticalAlignment: TextInput.AlignVCenter
                                horizontalAlignment: TextInput.AlignHCenter
                            }
                        }
                    }

                    RowLayout {
                        spacing: Math.round(8 * window.sf)

                        // Description input
                        Rectangle {
                            Layout.fillWidth: true
                            height: Math.round(32 * window.sf)
                            color: window.surface0
                            radius: Math.round(6 * window.sf)
                            border.color: descInput.activeFocus ? window.mauve : window.surface1
                            border.width: 1

                            TextField {
                                id: descInput
                                anchors.fill: parent
                                anchors.leftMargin: Math.round(8 * window.sf)
                                anchors.rightMargin: Math.round(8 * window.sf)
                                background: Item {}
                                color: window.text
                                font.family: "JetBrains Mono"
                                font.pixelSize: Math.round(12 * window.sf)
                                placeholderText: "Descripción (opcional)"
                                placeholderTextColor: window.overlay0
                                verticalAlignment: TextInput.AlignVCenter
                            }
                        }

                        // Save button
                        Rectangle {
                            Layout.preferredWidth: Math.round(90 * window.sf)
                            height: Math.round(32 * window.sf)
                            color: saveMa.containsMouse ? window.mauve : window.surface2
                            radius: Math.round(6 * window.sf)
                            border.color: window.surface1
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: "Guardar"
                                font.family: "JetBrains Mono"
                                font.weight: Font.Bold
                                font.pixelSize: Math.round(12 * window.sf)
                                color: saveMa.containsMouse ? window.base : window.text
                            }

                            MouseArea {
                                id: saveMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (titleInput.text.trim() === "") return;
                                    
                                    let padMonth = (window.selectedMonth + 1).toString().padStart(2, '0');
                                    let padDay = window.selectedDay.toString().padStart(2, '0');
                                    let dateStr = window.selectedYear + "-" + padMonth + "-" + padDay;
                                    
                                    let startISO = dateStr + "T" + startTimeInput.text.trim() + ":00-05:00";
                                    let endISO = dateStr + "T" + endTimeInput.text.trim() + ":00-05:00";
                                    
                                    eventCreatorProc.command = [
                                        "/home/juandiego/.local/state/quickshell/.venv/bin/python",
                                        "/home/juandiego/.config/quickshell/ii/services/gCloud/gcal_sync.py",
                                        "create",
                                        "--summary", titleInput.text.trim(),
                                        "--start", startISO,
                                        "--end", endISO,
                                        "--description", descInput.text.trim()
                                    ];
                                    eventCreatorProc.running = false;
                                    eventCreatorProc.running = true;
                                    
                                    titleInput.text = "";
                                    descInput.text = "";
                                    startTimeInput.text = "09:00";
                                    endTimeInput.text = "10:00";
                                }
                            }
                        }
                    }

                    Text {
                        id: statusText
                        font.family: "JetBrains Mono"
                        font.pixelSize: Math.round(11 * window.sf)
                        color: window.green
                        text: ""
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Process {
                id: eventCreatorProc
                command: []
                running: false
                stdout: StdioCollector {
                    onStreamFinished: {
                        try {
                            let parsed = JSON.parse(this.text);
                            if (parsed.status === "success") {
                                statusText.color = window.green;
                                statusText.text = "¡Evento guardado con éxito!";
                                window.fetchGoogleEvents();
                            } else {
                                statusText.color = window.red;
                                statusText.text = "Error: " + parsed.message;
                            }
                        } catch(e) {
                            statusText.color = window.red;
                            statusText.text = "Error al procesar respuesta";
                        }
                        statusTimer.restart();
                    }
                }
            }

            Timer {
                id: statusTimer
                interval: 4000
                onTriggered: statusText.text = ""
            }
        }
    }
}
