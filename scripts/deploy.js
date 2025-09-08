const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the token contract first
  console.log("\nDeploying RebelByNatureToken...");
  const RebelByNatureToken = await ethers.getContractFactory("RebelByNatureToken");
  const token = await upgrades.deployProxy(
    RebelByNatureToken,
    [deployer.address],
    { initializer: "initialize" }
  );
  await token.deployed();
  console.log("RebelByNatureToken deployed to:", token.address);

  // Deploy the ICO contract
  console.log("\nDeploying RebelByNatureICO...");
  const RebelByNatureICO = await ethers.getContractFactory("RebelByNatureICO");
  const ico = await upgrades.deployProxy(
    RebelByNatureICO,
    [token.address, deployer.address],
    { initializer: "initialize" }
  );
  await ico.deployed();
  console.log("RebelByNatureICO deployed to:", ico.address);

  // Transfer tokens to ICO contract for sale
  const tokensForSale = ethers.utils.parseEther("35000"); // 35,000 tokens for hard cap
  console.log("\nTransferring tokens to ICO contract...");
  await token.transfer(ico.address, tokensForSale);
  console.log("Transferred 35,000 tokens to ICO contract");

  // Setup common payment tokens (this would be done with real token addresses in production)
  console.log("\nSetting up payment tokens...");
  
  // Example USDT setup (using a placeholder address)
  // await ico.addPaymentToken(
  //   "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT mainnet address
  //   100000000, // $1.00 USD with 8 decimals
  //   6 // USDT has 6 decimals
  // );

  console.log("\nDeployment completed!");
  console.log("=".repeat(50));
  console.log("Token Contract:", token.address);
  console.log("ICO Contract:", ico.address);
  console.log("=".repeat(50));

  return {
    token: token.address,
    ico: ico.address
  };
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = main;