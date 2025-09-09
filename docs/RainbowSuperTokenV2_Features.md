# RainbowSuperTokenV2 - Feature Documentation

## Overview

RainbowSuperTokenV2 is a comprehensive ERC20 token implementation that extends the basic token functionality with advanced features for modern DeFi and Web3 applications. The contract is built using OpenZeppelin's battle-tested libraries and follows security best practices.

## Key Features

### 1. Token Details Management
- **Dynamic Metadata**: Token name, symbol, and tokenURI can be updated by owner/admin
- **Configurable Decimals**: Decimals are set during deployment and cannot be changed
- **URI Support**: Includes tokenURI for metadata compatibility with NFT-like features

**Functions:**
- `updateTokenMetadata(string name, string symbol, string tokenURI)` - Updates token metadata
- `tokenURI()` - Returns the token URI

### 2. Supply Management
- **Dynamic Max Supply**: Owner can increase/decrease max supply (cannot go below current supply)
- **Flexible Supply Types**: Supports fixed, unlimited, or dynamic supply models
- **Public Burning**: Any token holder can burn their tokens
- **Admin Minting**: Owner/admin can mint new tokens (respecting max supply limits)

**Functions:**
- `updateMaxSupply(uint256 newMaxSupply)` - Updates maximum total supply
- `setSupplyType(bool isFixed, bool isUnlimited)` - Sets supply type
- `mint(address to, uint256 amount)` - Mints tokens to specified address
- `burn(uint256 amount)` - Burns caller's tokens
- `burnFrom(address account, uint256 amount)` - Burns tokens from account (with allowance)

### 3. Ownership & Access Control
- **Transferable Ownership**: Built on OpenZeppelin's Ownable
- **Multi-Admin Support**: Multiple administrators with role-based permissions
- **Pausable Functionality**: Admin can pause all transfers, minting, and burning
- **Role-Based Access**: Uses AccessControl for granular permissions

**Roles:**
- `ADMIN_ROLE` - Administrative functions
- `BRIDGE_ROLE` - Cross-chain bridge operations
- `DEFAULT_ADMIN_ROLE` - Role management

**Functions:**
- `addAdmin(address admin)` - Adds new administrator
- `removeAdmin(address admin)` - Removes administrator
- `pause()` / `unpause()` - Pauses/unpauses contract

### 4. Claim/Airdrop Mechanisms
- **Multiple Claim Rounds**: Support for sequential airdrop campaigns
- **Merkle Tree Verification**: Gas-efficient claim verification
- **Time-Based Claims**: Claims can have start and end times
- **Claim Tracking**: Prevents double-claiming per round

**Functions:**
- `createClaimRound(bytes32 merkleRoot, uint256 startTime, uint256 endTime)` - Creates new claim round
- `claim(uint256 roundId, uint256 amount, bytes32[] merkleProof)` - Claims tokens with proof
- `hasClaimedInRound(uint256 roundId, address account)` - Checks claim status
- `deactivateClaimRound(uint256 roundId)` - Deactivates claim round

### 5. Cross-Chain / Bridge Features
- **Multiple Bridge Support**: Multiple authorized bridge addresses
- **Bridge Role Management**: Bridges have special minting/burning permissions
- **Cross-chain Operations**: Dedicated functions for bridge operations

**Functions:**
- `addBridge(address bridge)` - Adds authorized bridge
- `removeBridge(address bridge)` - Removes bridge authorization
- `crosschainMint(address to, uint256 amount)` - Bridge minting function
- `crosschainBurn(address from, uint256 amount)` - Bridge burning function
- `getBridgeAddresses()` - Returns all authorized bridges

### 6. Advanced Features

#### Snapshotting
- **Balance Snapshots**: Record balances at specific blocks
- **Governance Support**: Snapshots for voting weight calculation
- **Analytics**: Historical balance tracking

**Functions:**
- `takeSnapshot()` - Takes a snapshot of current state
- `getSnapshotBalance(uint256 snapshotId, address account)` - Gets historical balance
- `getSnapshotTotalSupply(uint256 snapshotId)` - Gets historical total supply

#### Transfer Hooks
- **Extensible Design**: Empty hooks for future extensions
- **Before/After Hooks**: Support for pre and post-transfer logic
- **Mint/Burn Hooks**: Hooks for minting and burning operations

#### On-Chain Governance
- **Proposal System**: Create and execute governance proposals
- **Time Delays**: Proposals have execution delays for security
- **Proposal Management**: Cancel or execute proposals

**Functions:**
- `createProposal(string description, bytes callData)` - Creates governance proposal
- `executeProposal(uint256 proposalId)` - Executes approved proposal
- `cancelProposal(uint256 proposalId)` - Cancels proposal

### 7. Security & Compliance

#### Blacklist/Allowlist System
- **Blacklist**: Prevent specific addresses from transfers, minting, claiming
- **Allowlist**: Restrict operations to approved addresses only
- **Batch Operations**: Efficient batch updates for lists
- **Toggle Control**: Enable/disable allowlist mode

**Functions:**
- `updateBlacklist(address account, bool isBlacklisted)` - Updates blacklist
- `updateAllowlist(address account, bool isAllowlisted)` - Updates allowlist
- `toggleAllowlist(bool enabled)` - Enables/disables allowlist
- `batchUpdateBlacklist(address[] accounts, bool isBlacklisted)` - Batch blacklist update
- `batchUpdateAllowlist(address[] accounts, bool isAllowlisted)` - Batch allowlist update

#### Anti-Bot Mechanism
- **Transfer Delays**: Minimum time between transfers per address
- **Configurable Timing**: Owner can adjust delay periods
- **Role Exemptions**: Owner and admins exempt from delays

**Functions:**
- `setMinTransferDelay(uint256 delay)` - Sets minimum transfer delay

#### Emergency Functions
- **Token Rescue**: Recover accidentally sent tokens or ETH
- **Emergency Access**: Owner-only emergency functions
- **Asset Recovery**: Support for both ETH and ERC20 recovery

**Functions:**
- `emergencyRescue(address token, address to, uint256 amount)` - Rescues stuck assets

## Security Features

### Access Control
- Role-based permissions using OpenZeppelin's AccessControl
- Multi-signature owner support through Ownable
- Granular role assignments for different operations

### Reentrancy Protection
- ReentrancyGuard on critical functions
- State-changing operations protected against reentrancy attacks

### Pausable Operations
- Emergency pause functionality
- Prevents transfers, minting, and burning when paused
- Admin-controlled pause/unpause

### Input Validation
- Comprehensive parameter validation
- Zero address checks
- Range and boundary validation

## Gas Optimization

### Efficient Storage
- Packed structs where possible
- Optimized storage layout
- Minimal storage operations

### Batch Operations
- Batch blacklist/allowlist updates
- Reduced transaction costs for bulk operations

### Event Optimization
- Comprehensive event logging
- Indexed parameters for efficient filtering

## Upgrade Considerations

### Hook System
- Empty hooks for future functionality
- Override-friendly design
- Extension points for additional features

### Modular Design
- Separated concerns across functions
- Reusable modifiers
- Clean inheritance hierarchy

## Deployment Parameters

```solidity
constructor(
    string memory name_,           // Token name
    string memory symbol_,         // Token symbol
    uint8 decimals_,              // Token decimals
    uint256 initialSupply_,       // Initial token supply
    uint256 maxTotalSupply_,      // Maximum total supply (0 for unlimited)
    bool isFixedSupply_,          // Whether supply is fixed
    string memory tokenURI_,      // Token metadata URI
    address initialOwner_         // Initial owner address
)
```

## Events

The contract emits comprehensive events for all major operations:
- Token metadata updates
- Supply changes
- Claim operations
- Access control changes
- Bridge operations
- Governance actions
- Emergency operations

## Compatible Interfaces

- ERC20 standard
- AccessControl
- Ownable
- Pausable
- Supports interface detection via ERC165

## Testing

The contract includes a comprehensive test suite covering:
- Basic ERC20 functionality
- Access control mechanisms
- Supply management
- Claim/airdrop functionality
- Bridge operations
- Security features
- Emergency functions

## Future Extensions

The contract is designed to be extensible through:
- Hook system for custom logic
- Role-based access for new features
- Governance system for parameter changes
- Modular architecture for additional functionality