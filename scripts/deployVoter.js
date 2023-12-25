const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const veLox = '0x51E5ddf8B4b8b8C08D68fEbD3Bad379B1084ef3E'

    const pairFactory =	'0x2F65c1e37f67960BdBdBd717c34fCe733040A1C0'
    const gaugeFactory = '0xeDE79ffbf23F76c40a72B8111666f62bf81a96ac'
    const bribeFactory = '0xEEe204459B5d3dF578347635B825fD882F2b7639'

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
