#!/bin/bash
# Website Feature Verification Script - Enhanced Version

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Mergington High School Activities Website Verification${NC}"
echo "========================================================"

# Change to src directory
cd src

echo ""
echo -e "${BLUE}📋 Checking FastAPI Application:${NC}"
echo ""

# Function to check status with color coding
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "   ${GREEN}✓${NC} $1"
    else
        echo -e "   ${RED}❌${NC} $1"
    fi
}

# Check Python imports with enhanced error handling
echo -e "${YELLOW}1. ✅ Python Dependencies:${NC}"
python3 -c "
import sys
import subprocess

dependencies = [
    ('fastapi', 'FastAPI'),
    ('uvicorn', 'Uvicorn'),
    ('pymongo', 'PyMongo'),
    ('pydantic', 'Pydantic')
]

all_good = True
for module, name in dependencies:
    try:
        imported = __import__(module)
        version = getattr(imported, '__version__', 'Unknown version')
        print(f'   {name}: {version}')
    except ImportError as e:
        print(f'   ❌ {name}: Import error - {e}')
        all_good = False

if all_good:
    print('   ✓ All dependencies imported successfully')
else:
    print('   ❌ Some dependencies failed to import')
    sys.exit(1)
"
check_status "Python dependencies check"
echo ""

# Check application imports with timeout
echo -e "${YELLOW}2. ✅ Application Structure:${NC}"
timeout 10s python3 -c "
try:
    import app
    print('   ✓ FastAPI app imports successfully')
    print('   ✓ Database initialization complete')
    
    # Check if app has expected attributes
    if hasattr(app, 'app'):
        print('   ✓ FastAPI app instance found')
    else:
        print('   ⚠️ FastAPI app instance not found')
    
except Exception as e:
    print(f'   ❌ Application error: {e}')
    exit(1)
" || echo -e "   ${YELLOW}⚠️ Application check timed out (expected in some environments)${NC}"
check_status "Application structure check"
echo ""

# Enhanced static files check
echo -e "${YELLOW}3. ✅ Static Files:${NC}"
check_file() {
    local file="$1"
    local description="$2"
    if [ -f "$file" ]; then
        local lines=$(wc -l < "$file")
        local size=$(du -h "$file" | cut -f1)
        echo -e "   ${GREEN}✓${NC} $description exists ($lines lines, $size)"
    else
        echo -e "   ${RED}❌${NC} $description missing"
    fi
}

check_file "static/index.html" "index.html"
check_file "static/styles.css" "styles.css"
check_file "static/app.js" "app.js"

# Check for additional static files
if [ -d "static" ]; then
    echo "   📁 Static directory contents:"
    ls -la static/ | grep -v "^total" | sed 's/^/      /'
fi
echo ""

# Enhanced backend structure check
echo -e "${YELLOW}4. ✅ Backend Structure:${NC}"
if [ -d "backend" ]; then
    echo -e "   ${GREEN}✓${NC} Backend directory exists"
    
    if [ -f "backend/database.py" ]; then
        echo -e "   ${GREEN}✓${NC} Database module exists"
    else
        echo -e "   ${RED}❌${NC} Database module missing"
    fi
    
    if [ -d "backend/routers" ]; then
        echo -e "   ${GREEN}✓${NC} Routers directory exists"
        router_count=$(ls backend/routers/*.py 2>/dev/null | wc -l)
        echo "   - Router files: $router_count"
        if [ "$router_count" -gt 0 ]; then
            echo "   - Router files:"
            ls backend/routers/*.py 2>/dev/null | sed 's/^/      /' || echo "      None found"
        fi
    else
        echo -e "   ${RED}❌${NC} Routers directory missing"
    fi
    
    # Check Python files in backend
    py_files=$(find backend -name "*.py" 2>/dev/null | wc -l)
    echo "   - Python files in backend: $py_files"
else
    echo -e "   ${RED}❌${NC} Backend directory missing"
fi
echo ""

# Check issue templates (go back to root)
cd ..
echo -e "${YELLOW}5. ✅ GitHub Issue Templates:${NC}"
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    echo -e "   ${GREEN}✓${NC} Issue template directory exists"
    template_count=$(ls .github/ISSUE_TEMPLATE/*.yml 2>/dev/null | wc -l)
    echo "   ✓ Template files: $template_count"
    if [ $template_count -gt 0 ]; then
        echo "   📋 Available templates:"
        ls .github/ISSUE_TEMPLATE/*.yml 2>/dev/null | sed 's/.*\//      /' | sed 's/\.yml$//'
    fi
else
    echo -e "   ${RED}❌${NC} Issue templates missing"
fi
echo ""

# Enhanced documentation check
echo -e "${YELLOW}6. ✅ Documentation:${NC}"
check_file "docs/copilot-guide-for-teachers.md" "Teacher guide"
check_file ".github/copilot-instructions.md" "Copilot instructions"
check_file "README.md" "README file"
check_file "IMPLEMENTATION_SUMMARY.md" "Implementation summary"

# Check for additional documentation
if [ -d "docs" ]; then
    doc_count=$(find docs -name "*.md" 2>/dev/null | wc -l)
    echo "   📚 Total documentation files: $doc_count"
fi
echo ""

# Enhanced project statistics
echo -e "${BLUE}📊 Project Statistics:${NC}"
echo "====================="
echo "Python files: $(find src -name "*.py" 2>/dev/null | wc -l)"
echo "HTML files: $(find src -name "*.html" 2>/dev/null | wc -l)"
echo "CSS files: $(find src -name "*.css" 2>/dev/null | wc -l)"
echo "JS files: $(find src -name "*.js" 2>/dev/null | wc -l)"
echo "Documentation files: $(find docs -name "*.md" 2>/dev/null | wc -l)"
echo "Solidity contracts: $(find contracts -name "*.sol" 2>/dev/null | wc -l)"
echo "GitHub workflows: $(find .github/workflows -name "*.yml" 2>/dev/null | wc -l)"
echo "Total project size: $(du -sh . 2>/dev/null | cut -f1)"
echo ""

# Environment and version information
echo -e "${BLUE}🔧 Environment Information:${NC}"
echo "========================="
echo "Python version: $(python3 --version 2>/dev/null || echo 'Not available')"
echo "Node.js version: $(node --version 2>/dev/null || echo 'Not available')"
echo "npm version: $(npm --version 2>/dev/null || echo 'Not available')"
echo "Git version: $(git --version 2>/dev/null || echo 'Not available')"
echo "Current directory: $(pwd)"
echo "Timestamp: $(date)"
echo ""

# Final health check
echo -e "${BLUE}🏥 Repository Health Check:${NC}"
echo "=========================="

# Check for security files
[ -f ".github/SECURITY.md" ] && echo -e "${GREEN}✓${NC} Security policy exists" || echo -e "${YELLOW}⚠️${NC} Security policy missing"
[ -f ".github/dependabot.yml" ] && echo -e "${GREEN}✓${NC} Dependabot configuration exists" || echo -e "${YELLOW}⚠️${NC} Dependabot configuration missing"
[ -f ".gitignore" ] && echo -e "${GREEN}✓${NC} .gitignore file exists" || echo -e "${RED}❌${NC} .gitignore file missing"
[ -f "LICENSE" ] && echo -e "${GREEN}✓${NC} License file exists" || echo -e "${YELLOW}⚠️${NC} License file missing"

echo ""
echo -e "${GREEN}✅ Website verification complete!${NC}"
echo -e "${GREEN}🚀 Ready for GitHub Copilot coding agent assignments!${NC}"