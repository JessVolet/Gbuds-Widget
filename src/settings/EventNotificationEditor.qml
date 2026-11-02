import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import "../config/NotificationPreferences.js" as Rules

Column {
    id:root
    required property var preferences
    property string kind:"noise-mode"
    property string subject:"mode"
    signal preview(var event)
    spacing:6
    readonly property var config:preferences.value
    readonly property var entry:Rules.rule(config,kind)
    readonly property var effective:Rules.resolve(config,{kind:kind,subject:subject})
    function options(values) { return [{value:"default",label:"Use default"}].concat(values.map(pair=>({value:pair[0],label:pair[1]}))); }
    function edit(key,value) { preferences.update("notificationRules",Rules.update(config.notificationRules,kind,key,value)); }
    Repeater {
        model:[
            {kind:"select",key:"presentation",label:"Presentation",icon:"notifications",options:root.options([["off","Off"],["popup","Popup"],["waveup","Waveup"],["both","Both"]])},
            {kind:"position",inherit:true,key:"position",label:"Popup position",icon:"open_with",options:root.options([["match","Match earbud"]].concat(Rules.positions.map(p=>[p,p.replace(/-/g," ")])))},
            {kind:"select",key:"waveOrigin",label:"Wave origin",icon:"waves",options:root.options([["match","Match earbud"],["left","Left"],["right","Right"],["both","Both sides"]])},
            {kind:"select",key:"waveEdge",label:"Wave edge",icon:"vertical_align_bottom",options:root.options([["top","Top"],["bottom","Bottom"]])},
            {kind:"select",key:"screen",label:"Display",icon:"monitor",options:root.options([["active","Active display"],["primary","Primary display"]].concat(Quickshell.screens.map(s=>[s.name,s.name])))},
            {kind:"select",key:"popupDuration",label:"Popup duration",icon:"timer",options:root.options([2,3,4,5,6,8,10,15].map(v=>[v,v+" seconds"]))},
            {kind:"select",key:"waveDuration",label:"Wave duration",icon:"timer",options:root.options([3,4,5,6,8,10,15].map(v=>[v,v+" seconds"]))},
            {kind:"select",key:"radius",label:"Wave reach",icon:"waves",options:root.options([80,120,180,220,280,350,400].map(v=>[v,v+" px"]))},
            {kind:"select",key:"stroke",label:"Wave stroke",icon:"line_weight",options:root.options([1,2,3,4,6,8,10,12].map(v=>[v,v+" px"]))},
            {kind:"select",key:"artwork",label:"Artwork",icon:"image",options:root.options([["auto","Automatic"],["svg","SVG icons"],["render","Device renders"]])}]
        PreferenceRow {
            required property var modelData
            width:parent.width; definition:modelData; value:root.entry[modelData.key] ?? "default"
            visible:modelData.key === "presentation" || root.effective.presentation!=="off" && (["position","popupDuration","artwork"].indexOf(modelData.key)>=0 ? root.effective.presentation!=="waveup" : ["waveOrigin","waveEdge","waveDuration","radius","stroke"].indexOf(modelData.key)>=0 ? root.effective.presentation!=="popup" : true)
            onEdited:value=>root.edit(modelData.key,value)
        }
    }
    PreferenceRow {
        width:parent.width
        definition:({kind:"select",key:"previewSubject",label:"Preview subject",icon:"earbuds",options:[{value:"left",label:"Left earbud"},{value:"right",label:"Right earbud"},{value:"pair",label:"Both earbuds"},{value:"case",label:"Case"}]})
        value:root.subject; visible:root.kind!=="noise-mode"
        onEdited:value=>root.subject=value
    }
    Row {
        spacing:8
        DButton { text:"Preview event"; iconName:"play_arrow"; onClicked:root.preview({kind:root.kind,subject:root.kind==="noise-mode" ? "mode" : root.subject,waves:root.kind==="noise-mode" || /^battery/.test(root.kind) ? 3 : 1,title:Rules.events.find(e=>e.key===root.kind)?.label || "Galaxy Buds",detail:"Notification preview",mode:"NOISE_REDUCTION"}) }
        DButton {
            text:"Reset to default"; iconName:"restart_alt"
            onClicked:{ const next=Object.assign({},root.config.notificationRules); delete next[root.kind]; root.preferences.update("notificationRules",next); root.preferences.update("notify_"+root.kind.replace(/-/g,"_"),"default"); }
        }
    }
}
