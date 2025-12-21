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
    property var popupDropHintX: 0
    property var popupDropHintY: 0
    property var popupDropHintWidth: 0
    property var popupDropHintHeight: 0
    property bool sizeEstablished: false

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
        showPopupDropHint = false;
    }

    function resetShowAll() {
        showAll = false;
        lastShowAll = false;
    }

    function updateScreen(forceUpdate = false) {
        if (forceUpdate || activeScreen != Workspace.activeScreen) {
            root.logE('updateScreen ' + Workspace.virtualScreenSize);
            activeScreen = Workspace.activeScreen;
            clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop);

            let localCursorPos = Workspace.activeScreen.mapFromGlobal(Workspace.cursorPos);

            if (root.config.popupGridAtMouse) {
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

            // positionX = localCursorPos.x - layouts.width / 2;
            // positionY = localCursorPos.y - (layouts.height + popupHint.height + 2) / 2;

            if (positionX < 0) {
                positionX = 0;
            } else if (positionX + layouts.width > popupTiler.width) {
                positionX = popupTiler.width - layouts.width;
            }

            if (positionY < 0) {
                positionY = 0;
            } else if (root.config.showTextHint && positionY + layouts.height + popupHint.height + 2 > popupTiler.height) {
                positionY = popupTiler.height - layouts.height - popupHint.height - 2;
            } else if (!root.config.showTextHint && positionY + layouts.height > popupTiler.height) {
                positionY = popupTiler.height - layouts.height;
            }
        }
    }

    function getGeometry() {
        if (activeLayoutIndex >= 0 && activeTileIndex >= 0 && layoutRepeater.model[activeLayoutIndex].special) {
            return {
                special: layoutRepeater.model[activeLayoutIndex].special,
                specialMode: activeTileIndex
            };
        } else if (activeLayoutIndex >= 0 && activeTileIndex >= 0) {
            let layout = layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex];
            return {
                x: clientArea.x + layout.x / 100 * clientArea.width,
                y: clientArea.y + layout.y / 100 * clientArea.height,
                width: layout.w / 100 * clientArea.width,
                height: layout.h / 100 * clientArea.height
            };
        }
        return null;
    }

    function toggleShowAll() {
        reset();
        showAll = !showAll;
    }

    function updateAndShowPopupDropHint() {
        if (root.config.showTargetTileHint) {
            let special = layoutRepeater.model[activeLayoutIndex].special;
            let geometry;
            switch (special) {
                case 'SPECIAL_FILL':
                    if (root.currentMoveWindow != null) {
                        geometry = root.getFillGeometry(root.currentMoveWindow, activeTileIndex == 0);
                    }
                    break;
                case 'SPECIAL_SPLIT_VERTICAL':
                    if (root.currentMoveWindow != null) {
                        geometry = splitAndMoveSplitted(root.currentMoveWindow, true, activeTileIndex == 0, false);
                    }
                    break;
                case 'SPECIAL_SPLIT_HORIZONTAL':
                    if (root.currentMoveWindow != null) {
                        geometry = splitAndMoveSplitted(root.currentMoveWindow, false, activeTileIndex == 0, false);
                    }
                    break;
                default:
                    let layout = layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex];
                    popupDropHintX = layout.x / 100 * clientArea.width;
                    popupDropHintY = layout.y / 100 * clientArea.height;
                    popupDropHintWidth = layout.w / 100 * clientArea.width;
                    popupDropHintHeight = layout.h / 100 * clientArea.height;
                    showPopupDropHint = true;
                    return; // Force return to avoid hiding popup
            }
            if (geometry != null) {
                popupDropHintX = geometry.x - clientArea.x;
                popupDropHintY = geometry.y - clientArea.y;
                popupDropHintWidth = geometry.width;
                popupDropHintHeight = geometry.height;
                showPopupDropHint = true;
            } else {
                showPopupDropHint = false;
            }
        }
    }

    Item {
        anchors.fill: parent

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

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: parent.top
            anchors.topMargin: positionY

            GridLayout {
                id: layoutGrid
                columns: showAll ? 4 : root.config.gridColumns
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

                                x: (modelData.x / 100 * (tiles.width - borderOffset * 2)) + borderOffset
                                y: (modelData.y / 100 * (tiles.height - borderOffset * 2)) + borderOffset
                                width: modelData.w / 100 * (tiles.width - borderOffset * 2)
                                height: modelData.h / 100 * (tiles.height - borderOffset * 2)

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
                                        text: modelData.t && modelData.t.length > 0 ? modelData.t : ""
                                        font.pixelSize: 14
                                        font.family: "Hack"
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: modelData.t ? modelData.t : false
                                    }
                                }
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
            visible: root.config.showTextHint

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: layouts.bottom
            anchors.topMargin: 2

            Text {
                id: popupHintText
                width: parent.width - 4
                anchors.centerIn: parent
                color: colors.textColor
                textFormat: Text.StyledText
                text: hint != null ? hint : showAll ? "Show default (<b>Ctrl+Space</b>) Visibility (<b>Meta+Space</b>) Mode (<b>Ctrl+Meta+Space</b>)" : "Show all (<b>Ctrl+Space</b>) Visibility (<b>Meta+Space</b>) Mode (<b>Ctrl+Meta+Space</b>)"
                font.pixelSize: 12
                font.family: "Hack"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
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

                let x = Workspace.cursorPos.x;
                let y = Workspace.cursorPos.y;
                let layoutIndex = -1;
                let tileIndex = -1;

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
                if (layoutIndex != activeLayoutIndex || tileIndex != activeTileIndex) {
                    activeLayoutIndex = layoutIndex;
                    activeTileIndex = tileIndex;

                    if (activeLayoutIndex >= 0 && activeTileIndex >= 0) {
                        updateAndShowPopupDropHint();
                        if (layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex].hint) {
                            hint = layoutRepeater.model[activeLayoutIndex].tiles[activeTileIndex].hint;
                        } else {
                            hint = null;
                        }
                    } else {
                        showPopupDropHint = false;
                        hint = null;
                    }
                }
            }
        }
    }
}