# Animation and presentation contract

Status: proposed rewrite contract, not a claim that current motion is fixed. Applies to the shared motion module and every consumer. Baseline: 0.6.7.

## 1. Visual intent

Preserve the approved design and enrich it with purposeful motion: ear placement, noise selection, connection changes, battery emphasis, popup arrivals, and layout transitions. Motion must explain change and feel continuous. Avoid perpetual decorative loops, stacked effects competing for attention, or different timing rules in each surface.

Notification waves are the first acceptance gate because the initial-radius issue remains reported after repeated patches. Mathematical start values alone do not close that gate.

## 2. One wave engine

WaveTimeline is a pure time function. WaveController owns start, expiry, repetition, cancellation, and configuration revision. WaveEmitter renders its output. PopupCard and WaveupSurface supply origin, bounds, theme, count, and maximum radius; neither supplies a second clock or alternate radius formula.

Inputs: event ID, generation, launch time, ring count 1–3, ring duration, stagger 250 ms, repeat gap 1000 ms, maximum radius in logical pixels, stroke width, color, overall deadline, reduced-motion flag, and an injectable clock.

Outputs: per-ring radius, opacity, visibility and phase; sequence start/end and completion. Motion does not execute CLI commands, inspect device models, or generate notification events.

Cancellation invalidates the generation immediately. A callback from an old event/generation cannot restart a completed, hidden, or disposed effect.

## 3. Wave geometry and timing

All rings share the same final radius for one event. Their number controls their launch times, not preassigned starting radii or distinct final diameters.

For ring i (zero-based), start time S and duration D:

```text
launch(i) = S + i × 250 ms
progress(i,t) = clamp((t - launch(i)) / D, 0, 1)
radius(i,t) = maxRadius × progress(i,t)
sequenceEnd = S + (count - 1) × 250 ms + D
nextSequenceStart = sequenceEnd + 1000 ms
```

Use linear radius growth as the initial reference. Do not begin with OutCubic: its fast early growth combined with opacity fade can make the first visible ring already large. A different easing curve is allowed only after comparison captures satisfy the first-visible-frame criterion.

Before launch: radius 0, diameter 0, opacity 0, no dot or minimum-size circle. At launch geometry remains zero. Once measurable, the stroke becomes visible promptly; do not hide the first 100 ms behind an opacity fade. Near completion fade out over the final 20% of ring time. Stroke at tiny radii is clamped so it cannot create an unintended solid center dot.

Every cycle explicitly resets geometry and visibility before its stagger. Geometry must remain centered while it grows. No pulse from another event may jump a running ring to its final radius.

### Reference timing proposal

Normal ring duration: 1400 ms. Low battery uses the same radial speed; critical battery can use a shorter 1200 ms duration plus stronger stroke, subject to visual review. Do not encode urgency through strobing.

| Count | Launches for normal duration | Last completion | Earliest repeat |
|---|---|---|---|
| 1 | 0 | 1400 ms | 2400 ms |
| 2 | 0, 250 ms | 1650 ms | 2650 ms |
| 3 | 0, 250, 500 ms | 1900 ms | 2900 ms |

Overall duration defaults to 5 seconds. Start another sequence only if its entire animation fits before the event deadline; the 1000 ms gap itself need not be displayed after the final sequence. Do not stretch duration to force an extra repeat. A new event receives its own timeline/deadline rather than extending an unrelated event forever.

## 4. Reach, stroke and surface bounds

Proposed Waveup final radius: 220 logical pixels by default, adjustable continuously from 80 to 400. This is radius, not an opaque panel size or a scale multiplier. Proposed popup radius: fit the approved card's artwork region, normally 70–90 logical pixels; derive bounds without placing rings over title/battery text.

Normal stroke: 4 logical pixels; critical: 6. User changes may tune reach/stroke in Advanced, with one definition shared by both hosts. Clamp against useful monitor geometry only when necessary and report the effective value in the editor. Preserve the user's chosen value for later larger screens.

The size of the transparent composition surface follows drawing requirements. It is not the user-facing Wave size. Measure full-monitor versus bounded surfaces before choosing the final host strategy. Keep the input region empty and keyboard focus disabled.

Popup backgrounds obscure external waves beneath text. If reach exceeds the artwork region, expand the card's measured layout or clip only the artwork region intentionally; never crop the end of a notification accidentally or push secondary cards off-screen.

## 5. Screen-origin contract

Resolve a monitor at event start. Work in its local logical coordinates, accounting for scale exactly once. Compute origins from actual rendered output bounds:

```text
top-left:     (inset, inset)
top-right:    (width - inset, inset)
bottom-left:  (inset, height - inset)
bottom-right: (width - inset, height - inset)
```

Waveup emits quarter-circle arcs inward from that origin. L/R matching chooses horizontal side; top/bottom chooses vertical edge. Case uses the configured fixed side. Pair/noise events start both sides on the same frame and clock. Keep origin stable during a sequence. Hotplug cancels/repositions through one resolver, without accumulating screen-global offsets on local coordinates.

Popup and Waveup previews use this exact renderer and timeline; a mock animation is not a substitute for the production path.

## 6. Other motion tokens

These are proposed targets, subject to the captured design review.

| Interaction | Motion | Timing |
|---|---|---|
| Hover/focus | Small contrast change, visible focus outline | 80–120 ms |
| Press | Subtle compression anchored to the control | 70–100 ms; release 120 ms |
| Noise selection | Move selection indicator; pending feedback immediately | 160–200 ms |
| Placement/idle | Crossfade approved same-side artwork/timer | 140–180 ms |
| Battery percentage | Stable text width; short value/color transition | 160–220 ms |
| Connect/disconnect | Content fade and layout transition preserving geometry | 180–240 ms |
| Popup enter | Opacity plus 8–12 px inward translation | 180–220 ms |
| Popup dismiss | Short reverse translation/fade | 140–180 ms |
| Popup reflow | Existing cards move to vacant positions | 160–220 ms |
| Desktop composition | Measured position/size transition without empty slots | 180–240 ms |
| Artwork mode change | Crossfade without resizing the whole surface abruptly | 140–180 ms |
| Settings changes | Immediate property update; animate only useful continuity | next scene update |

Do not delay action dispatch until an animation ends. Rapid repeat input replaces the intended target and animates from the current rendered value; it must not accumulate a stale transition queue. Events may run concurrently in separate cards and emitters without restarting siblings.

## 7. Reduced motion and lifecycle

Reduced motion is explicit: static thin arcs or a brief opacity change, no expansion, bounce, or repeated motion. Its static radius is intentional and documented. The default animated path must never inherit that radius after toggling the preference.

Stop animation work when surfaces are hidden, disposed, disconnected where appropriate, suspended, or locked. Resume from current state rather than replaying old motion. No external overlay on the lock screen. An animation cannot own a transport retry timer or notification lifetime.

## 8. Evidence required before calling motion correct

1. Reproduce the report with the actual Popup and Waveup renderer, separately and in Both mode. Record loaded source identity, config, display, scale, refresh rate, and timestamps.
2. Sample start, just-before-launch, each 250 ms boundary, sequence end, and end + 1000 ms using an injected clock. Assert radius zero before launch, monotonic growth, identical final radius, and no premature repeat.
3. Capture actual compositor frames, including the first visible stroke. Compare radius to elapsed time: it must match the timeline within one frame of rendering tolerance. The first visible stroke must not skip the first 10% of final radius; document refresh-rate limits rather than hiding them.
4. Verify that reset/opacity/easing do not reveal an old final-sized ring. Check repeated cycles, event replacement, settings edits, hidden→visible, reduce-motion toggles, and delegate reuse.
5. Verify all corners and bilateral synchronization at 1× and a second available scale, with known output bounds. Record pointer passthrough/focus behavior independently.
6. Measure a 30-second stress scene with multiple cards/events. Target p95 frame time within the reference display's frame budget and no recurring main-thread stalls over 50 ms attributable to the plugin. Report hardware and baseline; this is a target, not an existing benchmark.
7. Review light/dark captures against the approved identity. Keep recordings and a small evidence manifest linked to the verified commit.

An isolated mathematical test, a source hash, a static screenshot taken halfway through growth, or a `loaded` response cannot independently prove this contract. If the target cannot be captured on the current system, keep visual acceptance pending.
