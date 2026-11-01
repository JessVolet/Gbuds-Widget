.pragma library
var stem = "M13.1 9.1C12.1 9.8 10.8 10.1 9.5 9.7C7.3 9.1 6.6 7 7.5 5.1C8.4 3.2 10.9 2.5 13.1 3.4C15.2 4.2 16.2 6 16.2 8.2V20.2C16.2 21.4 15.7 22 14.7 22C13.7 22 13.1 21.4 13.1 20.2Z";
var small = "M10.5 5C14.1 4.2 17 7.1 17 11.8C17 16.2 15 19 12 19C9 19 7.4 16.6 7 13.7C5.7 13.4 5.1 12.4 5.4 11.3C5.7 10.2 6.5 9.7 7.5 9.5C7.9 7.1 8.8 5.6 10.5 5Z";
var timer = "M12 2C6.47715 2 2 6.47715 2 12C2 17.5228 6.47715 22 12 22C17.5228 22 22 17.5228 22 12C22 6.47715 17.5228 2 12 2ZM13 7C13 6.44772 12.5523 6 12 6C11.4477 6 11 6.44772 11 7V12C11 12.5523 11.4477 13 12 13C12.5523 13 13 12.5523 13 12V7ZM19.2929 2.29289C18.9024 2.68342 18.9024 3.31658 19.2929 3.70711L20.2929 4.70711C20.6834 5.09763 21.3166 5.09763 21.7071 4.70711C22.0976 4.31658 22.0976 3.68342 21.7071 3.29289L20.7071 2.29289C20.3166 1.90237 19.6834 1.90237 19.2929 2.29289Z";
function rgb(c) { return "rgb(" + [c.r,c.g,c.b].map(v => Math.round(v*255)).join(",") + ")"; }
function url(body) {
    return "data:image/svg+xml," + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">' + body + '</svg>');
}
function earbud(part, model, tint, fill, filled) {
    var compact = /SM-R400|SM-R177|SM-R170|SM-R175|SM-R180|SM-R190|SM-R510/.test(model.toUpperCase());
    var d = part === "case" ? "M8 4H16Q20 4 20 8V17Q20 21 16 21H8Q4 21 4 17V8Q4 4 8 4ZM4 10H20M10 15H14" : compact ? small : stem;
    var transform = part === "right" ? ' transform="translate(24 0) scale(-1 1)"' : "";
    return url('<path' + transform + ' d="' + d + '" fill="' + (filled ? rgb(fill) : "none") + '" fill-opacity="' + fill.a + '" stroke="' + rgb(tint) + '" stroke-opacity="' + tint.a + '" stroke-width="1.25" stroke-linecap="round" stroke-linejoin="round"/>');
}
function idle(tint) { return url('<path d="' + timer + '" fill="' + rgb(tint) + '" fill-opacity="' + tint.a + '" fill-rule="evenodd"/>'); }
