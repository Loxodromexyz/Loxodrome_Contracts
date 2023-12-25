const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]
    
  const voter = ethers.utils.getAddress("0x9fAdF1D2d40dAf4a957Ca50bAdc7f789fa9Dba53")


  console.log('Deploying Contract...');
  data = await ethers.getContractFactory("WrappedExternalBribeFactory");
  wBribeFactory = await data.deploy(voter);
  txDeployed = await wBribeFactory.deployed();
  console.log("WrappedExternalBribeFactory: ", wBribeFactory.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
