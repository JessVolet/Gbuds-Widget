import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets

Item {
    id: root

    required property string pluginId

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", status: null }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool connected: (snapshot.phase === "connected" || snapshot.phase === "controlling") &&
                                      !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")

    function battery(value) {
        return connected && typeof value === "number" && value >= 0 ? value + "%" : "—";
    }

    function batteryColor(value) {
        if (!connected || typeof value !== "number" || value < 0) return Theme.surfaceVariantText;
        if (value <= 10) return Theme.error;
        if (value <= 30) return Theme.warning;
        return Theme.primary;
    }

    function modeLabel(mode) {
        if (mode === "NOISE_REDUCTION") return "Noise cancellation";
        if (mode === "AMBIENT_SOUND") return "Ambient sound";
        if (mode === "ADAPTIVE") return "Adaptive sound";
        return mode === "OFF" ? "Normal mode" : "Waiting for Buds";
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.withAlpha("#122d40", BlurService.enabled ? 0.84 : 1) }
            GradientStop { position: 0.52; color: Theme.withAlpha("#1a4052", BlurService.enabled ? 0.78 : 1) }
            GradientStop { position: 1; color: Theme.withAlpha("#254e5e", BlurService.enabled ? 0.74 : 1) }
        }
    }

    Rectangle {
        width: Math.min(root.width * 0.82, 320)
        height: width
        radius: width / 2
        anchors.centerIn: parent
        color: "#0c83bad0"
        opacity: root.connected ? 0.28 : 0.14
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Row {
            width: parent.width
            height: 28
            spacing: 8
            DIcon {
                name: root.connected ? "bluetooth_connected" : "bluetooth_disabled"
                size: 18
                color: root.connected ? "#a9e5dc" : "#b0bfcc"
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                width: parent.width - 26
                text: root.connected ? (root.device.name || root.device.model || "Galaxy Buds") : "Galaxy Buds · Disconnected"
                color: "#f5f9fb"
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            width: parent.width
            height: 66
            spacing: 8

            Repeater {
                model: [
                    { key: "left", label: "LEFT", icon: "earbuds" },
                    { key: "case", label: "CASE", icon: "inventory_2" },
                    { key: "right", label: "RIGHT", icon: "earbuds" }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 16) / 3
                    height: parent.height
                    radius: 15
                    color: "#385c6e80"
                    border.color: "#416d8291"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        DIcon {
                            name: modelData.icon
                            size: 20
                            color: root.batteryColor(root.status[modelData.key])
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            spacing: 1
                            StyledText {
                                text: modelData.label
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                color: "#b3c7cf"
                            }
                            StyledText {
                                text: root.battery(root.status[modelData.key])
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                color: "#f5f9fb"
                                Behavior on color { ColorAnimation { duration: 220 } }
                            }
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            height: 20
            spacing: 6
            DIcon {
                name: root.connected ? "noise_control_on" : "info"
                size: 16
                color: "#a9cbd2"
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                width: parent.width - 22
                text: root.connected ? root.modeLabel(root.status.noise_control) : "Connect your Buds to see live status"
                font.pixelSize: Theme.fontSizeSmall
                color: "#c8d8dc"
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
