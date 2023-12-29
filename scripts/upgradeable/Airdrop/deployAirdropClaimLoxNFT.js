const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0x3365406A7A2aA4F20991c09a4416C4069B50F4da")
  const _ve = ethers.utils.getAddress("0x140e0529695639BAd188371f38E788C438b9ae3B")

  data = await ethers.getContractFactory("AirdropClaimLoxNFT");
  airdropLoxNFT = await data.deploy(_token, _ve);
  txDeployed = await airdropLoxNFT.deployed();
  console.log("airdropLoxNFT: ", airdropLoxNFT.address)

  data = await ethers.getContractFactory("MerkleTreeLoxNFT");
  merkleTreeTHENFT = await data.deploy(airdropLoxNFT.address);
  txDeployed = await merkleTreeTHENFT.deployed();
  console.log("MerkleTreeTHENFT: ", merkleTreeTHENFT.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
