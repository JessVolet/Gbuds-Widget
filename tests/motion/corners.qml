import QtQuick
import Quickshell
import "Plugin/src/alerts"
import "Plugin/src/config/Schema.js" as Schema
ShellRoot {
    id:root
    property int index:0
    property var positions:[{side:"left",edge:"top"},{side:"right",edge:"top"},{side:"left",edge:"bottom"},{side:"right",edge:"bottom"}]
    WaveupSurface {
        id:surface
        visible:true
        screen:Quickshell.screens[0]
        config:Schema.resolve({notifyMargin:0,notifyVerticalPosition:root.positions[Math.min(root.index,3)].edge})
        event:({waves:1})
        side:root.positions[Math.min(root.index,3)].side
        elapsedMs:700
    }
    Timer {
        id:steps
        interval:150; running:true; repeat:true
        onTriggered:{
            if(root.index>=4){console.warn("PASS four native Waveup corners captured");Qt.quit();return;}
            if(surface.width!==surface.screen.width || surface.height!==surface.screen.height){console.error("FAIL output bounds");Qt.quit();return;}
            const name=root.positions[root.index].edge+"-"+root.positions[root.index].side;
            steps.stop();
            const captured=surface.contentItem.children[0].grabToImage(result=>{
                result.saveToFile(Quickshell.env("EVIDENCE_DIR")+"/corner-"+name+".png");
                console.warn("CORNER "+name+" "+surface.width+"x"+surface.height+" scale="+surface.screen.devicePixelRatio);
                root.index++; steps.restart();
            });
            if(!captured){console.error("FAIL capture surface");Qt.exit(1);}
        }
    }
}
