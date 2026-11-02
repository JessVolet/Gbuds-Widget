const {test} = require('node:test');
const assert = require('node:assert/strict');
const load = require('./load-module.cjs');
const wave = load('src/motion/WaveTimeline.js');
const config = {count:3, durationMs:1400, lifetimeMs:5000, radiusPx:220};
test('all rings launch from zero at independent 250 ms boundaries', () => {
    for (let i=0;i<3;i++) {
        assert.equal(wave.sample(i*250,i,config).radiusPx,0);
        assert.equal(wave.sample(i*250-1,i,config).opacity,0);
        assert.ok(wave.sample(i*250+1,i,config).radiusPx < 1);
        assert.ok(wave.sample(i*250+1,i,config).opacity > 0);
    }
});
test('rings share radial speed and final radius rather than preset sizes', () => {
    for (let i=0;i<3;i++) assert.equal(wave.sample(i*250+700,i,config).radiusPx,110);
});
test('repeat starts one second after the final ring completes', () => {
    for (const t of [1900,2100,2500,2899,2900]) assert.equal(wave.sample(t,0,config).radiusPx,0);
    assert.ok(wave.sample(2901,0,config).radiusPx < 1);
});
test('a partial final sequence is never launched', () => {
    assert.equal(wave.sample(2901,0,{...config,lifetimeMs:3000}).radiusPx,0);
    assert.equal(wave.sample(5000,1,config).opacity,0);
});
