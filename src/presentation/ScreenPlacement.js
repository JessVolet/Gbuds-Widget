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

function popupRect(position, width, height, inset, occupied) {
    const cardWidth=Math.min(250,Math.max(1,width-inset*2)), cardHeight=Math.min(270,Math.max(1,height-inset*2));
    const parts=position.split("-"), vertical=parts[0], horizontal=parts[1] || "center";
    const x=horizontal==="left" ? inset : horizontal==="right" ? width-inset-cardWidth : (width-cardWidth)/2;
    const y=vertical==="top" ? inset : vertical==="bottom" ? height-inset-cardHeight : (height-cardHeight)/2;
    const candidates=[{x:x,y:y}];
    for (let step=1;step<Math.ceil(height/(cardHeight+12));step++) {
        candidates.push({x:x,y:y+step*(cardHeight+12)},{x:x,y:y-step*(cardHeight+12)});
    }
    [inset,(width-cardWidth)/2,width-inset-cardWidth].forEach(left=>{
        for(let top=inset;top+cardHeight<=height-inset;top+=cardHeight+12) candidates.push({x:left,y:top});
    });
    const point=candidates.find(p=>p.x>=inset && p.y>=inset && p.x+cardWidth<=width-inset+0.1 && p.y+cardHeight<=height-inset+0.1 && !occupied.some(r=>p.x<r.x+r.width+8 && p.x+cardWidth+8>r.x && p.y<r.y+r.height+8 && p.y+cardHeight+8>r.y));
    return point ? {x:point.x,y:point.y,width:cardWidth,height:cardHeight} : null;
}
