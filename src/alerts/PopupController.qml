import QtQuick

Item {
    id:root
    property alias model:items
    property var waiting:[]
    property int revision:0
    readonly property int count:items.count
    ListModel { id:items; dynamicRoles:true }
    function occupied(group, before) {
        let count=0;
        for (let i=0;i<Math.min(before,items.count);i++) if (items.get(i).group===group) count++;
        return count;
    }
    function enqueue(job) {
        if (occupied(job.group,items.count)>=job.capacity) {
            waiting=waiting.filter(item=>item.expiresAt>Date.now() && item.uid!==job.uid);
            if (waiting.length>=16) {
                if (job.priority>0) waiting=waiting.slice(0,15);
                else return;
            }
            waiting=waiting.concat([job]).sort((a,b)=>b.priority-a.priority);
            return;
        }
        items.append({uid:job.uid,payload:job.payload,group:job.group,deadline:Date.now()+job.durationMs});
        revision++;
    }
    function dismiss(uid) {
        for (let i=items.count-1;i>=0;i--) if (items.get(i).uid===uid) items.remove(i);
        revision++;
    }
    function clear() { items.clear(); waiting=[]; revision++; }
    Timer {
        interval:100; repeat:true; running:items.count>0 || root.waiting.length>0
        onTriggered: {
            for (let i=items.count-1;i>=0;i--) if (items.get(i).deadline<=Date.now()) { items.remove(i); root.revision++; }
            const waiting=root.waiting; root.waiting=[];
            waiting.forEach(job=>{ if (job.expiresAt>Date.now()) root.enqueue(job); });
        }
    }
}
