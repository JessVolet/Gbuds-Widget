import QtQuick
import qs.Common
import "../assets/Icons.js" as Icons

Item {
    id: root
    property string part: "left"
    property string modelCode: ""
    property color tint: Theme.primary
    property color fillTint: Theme.withAlpha(tint, 0.14)
    property color badgeColor: Theme.surfaceContainerHighest
    property color idleColor: Theme.surfaceVariantText
    property bool available: true
    property bool idle: false
    property bool filled: true
    implicitWidth: 20
    implicitHeight: 28
    Image {
        anchors.fill: parent
        source: Icons.earbud(root.part, root.modelCode, root.tint, root.fillTint, root.filled)
        sourceSize.width: Math.ceil(width * 2)
        sourceSize.height: Math.ceil(height * 2)
        fillMode: Image.PreserveAspectFit
        opacity: root.available ? (root.idle ? 0.65 : 1) : 0.3
    }
    Rectangle {
        visible: root.idle && root.available && root.part !== "case"
        width: Math.max(10, Math.round(root.height * 0.39))
        height: width
        radius: width / 2
        color: root.badgeColor
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -2
        Image {
            anchors.fill: parent
            anchors.margins: 1
            source: Icons.idle(root.idleColor)
            sourceSize.width: 32
            sourceSize.height: 32
        }
    }
}
