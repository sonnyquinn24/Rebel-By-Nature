# Rebel By Nature ICO Smart Contract

## Overview

This implementation provides a comprehensive Initial Coin Offering (ICO) smart contract system for the "Rebel By Nature" token (SEQREB) with advanced features including upgradeability, governance, and multi-token payment support.

## Token Specifications

- **Name**: Rebel By Nature
- **Symbol**: SEQREB
- **Total Supply**: 75,000 tokens
- **Decimals**: 18
- **Sale Period**: September 8, 2025 to September 15, 2025
- **Token Price**: 1 ETH = 7,435 tokens
- **Hard Cap**: 35,000 tokens for sale

## Accepted Payment Methods

- ETH (Ethereum)
- USDT (Tether)
- USDC (USD Coin)
- BTC (Bitcoin)*
- BCH (Bitcoin Cash)*
- TRX (Tron)*
- POL (Polygon)*

*Note: BTC, BCH, TRX, and POL would require additional bridge/wrapper contracts for cross-chain functionality.

## Key Features

### 1. Upgradeability
- Uses OpenZeppelin's UUPS (Universal Upgradeable Proxy Standard) pattern
- Allows contract logic updates while preserving state
- Owner-controlled upgrade authorization

### 2. Governance
- Token holders can vote on proposals
- Timelock controller for delayed execution
- Configurable voting parameters (quorum, voting period, etc.)

### 3. Security Enhancements
- Reentrancy protection on all state-changing functions
- Pausable functionality for emergency stops
- Access control with role-based permissions
- SafeERC20 for secure token transfers

### 4. Multi-Token Payment Support
- Dynamic payment token management
- Real-time price feed integration capability
- Automatic token amount calculation
- Support for tokens with different decimals

## Smart Contracts

### RebelByNatureToken.sol
- ERC20 token with voting capabilities
- Upgradeable and pausable
- Total supply of 75,000 tokens

### RebelByNatureICO.sol
- Main ICO contract handling token sales
- Multi-token payment processing
- Time-based sale period enforcement
- Hard cap protection

### RebelByNatureGovernor.sol
- Governance contract for token holders
- Proposal creation and voting
- Timelock integration for secure execution

## Deployment

### Prerequisites
```bash
npm install
```

### Local Deployment
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### Production Deployment
1. Configure network settings in `hardhat.config.js`
2. Set environment variables for private keys and API keys
3. Run deployment script with appropriate network

## Usage

### Purchasing Tokens with ETH
```javascript
await ico.buyTokensWithETH({ value: ethAmount });
```

### Purchasing Tokens with ERC20
```javascript
await ico.buyTokensWithToken(tokenAddress, amount);
```

### Adding Payment Tokens (Owner Only)
```javascript
await ico.addPaymentToken(tokenAddress, priceInUSD, decimals);
```

### Governance Participation
```javascript
// Delegate voting power
await token.delegate(voterAddress);

// Create proposal
await governor.propose(targets, values, calldatas, description);

// Vote on proposal
await governor.castVote(proposalId, support);
```

## Security Considerations

1. **Price Oracle Integration**: In production, integrate with Chainlink or similar price feeds for accurate token pricing
2. **Multi-signature Wallet**: Use multi-sig wallets for owner functions
3. **Audit**: Conduct thorough security audits before mainnet deployment
4. **Testing**: Comprehensive testing on testnets
5. **Emergency Procedures**: Implement emergency pause and recovery mechanisms

## Testing

Run the test suite:
```bash
npx hardhat test
```

## Configuration

### Sale Period Configuration
The sale dates are hardcoded as Unix timestamps:
- Start: September 8, 2025 00:00:00 UTC
- End: September 15, 2025 00:00:00 UTC

### Payment Token Configuration
Payment tokens can be added/removed by the contract owner with their USD prices and decimal configurations.

## Future Enhancements

1. **Cross-Chain Support**: Integration with bridge protocols for BTC, BCH, TRX, and POL
2. **Advanced Governance**: Additional proposal types and voting mechanisms
3. **Staking Mechanisms**: Post-ICO staking features for token holders
4. **Liquidity Provisions**: Integration with DEX protocols for trading