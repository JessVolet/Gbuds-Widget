import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root

    PluginGlobalVar {
        id: telemetry
        varName: "telemetry"
        defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" })
    }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property bool connected: snapshot.phase === "connected"
    readonly property string pillMode: pluginData.pillMode || "compact"

    function pillLabel(vertical) {
        if (snapshot.phase === "missing-cli")
            return vertical ? "!" : "Install Gbuds";
        if (!connected)
            return vertical ? "—" : "Buds waiting";
        if (pillMode === "minimal")
            return Math.min(status.left, status.right) + "%";
        if (pillMode === "detailed")
            return "L " + status.left + " · R " + status.right + (typeof status.case === "number" ? " · C " + status.case : "");
        return "L " + status.left + "%  ·  R " + status.right + "%";
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            DIcon {
                name: "headphones"
                size: root.iconSize
                color: root.connected ? Theme.primary : root.snapshot.phase === "missing-cli" ? Theme.error : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                text: root.pillLabel(false)
                font.pixelSize: root.textSize
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                visible: root.connected && root.status.noise_control
                text: root.status.noise_control === "NOISE_REDUCTION" ? "ANC" : root.status.noise_control === "AMBIENT_SOUND" ? "AMB" : root.status.noise_control === "ADAPTIVE" ? "AUTO" : "OFF"
                font.pixelSize: root.textSize - 1
                font.weight: Font.Bold
                color: Theme.primary
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
                color: root.connected ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
            StyledText {
                text: root.pillLabel(true)
                font.pixelSize: root.textSize
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: "Gbuds Watch"
            detailsText: root.connected ? "Live Galaxy Buds controls and telemetry" : root.snapshot.detail || "Waiting for a connected Galaxy Buds device"

            Item {
                width: parent.width
                implicitHeight: root.popoutHeight - popout.headerHeight - popout.detailsHeight - Theme.spacingXL
                GbudsPanel {
                    anchors.fill: parent
                    pluginId: root.pluginId
                    pluginService: root.pluginService
                    config: root.pluginData
                }
            }
        }
    }

    popoutWidth: 460
    popoutHeight: 650
}
