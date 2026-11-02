import QtQuick
Item {
 property bool active:false
 property bool clickable:false
 signal clicked(bool keyboard)
 property string title
 property string subtitle
 property string iconName
 default property alias body:container.data
 implicitHeight:72
 Item { id:container; width:parent.width; height:parent.height }
}
