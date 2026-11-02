import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Common as DC
import "Plugin/src/config"
import "Plugin/src/settings"

ShellRoot {
    id:root
    property int writes:0
    ConfigStore { id:preferences; source:({notificationPresentation:"waveup",advancedNotifications:true,notificationRules:{"noise-mode":{presentation:"popup",position:"center",popupDuration:4}}}); onPersist:(key,value)=>root.writes++ }
    FloatingWindow {
        visible:true; implicitWidth:1100; implicitHeight:1000
        Rectangle {
            id:stage; anchors.fill:parent; color:Theme.dark ? "#211e20" : "#fff8f7"
            Flickable {
                anchors.fill:parent; anchors.margins:24; contentHeight:editor.implicitHeight; clip:true
                NotificationSettings { id:editor; width:parent.width; preferences:preferences }
            }
        }
    }
    Component.onCompleted:{ DC.Style.theme=Theme; DC.Style.settings=SettingsData; }
    function find(item,name) { if(item.objectName===name) return item; for(const child of item.children || []) {const match=find(child,name);if(match)return match;} return null; }
    Timer { interval:800; running:true; onTriggered:stage.grabToImage(result=>{result.saveToFile(Quickshell.env("EVIDENCE_DIR")+"/settings-native.png");if(root.writes) {console.error("FAIL opening settings persisted values");Qt.exit(1);}else {console.warn("PASS native settings captured without writes");const events=root.find(editor,"eventRules");events.grabToImage(image=>{image.saveToFile(Quickshell.env("EVIDENCE_DIR")+"/event-editor-native.png");Qt.quit();});}}) }
}
