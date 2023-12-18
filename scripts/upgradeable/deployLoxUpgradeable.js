const ether = require('@openzeppelin/test-helpers/src/ether');
const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    
    /*data = await ethers.getContractFactory("Lox");
    lox = await data.deploy();
    txDeployed = await lox.deployed();
    console.log("Lox Address: ", lox.address)*/

    data = await ethers.getContractFactory("VeArtProxyUpgradeable");
    veArtProxy = await upgrades.deployProxy(data,[], {initializer: 'initialize'});
    txDeployed = await veArtProxy.deployed();
    console.log("veArtProxy Address: ", veArtProxy.address)

    const Lox = ethers.utils.getAddress("0xc2741FB2B16DC6B0690DB833B984d20d7e56119a")

    data = await ethers.getContractFactory("VotingEscrow");
    veLox = await data.deploy(Lox, veArtProxy.address);
    txDeployed = await veLox.deployed();
    console.log("veLox Address: ", veLox.address);

    data = await ethers.getContractFactory("RewardsDistributor");
    RewardsDistributor = await data.deploy(veLox.address);
    txDeployed = await RewardsDistributor.deployed();
    console.log("RewardsDistributor Address: ", RewardsDistributor.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
