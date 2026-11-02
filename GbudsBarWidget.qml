import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "src/state"
import "src/presentation"
import "src/surfaces"
import "src/config"

PluginComponent {
    id:root
    readonly property var config:preferences.value
    ConfigStore { id:preferences; source:root.pluginData }
    UiState { id:state; pluginId:root.pluginId; service:root.pluginService }
    function tint(mode, custom, fallback) {
        const palette={primary:Theme.primary,secondary:Theme.secondary,tertiary:Theme.tertiary,error:Theme.error,amber:Theme.warning,muted:Theme.widgetInactiveIconColor};
        return mode === "custom" ? custom || fallback : palette[mode] || fallback;
    }
    readonly property color iconTint:tint(config.iconColorMode,config.customColor,Theme.widgetIconColor)
    readonly property color caseTint:tint(config.caseColorMode,config.customCaseColor,iconTint)
    readonly property color idleTint:tint(config.idleColorMode,config.customIdleColor,Theme.warning)
    function batteryTint(part) {
        return Number(state.status[part]) <= 20 ? Theme.error : Number(state.status[part]) <= 50 ? Theme.warning : iconTint;
    }
    component Pill: Grid {
        columns:root.isVertical ? 1 : 4
        spacing:4
        DIcon { visible:!state.connected || root.config.pillMode === "icon-only"; name:state.connected ? "earbuds" : "bluetooth_disabled"; size:root.iconSize; color:Theme.widgetIconColor }
        Repeater {
            model:state.connected && root.config.pillMode !== "icon-only" ? (root.config.pillMode === "detailed" ? ["left","right","case"] : ["left","right"]) : []
            Row {
                required property string modelData
                spacing:2
                PartIcon { part:modelData; device:state.device; width:root.iconSize+3; height:width; idle:root.config.warnOutOfEar && state.status["placement_"+modelData] === "IDLE"; tint:root.config.batteryIndicatorStyle === "clean" ? (modelData === "case" ? root.caseTint : root.iconTint) : root.batteryTint(modelData); filled:root.config.batteryIndicatorStyle === "tint" || root.config.batteryIndicatorStyle === "glow"; idleTint:root.idleTint }
                StyledText { visible:root.config.showBatteryPercentages; text:state.battery(modelData); color:Theme.widgetTextColor; font.pixelSize:root.textSize; anchors.verticalCenter:parent.verticalCenter }
            }
        }
        ModeIcon { visible:state.connected && root.config.showModeIcon && state.mode !== "OFF" && root.config.pillMode !== "icon-only"; mode:state.mode; size:root.iconSize+3; tint:Theme.widgetIconColor }
    }
    horizontalBarPill:Component { Pill {} }
    verticalBarPill:Component { Pill {} }
    popoutContent:Component { DevicePanel { width:parent.width; height:560; pluginId:root.pluginId; service:root.pluginService; config:root.config } }
    popoutWidth:390
    popoutHeight:560
}
