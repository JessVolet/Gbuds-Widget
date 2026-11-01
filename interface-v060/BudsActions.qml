import QtQuick
import qs.Services
import qs.Widgets
import "ControlPolicy.js" as Policy

Item {
    id: root
    required property string pluginId
    PluginGlobalVar { id: telemetry; varName: "telemetry"; defaultValue: ({}) }
    PluginGlobalVar { id: deviceInfo; varName: "device"; defaultValue: ({}) }
    PluginGlobalVar { id: commandState; varName: "commandState"; defaultValue: ({}) }
    PluginGlobalVar { id: finding; varName: "findState"; defaultValue: ({active:false}) }
    PluginGlobalVar { id: actionError; varName: "actionError"; defaultValue: "" }
    readonly property var snapshot: telemetry.value || ({})
    readonly property var device: deviceInfo.value || ({})
    readonly property var status: snapshot.status || ({})
    readonly property bool connected: snapshot.connected !== undefined ? snapshot.connected :
        (snapshot.phase === "connected" || snapshot.phase === "controlling") && !(status.placement_left === "DISCONNECTED" && status.placement_right === "DISCONNECTED")
    readonly property bool busy: (commandState.value || ({})).busy === true
    readonly property var findState: finding.value || ({active:false})
    readonly property string error: actionError.value || ""
    function ringing(side) { return findState.active && findState.side === side; }
    function canFind(side) { return connected && !busy && !Policy.findError(device, status, side); }
    function send(command, args, label) {
        PluginService.setGlobalVar(pluginId, "commandRequest", {
            id: Date.now() + "-" + Math.random(), command:command, args:args || [], label:label || command
        });
    }
    function find(side) {
        if (ringing(side)) send("find", ["stop"], "Stop finding");
        else if (canFind(side)) send("find", [side], "Find " + side + " earbud");
    }
}
