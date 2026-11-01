import QtQuick
Rectangle {
property string text
property string iconName
property int buttonHeight: 32
property int minimumWidth
property color backgroundColor
property color textColor
property bool checkable
property bool checked
signal clicked()
height: buttonHeight
}
