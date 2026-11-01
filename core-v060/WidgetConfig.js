.pragma library

var SCHEMA_VERSION = 1;

var DEFAULTS = {
    widgetConfigVersion: SCHEMA_VERSION,
    desktopPreset: "compact",
    desktopOfflinePolicy: "hide",
    desktopArtwork: "svg",
    desktopShowName: true,
    desktopShowCase: true,
    desktopShowBattery: true,
    desktopShowNoise: true,
    desktopShowDisconnect: true,
    desktopHorizontal: true,
    desktopEarOrder: "left-case-right",
    desktopGap: 8,
    desktopPadding: 10,
    desktopEarbudSize: 48,
    desktopNoiseSize: 36,
    desktopVerticalOffset: 0,
    desktopBackgroundMode: "theme",
    desktopBackgroundOpacity: 94,
    desktopShowBorder: true,
    desktopLockControls: false,
    desktopLockAnimations: false,
    desktopSyncScreens: true,
    desktopScreenPreferences: ["all"],
    desktopScale: 1
};

function numberInRange(value, fallback, minimum, maximum) {
    var number = Number(value);
    return isFinite(number) ? Math.max(minimum, Math.min(maximum, number)) : fallback;
}

function resolve(instanceConfig, globalConfig, lockScreen) {
    var source = instanceConfig && typeof instanceConfig === "object" ? instanceConfig : {};
    var globalValues = globalConfig && typeof globalConfig === "object" ? globalConfig : {};
    var result = {};
    Object.keys(DEFAULTS).forEach(function (key) {
        if (Object.prototype.hasOwnProperty.call(source, key))
            result[key] = source[key];
        else if (["desktopPreset", "desktopOfflinePolicy", "desktopScreenPreferences", "desktopSyncScreens"].indexOf(key) < 0 &&
                 !Object.prototype.hasOwnProperty.call(source, "widgetConfigVersion") && Object.prototype.hasOwnProperty.call(globalValues, key))
            result[key] = globalValues[key];
        else
            result[key] = DEFAULTS[key];
    });

    // Migrate explicit legacy choices only. An absent legacy key means a new compact instance.
    if (!Object.prototype.hasOwnProperty.call(source, "desktopPreset") &&
        Object.prototype.hasOwnProperty.call(source, "desktopLayout"))
        result.desktopPreset = source.desktopLayout === "full" ? "detailed" : "compact";
    if (!Object.prototype.hasOwnProperty.call(source, "desktopOfflinePolicy") && source.showConnectButton === true)
        result.desktopOfflinePolicy = "connect";

    if (["compact", "minimal", "detailed", "custom"].indexOf(result.desktopPreset) < 0)
        result.desktopPreset = "compact";
    if (["hide", "connect", "status"].indexOf(result.desktopOfflinePolicy) < 0)
        result.desktopOfflinePolicy = "hide";
    if (["svg", "render", "auto"].indexOf(result.desktopArtwork) < 0)
        result.desktopArtwork = "svg";
    if (["left-case-right", "right-case-left", "case-left-right", "left-right-case", "right-left-case", "case-right-left"].indexOf(result.desktopEarOrder) < 0)
        result.desktopEarOrder = "left-case-right";

    result.desktopGap = numberInRange(result.desktopGap, DEFAULTS.desktopGap, 0, 48);
    result.desktopPadding = numberInRange(result.desktopPadding, DEFAULTS.desktopPadding, 0, 40);
    result.desktopEarbudSize = numberInRange(result.desktopEarbudSize, DEFAULTS.desktopEarbudSize, 20, 128);
    result.desktopNoiseSize = numberInRange(result.desktopNoiseSize, DEFAULTS.desktopNoiseSize, 16, 96);
    result.desktopVerticalOffset = numberInRange(result.desktopVerticalOffset, 0, -32, 32);
    result.desktopBackgroundOpacity = numberInRange(result.desktopBackgroundOpacity, 94, 0, 100);
    if (["theme", "transparent", "custom"].indexOf(result.desktopBackgroundMode) < 0)
        result.desktopBackgroundMode = "theme";
    result.desktopScale = numberInRange(result.desktopScale, 1, 0.6, 1.8);
    if (!Array.isArray(result.desktopScreenPreferences) || result.desktopScreenPreferences.length === 0)
        result.desktopScreenPreferences = ["all"];

    if (lockScreen) {
        result.desktopOfflinePolicy = "hide";
        if (source.desktopLockControls !== true)
            result.desktopShowDisconnect = false;
    }
    result.widgetConfigVersion = SCHEMA_VERSION;
    return result;
}

function presetBlocks(preset, config) {
    var blocks;
    if (preset === "minimal")
        blocks = ["earbuds", "battery"];
    else if (preset === "detailed")
        blocks = ["name", "earbuds", "case", "battery", "noise", "disconnect"];
    else
        blocks = ["name", "earbuds", "case", "battery", "noise", "disconnect"];
    if (preset === "custom") {
        if (config.desktopShowName !== true) blocks = blocks.filter(function (x) { return x !== "name"; });
        if (config.desktopShowCase !== true) blocks = blocks.filter(function (x) { return x !== "case"; });
        if (config.desktopShowBattery !== true) blocks = blocks.filter(function (x) { return x !== "battery"; });
        if (config.desktopShowNoise !== true) blocks = blocks.filter(function (x) { return x !== "noise"; });
        if (config.desktopShowDisconnect !== true) blocks = blocks.filter(function (x) { return x !== "disconnect"; });
    }
    return blocks;
}
