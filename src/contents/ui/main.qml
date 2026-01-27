import QtQuick
import QtCore
import org.kde.kwin

Item {
    // API and guides
    // https://develop.kde.org/docs/plasma/kwin/
    // https://develop.kde.org/docs/plasma/kwin/api/
    // https://develop.kde.org/docs/plasma/widget/configuration/
    // https://develop.kde.org/docs/features/configuration/kconfig_xt/
    // https://doc.qt.io/qt-6/qml-qtcore-settings.html
    // https://doc.qt.io/qt-6/qtquick-qmlmodule.html

    id: root

    property var debugLogs: false
    property var config: ({})
    property var mainMenuWindow: undefined
    property bool moving: false
    property bool moved: false
    property bool usePopupTiler: false
    property var currentTiler: popupTiler
    property var currentlyMovedWindow: null
    property bool useMouseCursor: true
    property var windowCursor: Qt.point(0,0)
    property bool centerInTile: false
    property list<var> virtualDesktops: ([])
    property var currentVirtualDesktopIndex: 0
    property bool virtualDesktopVisibile: false

    function log(string) {
        if (!debugLogs) return;
        console.warn('MouseTiler: ' + string);
    }

    function logE(string) {
        if (!debugLogs) return;
        console.error('MouseTiler: ' + string);
    }

    function logDev(string) {
        console.error('MouseTiler: ' + string);
    }

    function loadConfig() {
        log('Loading configuration');

        const defaultAllLayouts = `SPECIAL_FILL;Fill
SPECIAL_SPLIT_VERTICAL;Vertical Split
SPECIAL_SPLIT_HORIZONTAL;Horizontal Split
SPECIAL_MAXIMIZE
SPECIAL_MINIMIZE
SPECIAL_FULLSCREEN
0,0,50,100+50,0,50,50+50,50,50,50
0,0,50,50+0,50,50,50+50,0,50,100
0,0,25,50+0,50,25,50+25,0,50,100+75,0,25,50+75,50,25,50
0,0,25,50+0,50,25,50+25,0,50,50+25,50,50,50+75,0,25,50+75,50,25,50
SPECIAL_KEEP_ABOVE
SPECIAL_KEEP_BELOW
0,0,50,100+50,0,25,50+50,50,25,50+75,0,25,50+75,50,25,50
0,0,25,50+0,50,25,50+25,0,25,50+25,50,25,50+50,0,50,100
0,0,50,50+0,50,50,50+50,0,25,50+50,50,25,50+75,0,25,50+75,50,25,50
0,0,25,50+0,50,25,50+25,0,25,50+25,50,25,50+50,0,50,50+50,50,50,50
SPECIAL_NO_TITLEBAR_AND_FRAME
SPECIAL_CLOSE
1x1;Full Screen
2x1
3x1
4x1
5x1
6x1
1x2
1x3
1x4
1x5
0,0,75,100+25,0,75,100+25,0,50,100;75 50 75 (%)
0,0,75,50+25,0,75,50+25,0,50,50+0,50,75,50+25,50,75,50+25,50,50,50;75 50 75 (%) x2
2x2
3x2
4x2
5x2
0,0,67,100+33,0,67,100+17,0,66,100;67 66 67 (%)
0,0,67,50+33,0,67,50+17,0,66,50+0,50,67,50+33,50,67,50+17,50,66,50;67 66 67 (%) x2
2x3
3x3
4x3
5x3
1x1+17,0,66,100+33,0,34,100;100 66 34 (%)
1x2+17,0,66,50+33,0,34,50+17,50,66,50+33,50,34,50;100 66 34 (%) x2
11,25,26,50+37,25,26,50+63,25,26,50
11,0,26,100+37,0,26,100+63,0,26,100
11,0,26,50+37,0,26,50+63,0,26,50 + 11,50,26,50+37,50,26,50+63,50,26,50
11,0,26,100+37,0,26,100+63,0,26,100 + 11,12,26,76+37,12,26,76+63,12,26,76 + 11,25,26,50+37,25,26,50+63,25,26,50
1x1+12,0,76,100+25,0,50,100+37,0,26,100;100 76 50 26 (%)
1x2+12,0,76,50+25,0,50,50+37,0,26,50+12,50,76,50+25,50,50,50+37,50,26,50;100 76 50 26 (%) x2
0,25,37,50+37,25,26,50+63,25,37,50
0,0,37,100+37,0,26,100+63,0,37,100 ; 37 26 37 (%)
0,0,37,50+37,0,26,50+63,0,37,50 + 0,50,37,50+37,50,26,50+63,50,37,50 ; 37 26 37 (%) x2
0,0,37,100+37,0,26,100+63,0,37,100 + 0,12,37,76+37,12,26,76+63,12,37,76 + 0,25,37,50+37,25,26,50+63,25,37,50
1x1+17,17,66,66+33,33,34,34;100 66 34 (%)
1x1+12,12,76,76+25,25,50,50+37,37,26,26;100 76 50 26 (%)
0,0,25,100+75,0,25,100+25,0,50,100;25 50 25 (%)
0,0,25,67+75,0,25,67+25,0,50,67+0,67,25,33+75,67,25,33+25,67,50,33;25 50 25 (%)
0,0,25,33+75,0,25,33+25,0,50,33+0,33,25,67+75,33,25,67+25,33,50,67;25 50 25 (%)
0,0,25,67+75,0,25,67+25,0,50,67+0,33,25,67+75,33,25,67+25,33,50,67;25 50 25 (%)
0,0,33,67+33,0,34,67+67,0,33,67+0,67,33,33+33,67,34,33+67,67,33,33;67 x3 37 x3 (%)
0,0,33,33+33,0,34,33+67,0,33,33+0,33,33,67+33,33,34,67+67,33,33,67;33 x3 67 x3 (%)
0,0,67,100+67,0,33,100
0,0,33,100+33,0,67,100
0,0,67,100+67,0,33,50+67,50,33,50
0,0,33,50+0,50,33,50+33,0,67,100
0,0,67,50+67,0,33,50+0,50,67,50+67,50,33,50
0,0,33,50+33,0,67,50+0,50,33,50+33,50,67,50`;
        const defaultOverlayLayout = '4x2';
        const defaultPopupLayouts = `1x1
2x1
3x1
SPECIAL_SPLIT_HORIZONTAL;Horizontal Split
0,0,75,100+25,0,75,100+25,0,50,100;75 50 75 (%)
4x1
2x2
SPECIAL_FILL;Fill
4x2`;

        config = {
            // user settings
            usePopupTilerByDefault: KWin.readConfig("defaultTiler", 0) == 0,
            centerInTileMode: KWin.readConfig("centerInTileMode", 0),
            rememberTiler: KWin.readConfig("rememberTiler", false),
            restoreSize: KWin.readConfig("restoreSize", false),
            tilerVisibility: KWin.readConfig("tilerVisibility", 0),
            revealMargin: KWin.readConfig("revealMargin", 200),
            windowVisibility: KWin.readConfig("windowVisibility", 0),
            theme: KWin.readConfig("theme", 0),
            tileMargin: KWin.readConfig("tileMargin", 0),
            screenMargin: KWin.readConfig("screenMargin", 0),
            useMouseCursorByDefault: KWin.readConfig("defaultInput", 0) == 0,
            showOverlayTextHint: KWin.readConfig("showOverlayTextHint", true),
            overlay: convertOverlayLayout(KWin.readConfig("overlayLayout", defaultOverlayLayout), defaultOverlayLayout),
            overlayScreenEdgeMargin: KWin.readConfig("overlayScreenEdgeMargin", 0),
            overlayPollingRate: KWin.readConfig("overlayPollingRate", 100),
            rememberAllLayouts: KWin.readConfig("rememberAllLayouts", false),
            showTargetTileHint: KWin.readConfig("showTargetTileHint", true),
            showTextHint: KWin.readConfig("showTextHint", true),
            popupGridAt: KWin.readConfig("popupGridAt", 0),
            horizontalAlignment: KWin.readConfig("horizontalAlignment", 1),
            verticalAlignment: KWin.readConfig("verticalAlignment", 1),
            gridColumns: KWin.readConfig("gridColumns", 3),
            gridAllColumns: KWin.readConfig("gridAllColumns", 6),
            gridSpacing: KWin.readConfig("gridSpacing", 10),
            gridWidth: KWin.readConfig("gridWidth", 130),
            gridHeight: KWin.readConfig("gridHeight", 70),
            popupGridPollingRate: KWin.readConfig("popupGridPollingRate", 100),
            virtualDesktopVisibility: KWin.readConfig("virtualDesktopVisibility", 0),
            virtualDesktopHoverTime: KWin.readConfig("virtualDesktopHoverTime", 0),
            virtualDesktopDropAction: KWin.readConfig("virtualDesktopDropAction", 0),
            showAddVirtualDesktopButton: KWin.readConfig("showAddVirtualDesktopButton", true),
            autoRemoveEmptyVirtualDesktops: KWin.readConfig("autoRemoveEmptyVirtualDesktops", false),
            layouts: convertLayouts(KWin.readConfig("popupLayout", defaultPopupLayouts), defaultPopupLayouts),
            allLayouts: convertLayouts(KWin.readConfig("allPopupLayouts", defaultAllLayouts), defaultAllLayouts),
            shortcutChangeMode: KWin.readConfig("shortcutChangeMode", "Meta+Ctrl+Space"),
            shortcutShowAllSpan: KWin.readConfig("shortcutShowAllSpan", "Ctrl+Space"),
            shortcutVisibility: KWin.readConfig("shortcutVisibility", "Meta+Space"),
            shortcutInputType: KWin.readConfig("shortcutInputType", "Ctrl+Alt+I"),
            shortcutCenterInTile: KWin.readConfig("shortcutCenterInTile", "Meta+Ctrl+C"),
            hintChangeMode: KWin.readConfig("hintChangeMode", true),
            hintShowAllSpan: KWin.readConfig("hintShowAllSpan", true),
            hintVisibility: KWin.readConfig("hintVisibility", true),
            hintInputType: KWin.readConfig("hintInputType", false),
            hintCenterInTile: KWin.readConfig("hintCenterInTile", true),
            showHintHint: KWin.readConfig("showHintHint", true),
            showPositionHint: KWin.readConfig("showPositionHint", false),
            showPositionHintInPixels: KWin.readConfig("positionHintFormat", 0) == 0,
            showSizeHint: KWin.readConfig("showSizeHint", false),
            showSizeHintInPixels: KWin.readConfig("sizeHintFormat", 0) == 0

            // live settings
        };
        config.tileMarginLeftTop = Math.floor(config.tileMargin / 2);
        config.tileMarginRightBottom = Math.ceil(config.tileMargin / 2);
        config.rememberCenterInTile = config.centerInTileMode == 1 || config.centerInTileMode == 3;

        useMouseCursor = config.useMouseCursorByDefault;

        setDefaultTiler();
        setDefaultCenterInTile();
        updateVirtualDesktops();
    }

    function setDefaultTiler() {
        currentTiler = config.usePopupTilerByDefault ? popupTiler : overlayTiler;
    }

    function setDefaultCenterInTile() {
        centerInTile = config.centerInTileMode > 1;
    }

    function convertOverlayLayout(userLayout, defaultLayout) {
        let converted = convertLayout(userLayout);
        if (converted != null) {
            return [...converted.tiles];
        } else {
            converted = convertLayout(defaultLayout);
            if (converted != null) {
                return [...converted.tiles];
            }
        }
        return [];
    }

    function convertLayouts(userLayouts, defaultLayouts) {
        var layoutArray = userLayouts.split('\n');
        let convertedLayouts = [];

        if (layoutArray.length == 0) {
            layoutArray = defaultLayouts.split('\n');
        }

        logE('Converting ' + layoutArray.length + ' layouts.');

        for (let layoutIndex = 0; layoutIndex < layoutArray.length; layoutIndex++) {
            let convertedLayout = convertLayout(layoutArray[layoutIndex]);
            if (convertedLayout != null) {
                convertedLayouts.push(convertedLayout);
            }
        }
        return convertedLayouts;
    }

    function convertLayout(userLayout) {
        var hasDefault = false;
        var hasLayout = false;
        var hasName = false;
        var isValid = false;
        var name = "Default";

        let layout = { tiles: [] };

        const anchorValue = {
            left: "0",
            top: "0",
            center: "50",
            right: "100",
            bottom: "100"
        };

        let sections = userLayout.split(';');
        for (let sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
            if (sections[sectionIndex].startsWith('d') && !hasDefault) {
                hasDefault = true;
            } else if (!hasLayout) {
                let tiles = sections[sectionIndex].replace(/\s+/g, '').split('+');
                if (tiles.length == 1 && tiles[0].length > 0) {
                    name = tiles[0];
                }
                for (let tileIndex = 0; tileIndex < tiles.length; tileIndex++) {
                    let coordinates = tiles[tileIndex].split(',');
                    if (coordinates.length == 1) {
                        if (coordinates[0].startsWith('SPECIAL_')) {
                            switch (coordinates[0]) {
                                case 'SPECIAL_FILL':
                                    layout.tiles.push({x: 0, y: 0, w: 75, h: 100, t: "«&nbsp; FILL &nbsp;»", hint: "Fill largest empty space"});
                                    layout.tiles.push({x: 75, y: 0, w: 25, h: 100, t: "« »", d: false, hint: "Fill smallest empty space"});
                                    layout.special = 'SPECIAL_FILL';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_SPLIT_VERTICAL':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 50, t: "SPLIT", hint: "Split largest window and place on top"});
                                    layout.tiles.push({x: 0, y: 50, w: 100, h: 50, t: "SPLIT", d: false, hint: "Split largest window and place on bottom"});
                                    layout.special = 'SPECIAL_SPLIT_VERTICAL';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_SPLIT_HORIZONTAL':
                                    layout.tiles.push({x: 0, y: 0, w: 50, h: 100, t: "SPLIT", hint: "Split largest window and place to the left"});
                                    layout.tiles.push({x: 50, y: 0, w: 50, h: 100, t: "SPLIT", d: false, hint: "Split largest window and place to the right"});
                                    layout.special = 'SPECIAL_SPLIT_HORIZONTAL';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_MAXIMIZE':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>MAXIMIZE<br>⌞⌝", hint: "Set window to ⌞⌝ Maximized<br>It will return to previous size when moved"});
                                    layout.special = 'SPECIAL_MAXIMIZE';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_MINIMIZE':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>MINIMIZE<br>🗕", hint: "Set window to 🗕 Minimized<br>Useful for windows without a titlebar"});
                                    layout.special = 'SPECIAL_MINIMIZE';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_FULLSCREEN':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>FULLSCREEN<br>🗖", hint: "Set window to 🗖 Fullscreen<br><font color='orange'>⚠</font> <b>WARNING</b> you might need to press <b>Alt+F3</b> to exit"});
                                    layout.special = 'SPECIAL_FULLSCREEN';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_EMPTY':
                                    layout.special = 'SPECIAL_EMPTY';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_KEEP_ABOVE':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>KEEP ABOVE<br>▲", hint: "Toggle window ▲ Keep Above"});
                                    layout.special = 'SPECIAL_KEEP_ABOVE';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_KEEP_BELOW':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>KEEP BELOW<br>▼", hint: "Toggle window ▼ Keep Below"});
                                    layout.special = 'SPECIAL_KEEP_BELOW';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_NO_TITLEBAR_AND_FRAME':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "NO TITLEBAR<br>AND FRAME", hint: "Toggle window <font size='1'>⊘</font> No Titlebar and Frame<br><font color='orange'>⚠</font> <b>WARNING</b> you might need to press <b>Alt+F3</b> to re-enable"});
                                    layout.special = 'SPECIAL_NO_TITLEBAR_AND_FRAME';
                                    isValid = true;
                                    break;
                                case 'SPECIAL_CLOSE':
                                    layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "<br>CLOSE<br>🗙", hint: "🗙 Close the window<br>Useful for windows without a titlebar"});
                                    layout.special = 'SPECIAL_CLOSE';
                                    isValid = true;
                                    break;
                            }
                        } else {
                            // no coordinates found - just grid size defined by wxh
                            let wxh = coordinates[0].split('x');
                            if (wxh.length == 2) {
                                let w = parseInt(wxh[0]);
                                let h = parseInt(wxh[1]);
                                let width = Math.trunc(100 / w);
                                let height = Math.trunc(100 / h);
                                let widthModulo = 100 % w;
                                let heightModulo = 100 % h;

                                let yOffset = 0;
                                for (let y = 0; y < h; y++) {
                                    let xOffset = 0;
                                    let currentYOffset = getExtraPercentage(heightModulo, y, h);
                                    for (let x = 0; x < w; x++) {
                                        let currentXOffset = getExtraPercentage(widthModulo, x, w);
                                        layout.tiles.push({x: x * width + xOffset, y: y * height + yOffset, w: width + currentXOffset, h: height + currentYOffset});
                                        xOffset += currentXOffset;
                                    }
                                    yOffset += currentYOffset;
                                }
                                isValid = w > 0 && h > 0;
                            } else {
                                logE('Invalid user layout: ' + tiles[tileIndex]);
                            }
                        }
                    } else if (coordinates.length == 4 || coordinates.length == 6) {
                        // x, pixel x, y, pixel y, w, pixel w, h, pixel h, anchorX, anchorY
                        let x, pxX, y, pxY, w, pxW, h, pxH, aX, aY;
                        isValid = true;
                        if (coordinates[0].endsWith('px')) {
                            pxX = parseInt(coordinates[0]);
                            if (Number.isNaN(pxX)) {
                                isValid = false;
                            }
                        } else {
                            x = parseInt(coordinates[0]);
                            if (Number.isNaN(x)) {
                                isValid = false;
                            }
                        }

                        if (coordinates[1].endsWith('px')) {
                            pxY = parseInt(coordinates[1]);
                            if (Number.isNaN(pxY)) {
                                isValid = false;
                            }
                        } else {
                            y = parseInt(coordinates[1]);
                            if (Number.isNaN(y)) {
                                isValid = false;
                            }
                        }

                        if (coordinates[2].endsWith('px')) {
                            pxW = parseInt(coordinates[2]);
                            if (Number.isNaN(pxW)) {
                                isValid = false;
                            }
                        } else {
                            w = parseInt(coordinates[2]);
                            if (Number.isNaN(w)) {
                                isValid = false;
                            }
                        }

                        if (coordinates[3].endsWith('px')) {
                            pxH = parseInt(coordinates[3]);
                            if (Number.isNaN(pxH)) {
                                isValid = false;
                            }
                        } else {
                            h = parseInt(coordinates[3]);
                            if (Number.isNaN(h)) {
                                isValid = false;
                            }
                        }

                        if (coordinates.length == 6) {
                            let numericAX = coordinates[4].replace(/\b(?:left|center|right)\b/gi, value => anchorValue[value.toLowerCase()]);
                            aX = parseInt(numericAX);
                            if (Number.isNaN(aX)) {
                                isValid = false;
                            }

                            let numericAY = coordinates[5].replace(/\b(?:top|center|bottom)\b/gi, value => anchorValue[value.toLowerCase()]);
                            aY = parseInt(numericAY);
                            if (Number.isNaN(aY)) {
                                isValid = false;
                            }
                        }

                        if (isValid) {
                            layout.tiles.push({x: x, pxX: pxX, y: y, pxY: pxY, w: w, pxW: pxW, h: h, pxH: pxH, aX: aX, aY: aY});
                        } else {
                            logE('Invalid user layout: ' + tiles[tileIndex]);
                        }
                    } else {
                        logE('Invalid user layout: ' + tiles[tileIndex]);
                    }
                }
                hasLayout = true;
            } else if (!hasName) {
                let trimmedName = sections[sectionIndex].trim();
                if (trimmedName.length > 0) {
                    name = trimmedName;
                    hasName = true;
                }
            }
        }
        if (isValid) {
            layout.name = name;
            return layout;
        }
        return null;
    }

    function getExtraPercentage(extraPercentage, index, count) {
        if (extraPercentage == 0) return 0;
        if (extraPercentage >= count) return 1; // This should not even be possible just a fallback

        let isEven = count % 2 == 0;
        let isExtraEven = extraPercentage % 2 == 0;
        let areBothSame = isEven == isExtraEven;

        let startIndex = Math.trunc((count - extraPercentage) / 2);
        return index >= startIndex && index < startIndex + extraPercentage;
    }

    function getCursorPosition() {
        return useMouseCursor ? Workspace.cursorPos : windowCursor;
    }

    function isValidWindow(client) {
        if (!client) return false;
        if (!client.normalWindow) return false;
        if (client.skipTaskbar) return false;
        if (client.popupWindow) return false;
        if (client.deleted) return false;

        return true;
    }

    function addWindow(client) {
        if (!isValidWindow(client)) return;
        log('Adding window: ' + client.resourceClass);

        client.closed.connect(onClosed);
        client.interactiveMoveResizeStarted.connect(onInteractiveMoveResizeStarted);
        client.interactiveMoveResizeStepped.connect(onInteractiveMoveResizeStepped);
        client.interactiveMoveResizeFinished.connect(onInteractiveMoveResizeFinished);

        function onClosed() {
            client.closed.disconnect(onClosed);
            client.interactiveMoveResizeStarted.disconnect(onInteractiveMoveResizeStarted);
            client.interactiveMoveResizeStepped.disconnect(onInteractiveMoveResizeStepped);
            client.interactiveMoveResizeFinished.disconnect(onInteractiveMoveResizeFinished);
            removeEmptyVirtualDesktops();
        }

        function onInteractiveMoveResizeStarted() {
            if (client.move) {
                if (!useMouseCursor) {
                    windowCursor = Qt.point(client.x + client.width / 2, client.y);
                }
                if (config.restoreSize && client.mt_originalSize) {
                    client.frameGeometry = Qt.rect(getCursorPosition().x - client.mt_originalSize.xOffset, client.frameGeometry.y, client.mt_originalSize.width, client.mt_originalSize.height);
                    delete client.mt_originalSize;
                }
                client.mt_originalPosition = {x: client.x, y: client.y};
                moving = true;
                currentlyMovedWindow = client;
                showTiler(true);
                if (config.tilerVisibility == 1) {
                    autoHideTimer.startAutoHideTimer();
                }
            } else if (client.resize && client.mt_originalSize) {
                delete client.mt_originalSize;
            }
        }

        function onInteractiveMoveResizeStepped() {
            if (moving) {
                if (!useMouseCursor) {
                    windowCursor = Qt.point(client.x + client.width / 2, client.y);
                }
                if (!moved) {
                    moved = true;
                    if (currentTiler.visible) {
                        autoHideTimer.stopAutoHideTimer();
                    }
                }
            }
        }

        function onInteractiveMoveResizeFinished() {
            if (moving && !useMouseCursor) {
                windowCursor = Qt.point(client.x + client.width / 2, client.y);
            }
            if (currentTiler.visible) {
                if (moved) {
                    var activeVirtualDesktopIndex = currentTiler.getActiveVirtualDesktopIndex();
                    if (activeVirtualDesktopIndex != -1) {
                        let desktop;
                        if (virtualDesktops[activeVirtualDesktopIndex].isAdd) {
                            Workspace.createDesktop(Workspace.desktops.length, "");
                            desktop = Workspace.desktops[Workspace.desktops.length - 1];
                        } else {
                            desktop = virtualDesktops[activeVirtualDesktopIndex].desktop;
                        }
                        client.desktops = [virtualDesktops[activeVirtualDesktopIndex].desktop];
                        switch (config.virtualDesktopDropAction) {
                            case 0:
                                client.frameGeometry = Qt.rect(client.mt_originalPosition.x, client.mt_originalPosition.y, client.width, client.height);
                                Workspace.currentDesktop = desktop;
                                break;
                            case 1:
                                Workspace.activeWindow = client;
                                Workspace.slotWindowMaximize();
                                break;
                        }
                    } else {
                        var geometry = currentTiler.getGeometry();
                        if (geometry != null) {
                            let xOffset = (getCursorPosition().x - client.x) / client.width;
                            client.mt_originalSize = {xOffset: xOffset, width: client.width, height: client.height};

                            switch (geometry.special) {
                                case 'SPECIAL_FILL':
                                    geometry = getFillGeometry(client, geometry.specialMode == 0);
                                    addMargins(geometry, true, true, true, true);
                                    if (geometry != null) {
                                        moveAndResizeWindow(client, geometry);
                                    }
                                    break;
                                case 'SPECIAL_SPLIT_VERTICAL':
                                    geometry = splitAndMoveSplitted(client, true, geometry.specialMode == 0);
                                    if (geometry != null) {
                                        moveAndResizeWindow(client, geometry);
                                    }
                                    break;
                                case 'SPECIAL_SPLIT_HORIZONTAL':
                                    geometry = splitAndMoveSplitted(client, false, geometry.specialMode == 0);
                                    if (geometry != null) {
                                        moveAndResizeWindow(client, geometry);
                                    }
                                    break;
                                case 'SPECIAL_NO_TITLEBAR_AND_FRAME':
                                    client.noBorder = !client.noBorder;
                                    break;
                                case 'SPECIAL_KEEP_ABOVE':
                                    client.keepAbove = !client.keepAbove;
                                    break;
                                case 'SPECIAL_KEEP_BELOW':
                                    client.keepBelow = !client.keepBelow;
                                    break;
                                case 'SPECIAL_MAXIMIZE':
                                    Workspace.activeWindow = client;
                                    Workspace.slotWindowMaximize();
                                    break;
                                case 'SPECIAL_MINIMIZE':
                                    client.minimized = true;
                                    break;
                                case 'SPECIAL_FULLSCREEN':
                                    client.fullScreen = true;
                                    break;
                                case 'SPECIAL_CLOSE':
                                    Workspace.activeWindow = client;
                                    Workspace.slotWindowClose();
                                    break;
                                default:
                                    addMargins(geometry, true, true, true, true);
                                    moveAndResizeWindow(client, geometry);
                                    break;
                            }
                        }
                    }
                }
                hideTiler();
                popupTiler.resetVirtualDesktopOverride();
                if (!config.rememberTiler) {
                    setDefaultTiler();
                }
                if (!config.rememberCenterInTile) {
                    setDefaultCenterInTile();
                }

                removeEmptyVirtualDesktops();
            }
            moving = false;
            moved = false;
            currentlyMovedWindow.opacity = 1;
            currentlyMovedWindow = null;
            delete client.mt_originalPosition;
        }
    }

    function addMargins(geometry, left, right, top, bottom) {
        if (config.tileMargin > 0 || config.screenMargin != 0) {
            let clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop);
            if (left) {
                let isEdge = Math.abs(geometry.x - clientArea.left) < 0.1;
                geometry.x += isEdge ? config.tileMargin + config.screenMargin : config.tileMarginLeftTop;
                geometry.width -= isEdge ? config.tileMargin + config.screenMargin : config.tileMarginLeftTop;
            }
            if (right) {
                let isEdge = Math.abs(geometry.x + geometry.width - clientArea.right) < 0.1;
                geometry.width -= isEdge ? config.tileMargin + config.screenMargin : config.tileMarginRightBottom;
            }
            if (top) {
                let isEdge = Math.abs(geometry.y - clientArea.top) < 0.1;
                geometry.y += isEdge ? config.tileMargin + config.screenMargin : config.tileMarginLeftTop;
                geometry.height -= isEdge ? config.tileMargin + config.screenMargin : config.tileMarginLeftTop;
            }
            if (bottom) {
                let isEdge = Math.abs(geometry.y + geometry.height - clientArea.bottom) < 0.1;
                geometry.height -= isEdge ? config.tileMargin + config.screenMargin : config.tileMarginRightBottom;
            }
        }
    }

    function splitAndMoveSplitted(client, vertical, leftOrTop, moveSplitted = true) {
        var largestIndex = -1;
        var largestArea = -1;

        const windows = Workspace.stackingOrder;
        for (var i = 0; i < windows.length; i++) {
            let window = windows[i];
            if (client.internalId != window.internalId && isValidWindow(window) && Workspace.activeScreen.name == window.output.name && !window.minimized && (window.onAllDesktops || window.desktops.includes(Workspace.currentDesktop)) && (window.activities.length == 0 || window.activities.includes(Workspace.currentActivity))) {
                let area = window.width * window.height;
                if (area > largestArea) {
                    largestIndex = i;
                    largestArea = area;
                }
            }
        }

        if (largestIndex >= 0) {
            let window = windows[largestIndex];
            // logE('Largest: ' + window.width + ' x ' + window.height + ' window: ' + JSON.stringify(window));
            if (!window.resizeable) return null;
            let geometryFirst = vertical ? Qt.rect(window.x, window.y, window.width, window.height / 2) : Qt.rect(window.x, window.y, window.width / 2, window.height);
            let geometrySecond = vertical ? Qt.rect(window.x, window.y + window.height / 2, window.width, window.height / 2) : Qt.rect(window.x + window.width / 2, window.y, window.width / 2, window.height);

            if (moveSplitted) {
                if (vertical) {
                    addMargins(geometryFirst, false, false, false, true);
                    addMargins(geometrySecond, false, false, true, false);
                } else {
                    addMargins(geometryFirst, false, true, false, false);
                    addMargins(geometrySecond, true, false, false, false);
                }
                moveAndResizeWindow(window, leftOrTop ? geometrySecond : geometryFirst);
            }

            return leftOrTop ? geometryFirst : geometrySecond;
        }
    }

    function getFillGeometry(client, largest) {
        let screenGeometry = Workspace.activeScreen.geometry;
        //let freeAreas = [Qt.rect(screenGeometry.x, screenGeometry.y, screenGeometry.width, screenGeometry.height)];
        let freeAreas = [Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop)];

        const windows = Workspace.stackingOrder;
        for (var i = 0; i < windows.length; i++) {
            let window = windows[i];
            if (client.internalId != window.internalId && isValidWindow(window) && !window.minimized && (window.onAllDesktops || window.desktops.includes(Workspace.currentDesktop)) && (window.activities.length == 0 || window.activities.includes(Workspace.currentActivity))) {
                removeUsedAreas(freeAreas, window.frameGeometry);
                removeOverlappingSmallerAreas(freeAreas);
            }
        }

        var matchIndex = -1;
        var matchArea = largest ? -1 : Number.MAX_SAFE_INTEGER;

        for (var i = 0; i < freeAreas.length; i++) {
            let area = freeAreas[i].width * freeAreas[i].height;
            if (largest) {
                if (area > matchArea) {
                    matchArea = area;
                    matchIndex = i;
                }
            } else {
                if (area < matchArea) {
                    matchArea = area;
                    matchIndex = i;
                }
            }
        }

        if (matchIndex >= 0) {
            return freeAreas[matchIndex];
        }

        return null;
    }

    function removeOverlappingSmallerAreas(freeAreas) {
        for (let i = freeAreas.length - 1; i >= 0; i--) {
            for (let match = 0; match < i;) {
                if (freeAreas[match].left <= freeAreas[i].left && freeAreas[match].right >= freeAreas[i].right && freeAreas[match].top <= freeAreas[i].top && freeAreas[match].bottom >= freeAreas[i].bottom) {
                    freeAreas.splice(i, 1);
                    break;
                } else if (freeAreas[i].left <= freeAreas[match].left && freeAreas[i].right >= freeAreas[match].right && freeAreas[i].top <= freeAreas[match].top && freeAreas[i].bottom >= freeAreas[match].bottom) {
                    freeAreas.splice(match, 1);
                    i--;
                } else {
                    match++;
                }
            }
        }
    }

    function removeUsedAreas(freeAreas, area) {

        for (let i = freeAreas.length - 1; i >= 0; i--) {
            let freeArea = freeAreas[i];
            if (area.left >= freeArea.right || area.right <= freeArea.left || area.top >= freeArea.bottom || area.bottom <= freeArea.top) {
                // Do nothing
            } else {
                let left = Math.max(area.left, freeArea.left);
                let right = Math.min(area.right, freeArea.right);
                let top = Math.max(area.top, freeArea.top);
                let bottom = Math.min(area.bottom, freeArea.bottom);
                let rect = Qt.rect(left, top, right - left, bottom - top);
                freeAreas.splice(i, 1);
                if (rect.left <= freeArea.left && rect.right >= freeArea.right && rect.top <= freeArea.top && rect.bottom >= freeArea.bottom) {
                    // Do nothing
                } else {
                    if (freeArea.left < rect.left) {
                        freeAreas.push(Qt.rect(freeArea.left, freeArea.top, rect.left - freeArea.left, freeArea.height));
                    }
                    if (freeArea.right > rect.right) {
                        freeAreas.push(Qt.rect(rect.right, freeArea.top, freeArea.right - rect.right, freeArea.height));
                    }
                    if (freeArea.top < rect.top) {
                        freeAreas.push(Qt.rect(freeArea.left, freeArea.top, freeArea.width, rect.top - freeArea.top));
                    }
                    if (freeArea.bottom > rect.bottom) {
                        freeAreas.push(Qt.rect(freeArea.left, rect.bottom, freeArea.width, freeArea.bottom - rect.bottom));
                    }
                }
            }
        }
    }

    function moveAndResizeWindow(window, geometry) {
        log('Moving and resizing: ' + window.caption);
        if (window.resizeable) {
            if (geometry.width > 20 && geometry.height > 20) {
                window.frameGeometry = Qt.rect(geometry.x, geometry.y, geometry.width, geometry.height);
            }
        } else {
            window.frameGeometry = Qt.rect(geometry.x, geometry.y, window.width, window.height);
        }
    }

    function updateWindowVisibility() {
        if (currentlyMovedWindow == null) return;
        if (!currentTiler.visible || (currentTiler.opacity != 1 && config.tilerVisibility == 1)) {
            currentlyMovedWindow.opacity = 1;
        } else {
            switch (config.windowVisibility) {
                default:
                    currentlyMovedWindow.opacity = 1;
                    break;
                case 1:
                    if (currentTiler.visible) {
                        if (currentTiler == popupTiler) {
                            if (popupTiler.revealed) {
                                currentlyMovedWindow.opacity = 0;
                            } else {
                                currentlyMovedWindow.opacity = 1;
                            }
                        } else {
                            currentlyMovedWindow.opacity = 0;
                        }
                    }
                    break;
                case 2:
                    if (currentTiler == popupTiler) {
                        if (popupTiler.currentlyHovered) {
                            currentlyMovedWindow.opacity = 0;
                        } else {
                            currentlyMovedWindow.opacity = 1;
                        }
                    } else {
                        currentlyMovedWindow.opacity = 0;
                    }
                    break;
            }
        }
    }

    function setCurrentVirtualDesktop() {
        currentVirtualDesktopIndex = Workspace.desktops.indexOf(Workspace.currentDesktop);
    }

    function updateVirtualDesktops() {
        switch (config.virtualDesktopVisibility) {
            case 0:
            case 1:
                virtualDesktopVisibile = true;
                break;
            case 2:
                virtualDesktopVisibile = Workspace.desktops.length > 1;
                break;
            case 3:
                virtualDesktopVisibile = false;
                break;
        }
        virtualDesktops = [];
        if (virtualDesktopVisibile) {
            for (let i = 0; i < Workspace.desktops.length; i++) {
                virtualDesktops.push({desktop: Workspace.desktops[i], isAdd: false});
            }
            if (config.showAddVirtualDesktopButton) {
                virtualDesktops.push({isAdd: true});
            }
        }
    }

    function removeEmptyVirtualDesktops() {
        if (!config.autoRemoveEmptyVirtualDesktops) return;
        let virtualDesktopWindowCount = Array.from({ length: Workspace.desktops.length }, () => 0);
        virtualDesktopWindowCount[0]++;
        let filledCount = 1;

        for (let i = Workspace.stackingOrder.length - 1; i >= 0; i--) {
            let window = Workspace.stackingOrder[i];
            if (isValidWindow(window)) {
                if (window.onAllDesktops) {
                    // A window occupies all windows - do not remove anything
                    return;
                }
                for (let d = 0; d < window.desktops.length; d++) {
                    let index = Workspace.desktops.indexOf(window.desktops[d]);
                    if (virtualDesktopWindowCount[index] == 0) {
                        filledCount++;
                        if (filledCount == Workspace.desktops.length) {
                            // All virtual desktops filled - do not remove anything
                            return;
                        }
                    }
                    virtualDesktopWindowCount[index]++;
                }
            }
        }

        // i must be > 0, we do not delete the first desktop
        for (let i = virtualDesktopWindowCount.length; i > 0; i--) {
            if (virtualDesktopWindowCount[i] == 0) {
                log('Trying to remove empty virtual desktop with index: ' + i);
                Workspace.removeDesktop(Workspace.desktops[i]);
            }
        }

        setCurrentVirtualDesktop();
    }

    Timer {
        id: autoHideTimer

        property var timerIsRunning: false

        function startAutoHideTimer() {
            if (!timerIsRunning) {
                autoHideTimer.interval = 5;
                autoHideTimer.repeat = false;
                autoHideTimer.triggered.connect(onTimeoutTriggered);
                timerIsRunning = true;

                autoHideTimer.start();
            }
        }

        function stopAutoHideTimer() {
            if (timerIsRunning) {
                autoHideTimer.triggered.disconnect(onTimeoutTriggered);
                timerIsRunning = false;
                autoHideTimer.stop();
            }
        }

        function onTimeoutTriggered() {
            log('Auto-hiding tiler');
            autoHideTimer.triggered.disconnect(onTimeoutTriggered);
            timerIsRunning = false;
            autoHideTimer.stop();

            hideTiler();
            if (!config.rememberTiler) {
                setDefaultTiler();
            }
            if (!config.rememberCenterInTile) {
                setDefaultCenterInTile();
            }
        }
    }

    Settings {
        // Saved in default settings file ~/.config/kde.org/kwin.conf
        id: settings
        property string mousetiler_config: "{}"
    }

    Connections {
        target: Workspace

        function onWindowAdded(client) {
            addWindow(client);
        }

        function onCurrentDesktopChanged(previous) {
            setCurrentVirtualDesktop();
        }

        function onDesktopsChanged() {
            updateVirtualDesktops();
        }
    }

    Component.onCompleted: {
        log('Loading...');
        debugLogs = KWin.readConfig("debugLogs", false);
        // Script is loaded - init config
        loadConfig();

        // Add existing windows
        const clients = Workspace.stackingOrder;
        for (var i = 0; i < clients.length; i++) {
            addWindow(clients[i]);
        }

        log('Loaded...');
    }

    Component.onDestruction: {
        log('Closing...');
    }

    function showMainMenu() {
        if (!mainMenuWindow) {
            mainMenuWindow = mainmenu.createObject(root);
        }
        if (!mainMenuWindow.visible) {
            mainMenuWindow.show();
            mainMenuWindow.initMainMenu();
        }
    }

    function closeMainMenu() {
        if (mainMenuWindow && mainMenuWindow.visible) {
            mainMenuWindow.close();
        }
    }

    Item {
        id: main

        PopupTiler {
            id: popupTiler
        }

        OverlayTiler {
            id: overlayTiler
        }
    }

    Component {
        id: mainmenu

        MainMenu {
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Show Config"
        text: "Mouse Tiler: Show Config"
        sequence: "Ctrl+."
        onActivated: {
            log('Show Config triggered!');
            if (mainMenuWindow && mainMenuWindow.visible) {
                closeMainMenu();
            } else {
                showMainMenu();
            }
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Toggle Visibility"
        text: "Mouse Tiler: Toggle Visibility"
        sequence: "Meta+Space"
        onActivated: {
            log('Toggle Visibility triggered!');
            if (moving) {
                if (currentTiler.visible) {
                    hideTiler();
                } else {
                    showTiler(false, true);
                }
            }
        }
    }

    function hideTiler() {
        if (currentTiler.visible) {
            currentTiler.visible = false;
            updateWindowVisibility();
            return true;
        }
        return false;
    }

    function showTiler(animate, force = false) {
        let show = force || config.tilerVisibility != 2;
        if (show) {
            currentTiler.reset();
            if (!config.rememberAllLayouts && currentTiler == popupTiler) {
                currentTiler.resetShowAll();
            }
            currentTiler.visible = true;
            currentTiler.updateScreen();
            if (animate) {
                currentTiler.startAnimations();
            }
            updateWindowVisibility(); // Must run after startAnimation so that opacity is properly set to 0 or 1
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Change Mode"
        text: "Mouse Tiler: Change Mode"
        sequence: "Meta+Ctrl+Space"
        onActivated: {
            log('Change Mode triggered!');
            let wasVisible = hideTiler();
            if (currentTiler == popupTiler) {
                currentTiler = overlayTiler;
            } else {
                currentTiler = popupTiler;
            }
            if (wasVisible) {
                showTiler(false, true);
            }
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Show All/Toggle Span"
        text: "Mouse Tiler: Show All/Toggle Span"
        sequence: "Ctrl+Space"
        onActivated: {
            log('Show All/Toggle Span triggered!');
            if (overlayTiler.visible) {
                overlayTiler.toggleSpan();
            } else if (popupTiler.visible) {
                popupTiler.toggleShowAll();
            }
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Toggle Input Type"
        text: "Mouse Tiler: Toggle Input Type"
        sequence: "Ctrl+Alt+I"
        onActivated: {
            log('Toggle Input Type triggered!');
            if (useMouseCursor && currentlyMovedWindow != null) {
                windowCursor = Qt.point(currentlyMovedWindow.x + currentlyMovedWindow.width / 2, currentlyMovedWindow.y);
            }
            useMouseCursor = !useMouseCursor;
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Toggle Center In Tile"
        text: "Mouse Tiler: Toggle Center In Tile"
        sequence: "Meta+Ctrl+C"
        onActivated: {
            log('Toggle Center In Tile triggered!');
            centerInTile = !centerInTile;
        }
    }
}