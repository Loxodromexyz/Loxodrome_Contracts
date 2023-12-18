const { ethers  } = require('hardhat');

const { ZERO_ADDRESS } = require("@openzeppelin/test-helpers/src/constants.js");
const { AddressZero } = require('@ethersproject/constants');



async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');
  
  const voter = '0x5B719A67F259A7B86D8fC5A0bfDe4786246e8637' //set voter once deployed

  /*data = await ethers.getContractFactory("BribeFactoryV2");
  bribeFactory = await upgrades.deployProxy(data,[voter], {initializer: 'initialize'});
  txDeployed = await bribeFactory.deployed();
  console.log("BribeFactoryUpgradeable: ", bribeFactory.address)*/

  data = await ethers.getContractFactory("GaugeFactoryV2");
  GaugeFactoryV2 = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
  txDeployed = await GaugeFactoryV2.deployed();
  console.log("GaugeFactoryUpgradeable: ", GaugeFactoryV2.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
