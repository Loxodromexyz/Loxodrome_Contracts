async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const LoxoHoldersContract = await ethers.getContractFactory("contracts/LoxoHolders.sol:LoxoHolders");
  const LoxoHolders = await LoxoHoldersContract.deploy(2000, '1000000000000000000');

  // Wait for this transaction to be mined
  await LoxoHolders.deployed();

  console.log("LoxHolders address:", LoxoHolders.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });