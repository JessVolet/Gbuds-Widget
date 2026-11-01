import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets

Column {
    id: root
    property var preferences: ["all"]
    signal selectionChanged(var value)
    width: parent ? parent.width : 300
    spacing: Theme.spacingS

    function contains(name) { return preferences.indexOf("all") >= 0 || preferences.indexOf(name) >= 0 }
    function toggleScreen(name, checked) {
        var values = preferences.indexOf("all") >= 0 ? Quickshell.screens.map(screen => screen.name) : preferences.slice();
        if (checked && values.indexOf(name) < 0) values.push(name);
        if (!checked) values = values.filter(value => value !== name);
        var allNames = Quickshell.screens.map(screen => screen.name);
        if (allNames.length && values.length === allNames.length) values = ["all"];
        preferences = values;
        selectionChanged(values);
    }

    Row {
        width: parent.width
        spacing: Theme.spacingM
        Column {
            width: parent.width - allToggle.width - Theme.spacingM
            StyledText { text: "Mostrar en todas las pantallas"; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeLarge; width: parent.width }
            StyledText { text: "Cada salida guarda su propia posición; puedes sincronizarla abajo."; color: Theme.surfaceVariantText; font.pixelSize: Theme.fontSizeSmall; wrapMode: Text.WordWrap; width: parent.width }
        }
        DToggle {
            id: allToggle
            anchors.verticalCenter: parent.verticalCenter
            checked: root.preferences.indexOf("all") >= 0
            onToggled: checked => {
                root.preferences = checked ? ["all"] : [];
                root.selectionChanged(root.preferences);
            }
        }
    }

    Repeater {
        model: Quickshell.screens
        delegate: Row {
            required property var modelData
            width: root.width
            spacing: Theme.spacingM
            StyledText { width: parent.width - screenToggle.width - Theme.spacingM; text: modelData.name; color: Theme.surfaceText; font.pixelSize: Theme.fontSizeMedium; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideMiddle }
            DToggle {
                id: screenToggle
                checked: root.contains(modelData.name)
                onToggled: checked => root.toggleScreen(modelData.name, checked)
            }
        }
    }
}
