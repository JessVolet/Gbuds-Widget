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
    property var desktop
    property var settings
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
        var daemonComponent = Qt.createComponent("Plugin/Daemon.qml");
        if (daemonComponent.status !== Component.Ready)
            console.error("daemon component status=" + daemonComponent.status + " errors=" + daemonComponent.errorString());
        daemon = daemonComponent.createObject(harness, {
            pluginData:{targetMac:"AA:BB:CC:DD:EE:FF",showStatusCards:false,gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI")}
        });
        compact = Qt.createComponent("Plugin/interface-v060/BudsCompact.qml").createObject(harness, {pluginId:"gbudsWatch",width:360,height:256});
        actions = Qt.createComponent("Plugin/interface-v060/BudsActions.qml").createObject(harness,{pluginId:"gbudsWatch"});
        assertThat(!!daemon && !!compact && !!actions,"instantiate real daemon and compact UI");
        var desktopComponent = Qt.createComponent("Plugin/Desktop.qml");
        if (desktopComponent.status !== Component.Ready)
            console.error("desktop component status=" + desktopComponent.status + " errors=" + desktopComponent.errorString());
        desktop = desktopComponent.createObject(harness,{pluginId:"gbudsWatch",instanceId:"new-instance",instanceData:{config:{displayPreferences:["all"]}},pluginData:{}});
        assertThat(!!desktop && desktop.effectiveConfig.desktopPreset === "compact" && !desktop.visible,"new desktop instance defaults compact and hidden offline");
        desktop.instanceData = {config:{desktopOfflinePolicy:"connect",desktopLayout:"full",displayPreferences:["all"]}};
        assertThat(desktop.shouldShow && desktop.effectiveConfig.desktopPreset === "detailed","explicit legacy Full and Connect migrate for this instance");
        desktop.lockScreen = true;
        desktop.instanceData = {config:{desktopOfflinePolicy:"connect",desktopLockControls:false,displayPreferences:["all"]}};
        assertThat(desktop.effectiveConfig.desktopOfflinePolicy === "hide" && !desktop.visible,"lock-screen widget remains hidden offline");
        var settingsComponent = Qt.createComponent("Plugin/Settings.qml");
        if (settingsComponent.status !== Component.Ready)
            console.error("settings component status=" + settingsComponent.status + " errors=" + settingsComponent.errorString());
        settings = settingsComponent.createObject(harness,{pluginId:"gbudsWatch",pluginService:PluginService,instanceId:"new-instance",instanceData:{config:{displayPreferences:["all"]}}});
        assertThat(!!settings,"global and per-instance settings editor loads");
        var priorDaemonConfig = daemon.pluginData;
        daemon.pluginData = {targetMac:"AA:BB:CC:DD:EE:FF",gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI"),notificationsEnabled:true,notify_noise_mode:"both",notifyScreen:"active"};
        daemon.routeEvent({kind:"noise-mode",subject:"mode",title:"ANC",detail:"Active",severity:"normal",mode:"NOISE_REDUCTION",waves:3,snapshot:{left:68,right:68,noise_control:"NOISE_REDUCTION"}},{left:68,right:68,noise_control:"NOISE_REDUCTION"},{model_code:"SM-R530"});
        assertThat(daemon.popupPresenter.shown && daemon.waveupPresenter.active,"Popup and bilateral Waveup present the same simulated event");
        daemon.popupPresenter.dismiss();
        daemon.waveupPresenter.active = false;
        SessionService.locked = true;
        daemon.routeEvent({kind:"battery-20",subject:"right",title:"20%",detail:"Simulated",severity:"critical",waves:3},{right:18},{model_code:"SM-R530"});
        assertThat(!daemon.popupPresenter.shown && !daemon.waveupPresenter.active,"notifications stay off while the session is locked");
        SessionService.locked = false;
        daemon.pluginData = priorDaemonConfig;
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
