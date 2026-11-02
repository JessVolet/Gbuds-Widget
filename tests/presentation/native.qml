import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Common as DC
import "Plugin/src/surfaces"
import "Plugin/src/config/Schema.js" as Schema

ShellRoot {
    id:root
    property bool dark:Quickshell.env("GBUDS_DARK")==="1"
    FloatingWindow {
        visible:true
        implicitWidth:460; implicitHeight:860
        color:Theme.surfaceContainerLowest
        Rectangle {
            color:Theme.dark ? "#211e20" : "#fff8f7"
            id:stage; anchors.fill:parent
            DevicePanel { anchors.fill:parent; anchors.margins:20; service:PluginService; active:true; config:Schema.resolve({}) }
        }
    }
    Component.onCompleted: {
        Theme.dark=root.dark;
        DC.Style.theme=Theme; DC.Style.settings=SettingsData;
        const supported={device_support:"supported",gbuds_support:"implemented"};
        PluginService.values={selectedDevice:"AA:BB:CC:DD:EE:FF",telemetry:{connected:true,phase:"connected",status:{left:53,right:100,case:46,placement_left:"IDLE",placement_right:"WEARING",noise_control:"NOISE_REDUCTION"}},device:{name:"Buds3 de Jose",model_code:"SM-R530",features:{find_earbuds:supported,equalizer:supported,touchpad:supported},supported_noise_modes:["off","on","ambient"]}};
        AudioService.pipewireNodes=[{name:"bluez_output.AA_BB_CC_DD_EE_FF.1",audio:{volume:.68,muted:false},isSink:true,isStream:false}];
        AudioService.sink=AudioService.pipewireNodes[0];
    }
    Timer { interval:800; running:true; onTriggered:{ stage.grabToImage(result=>{result.saveToFile(Quickshell.env("EVIDENCE_DIR")+(root.dark ? "/panel-dark.png" : "/panel-light.png"));console.warn("PASS native-widget panel captured");Qt.quit();});} }
}
