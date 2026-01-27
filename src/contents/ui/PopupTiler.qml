import QtQuick
import QtQuick.Layouts
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: popupTiler

    property var activeScreen: null
    property var clientArea: ({width: 0, height: 0, x: 0, y: 0})
    property int tilePadding: 2
    property int borderOffset: 2
    property int activeLayoutIndex: -1
    property int activeTileIndex: -1
    property int positionX: 0
    property int positionY: 0
    property bool showAll: false
    property bool lastShowAll: false
    property var hint: null
    property bool showPopupDropHint: false
    property bool hasValidPopupDropHint: false
    property var popupDropHintX: 0
    property var popupDropHintY: 0
    property var popupDropHintWidth: 0
    property var popupDropHintHeight: 0
    property bool popupDropHintIsCenterInTile: false
    property bool sizeEstablished: false
    property var revealBox: null
    property bool revealed: false
    property bool currentlyHovered: false
    property int activeVirtualDesktopIndex: -1
    property var activeVirtualDesktopHoverTime: -1
    property bool virtualDesktopVisibilityOverride: false

    width: clientArea.width
    height: clientArea.height
    x: clientArea.x
    y: clientArea.y
    flags: Qt.Popup | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
    visible: false
    backgroundHints: PlasmaCore.Types.NoBackground
    outputOnly: true
    // type: PlasmaCore.Dialog.OnScreenDisplay
    location: PlasmaCore.Types.Desktop

    function reset() {
        activeScreen = null;
        activeLayoutIndex = -1;
        activeTileIndex = -1;
        hint = null;
        showPopupDropHint = false;
        updateHintContent();
    }

    function resetShowAll() {
        showAll = false;
        lastShowAll = false;
    }

    function startAnimations() {
        popupTiler.opacity = 0;
        showPopupTilerAnimation.start();
    }

    function updateScreen(forceUpdate = false) {
        if (forceUpdate || activeScreen != Workspace.activeScreen) {
            root.logE('updateScreen ' + Workspace.virtualScreenSize);
            activeScreen = Workspace.activeScreen;
            clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop);

            let localCursorPos = Workspace.activeScreen.mapFromGlobal(root.getCursorPosition());

            let visibleHeight = virtualDesktopVisibilityOverride || root.config.virtualDesktopVisibility != 1 ? layouts.height : 0;

            if (root.config.popupGridAt == 0) {
                switch (root.config.horizontalAlignment) {
                    default:
                        positionX = localCursorPos.x - root.config.gridWidth / 2 - root.config.gridSpacing;
                        break;
                    case 1:
                        positionX = localCursorPos.x - layouts.width / 2;
                        break;
                    case 2:
                        positionX = localCursorPos.x - layouts.width + root.config.gridWidth / 2 + root.config.gridSpacing;
                        break;
                }

                if (visibleHeight == 0) {
                    positionY = localCursorPos.y;
                } else {
                    switch (root.config.verticalAlignment) {
                        default:
                            positionY = localCursorPos.y - root.config.gridHeight / 2 - root.config.gridSpacing;
                            break;
                        case 1:
                            positionY = localCursorPos.y - layouts.height / 2;
                            break;
                        case 2:
                            positionY = localCursorPos.y - layouts.height + root.config.gridHeight / 2 + root.config.gridSpacing;
                            break;
                    }
                }
            } else {
                switch (root.config.horizontalAlignment) {
                    default:
                        positionX = 0;
                        break;
                    case 1:
                        positionX = clientArea.width / 2 - layouts.width / 2;
                        break;
                    case 2:
                        positionX = clientArea.width - layouts.width;
                        break;
                }

                if (visibleHeight == 0) {
                    positionY = 0;
                } else {
                    switch (root.config.verticalAlignment) {
                        default:
                            positionY = 0;
                            break;
                        case 1:
                            positionY = clientArea.height / 2 - layouts.height / 2;
                            break;
                        case 2:
                            positionY = clientArea.height - layouts.height;
                            break;
                    }
                }
            }

            // positionX = localCursorPos.x - layouts.width / 2;
            // positionY = localCursorPos.y - (layouts.height + popupHint.height + 2) / 2;

            if (positionX < 0) {
                positionX = 0;
            } else if (positionX + layouts.width > popupTiler.width) {
                positionX = popupTiler.width - layouts.width;
            }

            let totalHeight = visibleHeight;
            if (root.virtualDesktopVisibile) {
                if (totalHeight > 0) {
                    totalHeight += 2;
                }
                totalHeight += virtualDesktop.height;
            }
            if (root.config.showTextHint) {
                totalHeight += popupHint.height + 2;
            }

            if (positionY < 0) {
                positionY = 0;
            } else if (positionY + totalHeight > popupTiler.height) {
                positionY = popupTiler.height - totalHeight;
            }

            if (root.config.tilerVisibility == 3) {
                let triggerLeft = Math.max(positionX - config.revealMargin, 0);
                let triggerRight = Math.min(positionX + layouts.width + config.revealMargin, popupTiler.width);
                let triggerTop = Math.max(positionY - config.revealMargin, 0);
                let triggerBottom = Math.min(positionY + totalHeight + config.revealMargin, popupTiler.height);
                let leftTop = Workspace.activeScreen.mapToGlobal(Qt.point(triggerLeft, triggerTop));
                let rightBottom = Workspace.activeScreen.mapToGlobal(Qt.point(triggerRight, triggerBottom));
                revealBox = { left: leftTop.x, right: rightBottom.x, top: leftTop.y, bottom: rightBottom.y };
                updateRevealed(true);
            } else {
                revealBox = null;
                updateRevealed(true);
            }
        }
    }

    function getGeometry() {
        if (activeLayoutIndex >= 0 && activeTileIndex >= 0) {
            if (root.centerInTile && hasValidPopupDropHint) {
                return {
                    x: clientArea.x + popupDropHintX,
                    y: clientArea.y + popupDropHintY,
                    width: popupDropHintWidth,
                    height: popupDropHintHeight
                };
            } else if (layoutRepeater.model[activeLayoutIndex].special) {
                return {
                    special: layoutRepeater.model[activeLayoutIndex].special,
                    specialMode: activeTileIndex
                };
            } else if (!root.centerInTile) {
                return {
                    x: clientArea.x + popupDropHintX,
                    y: clientArea.y + popupDropHintY,
                    width: popupDropHintWidth,
                    height: popupDropHintHeight
                };
            }
        }
        return null;
    }

    function getActiveVirtualDesktopIndex() {
        return activeVirtualDesktopIndex;
    }

    function resetVirtualDesktopOverride() {
        virtualDesktopVisibilityOverride = false;
    }

    function toggleShowAll() {
        reset();
        if (!virtualDesktopVisibilityOverride) {
            virtualDesktopVisibilityOverride = true;
        } else {
            showAll = !showAll;
            updateHintContent();
        }
    }

    function updateAndShowPopupDropHint() {
        let shouldShowPopupDropHint = false;
        let special = layoutRepeater.model[activeLayoutIndex].special;
        let geometry = null;
        switch (special) {
            case 'SPECIAL_FILL':
                if (root.currentlyMovedWindow != null) {
                    geometry = root.getFillGeometry(root.currentlyMovedWindow, activeTileIndex == 0);
                }
                break;
            case 'SPECIAL_SPLIT_VERTICAL':
                if (root.currentlyMovedWindow != null) {
                    geometry = splitAndMoveSplitted(root.currentlyMovedWindow, true, activeTileIndex == 0, false);
                }
                break;
            case 'SPECIAL_SPLIT_HORIZONTAL':
                if (root.currentlyMovedWindow != null) {
                    geometry = splitAndMoveSplitted(root.currentlyMovedWindow, false, activeTileIndex == 0, false);
                }
                break;
            case 'SPECIAL_NO_TITLEBAR_AND_FRAME':
            case 'SPECIAL_KEEP_ABOVE':
            case 'SPECIAL_KEEP_BELOW':
            case 'SPECIAL_EMPTY':
            case 'SPECIAL_MINIMIZE':
            case 'SPECIAL_CLOSE':
                break;
            default:
                let layout = layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex];
                let hintWidth = layout.w == undefined ? layout.pxW : layout.w / 100 * clientArea.width;
                let hintHeight = layout.h == undefined ? layout.pxH : layout.h / 100 * clientArea.height;
                let hintX = (layout.x == undefined ? layout.pxX : layout.x / 100 * clientArea.width) - (layout.aX == undefined ? 0 : layout.aX * hintWidth / 100);
                let hintY = (layout.y == undefined ? layout.pxY : layout.y / 100 * clientArea.height) - (layout.aY == undefined ? 0 : layout.aY * hintHeight / 100);
                if (root.centerInTile) {
                    popupDropHintWidth = root.currentlyMovedWindow.width;
                    popupDropHintHeight = root.currentlyMovedWindow.height;
                    popupDropHintX = hintX + hintWidth / 2 - root.currentlyMovedWindow.width / 2;
                    popupDropHintY = hintY + hintHeight / 2 - root.currentlyMovedWindow.height / 2;
                } else {
                    popupDropHintWidth = hintWidth;
                    popupDropHintHeight = hintHeight;
                    popupDropHintX = hintX;
                    popupDropHintY = hintY;
                }
                showPopupDropHint = root.config.showTargetTileHint;
                hasValidPopupDropHint = true;
                return; // Force return to avoid hiding popup
        }
        if (geometry != null) {
            if (root.centerInTile) {
                popupDropHintX = (geometry.x - clientArea.x) + geometry.width / 2 - root.currentlyMovedWindow.width / 2;
                popupDropHintY = (geometry.y - clientArea.y) + geometry.height / 2 - root.currentlyMovedWindow.height / 2;
                popupDropHintWidth = root.currentlyMovedWindow.width;
                popupDropHintHeight = root.currentlyMovedWindow.height;
                shouldShowPopupDropHint = true;
            } else {
                popupDropHintX = geometry.x - clientArea.x;
                popupDropHintY = geometry.y - clientArea.y;
                popupDropHintWidth = geometry.width;
                popupDropHintHeight = geometry.height;
                shouldShowPopupDropHint = true;
            }
        }
        if (root.config.showTargetTileHint) {
            showPopupDropHint = shouldShowPopupDropHint;
        } else {
            showPopupDropHint = false;
        }
        hasValidPopupDropHint = shouldShowPopupDropHint;
    }

    function updateHintContent() {
        if (activeVirtualDesktopIndex >= 0) {
            hasValidPopupDropHint = false;
            showPopupDropHint = false;
            if (root.virtualDesktops[activeVirtualDesktopIndex].isAdd) {
                switch (config.virtualDesktopDropAction) {
                    case 0:
                        hint = '<b>Drop</b> - Add new virtual desktop and move window';
                        break;
                    case 1:
                        hint = '<b>Drop</b> - Add new virtual desktop and maximize window';
                        break;
                }
            } else {
                let virtualDesktopName = root.virtualDesktops[activeVirtualDesktopIndex].desktop.name;
                switch (config.virtualDesktopDropAction) {
                    case 0:
                        hint = '<b>Hover</b> - Switch to ' + virtualDesktopName + '<br><b>Drop</b> - Move window to ' + virtualDesktopName;
                        break;
                    case 1:
                        hint = '<b>Hover</b> - Switch to ' + virtualDesktopName + '<br><b>Drop</b> - Maximize window on ' + virtualDesktopName;
                        break;
                }
            }
        } else if (!virtualDesktopVisibilityOverride && root.config.virtualDesktopVisibility == 1) {
            hint = "Show tiler (<b>" + root.config.shortcutShowAllSpan + "</b>)";
            hasValidPopupDropHint = false;
            showPopupDropHint = false;
        } else if (activeLayoutIndex >= 0 && activeTileIndex >= 0) {
            updateAndShowPopupDropHint();
            popupDropHintIsCenterInTile = root.centerInTile;
            let special = layoutRepeater.model[activeLayoutIndex].special;
            let tile = layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex];
            if (root.centerInTile && hasValidPopupDropHint) {
                hint = '<b>Center in tile</b> - will not resize the window' + (root.config.hintCenterInTile ? '<br>Toggle with <b>' + root.config.shortcutCenterInTile + '</b>' : '');
            } else if (tile.hint) {
                switch (special) {
                    case 'SPECIAL_KEEP_ABOVE':
                        hint = tile.hint + '<br>Currently <b>' + (root.currentlyMovedWindow.keepAbove ? 'Enabled' : 'Disabled') + '</b>';
                        break;
                    case 'SPECIAL_KEEP_BELOW':
                        hint = tile.hint + '<br>Currently <b>' + (root.currentlyMovedWindow.keepBelow ? 'Enabled' : 'Disabled') + '</b>';
                        break;
                    case 'SPECIAL_FILL':
                        hint = hasValidPopupDropHint ? tile.hint : '<font color="orange">⚠</font> No free space available';
                        break;
                    case 'SPECIAL_SPLIT_HORIZONTAL':
                    case 'SPECIAL_SPLIT_VERTICAL':
                        hint = hasValidPopupDropHint ? tile.hint : '<font color="orange">⚠</font> No window available for splitting';
                        break;
                    default:
                        hint = tile.hint;
                        break;
                }
            } else if ((root.config.showSizeHint || root.config.showPositionHint) && !special) {
                hint = '';

                if (root.config.showPositionHint) {
                    if (root.config.showPositionHintInPixels) {
                        hint += 'X: <b>' + Math.round(popupDropHintX) + '</b> Y: <b>' + Math.round(popupDropHintY) + '</b>';
                    } else {
                        hint += 'X: <b>' + Math.round(100 * popupDropHintX / clientArea.width) + '</b>% Y: <b>' + Math.round(100 * popupDropHintY / clientArea.height) + '</b>%';
                    }
                }
                if (root.config.showSizeHint) {
                    if (hint.length > 0) {
                        hint += '<br>';
                    }
                    if (root.config.showSizeHintInPixels) {
                        hint += 'W: <b>' + Math.round(popupDropHintWidth) + '</b> H: <b>' + Math.round(popupDropHintHeight) + '</b>';
                    } else {
                        hint += 'W: <b>' + Math.round(100 * popupDropHintWidth / clientArea.width) + '</b>% H: <b>' + Math.round(100 * popupDropHintHeight / clientArea.height) + '</b>%';
                    }
                }
            } else {
                hint = null;
            }
        } else {
            hasValidPopupDropHint = false;
            showPopupDropHint = false;
            hint = null;
        }

        if (hint == null) {
            let defaultHint = "";
            let hasShortcutHint = false;

            if (root.config.showHintHint) {
                defaultHint += (defaultHint.length > 0 ? " " : "") + "Configure tiler visibility and these hints in settings.<br>";
            }
            if (root.config.hintShowAllSpan) {
                defaultHint += (hasShortcutHint ? " - " : "") + (showAll ? "Show default (<b>" + root.config.shortcutShowAllSpan + "</b>)" : "Show all (<b>" + root.config.shortcutShowAllSpan + "</b>)");
                hasShortcutHint = true;
            }
            if (root.config.hintVisibility) {
                defaultHint += (hasShortcutHint ? " - " : "") + "Visibility (<b>" + root.config.shortcutVisibility + "</b>)";
                hasShortcutHint = true;
            }
            if (root.config.hintChangeMode) {
                defaultHint += (hasShortcutHint ? " - " : "") + "Mode (<b>" + root.config.shortcutChangeMode + "</b>)";
                hasShortcutHint = true;
            }
            if (root.config.hintInputType) {
                defaultHint += (hasShortcutHint ? " - " : "") + "Input type (<b>" + root.config.shortcutInputType + "</b>)";
                hasShortcutHint = true;
            }
            if (root.config.hintCenterInTile) {
                defaultHint += (hasShortcutHint ? " - " : "") + "Center in tile (<b>" + root.config.shortcutCenterInTile + "</b>)";
                hasShortcutHint = true;
            }

            if (defaultHint.length > 0) {
                hint = defaultHint;
            }
        }
    }

    function updateRevealed(forceUpdate = false) {
        var updatedRevealed;
        if (revealBox == null) {
            updatedRevealed = true;
        } else {
            let x = root.getCursorPosition().x;
            let y = root.getCursorPosition().y;
            updatedRevealed = revealBox.left <= x && revealBox.right >= x && revealBox.top <= y && revealBox.bottom >= y;
        }

        if (forceUpdate || updatedRevealed != revealed) {
            revealed = updatedRevealed;
            root.updateWindowVisibility();
        }
    }

    Item {
        anchors.fill: parent
        visible: revealed

        SequentialAnimation {
            id: showPopupTilerAnimation
            running: false

            NumberAnimation {
                target: popupTiler;
                property: "opacity";
                from: 0;
                to: 0;
                duration: 32;
            }

            NumberAnimation {
                target: popupTiler;
                property: "opacity";
                from: 1;
                to: 1;
                duration: 1;
            }

            onFinished: {
                root.updateWindowVisibility();
            }
        }

        Colors {
            id: colors
        }

        Rectangle {
            id: popupDropHint
            anchors.left: parent.left
            anchors.leftMargin: popupDropHintX
            anchors.top: parent.top
            anchors.topMargin: popupDropHintY
            width: popupDropHintWidth
            height: popupDropHintHeight
            border.color: colors.tileBorderColor
            border.width: 2
            color: "transparent"
            radius: 12
            visible: showPopupDropHint

            Rectangle {
                anchors.fill: parent
                color: colors.hintBackgroundColor
                radius: 12
            }
        }

        Rectangle {
            id: layouts
            width: layoutGrid.implicitWidth + layoutGrid.columnSpacing * 2
            height: layoutGrid.implicitHeight + layoutGrid.rowSpacing * 2
            color: colors.backgroundColor
            border.color: colors.borderColor
            border.width: 1
            radius: 8
            visible: virtualDesktopVisibilityOverride || root.config.virtualDesktopVisibility != 1

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: parent.top
            anchors.topMargin: positionY

            GridLayout {
                id: layoutGrid
                columns: showAll ? root.config.gridAllColumns : root.config.gridColumns
                columnSpacing: root.config.gridSpacing
                rowSpacing: root.config.gridSpacing
                anchors.fill: parent
                anchors.margins: root.config.gridSpacing
                uniformCellWidths: true
                uniformCellHeights: true

                Repeater {
                    id: layoutRepeater
                    model: showAll ? root.config.allLayouts : root.config.layouts

                    Rectangle {
                        id: tiles
                        width: root.config.gridWidth
                        height: root.config.gridHeight
                        color: "transparent"
                        border.color: colors.borderColor
                        border.width: 1
                        radius: 8

                        property bool layoutActive: activeLayoutIndex == index

                        Repeater {
                            id: tileRepeater
                            model: modelData.tiles

                            Item {
                                id: tile

                                property bool tileActive: activeTileIndex == index
                                property bool tileDisabled: modelData.d ? true : false

                                width: (modelData.w == undefined ? modelData.pxW / clientArea.width : modelData.w / 100) * (tiles.width - borderOffset * 2)
                                height: (modelData.h == undefined ? modelData.pxH / clientArea.height : modelData.h / 100) * (tiles.height - borderOffset * 2)
                                x: (modelData.x == undefined ? modelData.pxX / clientArea.width : modelData.x / 100) * (tiles.width - borderOffset * 2) + borderOffset - (modelData.aX == undefined ? 0 : modelData.aX * width / 100)
                                y: (modelData.y == undefined ? modelData.pxY / clientArea.height : modelData.y / 100) * (tiles.height - borderOffset * 2) + borderOffset - (modelData.aY == undefined ? 0 : modelData.aY * height / 100)

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: tilePadding
                                    border.color: colors.tileBorderColor
                                    border.width: 1
                                    // color: "#152030"
                                    color: "transparent"
                                    radius: 6
                                    opacity: tileDisabled ? 0.3 : 1

                                    Rectangle {
                                        anchors.fill: parent
                                        color: layoutActive && tileActive ? colors.tileBackgroundColorActive : colors.tileBackgroundColor
                                        radius: 6
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        color: colors.textColor
                                        textFormat: Text.StyledText
                                        // ⸰ ·
                                        text: root.centerInTile && layoutActive && tileActive && hasValidPopupDropHint ? "⸰" : (modelData.t && modelData.t.length > 0 ? modelData.t : "")
                                        font.pixelSize: 14
                                        font.family: "Noto Sans"
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: root.centerInTile && layoutActive && tileActive && hasValidPopupDropHint ? true : (modelData.t ? modelData.t : false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: virtualDesktop
            width: layoutGrid.implicitWidth + layoutGrid.columnSpacing * 2
            height: virtualDesktopLayout.implicitHeight + layoutGrid.rowSpacing * 2
            color: colors.backgroundColor
            border.color: colors.borderColor
            border.width: 1
            radius: 8
            visible: root.virtualDesktopVisibile

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: layouts.visible ? layouts.bottom : parent.top
            anchors.topMargin: layouts.visible ? 2 : positionY

            GridLayout {
                id: virtualDesktopLayout
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                rowSpacing: 1
                columnSpacing: 1
                columns: layoutGrid.implicitWidth / 35

                Repeater {
                    id: virtualDesktopRepeater
                    model: root.virtualDesktops

                    Item {
                        id: virtualDesktop

                        property bool currentVirtualDesktop: root.currentVirtualDesktopIndex == index
                        property bool activeVirtualDesktop: activeVirtualDesktopIndex == index

                        width: 34
                        height: 34

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: tilePadding
                            border.color: colors.tileBorderColor
                            border.width: 1
                            color: "transparent"
                            radius: 6

                            Rectangle {
                                anchors.fill: parent
                                color: activeVirtualDesktop ? colors.tileBackgroundColorActive : colors.tileBackgroundColor
                                radius: 6
                            }

                            Text {
                                anchors.centerIn: parent
                                color: colors.textColor
                                textFormat: Text.StyledText
                                text: modelData.isAdd ? "+" : "⸰"
                                font.pixelSize: 14
                                font.family: "Noto Sans"
                                horizontalAlignment: Text.AlignHCenter
                                visible: modelData.isAdd || currentVirtualDesktop
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: popupHint
            width: layoutGrid.implicitWidth + layoutGrid.columnSpacing * 2
            height: popupHintText.implicitHeight + layoutGrid.rowSpacing * 2
            color: colors.backgroundColor
            border.color: colors.borderColor
            border.width: 1
            radius: 8
            visible: root.config.showTextHint && hint != null

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: virtualDesktop.visible ? virtualDesktop.bottom : layouts.bottom
            anchors.topMargin: 2

            Text {
                id: popupHintText
                width: parent.width - 4
                anchors.centerIn: parent
                color: colors.textColor
                textFormat: Text.StyledText
                text: hint != null ? hint : ""
                font.pixelSize: 12
                font.family: "Noto Sans"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        Rectangle {
            id: popupWindowCursor
            anchors.left: parent.left
            anchors.leftMargin: root.getCursorPosition().x - clientArea.x - 6
            anchors.top: parent.top
            anchors.topMargin: root.getCursorPosition().y - clientArea.y - 6
            width: 12
            height: 12
            border.color: colors.tileBorderColor
            border.width: 2
            color: colors.tileBackgroundColorActive
            radius: 6
            visible: !root.useMouseCursor

            Rectangle {
                anchors.centerIn: parent
                width: 2
                height: 2
                color: colors.textColor
                radius: 1
                opacity: 0.8
            }
        }

        Timer {
            interval: 1
            repeat: false
            running: popupTiler.visible && !sizeEstablished
            onTriggered: {
                sizeEstablished = true;
                updateScreen(true);
            }
        }

        Timer {
            interval: root.config.popupGridPollingRate
            repeat: true
            running: popupTiler.visible
            onTriggered: {
                let forceUpdate = lastShowAll != showAll;

                if (forceUpdate) {
                    if (showAll) {
                        lastShowAll = true;
                    } else {
                        lastShowAll = false;
                    }
                }
                updateScreen(forceUpdate);

                updateRevealed();

                let x = root.getCursorPosition().x;
                let y = root.getCursorPosition().y;
                let layoutIndex = -1;
                let tileIndex = -1;
                let virtualDesktopIndex = -1;

                if (root.config.windowVisibility == 2) {
                    var updatedHovered;
                    let layoutsPosition = layouts.mapToGlobal(Qt.point(0, 0));
                    let visibleHeight = (layouts.visible ? layouts.height : 0) + (virtualDesktop.visible ? virtualDesktop.height : 0) + (layouts.visible && virtualDesktop.visible ? 2 : 0)
                    if (layoutsPosition.x <= x && layoutsPosition.x + layouts.width >= x && layoutsPosition.y <= y && layoutsPosition.y + visibleHeight >= y) {
                        updatedHovered = true;
                    } else {
                        updatedHovered = false;
                    }
                    if (updatedHovered != currentlyHovered) {
                        currentlyHovered = updatedHovered;
                        root.updateWindowVisibility();
                    }
                }

                if (layouts.visible) {
                    for (let i = 0; i < layoutRepeater.count; i++) {
                        let currentLayout = layoutRepeater.itemAt(i);
                        let currentLayoutPosition = currentLayout.mapToGlobal(Qt.point(0, 0));

                        if (currentLayoutPosition.x <= x && currentLayoutPosition.x + currentLayout.width >= x && currentLayoutPosition.y <= y && currentLayoutPosition.y + currentLayout.height >= y) {
                            layoutIndex = i;
                            // if (layoutRepeater.model[layoutIndex].special) {
                            //     tileIndex = 0;
                            // } else {
                                //for (let j = 0; j < currentLayout.children.length; j++) {
                                for (let j = currentLayout.children.length - 1; j >= 0; j--) {
                                    let currentTile = currentLayout.children[j];
                                    // if (currentTile.tileDisabled) {
                                    //     continue;
                                    // }
                                    let currentTilePosition = currentTile.mapToGlobal(Qt.point(0, 0));
                                    if (currentTilePosition.x <= x && currentTilePosition.x + currentTile.width >= x && currentTilePosition.y <= y && currentTilePosition.y + currentTile.height >= y) {
                                        tileIndex = j;
                                        break;
                                    }
                                }
                            // }
                            break;
                        }
                    }
                }

                if (root.virtualDesktopVisibile && layoutIndex == -1) {
                    for (let i = 0; i < virtualDesktopRepeater.count; i++) {
                        let currentVirtualDesktop = virtualDesktopRepeater.itemAt(i);
                        let currentVirtualDesktopPosition = currentVirtualDesktop.mapToGlobal(Qt.point(0, 0));
                        if (currentVirtualDesktopPosition.x <= x && currentVirtualDesktopPosition.x + currentVirtualDesktop.width >= x && currentVirtualDesktopPosition.y <= y && currentVirtualDesktopPosition.y + currentVirtualDesktop.height >= y) {
                            virtualDesktopIndex = i;
                        }
                    }
                }

                let switchVirtualDesktop = virtualDesktopIndex != -1 && !root.virtualDesktops[virtualDesktopIndex].isAdd && virtualDesktopIndex != root.currentVirtualDesktopIndex;
                if (activeVirtualDesktopIndex != virtualDesktopIndex) {
                    activeVirtualDesktopIndex = virtualDesktopIndex;
                    if (switchVirtualDesktop) {
                        if (config.virtualDesktopHoverTime == 0) {
                            Workspace.currentDesktop = root.virtualDesktops[activeVirtualDesktopIndex].desktop;
                        } else {
                            activeVirtualDesktopHoverTime = Date.now();
                        }
                    }
                    updateHintContent();
                } else if (switchVirtualDesktop && config.virtualDesktopHoverTime > 0 && Date.now() - activeVirtualDesktopHoverTime > config.virtualDesktopHoverTime) {
                    Workspace.currentDesktop = root.virtualDesktops[activeVirtualDesktopIndex].desktop;
                }

                // TODO: Add support for negative values (-)
                // TODO: Span more than 1 layout if x < 0 || y < 0 || w > 100 || h > 100 to support SPECIAL_EMPTY
                if (layoutIndex != activeLayoutIndex || tileIndex != activeTileIndex) {
                    activeLayoutIndex = layoutIndex;
                    activeTileIndex = tileIndex;
                    updateHintContent();
                } else if (popupDropHintIsCenterInTile != root.centerInTile && activeLayoutIndex >= 0 && activeTileIndex >= 0) {
                    updateHintContent();
                    popupDropHintIsCenterInTile = root.centerInTile;
                }
            }
        }
    }
}