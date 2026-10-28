import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.Widgets
import qs.DCommon.Widgets
import qs.Modules.Plugins

Item {
    id: root
    clip: true
    implicitHeight: root.activePage !== "main" || controls.soundOpen ? 570 : 500

    required property string pluginId
    property var pluginService: null
    property var config: ({})
    property bool desktopMode: false
    property string activePage: "main"
    property int requestId: 0

    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({ phase: "checking-cli", detail: "", status: null, event: "" }) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandResult; varName: "commandResult"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({ busy: false, label: "" }) }
    PluginGlobalVar { id: selectedDevice; varName: "selectedDevice"; defaultValue: "" }

    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property var command: commandResult.value || ({})
    readonly property var busyState: commandState.value || ({})
    readonly property string selectedMac: selectedDevice.value || config.targetMac || ""
    readonly property bool connected: (snapshot.phase === "connected" || snapshot.phase === "controlling") && !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    readonly property var budsDevices: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))
    readonly property string installUrl: "https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md"
    readonly property int lowThreshold: 30

    readonly property color accentColor: {
        var mode = config.colorMode || "primary";
        if (mode === "primary") return Theme.primary;
        if (mode === "secondary") return Theme.secondary;
        if (mode === "tertiary") return Theme.tertiary;
        if (mode === "silver") return "#d2dce0";
        if (mode === "white") return "#f5f8fa";
        if (mode === "violet") return "#b388ff";
        if (mode === "mint") return "#80cbc4";
        if (mode === "custom") return config.customColor || Theme.primary;
        return Theme.primary;
    }

    readonly property color caseColor: {
        var mode = config.caseColorMode || "auto";
        if (mode === "auto") return Theme.primary;
        if (mode === "match") return root.accentColor;
        if (mode === "silver") return "#d2dce0";
        if (mode === "white") return "#f5f8fa";
        if (mode === "graphite") return "#50606b";
        if (mode === "custom") return config.customCaseColor || "#d2dce0";
        return Theme.primary;
    }
    readonly property var modeOptions: [
        { mode: "NOISE_REDUCTION", action: "on", label: "ANC", icon: "noise_control_on" },
        { mode: "AMBIENT_SOUND", action: "ambient", label: "Ambient", icon: "hearing" },
        { mode: "ADAPTIVE", action: "adaptive", label: "Adaptive", icon: "auto_mode" },
        { mode: "OFF", action: "off", label: "Normal", icon: "noise_control_off" }
    ].filter(item => Array.isArray(device.supported_noise_modes) && device.supported_noise_modes.indexOf(item.action) >= 0)

    function render(side) {
        var code = device.model_code || "";
        var model = code === "SM-R630" ? "Buds3Pro" : code === "SM-R530" ? "Buds3" : code === "SM-R420" ? "Buds3Fe" : code === "SM-R400N" ? "BudsFe" : "";
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

    function setMode(mode) {
        var option = root.modeOptions.find(item => item.mode === mode);
        if (option)
            sendCommand("anc", [option.action], modeLabel(mode));
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
        root.activePage = "main";
    }

    function saveSetting(key, value) {
        if (!root.pluginService)
            return;
        root.pluginService.savePluginData(root.pluginId, key, value);
        root.config = Object.assign({}, root.config, { [key]: value });
    }

    Rectangle {
        anchors.fill: parent
        radius: 24
        gradient: Gradient {
            GradientStop { position: 0; color: "#102a3d" }
            GradientStop { position: 0.55; color: "#1b4057" }
            GradientStop { position: 1; color: "#315b6b" }
        }
    }

    Column {
        id: layout
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        BudsHero {
            width: parent.width
            device: root.device
            status: root.status
            connected: root.connected
            busy: root.busyState.busy
            desktopMode: root.desktopMode
            lowThreshold: root.lowThreshold
            accentColor: root.accentColor
            caseColor: root.caseColor
            caseColorMode: root.config.caseColorMode || "silver"
            leftImageSource: root.render(0)
            rightImageSource: root.render(1)
            onDevicesClicked: root.activePage = root.activePage === "devices" ? "main" : "devices"
            onTerminalClicked: root.activePage = root.activePage === "terminal" ? "main" : "terminal"
            onSettingsClicked: {
                if (typeof PopoutService !== "undefined" && PopoutService.openSettingsWithTab) {
                    PopoutService.openSettingsWithTab("plugin_gbudsWatch");
                }
            }
        }

        BudsControls {
            id: controls
            width: parent.width
            visible: root.activePage === "main"
            device: root.device
            status: root.status
            modeOptions: root.modeOptions
            connected: root.connected
            busy: root.busyState.busy
            onModeRequested: mode => root.setMode(mode)
            onCommandRequested: (commandName, commandArgs, label) => root.sendCommand(commandName, commandArgs, label)
        }

        BudsOptions {
            width: parent.width
            height: root.height - 238
            visible: root.activePage !== "main"
            page: root.activePage
            config: root.config
            devices: root.budsDevices
            command: root.command
            status: root.status
            selectedMac: root.selectedMac
            detail: root.snapshot.detail || ""
            onCloseRequested: root.activePage = "main"
            onDeviceChosen: address => root.selectDevice(address)
        }
    }

}
