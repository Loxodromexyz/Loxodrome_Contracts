async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const LoxHoldersContract = await ethers.getContractFactory("contracts/LoxHolders.sol:LoxHolders");
  const LoxHolders = await LoxHoldersContract.deploy(2000, '1000000000000000000');

  // Wait for this transaction to be mined
  await LoxHolders.deployed();

  console.log("LoxHolders address:", LoxHolders.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });