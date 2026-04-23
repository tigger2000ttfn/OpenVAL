# OpenVAL Master Plan

**The Definitive Open Source GxP Computer System Validation Platform**
*Kneat Gx + SWARE Res_Q + ValGenesis VLMS — Open Source, Self-Hosted, AI-Ready*

**Version:** 2.0.0
**Last Updated:** 2026-04-08
**Status:** Living Document — Single Source of Truth

---

## How to Use This Document

This is the single living document for all OpenVAL development. Every
feature, every table, every phase, every workflow is defined here.
The addendum documents (MASTER_PLAN_ADDENDUM_001.md, MODULE_EXTENSIONS_001.md)
feed into this document. If there is a conflict, this document wins.

When a phase is completed, check off the tasks. When requirements change,
update this document first. All PRs must reference a phase and task from
this document.

---

## Table of Contents

1. [Vision, Principles, and Market Position](#1-vision)
2. [Architecture Overview](#2-architecture)
3. [Complete Feature Set — All 30 Validation Disciplines](#3-features)
4. [Database Schema — 251 Tables](#4-schema)
5. [Phase Plan — 26 Phases](#5-phases)
6. [Module Specifications](#6-modules)
7. [Compliance Framework Mapping](#7-compliance)
8. [Validation Package Specification](#8-validation-package)
9. [API Design Standards](#9-api)
10. [Security Architecture](#10-security)
11. [Bare Metal Deployment](#11-deployment)
12. [CE vs EE Feature Split](#12-editions)

---

## 1. Vision, Principles, and Market Position

### The Problem

The pharmaceutical industry spends billions on computer system validation.
Every validated system — LIMS, MES, ERP, QMS, chromatography data systems —
must be documented, tested, approved, and maintained in a validated state.
The leading commercial platforms (Kneat Gx, ValGenesis VLMS, SWARE Res_Q)
charge $30,000 to $200,000 per year. Paper-and-SharePoint is still the
reality at hundreds of pharmaceutical sites globally.

OpenVAL is the open source answer. Not a simplified version. The complete
platform.

### Market Research Basis

This plan incorporates feature analysis of:

- **Kneat Gx 25-R3** (8 of top 10 global life sciences companies, $64.8M ARR)
  - Entity system (System, Equipment, Test Case, Risk, File entities)
  - Entity Masks for site customization
  - Cross-workspace entity sharing (v9.5+)
  - Standalone Test Case Entities with executable step matrix
  - In-app real-time RTM (auto-generated, auto-updated)
  - Collections/Audit War Rooms (read-only staging for auditors)
  - Drawing Management Module (P&ID walkdowns)
  - Electronic Logbook Management (fully 21 CFR Part 11 compliant)
  - Electronic Batch Records (eBR)
  - Paperless Handover packages
  - Document redlining and annotation tools
  - Global Requirements management (25-R3)
  - Business Intelligence dashboards
  - 14 validation disciplines: AIV, Audit, Cleaning, Cold Chain,
    CQV, CSV, Document Mgmt, Drawing Mgmt, eBR, eLogbook, Equipment,
    Facilities & Utilities, Method, Process Validation

- **SWARE Res_Q** (AI-powered, CSA-focused)
  - Video-to-Script capture (film screen → auto-generate validation script)
  - Agentic AI: custom assistants for routine monitoring
  - Automated risk scoring (eliminates subjectivity)
  - Smart dashboards & analytics (data-first design)
  - Open API: 30+ application integrations
  - CSA-first approach (shifted from CSV)
  - GxPNext product (for developers)
  - Validate AI for GxP (ML model validation workflows)
  - Validation debt concept and tracking

- **ValGenesis VLMS 5.0 / iVal**
  - AI-powered authoring (cut cycle time 80%)
  - Live anomaly flags during execution
  - Real-time multi-user collaboration (Google Docs style)
  - Auto-generate documents from existing data
  - iRisk: QbD knowledge management
  - iClean: Cleaning validation lifecycle
  - Process Manager + Process Insight
  - e-Logbook: Electronic logbooks
  - CSA-ready (first to market): scripted + unscripted testing
  - Served 30 of top 50 life sciences companies globally

- **FDA Final CSA Guidance (Sept 24, 2025)**
  - 4-step process: Intended Use → Risk → Assurance Activities → Record
  - Risk-based, not "validate everything"
  - Unscripted and exploratory testing explicitly supported
  - Vendor documentation leverage (don't recreate what vendor already tested)
  - Critical thinking documentation — rationale, not volume
  - Cloud/SaaS continuous update model supported
  - Aligns with GAMP 5 (2nd Ed.) and ICH Q9

- **DCP (Roche/Genentech)**: GxP/non-GxP boundary labeling, process engineering
- **LabWare**: EM, stability, LIMS integration patterns
- **MasterControl**: Validation on Demand (patented), closed-loop QMS
- **Blue Mountain RAM**: Process engineering, CPV, PAT integration

### Design Principles

**For Compliance**
- Audit trail is the foundation, not a feature. Every write is intercepted
- 21 CFR Part 11 to the letter: meaning, identity, date/time, re-authentication
- ALCOA+ enforced by architecture: not by policy
- CSA and CSV are both first-class modes, not an afterthought
- The system generates evidence that regulators actually accept

**For Users**
- Non-developers execute protocols, build workflows, and generate reports
- The interface mirrors what validation engineers expect: it feels like Kneat
- Reusable test case library means write-once, reuse-everywhere
- Templates ship ready for pharma use on day one

**For Operations**
- Self-hosted. No cloud dependency. Data stays on your infrastructure
- Single-server bare metal deployment. No Kubernetes required
- Validation package bundled. Sites execute it themselves

**For Community**
- Community Edition: genuinely complete for single-site CSV programs
- Enterprise Edition: multi-site, analytics, AI, deep integrations
- Open source AGPL-3.0. No vendor lock-in. Export everything, always

---

## 2. Architecture Overview

### System Architecture

```
[ Nginx (TLS, static files, reverse proxy, security headers) ]
                         |
  [ Gunicorn + Uvicorn Workers — FastAPI Application ]
                  |               |
         [ PostgreSQL 15+ ]   [ Redis ]
           (Oracle 19c+)       (cache, queue, sessions)
           (MySQL 8.0+)             |
                            [ Celery Workers ]
                            (background tasks, notifications,
                             scheduled reviews, audit chain verification,
                             report generation, license validation)
```

### Module Architecture (Open Core)

```
backend/app/modules/
  community/           # AGPL-3.0 — always free
    auth/              # JWT + TOTP MFA authentication
    users/             # User management, RBAC
    sites/             # Site/organization management
    systems/           # System inventory, GAMP classification
    equipment/         # Equipment management, calibration
    risk/              # Risk assessment (FMEA, P×I)
    requirements/      # URS, FS, DS, CS management
    protocols/         # Protocol builder
    executions/        # Test execution engine
    deviations/        # Deviation management
    documents/         # Controlled document management
    workflows/         # Low-code workflow engine
    change_control/    # Change request lifecycle
    capa/              # Corrective and preventive actions
    nonconformances/   # Nonconformance events
    periodic_review/   # Periodic review scheduler
    traceability/      # RTM generation
    vendors/           # Vendor qualification
    audits/            # Audit management
    training/          # Training records
    reports/           # Standard reports and dashboards
    notifications/     # Email notifications
    files/             # File storage
    audit_log/         # Audit trail viewer
    admin/             # Administration

  enterprise/          # Commercial license — EE only
    oos_oot/           # OOS/OOT investigation
    complaints/        # Product complaints
    em/                # Environmental monitoring
    stability/         # Stability studies
    batch_lot/         # Batch/lot management
    inspection/        # Inspection readiness
    logbooks/          # Electronic logbook management
    drawings/          # Drawing/P&ID management
    tech_transfer/     # Technology transfer
    cleaning_val/      # Cleaning validation
    cold_chain/        # Cold chain/temperature mapping
    cqv/               # Commissioning & qualification
    process_val/       # Process validation stages 1/2/3
    sterilization/     # Sterilization validation
    csa/               # CSA mode and records
    test_case_lib/     # Reusable test case library
    audit_collections/ # Audit war rooms
    vmp/               # Validation Master Plan
    qbd/               # Quality by Design framework
    spc/               # Statistical process control
    analytics/         # Manufacturing analytics
    ai/                # AI assistance (Phase 22+)
    multi_site/        # Cross-site management
    advanced_wf/       # Advanced workflow features
    integrations/      # Deep external integrations
    advanced_reports/  # Custom report builder
```

### Technology Stack

| Layer | Technology | Notes |
|---|---|---|
| Backend | Python 3.11+ / FastAPI | Async throughout |
| ORM | SQLAlchemy 2.0 async | Multi-DB abstraction |
| Database | PostgreSQL 15+ (primary) | Oracle 19c+ and MySQL 8.0+ also supported |
| Frontend | React 18 + TypeScript + Vite | |
| State | Zustand | Minimal, co-located |
| Rich Text | TipTap | Document editing |
| Charts | Recharts | Dashboards and SPC |
| Background | Celery + Redis | All async work |
| Cache | Redis | Sessions, feature flags |
| Process | systemd + Gunicorn + Uvicorn | Bare metal |
| Web server | Nginx | TLS, reverse proxy |
| Migrations | Alembic | Multi-DB aware |
| Testing | pytest + pytest-asyncio | |
| Lint | Ruff + mypy | |

---

## 3. Complete Feature Set — All 30 Validation Disciplines

OpenVAL covers every validation discipline Kneat, ValGenesis, and SWARE cover.

### Core Validation Platform (CSV + CSA)
1. **Computer System Validation (CSV)** — Full IQ/OQ/PQ lifecycle
2. **Computer Software Assurance (CSA)** — FDA 2025 guidance, risk-based mode
3. **Equipment Validation** — DQ/IQ/OQ/PQ for equipment
4. **Analytical Instrument Validation (AIV)** — Calibration, qualification, maintenance
5. **Method / Analytical Method Validation (MAV)** — ICH Q2(R1) structured data

### Facility and Environmental
6. **Commissioning & Qualification (CQV)** — Packages, punch items, handover
7. **Facilities & Utilities Validation** — HVAC, WFI, purified water, compressed air
8. **Environmental Monitoring** — EM program, excursions, trending

### Manufacturing
9. **Process Validation (Stage 1/2/3)** — PPQ, CPV, design space
10. **Cleaning Validation** — MACO/ADE/LD50, swab/rinse sampling, CPK
11. **Sterilization Validation** — F0, bioburden, BIs, SAL
12. **Cold Chain / Temperature Mapping** — GDP, USP <659>, ICH Q1A

### Quality Management
13. **Change Control** — Full GMP change lifecycle
14. **CAPA Management** — Root cause, actions, effectiveness check
15. **Deviation / Nonconformance** — Inline capture during execution
16. **OOS/OOT Management** — Phase 1/2 investigation
17. **Complaint Management** — 21 CFR 211.198, MDR linkage
18. **Audit Management** — Internal, external, regulatory

### Lifecycle Management
19. **Periodic Review** — Scheduler, execution, revalidation triggers
20. **Technology Transfer** — Scale-up, site-to-site, product acquisition
21. **Validation Debt Tracking** — Backlog surfacing and prioritization

### Documentation
22. **Document Management** — Controlled documents, templates, approval routing
23. **Drawing / P&ID Management** — Walkdowns, version control
24. **Electronic Logbook Management** — Equipment, area, instrument, batch logs
25. **Electronic Batch Records (eBR)** — Linked to batch/lot module

### Traceability and Analytics
26. **Requirements Traceability Matrix (RTM)** — Real-time, auto-generated
27. **Statistical Process Control (SPC)** — Nelson/WE rules, Cp/Cpk
28. **Manufacturing Analytics** — CPP/CQA correlation, batch evolution

### Regulatory Programs
29. **Quality by Design (QbD)** — Design space, QTPP, control strategy
30. **Validation Master Plan (VMP)** — Corporate/site validation policy

---

## 4. Database Schema — 251 Tables

**Parts:**
- Part 1 (130 tables): Core — auth, audit trail, systems, protocols, documents, workflows, CAPA, change control
- Part 2 (0 tables): Indexes, sequences, RLS policies, seed data
- Part 3 (31 tables): Quality modules — OOS/OOT, EM, stability, batch/lot, complaints, inspection, SPC, AI
- Part 4 (4 tables): Open core license management
- Part 5 (33 tables): GxP validation workflows — projects, plans, sign-offs, pre-execution, witness, amendments, config baselines, lifecycle state machines
- Part 6 (16 tables): Gap closure — access reviews, DR tests, method validation, data migration, supplier controls, process engineering
- Part 7 (37 tables): All validation disciplines — logbooks, drawings, technology transfer, cleaning validation, cold chain, CQV, process validation, sterilization, reusable test cases, audit collections, VMP, CSA records, document annotations, validation debt, QbD

**Key design decisions:**
- All PKs are UUIDs
- All timestamps are UTC TIMESTAMPTZ (or UTC-normalized for MySQL)
- JSON fields stored as TEXT (compatible with all three DBs)
- Audit trail: append-only enforced at DB layer (PostgreSQL RLS, Oracle VPD, MySQL user permissions)
- SHA-256 hash chain for tamper detection across all databases
- No raw SQL in application code — SQLAlchemy ORM throughout

---

## 5. Phase Plan — 26 Phases

**Duration:** Approximately 36 months from Phase 0 start
**Editions:** Phases 0-20 build CE. Phases 21+ build EE features.

---

### Phase 0: Foundation and SDL (Months 1-2)

**Goal:** A production-grade foundation that passes a regulatory inspection
on day one. Compliance architecture correct before a single feature is built.

**Infrastructure:**
- [ ] GitHub repository with branch protection (main, develop, release/*)
- [ ] CONTRIBUTING.md, PR template, issue templates
- [ ] CHANGELOG.md with audit-ready format (version, date, validation-impact classification)
- [ ] SDL-001 Software Development Lifecycle document (public, versioned)
- [ ] GitHub Actions CI: lint (Ruff), type check (mypy), tests (pytest) on every PR
- [ ] Semantic versioning with validation-impact classification per commit
- [ ] AGPL-3.0 LICENSE for CE, Commercial license for EE
- [ ] .gitignore, .editorconfig, pre-commit hooks (black, ruff, mypy)

**Backend Foundation:**
- [ ] FastAPI app factory with lifespan management and conditional EE module loading
- [ ] SQLAlchemy 2.0 async setup: multi-database engine factory (PostgreSQL primary, Oracle, MySQL)
- [ ] Alembic migrations configured for all three database dialects
- [ ] Database connection health checks on startup
- [ ] Base ORM model with UUID PK, created_at, updated_at, created_by, updated_by
- [ ] Settings management via pydantic-settings (loads from .env)
- [ ] GxP API flag middleware: add X-OpenVAL-GxP-Context header to all responses

**Audit Trail Engine (must be perfect — regulators inspect this):**
- [ ] SQLAlchemy `before_flush` event listener on every session
- [ ] Captures: table, record_id, action (INSERT/UPDATE/DELETE), old_value (JSON), new_value (JSON), user_id, timestamp (server-side, never client), IP address, user_agent, reason_code
- [ ] SHA-256 chain_hash: each audit record hashes its own content + previous hash
- [ ] Append-only enforcement: PostgreSQL RLS policy (no UPDATE/DELETE for app user)
- [ ] Oracle: VPD policy equivalent
- [ ] MySQL: app user has INSERT/SELECT only on audit_log and electronic_signatures
- [ ] Nightly Celery task: walk hash chain, detect tamper, alert on failure
- [ ] Sensitive fields masked (passwords, MFA secrets never logged)

**Electronic Signature Engine:**
- [ ] SignatureCapture service: re-authenticate credentials server-side at signing
- [ ] Signature record: user_id, meaning_code, signed_at (server timestamp), signed_record_type, signed_record_id, signed_record_hash (SHA-256 of record content at signing), manifested_reason, ip_address
- [ ] Signature linking: record is hashed at signing time; any post-signing modification is detectable
- [ ] Delegate signature support (21 CFR 11.200(b) biometric approach not supported in v1)
- [ ] Signature meanings seeded: AUTHORED, REVIEWED, APPROVED, EXECUTED, WITNESSED, VERIFIED, READ_CONFIRMED, CLOSED, QA_APPROVED, DELEGATED_APPROVED

**Authentication:**
- [ ] bcrypt password hashing (cost factor 12+)
- [ ] JWT access tokens (15 min) + refresh tokens (7 days, rotated on use, stored hashed)
- [ ] TOTP MFA (RFC 6238): setup, verification, 10 single-use backup codes (hashed)
- [ ] MFA required for signature actions (configurable to require for all actions)
- [ ] Account lockout: 5 failed attempts, 15-minute lockout
- [ ] Password history: last 12 passwords cannot be reused
- [ ] Concurrent session limit (configurable, default 3)
- [ ] Session idle timeout (30 min) and absolute timeout (8 hours), both configurable

**Seed Data:**
- [ ] Execute openval_schema_part1.sql through openval_schema_part7.sql
- [ ] Default system roles seeded: system_admin, qa_manager, qa_associate, validation_engineer, technical_reviewer, business_owner, read_only, auditor (read-only external)
- [ ] Default signature meanings seeded
- [ ] Lookup categories and values seeded (regulations, GAMP categories, risk matrices)
- [ ] Default lifecycle state machines seeded (protocols, documents, change requests, CAPAs)
- [ ] Default feature flags seeded (CE features enabled, EE features disabled)
- [ ] Module registry populated

**Tests (Phase 0 must be 100% green before Phase 1):**
- [ ] Audit trail test: every ORM write generates an audit_log record
- [ ] Audit trail tamper test: manually modify audit_log, verify nightly check detects it
- [ ] Signature test: valid credentials sign successfully; invalid reject with specific error
- [ ] Signature test: re-signing modifies signature hash; original record hash mismatch detected
- [ ] Authentication test: full login, token refresh, MFA flow
- [ ] Lockout test: 5 failed attempts triggers lockout
- [ ] Concurrent session test: 4th session rejected

---

### Phase 1: Core Data Layer (Months 2-3)

**Goal:** All ORM models defined and tested. Database works on PostgreSQL,
Oracle, and MySQL. Migrations run cleanly. Schema matches all 251 DDL tables.

- [ ] All 251 SQLAlchemy ORM models created (one file per domain)
- [ ] All Alembic migrations generated and tested against all three databases
- [ ] Oracle-specific: VPD policies for audit_log and electronic_signatures
- [ ] MySQL-specific: id_sequences table populated; sequence service implemented
- [ ] PostgreSQL-specific: RLS policies, pg_trgm extension, UUID-OSSP
- [ ] Repository pattern: base repository class with paginate, filter, get, create, update
- [ ] All FK relationships verified (no orphan references)
- [ ] All indexes created and verified
- [ ] Seed data scripts: create_admin.py, seed_database.py
- [ ] Integration tests: CRUD on every major table, verify audit trail fires

---

### Phase 2: Application Shell and Design System (Months 3-4)

**Goal:** Every authenticated page shares a single, consistent AppShell.
Navigation, breadcrumbs, status badges, and component library all established
before any module-specific pages are built.

**Design Tokens:**
```
Primary:     #00A090  (dark teal)  (deep regulatory blue — trust, authority)
Primary-Lt:    #2D6BB5
Primary-Dk:    #0F3060
Accent-Green:  #00875A  (pass, approved, active)
Warning:       #FF8B00  (amber — review pending, attention needed)
Danger:        #DE350B  (fail, critical, overdue)
Neutral-900:   #172B4D  (text primary)
Neutral-700:   #344563  (text secondary)
Neutral-500:   #5E6C84  (text tertiary, placeholders)
Neutral-200:   #DFE1E6  (borders, dividers)
Neutral-100:   #F4F5F7  (surface, sidebar background)
Neutral-000:   #FFFFFF  (card and content background)
EE-Gold:       #B8860B  (Enterprise feature indicators)
```

**AppShell:**
- [ ] Header (64px): logo, site name selector, global search, notification bell, user menu
- [ ] Sidebar (240px): grouped navigation with collapse, active state, EE lock icons
- [ ] Breadcrumb bar: always shows full path, clickable
- [ ] Content area: full responsive width
- [ ] Mobile-responsive layout (execution and approval flows work on tablet)

**Sidebar Navigation Groups:**

```
VALIDATION
  Dashboard (Overview)
  Validation Projects
  Validation Master Plan
  System Inventory
  Equipment Inventory
  Risk Assessments
  Requirements
  Protocols
  Test Executions
  Reusable Test Cases  ⭐ EE
  Traceability Matrix

QUALITY
  Change Control
  CAPA
  Nonconformances
  Deviations
  OOS / OOT           ⭐ EE
  Complaints          ⭐ EE
  Periodic Reviews

DOCUMENTS
  Document Library
  Templates
  Pending Approvals
  Drawings            ⭐ EE

OPERATIONS
  Equipment
  Electronic Logbooks  ⭐ EE
  Environmental Monitoring ⭐ EE
  Stability Studies   ⭐ EE
  Batch Management    ⭐ EE
  Vendors
  Audits
  Audit Collections   ⭐ EE
  Training

DISCIPLINES           ⭐ EE
  Cleaning Validation
  Cold Chain / Temp Mapping
  Commissioning & Qual
  Process Validation
  Sterilization
  Technology Transfer

WORKFLOWS
  My Tasks
  Workflow Builder
  Active Workflows

REPORTS & ANALYTICS
  Report Builder
  Dashboards
  Inspection Readiness ⭐ EE
  Validation Debt      ⭐ EE
  SPC Charts          ⭐ EE

ADMIN
  User Management
  Roles & Permissions
  Site Settings
  Integrations
  License & Edition
  Audit Log Viewer
  System Health
```

**Universal UI Components (built once, used everywhere):**
- [ ] AppShell (header + sidebar + content)
- [ ] PageHeader (title, subtitle, action buttons, breadcrumbs)
- [ ] DataTable (sortable, filterable, paginated, column config, bulk select, CSV export)
- [ ] StatusBadge (universal status chip with correct color per status)
- [ ] FilterBar (search + multi-filter dropdowns + date range)
- [ ] DetailPanel (right-side slide-in for record details — 50% screen)
- [ ] RecordCard (summary card for grid list views)
- [ ] FormField (label + input + validation + help text + required indicator)
- [ ] RichTextEditor (TipTap with pharma-appropriate formatting — no markdown, no code blocks)
- [ ] FileUpload (drag-drop, preview, type restrictions, size limit)
- [ ] TimelineView (audit trail, workflow history, comment thread)
- [ ] SignatureCapture (21 CFR Part 11 modal: re-auth + meaning + confirmation checkbox)
- [ ] AnnotationPanel (for document review: inline comment thread per section)
- [ ] ConfirmDialog (destructive action confirmation)
- [ ] ProgressTracker (protocol execution: step 4 of 27)
- [ ] SplitView (requirements with linked tests, or document with sections)
- [ ] ApprovalPanel (shows all required approvers, who signed, when, with meaning)
- [ ] DashboardWidget (pluggable metric card for dashboards)
- [ ] NotificationToast (success, warning, error, info — top-right stack)
- [ ] EmptyState (illustrated, module-specific empty state with CTA)
- [ ] LoadingSkeleton (matches shape of content being loaded)
- [ ] NavItemLocked (EE feature with lock icon and upgrade CTA)
- [ ] UpgradePage (shown when navigating to locked EE feature)
- [ ] ExecutionModePanel (full-screen execution UI, see Phase 6)

**React Application Foundation:**
- [ ] React 18 + TypeScript + Vite setup
- [ ] React Router 6 with route-level code splitting
- [ ] Zustand stores: auth, license, notifications, ui
- [ ] API client (Axios with interceptors for JWT refresh)
- [ ] Error boundary with user-friendly fallback
- [ ] Global error handling for network/API errors
- [ ] Feature detection hook: `useFeature('feature_code')`

---

### Phase 3: System and Equipment Inventory + Validation Wizard (Months 4-5)

**Goal:** System inventory that is the foundation of the entire validation
program. GAMP 5 classification. The Guided Validation Wizard that replaces
weeks of setup with minutes. Entity library foundation.

**System Inventory:**
- [ ] System list page (filterable by GAMP category, GxP impact, validated status)
- [ ] System detail page:
  - System info (name, version, vendor, purpose, GxP processes supported)
  - GAMP 5 classification with justification
  - GxP impact matrix (product quality, patient safety, data integrity — with scores)
  - Validation status widget (validated / in qualification / overdue review)
  - Linked validation project(s)
  - Linked protocols (IQ/OQ/PQ status summary)
  - Configuration baseline (current validated state)
  - Linked CSA assessment (if CSA mode)
  - Open change requests
  - Revalidation event history
  - Validation debt items for this system
  - Documents linked to this system
  - Access review history
  - System health log
- [ ] System environments (dev/test/production) with separate validation status
- [ ] System interfaces: what does it connect to?
- [ ] System data flows: what data flows in/out and to where?
- [ ] System component list (hardware, software, database, network)

**GAMP 5 Classification Wizard:**
- [ ] Step-by-step questions leading to GAMP category recommendation
- [ ] Shows regulatory citations explaining why each category applies
- [ ] User can override with documented justification
- [ ] GAMP categories: 1 (infrastructure), 3 (non-configured), 4 (configured), 5 (custom)
- [ ] Category determines default validation scope recommendation

**Guided Validation Wizard ("Fast Track" setup):**

This is the MasterControl "Validation on Demand" equivalent — one of the most
requested features by validation engineers who hate the setup overhead.

- [ ] **Step 1: System Classification** — GAMP wizard, regulation selector, impact areas
- [ ] **Step 2: Approach** — Full CSV vs CSA vs Hybrid; wizard recommends based on GAMP category
- [ ] **Step 3: Risk Assessment Scaffold** — Pre-populate risk items from template for system type
- [ ] **Step 4: Requirements Generation** — Generate URS skeleton from system type template
- [ ] **Step 5: Protocol Selection** — Recommend IQ/OQ/PQ or DQ/IQ/OQ/PQ from template library
- [ ] **Step 6: Team Assignment** — Assign validation lead, QA, technical owner, business owner
- [ ] **Step 7: Timeline Setup** — Set target dates for each protocol
- [ ] **Step 8: Summary** — Shows everything created, links to validation project dashboard
- [ ] Wizard creates: validation_project, validation_plan, risk_assessment scaffold, requirement_set shells, protocol stubs from selected templates
- [ ] Estimated completion: 15 minutes from zero to full project scaffold

**Validation Master Plan (VMP):**
- [ ] VMP structured editor (not just a document — fills structured fields)
- [ ] VMP system inventory embedded (auto-populates from system table)
- [ ] VMP approval with signatures
- [ ] VMP dashboard: % systems validated, regulatory status per system
- [ ] VMP version history

**CSA Mode Foundation (alongside CSV):**
- [ ] System detail: toggle CSA mode (with justification)
- [ ] CSA Assessment form: intended use items, risk level per feature/function
- [ ] Vendor documentation library: attach and accept vendor test evidence
- [ ] CSA assurance activities capture (not full test scripts — concise evidence records)
- [ ] Critical thinking documentation field (required for CSA — the "why")
- [ ] CSA vs CSV mode clearly labeled throughout UI
- [ ] Unscripted testing capture (description + result, no step-by-step required)

**Equipment Inventory:**
- [ ] Equipment list with calibration and maintenance status
- [ ] Equipment detail: specs, service history, calibration records, qualification status
- [ ] Calibration schedule and certificate tracking
- [ ] Maintenance schedule management
- [ ] Equipment-linked electronic logbook (Phase 15: full EE module)

---

### Phase 4: Risk Assessment (Months 5-6)

**Goal:** Full risk assessment engine covering FMEA (pharma/device), P×I
(probability × impact), ICH Q9 framework, and QbD risk linkage.

- [ ] Risk assessment list page (filter by system, type, status, overall risk level)
- [ ] Risk assessment detail with:
  - Header: assessment type, system, overall risk level, status
  - Risk items table with inline add/edit
  - Risk heat map visualization (Recharts scatter plot with quadrant coloring)
  - Residual risk summary after controls applied
  - Risk matrix editor (configurable per site: 3×3, 4×4, 5×5)
  - Approval section with signatures
  - Full audit trail
- [ ] FMEA entry: Hazard, Failure Mode, Effect on Patient/Product, Root Cause, Probability (1-5), Impact (1-5), Detectability (1-5), RPN, Controls, Residual Probability, Residual Impact, Residual RPN
- [ ] P×I entry (simpler than FMEA): Risk, Probability, Impact, Risk Score, Controls, Residual
- [ ] Risk matrix configuration (admin): custom P/I/D scales, custom scoring colors, custom thresholds
- [ ] Risk register view: all risk items across all systems, filterable, sortable
- [ ] CSA integration: risk items drive assurance approach selection (high risk → scripted testing required)
- [ ] QbD integration: CPP/CQA risk items link to QbD framework (Phase 20)
- [ ] Risk-to-requirement linking: risk items can require specific URS requirements
- [ ] Risk-to-test-step linking: risk items can require specific test steps in protocols
- [ ] Export to Excel (standard format for offline review)
- [ ] Risk assessment version comparison (what changed between v1.0 and v2.0?)
- [ ] RPN trend chart (is risk going up or down over time?)

---

### Phase 5: Requirements Management (Months 6-7)

**Goal:** Full URS/FS/DS/CS lifecycle with hierarchy, linking, review sign-off,
and bidirectional traceability to test steps.

- [ ] Requirement set list page (grouped by system and type: URS/FS/DS/CS)
- [ ] Requirement set detail:
  - Requirements tree (numbered hierarchy: 1.0, 1.1, 1.1.1)
  - Inline add, edit, reorder, nest
  - Status filter (draft, approved, not-tested, tested-pass, tested-fail)
  - Test coverage % indicator per section
  - Import from CSV/Excel (template provided)
- [ ] Rich text requirement editor (format: title + acceptance criteria + notes + regulatory citation)
- [ ] Requirement type: functional, regulatory, performance, interface, security, data_integrity, audit_trail
- [ ] Requirement links: parent-child within set, cross-set (URS → FS → DS)
- [ ] Requirement set approval workflow (sequential or parallel reviewers)
- [ ] Per-reviewer sign-off with inline comments on individual requirements
- [ ] Comment resolution tracking (reviewer raises comment → author responds → resolved)
- [ ] Requirement set version management with version comparison
- [ ] Export: Excel (numbered hierarchy) and PDF (controlled copy format)
- [ ] Traceability preview panel: shows which test steps cover each requirement

---

### Phase 6: Protocol Builder and Test Execution Engine (Months 7-9)

**Goal:** The heart of the system. This is what Kneat users pay for.
Protocols that are better than paper: collaborative authoring, annotation
during review, step-by-step execution exactly like Kneat, inline deviation
capture, tabular data entry, witness support, test case library.

**Protocol Builder:**
- [ ] Protocol list page (filter by type, system, status, assignee)
- [ ] Protocol builder — split view:
  - Left panel: section/step outline with drag-to-reorder
  - Right panel: editor for selected section/step
  - Section add/remove/reorder/nest (sub-sections supported)
  - Step type selection:
    - **action** — do this thing
    - **check** — verify this condition (pass/fail)
    - **data_entry** — enter a specific value (numeric with range, text, date, dropdown)
    - **data_table** — enter multiple rows of values (tabular data)
    - **observation** — record what you observe (free text)
    - **screenshot** — capture screen evidence
    - **signature** — explicit signature step (in addition to section-level signatures)
    - **reference** — link to a document or external reference (no action required)
    - **calculation** — computed value from other step inputs
  - Expected result with rich text
  - Acceptance criteria with tolerance/range for numeric types
  - Requirement linking per step (multi-select from linked URS)
  - Regulatory citation per step
  - Conditional steps (step only required if a previous answer = certain value)
  - Step-level notes (additional guidance for executor)
  - Insert test case from reusable library (Phase 3 foundation used here)
- [ ] Section group templates: reusable section groups that can be inserted
- [ ] Protocol header: system, protocol type (IQ/OQ/PQ/UAT/MAV/DQ/SAT/FAT/RETRO/CQV), objective, scope, prerequisites, hardware/software/personnel requirements, references, acceptance criteria, approvals block
- [ ] Protocol version management: major (requires re-approval) vs minor (admin only)
- [ ] Protocol version comparison: side-by-side diff of any two versions
- [ ] Protocol approval workflow: sequential reviewers with per-section annotation
- [ ] Protocol template library: select template → fill system info → protocol created
- [ ] Protocol clone: copy an existing protocol for a similar system

**Document Annotation and Redlining (during protocol review):**
- [ ] During review, each reviewer can:
  - Highlight text and add a comment
  - Propose a redline (show tracked change: strikethrough old, underline new)
  - Ask a question on a specific section or step
  - Mark a concern (raises the severity of the annotation)
- [ ] Author sees all annotations from all reviewers in a side panel
- [ ] Author responds to each annotation, marks it resolved
- [ ] Resolved annotations are kept in history (audit trail of review process)
- [ ] Unresolved critical annotations block the approval action (configurable)

**Test Case Reusable Library:**
- [ ] Test case library: browse, search, filter by category and applicable system type
- [ ] Test case template detail: steps, acceptance criteria, applicable protocol types
- [ ] "Insert from Library" button in protocol builder: select template → steps appear in protocol
- [ ] Usage tracking: how many protocols use this test case
- [ ] Template version management: when template updates, linked protocols are flagged
- [ ] Site-level and global templates (EE: global templates shared across sites)

**Pre-Execution Checklist Builder:**
- [ ] Per-protocol configurable pre-execution checklist
- [ ] Default checklist items generated based on protocol type and system GAMP category
- [ ] Admin can add custom checklist items
- [ ] Items categorized: personnel, environment, equipment, documentation, system_state

**Test Execution Engine:**
- [ ] Execution creation: select protocol + environment → creates execution record
- [ ] Pre-execution checklist: must confirm all mandatory items before first step
- [ ] **Execution view** (full-screen, optimized for step-by-step):
  - Left panel: step outline with status indicators (not started / in progress / pass / fail / deviation / N/A)
  - Main area: current step
    - Step number, title, type indicator
    - Action text (rich formatted)
    - Expected result
    - **Result entry** (type-appropriate):
      - Pass/Fail/N-A buttons for check steps
      - Text area for observation/action steps
      - Numeric input with range validation for data_entry steps
      - Table grid for data_table steps (add rows, enter values, auto-compute stats)
      - Screenshot/file attach zone (drag-drop, annotate image)
      - Calculation display (auto-computed from previous step values)
    - **Deviation button**: open inline deviation capture without leaving step
    - **Witness button**: request witness signature for this step
    - **Annotation button**: view any review annotations on this step
    - **Notes field**: executor notes (not part of official result)
    - Elapsed time display (per step and overall)
  - Navigation: previous/next step buttons, keyboard shortcuts
  - Progress bar: steps completed / total, with color coding by result
  - Session controls: save draft, pause execution (with reason), complete execution
- [ ] **Inline Deviation Capture** (modal, does not break execution flow):
  - Type (process / system / documentation / specification)
  - Severity (critical / major / minor)
  - Description of what was observed vs expected
  - Impact on step result (can this step still pass? yes/no/need QA decision)
  - Immediate action taken
  - Linked to the specific step automatically
  - QA review assignment
  - Optionally auto-creates CAPA (configurable by deviation type)
- [ ] **Witness Log**: request witness for any step → witness receives notification → enters credentials + signature → logged
- [ ] **Pause/Resume**: document pause reason, last completed step; resume by re-authenticating
- [ ] **Script Execution**: for automated/scripted tests, display script → capture script output as evidence → pass/fail the step
- [ ] **CSA Unscripted Testing**: capture a free-form exploration session with summary result (not step-by-step)
- [ ] **Video-to-Script** (Phase 22 AI): record screen activity → AI generates test script suggestion
- [ ] Execution summary page (after completion):
  - Results by section: counts of pass/fail/deviation/N-A
  - Deviation list with severity
  - Open items list
  - Overall result indicator
  - Time taken
  - Next steps (submit for QA review)
- [ ] **Execution report generation** (PDF): all steps, actual results, attachments, witness signatures, deviations, amendments, signatures — in a format that would satisfy an FDA inspector
- [ ] Protocol amendments: change a step mid-execution → amendment workflow → signed → applied → logged
- [ ] Re-execution workflow: protocol fails → investigate → create amendment or new execution → re-run

---

### Phase 7: Document Management (Months 9-11)

**Goal:** Controlled document management as good as MasterControl. Documents
move through authoring, review, approval, distribution, and periodic review
with full traceability.

- [ ] Document library: folder tree (configurable) + document list
- [ ] Document types: SOP, Policy, Specification, Work Instruction, Form, Report, Template, External Document
- [ ] Document detail page:
  - Current version content (rendered from stored content)
  - Version history with comparison
  - Approval record (who approved, when, with meaning)
  - Distribution record (who received, who confirmed read)
  - Linked systems, protocols, change records
  - Annotations and redline history
  - Linked documents (replaced by, related to)
- [ ] Document editor (TipTap full-screen):
  - Section-based editing (not one big blob)
  - Variable placeholder insertion (from template variables)
  - Image and table insertion
  - Regulatory citation insertion
  - Lock sections (admin locks, others read-only)
  - Character count per section
- [ ] Template engine:
  - Template library browser with category filter
  - Template variable definition: name, type (text/date/number/dropdown), required/optional, help text
  - "Create from template" flow: fill variables → document created with values substituted
  - Template editor (admin): design template with variable placeholders
- [ ] Document version comparison (side-by-side diff — stored computed diff, fast to display)
- [ ] Annotation and redline review (same system as Phase 6 but for documents)
- [ ] Document approval workflow:
  - Configurable stages (technical review → QA review → approval)
  - Concurrent or sequential reviewer assignment
  - Per-section annotations during review
  - SLA tracking with escalation
  - Reject with reason → back to author with comments intact
- [ ] Document distribution:
  - Assign distribution groups (all users in role X at site Y)
  - Read confirmation requirement (must confirm within N days)
  - Auto-remind for pending reads
  - Training assignment trigger: when document approved → assign training (Phase 8 automation)
- [ ] Document search: full-text across all document content, title, ref number, tags
- [ ] PDF export: with site header/footer, document control number, "CONTROLLED COPY" watermark
- [ ] Controlled copy printing: number each copy, log who printed what when

---

### Phase 8: Low-Code Workflow Engine + Automation Rules (Months 11-13)

**Goal:** Visual workflow builder that non-developers use to define approval
processes. Closed-loop automation that connects modules.

**Workflow Builder (CE: up to 5 stages; EE: unlimited):**
- [ ] Workflow definition list page
- [ ] Visual workflow builder:
  - Stage canvas (drag to add stages, draw connections)
  - Stage configuration panel:
    - Stage type: approval, review, information, signature, form_entry, parallel_group
    - Assignee: specific user, role, department, or dynamic (field value lookup)
    - SLA hours with escalation path
    - Signature requirement and meaning
    - Embedded form (for additional data capture in the stage)
    - Instructions for assignee
    - Rejection routing (which stage if rejected)
    - Conditional routing (EE: if field X = Y, go to stage Z)
  - Trigger configuration: which module, which event, which conditions
  - Preview mode: trace a simulated record through the workflow
- [ ] My Tasks page: all workflow tasks assigned to current user
- [ ] Task action panel:
  - Preview the record being approved (inline, not separate window)
  - Action buttons: Approve (with signature) / Reject with comment / Request more info / Delegate
  - Comment field (mandatory on rejection)
- [ ] Workflow history timeline: every action on every workflow instance
- [ ] SLA monitoring: Celery task every 15 minutes checks overdue stages
- [ ] Escalation: when stage SLA breached → notify escalation target
- [ ] Workflow definition versioning: changes logged, in-flight instances use version they were started on

**Closed-Loop Automation Rules (EE in Phase 8, CE basic version):**
- [ ] Automation rules builder (admin): trigger → conditions → action
- [ ] Standard triggers:
  - Document approved and effective → assign training to required roles
  - Deviation raised severity=critical → create CAPA automatically
  - CAPA effectiveness check failed → re-open CAPA
  - Change request approved with testing_required=true → create UAT task
  - OOS result recorded → create investigation, notify lab supervisor
  - Periodic review overdue → escalate to QA manager
  - System validated_status changes → update VMP summary
  - Equipment calibration_due within 30 days → create calibration task
- [ ] Rule execution log: every rule that fired, what it created, any errors
- [ ] Rule simulation mode: test a rule without creating real records

---

### Phase 9: Change Control (Months 13-14)

**Goal:** Full GMP change control lifecycle. Every change to a validated system
goes through this process.

- [ ] Change request list page: Kanban view + table view
- [ ] Change request types: planned, emergency, administrative, retrospective
- [ ] Change request form with dynamic sections based on type
- [ ] Impact assessment wizard (guided):
  - Is this a GxP-relevant change?
  - Which validated systems are affected?
  - Which documents require update?
  - Is revalidation required? (GAMP 5 criteria)
  - Is testing required? What scope?
  - Is training required?
  - What is the rollback plan?
- [ ] Change task board: implementation tasks assigned to team members
- [ ] Verification and closure: evidence that change was implemented as planned
- [ ] Emergency change path: abbreviated workflow with retrospective documentation
- [ ] Change request → revalidation trigger: when approved, auto-create revalidation_event record
- [ ] Change request → validation debt: if change was applied without revalidation, auto-create debt item
- [ ] Integration hooks: TrackWise change sync (EE Phase 18)
- [ ] Change control metrics: cycle time, open by category, emergency ratio

---

### Phase 10: CAPA, Nonconformance, OOS/OOT, Complaints (Months 14-17)

**Goal:** Complete quality event management. These modules are deeply
interconnected — everything feeds everything else.

**CAPA Management:**
- [ ] CAPA list with status filters, overdue highlighting, and severity indicators
- [ ] CAPA detail:
  - Problem statement (what went wrong, what is the evidence)
  - Source linking (deviation / NC / audit finding / complaint / OOS / trend)
  - Immediate actions taken (containment)
  - Root cause analysis tool (5 Whys builder + Fishbone diagram builder)
  - Root cause category: People / Process / Equipment / Materials / Environment / Measurement
  - Action plan: tasks with owner, target date, evidence required
  - Effectiveness check: scheduled date, method, criteria, result
  - Closure with signature
- [ ] CAPA metrics: open by root cause category, cycle time, overdue aging
- [ ] Regulatory reporting flag (if CAPA relates to reportable issue)
- [ ] AI suggestion panel (Phase 22): root cause suggestions, similar CAPAs, action effectiveness predictor

**Nonconformance (NCE):**
- [ ] NCE list and detail pages
- [ ] NC types: system_outage, data_integrity, procedure_deviation, access_control, backup_failure, vendor, out_of_calibration, environmental_exceedance
- [ ] Investigation module with 5 Whys
- [ ] Disposition: acceptable, not_acceptable, requires_capa
- [ ] Bidirectional linking: NC → CAPA → Change → Protocol

**OOS/OOT Management (EE):**
- [ ] OOS/OOT record creation (manual entry or LIMS webhook)
- [ ] **Phase 1 Investigation** screen:
  - Lab error assessment checklist (pipetting error? dilution error? calculation error?)
  - Lab error found: invalidate result, document reason, schedule retest
  - No lab error found: escalate to Phase 2
  - Retest record capture (up to 3 retests)
- [ ] **Phase 2 Investigation** screen:
  - Full investigation with root cause
  - Lot/batch impact assessment
  - Disposition options: reject, pass with justification, retest
  - CAPA creation if required
- [ ] OOT control limit configuration per test/product
- [ ] OOT trend detection (uses SPC module when available)
- [ ] Investigation report generation (PDF: complete investigation record)
- [ ] OOS rate trending dashboard

**Complaint Management (EE):**
- [ ] Complaint intake: receipt method, complainant type, product, lot
- [ ] Triage: reportability determination, severity assessment
- [ ] Investigation with lot disposition and LIMS test linkage
- [ ] Response tracking (required response within X days configurable)
- [ ] Regulatory reporting: MDR flag, field safety, NDA supplement
- [ ] CAPA linkage
- [ ] Complaint metrics by type, product, severity, cycle time

---

### Phase 11: Periodic Review (Months 17-18)

- [ ] Periodic review schedule management (per system, per document, per equipment, per vendor)
- [ ] Review calendar (all upcoming reviews by type, with traffic light indicators)
- [ ] Review execution page:
  - Auto-populated review items (changes since last review, deviations, NCEs, open CAPAs, training gaps, calibration status, software version changes)
  - Finding capture per item
  - Outcome: continue_as_is / requires_update / revalidation_required / decommission
  - Signature and approval
- [ ] Review report generation (PDF — suitable for regulatory inspection)
- [ ] Overdue review alerts (Celery task daily)
- [ ] Revalidation trigger: if outcome = revalidation_required → create revalidation_event → link to change request

---

### Phase 12: Traceability Matrix (Months 18-19)

**Goal:** The RTM is what auditors and inspectors demand to see.
It must be automatic, real-time, and impossible to fake.

- [ ] Traceability link management: requirement ↔ protocol section ↔ test step (bulk import from protocol builder)
- [ ] **RTM live view** (the showpiece feature):
  - Rows: requirements (numbered, hierarchical)
  - Columns: test steps (grouped by protocol)
  - Cells: PASS / FAIL / NOT_TESTED / DEVIATION (color coded)
  - Updates automatically as executions are completed
  - Filter by protocol type, execution status, result
  - Click any cell to navigate to the actual step execution
- [ ] Coverage calculator: % requirements with at least one passing test step
- [ ] Gap analysis: requirements with zero test coverage
- [ ] RTM snapshot: generate a signed snapshot with approval (for validation package)
- [ ] RTM export: Excel (all data) and PDF (formatted for inspection)
- [ ] Cross-system RTM: view requirements across multiple related systems

---

### Phase 13: Reports, Dashboards, and Business Intelligence (Months 19-20)

- [ ] Standard report library (15+ pre-built reports):
  - System compliance status (all systems, validated/in-progress/overdue)
  - Periodic review overdue
  - CAPA aging
  - Deviation trend by severity and system
  - Training compliance matrix
  - Audit trail export (21 CFR Part 11 formatted)
  - Change control pipeline
  - OOS rate by test type and time period
  - Inspection readiness summary (EE)
  - Validation debt inventory (EE)
- [ ] Report builder (EE): drag-and-drop field selection, filters, grouping, chart types
- [ ] Scheduled reports (EE): configure report → deliver to email/Teams/Slack on schedule
- [ ] **Executive Dashboard**: KPI cards — % systems validated, open CAPAs, overdue reviews, pending signatures, new deviations 30d
- [ ] **QA Dashboard**: deviations by severity (bar), CAPA status (donut), change control pipeline (Kanban summary), inspection readiness score
- [ ] **Validation Engineer Dashboard**: protocol execution status by system, upcoming revalidations, open deviations, active amendments
- [ ] **System Health Dashboard**: audit chain status, service uptime, database size, active users, recent errors
- [ ] Dashboard widget library (pluggable): any metric can be a dashboard widget
- [ ] User-configurable dashboard layout (drag to arrange widgets)

---

### Phase 14: Vendor, Audit, and Inspection Readiness (Months 20-22)

**Vendor Management:**
- [ ] Vendor directory with qualification status, contact info, material/service catalog
- [ ] Approved Supplier List management (21 CFR 820.50 / 211.84)
- [ ] Vendor qualification workflow (questionnaire → audit → approval)
- [ ] Supplier performance records (annual review)
- [ ] Vendor audit scheduling with findings management
- [ ] Audit findings → CAPA linkage

**Audit Management:**
- [ ] Internal audit management (schedule, execute, findings, responses)
- [ ] External audit management (customer, regulatory body)
- [ ] Audit finding response tracking with due dates
- [ ] FDA 483 observation tracker (post-inspection response management)
- [ ] Audit calendar with advance preparation checklists

**Inspection Readiness Module (EE):**
- [ ] **Real-time compliance scorecard** (auto-computed, refreshed on every write):
  - Systems with expired validation
  - Systems with overdue periodic review
  - Open CAPA actions (count + aging)
  - Training gaps (% of users out of compliance)
  - Open deviations (by severity)
  - Documents overdue for review
  - Open OOS/OOT investigations (EE)
  - Equipment calibration overdue
  - Access reviews overdue (21 CFR 11.10(d))
  - Open audit findings
  - Open change requests with regulatory impact
- [ ] **Inspection simulation**:
  - Select framework (FDA GMP 21 CFR 211, FDA GLP, FDA CSV, EMA GMP, ISO 13485)
  - System generates list of records the inspector would likely request
  - Gap highlights: records with missing evidence or incomplete fields
  - Export as pre-inspection report (PDF)
- [ ] **Mock inspection checklists** aligned to FDA 483 common observations
- [ ] **Audit Collections / War Rooms** (EE):
  - Create a collection for a specific inspection or audit
  - Add approved documents, execution records, CAPAs, change records
  - Documents staged as read-only copies
  - Generate an auditor access code (time-limited, read-only, no authentication required for auditor)
  - All auditor views logged (collection_access_log)
  - Virtual "war room" accessible from anywhere
  - Supports remote inspections
- [ ] **Active Inspection Management**:
  - Log inspection: agency, dates, inspector names, scope
  - Track document requests and responses in real time
  - Verbal commitment capture
  - Post-inspection finding → formal audit finding creation

---

### Phase 15: Training, EM, Stability, Batch, Logbooks, Technology Transfer (Months 22-25)

**This phase is the largest. Three months minimum.**

**Training Records:**
- [ ] Training requirement configuration (linked to documents, roles, systems)
- [ ] Auto-assign training when document approved and effective (automation rule)
- [ ] Training assignment management with due dates and reminders
- [ ] Training completion with signature (user confirms they read and understood)
- [ ] Training compliance matrix (users × required trainings × status)
- [ ] Training expiry tracking and auto-renewal assignment
- [ ] Competency assessment support (pass/fail quiz after training)

**Electronic Logbook Management (EE):**
- [ ] Logbook catalog: create logbooks for equipment, areas, instruments, batches
- [ ] Logbook entry screen: date/time, type, performer, structured fields, attachments
- [ ] Correction workflow: new entry corrects old entry (never delete/overwrite)
- [ ] Correction requires reason (21 CFR 11.10(k))
- [ ] Sign-off workflow: QA reviews and signs completed sessions
- [ ] Logbook search: full-text across all entries
- [ ] Logbook export (PDF/CSV) for inspection
- [ ] Logbook linking to equipment, protocols, deviations

**Environmental Monitoring (EE):**
- [ ] EM location and sample point configuration (ISO class, EU GMP grade, limits)
- [ ] Session scheduling (calendar view, upcoming sessions highlighted)
- [ ] Session execution screen: step through sample points, enter results
- [ ] Auto-excursion creation when result exceeds alert or action limit
- [ ] Excursion investigation and CAPA linkage
- [ ] Organism identification capture
- [ ] Monthly EM summary report
- [ ] EM trending (SPC charts in Phase 21)

**Stability Studies (EE):**
- [ ] Study setup (product, batch numbers, storage conditions, ICH basis)
- [ ] Time point configuration and pull date calendar
- [ ] Result entry per time point and test
- [ ] OOS auto-link if stability result fails
- [ ] Trending charts (parameter vs time, multi-batch overlay)
- [ ] Stability summary report

**Batch and Lot Management (EE):**
- [ ] Batch creation (product, batch number, manufacture date, type)
- [ ] Test request assignment (QC tests required for this batch)
- [ ] Hold management with reason and notification
- [ ] Lot release workflow with QA signature
- [ ] Certificate of Analysis (CoA) generation and approval
- [ ] CoA version history and distribution

**Technology Transfer (EE):**
- [ ] Transfer project creation (type, sending/receiving site, product, team)
- [ ] Transfer item checklist (formulation, method, process, equipment, SOP, regulatory)
- [ ] Progress tracking per item with due dates
- [ ] Document linkage (each item links to the document or protocol)
- [ ] Technology transfer report generation

---

### Phase 16: Validation Package for OpenVAL Itself (Months 25-26)

**Goal:** OpenVAL ships with its own validation package. This is the ultimate
credibility statement: we trust this platform enough to validate itself with it.

**Documents to author** (in docs/validation_package/):
- [ ] VP-001: Software Description (what OpenVAL is, what it does, how it is classified)
- [ ] VP-002: GAMP 5 Category Assessment (Category 4, configured product, with justification)
- [ ] VP-003: Software Development Lifecycle (references SDL-001, public in repo)
- [ ] VP-004: User Requirements Specification for OpenVAL (what users need from it)
- [ ] VP-005: Risk Assessment FMEA (risks of the system, controls)
- [ ] VP-006: Validation Plan (scope, approach, exclusions, team, schedule)
- [ ] VP-007: Installation Qualification (IQ) Protocol — Ubuntu/RHEL specific
- [ ] VP-008: Operational Qualification (OQ) Protocol — all core functions
- [ ] VP-009: Performance Qualification (PQ) Protocol — end-to-end GxP scenarios
- [ ] VP-010: CSA Assessment Template (for sites adopting CSA mode)
- [ ] VP-011: Traceability Matrix (URS → Risk → OQ/PQ steps)
- [ ] VP-012: Validation Summary Report template
- [ ] VP-013: Periodic Review SOP template
- [ ] VP-014: Change Control SOP for OpenVAL upgrades (when and how to revalidate)
- [ ] VP-015: EE Feature Addendum (for sites licensing EE features)

---

### Phase 17: Pharma Template Library (Months 26-27)

**Goal:** Ship a library that covers every common validation scenario.
Users should be able to go from zero to executing a protocol in under an hour
for any of these scenarios.

**Protocol Templates (IQ/OQ/PQ for each):**
- [ ] LIMS (generic) — IQ, OQ, PQ
- [ ] HPLC / Chromatography Data System — IQ, OQ
- [ ] Infrastructure server (Windows/Linux) — IQ, OQ
- [ ] Network infrastructure — IQ, OQ
- [ ] Laboratory instrument (general) — IQ, OQ, PQ
- [ ] ERP system (general) — UAT, CSV
- [ ] MES system (general) — UAT, CSV
- [ ] QMS system (general) — UAT, CSV
- [ ] CSV: Retrospective assessment template
- [ ] DQ: Design qualification template
- [ ] CSA: Intended Use Assessment template
- [ ] MAV: Method validation template (ICH Q2(R1) aligned)
- [ ] Equipment qualification: balance, pH meter, autoclave, incubator
- [ ] CQV: Commissioning and qualification package template

**Document Templates:**
- [ ] SOP: Computer System Validation Procedure
- [ ] SOP: Computer Software Assurance Procedure
- [ ] SOP: Electronic Records and Signatures
- [ ] SOP: Change Control for Validated Systems
- [ ] SOP: Periodic Review of Validated Systems
- [ ] SOP: Data Integrity and ALCOA+ Requirements
- [ ] SOP: User Access Management and Periodic Review
- [ ] SOP: Backup, Restoration, and Disaster Recovery
- [ ] SOP: Audit Trail Review
- [ ] Policy: GxP Computerized System Policy
- [ ] Policy: Data Governance
- [ ] Template: Risk Assessment (FMEA)
- [ ] Template: Validation Plan
- [ ] Template: Validation Summary Report
- [ ] Template: Validation Master Plan

---

### Phase 18: Administration, Integrations, and Multi-Site (Months 27-29)

**Identity:**
- [ ] LDAP/Active Directory sync (user import + group-to-role mapping)
- [ ] SAML 2.0 / OIDC SSO (Azure AD, Okta, ADFS) (EE)
- [ ] SCIM user provisioning (EE)
- [ ] IP address allowlist (EE)

**Integrations (EE):**
- [ ] LabWare LIMS bidirectional integration (EM excursion webhook, OOS webhook, system sync)
- [ ] TrackWise change/CAPA sync
- [ ] SAP/Oracle equipment master sync
- [ ] Tempo MES batch event integration
- [ ] Microsoft Teams notification channel
- [ ] Slack notification channel
- [ ] Outbound webhook framework (any event → any endpoint)
- [ ] Integration health monitoring dashboard

**Cross-Site Enterprise (EE):**
- [ ] Corporate document publishing (source site → all sites as controlled copies)
- [ ] Cross-site compliance dashboard (executive view)
- [ ] Organization-level settings with site override
- [ ] Harmonized lookup tables (corporate-managed values)
- [ ] Cross-site user access review
- [ ] Network-wide VMP dashboard

**Administration:**
- [ ] REST API documentation (auto-generated, Swagger/ReDoc)
- [ ] API key management
- [ ] System health monitoring page
- [ ] Backup management UI (trigger, verify, restore)
- [ ] Upgrade management (version check, migration notes, revalidation impact)
- [ ] License management page (EE feature status, expiry, renewal)

---

### Phase 19: Specialized Validation Disciplines (Months 29-31)

**Cleaning Validation (EE):**
- [ ] Study setup: method, cleaning agent, equipment grouping, worst-case basis
- [ ] Acceptance limit calculator: MACO, ADE/PDE, LD50, 10 ppm (selectable, formula shown)
- [ ] Sampling plan builder: sample points, type (swab/rinse/placebo), locations
- [ ] Result entry per run with automatic limit comparison
- [ ] Recovery factor application
- [ ] OOS auto-link if result fails limit
- [ ] Run-to-run variability (RSD) calculation
- [ ] Cleaning validation summary report (PDF)
- [ ] Lifecycle review trigger (revalidation if product mix changes)

**Cold Chain / Temperature Mapping (EE):**
- [ ] Study setup: equipment, temperature range, sensor count, duration
- [ ] Sensor data import (CSV from data loggers, direct API for IoT sensors)
- [ ] Temperature mapping visualization (heat map of chamber — hotspots/coldspots)
- [ ] Excursion auto-detection and excursion record creation
- [ ] Statistical summary: mean, std dev, min, max per sensor
- [ ] Mapping report (PDF): sensor placement diagram, statistical table, pass/fail
- [ ] Cold chain excursion investigation with product disposition

**Commissioning & Qualification (CQV) (EE):**
- [ ] CQV project management with CQV-specific milestones
- [ ] Commissioning package creation and management
- [ ] Package item checklist (protocols, drawings, calibration certs, vendor docs)
- [ ] Punch item tracker (Category A/B/C with handover blocking)
- [ ] P&ID walkdown execution (linked to drawing module)
- [ ] Paperless handover: accept handover package with signature
- [ ] Commissioning → qualification transition (all punch items resolved)

**Drawing Management (EE):**
- [ ] Drawing catalog: number, title, type (P&ID, PFD, isometric), revision, status
- [ ] Drawing version control with supersession tracking
- [ ] Drawing viewer (PDF/SVG rendered in-browser)
- [ ] P&ID walkdown execution linked to drawing
- [ ] Walkdown item capture: tag number, expected vs actual state, redline note, photo
- [ ] Drawing markup export (PDF with walkdown results overlaid)
- [ ] Drawing-to-equipment linkage (drawing shows which equipment items)

**Process Validation (EE):**
- [ ] Stage 1: Design — CPPs/CQAs, design space, control strategy, risk assessment link
- [ ] Stage 2: PPQ — batch registration, acceptance criteria, protocol link
- [ ] PPQ batch tracking (manufacture 3+ batches, all criteria met)
- [ ] Stage 3: CPV — monitoring plan, annual product review, SPC chart link
- [ ] Process validation summary report

**Sterilization Validation (EE):**
- [ ] Sterilization study setup (method, product, organism, SAL target)
- [ ] Cycle record entry (F0 for steam, dose for radiation, gas concentration for EtO)
- [ ] Biological indicator results
- [ ] F0 calculation (for steam): enter thermocouple data → auto-compute F0
- [ ] SAL assessment: bioburden × D-value comparison
- [ ] Sterilization validation report

---

### Phase 20: Security Hardening and Docker Option (Months 31-32)

**Security Hardening:**
- [ ] External penetration test (engage third-party, remediate findings)
- [ ] OWASP Top 10 audit and remediation
- [ ] SQL injection hardening audit (parameterized queries everywhere — verify with Ruff rule)
- [ ] XSS audit: CSP headers, output encoding, TipTap content sanitization
- [ ] CSRF audit: SameSite cookies, double-submit pattern
- [ ] Rate limiting: login endpoint (10/min), API endpoints (60/min default, configurable)
- [ ] File upload security: extension whitelist, magic bytes validation, virus scan hook
- [ ] Session hardening: absolute timeout, idle timeout, concurrent session enforcement
- [ ] Encryption audit: all sensitive fields AES-256 encrypted at application layer
- [ ] Database performance profiling: slow query analysis, index optimization

**Docker Option:**
- [ ] docker-compose.yml for development (hot reload, no production configs)
- [ ] Docker Compose production configuration
- [ ] Dockerfile for backend and frontend
- [ ] Docker Hub publishing pipeline (CE image only)
- [ ] Container security scanning (Trivy or equivalent)

**Community Launch:**
- [ ] Community documentation site
- [ ] Contributing guide (GxP-aware — CONTRIBUTING.md already exists, expand)
- [ ] Code of conduct
- [ ] v1.0.0 release with complete CHANGELOG
- [ ] Announce to PDA, ISPE, pharma CSV community

---

### Phase 21: SPC and Manufacturing Analytics (Months 32-34) — EE

- [ ] SPC chart builder (data source, chart type, parameters)
- [ ] Control limit calculation from historical data
- [ ] Nelson rules + Western Electric rules engine
- [ ] Out-of-control event list with OOT auto-creation
- [ ] SPC dashboard with status indicators for all active charts
- [ ] Process parameter ingestion (REST API + file drop)
- [ ] Real-time parameter monitoring dashboard
- [ ] Batch evolution charts
- [ ] Batch-to-batch comparison charts
- [ ] CPP/CQA correlation analysis
- [ ] Process capability indices (Cp, Cpk, Pp, Ppk)
- [ ] Batch analytics summary (auto-generate on batch completion)
- [ ] GxP/non-GxP boundary labeling (DCP-inspired pattern)

---

### Phase 22: AI Assistance Phase 1 + Governance (Months 34-36) — EE

**AI Governance (required before any AI features go live):**
- [ ] AI model registry (name, version, validation status, deployment date)
- [ ] AI suggestion logging (every suggestion: type, content, confidence, accepted/rejected, user modification)
- [ ] AI transparency labeling: every record that AI assisted in creating shows an "AI Assisted" badge
- [ ] AI audit trail: AI actions appear in audit log attributed to the model version
- [ ] AI configuration per site (enable/disable features, confidence thresholds)
- [ ] Human-in-the-loop enforcement: AI never writes a record, it only suggests

**Document AI:**
- [ ] SOP draft assistant: title + scope → AI generates first draft in TipTap editor
- [ ] Regulatory gap checker: compare SOP against selected CFR section citation
- [ ] Similar document finder (before creating, shows existing documents with similar content)
- [ ] Cross-reference validator: flags references to superseded documents

**CAPA Intelligence:**
- [ ] Root cause suggestions: deviation description → top 3 root cause categories with reasoning
- [ ] Similar CAPA finder: shows historical CAPAs with similar problem statements and outcomes
- [ ] Action effectiveness predictor: this action type + root cause → predicted success rate
- [ ] Overdue risk scoring: CAPA at high risk of becoming overdue (complexity × assignee workload)

**Deviation Pattern Analysis:**
- [ ] Recurring deviation detector: same system + same type within 12 months → alert
- [ ] Cross-system pattern detector: site-wide pattern (same root cause across multiple systems)
- [ ] Severity trend alerting: deviation severity trending upward for a system

**Risk Item AI:**
- [ ] Risk item suggestions: system type + GAMP category → common risk items from template patterns
- [ ] Control effectiveness scoring: from natural language description → probability score suggestion
- [ ] CSA risk level suggestion: feature description → recommended CSA assurance approach

**Video-to-Script (SWARE-inspired):**
- [ ] Screen recording during system exploration
- [ ] AI processes recording → suggests a test script (action steps + expected results)
- [ ] User reviews and edits suggestion → saves as test case template in library
- [ ] Tagged as AI-generated in test case library

**Validation Debt AI:**
- [ ] Auto-detect debt items from database state (overdue reviews, unvalidated systems, gaps)
- [ ] AI prioritization: which debt items pose highest regulatory risk
- [ ] Remediation suggestions: recommended action to resolve each debt item

---

### Phase 23: AI Assistance Phase 2 (Months 36+) — EE

- [ ] Semantic search across all controlled documents (not keyword — meaning-based)
- [ ] Regulatory change impact analysis: given new FDA guidance → which SOPs need update
- [ ] Predictive quality event detection (leading indicators from trend data)
- [ ] Common 483 observation response library
- [ ] Data integrity risk scanner (anomaly patterns in audit trail)
- [ ] Multi-language support for documents (translation assistance)

---

### Phase 24: QbD Framework and Process Engineering (Months 37+) — EE

- [ ] QTPP builder (Quality Target Product Profile)
- [ ] CQA identification and documentation
- [ ] CPP identification and risk assessment linkage
- [ ] Design space definition and visualization
- [ ] Control strategy documentation
- [ ] PAT (Process Analytical Technology) tool registry and linkage
- [ ] Risk assessment → design space → process parameters linkage chain
- [ ] QbD knowledge management (knowledge accumulated during development follows product)
- [ ] ICH Q8/Q9/Q10/Q11/Q12 framework support

---

### Phase 25: Cloud Edition (Months 38+) — EE Cloud

- [ ] Multi-tenant SaaS architecture design
- [ ] Tenant isolation at database level
- [ ] Managed hosting infrastructure
- [ ] SaaS-specific onboarding flow
- [ ] Usage-based billing integration
- [ ] Cloud backup with immutability policies
- [ ] Cloud-native high availability

---

### Phase 26: Community and Ecosystem (Ongoing)

- [ ] OpenVAL marketplace concept (community-contributed templates)
- [ ] Partner validation services directory
- [ ] Integration library (community-built connectors)
- [ ] Kneat Academy equivalent: OpenVAL Academy (free online training)
- [ ] Annual "State of Validation" community survey
- [ ] ISPE/PDA community engagement
- [ ] Public case studies (anonymized customer implementations)

---

## 6. Module Specifications

### 6.1 Electronic Signature Flow (21 CFR Part 11 compliant)

Every action that requires a signature follows this exact sequence. No shortcuts.

1. User clicks sign/approve/execute action button
2. System presents **SignatureCapture modal**:
   - Record being signed (ref, title, version) — read-only
   - The meaning being applied (from signature_meanings table) — pre-selected, user cannot change
   - Username field — pre-populated, read-only (you cannot sign as someone else)
   - Password field — required re-entry even if already logged in (re-authentication)
   - TOTP token field — if MFA enabled for this meaning type or user
   - Confirmation checkbox: "I understand the meaning of this signature: [meaning text]"
3. User submits
4. Server re-authenticates credentials (separate from the session)
5. If valid:
   - Creates `electronic_signatures` record:
     - user_id (authenticated at signing, not session)
     - meaning_code
     - signed_at (server timestamp — never client)
     - signed_record_type, signed_record_id
     - signed_record_hash (SHA-256 of record content at the moment of signing)
     - manifested_reason (the meaning text, stored verbatim)
     - ip_address
   - Creates `audit_log` record for the SIGN action
   - Updates the target record status
6. Returns signed confirmation with signature timestamp to UI
7. If invalid: returns specific error code, increments failed_signature_attempt count, modal stays open
8. After 5 failed signature attempts: account locked, admin alert sent

**Signature linking (21 CFR 11.70):**
The `signed_record_hash` field stores the SHA-256 hash of the record's content at signing time.
If the record is modified after signing, this hash will not match the current content.
The system can detect post-signing modification. This makes retroactive tampering visible.

### 6.2 Audit Trail Architecture

The audit engine is a SQLAlchemy `before_flush` event listener. Every
`session.flush()` that includes any INSERT, UPDATE, or DELETE is intercepted.
The engine:

1. Identifies all changed objects (new, modified, deleted)
2. For each: serializes old value (before) and new value (after) to JSON
3. Reads current user from request context (FastAPI dependency, set on every authenticated request)
4. Reads IP address and user_agent from request context
5. Creates `audit_log` record atomically within the same database transaction
6. Creates `audit_log_integrity` record with:
   - `event_hash`: SHA-256 of (event_id + table + record_id + action + old_value + new_value + user_id + timestamp)
   - `chain_hash`: SHA-256 of (event_hash + previous_chain_hash)

This means:
- No application code path can modify data without an audit record (transaction-level guarantee)
- Any retroactive deletion or modification of audit records is detectable (hash chain)
- The `previous_chain_hash` creates a blockchain-style linked list of events

**Nightly verification (Celery task at 02:00):**
1. Read last verified `audit_log_integrity` record
2. Walk forward through all subsequent records
3. Recompute chain_hash for each
4. If mismatch detected: flag tamper event in `system_health_log`, send admin alert
5. Write verification result to `system_health_log`

### 6.3 Document and Protocol Approval Routing

Both documents and protocols use the workflow engine for approval routing.
The workflow definition specifies reviewers, sequence, and signature requirements.
The domain-specific tables (protocol_reviewer_assignments, document_reviews) 
capture the per-reviewer outcome. The workflow_instance tracks the overall state.

Approval routing supports:
- Sequential: reviewer 1 must complete before reviewer 2 is assigned
- Parallel: all reviewers assigned simultaneously, all must complete
- Hybrid: stages of parallel within overall sequential flow
- Dynamic assignment: stage is assigned to "owner_id field of the record" 
  (the person who owns the system, document, etc.)

### 6.4 Protocol Execution State Machine

```
DRAFT
  ↓ submit_for_review
IN_REVIEW
  ↓ approve          ↓ reject
APPROVED           DRAFT (back to author)
  ↓ begin_execution
EXECUTING
  ↓ complete_execution
COMPLETED
  ↓ submit_for_qa_review
IN_QA_REVIEW
  ↓ qa_approve       ↓ qa_reject
  ↓                  COMPLETED (address QA comments)
PASSED ───→ (triggers system validation completion check)
FAILED ───→ (triggers investigation, possible re-execution or CAPA)

VOIDED (from any state, requires QA_APPROVED signature, logs reason)
```

All transitions are enforced by the lifecycle_state_machines table.
Invalid transitions return a 409 Conflict response with the allowed transitions listed.

### 6.5 CSA vs CSV Mode

When a system is set to CSA mode (vs the default CSV mode), the following changes:

**In Protocol Builder:**
- Step types add: `unscripted_exploration` (no expected result required, just capture what you did)
- Step type `csa_assurance_activity` replaces `signature` for low-risk steps
- Vendor documentation steps: attach vendor test report, confirm it covers the requirement

**In Execution:**
- Unscripted steps show a free-form capture field: "Describe what you tested and observed"
- Result options: satisfactory / unsatisfactory (no pass/fail binary for unscripted)
- Critical thinking field required at execution conclusion: "Explain why the evidence collected is sufficient"

**In Validation Summary Report:**
- Shows CSA approach, intended use items, risk levels, assurance activities chosen
- Vendor documentation accepted: lists what vendor testing was relied upon
- Critical thinking documentation: the key CSA deliverable

**In Inspection Readiness:**
- CSA systems shown with CSA Assessment status and critical thinking documentation completeness

---

## 7. Compliance Framework Mapping

### 21 CFR Part 11 Controls

| Requirement | CFR Citation | OpenVAL Implementation |
|---|---|---|
| System validation | 11.10(a) | Bundled validation package VP-001 through VP-015 |
| Accurate/complete copies | 11.10(b) | PDF export, audit trail export, bulk data export (EE) |
| Record protection/retention | 11.10(c) | No-delete at application layer; archive capability; immutable audit log |
| Access controls | 11.10(d) | RBAC with unique user accounts; periodic access review module |
| Audit trails | 11.10(e) | Immutable append-only audit_log; SHA-256 hash chain; nightly verification |
| Audit trail review | 11.10(e) | Audit trail viewer; review workflow; scheduled review tasks |
| Operational checks | 11.10(f) | Lifecycle state machine enforces sequence; invalid transitions blocked |
| Authority checks | 11.10(g) | RBAC permission checks on every API call |
| Device checks | 11.10(h) | Session validation; IP logging; user_agent logging |
| Training | 11.10(i) | Training records module; access gates on training completion |
| Written policies | 11.10(j) | Policy document templates; document management module |
| Distribution controls | 11.10(c) | Document distribution with read confirmation tracking |
| E-signature requirements | 11.50(a) | Meaning text; printed name; date/time in signature record |
| E-signature linking | 11.70 | signed_record_hash links signature to record content at signing |
| Signature components | 11.100/11.200 | Password re-authentication + TOTP at every signing |

### ALCOA+ Data Integrity Matrix

| Principle | OpenVAL Implementation |
|---|---|
| **A**ttributable | user_id, created_by, updated_by on all records; audit trail user |
| **L**egible | Structured database; standardized formats; PDF export |
| **C**ontemporaneous | Server-side timestamps only; no client-provided timestamps in audit |
| **O**riginal | Immutable first record; versions preserve history |
| **A**ccurate | Validation on all inputs (Pydantic); no retroactive modification |
| **C**omplete | Mandatory fields enforced; workflow completion gates |
| **C**onsistent | Schema-enforced data types; lookup tables; lifecycle state machine |
| **E**nduring | No delete at application layer; archive strategy; immutable audit |
| **A**vailable | Search, export, no locking; multi-user concurrent access |

### CSA Compliance (FDA Final Guidance Sept 24, 2025)

| CSA Requirement | OpenVAL Implementation |
|---|---|
| Identify Intended Use | csa_intended_use_items table; structured per-feature assessment |
| Determine Risk | csa_intended_use_items risk fields; links to risk_assessments |
| Select Assurance Activities | assurance_approach field per intended use item; rationale required |
| Establish Record | csa_assurance_records; linked to protocols, executions, files |
| Critical Thinking | critical_thinking_rationale field required on CSA assessments |
| Vendor Doc Leverage | vendor_documentation_leveraged; vendor_testing_accepted fields |
| Unscripted Testing | Unscripted step type; free-form capture; result: satisfactory/unsatisfactory |
| Continuous Assurance | Automated risk re-assessment on change; validation debt tracking |

---

## 8. Validation Package Specification

The bundled validation package in `docs/validation_package/` follows GAMP 5
Category 4 approach. OpenVAL is classified as a configured commercial product.

**Classification Basis:**
- OpenVAL is built from a framework (FastAPI, SQLAlchemy, React) and configured for GxP use
- Configuration includes: workflow definitions, document templates, risk matrices, roles, permissions
- The framework components (PostgreSQL, Nginx, Celery) are Category 1-3 infrastructure
- The OpenVAL application itself is Category 4

**Site Responsibilities:**
1. Execute IQ against their installed instance (confirms installation is correct)
2. Execute OQ against their configured instance (confirms functions work as designed)
3. Execute PQ using representative business processes (confirms system works for their use)
4. Author and sign the Validation Summary Report
5. Establish periodic review schedule (recommend: annual or on major version upgrade)

**Revalidation Triggers:**
- Major version upgrade (X.0.0): full revalidation recommended
- Minor version upgrade (0.X.0): targeted OQ for changed functions
- Patch (0.0.X): risk assessment — likely no formal revalidation unless function change
- Infrastructure change (server, OS, database): IQ + targeted OQ
- Configuration change to validated workflows: targeted OQ
- Site relocation: IQ

---

## 9. API Design Standards

- All endpoints: `/api/v1/{module}/{resource}`
- Authentication: Bearer JWT in Authorization header
- All responses: `{ success: bool, data: any, message: str, errors: [], _license: {...} }`
- List responses: `{ items: [], total: int, page: int, per_page: int, pages: int }`
- Pagination: `?page=1&per_page=25`
- Filtering: `?field=value` or `?filters=JSON`
- Sorting: `?sort_by=field&sort_dir=asc|desc`
- All writes: audit trail created automatically (never by the API consumer)
- OpenAPI spec: auto-generated at `/api/docs` (dev) and `/api/redoc` (dev)
- Rate limiting: 60 req/min standard, 10 req/min auth endpoints
- Versioning: `/api/v1/` maintained for 2 major releases after breaking change
- EE endpoints: return 402 with `FEATURE_NOT_LICENSED` code if not licensed
- GxP headers: every response includes `X-OpenVAL-GxP-Context: true`

---

## 10. Security Architecture

### Authentication
- Passwords: bcrypt, minimum cost 12
- JWT access tokens: 15 minute expiry
- Refresh tokens: 7 day expiry, rotated on use, stored as SHA-256 hash
- TOTP MFA: RFC 6238, 10 backup codes (SHA-256 hashed, single-use)
- Account lockout: 5 failed attempts → 15-minute lockout
- Password policy: minimum 12 characters, uppercase, lowercase, number, special
- Password history: 12 versions cannot be reused
- Session timeouts: 30-minute idle, 8-hour absolute (configurable)
- Concurrent sessions: configurable limit (default 3)

### Data Protection
- MFA secrets: AES-256 encrypted at application layer before storage
- LDAP bind passwords: AES-256 encrypted
- API keys: stored as SHA-256 hash, shown once on creation
- File uploads: never directly accessible via URL; served through authenticated endpoint with audit log
- Sensitive fields in audit_log: masked (passwords, MFA secrets never logged, not even hashed)

### Infrastructure Security
- All inter-service communication: localhost only (no external exposure of Redis, PostgreSQL, Celery)
- Nginx: TLS 1.2+, HSTS, full security header set (CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy)
- Application: runs as dedicated non-root system user `openval`
- PostgreSQL: dedicated application user `openval_app` with minimum permissions; no superuser
- Redis: password protected, bound to localhost only

---

## 11. Bare Metal Deployment

### Service Architecture

```
/etc/systemd/system/
  openval-api.service       # Gunicorn + Uvicorn: FastAPI (4 workers default)
  openval-worker.service    # Celery worker: background tasks (4 concurrency default)
  openval-beat.service      # Celery beat: scheduled tasks (single instance)

/etc/nginx/sites-available/
  openval                   # Virtual host with TLS, gzip, security headers

/opt/openval/
  src/                      # Application source code
  venv/                     # Python virtual environment
  media/                    # Uploaded files (outside web root)
  logs/                     # Rotating application logs
  backups/                  # Database backup staging
  .env                      # Environment configuration (chmod 600)
```

### Supported Platforms
- Ubuntu 22.04 LTS (primary, most tested)
- Ubuntu 24.04 LTS
- RHEL 9 / Rocky Linux 9 / AlmaLinux 9

### Hardware Minimums
- CPU: 4 cores (8 recommended for >50 concurrent users)
- RAM: 8 GB (16 GB recommended)
- Storage: 100 GB (500 GB recommended for media-heavy deployments)
- Network: 100 Mbps (1 Gbps recommended)

---

## 12. CE vs EE Feature Split

### Community Edition — Always Free (AGPL-3.0)

Complete CSV platform for single-site, up to 50 users:

**Validation:** Protocol builder (IQ/OQ/PQ/UAT/MAV/DQ/SAT/FAT), test execution, electronic signatures, immutable audit trail, traceability matrix, periodic review, system inventory, GAMP 5 classification, risk assessment, requirements management, validation projects, validation plans, validation summary reports, configuration baselines, sign-off matrices, lifecycle state machines

**Quality:** Change control, CAPA, NCE, deviations, vendor management (basic), audit management (basic), training records (basic)

**Documents:** Document library, template engine, version control, approval workflows (up to 5 stages), distribution, read confirmation

**Workflow:** Low-code workflow builder (up to 5 stages), My Tasks, SLA monitoring, escalation

**Reports:** 15 standard reports, executive dashboard, QA dashboard, validation engineer dashboard

**Admin:** Single site, up to 50 users, local auth + TOTP, LDAP import (basic), email notifications, bare metal installer, backup/restore scripts, bundled validation package

### Enterprise Edition — Commercial License

Everything in CE plus:

**Advanced Quality:** OOS/OOT management, complaint management (21 CFR 211.198/820.198), inspection readiness module, audit collections / war rooms

**Advanced Validation Disciplines:** Electronic logbook management, drawing/P&ID management, technology transfer, cleaning validation (MACO/ADE), cold chain/temperature mapping, commissioning & qualification packages, process validation stages 1/2/3, sterilization validation, CSA mode (full), reusable test case library, validation master plan, QbD framework, validation debt tracker

**Operations:** Environmental monitoring (full), stability studies, batch/lot management, CoA generation

**Analytics:** SPC module, manufacturing analytics extension, process parameters

**AI (Phase 22+):** Document drafting assistant, CAPA intelligence, deviation pattern analysis, risk suggestions, video-to-script capture, validation debt AI prioritization, semantic document search

**Enterprise Features:** Multi-site management (unlimited), cross-site document publishing, organization compliance dashboard, advanced workflow builder (unlimited stages, conditional, parallel), form builder, automation rules engine, custom fields

**Advanced Integrations:** LabWare bidirectional, TrackWise sync, SAP equipment master, MES batch events, Teams/Slack, outbound webhooks, full read+write API

**Advanced Identity:** SAML/OIDC SSO, advanced LDAP, SCIM provisioning, IP allowlist

**Advanced Reporting:** Custom report builder, scheduled reports, cross-site reports, data export API

---

*OpenVAL Master Plan v2.0.0*
*Updated: 2026-04-08*
*Supersedes: MASTER_PLAN.md v1.0.0, MASTER_PLAN_ADDENDUM_001.md*
*Next review: After Phase 0 completion*


---

## ADDENDUM A: Workspace / Portfolio / Team Architecture

### Workspace Hierarchy

```
Organisation (AstraZeneca Global)
└── Region (North America)
    ├── Site: Madison MATC              ← sites table (existing)
    │   ├── Workspace: IT Validation   ← workspaces table (NEW)
    │   │   ├── Portfolio: SAP Suite   ← portfolios table (NEW)
    │   │   └── Portfolio: Lab Systems
    │   └── Workspace: Manufacturing Qual
    │       └── Portfolio: Fill/Finish Line 3
    └── Site: Chicago R&D
        └── Workspace: Drug Development CSV
```

**Data Isolation Levels (per workspace):**
- `shared` — members see all data in their site (default, most common)
- `restricted` — members only see data explicitly assigned to this workspace
- `strict` — full segregation, no cross-workspace visibility without explicit grant

**Use Cases:**
- Department A and Department B at same site never see each other's protocols
- CDMO client A and client B have completely isolated data on same server
- Corporate QA can see all sites; site teams see only their own
- External auditor access to exactly one collection, nothing else

### Team Workflow Integration

Teams receive workflow task assignments. The workflow engine supports:
- Assign to: specific user | role at site | team | workspace lead
- When assigned to a team: task appears in team queue; any eligible team member can claim it
- Team workload dashboard: how many open tasks per team member
- Delegation within teams: if user is unavailable → routes to backup_user_id

---

## ADDENDUM B: WP Bakery-Style Configuration System

The "WP Bakery style" principle applied to OpenVAL means:

**1. Configurable Dashboards (drag-and-drop)**
- 16 pre-built widgets in the widget_library table (seeded in Part 9)
- Users drag widgets into a 12-column grid layout
- Each widget has a "config panel" — click the gear icon → no-code options appear
- Example: Deviation Trend widget → configure: months to show, severity filter, site filter
- Layout saved in user_dashboards.personal_layout (JSON)
- System default dashboards per role (qa_manager, validation_engineer, executive)

**2. No-Code Module Configuration**
Every EE module is activated from a single Admin → Modules page:
- Toggle switch to enable/disable
- Click "Configure" → fills form (not editing JSON or YAML)
- Example: Environmental Monitoring → configure alert limits, sample point types, escalation paths

**3. Site Settings as Forms (not config files)**
- All site settings in workspace_settings and document_numbering_configs
- Admin pages present these as well-designed forms with help text
- Changes are audit-logged (who changed what setting, when)
- No SSH, no server access, no config file editing ever required post-install

**4. Template Builder (block palette)**
Exactly like WP Bakery's "Add Element" palette:
- Left panel: block library organized by category
- Drag a block type onto the canvas
- Block appears and can be configured inline
- Reorder by drag-and-drop
- Entire template can be cloned with one click

---

## ADDENDUM C: Complete Schema Summary — 362 Tables

| Part | Tables | Domain |
|---|---|---|
| 1 | 130 | Core: auth, audit trail, systems, protocols, documents, workflows, CAPA, change control |
| 2 | 0 | Indexes, sequences, RLS policies, seed data |
| 3 | 31 | Quality: OOS/OOT, EM, stability, batch, complaints, inspection, SPC, AI |
| 4 | 4 | License management |
| 5 | 33 | Validation workflows: projects, plans, sign-offs, amendments, lifecycle state machines |
| 6 | 16 | Gap closure: access reviews, DR tests, method validation, supplier controls |
| 7 | 37 | Disciplines: logbooks, drawings, tech transfer, cleaning, cold chain, CQV, process val, sterilization, CSA, test case library, audit war rooms, VMP, validation debt, QbD |
| 8 | 20 | Document system: block model, form fields, flowcharts, validation packages, AI assistance |
| 9 | 91 | Complete gap fill: workspaces, teams, calendar, training, equipment, eBR, regulatory submissions, integrations, dashboards/widgets, quality KPIs, AI registry, inspection findings, signature delegation, audit management, data retention, template library, numbering, distribution groups, risk controls, process monitoring, system health, onboarding, reference data, project templates, access requests, license snapshots |

**DBA Notes:**
- All PKs are UUID (gen_random_uuid()) — no sequential integers exposed to application
- All timestamps are TIMESTAMPTZ stored as UTC
- JSON fields are TEXT for portability across PostgreSQL/Oracle/MySQL
- Audit trail: append-only enforced at DB layer; every table has created_by/updated_by
- No hard deletes anywhere — status fields control lifecycle; delete = status change
- Foreign keys are defined but enforcement strategy depends on DB (PostgreSQL enforces; Oracle/MySQL configurable)
- Seed data: lookup tables, widget library, template step library, glossary seeded at install
- Sequence strategy: PostgreSQL uses gen_random_uuid(); Oracle uses sequences; MySQL uses id_sequences table

---

## ADDENDUM D: SOP Visualizer + Validation Package Visualizer

### SOP Visualizer — Competitive Differentiator

**What no other pharma validation platform does:**
Parse any SOP, work instruction, or procedure document and render it
as an interactive, navigable process flowchart automatically.

**How it works:**
1. User links any document in the system (SOP, process flow, WI)
2. AI extraction engine parses the text and identifies:
   - Process steps (rectangular nodes)
   - Decision gates (diamond nodes)
   - Roles / swimlane ownership
   - Document references
   - GxP-critical steps (highlighted in teal)
   - Regulatory citations
3. Rendered as interactive swimlane or flowchart diagram
4. Users can manually adjust, annotate, or correct nodes
5. Published visualizations can be shared via token link
6. PDF export for training materials and inspection evidence

**Why this wins inspections:**
- Inspectors love visual process maps — easier to follow than text SOPs
- During walkthroughs, show the flowchart on screen instead of reading paragraphs
- Instantly shows: who does what, when, what decisions are made
- Regulatory citation overlays prove the process is tied to the regulation

**Visualization types:**
- Swimlane (by role — default)
- Top-down flowchart
- Decision tree
- Responsibility matrix (RACI)
- Process map (simplified, for training)

**Pre-built templates seeded:**
- CSV Lifecycle (System Implementation path)
- CSV Lifecycle (Operational Change path)
- Change Control Workflow
- CAPA Workflow
- Deviation Management Process
- Periodic Review Process
- Document Approval Workflow
- Astellas SLC (two-path: implementation vs operational change)
- APS Execution and Disposition

**Schema:**
- `sop_visualizations` — visualization metadata and render data
- `sop_viz_nodes` — individual nodes with position, type, regulatory data
- `sop_viz_edges` — connections between nodes with branch labels
- `sop_viz_templates` — 9 seeded templates

---

### Validation Package Visualizer

**What it shows:**
Every validation project has a living visual representation showing
exactly where the project stands at any moment.

**Views available:**
1. **Lifecycle Map** — The deliverable chain with visual pass/fail/active/pending status
   Shows: RASC → Val Plan → URS → BFRA → IQ → OQ → PQ → UAT → RTM → VSR
   Each node shows status with the warm color system (green=passed, teal=active, gray=pending)

2. **RTM Heat Map** — Requirements × Test coverage grid
   Instantly shows: which requirements are not yet tested, which protocols cover what
   Color coded: covered (green), partial (gold), uncovered (coral), N/A (gray)
   Zoom: click any cell to see the specific test steps

3. **Protocol Completion Cards** — Per-protocol progress bars
   Shows: steps completed / total, current step, any open deviations

4. **Gantt View** — Timeline with dependencies
   Shows: who is blocking whom, which items are on the critical path

**The key insight:**
The Validation Package Visualizer turns what is normally a collection of
documents in a folder into a living, queryable status board. A QA manager
can see the entire project status in 5 seconds without opening a single document.
An inspector can understand where the project stands before they ask a question.

---

## ADDENDUM E: Complete Schema Summary — 428 Tables

| Part | Tables | Domain |
|---|---|---|
| 1 | 130 | Core: auth, audit trail, systems, protocols, documents, workflows, CAPA, change control |
| 3 | 31 | Quality: OOS/OOT, EM, stability, batch, complaints, inspection, SPC |
| 4 | 4 | License management |
| 5 | 33 | Validation workflows: projects, plans, sign-offs, lifecycle state machines |
| 6 | 16 | Gap closure: access reviews, DR testing, method validation, supplier controls |
| 7 | 37 | Disciplines: logbooks, drawings, tech transfer, cleaning, cold chain, CQV, process val, sterilization |
| 8 | 20 | Document system: block model, form fields, flowcharts, validation packages |
| 9 | 91 | Complete: workspaces, teams, calendar, training, equipment, eBR, regulatory submissions, integrations, dashboards, quality KPIs, AI registry, 483 tracking |
| 10 | 11 | Astellas gap fill: RASC, SMM, SRP, EOL, SRS, vendor releases, EHSA |
| 11 | $p11 | All remaining gaps: QMSR design control, Annex 1 (CCS/APS/PUPSIT), ATMP COI/COC, DCS/SCADA, GDP, data integrity, SOP visualizer, validation package visualizer |
| **TOTAL** | **$total** | |


---

## ADDENDUM F: Brand Name — OpenVAL® Trademark Conflict Resolution

**Problem:** OpenVAL® is registered USPTO #97737837 by Atorus Research, Inc.
(validated R packages for statistical analysis). Registered May 27, 2025.

**Candidate Names — All Researched, No Pharma Software Conflicts Found:**

| Name | Etymology | Strength |
|---|---|---|
| **VERIX** | VERIfy + -IX suffix (tech-native) | V anchors to existing logo. Clean, global, memorable. |
| **QUALINEX** | QUALity + INtelligence + NEXt | Enterprise weight. 3 syllables. Works for full vertical stack. |
| **VALIDUM** | VALIDation + Latin -um (material) | Latin authority. "As solid as validum." |
| **PHAROS** | PHARma + Pharos (ancient lighthouse) | Story: guides pharma through regulatory seas. |
| **CERTIMA** | Latin certus (certain) + -ima superlative | Elegant. "The most certain." |
| **NEXLID** | NEXt + Lifecycle Intelligence Dashboard | Compact acronym embedded. |
| **VALINEX** | VALIdation + NEXUS + valine (amino acid) | Pharma science resonance. |
| **COMPLIX** | COMPliance + IX | Risk: "complex" connotation. |

**Recommendation:** VERIX or QUALINEX. Both are clean, pronounceable globally,
work as a company name for future IPO or acquisition, and scale across
Validation + LIMS + QMS + ATMP vertical stack.

**GitHub repos to rename once decided:**
- `tigger2000ttfn/OpenVAL` → `tigger2000ttfn/VERIX` (or chosen name)
- `openval.github.io` → `verix.io` (or chosen name)

---

## ADDENDUM G: Oracle 19c+ Full Compatibility

See: `docs/architecture/ADR-016_Oracle_Full_Compatibility.md`

**Key decisions:**
- UUIDs stored as VARCHAR2(36) using generate_uuid() function (not RAW(16))
- TEXT → CLOB (19c) or native JSON type (21c+)
- BOOLEAN → NUMBER(1,0) with CHECK constraint
- RLS (PostgreSQL) → VPD Virtual Private Database (Oracle)
- SHA-256 audit chain → DBMS_CRYPTO.HASH (requires EXECUTE grant)
- JSON → CLOB+IS JSON constraint (19c) or JSON native (21c)
- Audit trail → range-partitioned by month
- Wallet-based connection (zero plaintext credentials in config)
- Alembic migrations: dialect-detected DDL per migration

**Oracle versions supported:**
Oracle 19c (LTR, primary), 21c (preferred JSON), 23ai, Oracle Autonomous Database

---

## ADDENDUM H: Complete Vertical Stack — The Quality Platform Vision

```
VALIDATION SUITE (Building now — 418 tables, 11 schema parts)
    ↓
LIMS MODULE (Phase 18-20)
    Sample registration → Testing assignment → Result capture
    OOS/OOT investigation → CoA generation → Stability scheduling
    Integrates: LabWare, LabVantage, STARLIMS (via Integration Infrastructure)
    Native lightweight LIMS for companies without enterprise LIMS
    ↓
QMS MODULE (Already built into core)
    CAPA · Change Control · Complaints · Audits · Training
    ↓
MES / eBR MODULE (Future EE — schema in Part 9)
    Electronic Batch Records · Manufacturing Execution
    ↓
ELN MODULE (Future EE)
    Electronic Lab Notebook · Experiment tracking
    ↓
REGULATORY AFFAIRS MODULE (Future EE)
    CTD dossier · Submission tracking · Agency commitments
    ↓
ATMP MODULE (Future EE — schema in Part 11)
    Chain of Identity · Chain of Custody · Donor eligibility
    Patient-specific manufacturing records

AI INTELLIGENCE LAYER — runs across every module
    Gap analysis · Draft generation · Anomaly detection · RTM automation
```

The LIMS module key insight: validation data and lab data are deeply interconnected.
An OQ test step that measures pH needs to know the instrument calibration date.
A stability sample result feeds directly into the CPV module.
A deviation in the LIMS triggers a CAPA in the QMS.

The platform IS the integration. That's the competitive moat.
