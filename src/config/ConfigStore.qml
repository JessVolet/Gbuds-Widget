import QtQuick
import "Schema.js" as Schema

Item {
    id:root
    property var source:({})
    property bool locked:false
    property var overrides:({})
    property var pending:({})
    readonly property var value:Schema.resolve(Object.assign({},source,overrides),locked)
    signal persist(string key, var value)
    function update(key, value) {
        if (["__proto__","constructor","prototype"].indexOf(key)>=0) return;
        overrides=Object.assign({},overrides,{[key]:value});
        pending=Object.assign({},pending,{[key]:value});
        writer.restart();
    }
    function flush() {
        const changes=pending; pending={};
        Object.keys(changes).forEach(key=>root.persist(key,changes[key]));
    }
    onSourceChanged:overrides=({})
    Timer { id:writer; interval:60; onTriggered:root.flush() }
    Component.onDestruction:flush()
}
