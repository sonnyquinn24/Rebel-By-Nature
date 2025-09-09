// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RainbowSuperTokenV2
 * @dev Enhanced ERC20 token with comprehensive features including:
 * - Dynamic token metadata (name, symbol, tokenURI)
 * - Advanced supply management with configurable limits
 * - Multi-admin access control with pausable functionality
 * - Merkle tree-based claim/airdrop mechanisms with multiple rounds
 * - Cross-chain bridge support with multiple authorized bridges
 * - Advanced security features (blacklist, allowlist, anti-bot)
 * - Snapshotting for governance and analytics
 * - Emergency rescue functionality
 * - On-chain governance for critical operations
 */
contract RainbowSuperTokenV2 is ERC20, Ownable, AccessControl, Pausable, ReentrancyGuard {
    
    // ========== CONSTANTS ==========
    
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    uint256 public constant MAX_TRANSFER_DELAY = 1 hours;
    uint256 public constant GOVERNANCE_DELAY = 48 hours;
    
    // ========== STATE VARIABLES ==========
    
    // Token metadata
    string private _tokenName;
    string private _tokenSymbol;
    string private _tokenURI;
    uint8 private _tokenDecimals;
    
    // Supply management
    uint256 public maxTotalSupply;
    bool public isFixedSupply;
    bool public isUnlimitedSupply;
    
    // Claim/Airdrop system
    struct ClaimRound {
        bytes32 merkleRoot;
        bool isActive;
        uint256 startTime;
        uint256 endTime;
        mapping(address => bool) hasClaimed;
    }
    
    uint256 public currentClaimRound;
    mapping(uint256 => ClaimRound) public claimRounds;
    
    // Access control lists
    mapping(address => bool) public blacklist;
    mapping(address => bool) public allowlist;
    bool public allowlistEnabled;
    
    // Anti-bot mechanism
    mapping(address => uint256) public lastTransferTime;
    uint256 public minTransferDelay;
    
    // Bridge management
    address[] public bridgeAddresses;
    mapping(address => bool) public authorizedBridges;
    
    // Snapshots
    struct Snapshot {
        uint256 blockNumber;
        uint256 timestamp;
        mapping(address => uint256) balances;
        uint256 totalSupply;
    }
    
    uint256 public snapshotCounter;
    mapping(uint256 => Snapshot) public snapshots;
    
    // Governance
    struct Proposal {
        address proposer;
        string description;
        bytes callData;
        uint256 proposalTime;
        uint256 executionTime;
        bool executed;
        bool cancelled;
    }
    
    uint256 public proposalCounter;
    mapping(uint256 => Proposal) public proposals;
    
    // ========== EVENTS ==========
    
    event TokenMetadataUpdated(string name, string symbol, string tokenURI);
    event MaxSupplyUpdated(uint256 oldMax, uint256 newMax);
    event SupplyTypeUpdated(bool isFixed, bool isUnlimited);
    event ClaimRoundCreated(uint256 indexed roundId, bytes32 merkleRoot, uint256 startTime, uint256 endTime);
    event TokensClaimed(address indexed user, uint256 indexed roundId, uint256 amount);
    event BlacklistUpdated(address indexed account, bool isBlacklisted);
    event AllowlistUpdated(address indexed account, bool isAllowlisted);
    event AllowlistToggled(bool enabled);
    event BridgeAdded(address indexed bridge);
    event BridgeRemoved(address indexed bridge);
    event SnapshotTaken(uint256 indexed snapshotId, uint256 blockNumber, uint256 totalSupply);
    event ProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event ProposalExecuted(uint256 indexed proposalId, bool success);
    event EmergencyRescue(address indexed token, address indexed to, uint256 amount);
    event TransferDelayUpdated(uint256 oldDelay, uint256 newDelay);
    
    // ========== MODIFIERS ==========
    
    modifier onlyAdminOrOwner() {
        require(
            owner() == msg.sender || hasRole(ADMIN_ROLE, msg.sender),
            "RainbowSuperTokenV2: caller is not owner or admin"
        );
        _;
    }
    
    modifier onlyBridge() {
        require(
            hasRole(BRIDGE_ROLE, msg.sender) || authorizedBridges[msg.sender],
            "RainbowSuperTokenV2: caller is not authorized bridge"
        );
        _;
    }
    
    modifier notBlacklisted(address account) {
        require(!blacklist[account], "RainbowSuperTokenV2: account is blacklisted");
        _;
    }
    
    modifier onlyAllowlisted(address account) {
        if (allowlistEnabled) {
            require(allowlist[account], "RainbowSuperTokenV2: account not in allowlist");
        }
        _;
    }
    
    modifier respectTransferDelay(address account) {
        if (minTransferDelay > 0 && account != owner() && !hasRole(ADMIN_ROLE, account)) {
            require(
                block.timestamp >= lastTransferTime[account] + minTransferDelay,
                "RainbowSuperTokenV2: transfer too frequent"
            );
        }
        _;
    }
    
    // ========== CONSTRUCTOR ==========
    
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        uint256 maxTotalSupply_,
        bool isFixedSupply_,
        string memory tokenURI_,
        address initialOwner_
    ) ERC20(name_, symbol_) Ownable(initialOwner_) {
        _tokenName = name_;
        _tokenSymbol = symbol_;
        _tokenDecimals = decimals_;
        _tokenURI = tokenURI_;
        
        maxTotalSupply = maxTotalSupply_;
        isFixedSupply = isFixedSupply_;
        isUnlimitedSupply = maxTotalSupply_ == 0;
        
        // Setup roles
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner_);
        _grantRole(ADMIN_ROLE, initialOwner_);
        
        // Mint initial supply
        if (initialSupply_ > 0) {
            _mint(initialOwner_, initialSupply_);
        }
    }
    
    // ========== TOKEN METADATA FUNCTIONS ==========
    
    function name() public view override returns (string memory) {
        return _tokenName;
    }
    
    function symbol() public view override returns (string memory) {
        return _tokenSymbol;
    }
    
    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }
    
    function tokenURI() public view returns (string memory) {
        return _tokenURI;
    }
    
    function updateTokenMetadata(
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) external onlyAdminOrOwner {
        _tokenName = name_;
        _tokenSymbol = symbol_;
        _tokenURI = tokenURI_;
        emit TokenMetadataUpdated(name_, symbol_, tokenURI_);
    }
    
    // ========== SUPPLY MANAGEMENT ==========
    
    function updateMaxSupply(uint256 newMaxSupply) external onlyAdminOrOwner {
        require(!isFixedSupply, "RainbowSuperTokenV2: supply is fixed");
        require(
            newMaxSupply >= totalSupply(),
            "RainbowSuperTokenV2: new max supply below current supply"
        );
        
        uint256 oldMax = maxTotalSupply;
        maxTotalSupply = newMaxSupply;
        isUnlimitedSupply = newMaxSupply == 0;
        
        emit MaxSupplyUpdated(oldMax, newMaxSupply);
    }
    
    function setSupplyType(bool isFixed, bool isUnlimited) external onlyAdminOrOwner {
        require(!(isFixed && isUnlimited), "RainbowSuperTokenV2: cannot be both fixed and unlimited");
        
        isFixedSupply = isFixed;
        isUnlimitedSupply = isUnlimited;
        
        if (isUnlimited) {
            maxTotalSupply = 0;
        }
        
        emit SupplyTypeUpdated(isFixed, isUnlimited);
    }
    
    function mint(address to, uint256 amount) 
        external 
        onlyAdminOrOwner 
        notBlacklisted(to) 
        onlyAllowlisted(to) 
    {
        require(to != address(0), "RainbowSuperTokenV2: mint to zero address");
        
        if (!isUnlimitedSupply) {
            require(
                totalSupply() + amount <= maxTotalSupply,
                "RainbowSuperTokenV2: exceeds max supply"
            );
        }
        
        _mint(to, amount);
    }
    
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    
    function burnFrom(address account, uint256 amount) external {
        uint256 currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "RainbowSuperTokenV2: burn amount exceeds allowance");
        
        _approve(account, msg.sender, currentAllowance - amount);
        _burn(account, amount);
    }
    
    // ========== CLAIM/AIRDROP FUNCTIONS ==========
    
    function createClaimRound(
        bytes32 merkleRoot,
        uint256 startTime,
        uint256 endTime
    ) external onlyAdminOrOwner {
        require(merkleRoot != bytes32(0), "RainbowSuperTokenV2: invalid merkle root");
        require(startTime < endTime, "RainbowSuperTokenV2: invalid time range");
        require(startTime >= block.timestamp, "RainbowSuperTokenV2: start time in past");
        
        currentClaimRound++;
        ClaimRound storage round = claimRounds[currentClaimRound];
        round.merkleRoot = merkleRoot;
        round.isActive = true;
        round.startTime = startTime;
        round.endTime = endTime;
        
        emit ClaimRoundCreated(currentClaimRound, merkleRoot, startTime, endTime);
    }
    
    function claim(
        uint256 roundId,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external nonReentrant notBlacklisted(msg.sender) onlyAllowlisted(msg.sender) {
        ClaimRound storage round = claimRounds[roundId];
        require(round.isActive, "RainbowSuperTokenV2: round not active");
        require(
            block.timestamp >= round.startTime && block.timestamp <= round.endTime,
            "RainbowSuperTokenV2: round not in valid time range"
        );
        require(!round.hasClaimed[msg.sender], "RainbowSuperTokenV2: already claimed");
        
        // Verify merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        require(
            MerkleProof.verify(merkleProof, round.merkleRoot, leaf),
            "RainbowSuperTokenV2: invalid proof"
        );
        
        round.hasClaimed[msg.sender] = true;
        _mint(msg.sender, amount);
        
        emit TokensClaimed(msg.sender, roundId, amount);
    }
    
    function hasClaimedInRound(uint256 roundId, address account) external view returns (bool) {
        return claimRounds[roundId].hasClaimed[account];
    }
    
    function deactivateClaimRound(uint256 roundId) external onlyAdminOrOwner {
        claimRounds[roundId].isActive = false;
    }
    
    // ========== ACCESS CONTROL FUNCTIONS ==========
    
    function addAdmin(address admin) external onlyOwner {
        grantRole(ADMIN_ROLE, admin);
    }
    
    function removeAdmin(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
    }
    
    function pause() external onlyAdminOrOwner {
        _pause();
    }
    
    function unpause() external onlyAdminOrOwner {
        _unpause();
    }
    
    // ========== BLACKLIST/ALLOWLIST FUNCTIONS ==========
    
    function updateBlacklist(address account, bool isBlacklisted) external onlyAdminOrOwner {
        blacklist[account] = isBlacklisted;
        emit BlacklistUpdated(account, isBlacklisted);
    }
    
    function updateAllowlist(address account, bool isAllowlisted) external onlyAdminOrOwner {
        allowlist[account] = isAllowlisted;
        emit AllowlistUpdated(account, isAllowlisted);
    }
    
    function toggleAllowlist(bool enabled) external onlyAdminOrOwner {
        allowlistEnabled = enabled;
        emit AllowlistToggled(enabled);
    }
    
    function batchUpdateBlacklist(address[] calldata accounts, bool isBlacklisted) external onlyAdminOrOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            blacklist[accounts[i]] = isBlacklisted;
            emit BlacklistUpdated(accounts[i], isBlacklisted);
        }
    }
    
    function batchUpdateAllowlist(address[] calldata accounts, bool isAllowlisted) external onlyAdminOrOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            allowlist[accounts[i]] = isAllowlisted;
            emit AllowlistUpdated(accounts[i], isAllowlisted);
        }
    }
    
    // ========== ANTI-BOT FUNCTIONS ==========
    
    function setMinTransferDelay(uint256 delay) external onlyAdminOrOwner {
        require(delay <= MAX_TRANSFER_DELAY, "RainbowSuperTokenV2: delay too high");
        
        uint256 oldDelay = minTransferDelay;
        minTransferDelay = delay;
        
        emit TransferDelayUpdated(oldDelay, delay);
    }
    
    // ========== BRIDGE FUNCTIONS ==========
    
    function addBridge(address bridge) external onlyAdminOrOwner {
        require(bridge != address(0), "RainbowSuperTokenV2: invalid bridge address");
        require(!authorizedBridges[bridge], "RainbowSuperTokenV2: bridge already added");
        
        authorizedBridges[bridge] = true;
        bridgeAddresses.push(bridge);
        grantRole(BRIDGE_ROLE, bridge);
        
        emit BridgeAdded(bridge);
    }
    
    function removeBridge(address bridge) external onlyAdminOrOwner {
        require(authorizedBridges[bridge], "RainbowSuperTokenV2: bridge not found");
        
        authorizedBridges[bridge] = false;
        revokeRole(BRIDGE_ROLE, bridge);
        
        // Remove from array
        for (uint256 i = 0; i < bridgeAddresses.length; i++) {
            if (bridgeAddresses[i] == bridge) {
                bridgeAddresses[i] = bridgeAddresses[bridgeAddresses.length - 1];
                bridgeAddresses.pop();
                break;
            }
        }
        
        emit BridgeRemoved(bridge);
    }
    
    function crosschainMint(address to, uint256 amount) external onlyBridge notBlacklisted(to) {
        if (!isUnlimitedSupply) {
            require(
                totalSupply() + amount <= maxTotalSupply,
                "RainbowSuperTokenV2: exceeds max supply"
            );
        }
        _mint(to, amount);
    }
    
    function crosschainBurn(address from, uint256 amount) external onlyBridge {
        _burn(from, amount);
    }
    
    function getBridgeAddresses() external view returns (address[] memory) {
        return bridgeAddresses;
    }
    
    // ========== SNAPSHOT FUNCTIONS ==========
    
    function takeSnapshot() external onlyAdminOrOwner returns (uint256) {
        snapshotCounter++;
        Snapshot storage snapshot = snapshots[snapshotCounter];
        snapshot.blockNumber = block.number;
        snapshot.timestamp = block.timestamp;
        snapshot.totalSupply = totalSupply();
        
        emit SnapshotTaken(snapshotCounter, block.number, totalSupply());
        return snapshotCounter;
    }
    
    function getSnapshotBalance(uint256 snapshotId, address account) external view returns (uint256) {
        return snapshots[snapshotId].balances[account];
    }
    
    function getSnapshotTotalSupply(uint256 snapshotId) external view returns (uint256) {
        return snapshots[snapshotId].totalSupply;
    }
    
    // ========== GOVERNANCE FUNCTIONS ==========
    
    function createProposal(
        string memory description,
        bytes memory callData
    ) external onlyAdminOrOwner returns (uint256) {
        proposalCounter++;
        Proposal storage proposal = proposals[proposalCounter];
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.callData = callData;
        proposal.proposalTime = block.timestamp;
        proposal.executionTime = block.timestamp + GOVERNANCE_DELAY;
        
        emit ProposalCreated(proposalCounter, msg.sender, description);
        return proposalCounter;
    }
    
    function executeProposal(uint256 proposalId) external onlyAdminOrOwner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "RainbowSuperTokenV2: already executed");
        require(!proposal.cancelled, "RainbowSuperTokenV2: proposal cancelled");
        require(
            block.timestamp >= proposal.executionTime,
            "RainbowSuperTokenV2: execution time not reached"
        );
        
        proposal.executed = true;
        
        // Execute the proposal
        (bool success, ) = address(this).call(proposal.callData);
        
        emit ProposalExecuted(proposalId, success);
    }
    
    function cancelProposal(uint256 proposalId) external onlyAdminOrOwner {
        Proposal storage proposal = proposals[proposalId];
        require(!proposal.executed, "RainbowSuperTokenV2: already executed");
        proposal.cancelled = true;
    }
    
    // ========== EMERGENCY FUNCTIONS ==========
    
    function emergencyRescue(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(to != address(0), "RainbowSuperTokenV2: invalid recipient");
        
        if (token == address(0)) {
            // Rescue ETH
            payable(to).transfer(amount);
        } else {
            // Rescue ERC20 tokens
            IERC20(token).transfer(to, amount);
        }
        
        emit EmergencyRescue(token, to, amount);
    }
    
    // ========== OVERRIDE FUNCTIONS ==========
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override whenNotPaused {
        // Skip checks for minting/burning
        if (from != address(0) && to != address(0)) {
            require(!blacklist[from], "RainbowSuperTokenV2: sender blacklisted");
            require(!blacklist[to], "RainbowSuperTokenV2: recipient blacklisted");
            
            if (allowlistEnabled) {
                require(allowlist[from], "RainbowSuperTokenV2: sender not allowlisted");
                require(allowlist[to], "RainbowSuperTokenV2: recipient not allowlisted");
            }
            
            // Anti-bot check for sender
            if (minTransferDelay > 0 && from != owner() && !hasRole(ADMIN_ROLE, from)) {
                require(
                    block.timestamp >= lastTransferTime[from] + minTransferDelay,
                    "RainbowSuperTokenV2: transfer too frequent"
                );
            }
        }
        
        super._beforeTokenTransfer(from, to, amount);
    }
    
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // Update last transfer time for anti-bot
        if (from != address(0) && to != address(0)) {
            lastTransferTime[from] = block.timestamp;
        }
        
        // Update snapshots if any exist
        if (snapshotCounter > 0) {
            if (from != address(0)) {
                snapshots[snapshotCounter].balances[from] = balanceOf(from);
            }
            if (to != address(0)) {
                snapshots[snapshotCounter].balances[to] = balanceOf(to);
            }
        }
        
        super._afterTokenTransfer(from, to, amount);
    }
    
    // ========== HOOKS (EMPTY BY DEFAULT, OVERRIDEABLE) ==========
    
    function _beforeTransferHook(address from, address to, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    function _afterTransferHook(address from, address to, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    function _beforeMintHook(address to, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    function _afterMintHook(address to, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    function _beforeBurnHook(address from, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    function _afterBurnHook(address from, uint256 amount) internal virtual {
        // Empty hook - can be overridden in future extensions
    }
    
    // ========== VIEW FUNCTIONS ==========
    
    function getClaimRoundInfo(uint256 roundId) external view returns (
        bytes32 merkleRoot,
        bool isActive,
        uint256 startTime,
        uint256 endTime
    ) {
        ClaimRound storage round = claimRounds[roundId];
        return (
            round.merkleRoot,
            round.isActive,
            round.startTime,
            round.endTime
        );
    }
    
    function getProposalInfo(uint256 proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 proposalTime,
        uint256 executionTime,
        bool executed,
        bool cancelled
    ) {
        Proposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.proposalTime,
            proposal.executionTime,
            proposal.executed,
            proposal.cancelled
        );
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    // ========== RECEIVE FUNCTION ==========
    
    receive() external payable {
        // Allow contract to receive ETH for emergency rescue functionality
    }
}