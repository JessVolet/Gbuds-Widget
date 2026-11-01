import QtQuick
import qs.Modules.Plugins
import "."
import "./interface-v060" as Gbuds
import "./core-v060/WidgetConfig.js" as WidgetConfig
import qs.Widgets

DesktopPluginComponent {
    id: root

    readonly property var effectiveConfig: WidgetConfig.resolve(isInstance ? instanceConfig : pluginData, isInstance ? ({}) : pluginData, lockScreen)
    readonly property string preset: effectiveConfig.desktopPreset
    readonly property bool detailed: preset === "detailed" && !lockScreen
    readonly property real earSize: Number(effectiveConfig.desktopEarbudSize || 48)
    readonly property real interBlockGap: effectiveConfig.desktopGap !== undefined ? Number(effectiveConfig.desktopGap) : 8
    readonly property real compactPreferredHeight: {
        var count = effectiveConfig.desktopShowCase === false || preset === "minimal" ? 2 : 3;
        var earRow = effectiveConfig.desktopHorizontal === false ? count * (earSize + 44) + (count - 1) * interBlockGap : earSize + 48;
        var padding = effectiveConfig.desktopPadding !== undefined ? Number(effectiveConfig.desktopPadding) : 10;
        return Math.max(208, padding * 2 +
            (effectiveConfig.desktopShowName === false || preset === "minimal" ? 0 : 24) + earRow +
            (effectiveConfig.desktopShowNoise === false || preset === "minimal" ? 0 : Math.max(80, Number(effectiveConfig.desktopNoiseSize || 36) + 44)) + 12);
    }
    property real defaultWidth: detailed ? 380 : 336
    property real defaultHeight: detailed ? 570 : compactPreferredHeight
    minWidth: detailed ? 330 : 300
    minHeight: detailed ? 570 : compactPreferredHeight

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ connected: false }) }
    readonly property bool deviceConnected: telemetry.value && telemetry.value.connected === true
    readonly property bool shouldShow: effectiveConfig.desktopOfflinePolicy !== "hide" || deviceConnected
    function refreshVisibility() { root.visible = root.shouldShow }
    Component.onCompleted: refreshVisibility()
    onInstanceDataChanged: Qt.callLater(refreshVisibility)
    onPluginDataChanged: Qt.callLater(refreshVisibility)
    onLockScreenChanged: Qt.callLater(refreshVisibility)
    onEffectiveConfigChanged: refreshVisibility()
    onDeviceConnectedChanged: refreshVisibility()

    Loader {
        anchors.fill: parent
        sourceComponent: root.detailed && root.deviceConnected ? fullView : compactView
    }

    Component {
        id: fullView
        Gbuds.GbudsPanel {
            anchors.fill: parent
            anchors.margins: 1
            pluginId: root.pluginId
            pluginService: root.pluginService
            config: root.effectiveConfig
            desktopMode: true
        }
    }

    Component {
        id: compactView
        Gbuds.BudsCompact {
            anchors.fill: parent
            pluginId: root.pluginId
            config: root.effectiveConfig
            offlinePolicy: root.effectiveConfig.desktopOfflinePolicy
            preset: root.preset
            lockScreen: root.lockScreen
        }
    }
}
