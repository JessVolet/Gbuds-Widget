import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DBar
import "src/state"
import "src/presentation"
import "src/surfaces"
import "src/config"
import "src/presentation/ColorPolicy.js" as Colors

PluginComponent {
    id: root
    readonly property var config: preferences.value
    property alias deviceState: model
    ConfigStore { id: preferences; source: root.pluginData }
    UiState { id: model; pluginId: root.pluginId; service: root.pluginService }

    function tint(mode, custom, fallback) {
        const palette = {primary:Theme.primary, secondary:Theme.secondary, tertiary:Theme.tertiary,
            error:Theme.error, amber:Theme.warning, muted:Theme.widgetInactiveIconColor};
        return mode === "custom" ? custom || fallback : palette[mode] || fallback;
    }
    readonly property color systemIconTint:Colors.foreground(Theme.widgetIconColor,root.barConfig ? BarMetrics.widgetFill(root.barConfig) : Theme.widgetBaseBackgroundColor,[Theme.surfaceText,Theme.surface,Theme.contrastLight,Theme.contrastDark])
    readonly property color iconTint: tint(config.iconColorMode, config.customColor, systemIconTint)
    readonly property color caseTint: tint(config.caseColorMode, config.customCaseColor, iconTint)
    readonly property color idleTint: tint(config.idleColorMode, config.customIdleColor, Theme.warning)

    function batteryTint(part) {
        const value = Number(root.deviceState.status[part]);
        return value <= 20 ? Theme.error : value <= 50 ? Theme.warning : iconTint;
    }
    component Pill: Grid {
        columns: root.isVertical ? 1 : 4
        spacing: 4
        DIcon {
            visible: !root.deviceState.connected || root.config.pillMode === "icon-only"
            name: root.deviceState.connected ? "earbuds" : "bluetooth_disabled"
            size: root.iconSize
            color: Theme.widgetIconColor
        }
        Repeater {
            model: root.deviceState.connected && root.config.pillMode !== "icon-only"
                ? (root.config.pillMode === "detailed" ? ["left","right","case"] : ["left","right"]) : []
            Row {
                required property string modelData
                spacing: 2
                PartIcon {
                    part: modelData
                    device: root.deviceState.device
                    width: root.iconSize + 3
                    height: width
                    idle: root.config.warnOutOfEar && root.deviceState.status["placement_" + modelData] === "IDLE"
                    tint: root.config.batteryIndicatorStyle === "clean"
                        ? (modelData === "case" ? root.caseTint : root.iconTint) : root.batteryTint(modelData)
                    filled: root.config.batteryIndicatorStyle === "tint" || root.config.batteryIndicatorStyle === "glow"
                    idleTint: root.idleTint
                }
                StyledText {
                    visible: root.config.showBatteryPercentages
                    text: root.deviceState.battery(modelData)
                    color: Theme.widgetTextColor
                    font.pixelSize: root.textSize
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        ModeIcon {
            visible: root.deviceState.connected && root.config.showModeIcon
                && root.deviceState.mode !== "OFF" && root.config.pillMode !== "icon-only"
            mode: root.deviceState.mode
            size: root.iconSize + 3
            tint: root.systemIconTint
        }
    }
    horizontalBarPill: Component { Pill {} }
    verticalBarPill: Component { Pill {} }
    popoutContent: Component {
        DevicePanel {
            width: parent.width
            active:root.interactionActive
            pluginId: root.pluginId
            service: root.pluginService
            config: root.config
        }
    }
    popoutWidth: 420
    popoutHeight: 0
}
