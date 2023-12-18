const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]
    
  const voter = ethers.utils.getAddress("0xe60c1a6a14201C59DEaAC4Db9FA06A142cE013B0")


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
