// Deploy AgentPassCheckIn to BSC mainnet from the local sprint wallet.
// Key is read from ~/local-wallet/key.txt and never printed.
const fs = require('fs');
const { ethers } = require('ethers');

async function main() {
  const key = fs.readFileSync(process.env.HOME + '/local-wallet/key.txt', 'utf8').trim();
  const provider = new ethers.JsonRpcProvider('https://bsc-dataseed.bnbchain.org');
  const wallet = new ethers.Wallet(key, provider);
  const bal = await provider.getBalance(wallet.address);
  console.log('deployer:', wallet.address, 'BNB:', ethers.formatEther(bal));
  if (bal === 0n) { console.error('NO GAS - abort'); process.exit(1); }

  const abi = JSON.parse(fs.readFileSync('build/AgentPassCheckIn.abi.json', 'utf8'));
  const bytecode = fs.readFileSync('build/bytecode.txt', 'utf8').trim();
  const REGISTRY = '0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F';
  const factory = new ethers.ContractFactory(abi, bytecode, wallet);
  const contract = await factory.deploy(REGISTRY);
  const tx = contract.deploymentTransaction();
  console.log('deploy tx:', tx.hash);
  await contract.waitForDeployment();
  const addr = await contract.getAddress();
  console.log('deployed at:', addr);
  // sanity reads
  console.log('isAgent(AW 0xCd71...806a):', await contract.isAgent('0xCd710a311aedb31068661B6c8dfcdAff555b806a'));
  console.log('canCheckIn(AW):', await contract.canCheckIn('0xCd710a311aedb31068661B6c8dfcdAff555b806a'));
  fs.writeFileSync('build/deployed.json', JSON.stringify({ address: addr, tx: tx.hash, deployer: wallet.address, registry: REGISTRY }, null, 2));
}
main().catch(e => { console.error(e.message); process.exit(1); });
