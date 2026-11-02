import QtQuick
import qs.Common
import qs.DCommon.Widgets

Item {
    id:root
    property string deviceName:"Galaxy Buds"
    property string page:"main"
    property bool connected:false
    signal back()
    signal history()
    signal settings()
    implicitHeight:64
    Column {
        width:parent.width-96; spacing:5
        StyledText { width:parent.width; text:root.page==="main" ? root.deviceName : root.page==="history" ? "Command history" : "Connections"; font.pixelSize:20; font.weight:Font.DemiBold; color:Theme.surfaceText; elide:Text.ElideRight }
        StyledText { text:root.page==="main" ? (root.connected ? "Connected" : "Disconnected") : root.deviceName; color:Theme.surfaceVariantText; font.pixelSize:12 }
    }
    Row {
        anchors.right:parent.right; spacing:4
        DIconButton { iconName:root.page==="main" ? "history" : "arrow_back"; tooltipText:root.page==="main" ? "Command history" : "Back"; onClicked:root.page==="main" ? root.history() : root.back() }
        DIconButton { iconName:"settings"; tooltipText:"Gbuds settings"; onClicked:root.settings() }
    }
}
