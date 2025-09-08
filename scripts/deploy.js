const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy mock tokens for testing
  const MockERC20Token = await ethers.getContractFactory("MockERC20Token");
  
  // Deploy staking token
  const stakingToken = await MockERC20Token.deploy(
    "Staking Token",
    "STK",
    18,
    ethers.utils.parseEther("1000000") // 1M tokens
  );
  await stakingToken.deployed();
  console.log("Staking Token deployed to:", stakingToken.address);

  // Deploy reward token
  const rewardToken = await MockERC20Token.deploy(
    "Reward Token",
    "RWD",
    18,
    ethers.utils.parseEther("1000000") // 1M tokens
  );
  await rewardToken.deployed();
  console.log("Reward Token deployed to:", rewardToken.address);

  // Deploy ExampleContract using upgrades plugin
  const ExampleContract = await ethers.getContractFactory("ExampleContract");
  
  const exampleContract = await upgrades.deployProxy(
    ExampleContract,
    [
      stakingToken.address,
      rewardToken.address,
      ethers.utils.parseEther("0.1"), // 0.1 tokens per second reward rate
      ethers.utils.parseEther("100"), // 100 tokens minimum stake
      86400 // 1 day lock period
    ],
    { 
      initializer: "initialize",
      kind: "uups"
    }
  );
  
  await exampleContract.deployed();
  console.log("ExampleContract deployed to:", exampleContract.address);

  // Transfer some reward tokens to the contract for distribution
  await rewardToken.transfer(exampleContract.address, ethers.utils.parseEther("100000"));
  console.log("Transferred 100,000 reward tokens to ExampleContract");

  console.log("\nDeployment completed!");
  console.log("Staking Token:", stakingToken.address);
  console.log("Reward Token:", rewardToken.address);
  console.log("ExampleContract:", exampleContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });