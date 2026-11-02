import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../motion"
import "../presentation"

Rectangle {
    id: root
    property var event: ({})
    property var config: ({})
    property real elapsedMs:0
    property real lifeElapsedMs:elapsedMs
    property int lifetimeMs:config.dismissTimeout*1000
    property int motionLifetimeMs:lifetimeMs
    signal dismissed()
    implicitWidth: 250
    implicitHeight: 270
    property bool closing:event.closing === true
    Behavior on opacity { enabled:root.closing; NumberAnimation { duration:140 } }
    opacity:closing ? 0 : Math.max(0,Math.min(1,lifeElapsedMs/180,(lifetimeMs-lifeElapsedMs)/140))
    scale:0.98+0.02*Math.min(1,lifeElapsedMs/180)
    radius: Theme.cornerRadiusL
    color: Theme.withAlpha(Theme.surfaceContainerHigh,0.98)
    border.color: Theme.withAlpha(event.kind === "battery-20" ? Theme.error : Theme.primary, 0.45)
    border.width: 1
    Column {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8
        Row {
            width: parent.width
            StyledText { width: parent.width - 28; text: root.event.device?.name || "Galaxy Buds"; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.pixelSize: 12 }
            DButton { width:24; buttonHeight:24; minimumWidth:0; text:""; iconName:"close"; Accessible.name:"Dismiss notification"; onClicked:root.dismissed() }
        }
        Item {
            width: parent.width
            height: 135
            clip: true
            WaveEmitter {
                anchors.fill: parent
                elapsedMs: root.elapsedMs
                count: root.event.waves || 1
                radiusPx: 72
                lifetimeMs:root.motionLifetimeMs
                strokePx: root.event.kind === "battery-20" ? 6 : root.config.waveStrokePx
                tone: root.event.kind === "battery-20" ? Theme.error : root.event.kind === "battery-50" ? Theme.warning : Theme.primary
                reducedMotion: root.config.notifyReduceMotion
            }
            Row {
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: root.event.subject === "mode" ? [] : ["left","right"].indexOf(root.event.subject) >= 0 ? [root.event.subject] : root.event.subject === "case" ? ["case"] : ["left","right"]
                    PartIcon { required property string modelData; part:modelData; device:root.event.device || {}; artwork:root.config.notificationArtwork; width:70; height:90 }
                }
            }
            ModeIcon { anchors.centerIn: parent; visible:root.event.subject === "mode"; mode:root.event.mode || "OFF"; size:58 }
        }
        StyledText { width:parent.width; text:root.event.title || ""; color:Theme.surfaceText; font.pixelSize:16; font.bold:true; horizontalAlignment:Text.AlignHCenter; wrapMode:Text.WordWrap }
        StyledText { width:parent.width; text:root.event.detail || ""; color:Theme.surfaceVariantText; font.pixelSize:12; horizontalAlignment:Text.AlignHCenter; wrapMode:Text.WordWrap }
    }
}
