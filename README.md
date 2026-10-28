# Gbuds Watch

Gbuds Watch is a Dux Shell 2.0 composite plugin for Galaxy Buds. A single background watcher reads `gbuds watch --json` and shares live telemetry with the bar pill, a control popout, and a resizable desktop widget.

The interface takes the supplied Galaxy Buds Dux Shell prototype as its starting point. A full-panel gradient frames live battery levels, noise controls, quick actions, and a collapsible sound list. Noise modes and the ambient-volume, voice-detection, and Blade Lights controls follow the detected model metadata. The bar pill shows an out-of-ear warning in red, switches to a disconnected icon when needed, and uses icons for noise mode. A small configurable status card covers connection, placement, noise-mode, and 30% / 10% battery transitions inside the widget; the plugin does not send desktop notifications.

## Requirements

- Dux Shell 2.0 or newer.
- The `gbuds` CLI installed and discoverable by the Dux Shell process.
- A paired, connected Galaxy Buds device supported by the installed Gbuds version.
- Bluetooth permissions and BlueZ configured as described in the [Gbuds installation guide](https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md).

When no Buds device is available, the widget stays visible and retries with a backoff. If multiple Buds are paired, select the target from the popout; the plugin tracks a uniquely connected Buds automatically.

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the Dux Shell checkout, QML language server setup, plugin symlink, live reload, and real-device testing.

## Design notes

The source prototype is `galaxy_buds_dux_shell_prototype.html`. `gbuds capabilities --json` supplies cached model metadata without opening RFCOMM, while one persistent `gbuds watch --json` process supplies status. Before a control command, the daemon stops that watcher, runs the requested Gbuds command, applies returned state immediately, then resumes monitoring. Earbud foreground renders are attributed in [assets/README.md](assets/README.md); the charging case and compact bar/indicator icons use the vector assets in [assets/icons/](assets/icons/).

## License

Gbuds Watch QML and documentation are licensed under MIT; copied upstream renders have separate attribution and provenance in [assets/README.md](assets/README.md). See [LICENSE](LICENSE) and [LICENSE-GPL-3.0](LICENSE-GPL-3.0).
