// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./RebelByNatureToken.sol";

/**
 * @title RebelByNatureICO
 * @dev ICO contract for Rebel By Nature token sale
 * Sale Period: September 8, 2025 to September 15, 2025
 * Token Price: 1 ETH = 7,435 tokens
 * Hard Cap: 35,000 tokens
 * Accepted Payments: USDT, USDC, ETH, BTC, BCH, TRX, POL
 */
contract RebelByNatureICO is 
    Initializable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    using SafeERC20 for IERC20;

    // Token configuration
    RebelByNatureToken public token;
    uint256 public constant TOKENS_PER_ETH = 7435; // 1 ETH = 7,435 tokens
    uint256 public constant HARD_CAP = 35_000 * 10**18; // 35,000 tokens with 18 decimals
    
    // Sale period - September 8, 2025 to September 15, 2025
    uint256 public constant SALE_START = 1757376000; // September 8, 2025 00:00:00 UTC
    uint256 public constant SALE_END = 1757980800; // September 15, 2025 00:00:00 UTC
    
    // Tracking
    uint256 public tokensSold;
    uint256 public totalRaised; // Total funds raised in USD equivalent
    
    // Supported payment tokens
    mapping(address => bool) public supportedTokens;
    mapping(address => uint256) public tokenDecimals;
    mapping(address => uint256) public tokenPriceInUSD; // Price in USD with 8 decimals (like price feeds)
    
    // Events
    event TokensPurchased(
        address indexed buyer,
        address indexed paymentToken,
        uint256 paymentAmount,
        uint256 tokensReceived
    );
    event PaymentTokenAdded(address indexed token, uint256 priceInUSD, uint256 decimals);
    event PaymentTokenRemoved(address indexed token);
    event FundsWithdrawn(address indexed to, uint256 amount);
    event ICOFinalized();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _token,
        address initialOwner
    ) public initializer {
        __ReentrancyGuard_init();
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();

        token = RebelByNatureToken(_token);
        _transferOwnership(initialOwner);
        
        // Initialize ETH as a supported payment method (address(0) represents ETH)
        supportedTokens[address(0)] = true;
        tokenDecimals[address(0)] = 18;
        tokenPriceInUSD[address(0)] = 250000000000; // $2,500 USD with 8 decimals
    }

    /**
     * @dev Add a supported payment token
     * @param _token Token contract address
     * @param _priceInUSD Token price in USD with 8 decimals (e.g., $1.00 = 100000000)
     * @param _decimals Token decimals
     */
    function addPaymentToken(
        address _token,
        uint256 _priceInUSD,
        uint256 _decimals
    ) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_priceInUSD > 0, "Price must be greater than 0");
        require(_decimals <= 18, "Decimals must be <= 18");
        
        supportedTokens[_token] = true;
        tokenPriceInUSD[_token] = _priceInUSD;
        tokenDecimals[_token] = _decimals;
        
        emit PaymentTokenAdded(_token, _priceInUSD, _decimals);
    }

    /**
     * @dev Remove a supported payment token
     * @param _token Token contract address
     */
    function removePaymentToken(address _token) external onlyOwner {
        require(_token != address(0), "Cannot remove ETH");
        require(supportedTokens[_token], "Token not supported");
        
        supportedTokens[_token] = false;
        delete tokenPriceInUSD[_token];
        delete tokenDecimals[_token];
        
        emit PaymentTokenRemoved(_token);
    }

    /**
     * @dev Update token price for payment methods
     * @param _token Token contract address (address(0) for ETH)
     * @param _priceInUSD New price in USD with 8 decimals
     */
    function updateTokenPrice(address _token, uint256 _priceInUSD) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        require(_priceInUSD > 0, "Price must be greater than 0");
        
        tokenPriceInUSD[_token] = _priceInUSD;
    }

    /**
     * @dev Purchase tokens with ETH
     */
    function buyTokensWithETH() external payable nonReentrant whenNotPaused {
        require(isICOActive(), "ICO is not active");
        require(msg.value > 0, "Payment amount must be greater than 0");
        
        uint256 tokensToReceive = calculateTokensFromPayment(address(0), msg.value);
        require(tokensToReceive > 0, "Invalid token amount");
        require(tokensSold + tokensToReceive <= HARD_CAP, "Hard cap exceeded");
        
        tokensSold += tokensToReceive;
        totalRaised += (msg.value * tokenPriceInUSD[address(0)]) / 10**18;
        
        token.transfer(msg.sender, tokensToReceive);
        
        emit TokensPurchased(msg.sender, address(0), msg.value, tokensToReceive);
    }

    /**
     * @dev Purchase tokens with supported ERC20 tokens
     * @param _paymentToken Address of the payment token
     * @param _paymentAmount Amount of payment tokens
     */
    function buyTokensWithToken(
        address _paymentToken,
        uint256 _paymentAmount
    ) external nonReentrant whenNotPaused {
        require(isICOActive(), "ICO is not active");
        require(supportedTokens[_paymentToken], "Payment token not supported");
        require(_paymentToken != address(0), "Use buyTokensWithETH for ETH payments");
        require(_paymentAmount > 0, "Payment amount must be greater than 0");
        
        uint256 tokensToReceive = calculateTokensFromPayment(_paymentToken, _paymentAmount);
        require(tokensToReceive > 0, "Invalid token amount");
        require(tokensSold + tokensToReceive <= HARD_CAP, "Hard cap exceeded");
        
        // Transfer payment tokens from buyer
        IERC20(_paymentToken).safeTransferFrom(msg.sender, address(this), _paymentAmount);
        
        tokensSold += tokensToReceive;
        totalRaised += (_paymentAmount * tokenPriceInUSD[_paymentToken]) / (10**tokenDecimals[_paymentToken]);
        
        token.transfer(msg.sender, tokensToReceive);
        
        emit TokensPurchased(msg.sender, _paymentToken, _paymentAmount, tokensToReceive);
    }

    /**
     * @dev Calculate tokens to receive from payment
     * @param _paymentToken Payment token address (address(0) for ETH)
     * @param _paymentAmount Payment amount
     * @return Number of tokens to receive
     */
    function calculateTokensFromPayment(
        address _paymentToken,
        uint256 _paymentAmount
    ) public view returns (uint256) {
        require(supportedTokens[_paymentToken], "Payment token not supported");
        
        // Convert payment amount to USD value
        uint256 usdValue = (_paymentAmount * tokenPriceInUSD[_paymentToken]) / (10**tokenDecimals[_paymentToken]);
        
        // Calculate tokens based on ETH price (1 ETH = 7,435 tokens)
        // If ETH is $2,500, then 1 token = $2,500 / 7,435 ≈ $0.336
        uint256 ethPriceUSD = tokenPriceInUSD[address(0)];
        uint256 tokenPriceUSD = ethPriceUSD / TOKENS_PER_ETH;
        
        return (usdValue * 10**18) / tokenPriceUSD;
    }

    /**
     * @dev Check if ICO is currently active
     */
    function isICOActive() public view returns (bool) {
        return block.timestamp >= SALE_START && 
               block.timestamp <= SALE_END && 
               tokensSold < HARD_CAP;
    }

    /**
     * @dev Get remaining tokens for sale
     */
    function getRemainingTokens() public view returns (uint256) {
        return HARD_CAP - tokensSold;
    }

    /**
     * @dev Withdraw raised funds (only owner)
     * @param _token Token address (address(0) for ETH)
     * @param _to Withdrawal address
     * @param _amount Amount to withdraw
     */
    function withdrawFunds(
        address _token,
        address payable _to,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "Invalid withdrawal address");
        require(_amount > 0, "Amount must be greater than 0");
        
        if (_token == address(0)) {
            require(address(this).balance >= _amount, "Insufficient ETH balance");
            _to.transfer(_amount);
        } else {
            IERC20 tokenContract = IERC20(_token);
            require(tokenContract.balanceOf(address(this)) >= _amount, "Insufficient token balance");
            tokenContract.safeTransfer(_to, _amount);
        }
        
        emit FundsWithdrawn(_to, _amount);
    }

    /**
     * @dev Finalize ICO and transfer remaining tokens back to owner
     */
    function finalizeICO() external onlyOwner {
        require(block.timestamp > SALE_END || tokensSold >= HARD_CAP, "ICO still active");
        
        uint256 remainingTokens = token.balanceOf(address(this));
        if (remainingTokens > 0) {
            token.transfer(owner(), remainingTokens);
        }
        
        emit ICOFinalized();
    }

    /**
     * @dev Emergency function to recover accidentally sent tokens
     * @param _token Token contract address
     * @param _amount Amount to recover
     */
    function recoverToken(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(token), "Cannot recover sale tokens during ICO");
        IERC20(_token).safeTransfer(owner(), _amount);
    }

    /**
     * @dev Pause the ICO
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the ICO
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Authorize upgrade (UUPS)
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev Receive function for ETH payments
     */
    receive() external payable {
        buyTokensWithETH();
    }
}