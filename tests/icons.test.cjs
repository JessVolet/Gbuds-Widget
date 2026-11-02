const {test} = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const source = fs.readFileSync(path.join(__dirname,"../src/presentation/ApprovedIcons.js"),"utf8");
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
test("theme coloring preserves timer and centered ANC cutouts",()=>{
  for(const name of Object.keys(icons.templates)) {
    const svg=decodeURIComponent(icons.url(name,pink,pink,false).split(",").slice(1).join(","));
    assert.doesNotMatch(svg,/currentColor/);
    assert.match(svg,/rgb\(255,128,191\)/);
  }
  assert.match(icons.templates["idle-timer"],/fill-rule="evenodd"/);
  assert.match(icons.templates["mode-anc"],/mask=/);
  assert.match(icons.templates["mode-anc"],/fill="black"/);
  assert.match(icons.templates["mode-anc"],/fill="white"/);
  assert.match(icons.templates["mode-anc"],/scale\(0.85\)/);
});
test("Blade geometry uses the opposite poses selected in the template",()=>{
  for(const name of ["bud-left","bud-right"]) {
    assert.ok(icons.templates[name].includes("rotate(54 24 24)"));
    assert.ok(icons.templates[name].includes("M30 18V38L25.5 41L21 38"));
  }
  assert.ok(icons.templates["bud-left"].includes("rotate(180 24 24)"));
  assert.ok(!icons.templates["bud-right"].includes("rotate(180 24 24)"));
});
test("noise controls retain the original paths from all four supplied SVGs",()=>{
  function paths(svg) {
    return [...svg.matchAll(/<path\b[^>]*\bd="([^"]*)"/g)].map(m=>m[1].replace(/\s+/g,""));
  }
  for(const [mode,files] of [
    ["mode-anc",["shield-alt-1-svgrepo-com.svg","ear-2-svgrepo-com.svg"]],
    ["mode-ambient",["ear-3-svgrepo-com.svg"]],
    ["mode-normal",["power-off-svgrepo-com.svg"]]
  ]) {
    const rendered=paths(icons.templates[mode]);
    for(const file of files) {
      const original=fs.readFileSync(path.join(__dirname,"../assets/source-icons",file),"utf8");
      assert.ok(paths(original).length > 0, "original contains paths: "+file);
      for(const p of paths(original)) assert.ok(rendered.includes(p),mode+" / "+file);
    }
  }
});

const artwork=require('./load-module.cjs')('src/presentation/ArtworkResolver.js');
test('notification artwork follows subject, storage and render selection',()=>{
  assert.deepEqual(Array.from(artwork.notificationParts({subject:'right'},'svg')),['right']);
  assert.deepEqual(Array.from(artwork.notificationParts({subject:'left',kind:'stored'},'auto')),['case']);
  assert.deepEqual(Array.from(artwork.notificationParts({subject:'mode'},'render')),['left','right']);
  assert.deepEqual(Array.from(artwork.notificationParts({subject:'mode'},'svg')),[]);
});
