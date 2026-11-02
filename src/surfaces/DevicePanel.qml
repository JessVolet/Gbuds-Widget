import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../state"
import "../presentation"

Item {
    id:root
    property string pluginId:"gbudsWatch"
    property var service
    property var config:({})
    property bool active:false
    property string page:"main"
    property real pageProgress:1
    onPageChanged:{ pageProgress=0; pageReveal.restart(); }
    NumberAnimation { id:pageReveal; target:root; property:"pageProgress"; to:1; duration:root.config.panelAnimations!==false && visual.motion ? visual.duration : 0 }
    property var parentPopout:null
    property var closePopout:null
    readonly property real availableHeight:parentPopout?.screen ? Math.max(280,parentPopout.screen.height-120) : 760
    implicitHeight:Math.min(availableHeight,body.implicitHeight+8)
    UiState { id:deviceState; pluginId:root.pluginId; service:root.service }
    VisualTokens { id:visual }
    function settings() {
        if (root.closePopout) root.closePopout();
        PopoutService.openSettingsWithTab(SettingsTabs.pluginPage(root.pluginId).id);
    }
    Flickable {
        anchors.fill:parent; contentHeight:body.implicitHeight; clip:true
        boundsBehavior:Flickable.StopAtBounds
        Column {
            id:body; width:parent.width; spacing:10; opacity:0.55+root.pageProgress*0.45
            PanelHeader { width:parent.width; deviceName:deviceState.device.name || "Galaxy Buds"; connected:deviceState.connected; page:root.page; onBack:root.page="main"; onHistory:root.page="history"; onSettings:root.settings() }
            Column {
                width:parent.width; spacing:12; visible:root.page==="main"
                PanelHero { width:parent.width; model:deviceState; config:root.config; visible:deviceState.connected }
                DCard {
                    width:parent.width; height:110; visible:!deviceState.connected; pad:14
                    Column { width:parent.width; spacing:8; StyledText { text:"Connect your Galaxy Buds"; color:Theme.surfaceText; font.pixelSize:16 } DButton { text:"Connect"; iconName:"bluetooth"; enabled:!deviceState.busy; onClicked:deviceState.request("connect",[]) } }
                }
                Column {
                    width:parent.width; spacing:8; visible:deviceState.connected && (deviceState.device.supported_noise_modes || []).length>0
                    StyledText { text:"Noise control"; color:Theme.surfaceText; font.pixelSize:14; font.weight:Font.DemiBold }
                    NoiseControls { width:parent.width; state:deviceState; iconSize:32; animate:root.config.panelAnimations!==false && visual.motion }
                }
                AudioMixer { width:parent.width; visible:deviceState.connected && root.config.panelShowMixer!==false; active:visible && root.active; address:deviceState.selectedAddress; deviceName:deviceState.device.name || "Galaxy Buds" }
                DCollapsibleSection {
                    width:parent.width; visible:deviceState.connected; title:"Sound & controls"; description:"Equalizer and supported device features"
                    AdvancedControls { width:parent.width; state:deviceState }
                }
                DButton { width:parent.width; text:"Manage connections"; backgroundColor:Theme.cardSurface; textColor:Theme.surfaceText; iconName:"devices"; onClicked:root.page="devices" }
            }
            CommandHistoryPage { width:parent.width; model:deviceState; service:root.service; pluginId:root.pluginId; visible:root.page==="history" }
            Column {
                width:parent.width; spacing:8; visible:root.page==="devices"
                Repeater {
                    model:BluetoothService.pairedDevices.filter(d=>/buds/i.test(d.name || ""))
                    DButton { required property var modelData; width:parent.width; text:modelData.name+(modelData.connected ? " · Connected" : " · Connect"); iconName:modelData.connected ? "bluetooth_connected" : "bluetooth"; enabled:!deviceState.busy; onClicked:{ root.service.setGlobalVar(root.pluginId,"deviceSelection",modelData.address); root.page="main"; } }
                }
                StyledText { width:parent.width; text:"Pair new devices from Control Center → Bluetooth."; color:Theme.surfaceVariantText; font.pixelSize:12 }
            }
            StyledText { width:parent.width; visible:!!deviceState.error; text:deviceState.error; color:Theme.error; font.pixelSize:12; wrapMode:Text.WordWrap }
        }
    }
}
