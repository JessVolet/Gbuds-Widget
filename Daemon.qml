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
    property int retryDelay: 1000
    property bool shuttingDown: false
    property bool actionInFlight: false
    property var actionProcess: null
    property var actionQueue: []
    property int lastRequestId: 0
    property int lastEventAt: 0
    property int lastLowBatteryAt: 0
    property string targetMac: ""
    readonly property var pairedBuds: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))

    function publish(phase, detail, status, eventText) {
        root.pluginService.setGlobalVar(root.pluginId, "telemetry", {
            phase: phase,
            detail: detail || "",
            status: status || null,
            event: eventText || "",
            updatedAt: Date.now()
        });
    }

    function publishCommand(command, result, success) {
        root.pluginService.setGlobalVar(root.pluginId, "commandResult", {
            command: command,
            result: result,
            success: success,
            completedAt: Date.now()
        });
    }

    function describeChange(previous, next) {
        if (!previous)
            return "Live telemetry received";
        if (previous.noise_control !== next.noise_control && next.noise_control)
            return "Noise control changed to " + next.noise_control.replace(/_/g, " ");
        if (previous.placement_left !== next.placement_left)
            return "Left earbud: " + (next.placement_left || "unknown").replace(/_/g, " ");
        if (previous.placement_right !== next.placement_right)
            return "Right earbud: " + (next.placement_right || "unknown").replace(/_/g, " ");
        if (previous.left !== next.left || previous.right !== next.right || previous.case !== next.case)
            return "Battery status updated";
        if (previous.equalizer !== next.equalizer && next.equalizer)
            return "Equalizer changed to " + next.equalizer.replace(/_/g, " ");
        if (previous.touchpad_locked !== next.touchpad_locked && next.touchpad_locked !== null)
            return "Touch controls " + (next.touchpad_locked ? "locked" : "unlocked");
        if (previous.is_coupled !== next.is_coupled)
            return "Earbud connection state changed";
        return "Buds status updated";
    }

    function acceptTelemetry(line) {
        var parsed;
        try {
            parsed = JSON.parse(line);
        } catch (error) {
            root.lastError = "Gbuds returned an invalid JSON status line.";
            console.warn("[gbudsWatch] " + root.lastError);
            return;
        }
        if (!parsed || typeof parsed.left !== "number" || typeof parsed.right !== "number") {
            root.lastError = parsed && parsed.error ? parsed.error : "Gbuds returned incomplete battery telemetry.";
            root.publish("waiting", root.lastError, root.lastStatus, "");
            return;
        }

        var previous = root.lastStatus;
        var currentSnapshot = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({ phase: "" }));
        var eventText = root.describeChange(previous, parsed);
        if (currentSnapshot.phase !== "connected" && previous !== null)
            eventText = "Connected to " + (root.device && (root.device.name || root.device.model) || "Galaxy Buds");
        var hasChange = root.lastStatus !== null && eventText !== "Buds status updated";
        root.lastStatus = parsed;
        root.lastError = "";
        root.retryDelay = 1000;
        root.publish("connected", "", parsed, eventText);
        if (hasChange && pluginData.notifyStateChanges !== false && Date.now() - root.lastEventAt > 1200) {
            root.lastEventAt = Date.now();
            ToastService.showInfo("Galaxy Buds updated", eventText);
        }
        var threshold = Number(pluginData.lowBatteryThreshold || 20);
        var crossedThreshold = previous && ((parsed.left <= threshold && previous.left > threshold) ||
                (parsed.right <= threshold && previous.right > threshold) ||
                (parsed.case !== null && parsed.case <= threshold && (previous.case === null || previous.case > threshold)));
        if (crossedThreshold && pluginData.notifyLowBattery !== false && Date.now() - root.lastLowBatteryAt > 60000) {
            root.lastLowBatteryAt = Date.now();
            ToastService.showWarning("Galaxy Buds battery low", "An earbud or case reached " + threshold + "%.");
        }
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
                var info = infoComponent.createObject(root, { targetAddress: root.targetMac });
                if (info)
                    info.running = true;
                else
                    root.startWatcher();
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
        if (persist)
            root.pluginService.savePluginData(root.pluginId, "targetMac", normalized);
        root.pluginService.setGlobalVar(root.pluginId, "selectedDevice", normalized);
        if (root.watchProcess)
            root.watchProcess.running = false;
        else if (!root.actionInFlight && restartIfIdle !== false)
            root.checkCli();
    }

    function acceptDeviceInfo(text) {
        try {
            var result = JSON.parse(text);
            if (result && result.success && result.device) {
                root.device = result.device;
                root.pluginService.setGlobalVar(root.pluginId, "device", result.device);
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
        if (root.actionInFlight) {
            root.runNextAction();
            return;
        }
        var detail = root.lastError || ("gbuds watch exited with code " + exitCode + ". Reconnecting…");
        root.publish("waiting", detail, root.lastStatus, "Connection interrupted");
        reconnectTimer.interval = root.retryDelay;
        reconnectTimer.start();
        root.retryDelay = Math.min(root.retryDelay * 2, 15000);
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
            root.pluginService.setGlobalVar(root.pluginId, "commandState", { busy: false, label: "" });
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
            ToastService.showInfo("Galaxy Buds", action.label + " applied");
        } else {
            root.lastError = result.error || "Gbuds command failed.";
            ToastService.showError("Galaxy Buds command failed", root.lastError);
        }
        if (root.actionQueue.length > 0)
            root.runNextAction();
        else {
            root.actionInFlight = false;
            root.pluginService.setGlobalVar(root.pluginId, "commandState", { busy: false, label: "" });
            root.checkCli();
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
            command: [root.cliCommand].concat(targetAddress ? ["--mac", targetAddress] : []).concat(["info", "--json"])
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
                root.startWatcher();
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
}
