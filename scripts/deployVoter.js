const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const veLox = '0x51E5ddf8B4b8b8C08D68fEbD3Bad379B1084ef3E'

    const pairFactory =	'0x66Fd2800f05bC3c925d080c76e106507BDB79A6d'
    const gaugeFactory = '0xDf59967F732535EAcFF2D73b434bEbdeDf9dd7Cd'
    const bribeFactory = '0x00f8a2Ab042a0e62d851799b2afd49A9Ab0f5e24'

    data = await ethers.getContractFactory("Voter");
    Voter = await data.deploy(veLox, pairFactory, gaugeFactory, bribeFactory);
    txDeployed = await Voter.deployed();
    console.log("Voter: ", Voter.address)



}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
