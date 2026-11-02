import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../device/Policy.js" as Policy

Column {
    id:root
    required property var state
    spacing:8
    DButton {
        width:parent.width
        visible:Policy.available(root.state.device.features,"touchpad")
        text:root.state.status.touchpad_locked ? "Unlock touch controls" : "Lock touch controls"
        enabled:!root.state.busy
        onClicked:root.state.request("touchpad",[root.state.status.touchpad_locked ? "unlock" : "lock"])
    }
    DButton {
        width:parent.width
        visible:Policy.available(root.state.device.features,"voice_detect")
        text:root.state.status.voice_detect ? "Turn conversation detection off" : "Turn conversation detection on"
        enabled:!root.state.busy
        onClicked:root.state.request("voice-detect",[root.state.status.voice_detect ? "off" : "on"])
    }
    StyledText { visible:eqGrid.visible; text:"Equalizer"; color:Theme.surfaceVariantText; font.pixelSize:12 }
    Grid {
        id:eqGrid
        width:parent.width; columns:3; spacing:6
        visible:Policy.available(root.state.device.features,"equalizer")
        Repeater {
            model:["normal","bass","soft","dynamic","clear","treble"]
            DButton { required property string modelData; width:(eqGrid.width-12)/3; text:modelData[0].toUpperCase()+modelData.slice(1); checked:root.state.status.equalizer === modelData; checkable:true; enabled:!root.state.busy; onClicked:root.state.request("eq",[modelData]) }
        }
    }
    StyledText { visible:amplification.visible; text:"Ambient amplification"; color:Theme.surfaceVariantText; font.pixelSize:12 }
    DSlider {
        id:amplification
        width:parent.width
        visible:Policy.supported(root.state.device.features,"ambient_volume")
        minimum:0; maximum:root.state.device.features?.ambient_volume?.max_level || 1
        value:root.state.status.ambient_volume || 0
        onSliderValueChanged: value => root.state.request("ambient-volume",[String(Math.round(value))])
    }
    Row {
        width:parent.width; spacing:6
        visible:Policy.available(root.state.device.features,"blade_lights")
        Repeater { model:["off","steady","fade","blink"]; DButton { required property string modelData; width:(root.width-18)/4; text:modelData; enabled:!root.state.busy; onClicked:root.state.request("lights",[modelData]) } }
    }
}
