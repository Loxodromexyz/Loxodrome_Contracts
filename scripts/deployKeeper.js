const ether = require('@openzeppelin/test-helpers/src/ether');
const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');
  
  const minter = ethers.utils.getAddress("0x14eF8583a98067ADc35b5f16A7fBB80FDC811692")
  const voter = ethers.utils.getAddress("0xe60c1a6a14201C59DEaAC4Db9FA06A142cE013B0")
   

  data = await ethers.getContractFactory("EpochController");
  EpochController = await data.deploy();
  txDeployed = await EpochController.deployed();
  console.log("EpochController: ", EpochController.address)
  

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
