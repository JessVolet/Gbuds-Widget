import QtQuick
import qs.Common
Rectangle { property int pad:12; property bool clickable:false; property bool interactive:true; signal clicked(); color:Theme.surfaceContainer; radius:20; MouseArea { anchors.fill:parent; enabled:parent.clickable; onClicked:parent.clicked() } }
