import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "."
import "./presentation" as Gbuds

PluginComponent {
    id: root
    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({}) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool connected: snapshot.phase === "connected" || snapshot.phase === "controlling"
    readonly property bool activeConnection: connected && !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    readonly property string pillMode: pluginData.pillMode || "compact"
    readonly property string batteryStyle: pluginData.batteryIndicatorStyle || "clean"
    readonly property int glyphSize: Math.max(root.iconSize, Math.max(28, Math.min(32, root.widgetThickness))) - 2
    function themeColor(mode, custom, fallback) {
        if (mode === "primary" || mode === "secondary" || mode === "tertiary") return Theme[mode];
        // Preserve color presets saved by older local versions.
        var legacy = {silver:"#d2dce0",white:"#ffffff",violet:"#b388ff",mint:"#80cbc4",graphite:"#50606b"};
        if (legacy[mode]) return legacy[mode];
        if (mode === "custom") return custom || fallback;
        return fallback;
    }
    readonly property color iconTint: themeColor(pluginData.iconColorMode, pluginData.customColor, Theme.widgetIconColor)
    readonly property color idleTint: {
        var mode = pluginData.idleColorMode;
        if (mode === "amber") return Theme.warning;
        if (mode === "error") return Theme.error;
        if (mode === "muted") return Theme.widgetInactiveIconColor;
        return themeColor(mode, pluginData.customIdleColor, Theme.warning);
    }
    readonly property color caseTint: pluginData.caseColorMode === "match"
        ? themeColor(pluginData.colorMode || "primary", pluginData.customColor, Theme.primary)
        : themeColor(pluginData.caseColorMode, pluginData.customCaseColor, root.iconTint)
    function available(part) {
        return root.activeConnection && typeof root.status[part] === "number" && root.status[part] >= 0 &&
            (part === "case" || root.status["placement_" + part] !== "DISCONNECTED");
    }
    function batteryTint(part) {
        if (!available(part)) return Theme.widgetInactiveIconColor;
        if (root.status[part] <= 10) return Theme.error;
        if (root.status[part] <= 30) return Theme.warning;
        return part === "case" ? root.caseTint : root.iconTint;
    }
    component Pill: Grid {
        columns: root.isVertical ? 1 : 5
        spacing: Theme.spacingS
        DIcon {
            visible: !root.activeConnection || root.pillMode === "icon-only"
            name: root.activeConnection ? "earbuds" : "bluetooth_disabled"
            size: root.iconSize
            color: root.activeConnection ? root.iconTint : Theme.widgetInactiveIconColor
        }
        Repeater {
            model: root.activeConnection && root.pillMode !== "icon-only"
                ? (root.pillMode === "detailed" ? ["left", "right", "case"] : ["left", "right"]) : []
            delegate: Row {
                required property string modelData
                spacing: Theme.spacingXXS
                Gbuds.EarbudGlyph {
                    part: modelData
                    modelCode: root.device.model_code || ""
                    width: root.glyphSize
                    height: root.glyphSize
                    available: root.available(modelData)
                    idle: root.pluginData.warnOutOfEar !== false && root.status["placement_" + modelData] === "IDLE"
                    idleColor: root.idleTint
                    badgeColor: Theme.surfaceContainer
                    tint: root.batteryStyle === "tint" || root.batteryStyle === "border" || root.batteryStyle === "clean"
                        ? root.batteryTint(modelData) : modelData === "case" ? root.caseTint : root.iconTint
                    fillTint: root.batteryStyle === "tint" ? root.batteryTint(modelData)
                        : Theme.withAlpha(root.batteryStyle === "glow" ? root.batteryTint(modelData) : tint, 0.16)
                    filled: root.batteryStyle === "tint" || root.batteryStyle === "glow"
                }
                StyledText {
                    visible: root.pluginData.showBatteryPercentages === true
                    text: root.available(modelData) ? root.status[modelData] + "%" : "—"
                    font.pixelSize: root.textSize
                    color: Theme.widgetTextColor
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
        Gbuds.NoiseModeIcon {
            visible: root.activeConnection && root.pillMode !== "icon-only" && root.pluginData.showModeIcon !== false && !!root.status.noise_control
            mode: root.status.noise_control || "OFF"
            size: root.glyphSize
            color: root.iconTint
        }
    }
    horizontalBarPill: Component { Pill {} }
    verticalBarPill: Component { Pill {} }
    popoutContent: Component {
        Item {
            width: parent.width
            implicitHeight: panel.implicitHeight
            Gbuds.GbudsPanel {
                id: panel
                anchors.fill: parent
                pluginId: root.pluginId
                pluginService: root.pluginService
                config: root.pluginData
            }
        }
    }
    popoutWidth: 390
    popoutHeight: 590
}
