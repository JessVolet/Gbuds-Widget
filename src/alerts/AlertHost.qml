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
    property int slot: 0
    readonly property var output: Placement.screen(Quickshell.screens, CompositorService.getFocusedScreen(), payload.screenName)
    readonly property bool popup: payload.channel === "popup" || payload.channel === "both"
    readonly property bool waveup: payload.channel === "waveup" || payload.channel === "both"
    readonly property bool bilateral: payload.subject === "pair" || payload.subject === "mode"
    property real offsetPx:slot * 282
    Behavior on offsetPx { NumberAnimation { duration:180; easing.type:Easing.OutCubic } }
    signal dismissed(string id)
    WaveController {
        id: clock
        lifetimeMs: Math.max(root.popup ? root.config.dismissTimeout : 0, root.waveup ? root.config.notifyWaveDuration : 0) * 1000
        Component.onCompleted: start()
    }
    WaveupSurface {
        screen: root.output
        event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; side:"left"
        visible: clock.active && root.waveup && (root.bilateral || root.payload.side === "left") && clock.elapsedMs < root.config.notifyWaveDuration * 1000
    }
    WaveupSurface {
        screen: root.output
        event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; side:"right"
        visible: clock.active && root.waveup && (root.bilateral || root.payload.side === "right") && clock.elapsedMs < root.config.notifyWaveDuration * 1000
    }
    PanelWindow {
        screen: root.output
        visible: clock.active && root.popup && clock.elapsedMs < root.config.dismissTimeout * 1000
        implicitWidth: 250
        implicitHeight: 270
        color: "transparent"
        anchors { left:root.payload.side === "left"; right:root.payload.side !== "left"; top:root.config.notifyVerticalPosition === "top"; bottom:root.config.notifyVerticalPosition !== "top" }
        margins {
            left: root.config.notifyMargin; right:root.config.notifyMargin
            top: root.config.notifyMargin + root.offsetPx
            bottom: root.config.notifyMargin + root.offsetPx
        }
        WlrLayershell.namespace: "dms:gbuds-popup"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        PopupCard { anchors.fill:parent; event:root.payload; config:root.config; elapsedMs:clock.elapsedMs; onDismissed:root.dismissed(root.uid) }
    }
}
