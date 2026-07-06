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

    // --- Responsive Scaling Logic ---
    Scaler {
        id: scaler
        currentWidth: Screen.width
        currentHeight: Screen.height
    }

    readonly property real sf: scaler.baseScale
    function s(val) { 
        return Math.round(val * window.sf); 
    }

    property real targetMasterHeight: Math.round(580 * window.sf)
    property real targetMasterWidth: Math.round(400 * window.sf)

    property var notifModel: null
    property var liveNotifs: null
    property real layoutWidth: 400
    property real layoutHeight: 580

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
    readonly property color green: _theme.green || "#a6e3a1"
    readonly property color red: _theme.red

    property real introMain: 0
    NumberAnimation on introMain {
        from: 0; to: 1.0; duration: 400; easing.type: Easing.OutExpo
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // --- POMODORO TIMER STATE ---
    property int focusTimeSeconds: 1500
    property int timeLeft: 1500
    property bool isTimerRunning: false

    Process {
        id: timerStateRunner
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/timer_helper.py", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        window.timeLeft = data.timeLeft;
                        window.isTimerRunning = data.running;
                        window.focusTimeSeconds = data.focusTimeSeconds;
                    } catch(e) {
                        console.log("Error parsing timer state: ", e);
                    }
                }
            }
        }
    }

    Timer {
        id: statePoller
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            timerStateRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/timer_helper.py", "get"];
            timerStateRunner.running = false;
            timerStateRunner.running = true;
        }
    }

    function formatTime(totalSeconds) {
        let m = Math.floor(totalSeconds / 60);
        let s = totalSeconds % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    function saveTimerState(tLeft, isRun, fTime) {
        timerStateRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/timer_helper.py", "set", tLeft.toString(), isRun.toString(), fTime.toString()];
        timerStateRunner.running = false;
        timerStateRunner.running = true;
    }

    function startTimer() { saveTimerState(window.timeLeft, true, window.focusTimeSeconds); }
    function pauseTimer() { saveTimerState(window.timeLeft, false, window.focusTimeSeconds); }
    function resetTimer() { saveTimerState(window.focusTimeSeconds, false, window.focusTimeSeconds); }
    function setPreset(minutes) { saveTimerState(minutes * 60, false, minutes * 60); }

    // --- TODO LIST STATE ---
    property var todoList: []

    Process {
        id: todoRunner
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/todo_helper.py", "list"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        window.todoList = JSON.parse(txt);
                    } catch(e) {
                        console.log("Error parsing todo list: ", e);
                    }
                }
            }
        }
    }

    function refreshTodos() {
        todoRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/todo_helper.py", "list"];
        todoRunner.running = false;
        todoRunner.running = true;
    }

    function addTodo(taskText) {
        if (taskText.trim() === "") return;
        todoRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/todo_helper.py", "add", taskText];
        todoRunner.running = false;
        todoRunner.running = true;
    }

    function toggleTodo(idx) {
        todoRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/todo_helper.py", "toggle", idx.toString()];
        todoRunner.running = false;
        todoRunner.running = true;
    }

    function deleteTodo(idx) {
        todoRunner.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/productivity/todo_helper.py", "delete", idx.toString()];
        todoRunner.running = false;
        todoRunner.running = true;
    }

    // Get count of completed tasks
    readonly property int completedTasksCount: {
        let count = 0;
        for (let i = 0; i < todoList.length; i++) {
            if (todoList[i].done) count++;
        }
        return count;
    }

    Component.onCompleted: {
        refreshTodos();
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
            x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * window.s(60)
            y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * window.s(40)
            opacity: 0.08
            color: window.mauve
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.s(18)
            spacing: window.s(12)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: window.s(10)
                Text {
                    text: "󰄉"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: window.s(24)
                    color: window.mauve
                }
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Productividad"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(15)
                        font.weight: Font.Black
                        color: window.text
                    }
                    Text {
                        text: "Enfoque Pomodoro y pendientes"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(10)
                        font.weight: Font.Bold
                        color: window.subtext0
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true; height: 1
                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.4)
            }

            // SECTION 1: Focus Timer Card
            Rectangle {
                Layout.fillWidth: true
                height: window.s(140)
                color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4)
                radius: window.s(12)
                border.color: Qt.rgba(window.surface2.r, window.surface2.g, window.surface2.b, 0.4)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: window.s(12)
                    spacing: window.s(8)

                    // Row 1: Header Status
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: window.isTimerRunning ? "Modo Enfoque Activo" : "Temporizador listo"
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(11)
                            font.weight: Font.Bold
                            color: window.isTimerRunning ? window.green : window.subtext0
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "Sesión"
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(10)
                            color: window.subtext0
                        }
                    }

                    // Row 2: Huge Time Display & Controls
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: window.s(15)

                        Text {
                            text: window.formatTime(window.timeLeft)
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(36)
                            font.weight: Font.Black
                            color: window.text
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        // Controls
                        Row {
                            spacing: window.s(8)
                            Layout.alignment: Qt.AlignVCenter

                            // Play/Pause button
                            Rectangle {
                                width: window.s(36); height: width; radius: width/2
                                color: window.isTimerRunning ? window.yellow : window.green
                                Text {
                                    anchors.centerIn: parent
                                    text: window.isTimerRunning ? "󰏤" : "󰐊"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(18)
                                    color: window.crust
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (window.isTimerRunning) window.pauseTimer();
                                        else window.startTimer();
                                    }
                                }
                            }

                            // Reset button
                            Rectangle {
                                width: window.s(36); height: width; radius: width/2
                                color: window.surface2
                                Text {
                                    anchors.centerIn: parent
                                    text: "󰜉"
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: window.s(18)
                                    color: window.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: window.resetTimer()
                                }
                            }
                        }
                    }

                    // Row 3: Adjustments & Presets
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: window.s(8)
                        enabled: !window.isTimerRunning
                        opacity: window.isTimerRunning ? 0.35 : 1.0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Text {
                            text: "Ajustar:"
                            font.family: "JetBrains Mono"
                            font.pixelSize: window.s(10)
                            color: window.subtext0
                        }

                        Row {
                            spacing: window.s(4)
                            
                            // Minus button
                            Rectangle {
                                width: window.s(18); height: window.s(18)
                                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6)
                                radius: window.s(4)
                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(10)
                                    font.weight: Font.Bold
                                    color: window.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        let currentMins = Math.round(window.focusTimeSeconds / 60);
                                        if (currentMins > 1) {
                                            window.setPreset(currentMins - 1);
                                        }
                                    }
                                }
                            }
                            
                            // Current custom duration value
                            Rectangle {
                                width: window.s(36); height: window.s(18)
                                color: Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.2)
                                radius: window.s(4)
                                border.color: window.mauve
                                border.width: 1
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(window.focusTimeSeconds / 60) + "m"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(9)
                                    font.weight: Font.Black
                                    color: window.mauve
                                }
                            }

                            // Plus button
                            Rectangle {
                                width: window.s(18); height: window.s(18)
                                color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6)
                                radius: window.s(4)
                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: window.s(10)
                                    font.weight: Font.Bold
                                    color: window.text
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        let currentMins = Math.round(window.focusTimeSeconds / 60);
                                        if (currentMins < 300) {
                                            window.setPreset(currentMins + 1);
                                        }
                                    }
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Predefined presets
                        Row {
                            spacing: window.s(4)
                            Repeater {
                                model: [15, 25, 45]
                                delegate: Rectangle {
                                    width: window.s(30); height: window.s(18)
                                    color: (Math.round(window.focusTimeSeconds / 60) === modelData) ? Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, 0.4) : Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.6)
                                    radius: window.s(4)
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "m"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: window.s(9)
                                        font.weight: Font.Bold
                                        color: window.text
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: window.setPreset(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Progress bar track
                    Rectangle {
                        id: progressTrack
                        Layout.fillWidth: true
                        height: window.s(6)
                        color: window.surface1
                        radius: height/2

                        Rectangle {
                            height: parent.height
                            radius: height/2
                            color: window.mauve
                            width: Math.max(0, parent.width * (window.timeLeft / window.focusTimeSeconds))
                            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }

            // SECTION 2: Todo List Card
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: window.s(8)

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Tareas Pendientes"
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(13)
                        font.weight: Font.Black
                        color: window.text
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: window.completedTasksCount + "/" + window.todoList.length
                        font.family: "JetBrains Mono"
                        font.pixelSize: window.s(11)
                        font.weight: Font.Bold
                        color: window.mauve
                    }
                }

                // Add Task Field
                TextField {
                    id: todoInput
                    Layout.fillWidth: true
                    height: window.s(36)
                    placeholderText: "Añadir tarea y presionar Enter..."
                    placeholderTextColor: window.subtext0
                    color: window.text
                    font.family: "JetBrains Mono"
                    font.pixelSize: window.s(11)
                    leftPadding: window.s(12)
                    
                    background: Rectangle {
                        color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.4)
                        radius: window.s(8)
                        border.color: todoInput.activeFocus ? window.mauve : window.surface2
                        border.width: 1
                    }
                    onAccepted: {
                        if (text.trim() !== "") {
                            window.addTodo(text);
                            text = "";
                        }
                    }
                }

                // List of Tasks
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        width: parent.width
                        spacing: window.s(6)

                        Repeater {
                            model: window.todoList
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                height: window.s(38)
                                color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.2)
                                radius: window.s(6)
                                border.color: Qt.rgba(window.surface1.r, window.surface1.g, window.surface1.b, 0.2)
                                border.width: 1
                                opacity: modelData.done ? 0.6 : 1.0

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: window.s(10)
                                    anchors.rightMargin: window.s(10)
                                    spacing: window.s(8)

                                    // Checkbox
                                    Rectangle {
                                        width: window.s(16); height: width; radius: window.s(4)
                                        color: modelData.done ? window.green : "transparent"
                                        border.color: modelData.done ? window.green : window.subtext0
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: window.s(10)
                                            font.weight: Font.Bold
                                            color: window.crust
                                            visible: modelData.done
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: window.toggleTodo(index)
                                        }
                                    }

                                    // Task Text
                                    Text {
                                        text: modelData.text
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: window.s(11)
                                        font.weight: Font.Bold
                                        color: window.text
                                        font.strikeout: modelData.done
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    // Delete Button
                                    Rectangle {
                                        width: window.s(22); height: width; radius: window.s(4)
                                        color: "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: window.s(13)
                                            color: window.red
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: window.deleteTodo(index)
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
