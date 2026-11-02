.pragma library
var events = [
    {key:"connected", label:"Connected", icon:"bluetooth_connected"},
    {key:"disconnected", label:"Disconnected", icon:"bluetooth_disabled"},
    {key:"out-of-ear", label:"Removed from ear", icon:"earbuds"},
    {key:"in-ear", label:"Back in ear", icon:"hearing"},
    {key:"out-of-case", label:"Removed from case", icon:"earbuds"},
    {key:"stored", label:"Stored in case", icon:"inventory_2"},
    {key:"noise-mode", label:"Noise mode changed", icon:"noise_control_on"},
    {key:"battery-50", label:"Battery at 50%", icon:"battery_4_bar"},
    {key:"battery-20", label:"Battery at 20%", icon:"battery_alert"},
    {key:"out-of-ear-reminder", label:"Out-of-ear reminder", icon:"timer"}
];
var positions = ["top-left","top-center","top-right","center-left","center","center-right","bottom-left","bottom-center","bottom-right"];
function clamp(value, fallback, min, max) {
    return value !== null && value !== "" && Number.isFinite(Number(value)) ? Math.max(min,Math.min(max,Number(value))) : fallback;
}
function rule(config, kind) {
    const value = config.notificationRules?.[kind];
    return value && typeof value === "object" && !Array.isArray(value) ? value : {};
}
function resolve(config, event) {
    const result = Object.assign({},config);
    const enabled = config.advancedNotifications !== false;
    const custom = enabled ? rule(config,event.kind) : {};
    const legacy = enabled ? config["notify_"+event.kind.replace(/-/g,"_")] : "default";
    const channel = custom.presentation && custom.presentation !== "default" ? custom.presentation : legacy && legacy !== "default" ? legacy : config.notificationPresentation;
    result.presentation = ["off","popup","waveup","both"].indexOf(channel)>=0 ? channel : "waveup";
    const position = custom.position || config.notifyPopupPosition || "match";
    const side = config.notifyMatchPosition && ["left","right"].indexOf(event.subject)>=0 ? event.subject : config.notifyFixedSide || "right";
    result.popupPosition = positions.indexOf(position)>=0 ? position : config.notifyVerticalPosition+"-"+side;
    result.notifyScreen = custom.screen && custom.screen !== "default" ? custom.screen : config.notifyScreen;
    result.dismissTimeout = clamp(custom.popupDuration,config.dismissTimeout,2,15);
    result.notifyWaveDuration = clamp(custom.waveDuration,config.notifyWaveDuration,3,15);
    result.waveRadiusPx = clamp(custom.radius,config.waveRadiusPx,80,400);
    result.waveStrokePx = clamp(custom.stroke,config.waveStrokePx,1,12);
    result.notificationArtwork = ["svg","render","auto"].indexOf(custom.artwork)>=0 ? custom.artwork : config.notificationArtwork;
    result.waveOrigin = ["left","right","both"].indexOf(custom.waveOrigin)>=0 ? custom.waveOrigin : ["left","right","both"].indexOf(config.notifyWaveOrigin)>=0 ? config.notifyWaveOrigin : ["pair","mode"].indexOf(event.subject)>=0 ? "both" : side;
    if (["top","bottom"].indexOf(custom.waveEdge)>=0) result.notifyVerticalPosition=custom.waveEdge;
    return result;
}
function update(rules, kind, key, value) {
    const next=Object.assign({},rules), entry=Object.assign({},next[kind] || {});
    if (value === "default" || value === null || value === "") delete entry[key]; else entry[key]=value;
    if (Object.keys(entry).length) next[kind]=entry; else delete next[kind];
    return next;
}
function summary(config, kind) {
    const custom=Object.keys(rule(config,kind)).length>0 || (config["notify_"+kind.replace(/-/g,"_")] && config["notify_"+kind.replace(/-/g,"_")]!=="default");
    const effective=resolve(config,{kind:kind,subject:"pair"});
    const label={off:"Off",popup:"Popup",waveup:"Waveups",both:"Both"}[effective.presentation];
    return (config.advancedNotifications && custom ? "Custom" : "Default")+" · "+label+(effective.presentation==="popup" && effective.popupPosition==="center" ? " · Center" : "");
}
