import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../config/Schema.js" as Schema

Rectangle {
    id: root
    required property var state
    property var config: ({})
    property bool locked: false
    property string offlinePolicy: "connect"
    readonly property var blocks: Schema.blocks(config)
    readonly property var parts: {
        const order = String(config.desktopEarOrder || "left-case-right").split("-");
        return order.filter(part => ["left","right","case"].indexOf(part) >= 0 && (part !== "case" || (config.desktopShowCase !== false && config.desktopPreset !== "minimal")));
    }
    implicitHeight: state.connected ? content.implicitHeight + config.desktopPadding * 2 : 74
    color: config.desktopBackgroundMode === "transparent" ? "transparent" : Theme.withAlpha(config.desktopBackgroundMode === "custom" ? config.desktopSurfaceColor || Theme.surfaceContainer : Theme.surfaceContainer, config.desktopBackgroundOpacity / 100)
    radius: Theme.cornerRadiusL
    border.width: config.desktopShowBorder && config.desktopBackgroundMode !== "transparent" ? 1 : 0
    border.color: Theme.withAlpha(Theme.outline,0.2)
    Column {
        id: content
        x: root.config.desktopPadding
        y: root.config.desktopPadding
        width: parent.width - root.config.desktopPadding * 2
        spacing: root.config.desktopGap
        add: Transition { enabled:!root.locked || root.config.desktopLockAnimations === true; NumberAnimation { properties:"opacity"; from:0; to:1; duration:160 } }
        move: Transition { enabled:!root.locked || root.config.desktopLockAnimations === true; NumberAnimation { properties:"x,y"; duration:180 } }
        visible: root.state.connected
        Repeater {
            model: root.blocks
            Loader {
                required property string modelData
                width: content.width
                sourceComponent: modelData === "name" ? titleBlock : modelData === "parts" ? partsBlock : modelData === "noise" ? noiseBlock : disconnectBlock
            }
        }
    }
    Component {
        id: titleBlock
        StyledText { text:root.state.device.name || root.state.device.model || "Galaxy Buds"; color:Theme.surfaceText; font.pixelSize:14; font.bold:true; horizontalAlignment:Text.AlignHCenter; elide:Text.ElideRight; height:24 }
    }
    Component {
        id: partsBlock
        Item {
            implicitHeight: partsGrid.implicitHeight
            Grid {
                id:partsGrid
                anchors.horizontalCenter:parent.horizontalCenter
                columns:root.config.desktopHorizontal === false ? 1 : Math.max(1,root.parts.length)
                spacing:root.config.desktopGap
                Repeater { model:root.parts; PartControl { required property string modelData; part:modelData; state:root.state; config:root.config; readOnly:root.locked; objectName:"find-"+modelData } }
            }
        }
    }
    Component {
        id:noiseBlock
        NoiseControls { state:root.state; animate:!root.locked || root.config.desktopLockAnimations === true; readOnly:root.locked && root.config.desktopLockControls !== true; iconSize:root.config.desktopNoiseSize }
    }
    Component {
        id:disconnectBlock
        Item {
            implicitHeight: root.locked ? 0 : 32
            visible: !root.locked
            DButton { objectName:"disconnectButton"; anchors.horizontalCenter:parent.horizontalCenter; width:116; text:"Disconnect"; enabled:!root.state.busy; onClicked:root.state.request("disconnect",[]) }
        }
    }
    Column {
        anchors.centerIn:parent
        visible:!root.state.connected
        spacing:6
        StyledText { anchors.horizontalCenter:parent.horizontalCenter; text:root.state.snapshot.phase === "connecting" ? "Connecting…" : "Galaxy Buds disconnected"; font.pixelSize:12; color:Theme.surfaceVariantText }
        DButton { objectName:"connectButton"; anchors.horizontalCenter:parent.horizontalCenter; visible:root.offlinePolicy === "connect" && !root.locked; text:"Connect"; width:120; enabled:!root.state.busy; onClicked:root.state.request("connect",[]) }
    }
}
