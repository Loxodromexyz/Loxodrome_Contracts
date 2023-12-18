const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0x9F6B1645E1Be571ADd5E57C1EaCC86669D977BFD'
    const pairFactory =	'0xfe783DA13Ec2F28e140EEebc5fEeE88caf8E700e'
    const gaugeFactory = '0x0075696D81ef6666E162c1abEf5D13954BB50AC1'

    // deploy new bribe factory (old 0x4ffcf83FEAE8a44F61575722aefC2706E73c7770)
    data = await ethers.getContractFactory("contracts/factories/BribeFactoryV2.sol:BribeFactoryV2");
    console.log('deploying...')
    BribeFactoryV2 = await upgrades.deployProxy(data,['0x0000000000000000000000000000000000000000'], {initializer: 'initialize'});
    txDeployed = await BribeFactoryV2.deployed();
    console.log('deployed b fact: ', BribeFactoryV2.address)


    console.log('deploying...')
    data = await ethers.getContractFactory("VoterV2_1");
    input = [ve, pairFactory, gaugeFactory, BribeFactoryV2.address]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)

    

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
