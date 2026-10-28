import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.Widgets as DuxWidgets
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

    DuxWidgets.WindowBlur {
        targetWindow: root.Window.window
        blurEnabled: BlurService.enabled
        surfaceColor: Theme.withAlpha(Theme.surfaceContainer, 0.78)
        blurX: 1
        blurY: 1
        blurWidth: Math.max(0, root.width - 2)
        blurHeight: Math.max(0, root.height - 2)
        blurRadius: 24
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: "transparent"
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
