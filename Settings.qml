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
    property int selectedSection:0
    property int settingsRevision:0
    readonly property bool instanceScope:instanceId !== ""
    readonly property var rows:Model.sectionRows(selectedSection,instanceScope)
    function readSettings() {
        const values={};
        Object.keys(Schema.defaults).concat(Model.rows(false).map(row=>row.key),["desktopLayout","showConnectButton","notifyWaveSize","showStatusCards"]).forEach(key=>{
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
    StyledText { width:parent.width; text:root.instanceScope ? "Appearance and behavior for this instance." : "Appearance, sound and notifications. Desktop layout is configured per widget instance."; wrapMode:Text.WordWrap; color:Theme.surfaceVariantText; font.pixelSize:12 }
    DTabBar {
        width:parent.width; visible:!root.instanceScope
        model:Model.sections(); currentIndex:root.selectedSection
        showIcons:true
        onTabClicked:index=>root.selectedSection=index
    }
    NotificationSettings {
        width:parent.width; visible:!root.instanceScope && root.selectedSection===2
        preferences:settingsStore
        onPreview:event=>{
            settingsStore.flush();
            if (root.pluginService) root.pluginService.setGlobalVar(root.pluginId,"notificationTest",Object.assign({},event,{id:String(Date.now())}));
        }
    }
    Repeater {
        model:root.rows
        PreferenceRow {
            required property var modelData
            width:parent.width
            visible:(root.instanceScope || root.selectedSection!==2) &&
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
}
