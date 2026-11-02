import QtQuick
import qs.Widgets
import "../device/Policy.js" as Policy

Item {
    id: root
    property string pluginId: "gbudsWatch"
    property var service
    PluginGlobalVar { id: telemetry; varName:"telemetry"; defaultValue:({}) }
    PluginGlobalVar { id: metadata; varName:"device"; defaultValue:({}) }
    PluginGlobalVar { id: actions; varName:"commandState"; defaultValue:({}) }
    PluginGlobalVar { id: find; varName:"findState"; defaultValue:({active:false}) }
    PluginGlobalVar { id:selected; varName:"selectedDevice"; defaultValue:"" }
    PluginGlobalVar { id:history; varName:"commandHistory"; defaultValue:[] }
    readonly property string selectedAddress:selected.value || ""
    readonly property var commandHistory:history.value || []
    PluginGlobalVar { id: failure; varName:"actionError"; defaultValue:"" }
    readonly property var snapshot: telemetry.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property var device: metadata.value || ({})
    readonly property bool connected: snapshot.connected === true
    readonly property bool busy: actions.value?.busy === true
    readonly property var findState: find.value || ({active:false})
    readonly property string error: failure.value || snapshot.detail || ""
    readonly property var pending: actions.value?.request || null
    readonly property string mode: pending?.command === "anc" ? ({off:"OFF", on:"NOISE_REDUCTION", ambient:"AMBIENT_SOUND", adaptive:"ADAPTIVE"})[pending.args[0]] : status.noise_control || "OFF"
    function battery(part) { return typeof status[part] === "number" && status[part] >= 0 ? status[part] + "%" : "—"; }
    function canFind(side) { return connected && !busy && !Policy.findError(device,status,side); }
    function request(command, args) {
        if (service) service.setGlobalVar(pluginId,"commandRequest",{id:Date.now()+":"+Math.random(), command:command, args:args});
    }
    function findEar(side) { request("find", [findState.active ? "stop" : side]); }
}
