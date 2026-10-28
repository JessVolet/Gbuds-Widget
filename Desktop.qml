import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "."

DesktopPluginComponent {
    id: root

    readonly property bool compact: pluginData.desktopLayout === "compact"
    property real defaultWidth: compact ? 330 : 380
    property real defaultHeight: compact ? 150 : 570
    minWidth: compact ? 260 : 330
    minHeight: compact ? 140 : 570
    widgetWidth: 380
    widgetHeight: 570
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
        GbudsPanel {
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
        BudsCompact {
            anchors.fill: parent
            pluginId: root.pluginId
        }
    }
}
