import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Column {
    id: root

    property var device: ({})
    property var status: ({})
    property var modeOptions: []
    property bool connected: false
    property bool busy: false
    property bool lightsOpen: false
    property bool soundOpen: false
    readonly property bool hasAmbientVolume: device.has_ambient === true && Number(device.max_ambient_volume) > 0
    readonly property bool hasVoiceDetect: device.has_voice_detect === true
    readonly property bool hasBladeLights: device.has_blade_lights === true
    readonly property bool hasEqualizer: status.equalizer !== null && status.equalizer !== undefined
    readonly property bool hasSoundOptions: connected && (hasAmbientVolume || hasVoiceDetect || hasBladeLights || hasEqualizer)

    signal modeRequested(string mode)
    signal commandRequested(string commandName, var commandArgs, string label)

    width: parent.width
    spacing: Theme.spacingS

    function modeLabel(value) {
        if (value === "NOISE_REDUCTION") return "Noise cancellation";
        if (value === "AMBIENT_SOUND") return "Ambient sound";
        if (value === "ADAPTIVE") return "Adaptive sound";
        if (value === "OFF") return "Normal";
        return "Choose a mode";
    }

    function triggerAction(key) {
        if (key === "sync")
            root.commandRequested("battery", [], "Battery status refreshed");
        else
            root.commandRequested("touchpad", [root.status.touchpad_locked ? "unlock" : "lock"], "Touch controls updated");
    }

    Rectangle {
        width: parent.width
        height: root.modeOptions.length > 0 && !root.soundOpen ? 112 : 0
        visible: height > 1
        radius: Theme.cornerRadiusL
        color: Theme.surface
        border.color: Theme.withAlpha(Theme.outline, 0.2)
        border.width: 1
        clip: true
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: Theme.spacingS
            Row {
                width: parent.width
                height: 20
                spacing: Theme.spacingS
                DIcon { name: "noise_control_on"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                StyledText {
                    width: parent.width * 0.44
                    text: "Noise control"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    width: parent.width - parent.children[0].width - parent.children[1].width - 14
                    text: root.modeLabel(root.status.noise_control)
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle {
                width: parent.width
                height: 56
                radius: Theme.cornerRadiusM
                color: Theme.surfaceContainerHigh
                Row {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    Repeater {
                        model: root.modeOptions
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool selected: root.status.noise_control === modelData.mode
                            width: (parent.width - (root.modeOptions.length - 1) * 4) / Math.max(1, root.modeOptions.length)
                            height: parent.height
                            radius: Theme.cornerRadiusM
                            color: selected ? Theme.primaryContainer : "transparent"
                            scale: selected ? 1 : 0.97
                            enabled: root.connected && !root.busy
                            activeFocusOnTab: enabled
                            Accessible.role: Accessible.Button
                            Accessible.name: modelData.label
                            Accessible.checked: selected
                            Behavior on color { ColorAnimation { duration: 220 } }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                DIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: modelData.icon
                                    size: 18
                                    color: selected ? Theme.primary : Theme.surfaceVariantText
                                }
                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    color: selected ? Theme.primary : Theme.surfaceVariantText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: selected ? Font.Bold : Font.Medium
                                }
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.modeRequested(modelData.mode) }
                            Keys.onReturnPressed: root.modeRequested(modelData.mode)
                            Keys.onSpacePressed: root.modeRequested(modelData.mode)
                        }
                    }
                }
            }
        }
    }

    Row {
        width: parent.width
        height: root.soundOpen ? 0 : 64
        visible: height > 1
        spacing: Theme.spacingS

        Repeater {
            model: [
                { key: "touch", title: "Touch controls", icon: root.status.touchpad_locked ? "lock" : "touch_app", detail: root.status.touchpad_locked ? "Locked" : "Active" },
                { key: "sync", title: "Sync", icon: "sync", detail: root.busy ? "Working…" : "Refresh status" }
            ]
            delegate: Rectangle {
                required property var modelData
                readonly property bool actionable: root.connected && !root.busy && (modelData.key === "sync" || typeof root.status.touchpad_locked === "boolean")
                width: (parent.width - 10) / 2
                height: parent.height
                radius: Theme.cornerRadiusM
                color: actionMouse.containsMouse && actionable ? Theme.primaryContainer : Theme.surface
                scale: actionMouse.containsMouse && actionable ? 1.025 : 1
                border.color: Theme.withAlpha(Theme.outline, 0.2)
                border.width: 1
                enabled: actionable
                activeFocusOnTab: enabled
                Accessible.role: Accessible.Button
                Accessible.name: modelData.title + ", " + modelData.detail
                Behavior on color { ColorAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Row {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 9
                    Rectangle {
                        width: 38; height: 38; radius: Theme.cornerRadiusS
                        color: Theme.primaryContainer
                        anchors.verticalCenter: parent.verticalCenter
                        DIcon { anchors.centerIn: parent; name: modelData.icon; size: 20; color: Theme.primary }
                    }
                    Column {
                        width: parent.width - 47
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter
                        StyledText {
                            width: parent.width
                            text: modelData.title
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                        StyledText {
                            width: parent.width
                            text: modelData.detail
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }
                }
                MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.triggerAction(modelData.key)
                }
                Keys.onReturnPressed: root.triggerAction(modelData.key)
                Keys.onSpacePressed: root.triggerAction(modelData.key)
            }
        }
    }

    Rectangle {
        width: parent.width
        height: root.hasSoundOptions ? (root.soundOpen ? soundContent.implicitHeight + 28 : 52) : 0
        visible: height > 1
        radius: Theme.cornerRadiusL
        color: Theme.surface
        border.color: Theme.withAlpha(Theme.outline, 0.2)
        border.width: 1
        clip: true
        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Column {
            id: soundContent
            width: parent.width - 28
            x: 14; y: 14
            spacing: Theme.spacingM

            Item {
                width: parent.width
                height: 24
                activeFocusOnTab: root.hasSoundOptions
                Accessible.role: Accessible.Button
                Accessible.name: root.soundOpen ? "Collapse sound controls" : "Expand sound controls"
                DIcon { name: "tune"; size: 19; width: 20; height: 20; color: Theme.primary; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                StyledText {
                    anchors.left: parent.left
                    anchors.leftMargin: 28
                    width: parent.width - 56
                    text: "Sound & controls"
                    color: Theme.surfaceText
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                }
                DIcon { name: root.soundOpen ? "expand_less" : "expand_more"; size: 19; width: 20; height: 20; color: Theme.primary; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                MouseArea { anchors.fill: parent; onClicked: root.soundOpen = !root.soundOpen }
                Keys.onReturnPressed: root.soundOpen = !root.soundOpen
                Keys.onSpacePressed: root.soundOpen = !root.soundOpen
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: root.soundOpen
            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.hasEqualizer
                StyledText {
                    text: "SOUND PROFILE"
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }
                Flow {
                    width: parent.width
                    spacing: Theme.spacingXS
                    Repeater {
                        model: [
                            { key: "normal", value: "OFF", label: "Normal" },
                            { key: "bass", value: "BASS_BOOST", label: "Bass" },
                            { key: "soft", value: "SOFT", label: "Soft" },
                            { key: "dynamic", value: "DYNAMIC", label: "Dynamic" },
                            { key: "clear", value: "CLEAR", label: "Clear" },
                            { key: "treble", value: "TREBLE_BOOST", label: "Treble" }
                        ]
                        delegate: DButton {
                            required property var modelData
                            width: 86; buttonHeight: 32; minimumWidth: 0
                            text: modelData.label
                            enabled: root.connected && !root.busy
                            checkable: true
                            checked: root.status.equalizer === modelData.value
                            backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: checked ? Theme.primary : Theme.surfaceText
                            onClicked: root.commandRequested("eq", [modelData.key], "Equalizer " + modelData.key)
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.hasAmbientVolume
                StyledText {
                    text: "AMBIENT VOLUME  ·  " + (typeof root.status.ambient_volume === "number" ? root.status.ambient_volume : "—")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }
                Row {
                    width: parent.width
                    spacing: Theme.spacingXS
                    Repeater {
                        model: root.hasAmbientVolume ? Number(root.device.max_ambient_volume) + 1 : 0
                        delegate: DButton {
                            required property int index
                            width: (parent.width - Number(root.device.max_ambient_volume) * 6) / (Number(root.device.max_ambient_volume) + 1)
                            buttonHeight: 32; minimumWidth: 0
                            text: String(index)
                            enabled: root.connected && !root.busy
                            checkable: true
                            checked: root.status.ambient_volume === index
                            backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                            textColor: checked ? Theme.primary : Theme.surfaceText
                            onClicked: root.commandRequested("ambient-volume", [String(index)], "Ambient volume " + index)
                        }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: Theme.spacingS
                visible: root.hasVoiceDetect || root.hasBladeLights
                DButton {
                    width: root.hasBladeLights ? (parent.width - 8) / 2 : parent.width
                    visible: root.hasVoiceDetect
                    text: root.status.voice_detect ? "Voice detect on" : "Voice detect"
                    iconName: "record_voice_over"
                    enabled: root.connected && typeof root.status.voice_detect === "boolean" && !root.busy
                    backgroundColor: root.status.voice_detect ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    onClicked: root.commandRequested("voice-detect", [root.status.voice_detect ? "off" : "on"], "Voice detect")
                }
                DButton {
                    width: root.hasVoiceDetect ? (parent.width - 8) / 2 : parent.width
                    visible: root.hasBladeLights
                    text: "Blade Lights"
                    iconName: "lightbulb"
                    enabled: root.connected && !root.busy
                    backgroundColor: root.lightsOpen ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    onClicked: root.lightsOpen = !root.lightsOpen
                }
            }

            Flow {
                width: parent.width
                spacing: Theme.spacingXS
                visible: root.hasBladeLights && root.lightsOpen
                Repeater {
                    model: ["off", "steady", "fade", "blink"]
                    delegate: DButton {
                        required property string modelData
                        width: 74; buttonHeight: 32; minimumWidth: 0
                        text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                        enabled: root.connected && !root.busy
                        checkable: true
                        checked: String(root.status.blade_lights || "").toLowerCase() === modelData
                        backgroundColor: checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        textColor: checked ? Theme.primary : Theme.surfaceText
                        onClicked: root.commandRequested("lights", [modelData], "Blade Lights " + modelData)
                    }
                }
            }
            }
        }
    }
}
