const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]


    
  const voter = ethers.utils.getAddress("0x8FAb1fBA4f33B2a03369d33847fa1d4dEA923f64")
  const wbribe = ethers.utils.getAddress("0xf8D6C2Ad42746bF19be5c6fb5e9140C96d032498")
  const rewDistro = ethers.utils.getAddress("0x0656029e4ed3fE3cAEC5Cc3E16D6ABe941eDd963")
  const pairFactory = ethers.utils.getAddress("0xA175ED7358d6105847DB305ca23F9806D30af38a")
  //const pairapi = ethers.utils.getAddress("0x2b481d200c6679840435c9997dc2499fda752e09");

  console.log('Deploying Contract...');

  data = await ethers.getContractFactory("PairAPI");
  pairApi = await data.deploy();
  txDeployed = await pairApi.deployed();
  console.log("pairApi: ", pairApi.address)


  data = await ethers.getContractFactory("veNFTAPI");
  veNFTAPI = await data.deploy();
  txDeployed = await veNFTAPI.deployed();
  console.log("veNFTAPI: ", veNFTAPI.address)

  // deploy
  // data = await ethers.getContractFactory("veNFTAPI");
  // input = [voter, rewDistro, pairapi, pairFactory]
  // venftapi = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
  // txDeployed = await venftapi.deployed();
  // console.log("veNFTAPI: ", venftapi.address)

  /*data = await ethers.getContractFactory("veNFTAPI");
  console.log('upgrading...')
  venftapi = await upgrades.upgradeProxy('0x190b166Edf30Baa8C1cdBF6653107Cec1020D36D', data);
  console.log('upgraded...')*/

  


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
