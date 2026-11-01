import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.DCommon.Widgets
import "."
import "./interface-v060" as Gbuds

PluginSettings {
    id: root
    pluginId: "gbudsWatch"
    property string instanceId: ""
    property var instanceData: null
    readonly property bool instanceScope: instanceId !== ""
    readonly property var notificationScreens: {
        var values = [{ value: "active", label: "Active display" }, { value: "primary", label: "Primary display" }];
        Quickshell.screens.forEach(screen => { if (screen.name) values.push({ value: screen.name, label: screen.name }); });
        return values;
    }

    function testNotification(kind, subject, title, detail, severity, waves, extra) {
        if (!pluginService || !pluginService.setGlobalVar) return;
        var event = { id: Date.now() + "-" + Math.random(), kind: kind, subject: subject, title: title, detail: detail, severity: severity, waves: waves, snapshot: root.instanceData?.config?.status || null };
        if (extra) Object.keys(extra).forEach(key => event[key] = extra[key]);
        pluginService.setGlobalVar(pluginId, "notificationTest", event);
    }

    StyledText {
        width: parent.width
        text: root.instanceScope ? "This instance · desktop or lock screen" : "Gbuds Widget"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
        wrapMode: Text.WordWrap
    }
    StyledText {
        width: parent.width
        visible: root.instanceScope
        text: "These preferences apply to this widget only. The bar, alerts, and other instances keep their own settings."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }
    StyledText {
        width: parent.width
        visible: !root.instanceScope
        text: "Global bar, alert, and device settings. To customize a layout, open the settings for a desktop widget instance."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledText { width: parent.width; visible: root.instanceScope; text: "Layout"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting {
        id: desktopPreset
        settingKey: "desktopPreset"; label: "Layout base"
        description: "New instances start compact. Custom enables the blocks below."
        options: [{value:"compact",label:"Compact"},{value:"minimal",label:"Minimal"},{value:"detailed",label:"Detailed"},{value:"custom",label:"Custom"}]
        defaultValue: "compact"; visible: root.instanceScope
    }
    SelectionSetting {
        settingKey: "desktopOfflinePolicy"; label: "When the Buds are disconnected"
        description: "Hide leaves the desktop clear. Connect shows an action. Status shows a label without reconnecting."
        options: [{value:"hide",label:"Hide"},{value:"connect",label:"Show Connect"},{value:"status",label:"Show status"}]
        defaultValue: "hide"; visible: root.instanceScope
    }
    SelectionSetting {
        settingKey: "desktopArtwork"; label: "Artwork"
        options: [{value:"svg",label:"SVG icons"},{value:"render",label:"Device render"},{value:"auto",label:"Automatic with SVG fallback"}]
        defaultValue: "svg"; visible: root.instanceScope
    }
    Rectangle {
        width: parent.width
        height: 78
        radius: Theme.cornerRadiusM
        visible: root.instanceScope
        color: Theme.withAlpha(Theme.surfaceContainer, 0.72)
        border.color: Theme.withAlpha(Theme.outline, 0.2)
        Row {
            anchors.centerIn: parent
            spacing: 12
            Image { source: Qt.resolvedUrl("./assets/approved/bud-left.svg"); width: 30; height: 42; fillMode: Image.PreserveAspectFit }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Image { source: Qt.resolvedUrl("./assets/approved/case.svg"); width: 30; height: 30; fillMode: Image.PreserveAspectFit; anchors.horizontalCenter: parent.horizontalCenter }
                StyledText { text: "CASE  59%"; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; anchors.horizontalCenter: parent.horizontalCenter }
            }
            Image { source: Qt.resolvedUrl("./assets/approved/bud-right.svg"); width: 30; height: 42; fillMode: Image.PreserveAspectFit }
            Gbuds.NoiseModeIcon { mode:"NOISE_REDUCTION"; size:28; color:Theme.primary; anchors.verticalCenter:parent.verticalCenter }
        }
    }

    StyledText { width: parent.width; visible: root.instanceScope; text: "Blocks and controls"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    ToggleSetting { settingKey:"desktopShowName"; label:"Device name"; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopShowCase"; label:"Show case"; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopShowBattery"; label:"Battery percentages"; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { id: desktopShowNoise; settingKey:"desktopShowNoise"; label:"Noise control buttons"; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopShowDisconnect"; label:"Disconnect button under CASE"; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopHorizontal"; label:"Layout horizontal"; description:"Turn off for a vertical layout."; defaultValue:true; visible:root.instanceScope && desktopPreset.value === "custom" }
    SelectionSetting { settingKey:"desktopEarOrder"; label:"L / CASE / R order"; options:[{value:"left-case-right",label:"L · CASE · R"},{value:"right-case-left",label:"R · CASE · L"},{value:"case-left-right",label:"CASE · L · R"},{value:"left-right-case",label:"L · R · CASE"},{value:"right-left-case",label:"R · L · CASE"},{value:"case-right-left",label:"CASE · R · L"}]; defaultValue:"left-case-right"; visible:root.instanceScope && desktopPreset.value !== "minimal" }

    StyledText { width: parent.width; visible: root.instanceScope; text: "Size and spacing"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting { settingKey:"desktopEarbudSize"; label:"Earbud size"; options:[{value:"32",label:"Small · 32"},{value:"40",label:"40"},{value:"48",label:"Normal · 48"},{value:"56",label:"56"},{value:"64",label:"Large · 64"},{value:"80",label:"80"}]; defaultValue:"48"; visible:root.instanceScope }
    SelectionSetting { settingKey:"desktopNoiseSize"; label:"Noise icon size"; options:[{value:"24",label:"24"},{value:"30",label:"30"},{value:"36",label:"Normal · 36"},{value:"42",label:"42"},{value:"48",label:"48"}]; defaultValue:"36"; visible:root.instanceScope && desktopPreset.value !== "minimal" && desktopShowNoise.value }
    SelectionSetting { settingKey:"desktopGap"; label:"Block spacing"; options:[{value:"0",label:"None"},{value:"4",label:"4"},{value:"8",label:"Normal · 8"},{value:"12",label:"12"},{value:"16",label:"16"},{value:"24",label:"24"}]; defaultValue:"8"; visible:root.instanceScope }
    SelectionSetting { settingKey:"desktopPadding"; label:"Inner padding"; options:[{value:"0",label:"0"},{value:"4",label:"4"},{value:"8",label:"8"},{value:"10",label:"Normal · 10"},{value:"16",label:"16"},{value:"24",label:"24"}]; defaultValue:"10"; visible:root.instanceScope }
    SelectionSetting { settingKey:"desktopVerticalOffset"; label:"Earbud vertical offset"; options:[{value:"-12",label:"−12"},{value:"-6",label:"−6"},{value:"0",label:"Centered"},{value:"6",label:"+6"},{value:"12",label:"+12"}]; defaultValue:"0"; visible:root.instanceScope }

    StyledText { width: parent.width; visible: root.instanceScope; text: "Style"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting { id: desktopBackgroundMode; settingKey:"desktopBackgroundMode"; label:"Background"; options:[{value:"theme",label:"System theme"},{value:"transparent",label:"Transparent"},{value:"custom",label:"Custom color"}]; defaultValue:"theme"; visible:root.instanceScope }
    ColorSetting { settingKey:"desktopSurfaceColor"; label:"Background color"; defaultValue:Theme.surfaceContainer; visible:root.instanceScope && desktopBackgroundMode.value === "custom" }
    SelectionSetting { settingKey:"desktopBackgroundOpacity"; label:"Background opacity"; options:[{value:"0",label:"0%"},{value:"50",label:"50%"},{value:"75",label:"75%"},{value:"94",label:"94%"},{value:"100",label:"100%"}]; defaultValue:"94"; visible:root.instanceScope && desktopBackgroundMode.value !== "transparent" }
    ToggleSetting { settingKey:"desktopShowEdger"; label:"Subtle border"; defaultValue:true; visible:root.instanceScope && desktopBackgroundMode.value !== "transparent" }

    StyledText { width: parent.width; visible: root.instanceScope; text: "Displays and lock screen"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    Gbuds.MultiDisplaySetting {
        visible: root.instanceScope
        preferences: root.instanceData?.config?.displayPreferences || ["all"]
        onSelectionChanged: values => root.saveValue("displayPreferences", values)
    }
    ToggleSetting { settingKey:"syncPositionAcrossScreens"; label:"Sync position across displays"; description:"The widget keeps the same relative position on each display."; defaultValue:true; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopLockControls"; label:"Allow noise control on the lock screen"; description:"Only applies if this instance is added to the lock screen. Connect, Find, and Disconnect stay disabled."; defaultValue:false; visible:root.instanceScope }
    ToggleSetting { settingKey:"desktopLockAnimations"; label:"Allow lock screen animations"; description:"Off by default to save resources."; defaultValue:false; visible:root.instanceScope }

    StyledText { width: parent.width; visible: !root.instanceScope; text: "Bar"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting { settingKey:"batteryIndicatorStyle"; label:"Battery style"; options:[{value:"glow",label:"Soft accent"},{value:"border",label:"Colored outline"},{value:"tint",label:"Tint icon"},{value:"clean",label:"Theme outline"}]; defaultValue:"clean"; visible:!root.instanceScope }
    SelectionSetting { id: iconColorMode; settingKey:"iconColorMode"; label:"Icon color"; options:[{value:"auto",label:"DMS theme"},{value:"primary",label:"Primary"},{value:"secondary",label:"Secondary"},{value:"tertiary",label:"Tertiary"},{value:"custom",label:"Custom"}]; defaultValue:"auto"; visible:!root.instanceScope }
    ColorSetting { settingKey:"customColor"; label:"Custom color"; defaultValue:Theme.surfaceText; visible:!root.instanceScope && iconColorMode.value === "custom" }
    SelectionSetting { settingKey:"pillMode"; label:"Bar layout"; options:[{value:"compact",label:"Compact"},{value:"detailed",label:"With case"},{value:"icon-only",label:"Icons only"}]; defaultValue:"compact"; visible:!root.instanceScope }
    ToggleSetting { settingKey:"showBatteryPercentages"; label:"Show percentages"; defaultValue:false; visible:!root.instanceScope }
    ToggleSetting { settingKey:"showModeIcon"; label:"Show noise control"; defaultValue:true; visible:!root.instanceScope }
    ToggleSetting { settingKey:"warnOutOfEar"; label:"Show idle timer when removed"; defaultValue:true; visible:!root.instanceScope }
    SelectionSetting { id: idleColorMode; settingKey:"idleColorMode"; label:"Idle timer color"; options:[{value:"auto",label:"Theme alert color"},{value:"amber",label:"Amber"},{value:"primary",label:"Primary"},{value:"secondary",label:"Secondary"},{value:"tertiary",label:"Tertiary"},{value:"error",label:"Red"},{value:"muted",label:"Muted"},{value:"custom",label:"Custom"}]; defaultValue:"auto"; visible:!root.instanceScope }
    StringSetting { settingKey:"customIdleColor"; label:"Custom idle timer color"; placeholder:"#f59e0b"; defaultValue:"#f59e0b"; visible:!root.instanceScope && idleColorMode.value === "custom" }
    SelectionSetting { id: caseColorMode; settingKey:"caseColorMode"; label:"Case color"; options:[{value:"auto",label:"DMS theme"},{value:"match",label:"Accent"},{value:"custom",label:"Custom"}]; defaultValue:"auto"; visible:!root.instanceScope }
    ColorSetting { settingKey:"customCaseColor"; label:"Custom case color"; defaultValue:Theme.surfaceVariantText; visible:!root.instanceScope && caseColorMode.value === "custom" }

    StyledText { width: parent.width; visible: !root.instanceScope; text: "Notifications"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    ToggleSetting { settingKey:"notificationsEnabled"; label:"Enable notifications"; description:"Popups include a wave. Waveups do not capture clicks or focus."; defaultValue:true; visible:!root.instanceScope }
    SelectionSetting { id: notificationPresentation; settingKey:"notificationPresentation"; label:"Notification style"; description:"Choose Popups, Waveups, or both. Customize events under Advanced."; options:[{value:"popup",label:"Popups"},{value:"waveup",label:"Waveups"},{value:"both",label:"Popups and Waveups"}]; defaultValue:"popup"; visible:!root.instanceScope }
    SelectionSetting { settingKey:"dismissTimeout"; label:"Popup duration"; options:[{value:"3",label:"3 seconds"},{value:"5",label:"5 seconds"},{value:"8",label:"8 seconds"}]; defaultValue:"5"; visible:!root.instanceScope && notificationPresentation.value !== "waveup" }
    SelectionSetting { settingKey:"notifyWaveDuration"; label:"Wave effect duration"; description:"The sequence repeats during this time."; options:[{value:"3",label:"3 seconds"},{value:"5",label:"5 seconds"},{value:"8",label:"8 seconds"},{value:"10",label:"10 seconds"}]; defaultValue:"5"; visible:!root.instanceScope }
    SelectionSetting { settingKey:"notifyWaveInterval"; label:"Time between wave sequences"; options:[{value:"1200",label:"1.2 seconds"},{value:"1500",label:"1.5 seconds"},{value:"2000",label:"2 seconds"},{value:"2500",label:"2.5 seconds"}]; defaultValue:"1500"; visible:!root.instanceScope }
    ToggleSetting { id: advancedNotifications; settingKey:"showAdvancedNotificationSettings"; label:"Advanced notification settings"; description:"Per-event channels, artwork, position, and accessibility."; defaultValue:false; visible:!root.instanceScope }
    StyledText { width: parent.width; visible: !root.instanceScope && advancedNotifications.value; text: "Advanced · Appearance and placement"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting { settingKey:"notifyWaveSize"; label:"Wave size"; options:[{value:"200",label:"Small · 200"},{value:"240",label:"Default · 240"},{value:"280",label:"Large · 280"},{value:"320",label:"Extra large · 320"}]; defaultValue:"240"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notificationArtwork"; label:"Artwork"; options:[{value:"svg",label:"SVG icons"},{value:"render",label:"Device render"},{value:"auto",label:"Automatic with fallback"}]; defaultValue:"auto"; visible:!root.instanceScope && advancedNotifications.value }
    ToggleSetting { settingKey:"notifyMatchPosition"; label:"Match left/right position"; description:"Left ear alerts appear on the left, and right ear alerts on the right."; defaultValue:true; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notifyVerticalPosition"; label:"Edge"; options:[{value:"top",label:"Top"},{value:"bottom",label:"Bottom"}]; defaultValue:"bottom"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notifyFixedSide"; label:"Fixed side / case fallback"; options:[{value:"left",label:"Left"},{value:"right",label:"Right"}]; defaultValue:"right"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notifyMargin"; label:"Corner margin"; options:[{value:"12",label:"12"},{value:"18",label:"Default · 18"},{value:"24",label:"24"},{value:"36",label:"36"}]; defaultValue:"18"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notifyScreen"; label:"Notification display"; options:root.notificationScreens; defaultValue:"active"; visible:!root.instanceScope && advancedNotifications.value }
    ToggleSetting { settingKey:"notifyReduceMotion"; label:"Reduce motion"; description:"Uses a static arc instead of an expanding wave."; defaultValue:false; visible:!root.instanceScope && advancedNotifications.value }

    StyledText { width: parent.width; visible: !root.instanceScope && advancedNotifications.value; text: "Advanced · Event overrides"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    SelectionSetting { settingKey:"notify_out_of_ear"; label:"Removed from ear · 1 wave"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_disconnected"; label:"Disconnected · 2 waves"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_connected"; label:"Connected · 2 waves"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_in_ear"; label:"Back in ear · 1 wave"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_out_of_case"; label:"Removed from case · 1 wave"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_stored"; label:"Stored in case · 1 wave"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_noise_mode"; label:"Noise control · 1/2/3 waves"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_battery_50"; label:"Battery ≤50% · 3 soft waves"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_battery_20"; label:"Battery ≤20% · 3 intense waves"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notify_out_of_ear_reminder"; label:"Out-of-ear reminder"; options:[{value:"default",label:"Use default"},{value:"off",label:"Off"},{value:"popup",label:"Popup"},{value:"waveup",label:"Waveup"},{value:"both",label:"Both"}]; defaultValue:"default"; visible:!root.instanceScope && advancedNotifications.value }
    StyledText { width: parent.width; visible: !root.instanceScope && advancedNotifications.value; text: "Preview · simulated events only"; font.pixelSize: Theme.fontSizeSmall; color: Theme.surfaceVariantText }
    Row {
        width: parent.width
        spacing: Theme.spacingS
        visible: !root.instanceScope && advancedNotifications.value
        DButton { width: (parent.width - Theme.spacingS) / 2; text:"Test 50%"; buttonHeight:36; onClicked:root.testNotification("battery-50","right","Battery at 50%","Right earbud · 50%","notice",3,{level:50,value:50,component:"right",snapshot:{right:50,left:68,case:77}}) }
        DButton { width: (parent.width - Theme.spacingS) / 2; text:"Test 20%"; buttonHeight:36; onClicked:root.testNotification("battery-20","left","Critical battery · 20%","Left earbud · 18%","critical",3,{level:20,value:18,component:"left",snapshot:{left:18,right:68,case:77}}) }
    }
    Row {
        width: parent.width
        spacing: Theme.spacingS
        visible: !root.instanceScope && advancedNotifications.value
        DButton { width: (parent.width - Theme.spacingS) / 2; text:"Test ANC"; buttonHeight:36; onClicked:root.testNotification("noise-mode","mode","Noise cancellation","ANC is active","normal",3,{mode:"NOISE_REDUCTION",snapshot:{left:68,right:68,noise_control:"NOISE_REDUCTION"}}) }
        DButton { width: (parent.width - Theme.spacingS) / 2; text:"Test removal"; buttonHeight:36; onClicked:root.testNotification("out-of-ear","left","Earbud removed","Left earbud is out of ear","normal",1,{snapshot:{left:68,right:68,placement_left:"IDLE"}}) }
    }
    ToggleSetting { id: idleReminder; settingKey:"notifyIdleReminder"; label:"Repeat while still out of ear"; defaultValue:false; visible:!root.instanceScope && advancedNotifications.value }
    SelectionSetting { settingKey:"notifyIdleInterval"; label:"Reminder interval"; options:[{value:"30",label:"30 seconds"},{value:"60",label:"1 minute"},{value:"120",label:"2 minutes"},{value:"300",label:"5 minutes"}]; defaultValue:"60"; visible:!root.instanceScope && advancedNotifications.value && idleReminder.value }

    StyledText { width: parent.width; visible: !root.instanceScope; text: "Device"; font.pixelSize: Theme.fontSizeMedium; font.weight: Font.DemiBold; color: Theme.primary }
    StringSetting { settingKey:"targetMac"; label:"Preferred MAC"; description:"Leave blank to detect a connected Galaxy Buds device."; placeholder:"AA:BB:CC:DD:EE:FF"; defaultValue:""; visible:!root.instanceScope }
    StringSetting { settingKey:"gbudsCommand"; label:"gbuds executable"; description:"Path to the CLI; usually just “gbuds” is enough."; placeholder:"gbuds"; defaultValue:"gbuds"; visible:!root.instanceScope }
}
