const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deployment parameters
  const TOKEN_NAME = "Rainbow Super Token V2";
  const TOKEN_SYMBOL = "RSTV2";
  const TOKEN_DECIMALS = 18;
  const INITIAL_SUPPLY = ethers.parseEther("1000000"); // 1M tokens
  const MAX_SUPPLY = ethers.parseEther("100000000"); // 100M max supply
  const IS_FIXED_SUPPLY = false; // Allow supply changes
  const TOKEN_URI = "https://api.rainbowsupertoken.com/metadata.json";
  const INITIAL_OWNER = deployer.address;

  // Deploy the contract
  const RainbowSuperTokenV2 = await ethers.getContractFactory("RainbowSuperTokenV2");
  const token = await RainbowSuperTokenV2.deploy(
    TOKEN_NAME,
    TOKEN_SYMBOL,
    TOKEN_DECIMALS,
    INITIAL_SUPPLY,
    MAX_SUPPLY,
    IS_FIXED_SUPPLY,
    TOKEN_URI,
    INITIAL_OWNER
  );

  await token.waitForDeployment();

  console.log("RainbowSuperTokenV2 deployed to:", await token.getAddress());
  console.log("Token name:", await token.name());
  console.log("Token symbol:", await token.symbol());
  console.log("Token decimals:", await token.decimals());
  console.log("Initial supply:", ethers.formatEther(await token.totalSupply()));
  console.log("Max supply:", ethers.formatEther(await token.maxTotalSupply()));
  console.log("Owner:", await token.owner());

  // Optional: Verify some initial settings
  console.log("\n=== Initial Contract State ===");
  console.log("Is Fixed Supply:", await token.isFixedSupply());
  console.log("Is Unlimited Supply:", await token.isUnlimitedSupply());
  console.log("Allowlist Enabled:", await token.allowlistEnabled());
  console.log("Min Transfer Delay:", await token.minTransferDelay());
  console.log("Current Claim Round:", await token.currentClaimRound());
  console.log("Snapshot Counter:", await token.snapshotCounter());
  console.log("Proposal Counter:", await token.proposalCounter());

  // Optional: Add some initial configuration
  console.log("\n=== Setting up initial configuration ===");
  
  // Example: Set a minimal transfer delay (5 minutes)
  const transferDelay = 300; // 5 minutes in seconds
  await token.setMinTransferDelay(transferDelay);
  console.log("Set min transfer delay to:", transferDelay, "seconds");

  // Example: Take an initial snapshot
  await token.takeSnapshot();
  console.log("Initial snapshot taken");

  console.log("\n=== Deployment Complete ===");
  console.log("Contract Address:", await token.getAddress());
  console.log("Remember to:");
  console.log("1. Verify the contract on block explorer");
  console.log("2. Add any additional admins if needed");
  console.log("3. Configure bridge addresses for cross-chain functionality");
  console.log("4. Set up claim rounds for airdrops");
  console.log("5. Configure blacklist/allowlist as needed");

  return token;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });