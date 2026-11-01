const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const path=require("node:path");
const vm=require("node:vm");

function load(file){
    const context=vm.createContext({Date});
    vm.runInContext(fs.readFileSync(path.join(__dirname,"..",file),"utf8").replace(/^\.pragma library\s*/,""),context);
    return context;
}
const policy=load("core-v060/NotificationPolicy.js");
const config=load("core-v060/WidgetConfig.js");

test("new widgets default to compact, hidden offline and preserve zero/false instance values",()=>{
    const value=config.resolve({desktopGap:0,desktopShowNoise:false},{desktopPreset:"detailed",desktopOfflinePolicy:"connect"},false);
    assert.equal(value.desktopPreset,"compact");
    assert.equal(value.desktopOfflinePolicy,"hide");
    assert.equal(value.desktopGap,0);
    assert.equal(value.desktopShowNoise,false);
});
test("legacy explicit layout migrates but a missing layout never inherits global Full",()=>{
    assert.equal(config.resolve({desktopLayout:"full"},{},false).desktopPreset,"detailed");
    assert.equal(config.resolve({},{desktopLayout:"full"},false).desktopPreset,"compact");
});
test("widget dimensions and preferences are normalized without losing screen selection",()=>{
    const value=config.resolve({desktopGap:90,desktopEarbudSize:5,desktopScreenPreferences:["HDMI-A-1"]},{},false);
    assert.equal(value.desktopGap,48);
    assert.equal(value.desktopEarbudSize,20);
    assert.deepEqual(Array.from(value.desktopScreenPreferences),["HDMI-A-1"]);
    assert.equal(config.resolve({desktopEarOrder:"not-valid"},{},false).desktopEarOrder,"left-case-right");
});
test("simultaneous battery, placement and noise events are all retained with side snapshots",()=>{
    const previous={left:60,right:25,case:80,placement_left:"WEARING",placement_right:"WEARING",noise_control:"OFF",is_coupled:true};
    const next={...previous,left:18,placement_left:"IDLE",noise_control:"NOISE_REDUCTION"};
    const events=policy.detect(previous,next,{model:"Buds FE"},false);
    assert.deepEqual(Array.from(events,e=>e.kind),["battery-20","out-of-ear","noise-mode"]);
    assert.equal(events[0].subject,"left");
    assert.equal(events[0].snapshot.left,18);
    assert.equal(events[2].waves,3);
});
test("taking a bud out of the case gets its own event and urgent events are routed first",()=>{
    const events=policy.detect({left:60,right:25,case:80,placement_left:"IN_CASE",placement_right:"WEARING",noise_control:"OFF"},
        {left:18,right:25,case:80,placement_left:"IDLE",placement_right:"WEARING",noise_control:"AMBIENT_SOUND"},{},false);
    assert.deepEqual(Array.from(events,e=>e.kind),["battery-20","out-of-case","noise-mode"]);
    assert.equal(events[1].subject,"left");
});
test("a jump across 50 and 20 emits only the urgent threshold for each component",()=>{
    const events=policy.batteryCrossings({left:59,right:80,case:55},{left:18,right:50,case:49});
    assert.deepEqual(Array.from(events,e=>[e.subject,e.level]),[["left",20],["right",50],["case",50]]);
});
test("battery thresholds use five-point hysteresis and do not repeat on 49/50 oscillation",()=>{
    const state={};
    assert.deepEqual(Array.from(policy.batteryCrossings({left:56,right:70,case:90},{left:50,right:70,case:90},state),e=>e.level),[50]);
    assert.deepEqual(Array.from(policy.batteryCrossings({left:50,right:70,case:90},{left:49,right:70,case:90},state)),[]);
    assert.deepEqual(Array.from(policy.batteryCrossings({left:49,right:70,case:90},{left:56,right:70,case:90},state)),[]);
    assert.deepEqual(Array.from(policy.batteryCrossings({left:56,right:70,case:90},{left:50,right:70,case:90},state),e=>e.level),[50]);
});
test("initial telemetry does not fake a threshold crossing and disconnected snapshot survives",()=>{
    const initial=policy.detect(null,{left:10,right:15,placement_left:"IDLE",placement_right:"IDLE"},{},false);
    assert.deepEqual(Array.from(initial,e=>e.kind),["connected"]);
    const events=policy.detect({left:40,right:42,is_coupled:true},{left:40,right:42,is_coupled:false},{},false);
    assert.equal(events[0].kind,"disconnected");
    assert.equal(events[0].snapshot.is_coupled,true);
});
test("noise wave pattern and notification channel are stable and configurable",()=>{
    const event={kind:"noise-mode",mode:"AMBIENT_SOUND"};
    assert.equal(policy.waveCount(event),2);
    assert.equal(policy.channelsFor(event,{notify_noise_mode:"waveup"}),"waveup");
    assert.equal(policy.channelsFor(event,{}),"popup");
});
test("paired buds crossing the same threshold become one bilateral event with both percentages",()=>{
    const events=policy.batteryCrossings({left:60,right:70,case:90},{left:50,right:40,case:90});
    assert.equal(events.length,1);
    assert.equal(events[0].subject,"pair");
    assert.deepEqual(JSON.parse(JSON.stringify(events[0].parts)),{left:50,right:40});
    assert.match(events[0].detail,/L 50% · R 40%/);
});
