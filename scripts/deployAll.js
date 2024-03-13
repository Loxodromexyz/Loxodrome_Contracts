const { ethers  } = require('hardhat');




async function main () {

  accounts = await ethers.getSigners();
  owner = accounts[0]

  console.log('Deploying Contract...');


  // WIOTX need to be updated and use the right address in the mainnet
  const WIOTX= '0x87B873224EaD2a8cbBB7CfB39b18a795e7DA8CC7' // Wrapped IoTeX(WIOTX) deployed in the testnet
  const fundAddress = '0xC2e61CFae2A04d4450533d7Ce7E0BD9607519aEf' // unclaimed tradersRewards will be sent to this address


// Loxodrome contracts 
// step 1 

  data = await ethers.getContractFactory("Loxo");
  Loxo = await data.deploy();
  txDeployed = await Loxo.deployed();
  console.log("Loxo Address: ", Loxo.address)

  const LoxoAd = Loxo.address

  data = await ethers.getContractFactory("VeArtProxy");
  veArtProxy = await data.deploy();
  txDeployed = await veArtProxy.deployed();
  console.log("veArtProxy Address: ", veArtProxy.address)

  data = await ethers.getContractFactory("VotingEscrow");
  veLoxo = await data.deploy(Loxo.address, veArtProxy.address);
  txDeployed = await veLoxo.deployed();
  console.log("veLoxo Address: ", veLoxo.address)

   const veLoxoAd = veLoxo.address
  
  data = await ethers.getContractFactory("RewardsDistributor");
  RewardsDistributor = await data.deploy(veLoxoAd);
  txDeployed = await RewardsDistributor.deployed();
  console.log("RewardsDistributor Address: ", RewardsDistributor.address)

  data = await ethers.getContractFactory("PairFactory");
  pairFactory = await data.deploy();
  txDeployed = await pairFactory.deployed();
  console.log("pairFactory: ", pairFactory.address)

  data = await ethers.getContractFactory("contracts/factories/GaugeFactoryV2.sol:GaugeFactoryV2");
  gaugeFactory = await data.deploy();
  txDeployed = await gaugeFactory.deployed();
  console.log("gaugeFactory: ", gaugeFactory.address)

  data = await ethers.getContractFactory("contracts/factories/BribeFactoryV2.sol:BribeFactoryV2");
  bribeFactory = await data.deploy();
  txDeployed = await bribeFactory.deployed();
  console.log("bribeFactory: ", bribeFactory.address)

  //Step 2

  
  const pairFactoryAd =	pairFactory.address
  const gaugeFactoryAd = gaugeFactory.address
  const bribeFactoryAd = bribeFactory.address


  data = await ethers.getContractFactory("VoterV2");
  Voter = await data.deploy();
  txDeployed = await Voter.deployed();
  console.log("Voter: ", Voter.address)


  data = await ethers.getContractFactory("WrappedExternalBribeFactory");
  wBribeFactory = await data.deploy(Voter.address);
  txDeployed = await wBribeFactory.deployed();
  console.log("WrappedExternalBribeFactory: ", wBribeFactory.address)


  const voterAd =	Voter.address
  const RewardsDistributorAd = RewardsDistributor.address



  data = await ethers.getContractFactory("Router");
  router = await data.deploy(pairFactoryAd, WIOTX);

  txDeployed = await router.deployed();
  console.log("router: ", router.address)

 // step 0 deploy NFT contract 

  const LoxoHoldersContract = await ethers.getContractFactory("contracts/LoxoHolders.sol:LoxoHolders");
  const LoxoHolders = await LoxoHoldersContract.deploy(5000, '1000000000000000000');

  await LoxoHolders.deployed();

  console.log("LoxHolders address:", LoxoHolders.address);
  
  data = await ethers.getContractFactory("MasterChef");
  MasterChef = await data.deploy(WIOTX, veLoxoAd, LoxoHolders.address); //LoxoHolders.address
  txDeployed = await MasterChef.deployed();
  console.log("Masterchef: ", MasterChef.address)

  data = await ethers.getContractFactory("Royalties");
  Royalties = await data.deploy(WIOTX, LoxoHolders.address); //LoxoHolders.address
  txDeployed = await Royalties.deployed();
  console.log("Royalties: ", Royalties.address)

  data = await ethers.getContractFactory("TraderRewards");
  traderRewards = await data.deploy(LoxoAd, fundAddress);
  txDeployed = await traderRewards.deployed();
  console.log("TraderRewards: ", traderRewards.address)

  // minter

  data = await ethers.getContractFactory("MinterV2");
  Minter = await data.deploy(voterAd, veLoxoAd, RewardsDistributorAd, MasterChef.address, traderRewards.address); 
  txDeployed = await Minter.deployed();
  console.log("MinterV2: ", Minter.address)

  // data = await ethers.getContractFactory("AirdropClaimLoxNFT");
  // airdropLoxNFT = await data.deploy(Loxo.address, veLoxoAd);
  // txDeployed = await airdropLoxNFT.deployed();
  // console.log("airdropLoxNFT: ", airdropLoxNFT.address)

  // data = await ethers.getContractFactory("MerkleTreeLoxNFT");
  // merkleTreeTHENFT = await data.deploy(airdropLoxNFT.address);
  // txDeployed = await merkleTreeTHENFT.deployed();
  // console.log("MerkleTreeTHENFT: ", merkleTreeTHENFT.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
