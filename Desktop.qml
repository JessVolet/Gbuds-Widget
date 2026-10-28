import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "."

DesktopPluginComponent {
    id: root

    readonly property bool compact: pluginData.desktopLayout === "compact"
    property real defaultWidth: compact ? 330 : 380
    property real defaultHeight: compact ? 190 : 570
    minWidth: compact ? 260 : 330
    minHeight: compact ? 160 : 570
    widgetWidth: 380
    widgetHeight: 570

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, 0.96)
        border.color: Theme.outline
        border.width: 1
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
