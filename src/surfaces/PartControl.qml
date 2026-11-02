import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../presentation"
import "../presentation/Layout.js" as Layout

FocusScope {
    id: root
    required property var state
    property string part: "left"
    property var config: ({})
    property bool readOnly: false
    readonly property bool ringing: state.findState.active && state.findState.side === part
    readonly property bool actionable: !readOnly && part !== "case" && (ringing || state.canFind(part))
    signal clicked()
    width:Layout.partWidth(config,part)
    height:Math.max(config.desktopEarbudSize || 48, config.desktopCaseSize || 48)+48
    activeFocusOnTab: actionable
    Accessible.role: Accessible.Button
    Accessible.name: ringing ? "Stop finding " + part + " earbud" : "Find " + part + " earbud"
    onClicked: if (actionable) state.findEar(part)
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.ringing || root.activeFocus ? Theme.primaryContainer : pointer.containsMouse && root.actionable ? Theme.withAlpha(Theme.primary,0.08) : "transparent"
        Behavior on color { ColorAnimation { duration:100 } }
    }
    Column {
        anchors.centerIn: parent
        spacing: 6
        Item {
            width:root.width
            height:Math.max(root.config.desktopEarbudSize || 48,root.config.desktopCaseSize || 48)
            PartIcon {
                anchors.centerIn:parent
                width:Layout.partSize(root.config,root.part)
                height:width
                part:root.part
                device:root.state.device
                artwork:root.config.desktopArtwork || "svg"
                idle:root.state.status["placement_"+root.part] === "IDLE"
                available:root.state.connected && (root.part === "case"
                    || root.state.status["placement_"+root.part] !== "DISCONNECTED")
                transform:Translate { y:Number(root.config.desktopVerticalOffset || 0) }
            }
        }
        StyledText {
            anchors.horizontalCenter:parent.horizontalCenter
            visible:root.config.desktopShowBattery !== false
            text:root.ringing ? "Stop" : (root.part === "left" ? "LEFT" : root.part === "right" ? "RIGHT" : "CASE") + "  " + root.state.battery(root.part)
            font.pixelSize:root.config.desktopTextSize || 11; color:Theme.surfaceText
        }
    }
    MouseArea { id:pointer; anchors.fill:parent; hoverEnabled:true; onClicked:root.clicked(); cursorShape:root.actionable ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
