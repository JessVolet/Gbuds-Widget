import QtQuick
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

Item {
    id: root

    required property string pluginId
    property var pluginService: null
    property var config: ({})
    property bool desktopMode: false
    property bool terminalOpen: false
    property bool settingsOpen: false
    property bool devicesOpen: false
    property bool liveTestOpen: false
    property int requestId: 0
    property int dismissedEventId: 0

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandResult; varName: "commandResult"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({ busy: false, label: "" }) }
    PluginGlobalVar { id: selectedDevice; varName: "selectedDevice"; defaultValue: "" }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var latestEvent: snapshot.latestEvent || null
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property var command: commandResult.value || ({})
    readonly property var busyState: commandState.value || ({})
    readonly property string selectedMac: selectedDevice.value || config.targetMac || ""
    readonly property bool connected: snapshot.phase === "connected"
    readonly property var budsDevices: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))
    readonly property string installUrl: "https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md"
    readonly property int lowThreshold: Number(config.lowBatteryThreshold || 20)
    readonly property var modeOptions: [
        { mode: "NOISE_REDUCTION", action: "on", label: "ANC", icon: "noise_control_on" },
        { mode: "AMBIENT_SOUND", action: "ambient", label: "Ambient", icon: "hearing" },
        { mode: "ADAPTIVE", action: "adaptive", label: "Adaptive", icon: "auto_mode" },
        { mode: "OFF", action: "off", label: "Normal", icon: "noise_control_off" }
    ].filter(item => Array.isArray(device.supported_noise_modes) && device.supported_noise_modes.indexOf(item.action) >= 0)

    function render(side) {
        var code = device.model_code || "";
        var model = code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
        if (!model)
            return "";
        var colorName = (device.color || "").toLowerCase();
        var color = colorName.indexOf("white") >= 0 ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
        return Qt.resolvedUrl("assets/device/" + model + color + "-" + side + ".png");
    }

    function modeLabel(value) {
        if (value === "NOISE_REDUCTION") return "Noise cancellation";
        if (value === "AMBIENT_SOUND") return "Ambient sound";
        if (value === "ADAPTIVE") return "Adaptive sound";
        if (value === "OFF") return "Normal";
        return value ? value.replace(/_/g, " ") : "Not available";
    }

    function placementLabel(value) {
        if (value === "WEARING") return "Wearing";
        if (value === "IDLE") return "Out of ear";
        if (value === "IN_CASE") return "In case";
        if (value === "CLOSED_CASE") return "Case closed";
        if (value === "DISCONNECTED") return "Disconnected";
        return "Unknown";
    }

    function isModeSupported(mode) {
        return root.modeOptions.some(item => item.mode === mode);
    }

    function setMode(mode) {
        var option = root.modeOptions.find(item => item.mode === mode);
        var action = option ? option.action : "off";
        sendCommand("anc", [action], modeLabel(mode));
    }

    function sendCommand(commandName, args, label) {
        root.requestId++;
        root.pluginService.setGlobalVar(root.pluginId, "commandRequest", {
            id: Date.now() + root.requestId,
            command: commandName,
            args: args || [],
            label: label || commandName
        });
    }

    function selectDevice(address) {
        var requestedAddress = (address || "").toUpperCase();
        var target = root.budsDevices.find(device => (device.address || "").toUpperCase() === requestedAddress);
        if (target && !target.connected)
            target.connect();
        root.pluginService.setGlobalVar(root.pluginId, "deviceSelection", address);
        root.devicesOpen = false;
    }

    function saveSetting(key, value) {
        if (!root.pluginService)
            return;
        root.pluginService.savePluginData(root.pluginId, key, value);
        root.config = Object.assign({}, root.config, { [key]: value });
    }

    function batteryColor(value) {
        if (typeof value !== "number") return Theme.surfaceVariantText;
        if (value <= root.lowThreshold) return Theme.error;
        if (value <= 40) return Theme.tertiary;
        return Theme.primary;
    }

    function eventValue(change) {
        return change.label + "  " + change.from + "  →  " + change.to;
    }

    onLatestEventChanged: {
        if (root.latestEvent && root.latestEvent.id > root.dismissedEventId) {
            eventDismissTimer.restart();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        clip: true
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: Theme.spacingS

            Rectangle {
                width: parent.width
                height: root.desktopMode ? 150 : 176
                color: Theme.surface
                clip: true

                Rectangle {
                    width: parent.width * 1.25
                    height: parent.height * 1.25
                    x: -parent.width * 0.125
                    y: -parent.height * 0.48
                    radius: width / 2
                    color: root.connected ? Theme.withAlpha(Theme.primaryContainer, 0.55) : Theme.surfaceContainerHigh
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingXS

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS

                        Column {
                            width: parent.width - headerActions.width - Theme.spacingS
                            spacing: Theme.spacingXS
                            StyledText {
                                width: parent.width
                                text: root.device.name || root.device.model || "Galaxy Buds"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }
                            Row {
                                spacing: Theme.spacingXS
                                Rectangle {
                                    width: 8; height: 8; radius: 4
                                    color: root.connected ? Theme.primary : root.snapshot.phase === "missing-cli" ? Theme.error : Theme.tertiary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: root.connected ? "Connected · " + (root.device.model_code || "Live telemetry") :
                                          root.snapshot.phase === "missing-cli" ? "Gbuds CLI not found" :
                                          root.busyState.busy ? root.busyState.label + "…" : "Waiting for Galaxy Buds"
                                    color: root.connected ? Theme.primary : Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }

                        Row {
                            id: headerActions
                            spacing: Theme.spacingXS
                            DButton {
                                iconName: "devices"
                                text: ""
                                onClicked: root.devicesOpen = !root.devicesOpen
                                Accessible.name: "Choose Galaxy Buds device"
                            }
                            DButton {
                                iconName: "monitoring"
                                text: ""
                                onClicked: root.liveTestOpen = !root.liveTestOpen
                                Accessible.name: "Open live telemetry test panel"
                            }
                            DButton {
                                iconName: "terminal"
                                text: ""
                                onClicked: root.terminalOpen = !root.terminalOpen
                                Accessible.name: "Show or hide Gbuds CLI output"
                            }
                            DButton {
                                iconName: "settings"
                                text: ""
                                onClicked: root.settingsOpen = !root.settingsOpen
                                Accessible.name: "Open Gbuds Watch settings"
                            }
                        }
                    }

                    Item { width: 1; height: Theme.spacingXS }

                    Row {
                        width: parent.width
                        height: root.desktopMode ? 82 : 96
                        spacing: Theme.spacingS
                        Repeater {
                            model: [
                                { key: "left", label: "LEFT", side: 0, placement: root.status.placement_left, charging: root.status.left_charging },
                                { key: "case", label: "CASE", side: -1, placement: "Charging case", charging: root.status.case_charging },
                                { key: "right", label: "RIGHT", side: 1, placement: root.status.placement_right, charging: root.status.right_charging }
                            ]
                            delegate: Column {
                                required property var modelData
                                width: (parent.width - 2 * Theme.spacingS) / 3
                                height: parent.height
                                spacing: Theme.spacingXS

                                Item {
                                    width: parent.width
                                    height: root.desktopMode ? 48 : 60
                                    Image {
                                        anchors.centerIn: parent
                                        width: parent.width * 0.8
                                        height: parent.height
                                        source: modelData.side >= 0 ? root.render(modelData.side) : ""
                                        fillMode: Image.PreserveAspectFit
                                        visible: modelData.side >= 0 && source.toString() !== ""
                                        opacity: !root.connected ? 0.45 : modelData.side === 0 && root.status.placement_left === "DISCONNECTED" || modelData.side === 1 && root.status.placement_right === "DISCONNECTED" ? 0.55 : 1
                                    }
                                    DIcon {
                                        anchors.centerIn: parent
                                        name: modelData.side < 0 ? "inventory_2" : "headphones"
                                        size: root.desktopMode ? 32 : 38
                                        color: Theme.primary
                                        visible: modelData.side < 0 || !root.render(modelData.side)
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    radius: Theme.cornerRadius
                                    color: Theme.surfaceContainerHigh
                                    border.color: Theme.withAlpha(Theme.outline, 0.45)
                                    border.width: 1
                                    width: Math.min(parent.width, 82)
                                    height: 24
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 3
                                        DIcon {
                                            name: modelData.charging ? "bolt" : "battery_full"
                                            size: 14
                                            color: root.batteryColor(root.status[modelData.key])
                                        }
                                        StyledText {
                                            text: typeof root.status[modelData.key] === "number" ? root.status[modelData.key] + "%" : "N/A"
                                            color: root.batteryColor(root.status[modelData.key])
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                visible: root.latestEvent && root.latestEvent.id > root.dismissedEventId
                height: visible ? eventCard.implicitHeight + Theme.spacingM : 0
                radius: Theme.cornerRadius
                color: !root.latestEvent ? Theme.surfaceContainerHigh : root.latestEvent.severity === "warning" ? Theme.errorContainer : root.latestEvent.severity === "success" ? Theme.primaryContainer : Theme.surfaceContainerHigh
                Column {
                    id: eventCard
                    anchors.fill: parent
                    anchors.margins: Theme.spacingS
                    spacing: Theme.spacingXS
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        DIcon {
                            name: root.latestEvent && root.latestEvent.severity === "warning" ? "warning" : "notifications_active"
                            size: 19
                            color: root.latestEvent && root.latestEvent.severity === "warning" ? Theme.error : Theme.primary
                        }
                        StyledText {
                            width: parent.width - 56
                            text: root.latestEvent ? root.latestEvent.title : "Status changed"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        DButton {
                            iconName: "close"
                            text: ""
                            buttonHeight: 28
                            onClicked: {
                                root.dismissedEventId = root.latestEvent ? root.latestEvent.id : 0;
                                eventDismissTimer.stop();
                            }
                            Accessible.name: "Dismiss status change card"
                        }
                    }
                    Repeater {
                        model: root.latestEvent ? root.latestEvent.changes : []
                        delegate: StyledText {
                            required property var modelData
                            width: parent.width
                            text: root.eventValue(modelData)
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Timer {
                id: eventDismissTimer
                interval: Math.max(1500, Number(root.config.dismissTimeout || 6) * 1000)
                repeat: false
                onTriggered: if (root.latestEvent) root.dismissedEventId = root.latestEvent.id
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    StyledText {
                        width: parent.width * 0.58
                        text: "Noise control"
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    StyledText {
                        width: parent.width * 0.42
                        text: root.modeLabel(root.status.noise_control)
                        color: Theme.primary
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    width: parent.width
                    height: !root.connected ? errorContent.implicitHeight + Theme.spacingM : 0
                    visible: !root.connected
                    radius: Theme.cornerRadius
                    color: root.snapshot.phase === "missing-cli" ? Theme.errorContainer : Theme.surfaceContainerHigh
                    Column {
                        id: errorContent
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS
                        StyledText {
                            width: parent.width
                            text: root.snapshot.phase === "missing-cli" ? "Gbuds CLI is required" : root.snapshot.detail || "Waiting for a connected Galaxy Buds device."
                            color: root.snapshot.phase === "missing-cli" ? Theme.error : Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                        DButton {
                            visible: root.snapshot.phase === "missing-cli"
                            text: "Open installation guide"
                            iconName: "open_in_new"
                            onClicked: Qt.openUrlExternally(root.installUrl)
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingXS
                    Repeater {
                        model: root.modeOptions
                        delegate: DButton {
                            required property var modelData
                            width: (parent.width - (root.modeOptions.length - 1) * Theme.spacingXS) / root.modeOptions.length
                            text: modelData.label
                            iconName: modelData.icon
                            enabled: root.connected && !root.busyState.busy
                            checkable: true
                            checked: root.status.noise_control === modelData.mode
                            backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: checked ? Theme.primary : Theme.surfaceText
                            onClicked: root.setMode(modelData.mode)
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    DButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: root.status.touchpad_locked ? "Touch controls locked" : "Touch controls active"
                        iconName: root.status.touchpad_locked ? "lock" : "lock_open"
                        enabled: root.connected && root.status.touchpad_locked !== null && !root.busyState.busy
                        onClicked: root.sendCommand("touchpad", [root.status.touchpad_locked ? "unlock" : "lock"], root.status.touchpad_locked ? "Touch controls unlocked" : "Touch controls locked")
                    }
                    DButton {
                        width: (parent.width - Theme.spacingS) / 2
                        text: root.busyState.busy ? "Syncing…" : "Sync status"
                        iconName: "sync"
                        enabled: root.connected && !root.busyState.busy
                        onClicked: root.sendCommand("battery", [], "Battery status refreshed")
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    visible: root.connected
                    StyledText {
                        text: "Sound profile"
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                    }
                    Flow {
                        width: parent.width
                        spacing: Theme.spacingXS
                        Repeater {
                            model: [
                                { key: "normal", value: "OFF" }, { key: "bass", value: "BASS_BOOST" },
                                { key: "soft", value: "SOFT" }, { key: "dynamic", value: "DYNAMIC" },
                                { key: "clear", value: "CLEAR" }, { key: "treble", value: "TREBLE_BOOST" }
                            ]
                            delegate: DButton {
                                required property var modelData
                                width: 74
                                buttonHeight: 32
                                minimumWidth: 0
                                text: modelData.key.charAt(0).toUpperCase() + modelData.key.slice(1)
                                enabled: root.connected && !root.busyState.busy
                                checkable: true
                                checked: root.status.equalizer === modelData.value
                                backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                                textColor: checked ? Theme.primary : Theme.surfaceText
                                onClicked: root.sendCommand("eq", [modelData.key], modelData.key + " equalizer")
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.connected
                    height: visible ? activityList.implicitHeight + Theme.spacingM : 0
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    Column {
                        id: activityList
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS
                        Row {
                            width: parent.width
                            DIcon { name: "timeline"; size: 17; color: Theme.primary }
                            StyledText {
                                width: parent.width - 24
                                text: "Recent activity"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.DemiBold
                            }
                        }
                        Repeater {
                            model: (root.snapshot.history || []).slice(0, 3)
                            delegate: Row {
                                required property var modelData
                                width: parent.width
                                spacing: Theme.spacingXS
                                Rectangle {
                                    width: 6; height: 6; radius: 3
                                    color: modelData.severity === "warning" ? Theme.error : Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    width: parent.width - 12
                                    text: modelData.title + (modelData.changes && modelData.changes.length ? " · " + modelData.changes.map(change => change.to).join(", ") : "")
                                    color: Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        StyledText {
                            visible: (root.snapshot.history || []).length === 0
                            text: "Waiting for the first device update…"
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    visible: root.liveTestOpen
                    height: visible ? testInspector.implicitHeight + Theme.spacingM : 0
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    Column {
                        id: testInspector
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS
                        Row {
                            width: parent.width
                            Column {
                                width: parent.width - testClose.width - Theme.spacingS
                                StyledText { text: "Live test panel"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.Bold }
                                StyledText { text: "Real frames from gbuds watch --json"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                            }
                            DButton { id: testClose; iconName: "close"; text: ""; buttonHeight: 30; onClicked: root.liveTestOpen = false; Accessible.name: "Close live test panel" }
                        }
                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS
                            Repeater {
                                model: [
                                    { label: "STREAM", value: root.connected ? "LIVE" : "WAITING" },
                                    { label: "FRAMES", value: String(root.snapshot.frameCount || 0) },
                                    { label: "CHANGES", value: String(root.snapshot.changeCount || 0) }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - 2 * Theme.spacingXS) / 3
                                    height: 56
                                    radius: Theme.cornerRadius
                                    color: Theme.surface
                                    Column {
                                        anchors.centerIn: parent
                                        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall }
                                        StyledText { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.value; color: modelData.label === "STREAM" ? (root.connected ? Theme.primary : Theme.tertiary) : Theme.surfaceText; font.weight: Font.Bold; font.pixelSize: Theme.fontSizeMedium }
                                    }
                                }
                            }
                        }
                        StyledText { text: "Try a real change"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.DemiBold }
                        Flow {
                            width: parent.width
                            spacing: Theme.spacingXS
                            Repeater {
                                model: root.modeOptions
                                delegate: DButton {
                                    required property var modelData
                                    text: "Set " + modelData.label
                                    buttonHeight: 34
                                    enabled: root.connected && !root.busyState.busy
                                    onClicked: root.setMode(modelData.mode)
                                }
                            }
                            DButton {
                                text: root.status.touchpad_locked ? "Unlock touch" : "Lock touch"
                                buttonHeight: 34
                                enabled: root.connected && !root.busyState.busy
                                onClicked: root.sendCommand("touchpad", [root.status.touchpad_locked ? "unlock" : "lock"], "Touch controls")
                            }
                            DButton {
                                text: "Refresh battery"
                                buttonHeight: 34
                                enabled: root.connected && !root.busyState.busy
                                onClicked: root.sendCommand("battery", [], "Battery refresh")
                            }
                        }
                        StyledText { text: "Recent changes"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.DemiBold }
                        Repeater {
                            model: (root.snapshot.history || []).slice(0, 5)
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width
                                height: historyRow.implicitHeight + Theme.spacingS
                                radius: Theme.cornerRadius
                                color: Theme.surface
                                Column {
                                    id: historyRow
                                    anchors.fill: parent
                                    anchors.margins: Theme.spacingXS
                                    StyledText { width: parent.width; text: modelData.title; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall; font.weight: Font.DemiBold }
                                    Repeater {
                                        model: modelData.changes || []
                                        delegate: StyledText {
                                            required property var modelData
                                            width: parent.width
                                            text: root.eventValue(modelData)
                                            color: Theme.surfaceVariantText
                                            font.pixelSize: Theme.fontSizeSmall
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            width: parent.width
                            radius: Theme.cornerRadius
                            color: "#101820"
                            implicitHeight: rawJson.implicitHeight + Theme.spacingM
                            StyledText {
                                id: rawJson
                                anchors.fill: parent
                                anchors.margins: Theme.spacingS
                                text: JSON.stringify(root.status, null, 2)
                                color: "#d8e5df"
                                font.family: "monospace"
                                font.pixelSize: Theme.fontSizeSmall
                                wrapMode: Text.WrapAnywhere
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.devicesOpen ? deviceList.implicitHeight + Theme.spacingM : 0
                    visible: root.devicesOpen
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    clip: true
                    Column {
                        id: deviceList
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "Paired Galaxy Buds"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                        Repeater {
                            model: root.budsDevices
                            delegate: DButton {
                                required property var modelData
                                width: parent.width
                                text: (modelData.name || "Galaxy Buds") + (modelData.connected ? " · Connected" : "")
                                iconName: "headphones"
                                checkable: true
                                checked: (modelData.address || "").toUpperCase() === root.selectedMac.toUpperCase()
                                backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                                textColor: checked ? Theme.primary : Theme.surfaceText
                                onClicked: root.selectDevice(modelData.address)
                            }
                        }
                        StyledText {
                            visible: root.budsDevices.length === 0
                            text: "No paired Galaxy Buds were found by Dux Shell."
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: root.settingsOpen ? quickSettings.implicitHeight + Theme.spacingM : 0
                    visible: root.settingsOpen
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    clip: true
                    Column {
                        id: quickSettings
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS
                        StyledText {
                            text: "Quick settings"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.58
                                text: "Notify on state changes"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DButton {
                                text: root.config.notifyStateChanges === false ? "Off" : "On"
                                onClicked: root.saveSetting("notifyStateChanges", root.config.notifyStateChanges === false)
                            }
                        }
                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.58
                                text: "Low battery threshold"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DButton {
                                text: root.lowThreshold + "%"
                                onClicked: {
                                    var levels = [10, 15, 20, 25, 30, 40];
                                    var index = levels.indexOf(root.lowThreshold);
                                    root.saveSetting("lowBatteryThreshold", levels[(index + 1) % levels.length]);
                                }
                            }
                        }
                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.58
                                text: "Low battery alerts"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DButton {
                                text: root.config.notifyLowBattery === false ? "Off" : "On"
                                onClicked: root.saveSetting("notifyLowBattery", root.config.notifyLowBattery === false)
                            }
                        }
                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.58
                                text: "Status card duration"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DButton {
                                text: (root.config.dismissTimeout || 6) + " sec"
                                onClicked: {
                                    var values = [3, 6, 10];
                                    var index = values.indexOf(Number(root.config.dismissTimeout || 6));
                                    root.saveSetting("dismissTimeout", values[(index + 1) % values.length]);
                                }
                            }
                        }
                        Row {
                            width: parent.width
                            StyledText {
                                width: parent.width * 0.58
                                text: "Bar pill"
                                color: Theme.surfaceText
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DButton {
                                text: root.config.pillMode || "compact"
                                onClicked: {
                                    var modes = ["compact", "minimal", "detailed"];
                                    var index = modes.indexOf(root.config.pillMode || "compact");
                                    root.saveSetting("pillMode", modes[(index + 1) % modes.length]);
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    id: terminalDrawer
                    width: parent.width
                    height: root.terminalOpen ? terminalColumn.implicitHeight + Theme.spacingM : 0
                    visible: root.terminalOpen
                    radius: Theme.cornerRadius
                    color: "#101820"
                    clip: true
                    Column {
                        id: terminalColumn
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingXS
                        Row {
                            width: parent.width
                            DIcon { name: "terminal"; size: 16; color: Theme.primary }
                            StyledText {
                                width: parent.width - 20
                                text: root.command.command || "gbuds watch --json"
                                color: "#a9d6b7"
                                font.family: "monospace"
                                font.pixelSize: Theme.fontSizeSmall
                                elide: Text.ElideRight
                            }
                        }
                        StyledText {
                            width: parent.width
                            text: root.command.result ? JSON.stringify(root.command.result, null, 2) : root.connected ? JSON.stringify(root.status, null, 2) : root.snapshot.detail || "Waiting for gbuds watch --json…"
                            color: "#d8e5df"
                            font.family: "monospace"
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                Column {
                    width: parent.width
                    visible: root.snapshot.phase === "missing-cli"
                    spacing: Theme.spacingXS
                    StyledText { text: "Install the Gbuds CLI to use the live widget."; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeSmall }
                    DButton { text: "Open installation guide"; iconName: "open_in_new"; onClicked: Qt.openUrlExternally(root.installUrl) }
                }
            }
        }
    }
}
