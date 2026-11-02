const {test}=require('node:test');
const assert=require('node:assert/strict');
const load=require('./load-module.cjs');
const events=load('src/events/EventPolicy.js');
const schema=load('src/config/Schema.js');
const before={left:60,right:80,case:90,placement_left:'WEARING',placement_right:'WEARING',noise_control:'OFF'};
test('independent battery, placement and noise events preserve their snapshots',()=>{
    const next={...before,left:18,placement_left:'IDLE',noise_control:'NOISE_REDUCTION'};
    const result=events.detect(before,next,{},1000);
    assert.deepEqual(Array.from(result,e=>e.kind),['battery-20','out-of-ear','noise-mode']);
    assert.equal(result[0].at,1000);
    assert.equal(result[1].subject,'left');
});
test('thresholds rearm at inclusive hysteresis boundaries',()=>{
    const state={};
    assert.equal(events.detect(before,{...before,left:20},state,0).filter(e=>e.kind==='battery-20').length,1);
    assert.equal(events.detect({...before,left:21},{...before,left:20},state,1).filter(e=>e.kind==='battery-20').length,0);
    events.detect({...before,left:20},{...before,left:25},state,2);
    assert.equal(events.detect({...before,left:25},{...before,left:20},state,3).filter(e=>e.kind==='battery-20').length,1);
});
test('initial telemetry does not fabricate battery crossings',()=>{
    assert.deepEqual(Array.from(events.detect(null,{...before,left:10},{},0),e=>e.kind),['connected']);
});
test('schema preserves zero/false and explicit legacy layouts',()=>{
    assert.equal(schema.resolve({desktopGap:0,desktopShowNoise:false}).desktopGap,0);
    assert.equal(schema.resolve({desktopGap:0,desktopShowNoise:false}).desktopShowNoise,false);
    assert.equal(schema.resolve({desktopLayout:'full'}).desktopPreset,'detailed');
    assert.equal(schema.resolve({}).desktopPreset,'compact');
    assert.equal(schema.resolve({desktopOfflinePolicy:'connect'},true).desktopOfflinePolicy,'hide');
});
test('event channels follow the global style with explicit overrides',()=>{
    assert.equal(events.channel({kind:'noise-mode'},{notificationPresentation:'waveup'}),'waveup');
    assert.equal(events.channel({kind:'noise-mode'},{notificationPresentation:'both',notify_noise_mode:'off'}),'off');
});

const layout=load('src/presentation/ScreenPlacement.js');
test('case positioning and minimum width follow order and independent sizes',()=>{
    const config=schema.resolve({desktopCaseSize:80,desktopAlignment:'left',desktopTextSize:12});
    const parts=['case','left','right'];
    assert.equal(layout.partCenter(config,parts,'case',400),layout.partWidth(config,'case')/2);
    assert.ok(layout.groupWidth(config,parts)>layout.groupWidth(schema.resolve({}),parts));
    assert.equal(schema.resolve({desktopEarbudSize:72}).desktopCaseSize,72);
});
