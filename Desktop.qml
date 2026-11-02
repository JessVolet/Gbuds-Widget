import QtQuick
import Quickshell
import qs.Modules.Plugins
import "src/config"
import "src/presentation/Layout.js" as Layout
import "src/state"
import "src/surfaces"

DesktopPluginComponent {
    id:root
    readonly property var effectiveConfig:preferences.value
    ConfigStore { id:preferences; source:root.isInstance ? root.instanceConfig : root.pluginData; locked:root.lockScreen }
    readonly property bool shouldShow:model.connected || effectiveConfig.desktopOfflinePolicy !== "hide"
    property bool acceptsKeyboardFocus:!lockScreen
    property real defaultWidth:336
    property real defaultHeight:320
    readonly property real noiseMinWidth:effectiveConfig.desktopShowNoise && effectiveConfig.desktopPreset !== "minimal"
        ? (model.device.supported_noise_modes || []).length * (effectiveConfig.desktopNoiseSize+16) : 0
    minWidth:Math.max(220,effectiveConfig.desktopPadding*2+Math.max(Layout.groupWidth(effectiveConfig,view.parts),noiseMinWidth))
    minHeight:model.connected ? view.implicitHeight : 74
    UiState { id:model; pluginId:root.pluginId; service:root.pluginService }
    DeviceView { id:view; anchors.fill:parent; state:model; config:root.effectiveConfig; locked:root.lockScreen; offlinePolicy:root.effectiveConfig.desktopOfflinePolicy }
    Region { id:emptyInput }
    Binding {
        target:root.QsWindow.window
        property:"mask"
        value:emptyInput
        when:!root.lockScreen && !root.shouldShow && root.QsWindow.window !== null
        restoreMode:Binding.RestoreBindingOrValue
    }
    function updateVisibility() { visible=shouldShow; }
    onShouldShowChanged:updateVisibility()
    Component.onCompleted:updateVisibility()
}
