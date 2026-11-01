const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const vm = require("node:vm");
const path = require("node:path");
const source = fs.readFileSync(path.join(__dirname, "../Daemon.qml"), "utf8");
const Policy = vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(__dirname,"../interface-v050/ControlPolicy.js"),"utf8").replace(/^\.pragma library\s*/,""),Policy);
function context() {
    const root = {
        actionQueue: [], actionInFlight: true, shuttingDown: false, targetMac: "NEW",
        notificationEvents: [], routeEvent(value){this.notificationEvents.push(value);},
        lastStatus: {left:94,right:92,noise_control:"OFF"}, lastError: "",
        pluginService: {setGlobalVar(){}}, checkCli(){}, publish(){}, publishCommand(){},
        runNextAction(){}, acceptTelemetry(s){this.lastStatus=JSON.parse(s);}
    };
    Object.assign(root, {pairedBuds:[], connectedBuds:[], targetConnected:true, disconnectedByUser:false,
        device:{model_code:"SM-R530",features:{find_earbuds:{device_support:"unknown",gbuds_support:"unknown"}}},
        findState:{active:false}, publishFind(value){this.findState=value;}, resetConnection(){this.lastStatus=null; this.device=null; this.findState={active:false};},
        resolveTarget(){return this.targetMac;}, rejectAction(){}, validateAction(){return "";}});
    const sandbox = vm.createContext({root, Policy, reconnectTimer:{stop(){}}, findTimer:{restart(){},stop(){}}, console});
    for (const name of ["enqueueAction","finishAction","handleWatcherExit","acceptDeviceInfo"]) {
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
test("connect can be queued without telemetry and disconnect clears stale batteries",()=>{
    const r=context(); r.lastStatus=null; r.targetConnected=false;
    r.enqueueAction("connect",[],"Connect");
    assert.equal(r.actionQueue[0]?.command,"connect");
    r.actionQueue=[]; r.lastStatus={left:90,right:91};
    r.finishAction({command:"disconnect",args:[],targetAddress:"NEW"},{success:true},true);
    assert.equal(r.lastStatus,null);
    assert.equal(r.disconnectedByUser,true);
    assert.equal(r.notificationEvents.at(-1).kind,"disconnected");
    assert.equal(r.notificationEvents.at(-1).severity,"normal");
});
test("disconnect stops a ringing earbud first and find stop remains queueable",()=>{
    const r=context(); r.findState={active:true,side:"left",targetAddress:"NEW"};
    r.enqueueAction("disconnect",[],"Disconnect");
    assert.deepEqual(Array.from(r.actionQueue,x=>x.command+":"+x.args.join()),["find:stop","disconnect:"]);
});
test("stop has priority over queued controls and cancels pending search starts",()=>{
    const r=context();
    r.enqueueAction("find",["left"],"Find left");
    for(let i=0;i<15;i++) r.enqueueAction("battery",[],"Battery");
    r.enqueueAction("find",["stop"],"Stop finding");
    assert.equal(r.actionQueue[0].args[0],"stop");
    assert.equal(r.actionQueue.filter(x=>x.command==="find").length,1);
});
test("a failed stop keeps the stop control available and cancels pending disconnect",()=>{
    const r=context(); r.findState={active:true,side:"left",targetAddress:"NEW"};
    r.actionQueue=[{command:"disconnect",args:[],targetAddress:"NEW"}];
    r.finishAction({command:"find",args:["stop"],targetAddress:"NEW"},{success:false,error:"transport failed"},false);
    assert.equal(r.findState.active,true);
    assert.equal(r.actionQueue.length,0);
    assert.equal(r.disconnectedByUser,false);
});
test("only an acknowledged stop clears the active search",()=>{
    const r=context();
    r.finishAction({command:"find",args:["right"],targetAddress:"NEW"},{success:true},true);
    assert.equal(r.findState.side,"right");
    assert.equal(r.findState.active,true);
    r.finishAction({command:"find",args:["stop"],targetAddress:"NEW"},{success:true},true);
    assert.equal(r.findState.active,false);
});
test("new capability results replace old mode support rather than merging it",()=>{
    const r=context();
    const supported={device_support:"supported",gbuds_support:"implemented"};
    const result={success:true,device:{model_code:"SM-R400N"},capabilities:{noise_control_modes:["off","on","ambient"],features:{anc:supported,ambient_sound:supported}}};
    r.acceptDeviceInfo(JSON.stringify(result));
    assert.equal(r.device.has_ambient,true);
    result.device.model_code="SM-R530";
    result.capabilities.features.ambient_sound={device_support:"unsupported",gbuds_support:"rejected"};
    r.acceptDeviceInfo(JSON.stringify(result));
    assert.equal(r.device.has_ambient,false);
    assert.deepEqual(Array.from(r.device.supported_noise_modes),["off","on"]);
});
