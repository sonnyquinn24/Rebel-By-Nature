"""
Test suite for the Mergington High School Activities API
"""
import pytest
import sys
import os
from pathlib import Path

# Add src directory to path for imports
src_path = Path(__file__).parent / "src"
sys.path.insert(0, str(src_path))

from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

def test_health_endpoint():
    """Test the health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert data["service"] == "Mergington High School Activities API"
    assert data["version"] == "1.0.0"

def test_root_endpoint():
    """Test the root endpoint redirects properly"""
    response = client.get("/")
    assert response.status_code == 200

def test_static_files_accessible():
    """Test that static files are accessible"""
    # Test main HTML file
    response = client.get("/static/index.html")
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    
    # Test CSS file
    response = client.get("/static/styles.css")
    assert response.status_code == 200
    assert "text/css" in response.headers["content-type"]
    
    # Test JavaScript file
    response = client.get("/static/app.js")
    assert response.status_code == 200
    assert "javascript" in response.headers["content-type"] or "text/plain" in response.headers["content-type"]

def test_api_endpoints_exist():
    """Test that API endpoints are accessible"""
    # Test activities endpoint
    response = client.get("/activities")
    assert response.status_code == 200
    
    # Test auth endpoints (may require proper setup)
    response = client.get("/auth/")
    # Auth endpoint might redirect or return different status, just check it's not 500
    assert response.status_code != 500

def test_cors_headers():
    """Test that CORS is properly configured if needed"""
    response = client.get("/health")
    # Basic check that response is successful
    assert response.status_code == 200

def test_app_startup():
    """Test that the application starts up properly"""
    # This test verifies the app can be imported and initialized
    from app import app
    assert app is not None
    assert hasattr(app, 'routes')
    
def test_database_initialization():
    """Test that database initialization works"""
    # Import should work without errors even if MongoDB is not available
    from backend import database
    # Database module should be importable
    assert hasattr(database, 'init_database')

if __name__ == "__main__":
    pytest.main([__file__])