# Deployment Guide

## Automated Deployment System

This repository includes a fully automated deployment system for the Mergington High School Activities website.

## Quick Start

### Prerequisites
- Docker and Docker Compose
- Git

### Development Deployment
```bash
# Clone the repository
git clone https://github.com/sonnyquinn24/Rebel-By-Nature.git
cd Rebel-By-Nature

# Start development environment
./scripts/deploy-dev.sh
```

### Production Deployment
```bash
# Deploy to production
./scripts/deploy-prod.sh
```

## Deployment Methods

### 1. Automated CI/CD (Recommended)

The repository includes GitHub Actions workflows that automatically:

- **On Pull Requests**: Run tests and validate Docker builds
- **On Main Branch**: Deploy to production automatically

#### Workflows:
- `.github/workflows/ci.yml` - Continuous Integration for PRs
- `.github/workflows/deploy.yml` - Production deployment on main branch

### 2. Manual Docker Deployment

#### Development Environment
```bash
docker-compose up -d
```

#### Production Environment
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 3. Local Python Development
```bash
cd src
pip install -r requirements.txt
python -m uvicorn app:app --reload --host 0.0.0.0 --port 8000
```

## Environment Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MONGODB_URL` | MongoDB connection string | `mongodb://localhost:27017/mergington_high` |
| `ENV` | Environment name | `development` |

### Docker Services

The deployment includes two main services:

#### 1. Web Application (`app`)
- **Port**: 8000
- **Health Check**: `/health` endpoint
- **Auto-restart**: On failure
- **Resource Limits**: 512MB RAM, 0.5 CPU (production)

#### 2. MongoDB Database (`mongo`)
- **Port**: 27017
- **Persistent Storage**: Docker volume
- **Health Check**: MongoDB ping
- **Auto-restart**: On failure

## Health Monitoring

### Health Check Endpoints

- **Application Health**: `GET /health`
  ```json
  {
    "status": "healthy",
    "service": "Mergington High School Activities API",
    "version": "1.0.0"
  }
  ```

### Docker Health Checks

Both services include health checks:
- **Interval**: 30 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start Period**: 40 seconds

## Deployment Verification

After deployment, verify the system is working:

```bash
# Check health endpoint
curl http://localhost:8000/health

# Check main application
curl http://localhost:8000/

# View running containers
docker-compose ps

# View logs
docker-compose logs -f app
```

## Rollback Procedures

### Automatic Rollback
If health checks fail during deployment, the system will automatically attempt to restart services.

### Manual Rollback
```bash
# Stop current deployment
docker-compose down

# Deploy previous version
git checkout <previous-commit>
./scripts/deploy-prod.sh
```

## Troubleshooting

### Common Issues

1. **Port Already in Use**
   ```bash
   # Stop existing services
   docker-compose down
   # Or use different ports in docker-compose.yml
   ```

2. **Database Connection Issues**
   ```bash
   # Check MongoDB status
   docker-compose logs mongo
   
   # Restart database
   docker-compose restart mongo
   ```

3. **Application Startup Failures**
   ```bash
   # Check application logs
   docker-compose logs app
   
   # Rebuild and restart
   docker-compose up --build -d
   ```

### Log Monitoring

```bash
# View all service logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f mongo

# View last 100 lines
docker-compose logs --tail=100 app
```

## Security Considerations

- Application runs as non-root user in container
- Resource limits prevent resource exhaustion
- Health checks enable quick failure detection
- Automated restarts improve availability
- Docker isolation provides security boundaries

## Performance Optimization

### Production Configuration
- Multi-replica deployment (2 instances)
- Resource limits and reservations
- Connection pooling for database
- Static file serving optimizations

### Monitoring
- Health check endpoints for monitoring systems
- Docker health checks for container orchestration
- Application logs for debugging

## Maintenance

### Regular Tasks
1. **Update Dependencies**: Run `pip-audit` for security updates
2. **Monitor Logs**: Check for errors and performance issues
3. **Database Backup**: Regular MongoDB backups
4. **Image Updates**: Keep base images updated

### Scaling
To scale the application:
```bash
# Scale to 3 replicas
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d --scale app=3
```

## Support

For deployment issues:
1. Check the troubleshooting section above
2. Review application logs: `docker-compose logs app`
3. Verify health checks: `curl http://localhost:8000/health`
4. Check GitHub Actions for CI/CD issues