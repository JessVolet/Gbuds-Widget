import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "./ApprovedIcons.js" as Artwork

Item {
    id: root
    property string mode: "OFF"
    property int size: 32
    property color color: Theme.primary
    implicitWidth: size
    implicitHeight: size
    Image {
        anchors.fill: parent
        visible: root.mode !== "ADAPTIVE"
        source: Artwork.url(root.mode === "NOISE_REDUCTION" ? "mode-anc" : root.mode === "AMBIENT_SOUND" ? "mode-ambient" : "mode-normal", root.color, root.color, false)
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
    }
    DIcon {
        anchors.centerIn: parent
        visible: root.mode === "ADAPTIVE"
        name: "auto_mode"
        size: root.size
        color: root.color
    }
}
