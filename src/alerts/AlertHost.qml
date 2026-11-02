import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Services
import "../motion"
import "../presentation/ScreenPlacement.js" as Placement

Item {
    id: root
    required property var payload
    required property string uid
    required property int index
    property var config: ({})
    property int slot:0
    property bool initialized:false
    property double createdAt:0
    property int popupDurationMs:0
    property int waveDurationMs:0
    property int popupMotionMs:0
    property int waveMotionMs:0
    readonly property real ageMs:{ clock.elapsedMs; return initialized ? Date.now()-createdAt : 0; }
    readonly property string motionKey:[config.waveRadiusPx,config.waveStrokePx,config.notifyReduceMotion,config.dismissTimeout,config.notifyWaveDuration].join(":")
    function restartMotion() {
        if (!initialized) return;
        popupMotionMs=Math.max(0,popupDurationMs-ageMs);
        waveMotionMs=Math.max(0,waveDurationMs-ageMs);
        clock.lifetimeMs=Math.max(popupMotionMs,waveMotionMs);
        if (clock.lifetimeMs>0) clock.start(); else clock.cancel();
    }
    onMotionKeyChanged:restartMotion()
    Component.onCompleted:{
        createdAt=Date.now();
        popupDurationMs=popup ? config.dismissTimeout*1000 : 0;
        waveDurationMs=waveup ? config.notifyWaveDuration*1000 : 0;
        initialized=true; restartMotion();
    }
    readonly property var output: Placement.screen(Quickshell.screens, CompositorService.getFocusedScreen(), payload.screenName)
    readonly property bool popup: payload.channel === "popup" || payload.channel === "both"
    readonly property bool waveup: payload.channel === "waveup" || payload.channel === "both"
    readonly property string waveOrigin:config.waveOrigin || (payload.subject === "pair" || payload.subject === "mode" ? "both" : payload.side)
    readonly property bool bilateral:waveOrigin === "both"
    property real offsetPx:slot * 282
    Behavior on offsetPx { NumberAnimation { duration:180; easing.type:Easing.OutCubic } }
    signal dismissed(string id)
    WaveController {
        id: clock

    }
    WaveupSurface {
        screen: root.output
        event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; lifetimeMs:root.waveMotionMs; side:"left"
        visible: clock.active && !root.payload.closing && root.waveup && (root.bilateral || root.waveOrigin === "left") && root.ageMs < root.waveDurationMs
    }
    WaveupSurface {
        screen: root.output
        event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; lifetimeMs:root.waveMotionMs; side:"right"
        visible: clock.active && !root.payload.closing && root.waveup && (root.bilateral || root.waveOrigin === "right") && root.ageMs < root.waveDurationMs
    }
    PanelWindow {
        screen: root.output
        visible: clock.active && root.popup && root.ageMs < root.popupDurationMs
        implicitWidth: root.payload.popupRect?.width || 250
        implicitHeight: root.payload.popupRect?.height || 270
        color: "transparent"
        anchors { left:true; top:true }
        margins { left:root.payload.popupRect?.x || 0; top:root.payload.popupRect?.y || 0 }
        WlrLayershell.namespace: "dms:gbuds-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        PopupCard { anchors.fill:parent; event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; lifeElapsedMs:root.ageMs; lifetimeMs:root.popupDurationMs; motionLifetimeMs:root.popupMotionMs; onDismissed:root.dismissed(root.uid) }
    }
}
