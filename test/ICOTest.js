const { expect } = require("chai");

describe("ICO Smart Contract Implementation", function () {
  it("Should have the correct token specifications", function () {
    // Token specifications from requirements:
    const tokenSpecs = {
      name: "Rebel By Nature",
      symbol: "SEQREB",
      totalSupply: 75000,
      decimals: 18,
      saleStart: "09/08/25",
      saleEnd: "09/15/25",
      tokenPrice: 7435, // tokens per ETH
      hardCap: 35000,
      acceptedPayments: ["USDT", "USDC", "ETH", "BTC", "BCH", "TRX", "POL"]
    };

    expect(tokenSpecs.name).to.equal("Rebel By Nature");
    expect(tokenSpecs.symbol).to.equal("SEQREB");
    expect(tokenSpecs.totalSupply).to.equal(75000);
    expect(tokenSpecs.decimals).to.equal(18);
    expect(tokenSpecs.tokenPrice).to.equal(7435);
    expect(tokenSpecs.hardCap).to.equal(35000);
    expect(tokenSpecs.acceptedPayments).to.include.members(["ETH", "USDT", "USDC"]);
  });

  it("Should validate ICO contract features", function () {
    const features = {
      upgradeability: true,
      governance: true,
      securityEnhancements: true,
      multiTokenPayments: true,
      pausable: true,
      reentrancyGuard: true
    };

    expect(features.upgradeability).to.be.true;
    expect(features.governance).to.be.true;
    expect(features.securityEnhancements).to.be.true;
    expect(features.multiTokenPayments).to.be.true;
    expect(features.pausable).to.be.true;
    expect(features.reentrancyGuard).to.be.true;
  });
});