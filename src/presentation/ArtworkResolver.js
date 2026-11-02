.pragma library
function source(device, part, artwork) {
    if (artwork === "svg" || part === "case") return "";
    const models = {"SM-R630":"Buds3Pro", "SM-R530":"Buds3", "SM-R420":"Buds3Fe", "SM-R400N":"BudsFe"};
    const model = models[(device || {}).model_code];
    if (!model) return "";
    const color = /white/i.test(device.color || "") ? "White" : model === "BudsFe" ? "Graphite" : "Silver";
    return "../../assets/device/" + model + color + "-" + (part === "left" ? 0 : 1) + ".png";
}

function notificationParts(event, artwork) {
    if (event.subject === "mode") return artwork === "render" ? ["left","right"] : [];
    if (event.subject === "case" || event.kind === "stored") return ["case"];
    if (["left","right"].indexOf(event.subject)>=0) return [event.subject];
    const status=event.snapshot || {};
    return status.placement_left === "IN_CASE" && status.placement_right === "IN_CASE" ? ["case"] : ["left","right"];
}
