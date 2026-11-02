import QtQuick
import qs.Modules.Plugins
import qs.Widgets
import "src/device"
import "src/events"
import "src/alerts"
import "src/config"

PluginComponent {
    id:root
    readonly property var config:preferences.value
    ConfigStore { id:preferences; source:root.pluginData }
    property alias controller:device
    property alias notifications:alerts
    property string lastPreview:""
    property bool ready:false
    Component.onCompleted:{ lastPreview=String(preview.value?.id || ""); ready=true; }
    DeviceController { id:device; config:root.config; service:root.pluginService; pluginId:root.pluginId }
    EventController { backend:device; config:root.config; onEmitted:event => alerts.add(event) }
    NotificationController { id:alerts; config:root.config }
    PluginGlobalVar { id:preview; varName:"notificationTest"; defaultValue:({}) }
    Connections {
        target:preview
        function onValueChanged() {
            if (!root.ready) return;
            const event=preview.value || {};
            if (!event.id || String(event.id) === root.lastPreview) return;
            root.lastPreview=String(event.id);
            alerts.add(Object.assign({},event,{device:device.state.device}));
        }
    }
}
