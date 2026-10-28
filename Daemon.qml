import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string cliCommand: pluginData.gbudsCommand || "gbuds"
    property var watchProcess: null
    property var lastStatus: null
    property var device: null
    property string lastError: ""
    property string watchBuffer: ""
    property int retryDelay: 500
    property bool shuttingDown: false
    property bool actionInFlight: false
    property var actionProcess: null
    property var actionQueue: []
    property int lastRequestId: 0
    property int eventSequence: 0
    property bool disconnectedSinceLastStatus: false
    property bool targetSwitching: false
    property bool restartAfterTargetSwitch: false
    property string targetMac: ""
    readonly property var pairedBuds: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))

    function publish(phase, detail, status, eventText, latestEvent) {
        var old = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({}));
        root.pluginService.setGlobalVar(root.pluginId, "telemetry", {
            phase: phase,
            detail: detail || "",
            status: status || null,
            event: eventText || "",
            latestEvent: latestEvent || old.latestEvent || null,
            updatedAt: Date.now()
        });
        if (latestEvent)
            eventPopup.present(latestEvent, status || root.lastStatus, root.device);
    }

    function recordEvent(kind, title, detail, severity, icon) {
        root.eventSequence++;
        return { id: root.eventSequence, kind: kind, title: title, detail: detail || "", at: Date.now(), severity: severity || "normal", icon: icon || "headphones" };
    }

    function modeName(mode) {
        if (mode === "NOISE_REDUCTION") return "Noise cancellation";
        if (mode === "AMBIENT_SOUND") return "Ambient sound";
        if (mode === "ADAPTIVE") return "Adaptive sound";
        return "Normal mode";
    }

    function statusEvent(previous, next) {
        if (!previous || root.disconnectedSinceLastStatus)
            return root.recordEvent("connected", "Galaxy Buds connected", root.device && root.device.model || "Ready to listen", "success", "bluetooth_connected");

        var parts = [{ key: "left", label: "Left earbud" }, { key: "right", label: "Right earbud" }, { key: "case", label: "Case" }];
        for (var level of [10, 30]) {
            for (var part of parts) {
                var value = next[part.key];
                var oldValue = previous ? previous[part.key] : null;
                if (typeof value === "number" && value <= level && (!previous || typeof oldValue === "number" && oldValue > level))
                    return root.recordEvent(level === 10 ? "critical-battery" : "low-battery", level === 10 ? "Critical battery" : "Battery at 30%", part.label + " · " + value + "%", "warning", "battery_alert");
            }
        }

        if (previous.is_coupled === true && next.is_coupled === false)
            return root.recordEvent("disconnected", "Galaxy Buds disconnected", "Earbuds are no longer coupled", "warning", "bluetooth_disabled");
        if (previous.is_coupled === false && next.is_coupled === true)
            return root.recordEvent("connected", "Galaxy Buds connected", "Earbuds are coupled", "success", "bluetooth_connected");

        for (var side of [{ key: "placement_left", label: "Left earbud" }, { key: "placement_right", label: "Right earbud" }]) {
            if (previous[side.key] !== next[side.key]) {
                if (next[side.key] === "IN_CASE")
                    return root.recordEvent("stored", "Earbud stored", side.label + " is in the case", "normal", "inventory_2");
                if (next[side.key] === "IDLE")
                    return root.recordEvent("out-of-ear", "Earbud removed", side.label + " is out of ear", "normal", "earbuds");
                if (next[side.key] === "WEARING")
                    return root.recordEvent("in-ear", "Earbud in ear", side.label + " is ready", "success", "earbuds");
                if (next[side.key] === "DISCONNECTED")
                    return root.recordEvent("disconnected", "Earbud disconnected", side.label + " is unavailable", "warning", "bluetooth_disabled");
            }
        }

        if (previous.noise_control !== next.noise_control && next.noise_control)
            return root.recordEvent("noise-mode", root.modeName(next.noise_control), "Noise control changed", "normal", next.noise_control === "AMBIENT_SOUND" ? "hearing" : next.noise_control === "ADAPTIVE" ? "auto_mode" : next.noise_control === "OFF" ? "noise_control_off" : "noise_control_on");
        return null;
    }

    function publishCommand(command, result, success) {
        root.pluginService.setGlobalVar(root.pluginId, "commandResult", {
            command: command,
            result: result,
            success: success,
            completedAt: Date.now()
        });
    }

    function acceptTelemetry(line) {
        root.watchBuffer += line + "\n";
        if (root.watchBuffer.length > 65536) {
            root.watchBuffer = "";
            root.lastError = "Gbuds returned an oversized JSON response.";
            root.publish("waiting", root.lastError, root.lastStatus, "");
            return;
        }
        var parsed;
        try {
            parsed = JSON.parse(root.watchBuffer);
        } catch (error) {
            // watch emits one JSON object per line; CLI errors use indented JSON.
            return;
        }
        root.watchBuffer = "";
        if (!parsed || typeof parsed.left !== "number" || typeof parsed.right !== "number") {
            root.lastError = parsed && parsed.error ? parsed.error : "Gbuds returned incomplete battery telemetry.";
            root.publish("waiting", root.lastError, root.lastStatus, "");
            return;
        }

        var previous = root.lastStatus;
        var event = root.statusEvent(previous, parsed);
        root.disconnectedSinceLastStatus = false;
        root.lastStatus = parsed;
        root.lastError = "";
        root.retryDelay = 500;
        root.publish("connected", "", parsed, event ? event.title : "", event);
    }

    function recordError(line) {
        var message = line.trim();
        if (message) {
            root.lastError = message;
            console.warn("[gbudsWatch] " + message);
        }
    }

    function checkCli() {
        if (root.shuttingDown || root.actionInFlight)
            return;
        Proc.runCommand(null, ["/bin/sh", "-c", "command -v -- \"$1\" >/dev/null 2>&1", "gbuds-watch-check", root.cliCommand], (stdout, exitCode) => {
            if (root.shuttingDown)
                return;
            if (exitCode === 0) {
                root.refreshTargetFromBluetooth();
                root.startWatcher();
                if (!root.device) {
                    var info = infoComponent.createObject(root, { targetAddress: root.targetMac });
                    if (info)
                        info.running = true;
                }
            } else {
                root.publish("missing-cli", "Install Gbuds CLI to enable live telemetry.", null, "");
            }
        }, 0, 5000, root);
    }

    function refreshTargetFromBluetooth() {
        var connected = root.pairedBuds.filter(device => device.connected && device.address);
        if (connected.length === 1)
            root.setTarget(connected[0].address, false, false);
        else if (!root.targetMac && pluginData.targetMac)
            root.setTarget(pluginData.targetMac, false);
    }

    function setTarget(address, persist, restartIfIdle) {
        var normalized = (address || "").trim().toUpperCase();
        if (!normalized || normalized === root.targetMac)
            return;
        root.targetMac = normalized;
        // Do not compare one device's first frame against the previous device.
        root.lastStatus = null;
        root.disconnectedSinceLastStatus = false;
        root.device = null;
        root.pluginService.setGlobalVar(root.pluginId, "device", ({}));
        root.publish("connecting", "Reading the selected Galaxy Buds model.", null, "");
        if (persist)
            root.pluginService.savePluginData(root.pluginId, "targetMac", normalized);
        root.pluginService.setGlobalVar(root.pluginId, "selectedDevice", normalized);
        if (root.watchProcess) {
            root.targetSwitching = true;
            root.restartAfterTargetSwitch = restartIfIdle !== false;
            root.watchProcess.running = false;
        } else if (!root.actionInFlight && restartIfIdle !== false)
            root.checkCli();
    }

    function acceptDeviceInfo(text) {
        try {
            var result = JSON.parse(text);
            if (result && result.success && result.device) {
                var capabilities = result.capabilities || ({});
                var features = capabilities.features || ({});
                root.device = Object.assign({}, result.device, {
                    supported_noise_modes: capabilities.noise_control_modes || [],
                    has_ambient: features.ambient_sound && features.ambient_sound.device_support === "supported",
                    has_voice_detect: features.voice_detect && features.voice_detect.device_support === "supported",
                    has_blade_lights: features.blade_lights && features.blade_lights.device_support === "supported",
                    max_ambient_volume: features.ambient_volume && features.ambient_volume.max_level || 0
                });
                root.pluginService.setGlobalVar(root.pluginId, "device", root.device);
            } else if (result && result.error) {
                root.lastError = result.error;
            }
        } catch (error) {
            root.lastError = "Could not parse gbuds info metadata.";
            console.warn("[gbudsWatch] " + root.lastError);
        }
    }

    function startWatcher() {
        if (root.shuttingDown || root.watchProcess || root.actionInFlight)
            return;
        root.watchBuffer = "";
        if (!root.lastStatus || root.disconnectedSinceLastStatus)
            root.publish("connecting", root.lastError || "Looking for a connected Galaxy Buds device.", root.lastStatus, "");
        root.watchProcess = watcherComponent.createObject(root);
        if (root.watchProcess)
            root.watchProcess.running = true;
    }

    function handleWatcherExit(process, exitCode) {
        if (process !== root.watchProcess)
            return;
        root.watchProcess = null;
        process.destroy();
        if (root.shuttingDown)
            return;
        if (root.targetSwitching) {
            root.targetSwitching = false;
            if (root.restartAfterTargetSwitch) {
                reconnectTimer.interval = 250;
                reconnectTimer.start();
            }
            root.restartAfterTargetSwitch = false;
            return;
        }
        if (root.actionInFlight) {
            root.runNextAction();
            return;
        }
        var detail = root.lastError || ("gbuds watch exited with code " + exitCode + ". Reconnecting…");
        var oldSnapshot = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({}));
        var disconnectedEvent = oldSnapshot.phase === "connected" ? root.recordEvent("disconnected", "Galaxy Buds disconnected", "Connection lost", "warning", "bluetooth_disabled") : null;
        if (disconnectedEvent)
            root.disconnectedSinceLastStatus = true;
        root.publish("waiting", detail, root.lastStatus, disconnectedEvent ? disconnectedEvent.title : "", disconnectedEvent);
        reconnectTimer.interval = root.retryDelay;
        reconnectTimer.start();
        root.retryDelay = Math.min(root.retryDelay * 2, 3000);
    }

    function enqueueAction(command, args, label) {
        root.actionQueue = root.actionQueue.concat([{ command: command, args: args || [], label: label || command }]);
        root.pluginService.setGlobalVar(root.pluginId, "commandState", { busy: true, label: label || command });
        if (root.actionInFlight)
            return;
        root.actionInFlight = true;
        root.publish("controlling", "Applying " + (label || command) + "…", root.lastStatus, "");
        if (root.watchProcess)
            root.watchProcess.running = false;
        else
            root.runNextAction();
    }

    function runNextAction() {
        if (root.shuttingDown || root.actionQueue.length === 0) {
            root.actionInFlight = false;
            if (!root.shuttingDown)
                root.checkCli();
            return;
        }
        var action = root.actionQueue[0];
        root.actionQueue = root.actionQueue.slice(1);
        root.actionProcess = actionComponent.createObject(root, { actionData: action });
        if (root.actionProcess)
            root.actionProcess.running = true;
        else
            root.finishAction(action, { success: false, error: "Could not start Gbuds command." }, false);
    }

    function finishAction(action, result, succeeded) {
        root.publishCommand("gbuds --json " + action.command + " " + action.args.join(" "), result, succeeded);
        if (succeeded) {
            root.lastError = "";
            if (root.lastStatus) {
                var updated = Object.assign({}, root.lastStatus);
                var changed = false;
                for (var field of ["noise_control", "equalizer", "touchpad_locked", "ambient_volume", "voice_detect", "blade_lights"]) {
                    if (result[field] !== undefined && result[field] !== null) {
                        updated[field] = result[field];
                        changed = true;
                    }
                }
                if (changed)
                    root.acceptTelemetry(JSON.stringify(updated));
            }
            if (root.lastStatus)
                root.publish("connected", "", root.lastStatus, "");
        } else {
            root.lastError = result.error || "Gbuds command failed.";
        }
        if (root.actionQueue.length > 0)
            root.runNextAction();
        else {
            root.actionInFlight = false;
            root.pluginService.setGlobalVar(root.pluginId, "commandState", { busy: false, label: "" });
            root.startWatcher();
        }
    }

    Connections {
        target: root.pluginService
        function onGlobalVarChanged(pluginId, varName) {
            if (pluginId !== root.pluginId)
                return;
            if (varName === "commandRequest") {
                var request = root.pluginService.getGlobalVar(root.pluginId, "commandRequest", null);
                if (!request || request.id <= root.lastRequestId)
                    return;
                root.lastRequestId = request.id;
                root.enqueueAction(request.command, request.args, request.label);
            } else if (varName === "deviceSelection") {
                var address = root.pluginService.getGlobalVar(root.pluginId, "deviceSelection", "");
                root.setTarget(address, true);
            }
        }
    }

    Component {
        id: infoComponent
        Process {
            id: infoRunner
            property string targetAddress: ""
            command: [root.cliCommand].concat(targetAddress ? ["--mac", targetAddress] : []).concat(["capabilities", "--json"])
            running: false
            property string output: ""
            stdout: SplitParser {
                onRead: line => infoRunner.output += line + "\n"
            }
            onExited: (exitCode) => {
                if (exitCode === 0)
                    root.acceptDeviceInfo(infoRunner.output);
                infoRunner.output = "";
                infoRunner.destroy();
            }
        }
    }

    Component {
        id: watcherComponent
        Process {
            id: runner
            command: [root.cliCommand].concat(root.targetMac ? ["--mac", root.targetMac] : []).concat(["watch", "--json"])
            running: false
            stdout: SplitParser { onRead: line => root.acceptTelemetry(line) }
            stderr: SplitParser { onRead: line => root.recordError(line) }
            onExited: (exitCode) => root.handleWatcherExit(runner, exitCode)
        }
    }

    Component {
        id: actionComponent
        Process {
            id: actionRunner
            property var actionData: ({ command: "", args: [], label: "" })
            command: [root.cliCommand].concat(root.targetMac ? ["--mac", root.targetMac] : []).concat(["--json", actionData.command]).concat(actionData.args)
            running: false
            stdout: StdioCollector { id: actionOutput }
            stderr: StdioCollector { id: actionErrors }
            onExited: (exitCode) => {
                var result = null;
                try {
                    result = JSON.parse(actionOutput.text);
                } catch (error) {
                    result = { success: false, error: actionErrors.text.trim() || "Invalid response from Gbuds." };
                }
                var succeeded = exitCode === 0 && result && result.success !== false;
                var completedAction = actionRunner.actionData;
                root.actionProcess = null;
                actionRunner.destroy();
                root.finishAction(completedAction, result || { success: false, error: "Gbuds command failed." }, succeeded);
            }
        }
    }

    Timer {
        id: reconnectTimer
        repeat: false
        onTriggered: root.checkCli()
    }

    Component.onCompleted: {
        root.targetMac = pluginData.targetMac || "";
        root.publish("checking-cli", "Checking for the gbuds executable.", null, "");
        root.checkCli();
    }

    Component.onDestruction: {
        root.shuttingDown = true;
        reconnectTimer.stop();
        if (root.watchProcess) {
            var process = root.watchProcess;
            root.watchProcess = null;
            process.running = false;
            process.destroy();
        }
    }

    BudsEventPopup {
        id: eventPopup
        config: root.pluginData
    }
}
