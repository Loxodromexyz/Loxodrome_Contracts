const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');

  const wbnb = ethers.utils.getAddress("0xa00744882684c3e4747faefd68d283ea44099d03") 
  const nft = ethers.utils.getAddress("0x037A72510bE58E0C261EF69E48Ef101FfCE06d1e")

  data = await ethers.getContractFactory("MasterChef");
  MasterChef = await data.deploy(wbnb, nft);
  txDeployed = await MasterChef.deployed();
  console.log("Masterchef: ", MasterChef.address)


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
