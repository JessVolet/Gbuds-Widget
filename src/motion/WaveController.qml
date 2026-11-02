import QtQuick
Item {
    id: root
    property real elapsedMs: 0
    property int lifetimeMs: 5000
    property bool active: false
    property int generation: 0
    signal completed()
    function start() {
        clock.stop(); generation++; elapsedMs = 0; active = true; clock.start();
    }
    function cancel() { clock.stop(); generation++; elapsedMs = 0; active = false; }
    NumberAnimation {
        id: clock
        target: root
        property: "elapsedMs"
        from: 0
        to: root.lifetimeMs
        duration: root.lifetimeMs
        onFinished: { root.active = false; root.completed(); }
    }
    Component.onDestruction: clock.stop()
}
