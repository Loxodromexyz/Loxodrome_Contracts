const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    
    data = await ethers.getContractFactory("Loxo");
    Loxo = await data.deploy();
    txDeployed = await Loxo.deployed();
    console.log("Loxo Address: ", Loxo.address)

    data = await ethers.getContractFactory("VeArtProxy");
    veArtProxy = await data.deploy();
    txDeployed = await veArtProxy.deployed();
    console.log("veArtProxy Address: ", veArtProxy.address)

    data = await ethers.getContractFactory("VotingEscrow");
    veLoxo = await data.deploy(Loxo.address, veArtProxy.address);
    txDeployed = await veLoxo.deployed();
    console.log("veLoxo Address: ", veLoxo.address)

    data = await ethers.getContractFactory("RewardsDistributor");
    RewardsDistributor = await data.deploy(veLoxo.address);
    txDeployed = await RewardsDistributor.deployed();
    console.log("RewardsDistributor Address: ", RewardsDistributor.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
