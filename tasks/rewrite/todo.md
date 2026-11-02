# Rewrite implementation TODO

Status: runtime candidate implemented on rewrite/modular-widget; see status.md for evidence and pending native/physical checks. Tasks below are ordered by the capability map in roadmap.md. Apply specs.md, animations.md, and codestyle.md to every task. Proposed paths may be refined before implementation; update this plan when a boundary changes.

## Documentation delivery

- [x] Inspect the current 0.6.7 implementation and record unresolved visual evidence.
- [x] Define module ownership, dependency direction, migration and release gates.
- [x] Specify behavior, shared animation timing, code quality and reusable controllers.
- [x] Break implementation into dependent, verifiable slices.
- [x] User approved implementation of the rewrite contracts on a separate branch.

## P0: Establish facts and reference scenes

### R01 — Record the deployed baseline

- [ ] Record tag/commit, loaded component identity, effective notification settings, output geometry, scale and refresh rate.
- [ ] Preserve approved SVG/renders and baseline captures for every surface; label the current radius bug unresolved.
- [ ] Verify source/installed directory relationships and the actual imported-component reload behavior.

Dependencies: none. Scope: small, evidence manifest and baseline scene/config (2–3 files). Verification: compare source and loaded revision, capture one actual notification, and reproduce from a fresh QML process. Do not trigger device controls merely to capture motion; use simulated events.

### R02 — Reproduce the first-visible-radius bug

- [ ] Isolate Popup and Waveup, with a switch for their actual production rendering path.
- [ ] Capture start/launch/first-visible/end frames for 1/2/3 rings and distinguish clock, opacity, easing, geometry and cache hypotheses.
- [ ] Record which hypothesis is supported; keep the bug open if the reproduction does not match the report.

Dependencies: R01. Proposed files: tests/motion/scene.qml, tests/motion/capture script, evidence manifest (3). Verification: timestamped captures and radius samples, light/dark, preview and notification paths. Static source inspection alone fails acceptance.

Checkpoint P0: reproduction, identity and visual references are usable; no visual fix is claimed yet.

## P1: A reusable and measurable wave engine

### R03 — Implement the pure wave timeline

- [x] Produce radius/opacity/phase from explicit elapsed time, with radius zero before launch and a common final radius.
- [x] Enforce 250 ms launch spacing and repeat at last completion + 1000 ms.
- [x] Reject invalid inputs and prevent partial repeats beyond the deadline or callbacks from canceled generations.

Dependencies: R02. Proposed files: src/motion/WaveTimeline.js, motion tokens, focused timeline tests (3). Verification: deterministic boundary tests at each launch, end, repeat, cancellation and insufficient remaining lifetime. These tests exercise timing semantics rather than QML property spelling.

### R04 — Implement the shared renderer in both hosts

- [ ] Feed one timeline into WaveEmitter and wire that component into isolated Popup/Waveup hosts.
- [ ] Make the first visible stroke small enough to match elapsed time; use stronger stroke/reach without a center dot.
- [ ] Prove monitor-corner origin, bilateral synchronization, and pointer passthrough.

Dependencies: R03. Proposed files: WaveEmitter.qml, Popup wave host, Waveup surface, motion scene (4). Verification: actual frame captures per animations.md, runtime QML errors, corners and available output scales. Compare renderer behavior with and without loaded-component caching.

### R05 — Complete motion lifecycle and settings preview

- [ ] Restart preview from zero on edits using the production renderer and a new generation.
- [ ] Cancel hidden/disposed/locked animations; reduced motion cannot leak static radii into the animated mode.
- [ ] Ensure independent events do not reset sibling clocks or extend unrelated lifetimes.

Dependencies: R04. Proposed files: WaveController.qml, motion preview adapter, lifecycle checks (3). Verification: rapid setting edits, event overlap, hide/show, disposal, reduced-motion toggle, and finite lifetime capture.

Checkpoint P1: attach visual evidence to the exact commit. Only then create a verified motion milestone tag. Do not proceed by declaring a successful reload equivalent to correct motion.

## P2: Connection, actions and normalized state

### R06 — Introduce reactive configuration and migration

- [x] Define one schema/default source for global and instance preferences, preserving false/zero and old choices.
- [x] Publish local changes within the response target while grouping persistence writes.
- [x] Migrate idempotently with backup; do not rewrite values merely by opening settings.

Dependencies: R01. Proposed files: ConfigSchema.js, ConfigStore.qml, ConfigMigration.js, focused migration checks (4). Verification: old layouts and event overrides, missing/unknown keys, repeated migration, two independent instances and immediate subscriptions.

### R07 — Extract a reusable command registry/queue

- [x] Describe currently supported actions declaratively with validation, capability, priority, timeout and retry policy.
- [x] Serialize watcher/commands through one transport owner; preserve Stop priority and uncertain Find outcomes.
- [x] Reject stale device epochs, unsafe argument shapes and oversized output.

Dependencies: R06. Proposed files: CommandRegistry.js, CommandController.qml, GbudsAdapter.qml, command checks (4). Verification: existing daemon/control tests plus fake-adapter timeout, failure, cancellation and device-switch cases. Adding a registry entry must not require a new process loop.

### R08 — Normalize state and reconciliation

- [x] Publish one immutable-by-convention snapshot with connection epoch, revision, capabilities and nullable readings.
- [x] Separate pending selections from confirmed hardware state and reconcile failures without stale overwrites.
- [x] Keep transport recovery distinct from Bluetooth disconnect.

Dependencies: R07. Proposed files: DeviceStore.qml, StateSelectors.js, TelemetryNormalizer.js, state checks (4). Verification: connect→command→confirmation→disconnect with fake CLI, old-device responses, unknown data and command echo.

### R09 — Extract event detection and reminders

- [x] Preserve independent placement/noise/battery causes, subjects and immutable snapshots; deduplicate echoes.
- [x] Implement threshold crossings and inclusive five-point hysteresis per device/part.
- [x] Centralize cancelable per-ear reminders with lock/suspend/freshness rules.

Dependencies: R08. Proposed files: EventPolicy.js, EventController.qml, ReminderController.qml, event checks (4). Verification: simultaneous causes, 59→18, 25/55 rearm boundaries, unknown values, storing/wearing/disconnect and resume without backlog.

Checkpoint P2: existing control invariants pass through the new adapters. No surface owns a process or independent event detector.

## P3: Preserve and rebuild the product surfaces

### R10 — Shared artwork and presentation tokens

- [x] Resolve correct model/color/part and same-side SVG fallback centrally.
- [x] Preserve approved diagonal poses, ANC cutouts, timer and theme coloring.
- [x] Define shared dimensions, spacing, focus and motion tokens rather than surface-specific magic values.

Dependencies: R06, R08. Proposed files: ArtworkResolver.js, ThemeTokens.qml, LayoutTokens.js, asset checks (4). Verification: existing icon checks plus missing render, FE/Buds3 fixtures and same-scale visual comparisons.

### R11 — Rewrite the bar interaction slice

- [ ] Render normalized state with approved icons, per-ear idle and configured battery/mode display.
- [ ] Update settings without closing/reloading and keep optical alignment stable.
- [ ] Open the popout with correct keyboard/focus and connection state.

Dependencies: R08, R10. Proposed files: BarWidget.qml, BarContent.qml, GbudsBarWidget.qml adapter, scene/checks (4). Verification: online/offline/unknown, OFF-icon preference, rapid settings changes, narrow bar and light/dark captures.

### R12 — Rewrite the popout interaction slice

- [ ] Preserve the approved device/battery/noise layout and progressive secondary content.
- [ ] Route Find, Stop, disconnect and noise controls through shared intents and pending states.
- [ ] Show concise English failures and remove decorative technical labels or controls without useful effects.

Dependencies: R07–R11. Proposed files: DevicePanel.qml, DeviceParts.qml, NoiseControls.qml, panel checks (4). Verification: capability variants, safe Find gating, failed Stop, keyboard navigation, long names, render fallback and visual comparison.

### R13 — Rewrite desktop composition

- [ ] New instances are Compact/SVG/hidden offline, while explicit legacy choices migrate correctly.
- [ ] Support real major-block ordering, per-instance geometry/artwork/spacing and empty-gap removal.
- [ ] Resolve monitor selection/placement independently and ensure hidden hosts pass pointer input.

Dependencies: R06, R08, R10, R12. Proposed files: DesktopLayout.qml, DesktopBlocks.js, ScreenPlacement.js, Desktop.qml adapter, desktop checks (5). Verification: create without touching layout selector, multiple instances, all blocks hidden, extreme sizes, actual host input region and available display/hotplug cases.

### R14 — Integrate lock-screen composition

- [ ] Keep lock instances independent and offline-hidden/read-only by default.
- [ ] Optional internal noise controls obey capabilities; Find/connect/disconnect and external alerts remain unavailable there.
- [ ] Preserve password focus and suspend motion/reminders appropriately.

Dependencies: R13. Proposed files: LockWidget.qml, lock adapter/policy, lock scene/checks (3). Verification: actual native lock widget integration and focus when available; keep physical acceptance pending if unavailable.

Checkpoint P3: surfaces retain the approved identity, all local changes are reactive, and shared state/control behavior is consistent across surfaces.

## P4: Alerts and editor

### R15 — Independent popup lifetime and occupancy

- [ ] Render concurrent event cards with independent timers/artwork instead of replacing/promoting one shared main event.
- [ ] Stack deterministically by monitor/corner with bounded overflow and priority/expiry behavior.
- [ ] Reflow survivors without restarting them and preserve Match L/R and screen identity.

Dependencies: R05, R09, R10, R13. Proposed files: PopupController.qml, PopupCard.qml, AlertPlacement.js, occupancy/lifetime checks (4). Verification: two simultaneous placement/noise events, close-middle, small output, L/R/pair/case, hotplug, screenshot overlap bounds.

### R16 — Integrate the notification router and Waveups

- [ ] Apply global style and explicit per-event overrides through one notification controller.
- [ ] Use shared motion hosts with no stolen focus, duplicate causes or interrupted sibling events.
- [ ] Match tone/count/subject and suppress external alerts while locked.

Dependencies: R09, R15. Proposed files: NotificationController.qml, WaveupSurface.qml, Daemon.qml adapter, routing checks (4). Verification: event matrix from specs.md in Popup/Waveup/Both; cancellation and finite repeated sequences in the actual runtime.

### R17 — Rebuild settings around useful controls

- [ ] Clearly separate global and instance preferences; keep common style/duration/preview basic and detailed overrides Advanced.
- [ ] Every setting has one effect, a valid unit/range and immediate preview/update; remove redundant or no-op controls.
- [ ] Use English copy and no decorative Live/Realtime/En vivo badges.

Dependencies: R06, R11–R16. Proposed files: Settings.qml adapter, NotificationSettings.qml, DesktopSettings.qml, settings check/scene (4). Verification: edit while surfaces/alerts are open, persistence/reopen, narrow editor, keyboard, preview through the production renderer without device actions.

Checkpoint P4: all options have an observed effect, events remain independent, and the shared motion contract passes in every host.

## P5: Integration, performance and recovery

### R18 — Retire legacy implementations

- [x] Switch all entry points/imports to the validated src modules and remove unused versioned UI/core folders.
- [x] Retain assets/licenses and adjust only the required packaging/import metadata.
- [x] Confirm no legacy process owner, duplicate wave formulas, orphan timers or unused settings remain.

Dependencies: R17. Scope: mechanical legacy-folder retirement plus qmldir/import inventory; no new behavior in this change. Verification: reference search, full Node regressions, runtime QML loading and package asset/import audit. Keep the folder deletion isolated for easy review.

### R19 — Validate responsiveness and final presentation

- [ ] Measure feedback p95 and frame timing against a documented baseline/reference display.
- [ ] Exercise the acceptance matrix and capture final motion/presentation evidence.
- [ ] Record residual limitations honestly; fix observed regressions before release.

Dependencies: R18. Proposed files: performance/motion scenarios and evidence manifest (2–4). Verification: profiling and real compositor captures, keyboard/focus/input passthrough, available hardware/displays. Do not claim untested physical cells from fixtures.

### R20 — Reproducible package and rollback

- [ ] Build/install an artifact from an exact commit and verify the actual loaded component revision after reload.
- [ ] Back up compatible settings/code and rehearse restoration without overwriting unrelated working changes.
- [ ] Create an immutable local release tag with changelog and linked evidence only after all required gates pass.

Dependencies: R19. Proposed files: package/deploy script, deployment manifest, recovery instructions (3). Verification: package→install→reload→revision check→rollback→restore, plus final visual check. Decide final release version from compatibility review; do not publish remotely as part of this task.

## Completion rule

A checked task needs its acceptance evidence and commit ID recorded beneath it. Keep blocked or unavailable checks pending. Implemented code and automated evidence are recorded in status.md. Unchecked items retain native/physical or broader visual acceptance work; implementation alone does not check them.

## Checked-item commit and evidence index

- Documentation delivery: 92dc1e3, rewrite contracts and user approval recorded before implementation.
- R03: 49d7276, tests/motion.test.cjs; actual renderer samples and wave-contact-sheet.png in the evidence delivery.
- R06: cf5eb3d, ea7a1bc, c6baaa7; Schema migration behavior checks and ConfigStore QML immediate/coalesced persistence checks.
- R07–R08: cf5eb3d, c6baaa7; registry/telemetry/policy cases and fake-process QML connect, timeout, Find/Stop/disconnect flow. Physical device acceptance remains separate.
- R09: cf5eb3d, c6baaa7; EventPolicy crossings, inclusive rearm and channel cases, plus runtime lock suppression and independent alerts.
- R10: eb24a61, 0f1f52d, 24e1d84, 5615242; asset/subject/layout checks and final presentation capture. No mixed-scale visual certification is implied.
- R18: b204e03; retired folders absent in source and installation, 104 final artifact files compared with no mismatches.

The full outstanding acceptance matrix remains deliberately unchecked. See status.md for exact candidate/native identity and limitations.
