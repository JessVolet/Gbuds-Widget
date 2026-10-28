import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    minWidth: 290
    minHeight: 245
    widgetWidth: 365
    widgetHeight: 300

    PluginGlobalVar {
        id: telemetry
        varName: "telemetry"
        defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" })
    }
    PluginGlobalVar {
        id: deviceInfo
        varName: "device"
        defaultValue: ({})
    }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool isConnected: snapshot.phase === "connected"
    readonly property string installUrl: "https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md"

    function render(side) {
        var code = device.model_code || "";
        var model = code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (!model) return "";
        var colorName = (device.color || "").toLowerCase();
        var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
        return Qt.resolvedUrl("assets/device/" + model + color + "-" + side + ".png");
    }

    function placement(value) {
        if (value === "WEARING") return "Wearing"
        if (value === "IDLE") return "Out of ear"
        if (value === "IN_CASE") return "In case"
        if (value === "CLOSED_CASE") return "Case closed"
        if (value === "DISCONNECTED") return "Disconnected"
        return "—"
    }

    function mode(value) {
        if (value === "NOISE_REDUCTION") return "Noise cancellation"
        if (value === "AMBIENT_SOUND") return "Ambient sound"
        if (value === "ADAPTIVE") return "Adaptive"
        if (value === "OFF") return "Normal"
        return value ? value.replace(/_/g, " ") : "—"
    }

    function batteryText(value) {
        return typeof value === "number" && value > 0 ? value + "%" : "N/A"
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, 0.97)
        border.color: Theme.outline
        border.width: 1
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingS

        Row {
            width: parent.width
            spacing: Theme.spacingS

            Rectangle {
                width: 40
                height: 40
                radius: Theme.cornerRadius
                color: Theme.primaryContainer
                anchors.verticalCenter: parent.verticalCenter

                DIcon {
                    anchors.centerIn: parent
                    name: "headphones"
                    size: 22
                    color: Theme.primary
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacingXS
                width: parent.width - 40 - Theme.spacingS

                StyledText {
                    width: parent.width
                    text: root.device.model || "Galaxy Buds"
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    color: Theme.surfaceText
                    elide: Text.ElideRight
                }

                StyledText {
                    width: parent.width
                    text: root.isConnected ? "LIVE  ·  RFCOMM telemetry" : root.snapshot.phase === "missing-cli" ? "Gbuds CLI required" : "Waiting for Galaxy Buds"
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.isConnected ? Theme.primary : Theme.surfaceVariantText
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.outline
        }

        Row {
            width: parent.width
            spacing: Theme.spacingXS
            visible: root.isConnected

            Repeater {
                model: [
                    { label: "LEFT", battery: root.status.left, charging: root.status.left_charging, place: root.placement(root.status.placement_left) },
                    { label: "RIGHT", battery: root.status.right, charging: root.status.right_charging, place: root.placement(root.status.placement_right) },
                    { label: "CASE", battery: root.status.case, charging: root.status.case_charging, place: "Charging case" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: (parent.width - 2 * Theme.spacingXS) / 3
                    height: 84
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        spacing: Theme.spacingXS

                        Item {
                            width: 38
                            height: parent.height
                            Image {
                                anchors.fill: parent
                                source: modelData.label === "LEFT" ? root.render(0) : modelData.label === "RIGHT" ? root.render(1) : ""
                                fillMode: Image.PreserveAspectFit
                                visible: source.toString() !== ""
                            }
                            DIcon {
                                anchors.centerIn: parent
                                name: modelData.label === "CASE" ? "inventory_2" : "headphones"
                                size: 28
                                color: Theme.primary
                                visible: modelData.label === "CASE" || !root.render(modelData.label === "LEFT" ? 0 : 1)
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 38 - Theme.spacingXS
                            spacing: Theme.spacingXS

                            StyledText {
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: Theme.surfaceVariantText
                            }
                            StyledText {
                                text: root.batteryText(modelData.battery) + (modelData.charging ? "  ⚡" : "")
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                            }
                            StyledText {
                                width: parent.width
                                text: modelData.place
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: Theme.spacingXS
            visible: root.isConnected

            Rectangle {
                width: (parent.width - Theme.spacingXS) / 2
                height: 58
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "NOISE CONTROL"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        width: parent.width
                        text: root.mode(root.status.noise_control)
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                width: (parent.width - Theme.spacingXS) / 2
                height: 58
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS

                    StyledText {
                        text: "EQUALIZER"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        width: parent.width
                        text: root.mode(root.status.equalizer)
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.surfaceText
                        elide: Text.ElideRight
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: root.snapshot.phase === "missing-cli" ? 66 : 50
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            visible: !root.isConnected

            Column {
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: Theme.spacingXS

                StyledText {
                    width: parent.width
                    text: root.snapshot.phase === "missing-cli" ? "Install the Gbuds CLI" : root.snapshot.detail || "Connect a paired Galaxy Buds device. Gbuds Watch will retry automatically."
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.surfaceText
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: root.snapshot.phase === "missing-cli"
                    text: "Open installation guide"
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.underline: true

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.openUrlExternally(root.installUrl)
                    }
                }
            }
        }

        StyledText {
            width: parent.width
            visible: root.isConnected && !!root.snapshot.event
            text: root.snapshot.event || ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            elide: Text.ElideRight
        }
    }
}
