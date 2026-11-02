import QtQuick
import qs.Services
import "AudioPolicy.js" as Policy

Item {
    id:root
    property bool active:false
    property string address:""
    property bool acquired:false
    readonly property var nodes:AudioService.pipewireNodes || []
    readonly property var output:Policy.output(nodes,address)
    readonly property bool available:!!output?.audio
    readonly property bool current:available && AudioService.sink===output
    readonly property real volume:available ? Math.round(output.audio.volume*100) : 0
    readonly property int maximum:available ? AudioService.getMaxVolumePercent(output) : 100
    readonly property bool muted:available && output.audio.muted
    readonly property var streams:nodes.filter(node=>node.audio && node.isSink && node.isStream && !AudioService.isOwnStream(node))
    function sync() {
        if (active===acquired) return;
        if (active) AudioService.addRef(); else AudioService.removeRef();
        acquired=active;
    }
    function setVolume(value) {
        if (!available) return;
        output.audio.volume=Math.max(0,Math.min(maximum,value))/100;
        if (value>0) output.audio.muted=false;
    }
    function mute() { if (available) output.audio.muted=!output.audio.muted; }
    function selectOutput() { if (available) AudioService.setSink(output); }
    onActiveChanged:sync()
    Component.onCompleted:sync()
    Component.onDestruction:if (acquired) AudioService.removeRef()
}
