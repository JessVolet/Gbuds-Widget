import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "."

DesktopPluginComponent {
    id: root

    minWidth: 330
    minHeight: 570
    widgetWidth: 380
    widgetHeight: 570

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surfaceContainer, 0.96)
        border.color: Theme.outline
        border.width: 1
    }

    GbudsPanel {
        anchors.fill: parent
        anchors.margins: 1
        pluginId: root.pluginId
        pluginService: root.pluginService
        config: root.pluginData
        desktopMode: true
    }
}
