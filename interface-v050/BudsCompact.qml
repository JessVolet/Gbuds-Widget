import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import "." as Gbuds

Item {
    id: root

    required property string pluginId
    property var config: ({})
    BudsActions { id: actionController; pluginId: root.pluginId }

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", status: null }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({ busy: false }) }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool busy: (commandState.value || ({})).busy === true
    readonly property bool connected: actionController.connected
    readonly property var modeOptions: [
        { mode: "NOISE_REDUCTION", action: "on", label: "ANC", icon: "noise_control_on" },
        { mode: "AMBIENT_SOUND", action: "ambient", label: "AMBIENT", icon: "hearing" },
        { mode: "ADAPTIVE", action: "adaptive", label: "Adaptive", icon: "auto_mode" },
        { mode: "OFF", action: "off", label: "OFF", icon: "noise_control_off" }
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
        return Theme.primary;
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

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusL
        color: Theme.withAlpha(Theme.surfaceContainer, 0.94)
        border.color: Theme.withAlpha(Theme.outline, 0.2)
        border.width: 1
        visible: root.connected
    }

    ConnectOnly { anchors.fill: parent; pluginId: root.pluginId; visible: !root.connected }

    Column {
        visible: root.connected
        anchors.fill: parent
        anchors.margins: Theme.spacingS
        spacing: Theme.spacingXS

        Row {
            width: parent.width
            height: 20
            spacing: Theme.spacingXS
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
            height: 106
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
                        Loader {
                            width: 48; height: 48
                            anchors.horizontalCenter: parent.horizontalCenter
                            sourceComponent: modelData.key === "case" ? caseGlyph : earbudButton
                            Component {
                                id: caseGlyph
                                Gbuds.EarbudGlyph {
                                    part: "case"
                                    available: root.connected
                                    tint: root.batteryColor("case")
                                }
                            }
                            Component {
                                id: earbudButton
                                EarbudButton {
                                    actions: actionController
                                    side: modelData.key
                                    modelCode: root.device.model_code || ""
                                    available: root.partAvailable(modelData.key)
                                    idle: root.config.warnOutOfEar !== false && root.status["placement_" + modelData.key] === "IDLE"
                                    tint: root.batteryColor(modelData.key)
                                }
                            }
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: (actionController.ringing(modelData.key) ? "STOP" : modelData.label) + "  " + root.battery(modelData.key)
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                        }
                        Item {
                            width: parent.width
                            height: 30
                            ActionButton {
                                objectName: "disconnectButton"
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(100, (root.width - 30) / 3)
                                height: 27
                                visible: modelData.key === "case"
                                enabled: !root.busy
                                text: "Desconectar"
                                onClicked: actionController.send("disconnect", [], "Disconnect Galaxy Buds")
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 80
            radius: Theme.cornerRadiusS
            visible: root.modeOptions.length > 0
            color: Theme.surfaceContainerHigh
            border.color: Theme.withAlpha(Theme.outline, 0.35)
            border.width: 1
            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3
                Repeater {
                    model: root.modeOptions
                    delegate: Rectangle {
                        id: modeButton
                        required property var modelData
                        readonly property bool selected: root.status.noise_control === modelData.mode
                        width: (parent.width - (root.modeOptions.length - 1) * 3) / root.modeOptions.length
                        height: parent.height
                        radius: Theme.cornerRadiusS
                        color: selected ? Theme.primaryContainer : "transparent"
                        enabled: root.connected && !root.busy
                        activeFocusOnTab: enabled
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label
                        Accessible.checked: selected
                        border.width: activeFocus ? 2 : 0
                        border.color: Theme.primary
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS
                            NoiseModeIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                mode: modelData.mode
                                size: 36
                                color: modeButton.selected ? Theme.primary : Theme.surfaceText
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: modeButton.selected ? Theme.primary : Theme.surfaceText
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.requestMode(modelData.action) }
                        Keys.onReturnPressed: root.requestMode(modelData.action)
                        Keys.onSpacePressed: root.requestMode(modelData.action)
                    }
                }
            }
        }
        StyledText {
            width: parent.width
            height: visible ? implicitHeight : 0
            visible: !!actionController.error
            text: actionController.error
            color: Theme.error
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
        }
    }
}
