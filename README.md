# Gbuds Watch

Gbuds Watch is a Dux Shell 2.0 composite plugin for Galaxy Buds. A single background watcher reads `gbuds watch --json` and shares live telemetry with the bar pill, a control popout, and a resizable desktop widget.

The interface follows the supplied Galaxy Buds Dux Shell prototype: a connected-state pill, model renders with battery badges, hardware-aware noise controls, touchpad and EQ actions, a collapsible CLI output drawer, device selection, state notifications, and quick settings. Small surfaces use Material icons; larger surfaces use GalaxyBudsClient model renders when available. The plugin does not open a watcher connection per surface.

## Requirements

- Dux Shell 2.0 or newer.
- The `gbuds` CLI installed and discoverable by the Dux Shell process.
- A paired, connected Galaxy Buds device supported by the installed Gbuds version.
- Bluetooth permissions and BlueZ configured as described in the [Gbuds installation guide](https://github.com/JessVolet/gbuds-cli/blob/main/docs/INSTALLATION.md).

When `gbuds` is missing, the widget links to the installation guide. When no Buds device is available, it stays visible and retries with a backoff. If multiple Buds are paired, select the target from the popout; the plugin tracks a uniquely connected Buds automatically.

## Development

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the Dux Shell checkout, QML language server setup, plugin symlink, live reload, and real-device testing.

## Design notes

The source prototype is `galaxy_buds_dux_shell_prototype.html`. The QML implementation uses Dux Shell theme tokens instead of copying the prototype's Tailwind/CSS runtime. A metadata lookup selects the device render; one persistent `gbuds watch --json` process supplies status. Before a control command, the daemon stops that watcher, runs the requested Gbuds command, reports its real result, then resumes monitoring. Earbud renders are attributed in [assets/README.md](assets/README.md); the charging case uses a Material icon.

## License

Gbuds Watch QML and documentation are licensed under MIT; copied upstream renders have separate attribution and provenance in [assets/README.md](assets/README.md). See [LICENSE](LICENSE) and [LICENSE-GPL-3.0](LICENSE-GPL-3.0).
