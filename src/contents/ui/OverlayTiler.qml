import QtQuick
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore

PlasmaCore.Dialog {
    id: overlayTiler

    property var activeScreen: null
    property var clientArea: ({width: 0, height: 0, x: 0, y: 0})
    property var tilePadding: 2
    property int activeIndex: -1
    property int spanFromIndex: -1
    property int minSpanX: -1
    property int minSpanY: -1
    property int maxSpanX: -1
    property int maxSpanY: -1
    property var convertedOverlay: ([])

    width: clientArea.width - root.config.overlayScreenEdgeMargin * 2
    height: clientArea.height - root.config.overlayScreenEdgeMargin * 2
    x: clientArea.x + root.config.overlayScreenEdgeMargin
    y: clientArea.y + root.config.overlayScreenEdgeMargin
    flags: Qt.Popup | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
    visible: false
    backgroundHints: PlasmaCore.Types.NoBackground
    outputOnly: true
    // type: PlasmaCore.Dialog.OnScreenDisplay
    location: PlasmaCore.Types.Desktop

    function reset() {
        activeScreen = null;
        spanFromIndex = -1;
        activeIndex = -1;
        updateSpan();
    }

    function startAnimations() {
        overlayTiler.opacity = 0;
        showOverlayTilerAnimation.start();
    }

    function updateScreen() {
        if (activeScreen != Workspace.activeScreen) {
            root.logE('updateScreen ' + Workspace.virtualScreenSize);
            reset();
            activeScreen = Workspace.activeScreen;
            clientArea = Workspace.clientArea(KWin.FullScreenArea, activeScreen, Workspace.currentDesktop);
            convertLayoutToScreen();
        }
    }

    function convertLayoutToScreen() {
        let layout = root.config.overlay;
        let converted = [];
        for (let i = 0; i < layout.length; i++) {
            let tile = layout[i];
            let width = (tile.pxW == undefined ? tile.w / 100 * tiles.width : tile.pxW);
            let height = (tile.pxH == undefined ? tile.h / 100 * tiles.height : tile.pxH);
            converted.push({
                pxX: (tile.pxX == undefined ? tile.x / 100 * tiles.width : tile.pxX) - (tile.aX == undefined ? 0 : tile.aX * width / 100),
                pxY: (tile.pxY == undefined ? tile.y / 100 * tiles.height : tile.pxY) - (tile.aY == undefined ? 0 : tile.aY * height / 100),
                pxW: width,
                pxH: height
            });
        }
        convertedOverlay = converted;
    }

    function toggleSpan() {
        if (spanFromIndex != activeIndex && spanFromIndex == -1) {
            spanFromIndex = activeIndex;
            updateSpan();
        } else if (spanFromIndex >= 0) {
            spanFromIndex = -1;
            updateSpan();
        }
    }

    function updateSpan() {
        if (activeIndex == -1 || spanFromIndex == -1) {
            minSpanX = -1;
            minSpanY = -1;
            maxSpanX = -1;
            maxSpanY = -1;
        } else {
            let itemActive = tileRepeater.itemAt(activeIndex);
            let itemSpan = tileRepeater.itemAt(spanFromIndex);
            minSpanX = Math.min(itemActive.x, itemSpan.x);
            minSpanY = Math.min(itemActive.y, itemSpan.y);
            maxSpanX = Math.max(itemActive.x + itemActive.width, itemSpan.x + itemSpan.width);
            maxSpanY = Math.max(itemActive.y + itemActive.height, itemSpan.y + itemSpan.height);
        }
        root.log('Span activeIndex: ' + activeIndex + ' spanFromIndex: ' + spanFromIndex + ' minSpanX: ' + minSpanX + ' minSpanY: ' + minSpanY + ' maxSpanX: ' + maxSpanX + ' maxSpanY: ' + maxSpanY);
    }

    function getGeometry() {
        if (activeIndex >= 0) {
            let x, y, width, height;
            if (spanFromIndex >= 0) {
                x = clientArea.x + minSpanX;
                y = clientArea.y + minSpanY;
                width = maxSpanX - minSpanX;
                height = maxSpanY - minSpanY;
            } else {
                let item = tileRepeater.itemAt(activeIndex);
                x = clientArea.x + item.x;
                y = clientArea.y + item.y;
                width = item.width;
                height = item.height;
            }
            if (root.centerInTile) {
                return {
                    x: x + width / 2 - root.currentlyMovedWindow.width / 2,
                    y: y + height / 2 - root.currentlyMovedWindow.height / 2,
                    width: root.currentlyMovedWindow.width,
                    height: root.currentlyMovedWindow.height
                };
            } else {
                return {
                    x: x,
                    y: y,
                    width: width,
                    height: height
                };
            }
        }
        return null;
    }

    function getActiveVirtualDesktopIndex() {
        return -1;
    }

    Item {
        id: tiles
        anchors.fill: parent

        SequentialAnimation {
            id: showOverlayTilerAnimation
            running: false

            NumberAnimation {
                target: overlayTiler;
                property: "opacity";
                from: 0;
                to: 0;
                duration: 32;
            }

            NumberAnimation {
                target: overlayTiler;
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

        Repeater {
            id: tileRepeater
            model: overlayTiler.convertedOverlay

            Item {
                id: tile

                property bool active: activeIndex == index
                property bool spanned: !active && Math.ceil(modelData.pxX) >= Math.floor(minSpanX) && Math.floor(modelData.pxX) + Math.floor(modelData.pxW) <= Math.ceil(maxSpanX) && Math.ceil(modelData.pxY) >= Math.floor(minSpanY) && Math.floor(modelData.pxY) + Math.floor(modelData.pxH) <= Math.ceil(maxSpanY)
                property bool spannedFrom: spanFromIndex == index

                x: modelData.pxX
                y: modelData.pxY
                width: modelData.pxW
                height: modelData.pxH

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: tilePadding
                    border.color: colors.tileBorderColor
                    border.width: 2
                    color: "transparent"
                    radius: 12

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        color: active || spanned ? colors.tileBackgroundColorActive : colors.tileBackgroundColor
                    }

                    Text {
                        anchors.centerIn: parent
                        color: colors.overlayTextColor
                        textFormat: Text.StyledText
                        text: {
                            let defaultHint = "";
                            let insertExtraBreak = false;

                            if (root.config.showHintHint) {
                                defaultHint += (defaultHint.length > 0 ? "<br>" : "") + "Configure tiler visibility and these hints in settings.";
                                insertExtraBreak = true;
                            }
                            if (root.config.hintShowAllSpan) {
                                if (insertExtraBreak) {
                                    defaultHint += "<br>";
                                    insertExtraBreak = false;
                                }
                                defaultHint += (defaultHint.length > 0 ? "<br>" : "") + (spannedFrom ? "Stop spanning (<b>" + root.config.shortcutShowAllSpan + "</b>)" : "Span from this tile (<b>" + root.config.shortcutShowAllSpan + "</b>)");
                                insertExtraBreak = true;
                            }
                            if (root.config.hintVisibility) {
                                if (insertExtraBreak) {
                                    defaultHint += "<br>";
                                    insertExtraBreak = false;
                                }
                                defaultHint += (defaultHint.length > 0 ? "<br>" : "") + "Toggle visibility (<b>" + root.config.shortcutVisibility + "</b>)";
                            }
                            if (root.config.hintInputType) {
                                if (insertExtraBreak) {
                                    defaultHint += "<br>";
                                    insertExtraBreak = false;
                                }
                                defaultHint += (defaultHint.length > 0 ? "<br>" : "") + "Input type: " + (root.useMouseCursor ? "Mouse" : "Window") + " (<b>" + root.config.shortcutInputType + "</b>)";
                            }
                            if (root.config.hintCenterInTile) {
                                if (insertExtraBreak) {
                                    defaultHint += "<br>";
                                    insertExtraBreak = false;
                                }
                                defaultHint += (defaultHint.length > 0 ? "<br>" : "") + "Center in tile: " + (root.centerInTile ? "Enabled" : "Disabled") + " (<b>" + root.config.shortcutCenterInTile + "</b>)";
                            }
                            if (root.config.hintChangeMode) {
                                insertExtraBreak = false;
                                defaultHint += (defaultHint.length > 0 ? "<br><br>" : "") + "Switch mode (<b>" + root.config.shortcutChangeMode + "</b>)";
                            }

                            if (root.centerInTile) {
                                return (spannedFrom ? "<b>Center in spanned tiles</b><br><br>" : "<b>Center in this tile</b><br><br>") + defaultHint;
                            } else {
                                return defaultHint;
                            }
                            return defaultHint;
                        }
                        font.pixelSize: 16
                        font.family: "Noto Sans"
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.config.showOverlayTextHint && (active && spanFromIndex == -1 || spannedFrom)
                    }
                }
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
            interval: root.config.overlayPollingRate
            repeat: true
            running: overlayTiler.visible
            onTriggered: {
                updateScreen();

                let localCursorPos = Workspace.activeScreen.mapFromGlobal(root.getCursorPosition());
                let x = localCursorPos.x - root.config.overlayScreenEdgeMargin;
                let y = localCursorPos.y - root.config.overlayScreenEdgeMargin;
                let index = -1;

                for (let i = 0; i < tileRepeater.count; i++) {
                    let item = tileRepeater.itemAt(i);
                    if (item.x <= x && item.x + item.width >= x && item.y <= y && item.y + item.height >= y) {
                        index = i;
                        break;
                    }
                }

                if (index != activeIndex) {
                    activeIndex = index;
                    updateSpan();
                }
            }
        }
    }
}