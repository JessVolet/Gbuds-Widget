.pragma library
function choices(values) { return values.map(value => ({value:value[0],label:value[1]})); }
function rows(instance) {
    const list = instance ? [
        ["title","","Layout"],
        ["select","desktopPreset","Preset", [["compact","Compact"],["minimal","Minimal"],["detailed","Detailed"],["custom","Custom"]]],
        ["select","desktopOfflinePolicy","When disconnected",[["hide","Hide"],["connect","Show Connect"],["status","Show status"]]],
        ["select","desktopArtwork","Artwork",[["svg","SVG icons"],["render","Device renders"],["auto","Automatic"]]],
        ["title","","Blocks"],
        ["toggle","desktopShowName","Device name"], ["toggle","desktopShowCase","Case"],
        ["toggle","desktopShowBattery","Battery percentages"], ["toggle","desktopShowNoise","Noise controls"],
        ["toggle","desktopShowDisconnect","Disconnect button"],
        ["select","desktopEarOrder","Earbud order",[["left-case-right","L · CASE · R"],["right-case-left","R · CASE · L"],["case-left-right","CASE · L · R"],["left-right-case","L · R · CASE"]]],
        ["toggle","desktopHorizontal","Horizontal arrangement"],
        ["title","","Size and spacing"],
        ["slider","desktopEarbudSize","Earbud size",20,128], ["slider","desktopCaseSize","Case size",20,128],
        ["slider","desktopTextSize","Battery label size",9,24], ["slider","desktopNameSize","Device name size",12,28],
        ["select","desktopAlignment","Content alignment",[["left","Left"],["center","Center"],["right","Right"]]], ["slider","desktopNoiseSize","Noise icon size",16,96],
        ["slider","desktopGap","Spacing",0,48], ["slider","desktopPadding","Padding",0,40],
        ["slider","desktopVerticalOffset","Earbud vertical offset",-32,32],
        ["title","","Appearance"],
        ["select","desktopBackgroundMode","Background",[["theme","System theme"],["transparent","Transparent"],["custom","Custom"]]],
        ["string","desktopSurfaceColor","Custom background color"],
        ["slider","desktopBackgroundOpacity","Background opacity",0,100],
        ["toggle","desktopShowBorder","Border"],
        ["toggle","syncPositionAcrossScreens","Sync position across displays"],
        ["toggle","desktopLockControls","Allow noise control on the lock screen"],
        ["toggle","desktopLockAnimations","Allow lock-screen animations"]
    ] : [
        ["title","","Device panel"],
        ["select","panelArtwork","Artwork",[["svg","SVG icons"],["render","Device renders"],["auto","Automatic"]]],
        ["title","","Bar"],
        ["select","pillMode","Bar layout",[["compact","Compact"],["detailed","With case"],["icon-only","Icons only"]]],
        ["toggle","showBatteryPercentages","Battery percentages"], ["toggle","showModeIcon","Noise mode icon"],
        ["toggle","warnOutOfEar","Idle timer"],
        ["select","batteryIndicatorStyle","Battery style",[["clean","Theme outline"],["border","Battery outline"],["tint","Filled"],["glow","Soft accent"]]],
        ["select","iconColorMode","Icon color",[["auto","System theme"],["primary","Primary"],["secondary","Secondary"],["tertiary","Tertiary"],["custom","Custom"]]],
        ["string","customColor","Custom icon color"],
        ["select","idleColorMode","Idle timer color",[["auto","Theme warning"],["primary","Primary"],["secondary","Secondary"],["error","Red"],["custom","Custom"]]],
        ["string","customIdleColor","Custom idle color"],
        ["select","caseColorMode","Case color",[["auto","System theme"],["primary","Primary"],["secondary","Secondary"],["custom","Custom"]]],
        ["string","customCaseColor","Custom case color"],
        ["title","","Notifications"],
        ["toggle","notificationsEnabled","Enable notifications"],
        ["select","notificationPresentation","Notification style",[["popup","Popups"],["waveup","Waveups"],["both","Popups and Waveups"]]],
        ["slider","dismissTimeout","Popup duration",2,15], ["slider","notifyWaveDuration","Wave duration",3,15],
        ["title","","Advanced notification settings",true],
        ["slider","waveRadiusPx","Wave reach (radius)",80,400,true], ["slider","waveStrokePx","Wave stroke",1,12,true],
        ["select","notificationArtwork","Notification artwork",[["svg","SVG icons"],["render","Device renders"],["auto","Automatic"]],true],
        ["toggle","notifyMatchPosition","Match left/right position",true],
        ["select","notifyVerticalPosition","Screen edge",[["top","Top"],["bottom","Bottom"]],true],
        ["select","notifyFixedSide","Fixed side / case fallback",[["left","Left"],["right","Right"]],true],
        ["slider","notifyMargin","Corner inset",0,100,true],
        ["select","notifyScreen","Notification display",[["active","Active display"],["primary","Primary display"]],true],
        ["toggle","notifyReduceMotion","Reduce motion",true],
        ["toggle","notifyIdleReminder","Out-of-ear reminders",true],
        ["slider","notifyIdleInterval","Reminder interval",15,3600,true],
        ["title","","Device"], ["string","targetMac","Preferred Bluetooth address"], ["string","gbudsCommand","Gbuds executable"]
    ];
    const result = list.map(row => ({kind:row[0], key:row[1], label:row[2], options:row[0] === "select" ? choices(row[3]) : [],
        min:row[0] === "slider" ? row[3] : 0, max:row[0] === "slider" ? row[4] : 0,
        advanced:row[row.length-1] === true}));
    if (!instance) {
        const events = [["out_of_ear","Removed from ear"],["in_ear","Back in ear"],["out_of_case","Removed from case"],
            ["stored","Stored in case"],["connected","Connected"],["disconnected","Disconnected"],
            ["noise_mode","Noise mode changed"],["battery_50","Battery at 50%"],["battery_20","Battery at 20%"],["out_of_ear_reminder","Out-of-ear reminder"]];
        const insert = result.findIndex(row => row.key === "notifyIdleReminder");
        result.splice.apply(result,[insert,0].concat(events.map(event => ({kind:"select", key:"notify_"+event[0], label:event[1], advanced:true,
            options:choices([["default","Use default"],["off","Off"],["popup","Popup"],["waveup","Waveup"],["both","Both"]])}))));
    }
    return result;
}
