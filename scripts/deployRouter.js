const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    const pairFactory = '0x66Fd2800f05bC3c925d080c76e106507BDB79A6d'
    const WIOTX= '0xa00744882684c3e4747faefd68d283ea44099d03' // Wrapped IoTeX(WIOTX)

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
