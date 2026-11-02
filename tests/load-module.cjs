const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
module.exports = function load(file, imports = {}) {
    const context = vm.createContext({...imports});
    vm.runInContext(fs.readFileSync(path.join(__dirname, '..', file), 'utf8').replace(/^\.(pragma|import).*$/gm, ''), context);
    return context;
};
