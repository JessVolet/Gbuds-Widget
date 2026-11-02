import QtQuick
import qs.Services
import "EventPolicy.js" as Policy

Item {
    id: root
    property var backend
    property var config: ({})
    property var memory: ({})
    property var due: ({left:0, right:0})
    property int sequence: 0
    signal emitted(var event)
    function publish(event, device) {
        event.id = String(++sequence) + ":" + Date.now();
        event.device = Object.assign({}, device || {});
        emitted(event);
    }
    Connections {
        target: root.backend
        function onSample(previous, next, device) {
            if (!previous) root.memory = {};
            const events = Policy.detect(previous, next, root.memory, Date.now());
            events.forEach(event => root.publish(event, device));
            ["left","right"].forEach(side => {
                if (next["placement_" + side] !== "IDLE") root.due[side] = 0;
                else if (!root.due[side]) root.due[side] = Date.now() + root.config.notifyIdleInterval * 1000;
            });
        }
        function onDisconnected(previous, device, voluntary) {
            root.due = {left:0, right:0}; root.memory = {};
            root.publish(Policy.create("disconnected","pair","Galaxy Buds disconnected",voluntary ? "Disconnected from this widget" : "Bluetooth connection ended",2,previous,Date.now(),voluntary ? "normal" : "warning"),device);
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: root.config.notifyIdleReminder === true && !SessionService.locked && root.backend.state.connected
        onTriggered: {
            ["left","right"].forEach(side => {
                if (root.due[side] && Date.now() >= root.due[side]) {
                    root.publish(Policy.create("out-of-ear-reminder",side,"Still out of ear",Policy.label(side) + " is still out",1,root.backend.state.status,Date.now()),root.backend.state.device);
                    root.due[side] = Date.now() + root.config.notifyIdleInterval * 1000;
                }
            });
        }
    }
    Connections {
        target: SessionService
        function onLockedChanged() { root.due = {left:0, right:0}; }
    }
}
