import { MerkleTree } from "merkletreejs";
import keccak256 from "keccak256";

const whitelist = [
  '0x617F2E2fD72FD9D5503197092aC168c91465E7f2',
  '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',
  '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',
  '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB'
];

const leaves = whitelist.map(addr => keccak256(addr));
const merkleTree = new MerkleTree(leaves, keccak256, { sortPairs: true });
const rootHash = merkleTree.getRoot().toString('hex');

console.log(`Whitelist Merkle Root: 0x${rootHash}`);

whitelist.forEach((address) => {
  const hashedAddress = keccak256(address);
  const proof = merkleTree.getHexProof(hashedAddress);
  const index = leaves.findIndex(leaf => leaf.equals(hashedAddress));

  console.log(`Address: ${address} Index: ${index} Proof: ${proof}`);
});
