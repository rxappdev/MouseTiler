import QtQuick
import org.kde.kirigami as Kirigami

Item {
    Kirigami.Theme.colorSet: Kirigami.Theme.View

    property bool lightTheme: {
        return Kirigami.ColorUtils.brightnessForColor(Kirigami.Theme.backgroundColor) === Kirigami.ColorUtils.Light;
    }

    property var backgroundColor: {
        switch (config.theme) {
            case 1:
                return "#161925";
            case 2:
                return "#110B00";
            case 3:
                return "#FFFFFF";
            case 4:
                return "#110000";
            case 5:
                return "#020900";
            case 6:
                return "#0A0010";
            case 7:
                return "#001100";
            case 8:
                return "#111100";
            case 9:
                return "#000710";
            default:
                return Kirigami.Theme.backgroundColor;
        }
    }

    property var borderColor: {
        switch (config.theme) {
            case 1:
                return "#666666";
            case 2:
                return "#7F4F00";
            case 3:
                return "#777777";
            case 4:
                return "#780000";
            case 5:
                return "#587C00";
            case 6:
                return "#4A0076";
            case 7:
                return "#225522";
            case 8:
                return "#555500";
            case 9:
                return "#004093";
            default:
                if (lightTheme) {
                    return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "black", 0.2);
                } else {
                    return Kirigami.ColorUtils.tintWithAlpha(Kirigami.Theme.backgroundColor, "white", 0.2);
                }
        }
    }

    property var textColor: {
        switch (config.theme) {
            case 1:
                return "white";
            case 2:
                return "white";
            case 3:
                return "black";
            case 4:
                return "white";
            case 5:
                return "white";
            case 6:
                return "white";
            case 7:
                return "white";
            case 8:
                return "white";
            case 9:
                return "white";
            default:
                return lightTheme ? "black" : "white";
        }
    }

    property var overlayTextColor: {
        switch (config.theme) {
            case 1:
                return "white";
            case 2:
                return "white";
            case 3:
                return "black";
            case 4:
                return "black";
            case 5:
                return "black";
            case 6:
                return "white";
            case 7:
                return "black";
            case 8:
                return "black";
            case 9:
                return "white";
            default:
                return lightTheme ? "black" : "white";
        }
    }

    property var hintBackgroundColor: {
        switch (config.theme) {
            case 1:
                return "#590099FF";
            case 2:
                return "#59FF9F00";
            case 3:
                return "#59FF0000";
            case 4:
                return "#59FF0000";
            case 5:
                return "#59B5FF00";
            case 6:
                return "#599F00FF";
            case 7:
                return "#5900FF00";
            case 8:
                return "#59FFFF00";
            case 9:
                return "#590067FF";
            default:
                return Kirigami.ColorUtils.tintWithAlpha("transparent", Kirigami.Theme.highlightColor, 0.35);
        }
    }

    property var tileBorderColor: {
        switch (config.theme) {
            case 1:
                return "#0099FF";
            case 2:
                return "#FF9F00";
            case 3:
                return "#FF0000";
            case 4:
                return "#FF0000";
            case 5:
                return "#B5FF00";
            case 6:
                return "#9F00FF";
            case 7:
                return "#00FF00";
            case 8:
                return "#FFFF00";
            case 9:
                return "#0067FF";
            default:
                return Kirigami.Theme.highlightColor;
        }
    }

    property var tileBackgroundColor: {
        switch (config.theme) {
            case 1:
                return "#0C0099FF";
            case 2:
                return "#0CFF9F00";
            case 3:
                return "#3CFF0000";
            case 4:
                return "#3CFF0000";
            case 5:
                return "#3CB5FF00";
            case 6:
                return "#3C9F00FF";
            case 7:
                return "#3C00FF00";
            case 8:
                return "#3CFFFF00";
            case 9:
                return "#3C0067FF";
            default:
                return Kirigami.ColorUtils.tintWithAlpha("transparent", Kirigami.Theme.highlightColor, 0.05);
        }
    }

    property var tileBackgroundColorActive: {
        switch (config.theme) {
            case 1:
                return "#BE0099FF";
            case 2:
                return "#BEFF9F00";
            case 3:
                return "#BEFF0000";
            case 4:
                return "#BEFF0000";
            case 5:
                return "#BEB5FF00";
            case 6:
                return "#BE9F00FF";
            case 7:
                return "#BE00FF00";
            case 8:
                return "#BEFFFF00";
            case 9:
                return "#BE0067FF";
            default:
                return Kirigami.ColorUtils.tintWithAlpha("transparent", Kirigami.Theme.highlightColor, 0.75);
        }
    }
}
