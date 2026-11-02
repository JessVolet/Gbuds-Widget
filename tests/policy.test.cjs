const {test}=require("node:test");
const assert=require("node:assert/strict");
const fs=require("node:fs");
const vm=require("node:vm");
const policy=vm.createContext({});
vm.runInContext(fs.readFileSync(require("node:path").join(__dirname,"../src/device/Policy.js"),"utf8").replace(/^\.pragma library\s*/,""),policy);
test("noise modes follow device capabilities, including Buds3 versus FE",()=>{
    const features={anc:{device_support:"supported",gbuds_support:"implemented"},ambient_sound:{device_support:"unsupported",gbuds_support:"rejected"}};
    const caps={noise_control_modes:["off","on","ambient"],features};
    assert.deepEqual(Array.from(policy.noiseModes(caps)),["off","on"]);
    features.ambient_sound={device_support:"supported",gbuds_support:"implemented"};
    assert.deepEqual(Array.from(policy.noiseModes(caps)),["off","on","ambient"]);
    features.anc.gbuds_support="not_implemented";
    assert.deepEqual(Array.from(policy.noiseModes(caps)),["off","ambient"]);
});
test("find allows an idle side but rejects worn, stored, disconnected and unknown placement",()=>{
    const device={model_code:"SM-R530",features:{find_earbuds:{device_support:"unknown",gbuds_support:"unknown"}}};
    assert.equal(policy.findError(device,{placement_left:"IDLE"},"left"),"");
    for (const state of ["WEARING","IN_CASE","DISCONNECTED",undefined])
        assert.ok(policy.findError(device,{placement_left:state},"left"));
    device.features.find_earbuds.gbuds_support="not_implemented";
    assert.ok(policy.findError(device,{placement_left:"IDLE"},"left"));
    assert.equal(policy.findError({},null,"stop"),"");
    assert.ok(policy.findError(device,{placement_left:"IDLE"},"both"));
});
test("connect targets the saved device or a unique paired device, never an arbitrary one",()=>{
    const paired=[{address:"AA"},{address:"BB"}];
    assert.equal(policy.targetAddress("BB",paired),"BB");
    assert.equal(policy.targetAddress("",paired),"");
    assert.equal(policy.targetAddress("",paired.slice(0,1)),"AA");
});
