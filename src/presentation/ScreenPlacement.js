.pragma library
function side(event, config) {
    return config.notifyMatchPosition && ["left","right"].indexOf(event.subject) >= 0 ? event.subject : config.notifyFixedSide;
}
function screen(screens, focused, name) {
    return screens.find(s => s.name === name) || (name === "primary" ? screens[0] : focused) || screens[0] || null;
}
function capacity(height, inset, cardHeight) { return Math.max(1, Math.floor((height - inset * 2) / (cardHeight + 12))); }

function partSize(config, part) {
    return Number(part === "case" ? config.desktopCaseSize : config.desktopEarbudSize) || 48;
}
function partWidth(config, part) {
    return Math.max(partSize(config,part)+26,Number(config.desktopTextSize || 11)*7);
}
function groupWidth(config, parts) {
    if (!config.desktopHorizontal) return Math.max.apply(null,parts.map(part=>partWidth(config,part)).concat([0]));
    return parts.reduce((total,part)=>total+partWidth(config,part),0)+Math.max(0,parts.length-1)*config.desktopGap;
}
function partCenter(config, parts, part, availableWidth) {
    const width=groupWidth(config,parts);
    const left=config.desktopAlignment === "left" ? 0 : config.desktopAlignment === "right" ? availableWidth-width : (availableWidth-width)/2;
    const index=parts.indexOf(part);
    if (!config.desktopHorizontal || index<0) return left+width/2;
    return left+parts.slice(0,index).reduce((total,value)=>total+partWidth(config,value)+config.desktopGap,0)+partWidth(config,part)/2;
}
