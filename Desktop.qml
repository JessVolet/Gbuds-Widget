import QtQuick
import Quickshell
import qs.Modules.Plugins
import "src/config"
import "src/state"
import "src/surfaces"

DesktopPluginComponent {
    id:root
    readonly property var effectiveConfig:preferences.value
    ConfigStore { id:preferences; source:root.isInstance ? root.instanceConfig : root.pluginData; locked:root.lockScreen }
    readonly property bool shouldShow:state.connected || effectiveConfig.desktopOfflinePolicy !== "hide"
    property bool acceptsKeyboardFocus:!lockScreen
    property real defaultWidth:336
    property real defaultHeight:320
    minWidth:Math.max(220, effectiveConfig.desktopPadding*2 + (effectiveConfig.desktopHorizontal ? view.parts.length*(effectiveConfig.desktopEarbudSize+26)+Math.max(0,view.parts.length-1)*effectiveConfig.desktopGap : effectiveConfig.desktopEarbudSize+26))
    minHeight:state.connected ? view.implicitHeight : 74
    UiState { id:state; pluginId:root.pluginId; service:root.pluginService }
    DeviceView { id:view; anchors.fill:parent; state:state; config:root.effectiveConfig; locked:root.lockScreen; offlinePolicy:root.effectiveConfig.desktopOfflinePolicy }
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
