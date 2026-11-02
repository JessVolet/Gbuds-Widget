.pragma library
function luminance(c) {
    const linear=value=>value<=0.04045 ? value/12.92 : Math.pow((value+0.055)/1.055,2.4);
    return .2126*linear(c.r)+.7152*linear(c.g)+.0722*linear(c.b);
}
function ratio(a,b) { const x=luminance(a),y=luminance(b); return (Math.max(x,y)+.05)/(Math.min(x,y)+.05); }
function foreground(preferred, background, candidates) {
    if (!background || background.a<.7 || ratio(preferred,background)>=3) return preferred;
    return candidates.reduce((best,color)=>ratio(color,background)>ratio(best,background) ? color : best,preferred);
}
