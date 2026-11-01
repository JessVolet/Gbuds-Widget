# Code quality and reusable controller style

Status: required coding contract for the proposed rewrite. All implementation tasks must follow this document. Examples are contracts, not already implemented APIs.

## 1. Quality standard

Write clear, fast, safe, effective code that can be reused when another feature needs the same mechanism. Prefer a small complete implementation over sprawling special cases. Line count is an indicator, not a target: 120 readable lines are better than 1000 duplicated lines, while a compressed one-liner is not better than an understandable function.

Use English for identifiers, comments, documentation, errors, and product copy. Comments are sparse and explain an invariant, timing choice, external limitation, or non-obvious reason. Delete comments that merely narrate the next line. Do not hide intent behind clever abbreviations, nested ternaries, or dense one-line QML objects.

## 2. Responsibility and dependency rules

- A controller owns one lifecycle and exposes a narrow interface.
- Pure policy/calculation functions receive all inputs, including time, and return values without I/O.
- QML views render state and emit intents. They do not invoke shell commands, parse hardware JSON, or write unrelated settings.
- Adapters own external behavior: Gbuds/BlueZ, Dux settings, screen resolution, process execution, persistence.
- The root coordinator connects modules; modules must not import the coordinator back.
- Share proven mechanisms, not a speculative general-purpose framework. Extract when two real consumers need the same behavior or an external boundary needs isolation.

Review a QML component around 200 lines or a function around 40 lines for mixed responsibilities. These are review prompts, not hard limits or reasons to split cohesive code into meaningless wrappers. Each extraction must remove duplication or clarify ownership.

## 3. Reusable controllers

| Controller | Reusable mechanism | Domain-specific input |
|---|---|---|
| WaveController | Timeline, stagger, repeat, cancellation, deadlines | Count, tone, reach, origin, motion preference |
| PopupController | Active items, independent expiry, dismissal, occupancy/reflow | Card content and artwork model |
| NotificationController | Routing, identity, channel policy, bounded overflow | Normalized event and user preferences |
| CommandController | Serialized jobs, timeout, cancellation, priority, epoch checking | A validated descriptor from CommandRegistry |
| ArtworkResolver | Asset lookup, same-subject fallback, cache | Device/model/color/part |
| ConfigStore | Schema, migration, observable update, persistence | Global/instance schema entries |

Controllers must be reusable without copying them. Adding a supported action should normally require a registry entry, argument/result validation, a capability rule, and a UI intent. It should not require a new process loop or another command-specific branch in every surface.

## 4. Command registry contract

A declarative registry maps stable action IDs to validated command descriptors. Each descriptor declares argument schema, capability requirement, connection policy, timeout, priority, idempotency, cancellation semantics, and result normalization.

```js
const commands = {
    stopFind: {
        cliCommand: 'find',
        args: ['stop'],
        priority: 100,
        requiresConnection: true,
        timeoutMs: 5000,
        retryPolicy: 'manual',
    },
};
```

This fragment illustrates shape only. Every executable descriptor still needs a validator and model coverage. Never accept a free-form shell string from settings/UI, append a MAC to a shell command, or call eval. Pass executable and arguments as a process argv array. Resolve the configured executable through one adapter and validate addresses/enum values before dispatch.

Allow exactly one transport-owning command/watch session at a time. Give Stop an explicit priority and preserve its uncertain state after a timeout. A generic retry must not repeat a potentially delivered Find start or another non-idempotent operation. Bound queue length and process output; abort parsing oversized or invalid input with a useful error.

## 5. State, time and reactive settings

Use explicit device epochs and revisions so stale async results cannot overwrite a newer connection or intent. Make authoritative snapshots immutable by convention; never mutate a shared object inside a delegate. Store pending requests separately and reconcile on confirmation/failure.

Use one event clock per motion/notification lifecycle. Views receive a timestamp/phase instead of inventing timers. Inject clocks and external adapters where determinism matters. Cancel subscriptions, timers, processes, and animation generations on disposal.

Configuration has one schema/default source. Publish a changed property immediately, coalesce disk writes, and avoid rebuilding the whole UI tree for a color or size update. Preserve bindings; do not assign imperatively to a bound property as an accidental workaround.

## 6. Performance and readability

Cache resolved assets/normalized capabilities until their inputs change. Avoid per-frame JSON parsing, file access, process calls, settings persistence, and repeated screen enumeration. Reuse delegates and derived selectors; measure before adding caches that complicate invalidation.

Do not animate multiple properties when a single explicit progress value can derive geometry consistently. Keep geometry units visible in names: radiusPx, elapsedMs, durationMs. Distinguish logical from physical pixels once at the screen boundary.

Use early validation and simple control flow. Prefer a small table to repeated switch ladders when data drives behavior. Avoid global mutable scratch state, hidden side effects, unnecessary abstraction layers, and duplicated constants.

## 7. Errors and diagnostics

Handle expected operational errors at their owning boundary. Return structured failure/uncertain states; show concise user actions in the UI. Do not catch all errors and silently present success, expose raw command output as product text, or log every animation frame in normal operation.

Developer diagnostics may identify source revision, component generation, command ID, epoch, and timing. Keep them opt-in, bounded, and free of unnecessary personal data. No diagnostic badges such as “Live engine” in the normal UI.

## 8. Review and evidence

Before a task commit, inspect the diff for mixed responsibilities, dead code, accidental binding removal, unbounded work, unchecked external input, and duplicated policy. Run the meaningful focused checks for that task. Add tests for behavior and failure boundaries; do not add tests that merely assert implementation spelling or mirror trivial assignments.

Animation fixes require real frame evidence in addition to timeline tests. Process/queue fixes require fake-adapter failure cases. Hardware claims require hardware observation. Missing evidence remains pending rather than being described as verified.

Each accepted slice gets a descriptive commit referencing its task ID. Verified tags point to the exact evidence-backed commit. Remove temporary instrumentation and obsolete alternatives before release. Never move a published/checkpoint tag to conceal a correction.

## 9. Definition of done

A module has a clear owner and contract, relevant meaningful coverage, bounded resource use, useful errors, and no duplicated behavior across consumers. Its settings react immediately, its callbacks cannot outlive their generation, and another feature can reuse its mechanism through the public interface. The user can understand the resulting UI without knowing how the module works.
