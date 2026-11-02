import QtQuick
import "WaveTimeline.js" as Timeline

Item {
    id: root
    property real elapsedMs: 0
    property int count: 1
    property real radiusPx: 220
    property int durationMs: 1400
    property int lifetimeMs: 5000
    property real strokePx: 4
    property color tone: "white"
    property bool reducedMotion: false
    property real originX: width / 2
    property real originY: height / 2
    readonly property var timing: ({count: count, durationMs: durationMs, lifetimeMs: lifetimeMs, radiusPx: radiusPx})

    Repeater {
        model: root.count
        Rectangle {
            required property int index
            readonly property var frame: root.reducedMotion
                ? {radiusPx: root.radiusPx * (0.55 + index * 0.15), opacity: 0.22}
                : Timeline.sample(root.elapsedMs, index, root.timing)
            width: frame.radiusPx * 2
            height: width
            radius: frame.radiusPx
            x: root.originX - width / 2
            y: root.originY - height / 2
            color: "transparent"
            border.color: root.tone
            border.width: Math.min(root.strokePx, frame.radiusPx * 0.35)
            opacity: frame.opacity
            visible: frame.radiusPx > 0 && frame.opacity > 0
            antialiasing: true
        }
    }
}
