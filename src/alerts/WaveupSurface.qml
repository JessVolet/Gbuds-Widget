import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import "../motion"

PanelWindow {
    id: root
    property var event: ({})
    property var config: ({})
    property real elapsedMs: 0
    property string side: "right"
    color: "transparent"
    anchors { left:true; right:true; top:true; bottom:true }
    WlrLayershell.namespace: "dms:gbuds-wave"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Region { id: empty }
    mask: empty
    WaveEmitter {
        anchors.fill: parent
        elapsedMs: root.elapsedMs
        count: root.event.waves || 1
        radiusPx: root.config.waveRadiusPx
        lifetimeMs: root.config.notifyWaveDuration * 1000
        strokePx: root.event.kind === "battery-20" ? 6 : root.config.waveStrokePx
        tone: root.event.kind === "battery-20" ? Theme.error : root.event.kind === "battery-50" ? Theme.warning : Theme.primary
        reducedMotion: root.config.notifyReduceMotion
        originX: root.side === "left" ? root.config.notifyMargin : width - root.config.notifyMargin
        originY: root.config.notifyVerticalPosition === "top" ? root.config.notifyMargin : height - root.config.notifyMargin
    }
}
