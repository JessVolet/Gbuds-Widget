pragma Singleton
import QtQuick
QtObject { function runCommand(id, command, callback, debounce, timeout, owner) { Qt.callLater(function() { callback("",0); }); } }
