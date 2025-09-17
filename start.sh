#!/bin/bash
# Startup script for Mergington High School Activities Website

set -e

echo "🎓 Mergington High School Activities Website Startup"
echo "===================================================="

# Check if we're in the right directory
if [ ! -f "src/app.py" ]; then
    echo "❌ Error: Please run this script from the repository root directory"
    exit 1
fi

# Setup environment
echo "🔧 Setting up environment..."
if [ -f ".env" ]; then
    echo "✅ Loading environment from .env file"
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  No .env file found, using defaults"
fi

# Install dependencies
echo "📦 Installing dependencies..."
cd src
pip install -r requirements.txt

# Environment variables with defaults
HOST=${HOST:-"0.0.0.0"}
PORT=${PORT:-"8000"}
ENV=${ENV:-"development"}
RELOAD=${RELOAD:-"true"}

# Start the application
echo "🚀 Starting application..."
echo "   Environment: $ENV"
echo "   Host: $HOST"
echo "   Port: $PORT"
echo "   Reload: $RELOAD"
echo ""

if [ "$RELOAD" = "true" ]; then
    echo "🔄 Starting with auto-reload (development mode)"
    python -m uvicorn app:app --host $HOST --port $PORT --reload
else
    echo "⚡ Starting in production mode"
    python -m uvicorn app:app --host $HOST --port $PORT
fi