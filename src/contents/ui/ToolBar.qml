import QtQuick
import QtQuick.Layouts
import org.kde.kwin
import org.kde.plasma.core as PlasmaCore

Item {
    id: toolBar

    property list<var> toolBarItems: ([])
    property bool initialized: false
    property int activeToolBarItemIndex: -1
    property alias fullHeight: toolBarLayout.implicitHeight
    property alias fullWidth: toolBarLayout.implicitWidth

    function initToolbar() {
        if (initialized) return;

        logE('Trying to parse toolbar items: ' + config.toolBarItems);

        var userItems = config.toolBarItems.split('\n');
        var addedItems = [];
        var valid = true;

        logE('Found ' + userItems.length + ' toolbar items.');

        for (let itemIndex = 0; itemIndex < userItems.length; itemIndex++) {
            let item = userItems[itemIndex].trim();
            logE('Item ' + itemIndex + ': ' + item);

            if (addedItems.includes(item) || item.startsWith('#')) {
                continue;
            }

            valid = true;
            switch (item) {
                case 'TOGGLE_SUGGESTIONS':
                    toolBarItems.push({id: 'SUGGEST', toggle: true, short: '💡', text: '💡 SUGGEST', hint: '<b>Hover</b>: Toggle window suggestions: ❌ <b>Disabled</b>', hintEnabled: '<b>Hover</b>: Toggle window suggestions: ✅ <b>Enabled</b>'});
                    break;
                case 'TOGGLE_CENTER_IN_TILE':
                    toolBarItems.push({id: 'CENTER', toggle: true, enabled: false, short: '⸰', text: '⸰ CENTER', hint: '<b>Hover</b>: Toggle "Center in Tile": ❌ <b>Disabled</b><br><b>Drop</b>: Center window on current desktop', hintEnabled: '<b>Hover</b>: Toggle "Center in Tile": ✅ <b>Enabled</b><br><b>Drop</b>: Center window on current desktop'});
                    break;
                case 'TOGGLE_SHOW_ALL':
                    toolBarItems.push({id: 'SHOWALL', toggle: true, enabled: false, short: '👀', text: '👀 SHOW ALL', hint: '<b>Hover</b>: Show all layouts', hintEnabled: '<b>Hover</b>: Show default layouts'});
                    break;
                case 'HIDE_TILER':
                    toolBarItems.push({id: 'HIDE', toggle: false, enabled: false, short: '🙈', text: '🙈 HIDE', hint: '<b>Hover</b>: Hide tiler', hintEnabled: ''});
                    break;
                case 'TOGGLE_AUTO_TILE_DESKTOP':
                    toolBarItems.push({id: 'AUTO', toggle: true, enabled: false, short: '🤖', text: '🤖 AUTO', hint: '<b>Drop</b>: Toggle auto tiling of new windows: ❌ <b>Disabled</b><br>Persists after reboot (for this screen + activity + virtual desktop)', hintEnabled: '<b>Drop</b>: Toggle auto tiling of new windows: ✅ <b>Enabled</b><br>Persists after reboot (for this screen + activity + virtual desktop)'});
                    break;
                case 'CANCEL_MOVE':
                    toolBarItems.push({id: 'CANCEL', toggle: false, short: '↩️', text: '↩️ CANCEL', hint: '<b>Drop</b>: Cancel move<br>Window will be placed back where it was picked up'});
                    break;
                case 'CLOSE_WINDOW':
                    toolBarItems.push({id: 'CLOSE', toggle: false, short: '🗙', text: '🗙 CLOSE', hint: '<b>Drop</b>: Close window'});
                    break;
                case 'TOGGLE_KEEP_ABOVE':
                    toolBarItems.push({id: 'ABOVE', toggle: true, enabled: false, short: '▲', text: '▲ ABOVE', hint: '<b>Drop</b>: Toggle "Keep Above Others": ❌ <b>Disabled</b>', hintEnabled: '<b>Drop</b>: Toggle "Keep Above Others": ✅ <b>Enabled</b>'});
                    break;
                case 'TOGGLE_KEEP_BELOW':
                    toolBarItems.push({id: 'BELOW', toggle: true, enabled: false, short: '▼', text: '▼ BELOW', hint: '<b>Drop</b>: Toggle "Keep Below Others": ❌ <b>Disabled</b>', hintEnabled: '<b>Drop</b>: Toggle "Keep Below Others": ✅ <b>Enabled</b>'});
                    break;
                case 'MAXIMIZE':
                    toolBarItems.push({id: 'MAXIMIZE', toggle: true, short: '⌞⌝', text: '⌞⌝ MAXIMIZE', hint: '<b>Drop</b>: Maximize window', hintEnabled: '<b>Drop</b>: Restore maximized window'});
                    break;
                case 'TRUE_MAXIMIZE':
                    toolBarItems.push({id: 'TRUEMAX', toggle: true, short: '🗖', text: '🗖 TRUE MAX', hint: '<b>Drop</b>: Maximize window removing titlebar and frame<br><font color="orange">⚠</font> <b>WARNING</b> you might need to press <b>Alt+F3</b> to re-enable<br>You can restore the window by holding <b>Meta+Drag</b> (drag it here)', hintEnabled: '<b>Drop</b>: Restore maximized window restoring titlebar and frame'});
                    break;
                case 'MINIMIZE_OTHER':
                    toolBarItems.push({id: 'MINOTHER', toggle: false, short: '🗕', text: '🗕 OTHER', hint: '<b>Drop</b>: Minimize all other windows on current desktop'});
                    break;
                case 'MINIMIZE_OBSTRUCTED':
                    toolBarItems.push({id: 'MINOBSTRUCTED', toggle: false, short: '🗗', text: '🗗 HIDDEN', hint: '<b>Drop</b>: Minimize obstructed windows on current desktop'});
                    break;
                default:
                    valid = false;
                    break;
            }

            if (valid) {
                addedItems.push(item);
            }
        }

        initialized = true;
    }

    function activeHasHoverAction() {
        if (activeToolBarItemIndex < 0) return false;
        if (toolBarItems[activeToolBarItemIndex].id == 'HIDE') return true;
        return toolBarItems[activeToolBarItemIndex].toggle;
    }

    function findActive(x, y) {
        let toolBarItemIndex = -1;

        for (let i = 0; i < toolBarRepeater.count; i++) {
            let currentToolBarItem = toolBarRepeater.itemAt(i);
            let currentToolBarItemPosition = currentToolBarItem.mapToGlobal(Qt.point(0, 0));

            if (currentToolBarItemPosition.x <= x && currentToolBarItemPosition.x + currentToolBarItem.width >= x && currentToolBarItemPosition.y <= y && currentToolBarItemPosition.y + currentToolBarItem.height >= y) {
                toolBarItemIndex = i;
                break;
            }
        }

        return toolBarItemIndex;
    }

    Colors {
        id: colors
    }

    Rectangle {
        id: toolBarBackground
        anchors.fill: parent
        color: root.config.gridTilerOpacity != 1 ? Qt.alpha(colors.backgroundColor, root.config.gridTilerOpacity) : colors.backgroundColor
        border.color: colors.borderColor
        border.width: 1
        radius: 8

        GridLayout {
            property bool horizontalBar: config.toolBarPosition < 2

            id: toolBarLayout
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            rowSpacing: 1
            columnSpacing: 1
            columns: horizontalBar ? toolBarItems.length : 1
            rows: horizontalBar ? 1 : toolBarItems.length

            Repeater {
                id: toolBarRepeater
                model: toolBarItems

                Item {
                    id: toolBarItem

                    width: 34
                    height: 34

                    property bool activeItem: activeToolBarItemIndex == index
                    property bool itemToggled: {
                        switch (toolBarItems[index].id) {
                            case 'CENTER':
                                return root.centerInTile;
                            case 'SHOWALL':
                                return popupTiler.showAll;
                            case 'AUTO':
                                return popupTiler.autoTileNewWindowsActiveOnCurrentScreen;
                            case 'ABOVE':
                                return root.currentlyMovedWindow ? root.currentlyMovedWindow.keepAbove : false;
                            case 'BELOW':
                                return root.currentlyMovedWindow ? root.currentlyMovedWindow.keepBelow : false;
                            case 'SUGGEST':
                                return root.systemSettings.showTilingSuggestions;
                            case 'MAXIMIZE':
                                return root.positionAtMoveStart.maximized;
                            case 'TRUEMAX':
                                return root.currentlyMovedWindow ? root.positionAtMoveStart.maximized && root.currentlyMovedWindow.noBorder : false;
                            default:
                                return false;
                        }
                    }
                    property bool itemTogglable: toolBarItems[index].toggle

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: tilePadding
                        border.color: colors.tileBorderColor
                        border.width: 1
                        color: "transparent"
                        radius: 6

                        Rectangle {
                            anchors.fill: parent
                            color: activeItem ? colors.tileBackgroundColorActive : (itemToggled ? colors.tileBorderColor : (itemTogglable ? colors.tileBackgroundColorToggle : colors.tileBackgroundColor))
                            radius: 6
                        }

                        Text {
                            anchors.centerIn: parent
                            color: colors.textColor
                            textFormat: Text.StyledText
                            text: modelData.short
                            font.pixelSize: 14
                            font.family: "Noto Sans"
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }
        }
    }
}