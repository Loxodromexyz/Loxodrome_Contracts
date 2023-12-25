const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const veLox = '0x1033e636B89D1dF7cCed06b4026C10176CF737b0'
    const voter =	'0x9fAdF1D2d40dAf4a957Ca50bAdc7f789fa9Dba53'
    const RewardsDistributor = '0x82366Fc4AE2A9AAB1Db93Fa9d38c75AA8b2a032f'

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
