.pragma library
var defaults = {
    schemaVersion: 2, panelArtwork:"auto", desktopPreset: "compact", desktopOfflinePolicy: "hide", desktopArtwork: "svg",
    desktopShowName: true, desktopShowCase: true, desktopShowBattery: true, desktopShowNoise: true,
    desktopShowDisconnect: true, desktopHorizontal: true, desktopEarOrder: "left-case-right",
    desktopBlockOrder: "name,parts,noise,disconnect", desktopGap: 8, desktopPadding: 12,
    desktopEarbudSize: 48, desktopCaseSize:48, desktopTextSize:11, desktopNameSize:14, desktopAlignment:"center", desktopNoiseSize: 36, desktopVerticalOffset: 0,
    desktopBackgroundMode: "theme", desktopBackgroundOpacity: 94, desktopShowBorder: true,
    desktopLockControls: false, desktopLockAnimations:false, desktopLockAnimations: false, displayPreferences: ["all"],
    syncPositionAcrossScreens: true, notificationsEnabled: true, notificationPresentation: "popup",
    notificationArtwork: "auto", dismissTimeout: 5, notifyWaveDuration: 5, waveRadiusPx: 220,
    waveStrokePx: 4, notifyMatchPosition: true, notifyVerticalPosition: "bottom", notifyFixedSide: "right",
    notifyMargin: 18, notifyScreen: "active", notifyReduceMotion: false, notifyIdleReminder: false,
    notifyIdleInterval: 60, pillMode: "compact", showModeIcon: true, showBatteryPercentages: false,
    warnOutOfEar: true, batteryIndicatorStyle: "clean", iconColorMode:"auto", customColor:"", idleColorMode:"auto", caseColorMode:"auto", gbudsCommand: "gbuds", targetMac: ""
};
function number(value, fallback, min, max) {
    const n = Number(value);
    return Number.isFinite(n) ? Math.max(min, Math.min(max, n)) : fallback;
}
function resolve(input, locked) {
    const source = input || {};
    const result = Object.assign({}, defaults, source);
    if (source.desktopPreset === undefined && source.desktopLayout !== undefined)
        result.desktopPreset = source.desktopLayout === "full" ? "detailed" : "compact";
    if (source.desktopOfflinePolicy === undefined && source.showConnectButton === true)
        result.desktopOfflinePolicy = "connect";
    if (source.waveRadiusPx === undefined && source.notifyWaveSize !== undefined)
        result.waveRadiusPx = number(source.notifyWaveSize, 220, 80, 400);
    if (source.notificationsEnabled === undefined && source.showStatusCards === false)
        result.notificationsEnabled = false;
    const ranges = {desktopGap:[0,48], desktopPadding:[0,40], desktopEarbudSize:[20,128],
        desktopCaseSize:[20,128], desktopTextSize:[9,24], desktopNameSize:[12,28], desktopNoiseSize:[16,96], desktopVerticalOffset:[-32,32], desktopBackgroundOpacity:[0,100],
        waveRadiusPx:[80,400], waveStrokePx:[1,12], notifyMargin:[0,100], dismissTimeout:[2,15],
        notifyWaveDuration:[3,15], notifyIdleInterval:[15,3600]};
    Object.keys(ranges).forEach(key => result[key] = number(result[key], defaults[key], ranges[key][0], ranges[key][1]));
    if (["compact","minimal","detailed","custom"].indexOf(result.desktopPreset) < 0) result.desktopPreset = "compact";
    if (["hide","connect","status"].indexOf(result.desktopOfflinePolicy) < 0) result.desktopOfflinePolicy = "hide";
    if (result.desktopPreset === "detailed" && source.desktopEarbudSize === undefined) result.desktopEarbudSize = 72;
    if (source.desktopCaseSize === undefined) result.desktopCaseSize=result.desktopEarbudSize;
    if (["left","center","right"].indexOf(result.desktopAlignment)<0) result.desktopAlignment="center";
    if (locked) { result.desktopOfflinePolicy = "hide"; result.desktopShowDisconnect = false; }
    result.schemaVersion = 2;
    return result;
}
function blocks(config) {
    const keys = config.desktopPreset === "minimal" ? ["parts"] : String(config.desktopBlockOrder).split(",");
    const enabled = {name:config.desktopShowName, parts:true, noise:config.desktopShowNoise, disconnect:config.desktopShowDisconnect};
    return keys.filter((key, i) => enabled[key] !== false && enabled[key] !== undefined && keys.indexOf(key) === i);
}
