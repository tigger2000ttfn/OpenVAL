# Contributing to OpenVAL

Thank you for your interest in contributing to OpenVAL. This guide explains how
to contribute effectively while maintaining the quality and compliance standards
that regulated pharmaceutical environments demand.

---

## Before You Contribute

### Understand the Regulatory Context

OpenVAL is software used in GMP-regulated environments. Code changes can affect
validated systems at pharmaceutical and medical device companies. This means:

- **Every change has a validation impact classification.** You must assess whether
  your change affects GxP-critical functions (audit trail, electronic signatures,
  access controls, data integrity) and classify it accordingly.
- **Backward compatibility matters.** Breaking changes to the API or database
  schema require deprecation periods and migration paths, because sites have
  validated these interfaces.
- **The audit trail is sacred.** Never modify code that reduces the scope or
  integrity of the audit trail. Never add shortcuts around electronic signature
  re-authentication.
- **Your name is on it.** Every contributor's changes are traceable through Git
  history, which is referenced in the OpenVAL SDL. Regulated sites may audit
  this history during inspections.

### Sign the Contributor License Agreement (CLA)

Before your first pull request is merged, you must sign the OpenVAL CLA. This is
handled automatically via the CLA bot on your first PR.

---

## Development Setup

### Prerequisites

- Python 3.11+
- Node.js 20 LTS
- PostgreSQL 15+ (local)
- Redis 7+ (local)
- Git 2.40+
- Poetry (Python dependency management): `pip install poetry`

### Local Setup

```bash
# 1. Fork and clone
git clone https://github.com/YOUR_USERNAME/openval.git
cd openval

# 2. Set up backend
cd backend
poetry install
cp ../.env.example ../.env
# Edit .env with your local DB credentials

# 3. Initialize local database
createdb openval_dev
psql openval_dev -f ../schema/openval_schema_part1.sql
psql openval_dev -f ../schema/openval_schema_part2.sql
poetry run alembic upgrade head
poetry run python ../scripts/seed_database.py

# 4. Set up frontend
cd ../frontend
npm install

# 5. Start development servers
# Terminal 1 (backend):
cd backend && poetry run uvicorn app.main:app --reload --port 8000

# Terminal 2 (Celery worker):
cd backend && poetry run celery -A app.core.celery_app worker --loglevel=debug

# Terminal 3 (frontend):
cd frontend && npm run dev
```

---

## Contribution Workflow

### 1. Find or Create an Issue

All work starts with a GitHub Issue. Before coding:
- Check if an issue exists for what you want to work on
- If not, create one describing the problem or feature
- For significant features or design decisions, wait for maintainer feedback before coding

### 2. Branch from `develop`

```bash
git checkout develop
git pull origin develop
git checkout -b feature/ISSUE-NUMBER-short-description
# Example: feature/142-add-risk-item-bulk-import
```

### 3. Write Code

Follow the coding standards documented below. Run linting and tests locally before committing.

### 4. Commit with Conventional Commits

```bash
git commit -m "feat(risk): add bulk import for risk items from CSV

Allows validation engineers to import multiple risk items from a
CSV template rather than entering them one at a time.

Supports: hazard, effect, probability, impact, detectability, controls
Validation required: simple pass/fail, shows preview before import

Closes #142
Validation-Impact: none
"
```

### 5. Open a Pull Request

Target the `develop` branch. Use the PR template. Fill in all sections.

### 6. Address Review Feedback

Maintainers review within 5 business days. Address all comments. Do not resolve
comment threads on others' behalf.

### 7. Merge

Maintainers merge approved PRs. Contributors do not self-merge.

---

## Coding Standards

### Backend (Python)

**Style:** Black formatting (100 char line length) + Ruff linting. Run before committing:
```bash
cd backend
poetry run black .
poetry run ruff check . --fix
poetry run mypy app/
```

**Structure:**
- Route handlers in `api/v1/endpoints/` are thin. No business logic.
- Business logic lives in `services/`. One service per domain.
- Database models in `models/`. Mirror the schema exactly.
- Pydantic schemas in `schemas/`. Separate request and response schemas.
- No raw SQL. Use SQLAlchemy ORM or Core expressions.
- No `SELECT *`. Always specify columns.

**Async:**
- All database operations must be async (use `async with db.begin()` pattern)
- All Celery tasks are sync (Celery handles the async boundary)

**Error handling:**
- Use HTTPException with specific status codes from the standards in API-SPEC-001
- Never expose internal error details in API responses (log them, return generic message)
- Never silently swallow exceptions

**Audit trail:**
- Do not call audit logging functions directly from service code
- The SQLAlchemy event listener handles all audit logging automatically
- If you add a new auditable action type, add it to the CHECK constraint in the migration

**Permissions:**
- Every endpoint must declare required permissions using the `@require_permission` decorator
- Never check permissions inside service layer functions; keep it in the route handler
- Document the permission required in the endpoint docstring

### Frontend (TypeScript/React)

**Style:** ESLint + TypeScript strict mode. Run before committing:
```bash
cd frontend
npm run lint
npm run type-check
```

**Structure:**
- Pages in `pages/` are layout components only. No business logic.
- Business logic in custom hooks (`hooks/`).
- API calls via the typed API client in `utils/api.ts`.
- All server state via TanStack Query. No manual fetching in components.
- All global UI state via Zustand stores. No prop drilling for global concerns.
- No `any` types. No `// @ts-ignore`.

**Components:**
- Every new UI component must use tokens from the design system (no raw hex codes)
- Status display must use the `StatusBadge` component, not ad-hoc styling
- Tables must use the `DataTable` component, not custom tables
- Forms must use `react-hook-form` with Zod validation schemas

**Accessibility:**
- All interactive elements must have accessible names
- No color-only status indicators (always include icon or text)
- Test with keyboard navigation before submitting

---

## Testing Requirements

### What Must Be Tested

Every PR must include tests for new or changed functionality.

**Backend:**
```bash
cd backend
# Run all tests
poetry run pytest

# Run with coverage
poetry run pytest --cov=app --cov-report=html

# Run audit trail tests only
poetry run pytest -m audit

# Run a specific test file
poetry run pytest tests/test_protocols.py -v
```

Minimum coverage for new code: **80%**

Every audit-generating action needs a test that:
```python
@pytest.mark.audit
async def test_protocol_approval_creates_audit_entry(client, db, test_protocol):
    # ...approve the protocol...
    
    audit_entry = await db.execute(
        select(AuditLog)
        .where(AuditLog.table_name == "protocols")
        .where(AuditLog.record_id == test_protocol.id)
        .where(AuditLog.action == "APPROVE")
    )
    assert audit_entry.scalar_one() is not None
    assert audit_entry.scalar_one().user_name == "test_user"
```

**Frontend:**
- Component tests using React Testing Library for all new components
- Integration tests for critical user flows (protocol execution, signature flow, document approval)

---

## PR Template

When opening a PR, fill in this template:

```markdown
## Summary
<!-- What does this PR do? Why? -->

## Changes
<!-- List specific changes made -->

## Validation Impact
<!-- Classify each change:
  - [MAJOR] - affects audit trail, e-signatures, access controls, data integrity
  - [MOD]   - new GxP feature or workflow change
  - [MINOR] - UI, non-GxP feature, performance
  - [PATCH] - bug fix, security patch
  - [NONE]  - docs, tests, build tooling -->

- [CLASSIFICATION] Change description

## Testing
<!-- How did you test this? What scenarios did you cover? -->

- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Audit trail tests added (if applicable)
- [ ] Tested manually in local environment
- [ ] Keyboard navigation tested (if UI change)

## Database Changes
<!-- List any new migrations. None if not applicable. -->

Migration: `YYYYMMDD_HHMM_description.py`
Impact: additive | modifying | data_migrating | audit_touching

## Breaking Changes
<!-- Any breaking API or behavior changes? Migration path? -->

## Checklist
- [ ] Code follows project coding standards
- [ ] Linting passes (`black`, `ruff`, `mypy` / `eslint`, `tsc`)
- [ ] All tests pass
- [ ] Documentation updated (if applicable)
- [ ] CHANGELOG.md updated
- [ ] Validation impact classified for each change
- [ ] No secrets or credentials in code
- [ ] No raw hex colors in frontend (use design tokens)
- [ ] No `.any()` type assertions in TypeScript
```

---

## What We Will Not Accept

- Changes that reduce the scope of audit trail coverage
- Changes that allow bypassing electronic signature re-authentication
- Changes that weaken password or session security
- Hardcoded credentials or secrets of any kind
- Direct SQL manipulation of `audit_log` or `electronic_signatures` tables
- Features that depend on external services without appropriate fallback handling
- Frontend code that uses raw hex colors instead of design tokens
- TypeScript code with `any` types or suppressed type errors
- PRs without validation impact classification

---

## Getting Help

- **Questions about the codebase:** Open a GitHub Discussion
- **Bug reports:** Open a GitHub Issue with the `bug` label
- **Feature ideas:** Open a GitHub Discussion first, then an Issue after feedback
- **Security vulnerabilities:** See `SECURITY.md` for responsible disclosure

---

*Thank you for helping build OpenVAL. Every contribution makes GMP compliance more accessible.*
