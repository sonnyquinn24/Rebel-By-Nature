### Copilot Instructions for Mergington High School Activities Website

You are working on the Mergington High School Activities website - a FastAPI application that helps students view and register for extracurricular activities. This is part of a GitHub Skills exercise teaching users how to use GitHub Copilot coding agent.

**Project Context:**
- FastAPI backend (Python) in `src/` directory  
- Static frontend (HTML/CSS/JS) in `src/static/`
- Database models in `src/backend/`
- Activities are stored with categories, schedules, and student limits

**Common Tasks:**
- Adding new extracurricular activities with full details
- Implementing UI improvements and filters
- Fixing bugs in registration or display logic
- Updating styling to match school branding
- Adding new features like difficulty levels or calendar views

**Code Style:**
- Follow existing patterns in the codebase
- Test changes work with the FastAPI app
- Keep UI consistent with current design
- Make minimal, focused changes that solve the specific issue

**When making changes:**
1. Always read and understand the full issue description
2. Check existing code patterns before implementing new features
3. Test that the app still runs properly: `cd src && python -m uvicorn app:app`
4. Make sure new activities appear correctly in the frontend
5. Keep database changes simple and backwards compatible
