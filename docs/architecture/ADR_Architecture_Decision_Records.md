# PHARION Architecture Decision Records (ADRs)

**Location:** `docs/architecture/`
**Format:** Each ADR is a numbered decision record. Once accepted, ADRs are never deleted, only superseded.

---

## ADR-001: FastAPI over Django for Backend Framework

**Date:** 2026-04-06
**Status:** Accepted

### Context
PHARION needs a Python backend framework. The primary candidates were Django REST Framework (DRF) and FastAPI.

### Decision
FastAPI with SQLAlchemy 2.0 async and Pydantic v2.

### Rationale
- FastAPI's async-first architecture supports high concurrency for protocol execution sessions where multiple users may be executing test steps simultaneously
- Pydantic v2 provides automatic request/response validation and OpenAPI schema generation with no additional tooling
- SQLAlchemy 2.0 with asyncpg gives full control over query construction while preventing SQL injection
- FastAPI's dependency injection system cleanly supports request-scoped audit context (current user, IP, session ID available in every handler)
- Auto-generated OpenAPI docs at `/api/docs` satisfy the documentation requirement for validated systems without manual maintenance

### Trade-offs
- Django provides more built-in features (admin panel, ORM migrations via its own system). We mitigate this with Alembic for migrations and a custom admin UI.
- FastAPI requires more explicit wiring than Django's magic. Acceptable given the team's skill level and the need for explicitness in a regulated context.

---

## ADR-002: PostgreSQL over MySQL or SQLite

**Date:** 2026-04-06
**Status:** Accepted

### Context
Choice of relational database engine.

### Decision
PostgreSQL 15+ as the sole supported database.

### Rationale
- Row Level Security (RLS) policies are used to enforce append-only behavior on `audit_log` and `electronic_signatures` tables. This is a critical 21 CFR Part 11 control. RLS is a PostgreSQL-specific feature.
- `uuid_generate_v4()` is native to PostgreSQL via the `uuid-ossp` extension
- `pg_trgm` extension supports full-text trigram search without a separate search engine
- JSON operators allow efficient querying of JSON-typed columns
- PostgreSQL's ACID compliance, MVCC implementation, and row-level locking are appropriate for a multi-user validation platform where data integrity is paramount

### Trade-offs
- Single database engine means no SQLite option for development (we use a local PostgreSQL instance instead)
- MySQL and MariaDB are not supported

---

## ADR-003: Append-Only Audit Trail Enforced at Database Layer

**Date:** 2026-04-06
**Status:** Accepted

### Context
21 CFR 11.10(e) requires that audit trails be secure and computer-generated such that they cannot be altered. The question is: enforce this at the application layer only, or also at the database layer.

### Decision
Enforce at both layers. PostgreSQL RLS policies on `audit_log` and `electronic_signatures` permit INSERT and SELECT but have no UPDATE or DELETE policy defined, making those operations fail regardless of application code.

Additionally, a hash chain is maintained in `audit_log_integrity` linking each record to the previous via SHA-256, making retroactive insertion or modification detectable.

### Rationale
- Application-layer-only enforcement can be bypassed by a developer with database access
- In a regulated environment, a DBA or system administrator with direct DB access represents a real threat model
- Database-layer enforcement is a defense-in-depth measure consistent with FDA expectation that audit trails be protected from modification by any means

### Implementation
```sql
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_log_select ON audit_log FOR SELECT USING (true);
CREATE POLICY audit_log_insert ON audit_log FOR INSERT WITH CHECK (true);
-- No UPDATE policy = UPDATE fails
-- No DELETE policy = DELETE fails
```

The application connects as a dedicated PostgreSQL user `pharion_app` that does not have SUPERUSER privileges and cannot bypass RLS.

---

## ADR-004: SQLAlchemy Event Listener for Automatic Audit Trail

**Date:** 2026-04-06
**Status:** Accepted

### Context
Every data write must generate an audit trail entry. Two approaches considered:
1. Explicit audit logging in every service method
2. SQLAlchemy event listener that intercepts all session flushes

### Decision
SQLAlchemy `after_flush` event listener on all sessions.

### Rationale
- Explicit logging requires every developer to remember to call the audit function. One missed call means a gap in the audit trail, which is a regulatory finding.
- The event listener approach is architecturally impossible to bypass. If data is written through the SQLAlchemy session (the only sanctioned path), the audit entry is created automatically in the same transaction.
- The listener is implemented once, tested once, and then all future development inherits it for free.

### Implementation Notes
- The listener reads request context (user ID, IP, session ID) from a Python `contextvars.ContextVar` set by authentication middleware
- Old and new values are serialized as JSON, with SHA-256 hashes computed for integrity verification
- The audit entry is written within the same database transaction as the data change, so they commit or rollback together atomically

---

## ADR-005: JWT with Short-Lived Access Tokens and Rotating Refresh Tokens

**Date:** 2026-04-06
**Status:** Accepted

### Context
Session management approach for the REST API.

### Decision
- Access tokens: JWT, 15-minute expiry, signed with HS256
- Refresh tokens: opaque random string, 7-day expiry, stored hashed in `user_sessions`, rotated on every use

### Rationale
- Short-lived access tokens limit the damage window if a token is compromised
- Refresh token rotation means a stolen refresh token is detectable (using the old token after rotation invalidates the entire session family)
- JWT access tokens are stateless, reducing database load for the majority of API requests
- Refresh tokens are stateful (stored in DB) to enable server-side revocation (logout, lock account, session expiry)
- 21 CFR 11.10(d) requires that system access be limited to authorized individuals. Token expiry and revocation support this.

### Token Claims
Access token payload:
```json
{
  "sub": "user-uuid",
  "username": "mescamilla",
  "site_id": "site-uuid",
  "roles": ["validation_engineer"],
  "mfa_verified": true,
  "iat": 1234567890,
  "exp": 1234568790
}
```

---

## ADR-006: TOTP for MFA Rather Than SMS or Email OTP

**Date:** 2026-04-06
**Status:** Accepted

### Context
MFA mechanism for electronic signature re-authentication and optional login MFA.

### Decision
TOTP (RFC 6238) using authenticator apps (Google Authenticator, Authy, Microsoft Authenticator). SMS and email OTP are not supported.

### Rationale
- TOTP does not require an external service dependency (no Twilio, no email delay at signing time)
- SMS OTP is vulnerable to SIM swapping attacks, which is inappropriate for a system protecting GxP records
- Email OTP creates dependency on email deliverability at the exact moment a user needs to sign a record
- TOTP is widely understood and supported by all major authenticator apps
- 10 single-use backup codes are generated at MFA enrollment, stored hashed, for account recovery

### Implementation
- TOTP secret generated via `pyotp.random_base32()`
- Secret encrypted with AES-256 before storage in `users.mfa_secret`
- QR code generated at enrollment using `qrcode` library
- Backup codes generated as `secrets.token_hex(10)`, stored as bcrypt hashes

---

## ADR-007: Celery with Redis for Background Tasks

**Date:** 2026-04-06
**Status:** Accepted

### Context
Several PHARION functions require asynchronous or scheduled execution: email notifications, report generation, audit chain verification, periodic review reminders, SLA escalations.

### Decision
Celery 5 with Redis as both the message broker and result backend.

### Rationale
- Celery is the most mature Python background task system with proven reliability
- Redis is already required as a session cache, so no additional infrastructure is added
- Celery Beat handles scheduled tasks (audit chain verification, overdue alerts, periodic review reminders) without a separate cron setup
- Task failures are logged and retried automatically
- Celery Flower can be added later for task monitoring

### Scheduled Tasks
| Task | Schedule | Purpose |
|---|---|---|
| `verify_audit_chain` | Nightly 02:00 | Hash chain integrity verification |
| `send_overdue_alerts` | Daily 08:00 | Workflow SLA, CAPA, periodic review overdue notifications |
| `check_periodic_reviews` | Daily 07:00 | Generate periodic review reminders at lead time |
| `check_calibration_due` | Daily 07:00 | Equipment calibration and maintenance reminders |
| `check_document_reviews` | Daily 07:00 | Document periodic review reminders |
| `process_scheduled_reports` | Hourly | Run any report schedules that are due |
| `cleanup_expired_sessions` | Nightly 01:00 | Remove expired user sessions from DB |

---

## ADR-008: React 18 with TypeScript and Vite

**Date:** 2026-04-06
**Status:** Accepted

### Context
Frontend framework selection.

### Decision
React 18 + TypeScript + Vite. No Next.js, no SSR.

### Rationale
- PHARION is a single-page application (SPA). Users authenticate once and work within the app. SSR provides no SEO benefit (it is a private, authenticated tool) and adds deployment complexity.
- Vite provides significantly faster development build times than Create React App or Webpack
- TypeScript catches interface mismatches between frontend and backend at build time, reducing runtime errors in production
- React 18's concurrent features (useTransition, Suspense) improve perceived performance in complex UIs like the protocol execution engine
- The SPA model serves static files from Nginx, keeping the deployment simple for bare metal sites

### Build Output
Vite builds to `frontend/dist/`. Nginx serves this directory as static files. All API calls go to `/api/v1/` which Nginx proxies to Gunicorn.

---

## ADR-009: Zustand for State Management

**Date:** 2026-04-06
**Status:** Accepted

### Context
Client-side state management. Candidates: Redux Toolkit, Zustand, React Query only.

### Decision
Zustand for global client state + TanStack Query for server state.

### Rationale
- Redux Toolkit adds significant boilerplate for a team that may have varying React experience
- Zustand has a minimal API (a single `create` function) with no required providers, making it easier for contributors to understand
- TanStack Query handles server-state concerns (caching, background refetching, loading/error states) that would otherwise require significant Redux middleware
- The combination cleanly separates concerns: Zustand for UI state (sidebar open, selected site, current user), TanStack Query for all API data

### Store Structure
```
stores/
  auth.store.ts         current user, tokens, permissions
  ui.store.ts           sidebar state, theme, breadcrumbs
  site.store.ts         current site context
  notifications.store.ts  unread notification count, toast queue
```

---

## ADR-010: TipTap for Rich Text Editing

**Date:** 2026-04-06
**Status:** Accepted

### Context
Rich text editor for protocol descriptions, document body content, requirement descriptions, CAPA problem statements, and other narrative fields.

### Decision
TipTap (ProseMirror-based).

### Rationale
- TipTap is headless (no default styling), allowing it to match PHARION's design system exactly
- Supports tables, which are needed in protocol steps and documents
- JSON-based document model serializes cleanly to the database (no raw HTML stored for content, only rendered HTML cached)
- Collaborative editing extension available for future roadmap item
- MIT licensed

### Content Storage
TipTap document JSON is stored in the database. On save, a rendered HTML version is also cached in `rendered_html` columns for PDF generation and display. The JSON is the source of truth.

---

## ADR-011: No Docker Required for Production Deployment

**Date:** 2026-04-06
**Status:** Accepted

### Context
Deployment model for production use.

### Decision
Bare metal on Ubuntu 22.04 LTS or RHEL 9 is the primary supported deployment. Nginx + Gunicorn + systemd. Docker Compose is a future optional packaging, not a requirement.

### Rationale
- Many pharmaceutical sites have IT security policies that restrict or prohibit container runtimes in production
- Container overhead is unnecessary for a single-site deployment on dedicated hardware
- systemd provides reliable process management, automatic restart, and log management via journald without additional tooling
- A bare metal install has fewer moving parts and is easier to reason about during a regulatory inspection
- Resource requirements are lower without container overhead

### Impact
- `install.sh` automates the full bare metal setup
- systemd unit files are provided for all services
- Nginx configuration template is provided
- Docker Compose support is deferred to Phase 20

---

## ADR-012: Monorepo Structure

**Date:** 2026-04-06
**Status:** Accepted

### Context
Should backend and frontend live in the same repository or separate repositories?

### Decision
Single monorepo with `backend/` and `frontend/` directories.

### Rationale
- Atomic commits: a feature that changes both API and UI is a single PR with a single validation impact classification
- Simpler issue tracking: one issue references both backend and frontend changes
- Easier onboarding: contributors clone one repository
- Version synchronization: the released version applies to the whole system, not independently versioned components
- The validation package references a single repository tag for a complete system snapshot

---

## ADR-013: AGPL-3.0 License

**Date:** 2026-04-06
**Status:** Accepted

### Context
Open source license selection.

### Decision
GNU Affero General Public License v3.0 (AGPL-3.0).

### Rationale
- AGPL requires that anyone who runs a modified version of PHARION over a network must release their modifications under AGPL. This prevents commercial entities from taking the codebase, modifying it, and offering it as a competing SaaS product without contributing back.
- Sites that use PHARION without modification for their own internal use are not required to publish anything.
- Sites that modify the source code for internal use only are not required to publish their modifications (the network-distribution trigger does not apply to internal tools).
- Commercial support licensing can coexist with AGPL through a dual-licensing arrangement if needed in future.

---

## ADR-014: Server-Side Reference Number Generation via PostgreSQL Sequences

**Date:** 2026-04-06
**Status:** Accepted

### Context
Human-readable reference numbers (SYS-0001, CAPA-0042, IQ-LIMS-001) are required throughout the system for regulatory traceability.

### Decision
PostgreSQL sequences with a `generate_ref(prefix, sequence_name, padding)` function. Reference numbers are assigned server-side at INSERT time, never generated client-side.

### Rationale
- Client-side generation risks collisions in concurrent environments
- PostgreSQL sequences are atomic and gap-free under normal operation
- Server-side assignment means reference numbers are always in the audit trail and cannot be influenced by the client
- The `generate_ref` function provides a consistent format: `{PREFIX}-{zero-padded-number}`

### Format Examples
```
SYS-0042       System inventory record
EQ-0012        Equipment record
RA-0007        Risk assessment
RS-0003        Requirement set
IQ-0015        IQ protocol
TE-0089        Test execution
DEV-0003       Deviation
CR-0024        Change request
CAPA-0011      CAPA record
NC-0005        Nonconformance
PR-0019        Periodic review
VEND-0008      Vendor record
AUD-0002       Audit record
```

---

*All ADRs are living records. Superseded ADRs are marked with status "Superseded by ADR-XXX" and are never deleted.*
