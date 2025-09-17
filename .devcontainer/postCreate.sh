#!/bin/bash
# Post-creation setup script for development environment

echo "🚀 Setting up Rebel By Nature development environment..."

# Update package manager
sudo apt-get update

# Prepare Python environment
echo "🐍 Setting up Python environment..."
pip install --upgrade pip
pip install -r src/requirements.txt
pip install black flake8 isort pytest

# Install Node.js dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Update npm packages to latest versions
echo "⬆️ Updating npm packages..."
npm update

# Prepare MongoDB Dev DB
echo "🍃 Setting up MongoDB..."
chmod +x ./.devcontainer/installMongoDB.sh
./.devcontainer/installMongoDB.sh

# Set up Git hooks (optional)
echo "🔧 Setting up development tools..."
git config --global init.defaultBranch main

# Create local environment file template
echo "📄 Creating environment template..."
cat > .env.example << EOF
# FastAPI Configuration
FASTAPI_ENV=development
SECRET_KEY=your-secret-key-here
DATABASE_URL=mongodb://localhost:27017/rebel_by_nature

# Development Settings
DEBUG=true
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8000
EOF

# Make scripts executable
chmod +x verify_features.sh verify_website.sh

echo "✅ Development environment setup complete!"
echo "📋 Next steps:"
echo "   1. Copy .env.example to .env and update values"
echo "   2. Run: cd src && python -m uvicorn app:app --reload"
echo "   3. Run: npx hardhat node (for blockchain development)"
echo "   4. Visit: http://localhost:8000 for the API"