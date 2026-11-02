.pragma library
function safe(value) {
    return String(value || "").replace(/(?:[0-9a-f]{2}:){5}[0-9a-f]{2}/gi,"[device]").replace(/\/(?:home|run\/user)\/[^\s"']+/g,"[private path]").slice(0,1200);
}
function begin(entries, job, now, id) {
    const argv=(job.argv || []).map((arg,index)=>index===0 ? String(arg).split("/").pop() : safe(arg));
    return [{id:id,command:job.command || (argv.indexOf("watch")>=0 ? "watch" : "capabilities"),argv:argv.join(" "),at:now,durationMs:0,status:"Pending",detail:""}].concat(entries).slice(0,80);
}
function finish(entries, id, result, success, now) {
    return entries.map(entry=>entry.id!==id ? entry : Object.assign({},entry,{durationMs:Math.max(0,now-entry.at),status:result.cancelled ? "Stopped" : success ? "Succeeded" : result.uncertain ? "Uncertain" : "Failed",detail:safe(result.error || (success ? "Completed" : "The command could not be completed."))}));
}
