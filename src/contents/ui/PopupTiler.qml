import QtQuick
import QtQuick.Layouts
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmaCore.Dialog {
    id: popupTiler

    property var activeScreen: null
    property var clientArea: {}
    property var config
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
    }

    function resetShowAll() {
        showAll = false;
        lastShowAll = false;
    }

    function screenChanged(forceUpdate = false) {
        if (forceUpdate || activeScreen != Workspace.activeScreen) {
            root.logE('screenChanged ' + Workspace.virtualScreenSize);
            activeScreen = Workspace.activeScreen;
            clientArea = Workspace.clientArea(KWin.FullScreenArea, Workspace.activeScreen, Workspace.currentDesktop);

            let localCursorPos = Workspace.activeScreen.mapFromGlobal(Workspace.cursorPos);

            positionX = localCursorPos.x - layouts.width / 2;
            positionY = localCursorPos.y - (layouts.height + popupHint.height + 2) / 2;

            if (positionX < 0) {
                positionX = 0;
            } else if (positionX + layouts.width > popupTiler.width) {
                positionX = popupTiler.width - layouts.width;
            }

            if (positionY < 0) {
                positionY = 0;
            } else if (positionY + layouts.height + popupHint.height + 2 > popupTiler.height) {
                positionY = popupTiler.height - layouts.height - popupHint.height - 2;
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
                    popupDropHintX = clientArea.x + layout.x / 100 * clientArea.width;
                    popupDropHintY = clientArea.y + layout.y / 100 * clientArea.height;
                    popupDropHintWidth = layout.w / 100 * clientArea.width;
                    popupDropHintHeight = layout.h / 100 * clientArea.height;
                    showPopupDropHint = true;
                    break;
            }
            if (geometry != null) {
                popupDropHintX = geometry.x;
                popupDropHintY = geometry.y;
                popupDropHintWidth = geometry.width;
                popupDropHintHeight = geometry.height;
                showPopupDropHint = true;
            }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: popupDropHint
            anchors.left: parent.left
            anchors.leftMargin: popupDropHintX
            anchors.top: parent.top
            anchors.topMargin: popupDropHintY
            width: popupDropHintWidth
            height: popupDropHintHeight
            border.color: "#0099FF"
            border.width: 2
            color: "transparent"
            radius: 12
            visible: showPopupDropHint

            Rectangle {
                anchors.fill: parent
                color: "#0099FF"
                radius: 12
                opacity: 0.35
            }
        }

        Rectangle {
            id: layouts
            width: layoutGrid.implicitWidth + layoutGrid.columnSpacing * 2
            height: layoutGrid.implicitHeight + layoutGrid.rowSpacing * 2
            color: "#161925"
            border.color: "#666666"
            border.width: 1
            radius: 8

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: parent.top
            anchors.topMargin: positionY

            GridLayout {
                id: layoutGrid
                columns: showAll ? 4 : 3
                columnSpacing: 10
                rowSpacing: 10
                anchors.fill: parent
                anchors.margins: columnSpacing
                uniformCellWidths: true
                uniformCellHeights: true

                Repeater {
                    id: layoutRepeater
                    model: showAll ? root.config.allLayouts : root.config.layouts

                    Rectangle {
                        id: tiles
                        width: 130
                        height: 70
                        color: "transparent"
                        border.color: "#666666"
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
                                    border.color: "#0099FF"
                                    border.width: 1
                                    // color: "#152030"
                                    color: "transparent"
                                    radius: 6
                                    opacity: tileDisabled ? 0.3 : 1

                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#0099FF"
                                        radius: 6
                                        opacity: layoutActive && tileActive ? 0.75 : 0.05
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        color: "white"
                                        textFormat: Text.StyledText
                                        text: modelData.t && modelData.t.length > 0 ? modelData.t : ""
                                        font.pixelSize: 16
                                        font.family: "Hack"
                                        horizontalAlignment: Text.AlignHCenter
                                        visible: modelData.t
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
            color: "#161925"
            border.color: "#666666"
            border.width: 1
            radius: 8

            anchors.left: parent.left
            anchors.leftMargin: positionX
            anchors.top: layouts.bottom
            anchors.topMargin: 2

            Text {
                id: popupHintText
                width: parent.width
                anchors.centerIn: parent
                color: "white"
                textFormat: Text.StyledText
                text: hint != null ? hint : showAll ? "Show default (<b>Ctrl+Space</b>) Visibility (<b>Meta+Space</b>) Mode (<b>Ctrl+Meta+Space</b>)" : "Show all (<b>Ctrl+Space</b>) Visibility (<b>Meta+Space</b>) Mode (<b>Ctrl+Meta+Space</b>)"
                font.pixelSize: 12
                font.family: "Hack"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }
        }

        Timer {
            interval: 100
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
                screenChanged(forceUpdate);

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