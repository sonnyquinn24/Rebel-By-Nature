# Quick Setup Guide

## 🚀 Get Started in 30 Seconds

### One-Command Startup
```bash
./start.sh
```

That's it! The application will be running at http://localhost:8000

### Alternative Methods

#### 1. Docker (Recommended for Production)
```bash
# Development
./scripts/deploy-dev.sh

# Production  
./scripts/deploy-prod.sh
```

#### 2. Manual Setup
```bash
cd src
pip install -r requirements.txt
python -m uvicorn app:app --reload
```

### Environment Configuration

Copy `.env.example` to `.env` and customize:
```bash
cp .env.example .env
# Edit .env with your settings
```

### Health Check
Visit http://localhost:8000/health to verify the application is running.

### Documentation
- [Complete Deployment Guide](docs/deployment.md)
- [Application Documentation](README.md)

## Features

✅ **Fully Automated Deployment**
- GitHub Actions CI/CD pipeline
- Docker containerization  
- Health monitoring
- Auto-testing

✅ **Multiple Deployment Options**
- One-command startup script
- Docker Compose (dev & prod)
- Manual Python setup
- GitHub Actions automation

✅ **Production Ready**
- Health checks
- Error handling
- Resource management
- Security best practices