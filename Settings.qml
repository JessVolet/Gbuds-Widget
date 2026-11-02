import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.DCommon.Widgets
import "src/config"
import "src/config/Schema.js" as Schema
import "src/settings"
import "src/settings/SettingsModel.js" as Model

PluginSettings {
    id:root
    pluginId:"gbudsWatch"
    property string instanceId:""
    property var instanceData:null
    property bool expanded:false
    property int settingsRevision:0
    readonly property bool instanceScope:instanceId !== ""
    readonly property var rows:Model.rows(instanceScope)
    function readSettings() {
        const values={};
        Object.keys(Schema.defaults).concat(rows.map(row=>row.key),["desktopLayout","showConnectButton","notifyWaveSize","showStatusCards"]).forEach(key=>{
            if (!key) return;
            const value=root.loadValue(key,undefined);
            if (value !== undefined) values[key]=value;
        });
        return values;
    }
    ConfigStore {
        id:settingsStore
        source:{ root.settingsRevision; root.pluginService; return root.readSettings(); }
        onPersist:(key,value)=>root.saveValue(key,value)
    }
    Connections {
        target:root.pluginService
        ignoreUnknownSignals:true
        function onPluginDataChanged(pid) { if (pid===root.pluginId) root.settingsRevision++; }
    }
    function preview(kind, side, count) {
        if (!pluginService) return;
        settingsStore.flush();
        pluginService.setGlobalVar(pluginId,"notificationTest",{id:String(Date.now()),kind:kind,subject:side,waves:count,
            title:kind === "noise-mode" ? "Noise cancellation" : kind === "battery-20" ? "Battery at 20%" : "Earbud removed",
            detail:side === "left" ? "Left earbud" : "Galaxy Buds",mode:"NOISE_REDUCTION",severity:kind === "battery-20" ? "critical" : "normal"});
    }
    StyledText { width:parent.width; text:root.instanceScope ? "This widget" : "Gbuds Widget"; color:Theme.surfaceText; font.pixelSize:20; font.bold:true }
    StyledText { width:parent.width; text:root.instanceScope ? "Appearance and behavior for this instance." : "Bar, notifications, and device settingsStore."; wrapMode:Text.WordWrap; color:Theme.surfaceVariantText; font.pixelSize:12 }
    DButton { width:parent.width; visible:!root.instanceScope; text:root.expanded ? "Hide advanced options" : "Advanced options"; onClicked:root.expanded=!root.expanded }
    Repeater {
        model:root.rows
        PreferenceRow {
            required property var modelData
            width:parent.width
            visible:(!modelData.advanced || root.expanded) &&
                (modelData.key !== "customColor" || settingsStore.value.iconColorMode === "custom") &&
                (modelData.key !== "customCaseColor" || settingsStore.value.caseColorMode === "custom") &&
                (modelData.key !== "customIdleColor" || settingsStore.value.idleColorMode === "custom") &&
                (modelData.key !== "desktopSurfaceColor" || settingsStore.value.desktopBackgroundMode === "custom")
            definition:modelData.key === "notifyScreen" ? Object.assign({},modelData,{options:modelData.options.concat(Quickshell.screens.map(s=>({value:s.name,label:s.name})))}) : modelData
            value:settingsStore.value[modelData.key] !== undefined ? settingsStore.value[modelData.key] : "default"
            onEdited:value=>settingsStore.update(modelData.key,value)
        }
    }
    BlockOrderSetting {
        width:parent.width; visible:root.instanceScope
        order:settingsStore.value.desktopBlockOrder
        onChanged:value=>settingsStore.update("desktopBlockOrder",value)
    }
    DisplaySelector {
        width:parent.width; visible:root.instanceScope
        preferences:settingsStore.value.displayPreferences
        onChanged:values=>settingsStore.update("displayPreferences",values)
    }
    Row {
        width:parent.width; spacing:6; visible:!root.instanceScope
        DButton { width:(parent.width-12)/3; text:"Test removal"; onClicked:root.preview("out-of-ear","left",1) }
        DButton { width:(parent.width-12)/3; text:"Test ANC"; onClicked:root.preview("noise-mode","mode",3) }
        DButton { width:(parent.width-12)/3; text:"Test battery"; onClicked:root.preview("battery-20","right",3) }
    }
}
