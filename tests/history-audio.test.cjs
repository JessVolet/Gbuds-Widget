const {test}=require('node:test');
const assert=require('node:assert/strict');
const load=require('./load-module.cjs');
const history=load('src/device/History.js'), audio=load('src/audio/AudioPolicy.js');
test('command history is bounded, sanitized and updates only its matching job',()=>{
 let entries=[];
 for(let i=0;i<100;i++) entries=history.begin(entries,{command:'anc',argv:['/home/user/gbuds','--mac','AA:BB:CC:DD:EE:FF','anc','on']},i,String(i));
 assert.equal(entries.length,80);assert.ok(!entries[0].argv.includes('AA:BB'));assert.ok(!entries[0].argv.includes('/home'));
 entries=history.finish(entries,'99',{error:'Timeout',uncertain:true},false,120);
 assert.equal(entries[0].status,'Uncertain');assert.equal(entries[0].durationMs,21);assert.equal(entries[1].status,'Pending');
});
test('audio selection requires unique exact Bluetooth identity, never the default output',()=>{
 const speaker={name:'speakers',audio:{volume:.5},isSink:true};
 const buds={name:'bluez_output.AA_BB_CC_DD_EE_FF.1',audio:{volume:.3},isSink:true};
 assert.equal(audio.output([speaker,buds],'AA:BB:CC:DD:EE:FF'),buds);
 assert.equal(audio.output([speaker],''),null);assert.equal(audio.output([buds,{...buds}], 'AA:BB:CC:DD:EE:FF'),null);
});
