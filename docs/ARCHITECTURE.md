# Architecture

Gbuds Watch is a composite Dux Shell plugin. One daemon owns Gbuds CLI processes and publishes shared state to the bar, popout, and desktop surfaces.

```mermaid
flowchart LR
    BlueZ[BlueZ paired and connected devices] -->|target selection| Daemon
    Daemon -->|gbuds info --json| Metadata[Model and capabilities]
    Daemon -->|one persistent gbuds watch --json| Watch[Live status stream]
    Watch -->|telemetry and events| State[PluginGlobalVar]
    State --> Pill[Bar pill]
    State --> Panel[Control popout]
    State --> Desktop[Desktop widget]
    Panel -->|ANC / touchpad / EQ / sync request| Queue[Serialized action queue]
    Queue -->|stop watch, run command, restart| Daemon
    Settings[Plugin settings] -->|CLI path, target, alerts, pill| Daemon
    Watch -->|state and low-battery changes| Notify[DMS notifications]
```

## Device selection

The daemon follows a uniquely connected Galaxy Buds device detected by Dux Shell. If more than one is paired, the popout lists the paired Buds; selecting one asks BlueZ to connect it, persists its address, and passes that target to Gbuds using `--mac`. A uniquely connected device is followed automatically so switching between paired models updates the active stream.

`gbuds info --json` supplies model code, color, supported noise modes, and device name. These fields choose an available GalaxyBudsClient render and filter noise controls. Models without a copied render use Material icons.

## Watch lifecycle and actions

The daemon starts one `gbuds watch --json` process. Each newline-delimited JSON object updates shared telemetry. When the process exits, Gbuds Watch keeps the last sample visible and retries with exponential backoff up to 15 seconds.

Control requests enter a FIFO queue. The daemon stops the watch process first, then runs exactly one `gbuds --json <command>` process. It publishes the command and response for the collapsible output drawer, displays success/error feedback, and resumes device metadata lookup and watch. This avoids running two CLI RFCOMM sessions at once.

## State and notifications

The `telemetry` global variable contains the latest status, `frameCount`, `changeCount`, a bounded event `history`, and `latestEvent` with per-field before/after values. Every field from `gbuds watch --json` is compared, including charging flags, ambient volume, voice detect, blade lights, coupling, and touch controls. The popout and desktop show a dismissible state-change card; the live test panel exposes stream counters, real control actions, recent events, and the current JSON sample. Low-battery alerts fire when a battery crosses the configured threshold and are rate-limited. The state card dismisses after the configured 3, 6, or 10 second interval.

## UI surfaces

- **Bar pill:** compact, minimal, or detailed battery and noise-mode summary.
- **Control popout:** large model renders, per-part battery, supported ANC modes, touchpad, EQ, device selection, quick settings, a live telemetry test panel, and a hidden-by-default CLI output drawer.
- **Desktop widget:** the same controls and live state in a resizable card.

Every control is capability-filtered or disabled when disconnected. Status remains read-only telemetry; user actions invoke the installed Gbuds CLI.
