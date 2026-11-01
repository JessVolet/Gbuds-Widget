import QtQuick
import qs.Modules.Plugins
import "."
import "./interface-v050" as Gbuds

DesktopPluginComponent {
    id: root

    readonly property bool compact: pluginData.desktopLayout === "compact"
    property real defaultWidth: compact ? 360 : 380
    property real defaultHeight: compact ? 256 : 570
    minWidth: compact ? 300 : 330
    minHeight: compact ? 246 : 570

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
