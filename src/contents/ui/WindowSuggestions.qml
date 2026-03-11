import QtQuick
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// Window {
PlasmaCore.Dialog {
    id: windowSuggestions

    property var activeScreen: null
    property var currentDesktop: null
    property var currentActivity: null
    property bool isDefault: true
    property int layoutIndex: 0
    property int tileIndex: 0

    property var clientArea: ({width: 1, height: 1, x: 0, y: 0})
    property var tilePadding: 2
    property list<var> convertedOverlay: ([])

    property int skipIndex: -1
    property int activeIndex: -1

    property int suggestionsVisibility: 0
    property bool suggestionsInsideTile: true
    property bool excludeOtherScreens: true
    property bool excludeOtherDesktops: true
    property bool excludeOtherActivities: true
    property bool excludeAutoTiled: true
    property bool excludeMinimized: true

    property int sortMode: 2
    property int colCount: 1
    property int rowCount: 1
    property int cellWidth: 0
    property int previewHeight: 0
    property real cellRatio: 0
    property int cellHeight: 0
    property int cellBottomMargin: 0
    property int textSize: 14
    property int totalWidth: 0
    property int totalHeight: 0

    property int offsetX: 0
    property int offsetY: 0

    property int gridSpacing: 20

    property list<var> validWindows: ([])

    width: clientArea.width
    height: clientArea.height
    x: clientArea.x
    y: clientArea.y
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus | Qt.BypassWindowManagerHint
    // flags: Qt.Tool | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
    // flags: Qt.Tool | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
    // color: "transparent" // PlasmaCore.Dialog
    visible: false
    // outputOnly: true
    backgroundHints: PlasmaCore.Types.NoBackground // PlasmaCore.Dialog
    // type: PlasmaCore.Dialog.OnScreenDisplay
    location: PlasmaCore.Types.Desktop // PlasmaCore.Dialog

    function init() {
        suggestionsVisibility = KWin.readConfig("suggestionsVisibility", 0);
        suggestionsInsideTile = KWin.readConfig("suggestionsMode", 0) == 0;
        excludeOtherScreens = !KWin.readConfig("suggestOtherScreens", false);
        excludeOtherDesktops = !KWin.readConfig("suggestOtherDesktops", false);
        excludeOtherActivities = !KWin.readConfig("suggestOtherActivities", false);
        excludeAutoTiled = !KWin.readConfig("suggestAutoTiled", false);
        excludeMinimized = !KWin.readConfig("suggestMinimized", false);
    }

    function updateValid(addedWindow) {
        let valid = [];

        for (let i = 0; i < Workspace.stackingOrder.length; i++) {
            let window = Workspace.stackingOrder[i];
            if (window == addedWindow) continue;
            if (!root.isValidWindow(window)) continue;
            if (excludeAutoTiled && window.mt_auto) continue;
            if (excludeMinimized && window.minimized) continue;
            if (excludeOtherScreens && window.output != activeScreen) continue;
            if (excludeOtherDesktops && window.desktops.length > 0 && !window.desktops.includes(currentDesktop)) continue;
            if (excludeOtherActivities && window.activities.length > 0 && !window.activities.includes(currentActivity)) continue;
            valid.push(window);
        }

        switch (sortMode) {
            case 0: // newest focused first
                valid.reverse();
                break;
            case 1: // oldest focused first
                break;
            case 2: // a-z
                valid.sort((a, b) => a.caption.toLowerCase().localeCompare(b.caption.toLowerCase()));
                break;
        }

        validWindows = valid;
    }

    function updateSizes() {
        let count = validWindows.length;

        log('Valid count: ' + count);

        let usableHeight = suggestionsInsideTile ? convertedOverlay[activeIndex].height : clientArea.height - 180;
        let usableWidth = suggestionsInsideTile ? convertedOverlay[activeIndex].width : clientArea.width / 2;
        let wantedRatio = 16 / 9;
        let ratio = usableWidth / usableHeight;

        if (!suggestionsInsideTile) {
            if (ratio < wantedRatio) {
                usableWidth = parseInt(usableWidth);
                usableHeight = parseInt(usableWidth / wantedRatio);
            } else {
                usableHeight = parseInt(usableHeight);
                usableWidth = parseInt(usableHeight * wantedRatio);
            }
        }

        colCount = Math.ceil(Math.sqrt(count));
        rowCount = Math.ceil(count / colCount);
        cellWidth = (usableWidth - gridSpacing * (colCount + 1)) / Math.max(colCount, 2);
        log('CellWidth before: ' + cellWidth);
        if (suggestionsInsideTile) {
            if (cellWidth < 320) {
                colCount = Math.min(count, Math.floor(convertedOverlay[activeIndex].width / 320));
            } else {
                colCount = Math.min(count, Math.floor(convertedOverlay[activeIndex].width / cellWidth));
            }
            cellWidth = (convertedOverlay[activeIndex].width - gridSpacing * (colCount + 1)) / Math.max(colCount, 2);
        }
        log('ColCount: ' + colCount + ' width: ' + cellWidth + ' gridSpacing: ' + gridSpacing + ' width: ' + convertedOverlay[activeIndex].width + ' usable: ' + usableWidth);
        cellBottomMargin = Kirigami.Units.iconSizes.large / 4;
        previewHeight = (usableHeight - gridSpacing * (rowCount + 1)) / Math.max(colCount, 2);
        if (suggestionsInsideTile && previewHeight < 200) {
            rowCount = Math.ceil(count / colCount);
            previewHeight = 200;
        }
        cellHeight = previewHeight - cellBottomMargin - textSize;
        totalWidth = suggestionsInsideTile ? convertedOverlay[activeIndex].width : cellWidth * Math.max(colCount, 2) + gridSpacing * (colCount + 1);
        totalHeight = suggestionsInsideTile ? convertedOverlay[activeIndex].height : previewHeight * rowCount + gridSpacing * (rowCount + 1);
        cellRatio = cellWidth / previewHeight;
        log('Count: ' + count + ' rowCount: ' + rowCount + ' colCount: ' + colCount + ' width: ' + usableWidth + ' height: ' + usableHeight + ' ratio: ' + ratio + ' wanted ratio: ' + wantedRatio + ' cell width: ' + cellWidth + ' cell height: ' + cellHeight + ' totalHeight: ' + totalHeight);
    }

    function showSuggestions(window, screen, virtualDesktop, activity, isDefault, layoutIndex, tileIndex) {
        log('screen: ' + screen.name + ' virtualDesktop: ' + virtualDesktop.id + ' activity: ' + activity + ' isDefault: ' + isDefault + ' layoutIndex: ' + layoutIndex + ' tileIndex: ' + tileIndex);
        activeScreen = screen;
        currentDesktop = virtualDesktop;
        currentActivity = activity;
        windowSuggestions.isDefault = isDefault;
        windowSuggestions.layoutIndex = layoutIndex;
        windowSuggestions.tileIndex = tileIndex;

        clientArea = Workspace.clientArea(KWin.FullScreenArea, activeScreen, currentDesktop);
        activeIndex = 0;
        skipIndex = tileIndex;

        convertLayoutToScreen();

        updateValid(window);

        if (validWindows.length > 0 && convertedOverlay.length > 0) {
            updateSizes();
            updateOffsets();
            windowSuggestions.visible = true;
        }
    }

    function convertLayoutToScreen() {
        let layout = isDefault ? popupGridLayouts[layoutIndex].tiles : popupGridAllLayouts[layoutIndex].tiles;
        log('Window suggestions layout to convert: ' + JSON.stringify(layout));
        let converted = [];
        for (let i = 0; i < layout.length; i++) {
            if (i == skipIndex) continue;
            let tile = layout[i];
            let width = (tile.pxW == undefined ? tile.w / 100 * windowSuggestions.width : tile.pxW);
            let height = (tile.pxH == undefined ? tile.h / 100 * windowSuggestions.height : tile.pxH);

            // Temporarily add clientArea x/y since it is needed for calculating margins
            let geometry = {
                x: clientArea.x + ((tile.pxX == undefined ? tile.x / 100 * windowSuggestions.width : tile.pxX) - (tile.aX == undefined ? 0 : tile.aX * width / 100)),
                y: clientArea.y + ((tile.pxY == undefined ? tile.y / 100 * windowSuggestions.height : tile.pxY) - (tile.aY == undefined ? 0 : tile.aY * height / 100)),
                width: width,
                height: height,
                tileIndex: i
            };
            root.addMargins(geometry, true, true, true, true);
            geometry.x -= clientArea.x;
            geometry.y -= clientArea.y;
            converted.push(geometry);
        }
        windowSuggestions.convertedOverlay = converted;
    }

    function updateOffsets() {
        if (activeIndex < convertedOverlay.length) {
            if (suggestionsInsideTile) {
                offsetX = convertedOverlay[activeIndex].x;
                offsetY = convertedOverlay[activeIndex].y;
            } else {
                let overlay = convertedOverlay[activeIndex];
                let rightSpace = clientArea.width - overlay.x - overlay.width;
                if (overlay.x < rightSpace) {
                    offsetX = Math.min(clientArea.width - rightSpace + 2, clientArea.width - totalWidth - 2);
                } else {
                    offsetX = Math.max(overlay.x - totalWidth - 2, 2);
                }

                offsetY = overlay.y - ((totalHeight + 80 - overlay.height) / 2);
                if (offsetY < 0) {
                    offsetY = 0;
                } else if (offsetY + totalHeight + 80 > clientArea.height) {
                    offsetY = clientArea.height - totalHeight - 80;
                }
            }
        }
    }

    function selectSuggestion(index, tileIndex) {
        log('Select suggestion: ' + index + ' ' + tileIndex);
        activeIndex = index;
        if (suggestionsInsideTile) {
            updateSizes();
        }
        updateOffsets();
    }

    function addWindowToSelected(window) {
        log('Selected window caption: ' + window.caption);

        if (activeIndex != -1 && validWindows.length > 0) {
            let localWindows = [...validWindows];
            let overlays = JSON.parse(JSON.stringify(windowSuggestions.convertedOverlay)); // Workaround for a strange bug where wrong item is fetched even if activeIndex is correct
            let geometry = overlays.splice(activeIndex, 1)[0];
            windowSuggestions.convertedOverlay = [...overlays];
            geometry.x += clientArea.x;
            geometry.y += clientArea.y;
            let index = localWindows.indexOf(window);
            if (index != -1) {
                localWindows.splice(index, 1);

                if (!window.desktops.includes(currentDesktop)) {
                    window.desktops = [currentDesktop];
                }
                if (!window.activities.includes(currentActivity)) {
                    window.activities = [currentActivity];
                }
                if (window.mt_auto) {
                    autoTiler.disableAutoTiling(window);
                }
                if (window.minimized) {
                    window.minimized = false;
                }
                root.moveAndResizeWindow(window, geometry);
                Workspace.raiseWindow(window);

                activeIndex = 0;

                if (localWindows.length == 0 || convertedOverlay.length == 0) {
                    windowSuggestions.visible = false;
                    validWindows = [];
                } else {
                    validWindows = localWindows;
                    if (suggestionsInsideTile) {
                        updateSizes();
                    }
                    updateOffsets();
                }
            }
        }
    }

    function windowClosed(window) {
        log('Closed window caption: ' + window.caption);

        if (activeIndex != -1 && validWindows.length > 0) {
            let localWindows = [...validWindows];
            let index = localWindows.indexOf(window);
            if (index != -1) {
                localWindows.splice(index, 1);

                if (localWindows.length == 0) {
                    validWindows = [];
                } else {
                    validWindows = localWindows;
                    if (suggestionsInsideTile) {
                        updateSizes();
                    }
                }
            }
        }
    }

    Item {
        id: mainItem
        width: windowSuggestions.width
        height: windowSuggestions.height

        TapHandler {
            onTapped: windowSuggestions.visible = false;
        }

        Colors {
            id: colors
        }

        Repeater {
            id: tileRepeater
            model: windowSuggestions.convertedOverlay

            Item {
                id: tile

                property bool active: activeIndex == index
                property int tileIndex: modelData.tileIndex

                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: tilePadding
                    border.color: colors.tileBorderColor
                    border.width: 2
                    color: active ? colors.tileBackgroundColorActive : colors.tileBackgroundColorIntense
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        color: colors.overlayTextColor
                        textFormat: Text.StyledText
                        text: "<b>Select a window to tile here</b>"
                        font.pixelSize: 16
                        font.family: "Noto Sans"
                        horizontalAlignment: Text.AlignHCenter
                        visible: active && !suggestionsInsideTile
                    }

                    TapHandler {
                        gesturePolicy: TapHandler.ReleaseWithinBounds
                        onTapped: selectSuggestion(index, tileIndex);
                    }
                }
            }
        }

        Item {
            height: suggestionsInsideTile ? totalHeight : totalHeight + 80
            width: totalWidth
            anchors.top: parent.top
            // anchors.topMargin: (clientArea.height - height) / 2
            anchors.topMargin: offsetY
            anchors.left: parent.left
            anchors.leftMargin: offsetX

            Rectangle {
                id: cellWrapper
                width: totalWidth
                height: suggestionsInsideTile ? totalHeight : totalHeight + 80
                color: suggestionsInsideTile ? "transparent" : "#BB000000"
                border.width: 1
                border.color: suggestionsInsideTile ? "transparent" : "#80FFFFFF"
                radius: 6

                GridView {
                    id: listView
                    model: validWindows
                    width: colCount * (windowSuggestions.cellWidth + gridSpacing)
                    // height: rowCount * (previewHeight + gridSpacing)
                    height: suggestionsInsideTile ? Math.min((previewHeight + gridSpacing) * rowCount, totalHeight - 80 - gridSpacing * 2) : totalHeight - 80 - gridSpacing * 2
                    cellWidth: windowSuggestions.cellWidth + gridSpacing
                    cellHeight: previewHeight + gridSpacing
                    interactive: suggestionsInsideTile ? true : false
                    clip: suggestionsInsideTile
                    anchors.top: parent.top
                    anchors.topMargin: suggestionsInsideTile ? (cellWrapper.height - height) / 2 : 40 + gridSpacing
                    anchors.left: parent.left
                    anchors.leftMargin: suggestionsInsideTile ? (cellWrapper.width + gridSpacing - width) / 2 : gridSpacing

                    delegate: Rectangle {
                        width: windowSuggestions.cellWidth
                        height: previewHeight
                        color: "transparent"

                        property real previewRatio: modelData.width / modelData.height
                        property int previewActualWidth: previewRatio > cellRatio ? windowSuggestions.cellWidth : windowSuggestions.cellHeight * previewRatio
                        property int previewActualHeight: previewRatio > cellRatio ? windowSuggestions.cellWidth / previewRatio : windowSuggestions.cellHeight

                        WindowThumbnail {
                            id: preview
                            client: modelData
                            width: previewActualWidth
                            height: previewActualHeight
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: -((textSize + cellBottomMargin) / 2)

                            TapHandler {
                                gesturePolicy: TapHandler.ReleaseWithinBounds
                                onTapped: addWindowToSelected(modelData);
                            }

                            Kirigami.Icon {
                                id: icon
                                width: Kirigami.Units.iconSizes.large
                                height: Kirigami.Units.iconSizes.large
                                source: modelData.icon
                                anchors.horizontalCenter: preview.horizontalCenter
                                anchors.verticalCenter: preview.bottom
                                anchors.verticalCenterOffset: -Math.round(height / 4)

                                PlasmaComponents.Label {
                                    id: text
                                    width: windowSuggestions.cellWidth
                                    height: textSize
                                    text: modelData.caption
                                    anchors.top: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    color: "white"

                                    background: Rectangle {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: 3
                                        height: parent.height + 4
                                        width: parent.contentWidth + 6
                                        color: "#66000000"
                                        radius: 3
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: suggestionsInsideTile ? 4 : 1
                anchors.left: parent.left
                anchors.leftMargin: suggestionsInsideTile ? 4 : 1
                width: suggestionsInsideTile ? totalWidth - 8 : totalWidth - 2
                height: 40;
                color: "#EE333333"
                radius: suggestionsInsideTile ? 12 : 6

                Text {
                    anchors.centerIn: parent
                    color: "white"
                    textFormat: Text.StyledText
                    text: suggestionsInsideTile ? "Select a window to place here" : "Select a window to place in the highlighted tile"
                    font.pixelSize: 16
                    font.family: "Noto Sans"
                    horizontalAlignment: Text.AlignHCenter
                }


                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: "white"
                    textFormat: Text.StyledText
                    text: "✖"
                    font.pixelSize: 16
                    font.family: "Noto Sans"
                    horizontalAlignment: Text.AlignHCenter
                }

                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: windowSuggestions.visible = false;
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: suggestionsInsideTile ? 4 : 1
                anchors.left: parent.left
                anchors.leftMargin: suggestionsInsideTile ? 4 : 1
                width: suggestionsInsideTile ? totalWidth - 8 : totalWidth - 2
                height: 40;
                color: "#EE333333"
                radius: suggestionsInsideTile ? 12 : 6

                Text {
                    anchors.centerIn: parent
                    color: "white"
                    textFormat: Text.StyledText
                    text: "Click a tile to switch to it. Click anywhere else to close suggestions. Disable suggestions (<b>" + config.shortcutToggleTilingSuggestions + "</b>)"
                    font.pixelSize: 16
                    font.family: "Noto Sans"
                    horizontalAlignment: Text.AlignHCenter
                }

                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: windowSuggestions.visible = false;
                }
            }
        }
    }
}