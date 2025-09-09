# Rebel By Nature - Smart Contracts

<img src="https://octodex.github.com/images/Professortocat_v2.png" align="right" height="200px" />

Advanced Solidity contracts with comprehensive features for modern DeFi and Web3 applications.

## 🌈 RainbowSuperTokenV2

The flagship contract of this repository - a comprehensive ERC20 token implementation with advanced features:

### ✨ Key Features

- **Dynamic Token Metadata** - Update name, symbol, and tokenURI
- **Advanced Supply Management** - Dynamic max supply, public burning, admin minting
- **Multi-Admin Access Control** - Role-based permissions with pausable functionality
- **Merkle Tree Airdrops** - Multiple claim rounds with efficient verification
- **Cross-Chain Bridge Support** - Multiple authorized bridges for seamless transfers
- **Security Features** - Blacklist/allowlist, anti-bot mechanisms, emergency rescue
- **Governance System** - On-chain proposals with time delays
- **Snapshotting** - Historical balance tracking for governance and analytics

### 🚀 Quick Start

```bash
# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm run test

# Deploy to local network
npm run node
npm run deploy
```

### 📖 Documentation

- [Complete Feature Documentation](./docs/RainbowSuperTokenV2_Features.md)
- [Deployment Guide](./scripts/deploy-rainbowsupertoken.js)
- [Usage Examples](./scripts/example-usage.js)

### 🧪 Testing

Comprehensive test suite covering all features:

```bash
npm test
```

### 🔧 Deployment

Deploy RainbowSuperTokenV2 with custom parameters:

```javascript
const token = await RainbowSuperTokenV2.deploy(
  "Token Name",        // name
  "SYMBOL",           // symbol
  18,                 // decimals
  ethers.parseEther("1000000"), // initial supply
  ethers.parseEther("100000000"), // max supply
  false,              // is fixed supply
  "https://...",      // token URI
  owner.address       // initial owner
);
```

### 🛡️ Security

- Built with OpenZeppelin's battle-tested libraries
- Comprehensive access controls and role management
- Reentrancy protection on critical functions
- Emergency pause functionality
- Extensive input validation

---

[![](https://img.shields.io/badge/Go%20to%20Exercise-%E2%86%92-1f883d?style=for-the-badge&logo=github&labelColor=197935)](https://github.com/sonnyquinn24/Rebel-By-Nature/issues/1)

---

&copy; 2025 GitHub &bull; [Code of Conduct](https://www.contributor-covenant.org/version/2/1/code_of_conduct/code_of_conduct.md) &bull; [MIT License](https://gh.io/mit)

