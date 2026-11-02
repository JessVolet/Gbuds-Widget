import QtQuick
import qs.Common
import "ApprovedIcons.js" as Icons
import "ArtworkResolver.js" as Artwork

Item {
    id:root
    property string part:"left"
    property var device:({})
    property string artwork:"svg"
    property color tint:Theme.primary
    property bool filled:false
    property color fillTint:Theme.withAlpha(tint,0.16)
    property color idleTint:Theme.warning
    property bool idle:false
    property bool available:true
    readonly property string renderPath:Artwork.source(device,part,artwork)
    implicitWidth:48
    implicitHeight:48
    opacity:available ? 1 : 0.3
    Image {
        id:render
        anchors.fill:parent
        source:root.renderPath ? Qt.resolvedUrl(root.renderPath) : ""
        visible:root.renderPath !== "" && status !== Image.Error
        fillMode:Image.PreserveAspectFit
        sourceSize.width:Math.ceil(width*2)
        sourceSize.height:Math.ceil(height*2)
    }
    Image {
        anchors.fill:parent
        visible:!root.renderPath || render.status === Image.Error
        source:Icons.url(root.part === "case" ? "case" : "bud-"+root.part,root.tint,root.fillTint,root.filled)
        fillMode:Image.PreserveAspectFit
        sourceSize.width:Math.ceil(width*2)
        sourceSize.height:Math.ceil(height*2)
    }
    Rectangle {
        visible:root.idle && root.available && root.part !== "case"
        width:Math.max(14,root.width*0.43)
        height:width
        radius:width/2
        color:Theme.surfaceContainer
        x:root.width*0.60; y:root.height*0.52
        Image { anchors.fill:parent; source:Icons.url("idle-timer",root.idleTint,root.idleTint,false); fillMode:Image.PreserveAspectFit }
    }
}
