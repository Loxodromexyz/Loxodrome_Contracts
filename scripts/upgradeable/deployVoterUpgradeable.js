const { ethers  } = require('hardhat');




async function main () {
    accounts = await ethers.getSigners();
    owner = accounts[0]

    console.log('Deploying Contract...');
    
    const ve = '0x9F6B1645E1Be571ADd5E57C1EaCC86669D977BFD'
    const pairFactory =	'0xfe783DA13Ec2F28e140EEebc5fEeE88caf8E700e'
    const gaugeFactory = '0x0075696D81ef6666E162c1abEf5D13954BB50AC1'
    const bribeFactory = '0xC90163315DE7d45087d80a609964AbAB744C37E4'
    const wbribeFactory = '0x379f13600ccF0B76A15d1dda6a7a70c4606CB545'

    data = await ethers.getContractFactory("VoterUpgradeable");
    input = [ve, pairFactory, gaugeFactory, bribeFactory, wbribeFactory]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)

    data = await ethers.getContractFactory("VoterV2");
    input = [ve, pairFactory, gaugeFactory, bribeFactory]
    voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    console.log("Voter: ", voter.address)

    /*data = await ethers.getContractFactory("VoterV2");
    console.log('upgrading...')
    VoterV2 = await upgrades.upgradeProxy('0x43659f29356b7D84f6464957db06f1fD883A706B', data);
    console.log('upgraded...')*/

    // data = await ethers.getContractFactory("VoterV2_1");
    // input = [ve, pairFactory, gaugeFactory, bribeFactory]
    // voter = await upgrades.deployProxy(data,input, {initializer: 'initialize'});
    // console.log("Voter: ", voter.address)

    

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
