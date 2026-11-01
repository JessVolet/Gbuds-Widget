import QtQuick
import qs.Common
import "./ApprovedIcons.js" as Artwork

Item {
    id: root
    property string part: "left"
    property string modelCode: ""
    property color tint: Theme.primary
    property color fillTint: Theme.withAlpha(tint, 0.14)
    property color badgeColor: Theme.surfaceContainerHighest
    property color idleColor: Theme.warning
    property bool available: true
    property bool idle: false
    property bool filled: false
    implicitWidth: 32
    implicitHeight: 32
    Image {
        anchors.fill: parent
        source: Artwork.url(root.part === "case" ? "case" : "bud-" + root.part, root.tint, root.fillTint, root.filled)
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
        opacity: root.available ? 1 : 0.3
    }
    Rectangle {
        visible: root.idle && root.available && root.part !== "case"
        width: Math.max(16, Math.round(root.height * 0.57))
        height: width
        radius: width / 2
        color: root.badgeColor
        x: root.width * 0.595
        y: root.height * 0.515
        Image {
            anchors.fill: parent
            anchors.margins: parent.width * 0.085
            source: Artwork.url("idle-timer", root.idleColor, root.idleColor, false)
            sourceSize.width: Math.ceil(width * 2)
            sourceSize.height: Math.ceil(height * 2)
        }
    }
}
