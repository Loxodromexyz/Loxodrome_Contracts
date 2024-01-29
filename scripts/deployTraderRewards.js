const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]
    
  const loxo = ethers.utils.getAddress("0xeA1805ECC0c65A2D0de3F7Df8F6588d141560850")
  const fundAddress = '0x2F186D06707105CCADE930Adc55eC7D35A189C98' 


  console.log('Deploying Contract...');
  data = await ethers.getContractFactory("TraderRewards");
  traderRewards = await data.deploy(loxo, fundAddress);
  txDeployed = await traderRewards.deployed();
  console.log("TraderRewards: ", traderRewards.address)

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
