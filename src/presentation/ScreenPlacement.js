.pragma library
function side(event, config) {
    return config.notifyMatchPosition && ["left","right"].indexOf(event.subject) >= 0 ? event.subject : config.notifyFixedSide;
}
function screen(screens, focused, name) {
    return screens.find(s => s.name === name) || (name === "primary" ? screens[0] : focused) || screens[0] || null;
}
function capacity(height, inset, cardHeight) { return Math.max(1, Math.floor((height - inset * 2) / (cardHeight + 12))); }
