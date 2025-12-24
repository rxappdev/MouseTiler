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
        }
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
            let layoutActive = tileRepeater.model[activeIndex];
            let layoutSpan = tileRepeater.model[spanFromIndex];
            minSpanX = Math.min(layoutActive.x, layoutSpan.x);
            minSpanY = Math.min(layoutActive.y, layoutSpan.y);
            maxSpanX = Math.max(layoutActive.x + layoutActive.w, layoutSpan.x + layoutSpan.w);
            maxSpanY = Math.max(layoutActive.y + layoutActive.h, layoutSpan.y + layoutSpan.h);
        }
        root.log('Span activeIndex: ' + activeIndex + ' spanFromIndex: ' + spanFromIndex + ' minSpanX: ' + minSpanX + ' minSpanY: ' + minSpanY + ' maxSpanX: ' + maxSpanX + ' maxSpanY: ' + maxSpanY);
    }

    function getGeometry() {
        if (activeIndex >= 0) {
            if (spanFromIndex >= 0) {
                return {
                    x: clientArea.x + minSpanX / 100 * clientArea.width,
                    y: clientArea.y + minSpanY / 100 * clientArea.height,
                    width: (maxSpanX - minSpanX) / 100 * clientArea.width,
                    height: (maxSpanY - minSpanY) / 100 * clientArea.height
                };
            } else {
                let layout = tileRepeater.model[activeIndex];
                return {
                    x: clientArea.x + layout.x / 100 * clientArea.width,
                    y: clientArea.y + layout.y / 100 * clientArea.height,
                    width: layout.w / 100 * clientArea.width,
                    height: layout.h / 100 * clientArea.height
                };
            }
        }
        return null;
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
        }

        Colors {
            id: colors
        }

        Repeater {
            id: tileRepeater
            model: root.config.overlay

            Item {
                id: tile

                property bool active: activeIndex == index
                property bool spanned: !active && modelData.x >= minSpanX && modelData.x + modelData.w <= maxSpanX && modelData.y >= minSpanY && modelData.y + modelData.h <= maxSpanY
                property bool spannedFrom: spanFromIndex == index

                x: modelData.x / 100 * tiles.width
                y: modelData.y / 100 * tiles.height
                width: modelData.w / 100 * tiles.width
                height: modelData.h / 100 * tiles.height

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
                        text: spannedFrom ? "Stop spanning (<b>Ctrl+Space</b> by default)<br>Toggle visibility (<b>Meta+Space</b> by default)<br><br>Switch mode (<b>Ctrl+Meta+Space</b> by default)" : "Span from this tile (<b>Ctrl+Space</b> by default)<br>Toggle visibility (<b>Meta+Space</b> by default)<br><br>Switch mode (<b>Ctrl+Meta+Space</b> by default)"
                        font.pixelSize: 16
                        font.family: "Hack"
                        horizontalAlignment: Text.AlignHCenter
                        visible: root.config.showOverlayTextHint && (active && spanFromIndex == -1 || spannedFrom)
                    }
                }
            }
        }

        Timer {
            interval: root.config.overlayPollingRate
            repeat: true
            running: overlayTiler.visible
            onTriggered: {
                updateScreen();

                let localCursorPos = Workspace.activeScreen.mapFromGlobal(Workspace.cursorPos);
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