import QtQuick
import Quickshell
import qs.Services
import "Plugin/src/state"
import "Plugin/src/surfaces"
import "Plugin/src/alerts"
import "Plugin/src/config/Schema.js" as Schema

ShellRoot {
    id:root
    FloatingWindow {
        visible:true
        implicitWidth:1080; implicitHeight:620
        color:"#e9dce2"
        Item {
            id:stage
            anchors.fill:parent
            UiState { id:state; pluginId:"gbudsWatch"; service:PluginService }
            DevicePanel { x:16; y:16; width:390; height:580; service:PluginService; config:Schema.resolve({}) }
            DeviceView { x:424; y:16; width:336; height:implicitHeight; state:state; config:Schema.resolve({}) }
            PopupCard { x:786; y:16; width:250; height:270; config:Schema.resolve({}); elapsedMs:500; event:({title:"Noise cancellation",detail:"ANC is active",subject:"mode",mode:"NOISE_REDUCTION",waves:3}) }
        }
    }
    Component.onCompleted: {
        const supported={device_support:"supported",gbuds_support:"implemented"};
        PluginService.values={telemetry:{connected:true,phase:"connected",status:{left:94,right:92,case:59,placement_left:"IDLE",placement_right:"WEARING",noise_control:"NOISE_REDUCTION"}},
            device:{name:"Galaxy Buds3",model_code:"SM-R530",features:{find_earbuds:supported,equalizer:supported,touchpad:supported},supported_noise_modes:["off","on"]}};
    }
    Timer { interval:500; running:true; onTriggered:stage.grabToImage(result=>{result.saveToFile(Quickshell.env("EVIDENCE_DIR")+"/presentation.png");console.warn("PASS presentation scene rendered");Qt.quit();}) }
}
