const {test}=require('node:test');
const assert=require('node:assert/strict');
const load=require('./load-module.cjs');
const preferences=load('src/config/NotificationPreferences.js');
const schema=load('src/config/Schema.js');
const placement=load('src/presentation/ScreenPlacement.js');
test('centered noise popup overrides global waves without changing other events',()=>{
 const config=schema.resolve({notificationPresentation:'waveup',advancedNotifications:true,notificationRules:{'noise-mode':{presentation:'popup',position:'center',popupDuration:4}}});
 const noise=preferences.resolve(config,{kind:'noise-mode',subject:'mode'});
 assert.equal(noise.presentation,'popup');assert.equal(noise.popupPosition,'center');assert.equal(noise.dismissTimeout,4);
 assert.equal(preferences.resolve(config,{kind:'out-of-ear',subject:'left'}).presentation,'waveup');
 assert.equal(preferences.resolve({...config,advancedNotifications:false},{kind:'noise-mode',subject:'mode'}).presentation,'waveup');
});
test('legacy overrides migrate, resetting removes only the selected exception',()=>{
 const config=schema.resolve({notificationPresentation:'popup',notify_noise_mode:'waveup'});
 assert.equal(config.advancedNotifications,true);
 assert.equal(preferences.resolve(config,{kind:'noise-mode',subject:'mode'}).presentation,'waveup');
 const next=preferences.update({'noise-mode':{position:'center',presentation:'popup'}},'noise-mode','position','default');
 assert.equal(next['noise-mode'].position,undefined);assert.equal(next['noise-mode'].presentation,'popup');
});
test('overlapping anchors occupy separate deterministic screen rectangles',()=>{
 const first=placement.popupRect('center',1000,800,18,[]);
 const next=placement.popupRect('center-right',1000,800,18,[first]);
 assert.ok(next);assert.ok(next.y>=first.y+first.height || next.y+next.height<=first.y || next.x>=first.x+first.width || next.x+next.width<=first.x);
 assert.equal(placement.popupRect('center',200,200,18,[{x:18,y:18,width:164,height:164}]),null);
});
