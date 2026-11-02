import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../device/Policy.js" as Policy

Column {
    id:root
    required property var state
    spacing:8

    DCard {
        width:parent.width
        height:68
        pad:12
        visible:Policy.available(root.state.device.features,"touchpad")
        Row {
            anchors.fill:parent
            spacing:10
            Rectangle {
                width:40; height:40; radius:14; anchors.verticalCenter:parent.verticalCenter
                color:Theme.secondaryContainer
                DIcon { anchors.centerIn:parent; name:"touch_app"; size:21; color:Theme.primary }
            }
            Column {
                width:parent.width-100; anchors.verticalCenter:parent.verticalCenter; spacing:3
                StyledText { width:parent.width; text:"Touch controls"; color:Theme.surfaceText; font.pixelSize:13; font.weight:Font.DemiBold; elide:Text.ElideRight }
                StyledText { width:parent.width; text:root.state.status.touchpad_locked ? "Locked" : "Active"; color:Theme.surfaceVariantText; font.pixelSize:11 }
            }
            DToggle {
                anchors.verticalCenter:parent.verticalCenter
                hideText:true
                checked:!root.state.status.touchpad_locked
                text:"Touch controls"
                Accessible.name:text
                enabled:!root.state.busy
                onToggled:value=>root.state.request("touchpad",[value ? "unlock" : "lock"])
            }
        }
    }

    DCard {
        id:eqCard
        width:parent.width
        visible:Policy.available(root.state.device.features,"equalizer")
        implicitHeight:eqContent.implicitHeight+24
        pad:12
        Column {
            id:eqContent
            width:parent.width
            spacing:10
            Row {
                width:parent.width; spacing:9
                Rectangle {
                    width:36; height:36; radius:12; anchors.verticalCenter:parent.verticalCenter
                    color:Theme.primaryContainer
                    DIcon { anchors.centerIn:parent; name:"equalizer"; size:20; color:Theme.onPrimaryContainer }
                }
                Column {
                    width:parent.width-45; anchors.verticalCenter:parent.verticalCenter; spacing:2
                    StyledText { text:"Equalizer"; color:Theme.surfaceText; font.pixelSize:13; font.weight:Font.DemiBold }
                    StyledText { text:"Choose a sound profile"; color:Theme.surfaceVariantText; font.pixelSize:11 }
                }
            }
            Item {
                width:parent.width; height:72
                Rectangle { anchors.fill:parent; radius:12; color:Theme.surfaceContainerLow }
                EqualizerPreview { anchors.fill:parent; anchors.margins:8; profile:root.state.status.equalizer || "normal"; Accessible.name:"Illustrative equalizer preset preview" }
            }
            Grid {
                id:eqGrid
                width:parent.width; columns:3; spacing:6
                Repeater {
                    model:["normal","bass","soft","dynamic","clear","treble"]
                    DButton {
                        required property string modelData
                        width:(eqGrid.width-12)/3
                        buttonHeight:36
                        text:modelData[0].toUpperCase()+modelData.slice(1)
                        checked:root.state.status.equalizer===modelData
                        checkable:true
                        backgroundColor:checked ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        textColor:checked ? Theme.onPrimaryContainer : Theme.surfaceText
                        enabled:!root.state.busy
                        onClicked:root.state.request("eq",[modelData])
                    }
                }
            }
        }
    }

    DCard {
        width:parent.width
        visible:Policy.available(root.state.device.features,"ambient_volume")
        implicitHeight:amplificationContent.implicitHeight+24
        pad:12
        Column {
            id:amplificationContent
            width:parent.width; spacing:8
            Row {
                width:parent.width; spacing:9
                DIcon { anchors.verticalCenter:parent.verticalCenter; name:"volume_up"; size:20; color:Theme.primary }
                Column {
                    width:parent.width-30; spacing:2
                    StyledText { text:"Ambient amplification"; color:Theme.surfaceText; font.pixelSize:13; font.weight:Font.DemiBold }
                    StyledText { text:"Level "+(root.state.status.ambient_volume || 0); color:Theme.surfaceVariantText; font.pixelSize:11 }
                }
            }
            DSlider {
                width:parent.width
                minimum:0; maximum:root.state.device.features?.ambient_volume?.max_level || 1
                value:root.state.status.ambient_volume || 0
                onSliderValueChanged:value=>root.state.request("ambient-volume",[String(Math.round(value))])
            }
        }
    }

    DCard {
        width:parent.width
        visible:Policy.available(root.state.device.features,"voice_detect")
        height:64; pad:12
        Row {
            anchors.fill:parent; spacing:10
            Rectangle {
                width:40; height:40; radius:14; anchors.verticalCenter:parent.verticalCenter
                color:Theme.tertiaryContainer
                DIcon { anchors.centerIn:parent; name:"graphic_eq"; size:21; color:Theme.primary }
            }
            Column {
                width:parent.width-100; anchors.verticalCenter:parent.verticalCenter; spacing:3
                StyledText { width:parent.width; text:"Conversation detection"; color:Theme.surfaceText; font.pixelSize:13; font.weight:Font.DemiBold; elide:Text.ElideRight }
                StyledText { width:parent.width; text:root.state.status.voice_detect ? "Active" : "Off"; color:Theme.surfaceVariantText; font.pixelSize:11 }
            }
            DToggle {
                anchors.verticalCenter:parent.verticalCenter
                hideText:true
                checked:!!root.state.status.voice_detect
                text:"Conversation detection"
                Accessible.name:text
                enabled:!root.state.busy
                onToggled:value=>root.state.request("voice-detect",[value ? "on" : "off"])
            }
        }
    }

    DCard {
        width:parent.width
        visible:Policy.available(root.state.device.features,"blade_lights")
        implicitHeight:lightsContent.implicitHeight+24
        pad:12
        Column {
            id:lightsContent; width:parent.width; spacing:8
            Row {
                spacing:9
                DIcon { name:"light_mode"; size:20; color:Theme.primary }
                StyledText { text:"Blade lights"; color:Theme.surfaceText; font.pixelSize:13; font.weight:Font.DemiBold }
            }
            Row {
                width:parent.width; spacing:6
                Repeater {
                    model:["off","steady","fade","blink"]
                    DButton {
                        required property string modelData
                        width:(lightsContent.width-18)/4; buttonHeight:34
                        text:modelData[0].toUpperCase()+modelData.slice(1)
                        checked:root.state.status.blade_lights===modelData; checkable:true
                        backgroundColor:checked ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                        textColor:checked ? Theme.onSecondaryContainer : Theme.surfaceText
                        enabled:!root.state.busy
                        onClicked:root.state.request("lights",[modelData])
                    }
                }
            }
        }
    }
}
