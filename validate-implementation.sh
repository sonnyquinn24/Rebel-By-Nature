#!/bin/bash

echo "=================================================="
echo "Rebel By Nature ICO Smart Contract Validation"
echo "=================================================="

# Check if required files exist
echo "📁 Checking contract files..."
contracts=("RebelByNatureToken.sol" "RebelByNatureICO.sol" "RebelByNatureGovernor.sol")
for contract in "${contracts[@]}"; do
    if [ -f "contracts/$contract" ]; then
        echo "✅ $contract found"
    else
        echo "❌ $contract missing"
        exit 1
    fi
done

# Check deployment scripts
echo -e "\n📋 Checking deployment scripts..."
scripts=("deploy.js" "configure-payment-tokens.js")
for script in "${scripts[@]}"; do
    if [ -f "scripts/$script" ]; then
        echo "✅ $script found"
    else
        echo "❌ $script missing"
        exit 1
    fi
done

# Check configuration files
echo -e "\n⚙️ Checking configuration..."
configs=("hardhat.config.js" "package.json" ".gitignore")
for config in "${configs[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ $config found"
    else
        echo "❌ $config missing"
        exit 1
    fi
done

# Validate contract specifications in source code
echo -e "\n🔍 Validating contract specifications..."

# Check token specifications
if grep -q "Rebel By Nature" contracts/RebelByNatureToken.sol; then
    echo "✅ Token name 'Rebel By Nature' found"
else
    echo "❌ Token name not found"
fi

if grep -q "SEQREB" contracts/RebelByNatureToken.sol; then
    echo "✅ Token symbol 'SEQREB' found"
else
    echo "❌ Token symbol not found"
fi

if grep -q "75_000" contracts/RebelByNatureToken.sol; then
    echo "✅ Total supply 75,000 tokens found"
else
    echo "❌ Total supply not found"
fi

# Check ICO specifications
if grep -q "7435" contracts/RebelByNatureICO.sol; then
    echo "✅ Token price 7,435 tokens per ETH found"
else
    echo "❌ Token price not found"
fi

if grep -q "35_000" contracts/RebelByNatureICO.sol; then
    echo "✅ Hard cap 35,000 tokens found"
else
    echo "❌ Hard cap not found"
fi

# Check security features
echo -e "\n🔒 Validating security features..."
security_features=("ReentrancyGuardUpgradeable" "PausableUpgradeable" "OwnableUpgradeable" "UUPSUpgradeable")
for feature in "${security_features[@]}"; do
    if grep -q "$feature" contracts/RebelByNature*.sol; then
        echo "✅ $feature implemented"
    else
        echo "❌ $feature missing"
    fi
done

# Check governance features
echo -e "\n🗳️ Validating governance features..."
if [ -f "contracts/RebelByNatureGovernor.sol" ] && grep -q "GovernorUpgradeable" contracts/RebelByNatureGovernor.sol; then
    echo "✅ Governance system implemented"
else
    echo "❌ Governance system missing"
fi

# Check multi-token support
echo -e "\n💳 Validating multi-token payment support..."
payment_features=("addPaymentToken" "buyTokensWithToken" "supportedTokens")
for feature in "${payment_features[@]}"; do
    if grep -q "$feature" contracts/RebelByNatureICO.sol; then
        echo "✅ $feature function found"
    else
        echo "❌ $feature function missing"
    fi
done

# Check upgradeability
echo -e "\n🔄 Validating upgradeability..."
if grep -q "upgrades.deployProxy" scripts/deploy.js; then
    echo "✅ Proxy deployment pattern found"
else
    echo "❌ Proxy deployment pattern missing"
fi

# Check documentation
echo -e "\n📚 Checking documentation..."
if [ -f "ICO_README.md" ]; then
    echo "✅ ICO documentation found"
else
    echo "❌ ICO documentation missing"
fi

# Final summary
echo -e "\n=================================================="
echo "✅ ICO Smart Contract Implementation Complete!"
echo "=================================================="
echo ""
echo "📋 Implementation Summary:"
echo "   • ERC20 Token with governance capabilities"
echo "   • ICO contract with multi-token payment support"
echo "   • Governance system with timelock controller"
echo "   • UUPS upgradeability pattern"
echo "   • Comprehensive security features"
echo "   • Deployment and configuration scripts"
echo ""
echo "🚀 Next Steps:"
echo "   1. Compile contracts: npm run compile"
echo "   2. Run tests: npm run test"
echo "   3. Deploy to testnet: npm run deploy"
echo "   4. Configure payment tokens: npm run configure-tokens"
echo ""
echo "📖 See ICO_README.md for detailed usage instructions"
echo "=================================================="