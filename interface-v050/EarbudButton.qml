import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

ActionButton {
    id: root
    objectName: "find-" + side
    required property var actions
    property string side: "left"
    property string modelCode: ""
    property bool available: true
    property bool idle: false
    property color tint: Theme.primary
    readonly property bool ringing: actions.ringing(side)
    width: 48; height: 48
    text: ""
    selected: ringing
    enabled: ringing || actions.canFind(side)
    // Keep artwork at full contrast even while a bud is being worn.
    opacity: 1
    color: ringing || activeFocus ? Theme.primaryContainer : "transparent"
    Accessible.name: ringing ? "Stop finding " + side + " earbud" : "Find " + side + " earbud"
    Accessible.description: ringing ? "Click again to stop." : !enabled ? "Remove the earbud from your ear and case to find it." :
        ((actions.device.features || {}).find_earbuds || {}).device_support === "unknown" ? "Gbuds does not classify find support for this model." : "Click to ring this earbud."
    onClicked: actions.find(side)
    EarbudGlyph {
        anchors.fill: parent
        part: root.side
        modelCode: root.modelCode
        available: root.available
        idle: root.idle && !root.ringing
        tint: root.tint
        badgeColor: Theme.surfaceContainer
    }
    DIcon {
        visible: root.ringing
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        name: "stop_circle"
        size: 19
        color: Theme.primary
    }
}
