# Rewrite candidate status

Branch: rewrite/modular-widget. Product version: 0.7.0-dev.5. Base: v0.6.7.
This is a new runtime implementation under src. Legacy UI/core folders have been removed in the branch. Approved vector artwork, renders and license files are retained.

## Implemented

R03–R17 have runtime implementations: shared wave timeline/controller/emitter; reactive schema/config store; registry/process/connection/state controllers; event/reminder policy; artwork and geometry; rebuilt bar, panel, desktop, lock-aware controls, settings; independent alert scheduling and hosts. This records code delivery, not completion of every acceptance cell in those tasks.

Settings publish immediately and persist in a 60 ms batch. Controls dispatch argv through one queue. The settings editor uses explicit user edit signals, avoiding default writes during initialization. Major desktop blocks can be reordered directly.

## Evidence obtained

- Twenty-two Node behavior checks across motion, registry/telemetry, events/config, capabilities/Find policy, and approved assets.
- Twenty-five QML runtime checks: entry-point loading, compact hidden default, connect/BlueZ confirmation, capabilities, watch, immediate feedback, selected-ear Find, failed Stop cancellation, safe disconnect, missing executable, timeout, coalesced persistence, independent notifications, and lock suppression. The runtime uses fixture services and fake Gbuds processes.
- Thirteen image samples from the actual WaveEmitter renderer in a Wayland window. At 0 ms the image is empty; at 16 ms its nontransparent bounds are 6 × 6 logical pixels, versus approximately 2.51 px expected radius. Growth matches the linear timeline within 2 px. Completion/gap frames are empty, and the restart at 2916 ms returns to the same small radius.
- A 30-second isolated animation-cadence sample produced 1872 updates, p95 17 ms, maximum 17 ms, and zero intervals over 50 ms. A second 30-second scene with concurrent Popup/Waveup hosts produced 1855 updates, p95 17 ms, maximum 44 ms, and zero intervals over 50 ms. Date.now integer precision limits interpretation; this is not a GPU/compositor latency benchmark or a GPU composition benchmark.
- Four native Waveup corner captures reach the corresponding image edges. The reported logical surface was 1670 × 939 and captured images were 1920 × 1080; capture scaling is recorded separately rather than assuming devicePixelRatio alone converts coordinates.
- A rendered presentation scene compares panel, desktop and popup with real layouts/assets and fixture Dux button controls.
- Temporary-directory install/rollback test passes and preserves unrelated plugin preferences.

The user's historical first-radius report is the baseline symptom. Its unique original cause has not been established by these new-renderer measurements. New evidence demonstrates the new emitter, rather than retroactively proving a previous patch correct.

## Pending before merge

- User/native Dux review of presentation, first-visible waves and every setting on the actual host.
- Native desktop pointer passthrough while hidden, keyboard focus and lock-screen/password integration.
- Physical Buds control/telemetry verification for the connected model; fixtures cannot certify it.
- Multiple outputs, mixed scale and hotplug; all four corners and bilateral synchronization in that environment.
- GPU/compositor presentation profiling and p95 local input feedback measurement on the reference system. The multi-overlay animation-cadence measurement is already available.
- Actual installed-candidate rollback verification including the native settings cache.

Native smoke testing initially found a Qt Item.state name collision inside the bar inline component. Candidate v2 names the model explicitly, and the harness now instantiates both bar components and rejects QML binding warnings.

## Evidence locations

User-facing captures, contact sheet, radius samples and validation reports are delivered under outputs/gbuds-rewrite-evidence in the Codex workspace. Source scenarios and analysis commands live in tests/motion and tests/presentation. Deployment artifacts include exact commit/version/hash manifests.

Keep the candidate branch separate from the original branch until the requested testing stage and remaining acceptance review are complete. Do not label this candidate as a verified release or silently mark unchecked physical TODO cells complete.
