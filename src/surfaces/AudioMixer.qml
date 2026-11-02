import QtQuick
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../audio"

DCard {
    id:root
    property bool active:false
    property string address:""
    property string deviceName:"Galaxy Buds"
    property bool applicationsOpen:false
    pad:14
    implicitHeight:body.implicitHeight+pad*2
    AudioAdapter { id:audio; active:root.active; address:root.address }
    Column {
        id:body; width:parent.width; spacing:8
        Row {
            width:parent.width; spacing:8
            DIconButton { iconName:audio.muted ? "volume_off" : "volume_up"; tooltipText:audio.muted ? "Unmute" : "Mute"; enabled:audio.available; onClicked:audio.mute() }
            StyledText { text:"Mixer"; color:Theme.surfaceText; font.pixelSize:14; font.weight:Font.DemiBold; anchors.verticalCenter:parent.verticalCenter; width:Math.max(0,parent.width-96) }
            StyledText { text:audio.available ? audio.volume+"%" : "—"; color:Theme.surfaceVariantText; font.pixelSize:12; anchors.verticalCenter:parent.verticalCenter }
        }
        DSlider { width:parent.width; enabled:audio.available; minimum:0; maximum:audio.maximum; value:audio.volume; showValue:false; Accessible.name:"Buds output volume"; onSliderValueChanged:value=>audio.setVolume(value) }
        StyledText { width:parent.width; text:audio.available ? "Output · "+root.deviceName : "Buds audio output is unavailable."; color:Theme.surfaceVariantText; font.pixelSize:11; wrapMode:Text.WordWrap }
        DButton { width:parent.width; text:"Use as output"; iconName:"speaker"; visible:audio.available && !audio.current; onClicked:audio.selectOutput() }
        DCollapsibleSection {
            width:parent.width; title:"Applications"; description:"All playback streams"; expanded:root.applicationsOpen
            onExpandedChanged:root.applicationsOpen=expanded
            Column {
                width:parent.width; spacing:8
                StyledText { text:"No playback applications."; visible:!audio.streams.length; color:Theme.surfaceVariantText; font.pixelSize:12 }
                Repeater {
                    model:root.active && root.applicationsOpen ? audio.streams : []
                    Column {
                        required property var modelData
                        width:parent.width; spacing:4
                        StyledText { width:parent.width; text:AudioService.displayName(modelData); color:Theme.surfaceText; font.pixelSize:12; elide:Text.ElideRight }
                        DSlider { width:parent.width; minimum:0; maximum:AudioService.getMaxVolumePercent(modelData); value:Math.round(modelData.audio.volume*100); Accessible.name:AudioService.displayName(modelData)+" volume"; onSliderValueChanged:value=>{ modelData.audio.volume=value/100; if(value>0) modelData.audio.muted=false; } }
                    }
                }
            }
        }
    }
}
