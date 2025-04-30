# 🖼️ Advanced NFT Contract

This project implements an advanced NFT smart contract on Ethereum using Solidity. It features a Merkle-tree-based whitelist, gas optimization with BitMaps, commit-reveal randomness, a multicall interface, and a secure pull-based withdrawal system.

## 🚀 Features

### ✅ Merkle Tree Whitelist Airdrop
- Only addresses in the Merkle Tree can mint.
- Leaf format: `keccak256(abi.encodePacked(index, address))`.
- Prevents double claiming using **BitMaps** and **Mapping** for gas comparison.

### 🔬 Gas Comparison
- Two minting methods:
  - `merkleMintWithMapping()`: Tracks claims with a mapping.
  - `merkleMintWithBitmap()`: Tracks claims with a BitMap.
- Compare gas usage between both.

### 🎲 Commit-Reveal NFT Randomness
- Users `commit` a hash of a secret and salt.
- After 10 blocks, users `reveal` the secret to mint a **random NFT ID**.

### 🧩 Multicall Support
- Batch multiple `transferFrom()` or other safe actions in a single transaction.
- Minting is **protected** from abuse via multicall.

### 🧠 Sale State Machine
- Sale phases:
  - `CLOSED`
  - `PRESALE`
  - `PUBLIC`
  - `SOLD_OUT`
- Contract logic is restricted based on sale phase.

### 💸 Pull-Based Withdrawals
- Secure pull pattern for fund distribution.
- Owner can deposit ETH to contributors.
- Each address can withdraw their allocated amount independently.

## 🧪 Testing
Recommended testing with [Hardhat](https://hardhat.org/):

```bash
npm install
npx hardhat test
