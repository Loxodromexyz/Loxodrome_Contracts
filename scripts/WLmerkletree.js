const { ethers } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');

const filePath = './WL.txt';

// Read addresses from the text file into an array, trimming whitespace
const rawAddressesArray = fs.readFileSync(filePath, 'utf-8').split('\n').filter(Boolean).map(address => address.trim());

// Validate Ethereum addresses: check if they start with '0x' and are 42 characters long
const isValidEthereumAddress = address => /^0x[a-fA-F0-9]{40}$/.test(address);

// Filter addresses array for valid Ethereum addresses only
const addressesArray = rawAddressesArray.filter(isValidEthereumAddress);

if (addressesArray.length === 0) {
    console.error("No valid Ethereum addresses found. Please check your WL.txt file.");
    process.exit(1);
}

async function main() {
  // Hashing the addresses
  const leaves = addressesArray.map(address => keccak256(ethers.utils.keccak256(address)));

  // Creating the Merkle tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // Getting the Merkle root
  const root = tree.getRoot().toString('hex');

  console.log("Merkle Root:", root);
  
  const myAddress = "0x9Ef4b0B3087a8b2D9f3a78E6cA81a8bF73DD0097"; // Ensure this is a valid Ethereum address
  // Hashing your address for the leaf, ensuring it's a valid Ethereum address
  if (!isValidEthereumAddress(myAddress)) {
      console.error("The specified address is invalid.");
      process.exit(1);
  }
  const leaf = keccak256(ethers.utils.keccak256(myAddress));
  const proof = tree.getHexProof(leaf);
  console.log("Merkle Proof for my address:", proof);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
