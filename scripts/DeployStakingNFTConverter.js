const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  StakingNFT = await ethers.getContractFactory("StakingNFTFeeConverter");
  StakingNFTFeeConverter = await StakingNFT.deploy();
  txDeployed = await StakingNFTFeeConverter.deployed();
  console.log("StakingNFTFeeConverter: ", StakingNFTFeeConverter.address)  

  NFTSales = await ethers.getContractFactory("NFTSalesSplitter");
  NFTSalesSplitter = await NFTSales.deploy();
  txDeployed = await NFTSalesSplitter.deployed();
  console.log("NFTSalesSplitter: ", NFTSalesSplitter.address)  





}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
