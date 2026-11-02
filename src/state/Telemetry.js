.pragma library
function normalize(input) {
    if (!input || typeof input !== "object" || !("left" in input) || !("right" in input)) return null;
    const next=Object.assign({},input);
    ["left","right","case"].forEach(part=>{
        const value=input[part];
        next[part]=typeof value === "number" && Number.isFinite(value) && value>=0 && value<=100 ? value : null;
    });
    ["left","right"].forEach(side=>{
        const key="placement_"+side;
        next[key]=["IDLE","WEARING","IN_CASE","DISCONNECTED"].indexOf(input[key])>=0 ? input[key] : "UNKNOWN";
    });
    return next;
}
