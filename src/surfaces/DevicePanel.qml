import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../state"
import "../config/Schema.js" as Schema

Item {
    id:root
    property string pluginId: "gbudsWatch"
    property var service
    property var config: ({})
    property bool showMore: false
    property bool showDevices: false
    implicitHeight: 560
    UiState { id:state; pluginId:root.pluginId; service:root.service }
    Flickable {
        anchors.fill:parent
        contentHeight:body.implicitHeight+24
        clip:true
        Column {
            id:body
            x:12; y:12; width:parent.width-24; spacing:12
            DeviceView {
                width:parent.width
                height:implicitHeight
                state:state
                config:Object.assign({},Schema.resolve(root.config,false),{desktopArtwork:root.config.panelArtwork || "auto", desktopEarbudSize:72, desktopCaseSize:72, desktopPreset:"detailed", desktopPadding:16})
            }
            StyledText { width:parent.width; visible:!!state.error; text:state.error; color:Theme.error; font.pixelSize:12; wrapMode:Text.WordWrap }
            Row {
                width:parent.width; spacing:8
                DButton { width:state.connected ? (parent.width-8)/2 : parent.width; text:"Devices"; onClicked:root.showDevices=!root.showDevices }
                DButton { width:(parent.width-8)/2; text:root.showMore ? "Less" : "More controls"; visible:state.connected; onClicked:root.showMore=!root.showMore }
            }
            Column {
                width:parent.width; spacing:6; visible:root.showDevices
                Repeater {
                    model:BluetoothService.pairedDevices.filter(d => /buds/i.test(d.name || ""))
                    DButton { required property var modelData; width:parent.width; text:modelData.name; onClicked:root.service.setGlobalVar(root.pluginId,"deviceSelection",modelData.address) }
                }
            }
            AdvancedControls { width:parent.width; state:state; visible:root.showMore && state.connected }
        }
    }
}
