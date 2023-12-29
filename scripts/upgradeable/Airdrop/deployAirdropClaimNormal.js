const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0x3365406A7A2aA4F20991c09a4416C4069B50F4da")
  const _ve = ethers.utils.getAddress("0x140e0529695639BAd188371f38E788C438b9ae3B")

  data = await ethers.getContractFactory("AirdropClaim");
  AirdropClaim = await data.deploy(_token, _ve);
  txDeployed = await AirdropClaim.deployed();
  console.log("AirdropClaim: ", AirdropClaim.address)

  data = await ethers.getContractFactory("MerkleTree");
  MerkleTree = await data.deploy(AirdropClaim.address);
  txDeployed = await MerkleTree.deployed();
  console.log("MerkleTree: ", MerkleTree.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
