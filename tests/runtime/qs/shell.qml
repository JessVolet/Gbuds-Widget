import QtQuick
import Quickshell
import qs.Services

ShellRoot {
    id: harness
    property int stage: 0
    property int ticks: 0
    property int checks: 0
    property var daemon
    property var compact
    property var actions
    function assertThat(condition, label) {
        if (!condition) { console.error("FAIL " + label); Qt.exit(1); return; }
        checks++;
        console.warn("PASS " + label);
    }
    function find(item, name) {
        if (item.objectName === name) return item;
        for (var child of item.children || []) {
            var found = find(child, name);
            if (found) return found;
        }
        return null;
    }
    Component.onCompleted: {
        if (!Quickshell.env("GBUDS_FAKE_CLI")) {
            console.error("Run tests/run-runtime.sh; a fake CLI path is required.");
            Qt.exit(1);
            return;
        }
        PluginService.values = {};
        daemon = Qt.createComponent("Plugin/Daemon.qml").createObject(harness, {
            pluginData:{targetMac:"AA:BB:CC:DD:EE:FF",showStatusCards:false,gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI")}
        });
        compact = Qt.createComponent("Plugin/interface-v050/BudsCompact.qml").createObject(harness, {pluginId:"gbudsWatch",width:360,height:256});
        actions = Qt.createComponent("Plugin/interface-v050/BudsActions.qml").createObject(harness,{pluginId:"gbudsWatch"});
        assertThat(!!daemon && !!compact && !!actions,"instantiate real daemon and compact UI");
        poll.start();
    }
    Timer {
        id: poll
        interval: 50; repeat:true
        onTriggered: {
            if (++harness.ticks > 300) { harness.assertThat(false,"flow deadline"); return; }
            var d=harness.daemon, a=harness.actions;
            if (harness.stage === 0) {
                harness.assertThat(!a.connected,"disconnected has no stale connection");
                var button=harness.find(harness.compact,"connectButton");
                harness.assertThat(button && button.visible && button.enabled,"connect button is visible and interactive offline");
                button.clicked();
                harness.stage=1;
            } else if (harness.stage === 1 && !d.actionInFlight) {
                harness.assertThat(PluginService.values.commandResult.success,"connect command succeeds without telemetry");
                BluetoothService.pairedDevices=[{name:"Test Buds3",address:"AA:BB:CC:DD:EE:FF",connected:true}];
                harness.stage=2;
            } else if (harness.stage === 2 && d.device && d.lastStatus) {
                harness.assertThat(d.device.supported_noise_modes.indexOf("ambient") < 0,"initial capabilities hide unsupported Ambient");
                harness.assertThat(a.canFind("left") && !a.canFind("right"),"only out-of-ear bud is searchable");
                harness.find(harness.compact,"find-left").clicked(); harness.stage=3;
            } else if (harness.stage === 3 && !d.actionInFlight) {
                harness.assertThat(a.findState.active && a.findState.side === "left","left icon starts only left search");
                harness.find(harness.compact,"find-left").clicked(); harness.stage=4;
            } else if (harness.stage === 4 && !d.actionInFlight) {
                harness.assertThat(!a.findState.active,"second click stops search");
                a.find("left"); harness.stage=5;
            } else if (harness.stage === 5 && !d.actionInFlight) {
                harness.assertThat(a.findState.active,"search restarted for disconnect test");
                var button=harness.find(harness.compact,"disconnectButton");
                // CASE is the only visible button among the three delegates.
                function visibleButton(item) {
                    if (item.objectName === "disconnectButton" && item.visible) return item;
                    for (var child of item.children || []) { var found=visibleButton(child); if(found) return found; }
                    return null;
                }
                button=visibleButton(harness.compact);
                harness.assertThat(!!button,"disconnect button is under case");
                button.clicked(); harness.stage=6;
            } else if (harness.stage === 6 && !d.actionInFlight) {
                harness.assertThat(d.disconnectedByUser && !a.connected && !d.lastStatus && !a.findState.active,"disconnect stops search and clears UI while BlueZ is stale");
                harness.assertThat(!d.watchProcess,"disconnect never restarts watcher");
                harness.assertThat(harness.find(harness.compact,"connectButton").visible,"offline UI returns to connect only");
                BluetoothService.pairedDevices=[];
                a.send("connect",[],"Connect"); harness.stage=7;
            } else if (harness.stage === 7 && !d.actionInFlight) {
                BluetoothService.pairedDevices=[{name:"Test Buds3",address:"AA:BB:CC:DD:EE:FF",connected:true}];
                harness.stage=8;
            } else if (harness.stage === 8 && d.device && d.lastStatus) {
                harness.assertThat(a.connected && d.device.supported_noise_modes.length===2,"reconnection refreshes capabilities and resumes watch");
                harness.daemon.destroy();
                console.warn("PASS complete flow, " + harness.checks + " checks");
                Qt.quit();
            }
        }
    }
}
