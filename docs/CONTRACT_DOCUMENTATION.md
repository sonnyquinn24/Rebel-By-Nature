# ExampleContract - Advanced Smart Contract Features

## Overview

ExampleContract is a comprehensive smart contract that implements multiple advanced features commonly required in DeFi applications. It demonstrates best practices for security, upgradability, and governance.

## Features

### 1. Ownership Management
- **OpenZeppelin Ownable**: Implements standard ownership patterns
- **Role-based Access Control**: Multiple roles (Owner, Governor, Emergency Operator)
- **Administrative Functions**: Owner can modify contract parameters

### 2. Pausable Functionality
- **Emergency Stop**: Contract can be paused to halt operations
- **Selective Pausing**: Some functions remain available during pause
- **Security Measure**: Protects against exploits during emergencies

### 3. Staking Mechanism
- **Token Staking**: Users can stake ERC-20 tokens
- **Reward Distribution**: Automatic reward calculation and distribution
- **Lock Periods**: Configurable lock periods for staked tokens
- **Minimum/Maximum Limits**: Configurable stake amount limits

### 4. ERC-20 Token Compatibility
- **Full ERC-20 Support**: Compatible with any ERC-20 token
- **Safe Transfers**: Uses OpenZeppelin's SafeERC20 for secure transfers
- **Dual Token System**: Separate staking and reward tokens

### 5. Upgradeable Contract Pattern
- **UUPS Proxy Pattern**: Enables contract upgrades
- **Proxy Deployment**: Uses OpenZeppelin's upgrades plugin
- **Version Control**: Built-in version tracking

### 6. Governance System
- **Proposal Creation**: Token holders can create governance proposals
- **Voting Mechanism**: Stake-weighted voting system
- **Quorum Requirements**: Configurable participation thresholds
- **Execution Logic**: Automated proposal execution

### 7. Security Enhancements
- **Reentrancy Protection**: Guards against reentrancy attacks
- **Blacklist Functionality**: Ability to blacklist malicious addresses
- **Emergency Mode**: Special mode for emergency operations
- **Input Validation**: Comprehensive parameter validation

## Contract Architecture

```
ExampleContract
├── Initializable (OpenZeppelin)
├── OwnableUpgradeable (OpenZeppelin)
├── PausableUpgradeable (OpenZeppelin)
├── ReentrancyGuardUpgradeable (OpenZeppelin)
└── UUPSUpgradeable (OpenZeppelin)
```

## Key Functions

### Staking Functions
- `stake(uint256 amount)`: Stake tokens to earn rewards
- `unstake(uint256 amount)`: Unstake tokens and claim rewards
- `claimRewards()`: Claim accumulated rewards without unstaking
- `emergencyUnstake()`: Emergency unstake without rewards

### Governance Functions
- `createProposal(string description)`: Create a new governance proposal
- `vote(uint256 proposalId, bool support)`: Vote on a proposal
- `executeProposal(uint256 proposalId)`: Execute a passed proposal

### Administrative Functions
- `setRewardRate(uint256 rate)`: Update reward rate
- `setMinimumStakeAmount(uint256 amount)`: Set minimum stake
- `setMaxStakeAmount(uint256 amount)`: Set maximum stake
- `addGovernor(address governor)`: Add new governor
- `setBlacklisted(address account, bool status)`: Manage blacklist

### Emergency Functions
- `setEmergencyMode(bool mode)`: Toggle emergency mode
- `emergencyTokenWithdraw(address token, uint256 amount, address to)`: Emergency token recovery

## Security Features

### Access Control
- **Owner**: Full administrative control
- **Governors**: Can execute passed proposals
- **Emergency Operators**: Can trigger emergency mode

### Protection Mechanisms
- **Reentrancy Guard**: Prevents reentrancy attacks
- **Pausable**: Emergency stop functionality
- **Blacklist**: Prevents known malicious addresses from interacting
- **Input Validation**: Comprehensive parameter checks
- **Safe Math**: Uses Solidity 0.8+ built-in overflow protection

### Emergency Features
- **Emergency Mode**: Allows users to withdraw without rewards
- **Emergency Token Withdrawal**: Owner can recover stuck tokens
- **Pause Functionality**: Halt operations during emergencies

## Usage Examples

### Basic Staking
```javascript
// Approve tokens
await stakingToken.approve(contractAddress, stakeAmount);

// Stake tokens
await exampleContract.stake(ethers.utils.parseEther("1000"));

// Check rewards
const rewards = await exampleContract.earned(userAddress);

// Claim rewards
await exampleContract.claimRewards();
```

### Governance Participation
```javascript
// Create proposal (requires sufficient tokens)
await exampleContract.createProposal("Increase reward rate to 0.2 tokens per second");

// Vote on proposal
await exampleContract.vote(proposalId, true); // true for support

// Execute proposal (governors only)
await exampleContract.executeProposal(proposalId);
```

## Deployment

### Prerequisites
```bash
npm install
```

### Deploy Contracts
```bash
npx hardhat run scripts/deploy.js --network localhost
```

### Run Tests
```bash
npx hardhat test
```

## Configuration Parameters

| Parameter | Description | Default Value |
|-----------|-------------|---------------|
| `rewardRate` | Rewards per second per token | 0.1 tokens/second |
| `minimumStakeAmount` | Minimum stake required | 100 tokens |
| `stakingLockPeriod` | Lock period for stakes | 1 day (86400 seconds) |
| `votingPeriod` | Duration of governance votes | 7 days |
| `proposalThreshold` | Tokens needed to create proposal | 10,000 tokens |
| `quorum` | Required participation rate | 40% (4000 basis points) |

## Gas Optimization

The contract includes several gas optimization techniques:
- **Packed Structs**: Efficient storage layout
- **Batch Operations**: Multiple operations in single transaction
- **Lazy Reward Calculation**: Rewards calculated on-demand
- **Optimized Loops**: Minimal loop usage

## Audit Considerations

The contract follows security best practices:
- **OpenZeppelin Contracts**: Uses audited, battle-tested libraries
- **Standard Patterns**: Implements well-known security patterns
- **Comprehensive Testing**: Extensive test coverage
- **Clear Documentation**: Well-documented code and functionality

## License

MIT License - see LICENSE file for details.