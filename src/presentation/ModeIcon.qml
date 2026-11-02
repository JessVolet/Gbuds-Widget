import QtQuick
import qs.Common
import "ApprovedIcons.js" as Icons
Item {
    id: root
    property string mode: "OFF"
    property color tint: Theme.primary
    property int size: 32
    implicitWidth: size
    implicitHeight: size
    Image {
        anchors.fill: parent
        source: Icons.url(root.mode === "NOISE_REDUCTION" ? "mode-anc" : root.mode === "AMBIENT_SOUND" || root.mode === "ADAPTIVE" ? "mode-ambient" : "mode-normal", root.tint, root.tint, false)
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
    }
}
