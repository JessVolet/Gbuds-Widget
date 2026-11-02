.pragma library
function supported(features, key) {
    const f = (features || {})[key] || {};
    return f.device_support === "supported" && f.gbuds_support === "implemented";
}
function available(features, key) {
    const f = (features || {})[key];
    return !!f && f.device_support !== "unsupported" && ["not_implemented","rejected"].indexOf(f.gbuds_support) < 0;
}
function noiseModes(caps) {
    const features = {on:"anc", ambient:"ambient_sound", adaptive:"adaptive_noise"};
    return (caps.noise_control_modes || []).filter(mode => mode === "off" || supported(caps.features, features[mode]));
}
function findError(device, status, side) {
    if (side === "stop") return "";
    if (["left","right"].indexOf(side) < 0) return "Choose one earbud.";
    if (!available((device || {}).features, "find_earbuds")) return "Find is unavailable for this device.";
    return status && status["placement_" + side] === "IDLE" ? "" : "Remove the earbud from your ear and case first.";
}
function targetAddress(saved, paired) {
    return saved || (paired.length === 1 ? paired[0].address || "" : "");
}
function metadata(result) {
    const caps = result.capabilities || {};
    return Object.assign({}, result.device, {features:caps.features || {}, supported_noise_modes:noiseModes(caps)});
}
