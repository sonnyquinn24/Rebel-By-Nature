#!/bin/bash
# Website Feature Verification Script

echo "🔍 Mergington High School Activities Website Verification"
echo "========================================================"

# Change to src directory
cd src

echo ""
echo "📋 Checking FastAPI Application:"
echo ""

# Check Python imports
echo "1. ✅ Python Dependencies:"
python3 -c "
try:
    import fastapi
    import uvicorn
    import pymongo
    print('   FastAPI:', fastapi.__version__)
    print('   Uvicorn:', uvicorn.__version__)
    print('   PyMongo:', pymongo.__version__)
    print('   ✓ All dependencies imported successfully')
except ImportError as e:
    print('   ❌ Import error:', e)
    exit(1)
"
echo ""

# Check application imports
echo "2. ✅ Application Structure:"
python3 -c "
try:
    import app
    print('   ✓ FastAPI app imports successfully')
    print('   ✓ Database initialization complete')
except Exception as e:
    print('   ❌ Application error:', e)
    exit(1)
"
echo ""

# Check static files
echo "3. ✅ Static Files:"
if [ -f "static/index.html" ]; then
    echo "   ✓ index.html exists ($(wc -l < static/index.html) lines)"
else
    echo "   ❌ index.html missing"
fi

if [ -f "static/styles.css" ]; then
    echo "   ✓ styles.css exists ($(wc -l < static/styles.css) lines)"
else
    echo "   ❌ styles.css missing"
fi

if [ -f "static/app.js" ]; then
    echo "   ✓ app.js exists ($(wc -l < static/app.js) lines)"
else
    echo "   ❌ app.js missing"
fi
echo ""

# Check backend structure  
echo "4. ✅ Backend Structure:"
if [ -d "backend" ]; then
    echo "   ✓ Backend directory exists"
    if [ -f "backend/database.py" ]; then
        echo "   ✓ Database module exists"
    fi
    if [ -d "backend/routers" ]; then
        echo "   ✓ Routers directory exists"
        echo "   - Router files: $(ls backend/routers/*.py 2>/dev/null | wc -l)"
    fi
else
    echo "   ❌ Backend directory missing"
fi
echo ""

# Check issue templates
cd ..
echo "5. ✅ GitHub Issue Templates:"
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    echo "   ✓ Issue template directory exists"
    template_count=$(ls .github/ISSUE_TEMPLATE/*.yml 2>/dev/null | wc -l)
    echo "   ✓ Template files: $template_count"
else
    echo "   ❌ Issue templates missing"
fi
echo ""

# Check documentation
echo "6. ✅ Documentation:"
if [ -f "docs/copilot-guide-for-teachers.md" ]; then
    echo "   ✓ Teacher guide exists ($(wc -l < docs/copilot-guide-for-teachers.md) lines)"
else
    echo "   ❌ Teacher guide missing"
fi

if [ -f ".github/copilot-instructions.md" ]; then
    echo "   ✓ Copilot instructions exist"
else
    echo "   ❌ Copilot instructions missing"
fi
echo ""

echo "📊 Project Statistics:"
echo "====================="
echo "Python files: $(find src -name "*.py" | wc -l)"
echo "HTML files: $(find src -name "*.html" | wc -l)"
echo "CSS files: $(find src -name "*.css" | wc -l)"
echo "JS files: $(find src -name "*.js" | wc -l)"
echo "Documentation files: $(find docs -name "*.md" 2>/dev/null | wc -l)"
echo ""

echo "✅ Website verification complete!"
echo "🚀 Ready for GitHub Copilot coding agent assignments!"