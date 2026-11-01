import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "."
import "./interface" as Gbuds

DesktopPluginComponent {
    id: root

    readonly property bool compact: pluginData.desktopLayout === "compact"
    property real defaultWidth: compact ? 360 : 380
    property real defaultHeight: compact ? 230 : 570
    minWidth: compact ? 300 : 330
    minHeight: compact ? 220 : 570
    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property bool connected: (snapshot.phase === "connected" || snapshot.phase === "controlling") &&
                                      !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    opacity: connected ? 1 : 0
    enabled: connected
    Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", status: null }) }
    Region { id: emptyInputMask; width: 0; height: 0 }
    Binding {
        target: root.QsWindow.window
        property: "mask"
        value: emptyInputMask
        when: !root.connected && root.QsWindow.window !== null
        restoreMode: Binding.RestoreBinding
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.compact ? compactView : fullView
    }

    Component {
        id: fullView
        Gbuds.GbudsPanel {
            anchors.fill: parent
            anchors.margins: 1
            pluginId: root.pluginId
            pluginService: root.pluginService
            config: root.pluginData
            desktopMode: true
        }
    }

    Component {
        id: compactView
        Gbuds.BudsCompact {
            anchors.fill: parent
            pluginId: root.pluginId
            config: root.pluginData
        }
    }
}
