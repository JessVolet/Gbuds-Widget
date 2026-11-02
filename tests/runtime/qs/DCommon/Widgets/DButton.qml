import QtQuick
import qs.Common
Rectangle {
    id:root
    property string text
    property string iconName
    property int buttonHeight:32
    property int minimumWidth
    property color backgroundColor:Theme.surfaceContainerHigh
    property color textColor:Theme.surfaceText
    property bool checkable
    property bool checked
    signal clicked()
    height:buttonHeight
    radius:8
    color:checked ? Theme.primaryContainer : backgroundColor
    Text { anchors.centerIn:parent; text:root.text || (root.iconName === "close" ? "×" : ""); color:root.textColor; font.pixelSize:12 }
    MouseArea { anchors.fill:parent; onClicked:root.clicked() }
}
