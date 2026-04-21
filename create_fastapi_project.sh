#!/bin/bash

# Check if project name is provided
if [ -z "$1" ]; then
  echo "Usage: ./create_fastapi_project.sh <project_name>"
  exit 1
fi

PROJECT_NAME=$1

echo "🚀 Creating FastAPI project: $PROJECT_NAME"

# 1. Initialize UV project
uv init "$PROJECT_NAME" --no-workspace
cd "$PROJECT_NAME"

# 2. Create directory structure
echo "📁 Creating directory structure..."
mkdir -p app/api/v1/endpoints
mkdir -p app/core
mkdir -p app/db
mkdir -p app/models
mkdir -p app/schemas
mkdir -p app/services
mkdir -p tests

# 3. Create __init__.py files
find app -type d -exec touch {}/__init__.py \;
touch tests/__init__.py

# 4. Add essential dependencies
echo "📦 Adding dependencies..."
uv add fastapi "uvicorn[standard]" pydantic-settings sqlmodel email-validator pytest pytest-asyncio httpx

# 5. Create core boilerplate files
echo "📝 Generating boilerplate..."

# Config boilerplate
cat <<EOF >app/core/config.py
from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "$PROJECT_NAME"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your-secret-key-here")
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite+aiosqlite:///./db.sqlite3")

    class Config:
        case_sensitive = True

settings = Settings()
EOF

# Main entry point
cat <<EOF >app/main.py
from fastapi import FastAPI
from app.api.v1.api import api_router
from app.core.config import settings

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

app.include_router(api_router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {"message": "Welcome to \$settings.PROJECT_NAME API"}
EOF

# API router aggregator
cat <<EOF >app/api/v1/api.py
from fastapi import APIRouter
# from app.api.v1.endpoints import users, posts

api_router = APIRouter()
# api_router.include_router(users.router, prefix="/users", tags=["users"])
EOF

# 6. Create Project README
echo "📖 Creating project README..."
cat <<EOF >README.md
# $PROJECT_NAME

This project is a FastAPI application structured for scalability and maintainability.

## 📁 Project Structure

\`\`\`text
app/
├── api/             # API routes and versioning
│   ├── v1/          # Version 1 of the API
│   │   ├── endpoints/ # Resource-specific route handlers
│   │   └── api.py   # Main router aggregator for v1
├── core/            # Global configuration and security settings
├── db/              # Database session and connection management
├── models/          # SQLAlchemy/SQLModel database table definitions
├── schemas/         # Pydantic models for request/response validation
├── services/        # Business logic layer (CRUD and complex logic)
└── main.py          # FastAPI application entry point
tests/               # Automated test suite
\`\`\`

## 🚀 Getting Started

1. **Install uv** (if not already installed):
   \`curl -LsSf https://astral.sh/uv/install.sh | sh\`

2. **Sync dependencies**:
   \`uv sync\`

3. **Run the application**:
   \`uv run uvicorn app.main:app --reload\`

4. **Interactive Docs**: 
   Go to [http://localhost:8000/docs](http://localhost:8000/docs)
EOF

# Cleanup uv init noise
rm hello.py

echo "✅ Project '$PROJECT_NAME' created successfully!"
echo "👉 cd $PROJECT_NAME && uv run uvicorn app.main:app --reload"
