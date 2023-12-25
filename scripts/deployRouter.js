const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    const pairFactory = '0x2F65c1e37f67960BdBdBd717c34fCe733040A1C0'
    const WIOTX= '0x87B873224EaD2a8cbBB7CfB39b18a795e7DA8CC7' // Wrapped IoTeX(WIOTX)

    data = await ethers.getContractFactory("Router");
    router = await data.deploy(pairFactory, WIOTX);

    txDeployed = await router.deployed();
    console.log("router: ", router.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
