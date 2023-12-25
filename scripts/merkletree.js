const { ethers } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

async function main() {
  // List of addresses
  const addressAmountPairs = [
    { address: "0x2F186D06707105CCADE930Adc55eC7D35A189C98", amount: '1000000000000000000' },
    { address: "0x9Ef4b0B3087a8b2D9f3a78E6cA81a8bF73DD0097", amount: '1000000000000000000' },
    { address: "0x273321eEd515AAD1AE0B6a985875839BBDCaFAE4", amount: '1000000000000000000' }
  ];

  // Hashing the addresses
  const leaves = addressAmountPairs.map(pair => keccak256(ethers.utils.solidityPack(["address", "uint256"], [pair.address, pair.amount])));

  // Creating the Merkle tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // Getting the Merkle root
  const root = tree.getRoot().toString('hex');

  console.log("Merkle Root:", root);
  const myAddress = "0x2F186D06707105CCADE930Adc55eC7D35A189C98"; // replace with your address
  const myAmount = "1000000000000000000"; // replace with your amount
  const leaf = keccak256(ethers.utils.solidityPack(["address", "uint256"], [myAddress, myAmount]));
  const proof = tree.getHexProof(leaf);
  console.log("Merkle Proof for my address:", proof);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
