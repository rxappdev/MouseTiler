import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kwin
import org.kde.kirigami as Kirigami
// import QtWebView

ApplicationWindow {
    property var overrides: {}
    property var currentOverrides: {}
    property var currentApplications: []
    property var currentWindows: []
    property var defaultConfig: {}
    property var currentApplicationIndex: -1
    property var currentWindowIndex: -1
    // property var isX11: Qt.platform.pluginName == 'xcb'
    property var mouseStartX
    property var mouseStartY
    property var windowStartX
    property var windowStartY

    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    property var lightTheme: {
        return Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light;
    }

    property var headerColor: {
        if (lightTheme) {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "white", 0.4);
        } else {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.3);
        }
    }

    property var headerBorderColor: {
        if (lightTheme) {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.2);
        } else {
            return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "white", 0.2);
        }
    }

    id: mainMenuRoot
    width: 1000
    height: 734
    title: "Mouse Tiler Configuration"
    color: Kirigami.Theme.backgroundColor
    flags: Qt.FramelessWindowHint | Qt.Window | Qt.BypassWindowManagerHint
    // flags: ixX11 ? Qt.X11BypassWindowManagerHint : flags

    // x: isX11 ? Workspace.virtualScreenSize.width / 2 - width / 2 : x
    // y: isX11 ? Workspace.virtualScreenSize.height / 2 - height / 2 : y
    x: Workspace.virtualScreenSize.width / 2 - width / 2
    y: Workspace.virtualScreenSize.height / 2 - height / 2

    function initMainMenu() {
    }

    Rectangle {
        color: headerColor
        height: 34
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        border.color: headerBorderColor
        border.width: 1

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton

            onPressed: {
                mouseStartX = Workspace.cursorPos.x;
                mouseStartY = Workspace.cursorPos.y;
                windowStartX = mainMenuRoot.x;
                windowStartY = mainMenuRoot.y;
            }

            onPositionChanged: {
                mainMenuRoot.x = windowStartX + (Workspace.cursorPos.x - mouseStartX);
                mainMenuRoot.y = windowStartY + (Workspace.cursorPos.y - mouseStartY);
            }

            onReleased: {
                mainMenuRoot.x = windowStartX + (Workspace.cursorPos.x - mouseStartX);
                mainMenuRoot.y = windowStartY + (Workspace.cursorPos.y - mouseStartY);
            }

            Label {
                text: "Mouse Tiler Configuration"
                anchors.centerIn: parent
            }

            Button {
                text: "X"
                flat: true

                width: 26
                height: 26
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 4

                onClicked: root.closeMainMenu()
            }
        }
    }

    GroupBox {
        id: mainGroupBox
        anchors.fill: parent
        anchors.topMargin: 35

        // WebView {
        //     id: webView
        //     anchors.fill: parent
        //     url: "https://rxweb.epizy.com/mousetiler/editor.html"
        // }

        ColumnLayout {
            id: mainChoice
            visible: true
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            GroupBox {
                spacing: 5
                Layout.fillWidth: true

                ColumnLayout {
                    anchors.fill: parent

                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "This was meant to be the UI designer. However it is a lot of work to implement it, probaly at least 1-2 weeks full time. Sadly I got rent to pay and a 3 year old son to feed and based on my previous project Remember Window Positions, I will not be able to feed us from my contributions to Linux. (After over 3 months full time work I earned $100 total which I apreciate but it's not possible to survive on). I might implement it in the future if the situation changes."
                        wrapMode: Text.WordWrap
                    }

                    // Label {
                    //     Layout.fillWidth: true
                    //     text: "Not implemented yet"
                    //     wrapMode: Text.WordWrap
                    // }
                }
            }

            // GroupBox {
            //     spacing: 5
            //     Layout.fillWidth: true

            //     ColumnLayout {
            //         anchors.fill: parent

            //         Label {
            //             Layout.fillWidth: true
            //             horizontalAlignment: Text.AlignHCenter
            //             text: "."
            //             wrapMode: Text.WordWrap
            //         }

            //         Button {
            //             id: selectWindowButton
            //             text: "Select Application/Window"
            //             Layout.fillWidth: true

            //             onClicked: selectWindow()
            //         }

            //         Button {
            //             text: "Edit Saved Applications and Windows"
            //             Layout.fillWidth: true

            //             onClicked: editSavedAppOrWindow()
            //         }
            //     }
            // }
        }
    }
}