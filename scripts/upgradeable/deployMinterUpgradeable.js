const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0x9F6B1645E1Be571ADd5E57C1EaCC86669D977BFD'
    const voter =	'0x3C2c56C379097725815046a95F89204141b2eC05'
    const rewDistro = '0x6530Ff6e2BE393Bb57a7D112367082BbE782d53C'

    data = await ethers.getContractFactory("MinterUpgradeable");
    input = [voter, ve, rewDistro]
    minter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Minter: ", minter.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
