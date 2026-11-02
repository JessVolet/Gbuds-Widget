pragma Singleton
import QtQuick
QtObject {
 property var pipewireNodes:[]
 property var sink:null
 property int refCount:0
 function addRef() { refCount++; }
 function removeRef() { refCount=Math.max(0,refCount-1); }
 function getMaxVolumePercent(node) { return 100; }
 function isOwnStream(node) { return false; }
 function displayName(node) { return node.name || "Playback"; }
 function setSink(node) { sink=node; }
}
