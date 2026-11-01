.pragma library

function event(kind, subject, title, detail, severity, waves, snapshot, extras) {
    var value = {
        kind: kind, subject: subject || "pair", title: title, detail: detail || "",
        severity: severity || "normal", waves: waves || 1,
        at: Date.now(), snapshot: snapshot || null
    };
    if (extras) Object.keys(extras).forEach(function (key) { value[key] = extras[key]; });
    return value;
}

function label(part) {
    return part === "left" ? "Left earbud" : part === "right" ? "Right earbud" : "Case";
}

function batteryEvents(previous, next, batteryState) {
    var result = [];
    var state = batteryState || {};
    ["left", "right", "case"].forEach(function (part) {
        var value = next[part];
        var old = previous && previous[part];
        if (typeof value !== "number" || value < 0 || value > 100 || typeof old !== "number" || old < 0 || old > 100)
            return;
        if (!state[part]) state[part] = { 20: true, 50: true };
        if (value > 25) state[part][20] = true;
        if (value > 55) state[part][50] = true;
        if (value >= old) return;
        var threshold = old > 20 && value <= 20 && state[part][20] ? 20 : old > 50 && value <= 50 && state[part][50] ? 50 : 0;
        if (!threshold) return;
        state[part][threshold] = false;
        if (threshold === 20) state[part][50] = false;
        result.push(event(threshold === 20 ? "battery-20" : "battery-50", part,
            threshold + "% battery", label(part) + " · " + value + "%",
            threshold === 20 ? "critical" : "notice", 3, next,
            { level: threshold, value: value, component: part }));
    });
    return result;
}

function detect(previous, next, device, wasDisconnected, batteryState) {
    if (!next || typeof next !== "object") return [];
    if (!previous || wasDisconnected) {
        return [event("connected", "pair", "Galaxy Buds connected", (device && (device.name || device.model)) || "Ready to listen", "success", 2, next)];
    }

    var result = batteryEvents(previous, next, batteryState);
    var lostCoupling = previous.is_coupled === true && next.is_coupled === false;
    if (lostCoupling) {
        result.push(event("disconnected", "pair", "Galaxy Buds disconnected", "Earbuds are no longer coupled", "warning", 2, previous));
    }
    if (previous.is_coupled === false && next.is_coupled === true)
        result.push(event("connected", "pair", "Galaxy Buds connected", "Earbuds are coupled", "success", 2, next));

    [{ key: "placement_left", side: "left" }, { key: "placement_right", side: "right" }].forEach(function (entry) {
        if (lostCoupling || previous[entry.key] === next[entry.key]) return;
        var state = next[entry.key], side = entry.side;
        if (state === "IN_CASE") result.push(event("stored", side, "Earbud stored", label(side) + " is in the case", "normal", 1, next));
        else if (state === "IDLE") {
            var removedFromCase = previous[entry.key] === "IN_CASE";
            result.push(event(removedFromCase ? "out-of-case" : "out-of-ear", side,
                removedFromCase ? "Earbud removed from case" : "Earbud removed",
                removedFromCase ? label(side) + " is out of the case" : label(side) + " is out of ear",
                "normal", 1, next));
        }
        else if (state === "WEARING") result.push(event("in-ear", side, "Earbud in ear", label(side) + " is ready", "success", 1, next));
        else if (state === "DISCONNECTED") result.push(event("disconnected", side, "Earbud disconnected", label(side) + " is unavailable", "warning", 2, previous));
    });

    if (previous.noise_control !== next.noise_control && next.noise_control) {
        var mode = next.noise_control;
        var title = mode === "NOISE_REDUCTION" ? "Noise cancellation" : mode === "AMBIENT_SOUND" ? "Ambient sound" : mode === "ADAPTIVE" ? "Adaptive sound" : "Normal mode";
        var waves = mode === "NOISE_REDUCTION" ? 3 : mode === "AMBIENT_SOUND" ? 2 : mode === "ADAPTIVE" ? 2 : 1;
        result.push(event("noise-mode", "mode", title, "Noise control changed", "normal", waves, next, { mode: mode }));
    }
    return prioritize(coalesceRelatedEvents(result));
}

function priority(value) {
    if (value.kind === "battery-20" || value.kind === "critical-battery") return 0;
    if (value.kind === "disconnected") return 1;
    if (value.kind === "connected") return 2;
    if (value.kind === "out-of-ear" || value.kind === "out-of-case" || value.kind === "in-ear" || value.kind === "stored") return 3;
    if (value.kind === "noise-mode") return 4;
    if (value.kind === "battery-50" || value.kind === "low-battery") return 5;
    if (value.kind === "out-of-ear-reminder") return 6;
    return 7;
}

function prioritize(events) { return events.sort(function (a, b) { return priority(a) - priority(b); }); }

function coalesceRelatedEvents(events) {
    var result = [], consumed = {};
    events.forEach(function (value, index) {
        if (consumed[index]) return;
        var pairedKind = value.kind === "battery-50" || value.kind === "battery-20" || value.kind === "disconnected";
        if (!pairedKind || (value.subject !== "left" && value.subject !== "right")) { result.push(value); return; }
        var pair = [value];
        events.forEach(function (candidate, candidateIndex) {
            if (candidateIndex > index && !consumed[candidateIndex] && candidate.kind === value.kind &&
                (candidate.subject === "left" || candidate.subject === "right") && candidate.subject !== value.subject) {
                pair.push(candidate); consumed[candidateIndex] = true;
            }
        });
        if (pair.length === 1) { result.push(value); return; }
        if (value.kind === "disconnected") {
            result.push(event("disconnected", "pair", "Galaxy Buds disconnected", "Both earbuds are unavailable", "warning", 2, value.snapshot));
            return;
        }
        var values = {};
        pair.forEach(function (entry) { values[entry.subject] = entry.value; });
        var combined = event(value.kind, "pair", value.title,
            "L " + values.left + "% · R " + values.right + "%", value.severity, 3, value.snapshot,
            { level: value.level, parts: values });
        result.push(combined);
    });
    return result;
}

function batteryCrossings(previous, next, state) { return prioritize(coalesceRelatedEvents(batteryEvents(previous, next, state))); }

function channelsFor(eventValue, config) {
    var key = "notify_" + String(eventValue.kind || "").replace(/-/g, "_");
    var value = config && config[key] !== undefined ? config[key] : "default";
    if (value === "default") value = config && config.notificationPresentation || "popup";
    if (["off", "popup", "waveup", "both"].indexOf(value) < 0) value = "popup";
    return value === "off" ? "off" : value;
}

function waveCount(eventValue) {
    if (eventValue.waves) return Math.max(1, Math.min(3, Number(eventValue.waves)));
    if (eventValue.kind === "battery-50" || eventValue.kind === "battery-20") return 3;
    if (eventValue.kind === "disconnected") return 2;
    if (eventValue.kind === "noise-mode") return eventValue.mode === "NOISE_REDUCTION" ? 3 : eventValue.mode === "AMBIENT_SOUND" ? 2 : 1;
    return 1;
}

function waveTone(eventValue) {
    if (eventValue.kind === "battery-20" || eventValue.kind === "critical-battery") return "critical";
    if (eventValue.kind === "battery-50" || eventValue.kind === "low-battery") return "warning";
    return eventValue.severity || "normal";
}
