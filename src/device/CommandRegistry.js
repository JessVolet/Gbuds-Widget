.pragma library
.import "Policy.js" as Policy
var commands = {
    connect: {args:[], online:false}, disconnect:{args:[], online:true}, battery:{args:[], online:true},
    anc:{args:["off","on","ambient","adaptive"], online:true},
    find:{args:["left","right","stop"], online:true},
    touchpad:{args:["lock","unlock"], feature:"touchpad", online:true},
    eq:{args:["normal","bass","soft","dynamic","clear","treble"], feature:"equalizer", online:true},
    "ambient-volume":{numeric:true, feature:"ambient_volume", online:true},
    "voice-detect":{args:["on","off"], feature:"voice_detect", online:true},
    lights:{args:["off","steady","fade","blink"], feature:"blade_lights", online:true}
};
function validate(command, args, context) {
    const spec = commands[command];
    if (!spec || !Array.isArray(args) || args.some(arg => typeof arg !== "string")) return "Invalid command.";
    const stopping = command === "find" && args[0] === "stop";
    if (spec.online && !context.connected && !stopping) return "Connect Galaxy Buds first.";
    if (spec.numeric) {
        const max = ((context.device.features || {}).ambient_volume || {}).max_level || 0;
        if (args.length !== 1 || !/^\d+$/.test(args[0]) || Number(args[0]) > max) return "Invalid amplification level.";
    } else if (spec.args.length === 0 ? args.length !== 0 : args.length !== 1 || spec.args.indexOf(args[0]) < 0)
        return "Invalid command arguments.";
    if (spec.feature && !Policy.available(context.device.features, spec.feature)) return "This control is unavailable.";
    if (command === "anc" && (context.device.supported_noise_modes || []).indexOf(args[0]) < 0) return "This noise mode is unavailable.";
    if (command === "find") return Policy.findError(context.device, context.status, args[0]);
    return "";
}
function argv(executable, target, command, args) {
    return [executable, "--mac", target, "--json", command].concat(args);
}
