import QtQuick
import org.kde.kwin

QtObject {
    id: autoTiler

    property bool configAutoTileNewWindows: false
    property bool configAutoTileMinimizedMaximized: true
    property bool configAutoTileRestoreSize: false
    property int configAutoTileWindowAction: 0
    property int configAutoTileWindowIndex: 0
    property int configAutoTileFocusAction: 0
    property int configAutoTileFocusIndex: 0
    property int configAutoTileMinimizedFocusAction: 0
    property int configAutoTileMinimizedFocusIndex: 0
    property int configAutoTileDragSwapAction: 0
    property int configAutoTileLayer: 0
    property int configMaxAutoTileDelay: 5
    property int configMaxAutoTileDelaySessionStart: 10
    property var configAutoTileBlacklist: []

    // Use to determine if people can auto-tile
    property bool autoTileInitialized: false

    property list<var> autoActivities: ([])
    property list<var> autoScreens: ([])
    property list<var> autoVirtualDesktops: ([])

    property var autoWindowMapping: ({})

    property var autoLayouts: ([])
    property var autoLayoutConfigs: ([])

    property var layoutMapping: ([])

    property bool ignoreActivates: false

    property bool currentWindowUnMaximized: false

    property var sessionStartTime: (Date.now())

    property bool shouldShowLeftScreenEdge: false
    property bool shouldShowRightScreenEdge: false

    property var activeWindow: Workspace.activeWindow

    function logDev(text) {
        root.logDev('AutoTiler - ' + text);
    }

    function logAutoTiler(text) {
        if (!root.debugLogs) return;
        console.warn('MouseTiler: AutoTiler - ' + text);
    }

    function isValidAutoTileWindow(window) {
        if (!window) return false;
        if (!window.normalWindow) return false;
        if (window.skipTaskbar) return false;
        if (window.popupWindow) return false;
        if (window.deleted) return false;
        if (window.transient) return false;
        if (window.desktops.length != 1) return false;
        if (configAutoTileBlacklist.includes(window.resourceClass)) return false;

        return true;
    }

    function initAll() {
        logAutoTiler('initAll');

        for (let i = 0; i < Workspace.desktops.length; i++) {
            autoVirtualDesktops.push(Workspace.desktops[i].id);
        }

        for (let i = 0; i < Workspace.screens.length; i++) {
            autoScreens.push(Workspace.screens[i].name);
            // autoWindowMapping[Workspace.screens[i].name] = {};
            for (let v = 0; v < Workspace.desktops.length; v++) {
                // autoWindowMapping[Workspace.screens[i].name][Workspace.desktops[v].id] = {
                let id = Workspace.screens[i].name + Workspace.desktops[v].id;
                autoWindowMapping[id] = {
                    windows: [],
                    geometries: [],
                    layoutIndex: 0,
                    geometryIndex: -1,
                    windowCount: 0,
                    primaryWindowIndex: 0,
                    isCarousel: false,
                    autoTilerIndex: -1,
                    id: id,
                    screenName: Workspace.screens[i].name,
                    desktopId: Workspace.desktops[v].id
                };
            }
        }

        autoTileInitialized = true;

        printCurrentInfo();
    }

    function autoTileWindowOnStart(window) {
        if (isValidAutoTileWindow(window)) {
            if (configAutoTileNewWindows || ((window.mt_autoRestore & 256) == 256)) {
                if ((window.mt_autoRestore & 128) != 128) {
                    if (window.mt_auto == undefined) {
                        let currentMapping = getMappingForWindow(window);
                        if (currentMapping.autoTilerIndex == -1) {
                            let tiler = (window.mt_autoRestore & 3);
                            logAutoTiler('autoTileWindowOnStart Restoring tiler: ' + tiler);
                            toggleAutoTile(window, tiler);
                        } else {
                            toggleAutoTile(window);
                        }
                    }
                }
            }
        }
    }

    function getMappingById(id) {
        return autoWindowMapping[id];
    }

    function getMappingForWindow(window) {
        return autoWindowMapping[window.output.name + window.desktops[0].id];
    }

    function getMappingByScreenNameAndVirtualDesktopId(screenName, virtualDesktopId) {
        return autoWindowMapping[screenName + virtualDesktopId];
    }

    function getMappingForCurrentScreenAndDesktop() {
        return autoWindowMapping[Workspace.activeScreen.name + Workspace.currentDesktop.id];
    }

    function updateAutoTilersInPopupTiler() {
        logAutoTiler('updateAutoTilersInPopupTiler 1');
        let currentScreenMapping = getMappingForCurrentScreenAndDesktop();
        let currentScreenAutoTilerIndex = currentScreenMapping.autoTilerIndex;
        let currentScreenLayoutIndex = currentScreenMapping.layoutIndex;
        let nextLayoutIndex = currentScreenMapping.windowCount;

        if (currentlyMovedWindow && currentlyMovedWindow.mt_auto == currentScreenMapping.id) {
            if (currentScreenMapping.windowCount < autoLayouts[currentScreenAutoTilerIndex].length) {
                logAutoTiler('DECREASING!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                currentScreenLayoutIndex--;
            }
            nextLayoutIndex = currentScreenLayoutIndex;
        }

        logAutoTiler('updateAutoTilersInPopupTiler 2');
        for (let i = 0; i < layoutMapping.length; i++) {
            let currentLayoutMapping = layoutMapping[i];
            logAutoTiler('updateAutoTilersInPopupTiler 2.1 ' + JSON.stringify(currentLayoutMapping));
            if (currentScreenAutoTilerIndex == -1) {
                if (currentLayoutMapping.all) {
                    popupGridAllLayouts[currentLayoutMapping.index].tiles = [{x: 0, y: 0, w: 100, h: 100, t: "START<br>AUTO TILING", hint: "Start using Auto Tiler \"<b>" + autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].name + "</b>\""}];
                    popupGridAllLayouts[currentLayoutMapping.index].activeAutoTiler = false;
                } else {
                    popupGridLayouts[currentLayoutMapping.index].tiles = [{x: 0, y: 0, w: 100, h: 100, t: "START<br>AUTO TILING", hint: "Start using Auto Tiler \"<b>" + autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].name + "</b>\""}];
                    popupGridLayouts[currentLayoutMapping.index].activeAutoTiler = false;
                }
            } else if (currentLayoutMapping.autoTilerIndex == currentScreenAutoTilerIndex) {
                logAutoTiler('updateAutoTilersInPopupTiler 2.2');
                if (currentLayoutMapping.all) {
                    popupGridAllLayouts[currentLayoutMapping.index].tiles = autoLayouts[currentLayoutMapping.autoTilerIndex][currentScreenLayoutIndex].tiles;
                    popupGridAllLayouts[currentLayoutMapping.index].clip = autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].clip;
                    popupGridAllLayouts[currentLayoutMapping.index].activeAutoTiler = true;
                } else {
                    logAutoTiler('updateAutoTilersInPopupTiler 2.4 ' + JSON.stringify(autoLayouts[currentLayoutMapping.autoTilerIndex][currentScreenLayoutIndex]) + ' ' + currentLayoutMapping.index);
                    popupGridLayouts[currentLayoutMapping.index].tiles = autoLayouts[currentLayoutMapping.autoTilerIndex][currentScreenLayoutIndex].tiles;
                    popupGridLayouts[currentLayoutMapping.index].clip = autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].clip;
                    popupGridLayouts[currentLayoutMapping.index].activeAutoTiler = true;
                }
            } else {
                logAutoTiler('updateAutoTilersInPopupTiler 2.3');
                if (currentLayoutMapping.all) {
                    // popupGridAllLayouts[currentLayoutMapping.index].tiles = autoLayouts[currentLayoutMapping.autoTilerIndex][Math.min(nextLayoutIndex, autoLayouts[currentLayoutMapping.autoTilerIndex].length - 1)].tiles;
                    popupGridAllLayouts[currentLayoutMapping.index].tiles = [{x: 0, y: 0, w: 100, h: 100, t: "SWITCH<br>AUTO TILER", hint: "Switch to Auto Tiler \"<b>" + autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].name + "</b>\""}];
                    popupGridAllLayouts[currentLayoutMapping.index].activeAutoTiler = false;
                } else {
                    // popupGridLayouts[currentLayoutMapping.index].tiles = autoLayouts[currentLayoutMapping.autoTilerIndex][Math.min(nextLayoutIndex, autoLayouts[currentLayoutMapping.autoTilerIndex].length - 1)].tiles;
                    popupGridLayouts[currentLayoutMapping.index].tiles = [{x: 0, y: 0, w: 100, h: 100, t: "SWITCH<br>AUTO TILER", hint: "Switch to Auto Tiler \"<b>" + autoLayoutConfigs[currentLayoutMapping.autoTilerIndex].name + "</b>\""}];
                    popupGridLayouts[currentLayoutMapping.index].activeAutoTiler = false;
                }
            }
        }
        logAutoTiler('updateAutoTilersInPopupTiler 3');
    }

    function updateShouldShowScreenEdges() {
        if (root.autoTilerEdgeScroll) {
            let edges = shouldShowAutoTileScroll();
            shouldShowLeftScreenEdge = edges.left;
            shouldShowRightScreenEdge = edges.right;
        } else {
            shouldShowLeftScreenEdge = false;
            shouldShowRightScreenEdge = false;
        }
    }

    function shouldShowAutoTileScroll() {
        let currentMapping = getMappingForCurrentScreenAndDesktop();
        if (currentMapping.autoTilerIndex == -1) return {left: false, right: false};
        if (currentMapping.windows.length < 2) return {left: false, right: false};
        if (currentMapping.isCarousel) return {left: true, right: true};
        if (currentMapping.windows.length > autoLayouts[currentMapping.autoTilerIndex].length) {
            let left = false;
            let right = false;
            if (currentMapping.primaryWindowIndex > 0) {
                left = true;
            }
            let maxLength = autoLayouts[currentMapping.autoTilerIndex][Math.min(currentMapping.windowCount - 1, currentMapping.layoutIndex)].tiles.length;
            if (currentMapping.primaryWindowIndex < currentMapping.windowCount - maxLength) {
                right = true;
            }

            return {left: left, right: right};
        }
        return {left: false, right: false};
    }

    function windowActivated(window) {
        if (!window) return;
        let previousWindow = activeWindow;
        activeWindow = window;
        if (ignoreActivates) return;
        logAutoTiler('Window activated: ' + window.caption);

        let scrollToActivated = false;
        let swapWithActivated = false;

        if (window.mt_auto) {
            logAutoTiler('windowActivated 1');
            let currentMapping = getMappingById(window.mt_auto);
            let index = currentMapping.windows.indexOf(window);
            logAutoTiler('windowActivated 2 index: ' + index);
            if (index >= 0) {
                if (window.mt_minimized) {
                    let offset = Math.min(autoLayoutConfigs[currentMapping.autoTilerIndex].minimizedFocusIndex, currentMapping.windowCount - 1);
                    let replaceIndex = currentMapping.primaryWindowIndex + offset;
                    if (replaceIndex < 0) {
                        replaceIndex += currentMapping.windowCount;
                    } else if (replaceIndex >= currentMapping.windowCount) {
                        replaceIndex -= currentMapping.windowCount;
                    }
                    switch (autoLayoutConfigs[currentMapping.autoTilerIndex].minimizedFocusAction) {
                        default:
                        case 0: // scroll as close as possible
                            modifyPrimaryIndex(index - currentMapping.primaryWindowIndex, currentMapping);
                            break;
                        case 1: // insert before window at index
                            internalMoveBeforeTile(window, replaceIndex);
                            break;
                        case 2: // swap place with window at index
                            internalSwapTwoTiles(window, replaceIndex, false, currentMapping);
                            break;
                    }
                } else {
                    let offset = Math.min(autoLayoutConfigs[currentMapping.autoTilerIndex].focusIndex, currentMapping.windowCount - 1);
                    let replaceIndex = currentMapping.primaryWindowIndex + offset;
                    if (replaceIndex < 0) {
                        replaceIndex += currentMapping.windowCount;
                    } else if (replaceIndex >= currentMapping.windowCount) {
                        replaceIndex -= currentMapping.windowCount;
                    }
                    switch (autoLayoutConfigs[currentMapping.autoTilerIndex].focusAction) {
                        case 0: // scroll to focused
                            modifyPrimaryIndex(index - currentMapping.primaryWindowIndex, currentMapping);
                            internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            break;
                        case 1: // insert focused window at index
                            internalMoveToTile(window, replaceIndex);
                            internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            break;
                        case 2: // insert focused window at index - ignore primary
                            if (index != currentMapping.primaryWindowIndex) {
                                internalMoveToTile(window, replaceIndex);
                                internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            }
                            break;
                        case 3: // swap place with window at index
                            internalSwapTwoTiles(window, replaceIndex, false, currentMapping);
                            internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            break;
                        case 4: // swap place with window at index - ignore primary
                            if (index != currentMapping.primaryWindowIndex) {
                                internalSwapTwoTiles(window, replaceIndex, false, currentMapping);
                                internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            }
                            break;
                        case 5: // do nothing
                            internalSetActiveWindow(window, currentMapping.autoTilerIndex);
                            break;
                    }
                }
            }
        }
        delete window.mt_minimized;

        if (Workspace.activeWindow != previousWindow && previousWindow != null) {
            if (previousWindow.mt_auto) {
                let previousMapping = getMappingById(previousWindow.mt_auto);
                if (previousMapping.autoTilerIndex != -1) {
                    if (!previousWindow.keepBelow) {
                        internalUpdateLayer(previousWindow, previousMapping.autoTilerIndex, false);
                    }
                }
            }
        }

        printCurrentInfo();
    }

    function internalUpdateGeometries(mapping, newWindow = false) {
        logAutoTiler('update geo 1');
        let currentScreenLayoutIndex = mapping.layoutIndex;
        let wantedGeometryIndex = Math.max(Math.min((newWindow ? mapping.windowCount : mapping.windowCount - 1), mapping.layoutIndex), 0);
        logAutoTiler('update geo 2 currentScreenLayoutIndex: ' + currentScreenLayoutIndex + ' mapping.geometryIndex: ' + mapping.geometryIndex + ' wantedGeometryIndex: ' + wantedGeometryIndex);
        if (wantedGeometryIndex != mapping.geometryIndex) {
            mapping.geometries = [];
            let currentScreenAutoTilerIndex = mapping.autoTilerIndex;
            if (currentScreenAutoTilerIndex < 0) {
                return;
            }
            logAutoTiler('update geo 3 ' + currentScreenAutoTilerIndex);

            let screenIndex = Workspace.screens.findIndex(screen => screen.name == mapping.screenName);
            let desktopIndex = Workspace.desktops.findIndex(desktop => desktop.id == mapping.desktopId);
            logAutoTiler('update geo 4 ' + screenIndex + ' ' + desktopIndex);

            if (screenIndex != -1 && desktopIndex != -1) {
                logAutoTiler('update geo 4.1');
                let clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.screens[screenIndex], Workspace.desktops[desktopIndex]);
                logAutoTiler('update geo 4.2 ' + wantedGeometryIndex);
                let tiles = autoLayouts[currentScreenAutoTilerIndex][wantedGeometryIndex].tiles;
                logAutoTiler('update geo 5');
                
                for (let i = 0; i < tiles.length; i++) {
                    let tile = tiles[i];
                    let width = tile.w == undefined ? tile.pxW : tile.w / 100 * clientArea.width;
                    let height = tile.h == undefined ? tile.pxH : tile.h / 100 * clientArea.height;
                    let x = (tile.x == undefined ? tile.pxX : tile.x / 100 * clientArea.width) - (tile.aX == undefined ? 0 : tile.aX * width / 100);
                    let y = (tile.y == undefined ? tile.pxY : tile.y / 100 * clientArea.height) - (tile.aY == undefined ? 0 : tile.aY * height / 100);
                    mapping.geometries.push({
                        x: clientArea.x + x,
                        y: clientArea.y + y,
                        width: width,
                        height: height
                    });
                }
                logAutoTiler('update geo 6');
                mapping.geometryIndex = wantedGeometryIndex;
            } else {
                logAutoTiler('update geo 7');
                mapping.geometryIndex = -1;
            }
            logAutoTiler('update geo 8');
        }
        logAutoTiler('update geo 9');
    }

    function modifyPrimaryIndex(offset, forcedMapping = null) {
        let currentMapping = forcedMapping || getMappingForCurrentScreenAndDesktop();
        if (currentMapping.windowCount > 0) {
            let primaryWindowIndexBefore = currentMapping.primaryWindowIndex;
            currentMapping.primaryWindowIndex += offset;
            if (currentMapping.isCarousel) {
                if (currentMapping.primaryWindowIndex < 0) {
                    currentMapping.primaryWindowIndex += currentMapping.windowCount;
                } else if (currentMapping.primaryWindowIndex >= currentMapping.windowCount) {
                    currentMapping.primaryWindowIndex -= currentMapping.windowCount;
                }
            } else {
                let maxLength = autoLayouts[currentMapping.autoTilerIndex][Math.min(currentMapping.windowCount - 1, currentMapping.layoutIndex)].tiles.length;
                if (currentMapping.primaryWindowIndex < 0) {
                    currentMapping.primaryWindowIndex = 0;
                } else if (currentMapping.primaryWindowIndex > currentMapping.windowCount - maxLength) {
                    currentMapping.primaryWindowIndex = currentMapping.windowCount - maxLength;
                }
            }
            if (currentMapping.primaryWindowIndex != primaryWindowIndexBefore) {
                updateShouldShowScreenEdges();
                internalRetileAll(currentMapping);
            }
            logAutoTiler('modifyPrimaryIndex: ' + currentMapping.primaryWindowIndex);
        }

        printCurrentInfo();
    }

    function shiftAllTilesUp() {
    }

    function shiftAllTilesDown() {
    }
    
    function internalScrollAllTilesUp(mappingId, startIndex, scrollLength) {

    }

    function internalScrollAllTilesDown(mappingId, startIndex, scrollLength) {

    }

    function internalDisableAutoTiling(window) {
        logAutoTiler('### Disable 1');
        if (window.mt_auto) {
            let previousWindow = Workspace.activeWindow;
            let currentMapping = getMappingById(window.mt_auto);
            logAutoTiler('### Disable 2');
            let index = currentMapping.windows.indexOf(window);
            delete window.mt_auto;
            if (index >= 0) {
                currentMapping.windows.splice(index, 1);
                currentMapping.windowCount--;
                if (currentMapping.primaryWindowIndex > index) {
                    currentMapping.primaryWindowIndex--;
                }
                currentMapping.layoutIndex = Math.max(Math.min(currentMapping.windowCount, autoLayouts[currentMapping.autoTilerIndex].length - 1), 0);
                logAutoTiler('### Disable 3 ' + currentMapping.layoutIndex + ' ' + currentMapping.windowCount);
                if (currentMapping.windowCount > 0) {
                    internalRetileAll(currentMapping);
                }
                if (currentMapping.windowCount == 0) {
                    currentMapping.autoTilerIndex = -1;
                }
                updateShouldShowScreenEdges();
            }
            logAutoTiler('### Disable 4');
            window.keepBelow = false;
            window.keepAbove = false;
            // TODO: Remove it from the auto-tiling

            if (previousWindow != null && !previousWindow.minimized) {
                logAutoTiler('### Disable 4.1');
                ignoreActivates = true;
                if (previousWindow.my_auto) {
                    let previousMapping = getMappingById(previousWindow.mt_auto);
                    internalUpdateLayer(window, previousMapping.autoTilerIndex, true);
                }
                Workspace.activeWindow = previousWindow;
                ignoreActivates = false;
            }

            if (configAutoTileNewWindows) {
                window.mt_autoRestore = 128;
            } else {
                delete window.mt_autoRestore;
            }
        }
        logAutoTiler('### Disable 5');
    }

    function printCurrentInfo() {
        logAutoTiler('##########################################################');
        let currentMapping = getMappingForCurrentScreenAndDesktop();
        logAutoTiler('Tiler: ' + currentMapping.autoTilerIndex + ' windowCount: ' + currentMapping.windowCount + '(' + currentMapping.windows.length + ') isCarousel: ' + currentMapping.isCarousel);
        logAutoTiler('primaryWindowIndex: ' + currentMapping.primaryWindowIndex + ' geometryIndex: ' + currentMapping.geometryIndex + ' geometries #: ' + currentMapping.geometries.length);
        if (Workspace.activeWindow != null) {
            logAutoTiler('Current window auto-tiled: ' + Workspace.activeWindow.mt_auto  + ' autoRestore: ' + Workspace.activeWindow.mt_autoRestore);
            logAutoTiler('Current window id: ' + Workspace.activeWindow.internalId);
        }
        for (let i = 0; i < currentMapping.windows.length; i++) {
            logAutoTiler('Window #' + i + ': ' + currentMapping.windows[i].internalId);
        }
        logAutoTiler('##########################################################');
    }

    function virtualDesktopAboutToChange() {
        if (root.currentlyMovedWindow != null && root.currentlyMovedWindow.mt_auto) {
            internalDisableAutoTiling(root.currentlyMovedWindow);
        }
    }

    function internalRetileAll(mapping) {
        internalUpdateGeometries(mapping, false);
        if (mapping.autoTilerIndex < 0) {
            return;
        }
        let previousWindow = Workspace.activeWindow;
        let updateLayerKeepBelow = autoLayoutConfigs[mapping.autoTilerIndex].layer == 0;
        let layout = autoLayouts[mapping.autoTilerIndex][mapping.geometryIndex];
        logAutoTiler('LAYOUT: ' + JSON.stringify(layout));
        let isVisible = Array.from({ length: mapping.windowCount }, () => false);
        let currentVirtualDesktop = Workspace.currentDesktop;
        // if (mapping.desktopId != currentVirtualDesktop.id) {
        //     let desktopIndex = Workspace.desktops.findIndex(desktop => desktop.id == mapping.desktopId);
        //     if (desktopIndex != -1) {
        //         Workspace.currentDesktop = Workspace.desktops[desktopIndex];
        //     }
        // }

        let sorted = Array.from({ length: mapping.windowCount }, () => null);
        for (let i = 0; i < layout.autoMapping.length; i++) {
            let windowIndex = layout.autoMapping[i];
            if (windowIndex == '*') {
                // Fixed tile
                continue;
            }
            logAutoTiler('RETILE 1 ' + i);
            logAutoTiler('RETILE 2 ' + mapping.windows.length);
            windowIndex += mapping.primaryWindowIndex;
            if (windowIndex < 0) {
                windowIndex += mapping.windows.length;
            } else if (windowIndex >= mapping.windows.length) {
                windowIndex -= mapping.windows.length;
            }

            let sortedIndex = windowIndex - mapping.primaryWindowIndex;
            if (sortedIndex < 0) {
                sortedIndex += mapping.windows.length;
            }

            let geometry = JSON.parse(JSON.stringify(mapping.geometries[i]));
            logAutoTiler('RETILE 2.0 geometry: ' + JSON.stringify(geometry));
            root.addMargins(geometry, true, true, true, true);
            logAutoTiler('RETILE -- index: ' + i + ' windowIndex: ' + windowIndex);

            logAutoTiler('RETILE ## l: ' + mapping.windows.length + ' p: ' + mapping.primaryWindowIndex + ' w: ' + windowIndex + ' i: ' + sortedIndex);
            sorted[sortedIndex] = {index: windowIndex, geometry: geometry};
        }

        ignoreActivates = true;
        for (let i = sorted.length - 1; i >= 0; i--) {
        // for (let i = 0; i < sorted.length; i++) {
            let data = sorted[i];
            if (data == null) {
                continue;
            }
            let windowIndex = data.index;
            logAutoTiler('i: ' + i + ' w: ' + windowIndex);
            logAutoTiler('RETILE 2.1 - width before: ' + mapping.windows[windowIndex].width);
            root.moveAndResizeWindow(mapping.windows[windowIndex], data.geometry);
            logAutoTiler('RETILE 2.2 - width after: ' + mapping.windows[windowIndex].width);
            isVisible[windowIndex] = true;
            if (updateLayerKeepBelow) {
                mapping.windows[windowIndex].keepBelow = true;
            }
            if (mapping.windows[windowIndex].minimized) {
                mapping.windows[windowIndex].minimized = false;
                delete mapping.windows[windowIndex].mt_minimized
            }
            if (config.sortZ) {
                Workspace.activeWindow = mapping.windows[windowIndex];
            }
        }

        if (!config.sortZ) {
            for (let i = 0; i < layout.autoMapping.length; i++) {
                let windowIndex = layout.autoMapping[i];
                if (windowIndex == '*') {
                    // Fixed tile
                    continue;
                }
                windowIndex += mapping.primaryWindowIndex;
                if (windowIndex < 0) {
                    windowIndex += mapping.windows.length;
                } else if (windowIndex >= mapping.windows.length) {
                    windowIndex -= mapping.windows.length;
                }
                Workspace.activeWindow = mapping.windows[windowIndex];
            }
        }

        logAutoTiler('RETILE 3 ' + JSON.stringify(isVisible));
        for (let i = 0; i < mapping.windowCount; i++) {
            if (!isVisible[i]) {
                logAutoTiler('RETILE 4 id: ' + mapping.windows[i].internalId);
                mapping.windows[i].mt_minimized = true;
                mapping.windows[i].minimized = true;
            }
        }

        if (previousWindow != null && previousWindow.mt_auto && mapping.id == previousWindow.mt_auto) {
        //     // Window is already updated
        //     if (updateLayerKeepBelow) {
        //         Workspace.activeWindow.keepBelow = false;
        //     }
            if (!previousWindow.minimized && internalIsFullyOnScreen(previousWindow, mapping)) {
                Workspace.activeWindow = previousWindow;
                Workspace.activeWindow.keepBelow = false;
            } else {
                Workspace.activeWindow = mapping.windows[mapping.primaryWindowIndex];
                Workspace.activeWindow.keepBelow = false;
            }
        } else {
            Workspace.activeWindow = previousWindow;
        }

        ignoreActivates = false;
        // if (currentVirtualDesktop.id != Workspace.currentDesktop.id) {
        //     Workspace.currentDesktop = currentVirtualDesktop;
        // }
    }

    function internalIsFullyOnScreen(window, mapping) {
        let screenIndex = Workspace.screens.findIndex(screen => screen.name == mapping.screenName);
        let desktopIndex = Workspace.desktops.findIndex(desktop => desktop.id == mapping.desktopId);

        if (screenIndex != -1 && desktopIndex != -1) {
            let clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.screens[screenIndex], Workspace.desktops[desktopIndex]);
            return (window.frameGeometry.left + 0.01 > clientArea.left && window.frameGeometry.right - 0.01 < clientArea.right && window.frameGeometry.top + 0.01 > clientArea.top && window.frameGeometry.bottom - 0.01 < clientArea.bottom);
        }
        return false;
    }

    function internalInsertNewWindow(window, index, lookUpIndex = false, tiler = -1, forcedMapping = null) {
        if (isValidAutoTileWindow(window)) {
            let currentMapping = forcedMapping || getMappingForCurrentScreenAndDesktop();
            logAutoTiler('INSERT Window mapping: ' + getMappingForWindow(window).id);
            logAutoTiler('INSERT Screen mapping: ' + getMappingForCurrentScreenAndDesktop().id);
            logAutoTiler('INSERT Forced mapping: ' + (forcedMapping ? forcedMapping.id : forcedMapping));
            logAutoTiler('INSERT 1.0 insert index: ' + index + ' tiler: ' + tiler + ' currentMapping.autoTilerIndex: ' + currentMapping.autoTilerIndex + ' lookUpIndex: ' + lookUpIndex);
            if (currentMapping.autoTilerIndex == -1 && index == 0) {
                lookUpIndex = false;
            }
            if (tiler != -1 && currentMapping.autoTilerIndex != tiler) {
                currentMapping.autoTilerIndex = tiler;
                currentMapping.isCarousel = autoLayoutConfigs[currentMapping.autoTilerIndex].carousel == true;
                currentMapping.geometryIndex = -1;
            } else if (currentMapping.autoTilerIndex == -1) {
                currentMapping.autoTilerIndex = 0; // Set default auto-tiler
                currentMapping.isCarousel = autoLayoutConfigs[currentMapping.autoTilerIndex].carousel == true;
                currentMapping.geometryIndex = -1;
            }
            if (lookUpIndex) {
                let geometryIndex = index;
                logAutoTiler('INSERT Z -- geometryIndex: ' + geometryIndex + ' ' + currentMapping.autoTilerIndex + ' ' + currentMapping.layoutIndex + ' ' + index + ' -- ' + JSON.stringify(autoLayouts[currentMapping.autoTilerIndex]));
                index = autoLayouts[currentMapping.autoTilerIndex][currentMapping.layoutIndex].autoMapping[index];
                logAutoTiler('INSERT Z --- ' + index);
                if (index == '*') {
                    internalUpdateGeometries(currentMapping, true);
                    logAutoTiler('INSERT Z ---- currentMapping.geometries: ' + currentMapping.geometries.length + ' wanted: ' + geometryIndex);
                    let geometry = JSON.parse(JSON.stringify(currentMapping.geometries[geometryIndex]));
                    root.addMargins(geometry, true, true, true, true);
                    root.moveAndResizeWindow(window, geometry);
                    return;
                }
                logAutoTiler('INSERT Z index: ' + index);
                if (index < 0) {
                    index += currentMapping.windows.length + 1;
                    logAutoTiler('INSERT Z index next: ' + index);
                }
            }
            index += currentMapping.primaryWindowIndex;
            logAutoTiler('INSERT Z index again: ' + index + ' primary: ' + currentMapping.primaryWindowIndex);
            if (index > currentMapping.windows.length) {
                index -= currentMapping.windows.length;
            }

            // if (index <= currentMapping.primaryWindowIndex && currentMapping.primaryWindowIndex > 0) {
            //      currentMapping.primaryWindowIndex++;
            // }
            logAutoTiler('INSERT 1.1 insert index: ' + index + ' tiler: ' + currentMapping.autoTilerIndex);
            window.mt_auto = currentMapping.id;
            window.mt_autoRestore = 256 + currentMapping.autoTilerIndex;
            // currentMapping.windows.unshift(window);
            currentMapping.windows.splice(Math.min(index, currentMapping.windowCount), 0, window);
            currentMapping.windowCount++;
            logAutoTiler('INSERT 2');
            currentMapping.layoutIndex = Math.min(currentMapping.windowCount, autoLayouts[currentMapping.autoTilerIndex].length - 1);
            logAutoTiler('INSERT NEW index: ' + currentMapping.layoutIndex + ' ' + currentMapping.autoTilerIndex + ' ' + autoLayouts[currentMapping.autoTilerIndex].length);

            updateShouldShowScreenEdges();

            internalRetileAll(currentMapping);
            internalInitLayer(window, currentMapping.autoTilerIndex);
        }
    }

    function internalInitLayer(window, tilerIndex) {
        switch (autoLayoutConfigs[tilerIndex].layer) {
            case 0: // keep below except active window
                window.keepBelow = window != Workspace.activeWindow;
                break;
            case 1: // keep below
                window.keepBelow = true;
                break;
            case 2: // keep normal
                window.keepAbove = false;
                window.keepBelow = false;
                break;
            case 3: // keep above
                window.keepAbove = true;
                break;
        }
    }

    function internalUpdateLayer(window, tilerIndex, active) {
        switch (autoLayoutConfigs[tilerIndex].layer) {
            case 0: // keep below except active window
                window.keepBelow = !active;
                break;
            case 1: // keep below
                window.keepBelow = true;
                break;
            case 2: // keep normal
                window.keepAbove = false;
                window.keepBelow = false;
                break;
            case 3: // keep above
                window.keepAbove = true;
                break;
        }
    }

    function internalSetActiveWindow(window, tiler) {
        ignoreActivates = true;
        internalUpdateLayer(window, tiler, true);
        Workspace.activeWindow = window;
        ignoreActivates = false;
    }

    function internalGetWindowIndexAtTileIndex(mapping, index, layoutIndex) {
        if (mapping.autoTilerIndex < 0) {
            return NaN;
        }
        logAutoTiler('internalGetWindowIndexAtTileIndex 1 index: ' + index + ' ' + JSON.stringify(autoLayouts[mapping.autoTilerIndex][layoutIndex].autoMapping));
        let windowIndex = autoLayouts[mapping.autoTilerIndex][layoutIndex].autoMapping[index];
        if (windowIndex == '*') {
            return windowIndex;
        }
        logAutoTiler('internalGetWindowIndexAtTileIndex 2 windowIndex: ' + windowIndex);
        windowIndex += mapping.primaryWindowIndex;
        logAutoTiler('internalGetWindowIndexAtTileIndex 3 windowIndex: ' + windowIndex);
        if (windowIndex < 0) {
            windowIndex += mapping.windows.length;
            logAutoTiler('internalGetWindowIndexAtTileIndex 4 windowIndex: ' + windowIndex);
        } else if (windowIndex >= mapping.windows.length) {
            windowIndex -= mapping.windows.length;
            logAutoTiler('internalGetWindowIndexAtTileIndex 5 windowIndex: ' + windowIndex);
        }
        return windowIndex;
    }

    function internalMoveToTile(window, index) {
        let currentMapping = getMappingById(window.mt_auto);
        let currentIndex = currentMapping.windows.indexOf(window);
        logAutoTiler('internalMoveToTile index: ' + index + ' currentIndex: ' + currentIndex + ' window: ' + window.internalId);
        if (currentIndex == index) {
            return;
        }
        currentMapping.windows.splice(currentIndex, 1);
        if (index < currentIndex) {
            currentMapping.windows.splice(index, 0, window);
        } else {
            currentMapping.windows.splice(index, 0, window);
        }
        internalRetileAll(currentMapping);
    }

    function internalMoveBeforeTile(window, index) {
        let currentMapping = getMappingById(window.mt_auto);
        let currentIndex = currentMapping.windows.indexOf(window);
        logAutoTiler('internalMoveBeforeTile index: ' + index + ' currentIndex: ' + currentIndex + ' window: ' + window.internalId);
        if (currentIndex == index) {
            return;
        }
        currentMapping.windows.splice(currentIndex, 1);
        if (index < currentIndex) {
            currentMapping.windows.splice(index, 0, window);
        } else {
            currentMapping.windows.splice(index - 1, 0, window);
        }
        internalRetileAll(currentMapping);
    }

    function internalSwapTwoTiles(window, index, convertIndex = true, forcedMapping = null) {
        logAutoTiler('internalSwapTwoTiles !!! 1');
        let currentMapping = forcedMapping || getMappingForWindow(window);
        let currentIndex = currentMapping.windows.indexOf(window);
        logAutoTiler('internalSwapTwoTiles !!! 3');
        let layoutIndex = Math.max(Math.min(currentMapping.windowCount - 1, currentMapping.layoutIndex), 0);
        let targetIndex = convertIndex ? internalGetWindowIndexAtTileIndex(currentMapping, index, layoutIndex) : index;
        logAutoTiler('internalSwapTwoTiles !!! current: ' + currentIndex + ' target: ' + targetIndex + ' layoutIndex: ' + layoutIndex);
        if (currentIndex >= 0 && targetIndex >= 0) {
            let current = currentMapping.windows[currentIndex];
            let target = currentMapping.windows[targetIndex]
            currentMapping.windows.splice(currentIndex, 1, target);
            currentMapping.windows.splice(targetIndex, 1, current);
            internalRetileAll(currentMapping);
        }
    }

    function windowDropped(window, index, tiler) {
        logAutoTiler('Window auto tiled: ' + window.caption + ' index: ' + index + ' tiler: ' + tiler);

        if (window.mt_auto == undefined) {
            logAutoTiler('windowDropped 1');
            internalInsertNewWindow(window, index, true, tiler);
        } else {
            logAutoTiler('windowDropped 2');
            let currentMapping = getMappingForCurrentScreenAndDesktop();
            logAutoTiler('windowDropped 3 ' + currentMapping.id);
            let previousMapping = getMappingById(window.mt_auto);
            logAutoTiler('windowDropped 4 ' + previousMapping.id);
            logAutoTiler('windowDropped 4.0 ' + getMappingForWindow(window).id);

            let layoutIndex = Math.max(Math.min(currentMapping.windowCount - (currentMapping.id == previousMapping.id ? 1 : 0), currentMapping.layoutIndex), 0);
            logAutoTiler('windowDropped 4.1');
            let targetIndex = internalGetWindowIndexAtTileIndex(currentMapping, index, layoutIndex);
            logAutoTiler('windowDropped 4.2');
            if (targetIndex == '*') {
                let geometryIndex = index;
                logAutoTiler('windowDropped 4.3');
                // TODO? currentMapping.layoutIndex = Math.max(Math.min(currentMapping.windowCount, autoLayouts[currentMapping.autoTilerIndex].length - 1), 0);
                internalUpdateGeometries(currentMapping, false);
                logAutoTiler('windowDropped 4.5 geometryIndex: ' + geometryIndex + ' length: ' + currentMapping.geometries.length);
                let geometry = JSON.parse(JSON.stringify(currentMapping.geometries[geometryIndex]));
                internalDisableAutoTiling(window);
                root.addMargins(geometry, true, true, true, true);
                root.moveAndResizeWindow(window, geometry);
            } else if (currentMapping.id == previousMapping.id) {
                logAutoTiler('windowDropped 5 target index: ' + targetIndex);

                if (currentMapping.autoTilerIndex != tiler) {
                    logAutoTiler('windowDropped 6');
                    changeToTiler(tiler, currentMapping);
                } else if (currentMapping.windows[targetIndex].internalId == window.internalId) {
                    logAutoTiler('windowDropped 7');
                    internalRetileAll(currentMapping);
                } else {
                    logAutoTiler('windowDropped 8');
                    switch (autoLayoutConfigs[currentMapping.autoTilerIndex].dragSwapAction) {
                        default:
                        case 0: // insert dragged window at target priority
                            internalMoveToTile(window, targetIndex);
                            break;
                        case 1: // swap places
                            internalSwapTwoTiles(window, targetIndex, false);
                            break;
                    }
                }
            } else {
                logAutoTiler('windowDropped 9');

                internalDisableAutoTiling(window);
                internalInsertNewWindow(window, index, true, tiler, currentMapping);
            }
            logAutoTiler('windowDropped 10');

            if (Workspace.activeWindow == window && window.mt_auto) {
                let activeMapping = getMappingById(window.mt_auto);
                internalUpdateLayer(window, activeMapping.autoTilerIndex, true);
            }
        }
    }

    function changeToTiler(tiler, currentMapping) {
        if (tiler == -1 || currentMapping.autoTilerIndex == -1 || tiler == currentMapping.autoTilerIndex) return;
        currentMapping.autoTilerIndex = tiler;
        for (let i = 0; i < currentMapping.windows.length; i++) {
            currentMapping.windows[i].mt_autoRestore = 256 + currentMapping.autoTilerIndex;
        }
        currentMapping.isCarousel = autoLayoutConfigs[tiler].carousel == true;
        currentMapping.geometryIndex = -1;
        currentMapping.layoutIndex = Math.max(Math.min(currentMapping.windowCount, autoLayouts[tiler].length - 1), 0);
        updateShouldShowScreenEdges();
        internalRetileAll(currentMapping);
    }

    function changeToPreviousTiler() {
        let mapping = getMappingForCurrentScreenAndDesktop();
        let nextTiler = mapping.autoTilerIndex - 1;
        if (nextTiler >= 0) {
            changeToTiler(nextTiler, mapping);
        }
    }

    function changeToNextTiler() {
        let mapping = getMappingForCurrentScreenAndDesktop();
        let nextTiler = mapping.autoTilerIndex + 1;
        if (mapping.autoTilerIndex != -1 && nextTiler < 3) {
            changeToTiler(nextTiler, mapping);
        }
    }

    function toggleAutoTile(window, tiler = -1) {
        if (window.mt_auto == undefined) {
            if (configAutoTileRestoreSize) {
                window.mt_originalSize = {xOffset: 0, width: window.width, height: window.height};
            }
            let currentMapping = getMappingForWindow(window);
            let configIndex = tiler != -1 ? tiler : (currentMapping.autoTilerIndex != -1 ? currentMapping.autoTilerIndex : 0);
            let insertIndex = autoLayoutConfigs[configIndex].autoTileIndex;
            if (currentMapping.windows.length == 0) {
                insertIndex = 0;
            } else if (insertIndex == -1) {
                insertIndex += currentMapping.windows.length;
            } else if (insertIndex >= currentMapping.windows.length) {
                insertIndex = currentMapping.windows.length;
            }

            switch(autoLayoutConfigs[configIndex].autoTileAction) {
                case 0: // insert before
                    // Do nothing already correct
                    break;
                case 1: // insert after
                    if (insertIndex < currentMapping.windows.length) {
                        insertIndex++;
                    }
                    break;
            }

            internalInsertNewWindow(window, insertIndex, false, tiler, currentMapping);
            if (Workspace.activeWindow == window) {
                if (currentMapping.autoTilerIndex != -1) {
                    internalUpdateLayer(window, currentMapping.autoTilerIndex, true);
                }
            }
            // if (!window.minimized) {
            //     internalSetActiveWindow(window, currentMapping.autoTilerIndex);
            // }
        } else {
            internalDisableAutoTiling(window);
            if (configAutoTileRestoreSize && window.mt_originalSize) {
                window.frameGeometry = Qt.rect(window.frameGeometry.x, window.frameGeometry.y, window.mt_originalSize.width, window.mt_originalSize.height);
                delete window.mt_originalSize;
            }
        }
    }

    function windowAdded(window) {
        logAutoTiler('Window added: ' + window.caption);

        window.minimizedChanged.connect(windowMinimizedChanged);
        window.maximizedAboutToChange.connect(windowMaximizedAboutToChange);
        window.maximizedChanged.connect(windowMaximizedChanged);
        window.transientChanged.connect(windowTransientChanged);
        window.outputChanged.connect(windowOutputChanged);
        window.desktopsChanged.connect(windowDesktopsChanged);

        delete window.mt_auto;

        let now = Date.now();
        if (configMaxAutoTileDelaySessionStart > 0 && (now < sessionStartTime + configMaxAutoTileDelaySessionStart * 1000)) {
            let sessionDelay = configMaxAutoTileDelaySessionStart * 1000 - (now - sessionStartTime);
            if (sessionDelay < configMaxAutoTileDelay * 1000) {
                sessionDelay = configMaxAutoTileDelay * 1000;
            }
            logAutoTiler('session delay duration: ' + sessionDelay);
            // Create timer
            autoTileTimer.setTimeout(sessionDelay, window);

        } else if (configMaxAutoTileDelay > 0) {
            let startDelay = (configMaxAutoTileDelay * 1000);
            logAutoTiler('start delay duration: ' + startDelay);
            autoTileTimer.setTimeout(startDelay, window);
            // Create timer
        } else {
            logAutoTiler('instant restore');
            // No timer
            autoTileWindowOnStart(window);
        }

        function windowMinimizedChanged() {
            logAutoTiler('################# Window minimized: ' + window.caption + ' ' + window.minimized + ' mt_minimized: ' + window.mt_minimized + ' id: ' + window.internalId);
            // TODO:
            if (window.minimized) {
                if (!window.mt_minimized) {
                    if (window.mt_auto && configAutoTileMinimizedMaximized) {
                        window.mt_autoRestoreMinMax = true;
                    }
                    internalDisableAutoTiling(window);
                    delete window.mt_minimized;
                }
            } else {
                if (configAutoTileMinimizedMaximized && window.mt_autoRestoreMinMax) {
                    toggleAutoTile(window);
                    delete window.mt_autoRestoreMinMax;
                }
            }
        }

        function windowMaximizedAboutToChange(mode) {
            logAutoTiler('Window maximized about to change: ' + window.caption + ' ' + JSON.stringify(mode));
            // TODO: 0 disabled 3 enabled probably mask 1 & 2
            if (mode != 0) {
                if (window.mt_auto && configAutoTileMinimizedMaximized) {
                    logAutoTiler('11111111111111111111111111111');
                    window.mt_autoRestoreMinMax = true;
                }
                internalDisableAutoTiling(window);
            } else if (configAutoTileMinimizedMaximized && window.mt_autoRestoreMinMax) {
                currentWindowUnMaximized = true;
            }
        }

        function windowMaximizedChanged() {
            if (currentWindowUnMaximized) {
                logAutoTiler('22222222222222222222222222222');
                toggleAutoTile(window);
                delete window.mt_autoRestoreMinMax;
            }
            currentWindowUnMaximized = false;
        }

        function windowTransientChanged() {
            logAutoTiler('Window transient: ' + window.caption + ' ' + window.transient);
            // TODO:
            internalDisableAutoTiling(window);
        }

        function windowOutputChanged() {
            logAutoTiler('Window output changed: ' + window.caption + ' currently moved window: ' + (window == root.currentlyMovedWindow));
            if (window != root.currentlyMovedWindow) {
                internalDisableAutoTiling(window);
            }
        }

        function windowDesktopsChanged() {
            logAutoTiler('Window desktops changed: ' + window.caption + ' currently moved window: ' + (window == root.currentlyMovedWindow));
            if (window != root.currentlyMovedWindow) {
                internalDisableAutoTiling(window);
            }
        }
    }

    function windowClosed(window) {
        logAutoTiler('Window closed: ' + window.caption);
        internalDisableAutoTiling(window);
    }

    function windowMoved(window) {
        logAutoTiler('Window moved: ' + window.caption);
        internalDisableAutoTiling(window);
    }

    function windowResized(window) {
        logAutoTiler('Window resized: ' + window.caption);
        internalDisableAutoTiling(window);
    }

    function virtualDesktopsChanged() {
        let removed = [...autoVirtualDesktops];
        let added = [];

        for (let i = 0; i < Workspace.desktops.length; i++) {
            let desktopId = Workspace.desktops[i].id;
            if (autoVirtualDesktops.indexOf(desktopId) == -1) {
                added.push(desktopId);
            } else {
                removed.splice(removed.indexOf(desktopId), 1);
            }
        }

        for (let i = 0; i < added.length; i++) {
            let desktopId = added[i];
            autoVirtualDesktops.push(desktopId);
            for (let s = 0; s < autoScreens.length; s++) {
                let id = autoScreens[s] + desktopId;
                autoWindowMapping[id] = {
                    windows: [],
                    geometries: [],
                    layoutIndex: 0,
                    geometryIndex: -1,
                    windowCount: 0,
                    primaryWindowIndex: 0,
                    isCarousel: false,
                    autoTilerIndex: -1,
                    id: id,
                    screenName: autoScreens[s],
                    desktopId: desktopId
                };
            }
        }

        for (let i = 0; i < removed.length; i++) {
            let desktopId = removed[i];
            let index = autoVirtualDesktops.indexOf(desktopId);
            if (index != -1) {
                autoVirtualDesktops.splice(index, 1);
                for (let s = 0; s < autoScreens.length; s++) {
                    let currentMapping = getMappingByScreenNameAndVirtualDesktopId(autoScreens[s], desktopId);
                    for (let w = 0; w < currentMapping.windows.length; w++) {
                        delete currentMapping.windows[w].mt_auto;
                    }
                    delete autoWindowMapping[autoScreens[s] + desktopId];
                }
            }
        }

        log('virtualDesktopChanged added: ' + JSON.stringify(added) + ' removed: ' + JSON.stringify(removed) + ' all: ' + JSON.stringify(autoVirtualDesktops));
    }

    function screensChanged() {
        let removed = [...autoScreens];
        let added = [];

        for (let i = 0; i < Workspace.screens.length; i++) {
            let screenName = Workspace.screens[i].name;
            if (autoScreens.indexOf(screenName) == -1) {
                added.push(screenName);
            } else {
                removed.splice(removed.indexOf(screenName), 1);
            }
        }

        for (let i = 0; i < added.length; i++) {
            let screenName = added[i];
            autoScreens.push(screenName);
            for (let v = 0; v < autoVirtualDesktops.length; v++) {
                let id = screenName + autoVirtualDesktops[v];
                autoWindowMapping[id] = {
                    windows: [],
                    geometries: [],
                    layoutIndex: 0,
                    geometryIndex: -1,
                    windowCount: 0,
                    primaryWindowIndex: 0,
                    isCarousel: false,
                    autoTilerIndex: -1,
                    id: id,
                    screenName: screenName,
                    desktopId: autoVirtualDesktops[v]
                };
            }
        }

        for (let i = 0; i < removed.length; i++) {
            let screenName = removed[i];
            let index = autoScreens.indexOf(screenName);
            if (index != -1) {
                autoScreens.splice(index, 1);
                for (let v = 0; v < autoVirtualDesktops.length; v++) {
                    let currentMapping = getMappingByScreenNameAndVirtualDesktopId(screenName, autoVirtualDesktops[v]);
                    for (let w = 0; w < currentMapping.windows.length; w++) {
                        delete currentMapping.windows[w].mt_auto;
                    }
                    delete autoWindowMapping[screenName + autoVirtualDesktops[v]];
                }
            }
        }

        log('screensChanged added: ' + JSON.stringify(added) + ' removed: ' + JSON.stringify(removed) + ' all: ' + JSON.stringify(autoScreens));
    }

    function updateLayoutMapping() {
        for (let i = 0; i < popupGridLayouts.length; i++) {
            switch (popupGridLayouts[i].special) {
                case 'SPECIAL_AUTO_TILER_1':
                    layoutMapping.push({all: false, index: i, autoTilerIndex: 0});
                    break;
                case 'SPECIAL_AUTO_TILER_2':
                    layoutMapping.push({all: false, index: i, autoTilerIndex: 1});
                    break;
                case 'SPECIAL_AUTO_TILER_3':
                    layoutMapping.push({all: false, index: i, autoTilerIndex: 2});
                    break;
            }
        }

        for (let i = 0; i < popupGridAllLayouts.length; i++) {
            switch (popupGridAllLayouts[i].special) {
                case 'SPECIAL_AUTO_TILER_1':
                    layoutMapping.push({all: true, index: i, autoTilerIndex: 0});
                    break;
                case 'SPECIAL_AUTO_TILER_2':
                    layoutMapping.push({all: true, index: i, autoTilerIndex: 1});
                    break;
                case 'SPECIAL_AUTO_TILER_3':
                    layoutMapping.push({all: true, index: i, autoTilerIndex: 2});
                    break;
            }
        }
    }

    function loadAutoTilerConfig() {
        const defaultBlacklist = 'krunner,kded,polkit,plasmashell,yakuake,spectacle,kded5,xwaylandvideobridge,ksplashqml,org.kde.plasmashell,org.kde.polkit-kde-authentication-agent-1,org.kde.kruler,kruler,kwin_wayland,ksmserver-logout-greeter';

        configAutoTileNewWindows = KWin.readConfig("autoTileNewWindows", false);
        configAutoTileMinimizedMaximized = KWin.readConfig("autoTileMinimizedMaximized", true);
        configAutoTileRestoreSize = KWin.readConfig("autoTileRestoreSize", false);
        configAutoTileWindowAction = KWin.readConfig("autoTileWindowAction", 0);
        configAutoTileWindowIndex = KWin.readConfig("autoTileWindowIndex", 0);
        configAutoTileFocusAction = KWin.readConfig("autoTileFocusAction", 0);
        configAutoTileFocusIndex = KWin.readConfig("autoTileFocusIndex", 0);
        configAutoTileMinimizedFocusAction = KWin.readConfig("autoTileMinimizedFocusAction", 0);
        configAutoTileMinimizedFocusIndex = KWin.readConfig("autoTileMinimizedFocusIndex", 0);
        configAutoTileDragSwapAction = KWin.readConfig("autoTileDragSwapAction", 0);
        configAutoTileLayer = KWin.readConfig("autoTileLayer", 2);
        configMaxAutoTileDelay = KWin.readConfig("maxAutoTileDelay", 5);
        configMaxAutoTileDelaySessionStart = KWin.readConfig("maxAutoTileDelaySessionStart", 10);
        configAutoTileBlacklist = KWin.readConfig("autoTileBlacklist", defaultBlacklist).replace(/\s+/g, '').split(',');

        initAutoTilerLayout(1);
        initAutoTilerLayout(2);
        initAutoTilerLayout(3);
    }

    function initAutoTilerLayout(humanReadableIndex) {
        const defaultModes = [8, 1, 12];

        let mode = KWin.readConfig('autoTilerMode' + humanReadableIndex, defaultModes[humanReadableIndex - 1]);
        let name = 'Default';

        function getLayout() {
            const defaultAutoTile_development = `{"tileTextMode":0}
0:0,0,25,100
0:0,0,25,50+1:0,50,25,50
0:0,0,25,50+1:0,50,13,50+2:13,50,12,50
0:0,0,13,50+1:13,0,12,50+2:0,50,13,50+3:13,50,12,50`;

            const defaultAutoTile1 = `0:0,0,100,100
0:0,0,50,100+1:50,0,50,100
0:0,0,50,100+1:50,0,50,50+2:50,50,50,50
0:0,0,50,50+3:0,50,50,50+1:50,0,50,50+2:50,50,50,50`;

            const defaultAutoTile2 = `{"carousel":true}
0:0,0,100,100`;

            const defaultAutoTile3 = `0:0,0,67,100
0:0,0,67,100+1:67,0,33,100
0:0,0,67,100+1:67,0,33,50+2:67,50,33,50`;

            switch(mode) {
                case 0:
                    name = 'CUSTOM ' + humanReadableIndex;
                    switch (humanReadableIndex) {
                        case 1:
                            return KWin.readConfig('autoTilerCustom1', defaultAutoTile1);
                        case 2:
                            return KWin.readConfig('autoTilerCustom2', defaultAutoTile2);
                        case 3:
                            return KWin.readConfig('autoTilerCustom3', defaultAutoTile3);
                    }
                case 1:
                    name = 'SINGLE TILE CAROUSEL';
                    return `{"carousel":true}
0:0,0,100,100`;
                case 2:
                    name = 'THREE TILE CAROUSEL';
                    return `{"carousel":true}
0:0,0,100,100
0:0,0,100,100+1:100,0,100,100
-1:-100,0,100,100+0:0,0,100,100+1:100,0,100,100`;
                case 3:
                    name = '50% CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
0:25,0,50,100
0:25,0,50,100+1:75,0,50,100
-1:-25,0,50,100+0:25,0,50,100+1:75,0,50,100`;
                case 4:
                    name = '66% CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
0:17,0,66,100
0:17,0,66,100+1:83,0,66,100
-1:-49,0,66,100+0:17,0,66,100+1:83,0,66,100`;
                case 5:
                    name = '96% CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
0:2,0,96,100
0:2,0,96,100+1:98,0,96,100
-1:-94,0,96,100+0:2,0,96,100+1:98,0,96,100`;
                case 6:
                    name = '3 CARD STACK';
                    return `{"carousel":true,"focusAction":0,"tileTextMode":2,"sortZ":false}
0:4,0,92,100
1:8,0,92,100+0:4,0,92,100
-1:0,0,92,100+1:8,0,92,100+0:4,0,92,100`;
                case 7:
                    name = '5 CARD STACK';
                    return `{"carousel":true,"focusAction":0,"tileTextMode":2,"sortZ":false}
0:6,0,88,100
1:12,0,88,100+0:6,0,88,100
-1:0,0,88,100+1:12,0,88,100+0:6,0,88,100
-1:0,0,88,100+2:12,0,88,100+1:9,0,88,100+0:6,0,88,100
-2:0,0,88,100+-1:3,0,88,100+2:12,0,88,100+1:9,0,88,100+0:6,0,88,100`;
                case 8:
                    name = 'SPIRAL 4';
                    return `0:0,0,100,100
0:0,0,50,100+1:50,0,50,100
0:0,0,50,100+1:50,0,50,50+2:50,50,50,50
0:0,0,50,50+3:0,50,50,50+1:50,0,50,50+2:50,50,50,50`;
                case 9:
                    name = 'SPIRAL 8';
                    return `0:0,0,100,100
0:0,0,50,100+1:50,0,50,100
0:0,0,50,100+1:50,0,50,50+2:50,50,50,50
0:0,0,50,50+3:0,50,50,50+1:50,0,50,50+2:50,50,50,50
0:0,0,50,50+4:0,50,25,50+3:25,50,25,50+1:50,0,50,50+2:50,50,50,50
0:0,0,50,50+5:0,50,25,50+4:25,50,25,50+1:50,0,50,50+3:50,50,25,50+2:75,50,25,50
0:0,0,50,50+6:0,50,25,50+5:25,50,25,50+1:50,0,25,50+2:75,0,25,50+4:50,50,25,50+3:75,50,25,50
0:0,0,25,50+1:25,0,25,50+7:0,50,25,50+6:25,50,25,50+2:50,0,25,50+3:75,0,25,50+5:50,50,25,50+4:75,50,25,50`;
                case 10:
                    name = '50% + 2 STACK';
                    return `0:0,0,50,100
0:0,0,50,100+1:50,0,50,100
0:0,0,50,100+1:50,0,50,50+2:50,50,50,50`;
                case 11:
                    name = '50% + 3 STACK';
                    return `0:0,0,50,100
0:0,0,50,100+1:50,0,50,100
0:0,0,50,100+1:50,0,50,50+2:50,50,50,50
0:0,0,50,100+1:50,0,50,33+2:50,33,50,34+3:50,67,50,33`;
                case 12:
                    name = '67% + 2 STACK';
                    return `0:0,0,67,100
0:0,0,67,100+1:67,0,33,100
0:0,0,67,100+1:67,0,33,50+2:67,50,33,50`;
                case 13:
                    name = '67% + 3 STACK';
                    return `0:0,0,67,100
0:0,0,67,100+1:67,0,33,100
0:0,0,67,100+1:67,0,33,50+2:67,50,33,50
0:0,0,67,100+1:67,0,33,33+2:67,33,33,34+3:67,67,33,33`;
                case 14:
                    name = '2 + 50% + 2 STACK';
                    return `0:25,0,50,100
0:25,0,50,100+1:75,0,25,100
2:0,0,25,100+0:25,0,50,100+1:75,0,25,100
3:0,0,25,100+0:25,0,50,100+1:75,0,25,50+2:75,50,25,50
3:0,0,25,50+4:0,50,25,50+0:25,0,50,100+1:75,0,25,50+2:75,50,25,50`;
                case 15:
                    name = '* | 1 + 50% + * | 1 CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
*:0,0,25,50+0:25,0,50,100+*:75,0,25,50
*:0,0,25,50+0:25,0,50,100+*:75,0,25,50+1:75,50,25,50
*:0,0,25,50+-1:0,50,25,50+0:25,0,50,100+*:75,0,25,50+1:75,50,25,50`;
                case 16:
                    name = '1 | * + 50% + 1 | * CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
*:0,50,25,50+0:25,0,50,100+*:75,50,25,50
*:0,50,25,50+0:25,0,50,100+1:75,0,25,50+*:75,50,25,50
-1:0,0,25,50+*:0,50,25,50+0:25,0,50,100+1:75,0,25,50+*:75,50,25,50`;
                case 17:
                    name = '76% CAROUSEL';
                    return `{"carousel":true,"focusAction":0}
0:12,0,76,100
0:12,0,76,100+1:88,0,76,100
-1:-64,0,76,100+0:12,0,76,100+1:88,0,76,100
-1:-64,0,76,100+0:12,0,76,100+1:88,0,76,100+2:152,0,76,100
-2:-140,0,76+-1:-64,0,76,100+0:12,0,76,100+1:88,0,76,100+2:164,0,76,100`;
                case 18:
                    name = '50% + 50% CAROUSEL';
                    return `{"carousel":true,"focusAction":5}
0:0,0,50,100
0:0,0,50,100+1:50,0,50,100
-1:-50,0,50,100+0:0,0,50,100+1:50,0,50,100
-1:-50,0,50,100+0:0,0,50,100+1:50,0,50,100+2:100,0,50,100`;
            }
        }

        let convertedLayout = convertAutoTilerLayouts(getLayout());

        let config = convertedLayout.config;
        if (config.autoTileAction === undefined) {
            config.autoTileAction = configAutoTileWindowAction;
        }
        if (config.autoTileIndex === undefined) {
            config.autoTileIndex = configAutoTileWindowIndex;
        }
        if (config.focusAction === undefined) {
            config.focusAction = configAutoTileFocusAction;
        }
        if (config.focusIndex === undefined) {
            config.focusIndex = configAutoTileFocusIndex;
        }
        if (config.minimizedFocusAction === undefined) {
            config.minimizedFocusAction = configAutoTileMinimizedFocusAction;
        }
        if (config.minimizedFocusIndex === undefined) {
            config.minimizedFocusIndex = configAutoTileMinimizedFocusIndex;
        }
        if (config.dragSwapAction === undefined) {
            config.dragSwapAction = configAutoTileDragSwapAction;
        }
        if (config.carousel === undefined) {
            config.carousel = KWin.readConfig("autoTilerCarousel" + humanReadableIndex, false);
        }
        if (config.clip === undefined) {
            config.clip = config.carousel;
        }
        if (config.sortZ === undefined) {
            config.sortZ = true;
        }
        if (config.layer === undefined) {
            config.layer = configAutoTileLayer;
        }

        config.name = name;

        autoLayouts.push(convertedLayout.layouts);
        autoLayoutConfigs.push(config);

        if (root.useAutoTilerPreview && humanReadableIndex == 2) {
            root.popupGridLayouts = convertedLayout.layouts;
        }

        logAutoTiler('##### name: ' + name + ' layout:\n' + JSON.stringify(convertedLayout));
    }
}