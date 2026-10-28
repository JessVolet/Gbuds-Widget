import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    required property string pluginId

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", status: null }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({ busy: false }) }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool busy: (commandState.value || ({})).busy === true
    readonly property bool connected: (snapshot.phase === "connected" || snapshot.phase === "controlling") &&
                                      !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    readonly property var modeOptions: [
        { mode: "NOISE_REDUCTION", action: "on", label: "ANC", icon: "noise_control_on" },
        { mode: "AMBIENT_SOUND", action: "ambient", label: "Ambient", icon: "hearing" },
        { mode: "ADAPTIVE", action: "adaptive", label: "Adaptive", icon: "auto_mode" },
        { mode: "OFF", action: "off", label: "Normal", icon: "noise_control_off" }
    ].filter(item => Array.isArray(device.supported_noise_modes) && device.supported_noise_modes.indexOf(item.action) >= 0)

    function partAvailable(part) {
        return connected && (part === "case" || status["placement_" + part] !== "DISCONNECTED");
    }

    function battery(part) {
        var value = status[part];
        return partAvailable(part) && typeof value === "number" && value >= 0 ? value + "%" : "—";
    }

    function batteryColor(part) {
        var value = status[part];
        if (!partAvailable(part) || typeof value !== "number" || value < 0) return Theme.surfaceVariantText;
        if (value <= 10) return Theme.error;
        if (value <= 30) return Theme.warning;
        return Theme.success;
    }

    function icon(part) {
        if (part === "case") return Qt.resolvedUrl("assets/icons/case.svg");
        var code = (device.model_code || "").toUpperCase();
        var small = /SM-R400|SM-R177|SM-R170|SM-R175|SM-R180|SM-R190|SM-R510/.test(code);
        return Qt.resolvedUrl("assets/icons/" + (small ? "s_" : "L_") + part + ".svg");
    }

    function requestMode(action) {
        if (!connected || busy) return;
        PluginService.setGlobalVar(pluginId, "commandRequest", {
            id: Date.now() + "-" + Math.random(),
            command: "anc",
            args: [action],
            label: "Noise mode " + action
        });
    }

    Column {
        anchors.fill: parent
        anchors.margins: 7
        spacing: 6

        Row {
            width: parent.width
            height: 20
            spacing: 6
            DIcon {
                name: "bluetooth_connected"
                size: 16
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                width: parent.width - 22
                text: root.device.name || root.device.model || "Galaxy Buds"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            width: parent.width
            height: 53
            spacing: 5
            Repeater {
                model: [
                    { key: "left", label: "LEFT" },
                    { key: "case", label: "CASE" },
                    { key: "right", label: "RIGHT" }
                ]
                delegate: Item {
                    required property var modelData
                    width: (parent.width - 10) / 3
                    height: parent.height
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                        Item {
                            width: 28; height: 29
                            anchors.horizontalCenter: parent.horizontalCenter
                            Image {
                                id: partIcon
                                anchors.fill: parent
                                source: root.icon(modelData.key)
                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }
                            MultiEffect {
                                anchors.fill: partIcon
                                source: partIcon
                                colorization: 1
                                colorizationColor: root.batteryColor(modelData.key)
                                opacity: root.partAvailable(modelData.key) ? 1 : 0.4
                                Behavior on colorizationColor { ColorAnimation { duration: 220 } }
                            }
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label + "  " + root.battery(modelData.key)
                            color: Theme.surfaceText
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 34
            radius: 12
            visible: root.modeOptions.length > 0
            color: Theme.withAlpha(Theme.surfaceContainer, 0.28)
            border.color: Theme.withAlpha(Theme.outline, 0.35)
            border.width: 1
            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3
                Repeater {
                    model: root.modeOptions
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool selected: root.status.noise_control === modelData.mode
                        width: (parent.width - (root.modeOptions.length - 1) * 3) / root.modeOptions.length
                        height: parent.height
                        radius: 9
                        color: selected ? Theme.primaryContainer : "transparent"
                        enabled: root.connected && !root.busy
                        activeFocusOnTab: enabled
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label
                        Accessible.checked: selected
                        Behavior on color { ColorAnimation { duration: 200 } }
                        DIcon {
                            anchors.centerIn: parent
                            name: modelData.icon
                            size: 18
                            color: selected ? Theme.onPrimaryContainer : Theme.surfaceText
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.requestMode(modelData.action) }
                        Keys.onReturnPressed: root.requestMode(modelData.action)
                        Keys.onSpacePressed: root.requestMode(modelData.action)
                    }
                }
            }
        }
    }
}
