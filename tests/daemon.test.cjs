const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const source = fs.readFileSync(path.join(__dirname, "../Daemon.qml"), "utf8");
function context() {
    const root = {
        actionQueue: [], actionInFlight: true, shuttingDown: false, targetMac: "NEW",
        lastStatus: {left:94,right:92,noise_control:"OFF"}, lastError: "",
        pluginService: {setGlobalVar(){}}, checkCli(){}, publish(){}, publishCommand(){},
        runNextAction(){}, acceptTelemetry(s){this.lastStatus=JSON.parse(s);}
    };
    const sandbox = vm.createContext({root, reconnectTimer:{}, console});
    for (const name of ["enqueueAction","finishAction","handleWatcherExit"]) {
        const re = new RegExp("    function "+name+"\\(([^)]*)\\) \\{([\\s\\S]*?)\\n    \\}");
        const match = source.match(re);
        assert.ok(match, name);
        root[name] = vm.runInContext("(function("+match[1]+"){"+match[2]+"})", sandbox);
    }
    return root;
}
test("requests capture their device and reject unknown commands or non-string arguments",()=>{
    const r=context();
    r.enqueueAction("anc",["ambient"],"Ambient");
    assert.equal(r.actionQueue[0].targetAddress,"NEW");
    r.targetMac="OTHER";
    assert.equal(r.actionQueue[0].targetAddress,"NEW");
    r.enqueueAction("exec",["anything"],"invalid");
    r.enqueueAction("anc",[{}],"invalid");
    assert.equal(r.actionQueue.length,1);
});
test("all commands exposed by the UI are accepted and the queue is bounded",()=>{
    const r=context();
    for (const name of ["battery","anc","touchpad","eq","ambient-volume","voice-detect","lights"])
        r.enqueueAction(name,[],name);
    assert.equal(r.actionQueue.length,7);
    for(let i=0;i<30;i++) r.enqueueAction("battery",[],"Battery");
    assert.equal(r.actionQueue.length,16);
});
test("a completed command for an old device cannot overwrite current telemetry",()=>{
    const r=context();
    r.finishAction({command:"anc",args:["on"],targetAddress:"OLD"},{success:true,noise_control:"NOISE_REDUCTION"},true);
    assert.equal(r.lastStatus.noise_control,"OFF");
    assert.equal(r.actionInFlight,false);
});
test("a current-device command updates state and releases the queue",()=>{
    const r=context();
    r.finishAction({command:"anc",args:["on"],targetAddress:"NEW"},{success:true,noise_control:"NOISE_REDUCTION"},true);
    assert.equal(r.lastStatus.noise_control,"NOISE_REDUCTION");
    assert.equal(r.actionInFlight,false);
});
test("a command failure publishes an error and resumes recovery",()=>{
    const r=context(); let recovery=false; let detail="";
    r.checkCli=()=>recovery=true;
    r.publish=(phase,message)=>detail=message;
    r.finishAction({command:"battery",args:[],targetAddress:"NEW"},{success:false,error:"timeout"},false);
    assert.equal(r.lastError,"timeout");
    assert.equal(detail,"timeout");
    assert.equal(recovery,true);
    assert.equal(r.actionInFlight,false);
});
test("switching devices while stopping the watcher cannot strand queued actions",()=>{
    const r=context(); let ran=false;
    r.targetSwitching=true; r.restartAfterTargetSwitch=true;
    const process={destroy(){}};
    r.watchProcess=process;
    r.runNextAction=()=>ran=true;
    r.handleWatcherExit(process,0);
    assert.equal(ran,true);
    assert.equal(r.targetSwitching,false);
});
