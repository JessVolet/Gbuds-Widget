const {test}=require('node:test');
const assert=require('node:assert/strict');
const load=require('./load-module.cjs');
const Policy=load('src/device/Policy.js');
const registry=load('src/device/CommandRegistry.js',{Policy});
const ctx={connected:true,device:{features:{find_earbuds:{device_support:'unknown',gbuds_support:'unknown'}},supported_noise_modes:['off','on']},status:{placement_left:'IDLE',placement_right:'WEARING'}};
test('registry rejects shell-shaped, unsupported and malformed actions',()=>{
    assert.ok(registry.validate('exec',['rm'],ctx));
    assert.ok(registry.validate('anc',['ambient'],ctx));
    assert.ok(registry.validate('anc',[{}],ctx));
    assert.ok(registry.validate('connect',['arg'],ctx));
    assert.ok(registry.validate('eq',['normal'],ctx));
});
test('find gates actual placement while Stop remains available during uncertainty',()=>{
    assert.equal(registry.validate('find',['left'],ctx),'');
    assert.ok(registry.validate('find',['right'],ctx));
    assert.equal(registry.validate('find',['stop'],{...ctx,connected:false}),'');
});
test('the process boundary is argv, including paths with spaces',()=>{
    assert.deepEqual(Array.from(registry.argv('/tmp/bin with spaces','AA','find',['stop'])),['/tmp/bin with spaces','--mac','AA','--json','find','stop']);
});

const telemetry=load('src/state/Telemetry.js');
test('invalid readings stay unknown rather than showing zero or out-of-range batteries',()=>{
    const state=telemetry.normalize({left:-1,right:150,case:0,placement_left:'invalid'});
    assert.equal(state.left,null);
    assert.equal(state.right,null);
    assert.equal(state.case,0);
    assert.equal(state.placement_left,'UNKNOWN');
    assert.equal(telemetry.normalize({error:'offline'}),null);
});
