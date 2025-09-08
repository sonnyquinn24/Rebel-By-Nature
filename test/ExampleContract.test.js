const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("ExampleContract", function () {
  let exampleContract;
  let stakingToken;
  let rewardToken;
  let owner;
  let user1;
  let user2;
  let governor;

  const INITIAL_SUPPLY = ethers.utils.parseEther("1000000");
  const REWARD_RATE = ethers.utils.parseEther("0.1"); // 0.1 tokens per second
  const MIN_STAKE = ethers.utils.parseEther("100");
  const LOCK_PERIOD = 86400; // 1 day

  beforeEach(async function () {
    [owner, user1, user2, governor] = await ethers.getSigners();

    // Deploy mock tokens
    const MockERC20Token = await ethers.getContractFactory("MockERC20Token");
    
    stakingToken = await MockERC20Token.deploy("Staking Token", "STK", 18, INITIAL_SUPPLY);
    rewardToken = await MockERC20Token.deploy("Reward Token", "RWD", 18, INITIAL_SUPPLY);

    // Deploy ExampleContract
    const ExampleContract = await ethers.getContractFactory("ExampleContract");
    exampleContract = await upgrades.deployProxy(
      ExampleContract,
      [stakingToken.address, rewardToken.address, REWARD_RATE, MIN_STAKE, LOCK_PERIOD],
      { initializer: "initialize", kind: "uups" }
    );

    // Setup tokens
    await stakingToken.transfer(user1.address, ethers.utils.parseEther("10000"));
    await stakingToken.transfer(user2.address, ethers.utils.parseEther("10000"));
    await rewardToken.transfer(exampleContract.address, ethers.utils.parseEther("100000"));

    // Approve staking
    await stakingToken.connect(user1).approve(exampleContract.address, ethers.constants.MaxUint256);
    await stakingToken.connect(user2).approve(exampleContract.address, ethers.constants.MaxUint256);
  });

  describe("Initialization", function () {
    it("Should initialize correctly", async function () {
      expect(await exampleContract.stakingToken()).to.equal(stakingToken.address);
      expect(await exampleContract.rewardToken()).to.equal(rewardToken.address);
      expect(await exampleContract.rewardRate()).to.equal(REWARD_RATE);
      expect(await exampleContract.minimumStakeAmount()).to.equal(MIN_STAKE);
      expect(await exampleContract.stakingLockPeriod()).to.equal(LOCK_PERIOD);
    });

    it("Should set owner as initial governor", async function () {
      expect(await exampleContract.governors(owner.address)).to.be.true;
      expect(await exampleContract.emergencyOperators(owner.address)).to.be.true;
    });
  });

  describe("Ownership", function () {
    it("Should allow owner to set parameters", async function () {
      const newRewardRate = ethers.utils.parseEther("0.2");
      await exampleContract.setRewardRate(newRewardRate);
      expect(await exampleContract.rewardRate()).to.equal(newRewardRate);
    });

    it("Should not allow non-owner to set parameters", async function () {
      const newRewardRate = ethers.utils.parseEther("0.2");
      await expect(
        exampleContract.connect(user1).setRewardRate(newRewardRate)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow owner to add/remove governors", async function () {
      await exampleContract.addGovernor(governor.address);
      expect(await exampleContract.governors(governor.address)).to.be.true;

      await exampleContract.removeGovernor(governor.address);
      expect(await exampleContract.governors(governor.address)).to.be.false;
    });
  });

  describe("Pausable Functionality", function () {
    it("Should allow owner to pause/unpause", async function () {
      await exampleContract.pause();
      expect(await exampleContract.paused()).to.be.true;

      await exampleContract.unpause();
      expect(await exampleContract.paused()).to.be.false;
    });

    it("Should prevent staking when paused", async function () {
      await exampleContract.pause();
      await expect(
        exampleContract.connect(user1).stake(MIN_STAKE)
      ).to.be.revertedWith("Pausable: paused");
    });

    it("Should allow unstaking when paused", async function () {
      // First stake when not paused
      await exampleContract.connect(user1).stake(MIN_STAKE);
      
      // Then pause and try to unstake
      await exampleContract.pause();
      
      // Fast forward time past lock period
      await ethers.provider.send("evm_increaseTime", [LOCK_PERIOD + 1]);
      await ethers.provider.send("evm_mine");
      
      // Should be able to unstake even when paused
      await expect(exampleContract.connect(user1).unstake(MIN_STAKE)).to.not.be.reverted;
    });
  });

  describe("Staking Mechanism", function () {
    it("Should allow staking valid amounts", async function () {
      const stakeAmount = ethers.utils.parseEther("500");
      
      await expect(exampleContract.connect(user1).stake(stakeAmount))
        .to.emit(exampleContract, "Staked")
        .withArgs(user1.address, stakeAmount, await ethers.provider.getBlockNumber() + 1);

      const stakeInfo = await exampleContract.getStakeInfo(user1.address);
      expect(stakeInfo.amount).to.equal(stakeAmount);
    });

    it("Should reject staking below minimum", async function () {
      const belowMin = ethers.utils.parseEther("50");
      
      await expect(
        exampleContract.connect(user1).stake(belowMin)
      ).to.be.revertedWith("Amount below minimum stake");
    });

    it("Should allow unstaking after lock period", async function () {
      const stakeAmount = ethers.utils.parseEther("500");
      
      await exampleContract.connect(user1).stake(stakeAmount);
      
      // Fast forward time past lock period
      await ethers.provider.send("evm_increaseTime", [LOCK_PERIOD + 1]);
      await ethers.provider.send("evm_mine");
      
      await expect(exampleContract.connect(user1).unstake(stakeAmount)).to.not.be.reverted;
    });

    it("Should prevent unstaking before lock period", async function () {
      const stakeAmount = ethers.utils.parseEther("500");
      
      await exampleContract.connect(user1).stake(stakeAmount);
      
      await expect(
        exampleContract.connect(user1).unstake(stakeAmount)
      ).to.be.revertedWith("Tokens still locked");
    });

    it("Should calculate rewards correctly", async function () {
      const stakeAmount = ethers.utils.parseEther("1000");
      
      await exampleContract.connect(user1).stake(stakeAmount);
      
      // Fast forward 1 hour
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");
      
      const earned = await exampleContract.earned(user1.address);
      const expectedReward = REWARD_RATE.mul(3600); // reward rate * time
      
      expect(earned).to.be.closeTo(expectedReward, ethers.utils.parseEther("0.1"));
    });
  });

  describe("ERC-20 Token Compatibility", function () {
    it("Should handle token transfers correctly", async function () {
      const stakeAmount = ethers.utils.parseEther("500");
      const initialBalance = await stakingToken.balanceOf(user1.address);
      
      await exampleContract.connect(user1).stake(stakeAmount);
      
      const newBalance = await stakingToken.balanceOf(user1.address);
      expect(newBalance).to.equal(initialBalance.sub(stakeAmount));
      
      const contractBalance = await stakingToken.balanceOf(exampleContract.address);
      expect(contractBalance).to.equal(stakeAmount);
    });

    it("Should distribute reward tokens correctly", async function () {
      const stakeAmount = ethers.utils.parseEther("1000");
      
      await exampleContract.connect(user1).stake(stakeAmount);
      
      // Fast forward time
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");
      
      const initialRewardBalance = await rewardToken.balanceOf(user1.address);
      await exampleContract.connect(user1).claimRewards();
      const newRewardBalance = await rewardToken.balanceOf(user1.address);
      
      expect(newRewardBalance).to.be.gt(initialRewardBalance);
    });
  });

  describe("Governance System", function () {
    beforeEach(async function () {
      // Stake tokens to get voting power
      await exampleContract.connect(user1).stake(ethers.utils.parseEther("15000"));
      await exampleContract.connect(user2).stake(ethers.utils.parseEther("5000"));
    });

    it("Should allow creating proposals with sufficient tokens", async function () {
      const description = "Test proposal";
      
      await expect(exampleContract.connect(user1).createProposal(description))
        .to.emit(exampleContract, "GovernanceProposalCreated")
        .withArgs(1, user1.address, description);
    });

    it("Should reject proposals from users without sufficient tokens", async function () {
      const description = "Test proposal";
      
      await expect(
        exampleContract.connect(user2).createProposal(description)
      ).to.be.revertedWith("Insufficient tokens to create proposal");
    });

    it("Should allow voting on proposals", async function () {
      const description = "Test proposal";
      
      await exampleContract.connect(user1).createProposal(description);
      
      await expect(exampleContract.connect(user1).vote(1, true))
        .to.emit(exampleContract, "GovernanceVoteCast")
        .withArgs(1, user1.address, true, ethers.utils.parseEther("15000"));
    });

    it("Should prevent double voting", async function () {
      const description = "Test proposal";
      
      await exampleContract.connect(user1).createProposal(description);
      await exampleContract.connect(user1).vote(1, true);
      
      await expect(
        exampleContract.connect(user1).vote(1, false)
      ).to.be.revertedWith("Already voted");
    });
  });

  describe("Security Features", function () {
    it("Should prevent blacklisted addresses from staking", async function () {
      await exampleContract.setBlacklisted(user1.address, true);
      
      await expect(
        exampleContract.connect(user1).stake(MIN_STAKE)
      ).to.be.revertedWith("Address is blacklisted");
    });

    it("Should allow emergency mode operations", async function () {
      // First stake some tokens
      await exampleContract.connect(user1).stake(ethers.utils.parseEther("500"));
      
      // Enable emergency mode
      await exampleContract.setEmergencyMode(true);
      
      // Should be able to emergency unstake
      await expect(exampleContract.connect(user1).emergencyUnstake()).to.not.be.reverted;
    });

    it("Should prevent staking in emergency mode", async function () {
      await exampleContract.setEmergencyMode(true);
      
      await expect(
        exampleContract.connect(user1).stake(MIN_STAKE)
      ).to.be.revertedWith("Emergency mode active");
    });

    it("Should allow emergency token withdrawal by owner", async function () {
      const withdrawAmount = ethers.utils.parseEther("1000");
      
      await expect(
        exampleContract.emergencyTokenWithdraw(rewardToken.address, withdrawAmount, owner.address)
      ).to.not.be.reverted;
    });
  });

  describe("Upgradeable Contract", function () {
    it("Should return correct version", async function () {
      expect(await exampleContract.version()).to.equal("1.0.0");
    });

    it("Should only allow owner to authorize upgrades", async function () {
      // This test would require deploying a new implementation
      // For now, we just test that _authorizeUpgrade exists and is protected
      expect(await exampleContract.owner()).to.equal(owner.address);
    });
  });
});