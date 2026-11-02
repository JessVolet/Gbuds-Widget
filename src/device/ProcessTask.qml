import QtQuick
import Quickshell.Io

Item {
    id:root
    property var process:null
    property bool stream:false
    property bool disposing:false
    readonly property bool busy:process !== null
    signal started(var job)
    signal line(var job, string value)
    signal finished(var job, var result, bool success)
    function start(job) {
        if (busy || disposing) return false;
        process=runner.createObject(root,{job:job});
        started(job);
        process.running=true;
        return true;
    }
    function stop() {
        if (!process) return;
        process.signal(15); killTimer.restart();
    }
    Timer { id:killTimer; interval:1000; onTriggered:if (root.process) root.process.signal(9) }
    Component {
        id:runner
        Process {
            id:task
            property var job
            property string output:""
            property string errors:""
            property bool timedOut:false
            property bool completed:false
            function finish(code) {
                if (completed) return;
                completed=true; killTimer.stop();
                let result={};
                try { result=JSON.parse(output); }
                catch (error) { result={error:errors.trim() || "Could not read the device response."}; }
                if (timedOut) result={error:"The device did not respond in time.",uncertain:true};
                if (root.process===task) root.process=null;
                if (!root.disposing) root.finished(job,result,code===0 && !timedOut && !result.error && result.success!==false);
                task.destroy();
            }
            command:job.argv
            stdout:SplitParser {
                onRead:value=>{
                    if (root.stream) {
                        if (value.length<65536) root.line(task.job,value);
                        else { task.errors="Telemetry exceeded the limit."; task.signal(9); }
                    } else if (task.output.length+value.length<1048576) task.output+=value+"\n";
                    else { task.errors="Command output exceeded the limit."; task.signal(9); }
                }
            }
            stderr:SplitParser { onRead:value=>task.errors=(task.errors+value+"\n").slice(-4096) }
            property Timer launchDeadline:Timer {
                interval:2000
                running:root.process===task && !task.running && !task.completed
                onTriggered:{ task.errors="The Gbuds executable could not be started."; task.finish(127); }
            }
            property Timer watchdog:Timer {
                interval:Math.max(1,task.job.timeoutMs || 15000)
                running:root.process===task && task.job.timeoutMs!==0 && !task.completed
                onTriggered:{ task.timedOut=true; if (task.running) task.signal(9); else task.finish(124); }
            }
            onExited:code=>Qt.callLater(()=>task.finish(code))
        }
    }
    Component.onDestruction:{ disposing=true; if (process) process.signal(9); }
}
