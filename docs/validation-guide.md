# Quick Validation Script

This script helps validate that the website works correctly after changes.

## Usage

```bash
# From the repository root
./verify_features.sh
```

## What it checks

- FastAPI application imports successfully
- Database initialization works
- Static files are present
- Basic endpoint functionality

## For Teachers

If you see any errors after Copilot makes changes, you can run this script to help identify issues. Include the output in your feedback to Copilot.

## For Copilot

Run this script after making changes to ensure the application still works:

```bash
cd /path/to/repo && ./verify_features.sh
```

The script should complete without errors for successful changes.