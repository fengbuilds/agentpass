**Live product / 产品页：https://fengbuilds.github.io/agentpass/**

**Contract (BNB Chain): 0xef5EA1277Ed12E6FAf8383ddDDC14F0934543019**

# AgentPass — Agent ID Holders' Daily Check-In

A daily check-in dApp on BNB Smart Chain, gated by **Binance Agent ID** (.ai).

## What it does
- Only wallets holding an Agent ID can check in — identity is the ticket.
- First check-in mints a **soulbound badge NFT** (non-transferable).
- Daily check-ins build an on-chain **streak**, bound to the holder's wallet.
- Public counters: unique agents, total check-ins, badge supply.

## How Agent ID is used
The contract calls `balanceOf(address)` on the official Agent ID registry
(SPACE ID Agent ID, `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`); a return
value > 0 means the caller holds an Agent ID. This is the access-control
gate for `checkIn()` — the identity/准入 scenario from the hackathon brief.

## Safety design
- No owner, no admin functions, nothing can be paused or reconfigured.
- The contract never takes custody of funds; `checkIn()` is non-payable.
- No login sessions, no pairing codes, no key/secret collection — users sign
  with their own wallet only.
- Badge is soulbound: all transfer/approval functions revert.

## Build & deploy
- `contracts/AgentPassCheckIn.sol` — Solidity ^0.8.20, no dependencies.
- `scripts/compile.js` — compiles with solc 0.8.26 (optimizer 200 runs);
  writes ABI, bytecode and the standard JSON input used for verification.
- `scripts/deploy.js` — deploys to BSC mainnet (constructor arg = registry).
- `site/index.html` — single-file product page (ethers.js via CDN).

## Addresses
- Agent ID registry (BSC): 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
- AgentPass contract: TBD after deployment
