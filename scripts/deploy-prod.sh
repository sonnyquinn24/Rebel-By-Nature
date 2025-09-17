#!/bin/bash
# Production deployment script

set -e

echo "🚀 Starting production deployment..."

# Build and start services
echo "📦 Building and starting services..."
docker-compose -f docker-compose.yml -f docker-compose.prod.yml down --remove-orphans
docker-compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Wait for services to be healthy
echo "⏳ Waiting for services to be healthy..."
timeout 300 bash -c '
  until docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps | grep -q "healthy"; do
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
docker-compose -f docker-compose.yml -f docker-compose.prod.yml ps

echo "✅ Production deployment completed successfully!"
echo "🌐 Application is running at: http://localhost:8000"