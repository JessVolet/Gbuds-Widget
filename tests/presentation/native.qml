import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common as DC
import qs.DCommon.Widgets
import "Plugin/src/state"
import "Plugin/src/surfaces"
import "Plugin/src/config/Schema.js" as Schema

ShellRoot {
    id:root
    property bool dark:Quickshell.env("GBUDS_DARK")==="1"
    FloatingWindow {
        visible:true
        implicitWidth:930; implicitHeight:860
        color:Theme.surfaceContainerLowest
        Rectangle {
            color:Theme.dark ? "#211e20" : "#fff8f7"
            id:stage; anchors.fill:parent
            DevicePanel { x:20; y:20; width:420; height:820; service:PluginService; active:true; config:Schema.resolve({}) }
            UiState { id:showcaseState; pluginId:"gbudsWatch"; service:PluginService }
            DCard {
                x:470; y:20; width:440; height:820; pad:16
                Column {
                    anchors.fill:parent; anchors.margins:16; spacing:10
                    StyledText { text:"Sound & controls"; color:Theme.surfaceText; font.pixelSize:18; font.weight:Font.DemiBold }
                    StyledText { text:"Native Dux controls · capability-aware"; color:Theme.surfaceVariantText; font.pixelSize:12 }
                    AdvancedControls { width:parent.width; state:showcaseState }
                }
            }
        }
    }
    Component.onCompleted: {
        Theme.dark=root.dark;
        DC.Style.theme=Theme; DC.Style.settings=SettingsData;
        const supported={device_support:"supported",gbuds_support:"implemented"};
        PluginService.values={selectedDevice:"AA:BB:CC:DD:EE:FF",telemetry:{connected:true,phase:"connected",status:{left:53,right:100,case:46,placement_left:"IDLE",placement_right:"WEARING",noise_control:"NOISE_REDUCTION"}},device:{name:"Buds3 de Jose",model_code:"SM-R530",features:{find_earbuds:supported,equalizer:supported,touchpad:supported},supported_noise_modes:["off","on","ambient"]}};
    }
    Timer { interval:800; running:true; onTriggered:{ stage.grabToImage(result=>{result.saveToFile(Quickshell.env("EVIDENCE_DIR")+(root.dark ? "/panel-dark.png" : "/panel-light.png"));console.warn("PASS native-widget panel captured");Qt.quit();});} }
}
