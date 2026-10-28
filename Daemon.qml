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
    property int eventSequence: 0
    property int frameCount: 0
    property var eventHistory: []
    property int lastLowBatteryAt: 0
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
            history: root.eventHistory,
            frameCount: root.frameCount,
            changeCount: root.eventSequence,
            updatedAt: Date.now()
        });
    }

    function valueLabel(value) {
        if (value === null || value === undefined) return "Not available";
        if (typeof value === "boolean") return value ? "On" : "Off";
        if (typeof value === "string") return value.replace(/_/g, " ").toLowerCase().replace(/\b\w/g, letter => letter.toUpperCase());
        return String(value) + (typeof value === "number" && value <= 100 ? "%" : "");
    }

    function buildChanges(previous, next) {
        if (!previous) return [];
        var fields = [
            ["left", "Left battery"], ["right", "Right battery"], ["case", "Case battery"],
            ["left_charging", "Left charging"], ["right_charging", "Right charging"], ["case_charging", "Case charging"],
            ["is_coupled", "Earbuds connected"], ["placement_left", "Left placement"], ["placement_right", "Right placement"],
            ["noise_control", "Noise control"], ["equalizer", "Sound profile"], ["ambient_volume", "Ambient volume"],
            ["voice_detect", "Voice detect"], ["blade_lights", "Blade lights"], ["touchpad_locked", "Touch controls"]
        ];
        var changes = [];
        fields.forEach(field => {
            if (previous[field[0]] !== next[field[0]])
                changes.push({ key: field[0], label: field[1], from: root.valueLabel(previous[field[0]]), to: root.valueLabel(next[field[0]]) });
        });
        return changes;
    }

    function recordEvent(title, changes, severity) {
        root.eventSequence++;
        var event = { id: root.eventSequence, title: title, changes: changes || [], at: Date.now(), severity: severity || "normal" };
        root.eventHistory = [event].concat(root.eventHistory).slice(0, 12);
        return event;
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
        var changes = root.buildChanges(previous, parsed);
        var event = null;
        var eventText = "";
        if (!previous) {
            eventText = "Live telemetry received";
            event = root.recordEvent("Live telemetry connected", [], "success");
        } else if (currentSnapshot.phase !== "connected") {
            eventText = "Connected to " + (root.device && (root.device.name || root.device.model) || "Galaxy Buds");
            event = root.recordEvent(eventText, changes, "success");
        } else if (changes.length > 0) {
            eventText = changes.map(change => change.label + ": " + change.to).join(" · ");
            var thresholdForEvent = Number(pluginData.lowBatteryThreshold || 20);
            var lowBatteryChange = changes.some(change => ["left", "right", "case"].indexOf(change.key) >= 0 &&
                typeof parsed[change.key] === "number" && parsed[change.key] <= thresholdForEvent);
            event = root.recordEvent(changes.length === 1 ? changes[0].label + " changed" : changes.length + " status changes", changes,
                lowBatteryChange ? "warning" : "normal");
        }
        root.lastStatus = parsed;
        root.frameCount++;
        root.lastError = "";
        root.retryDelay = 1000;
        root.publish("connected", "", parsed, eventText, event);
        if (changes.length > 0 && pluginData.notifyStateChanges !== false && Date.now() - root.lastEventAt > 1200) {
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
        // Do not compare one device's first frame against the previous device.
        root.lastStatus = null;
        root.device = null;
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
        var disconnectedEvent = root.recordEvent("Live stream interrupted", [
            { key: "connection", label: "Connection", from: "Connected", to: "Reconnecting" }
        ], "warning");
        root.publish("waiting", detail, root.lastStatus, "Connection interrupted", disconnectedEvent);
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
