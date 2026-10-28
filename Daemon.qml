import QtQuick
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root

    property string cliCommand: pluginData.gbudsCommand || "gbuds"
    property var watchProcess: null
    property var lastStatus: null
    property var device: null
    property string lastError: ""
    property int retryDelay: 1000
    property bool shuttingDown: false

    function publish(phase, detail, status, eventText) {
        root.pluginService.setGlobalVar(root.pluginId, "telemetry", {
            phase: phase,
            detail: detail || "",
            status: status || null,
            event: eventText || "",
            updatedAt: Date.now()
        });
    }

    function describeChange(previous, next) {
        if (!previous)
            return "Live telemetry received";
        if (previous.noise_control !== next.noise_control && next.noise_control)
            return "Noise control: " + next.noise_control.replace(/_/g, " ");
        if (previous.placement_left !== next.placement_left)
            return "Left earbud: " + (next.placement_left || "unknown").replace(/_/g, " ");
        if (previous.placement_right !== next.placement_right)
            return "Right earbud: " + (next.placement_right || "unknown").replace(/_/g, " ");
        if (previous.left !== next.left)
            return "Left battery: " + next.left + "%";
        if (previous.right !== next.right)
            return "Right battery: " + next.right + "%";
        if (previous.case !== next.case)
            return "Case battery updated";
        if (previous.equalizer !== next.equalizer && next.equalizer)
            return "Equalizer: " + next.equalizer.replace(/_/g, " ");
        if (previous.touchpad_locked !== next.touchpad_locked && next.touchpad_locked !== null)
            return "Touchpad state updated";
        return "Buds status updated";
    }

    function acceptTelemetry(line) {
        var parsed;
        try {
            parsed = JSON.parse(line);
        } catch (error) {
            root.lastError = "Gbuds returned an invalid JSON status line.";
            console.warn("[gbudsWatch] " + root.lastError);
            return;
        }

        if (!parsed || typeof parsed.left !== "number" || typeof parsed.right !== "number") {
            root.lastError = "Gbuds returned JSON without left/right battery values.";
            console.warn("[gbudsWatch] " + root.lastError);
            return;
        }

        var eventText = root.describeChange(root.lastStatus, parsed);
        root.lastStatus = parsed;
        root.lastError = "";
        root.retryDelay = 1000;
        root.publish("connected", "", parsed, eventText);
    }

    function recordError(line) {
        var message = line.trim();
        if (!message)
            return;
        root.lastError = message;
        console.warn("[gbudsWatch] " + message);
    }

    function startWatcher() {
        if (root.shuttingDown || root.watchProcess)
            return;

        root.lastError = "";
        root.publish("connecting", "Looking for a connected Galaxy Buds device.", root.lastStatus, "");
        root.watchProcess = watcherComponent.createObject(root);
        if (root.watchProcess)
            root.watchProcess.running = true;
    }

    function acceptDeviceInfo(text) {
        try {
            var result = JSON.parse(text);
            if (result && result.success && result.device) {
                root.device = result.device;
                root.pluginService.setGlobalVar(root.pluginId, "device", result.device);
            }
        } catch (error) {
            console.warn("[gbudsWatch] Could not parse gbuds info metadata.");
        }
    }

    function handleExit(process, exitCode) {
        if (root.shuttingDown || process !== root.watchProcess)
            return;

        root.watchProcess = null;
        process.destroy();
        root.publish("waiting", root.lastError || ("gbuds watch exited with code " + exitCode + "."), root.lastStatus, "Connection interrupted");
        reconnectTimer.interval = root.retryDelay;
        reconnectTimer.start();
        root.retryDelay = Math.min(root.retryDelay * 2, 15000);
    }

    function checkCli() {
        Proc.runCommand(null, ["/bin/sh", "-c", "command -v -- \"$1\" >/dev/null 2>&1", "gbuds-watch-check", root.cliCommand], (stdout, exitCode) => {
            if (exitCode === 0) {
                var info = infoComponent.createObject(root);
                if (info)
                    info.running = true;
                else
                    root.startWatcher();
                return;
            }

            root.publish("missing-cli", "Install Gbuds CLI to enable live telemetry.", null, "");
        }, 0, 5000, root);
    }

    Component {
        id: infoComponent

        Process {
            id: infoRunner
            command: [root.cliCommand, "info", "--json"]
            running: false
            property string output: ""

            stdout: SplitParser {
                onRead: line => infoRunner.output += line + "\n"
            }

            onExited: (exitCode) => {
                if (exitCode === 0)
                    root.acceptDeviceInfo(infoRunner.output);
                infoRunner.output = "";
                root.startWatcher();
                infoRunner.destroy();
            }
        }
    }

    Component {
        id: watcherComponent

        Process {
            id: runner
            command: [root.cliCommand, "watch", "--json"]
            running: false

            stdout: SplitParser {
                onRead: line => root.acceptTelemetry(line)
            }

            stderr: SplitParser {
                onRead: line => root.recordError(line)
            }

            onExited: (exitCode) => root.handleExit(runner, exitCode)
        }
    }

    Timer {
        id: reconnectTimer
        repeat: false
        onTriggered: root.checkCli()
    }

    Component.onCompleted: {
        root.publish("checking-cli", "Checking for the gbuds executable.", null, "");
        root.checkCli();
    }

    Component.onDestruction: {
        root.shuttingDown = true;
        reconnectTimer.stop();
        if (root.watchProcess) {
            var process = root.watchProcess;
            root.watchProcess = null;
            process.running = false;
            process.destroy();
        }
    }
}
