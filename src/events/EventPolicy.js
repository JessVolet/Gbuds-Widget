.pragma library
function create(kind, subject, title, detail, count, snapshot, now, severity) {
    return {kind:kind, subject:subject, title:title, detail:detail, waves:count,
        snapshot:snapshot, at:now, severity:severity || "normal"};
}
function detect(previous, next, memory, now) {
    if (!next) return [];
    if (!previous) return [create("connected", "pair", "Galaxy Buds connected", "Ready to listen", 2, next, now, "success")];
    const events = [];
    ["left","right","case"].forEach(part => {
        const old = previous[part], value = next[part];
        if (typeof value !== "number" || value < 0 || value > 100 || typeof old !== "number" || old < 0 || old > 100) return;
        const armed = memory[part] || (memory[part] = {low:true, critical:true});
        if (value >= 25) armed.critical = true;
        if (value >= 55) armed.low = true;
        const level = old > 20 && value <= 20 && armed.critical ? 20 : old > 50 && value <= 50 && armed.low ? 50 : 0;
        if (!level || value >= old) return;
        if (level === 20) { armed.critical = false; armed.low = false; } else armed.low = false;
        events.push(create("battery-" + level, part, "Battery at " + level + "%", label(part) + " · " + value + "%", 3, next, now, level === 20 ? "critical" : "notice"));
    });
    ["left","right"].forEach(side => {
        const key = "placement_" + side;
        if (previous[key] === next[key]) return;
        const states = {
            WEARING:["in-ear","Earbud in ear","is ready",1],
            IN_CASE:["stored","Earbud stored","is in the case",1],
            DISCONNECTED:["disconnected","Earbud disconnected","is unavailable",2],
            IDLE:previous[key] === "IN_CASE" ? ["out-of-case","Earbud removed from case","is out of the case",1] : ["out-of-ear","Earbud removed","is out of ear",1]
        };
        const state = states[next[key]];
        if (state) events.push(create(state[0], side, state[1], label(side) + " " + state[2], state[3], next, now));
    });
    if (next.noise_control && next.noise_control !== previous.noise_control) {
        const modes = {OFF:["Normal mode",1], NOISE_REDUCTION:["Noise cancellation",3], AMBIENT_SOUND:["Ambient sound",2], ADAPTIVE:["Adaptive sound",2]};
        const mode = modes[next.noise_control];
        if (mode) events.push(Object.assign(create("noise-mode","mode",mode[0],"Noise control changed",mode[1],next,now), {mode:next.noise_control}));
    }
    return events.sort((a,b) => (a.severity === "critical" ? -1 : 0) - (b.severity === "critical" ? -1 : 0));
}
function label(part) { return part === "left" ? "Left earbud" : part === "right" ? "Right earbud" : "Case"; }
function channel(event, config) {
    const override = config.advancedNotifications === false ? "default" : config.notificationRules?.[event.kind]?.presentation || config["notify_" + event.kind.replace(/-/g,"_")];
    const value = override && override !== "default" ? override : config.notificationPresentation;
    return ["off","popup","waveup","both"].indexOf(value) >= 0 ? value : "waveup";
}
