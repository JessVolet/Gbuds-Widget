import QtQuick
import qs.Common
import qs.DCommon.Widgets
Item {
    id: root
    property string mode: "OFF"
    property color tint: Theme.primary
    property int size: 32
    implicitWidth: size
    implicitHeight: size
    DIcon {
        anchors.fill: parent
        name: root.mode === "NOISE_REDUCTION" ? "noise_control_on" : root.mode === "AMBIENT_SOUND" || root.mode === "ADAPTIVE" ? "hearing" : "power_settings_new"
        size: root.size
        color: root.tint
        Accessible.ignored: true
    }
}
