import QtQuick
import qs.Common
import "ApprovedIcons.js" as Icons
import "ArtworkResolver.js" as Artwork

Item {
    id: root
    property string part: "left"
    property var device: ({})
    property string artwork: "svg"
    property color tint: Theme.primary
    property bool filled:false
    property color fillTint:Theme.withAlpha(tint,0.16)
    property color idleTint:Theme.warning
    property bool idle: false
    property bool available: true
    implicitWidth: 48
    implicitHeight: 48
    Image {
        id: image
        anchors.fill: parent
        source: root.artwork === "svg" ? Icons.url(root.part === "case" ? "case" : "bud-" + root.part,root.tint,root.fillTint,root.filled)
            : Qt.resolvedUrl(Artwork.source(root.device, root.part, root.artwork))
        fillMode: Image.PreserveAspectFit
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        opacity: root.available ? 1 : 0.3
        onStatusChanged: if (status === Image.Error) source = Icons.url(root.part === "case" ? "case" : "bud-" + root.part,root.tint,root.fillTint,root.filled)
    }
    Rectangle {
        visible: root.idle && root.available && root.part !== "case"
        width: Math.max(14, root.width * 0.43)
        height: width
        radius: width / 2
        color: Theme.surfaceContainer
        x: root.width * 0.60
        y: root.height * 0.52
        Image {
            anchors.fill: parent
            source: Icons.url("idle-timer", root.idleTint, root.idleTint, false)
            fillMode: Image.PreserveAspectFit
        }
    }
}
