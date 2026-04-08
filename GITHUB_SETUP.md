# OpenVAL GitHub Repository Setup Guide

## Step 1: Create the GitHub Repository

1. Go to https://github.com/new
2. Repository name: `openval`
3. Description: `Open Source Enterprise Computer System Validation Platform for Pharmaceutical and Process Engineering`
4. Set to **Public**
5. Initialize with a README: **No** (we already have one)
6. Add .gitignore: **No** (we will create it)
7. Choose license: **AGPL-3.0**
8. Click **Create repository**

---

## Step 2: Clone and Initialize Locally

```bash
# Clone the empty repo
git clone https://github.com/YOUR_USERNAME/openval.git
cd openval

# Copy all project files from wherever you have them
# Then initialize the project structure
```

---

## Step 3: Create .gitignore

Create `.gitignore` in the root:

```
# Python
__pycache__/
*.py[cod]
*.pyo
*.pyd
.Python
.venv/
venv/
env/
*.egg-info/
dist/
build/
.eggs/
*.egg
.pytest_cache/
.mypy_cache/
.coverage
htmlcov/
.tox/

# Node / Frontend
node_modules/
dist/
.next/
.nuxt/
*.local

# Environment files (NEVER commit these)
.env
.env.local
.env.production
*.env

# IDE
.vscode/
.idea/
*.swp
*.swo
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Database
*.sqlite3
*.db

# Media / uploads (site-specific, never in repo)
media/
uploads/

# Build artifacts
backend/app/__pycache__/
frontend/dist/
frontend/build/

# Alembic auto-generated (keep migrations, not cache)
backend/migrations/__pycache__/

# Certificates and keys (NEVER commit)
*.pem
*.key
*.crt
*.p12
*.pfx
secrets/
```

---

## Step 4: Create pyproject.toml for Backend

```toml
[tool.poetry]
name = "openval"
version = "0.1.0"
description = "Open Source Computer System Validation Platform"
authors = ["OpenVAL Contributors"]
license = "AGPL-3.0"

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.111.0"
uvicorn = {extras = ["standard"], version = "^0.30.0"}
gunicorn = "^22.0.0"
sqlalchemy = {extras = ["asyncio"], version = "^2.0.0"}
alembic = "^1.13.0"
asyncpg = "^0.29.0"
psycopg2-binary = "^2.9.9"
pydantic = {extras = ["email"], version = "^2.7.0"}
pydantic-settings = "^2.3.0"
python-jose = {extras = ["cryptography"], version = "^3.3.0"}
passlib = {extras = ["bcrypt"], version = "^1.7.4"}
pyotp = "^2.9.0"
qrcode = {extras = ["pil"], version = "^7.4.2"}
python-multipart = "^0.0.9"
aiofiles = "^23.2.1"
celery = {extras = ["redis"], version = "^5.4.0"}
redis = "^5.0.6"
aiosmtplib = "^3.0.1"
jinja2 = "^3.1.4"
cryptography = "^42.0.8"
httpx = "^0.27.0"
python-ldap = "^3.4.4"
reportlab = "^4.2.0"
openpyxl = "^3.1.4"
pillow = "^10.3.0"
slowapi = "^0.1.9"

[tool.poetry.group.dev.dependencies]
pytest = "^8.2.0"
pytest-asyncio = "^0.23.7"
pytest-cov = "^5.0.0"
httpx = "^0.27.0"
factory-boy = "^3.3.0"
black = "^24.4.2"
ruff = "^0.4.4"
mypy = "^1.10.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 100
target-version = ['py311']

[tool.ruff]
line-length = 100
select = ["E", "F", "I", "N", "UP"]

[tool.mypy]
python_version = "3.11"
warn_return_any = true
warn_unused_configs = true
```

---

## Step 5: Create package.json for Frontend

```json
{
  "name": "openval-frontend",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "type-check": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.23.1",
    "axios": "^1.7.2",
    "zustand": "^4.5.2",
    "react-hook-form": "^7.51.5",
    "zod": "^3.23.8",
    "@hookform/resolvers": "^3.6.0",
    "@tiptap/react": "^2.4.0",
    "@tiptap/starter-kit": "^2.4.0",
    "@tiptap/extension-table": "^2.4.0",
    "@tiptap/extension-image": "^2.4.0",
    "@tiptap/extension-link": "^2.4.0",
    "@tanstack/react-table": "^8.17.3",
    "@tanstack/react-query": "^5.40.0",
    "recharts": "^2.12.7",
    "lucide-react": "^0.383.0",
    "date-fns": "^3.6.0",
    "clsx": "^2.1.1",
    "tailwind-merge": "^2.3.0",
    "react-beautiful-dnd": "^13.1.1",
    "react-dropzone": "^14.2.3",
    "otpauth": "^9.3.3"
  },
  "devDependencies": {
    "@types/react": "^18.3.3",
    "@types/react-dom": "^18.3.0",
    "@vitejs/plugin-react": "^4.3.0",
    "typescript": "^5.4.5",
    "vite": "^5.2.13",
    "tailwindcss": "^3.4.4",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "eslint": "^8.57.0",
    "@typescript-eslint/eslint-plugin": "^7.13.0",
    "@typescript-eslint/parser": "^7.13.0"
  }
}
```

---

## Step 6: Initial Commit

```bash
cd openval

git add .
git commit -m "chore: initial project structure

- Complete MASTER_PLAN.md with all 20 phases, full feature specs,
  database schema documentation, compliance mapping, and architecture
- Complete PostgreSQL DDL schema (Part 1 + Part 2)
  covering 100+ tables across all modules
- README with regulatory coverage, tech stack, and deployment guide
- pyproject.toml and package.json with full dependency declarations
- .gitignore
- Schema covers: users/auth, audit trail (21 CFR Part 11),
  electronic signatures, system inventory, risk assessment,
  requirements, protocols, test execution, deviations, documents,
  workflows, change control, CAPA, nonconformances, periodic review,
  traceability, vendor management, audit management, training,
  reports/dashboards, and system configuration
- All seed data: signature meanings, GAMP categories, roles,
  risk matrices, regulatory references, notification templates,
  feature flags, ALCOA+ attributes, applicable regulations"

git push origin main
```

---

## Step 7: Set Up Branch Protection

In GitHub Settings > Branches > Add rule for `main`:
- Require pull request reviews before merging: 1 reviewer
- Require status checks to pass before merging
- Require branches to be up to date before merging
- Include administrators: Yes

---

## Step 8: Create GitHub Issue Labels

Create these labels in your repository (Settings > Labels):

| Label | Color | Description |
|---|---|---|
| `phase-0` | `#0052CC` | Foundation work |
| `phase-1` through `phase-20` | graduated blues | Phase-specific work |
| `compliance` | `#FF8B00` | Regulatory compliance requirement |
| `validation-impact: major` | `#DE350B` | Requires site revalidation |
| `validation-impact: minor` | `#FF8B00` | Minor validation impact |
| `validation-impact: none` | `#00875A` | No validation impact |
| `21cfr11` | `#5243AA` | 21 CFR Part 11 related |
| `audit-trail` | `#5243AA` | Audit trail related |
| `ui/ux` | `#00B8D9` | Frontend design work |
| `database` | `#172B4D` | Schema or data model |
| `security` | `#DE350B` | Security-related |
| `bug` | `#DE350B` | Something is broken |
| `enhancement` | `#00875A` | New feature or improvement |
| `documentation` | `#344563` | Documentation |

---

## Step 9: Create First Issues (Phase 0)

Create the following issues to begin Phase 0:

1. **[Phase 0] Initialize FastAPI backend project structure**
2. **[Phase 0] Configure SQLAlchemy 2.0 async + Alembic migrations**
3. **[Phase 0] Build JWT authentication with refresh token rotation**
4. **[Phase 0] Implement TOTP MFA with backup codes**
5. **[Phase 0] Build audit trail engine as SQLAlchemy event listener**
6. **[Phase 0] Build electronic signature engine**
7. **[Phase 0] Implement RBAC permission middleware**
8. **[Phase 0] Configure Celery + Redis**
9. **[Phase 0] Write bare metal install.sh script**
10. **[Phase 0] Initialize React 18 + TypeScript + Vite frontend**
11. **[Phase 0] Build AppShell component (header + sidebar + content)**
12. **[Phase 0] Build base UI component library**
13. **[Phase 0] Write SDL documentation**

---

## Repository Structure After Setup

```
openval/                        <- GitHub repo root
  README.md                     <- Project overview
  MASTER_PLAN.md                <- Living development document
  CHANGELOG.md                  <- Version history with validation impact
  CONTRIBUTING.md               <- Contribution guidelines
  LICENSE                       <- AGPL-3.0
  .gitignore
  pyproject.toml                <- Backend Python dependencies
  package.json                  <- Frontend Node dependencies
  schema/
    openval_schema_part1.sql    <- All DDL table definitions
    openval_schema_part2.sql    <- Indexes, sequences, RLS, seed data
  backend/
    app/
      main.py                   <- FastAPI app entry point
      api/v1/endpoints/         <- Route handlers per module
      core/                     <- Config, security, audit engine
      models/                   <- SQLAlchemy ORM models
      schemas/                  <- Pydantic schemas
      services/                 <- Business logic
      workflows/                <- Workflow engine runtime
      utils/                    <- PDF, email, file handling
    migrations/                 <- Alembic
    tests/
  frontend/
    src/
      components/layout/        <- AppShell, Header, Sidebar
      components/ui/            <- Reusable UI primitives
      pages/                    <- Page components per module
      hooks/                    <- Custom React hooks
      store/                    <- Zustand state
      utils/                    <- API client, formatters
  docs/
    validation_package/         <- Bundled IQ/OQ/PQ for OpenVAL
    compliance/                 <- CFR mapping, ALCOA matrix
    architecture/               <- Architecture decision records
  templates/
    protocols/                  <- Pharma protocol templates
    documents/                  <- Document templates
  scripts/
    install.sh                  <- Bare metal installer
    backup.sh                   <- Backup script
    upgrade.sh                  <- Upgrade script
  config/
    nginx.conf                  <- Nginx template
    openval-api.service         <- systemd unit
    openval-worker.service      <- Celery worker systemd unit
    openval-beat.service        <- Celery beat systemd unit
    .env.example                <- Environment variable template
```
