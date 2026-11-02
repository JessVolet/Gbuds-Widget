.pragma library
function address(value) { return String(value || "").replace(/[^a-f0-9]/gi,"").toUpperCase(); }
function output(nodes, mac) {
    const identity=address(mac);
    if (identity.length!==12) return null;
    const matches=nodes.filter(node=>{
        if (!node.audio || !node.isSink || node.isStream) return false;
        const props=node.properties || {};
        return [props["api.bluez5.address"],props["device.string"],props["device.name"],node.name].some(value=>address(value).includes(identity));
    });
    return matches.length===1 ? matches[0] : null;
}
