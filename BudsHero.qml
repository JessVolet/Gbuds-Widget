import QtQuick
import QtQuick.Effects
import qs.Common
import qs.Widgets
import qs.DCommon.Widgets

Rectangle {
    id: root

    property var device: ({})
    property var status: ({})
    property bool connected: false
    property bool busy: false
    property bool desktopMode: false
    property int lowThreshold: 20
    property color accentColor: Theme.primary
    property color caseColor: "#8ea6b4"
    property string caseColorMode: "auto"
    property url leftImageSource: ""
    property url rightImageSource: ""

    readonly property color caseBaseColorLight: Qt.lighter(root.caseColor, 1.25)
    readonly property color caseBaseColorDark: Qt.darker(root.caseColor, 1.35)
    readonly property color caseBorderColor: Qt.lighter(root.caseColor, 1.35)
    readonly property color caseSeamColor: Qt.darker(root.caseColor, 1.45)

    signal devicesClicked()
    signal terminalClicked()
    signal settingsClicked()

    width: parent.width
    height: 210
    radius: 26
    clip: true
    color: "transparent"

    function batteryText(value) {
        return typeof value === "number" ? value + "%" : "—";
    }

    function batteryTint(value) {
        if (typeof value !== "number") return "#93a7b4";
        if (value <= lowThreshold) return "#ffb8ad";
        if (value <= 40) return "#f5d397";
        return "#b8efd0";
    }

    function modeIcon(mode) {
        if (mode === "NOISE_REDUCTION") return "noise_control_on";
        if (mode === "AMBIENT_SOUND") return "hearing";
        if (mode === "ADAPTIVE") return "auto_mode";
        return "noise_control_off";
    }

    Rectangle {
        width: 270; height: 270; radius: 135
        anchors.horizontalCenter: parent.horizontalCenter
        y: 9
        color: "transparent"
        border.color: "#2a8494a4"
        border.width: 1
        opacity: root.connected ? 0.65 : 0.3
        SequentialAnimation on scale {
            running: root.connected
            loops: Animation.Infinite
            NumberAnimation { to: 1.09; duration: 2700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 2700; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        width: 200; height: 200; radius: 100
        anchors.horizontalCenter: parent.horizontalCenter
        y: 42
        color: "#103f5963"
        border.color: "#31789a9f"
        border.width: 1
    }

    Rectangle {
        width: 120; height: 120; radius: 60
        anchors.horizontalCenter: parent.horizontalCenter
        y: 80
        color: "#184f6870"
    }

    Rectangle {
        width: 48; height: parent.height * 1.8
        x: -90; y: -parent.height * 0.35
        rotation: 24
        color: "#d4fff4"
        opacity: root.connected ? 0.09 : 0
        SequentialAnimation on x {
            running: root.connected
            loops: Animation.Infinite
            PauseAnimation { duration: 2400 }
            NumberAnimation { from: -90; to: root.width + 60; duration: 1800; easing.type: Easing.InOutSine }
            PauseAnimation { duration: 4800 }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 0

        Row {
            width: parent.width
            height: 30
            spacing: 10

            Row {
                width: parent.width - headerActions.width - 10
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                    Rectangle {
                        width: 6; height: 6; radius: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.connected ? "#8de0ad" : "#8e9dab"
                        SequentialAnimation on opacity {
                            running: root.connected
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 950 }
                            NumberAnimation { to: 1; duration: 950 }
                        }
                    }
                    StyledText {
                        text: root.connected ? (root.device.model_code || "Galaxy Buds") + " · Connected" :
                              root.busy ? "Applying…" : "Disconnected"
                        color: root.connected ? "#a9d9bd" : "#b7c6d0"
                        font.pixelSize: 11
                    }
            }

            Row {
                id: headerActions
                spacing: 3
                DButton {
                    width: 30; buttonHeight: 30; minimumWidth: 0
                    iconName: "devices"; text: ""
                    backgroundColor: "#34556a"
                    textColor: "#f4f9f7"
                    Accessible.name: "Choose Galaxy Buds device"
                    onClicked: root.devicesClicked()
                }
                DButton {
                    width: 30; buttonHeight: 30; minimumWidth: 0
                    iconName: "terminal"; text: ""
                    backgroundColor: "#34556a"
                    textColor: "#f4f9f7"
                    Accessible.name: "Show Gbuds console"
                    onClicked: root.terminalClicked()
                }
                DButton {
                    width: 30; buttonHeight: 30; minimumWidth: 0
                    iconName: "settings"; text: ""
                    backgroundColor: "#34556a"
                    textColor: "#f4f9f7"
                    Accessible.name: "Open widget settings"
                    onClicked: root.settingsClicked()
                }
            }
        }

        Item { width: 1; height: 4 }

        Row {
            width: parent.width
            height: 128
            spacing: 8
            Repeater {
                model: [
                    { key: "left", title: "LEFT", source: root.leftImageSource, icon: "earbuds", charging: root.status.left_charging },
                    { key: "case", title: "CASE", source: "", icon: "inventory_2", charging: root.status.case_charging },
                    { key: "right", title: "RIGHT", source: root.rightImageSource, icon: "earbuds", charging: root.status.right_charging }
                ]
                delegate: Column {
                    required property var modelData
                    width: (parent.width - 16) / 3
                    height: parent.height
                    spacing: 4

                    Item {
                        width: parent.width
                        height: 66

                        // --- Earbud 3D Render (Left & Right) ---
                        Image {
                            id: budImage
                            visible: modelData.key !== "case" && source.toString() !== ""
                            width: parent.width * 0.78
                            height: parent.height * 0.85
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 5
                            source: modelData.source
                            sourceSize.width: 256
                            sourceSize.height: 256
                            fillMode: Image.PreserveAspectFit
                            opacity: root.connected ? 1 : 0.45
                            SequentialAnimation on y {
                                running: root.connected && budImage.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 2200; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 7; duration: 2200; easing.type: Easing.InOutSine }
                            }
                        }

                        // --- Galaxy Buds Charging Case (case.svg with DMS Accent Fill & Battery Border) ---
                        Item {
                            id: caseVisual
                            visible: modelData.key === "case"
                            width: 58; height: 60
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 5
                            opacity: root.connected ? 1 : 0.45

                            SequentialAnimation on y {
                                running: root.connected && caseVisual.visible
                                loops: Animation.Infinite
                                NumberAnimation { to: 0; duration: 2200; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 7; duration: 2200; easing.type: Easing.InOutSine }
                            }

                            // Layer 1: Case Fill (DMS Accent / Theme.primary)
                            Image {
                                id: caseFillImage
                                anchors.centerIn: parent
                                width: 54; height: 56
                                source: Qt.resolvedUrl("assets/icons/case_fill.svg")
                                sourceSize.width: 128
                                sourceSize.height: 128
                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: caseFillImage
                                source: caseFillImage
                                colorization: 1.0
                                colorizationColor: root.accentColor
                                opacity: root.connected ? 0.45 : 0.2
                            }

                            // Layer 2: Case Border / Stroke (Battery state)
                            Image {
                                id: caseStrokeImage
                                anchors.centerIn: parent
                                width: 54; height: 56
                                source: Qt.resolvedUrl("assets/icons/case_stroke.svg")
                                sourceSize.width: 128
                                sourceSize.height: 128
                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }

                            MultiEffect {
                                anchors.fill: caseStrokeImage
                                source: caseStrokeImage
                                colorization: 1.0
                                colorizationColor: root.batteryTint(root.status.case)
                                opacity: root.connected ? 1.0 : 0.45
                            }

                            // Interactive LED indicator on case
                            Rectangle {
                                id: caseLedIndicator
                                width: 5.5; height: 5.5; radius: 2.75
                                anchors.horizontalCenter: caseStrokeImage.horizontalCenter
                                y: caseStrokeImage.y + caseStrokeImage.height * (14.0 / 21.0) - height / 2
                                color: modelData.charging ? "#ffe2a3" : root.batteryTint(root.status.case)
                                SequentialAnimation on opacity {
                                    running: modelData.charging === true
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 900; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                }
                            }
                        }

                        // Fallback DIcon
                        Rectangle {
                            width: 50; height: 50; radius: 25
                            anchors.centerIn: parent
                            visible: modelData.key !== "case" && String(modelData.source || "") === ""
                            color: "#31576a"
                            border.color: "#55859a"
                            DIcon {
                                anchors.centerIn: parent
                                name: modelData.icon
                                size: 29
                                color: "#d2ece6"
                            }
                        }
                    }

                    StyledText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.title
                        color: "#aabfca"
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2
                        DIcon {
                            visible: modelData.charging === true
                            name: "bolt"
                            size: 14
                            color: root.batteryTint(root.status[modelData.key])
                        }
                        StyledText {
                            text: root.connected ? root.batteryText(root.status[modelData.key]) : "—"
                            color: root.batteryTint(root.status[modelData.key])
                            font.pixelSize: 19
                            font.weight: Font.Bold
                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }

                    Rectangle {
                        width: Math.min(parent.width - 14, 72)
                        height: 3
                        radius: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#496170"
                        Rectangle {
                            width: root.connected && typeof root.status[modelData.key] === "number" ? parent.width * Math.max(0, Math.min(1, root.status[modelData.key] / 100)) : 0
                            height: parent.height
                            radius: parent.radius
                            color: root.batteryTint(root.status[modelData.key])
                            Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#355165"
        }

        Row {
            width: parent.width
            height: 31
            spacing: 5
            DIcon {
                name: root.connected ? "bluetooth_connected" : "bluetooth_disabled"
                size: 14
                color: "#a9d9bd"
                anchors.verticalCenter: parent.verticalCenter
            }
            StyledText {
                width: parent.width - 42
                text: root.connected ? root.device.model || "Galaxy Buds" : "Connect your Galaxy Buds to begin"
                color: "#b5c9d2"
                font.pixelSize: 10
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
            DIcon {
                visible: root.connected && !!root.status.noise_control
                name: root.modeIcon(root.status.noise_control)
                size: 16
                color: "#b8efd0"
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
