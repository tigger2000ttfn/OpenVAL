# OpenVAL Software Development Lifecycle (SDL)

**Document Reference:** SDL-001
**Version:** 1.0
**Status:** Approved
**Effective Date:** 2026-04-06
**Author:** OpenVAL Core Team
**Review Cycle:** Annual or upon major release

---

## 1. Purpose

This document describes the Software Development Lifecycle (SDL) for OpenVAL, an open source computer system validation platform intended for use in GMP-regulated pharmaceutical, biotech, and medical device environments.

This SDL is a foundational document for the OpenVAL validation package. Sites deploying OpenVAL will reference this document as evidence that the software was developed under a controlled, documented process consistent with GAMP 5 Category 4 requirements.

---

## 2. Scope

This SDL applies to:

- All source code in the OpenVAL repository
- Database schema and migration files
- Configuration templates and installer scripts
- Bundled protocol and document templates
- Documentation shipped with the product

This SDL does not govern site-specific configuration, custom templates, or integrations developed by implementing organizations. Those activities fall under the site's own CSV program.

---

## 3. Regulatory Basis

| Reference | Relevance |
|---|---|
| GAMP 5 (2nd Edition) | Primary framework. OpenVAL is classified Category 4 (configured software). |
| 21 CFR Part 11 | Electronic records and signatures compliance built into core architecture. |
| EU Annex 11 | Computerised systems requirements inform audit trail and access control design. |
| ICH Q10 | Pharmaceutical Quality System principles applied to release process. |
| ISO/IEC 12207 | Software lifecycle process standard used as structural reference. |

---

## 4. GAMP 5 Software Category Assessment

OpenVAL is classified as **GAMP 5 Category 4 - Configured Software**.

**Rationale:**

OpenVAL is a standard software product (open source, publicly available, with a defined architecture and feature set) that is configured by implementing sites to meet their specific requirements. Configuration occurs through the administration interface, database seed data, workflow definitions, template customization, and LDAP/SSO integration. No modification of source code is required or expected for standard deployment.

Sites that modify source code to add custom functionality should reassess the classification of their instance as GAMP 5 Category 5 for those modifications.

**Validation Approach:**

Consistent with GAMP 5 Category 4:
- The software developer (OpenVAL community) maintains SDL documentation and a controlled release process
- The implementing site performs Installation Qualification (IQ) and Operational Qualification (OQ)
- Performance Qualification (PQ) is performed using site-specific business scenarios
- The pre-authored validation package in `docs/validation_package/` supports this approach

---

## 5. Development Team Roles and Responsibilities

### Core Maintainers
Responsible for: architecture decisions, security review, release approval, SDL compliance.

Minimum qualification: software development experience in regulated environments or demonstrable understanding of GxP software requirements.

### Contributors
Responsible for: feature development, bug fixes, documentation updates per contribution guidelines.

All contributions require: signed Contributor License Agreement (CLA), code review by at least one maintainer, passing CI pipeline.

### Release Manager
Responsible for: version tagging, CHANGELOG maintenance, validation impact classification per release, release notes.

### Security Reviewer
Responsible for: security-sensitive pull requests, dependency vulnerability review, penetration test coordination.

---

## 6. Development Environment Requirements

All developers working on OpenVAL must use:

- Python 3.11+ for backend development
- Node.js 20 LTS for frontend development
- PostgreSQL 15+ for local database
- Redis 7+ for local cache and task queue
- Git 2.40+ for version control
- A code editor with linting integration (ruff, ESLint)

Local development uses `.env` files. No secrets are ever committed to the repository. All `.env` files are listed in `.gitignore`.

---

## 7. Version Control and Branching Strategy

### Repository
All code is maintained in a single public GitHub repository under a defined organization. The repository URL is the authoritative source for all releases.

### Branch Model

```
main                    Protected. Production-ready code only.
                        Requires PR + 1 maintainer review + passing CI.

develop                 Integration branch. Feature branches merge here first.
                        Automated tests run on every push.

feature/ISSUE-short-desc    Individual feature or bug fix branches.
                            Branch from develop. Merge back to develop via PR.

hotfix/ISSUE-short-desc     Critical bug fixes that cannot wait for next release.
                            Branch from main. Merge to both main and develop.

release/vX.Y.Z             Release preparation branches.
                            Branch from develop when ready to release.
                            Merge to main and tag when approved.
```

### Commit Message Format

All commits follow Conventional Commits specification:

```
<type>(<scope>): <short description>

[optional body]

[optional footer: Issue refs, validation impact]

Type: feat | fix | docs | style | refactor | test | chore | security
Scope: auth | audit | protocols | documents | workflows | db | ui | api | deps | config

Examples:
feat(protocols): add screenshot annotation tool to execution view
fix(audit): correct hash chain computation on concurrent writes
security(auth): enforce MFA re-authentication for all signature actions
docs(sdl): update GAMP category justification for v0.3.0
```

### Validation Impact in Commit Footer

For any commit that affects validated functionality, include:

```
Validation-Impact: major | minor | none
Validation-Note: <brief description of what sites may need to assess>
```

---

## 8. Code Review Requirements

All code merged to `develop` or `main` requires:

| Criteria | Requirement |
|---|---|
| Reviewer count | Minimum 1 maintainer |
| CI pipeline | Must pass (tests, linting, type checking) |
| Security-sensitive code | Additional security reviewer required |
| Database schema changes | Must include Alembic migration |
| API changes | Must include updated OpenAPI schema |
| New dependencies | Must be reviewed for license compatibility and known vulnerabilities |
| Audit trail impact | Any change affecting audit_log or electronic_signatures tables requires maintainer sign-off |

Pull request descriptions must include:
- Summary of changes
- Testing performed
- Validation impact classification (major / minor / none)
- Link to related issue(s)

---

## 9. Testing Requirements

### Test Types

**Unit Tests**
- All business logic in `services/` layer must have unit tests
- Target: 80% line coverage minimum
- Framework: pytest with pytest-asyncio

**Integration Tests**
- All API endpoints must have integration tests covering:
  - Happy path (expected input, expected output)
  - Authentication failure (401)
  - Authorization failure (403)
  - Input validation failure (422)
  - Business rule violation (400 or 409)
- Framework: pytest + httpx AsyncClient

**Audit Trail Tests**
- Every action that should generate an audit log entry must have a specific test verifying the entry was created with correct fields
- These tests are tagged `@pytest.mark.audit` and run separately in CI

**Electronic Signature Tests**
- Every signature action must have tests verifying:
  - Signature record created with correct meaning
  - Re-authentication is enforced
  - Invalid credentials are rejected
  - Signature hash is computed correctly

**Security Tests**
- Automated OWASP ZAP scan runs on every release candidate
- Dependency vulnerability scanning via pip-audit and npm audit on every PR
- SQL injection tests for all user-input parameters

### Test Data Management

Test data uses factory_boy factories. No production data is used in tests. All test databases are created fresh per test session and dropped on completion.

### CI Pipeline Steps

1. Checkout code
2. Install dependencies (cached)
3. Run linting (ruff, ESLint)
4. Run type checking (mypy, TypeScript)
5. Run unit tests
6. Run integration tests
7. Run audit trail tests
8. Run security scans
9. Build frontend
10. Generate coverage report
11. On `release/*` branches: generate API docs

---

## 10. Dependency Management

### Backend (Python)

Dependencies are declared in `pyproject.toml` using Poetry. Version constraints use `^` (compatible release) to allow patch updates while preventing breaking changes.

All dependencies are reviewed for:
- License compatibility with AGPL-3.0
- Known CVEs (checked via pip-audit in CI)
- Maintenance status (actively maintained projects only)

Dependencies are updated on a quarterly schedule. Security patches are applied immediately upon disclosure.

### Frontend (Node.js)

Dependencies are declared in `package.json`. `package-lock.json` is committed to the repository to ensure reproducible builds.

All dependencies are reviewed for:
- License compatibility
- Known CVEs (checked via npm audit in CI)
- Bundle size impact

---

## 11. Database Migration Management

All database schema changes are managed through Alembic migrations.

**Rules:**
- No DDL changes are made outside of Alembic migrations
- Every migration must be reversible (include both `upgrade()` and `downgrade()` functions)
- Migrations that affect the `audit_log` or `electronic_signatures` tables require maintainer review
- Migration files are named: `YYYYMMDD_HHMM_short_description.py`
- Every release includes a `MIGRATION_NOTES.md` listing all migrations and their validation impact

**Migration Classification:**
- **Schema-additive** (new tables, new nullable columns): Low impact, no data loss risk
- **Schema-modifying** (column type changes, constraints): Medium impact, review required
- **Data-migrating** (backfilling or transforming existing records): High impact, must include rollback plan and data verification step
- **Audit-touching** (any change to audit_log or integrity tables): Requires explicit maintainer approval and SDL review

---

## 12. Security Development Practices

### Input Validation
All user-supplied input is validated via Pydantic schemas before reaching business logic. No raw SQL is constructed from user input. All database queries use SQLAlchemy's parameterized query system.

### Authentication and Session Management
- Passwords hashed with bcrypt, minimum cost factor 12
- JWT access tokens expire in 15 minutes
- Refresh tokens expire in 7 days, rotated on use, stored hashed
- MFA tokens validated server-side using PyOTP
- Account lockout after 5 failed attempts (15-minute lockout)

### Secrets Management
- No secrets in source code, configuration files, or commit history
- All secrets via environment variables
- Sensitive configuration values (LDAP passwords, API keys, MFA secrets) encrypted at rest using AES-256 at the application layer

### Dependency Security
- pip-audit and npm audit run in CI on every pull request
- GitHub Dependabot alerts enabled for the repository
- Critical CVEs patched within 48 hours of disclosure
- High CVEs patched within 7 days

### Audit Trail Integrity
- The audit_log table is protected by PostgreSQL Row Level Security (RLS) preventing UPDATE and DELETE at the database level
- A hash chain is maintained across all audit records to detect retroactive tampering
- The hash chain is verified nightly by a Celery scheduled task
- Hash chain failures generate immediate critical alerts

---

## 13. Release Process

### Version Numbering

OpenVAL uses Semantic Versioning (SemVer): `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes or significant architectural changes. Sites should treat as a major revalidation trigger.
- **MINOR**: New features, backward compatible. Sites should assess validation impact; OQ re-execution may be required.
- **PATCH**: Bug fixes and security patches. Sites should assess impact; typically administrative change control.

### Validation Impact Classification per Release

Every release is classified:

| Class | Definition | Typical Site Response |
|---|---|---|
| Major | Changes to audit trail, e-signatures, access controls, or core data integrity | Formal revalidation assessment, likely partial or full re-OQ |
| Moderate | New GxP-relevant features, workflow changes, document handling changes | Impact assessment, targeted re-OQ for affected areas |
| Minor | UI improvements, non-GxP features, performance improvements | Administrative change control, no re-OQ required |
| Patch | Bug fixes, security patches, dependency updates | Risk-based assessment; typically administrative |

### Release Checklist

- [ ] All milestone issues closed or deferred with justification
- [ ] CHANGELOG.md updated with version, date, validation impact class, and all changes
- [ ] All tests passing in CI
- [ ] Security scan completed with no unresolved critical or high CVEs
- [ ] API documentation regenerated
- [ ] Migration notes updated
- [ ] Validation package documents reviewed for currency
- [ ] Release candidate tested against fresh PostgreSQL 15 database
- [ ] Release candidate tested on Ubuntu 22.04 bare metal using install.sh
- [ ] Release branch merged to main
- [ ] Git tag created: `v1.2.3`
- [ ] GitHub Release created with release notes and validation impact statement
- [ ] Docker image tagged (when Docker packaging is active)

### Hotfix Process

Hotfixes for critical security or data integrity issues bypass the normal release cycle:
1. Branch from `main` as `hotfix/ISSUE-description`
2. Fix implemented and reviewed by at least one maintainer
3. Full test suite run
4. Merged to `main` and `develop`
5. Tagged as patch release (e.g., `1.2.3` -> `1.2.4`)
6. GitHub Security Advisory published if applicable

---

## 14. Change Control

Changes to OpenVAL source code are managed through GitHub Pull Requests. Every merged PR constitutes a controlled change with:

- Unique identifier (PR number)
- Description of change
- Reviewer identity and approval timestamp
- CI pipeline pass/fail record
- Validation impact classification
- Link to issue(s)

This GitHub PR record serves as the change control record for OpenVAL development. The CHANGELOG.md is the human-readable summary of all changes per version.

Sites implementing OpenVAL manage upgrades under their own site-level change control procedure, referencing the OpenVAL release notes and validation impact classification.

---

## 15. Problem Management (Bug Tracking)

All defects are tracked as GitHub Issues using the `bug` label.

Bug report template requires:
- OpenVAL version affected
- Environment (OS, PostgreSQL version, deployment type)
- Steps to reproduce
- Actual behavior
- Expected behavior
- GxP impact assessment (does this affect audit trail, signatures, access control, or data integrity?)

GxP-impacting bugs are prioritized as critical and addressed in the next patch release at minimum.

---

## 16. Documentation Requirements

All features must be documented before or alongside code release:

| Document Type | Required For | Location |
|---|---|---|
| API endpoint documentation | All new endpoints | Auto-generated via FastAPI, stored in `docs/api/` |
| User guide | All user-facing features | `docs/user_guide/` |
| Administration guide | All admin features | `docs/admin_guide/` |
| Architecture Decision Record (ADR) | Significant architectural decisions | `docs/architecture/` |
| Migration notes | All database migrations | `MIGRATION_NOTES.md` |
| CHANGELOG entry | All changes | `CHANGELOG.md` |

---

## 17. SDL Review and Maintenance

This SDL is reviewed:
- Annually as part of the OpenVAL periodic review cycle
- Upon any major release
- Upon any significant change to the development process, tools, or regulatory guidance

Changes to this SDL are managed as a PR to the repository with maintainer review and approval. The CHANGELOG records SDL updates.

---

## 18. Traceability

The following table maps SDL sections to regulatory requirements:

| SDL Section | Regulatory Reference |
|---|---|
| Section 4 (GAMP Category) | GAMP 5, Chapter 4 |
| Section 7 (Version Control) | 21 CFR 11.10(a), EU Annex 11 §4 |
| Section 8 (Code Review) | GAMP 5, Chapter 7 |
| Section 9 (Testing) | 21 CFR 11.10(a), GAMP 5, Chapter 8 |
| Section 10 (Dependencies) | GAMP 5, Chapter 5 |
| Section 11 (Migrations) | 21 CFR 11.10(c), EU Annex 11 §10 |
| Section 12 (Security) | 21 CFR 11.10(d), 21 CFR 11.200 |
| Section 13 (Release) | GAMP 5, Chapter 9 |
| Section 14 (Change Control) | 21 CFR 11.10(k), EU Annex 11 §10 |
| Section 15 (Problem Management) | EU Annex 11 §11 |
| Section 16 (Documentation) | 21 CFR 11.10(a) |

---

*SDL-001 v1.0 - OpenVAL Software Development Lifecycle*
