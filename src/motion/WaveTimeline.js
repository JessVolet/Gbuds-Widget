.pragma library
function options(input) {
    return {count: Math.max(1, Math.min(3, Number(input.count) || 1)),
        durationMs: Math.max(1, Number(input.durationMs) || 1400), staggerMs: 250, gapMs: 1000,
        lifetimeMs: Math.max(1, Number(input.lifetimeMs) || 5000), radiusPx: Math.max(0, Number(input.radiusPx) || 0)};
}
function sample(elapsedMs, index, input) {
    const o = options(input);
    const sequenceMs = o.durationMs + (o.count - 1) * o.staggerMs;
    const cycleMs = sequenceMs + o.gapMs;
    const cycle = Math.floor(Math.max(0, elapsedMs) / cycleMs);
    const startMs = cycle * cycleMs;
    const ageMs = elapsedMs - startMs - index * o.staggerMs;
    if (elapsedMs < 0 || elapsedMs >= o.lifetimeMs || index >= o.count ||
        startMs + sequenceMs > o.lifetimeMs || ageMs <= 0 || ageMs >= o.durationMs)
        return {radiusPx: 0, opacity: 0};
    const progress = ageMs / o.durationMs;
    return {radiusPx: o.radiusPx * progress, opacity: Math.min(1, (1 - progress) / 0.2) * 0.85};
}
