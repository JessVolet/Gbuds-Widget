import QtQuick
import Quickshell
import "Plugin/src/motion"
ShellRoot {
    id:root
    property var frames:[]
    property double previous:0
    FloatingWindow {
        visible:true; implicitWidth:500; implicitHeight:500; color:"#161616"
        WaveEmitter { anchors.fill:parent; elapsedMs:clock.elapsedMs; count:3; radiusPx:220; lifetimeMs:30000 }
    }
    WaveController {
        id:clock
        lifetimeMs:30000
        Component.onCompleted:start()
        onElapsedMsChanged: {
            const now=Date.now();
            if(root.previous) root.frames.push(now-root.previous);
            root.previous=now;
        }
        onCompleted: {
            const values=root.frames.sort((a,b)=>a-b);
            console.warn("PROFILE "+JSON.stringify({durationMs:30000,frames:values.length,p95Ms:values[Math.floor(values.length*.95)],maxMs:values[values.length-1],stallsOver50Ms:values.filter(v=>v>50).length}));
            Qt.quit();
        }
    }
}
