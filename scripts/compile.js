const fs = require('fs');
const solc = require('solc');
const src = fs.readFileSync('contracts/AgentPassCheckIn.sol', 'utf8');
const input = {
  language: 'Solidity',
  sources: { 'AgentPassCheckIn.sol': { content: src } },
  settings: {
    optimizer: { enabled: true, runs: 200 },
    outputSelection: { '*': { '*': ['abi', 'evm.bytecode.object', 'evm.deployedBytecode.object'] } }
  }
};
fs.writeFileSync('build/standard-json-input.json', JSON.stringify(input, null, 2));
const out = JSON.parse(solc.compile(JSON.stringify(input)));
if (out.errors) {
  for (const e of out.errors) console.log(e.severity.toUpperCase(), e.formattedMessage);
  if (out.errors.some(e => e.severity === 'error')) process.exit(1);
}
const c = out.contracts['AgentPassCheckIn.sol']['AgentPassCheckIn'];
fs.mkdirSync('build', { recursive: true });
fs.writeFileSync('build/AgentPassCheckIn.abi.json', JSON.stringify(c.abi, null, 2));
fs.writeFileSync('build/bytecode.txt', c.evm.bytecode.object);
console.log('compiled OK, bytecode bytes:', c.evm.bytecode.object.length / 2, 'runtime bytes:', c.evm.deployedBytecode.object.length / 2);
