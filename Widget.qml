import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    PluginGlobalVar {
        id: telemetry
        varName: "telemetry"
        defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" })
    }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    PluginGlobalVar {
        id: deviceInfo
        varName: "device"
        defaultValue: ({})
    }
    readonly property var device: deviceInfo.value || ({})
    readonly property bool isConnected: snapshot.phase === "connected"

    function render(side) {
        var code = device.model_code || "";
        var model = code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (!model) return "";
        var colorName = (device.color || "").toLowerCase();
        var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
        return Qt.resolvedUrl("assets/device/" + model + color + "-" + side + ".png");
    }

    function pillText() {
        if (snapshot.phase === "missing-cli")
            return "Install Gbuds"
        if (isConnected)
            return "L " + status.left + "%  ·  R " + status.right + "%"
        return "Buds waiting"
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DIcon {
                name: "headphones"
                size: root.iconSize
                color: root.isConnected ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.pillText()
                font.pixelSize: root.textSize
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DIcon {
                name: "headphones"
                size: root.iconSize
                color: root.isConnected ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.isConnected ? Math.min(root.status.left, root.status.right) + "%" : "—"
                font.pixelSize: root.textSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: panel
            headerText: "Gbuds Watch"
            detailsText: root.isConnected ? "Live telemetry from gbuds watch --json" : root.snapshot.detail || "Waiting for telemetry"

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - panel.headerHeight - panel.detailsHeight - Theme.spacingXL

                Column {
                    anchors.fill: parent
                    spacing: Theme.spacingS

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        Repeater {
                            model: [
                                { label: "LEFT", value: root.isConnected ? root.status.left + "%" : "—" },
                                { label: "RIGHT", value: root.isConnected ? root.status.right + "%" : "—" },
                                { label: "CASE", value: root.isConnected && root.status.case > 0 ? root.status.case + "%" : "N/A" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: (parent.width - 2 * Theme.spacingS) / 3
                                height: 62
                                radius: Theme.cornerRadius
                                color: Theme.cardSurface

                                Column {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXS

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.label
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceVariantText
                                    }

                                    StyledText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: modelData.value
                                        font.pixelSize: Theme.fontSizeMedium
                                        font.weight: Font.Bold
                                        color: Theme.surfaceText
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        height: 52
                        spacing: Theme.spacingS
                        visible: root.isConnected

                        Repeater {
                            model: [0, 1]
                            delegate: Item {
                                required property int modelData
                                width: 48
                                height: 52

                                Image {
                                    anchors.fill: parent
                                    source: root.render(modelData)
                                    fillMode: Image.PreserveAspectFit
                                    visible: source.toString() !== ""
                                }
                                DIcon {
                                    anchors.centerIn: parent
                                    name: "headphones"
                                    size: 32
                                    color: Theme.primary
                                    visible: !root.render(modelData)
                                }
                            }
                        }

                        DIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            name: "inventory_2"
                            size: 25
                            color: Theme.primary
                        }
                    }

                    StyledText {
                        width: parent.width
                        visible: root.isConnected && !!root.snapshot.event
                        text: root.snapshot.event || ""
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.primary
                        elide: Text.ElideRight
                    }

                    StyledText {
                        text: "Latest JSON sample"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: Theme.surfaceText
                    }

                    Text {
                        visible: root.snapshot.phase === "missing-cli"
                        text: "Open Gbuds installation guide"
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall
                        font.underline: true

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally("https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md")
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: Math.max(72, parent.height - y)
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh
                        clip: true

                        StyledText {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingS
                            text: root.isConnected ? JSON.stringify(root.status, null, 2) : root.snapshot.phase === "missing-cli" ? "Gbuds CLI is not installed." : "Waiting for a connected Galaxy Buds device.\n\nThe daemon starts one gbuds watch --json process and retries automatically."
                            font.family: "monospace"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 410
    popoutHeight: 370
}
