pragma Singleton
import QtQuick
QtObject {
property var values: ({
telemetry: {phase: "connected",status: {left:94,right:92,case:59,placement_left:"WEARING",placement_right:"IDLE",noise_control:"NOISE_REDUCTION"}},
device:{name:"Test Buds",model_code:"SM-R530",supported_noise_modes:["off","on","ambient"]},
commandState:{busy:false}
})
signal globalVarChanged(string pluginId, string varName)
function setGlobalVar(pid,name,value) { values=Object.assign({},values,{[name]:value}); globalVarChanged(pid,name); }
function getGlobalVar(pid,name,fallback) { return values[name] || fallback; }
function savePluginData(pid,name,value) {}
}
