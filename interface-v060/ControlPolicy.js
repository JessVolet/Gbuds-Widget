.pragma library

function supported(features, key) {
    var feature = (features || {})[key] || {};
    return feature.device_support === "supported" && feature.gbuds_support === "implemented";
}

function available(features, key) {
    var feature = (features || {})[key];
    return !!feature && feature.device_support !== "unsupported" && ["not_implemented", "rejected"].indexOf(feature.gbuds_support) < 0;
}

function noiseModes(capabilities) {
    var keys = {on:"anc", ambient:"ambient_sound", adaptive:"adaptive_noise"};
    return (capabilities.noise_control_modes || []).filter(function(mode) {
        return mode === "off" || (keys[mode] && supported(capabilities.features, keys[mode]));
    });
}

function findError(device, status, side) {
    if (side === "stop") return "";
    if (side !== "left" && side !== "right") return "Choose one earbud.";
    if (!available((device || {}).features, "find_earbuds"))
        return "Find earbuds is not available for this model.";
    if (!status || status["placement_" + side] !== "IDLE")
        return "Remove the earbud from your ear and case before ringing it.";
    return "";
}

function targetAddress(saved, paired) {
    if (saved) return saved;
    return paired.length === 1 ? paired[0].address || "" : "";
}
