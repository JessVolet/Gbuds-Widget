import QtQuick
import Quickshell
import qs.Services
import "Policy.js" as Policy
import "CommandRegistry.js" as Registry
import "../state"
import "../state/Telemetry.js" as Telemetry

Item {
    id: root
    property var config: ({})
    property var service
    property string pluginId: "gbudsWatch"
    property string target: ""
    property bool manualDisconnect: false
    property bool ready: false
    property var queue: []
    property string lastRequestId: ""
    property int retryMs: 500
    property alias state: store
    readonly property var paired: BluetoothService.pairedDevices.filter(d => /buds/i.test(d.name || ""))
    readonly property var connectedDevices: paired.filter(d => d.connected && d.address)
    readonly property bool targetConnected: connectedDevices.some(d => d.address.toUpperCase() === target)
    signal sample(var previous, var next, var device)
    signal disconnected(var previous, var device, bool voluntary)

    DeviceStore { id: store; service: root.service; pluginId: root.pluginId }
    function address(value) { return /^([0-9a-f]{2}:){5}[0-9a-f]{2}$/i.test(value || "") ? value.toUpperCase() : ""; }
    function selectTarget(value, persist) {
        const next = address(value);
        if (!next) return false;
        if (next === target) return true;
        if (store.findState.active || action.busy) { reject("device", "Finish the current action before changing devices."); return false; }
        target = next; queue = []; retry.stop(); watcher.stop(); metadata.stop(); store.reset(); store.connected = false;
        store.write("selectedDevice", next);
        if (persist && service) service.savePluginData(pluginId, "targetMac", next);
        manualDisconnect = false; retryMs = 500;
        refresh();
        return true;
    }
    function refresh() {
        if (!ready || !service) return;
        if (!target) {
            const next = address(config.targetMac) || (connectedDevices.length === 1 ? address(connectedDevices[0].address) : "");
            if (next) { selectTarget(next, false); return; }
        }
        const online = targetConnected && !manualDisconnect;
        if (store.connected && !online) {
            const previous = store.status, device = store.device;
            store.reset(); store.connected = false; store.phase = "disconnected";
            queue = queue.filter(r => r.command === "connect");
            retry.stop(); findDeadline.stop(); metadata.stop(); watcher.stop();
            disconnected(previous, device, manualDisconnect);
        }
        store.connected = online;
        if (!online) { store.phase = "disconnected"; store.publish(); return; }
        if (!Object.keys(store.device).length && !metadata.busy)
            metadata.start({epoch:store.epoch, argv:[config.gbudsCommand || "gbuds", "--mac", target, "capabilities", "--json"], timeoutMs:10000});
        if (queue.length || action.busy) { pump(); return; }
        if (!watcher.busy && !retry.running) {
            store.phase = store.status ? "connected" : "connecting";
            watcher.start({epoch:store.epoch, argv:[config.gbudsCommand || "gbuds", "--mac", target, "watch", "--json"], timeoutMs:0});
        }
        store.publish();
    }
    function accept(value) {
        let next;
        try { next = typeof value === "string" ? JSON.parse(value) : value; }
        catch (error) { return; }
        next=Telemetry.normalize(next);
        if (!next) return;
        const previous = store.status;
        store.status = Object.assign({}, next);
        store.phase = "connected"; store.error = ""; retryMs = 500;
        sample(previous, store.status, store.device);
        store.publish();
        if (store.findState.active && next["placement_" + store.findState.side] !== "IDLE") request("find", ["stop"]);
    }
    function reject(command, message) {
        store.error = message; store.result({command:command}, {error:message}, false); store.publish();
    }
    function request(command, args) {
        const error = Registry.validate(command, args, {connected:store.connected, device:store.device, status:store.status});
        const selected = address(Policy.targetAddress(target || config.targetMac, paired));
        if (error || !selected) { reject(command, error || "Select a paired Galaxy Buds device first."); return; }
        if (!target) selectTarget(selected, true);
        const stop = command === "find" && args[0] === "stop";
        if (!stop && queue.length >= 16) { reject(command, "Too many pending actions."); return; }
        if (stop && (queue.some(r => r.command === "find" && r.args[0] === "stop") ||
            (action.process && action.process.job.command === "find" && action.process.job.args[0] === "stop"))) return;
        if (stop || command === "disconnect") queue = queue.filter(r => r.command !== "find" || r.args[0] === "stop");
        const job = {command:command, args:args.slice(), epoch:store.epoch, target:target, timeoutMs:15000};
        if (command === "disconnect" && !queue.some(r => r.command === "find" && r.args[0] === "stop") &&
            !(action.process && action.process.job.command === "find" && action.process.job.args[0] === "stop") &&
            (store.findState.active || (action.process && action.process.job.command === "find")))
            queue = [{command:"find", args:["stop"], epoch:store.epoch, target:target, timeoutMs:15000}].concat(queue);
        if (command === "anc") queue = queue.filter(r => r.command !== "anc");
        queue = stop ? [job].concat(queue) : queue.concat([job]);
        store.error = ""; store.pending(job);
        if (command === "connect") manualDisconnect = false;
        if (watcher.busy) watcher.stop(); else pump();
    }
    function pump() {
        if (action.busy || watcher.busy) return;
        if (!queue.length) { store.pending(null); refresh(); return; }
        const job = queue[0]; queue = queue.slice(1);
        if (job.epoch !== store.epoch) { pump(); return; }
        const error = Registry.validate(job.command, job.args, {connected:store.connected, device:store.device, status:store.status});
        if (error) { reject(job.command, error); pump(); return; }
        job.argv = Registry.argv(config.gbudsCommand || "gbuds", job.target, job.command, job.args);
        store.pending(job);
        action.start(job);
    }
    function finish(job, value, success) {
        store.result(job, value, success);
        if (job.epoch !== store.epoch || job.target !== target) { pump(); return; }
        if (job.command === "find") {
            if (job.args[0] !== "stop") {
                store.findState = {active:true, side:job.args[0], uncertain:!success}; findDeadline.restart();
            } else if (success) { store.findState = {active:false, side:""}; findDeadline.stop(); }
            else queue = queue.filter(r => r.command !== "disconnect");
        }
        if (success && job.command === "disconnect") {
            const previous = store.status, device = store.device;
            manualDisconnect = true; store.reset(); store.connected = false; store.phase = "disconnected";
            retry.stop(); queue = queue.filter(r => r.command === "connect");
            disconnected(previous, device, true);
        } else if (success && job.command === "connect") {
            manualDisconnect = false; store.reset(); store.phase = "connecting";
        } else if (success && store.status) {
            const next = Object.assign({}, store.status);
            ["noise_control","equalizer","touchpad_locked","ambient_volume","voice_detect","blade_lights"].forEach(key => {
                if (value[key] !== undefined && value[key] !== null) next[key] = value[key];
            });
            accept(next);
        }
        if (!success) store.error = value.error || "The device could not complete this action.";
        store.publish(); pump();
    }
    ProcessTask {
        id: watcher
        stream: true
        onLine: (job, value) => { if (job.epoch === store.epoch && root.targetConnected && !root.manualDisconnect) root.accept(value); }
        onFinished: (job, result, success) => {
            if (root.queue.length) { root.pump(); return; }
            if (!root.targetConnected || root.manualDisconnect) return;
            store.phase = "waiting"; store.error = result.error || "Waiting for the device."; store.publish();
            retry.interval = root.retryMs; retry.restart(); root.retryMs = Math.min(root.retryMs * 2, 30000);
        }
    }
    ProcessTask { id: action; onFinished: (job, value, success) => root.finish(job, value, success) }
    ProcessTask {
        id: metadata
        onFinished: (job, value, success) => {
            if (success && job.epoch === store.epoch && root.targetConnected) {
                store.device = Policy.metadata(value); store.publish();
            }
        }
    }
    Timer { id: retry; onTriggered: root.refresh() }
    Timer { id: findDeadline; interval:30000; onTriggered: if (store.findState.active) root.request("find", ["stop"]) }
    Connections {
        target: root.service
        function onGlobalVarChanged(pid, key) {
            if (pid !== root.pluginId) return;
            const value = root.service.getGlobalVar(pid, key, null);
            if (key === "commandRequest" && value && value.id !== root.lastRequestId) {
                root.lastRequestId = value.id; root.request(value.command, value.args);
            }
            if (key === "deviceSelection" && root.selectTarget(value,true)) root.request("connect",[]);
        }
    }
    onTargetConnectedChanged: if (ready && targetConnected) { manualDisconnect = false; Qt.callLater(refresh); }
    onConnectedDevicesChanged: Qt.callLater(refresh)
    Component.onCompleted: { ready = true; refresh(); }
    Component.onDestruction: {
        ready = false; retry.stop(); findDeadline.stop();
        if (store.findState.active) {
            Quickshell.execDetached(Registry.argv(config.gbudsCommand || "gbuds", target, "find", ["stop"]));
        }
    }
}
