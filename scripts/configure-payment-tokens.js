const { ethers } = require("hardhat");

/**
 * Script to configure payment tokens for the ICO
 * Run after deployment to set up supported payment methods
 */
async function main() {
  // Replace with your deployed ICO contract address
  const ICO_CONTRACT_ADDRESS = process.env.ICO_CONTRACT_ADDRESS || "";
  
  if (!ICO_CONTRACT_ADDRESS) {
    console.error("Please set ICO_CONTRACT_ADDRESS environment variable");
    process.exit(1);
  }

  const [deployer] = await ethers.getSigners();
  console.log("Configuring payment tokens with account:", deployer.address);

  // Get the ICO contract instance
  const RebelByNatureICO = await ethers.getContractFactory("RebelByNatureICO");
  const ico = RebelByNatureICO.attach(ICO_CONTRACT_ADDRESS);

  // Payment token configurations
  // Note: These are example addresses - use actual mainnet addresses in production
  const paymentTokens = [
    {
      name: "USDT",
      address: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT on Ethereum
      price: 100000000, // $1.00 USD with 8 decimals
      decimals: 6
    },
    {
      name: "USDC",
      address: "0xA0b86a33E6b123BBaA21b1b3a1e3a8afcc9bAC86", // USDC on Ethereum  
      price: 100000000, // $1.00 USD with 8 decimals
      decimals: 6
    },
    // Note: BTC, BCH, TRX, POL would need wrapper/bridge tokens on Ethereum
    {
      name: "WBTC",
      address: "0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599", // Wrapped Bitcoin
      price: 4300000000000, // ~$43,000 USD with 8 decimals
      decimals: 8
    },
    {
      name: "POL",
      address: "0x455e53CFaB9067B4c89d53bb40B3e78d4f4d5E05", // Polygon Ecosystem Token
      price: 45000000, // ~$0.45 USD with 8 decimals  
      decimals: 18
    }
  ];

  console.log("\nAdding payment tokens...");

  for (const token of paymentTokens) {
    try {
      console.log(`Adding ${token.name}...`);
      const tx = await ico.addPaymentToken(
        token.address,
        token.price,
        token.decimals
      );
      await tx.wait();
      console.log(`✅ ${token.name} added successfully`);
    } catch (error) {
      console.error(`❌ Failed to add ${token.name}:`, error.message);
    }
  }

  // Update ETH price if needed
  console.log("\nUpdating ETH price...");
  try {
    const ethPrice = 250000000000; // $2,500 USD with 8 decimals
    const tx = await ico.updateTokenPrice(ethers.constants.AddressZero, ethPrice);
    await tx.wait();
    console.log("✅ ETH price updated successfully");
  } catch (error) {
    console.error("❌ Failed to update ETH price:", error.message);
  }

  console.log("\nPayment token configuration completed!");
  
  // Display current configuration
  console.log("\n" + "=".repeat(50));
  console.log("CURRENT ICO CONFIGURATION");
  console.log("=".repeat(50));
  
  const remainingTokens = await ico.getRemainingTokens();
  const isActive = await ico.isICOActive();
  
  console.log(`ICO Active: ${isActive}`);
  console.log(`Remaining Tokens: ${ethers.utils.formatEther(remainingTokens)} SEQREB`);
  
  for (const token of paymentTokens) {
    const isSupported = await ico.supportedTokens(token.address);
    console.log(`${token.name}: ${isSupported ? '✅ Supported' : '❌ Not Supported'}`);
  }
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