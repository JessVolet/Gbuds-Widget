# Architecture

The four root QML files are Dux adapters. All active implementation lives under stable src modules; there is no versioned UI directory.

| Module | Owner and contract |
|---|---|
| config | Schema resolves defaults/migration; ConfigStore publishes edits immediately and batches persistence for 60 ms |
| device | DeviceController owns the connection; CommandRegistry validates argv; ProcessTask bounds output, startup and deadlines |
| state | DeviceStore publishes snapshots; Telemetry normalizes unknown readings; UiState exposes selectors and command intents |
| events | EventPolicy derives independent causes with injected time; EventController owns threshold memory and reminders |
| motion | WaveTimeline is pure; WaveController owns a finite clock; WaveEmitter renders the same radius function in both hosts |
| presentation | Approved vector templates, artwork resolution and screen placement |
| alerts | PopupController owns independent lifetimes/overflow; NotificationController applies event channels; AlertHost composes Popup/Waveup with one clock |
| surfaces | DeviceView, bar, panel, desktop and lock-aware controls consume shared state |
| settings | Declarative rows use the same schema; explicit user events publish edits, with no writes during default initialization |

Only the device layer executes Gbuds. Metadata uses the cached capabilities command; watcher and control commands never own concurrent RFCOMM sessions. Stop has priority, and an uncertain Find result retains a Stop action. Failed Stop cancels queued disconnect. Device epochs reject late responses from a previous target.

Notification events retain their ID, subject, snapshot and device artwork. Active model insertion/removal preserves sibling instances and clocks. Capacity is computed per monitor/corner; waiting entries have bounded length and expiry. Wave-only entries use bounded groups. Lock clears external alert surfaces.

A wave uses radius = maximumRadius × elapsedFraction. Each ring has the same final radius and starts 250 ms after its predecessor. Repeat occurs 1000 ms after the last ring completes; a partial last sequence never starts. Opacity is present from the first measurable radius; there is no initial fade concealing an already growing ring. Frame captures, not source inspection alone, validate this behavior.

Configuration changes update bindings immediately. Active alert geometry edits restart the motion phase within the existing event deadline, preserving identity, popup age and expiry. The desktop temporarily supplies an empty host input mask while hidden, restores the Dux binding on reconnect, and never alters the lock-window mask.

See tasks/rewrite/status.md for demonstrated behavior and remaining physical acceptance. The branch is a testing candidate until that review is complete.
