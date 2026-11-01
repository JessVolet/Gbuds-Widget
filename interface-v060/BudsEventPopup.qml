import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets as DuxWidgets
import qs.DCommon.Widgets

PanelWindow {
    id: root
    objectName: "gbudsEventPopup"

    property var config: ({})
    property var eventData: null
    property var status: ({})
    property var device: ({})
    property bool shown: false
    property var eventQueue: []
    property int waveRevision: 0
    property int queueLimit: 4
    readonly property string corner: {
        var vertical = config.notifyVerticalPosition || (config.statusCardPosition || "bottom-right").split("-")[0];
        var fixed = config.notifyFixedSide || (config.statusCardPosition || "bottom-right").split("-")[1] || "right";
        var side = subject === "left" && config.notifyMatchPosition !== false ? "left" :
            subject === "right" && config.notifyMatchPosition !== false ? "right" : fixed;
        return vertical + "-" + side;
    }
    readonly property bool warning: eventData && eventData.severity === "warning"
    readonly property string subject: eventData ? eventData.subject || "pair" : "pair"
    readonly property var parts: {
        if (subject === "mode" && config.notificationArtwork !== "render") return [];
        if (subject === "mode") return ["left", "right"];
        if (subject === "case") return ["case"];
        if (subject === "left" || subject === "right") return [subject];
        if (eventData && eventData.kind === "connected" && status.placement_left === "IN_CASE" && status.placement_right === "IN_CASE")
            return ["case"];
        return ["left", "right"];
    }

    function present(nextEvent, nextStatus, nextDevice) {
        if (config.notificationsEnabled === false ||
            (config.notificationsEnabled === undefined && (config.showStatusCards === false ||
            ((String(nextEvent.kind).indexOf("battery-") === 0) && config.showBatteryCards === false)))) return;
        if (eventQueue.length >= queueLimit) eventQueue = eventQueue.slice(1);
        eventQueue = eventQueue.concat([{ event: nextEvent, status: nextStatus || ({}), device: nextDevice || ({}) }]);
        if (!shown) showNext();
    }

    function showNext() {
        if (!eventQueue.length) {
            shown = false;
            unmapTimer.restart();
            return;
        }
        var item = eventQueue[0];
        eventQueue = eventQueue.slice(1);
        var nextEvent = item.event;
        eventData = nextEvent;
        var targetName = config.notifyScreen || "active";
        screen = targetName === "primary" ? (Quickshell.screens.length ? Quickshell.screens[0] : null) :
            targetName === "active" ? CompositorService.getFocusedScreen() :
            (Quickshell.screens.find(candidate => candidate.name === targetName) || CompositorService.getFocusedScreen());
        status = nextEvent.snapshot || item.status;
        device = item.device;
        visible = true;
        shown = true;
        waveRevision++;
        contentIn.restart();
        startWaveCycle();
    }

    function dismiss() {
        if (eventQueue.length) {
            var item = eventQueue[0];
            eventQueue = eventQueue.slice(1);
            eventData = item.event;
            status = item.event.snapshot || item.status;
            device = item.device;
            waveRevision++;
            startWaveCycle();
            return;
        }
        shown = false;
        dismissTimer.stop();
        wavePulseTimer.stop();
        unmapTimer.restart();
    }

    function startWaveCycle() {
        dismissTimer.interval = Math.max(1500, Number(config.dismissTimeout || 5) * 1000);
        dismissTimer.restart();
        wavePulseTimer.interval = Math.max(1000, Math.min(5000, Number(config.notifyWaveInterval || 1500)));
        wavePulseTimer.restart();
    }

    function removeQueued(id) {
        eventQueue = eventQueue.filter(function (item) { return String(item.event.id) !== String(id); });
    }

    function render(part) {
        if ((config.notificationArtwork || "auto") === "svg")
            return Qt.resolvedUrl(part === "case" ? "../assets/approved/case.svg" : "../assets/approved/bud-" + part + ".svg");
        if (part === "case") return Qt.resolvedUrl("../assets/icons/case.svg");
        var code = device.model_code || "";
        var model = code === "SM-R630" ? "Buds3Pro" : code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (model) {
            var colorName = (device.color || "").toLowerCase();
            var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
            return Qt.resolvedUrl("../assets/device/" + model + color + "-" + (part === "left" ? 0 : 1) + ".png");
        }
        var small = /SM-R400|SM-R177|SM-R170|SM-R175|SM-R180|SM-R190|SM-R510/.test(code);
        return Qt.resolvedUrl("../assets/icons/" + (small ? "s_" : "L_") + part + ".svg");
    }

    function batteryLabel(part) {
        var value = status[part];
        return typeof value === "number" && value >= 0 ? value + "%" : "—";
    }

    screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    visible: false
    color: "transparent"
    implicitWidth: 230
    implicitHeight: 230 + Math.min(eventQueue.length, queueLimit) * 66
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
        left: Math.max(0, Number(root.config.notifyMargin || 18)); right: Math.max(0, Number(root.config.notifyMargin || 18)); top: Math.max(0, Number(root.config.notifyMargin || 18)); bottom: Math.max(0, Number(root.config.notifyMargin || 18))
    }

    DuxWidgets.WindowBlur {
        targetWindow: root
        surfaceColor: card.color
        blurX: card.x; blurY: card.y
        blurWidth: card.width; blurHeight: card.height
        blurRadius: card.radius
    }

    Timer { id: dismissTimer; repeat: false; onTriggered: root.dismiss() }
    Timer { id: wavePulseTimer; repeat: true; onTriggered: root.waveRevision++ }
    Timer { id: unmapTimer; interval: 250; repeat: false; onTriggered: if (!root.shown) { if (root.eventQueue.length) root.showNext(); else root.visible = false } }
    NumberAnimation { id: contentIn; target: body; property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }

    Rectangle {
        id: card
        x: 5; y: 5
        width: root.width - 10; height: 220
        radius: Theme.cornerRadiusL
        color: Theme.withAlpha(Theme.surfaceContainerHigh, BlurService.enabled ? 0.8 : 0.97)
        border.width: 1
        border.color: root.eventData && (root.eventData.kind === "battery-20" || root.eventData.kind === "critical-battery") ? Theme.withAlpha(Theme.error, 0.8) : root.eventData && root.eventData.kind === "battery-50" ? Theme.withAlpha(Theme.warning, 0.7) : root.warning ? Theme.withAlpha(Theme.error, 0.6) : Theme.withAlpha(Theme.primary, 0.4)
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
            spacing: Theme.spacingXS

            Row {
                width: parent.width
                height: 20
                spacing: Theme.spacingXS
                DIcon { name: "bluetooth"; size: 14; color: root.warning ? Theme.error : Theme.primary }
                StyledText {
                    width: parent.width - 46
                    text: root.device.name || root.device.model || "Galaxy Buds"
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
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
                Repeater {
                    model: Math.max(1, Math.min(3, Number(root.eventData && root.eventData.waves || 1)))
                    delegate: Rectangle {
                        id: popupRing
                        required property int index
                        width: 46 + index * 22
                        height: width
                        radius: width / 2
                        color: "transparent"
                        border.width: 2
                        border.color: root.eventData && root.eventData.kind === "battery-20" ? Theme.error : root.eventData && root.eventData.kind === "battery-50" ? Theme.warning : Theme.withAlpha(root.warning ? Theme.error : Theme.primary, 0.68)
                        opacity: 0
                        anchors.centerIn: parent
                        ParallelAnimation {
                            id: popupWave
                            NumberAnimation { target: popupRing; property: "scale"; from: 0.7; to: 1.2; duration: root.eventData && root.eventData.kind === "battery-20" ? 720 : 1100; easing.type: Easing.OutCubic }
                            NumberAnimation { target: popupRing; property: "opacity"; from: 0.52; to: 0; duration: root.eventData && root.eventData.kind === "battery-20" ? 720 : 1100; easing.type: Easing.OutQuad }
                        }
                        Connections {
                            target: root
                            function onWaveRevisionChanged() {
                                if (root.config.notifyReduceMotion === true) { popupWave.stop(); popupRing.opacity = 0.25; }
                                else popupWave.restart();
                            }
                        }
                        Component.onCompleted: {
                            if (root.config.notifyReduceMotion === true) popupRing.opacity = 0.25;
                            else popupWave.restart();
                        }
                    }
                }
                NoiseModeIcon {
                    anchors.centerIn: parent
                    visible: root.subject === "mode" && root.config.notificationArtwork !== "render"
                    mode: root.status.noise_control || "OFF"
                    size: 56
                    color: Theme.primary
                }
                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spacingM
                    visible: root.subject !== "mode" || root.config.notificationArtwork === "render"
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
                NoiseModeIcon {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    visible: root.subject === "mode" && root.config.notificationArtwork === "render"
                    mode: root.status.noise_control || "OFF"
                    size: 28
                    color: Theme.primary
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
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.primary
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Repeater {
        model: root.eventQueue
        delegate: Rectangle {
            required property int index
            required property var modelData
            x: 5
            y: 230 + index * 66
            width: root.width - 10
            height: 60
            radius: Theme.cornerRadiusM
            color: Theme.withAlpha(Theme.surfaceContainerHigh, BlurService.enabled ? 0.84 : 0.98)
            border.width: 1
            border.color: Theme.withAlpha(Theme.primary, 0.32)
            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: Theme.spacingS
                DIcon { name: modelData.event.severity === "warning" ? "bluetooth_disabled" : "notifications"; size: 18; color: modelData.event.kind === "battery-20" ? Theme.error : Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    width: parent.width - 24
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    StyledText { width: parent.width; text: modelData.event.title || "Galaxy Buds event"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    StyledText { width: parent.width; text: modelData.event.detail || ""; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; elide: Text.ElideRight }
                }
            }
            MouseArea {
                anchors.fill: parent
                Accessible.role: Accessible.Button
                Accessible.name: "Dismiss " + (modelData.event.title || "Galaxy Buds event")
                onClicked: root.removeQueued(modelData.event.id)
            }
        }
    }
}
