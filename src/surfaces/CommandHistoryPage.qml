import QtQuick
import qs.Common
import qs.DCommon.Widgets

Column {
    id:root
    required property var model
    property var service
    property string pluginId:"gbudsWatch"
    spacing:6
    StyledText { width:parent.width; visible:!root.model.commandHistory.length; text:"No commands yet. Device actions and connection checks appear here."; wrapMode:Text.WordWrap; color:Theme.surfaceVariantText; font.pixelSize:13 }
    DButton { text:"Clear history"; iconName:"delete_sweep"; visible:root.model.commandHistory.length>0; onClicked:root.service.setGlobalVar(root.pluginId,"clearCommandHistory",Date.now()) }
    Repeater {
        model:root.model.commandHistory
        DCollapsibleSection {
            required property var modelData
            width:parent.width
            title:modelData.command+" · "+modelData.status
            description:new Date(modelData.at).toLocaleTimeString()+" · "+modelData.durationMs+" ms"
            Column {
                width:parent.width; spacing:6
                StyledText { width:parent.width; text:modelData.argv; color:Theme.surfaceText; wrapMode:Text.WrapAnywhere; font.pixelSize:12 }
                StyledText { width:parent.width; text:modelData.detail; color:Theme.surfaceVariantText; wrapMode:Text.WordWrap; font.pixelSize:12 }
            }
        }
    }
}
