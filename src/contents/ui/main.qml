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
    property bool resizing: false
    property bool resized: false
    property bool usePopupTiler: false
    property var currentTiler: popupTiler
    property var currentlyMovedWindow: null
    property bool useMouseCursor: true
    property var windowCursor: Qt.point(0,0)
    property bool centerInTile: false
    property list<var> virtualDesktops: ([])
    property var currentVirtualDesktopIndex: Workspace.desktops.indexOf(Workspace.currentDesktop)
    property bool virtualDesktopVisibile: false
    property bool moveToVirtualDesktopOnDrop: false
    property bool moveToVirtualDesktopOnTile: false
    property var positionAtMoveStart: ({x: 0, y: 0})
    property var virtualDesktopAtMoveStart: Workspace.currentDesktop
    property var virtualDesktopIndexAtMoveStart: Workspace.desktops.indexOf(Workspace.currentDesktop)
    property var virtualDesktopChangedSinceMoveStart: false
    property bool useAutoTilerPreview: false
    property bool validAutoTilerPreview: true
    property list<var> popupGridLayouts: ([])
    property list<var> popupGridAllLayouts: ([])
    property bool autoTilerEdgeScroll: false

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
0,0,33,50+33,0,67,50+0,50,33,50+33,50,67,50
SPECIAL_AUTO_TILER_TOGGLE
SPECIAL_AUTO_TILER_1
SPECIAL_AUTO_TILER_2
SPECIAL_AUTO_TILER_3`;
        const defaultOverlayLayout = '4x2';
        const defaultPopupLayouts = `1x1
2x1
3x1
SPECIAL_SPLIT_HORIZONTAL;Horizontal Split
0,0,75,100+25,0,75,100+25,0,50,100;75 50 75 (%)
4x1
2x2
SPECIAL_FILL;Fill
4x2
SPECIAL_AUTO_TILER_1
SPECIAL_AUTO_TILER_2
SPECIAL_AUTO_TILER_3`;

        useAutoTilerPreview = KWin.readConfig("debugDesignAuto", false);

        popupGridLayouts = convertLayouts(KWin.readConfig("popupLayout", defaultPopupLayouts), defaultPopupLayouts);
        popupGridAllLayouts = convertLayouts(KWin.readConfig("allPopupLayouts", defaultAllLayouts), defaultAllLayouts);

        autoTilerEdgeScroll = KWin.readConfig("autoTilerEdgeScroll", true);

        config = {
            // user settings
            usePopupTilerByDefault: KWin.readConfig("defaultTiler", 0) == 0,
            centerInTileMode: KWin.readConfig("centerInTileMode", 0),
            rememberTiler: KWin.readConfig("rememberTiler", false),
            restoreSize: KWin.readConfig("restoreSize", false),
            allowTransient: KWin.readConfig("allowTransient", false),
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
            gridTilerOpacity: Math.min(1, Math.max(0, (KWin.readConfig("gridTilerOpacity", 100) / 100))),
            popupGridAt: KWin.readConfig("popupGridAt", 0),
            horizontalAlignment: KWin.readConfig("horizontalAlignment", 1),
            verticalAlignment: KWin.readConfig("verticalAlignment", 1),
            gridColumns: useAutoTilerPreview ? 14 : KWin.readConfig("gridColumns", 3),
            gridAllColumns: KWin.readConfig("gridAllColumns", 6),
            gridSpacing: KWin.readConfig("gridSpacing", 10),
            gridWidth: KWin.readConfig("gridWidth", 130),
            gridHeight: KWin.readConfig("gridHeight", 70),
            popupGridPollingRate: KWin.readConfig("popupGridPollingRate", 100),
            virtualDesktopVisibility: KWin.readConfig("virtualDesktopVisibility", 0),
            virtualDesktopDropAction: KWin.readConfig("virtualDesktopDropAction", 0),
            virtualDesktopHoverTime: KWin.readConfig("virtualDesktopHoverTime", 500),
            moveBackOnDrop: KWin.readConfig("moveBackOnDrop", false),
            moveBackOnTile: KWin.readConfig("moveBackOnTile", false),
            showAddVirtualDesktopButton: KWin.readConfig("showAddVirtualDesktopButton", true),
            autoRemoveEmptyVirtualDesktops: KWin.readConfig("autoRemoveEmptyVirtualDesktops", false),
            shortcutChangeMode: KWin.readConfig("shortcutChangeMode", "Meta+Ctrl+Space"),
            shortcutShowAllSpan: KWin.readConfig("shortcutShowAllSpan", "Ctrl+Space"),
            shortcutVisibility: KWin.readConfig("shortcutVisibility", "Meta+Space"),
            shortcutInputType: KWin.readConfig("shortcutInputType", "Ctrl+Alt+I"),
            shortcutCenterInTile: KWin.readConfig("shortcutCenterInTile", "Meta+Ctrl+C"),
            shortcutMoveOnDrop: KWin.readConfig("shortcutMoveOnDrop", "Meta+Ctrl+V"),
            hintChangeMode: KWin.readConfig("hintChangeMode", true),
            hintShowAllSpan: KWin.readConfig("hintShowAllSpan", true),
            hintVisibility: KWin.readConfig("hintVisibility", true),
            hintInputType: KWin.readConfig("hintInputType", true),
            hintCenterInTile: KWin.readConfig("hintCenterInTile", true),
            hintMoveOnDrop: KWin.readConfig("hintMoveOnDrop", true),
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
        setDefaultMoveToVirtualDesktop();
        updateVirtualDesktops();

        autoTiler.loadAutoTilerConfig();
        autoTiler.updateLayoutMapping();
        autoTiler.initAll();
    }

    function setDefaultTiler() {
        currentTiler = config.usePopupTilerByDefault ? popupTiler : overlayTiler;
    }

    function setDefaultCenterInTile() {
        centerInTile = config.centerInTileMode > 1;
    }

    function setDefaultMoveToVirtualDesktop() {
        moveToVirtualDesktopOnDrop = !config.moveBackOnDrop;
        moveToVirtualDesktopOnTile = !config.moveBackOnTile;
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

    function convertAutoTilerLayouts(userLayouts, defaultLayouts) {
        var layoutArray = userLayouts.split('\n');
        let convertedLayouts = [];

        if (layoutArray.length == 0) {
            layoutArray = defaultLayouts.split('\n');
        }

        logE('Converting ' + layoutArray.length + ' auto tiler layouts.');

        let config = {};
        let firstAutoTileIndex = 0;
        if (layoutArray.length > 0 && layoutArray[0].startsWith('{') && layoutArray[0].endsWith('}')) {
            config = JSON.parse(layoutArray[0]);
            firstAutoTileIndex = 1;
        }

        if (config.tileTextMode === undefined) {
            config.tileTextMode = 0;
        }

        for (let layoutIndex = firstAutoTileIndex; layoutIndex < layoutArray.length; layoutIndex++) {
            let convertedLayout = convertLayout(layoutArray[layoutIndex], true, layoutIndex + 1 - firstAutoTileIndex, config.tileTextMode);
            if (convertedLayout != null) {
                if (useAutoTilerPreview) {
                    // For generating previews
                    convertedLayout.clip = true;
                }
                convertedLayouts.push(convertedLayout);
                if (convertedLayout.firstIndex < 0) {
                    config.carousel = true;
                }
            }
        }
        return { layouts: convertedLayouts, config: config };
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

    function convertLayout(userLayout, isAutoTile = false, autoTileNumber = 0, tileTextMode = 0) {
        var hasDefault = false;
        var hasLayout = false;
        var hasName = false;
        var isValid = false;
        var name = "Default";

        let layout = { tiles: [] };

        let isValidAutoTile = true;
        let autoTileArray = isAutoTile ? Array.from({ length: autoTileNumber }, () => NaN) : [];
        let autoTileArrayPositive = isAutoTile ? Array.from({ length: autoTileNumber }, () => -1) : [];
        let autoTileArrayNegative = isAutoTile ? Array.from({ length: autoTileNumber }, () => -1) : [];
        let currentAutoTileHint = '';

        const anchorValue = {
            left: "0",
            top: "0",
            center: "50",
            right: "100",
            bottom: "100"
        };

        let sections = userLayout.split(';');
        for (let sectionIndex = 0; sectionIndex < sections.length; sectionIndex++) {
            if (sections[sectionIndex] == 'clip') {
                layout.clip = true;
            } else if (sections[sectionIndex].startsWith('d') && !hasDefault) {
                hasDefault = true;
            } else if (!hasLayout) {
                let tiles = sections[sectionIndex].replace(/\s+/g, '').split('+');
                if (tiles.length == 1 && tiles[0].length > 0) {
                    name = tiles[0];
                }
                for (let tileIndex = 0; tileIndex < tiles.length; tileIndex++) {
                    let coordinates = tiles[tileIndex].split(',');
                    if (isAutoTile) {
                        if (coordinates[0].indexOf(':') > 0 && (coordinates.length == 4 || coordinates.length == 6)) {
                            let autoTileIndex = coordinates[0].split(':');
                            coordinates[0] = autoTileIndex[1];
                            log('Auto tile index: ' + autoTileIndex[0] + ' Coordinates: ' + JSON.stringify(coordinates));
                            if (autoTileIndex[0] == '*') {
                                log('* - found');
                                autoTileArray[tileIndex] = '*';
                                currentAutoTileHint = '*';
                            } else {
                                let autoTileIndexConverted = parseInt(autoTileIndex[0]);
                                log('Converted index: ' + autoTileIndexConverted);
                                if (autoTileIndexConverted < 0) {
                                    autoTileArray[tileIndex] = autoTileIndexConverted;
                                    switch (tileTextMode) {
                                        case 0:
                                        case 1:
                                            currentAutoTileHint = '' + autoTileIndexConverted;
                                            break;
                                        case 2:
                                            currentAutoTileHint = '';
                                            break;
                                    }
                                    autoTileIndexConverted = autoTileNumber + autoTileIndexConverted;
                                    log('Negative index: ' + autoTileIndexConverted);
                                    if (autoTileIndexConverted < autoTileNumber) {
                                        autoTileArrayNegative[autoTileIndexConverted] = tileIndex;
                                    } else {
                                        logE('INVALID 1!');
                                        isValidAutoTile = false;
                                    }
                                } else if (autoTileIndexConverted >= 0 && autoTileIndexConverted < autoTileNumber) {
                                    autoTileArray[tileIndex] = autoTileIndexConverted;
                                    switch (tileTextMode) {
                                        case 0:
                                            currentAutoTileHint = '' + (autoTileIndexConverted + 1);
                                            break;
                                        case 1:
                                            currentAutoTileHint = '' + autoTileIndexConverted;
                                            break;
                                        case 2:
                                            if (autoTileIndexConverted == 0) {
                                                currentAutoTileHint = 'P';
                                            } else {
                                                currentAutoTileHint = '';
                                            }
                                            break;
                                    }
                                    autoTileArrayPositive[autoTileIndexConverted] = tileIndex;
                                } else {
                                    logE('INVALID 2!');
                                    isValidAutoTile = false;
                                }
                            }
                        } else {
                            logE('INVALID 3!');
                            isValidAutoTile = false;
                        }
                    }

                    if (isValidAutoTile) {
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
                                    case 'SPECIAL_AUTO_TILER_TOGGLE':
                                        layout.tiles.push({x: 0, y: 0, w: 100, h: 100, t: "TOGGLE<br>AUTO TILE", hint: "Toggle auto tile"});
                                        layout.special = 'SPECIAL_AUTO_TILER_TOGGLE';
                                        isValid = true;
                                        break;
                                    case 'SPECIAL_AUTO_TILER_1':
                                        layout.special = 'SPECIAL_AUTO_TILER_1';
                                        isValid = true;
                                        break;
                                    case 'SPECIAL_AUTO_TILER_2':
                                        layout.special = 'SPECIAL_AUTO_TILER_2';
                                        isValid = true;
                                        break;
                                    case 'SPECIAL_AUTO_TILER_3':
                                        layout.special = 'SPECIAL_AUTO_TILER_3';
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
                                x = parseFloat(coordinates[0]);
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
                                y = parseFloat(coordinates[1]);
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
                                w = parseFloat(coordinates[2]);
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
                                h = parseFloat(coordinates[3]);
                                if (Number.isNaN(h)) {
                                    isValid = false;
                                }
                            }

                            if (coordinates.length == 6) {
                                let numericAX = coordinates[4].replace(/\b(?:left|center|right)\b/gi, value => anchorValue[value.toLowerCase()]);
                                aX = parseFloat(numericAX);
                                if (Number.isNaN(aX)) {
                                    isValid = false;
                                }

                                let numericAY = coordinates[5].replace(/\b(?:top|center|bottom)\b/gi, value => anchorValue[value.toLowerCase()]);
                                aY = parseFloat(numericAY);
                                if (Number.isNaN(aY)) {
                                    isValid = false;
                                }
                            }

                            if (isValid) {
                                layout.tiles.push({x: x, pxX: pxX, y: y, pxY: pxY, w: w, pxW: pxW, h: h, pxH: pxH, aX: aX, aY: aY, t: (isAutoTile ? currentAutoTileHint : undefined)});
                            } else {
                                logE('Invalid user layout: ' + tiles[tileIndex]);
                            }
                        } else {
                            logE('Invalid user layout: ' + tiles[tileIndex]);
                        }
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
        if (isAutoTile) {
            let negativeCount = 0;
            let positiveCount = 0;
            for (let i = autoTileNumber - 1; i >= 0; i--) {
                if (autoTileArrayNegative[i] != -1) {
                    negativeCount++;
                } else {
                    break;
                }
            }
            for (let i = 0; i < autoTileNumber; i++) {
                if (autoTileArrayPositive[i] != -1) {
                    positiveCount++;
                } else {
                    break;
                }
            }
            log('negativeCount: ' + negativeCount + ' positiveCount: ' + positiveCount + ' autoTileNumber: ' + autoTileNumber);
            if (positiveCount < 1 || negativeCount + positiveCount != autoTileNumber) {
                log('INVALID 5!');
                isValidAutoTile = false;
            } else {
                layout.firstIndex = negativeCount > 0 ? negativeCount * -1 : 0;
                layout.autoMapping = [];

                // if (negativeCount > 0) {
                //     for (let i = autoTileNumber - negativeCount; i < autoTileNumber; i++) {
                //         layout.autoMapping.push(autoTileArrayNegative[i]);
                //     }
                // }
                // for (let i = 0; i < positiveCount; i++) {
                //     layout.autoMapping.push(autoTileArrayPositive[i]);
                // }

                layout.autoMapping = [...autoTileArray];

                log('Negative: ' + JSON.stringify(autoTileArrayNegative));
                log('Positive: ' + JSON.stringify(autoTileArrayPositive));
                log('layout: ' + JSON.stringify(layout));
            }
        }
        if (!isValidAutoTile) {
            logE('Not a valid auto-tile');
            validAutoTilerPreview = false;
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
        if (!config.allowTransient && client.transient) return false;

        return true;
    }

    function addWindow(client) {
        if (!isValidWindow(client)) return;
        log('Adding window: ' + client.resourceClass);

        autoTiler.windowAdded(client);

        client.closed.connect(onClosed);
        client.interactiveMoveResizeStarted.connect(onInteractiveMoveResizeStarted);
        client.interactiveMoveResizeStepped.connect(onInteractiveMoveResizeStepped);
        client.interactiveMoveResizeFinished.connect(onInteractiveMoveResizeFinished);

        function onClosed() {
            autoTiler.windowClosed(client);
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
                if ((config.restoreSize || autoTiler.configAutoTileRestoreSize) && client.mt_originalSize) {
                    client.frameGeometry = Qt.rect(getCursorPosition().x - client.mt_originalSize.xOffset, client.frameGeometry.y, client.mt_originalSize.width, client.mt_originalSize.height);
                    delete client.mt_originalSize;
                }
                positionAtMoveStart = {x: client.x, y: client.y};
                virtualDesktopAtMoveStart = Workspace.currentDesktop;
                virtualDesktopIndexAtMoveStart = Workspace.desktops.indexOf(virtualDesktopAtMoveStart);
                virtualDesktopChangedSinceMoveStart = false;
                moving = true;
                currentlyMovedWindow = client;
                showTiler(true);
                if (config.tilerVisibility == 1 || config.tilerVisibility == 4) {
                    autoHideTimer.startAutoHideTimer();
                }
            } else if (client.resize) {
                resizing = true;
                if (client.mt_originalSize) {
                    delete client.mt_originalSize;
                }
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
            } else if (resizing) {
                if (!resized) {
                    resized = true;
                }
            }
        }

        function onInteractiveMoveResizeFinished() {
            if (moving && !useMouseCursor) {
                windowCursor = Qt.point(client.x + client.width / 2, client.y);
            }
            if (resized) {
                autoTiler.windowResized(client);
            } else if (currentTiler.visible) {
                if (moved) {
                    let moveHandledByAutoTiler = false;
                    var activeVirtualDesktopIndex = currentTiler.getActiveVirtualDesktopIndex();
                    if (activeVirtualDesktopIndex != -1) {
                        let desktop;
                        autoTiler.virtualDesktopAboutToChange(); // Notify to remove window from current virtual desktop auto-tiler
                        if (virtualDesktops[activeVirtualDesktopIndex].isAdd) {
                            Workspace.createDesktop(Workspace.desktops.length, "");
                            desktop = Workspace.desktops[Workspace.desktops.length - 1];
                        } else {
                            desktop = virtualDesktops[activeVirtualDesktopIndex].desktop;
                        }
                        client.desktops = [virtualDesktops[activeVirtualDesktopIndex].desktop];
                        switch (config.virtualDesktopDropAction) {
                            case 0:
                                client.frameGeometry = Qt.rect(positionAtMoveStart.x, positionAtMoveStart.y, client.width, client.height);
                                if (moveToVirtualDesktopOnDrop) {
                                    Workspace.currentDesktop = desktop;
                                } else {
                                    Workspace.currentDesktop = virtualDesktopAtMoveStart;
                                }
                                break;
                            case 1:
                                Workspace.activeWindow = client;
                                Workspace.slotWindowMaximize();
                                if (!moveToVirtualDesktopOnDrop) {
                                    Workspace.currentDesktop = virtualDesktopAtMoveStart;
                                }
                                break;
                        }

                        setCurrentVirtualDesktop();
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
                                case 'SPECIAL_AUTO_TILER_TOGGLE':
                                    autoTiler.toggleAutoTile(client);
                                    moveHandledByAutoTiler = true;
                                    break;
                                case 'SPECIAL_AUTO_TILER_1':
                                    autoTiler.windowDropped(client, geometry.specialMode, 0);
                                    moveHandledByAutoTiler = true;
                                    break;
                                case 'SPECIAL_AUTO_TILER_2':
                                    autoTiler.windowDropped(client, geometry.specialMode, 1);
                                    moveHandledByAutoTiler = true;
                                    break;
                                case 'SPECIAL_AUTO_TILER_3':
                                    autoTiler.windowDropped(client, geometry.specialMode, 2);
                                    moveHandledByAutoTiler = true;
                                    break;
                                default:
                                    addMargins(geometry, true, true, true, true);
                                    moveAndResizeWindow(client, geometry);
                                    break;
                            }
                            if (virtualDesktopChangedSinceMoveStart && !moveToVirtualDesktopOnTile) {
                                Workspace.currentDesktop = virtualDesktopAtMoveStart;
                                setCurrentVirtualDesktop();
                            }
                        }
                    }

                    if (!moveHandledByAutoTiler) {
                        autoTiler.windowMoved(client);
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
                setDefaultMoveToVirtualDesktop();

                removeEmptyVirtualDesktops();
            } else if (moved) {
                autoTiler.windowMoved(client);
            }
            moving = false;
            moved = false;
            resizing = false;
            resized = false;
            currentlyMovedWindow.opacity = 1;
            currentlyMovedWindow = null;
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
        virtualDesktopChangedSinceMoveStart = Workspace.currentDesktop != virtualDesktopAtMoveStart;
        autoTiler.updateAutoTilersInPopupTiler();
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

                if (config.tilerVisibility == 4) {
                    internalHideTiler();
                }
            }
        }

        function internalHideTiler() {
            hideTiler();
            if (!config.rememberTiler) {
                setDefaultTiler();
            }
            if (!config.rememberCenterInTile) {
                setDefaultCenterInTile();
            }
            setDefaultMoveToVirtualDesktop();
        }

        function onTimeoutTriggered() {
            log('Auto-hiding tiler');
            autoHideTimer.triggered.disconnect(onTimeoutTriggered);
            timerIsRunning = false;
            autoHideTimer.stop();

            if (config.tilerVisibility == 1) {
                internalHideTiler();
            }
        }
    }

    Timer {
        id: autoTileTimer

        property var timeoutIsRunning: false
        property var timeoutData: []

        function setTimeout(delay, window) {
            logE('Setting timeout for ' + delay + ' isRunning: ' + timeoutIsRunning + ' timer count: ' + timeoutData.length + ' id: ' + window.internalId);

            if (!window) {
                return;
            // } else if (window.mt_autoRestore > 0) {
            //     let desktopBefore = Workspace.currentDesktop;
            //     autoTiler.autoTileWindowOnStart(window);
            //     Workspace.currentDesktop = desktopBefore;
            } else {
                timeoutData.push({time: Date.now() + delay, window: window});
                timeoutData.sort((a, b) => a.time - b.time);

                if (!timeoutIsRunning) {
                    autoTileTimer.interval = 250;
                    autoTileTimer.repeat = true;
                    autoTileTimer.triggered.connect(onTimeoutTriggered);
                    timeoutIsRunning = true;

                    autoTileTimer.start();
                }
            }
        }

        function removeTimeoutsFor(window) {
            for (var i = timeoutData.length - 1; i >= 0; i--) {
                if (timeoutData[i].window == window) {
                    timeoutData.splice(i, 1);
                }
            }
            if (timeoutData.length == 0 && timeoutIsRunning) {
                autoTileTimer.triggered.disconnect(onTimeoutTriggered);
                timeoutIsRunning = false;
                autoTileTimer.stop();
            }
        }

        function onTimeoutTriggered() {
            let desktopBefore = Workspace.currentDesktop;

            while (timeoutData.length > 0 && timeoutData[0].time <= Date.now()) {
                let data = timeoutData.shift();
                log('Trying to auto tile window: ' + data.window.internalId);
                autoTiler.autoTileWindowOnStart(data.window);
            }

            for (var i = timeoutData.length - 1; i >= 0; i--) {
                if (timeoutData[i].window.mt_autoRestore > 0) {
                    let data = timeoutData.splice(i, 1)[0];
                    autoTiler.autoTileWindowOnStart(data.window);
                }
            }

            Workspace.currentDesktop = desktopBefore;

            if (timeoutData.length == 0) {
                autoTileTimer.triggered.disconnect(onTimeoutTriggered);
                timeoutIsRunning = false;
                autoTileTimer.stop();
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
            autoTiler.virtualDesktopsChanged();
            updateVirtualDesktops();
        }

        function onScreensChanged() {
            autoTiler.screensChanged();
        }

        function onWindowActivated(window) {
            autoTiler.windowActivated(window);
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

        AutoTiler {
            id: autoTiler
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

    ShortcutHandler {
        name: "Mouse Tiler: Toggle Move To Previous Virtual Desktop"
        text: "Mouse Tiler: Toggle Move To Previous Virtual Desktop"
        sequence: "Meta+Ctrl+V"
        onActivated: {
            log('Toggle Move To Previous Virtual Desktop triggered!');
            moveToVirtualDesktopOnDrop = !moveToVirtualDesktopOnDrop;
            moveToVirtualDesktopOnTile = !moveToVirtualDesktopOnTile;
            if (popupTiler.visible) {
                popupTiler.updateHintContent();
            }
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Auto Tiler - Decrease Scroll Position"
        text: "Mouse Tiler: Auto Tiler - Scroll To Previous Window"
        sequence: "Ctrl+Alt+Left"
        onActivated: {
            log('Decrease Scroll Position triggered!');
            autoTiler.modifyPrimaryIndex(-1);
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Auto Tiler - Increase Scroll Position"
        text: "Mouse Tiler: Auto Tiler - Scroll To Next Window"
        sequence: "Ctrl+Alt+Right"
        onActivated: {
            log('Auto Tiler - Increase Scroll Position triggered!');
            autoTiler.modifyPrimaryIndex(1);
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Toggle Auto Tile For Active Window"
        text: "Mouse Tiler: Toggle Auto Tile For Active Window"
        sequence: "Ctrl+Alt+A"
        onActivated: {
            log('Toggle Auto Tile For Active Window triggered!');
            if (autoTiler.isValidAutoTileWindow(Workspace.activeWindow)) {
                autoTiler.toggleAutoTile(Workspace.activeWindow);
            }
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Change To Previous Auto Tiler"
        text: "Mouse Tiler: Change To Previous Auto Tiler"
        sequence: "Ctrl+Alt+X"
        onActivated: {
            log('Change To Previous Auto Tiler triggered!');
            autoTiler.changeToPreviousTiler();
        }
    }

    ShortcutHandler {
        name: "Mouse Tiler: Change To Next Auto Tiler"
        text: "Mouse Tiler: Change To Next Auto Tiler"
        sequence: "Ctrl+Alt+C"
        onActivated: {
            log('Change To Next Auto Tiler triggered!');
            autoTiler.changeToNextTiler();
        }
    }

    ScreenEdgeHandler {
        enabled: autoTiler.shouldShowLeftScreenEdge
        edge: ScreenEdgeHandler.LeftEdge
        onActivated: {
            log('LEFT Edge triggered!');
            autoTiler.modifyPrimaryIndex(-1);
        }
    }

    ScreenEdgeHandler {
        enabled: autoTiler.shouldShowRightScreenEdge
        edge: ScreenEdgeHandler.RightEdge
        onActivated: {
            log('RIGHT Edge triggered!');
            autoTiler.modifyPrimaryIndex(1);
        }
    }
}