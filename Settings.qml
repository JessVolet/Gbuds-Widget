import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root
    pluginId: "gbudsWatch"

    StyledText {
        width: parent.width
        text: "Gbuds Watch"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Choose the executable used for passive Galaxy Buds telemetry. The daemon keeps one gbuds watch process for both the bar pill and desktop card."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StringSetting {
        settingKey: "gbudsCommand"
        label: "Gbuds executable"
        description: "Use gbuds if it is on DMS PATH, or enter an absolute executable path."
        placeholder: "gbuds"
        defaultValue: "gbuds"
    }
}
