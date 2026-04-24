# PHAROLON Changelog

All changes to PHAROLON are documented here. Each release includes a validation impact
classification to help implementing sites determine the appropriate site-level response.

## Validation Impact Classification

| Class | Abbreviation | Definition | Typical Site Response |
|---|---|---|---|
| Major | `[MAJOR]` | Changes to audit trail, e-signatures, access controls, or core data integrity mechanisms | Formal revalidation assessment; likely partial or full re-OQ |
| Moderate | `[MOD]` | New GxP-relevant features, workflow engine changes, document handling changes | Impact assessment; targeted re-OQ for affected functional areas |
| Minor | `[MINOR]` | UI improvements, non-GxP features, performance improvements, report changes | Administrative change control; no re-OQ required |
| Patch | `[PATCH]` | Bug fixes, security patches, dependency updates | Risk-based assessment; typically administrative |
| None | `[NONE]` | Documentation, code style, tests, build tooling | No site action required |

---

## [Unreleased]

### Added
- Initial project structure, MASTER_PLAN.md, schema, and documentation suite

---

## [0.1.0] - Planned

**Overall Validation Impact: MAJOR**
*Reason: First release. Sites must execute full IQ/OQ/PQ from the bundled validation package.*

### Added

**Phase 0: Foundation**
- `[MAJOR]` FastAPI backend application with async SQLAlchemy 2.0 and PostgreSQL
- `[MAJOR]` JWT authentication with 15-minute access tokens and rotating refresh tokens
- `[MAJOR]` TOTP MFA with backup codes, AES-256 encrypted secret storage
- `[MAJOR]` Audit trail engine as SQLAlchemy event listener with SHA-256 hash chain
- `[MAJOR]` Electronic signature engine with re-authentication and meaning attestation
- `[MAJOR]` PostgreSQL Row Level Security enforcing append-only audit_log and electronic_signatures
- `[MAJOR]` RBAC permission system with module/action/resource granularity
- `[MINOR]` Celery + Redis background task infrastructure
- `[MINOR]` Structured JSON logging with request correlation IDs
- `[MINOR]` Rate limiting on authentication endpoints (10 req/min)
- `[NONE]`  React 18 + TypeScript + Vite frontend scaffold
- `[MINOR]` Complete AppShell: header, collapsible sidebar, breadcrumbs, content area
- `[MINOR]` Authentication pages: login, MFA entry, password reset, mandatory change
- `[MINOR]` Base UI component library (Button, Input, Modal, Toast, Badge, Table, FilterBar)
- `[MINOR]` DataTable with sort, filter, paginate, export, column config
- `[MINOR]` SignatureCapture modal (21 CFR Part 11 re-authentication flow)
- `[MINOR]` TimelineView (audit trail display component)
- `[MINOR]` FileUpload with SHA-256 verification and virus scan hook
- `[MINOR]` RichTextEditor (TipTap: headings, lists, tables, links, images)
- `[MINOR]` Notification center (in-app)
- `[NONE]`  User profile page (name, title, MFA setup, password change, preferences)
- `[NONE]`  Bare metal install.sh for Ubuntu 22.04 and RHEL 9
- `[NONE]`  systemd unit files for pharolon-api, pharolon-worker, pharolon-beat
- `[NONE]`  Nginx configuration template with TLS, security headers, reverse proxy
- `[NONE]`  Backup and restore scripts
- `[NONE]`  Environment variable template (.env.example)
- `[NONE]`  SDL-001 Software Development Lifecycle document
- `[NONE]`  Architecture Decision Records (ADR-001 through ADR-014)
- `[NONE]`  UI/UX Design Specification (UI-SPEC-001)
- `[NONE]`  API Specification (API-SPEC-001)
- `[NONE]`  Installation Guide (INSTALL-001)

**Phase 1: Core Data Layer**
- `[MAJOR]` Complete 100+ table PostgreSQL schema deployed via Alembic migrations
- `[MAJOR]` Seed data: signature meanings, GAMP categories, roles, permissions, risk matrices
- `[MAJOR]` Regulatory reference data (21 CFR Part 11, EU Annex 11, GAMP 5, ICH)
- `[MAJOR]` Default notification templates for all system events
- `[MAJOR]` Database helper functions: generate_ref, compute_risk_level, get_traceability_coverage
- `[MAJOR]` Database views: v_overdue_items, v_system_validation_status, v_my_tasks, v_training_compliance

---

## Template for Future Releases

```markdown
## [X.Y.Z] - YYYY-MM-DD

**Overall Validation Impact: [MAJOR|MOD|MINOR|PATCH|NONE]**
*Reason: Brief justification for the classification.*

### Added
- `[IMPACT]` Description of new feature

### Changed
- `[IMPACT]` Description of change (include what changed, old behavior, new behavior)

### Fixed
- `[PATCH]` Description of bug fixed (include impact on GxP functions if applicable)

### Security
- `[PATCH]` Description of security fix (include CVE reference if applicable)

### Deprecated
- `[MINOR]` Description of deprecated feature (include migration path)

### Removed
- `[MOD|MAJOR]` Description of removed feature

### Database Migrations
- Migration: `YYYYMMDD_HHMM_description.py` - Description of schema change
- Validation Impact: additive | modifying | data_migrating | audit_touching

### Breaking Changes (if any)
- Description of breaking change and migration path
```

---

*This changelog follows the format established by [Keep a Changelog](https://keepachangelog.com/).*
*Validation impact classifications are provided to support implementing sites' change control processes.*
*Sites should perform their own impact assessment; these classifications are guidance, not direction.*
