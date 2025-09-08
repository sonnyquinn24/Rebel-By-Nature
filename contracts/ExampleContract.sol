// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title ExampleContract
 * @dev Advanced smart contract with comprehensive features including:
 * - Ownership management
 * - Pausable functionality
 * - Staking mechanism with rewards
 * - ERC-20 token compatibility
 * - Upgradeable contract pattern
 * - Governance system
 * - Enhanced security features
 */
contract ExampleContract is 
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 rewards);
    event RewardsClaimed(address indexed user, uint256 rewards);
    event GovernanceProposalCreated(uint256 indexed proposalId, address proposer, string description);
    event GovernanceVoteCast(uint256 indexed proposalId, address voter, bool support, uint256 weight);
    event GovernanceProposalExecuted(uint256 indexed proposalId, bool success);
    event RewardRateUpdated(uint256 oldRate, uint256 newRate);
    event EmergencyWithdraw(address indexed user, uint256 amount);

    // Structs
    struct StakeInfo {
        uint256 amount;
        uint256 stakeTime;
        uint256 lastRewardTime;
        uint256 rewardDebt;
    }

    struct GovernanceProposal {
        uint256 id;
        address proposer;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteChoice; // true for support, false for against
    }

    // State variables
    IERC20Upgradeable public stakingToken;
    IERC20Upgradeable public rewardToken;
    
    uint256 public totalStaked;
    uint256 public rewardRate; // Rewards per second per token staked
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public minimumStakeAmount;
    uint256 public stakingLockPeriod; // Lock period in seconds
    
    // Governance variables
    uint256 public proposalCount;
    uint256 public votingPeriod; // Duration of voting in seconds
    uint256 public proposalThreshold; // Minimum tokens needed to create proposal
    uint256 public quorum; // Minimum participation rate for proposal to be valid
    
    mapping(address => StakeInfo) public stakes;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(uint256 => GovernanceProposal) public proposals;
    
    // Access control
    mapping(address => bool) public governors;
    mapping(address => bool) public emergencyOperators;
    
    // Security features
    bool public emergencyMode;
    uint256 public maxStakeAmount;
    mapping(address => bool) public blacklisted;

    // Modifiers
    modifier notBlacklisted() {
        require(!blacklisted[msg.sender], "Address is blacklisted");
        _;
    }

    modifier onlyGovernor() {
        require(governors[msg.sender] || msg.sender == owner(), "Not authorized governor");
        _;
    }

    modifier onlyEmergencyOperator() {
        require(emergencyOperators[msg.sender] || msg.sender == owner(), "Not authorized emergency operator");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "Amount must be greater than 0");
        require(amount >= minimumStakeAmount, "Amount below minimum stake");
        require(amount <= maxStakeAmount, "Amount exceeds maximum stake");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initialize the contract with required parameters
     * @param _stakingToken Address of the token to be staked
     * @param _rewardToken Address of the reward token
     * @param _rewardRate Initial reward rate per second
     * @param _minimumStakeAmount Minimum amount required to stake
     * @param _stakingLockPeriod Lock period for staked tokens
     */
    function initialize(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardRate,
        uint256 _minimumStakeAmount,
        uint256 _stakingLockPeriod
    ) public initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        __UUPSUpgradeable_init();

        require(_stakingToken != address(0), "Invalid staking token");
        require(_rewardToken != address(0), "Invalid reward token");
        require(_rewardRate > 0, "Reward rate must be positive");

        stakingToken = IERC20Upgradeable(_stakingToken);
        rewardToken = IERC20Upgradeable(_rewardToken);
        rewardRate = _rewardRate;
        minimumStakeAmount = _minimumStakeAmount;
        stakingLockPeriod = _stakingLockPeriod;
        maxStakeAmount = 1000000 * 10**18; // 1M tokens default
        
        // Governance settings
        votingPeriod = 7 days;
        proposalThreshold = 10000 * 10**18; // 10K tokens to create proposal
        quorum = 4000; // 40% participation rate (in basis points)
        
        lastUpdateTime = block.timestamp;
        
        // Set initial governor
        governors[msg.sender] = true;
        emergencyOperators[msg.sender] = true;
    }

    /**
     * @dev Stake tokens to earn rewards
     * @param amount Amount of tokens to stake
     */
    function stake(uint256 amount) 
        external 
        nonReentrant 
        whenNotPaused 
        notBlacklisted 
        validAmount(amount)
        updateReward(msg.sender) 
    {
        require(!emergencyMode, "Emergency mode active");
        
        StakeInfo storage userStake = stakes[msg.sender];
        
        // Transfer tokens from user
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // Update stake info
        userStake.amount += amount;
        userStake.stakeTime = block.timestamp;
        userStake.lastRewardTime = block.timestamp;
        
        totalStaked += amount;
        
        emit Staked(msg.sender, amount, block.timestamp);
    }

    /**
     * @dev Unstake tokens and claim rewards
     * @param amount Amount of tokens to unstake
     */
    function unstake(uint256 amount) 
        external 
        nonReentrant 
        updateReward(msg.sender) 
    {
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount >= amount, "Insufficient staked amount");
        require(
            block.timestamp >= userStake.stakeTime + stakingLockPeriod,
            "Tokens still locked"
        );
        
        uint256 rewardAmount = rewards[msg.sender];
        
        // Update stake info
        userStake.amount -= amount;
        totalStaked -= amount;
        rewards[msg.sender] = 0;
        
        // Transfer tokens back to user
        stakingToken.safeTransfer(msg.sender, amount);
        
        // Transfer rewards if any
        if (rewardAmount > 0) {
            rewardToken.safeTransfer(msg.sender, rewardAmount);
        }
        
        emit Unstaked(msg.sender, amount, rewardAmount);
    }

    /**
     * @dev Claim accumulated rewards without unstaking
     */
    function claimRewards() 
        external 
        nonReentrant 
        updateReward(msg.sender) 
    {
        uint256 rewardAmount = rewards[msg.sender];
        require(rewardAmount > 0, "No rewards available");
        
        rewards[msg.sender] = 0;
        rewardToken.safeTransfer(msg.sender, rewardAmount);
        
        emit RewardsClaimed(msg.sender, rewardAmount);
    }

    /**
     * @dev Emergency unstake without rewards (only in emergency mode)
     */
    function emergencyUnstake() 
        external 
        nonReentrant 
    {
        require(emergencyMode, "Not in emergency mode");
        
        StakeInfo storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No tokens staked");
        
        uint256 amount = userStake.amount;
        userStake.amount = 0;
        totalStaked -= amount;
        
        stakingToken.safeTransfer(msg.sender, amount);
        
        emit EmergencyWithdraw(msg.sender, amount);
    }

    /**
     * @dev Create a governance proposal
     * @param description Description of the proposal
     */
    function createProposal(string memory description) 
        external 
        whenNotPaused 
        notBlacklisted 
        returns (uint256) 
    {
        require(bytes(description).length > 0, "Empty description");
        require(
            stakingToken.balanceOf(msg.sender) >= proposalThreshold,
            "Insufficient tokens to create proposal"
        );
        
        uint256 proposalId = ++proposalCount;
        GovernanceProposal storage proposal = proposals[proposalId];
        
        proposal.id = proposalId;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + votingPeriod;
        
        emit GovernanceProposalCreated(proposalId, msg.sender, description);
        
        return proposalId;
    }

    /**
     * @dev Vote on a governance proposal
     * @param proposalId ID of the proposal
     * @param support True for support, false for against
     */
    function vote(uint256 proposalId, bool support) 
        external 
        whenNotPaused 
        notBlacklisted 
    {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votingWeight = stakes[msg.sender].amount;
        require(votingWeight > 0, "No voting weight");
        
        proposal.hasVoted[msg.sender] = true;
        proposal.voteChoice[msg.sender] = support;
        
        if (support) {
            proposal.forVotes += votingWeight;
        } else {
            proposal.againstVotes += votingWeight;
        }
        
        emit GovernanceVoteCast(proposalId, msg.sender, support, votingWeight);
    }

    /**
     * @dev Execute a passed governance proposal
     * @param proposalId ID of the proposal to execute
     */
    function executeProposal(uint256 proposalId) 
        external 
        onlyGovernor 
    {
        GovernanceProposal storage proposal = proposals[proposalId];
        require(proposal.id == proposalId, "Proposal does not exist");
        require(block.timestamp > proposal.endTime, "Voting still active");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 requiredQuorum = (totalStaked * quorum) / 10000;
        
        require(totalVotes >= requiredQuorum, "Quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");
        
        proposal.executed = true;
        
        // Here you would implement the actual execution logic
        // For this example, we just mark it as executed
        
        emit GovernanceProposalExecuted(proposalId, true);
    }

    // View functions
    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + 
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalStaked);
    }

    function earned(address account) public view returns (uint256) {
        return (stakes[account].amount * 
            (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 + 
            rewards[account];
    }

    function getStakeInfo(address account) 
        external 
        view 
        returns (uint256 amount, uint256 stakeTime, uint256 earnedRewards) 
    {
        StakeInfo memory userStake = stakes[account];
        return (userStake.amount, userStake.stakeTime, earned(account));
    }

    function getProposalInfo(uint256 proposalId) 
        external 
        view 
        returns (
            address proposer,
            string memory description,
            uint256 forVotes,
            uint256 againstVotes,
            uint256 startTime,
            uint256 endTime,
            bool executed,
            bool canceled
        ) 
    {
        GovernanceProposal storage proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.description,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.startTime,
            proposal.endTime,
            proposal.executed,
            proposal.canceled
        );
    }

    // Owner functions
    function setRewardRate(uint256 _rewardRate) 
        external 
        onlyOwner 
        updateReward(address(0)) 
    {
        uint256 oldRate = rewardRate;
        rewardRate = _rewardRate;
        emit RewardRateUpdated(oldRate, _rewardRate);
    }

    function setMinimumStakeAmount(uint256 _minimumStakeAmount) 
        external 
        onlyOwner 
    {
        minimumStakeAmount = _minimumStakeAmount;
    }

    function setMaxStakeAmount(uint256 _maxStakeAmount) 
        external 
        onlyOwner 
    {
        maxStakeAmount = _maxStakeAmount;
    }

    function setStakingLockPeriod(uint256 _stakingLockPeriod) 
        external 
        onlyOwner 
    {
        stakingLockPeriod = _stakingLockPeriod;
    }

    function setGovernanceParameters(
        uint256 _votingPeriod,
        uint256 _proposalThreshold,
        uint256 _quorum
    ) external onlyOwner {
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
        quorum = _quorum;
    }

    function addGovernor(address governor) external onlyOwner {
        governors[governor] = true;
    }

    function removeGovernor(address governor) external onlyOwner {
        governors[governor] = false;
    }

    function addEmergencyOperator(address operator) external onlyOwner {
        emergencyOperators[operator] = true;
    }

    function removeEmergencyOperator(address operator) external onlyOwner {
        emergencyOperators[operator] = false;
    }

    function setBlacklisted(address account, bool _blacklisted) external onlyOwner {
        blacklisted[account] = _blacklisted;
    }

    function setEmergencyMode(bool _emergencyMode) external onlyEmergencyOperator {
        emergencyMode = _emergencyMode;
        if (_emergencyMode) {
            _pause();
        } else {
            _unpause();
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Withdraw any ERC20 token from the contract (emergency function)
     */
    function emergencyTokenWithdraw(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        IERC20Upgradeable(token).safeTransfer(to, amount);
    }

    /**
     * @dev Required by UUPS upgradeable pattern
     */
    function _authorizeUpgrade(address newImplementation) 
        internal 
        override 
        onlyOwner 
    {}

    /**
     * @dev Get the current version of the contract
     */
    function version() external pure returns (string memory) {
        return "1.0.0";
    }
}