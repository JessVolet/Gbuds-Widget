import QtQuick
import QtQml.Models
import Quickshell
import qs.Services
import "../config/NotificationPreferences.js" as Preferences
import "../presentation/ScreenPlacement.js" as Placement

Item {
    id:root
    property var config:({})
    property int sequence:0
    readonly property int count:popups.count
    PopupController {
        id:popups
        placeJob:(job,items)=>{
            if (job.payload.channel === "waveup") return job;
            const output=Placement.screen(Quickshell.screens,CompositorService.getFocusedScreen(),job.payload.screenName);
            if (!output) return null;
            const occupied=[];
            for (let i=0;i<items.count;i++) {
                const payload=items.get(i).payload;
                if (payload.screenName===output.name && payload.popupRect) occupied.push(payload.popupRect);
            }
            const settings=job.payload.settings;
            const rectangle=Placement.popupRect(settings.popupPosition,output.width,output.height,settings.notifyMargin,occupied);
            return rectangle ? Object.assign({},job,{payload:Object.assign({},job.payload,{popupRect:rectangle})}) : null;
        }
    }
    function add(value) {
        if (!config.notificationsEnabled || SessionService.locked) return;
        const settings=Preferences.resolve(config,value);
        const channel=settings.presentation;
        if (channel==="off") return;
        const output=Placement.screen(Quickshell.screens,CompositorService.getFocusedScreen(),settings.notifyScreen);
        if (!output) return;
        const side=Placement.side(value,settings);
        const group=output.name+":"+side+":"+(channel==="waveup" ? "wave" : "popup");
        const duration=Math.max(channel!=="waveup" ? settings.dismissTimeout : 0,channel!=="popup" ? settings.notifyWaveDuration : 0)*1000;
        const payload=Object.assign({},value,{side:side,screenName:output.name,channel:channel,group:group,settings:settings});
        popups.enqueue({uid:String(value.id || ++sequence),payload:payload,group:group,priority:value.kind==="battery-20" ? 1 : 0,
            capacity:channel==="waveup" ? 2 : Placement.capacity(output.height,settings.notifyMargin,270),durationMs:duration,expiresAt:Date.now()+15000});
    }
    function dismiss(uid) { popups.dismiss(uid); }
    Instantiator {
        model:popups.model
        delegate:AlertHost {
            config:payload.settings || root.config
            slot:{ popups.revision; return popups.occupied(payload.group,index); }
            onDismissed:uid=>root.dismiss(uid)
        }
    }
    Connections { target:SessionService; function onLockedChanged() { if (SessionService.locked) popups.clear(); } }
}
