import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "../"

Item {
    id: root
    clip: true

    // Scaler fallback
    function s(val) {
        if (typeof parent !== "undefined" && parent && typeof parent.s === "function") {
            return parent.s(val);
        }
        return val;
    }

    // Theme Colors
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay2: _theme.overlay2
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink

    // Optional musicData binding passed from parent MusicPopup
    property var musicData: null

    // MPRIS Active Player Detection
    readonly property MprisPlayer activePlayer: {
        let players = Mpris.players.values;
        let playing = players.find(p => p.isPlaying);
        if (playing) return playing;
        let controllable = players.find(p => p.canControl);
        if (controllable) return controllable;
        return players.length > 0 ? players[0] : null;
    }

    readonly property bool isMediaActive: {
        if (activePlayer && activePlayer.playbackState !== MprisPlaybackState.Stopped && (activePlayer.trackTitle || "") !== "") {
            return true;
        }
        if (musicData && musicData.status && musicData.status !== "Stopped" && (musicData.title || "") !== "" && musicData.title !== "Not Playing") {
            return true;
        }
        return false;
    }

    readonly property string rawTrackTitle: activePlayer ? (activePlayer.trackTitle || "") : (musicData ? (musicData.title || "") : "")
    readonly property string rawTrackArtist: activePlayer ? (activePlayer.trackArtist || "") : (musicData ? (musicData.artist || "") : "")
    readonly property string currentTrackKey: isMediaActive ? (rawTrackArtist.trim() + " - " + rawTrackTitle.trim()) : ""

    property real currentPosition: 0
    property var lyrics: []
    property bool hasLyrics: false
    property bool loading: false
    property string activeFetchKey: ""
    property string lastFetchedKey: ""
    property real activeItemCenterY: 0
    property string lyricsSourceInfo: ""

    // In-memory lyrics cache
    property var localCache: ({})
    function getMemCache() {
        try {
            if (typeof globalThis !== "undefined" && globalThis) {
                if (!globalThis._lyricsCache) globalThis._lyricsCache = {};
                return globalThis._lyricsCache;
            }
        } catch(e) {}
        if (!root.localCache) root.localCache = {};
        return root.localCache;
    }

    // High frequency position tracker
    Timer {
        id: positionTimer
        interval: 35
        repeat: true
        running: root.visible && root.isMediaActive && (root.activePlayer ? root.activePlayer.isPlaying : (root.musicData ? root.musicData.status === "Playing" : false))
        onTriggered: {
            if (root.activePlayer) {
                if (typeof root.activePlayer.positionChanged === "function") {
                    root.activePlayer.positionChanged();
                }
                root.currentPosition = root.activePlayer.position;
            } else if (root.musicData && root.musicData.positionStr) {
                let parts = root.musicData.positionStr.split(":").map(Number);
                if (parts.length === 2) {
                    root.currentPosition = parts[0] * 60 + parts[1];
                }
            }
        }
    }

    // Track state change triggers search
    onCurrentTrackKeyChanged: triggerSearch()
    Component.onCompleted: triggerSearch()

    function triggerSearch() {
        if (!isMediaActive || currentTrackKey === "" || currentTrackKey === " - Not Playing") {
            lastFetchedKey = "";
            activeFetchKey = "";
            lyrics = [];
            hasLyrics = false;
            loading = false;
            activeItemCenterY = 0;
            lyricsSourceInfo = "";
            return;
        }

        if (currentTrackKey === lastFetchedKey && lyrics.length > 0) {
            return;
        }

        lastFetchedKey = currentTrackKey;
        activeFetchKey = currentTrackKey;
        activeItemCenterY = 0;
        checkCacheAndFetch(currentTrackKey);
    }

    function checkCacheAndFetch(key) {
        let mem = getMemCache();
        if (mem && mem[key] && Array.isArray(mem[key]) && mem[key].length > 0) {
            applyLyrics(mem[key], key, "Caché", false);
            return;
        }

        root.loading = true;
        cacheReadProcess.targetKey = key;
        cacheReadProcess.running = false;
        cacheReadProcess.running = true;
    }

    function cleanString(str) {
        if (!str) return "";
        return str.replace(/\s*[\(\[](?:feat\.|ft\.|official|video|audio|remastered|deluxe|version|lyric).*?[\)\]]/gi, "").trim();
    }

    function getPlayerDurationSec() {
        if (root.activePlayer && root.activePlayer.length) {
            let len = root.activePlayer.length;
            if (len > 10000) return len / 1000000.0;
            return len;
        }
        return 0;
    }

    // Parsing routines: LRC, YRC, Enhanced LRC
    function parseLrc(lrcText) {
        if (!lrcText || typeof lrcText !== "string") return [];
        let lines = lrcText.split("\n");
        let result = [];
        let timeRegex = /\[(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)\]/g;

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;

            let times = [];
            let match;
            timeRegex.lastIndex = 0;

            while ((match = timeRegex.exec(line)) !== null) {
                times.push(parseFloat(match[1]) * 60 + parseFloat(match[2]));
            }

            if (times.length > 0) {
                let text = line.replace(/\[\d{1,2}:\d{1,2}(?:\.\d{1,3})?\]/g, "").trim();
                for (let j = 0; j < times.length; j++) {
                    result.push({ time: times[j], text: text, words: [] });
                }
            }
        }

        result.sort((a, b) => a.time - b.time);
        return result;
    }

    function parseYrc(yrcText) {
        if (!yrcText || typeof yrcText !== "string") return null;
        let lines = yrcText.split("\n");
        let result = [];
        let hasAnyWord = false;

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;

            let lineTime = -1;
            let content = "";

            let msMatch = line.match(/^\[(\d+),(\d+)\](.*)$/);
            if (msMatch) {
                lineTime = parseFloat(msMatch[1]) / 1000.0;
                content = msMatch[3];
            } else {
                let lrcMatch = line.match(/^\[(\d{1,2}):(\d{1,2}(?:\.\d{1,3})?)\](.*)$/);
                if (lrcMatch) {
                    lineTime = parseFloat(lrcMatch[1]) * 60 + parseFloat(lrcMatch[2]);
                    content = lrcMatch[3];
                }
            }

            if (lineTime < 0) continue;

            let words = [];
            let wordRegex = /\((\d+),(\d+)(?:,\d+)?\)([^\(\[\n\r]*)/g;
            let match;

            while ((match = wordRegex.exec(content)) !== null) {
                let rawStart = parseFloat(match[1]) / 1000.0;
                let dur = parseFloat(match[2]) / 1000.0;
                let wStart = (rawStart < lineTime) ? (lineTime + rawStart) : rawStart;
                let wEnd = wStart + (dur > 0 ? dur : 0.25);
                let wText = match[3];
                if (wText !== "") {
                    words.push({ time: wStart, endTime: wEnd, text: wText });
                }
            }

            let cleanLine = content.replace(/\(\d+,\d+(?:,\d+)?\)/g, "").replace(/<\d+,\d+>/g, "").trim();
            if (cleanLine === "" && words.length > 0) {
                cleanLine = words.map(w => w.text).join("").trim();
            }

            if (words.length > 0) {
                hasAnyWord = true;
                result.push({ time: lineTime, text: cleanLine, words: words });
            } else if (cleanLine !== "") {
                result.push({ time: lineTime, text: cleanLine, words: [] });
            }
        }

        if (hasAnyWord && result.length > 0) {
            result.sort((a, b) => a.time - b.time);
            return result;
        }
        return null;
    }

    function applyLyrics(parsedList, key, sourceLabel, shouldSaveToDisk) {
        if (key !== root.activeFetchKey) return;
        searchTimeoutTimer.stop();
        root.lyrics = parsedList;
        root.hasLyrics = parsedList && parsedList.length > 0;
        root.loading = false;
        root.lyricsSourceInfo = sourceLabel || "";
        if (root.hasLyrics) {
            let mem = getMemCache();
            if (mem) mem[key] = parsedList;
            if (shouldSaveToDisk !== false) {
                saveLyricsToDisk(key, parsedList);
            }
        }
    }

    function saveLyricsToDisk(key, parsedList) {
        if (!key || !parsedList || parsedList.length === 0) return;
        try {
            saveLyricsProcess.pendingKey = key;
            saveLyricsProcess.pendingData = JSON.stringify(parsedList);
            saveLyricsProcess.running = false;
            saveLyricsProcess.running = true;
        } catch (e) {}
    }

    function fetchLyrics(artist, title, requestKey) {
        if (requestKey !== root.currentTrackKey) return;
        root.loading = true;
        root.hasLyrics = false;
        root.lyrics = [];

        let session = {
            key: requestKey,
            artist: cleanString(artist),
            title: cleanString(title) || title,
            done: false,
            netEaseDone: false,
            lrclibDone: false,
            candidate: null,
            source: ""
        };

        searchTimeoutTimer.restart();
        fetchNetEase(session);
        fetchLrclib(session);
    }

    function checkSessionCompletion(session) {
        if (session.key !== root.activeFetchKey || session.done) return;
        if (session.netEaseDone && session.lrclibDone) {
            session.done = true;
            searchTimeoutTimer.stop();
            if (session.candidate && session.candidate.length > 0) {
                applyLyrics(session.candidate, session.key, session.source, true);
            } else {
                root.loading = false;
                root.hasLyrics = false;
                root.lyrics = [];
            }
        }
    }

    function fetchNetEase(session) {
        let query = (session.artist + " " + session.title).trim();
        if (query === "") query = session.title;

        let url = "https://music.163.com/api/search/get/web?csrf_token=&hlpretag=&hlposttag=&s=" + encodeURIComponent(query) + "&type=1&offset=0&total=true&limit=5";
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    let songs = resp.result && resp.result.songs ? resp.result.songs : [];
                    if (songs.length > 0 && songs[0].id) {
                        fetchNetEaseLyric(songs[0].id, session);
                        return;
                    }
                } catch(e) {}
            }

            session.netEaseDone = true;
            checkSessionCompletion(session);
        };
        xhr.send();
    }

    function fetchNetEaseLyric(songId, session) {
        let url = "https://music.163.com/api/song/lyric?id=" + songId + "&lv=1&kv=1&tv=-1&yv=1";
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    if (resp.yrc && resp.yrc.lyric) {
                        let parsed = parseYrc(resp.yrc.lyric);
                        if (parsed && parsed.length > 0) {
                            session.done = true;
                            applyLyrics(parsed, session.key, "NetEase (Karaoke)", true);
                            return;
                        }
                    }
                    if (resp.lrc && resp.lrc.lyric) {
                        let lines = parseLrc(resp.lrc.lyric);
                        if (lines && lines.length > 0 && !session.candidate) {
                            session.candidate = lines;
                            session.source = "NetEase";
                        }
                    }
                } catch(e) {}
            }

            session.netEaseDone = true;
            checkSessionCompletion(session);
        };
        xhr.send();
    }

    function fetchLrclib(session) {
        let url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(session.artist) + "&track_name=" + encodeURIComponent(session.title);
        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);

        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (session.key !== root.activeFetchKey || session.done) return;

            if (xhr.status === 200) {
                try {
                    let resp = JSON.parse(xhr.responseText);
                    let raw = resp.syncedLyrics || resp.plainLyrics;
                    if (raw) {
                        let parsed = parseLrc(raw);
                        if (parsed && parsed.length > 0) {
                            session.done = true;
                            applyLyrics(parsed, session.key, "LRCLIB", true);
                            return;
                        }
                    }
                } catch(e) {}
            }

            session.lrclibDone = true;
            checkSessionCompletion(session);
        };
        xhr.send();
    }

    Timer {
        id: searchTimeoutTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (root.loading) {
                root.loading = false;
            }
        }
    }

    // Background Process for Caching & Local File Reading
    Process {
        id: cacheReadProcess
        property string targetKey: ""
        command: [
            "bash", "-c",
            'CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/lyrics"; HASH=$(echo -n "$1" | md5sum | cut -d" " -f1); FILE="$CACHE_DIR/${HASH}.json"; if [ -f "$FILE" ] && [ -s "$FILE" ]; then cat "$FILE"; fi',
            "--", targetKey
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let content = this.text.trim();
                let key = cacheReadProcess.targetKey;
                if (key !== root.currentTrackKey) return;

                if (content !== "") {
                    try {
                        let parsed = JSON.parse(content);
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            let mem = root.getMemCache();
                            if (mem) mem[key] = parsed;
                            root.applyLyrics(parsed, key, "Caché", false);
                            return;
                        }
                    } catch(e) {}
                }
                root.fetchLyrics(root.rawTrackArtist, root.rawTrackTitle, key);
            }
        }
    }

    Process {
        id: saveLyricsProcess
        property string pendingKey: ""
        property string pendingData: ""
        command: [
            "bash", "-c",
            'CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/lyrics"; mkdir -p "$CACHE_DIR"; HASH=$(echo -n "$1" | md5sum | cut -d" " -f1); printf "%s" "$2" > "$CACHE_DIR/${HASH}.json"',
            "--", pendingKey, pendingData
        ]
        running: false
    }

    Process {
        id: localFilePickerProcess
        command: [
            "zenity", "--file-selection",
            "--title=Seleccionar archivo de letras",
            '--file-filter=Archivos de letras (*.lrc *.yrc *.txt) | *.lrc *.yrc *.txt',
            '--file-filter=Todos los archivos | *'
        ]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let path = this.text.trim();
                if (path !== "") {
                    fileReaderProcess.filePath = path;
                    fileReaderProcess.running = false;
                    fileReaderProcess.running = true;
                }
            }
        }
    }

    Process {
        id: fileReaderProcess
        property string filePath: ""
        command: ["cat", filePath]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let content = this.text;
                if (content.trim() !== "") {
                    let parsed = parseYrc(content) || parseLrc(content);
                    if (parsed && parsed.length > 0) {
                        applyLyrics(parsed, root.currentTrackKey, "Archivo Local", true);
                    }
                }
            }
        }
    }

    // Active Line Calculation & Centering
    readonly property int currentIndex: {
        if (!hasLyrics || lyrics.length === 0) return -1;
        let pos = currentPosition;
        let idx = -1;
        for (let i = 0; i < lyrics.length; i++) {
            if (pos >= lyrics[i].time) {
                idx = i;
            } else {
                break;
            }
        }
        return idx;
    }

    onCurrentIndexChanged: {
        if (currentIndex >= 0 && lyricsRepeater && lyricsRepeater.count > currentIndex) {
            let item = lyricsRepeater.itemAt(currentIndex);
            if (item) {
                root.activeItemCenterY = item.y + item.height / 2;
            }
        }
    }

    readonly property real targetY: {
        let center = lyricsViewport.height * 0.42;
        if (currentIndex >= 0 && root.hasLyrics) {
            if (root.activeItemCenterY > 0) {
                return center - root.activeItemCenterY;
            }
            if (lyricsRepeater && lyricsRepeater.count > currentIndex) {
                let item = lyricsRepeater.itemAt(currentIndex);
                if (item) return center - (item.y + item.height / 2);
            }
        }
        return center - root.s(20);
    }

    function getLineOpacity(idx) {
        if (root.currentIndex < 0) return 0.50;
        if (idx === root.currentIndex) return 1.0;
        let d = Math.abs(idx - root.currentIndex);
        if (d === 1) return 0.65;
        if (d === 2) return 0.40;
        return Math.max(0.18, 0.40 - ((d - 2) * 0.08));
    }

    function renderActiveLineText(modelData, pos) {
        if (!modelData.words || modelData.words.length === 0) {
            return modelData.text !== "" ? modelData.text : "♪";
        }
        let activeIdx = -1;
        for (let i = 0; i < modelData.words.length; i++) {
            let w = modelData.words[i];
            let end = (w.endTime !== undefined && w.endTime > w.time) ? w.endTime : (i < modelData.words.length - 1 ? modelData.words[i + 1].time : (w.time + 0.8));
            if (pos >= w.time && pos < end) {
                activeIdx = i;
                break;
            }
        }

        let highlight = root.mauve.toString();
        let past = root.text.toString();
        let upcoming = Qt.rgba(root.text.r, root.text.g, root.text.b, 0.40).toString();
        let html = "";

        for (let i = 0; i < modelData.words.length; i++) {
            let w = modelData.words[i];
            let end = (w.endTime !== undefined && w.endTime > w.time) ? w.endTime : (i < modelData.words.length - 1 ? modelData.words[i + 1].time : (w.time + 0.8));
            let space = (i < modelData.words.length - 1) ? " " : "";
            let escaped = w.text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

            if (i === activeIdx) {
                html += "<font color='" + highlight + "'><b>" + escaped + "</b></font>" + space;
            } else if (pos >= end || (activeIdx !== -1 && i < activeIdx)) {
                html += "<font color='" + past + "'>" + escaped + "</font>" + space;
            } else {
                html += "<font color='" + upcoming + "'>" + escaped + "</font>" + space;
            }
        }
        return html.trim();
    }

    // ==========================================
    // UI VISUAL PRESENTATION
    // ==========================================
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.55)
        radius: root.s(16)
        clip: true

        // Top Toolbar (Source label, reload, local file picker)
        RowLayout {
            id: toolbarRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.s(12)
            height: root.s(26)
            z: 10

            Text {
                text: root.lyricsSourceInfo ? "󰎈 " + root.lyricsSourceInfo : ""
                color: root.subtext0
                font.family: "JetBrains Mono"
                font.pixelSize: root.s(11)
                opacity: 0.8
                Layout.fillWidth: true
            }

            // Local LRC Button
            Rectangle {
                width: root.s(26)
                height: root.s(26)
                radius: root.s(6)
                color: lrcBtnMouse.containsMouse ? root.surface2 : root.surface1
                Text {
                    anchors.centerIn: parent
                    text: "󰈔"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: root.s(14)
                    color: root.text
                }
                MouseArea {
                    id: lrcBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: localFilePickerProcess.running = true
                }
            }

            // Refresh / Search Button
            Rectangle {
                width: root.s(26)
                height: root.s(26)
                radius: root.s(6)
                color: refreshBtnMouse.containsMouse ? root.surface2 : root.surface1
                Text {
                    anchors.centerIn: parent
                    text: "󰑐"
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: root.s(14)
                    color: root.text
                }
                MouseArea {
                    id: refreshBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let mem = getMemCache();
                        if (mem && root.currentTrackKey) delete mem[root.currentTrackKey];
                        root.lastFetchedKey = "";
                        root.triggerSearch();
                    }
                }
            }
        }

        // Lyrics Viewport
        Item {
            id: lyricsViewport
            anchors.top: toolbarRow.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: root.s(4)
            anchors.bottomMargin: root.s(10)
            clip: true
            visible: root.hasLyrics

            Item {
                id: scrollContainer
                width: parent.width
                height: lyricsColumn.height
                y: root.targetY

                Behavior on y {
                    NumberAnimation {
                        duration: 550
                        easing.type: Easing.OutCubic
                    }
                }

                Column {
                    id: lyricsColumn
                    width: parent.width
                    spacing: root.s(14)

                    Repeater {
                        id: lyricsRepeater
                        model: root.lyrics

                        delegate: Item {
                            id: lineDelegate
                            width: lyricsColumn.width
                            height: Math.max(root.s(28), lineText.implicitHeight)

                            readonly property bool isCurrent: index === root.currentIndex

                            Component.onCompleted: {
                                if (isCurrent) root.activeItemCenterY = y + height / 2;
                            }
                            onIsCurrentChanged: {
                                if (isCurrent) root.activeItemCenterY = y + height / 2;
                            }
                            onYChanged: {
                                if (isCurrent) root.activeItemCenterY = y + height / 2;
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.time !== undefined) {
                                        let targetSec = modelData.time;
                                        if (root.activePlayer && typeof root.activePlayer.position === "number") {
                                            root.activePlayer.position = targetSec;
                                        }
                                        Quickshell.execDetached(["playerctl", "position", targetSec.toFixed(2)]);
                                    }
                                }
                            }

                            Text {
                                id: lineText
                                width: parent.width - root.s(32)
                                anchors.horizontalCenter: parent.horizontalCenter
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                font.family: "Inter"
                                font.weight: isCurrent ? Font.Bold : Font.Normal
                                font.pixelSize: isCurrent ? root.s(16) : root.s(14)
                                color: (isCurrent && (!modelData.words || modelData.words.length === 0)) ? root.mauve : root.text
                                opacity: root.getLineOpacity(index)
                                scale: isCurrent ? 1.06 : 0.95
                                transformOrigin: Item.Center

                                textFormat: (isCurrent && modelData.words && modelData.words.length > 0) ? Text.StyledText : Text.PlainText
                                text: {
                                    if (isCurrent && modelData.words && modelData.words.length > 0) {
                                        return root.renderActiveLineText(modelData, root.currentPosition);
                                    }
                                    return modelData.text !== "" ? modelData.text : "♪";
                                }

                                Behavior on color { ColorAnimation { duration: 300 } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }
            }
        }

        // Empty / Loading State
        ColumnLayout {
            anchors.centerIn: parent
            spacing: root.s(10)
            visible: !root.hasLyrics
            z: 5

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.loading ? "󰑐" : "󰎈"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: root.s(32)
                color: root.mauve
                opacity: 0.8
                RotationAnimation on rotation {
                    running: root.loading
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 1000
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: {
                    if (!root.isMediaActive) return "No hay música reproduciéndose";
                    if (root.loading) return "Buscando letra...";
                    return "No se encontró la letra en línea";
                }
                font.family: "JetBrains Mono"
                font.bold: true
                font.pixelSize: root.s(13)
                color: root.subtext0
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: root.s(6)
                visible: root.isMediaActive && !root.loading
                implicitWidth: localBtnText.implicitWidth + root.s(28)
                implicitHeight: root.s(32)
                radius: root.s(10)
                color: emptyLocalMouse.containsMouse ? root.surface2 : root.surface1
                border.color: root.surface2
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: root.s(8)
                    Text {
                        text: "󰈔"
                        font.family: "Iosevka Nerd Font"
                        font.pixelSize: root.s(15)
                        color: root.mauve
                    }
                    Text {
                        id: localBtnText
                        text: "Cargar archivo .lrc local"
                        font.family: "JetBrains Mono"
                        font.pixelSize: root.s(12)
                        font.bold: true
                        color: root.text
                    }
                }

                MouseArea {
                    id: emptyLocalMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: localFilePickerProcess.running = true
                }
            }
        }
    }
}
