import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../presentation"

DCard {
    id:root
    required property var model
    property string part:"left"
    property var config:({})
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
            PartIcon {
                anchors.centerIn:parent; width:Math.min(84,parent.width-12); height:width
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
        DButton { width:parent.width; buttonHeight:28; minimumWidth:0; text:"Disconnect"; visible:root.part==="case"; enabled:!root.model.busy; onClicked:root.model.request("disconnect",[]) }
    }
}
