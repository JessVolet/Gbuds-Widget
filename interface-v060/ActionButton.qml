import QtQuick
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Rectangle {
    id: root
    property string text: ""
    property bool selected: false
    signal clicked()
    implicitWidth: 100
    implicitHeight: 30
    radius: Theme.cornerRadiusS
    color: selected || mouse.containsMouse && enabled ? Theme.primaryContainer : Theme.withAlpha(Theme.surfaceContainerHigh, 0.65)
    border.width: activeFocus ? 2 : 0
    border.color: Theme.primary
    opacity: enabled ? 1 : 0.5
    activeFocusOnTab: enabled && visible
    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.onPressAction: if (enabled) root.clicked()
    StyledText {
        anchors.centerIn: parent
        text: root.text
        color: Theme.surfaceText
        font.pixelSize: Theme.fontSizeSmall
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
    Keys.onReturnPressed: if (enabled) root.clicked()
    Keys.onSpacePressed: if (enabled) root.clicked()
}
