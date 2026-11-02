import QtQuick
Item {
 property string title
 property string subtitle
 property string iconName
 default property alias body:container.data
 implicitHeight:72
 Item { id:container; width:parent.width; height:parent.height }
}
