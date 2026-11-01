# Gbuds Widget rewrite roadmap

Status: proposed implementation plan, not implemented. Baseline: 0.6.7, commit `1dfc7f4`, tag `v0.6.7`. Read with specs.md, animations.md, codestyle.md, and todo.md.

## Outcome and visual direction

Rewrite the bar, popout, desktop, lock screen, settings, and alerts around shared controllers. Preserve the approved diagonal earbuds, case, centered ANC ear/shield, Ambient/OFF assets, per-ear idle timer, device renders, and theme palette. Improve hierarchy, continuity, response, and maintainability while retaining the visual identity the user likes.

All code, comments, documentation, and product copy use English. Labels describe a real device, state, or action. Remove decorative technical labels such as “Live”, “Realtime”, “En vivo”, and implementation details from normal product flows.

This delivery defines the rewrite. It does not claim the current wave bug is fixed and does not change the installed plugin.

## Findings and uncertainties

| Inspected evidence | Rewrite consequence |
|---|---|
| Daemon.qml owns processes, queue, state, events, reminders, and presenters | Extract responsibilities while retaining one connection owner |
| Popup and Waveup implement separate formulas, clocks, and lifetimes | Use one tested motion engine and context-specific hosts |
| Several geometry/scale patches have not resolved the user's report | Reproduce and capture frames before choosing another fix |
| Mathematical radius zero does not prove perceived radius zero | Measure the first visible frame, opacity, easing, and stroke |
| OutCubic growth plus delayed visibility may hide the small-radius phase | Treat this as a hypothesis, not an established cause |
| interface-v050 and interface-v060 duplicate presentation code | Move to stable modules and remove obsolete code after migration |
| Source checkout and installed plugin are separate directories | Deploy a reproducible artifact and identify the loaded revision |
| Node tests and a QML harness already exist | Reuse meaningful coverage and add missing visual evidence |

The runtime cause remains unproven. Inspect generation, rendering, presentation timing, initial visibility, and component caching. A tag, matching hash, or `loaded` status is deployment evidence, not visual acceptance.

## Capability map

Dependencies identify providers; cycles are forbidden. This is the proposed map for review before implementation.

| Module ID | Responsibility | Depends on |
|---|---|---|
| config | Schema, defaults, migration, reactive configuration | — |
| device | CLI/BlueZ adapter, capabilities, watcher, command queue | — |
| state | Normalized snapshots, requests and confirmations | config, device |
| events | Deltas, identity, thresholds, reminders | state, config |
| motion | Wave timeline and reusable motion primitives | config |
| presentation | Artwork, theme tokens, layouts, screen geometry | config, state |
| alerts | Routing, occupancy, independent lifetimes, Popup/Waveup hosts | events, motion, presentation |
| surfaces | Bar, popout, desktop, lock screen | state, presentation, motion |
| settings | Scoped editor and simulated previews | config, presentation, motion |
| delivery | Artifact, revision identity, backup and rollback | All above |

Settings writes through config and never executes device commands. Surfaces emit intents to state and never spawn processes. Motion accepts generic visual inputs and knows nothing about Galaxy Buds. A small root coordinator wires dependencies.

## Delivery phases

| Phase | Usable slice | Exit gate |
|---|---|---|
| P0: Reproduction | Isolated wave scene, recording, approved visual baseline | Every frame is attributable to a loaded revision; the bug is documented |
| P1: Shared motion | One emitter used by Popup and Waveup in the harness | Visible zero-radius launch, 250 ms stagger, 1000 ms end-to-repeat gap demonstrated |
| P2: Connection/state | Connect → command → confirmation → disconnect through new controllers | No competing RFCOMM sessions; Stop and failed-command reconciliation work |
| P3: Surfaces | Bar/popout followed by desktop/lock screen | Approved identity preserved; reactive settings; independent instances |
| P4: Alerts/settings | Independent events, stacking, reminders, streamlined editor | Every visible control has one defined effect; events do not overwrite each other |
| P5: Delivery | Legacy retirement, migration, reproducible installation | Acceptance matrix, visual evidence, local tag, backup, verified reload |

P1 comes early because motion is the repeatedly unresolved risk. P2 preserves the existing command invariants. P3 is split by surface to avoid replacing every UI at once without evidence.

## Migration strategy

1. Keep v0.6.7 immutable as the pre-rewrite checkpoint; it is not a visually validated release.
2. Work on `rewrite/modular-widget`. Keep the current runtime available while validating new modules in the harness.
3. Build stable `src/` modules with temporary adapters at existing entry points.
4. Replace one surface after its gate passes, using a small commit per task.
5. Migrate configuration idempotently with a backup; opening settings must not overwrite saved choices with defaults.
6. Retire interface-v050, interface-v060, and core-v060 only after all consumers migrate and the replacement package passes acceptance.

Do not copy whole UI folders per patch to force reloads. Establish how Dux/Quickshell invalidates imported components, and verify that behavior against the installed version.

## Versioning and recovery

Each finished task has a focused commit referencing its TODO ID. Verified phase tags may use `rewrite-p0-verified`, `rewrite-p1-verified`, etc.; create them only with evidence. The eventual release version is determined after compatibility review; 0.7.0 is an indicative target, not a published promise.

Build deployment artifacts from a commit/tag, excluding .git, test fixtures, and personal files. Record commit, artifact hash, configuration schema, backup, and reload result in a deployment manifest. Rollback restores both code and compatible configuration into a recoverable local installation; never reset away unrelated working changes. Tags remain immutable. Remote publication is outside this delivery.

## Risks to close

| Risk | Evidence or mitigation |
|---|---|
| First visible ring already large | Capture frame timing; compare linear growth, fade, and stroke in the same scene |
| Imported QML remains cached | Identify the loaded component; compare with a fresh-process control scene |
| Full-monitor transparent layers cause composition cost | Measure frame times and input behavior; choose surface bounds using evidence |
| Old telemetry overwrites a recent user selection | Connection epochs and request revisions |
| Hidden desktop still intercepts clicks | Inspect/test the actual Dux host input region, not just child visibility |
| Missing hardware or additional monitors | Keep acceptance cells explicitly pending; simulation is not hardware verification |
| Rewrite changes the approved design | Compare captures at matching theme, scale, and state after each surface migration |

## Parallel work

After P0 contracts are fixed, config and the motion harness can proceed independently. After P2, bar/popout and desktop work can run separately in owned files. State schema, alert coordination, migration, and integration gates stay sequential. Completion is based on acceptance evidence, not task activity.
