import QtQuick
import Quickshell
import qs.Services
ShellRoot {
    id:root
    property var daemon
    property var desktop
    property var bar
    property var settings
    property var panel
    property bool timedOut:false
    property bool missingExecutable:false
    property int persisted:0
    property int stage:0
    property int ticks:0
    property int checks:0
    function check(value,label) {
        if (!value) { console.error("FAIL "+label); Qt.exit(1); return; }
        checks++; console.warn("PASS "+label);
    }
    function create(path,props) {
        const component=Qt.createComponent("Plugin/"+path);
        if (component.status !== Component.Ready) { console.error(component.errorString()); Qt.exit(1); return null; }
        const item=component.createObject(root,props);
        check(!!item,"load "+path);
        return item;
    }
    Component.onCompleted: {
        PluginService.values={};
        BluetoothService.pairedDevices=[{name:"Test Buds3",address:"AA:BB:CC:DD:EE:FF",connected:false}];
        const configuration=create("src/config/ConfigStore.qml",{source:{desktopGap:12}});
        configuration.persist.connect((key,value)=>{if(key==="desktopGap" && value===0) root.persisted++;});
        configuration.update("desktopGap",0);
        root.check(configuration.value.desktopGap===0,"configuration publishes zero immediately");
        const deadline=create("src/device/ProcessTask.qml",{});
        deadline.finished.connect((job,result,success)=>root.timedOut=!success && result.uncertain===true);
        deadline.start({argv:["/usr/bin/sleep","2"],timeoutMs:60});
        const missing=create("src/device/ProcessTask.qml",{});
        missing.finished.connect((job,result,success)=>root.missingExecutable=!success && !!result.error);
        missing.start({argv:["/does/not/exist/gbuds"],timeoutMs:0});
        daemon=create("Daemon.qml",{pluginData:{gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI"),notificationsEnabled:false}});
        desktop=create("Desktop.qml",{pluginId:"gbudsWatch",instanceId:"one",instanceData:{config:{}},pluginService:PluginService});
        check(desktop.effectiveConfig.desktopPreset === "compact" && !desktop.shouldShow,"new desktop defaults hidden offline");
        bar=create("GbudsBarWidget.qml",{pluginData:{},barConfig:{widgetBackgroundColor:"custom"},pluginService:PluginService});
        const pill=bar.horizontalBarPill.createObject(root,{});
        root.check(!!pill,"bar inline component instantiates");
        const popout=bar.popoutContent.createObject(root,{width:390,height:560});
        root.check(!!popout,"bar popout component instantiates");
        panel=create("src/surfaces/DevicePanel.qml",{width:390,height:560,service:PluginService});
        settings=create("Settings.qml",{pluginId:"gbudsWatch",pluginService:PluginService});
        settings.selectedSection=2;
        daemon.controller.request("connect",[]);
        poll.start();
    }
    Timer {
        id:poll; interval:50; repeat:true
        onTriggered: {
            if (++root.ticks>300) { root.check(false,"runtime deadline"); return; }
            const device=root.daemon.controller;
            if (root.stage===0 && PluginService.values.commandResult?.success) {
                root.check(!device.state.connected,"connect awaits actual BlueZ confirmation");
                BluetoothService.pairedDevices=[{name:"Test Buds3",address:"AA:BB:CC:DD:EE:FF",connected:true}];
                root.stage=1;
            } else if (root.stage===1 && device.state.status && device.state.device.supported_noise_modes) {
                root.check(device.state.device.supported_noise_modes.indexOf("ambient")<0,"capabilities suppress unsupported ambient");
                root.check(device.state.status.placement_left === "IDLE","watch telemetry normalized");
                root.check((PluginService.values.commandHistory || []).some(entry=>entry.command==="connect" && entry.status==="Succeeded"),"history publishes completed commands without device identifiers");
                root.panel.active=true;
                root.check(root.panel.children.length>0,"device panel remains composed without system audio integration");
                root.panel.active=false;
                root.panel.page="main";
                device.request("find",["left"]);
                root.check(PluginService.values.commandState.busy,"input immediately publishes pending feedback"); root.stage=2;
            } else if (root.stage===2 && device.state.findState.active && !PluginService.values.commandState.busy) {
                root.check(device.state.findState.side === "left","find starts the selected out-of-ear side");
                root.daemon.pluginData={gbudsCommand:Quickshell.env("GBUDS_FAKE_FAIL_CLI"),notificationsEnabled:false};
                device.request("disconnect",[]); root.stage=3;
            } else if (root.stage===3 && !PluginService.values.commandState.busy && PluginService.values.commandResult?.success === false) {
                root.check(device.state.findState.active && !device.manualDisconnect && device.queue.length===0,"failed Stop preserves search and cancels disconnect");
                root.daemon.pluginData={gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI"),notificationsEnabled:false};
                device.request("disconnect",[]); root.stage=4;
            } else if (root.stage===4 && device.manualDisconnect && !PluginService.values.commandState.busy) {
                root.check(!device.state.connected && !device.state.findState.active && !device.state.status,"disconnect stops search and clears stale telemetry");
                root.check(device.queue.length===0,"command queue drains");
                root.stage=5;
            } else if (root.stage===5 && root.timedOut && root.missingExecutable) {
                root.check(root.timedOut && root.missingExecutable,"timeout and executable failure release process ownership");
                root.check(root.persisted===1,"configuration persistence is coalesced without default writes");
                root.daemon.pluginData={notificationsEnabled:true,notificationPresentation:"both",gbudsCommand:Quickshell.env("GBUDS_FAKE_CLI")};
                root.daemon.notifications.add({id:"a",kind:"out-of-ear",subject:"left",title:"Earbud removed",detail:"Left earbud",waves:1});
                root.daemon.notifications.add({id:"b",kind:"noise-mode",subject:"mode",title:"Noise cancellation",detail:"ANC",waves:3,mode:"NOISE_REDUCTION"});
                root.check(root.daemon.notifications.count===2,"independent notifications coexist");
                root.daemon.notifications.dismiss("a");
                root.check(root.daemon.notifications.count===1,"dismiss preserves the other event");
                SessionService.locked=true;
                root.check(root.daemon.notifications.count===0,"lock clears external overlays");
                root.daemon.destroy();
                console.warn("PASS complete flow, "+root.checks+" checks");
                Qt.quit();
            }
        }
    }
}
