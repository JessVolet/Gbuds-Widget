import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "../config/NotificationPreferences.js" as Rules

Column {
    id:root
    required property var preferences
    signal preview(var event)
    spacing:6
    property string eventKind:"noise-mode"
    readonly property var config:preferences.value
    function field(kind,key,label,extra) { return Object.assign({kind:kind,key:key,label:label},extra || {}); }
    function options(pairs) { return pairs.map(pair=>({value:pair[0],label:pair[1]})); }
    function updateRule(key,value) {
        preferences.update("notificationRules",Rules.update(config.notificationRules,eventKind,key,value));
    }
    PreferenceRow { width:parent.width; definition:root.field("toggle","notificationsEnabled","Enable notifications",{icon:"notifications",description:"Show alerts for your Galaxy Buds."}); value:root.config.notificationsEnabled; onEdited:value=>root.preferences.update("notificationsEnabled",value) }
    PreferenceRow { width:parent.width; definition:root.field("select","notificationPresentation","Default style",{icon:"notifications_active",options:root.options([["waveup","Waveups"],["popup","Popups"],["both","Both"]])}); value:root.config.notificationPresentation; onEdited:value=>root.preferences.update("notificationPresentation",value) }
    Repeater {
        model:[
            root.field("slider","dismissTimeout","Popup duration",{min:2,max:15,unit:"s",icon:"timer"}),
            root.field("slider","notifyWaveDuration","Wave duration",{min:3,max:15,unit:"s",icon:"waves"}),
            root.field("select","notificationArtwork","Artwork",{icon:"image",options:root.options([["auto","Automatic"],["svg","SVG icons"],["render","Device renders"]])}),
            root.field("position","notifyPopupPosition","Popup position",{icon:"open_with",options:root.options([["match","Match earbud"]].concat(Rules.positions.map(p=>[p,p.replace(/-/g," ")]))) }),
            root.field("select","notifyScreen","Display",{icon:"monitor",options:root.options([["active","Active display"],["primary","Primary display"]].concat(Quickshell.screens.map(s=>[s.name,s.name])))}),
            root.field("select","notifyWaveOrigin","Wave origin",{icon:"waves",options:root.options([["match","Match earbud"],["left","Left"],["right","Right"],["both","Both sides"]])}),
            root.field("select","notifyVerticalPosition","Wave edge",{icon:"vertical_align_bottom",options:root.options([["top","Top"],["bottom","Bottom"]])})]
        PreferenceRow {
            required property var modelData
            width:parent.width
            definition:modelData
            visible:modelData.key === "dismissTimeout" || modelData.key === "notificationArtwork" || modelData.key === "notifyPopupPosition" ? root.config.notificationPresentation!=="waveup" : modelData.key === "notifyWaveDuration" || modelData.key === "notifyWaveOrigin" || modelData.key === "notifyVerticalPosition" ? root.config.notificationPresentation!=="popup" : true
            value:root.config[modelData.key]
            onEdited:value=>root.preferences.update(modelData.key,value)
        }
    }
    DButton { text:"Preview default"; iconName:"play_arrow"; onClicked:root.preview({kind:"connected",subject:"pair",waves:2,title:"Galaxy Buds connected",detail:"Ready to listen"}) }
    PreferenceRow { width:parent.width; definition:root.field("toggle","advancedNotifications","Advanced notifications",{icon:"tune",description:"Choose a different style, position or duration for each event. Your exceptions stay saved when disabled."}); value:root.config.advancedNotifications; onEdited:value=>root.preferences.update("advancedNotifications",value) }
    Grid {
        id:eventGrid
        objectName:"eventRules"
        width:parent.width; spacing:10; columns:width>=760 ? 2 : 1
        visible:root.config.advancedNotifications
        Column {
            width:eventGrid.columns===2 ? 250 : eventGrid.width
            spacing:4
            PreferenceRow {
                width:parent.width; visible:eventGrid.columns===1
                definition:root.field("select","eventKind","Event",{icon:Rules.events.find(e=>e.key===root.eventKind)?.icon || "notifications",options:Rules.events.map(e=>({value:e.key,label:e.label+" · "+Rules.summary(root.config,e.key)}))})
                value:root.eventKind; onEdited:value=>root.eventKind=value
            }
            Repeater {
                model:eventGrid.columns===2 ? Rules.events : []
                SettingsRow {
                    required property var modelData
                    width:parent.width; title:modelData.label; subtitle:Rules.summary(root.config,modelData.key)
                    iconName:modelData.icon; active:root.eventKind===modelData.key; clickable:true
                    onClicked:root.eventKind=modelData.key
                }
            }
        }
        EventNotificationEditor { width:eventGrid.columns===2 ? eventGrid.width-260 : eventGrid.width; preferences:root.preferences; kind:root.eventKind; onPreview:event=>root.preview(event) }
    }
    DCollapsibleSection {
        width:parent.width; title:"Wave appearance & reminders"; description:"Reach, stroke, corner inset and out-of-ear reminders."
        Column {
            width:parent.width; spacing:6
            Repeater {
                model:[root.field("slider","waveRadiusPx","Wave reach",{min:80,max:400,unit:"px",icon:"waves"}),root.field("slider","waveStrokePx","Wave stroke",{min:1,max:12,unit:"px",icon:"line_weight"}),root.field("slider","notifyMargin","Screen inset",{min:0,max:100,unit:"px",icon:"select_all"}),root.field("toggle","notifyReduceMotion","Reduce notification motion",{icon:"animation"}),root.field("toggle","notifyIdleReminder","Out-of-ear reminders",{icon:"timer"}),root.field("slider","notifyIdleInterval","Reminder interval",{min:15,max:3600,unit:"s",icon:"schedule"})]
                PreferenceRow { required property var modelData; width:parent.width; definition:modelData; value:root.config[modelData.key]; visible:modelData.key!=="notifyIdleInterval" || root.config.notifyIdleReminder; onEdited:value=>root.preferences.update(modelData.key,value) }
            }
        }
    }
}
