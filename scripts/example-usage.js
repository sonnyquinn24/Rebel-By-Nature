const { ethers } = require("hardhat");

/**
 * Example usage script demonstrating key features of RainbowSuperTokenV2
 * This script shows how to interact with the contract after deployment
 */
async function main() {
  // Get signers
  const [owner, admin, user1, user2, bridge] = await ethers.getSigners();
  
  // Replace with your deployed contract address
  const CONTRACT_ADDRESS = "0x..."; // Update this with actual deployed address
  
  // Get contract instance
  const RainbowSuperTokenV2 = await ethers.getContractFactory("RainbowSuperTokenV2");
  const token = RainbowSuperTokenV2.attach(CONTRACT_ADDRESS);
  
  console.log("=== RainbowSuperTokenV2 Usage Examples ===\n");
  
  // 1. Token Information
  console.log("1. Token Information:");
  console.log(`Name: ${await token.name()}`);
  console.log(`Symbol: ${await token.symbol()}`);
  console.log(`Decimals: ${await token.decimals()}`);
  console.log(`Total Supply: ${ethers.formatEther(await token.totalSupply())}`);
  console.log(`Max Supply: ${ethers.formatEther(await token.maxTotalSupply())}`);
  console.log(`Token URI: ${await token.tokenURI()}\n`);
  
  // 2. Access Control Management
  console.log("2. Access Control Management:");
  
  // Add admin
  await token.addAdmin(admin.address);
  console.log(`Added ${admin.address} as admin`);
  
  // Check admin role
  const ADMIN_ROLE = await token.ADMIN_ROLE();
  const isAdmin = await token.hasRole(ADMIN_ROLE, admin.address);
  console.log(`${admin.address} is admin: ${isAdmin}\n`);
  
  // 3. Supply Management
  console.log("3. Supply Management:");
  
  // Mint tokens to user1
  const mintAmount = ethers.parseEther("1000");
  await token.mint(user1.address, mintAmount);
  console.log(`Minted ${ethers.formatEther(mintAmount)} tokens to ${user1.address}`);
  
  // Check balance
  const balance = await token.balanceOf(user1.address);
  console.log(`User1 balance: ${ethers.formatEther(balance)}\n`);
  
  // 4. Bridge Management
  console.log("4. Bridge Management:");
  
  // Add bridge
  await token.addBridge(bridge.address);
  console.log(`Added bridge: ${bridge.address}`);
  
  // Bridge mint
  const bridgeMintAmount = ethers.parseEther("500");
  await token.connect(bridge).crosschainMint(user2.address, bridgeMintAmount);
  console.log(`Bridge minted ${ethers.formatEther(bridgeMintAmount)} to ${user2.address}`);
  
  // Check user2 balance
  const user2Balance = await token.balanceOf(user2.address);
  console.log(`User2 balance: ${ethers.formatEther(user2Balance)}\n`);
  
  // 5. Blacklist/Allowlist Management
  console.log("5. Blacklist/Allowlist Management:");
  
  // Add to allowlist
  await token.updateAllowlist(user1.address, true);
  await token.updateAllowlist(user2.address, true);
  console.log("Added users to allowlist");
  
  // Enable allowlist
  await token.toggleAllowlist(true);
  console.log("Allowlist enabled");
  
  // Try transfer (should work as both users are allowlisted)
  const transferAmount = ethers.parseEther("100");
  await token.connect(user1).transfer(user2.address, transferAmount);
  console.log(`Transferred ${ethers.formatEther(transferAmount)} from user1 to user2\n`);
  
  // 6. Snapshot Functionality
  console.log("6. Snapshot Functionality:");
  
  // Take snapshot
  await token.takeSnapshot();
  const snapshotId = await token.snapshotCounter();
  console.log(`Snapshot taken, ID: ${snapshotId}`);
  
  // Get snapshot data
  const snapshotSupply = await token.getSnapshotTotalSupply(snapshotId);
  console.log(`Snapshot total supply: ${ethers.formatEther(snapshotSupply)}\n`);
  
  // 7. Claim Round Setup (Example)
  console.log("7. Claim Round Setup:");
  
  // Example merkle root (in practice, this would be calculated from actual claim data)
  const exampleMerkleRoot = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
  const startTime = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
  const endTime = startTime + 86400; // 24 hours duration
  
  await token.createClaimRound(exampleMerkleRoot, startTime, endTime);
  const currentRound = await token.currentClaimRound();
  console.log(`Created claim round ${currentRound} with merkle root: ${exampleMerkleRoot}`);
  
  const [merkleRoot, isActive, roundStart, roundEnd] = await token.getClaimRoundInfo(currentRound);
  console.log(`Round active: ${isActive}, Start: ${new Date(Number(roundStart) * 1000).toISOString()}, End: ${new Date(Number(roundEnd) * 1000).toISOString()}\n`);
  
  // 8. Governance Proposal
  console.log("8. Governance Proposal:");
  
  // Create a proposal to update max supply
  const newMaxSupply = ethers.parseEther("200000000");
  const proposalCallData = token.interface.encodeFunctionData("updateMaxSupply", [newMaxSupply]);
  
  await token.createProposal("Increase max supply to 200M tokens", proposalCallData);
  const proposalId = await token.proposalCounter();
  console.log(`Created governance proposal ${proposalId} to increase max supply`);
  
  const [proposer, description, proposalTime, executionTime, executed, cancelled] = await token.getProposalInfo(proposalId);
  console.log(`Proposal by: ${proposer}`);
  console.log(`Description: ${description}`);
  console.log(`Execution time: ${new Date(Number(executionTime) * 1000).toISOString()}\n`);
  
  // 9. Anti-bot Configuration
  console.log("9. Anti-bot Configuration:");
  
  // Set transfer delay
  const transferDelay = 300; // 5 minutes
  await token.setMinTransferDelay(transferDelay);
  console.log(`Set minimum transfer delay to ${transferDelay} seconds\n`);
  
  // 10. Pausable Functionality
  console.log("10. Pausable Functionality:");
  
  // Pause contract
  await token.connect(admin).pause();
  console.log("Contract paused by admin");
  
  // Try transfer while paused (should fail)
  try {
    await token.connect(user1).transfer(user2.address, ethers.parseEther("1"));
    console.log("Transfer succeeded (unexpected)");
  } catch (error) {
    console.log("Transfer failed as expected while paused");
  }
  
  // Unpause
  await token.connect(admin).unpause();
  console.log("Contract unpaused by admin\n");
  
  // 11. Token Burning
  console.log("11. Token Burning:");
  
  const burnAmount = ethers.parseEther("50");
  const balanceBeforeBurn = await token.balanceOf(user1.address);
  
  await token.connect(user1).burn(burnAmount);
  
  const balanceAfterBurn = await token.balanceOf(user1.address);
  console.log(`User1 burned ${ethers.formatEther(burnAmount)} tokens`);
  console.log(`Balance before: ${ethers.formatEther(balanceBeforeBurn)}, after: ${ethers.formatEther(balanceAfterBurn)}\n`);
  
  // 12. Emergency Rescue (Example - owner only)
  console.log("12. Emergency Functions:");
  console.log("Emergency rescue function available to owner for stuck tokens/ETH");
  console.log("Bridge addresses can be updated for cross-chain operations");
  console.log("Multiple admins can be added/removed for decentralized management\n");
  
  console.log("=== Usage Examples Complete ===");
  console.log("All major features demonstrated successfully!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });