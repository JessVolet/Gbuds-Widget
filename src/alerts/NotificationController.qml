import QtQuick
import QtQml.Models
import Quickshell
import qs.Services
import "../events/EventPolicy.js" as Policy
import "../presentation/ScreenPlacement.js" as Placement

Item {
    id:root
    property var config:({})
    property int sequence:0
    readonly property int count:popups.count
    PopupController { id:popups }
    function add(value) {
        if (!config.notificationsEnabled || SessionService.locked) return;
        const channel=Policy.channel(value,config);
        if (channel==="off") return;
        const output=Placement.screen(Quickshell.screens,CompositorService.getFocusedScreen(),config.notifyScreen);
        if (!output) return;
        const side=Placement.side(value,config);
        const group=output.name+":"+side+":"+(channel==="waveup" ? "wave" : "popup");
        const duration=Math.max(channel!=="waveup" ? config.dismissTimeout : 0,channel!=="popup" ? config.notifyWaveDuration : 0)*1000;
        const payload=Object.assign({},value,{side:side,screenName:output.name,channel:channel,group:group});
        popups.enqueue({uid:String(value.id || ++sequence),payload:payload,group:group,priority:value.kind==="battery-20" ? 1 : 0,
            capacity:channel==="waveup" ? 2 : Placement.capacity(output.height,config.notifyMargin,270),durationMs:duration,expiresAt:Date.now()+15000});
    }
    function dismiss(uid) { popups.dismiss(uid); }
    Instantiator {
        model:popups.model
        delegate:AlertHost {
            config:root.config
            slot:{ popups.revision; return popups.occupied(payload.group,index); }
            onDismissed:uid=>root.dismiss(uid)
        }
    }
    Connections { target:SessionService; function onLockedChanged() { if (SessionService.locked) popups.clear(); } }
}
