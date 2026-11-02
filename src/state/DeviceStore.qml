import QtQuick

Item {
    id: root
    property var service
    property string pluginId: "gbudsWatch"
    property string phase: "disconnected"
    property bool connected: false
    property var status: null
    property var device: ({})
    property var findState: ({active:false, side:""})
    property string error: ""
    property int revision: 0
    property int epoch: 0
    function write(key, value) { if (service) service.setGlobalVar(pluginId, key, value); }
    function publish() {
        revision++;
        write("telemetry", {phase:phase, connected:connected, status:status, detail:error,
            epoch:epoch, revision:revision, updatedAt:Date.now()});
        write("device", device);
        write("findState", findState);
        write("actionError", error);
    }
    function reset() { epoch++; status = null; device = {}; findState = {active:false, side:""}; }
    function pending(request) { write("commandState", {busy:!!request, request:request || null}); }
    function result(request, value, success) {
        write("commandResult", {command:request.command, result:value, success:success, completedAt:Date.now()});
    }
}
