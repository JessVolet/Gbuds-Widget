import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../presentation"

Row {
    id: root
    required property var state
    property bool readOnly: false
    property bool animate:true
    property int iconSize: 36
    spacing: 6
    readonly property var modes:["on","ambient","adaptive","off"].filter(mode=>(state.device.supported_noise_modes || []).indexOf(mode)>=0)
    height: modes.length ? iconSize + 38 : 0
    Repeater {
        model: root.modes
        FocusScope {
            id: button
            required property string modelData
            readonly property string mode: ({off:"Off",on:"NOISE_REDUCTION",ambient:"AMBIENT_SOUND",adaptive:"ADAPTIVE"})[modelData]
            readonly property bool selected: root.state.mode === mode
            width: (root.width - Math.max(0,root.modes.length-1)*root.spacing) / Math.max(1,root.modes.length)
            height: root.height
            activeFocusOnTab: !root.readOnly && root.state.connected
            function activate() { if (!root.readOnly && root.state.connected) root.state.request("anc",[modelData]); }
            Accessible.role:Accessible.Button
            Accessible.name: label.text
            Keys.onReturnPressed: activate()
            Keys.onSpacePressed: activate()
            Rectangle {
                anchors.fill:parent; radius:14
                color:button.selected ? Theme.selectedContainer : Theme.withAlpha(Theme.surfaceContainerHigh,0.8)
                border.width:button.activeFocus ? 2 : 0; border.color:Theme.primary
                Behavior on color { enabled:root.animate && !SettingsData.reduceMotion; ColorAnimation { duration:Theme.mediumDuration } }
            }
            Column {
                anchors.centerIn:parent; spacing:5
                ModeIcon { anchors.horizontalCenter:parent.horizontalCenter; mode:button.mode; size:Math.min(root.iconSize,button.width-16); tint:button.selected ? Theme.onSelectedContainer : Theme.surfaceVariantText }
                StyledText { id:label; anchors.horizontalCenter:parent.horizontalCenter; text:({off:"Off",on:"ANC",ambient:"Ambient",adaptive:"Adaptive"})[button.modelData]; color:button.selected ? Theme.onSelectedContainer : Theme.surfaceText; font.pixelSize:11 }
            }
            MouseArea { anchors.fill:parent; cursorShape:Qt.PointingHandCursor; onClicked:button.activate() }
        }
    }
}
