#!/bin/bash
# Development deployment script

set -e

echo "🚀 Starting development deployment..."

# Build and start services
echo "📦 Building and starting services..."
docker-compose down --remove-orphans
docker-compose build
docker-compose up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
timeout 180 bash -c '
  until docker-compose ps | grep -q "healthy"; do
    echo "Waiting for health checks..."
    sleep 10
  done
'

# Verify deployment
echo "🔍 Verifying deployment..."
curl -f http://localhost:8000/health
echo "✅ Health check passed"

# Show running services
echo "📋 Running services:"
docker-compose ps

echo "✅ Development deployment completed successfully!"
echo "🌐 Application is running at: http://localhost:8000"
echo "📝 View logs with: docker-compose logs -f"