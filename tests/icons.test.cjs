const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname,"../presentation/ApprovedIcons.js"),"utf8");
const icons = vm.createContext({});
vm.runInContext(source.replace(/^\.pragma library\n/,""),icons);
const pink={r:1,g:0.5,b:0.75,a:1};
test("approved SVGs are independent vectors and flattened for Qt",()=>{
  for(const name of ["bud-left","bud-right","case","idle-timer","mode-anc","mode-ambient","mode-normal"]) {
    const svg=icons.templates[name];
    assert.ok(svg,name);
    assert.equal((svg.match(/<svg\b/g)||[]).length,1,name);
    assert.doesNotMatch(svg,/<image\b|data:image\/png/);
  }
  assert.notEqual(icons.templates["bud-left"],icons.templates["bud-right"]);
});
test("theme coloring preserves timer cutouts and ANC mask semantics",()=>{
  for(const name of Object.keys(icons.templates)) {
    const svg=decodeURIComponent(icons.url(name,pink,pink,false).split(",").slice(1).join(","));
    assert.doesNotMatch(svg,/currentColor/);
    assert.match(svg,/rgb\(255,128,191\)/);
  }
  assert.match(icons.templates["idle-timer"],/fill-rule="evenodd"/);
  assert.match(icons.templates["mode-anc"],/fill="white"/);
  assert.match(icons.templates["mode-anc"],/fill="black"/);
});
test("both earbud SVGs retain the supplied head and sensor",()=>{
  for(const name of ["bud-left","bud-right"]) {
    assert.match(icons.templates[name],/cx="245" cy="175" r="133"/);
    assert.match(icons.templates[name],/cx="215" cy="118" r="20"/);
  }
});
