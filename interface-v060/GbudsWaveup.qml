import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services

Item {
    id: root
    objectName: "gbudsWaveup"
    property var config: ({})
    property var eventData: null
    property var screen: null
    property int pulseRevision: 0
    property bool active: false
    property bool leftActive: false
    property bool rightActive: false
    property var waveQueue: []
    readonly property int currentDurationMs: Math.max(1000, Math.min(30000, Number(config.notifyWaveDuration || 5) * 1000))
    readonly property int surfaceSize: Math.max(180, Math.min(360, Number(config.notifyWaveSize || 240)))
    readonly property int cornerInset: Math.max(0, Number(config.notifyMargin || 18))

    function prepareEvent(value) {
        eventData = value;
        var targetName = config.notifyScreen || "active";
        screen = targetName === "primary" ? (Quickshell.screens.length ? Quickshell.screens[0] : null) :
            targetName === "active" ? CompositorService.getFocusedScreen() :
            (Quickshell.screens.find(candidate => candidate.name === targetName) || CompositorService.getFocusedScreen());
        var subject = value.subject || "pair";
        leftActive = subject === "left" || subject === "pair" || subject === "mode";
        rightActive = subject === "right" || subject === "pair" || subject === "mode";
        if (subject === "case") {
            var fixed = config.notifyFixedSide || "right";
            leftActive = fixed === "left";
            rightActive = fixed !== "left";
        }
        if (config.notifyMatchPosition === false && subject !== "mode" && subject !== "pair") {
            leftActive = (config.notifyFixedSide || "right") === "left";
            rightActive = !leftActive;
        }
    }

    function present(value) {
        if (!value) return;
        if (active && eventData) {
            if (waveQueue.length < 4) waveQueue = waveQueue.concat([value]);
            hideTimer.interval = currentDurationMs + waveQueue.length * pulseTimer.interval;
            hideTimer.restart();
            return;
        }
        prepareEvent(value);
        active = true;
        pulseRevision++;
        hideTimer.interval = currentDurationMs;
        pulseTimer.interval = Math.max(1000, Math.min(5000, Number(config.notifyWaveInterval || 1500)));
        pulseTimer.restart();
        hideTimer.restart();
    }

    function count() {
        if (eventData && eventData.waves) return Math.max(1, Math.min(3, Number(eventData.waves)));
        if (!eventData) return 1;
        if (eventData.kind === "battery-50" || eventData.kind === "battery-20") return 3;
        if (eventData.kind === "disconnected") return 2;
        if (eventData.kind === "noise-mode") return eventData.mode === "NOISE_REDUCTION" ? 3 : eventData.mode === "AMBIENT_SOUND" ? 2 : 1;
        return 1;
    }

    function accent() {
        if (!eventData) return Theme.primary;
        if (eventData.kind === "battery-20" || eventData.kind === "critical-battery") return Theme.error;
        if (eventData.kind === "battery-50" || eventData.kind === "low-battery") return Theme.warning;
        if (eventData.severity === "warning") return Theme.error;
        if (eventData.severity === "success") return Theme.primary;
        if (eventData.mode === "AMBIENT_SOUND") return Theme.secondary;
        return Theme.primary;
    }

    Timer { id: hideTimer; interval: 5000; repeat: false; onTriggered: { root.active = false; root.waveQueue = []; pulseTimer.stop() } }
    Timer { id: pulseTimer; interval: 1500; repeat: true; onTriggered: {
        if (root.waveQueue.length) {
            var nextEvent = root.waveQueue[0];
            root.waveQueue = root.waveQueue.slice(1);
            root.prepareEvent(nextEvent);
        }
        root.pulseRevision++;
    } }

    Component {
        id: waveWindow
        PanelWindow {
            property string emitterSide: "right"
            screen: root.screen
            visible: root.active && (emitterSide === "left" ? root.leftActive : root.rightActive)
            color: "transparent"
            WlrLayershell.namespace: "dms:gbuds-waveup:" + emitterSide
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            Region { id: emptyRegion }
            mask: emptyRegion
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }
            WlrLayershell.margins {
                left: 0; right: 0; top: 0; bottom: 0
            }

            Repeater {
                model: root.count()
                delegate: Rectangle {
                    id: ring
                    required property int index
                    width: root.surfaceSize * (0.25 + index * 0.16)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: root.eventData && root.eventData.kind === "battery-20" ? 3 : 2
                    border.color: root.accent()
                    opacity: 0
                    scale: 0.62
                    x: (emitterSide === "left" ? root.cornerInset : parent.width - root.cornerInset) - width / 2
                    y: (root.config.notifyVerticalPosition === "bottom" ? parent.height - root.cornerInset : root.cornerInset) - height / 2
                    SequentialAnimation {
                        id: waveSequence
                        PauseAnimation { duration: ring.index * 250 }
                        ParallelAnimation {
                            NumberAnimation { target: ring; property: "scale"; from: 0.55; to: 1.28; duration: root.eventData && root.eventData.kind === "battery-20" ? 1080 : 1450; easing.type: Easing.OutCubic }
                            NumberAnimation { target: ring; property: "opacity"; from: 0.8; to: 0; duration: root.eventData && root.eventData.kind === "battery-20" ? 1080 : 1450; easing.type: Easing.OutQuad }
                        }
                    }
                    onIndexChanged: waveSequence.restart()
                    Connections {
                        target: root
                        function onPulseRevisionChanged() {
                            if (root.config.notifyReduceMotion === true) {
                                waveSequence.stop();
                                ring.scale = 1;
                                ring.opacity = 0.35;
                            } else waveSequence.restart();
                        }
                    }
                    Component.onCompleted: {
                        if (root.config.notifyReduceMotion === true) {
                            ring.scale = 1;
                            ring.opacity = 0.35;
                        } else waveSequence.restart();
                    }
                }
            }
        }
    }

    Loader { active: true; sourceComponent: waveWindow; property string emitterSide: "left"; onLoaded: if (item) item.emitterSide = emitterSide }
    Loader { active: true; sourceComponent: waveWindow; property string emitterSide: "right"; onLoaded: if (item) item.emitterSide = emitterSide }
}
