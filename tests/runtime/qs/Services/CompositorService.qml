pragma Singleton
import QtQuick
import Quickshell
QtObject {
    function getFocusedScreen() { return Quickshell.screens.length ? Quickshell.screens[0] : null }
}
