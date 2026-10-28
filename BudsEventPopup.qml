import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets as DuxWidgets
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
    readonly property string subject: eventData ? eventData.subject || "pair" : "pair"
    readonly property var parts: {
        if (subject === "mode") return [];
        if (subject === "case") return ["case"];
        if (subject === "left" || subject === "right") return [subject];
        if (eventData && eventData.kind === "connected" && status.placement_left === "IN_CASE" && status.placement_right === "IN_CASE")
            return ["case"];
        return ["left", "right"];
    }

    function present(nextEvent, nextStatus, nextDevice) {
        if (config.showStatusCards === false ||
            ((nextEvent.kind === "low-battery" || nextEvent.kind === "critical-battery") && config.showBatteryCards === false))
            return;
        eventData = nextEvent;
        status = nextEvent.kind === "disconnected" ? ({}) : (nextStatus || ({}));
        device = nextDevice || ({});
        visible = true;
        shown = true;
        contentIn.restart();
        dismissTimer.interval = Math.max(1500, Number(config.dismissTimeout || 5) * 1000);
        dismissTimer.restart();
    }

    function dismiss() {
        shown = false;
        dismissTimer.stop();
        unmapTimer.restart();
    }

    function render(part) {
        if (part === "case") return Qt.resolvedUrl("assets/icons/case.svg");
        var code = device.model_code || "";
        var model = code === "SM-R630" ? "Buds3Pro" : code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (model) {
            var colorName = (device.color || "").toLowerCase();
            var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
            return Qt.resolvedUrl("assets/device/" + model + color + "-" + (part === "left" ? 0 : 1) + ".png");
        }
        var small = /SM-R400|SM-R177|SM-R170|SM-R175|SM-R180|SM-R190|SM-R510/.test(code);
        return Qt.resolvedUrl("assets/icons/" + (small ? "s_" : "L_") + part + ".svg");
    }

    function batteryLabel(part) {
        var value = status[part];
        return typeof value === "number" && value >= 0 ? value + "%" : "—";
    }

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: false
    color: "transparent"
    implicitWidth: 230
    implicitHeight: 230
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
        left: 18; right: 18; top: 18; bottom: 18
    }

    DuxWidgets.WindowBlur {
        targetWindow: root
        surfaceColor: card.color
        blurX: card.x; blurY: card.y
        blurWidth: card.width; blurHeight: card.height
        blurRadius: card.radius
    }

    Timer { id: dismissTimer; repeat: false; onTriggered: root.dismiss() }
    Timer { id: unmapTimer; interval: 250; repeat: false; onTriggered: if (!root.shown) root.visible = false }
    NumberAnimation { id: contentIn; target: body; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 5
        radius: 25
        color: Theme.withAlpha(Theme.surfaceContainerHigh, BlurService.enabled ? 0.8 : 0.97)
        border.width: 1
        border.color: root.warning ? Theme.withAlpha(Theme.error, 0.6) : Theme.withAlpha(Theme.primary, 0.4)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        transform: Translate {
            y: root.shown ? 0 : (root.corner.startsWith("top") ? -14 : 14)
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        }
        Behavior on opacity { NumberAnimation { duration: 210; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Column {
            id: body
            anchors.fill: parent
            anchors.margins: 14
            spacing: 6

            Row {
                width: parent.width
                height: 20
                spacing: 6
                DIcon { name: "bluetooth"; size: 14; color: root.warning ? Theme.error : Theme.primary }
                StyledText {
                    width: parent.width - 46
                    text: root.device.name || root.device.model || "Galaxy Buds"
                    color: Theme.surfaceVariantText
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
                DButton {
                    width: 20; buttonHeight: 20; minimumWidth: 0
                    iconName: "close"; text: ""
                    backgroundColor: "transparent"
                    Accessible.name: "Dismiss Galaxy Buds event"
                    onClicked: root.dismiss()
                }
            }

            Item {
                width: parent.width
                height: 91
                DIcon {
                    anchors.centerIn: parent
                    visible: root.subject === "mode"
                    name: root.eventData ? root.eventData.icon : "noise_control_off"
                    size: 56
                    color: Theme.primary
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: root.subject !== "mode"
                    Repeater {
                        model: root.parts
                        delegate: Item {
                            required property string modelData
                            width: root.parts.length === 1 ? 86 : 68
                            height: 86
                            Image {
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                source: root.render(modelData)
                                fillMode: Image.PreserveAspectFit
                                opacity: root.warning ? 0.75 : 1
                            }
                        }
                    }
                }
            }

            StyledText {
                width: parent.width
                text: root.eventData ? root.eventData.title : ""
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Bold
                color: Theme.surfaceText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                text: root.eventData ? root.eventData.detail : ""
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
            StyledText {
                width: parent.width
                visible: root.subject !== "mode" && root.eventData && root.eventData.kind !== "disconnected"
                text: root.parts.map(part => part.toUpperCase() + "  " + root.batteryLabel(part)).join("    ·    ")
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme.primary
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
