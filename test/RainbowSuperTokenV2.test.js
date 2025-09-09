const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RainbowSuperTokenV2", function () {
  let token;
  let owner;
  let admin;
  let user1;
  let user2;
  let bridge;

  const TOKEN_NAME = "Rainbow Super Token V2";
  const TOKEN_SYMBOL = "RSTV2";
  const TOKEN_DECIMALS = 18;
  const INITIAL_SUPPLY = ethers.parseEther("1000000");
  const MAX_SUPPLY = ethers.parseEther("10000000");
  const TOKEN_URI = "https://example.com/token.json";

  beforeEach(async function () {
    [owner, admin, user1, user2, bridge] = await ethers.getSigners();

    const RainbowSuperTokenV2 = await ethers.getContractFactory("RainbowSuperTokenV2");
    token = await RainbowSuperTokenV2.deploy(
      TOKEN_NAME,
      TOKEN_SYMBOL,
      TOKEN_DECIMALS,
      INITIAL_SUPPLY,
      MAX_SUPPLY,
      false, // isFixedSupply
      TOKEN_URI,
      owner.address
    );
  });

  describe("Deployment", function () {
    it("Should set the correct token metadata", async function () {
      expect(await token.name()).to.equal(TOKEN_NAME);
      expect(await token.symbol()).to.equal(TOKEN_SYMBOL);
      expect(await token.decimals()).to.equal(TOKEN_DECIMALS);
      expect(await token.tokenURI()).to.equal(TOKEN_URI);
    });

    it("Should set the correct supply parameters", async function () {
      expect(await token.totalSupply()).to.equal(INITIAL_SUPPLY);
      expect(await token.maxTotalSupply()).to.equal(MAX_SUPPLY);
      expect(await token.isFixedSupply()).to.equal(false);
      expect(await token.isUnlimitedSupply()).to.equal(false);
    });

    it("Should assign initial supply to owner", async function () {
      expect(await token.balanceOf(owner.address)).to.equal(INITIAL_SUPPLY);
    });

    it("Should grant correct roles to owner", async function () {
      const ADMIN_ROLE = await token.ADMIN_ROLE();
      const DEFAULT_ADMIN_ROLE = await token.DEFAULT_ADMIN_ROLE();
      
      expect(await token.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.equal(true);
      expect(await token.hasRole(ADMIN_ROLE, owner.address)).to.equal(true);
    });
  });

  describe("Token Metadata Management", function () {
    it("Should allow owner to update token metadata", async function () {
      const newName = "New Token Name";
      const newSymbol = "NTN";
      const newURI = "https://newuri.com/token.json";

      await token.updateTokenMetadata(newName, newSymbol, newURI);

      expect(await token.name()).to.equal(newName);
      expect(await token.symbol()).to.equal(newSymbol);
      expect(await token.tokenURI()).to.equal(newURI);
    });

    it("Should not allow non-admin to update metadata", async function () {
      await expect(
        token.connect(user1).updateTokenMetadata("New Name", "NEW", "newuri")
      ).to.be.revertedWith("RainbowSuperTokenV2: caller is not owner or admin");
    });
  });

  describe("Supply Management", function () {
    it("Should allow owner to update max supply", async function () {
      const newMaxSupply = ethers.parseEther("20000000");
      
      await token.updateMaxSupply(newMaxSupply);
      
      expect(await token.maxTotalSupply()).to.equal(newMaxSupply);
    });

    it("Should not allow setting max supply below current supply", async function () {
      const lowMaxSupply = ethers.parseEther("100");
      
      await expect(
        token.updateMaxSupply(lowMaxSupply)
      ).to.be.revertedWith("RainbowSuperTokenV2: new max supply below current supply");
    });

    it("Should allow owner to mint tokens", async function () {
      const mintAmount = ethers.parseEther("1000");
      
      await token.mint(user1.address, mintAmount);
      
      expect(await token.balanceOf(user1.address)).to.equal(mintAmount);
    });

    it("Should allow public burning", async function () {
      const burnAmount = ethers.parseEther("100");
      const initialBalance = await token.balanceOf(owner.address);
      
      await token.burn(burnAmount);
      
      expect(await token.balanceOf(owner.address)).to.equal(initialBalance - burnAmount);
    });
  });

  describe("Access Control", function () {
    it("Should allow owner to add admin", async function () {
      const ADMIN_ROLE = await token.ADMIN_ROLE();
      
      await token.addAdmin(admin.address);
      
      expect(await token.hasRole(ADMIN_ROLE, admin.address)).to.equal(true);
    });

    it("Should allow admin to perform admin functions", async function () {
      const ADMIN_ROLE = await token.ADMIN_ROLE();
      await token.addAdmin(admin.address);
      
      await token.connect(admin).pause();
      expect(await token.paused()).to.equal(true);
      
      await token.connect(admin).unpause();
      expect(await token.paused()).to.equal(false);
    });
  });

  describe("Blacklist/Allowlist", function () {
    it("Should allow admin to blacklist addresses", async function () {
      await token.updateBlacklist(user1.address, true);
      
      expect(await token.blacklist(user1.address)).to.equal(true);
    });

    it("Should prevent blacklisted addresses from receiving tokens", async function () {
      await token.updateBlacklist(user1.address, true);
      
      await expect(
        token.mint(user1.address, ethers.parseEther("100"))
      ).to.be.revertedWith("RainbowSuperTokenV2: account is blacklisted");
    });

    it("Should allow admin to manage allowlist", async function () {
      await token.toggleAllowlist(true);
      await token.updateAllowlist(user1.address, true);
      
      expect(await token.allowlistEnabled()).to.equal(true);
      expect(await token.allowlist(user1.address)).to.equal(true);
      
      // Should allow minting to allowlisted address
      await token.mint(user1.address, ethers.parseEther("100"));
      expect(await token.balanceOf(user1.address)).to.equal(ethers.parseEther("100"));
    });
  });

  describe("Bridge Management", function () {
    it("Should allow owner to add bridge", async function () {
      await token.addBridge(bridge.address);
      
      expect(await token.authorizedBridges(bridge.address)).to.equal(true);
      
      const bridges = await token.getBridgeAddresses();
      expect(bridges).to.include(bridge.address);
    });

    it("Should allow authorized bridge to crosschain mint", async function () {
      await token.addBridge(bridge.address);
      
      const mintAmount = ethers.parseEther("500");
      await token.connect(bridge).crosschainMint(user1.address, mintAmount);
      
      expect(await token.balanceOf(user1.address)).to.equal(mintAmount);
    });
  });

  describe("Snapshot Functionality", function () {
    it("Should allow admin to take snapshots", async function () {
      const snapshotId = await token.takeSnapshot();
      
      expect(await token.snapshotCounter()).to.equal(1);
      expect(await token.getSnapshotTotalSupply(1)).to.equal(await token.totalSupply());
    });
  });

  describe("Anti-bot Mechanism", function () {
    it("Should allow setting transfer delay", async function () {
      const delay = 300; // 5 minutes
      
      await token.setMinTransferDelay(delay);
      
      expect(await token.minTransferDelay()).to.equal(delay);
    });
  });

  describe("Emergency Functions", function () {
    it("Should allow owner to rescue tokens", async function () {
      // This would typically be tested with actual ERC20 tokens
      // For now, just verify the function exists and has correct access control
      await expect(
        token.connect(user1).emergencyRescue(ethers.ZeroAddress, user1.address, 0)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });
});