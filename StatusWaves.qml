import QtQuick

Item {
    id: root

    property bool active: false
    property color waveColor: "#d34b45"
    property int duration: 1800

    visible: active
    opacity: active ? 1 : 0

    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Math.min(width, height) / 2
            color: "transparent"
            border.width: 1.5
            border.color: root.waveColor
            opacity: 0
            scale: 0.9

            SequentialAnimation on opacity {
                running: root.active
                loops: Animation.Infinite
                PauseAnimation { duration: index * root.duration / 3 }
                NumberAnimation { from: 0.55; to: 0; duration: root.duration }
            }
            SequentialAnimation on scale {
                running: root.active
                loops: Animation.Infinite
                PauseAnimation { duration: index * root.duration / 3 }
                NumberAnimation { from: 0.9; to: 1.65; duration: root.duration; easing.type: Easing.OutCubic }
            }
        }
    }
}
