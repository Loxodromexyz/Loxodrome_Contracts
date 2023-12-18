const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');

    const pairFactory = '0xfe783DA13Ec2F28e140EEebc5fEeE88caf8E700e'
    const wBNB = '0xb6425DD43801E2b759BE2CAA2f642Ab5460FBAD6'

    data = await ethers.getContractFactory("Router");
    router = await data.deploy(pairFactory, wBNB);

    txDeployed = await router.deployed();
    console.log("router: ", router.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
