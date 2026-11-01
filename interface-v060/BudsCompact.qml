import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import "." as Gbuds

Item {
    id: root

    required property string pluginId
    property var config: ({})
    property string offlinePolicy: "connect"
    property string preset: "compact"
    property bool lockScreen: false
    BudsActions { id: actionController; pluginId: root.pluginId }

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", status: null }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({ busy: false }) }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property bool busy: (commandState.value || ({})).busy === true
    readonly property bool connected: actionController.connected
    readonly property bool verticalStack: root.config.desktopHorizontal === false
    readonly property int earbudCount: root.config.desktopShowCase === false || root.preset === "minimal" ? 2 : 3
    readonly property real desktopGap: root.config.desktopGap !== undefined ? Math.max(0, Number(root.config.desktopGap)) : 8
    readonly property var modeOptions: [
        { mode: "NOISE_REDUCTION", action: "on", label: "ANC", icon: "noise_control_on" },
        { mode: "AMBIENT_SOUND", action: "ambient", label: "AMBIENT", icon: "hearing" },
        { mode: "ADAPTIVE", action: "adaptive", label: "Adaptive", icon: "auto_mode" },
        { mode: "OFF", action: "off", label: "OFF", icon: "noise_control_off" }
    ].filter(item => Array.isArray(device.supported_noise_modes) && device.supported_noise_modes.indexOf(item.action) >= 0)

    function partAvailable(part) {
        return connected && (part === "case" || status["placement_" + part] !== "DISCONNECTED");
    }

    function battery(part) {
        var value = status[part];
        return partAvailable(part) && typeof value === "number" && value >= 0 ? value + "%" : "—";
    }

    function batteryColor(part) {
        var value = status[part];
        if (!partAvailable(part) || typeof value !== "number" || value < 0) return Theme.surfaceVariantText;
        if (value <= 10) return Theme.error;
        if (value <= 30) return Theme.warning;
        return Theme.primary;
    }

    function renderSource(side) {
        var code = root.device.model_code || "";
        var model = code === "SM-R630" ? "Buds3Pro" : code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (!model) return "";
        var colorName = (root.device.color || "").toLowerCase();
        var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
        return Qt.resolvedUrl("../assets/device/" + model + color + "-" + (side === "left" ? 0 : 1) + ".png");
    }

    function earbudItems() {
        var items = {
            left: { key: "left", label: "LEFT" },
            case: { key: "case", label: "CASE" },
            right: { key: "right", label: "RIGHT" }
        };
        var order = (root.config.desktopEarOrder || "left-case-right").split("-");
        return order.map(key => items[key]).filter(item => item &&
            (item.key !== "case" || (root.config.desktopShowCase !== false && root.preset !== "minimal")));
    }

    function requestMode(action) {
        if (!connected || busy) return;
        PluginService.setGlobalVar(pluginId, "commandRequest", {
            id: Date.now() + "-" + Math.random(),
            command: "anc",
            args: [action],
            label: "Noise mode " + action
        });
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusL
        color: root.config.desktopBackgroundMode === "transparent" ? "transparent" :
            Theme.withAlpha(root.config.desktopBackgroundMode === "custom" ? (root.config.desktopSurfaceColor || Theme.surfaceContainer) : Theme.surfaceContainer,
                (root.config.desktopBackgroundOpacity !== undefined ? Number(root.config.desktopBackgroundOpacity) : 94) / 100)
        border.color: root.config.desktopShowBorder === false ? "transparent" : Theme.withAlpha(Theme.outline, 0.2)
        border.width: root.config.desktopShowBorder === false ? 0 : 1
        visible: root.connected
    }

    ConnectOnly { anchors.fill: parent; pluginId: root.pluginId; visible: !root.connected && root.offlinePolicy === "connect" && !root.lockScreen }
    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadiusL
        visible: !root.connected && (root.offlinePolicy === "status" || root.lockScreen)
        color: Theme.withAlpha(Theme.surfaceContainer, 0.92)
        border.color: Theme.withAlpha(Theme.outline, 0.25)
        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingS
            NoiseModeIcon { mode: "OFF"; size: 22; color: Theme.surfaceVariantText; anchors.verticalCenter: parent.verticalCenter }
            StyledText { text: "Galaxy Buds desconectados"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; anchors.verticalCenter: parent.verticalCenter }
        }
    }

    Column {
        visible: root.connected
        anchors.fill: parent
        anchors.margins: root.config.desktopPadding !== undefined ? Number(root.config.desktopPadding) : Theme.spacingS
        spacing: Theme.spacingXS

        Row {
            width: parent.width
            height: root.config.desktopShowName === false || root.preset === "minimal" ? 0 : 20
            visible: root.config.desktopShowName !== false && root.preset !== "minimal"
            spacing: Theme.spacingXS
            DIcon {
                name: "bluetooth_connected"
                size: 16
                color: Theme.primary
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                width: parent.width - 22
                text: root.device.name || root.device.model || "Galaxy Buds"
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Grid {
            width: parent.width
            height: root.verticalStack ? root.earbudCount * (Number(root.config.desktopEarbudSize || 48) + 44) + (root.earbudCount - 1) * root.desktopGap : Math.max(76, Number(root.config.desktopEarbudSize || 48) + 48)
            columns: root.verticalStack ? 1 : root.earbudCount
            spacing: root.desktopGap
            flow: Grid.LeftToRight
            Repeater {
                model: root.earbudItems()
                delegate: Item {
                    required property var modelData
                    width: root.verticalStack ? parent.width : (parent.width - parent.spacing * (root.earbudCount - 1)) / root.earbudCount
                    height: root.verticalStack ? (parent.height - parent.spacing * (root.earbudCount - 1)) / root.earbudCount : parent.height
                    Column {
                        anchors.centerIn: parent
                        spacing: 1
                            transform: Translate { y: Number(root.config.desktopVerticalOffset || 0) }
                        Loader {
                            width: Number(root.config.desktopEarbudSize || 48); height: width
                            anchors.horizontalCenter: parent.horizontalCenter
                            sourceComponent: modelData.key === "case" ? caseGlyph : earbudButton
                            Component {
                                id: caseGlyph
                                Gbuds.EarbudGlyph {
                                    part: "case"
                                    available: root.connected
                                    tint: root.batteryColor("case")
                                }
                            }
                            Component {
                                id: earbudButton
                                EarbudButton {
                                    actions: actionController
                                    side: modelData.key
                                    modelCode: root.device.model_code || ""
                                    available: root.partAvailable(modelData.key)
                                    idle: root.config.warnOutOfEar !== false && root.status["placement_" + modelData.key] === "IDLE"
                                    tint: root.batteryColor(modelData.key)
                                    artwork: root.config.desktopArtwork || "svg"
                                    imageSource: root.renderSource(modelData.key)
                                    interactionAllowed: !root.lockScreen
                                }
                            }
                        }
                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.config.desktopShowBattery !== false
                            text: (actionController.ringing(modelData.key) ? "STOP" : modelData.label) + "  " + root.battery(modelData.key)
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.DemiBold
                        }
                        Item {
                            width: parent.width
                            height: root.config.desktopShowDisconnect !== false && !root.lockScreen ? 30 : 0
                            ActionButton {
                                objectName: "disconnectButton"
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.min(100, (root.width - 30) / 3)
                                height: 27
                                visible: modelData.key === "case" && root.config.desktopShowDisconnect !== false && !root.lockScreen
                                enabled: !root.busy
                                text: "Desconectar"
                                onClicked: actionController.send("disconnect", [], "Disconnect Galaxy Buds")
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: root.config.desktopShowNoise === false || root.preset === "minimal" ? 0 : Math.max(80, Number(root.config.desktopNoiseSize || 36) + 44)
            radius: Theme.cornerRadiusS
            visible: root.modeOptions.length > 0 && root.config.desktopShowNoise !== false && root.preset !== "minimal"
            color: Theme.surfaceContainerHigh
            border.color: Theme.withAlpha(Theme.outline, 0.35)
            border.width: 1
            Row {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3
                Repeater {
                    model: root.modeOptions
                    delegate: Rectangle {
                        id: modeButton
                        required property var modelData
                        readonly property bool selected: root.status.noise_control === modelData.mode
                        width: (parent.width - (root.modeOptions.length - 1) * 3) / root.modeOptions.length
                        height: parent.height
                        radius: Theme.cornerRadiusS
                        color: selected ? Theme.primaryContainer : "transparent"
                        enabled: root.connected && !root.busy && (!root.lockScreen || root.config.desktopLockControls === true)
                        activeFocusOnTab: enabled
                        Accessible.role: Accessible.Button
                        Accessible.name: modelData.label
                        Accessible.checked: selected
                        border.width: activeFocus ? 2 : 0
                        border.color: Theme.primary
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS
                            NoiseModeIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                mode: modelData.mode
                                size: Number(root.config.desktopNoiseSize || 36)
                                color: modeButton.selected ? Theme.primary : Theme.surfaceText
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                                color: modeButton.selected ? Theme.primary : Theme.surfaceText
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: root.requestMode(modelData.action) }
                        Keys.onReturnPressed: root.requestMode(modelData.action)
                        Keys.onSpacePressed: root.requestMode(modelData.action)
                    }
                }
            }
        }
        StyledText {
            width: parent.width
            height: visible ? implicitHeight : 0
            visible: !!actionController.error
            text: actionController.error
            color: Theme.error
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
        }
    }
}
