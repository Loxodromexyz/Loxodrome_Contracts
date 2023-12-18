const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const veLox = '0x51E5ddf8B4b8b8C08D68fEbD3Bad379B1084ef3E'
    const voter =	'0xe60c1a6a14201C59DEaAC4Db9FA06A142cE013B0'
    const RewardsDistributor = '0x6fC9F444E926cDafC7D501D3a7C3d38f6B830a2c'

    data = await ethers.getContractFactory("Minter");
    Minter = await data.deploy(voter, veLox, RewardsDistributor);
    txDeployed = await Minter.deployed();
    console.log("Minter: ", Minter.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
