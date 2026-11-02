import QtQuick
import Quickshell
import qs.Common
import "Plugin/src/motion"

ShellRoot {
    id:root
    property int frame:0
    property var times:[0,1,16,249,250,266,499,500,516,1900,2899,2900,2916]
    property string directory:Quickshell.env("EVIDENCE_DIR")
    FloatingWindow {
        id:window
        visible:true
        color:"#101010"
        implicitWidth:500
        implicitHeight:500
        Item {
            id:canvas
            anchors.fill:parent
            WaveEmitter { id:wave; anchors.fill:parent; count:3; radiusPx:220; lifetimeMs:5000; tone:"#ffffff"; strokePx:4 }
        }
    }
    Timer {
        interval:70; repeat:true; running:true
        onTriggered: {
            if (root.frame >= root.times.length) { console.warn("PASS real renderer frames captured"); Qt.quit(); return; }
            const t=root.times[root.frame++];
            wave.elapsedMs=t;
            Qt.callLater(() => canvas.grabToImage(result => {
                if (!result.saveToFile(root.directory+"/wave-"+t+".png")) { console.error("FAIL image save"); Qt.quit(); }
            }));
        }
    }
}
