import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins
import "."

PluginComponent {
    id: root

    PluginGlobalVar {
        id: telemetry
        varName: "telemetry"
        defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" })
    }

    PluginGlobalVar {
        id: deviceInfo
        varName: "device"
        defaultValue: ({})
    }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool connected: snapshot.phase === "connected" || snapshot.phase === "controlling"
    readonly property bool activeConnection: connected && !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    readonly property string pillMode: pluginData.pillMode || "compact"
    readonly property string batteryIndicatorStyle: pluginData.batteryIndicatorStyle || "glow"
    readonly property string iconColorMode: pluginData.iconColorMode || "auto"
    readonly property bool showModeIcon: pluginData.showModeIcon !== false
    readonly property bool showBatteryPercentages: pluginData.showBatteryPercentages === true
    readonly property bool warnOutOfEar: pluginData.warnOutOfEar !== false
    readonly property bool leftOut: activeConnection && status.placement_left && status.placement_left !== "WEARING"
    readonly property bool rightOut: activeConnection && status.placement_right && status.placement_right !== "WEARING"

    readonly property color pillIconColor: {
        var mode = root.iconColorMode;
        if (mode === "auto") return Theme.widgetIconColor;
        if (mode === "primary") return Theme.primary;
        if (mode === "secondary") return Theme.secondary;
        if (mode === "tertiary") return Theme.tertiary;
        if (mode === "custom") return pluginData.customColor || Theme.widgetIconColor;
        return Theme.widgetIconColor;
    }

    readonly property color pillAccentColor: {
        var mode = pluginData.colorMode || "primary";
        if (mode === "primary") return Theme.primary;
        if (mode === "secondary") return Theme.secondary;
        if (mode === "tertiary") return Theme.tertiary;
        if (mode === "custom") return pluginData.customColor || Theme.primary;
        return Theme.primary;
    }

    readonly property color pillCaseColor: {
        var mode = pluginData.caseColorMode || "auto";
        if (mode === "auto") return pillIconColor;
        if (mode === "match") return pillAccentColor;
        if (mode === "custom") return pluginData.customCaseColor || pillIconColor;
        return pillIconColor;
    }

    readonly property color pillBudFillColor: {
        var mode = root.iconColorMode;
        if (mode === "auto") return Theme.withAlpha(Theme.widgetIconColor, 0.3);
        if (mode === "primary") return Theme.primary;
        if (mode === "secondary") return Theme.secondary;
        if (mode === "tertiary") return Theme.tertiary;
        if (mode === "custom") return pluginData.customColor || Theme.widgetIconColor;
        return Theme.withAlpha(Theme.widgetIconColor, 0.3);
    }

    readonly property color idleIndicatorColor: {
        var mode = pluginData.idleColorMode || "auto";
        if (mode === "auto") return Theme.widgetIconColor;
        if (mode === "amber") return Theme.warning;
        if (mode === "primary") return Theme.primary;
        if (mode === "secondary") return Theme.secondary;
        if (mode === "tertiary") return Theme.tertiary;
        if (mode === "error") return Theme.error;
        if (mode === "muted") return Theme.widgetInactiveIconColor;
        if (mode === "custom") return pluginData.customIdleColor || Theme.widgetIconColor;
        return Theme.widgetIconColor;
    }

    function isStemModel() {
        var code = (root.device.model_code || "").toUpperCase();
        // Models with small/bean/in-ear form factor:
        // SM-R400N (Buds FE), SM-R177 (Buds2), SM-R170 (Buds), SM-R175 (Buds+),
        // SM-R180 (Buds Live), SM-R190 (Buds Pro), SM-R510 (Buds2 Pro)
        if (code.indexOf("SM-R400") !== -1 || code.indexOf("SM-R177") !== -1 ||
            code.indexOf("SM-R170") !== -1 || code.indexOf("SM-R175") !== -1 ||
            code.indexOf("SM-R180") !== -1 || code.indexOf("SM-R190") !== -1 ||
            code.indexOf("SM-R510") !== -1) {
            return false;
        }
        // Defaults to stem / Large (Buds 3 / SM-R530, Buds 3 Pro / SM-R630, etc.)
        return true;
    }

    function earbudIcon(side, layer) {
        var stem = isStemModel();
        var suffix = (layer && layer !== "") ? ("_" + layer + ".svg") : ".svg";
        var base = stem ? "assets/icons/L_" : "assets/icons/s_";
        return Qt.resolvedUrl(base + side + suffix);
    }

    function modeIcon(mode) {
        if (mode === "NOISE_REDUCTION") return "noise_control_on";
        if (mode === "AMBIENT_SOUND") return "hearing";
        if (mode === "ADAPTIVE") return "auto_mode";
        return "noise_control_off";
    }

    component EarbudsPairItem: Item {
        id: pairItem

        readonly property var leftBat: root.status.left
        readonly property var rightBat: root.status.right
        readonly property string leftPlacement: root.status.placement_left || ""
        readonly property string rightPlacement: root.status.placement_right || ""

        readonly property bool leftConnected: root.activeConnection && leftPlacement !== "DISCONNECTED" && typeof leftBat === "number" && leftBat >= 0
        readonly property bool rightConnected: root.activeConnection && rightPlacement !== "DISCONNECTED" && typeof rightBat === "number" && rightBat >= 0
        readonly property bool anyConnected: leftConnected || rightConnected
        readonly property bool bothConnected: leftConnected && rightConnected

        readonly property bool leftIdle: leftConnected && leftPlacement !== "WEARING"
        readonly property bool rightIdle: rightConnected && rightPlacement !== "WEARING"

        readonly property int budWidth: Math.round((root.iconSize + 2) * 0.70)
        readonly property int budHeight: Math.round((root.iconSize + 2) * 1.15)

        function getBudTint(bat, connected) {
            if (!connected || typeof bat !== "number" || bat < 0) return Theme.withAlpha(Theme.surfaceVariantText, 0.45);
            if (bat <= 20) return Theme.error;
            if (bat <= 40) return Theme.warning;
            return Theme.success;
        }

        readonly property color leftTintColor: getBudTint(leftBat, leftConnected)
        readonly property color rightTintColor: getBudTint(rightBat, rightConnected)

        readonly property int effectiveBattery: {
            if (bothConnected) return Math.min(leftBat, rightBat);
            if (leftConnected) return leftBat;
            if (rightConnected) return rightBat;
            return -1;
        }

        readonly property color pairTintColor: {
            if (!anyConnected || effectiveBattery < 0) return Theme.withAlpha(Theme.surfaceVariantText, 0.45);
            if (effectiveBattery <= 20) return Theme.error;
            if (effectiveBattery <= 40) return Theme.warning;
            return Theme.success;
        }

        width: root.activeConnection ? pairContentRow.implicitWidth : root.iconSize + 4
        height: pairItem.budHeight

        DIcon {
            anchors.centerIn: parent
            visible: !root.activeConnection
            name: "bluetooth_disabled"
            size: root.iconSize
            color: Theme.widgetInactiveIconColor
        }

        Row {
            id: pairContentRow
            visible: root.activeConnection
            spacing: 5
            anchors.verticalCenter: parent.verticalCenter

            Item {
                id: pairIconBox
                width: budsPairRow.implicitWidth
                height: pairItem.budHeight
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    id: pairGlow
                    anchors.centerIn: parent
                    width: parent.width + 10
                    height: parent.height + 4
                    radius: Math.round(height / 2)
                    color: pairItem.pairTintColor
                    visible: root.batteryIndicatorStyle === "glow" && pairItem.anyConnected
                    opacity: 0.28
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 26
                    }
                }

                Row {
                    id: budsPairRow
                    spacing: 2
                    anchors.centerIn: parent

                    Item {
                        width: pairItem.budWidth
                        height: pairItem.budHeight
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: leftFillSvg
                            anchors.fill: parent
                            source: root.earbudIcon("left", "fill")
                            sourceSize.width: 48; sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: leftFillSvg
                            source: leftFillSvg
                            visible: root.batteryIndicatorStyle !== "none"
                            colorization: 1.0
                            colorizationColor: root.pillBudFillColor
                            opacity: pairItem.leftConnected ? 0.95 : 0.25
                            Behavior on colorizationColor { ColorAnimation { duration: 150 } }
                        }

                        Image {
                            id: leftStrokeSvg
                            anchors.fill: parent
                            source: root.earbudIcon("left", "stroke")
                            sourceSize.width: 48; sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: leftStrokeSvg
                            source: leftStrokeSvg
                            colorization: 1.0
                            colorizationColor: {
                                if (root.batteryIndicatorStyle === "tint" || root.batteryIndicatorStyle === "border")
                                    return pairItem.leftTintColor;
                                return pairItem.leftConnected ? root.pillIconColor : Theme.widgetInactiveIconColor;
                            }
                            opacity: pairItem.leftConnected ? (pairItem.leftIdle ? 0.75 : 1.0) : 0.35
                            Behavior on colorizationColor { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            visible: root.warnOutOfEar && pairItem.leftIdle
                            width: 12; height: 12; radius: 6
                            color: Theme.surfaceContainerHighest
                            border.color: Theme.withAlpha(root.idleIndicatorColor, 0.55)
                            border.width: 1
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: -2
                            z: 10

                            DIcon {
                                name: "schedule"
                                size: 9
                                color: root.idleIndicatorColor
                                anchors.centerIn: parent
                            }
                        }
                    }

                    Item {
                        width: pairItem.budWidth
                        height: pairItem.budHeight
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            id: rightFillSvg
                            anchors.fill: parent
                            source: root.earbudIcon("right", "fill")
                            sourceSize.width: 48; sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: rightFillSvg
                            source: rightFillSvg
                            visible: root.batteryIndicatorStyle !== "none"
                            colorization: 1.0
                            colorizationColor: root.pillBudFillColor
                            opacity: pairItem.rightConnected ? 0.95 : 0.25
                            Behavior on colorizationColor { ColorAnimation { duration: 150 } }
                        }

                        Image {
                            id: rightStrokeSvg
                            anchors.fill: parent
                            source: root.earbudIcon("right", "stroke")
                            sourceSize.width: 48; sourceSize.height: 48
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: rightStrokeSvg
                            source: rightStrokeSvg
                            colorization: 1.0
                            colorizationColor: {
                                if (root.batteryIndicatorStyle === "tint" || root.batteryIndicatorStyle === "border")
                                    return pairItem.rightTintColor;
                                return pairItem.rightConnected ? root.pillIconColor : Theme.widgetInactiveIconColor;
                            }
                            opacity: pairItem.rightConnected ? (pairItem.rightIdle ? 0.75 : 1.0) : 0.35
                            Behavior on colorizationColor { ColorAnimation { duration: 150 } }
                        }

                        Rectangle {
                            visible: root.warnOutOfEar && pairItem.rightIdle
                            width: 12; height: 12; radius: 6
                            color: Theme.surfaceContainerHighest
                            border.color: Theme.withAlpha(root.idleIndicatorColor, 0.55)
                            border.width: 1
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottomMargin: -2
                            z: 10

                            DIcon {
                                name: "schedule"
                                size: 9
                                color: root.idleIndicatorColor
                                anchors.centerIn: parent
                            }
                        }
                    }
                }
            }

            StyledText {
                visible: root.showBatteryPercentages && root.activeConnection && pairItem.anyConnected
                text: {
                    if (pairItem.bothConnected) {
                        return pairItem.leftBat === pairItem.rightBat ?
                            pairItem.leftBat + "%" :
                            pairItem.leftBat + "% · " + pairItem.rightBat + "%";
                    }
                    if (pairItem.leftConnected) return pairItem.leftBat + "%";
                    if (pairItem.rightConnected) return pairItem.rightBat + "%";
                    return "—";
                }
                font.pixelSize: root.textSize - 1
                font.weight: Font.Medium
                color: Theme.widgetTextColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            EarbudsPairItem {
                visible: root.pillMode !== "icon-only"
                anchors.verticalCenter: parent.verticalCenter
            }

            DIcon {
                visible: root.pillMode === "icon-only"
                name: root.activeConnection ? "earbuds" : "bluetooth_disabled"
                size: root.iconSize
                color: root.activeConnection ? root.pillIconColor : Theme.widgetInactiveIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            // Case battery (when detailed mode)
            Item {
                id: pillCaseItem
                visible: root.activeConnection && root.pillMode === "detailed" && typeof root.status.case === "number"
                width: caseRow.implicitWidth
                height: root.iconSize + 2
                anchors.verticalCenter: parent.verticalCenter

                readonly property int caseBattery: typeof root.status.case === "number" ? root.status.case : 0
                readonly property color caseTint: {
                    if (caseBattery <= 20) return Theme.error;
                    if (caseBattery <= 40) return Theme.warning;
                    return Theme.success;
                }

                Row {
                    id: caseRow
                    spacing: 3
                    anchors.verticalCenter: parent.verticalCenter

                    Item {
                        width: root.iconSize + 2
                        height: root.iconSize + 2
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            id: caseGlow
                            anchors.centerIn: parent
                            width: root.iconSize + 8
                            height: root.iconSize + 8
                            radius: width / 2
                            color: pillCaseItem.caseTint
                            visible: root.batteryIndicatorStyle === "glow" && root.activeConnection
                            opacity: 0.28
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 1.0
                                blurMax: 28
                            }
                        }

                        Image {
                            id: pillCaseFillSvg
                            anchors.centerIn: parent
                            width: root.iconSize - 1
                            height: root.iconSize + 1
                            source: Qt.resolvedUrl("assets/icons/case_fill.svg")
                            sourceSize.width: 32; sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: pillCaseFillSvg
                            source: pillCaseFillSvg
                            visible: root.batteryIndicatorStyle !== "none"
                            colorization: 1.0
                            colorizationColor: root.pillBudFillColor
                            opacity: root.activeConnection ? 0.95 : 0.25
                        }

                        Image {
                            id: pillCaseStrokeSvg
                            anchors.centerIn: parent
                            width: root.iconSize - 1
                            height: root.iconSize + 1
                            source: Qt.resolvedUrl("assets/icons/case_stroke.svg")
                            sourceSize.width: 32; sourceSize.height: 32
                            fillMode: Image.PreserveAspectFit
                            visible: false
                        }

                        MultiEffect {
                            anchors.fill: pillCaseStrokeSvg
                            source: pillCaseStrokeSvg
                            colorization: 1.0
                            colorizationColor: {
                                if (root.batteryIndicatorStyle === "tint" || root.batteryIndicatorStyle === "border")
                                    return pillCaseItem.caseTint;
                                return root.activeConnection ? root.pillIconColor : Theme.widgetInactiveIconColor;
                            }
                            opacity: root.activeConnection ? 1.0 : 0.4
                        }
                    }

                    StyledText {
                        visible: root.showBatteryPercentages
                        text: pillCaseItem.caseBattery + "%"
                        font.pixelSize: root.textSize - 1
                        font.weight: Font.Medium
                        color: Theme.widgetTextColor
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            DIcon {
                visible: root.activeConnection && root.pillMode !== "icon-only" && root.showModeIcon && !!root.status.noise_control
                name: root.modeIcon(root.status.noise_control)
                size: Math.round(root.iconSize - 1)
                color: root.pillIconColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: 3

            EarbudsPairItem {
                visible: root.pillMode !== "icon-only"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            DIcon {
                visible: root.pillMode === "icon-only"
                name: root.activeConnection ? "earbuds" : "bluetooth_disabled"
                size: root.iconSize
                color: root.activeConnection ? root.pillIconColor : Theme.widgetInactiveIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            DIcon {
                visible: root.activeConnection && root.pillMode !== "icon-only" && root.showModeIcon && !!root.status.noise_control
                name: root.modeIcon(root.status.noise_control)
                size: Math.round(root.iconSize - 2)
                color: root.pillIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        Item {
            width: parent.width
            implicitHeight: panel.implicitHeight
            GbudsPanel {
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
