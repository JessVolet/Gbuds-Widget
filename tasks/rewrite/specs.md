# Gbuds Widget functional and technical specification

Status: proposed rewrite contract. Baseline 0.6.7. This specification records established user requirements and proposed implementation decisions. New numeric targets must be validated on the reference system. Module IDs and dependency direction are defined in roadmap.md.

## 1. Product contract

Represent the connected Buds accurately, expose supported controls, and reflect configuration changes on the next visual update. The bar, popout, desktop, lock screen, and alerts consume the same normalized state. Preserve approved SVG geometry, diagonal placement, centered ANC artwork, renders, idle timer, and theme identity.

Removal and automatic noise-mode changes remain independent events and may appear concurrently. Duplicate echoes of the same cause do not create new alerts. Every animated wave visibly originates at radius zero; this is still an unresolved runtime requirement.

## 2. Proposed structure and platform

```text
Daemon.qml / Desktop.qml / GbudsBarWidget.qml / Settings.qml  # Dux adapters
src/
  config/        # schema, migration, reactive store
  device/        # Gbuds adapter, command registry/queue, watcher
  state/         # snapshots, requests, selectors
  events/        # event policy, battery thresholds, reminders
  motion/        # WaveTimeline.js, WaveEmitter.qml, motion tokens
  presentation/  # artwork, screen placement, style/layout tokens
  alerts/        # coordinator, PopupCard, WaveupSurface
  surfaces/      # bar, popout, desktop, lock screen
  settings/      # scoped editor and preview
scripts/         # assets and reproducible deployment
tests/          # existing Node/QML tests plus motion scenes
tasks/rewrite/  # rewrite contracts
```

Use QML, JavaScript, and the existing Gbuds CLI. Confirm the installed Dux 2.0.1 and Quickshell APIs before finalizing version-dependent integration. No additional UI framework or background service is needed. Hardware capability decisions require CLI/official evidence rather than broad product-name assumptions.

## 3. Data boundaries

### State

DeviceSnapshot contains deviceId, connectionEpoch, revision, observedAt, connection, capabilities, noiseMode, and parts.left/right/case. Each part has a known battery percentage or null, a known placement or unknown, and charging only when explicitly reported.

Unknown is not 0%. A stopped watcher is not a Bluetooth disconnect. Drop responses from a different device or connection epoch. Surfaces use selectors instead of parsing JSON or independently interpreting capabilities.

### Actions

ActionRequest contains a unique ID, device/epoch, action type, and validated arguments. ActionState distinguishes queued, running, succeeded, failed, and uncertain.

A user intent receives immediate visual feedback. Pending selection is distinct from confirmed device state. A command timeout does not prove that a ringing earbud stopped; Stop stays accessible. Retrying a timed-out command must follow its explicit idempotency policy.

### Configuration

ConfigSnapshot contains schemaVersion, revision, global preferences, and instance preferences. Publish updates immediately; group persistence writes without blocking rendering. Migration is idempotent, preserves zero/false values, and retains screen and user selections. Opening an editor does not save default values over existing choices.

### Events

NotificationEvent contains ID, kind, deviceId/epoch, subject, timestamp, immutable snapshot, and semantic payload. Presenters do not infer Bluetooth state. Watch echoes and command results must not produce duplicate causes. Event identity and ordering have one owner.

## 4. Connection and command behavior

One controller owns BlueZ selection, watcher lifecycle, command serialization, cancellation, and recovery. At most one RFCOMM operation is active. Capabilities refresh on connect/device change, keeping unsupported separate from unknown.

Show ANC/Ambient/OFF/Adaptive only as supported. Do not hardcode all Buds3 devices as lacking Ambient. Hide the OFF mode icon in the bar when that preference is selected.

Clicking an earbud starts Find only for known IDLE placement. A second click offers Stop. WEARING, IN_CASE, disconnected, or unknown cannot start Find. Disconnect belongs below CASE when enabled; an active search must be stopped first. A failed Stop cancels the pending disconnect.

Missing CLI and connection failures show concise actionable English copy. No raw traces or transport labels in the normal UI. New Gbuds functionality beyond currently exposed supported controls is out of scope for this rewrite.

## 5. Surface contracts

| Surface | Behavior |
|---|---|
| Bar | Approved diagonal icons, per-ear idle timer, optional battery/mode, optical alignment |
| Popout | Preserve device presentation, L/CASE/R batteries and compatible controls; progressively reveal secondary content |
| Desktop | New instances start Compact + SVG + hidden offline; Connect or Status are explicit alternatives |
| Lock screen | Separate instance/configuration; read-only by default; optional internal noise controls; external alerts suspended |
| Settings | Clear global/instance scope; relevant controls; immediate preview without device actions |
| Alerts | Independent events, lifetimes, subject artwork and deterministic monitor/corner occupancy |

Compact/Minimal/Detailed/Custom reuse the same blocks. Custom supports real ordering of major blocks and L/CASE/R, visibility, alignment, size, padding, horizontal/vertical gaps, and offsets. Hidden blocks leave no reserved gap. The displayed preset agrees with saved composition.

SVG/render/auto resolves the correct model, color, and ear. Missing renders fall back to same-side SVG; never use a different device model. Preserve supplied assets and licenses. The timer idle icon must remain legible at compact sizes.

Use shared theme tokens, readable contrast, visible keyboard focus, and state indicators with more than color alone. Size changes must not crop controls or require model-specific magic offsets.

## 6. Immediate response and settings scope

Target local input/configuration feedback within 100 ms p95 on a documented reference system. Record monitor refresh rate, hardware, and sample size. Bluetooth completion has no zero-latency promise.

Size, artwork, color, background, margins, and layout update on the next scene update without closing the panel, reselecting a preset, or reloading DMS. Motion changes restart previews immediately from zero. Active events retain identity and deadline while recalculating their motion; changing a setting must not extend alerts indefinitely.

| Scope | Basic | Advanced |
|---|---|---|
| Global notifications | Enable, Popup/Waveup/Both, duration, preview | Event overrides, display, Match L/R, top/bottom, reach, stroke, reduced motion |
| Desktop instance | Preset, offline policy, artwork, blocks | Order, geometry, theme, display selection, lock behavior |
| Global bar | Battery, mode icon, idle timer | Color and fine spacing |
| Global device | Selected device | CLI path and developer diagnostics |

Do not expose duplicate controls for the same dimension. Wave reach means final radius in logical pixels, never sometimes panel size and sometimes diameter. Hide controls only when their context makes them irrelevant. Keep one source of defaults and limits.

Use English in all product text, names, code, comments, and documentation. Good labels include Connect, Disconnect, Noise control, Find left earbud, Stop, and Battery at 20%. Remove decorative “Live”, “Realtime”, “En vivo”, and internal backend/schema/watch status from normal flows.

## 7. Alerts and placement

The global style is the default for every event. Overrides are Use default, Off, Popup, Waveup, or Both. Migration must not silently erase deliberate event preferences when distinguishing legacy saved defaults is ambiguous.

PopupCoordinator owns a model of simultaneously visible cards, each with its own expiry. A second event neither overwrites nor secretly waits behind the first. Stack from the selected corner toward screen center with a proposed 12-logical-pixel gap. Visible capacity derives from usable screen height; overflow uses a bounded expiring queue and explicit critical-alert priority. Closing a card smoothly reflows survivors without restarting their lifetimes.

Match L/R follows each ear's side. Pair/mode events use one popup at the configured corner and synchronized bilateral Waveups. Resolve collisions per monitor/corner; keep a destination stable for an event lifetime. Hotplug moves to a valid output without replaying expired events.

A Waveup may render behind an opaque card without impairing text. Waveup takes no keyboard/pointer input. A hidden desktop must not leave an invisible host input rectangle. Verify actual Dux host masks and compositor surfaces, not only Item.visible.

## 8. Events, battery and reminders

| Event | Subject | Rings | Tone |
|---|---|---|---|
| Removed from ear/case | Affected ear | 1 | Soft accent |
| Back in ear/stored | Affected ear | 1 | Soft |
| Connected | Pair | 2 | Theme success |
| Disconnected | Ear/pair | 2 | Neutral voluntary, warning unexpected |
| Downward 50% crossing | Affected part | 3 | Theme-adapted yellow |
| Downward 20% crossing | Affected part | 3 | Red with stronger stroke, no flashing |
| OFF / Ambient / ANC | Mode, bilateral | 1 / 2 / 3 | Neutral / secondary / accent |

Adaptive only appears when supported; a provisional two-ring bilateral pattern must be distinguishable by title and reviewed visually. Do not add 10%, full charge, charging, or search alerts by default without a product decision and reliable telemetry.

Thresholds are per device/part, with inclusive five-point hysteresis: rearm 20 at 25 and 50 at 55. A 59→18 jump emits only 20%. Ignore unknown/out-of-range values. Initial connection telemetry is not a threshold crossing.

Per-ear IDLE reminders are optional. Wearing, storing, disconnection, unknown placement, lock, or suspend cancel/suspend them. Resume requires fresh placement; do not replay overdue reminders. Watcher transport recovery alone does not create a disconnect alert.

## 9. Quality and verification

Follow codestyle.md. Policies are pure and receive time explicitly. One controller owns each lifecycle. No CLI calls from delegates, duplicate per-widget polling, or copied wave formulas.

Existing commands from repository root:

```sh
node tests/notification-policy.test.cjs
node tests/daemon.test.cjs
node tests/policy.test.cjs
node tests/icons.test.cjs
sh tests/run-runtime.sh
git diff --check
dms ipc call plugin-scan reload gbudsWatch
dms ipc call plugin-scan status gbudsWatch
```

The runtime harness requires Wayland and uses a fake CLI. Its current success does not prove wave appearance. Add isolated scenes, timed radius samples, and real-renderer captures as defined in animations.md. There is no confirmed standalone build command; validate package imports/assets and QML loading rather than inventing an npm build.

Acceptance matrix: light/dark; 1/2/3 rings; preview/real event; Popup/Waveup/Both; L/R/pair/case; supported noise modes; online/offline; multiple widgets; single/multiple/hotplug displays; mixed scale; lock; reduced motion; missing CLI/failure/timeout. Fixtures verify logic. Physical sessions verify Bluetooth, focus, composition, and actual placement. Unavailable combinations remain pending.

## 10. Acceptance boundaries

Preserve approved artwork, licenses, migratable choices, and Git checkpoints. Claim visual fixes only with frame evidence. Every supported control has immediate feedback and honest reconciliation. Both notification hosts must satisfy animations.md.

Matching hashes and `loaded` are not visual acceptance. Do not remove failing checks to pass a gate. New external dependencies, remote operations, and environment changes beyond the plugin need explicit scope. Existing authorization covers local changes/reloads, not remote release publication.
