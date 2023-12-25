const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const _token = ethers.utils.getAddress("0xC251308803b08Dfec5be6Ef219f083Fd58979AEa")
  const _ve = ethers.utils.getAddress("0x51E5ddf8B4b8b8C08D68fEbD3Bad379B1084ef3E")

  // data = await ethers.getContractFactory("AirdropClaimLoxNFT");
  // airdropLoxNFT = await data.deploy(_token, _ve);
  // txDeployed = await airdropLoxNFT.deployed();
  // console.log("airdropLoxNFT: ", airdropLoxNFT.address)

  data = await ethers.getContractFactory("MerkleTreeLoxNFT");
  merkleTreeTHENFT = await data.deploy('0x3c322F560c0eE9c51e2a1E289E1aD945119D7932');
  txDeployed = await merkleTreeTHENFT.deployed();
  console.log("MerkleTreeTHENFT: ", merkleTreeTHENFT.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
