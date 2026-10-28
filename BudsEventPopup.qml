import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets

PanelWindow {
    id: root

    property var config: ({})
    property var eventData: null
    property var status: ({})
    property var device: ({})
    property bool shown: false
    readonly property string corner: config.statusCardPosition || "bottom-right"
    readonly property bool warning: eventData && eventData.severity === "warning"

    function present(nextEvent, nextStatus, nextDevice) {
        if (config.showStatusCards === false ||
            ((nextEvent.kind === "low-battery" || nextEvent.kind === "critical-battery") && config.showBatteryCards === false))
            return;
        eventData = nextEvent;
        status = nextStatus || ({});
        device = nextDevice || ({});
        visible = true;
        shown = true;
        dismissTimer.interval = Math.max(1500, Number(config.dismissTimeout || 5) * 1000);
        dismissTimer.restart();
    }

    function dismiss() {
        shown = false;
        dismissTimer.stop();
        unmapTimer.restart();
    }

    function render(side) {
        var code = device.model_code || "";
        var model = code === "SM-R630" ? "Buds3Pro" : code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (!model) return "";
        var colorName = (device.color || "").toLowerCase();
        var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
        return Qt.resolvedUrl("assets/device/" + model + color + "-" + side + ".png");
    }

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: false
    color: "transparent"
    implicitWidth: 344
    implicitHeight: 112
    WlrLayershell.namespace: "dms:gbuds-event"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    anchors {
        left: root.corner.endsWith("left")
        right: root.corner.endsWith("right")
        top: root.corner.startsWith("top")
        bottom: root.corner.startsWith("bottom")
    }
    WlrLayershell.margins {
        left: 18
        right: 18
        top: 18
        bottom: 18
    }

    WindowBlur {
        targetWindow: root
        surfaceColor: card.color
        blurX: card.x
        blurY: card.y
        blurWidth: card.width
        blurHeight: card.height
        blurRadius: card.radius
    }

    Timer { id: dismissTimer; repeat: false; onTriggered: root.dismiss() }
    Timer { id: unmapTimer; interval: 250; repeat: false; onTriggered: if (!root.shown) root.visible = false }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 5
        radius: 22
        color: Theme.withAlpha(Theme.surfaceContainerHigh, BlurService.enabled ? 0.78 : 0.96)
        border.width: 1
        border.color: root.warning ? Theme.withAlpha(Theme.error, 0.6) : Theme.withAlpha(Theme.primary, 0.45)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        transform: Translate {
            y: root.shown ? 0 : (root.corner.startsWith("top") ? -14 : 14)
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Row {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Row {
                width: 104
                height: parent.height
                spacing: 4
                Repeater {
                    model: [0, 1]
                    delegate: Item {
                        required property int index
                        width: 50
                        height: parent.height
                        Image {
                            anchors.centerIn: parent
                            width: 46; height: 56
                            source: root.render(index)
                            fillMode: Image.PreserveAspectFit
                            visible: source.toString() !== ""
                        }
                        DIcon {
                            anchors.centerIn: parent
                            name: "earbuds"
                            size: 32
                            color: root.warning ? Theme.error : Theme.primary
                            visible: root.render(index) === ""
                        }
                        StyledText {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: typeof (index === 0 ? root.status.left : root.status.right) === "number" ?
                                  (index === 0 ? root.status.left : root.status.right) + "%" : "—"
                            font.pixelSize: 10
                            color: Theme.surfaceVariantText
                        }
                    }
                }
            }

            Column {
                width: parent.width - 104 - 12 - closeButton.width - 8
                spacing: 5
                anchors.verticalCenter: parent.verticalCenter
                StyledText {
                    width: parent.width
                    text: root.eventData ? root.eventData.title : ""
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }
                StyledText {
                    width: parent.width
                    text: root.eventData ? root.eventData.detail : ""
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceVariantText
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }
            DButton {
                id: closeButton
                width: 24; buttonHeight: 24; minimumWidth: 0
                iconName: "close"; text: ""
                backgroundColor: "transparent"
                Accessible.name: "Dismiss Galaxy Buds event"
                onClicked: root.dismiss()
            }
        }
    }
}
