import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins
import qs.Widgets
import "."
import "./interface-v060" as Gbuds
import "./interface-v060/ControlPolicy.js" as Policy
import "./core-v060/NotificationPolicy.js" as NotificationPolicy

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
    property bool checkingCli: false
    property var actionProcess: null
    property var actionQueue: []
    readonly property int actionTimeoutMs: 15000
    property var infoProcess: null
    property string lastRequestId: ""
    property int eventSequence: 0
    property var reminderSide: ({ left: false, right: false })
    property var batteryThresholdState: ({})
    property string lastNotificationTestId: ""
    property bool disconnectedSinceLastStatus: false
    property bool targetSwitching: false
    property bool restartAfterTargetSwitch: false
    property string targetMac: ""
    property bool disconnectedByUser: false
    property var findState: ({ active: false, side: "", targetAddress: "" })
    readonly property var pairedBuds: BluetoothService.pairedDevices.filter(device => /buds/i.test(device.name || ""))
    readonly property var connectedBuds: pairedBuds.filter(device => device.connected && device.address)
    readonly property bool targetConnected: connectedBuds.some(device => !root.targetMac || device.address.toUpperCase() === root.targetMac.toUpperCase())

    onConnectedBudsChanged: {
        if (root.shuttingDown || root.actionInFlight)
            return;
        if (connectedBuds.length > 0) {
            root.disconnectedByUser = false;
            if (root.watchProcess)
                root.refreshTargetFromBluetooth();
            else if (!reconnectTimer.running)
                root.checkCli();
        } else {
            var previousTelemetry = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({}));
            var previousStatus = previousTelemetry.status || root.lastStatus;
            var previousDevice = root.device;
            var wasConnected = previousTelemetry.connected === true;
            var voluntary = root.disconnectedByUser;
            reconnectTimer.stop();
            root.resetConnection();
            root.publish("disconnected", "", null, "");
            if (wasConnected)
                root.routeEvent({ kind: "disconnected", subject: "pair", title: "Galaxy Buds disconnected", detail: voluntary ? "Disconnected from this widget" : "Bluetooth connection ended", severity: voluntary ? "normal" : "warning", waves: 2, snapshot: previousStatus }, previousStatus, previousDevice);
            if (root.watchProcess)
                root.watchProcess.running = false;
        }
    }

    function publish(phase, detail, status, eventText, latestEvent) {
        var old = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({}));
        root.pluginService.setGlobalVar(root.pluginId, "telemetry", {
            phase: phase,
            connected: root.targetConnected && !root.disconnectedByUser,
            detail: detail || "",
            status: status || null,
            event: eventText || "",
            latestEvent: latestEvent || old.latestEvent || null,
            updatedAt: Date.now()
        });
    }

    function routeEvent(value, status, snapshotDevice) {
        var legacyNotificationsDisabled = root.pluginData.notificationsEnabled === undefined &&
            (root.pluginData.showStatusCards === false ||
             ((value && String(value.kind).indexOf("battery-") === 0) && root.pluginData.showBatteryCards === false));
        if (!value || SessionService.locked || root.pluginData.notificationsEnabled === false || legacyNotificationsDisabled) return;
        root.eventSequence++;
        value.id = root.eventSequence;
        value.at = Date.now();
        if (!value.waves) value.waves = NotificationPolicy.waveCount(value);
        var channel = NotificationPolicy.channelsFor(value, root.pluginData);
        if (channel === "off") return;
        if (channel === "popup" || channel === "both")
            eventPopup.present(value, status, snapshotDevice);
        if (channel === "waveup" || channel === "both")
            waveup.present(value);
    }

    function statusEvents(previous, next) {
        return NotificationPolicy.detect(previous, next, root.device, root.disconnectedSinceLastStatus, root.batteryThresholdState);
    }

    function updateIdleReminder(side, placement) {
        var timer = side === "left" ? leftReminderTimer : rightReminderTimer;
        var isIdle = placement === "IDLE" && root.pluginData.notifyIdleReminder === true;
        if (!isIdle) {
            timer.stop();
            root.reminderSide[side] = false;
            return;
        }
        if (!root.reminderSide[side]) {
            root.reminderSide[side] = true;
            timer.interval = Math.max(15000, Math.min(3600000, Number(root.pluginData.notifyIdleInterval || 60) * 1000));
            timer.restart();
        }
    }

    function sendIdleReminder(side) {
        if (SessionService.locked || !root.lastStatus || root.lastStatus["placement_" + side] !== "IDLE" || root.lastStatus.is_coupled === false) return;
        var other = side === "left" ? "right" : "left";
        var bothIdle = root.lastStatus.placement_left === "IDLE" && root.lastStatus.placement_right === "IDLE";
        var reminder = { kind: "out-of-ear-reminder", subject: bothIdle ? "pair" : side, title: bothIdle ? "Both earbuds are out" : "Still out of ear", detail: bothIdle ? "Both earbuds are still out of ear" : (side === "left" ? "Left" : "Right") + " earbud is still out", severity: "normal", waves: 1, snapshot: root.lastStatus };
        root.routeEvent(reminder, root.lastStatus, root.device);
        if (root.pluginData.notifyIdleReminder === true) {
            var timer = side === "left" ? leftReminderTimer : rightReminderTimer;
            timer.interval = Math.max(15000, Math.min(3600000, Number(root.pluginData.notifyIdleInterval || 60) * 1000));
            timer.restart();
            if (bothIdle) {
                var otherTimer = other === "left" ? leftReminderTimer : rightReminderTimer;
                otherTimer.interval = timer.interval;
                otherTimer.restart();
            }
        }
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
        var events = root.statusEvents(previous, parsed);
        root.disconnectedSinceLastStatus = false;
        root.lastStatus = parsed;
        if (root.findState.active && parsed["placement_" + root.findState.side] !== "IDLE")
            root.enqueueAction("find", ["stop"], "Stop finding");
        root.lastError = "";
        root.retryDelay = 500;
        root.updateIdleReminder("left", parsed.placement_left);
        root.updateIdleReminder("right", parsed.placement_right);
        root.publish("connected", "", parsed, events.length ? events[0].title : "", events.length ? events[0] : null);
        for (var eventIndex = 0; eventIndex < events.length; eventIndex++)
            root.routeEvent(events[eventIndex], parsed, root.device);
    }

    function recordError(line) {
        var message = line.trim();
        if (message) {
            root.lastError = message;
            console.warn("[gbudsWatch] " + message);
        }
    }

    function checkCli() {
        if (root.shuttingDown || root.actionInFlight || root.checkingCli || root.watchProcess)
            return;
        if (root.disconnectedByUser || root.connectedBuds.length === 0) {
            root.publish("disconnected", "", null, "");
            return;
        }
        root.checkingCli = true;
        Proc.runCommand(null, ["/bin/sh", "-c", "command -v -- \"$1\" >/dev/null 2>&1", "gbuds-watch-check", root.cliCommand], (stdout, exitCode) => {
            root.checkingCli = false;
            if (root.shuttingDown || root.disconnectedByUser || root.connectedBuds.length === 0 || root.actionInFlight)
                return;
            if (exitCode === 0) {
                root.refreshTargetFromBluetooth();
                root.startWatcher();
                if (!root.device && !root.infoProcess) {
                    root.infoProcess = infoComponent.createObject(root, { targetAddress: root.targetMac });
                    if (root.infoProcess)
                        root.infoProcess.running = true;
                }
            } else {
                root.publish("missing-cli", "Install Gbuds CLI to enable live telemetry.", null, "");
            }
        }, 0, 5000, root);
    }

    function refreshTargetFromBluetooth() {
        var connected = root.connectedBuds;
        if (connected.length === 1)
            root.setTarget(connected[0].address, true, true);
        else if (!root.targetMac && pluginData.targetMac)
            root.setTarget(pluginData.targetMac, false);
    }

    function setTarget(address, persist, restartIfIdle) {
        var normalized = (address || "").trim().toUpperCase();
        if (!normalized || normalized === root.targetMac)
            return;
        if (root.findState.active || root.actionQueue.some(item => item.command === "find" && item.args[0] !== "stop") ||
            (root.actionProcess && root.actionProcess.actionData.command === "find" && root.actionProcess.actionData.args[0] !== "stop")) {
            root.rejectAction("device", "Stop finding before switching devices.");
            return;
        }
        root.targetMac = normalized;
        // Discard metadata for the previous target, including an in-flight read.
        if (root.infoProcess) {
            root.infoProcess.running = false;
            root.infoProcess.destroy();
            root.infoProcess = null;
        }
        // Do not compare one device's first frame against the previous device.
        root.lastStatus = null;
        root.batteryThresholdState = {};
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
                    features: features,
                    supported_noise_modes: Policy.noiseModes(capabilities),
                    has_ambient: Policy.supported(features, "ambient_sound"),
                    has_voice_detect: Policy.supported(features, "voice_detect"),
                    has_blade_lights: Policy.supported(features, "blade_lights"),
                    max_ambient_volume: Policy.supported(features, "ambient_volume") ? features.ambient_volume.max_level || 0 : 0
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
        if (root.shuttingDown || root.disconnectedByUser || root.watchProcess || root.actionInFlight)
            return;
        if (root.connectedBuds.length === 0) {
            root.publish("waiting", "Connect Galaxy Buds to start monitoring.", root.lastStatus, "");
            return;
        }
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
        if (root.actionInFlight) {
            root.targetSwitching = false;
            root.restartAfterTargetSwitch = false;
            root.runNextAction();
            return;
        }
        if (root.targetSwitching) {
            root.targetSwitching = false;
            if (root.restartAfterTargetSwitch) {
                reconnectTimer.interval = 250;
                reconnectTimer.start();
            }
            root.restartAfterTargetSwitch = false;
            return;
        }
        var detail = root.lastError || ("gbuds watch exited with code " + exitCode + ". Reconnecting…");
        var oldSnapshot = root.pluginService.getGlobalVar(root.pluginId, "telemetry", ({}));
        if (oldSnapshot.phase === "connected")
            root.disconnectedSinceLastStatus = true;
        root.publish("waiting", detail, root.lastStatus, "");
        if (!root.disconnectedByUser && root.connectedBuds.length > 0) {
            reconnectTimer.interval = root.retryDelay;
            reconnectTimer.start();
            root.retryDelay = Math.min(root.retryDelay * 2, 30000);
        }
    }

    function resolveTarget() {
        return Policy.targetAddress(root.targetMac || root.pluginData.targetMac || "", root.pairedBuds);
    }

    function publishFind(state) {
        root.findState = state;
        root.pluginService.setGlobalVar(root.pluginId, "findState", state);
    }

    function resetConnection() {
        if (root.infoProcess) {
            root.infoProcess.running = false;
            root.infoProcess.destroy();
            root.infoProcess = null;
        }
        root.lastStatus = null;
        root.device = null;
        root.disconnectedSinceLastStatus = true;
        root.pluginService.setGlobalVar(root.pluginId, "device", ({}));
        findTimer.stop();
        leftReminderTimer.stop();
        rightReminderTimer.stop();
        root.reminderSide = { left: false, right: false };
        root.publishFind({ active: false, side: "", targetAddress: "" });
    }

    function rejectAction(command, error) {
        root.publishCommand(command, { success: false, error: error }, false);
        root.pluginService.setGlobalVar(root.pluginId, "actionError", error);
    }

    function validateAction(command, args) {
        if (command === "connect" || command === "disconnect")
            return args.length ? "This command takes no arguments." : "";
        if (command === "find")
            return args.length !== 1 ? "Choose one earbud." : Policy.findError(root.device, root.lastStatus, args[0]);
        if (!root.targetConnected || root.disconnectedByUser)
            return "Connect Galaxy Buds first.";
        if (command === "anc" && (!root.device || root.device.supported_noise_modes.indexOf(args[0]) < 0))
            return "This noise mode is not available for this model.";
        var feature = {eq:"equalizer", touchpad:"touchpad", "ambient-volume":"ambient_volume", "voice-detect":"voice_detect", lights:"blade_lights"}[command];
        if (feature && !Policy.available((root.device || {}).features, feature))
            return "This control is not available for this model.";
        return "";
    }

    function enqueueAction(command, args, label) {
        var allowed = ["battery", "anc", "touchpad", "eq", "ambient-volume", "voice-detect", "lights", "connect", "disconnect", "find"];
        var stopping = command === "find" && Array.isArray(args) && args.length === 1 && args[0] === "stop";
        if (allowed.indexOf(command) < 0 || !Array.isArray(args) || args.some(arg => typeof arg !== "string") || (!stopping && root.actionQueue.length >= 16))
            return;
        var error = root.validateAction(command, args);
        var address = root.resolveTarget();
        if (error || !address) {
            root.rejectAction(command, error || "Select a paired Galaxy Buds device in the popout first.");
            return;
        }
        if (!root.targetMac) root.setTarget(address, true, false);
        if (command === "connect") root.disconnectedByUser = false;
        root.pluginService.setGlobalVar(root.pluginId, "actionError", "");
        var action = { command: command, args: args, label: label || command, targetAddress: address };
        if (stopping && root.actionQueue.some(item => item.command === "find" && item.args[0] === "stop")) return;
        if (stopping || command === "disconnect")
            root.actionQueue = root.actionQueue.filter(item => item.command !== "find" || item.args[0] === "stop");
        if (command === "disconnect" && (root.findState.active || (root.actionProcess && root.actionProcess.actionData.command === "find" && root.actionProcess.actionData.args[0] !== "stop"))) {
            root.actionQueue = root.actionQueue.concat([{command:"find", args:["stop"], label:"Stop finding", targetAddress:address}]);
        }
        root.actionQueue = stopping ? [action].concat(root.actionQueue) : root.actionQueue.concat([action]);
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
            root.pluginService.setGlobalVar(root.pluginId, "commandState", {busy:false, label:""});
            if (!root.shuttingDown)
                root.checkCli();
            return;
        }
        var action = root.actionQueue[0];
        root.actionQueue = root.actionQueue.slice(1);
        if (action.command === "find" && action.args[0] !== "stop") {
            var error = Policy.findError(root.device, root.lastStatus, action.args[0]);
            if (error) {
                root.rejectAction(action.command, error);
                root.runNextAction();
                return;
            }
        }
        root.actionProcess = actionComponent.createObject(root, { actionData: action });
        if (root.actionProcess) {
            root.actionProcess.running = true;
            root.actionProcess.watchdog.restart();
        } else
            root.finishAction(action, { success: false, error: "Could not start Gbuds command." }, false);
    }

    function finishAction(action, result, succeeded) {
        if (root.shuttingDown)
            return;
        root.publishCommand("gbuds --json " + action.command + " " + action.args.join(" "), result, succeeded);
        if (action.targetAddress === root.targetMac && action.command === "find") {
            // A timed-out start may have reached the Buds; keep Stop available.
            if (action.args[0] !== "stop") {
                root.publishFind({active:true, side:action.args[0], targetAddress:action.targetAddress});
                findTimer.restart();
            } else if (succeeded) {
                findTimer.stop();
                root.publishFind({active:false, side:"", targetAddress:""});
            } else {
                root.actionQueue = root.actionQueue.filter(item => item.command !== "disconnect");
            }
        }
        if (action.targetAddress === root.targetMac && succeeded) {
            root.lastError = "";
            if (action.command === "disconnect") {
                var disconnectedStatus = root.lastStatus;
                var disconnectedDevice = root.device;
                root.disconnectedByUser = true;
                root.actionQueue = root.actionQueue.filter(item => item.command === "connect");
                reconnectTimer.stop();
                root.resetConnection();
                root.publish("disconnected", "", null, "");
                root.routeEvent({ kind: "disconnected", subject: "pair", title: "Galaxy Buds disconnected", detail: "Disconnected from this widget", severity: "normal", waves: 2, snapshot: disconnectedStatus }, disconnectedStatus, disconnectedDevice);
            } else if (action.command === "connect") {
                root.disconnectedByUser = false;
                root.resetConnection();
                root.publish("connecting", "Reading device capabilities…", null, "");
            }
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
        } else if (action.targetAddress === root.targetMac) {
            root.lastError = result.error || "Gbuds command failed.";
            root.pluginService.setGlobalVar(root.pluginId, "actionError", root.lastError);
            root.publish("waiting", root.lastError, root.lastStatus, "");
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
                if (!request || !request.id || request.id === root.lastRequestId)
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
            property Timer timeout: Timer {
                interval: 10000
                running: infoRunner.running
                onTriggered: infoRunner.signal(9)
            }
            command: [root.cliCommand].concat(targetAddress ? ["--mac", targetAddress] : []).concat(["capabilities", "--json"])
            running: false
            property string output: ""
            stdout: SplitParser {
                onRead: line => infoRunner.output += line + "\n"
            }
            onExited: (exitCode) => {
                if (exitCode === 0 && root.targetConnected && !root.disconnectedByUser && infoRunner.targetAddress === root.targetMac)
                    root.acceptDeviceInfo(infoRunner.output);
                if (root.infoProcess === infoRunner)
                    root.infoProcess = null;
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
            property bool timedOut: false
            property bool completed: false
            function complete(exitCode) {
                if (completed) return;
                completed = true;
                watchdog.stop();
                var result;
                try { result = JSON.parse(actionOutput.text); }
                catch (error) { result = { success: false, error: actionErrors.text.trim() || "Invalid response from Gbuds." }; }
                if (timedOut)
                    result = { success: false, error: "Gbuds command timed out after 15 seconds." };
                var succeeded = !timedOut && exitCode === 0 && result && result.success !== false;
                root.actionProcess = null;
                root.finishAction(actionData, result || { success: false, error: "Gbuds command failed." }, succeeded);
                destroy();
            }
            property Timer watchdog: Timer {
                interval: root.actionTimeoutMs
                onTriggered: {
                    actionRunner.timedOut = true;
                    if (actionRunner.running)
                        actionRunner.signal(9);
                    else
                        actionRunner.complete(124);
                }
            }
            command: [root.cliCommand].concat(actionData.targetAddress ? ["--mac", actionData.targetAddress] : []).concat(["--json", actionData.command]).concat(actionData.args)
            running: false
            stdout: StdioCollector { id: actionOutput }
            stderr: StdioCollector { id: actionErrors }
            onExited: exitCode => Qt.callLater(() => actionRunner.complete(exitCode))
        }
    }

    Timer {
        id: findTimer
        interval: 30000
        onTriggered: if (root.findState.active) root.enqueueAction("find", ["stop"], "Stop finding");
    }

    Timer { id: leftReminderTimer; repeat: false; onTriggered: root.sendIdleReminder("left") }
    Timer { id: rightReminderTimer; repeat: false; onTriggered: root.sendIdleReminder("right") }
    Connections {
        target: SessionService
        function onLockedChanged() {
            if (SessionService.locked) {
                leftReminderTimer.stop();
                rightReminderTimer.stop();
                root.reminderSide = { left: false, right: false };
            } else if (root.lastStatus) {
                root.updateIdleReminder("left", root.lastStatus.placement_left);
                root.updateIdleReminder("right", root.lastStatus.placement_right);
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
        root.pluginService.setGlobalVar(root.pluginId, "device", ({}));
        root.pluginService.setGlobalVar(root.pluginId, "selectedDevice", root.targetMac);
        root.pluginService.setGlobalVar(root.pluginId, "commandState", {busy:false, label:""});
        root.pluginService.setGlobalVar(root.pluginId, "actionError", "");
        root.publishFind({active:false, side:"", targetAddress:""});
        root.publish("checking-cli", "Checking for the gbuds executable.", null, "");
        root.checkCli();
    }

    Component.onDestruction: {
        root.shuttingDown = true;
        reconnectTimer.stop();
        if (root.actionProcess) {
            root.actionProcess.signal(9);
            root.actionProcess.destroy();
            root.actionProcess = null;
        }
        if (root.infoProcess) {
            root.infoProcess.running = false;
            root.infoProcess.destroy();
            root.infoProcess = null;
        }
        if (root.watchProcess) {
            var process = root.watchProcess;
            root.watchProcess = null;
            process.running = false;
            process.destroy();
        }
        if (root.findState.active)
            Quickshell.execDetached([root.cliCommand, "--mac", root.findState.targetAddress, "--json", "find", "stop"]);
    }

    Gbuds.BudsEventPopup {
        id: eventPopup
        objectName: "gbudsEventPopup"
        config: root.pluginData
    }

    Gbuds.GbudsWaveup { id: waveup; objectName: "gbudsWaveup"; config: root.pluginData }
    property var popupPresenter: eventPopup
    property var waveupPresenter: waveup

    PluginGlobalVar {
        id: notificationTest
        varName: "notificationTest"
        defaultValue: ({})
        Component.onCompleted: root.lastNotificationTestId = String(value.id || "")
    }
    Connections {
        target: notificationTest
        function onValueChanged() {
            var value = notificationTest.value || ({});
            var id = String(value.id || "");
            if (!id || id === root.lastNotificationTestId) return;
            root.lastNotificationTestId = id;
            root.routeEvent(value, value.snapshot || root.lastStatus || ({ left: 0, right: 0, case: 0 }), root.device);
        }
    }
}
