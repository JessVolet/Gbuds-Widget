import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../presentation"

DCard {
    id:root
    required property var model
    property string part:"left"
    property var config:({})
    property bool motionEnabled:false
    readonly property bool ringing:model.findState.active && model.findState.side===part
    readonly property bool canSearch:part!=="case" && (ringing || model.canFind(part))
    color:"transparent"; border.width:0; pad:4
    clickable:canSearch
    Accessible.name:ringing ? "Stop finding "+part+" earbud" : "Find "+part+" earbud"
    onClicked:model.findEar(part)
    Column {
        width:parent.width; spacing:5
        Item {
            width:parent.width; height:100
            Repeater {
                model:[0,1,2]
                Rectangle {
                    id:ring
                    required property int modelData
                    readonly property int delay: modelData*820
                    width:24; height:24; radius:12; anchors.centerIn:parent
                    color:"transparent"; border.width:1.6; border.color:Theme.withAlpha(Theme.primary,0.72)
                    opacity:0; scale:0.4
                    SequentialAnimation {
                        loops:Animation.Infinite; running:root.motionEnabled
                        PauseAnimation { duration:delay }
                        ParallelAnimation {
                            SequentialAnimation {
                                NumberAnimation { target:ring; property:"opacity"; from:0; to:0.34; duration:220; easing.type:Easing.OutCubic }
                                NumberAnimation { target:ring; property:"opacity"; to:0; duration:1980; easing.type:Easing.OutCubic }
                            }
                            NumberAnimation { target:ring; property:"scale"; from:0.4; to:3.5; duration:2200; easing.type:Easing.OutCubic }
                        }
                        PropertyAction { target:ring; property:"scale"; value:0.4 }
                        PauseAnimation { duration:480 }
                    }
                }
            }
            DIcon {
                anchors.left:parent.left; anchors.leftMargin:Math.max(3,parent.width*0.12)
                anchors.verticalCenter:parent.verticalCenter
                name:"settings"; size:24; color:Theme.withAlpha(Theme.primary,0.34); rotation:0
                NumberAnimation on rotation { from:0; to:360; duration:26000; loops:Animation.Infinite; running:root.motionEnabled; easing.type:Easing.Linear }
            }
            DIcon {
                anchors.right:parent.right; anchors.rightMargin:Math.max(3,parent.width*0.12)
                anchors.verticalCenter:parent.verticalCenter
                name:"settings"; size:28; color:Theme.withAlpha(Theme.primary,0.30); rotation:0
                NumberAnimation on rotation { from:360; to:0; duration:34000; loops:Animation.Infinite; running:root.motionEnabled; easing.type:Easing.Linear }
            }
            PartIcon {
                z:2; anchors.centerIn:parent; width:Math.min(84,parent.width-12); height:width
                part:root.part; device:root.model.device; artwork:root.config.panelArtwork || "auto"
                tint:Theme.primary; idle:root.model.status["placement_"+root.part]==="IDLE"
                available:root.model.connected
            }
        }
        StyledText { anchors.horizontalCenter:parent.horizontalCenter; text:root.part.toUpperCase(); color:Theme.surfaceVariantText; font.pixelSize:10 }
        StyledText { anchors.horizontalCenter:parent.horizontalCenter; text:root.model.battery(root.part); color:Theme.surfaceText; font.pixelSize:21; font.weight:Font.DemiBold }
        Rectangle {
            anchors.horizontalCenter:parent.horizontalCenter; width:50; height:3; radius:1.5; color:Theme.outline
            Rectangle { width:parent.width*Math.max(0,Math.min(100,Number(root.model.status[root.part]) || 0))/100; height:parent.height; radius:parent.radius; color:Theme.primary; Behavior on width { enabled:!SettingsData.reduceMotion; NumberAnimation { duration:Theme.mediumDuration } } }
        }
        StyledText {
            width:parent.width; horizontalAlignment:Text.AlignHCenter; wrapMode:Text.WordWrap
            visible:root.part!=="case" && root.config.panelSearchHints!==false
            text:root.ringing ? "Stop search" : root.canSearch ? "Click for search" : root.model.status["placement_"+root.part]==="WEARING" ? "In ear" : root.model.status["placement_"+root.part]==="IN_CASE" ? "In case" : "Unavailable"
            font.pixelSize:10; color:root.canSearch ? Theme.primary : Theme.surfaceVariantText
        }
        DButton { width:parent.width; buttonHeight:28; minimumWidth:0; text:"Disconnect"; backgroundColor:Theme.surfaceContainerHigh; textColor:Theme.surfaceText; visible:root.part==="case"; enabled:!root.model.busy; onClicked:root.model.request("disconnect",[]) }
    }
}
