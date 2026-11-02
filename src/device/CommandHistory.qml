import QtQuick
import "History.js" as History

Item {
    id:root
    property var service
    property string pluginId:"gbudsWatch"
    property var entries:[]
    property int sequence:0
    function begin(job) {
        job.historyId=String(++sequence);
        entries=History.begin(entries,job,Date.now(),job.historyId);
    }
    function finish(job,result,success) { entries=History.finish(entries,job.historyId,result,success,Date.now()); }
    onEntriesChanged:if (service) service.setGlobalVar(pluginId,"commandHistory",entries)
    Connections {
        target:root.service
        function onGlobalVarChanged(pid,key) {
            if (pid===root.pluginId && key==="clearCommandHistory") root.entries=[];
        }
    }
}
