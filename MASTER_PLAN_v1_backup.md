# PHAROLON Master Plan

**Living Development Document - All Phases, Features, Database, and Architecture**

*This document is the authoritative reference for all OpenVAL development work. It is updated as phases progress and requirements evolve.*

Last Updated: 2026-04-06
Version: 1.0.0

---

## Table of Contents

1. [Vision and Principles](#1-vision-and-principles)
2. [Architecture Overview](#2-architecture-overview)
3. [UI/UX Design System](#3-uiux-design-system)
4. [Complete Database Schema](#4-complete-database-schema)
5. [Phase Plan](#5-phase-plan)
6. [Module Specifications](#6-module-specifications)
7. [Compliance Framework Mapping](#7-compliance-framework-mapping)
8. [Validation Package Specification](#8-validation-package-specification)
9. [API Design Standards](#9-api-design-standards)
10. [Security Architecture](#10-security-architecture)
11. [Bare Metal Deployment](#11-bare-metal-deployment)
12. [Future Roadmap](#12-future-roadmap)

---

## 1. Vision and Principles

### Core Vision

OpenVAL is the Kneat-equivalent for organizations that cannot afford commercial CSV platforms. It is not a wrapper around a generic project management tool. Every feature, every data model, every workflow is designed specifically for GMP-regulated computerized system validation.

### Design Principles

**For Users**
- Non-developers must be able to create systems, execute protocols, build workflows, and generate reports without writing a single line of code
- Every screen must be intuitive. If a user needs training to find a feature, the UI has failed
- Consistent navigation, consistent language, consistent behavior across every module
- Templates and defaults ship ready to use for pharma. Users configure, not build from scratch

**For Compliance**
- Audit trail is not a feature. It is the foundation. Every data write passes through the audit engine
- Electronic signatures follow 21 CFR Part 11 to the letter: meaning, identity, date/time, re-authentication
- ALCOA+ is enforced by architecture, not policy: Attributable, Legible, Contemporaneous, Original, Accurate, Complete, Consistent, Enduring, Available
- Change control is built into every module. Nothing changes without a record

**For Operations**
- Bare metal first. No Docker dependency for production use
- Minimal external dependencies. Runs on a single server with modest hardware
- Installer script handles everything. Sites should be operational within two hours
- The software validates itself. The bundled IQ/OQ/PQ package is the validation artifact

**For Community**
- Open source, AGPL-3.0
- Public issue tracker and changelog
- Versioned releases with validation impact classification per change
- SDL documentation is public and maintained in the repository

---

## 2. Architecture Overview

### System Architecture

```
[ Nginx (TLS termination, static files, reverse proxy) ]
          |
[ Gunicorn + Uvicorn Workers (FastAPI application) ]
          |
    +-----+-----+
    |           |
[ PostgreSQL ] [ Redis ]
  (primary DB)  (cache, task queue, sessions)
                    |
              [ Celery Workers ]
              (background tasks, notifications,
               report generation, scheduled reviews)
```

### Directory Structure

```
openval/
  backend/
    app/
      api/v1/endpoints/     # All route handlers, one file per module
      core/                 # Config, security, database session, audit engine
      models/               # SQLAlchemy ORM models (mirrors schema exactly)
      schemas/              # Pydantic request/response schemas
      services/             # Business logic, one service per domain
      workflows/            # Workflow engine runtime
      utils/                # PDF generation, email, file handling
    migrations/             # Alembic migration files
    tests/                  # Pytest test suite
  frontend/
    src/
      components/
        layout/             # AppShell, Header, Sidebar, Breadcrumbs, Footer
        ui/                 # Button, Modal, Table, Badge, Form, Toast etc.
        forms/              # Reusable domain form components
        charts/             # Dashboard chart components
      pages/                # One directory per module/route
      hooks/                # Custom React hooks
      store/                # Zustand state slices
      utils/                # API client, formatters, validators
    public/
  docs/
    database/               # Schema documentation
    architecture/           # Architecture decision records
    compliance/             # CFR mapping, ALCOA matrix
    validation_package/     # Bundled IQ/OQ/PQ for OpenVAL itself
    ui_design/              # Design system tokens and components
  schema/                   # PostgreSQL DDL files
  templates/                # Pre-built pharma templates (protocols, documents)
  scripts/                  # install.sh, backup.sh, upgrade.sh
  config/                   # nginx.conf, systemd unit files, env templates
```

### Data Flow for Every Write Operation

1. API endpoint receives authenticated request
2. Service layer validates business rules
3. Audit engine captures: table, record_id, action, old_value, new_value, user_id, timestamp, IP, user_agent, reason_code
4. Database write executes within transaction
5. Audit record commits atomically with the data change
6. Response returned to client

This means it is architecturally impossible to modify data without generating an audit record.

---

## 3. UI/UX Design System

### Design Philosophy

The OpenVAL interface is built on a consistent shell. Every page in the application shares the same structure. Users always know where they are, how to get back, and what actions are available. There are no surprise layouts or inconsistent navigation patterns.

### Color System

```
Primary:     #1B4F8A  (deep regulatory blue - trust, stability)
Primary-Lt:  #2D6BB5
Primary-Dk:  #0F3060
Accent:      #00875A  (success green, pass states)
Warning:     #FF8B00  (amber, review/pending states)
Danger:      #DE350B  (red, failure, critical deviation)
Neutral-900: #172B4D  (text primary)
Neutral-700: #344563  (text secondary)
Neutral-500: #5E6C84  (text tertiary)
Neutral-200: #DFE1E6  (borders, dividers)
Neutral-100: #F4F5F7  (surface, sidebar background)
Neutral-000: #FFFFFF  (card, content background)
```

### Status Badge System (universal across all modules)

| Status | Color | Usage |
|---|---|---|
| Draft | Neutral | Any record not yet submitted |
| In Review | Blue | Submitted, pending approval |
| Approved | Green | Fully approved, in effect |
| Rejected | Red | Returned for revision |
| Executed | Green | Protocol/test step executed |
| Failed | Red | Test step failed |
| Deviation | Amber | Step passed with deviation |
| Voided | Neutral-Dark | Record invalidated |
| Superseded | Neutral | Replaced by newer version |
| Overdue | Red | Past SLA or review date |
| Scheduled | Blue | Future action planned |
| Closed | Neutral | Completed and closed |

### Application Shell

Every authenticated page renders inside AppShell:

```
+----------------------------------------------------------+
| LOGO  OpenVAL     [Site Name]      [Search]  [User Menu] |  <- Header (64px)
+--------+--------------------------------------------------+
|        |  [Breadcrumb: Module > Section > Record]         |  <- Breadcrumb bar
|  NAV   |--------------------------------------------------|
|        |                                                  |
| System |   PAGE TITLE                    [Action Buttons] |
|  Inv   |                                                  |
|        |   [Page content]                                 |
| Risk   |                                                  |
|  Asmt  |                                                  |
|        |                                                  |
| Reqs   |                                                  |
|        |                                                  |
| Protos |                                                  |
|        |                                                  |
| Docs   |                                                  |
|        |                                                  |
| WF     |                                                  |
|        |                                                  |
| Change |                                                  |
|        |                                                  |
| CAPA   |                                                  |
|        |                                                  |
| Reports|                                                  |
|        |                                                  |
| Admin  |                                                  |
+--------+--------------------------------------------------+
```

### Sidebar Navigation Groups

```
VALIDATION
  System Inventory
  Risk Assessments
  Requirements
  Protocols
  Test Executions
  Traceability Matrix

QUALITY
  Change Control
  CAPA
  Nonconformances
  Deviations
  Periodic Reviews

DOCUMENTS
  Document Library
  Templates
  Pending Approvals

WORKFLOWS
  My Tasks
  Workflow Builder
  Active Workflows

OPERATIONS
  Equipment
  Vendors
  Training Records
  Audits

REPORTS
  Report Builder
  Dashboards
  Scheduled Reports

ADMINISTRATION
  User Management
  Roles & Permissions
  Site Settings
  Lookup Configuration
  Email Templates
  Integrations
  Audit Log Viewer
  System Health
```

### Reusable UI Component Library

All components are built once and used everywhere. No one-off styling.

- AppShell (header + sidebar + content area)
- PageHeader (title, subtitle, action buttons, breadcrumbs)
- DataTable (sortable, filterable, paginated, exportable, column configuration)
- StatusBadge (universal status chip)
- FilterBar (search + multi-filter dropdowns)
- DetailPanel (right-side slide-in for record details)
- RecordCard (summary card for list views)
- FormField (label + input + validation message + help text)
- RichTextEditor (TipTap, used for all narrative fields)
- FileUpload (drag-drop with preview, virus scan hook)
- TimelineView (audit trail, workflow history)
- SignatureCapture (21 CFR Part 11 modal: re-auth + meaning selection)
- ConfirmDialog (for destructive or signature-required actions)
- ProgressTracker (protocol execution progress, workflow stage)
- SplitView (requirements with linked tests, document with sections)
- CommentThread (inline comments with user, timestamp)
- VersionSelector (switch between document/protocol versions)
- ApprovalPanel (shows reviewers, signatures, dates)
- DashboardWidget (pluggable metric cards)
- NotificationToast (success, warning, error, info)
- EmptyState (illustrated empty state for each module)
- LoadingSkeleton (consistent loading placeholder)

---

## 4. Complete Database Schema

Every table the system will ever need is defined here. Tables are grouped by domain. All tables include created_at, updated_at, created_by, and updated_by unless noted. The audit_log captures the actual change history; these timestamps are for indexing and display.

All primary keys are UUIDs (uuid type in PostgreSQL). Foreign keys are named consistently: referenced_table_id.

### 4.1 Authentication and User Management

**users**
- id (uuid, PK)
- username (varchar 100, unique, not null)
- email (varchar 255, unique, not null)
- full_name (varchar 255, not null)
- title (varchar 100) -- job title
- department_id (uuid, FK departments)
- site_id (uuid, FK sites)
- hashed_password (varchar 255, not null)
- is_active (boolean, default true)
- is_locked (boolean, default false)
- lock_reason (text)
- locked_at (timestamptz)
- locked_by (uuid, FK users)
- must_change_password (boolean, default false)
- last_login_at (timestamptz)
- last_login_ip (varchar 45)
- failed_login_count (int, default 0)
- password_changed_at (timestamptz)
- mfa_enabled (boolean, default false)
- mfa_secret (varchar 255) -- encrypted TOTP secret
- mfa_backup_codes (text) -- encrypted JSON array
- created_at (timestamptz, not null, default now())
- updated_at (timestamptz, not null)
- created_by (uuid, FK users)
- updated_by (uuid, FK users)

**roles**
- id (uuid, PK)
- name (varchar 100, unique, not null)
- display_name (varchar 255, not null)
- description (text)
- is_system_role (boolean, default false) -- cannot be deleted
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**permissions**
- id (uuid, PK)
- module (varchar 100, not null) -- e.g. protocols, documents, users
- action (varchar 100, not null) -- e.g. create, read, update, delete, execute, approve, sign
- resource (varchar 100) -- optional sub-resource
- display_name (varchar 255)
- description (text)
- UNIQUE (module, action, resource)

**role_permissions**
- id (uuid, PK)
- role_id (uuid, FK roles)
- permission_id (uuid, FK permissions)
- granted_at (timestamptz)
- granted_by (uuid, FK users)
- UNIQUE (role_id, permission_id)

**user_roles**
- id (uuid, PK)
- user_id (uuid, FK users)
- role_id (uuid, FK roles)
- site_id (uuid, FK sites, nullable) -- null = all sites
- assigned_at (timestamptz)
- assigned_by (uuid, FK users)
- expires_at (timestamptz, nullable)
- UNIQUE (user_id, role_id, site_id)

**user_sessions**
- id (uuid, PK)
- user_id (uuid, FK users)
- session_token (varchar 512, unique, not null)
- refresh_token (varchar 512, unique)
- ip_address (varchar 45)
- user_agent (text)
- created_at (timestamptz)
- expires_at (timestamptz)
- last_active_at (timestamptz)
- revoked_at (timestamptz)
- revoked_reason (varchar 255)

**password_history**
- id (uuid, PK)
- user_id (uuid, FK users)
- hashed_password (varchar 255)
- created_at (timestamptz)

**login_attempts**
- id (uuid, PK)
- username_attempted (varchar 255)
- ip_address (varchar 45)
- user_agent (text)
- success (boolean)
- failure_reason (varchar 255)
- attempted_at (timestamptz)

**api_keys**
- id (uuid, PK)
- user_id (uuid, FK users)
- name (varchar 255, not null)
- key_prefix (varchar 12, not null) -- first 8 chars for display
- hashed_key (varchar 255, not null, unique)
- scopes (text) -- JSON array of permitted scopes
- last_used_at (timestamptz)
- expires_at (timestamptz)
- revoked_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**sso_providers**
- id (uuid, PK)
- name (varchar 100, unique)
- provider_type (varchar 50) -- saml, oidc, ldap
- config (text) -- encrypted JSON
- is_active (boolean)
- is_default (boolean)
- created_at, updated_at, created_by, updated_by

**sso_user_mappings**
- id (uuid, PK)
- user_id (uuid, FK users)
- provider_id (uuid, FK sso_providers)
- external_user_id (varchar 255)
- external_email (varchar 255)
- last_synced_at (timestamptz)
- UNIQUE (provider_id, external_user_id)

**user_preferences**
- id (uuid, PK)
- user_id (uuid, FK users, unique)
- timezone (varchar 100, default 'UTC')
- date_format (varchar 50)
- items_per_page (int, default 25)
- sidebar_collapsed (boolean, default false)
- theme (varchar 50, default 'light')
- notification_preferences (text) -- JSON
- dashboard_layout (text) -- JSON
- updated_at (timestamptz)

---

### 4.2 Organization and Site

**organizations**
- id (uuid, PK)
- name (varchar 255, not null)
- legal_name (varchar 255)
- duns_number (varchar 20)
- fda_establishment_number (varchar 50)
- address_line1, address_line2, city, state, postal_code, country
- phone, email, website
- logo_path (varchar 512)
- created_at, updated_at, created_by, updated_by

**sites**
- id (uuid, PK)
- organization_id (uuid, FK organizations)
- name (varchar 255, not null)
- code (varchar 50, unique) -- e.g. MATC, CAMB
- site_type (varchar 100) -- manufacturing, clinical, r&d, quality, warehouse
- address_line1, address_line2, city, state, postal_code, country
- phone, email
- fda_facility_number (varchar 50)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**departments**
- id (uuid, PK)
- site_id (uuid, FK sites)
- name (varchar 255, not null)
- code (varchar 50)
- department_type (varchar 100) -- QA, manufacturing, lab, IT, engineering
- manager_id (uuid, FK users, nullable)
- parent_department_id (uuid, FK departments, nullable)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**cost_centers**
- id (uuid, PK)
- site_id (uuid, FK sites)
- code (varchar 50, not null)
- name (varchar 255)
- department_id (uuid, FK departments, nullable)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

---

### 4.3 Audit Trail and Electronic Signatures

These are the most critical tables in the system. They are append-only. No UPDATE or DELETE is ever permitted at the application layer. Database-level row security policies enforce this.

**audit_log**
- id (uuid, PK)
- event_id (varchar 50, unique) -- formatted event ID for human reference
- table_name (varchar 100, not null)
- record_id (uuid, not null)
- record_display (varchar 512) -- human-readable record identifier at time of change
- action (varchar 20, not null) -- CREATE, UPDATE, DELETE, EXECUTE, APPROVE, REJECT, SIGN, LOGIN, LOGOUT, EXPORT, PRINT, VIEW
- field_name (varchar 100, nullable) -- for UPDATE, which field changed
- old_value (text, nullable)
- new_value (text, nullable)
- old_value_hash (varchar 64) -- SHA-256 of old_value for integrity verification
- new_value_hash (varchar 64)
- user_id (uuid, not null)
- user_name (varchar 100, not null) -- denormalized snapshot
- user_full_name (varchar 255, not null) -- denormalized snapshot
- ip_address (varchar 45)
- user_agent (text)
- session_id (uuid, FK user_sessions)
- reason_code (varchar 100) -- for UPDATE: reason for change
- reason_text (text)
- module (varchar 100) -- which application module generated this entry
- parent_table (varchar 100, nullable) -- for child records, links to parent context
- parent_record_id (uuid, nullable)
- cfr_citation (varchar 255) -- e.g. 21 CFR 11.10(e)
- timestamp (timestamptz, not null, default now())
-- NO updated_at, NO updated_by. This record never changes.
-- INDEX: table_name, record_id, timestamp, user_id, action

**audit_log_integrity**
- id (uuid, PK)
- audit_log_id (uuid, unique, not null) -- references audit_log.id
- record_hash (varchar 64, not null) -- SHA-256 of entire audit_log row
- chain_hash (varchar 64, not null) -- SHA-256 of previous chain_hash + record_hash
- verified_at (timestamptz)
-- Enables tamper detection by verifying hash chain

**electronic_signatures**
- id (uuid, PK)
- signature_id (varchar 50, unique) -- formatted signature ID
- table_name (varchar 100, not null)
- record_id (uuid, not null)
- record_version (int) -- version of the record at time of signing
- signer_id (uuid, FK users, not null)
- signer_username (varchar 100, not null) -- snapshot
- signer_full_name (varchar 255, not null) -- snapshot
- signer_title (varchar 100) -- snapshot
- meaning_id (uuid, FK signature_meanings)
- meaning_text (varchar 512, not null) -- snapshot of meaning at signing time
- signed_at (timestamptz, not null)
- auth_method (varchar 50, not null) -- password+totp, password, sso
- ip_address (varchar 45)
- signature_hash (varchar 64, not null) -- SHA-256 of signer_id + record_id + meaning + signed_at
- manifested_data_hash (varchar 64) -- hash of the data that was signed
- is_valid (boolean, default true)
- invalidated_at (timestamptz, nullable)
- invalidated_by (uuid, FK users, nullable)
- invalidation_reason (text)
-- NO updates. Invalidation creates a new record, does not modify this one.

**signature_meanings**
- id (uuid, PK)
- code (varchar 50, unique, not null) -- APPROVED, REVIEWED, AUTHORED, EXECUTED, WITNESSED, VERIFIED
- display_name (varchar 255, not null)
- description (text)
- regulatory_citation (varchar 255)
- applicable_modules (text) -- JSON array of modules this meaning applies to
- requires_mfa (boolean, default false)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**signature_delegates**
- id (uuid, PK)
- delegator_id (uuid, FK users)
- delegate_id (uuid, FK users)
- meaning_ids (text) -- JSON array of signature meaning IDs allowed
- module (varchar 100) -- which module this delegation applies to
- start_date (date, not null)
- end_date (date, not null)
- reason (text)
- approved_by (uuid, FK users)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

---

### 4.4 Lookup and Reference Data

**lookup_categories**
- id (uuid, PK)
- code (varchar 100, unique, not null)
- display_name (varchar 255, not null)
- description (text)
- is_system (boolean, default false) -- system categories cannot be deleted
- allow_custom_values (boolean, default true)
- created_at, updated_at, created_by, updated_by

**lookup_values**
- id (uuid, PK)
- category_id (uuid, FK lookup_categories)
- code (varchar 100, not null)
- display_name (varchar 255, not null)
- description (text)
- sort_order (int, default 0)
- metadata (text) -- JSON for extra fields per category
- is_active (boolean, default true)
- is_system (boolean, default false)
- created_at, updated_at, created_by, updated_by
- UNIQUE (category_id, code)

**regulatory_references**
- id (uuid, PK)
- framework (varchar 100, not null) -- 21CFR, EU_ANNEX11, ICH, GAMP5, ISO
- citation (varchar 255, not null) -- e.g. 21 CFR 11.10(a)
- title (varchar 512)
- summary (text)
- full_text_url (varchar 512)
- is_active (boolean)
- created_at, updated_at

**feature_regulatory_mappings**
- id (uuid, PK)
- feature_code (varchar 100, not null) -- internal feature identifier
- regulatory_reference_id (uuid, FK regulatory_references)
- compliance_note (text)
- created_at, updated_at, created_by, updated_by

**countries**
- id (uuid, PK)
- iso_code (varchar 3, unique)
- name (varchar 255)
- is_active (boolean)

**tags**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable) -- null = global tag
- category (varchar 100) -- system, protocol, document, equipment, etc.
- name (varchar 100, not null)
- color (varchar 7) -- hex color
- is_active (boolean)
- created_at, updated_at, created_by, updated_by
- UNIQUE (site_id, category, name)

**object_tags**
- id (uuid, PK)
- tag_id (uuid, FK tags)
- object_type (varchar 100, not null) -- table name
- object_id (uuid, not null)
- tagged_at (timestamptz)
- tagged_by (uuid, FK users)

**announcements**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable) -- null = all sites
- title (varchar 512, not null)
- body (text, not null)
- priority (varchar 20) -- info, warning, critical
- start_at (timestamptz)
- end_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**announcement_reads**
- id (uuid, PK)
- announcement_id (uuid, FK announcements)
- user_id (uuid, FK users)
- read_at (timestamptz)
- UNIQUE (announcement_id, user_id)

---

### 4.5 File Management

**file_store**
- id (uuid, PK)
- file_ref (varchar 50, unique, not null) -- human-readable file reference
- original_filename (varchar 512, not null)
- stored_filename (varchar 512, not null) -- UUID-based stored name
- storage_path (varchar 1024, not null)
- file_size_bytes (bigint)
- mime_type (varchar 255)
- extension (varchar 20)
- sha256_hash (varchar 64, not null) -- integrity verification
- is_virus_scanned (boolean, default false)
- virus_scan_result (varchar 50) -- clean, infected, error
- virus_scanned_at (timestamptz)
- is_encrypted (boolean, default false)
- uploaded_by (uuid, FK users)
- site_id (uuid, FK sites)
- uploaded_at (timestamptz, not null)

**file_attachments**
- id (uuid, PK)
- file_id (uuid, FK file_store)
- object_type (varchar 100, not null) -- polymorphic: table name
- object_id (uuid, not null)
- attachment_type (varchar 100) -- evidence, screenshot, reference, report, etc.
- display_name (varchar 512)
- description (text)
- sort_order (int, default 0)
- attached_at (timestamptz)
- attached_by (uuid, FK users)

**file_access_log**
- id (uuid, PK)
- file_id (uuid, FK file_store)
- user_id (uuid, FK users)
- action (varchar 50) -- view, download, print
- ip_address (varchar 45)
- accessed_at (timestamptz)

---

### 4.6 System Inventory and Equipment

**systems**
- id (uuid, PK)
- system_ref (varchar 50, unique, not null) -- e.g. SYS-0042
- site_id (uuid, FK sites)
- name (varchar 512, not null)
- description (text)
- system_type (varchar 100) -- software, equipment, infrastructure, hybrid
- gamp_category (varchar 10) -- 1, 3, 4, 5
- gamp_category_justification (text)
- gxp_relevant (boolean, not null)
- gxp_impact_areas (text) -- JSON array: data_integrity, product_quality, patient_safety, audit_trail, records
- gxp_justification (text)
- applicable_regulations (text) -- JSON array: 21cfr11, 21cfr211, 21cfr820, annex11, glp, etc.
- classification_status (varchar 50) -- draft, approved, under_review
- status (varchar 50) -- active, retired, pending_validation, decommissioned, under_change
- validated_status (varchar 50) -- not_validated, in_qualification, validated, validation_expired, requalification_required
- validation_basis (varchar 100) -- iqoqpq, risk_based_assessment, vendor_doc, retrospective
- version (varchar 100) -- system/software version
- vendor_id (uuid, FK vendors, nullable)
- vendor_product_name (varchar 255)
- vendor_product_version (varchar 100)
- license_type (varchar 100)
- license_expiry_date (date)
- location (varchar 512) -- physical or logical location
- hosting_type (varchar 100) -- on_premise, cloud, hybrid, saas
- environment (varchar 50) -- production, staging, test, development
- business_owner_id (uuid, FK users)
- technical_owner_id (uuid, FK users)
- qa_owner_id (uuid, FK users)
- installation_date (date)
- go_live_date (date)
- retirement_date (date, nullable)
- revalidation_required (boolean, default false)
- revalidation_due_date (date, nullable)
- revalidation_trigger (varchar 255)
- periodic_review_interval_months (int, default 12)
- next_periodic_review_date (date)
- criticality (varchar 50) -- critical, major, minor
- backup_frequency (varchar 100)
- disaster_recovery_rto (varchar 100)
- disaster_recovery_rpo (varchar 100)
- data_classification (varchar 100) -- gxp_critical, business_critical, internal, public
- notes (text)
- created_at, updated_at, created_by, updated_by

**system_versions**
- id (uuid, PK)
- system_id (uuid, FK systems)
- version_number (varchar 100, not null)
- version_date (date)
- change_summary (text)
- validation_impact (varchar 50) -- major, minor, none
- revalidation_required (boolean)
- release_notes (text)
- retired_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**system_components**
- id (uuid, PK)
- system_id (uuid, FK systems)
- name (varchar 255, not null)
- component_type (varchar 100) -- database, application_server, web_server, api, module, plugin
- version (varchar 100)
- vendor (varchar 255)
- gxp_relevant (boolean)
- description (text)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**system_interfaces**
- id (uuid, PK)
- source_system_id (uuid, FK systems)
- target_system_id (uuid, FK systems)
- interface_name (varchar 255)
- interface_type (varchar 100) -- api, database_link, file_transfer, manual, hl7, fhir
- direction (varchar 20) -- inbound, outbound, bidirectional
- data_types (text) -- JSON array
- gxp_relevant (boolean)
- validated (boolean)
- description (text)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**system_environments**
- id (uuid, PK)
- system_id (uuid, FK systems)
- environment_name (varchar 50) -- production, staging, validation, development
- server_hostname (varchar 255)
- server_ip (varchar 45)
- url (varchar 512)
- os_version (varchar 100)
- database_version (varchar 100)
- application_version (varchar 100)
- is_validated (boolean)
- notes (text)
- created_at, updated_at, created_by, updated_by

**system_data_flows**
- id (uuid, PK)
- system_id (uuid, FK systems)
- data_type (varchar 255, not null)
- source (varchar 255)
- destination (varchar 255)
- contains_gxp_data (boolean)
- contains_pii (boolean)
- encryption_in_transit (boolean)
- encryption_at_rest (boolean)
- notes (text)
- created_at, updated_at, created_by, updated_by

**equipment**
- id (uuid, PK)
- equipment_ref (varchar 50, unique, not null) -- e.g. EQ-0012
- site_id (uuid, FK sites)
- department_id (uuid, FK departments)
- name (varchar 512, not null)
- description (text)
- equipment_type (varchar 100) -- analytical, manufacturing, utility, lab, computer
- manufacturer (varchar 255)
- manufacturer_model (varchar 255)
- serial_number (varchar 255)
- asset_number (varchar 255)
- gxp_relevant (boolean)
- gamp_category (varchar 10)
- status (varchar 50) -- active, out_of_service, decommissioned, calibration_due
- validated_status (varchar 50)
- location (varchar 512)
- installation_date (date)
- owner_id (uuid, FK users)
- vendor_id (uuid, FK vendors, nullable)
- calibration_required (boolean, default false)
- calibration_interval_days (int)
- last_calibration_date (date)
- next_calibration_date (date)
- maintenance_interval_days (int)
- last_maintenance_date (date)
- next_maintenance_date (date)
- notes (text)
- created_at, updated_at, created_by, updated_by

**equipment_calibration_records**
- id (uuid, PK)
- equipment_id (uuid, FK equipment)
- calibration_ref (varchar 50, unique)
- performed_by (uuid, FK users)
- performed_date (date, not null)
- due_date (date)
- result (varchar 50) -- pass, fail, conditional
- certificate_number (varchar 255)
- calibrating_lab (varchar 255)
- standard_used (varchar 255)
- tolerance_as_found (varchar 255)
- tolerance_as_left (varchar 255)
- deviation_noted (boolean, default false)
- deviation_description (text)
- notes (text)
- created_at, updated_at, created_by, updated_by

**equipment_maintenance_records**
- id (uuid, PK)
- equipment_id (uuid, FK equipment)
- maintenance_ref (varchar 50, unique)
- maintenance_type (varchar 100) -- preventive, corrective, upgrade
- performed_by (uuid, FK users)
- performed_date (date, not null)
- description (text)
- parts_replaced (text)
- revalidation_required (boolean)
- validation_impact_notes (text)
- completed (boolean, default false)
- created_at, updated_at, created_by, updated_by

---

### 4.7 Risk Assessment

**risk_matrices**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable)
- name (varchar 255, not null)
- description (text)
- matrix_type (varchar 50) -- probability_impact, fmea, fmea_extended
- probability_scale (int, default 5) -- number of levels
- impact_scale (int, default 5)
- detectability_scale (int, default 5, nullable) -- for FMEA
- risk_thresholds (text) -- JSON: [{min_score, max_score, level, color, action_required}]
- is_default (boolean, default false)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**risk_assessments**
- id (uuid, PK)
- assessment_ref (varchar 50, unique, not null) -- RA-0001
- system_id (uuid, FK systems, nullable)
- equipment_id (uuid, FK equipment, nullable)
- assessment_type (varchar 100) -- system_validation, change_impact, periodic_review, supplier
- title (varchar 512, not null)
- scope (text)
- methodology (varchar 100) -- fmea, haccp, hazop, bow_tie, probability_impact
- matrix_id (uuid, FK risk_matrices)
- version (int, default 1)
- status (varchar 50) -- draft, in_review, approved, superseded
- assessment_date (date)
- review_date (date)
- next_review_date (date)
- overall_risk_level (varchar 50) -- critical, high, medium, low
- overall_residual_risk_level (varchar 50)
- conclusion (text)
- approved_at (timestamptz)
- approved_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**risk_assessment_versions**
- id (uuid, PK)
- assessment_id (uuid, FK risk_assessments)
- version_number (int, not null)
- change_summary (text)
- snapshot (text) -- JSON snapshot of full assessment at this version
- created_at, created_by
- UNIQUE (assessment_id, version_number)

**risk_items**
- id (uuid, PK)
- assessment_id (uuid, FK risk_assessments)
- item_number (varchar 20, not null)
- category (varchar 100) -- data_integrity, access_control, backup, infrastructure, process
- hazard (text, not null)
- potential_effect (text, not null)
- existing_controls (text)
- probability_score (int, not null)
- probability_rationale (text)
- impact_score (int, not null)
- impact_rationale (text)
- detectability_score (int, nullable) -- FMEA only
- detectability_rationale (text)
- inherent_risk_score (int) -- computed: probability * impact
- inherent_risk_level (varchar 50)
- rpn (int, nullable) -- FMEA: probability * impact * detectability
- mitigation_required (boolean)
- mitigation_actions (text)
- residual_probability_score (int)
- residual_impact_score (int)
- residual_detectability_score (int, nullable)
- residual_risk_score (int)
- residual_rpn (int, nullable)
- residual_risk_level (varchar 50)
- risk_accepted (boolean, default false)
- acceptance_rationale (text)
- owner_id (uuid, FK users)
- target_date (date)
- status (varchar 50) -- open, mitigated, accepted, closed
- sort_order (int)
- created_at, updated_at, created_by, updated_by

**risk_categories**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable)
- name (varchar 255, not null)
- description (text)
- sort_order (int)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

---

### 4.8 Requirements Management

**requirement_sets**
- id (uuid, PK)
- set_ref (varchar 50, unique, not null) -- RS-0001
- system_id (uuid, FK systems)
- set_type (varchar 20, not null) -- URS, FS, DS, CS, SRS
- title (varchar 512, not null)
- version (varchar 20, not null, default '1.0')
- status (varchar 50) -- draft, in_review, approved, superseded
- scope (text)
- purpose (text)
- references (text) -- JSON array of document references
- approved_at (timestamptz)
- effective_date (date)
- expiry_date (date, nullable)
- created_at, updated_at, created_by, updated_by

**requirement_set_versions**
- id (uuid, PK)
- set_id (uuid, FK requirement_sets)
- version_number (varchar 20, not null)
- change_summary (text)
- snapshot (text) -- JSON
- created_at, created_by

**requirements**
- id (uuid, PK)
- req_ref (varchar 50, unique, not null) -- auto-generated: URS-LIMS-001
- set_id (uuid, FK requirement_sets)
- parent_req_id (uuid, FK requirements, nullable) -- for hierarchy
- req_number (varchar 50, not null)
- section (varchar 255) -- section/category heading
- title (varchar 512, not null)
- description (text, not null)
- rationale (text)
- req_type (varchar 50) -- functional, non_functional, regulatory, interface, performance, security, data_integrity
- priority (varchar 20) -- mandatory, should, nice_to_have (MoSCoW)
- testability (varchar 20) -- testable, non_testable, partially_testable
- regulatory_citation (varchar 512)
- gxp_critical (boolean, default false)
- alcoa_attribute (varchar 50) -- attributable, legible, contemporaneous, original, accurate, complete, consistent, enduring, available
- status (varchar 50) -- draft, approved, modified, deprecated
- acceptance_criteria (text)
- notes (text)
- sort_order (int)
- created_at, updated_at, created_by, updated_by

**requirement_links**
- id (uuid, PK)
- parent_req_id (uuid, FK requirements)
- child_req_id (uuid, FK requirements)
- link_type (varchar 50) -- derives_from, implements, refines, conflicts_with
- created_at, created_by

---

### 4.9 Protocols and Test Execution

**protocols**
- id (uuid, PK)
- protocol_ref (varchar 50, unique, not null) -- IQ-LIMS-001
- system_id (uuid, FK systems)
- equipment_id (uuid, FK equipment, nullable)
- protocol_type (varchar 20, not null) -- IQ, OQ, PQ, UAT, MAV, CSV, DQ, SAT, FAT
- title (varchar 512, not null)
- version (varchar 20, not null, default '1.0')
- status (varchar 50) -- draft, in_review, approved, executing, executed, failed, voided, superseded
- objective (text)
- scope (text)
- prerequisites (text)
- hardware_requirements (text)
- software_requirements (text)
- personnel_requirements (text)
- references (text) -- JSON array
- acceptance_criteria (text)
- template_id (uuid, FK protocol_templates, nullable) -- if created from template
- environment_id (uuid, FK system_environments, nullable)
- approved_at (timestamptz)
- approved_by (uuid, FK users)
- execution_start_at (timestamptz)
- execution_end_at (timestamptz)
- executed_by (uuid, FK users)
- overall_result (varchar 20) -- pass, fail, pass_with_deviations, not_executed
- conclusion (text)
- created_at, updated_at, created_by, updated_by

**protocol_versions**
- id (uuid, PK)
- protocol_id (uuid, FK protocols)
- version_number (varchar 20, not null)
- change_summary (text)
- change_type (varchar 50) -- major, minor, administrative
- snapshot (text) -- JSON snapshot of protocol + all sections + steps
- created_at, created_by
- UNIQUE (protocol_id, version_number)

**protocol_sections**
- id (uuid, PK)
- protocol_id (uuid, FK protocols)
- section_number (varchar 20, not null)
- title (varchar 512, not null)
- description (text)
- section_type (varchar 50) -- setup, execution, acceptance, review
- sort_order (int, not null)
- created_at, updated_at, created_by, updated_by

**protocol_steps**
- id (uuid, PK)
- step_ref (varchar 50, not null) -- within-protocol reference e.g. IQ-001-S001
- protocol_id (uuid, FK protocols)
- section_id (uuid, FK protocol_sections)
- step_number (varchar 20, not null)
- title (varchar 512, not null)
- description (text, not null) -- what to do (rich text)
- expected_result (text, not null) -- what to look for
- step_type (varchar 50) -- action, check, data_entry, observation, signature, configuration, screenshot
- input_type (varchar 50) -- pass_fail, text, number, date, dropdown, checkbox, table, screenshot_required, signature_required
- input_options (text) -- JSON for dropdown options, table columns, number range
- is_mandatory (boolean, default true)
- requires_signature (boolean, default false)
- signature_meaning_id (uuid, FK signature_meanings, nullable)
- requires_screenshot (boolean, default false)
- requires_attachment (boolean, default false)
- linked_requirement_ids (text) -- JSON array of requirement IDs
- regulatory_citation (varchar 512)
- alcoa_applicable (boolean, default true)
- sort_order (int, not null)
- created_at, updated_at, created_by, updated_by

**test_scripts**
- id (uuid, PK)
- script_ref (varchar 50, unique, not null)
- protocol_id (uuid, FK protocols)
- step_id (uuid, FK protocol_steps, nullable)
- title (varchar 512, not null)
- description (text)
- script_type (varchar 50) -- manual, automated, hybrid
- script_language (varchar 50, nullable) -- python, powershell, sql, bash, robot_framework
- script_content (text) -- the actual script or automation steps
- expected_output (text)
- version (varchar 20)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**test_data_sets**
- id (uuid, PK)
- protocol_id (uuid, FK protocols)
- name (varchar 255, not null)
- description (text)
- data_content (text) -- JSON or CSV representation of test data
- is_representative (boolean, default true) -- representative/worst-case note
- created_at, updated_at, created_by, updated_by

**test_executions**
- id (uuid, PK)
- execution_ref (varchar 50, unique, not null) -- TE-IQ-LIMS-001-001
- protocol_id (uuid, FK protocols)
- execution_number (int, not null, default 1) -- for re-executions
- status (varchar 50) -- not_started, in_progress, paused, completed, abandoned
- environment_id (uuid, FK system_environments, nullable)
- executed_by (uuid, FK users)
- witnessed_by (uuid, FK users, nullable)
- started_at (timestamptz)
- completed_at (timestamptz)
- overall_result (varchar 50) -- pass, fail, pass_with_deviations, incomplete
- total_steps (int)
- steps_passed (int)
- steps_failed (int)
- steps_with_deviations (int)
- steps_not_executed (int)
- deviation_count (int, default 0)
- conclusion (text)
- notes (text)
- is_reexecution (boolean, default false)
- reexecution_reason (text)
- created_at, updated_at, created_by, updated_by

**test_execution_steps**
- id (uuid, PK)
- execution_id (uuid, FK test_executions)
- step_id (uuid, FK protocol_steps)
- sequence_number (int, not null)
- status (varchar 50) -- not_started, in_progress, passed, failed, deviation, skipped, not_applicable
- actual_result (text)
- entered_value (text) -- for data entry steps: what was entered
- pass_fail (varchar 20) -- pass, fail, n/a
- executed_by (uuid, FK users)
- executed_at (timestamptz)
- witnessed_by (uuid, FK users, nullable)
- witnessed_at (timestamptz, nullable)
- deviation_raised (boolean, default false)
- deviation_id (uuid, FK deviations, nullable)
- comments (text)
- time_started (timestamptz)
- time_completed (timestamptz)
- created_at, updated_at

**test_step_annotations**
- id (uuid, PK)
- execution_step_id (uuid, FK test_execution_steps)
- annotation_type (varchar 50) -- text, highlight, arrow, marker
- content (text)
- position_data (text) -- JSON with x, y, width, height on attachment
- file_attachment_id (uuid, FK file_attachments, nullable)
- created_at, created_by

**protocol_templates**
- id (uuid, PK)
- template_ref (varchar 50, unique, not null)
- name (varchar 512, not null)
- description (text)
- protocol_type (varchar 20, not null)
- category (varchar 100) -- software, equipment, process, infrastructure, laboratory
- industry (varchar 100) -- pharmaceutical, biotech, medical_device, cmo
- regulatory_scope (text) -- JSON array: 21cfr211, 21cfr820, annex11
- is_system_template (boolean, default false) -- ships with PHAROLON
- is_active (boolean, default true)
- version (varchar 20, not null)
- sections (text) -- JSON array of section templates
- steps (text) -- JSON array of step templates
- created_at, updated_at, created_by, updated_by

---

### 4.10 Deviations

**deviations**
- id (uuid, PK)
- deviation_ref (varchar 50, unique, not null) -- DEV-0001
- execution_id (uuid, FK test_executions, nullable)
- execution_step_id (uuid, FK test_execution_steps, nullable)
- protocol_id (uuid, FK protocols, nullable)
- system_id (uuid, FK systems, nullable)
- title (varchar 512, not null)
- description (text, not null)
- deviation_type (varchar 100) -- unexpected_result, equipment_failure, procedure_deviation, environmental, data, software
- severity (varchar 20) -- critical, major, minor
- impact_on_validation (varchar 50) -- invalidating, non_invalidating, requires_evaluation
- impact_description (text)
- immediate_action_taken (text)
- root_cause (text)
- disposition (varchar 50) -- acceptable, not_acceptable, requires_investigation, pending
- disposition_rationale (text)
- retest_required (boolean, default false)
- retest_steps (text)
- capa_required (boolean, default false)
- capa_id (uuid, FK capas, nullable)
- status (varchar 50) -- open, under_investigation, closed, voided
- raised_by (uuid, FK users)
- raised_at (timestamptz, not null)
- closed_by (uuid, FK users, nullable)
- closed_at (timestamptz, nullable)
- created_at, updated_at, created_by, updated_by

**deviation_reviews**
- id (uuid, PK)
- deviation_id (uuid, FK deviations)
- reviewer_id (uuid, FK users)
- reviewed_at (timestamptz)
- disposition (varchar 50)
- comments (text)
- signature_id (uuid, FK electronic_signatures, nullable)

---

### 4.11 Document Management

**document_categories**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable)
- parent_category_id (uuid, FK document_categories, nullable)
- name (varchar 255, not null)
- code (varchar 50)
- description (text)
- numbering_prefix (varchar 20) -- e.g. SOP-, POL-, SPEC-
- numbering_format (varchar 100) -- e.g. {prefix}{site_code}-{seq:04d}
- default_review_interval_months (int, default 24)
- requires_periodic_review (boolean, default true)
- is_controlled (boolean, default true) -- controlled documents require formal approval
- is_active (boolean)
- sort_order (int)
- created_at, updated_at, created_by, updated_by

**document_templates**
- id (uuid, PK)
- template_ref (varchar 50, unique, not null)
- category_id (uuid, FK document_categories, nullable)
- name (varchar 512, not null)
- description (text)
- doc_type (varchar 100) -- SOP, policy, specification, report, form, protocol, plan
- industry (varchar 100)
- regulatory_scope (text) -- JSON array
- is_system_template (boolean, default false)
- version (varchar 20, not null)
- body_content (text) -- rich text with variable placeholders {{variable_name}}
- available_variables (text) -- JSON: [{name, description, type, required}]
- header_content (text)
- footer_content (text)
- page_layout (text) -- JSON: margins, orientation, font, etc.
- sections (text) -- JSON array of section definitions
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**document_template_variables**
- id (uuid, PK)
- template_id (uuid, FK document_templates)
- variable_name (varchar 100, not null)
- display_name (varchar 255, not null)
- variable_type (varchar 50) -- text, date, number, user, lookup, system_field
- lookup_category_id (uuid, FK lookup_categories, nullable)
- default_value (varchar 512)
- is_required (boolean, default false)
- help_text (text)
- sort_order (int)

**documents**
- id (uuid, PK)
- doc_ref (varchar 100, unique, not null) -- SOP-MATC-0042
- site_id (uuid, FK sites)
- category_id (uuid, FK document_categories)
- template_id (uuid, FK document_templates, nullable)
- system_id (uuid, FK systems, nullable) -- if system-specific
- title (varchar 512, not null)
- current_version (varchar 20, not null, default '1.0')
- status (varchar 50) -- draft, in_review, approved, effective, obsolete, superseded, withdrawn
- doc_type (varchar 100)
- effective_date (date)
- expiry_date (date, nullable)
- next_review_date (date)
- review_interval_months (int)
- scope (text)
- purpose (text)
- regulatory_citations (text) -- JSON array
- is_controlled (boolean, default true)
- requires_training (boolean, default false)
- training_roles (text) -- JSON array of role IDs that must be trained on this document
- owner_id (uuid, FK users)
- author_id (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**document_versions**
- id (uuid, PK)
- document_id (uuid, FK documents)
- version_number (varchar 20, not null)
- change_type (varchar 50) -- major, minor, administrative
- change_summary (text)
- change_reason (text)
- body_content (text, not null) -- full rich text content of this version
- header_content (text)
- footer_content (text)
- variable_values (text) -- JSON: filled variable values for this version
- rendered_html (text) -- cached rendered HTML
- word_count (int)
- status (varchar 50)
- drafted_by (uuid, FK users)
- drafted_at (timestamptz)
- submitted_for_review_at (timestamptz)
- approved_at (timestamptz)
- approved_by (uuid, FK users)
- effective_date (date)
- superseded_at (timestamptz)
- UNIQUE (document_id, version_number)

**document_sections**
- id (uuid, PK)
- version_id (uuid, FK document_versions)
- section_number (varchar 20)
- title (varchar 512)
- content (text) -- rich text
- sort_order (int)
- is_locked (boolean, default false)
- created_at, updated_at

**document_reviews**
- id (uuid, PK)
- version_id (uuid, FK document_versions)
- reviewer_id (uuid, FK users)
- review_type (varchar 50) -- technical, quality, regulatory, peer
- status (varchar 50) -- pending, in_progress, completed, declined
- assigned_at (timestamptz)
- due_date (date)
- completed_at (timestamptz)
- decision (varchar 50) -- approved, approved_with_comments, rejected
- comments (text)
- signature_id (uuid, FK electronic_signatures, nullable)

**document_approvals**
- id (uuid, PK)
- version_id (uuid, FK document_versions)
- approver_id (uuid, FK users)
- approver_role (varchar 100) -- author, reviewer, approver, qa_approver
- sequence_number (int) -- approval order
- status (varchar 50) -- pending, approved, rejected, delegated
- assigned_at (timestamptz)
- due_date (date)
- actioned_at (timestamptz)
- decision (varchar 50)
- comments (text)
- signature_id (uuid, FK electronic_signatures)

**document_distributions**
- id (uuid, PK)
- document_id (uuid, FK documents)
- version_id (uuid, FK document_versions)
- distributed_to_type (varchar 50) -- user, role, department, all_site
- distributed_to_id (uuid, nullable)
- distributed_at (timestamptz)
- distributed_by (uuid, FK users)
- read_confirmation_required (boolean, default false)
- read_deadline (date)

**document_reads**
- id (uuid, PK)
- distribution_id (uuid, FK document_distributions)
- user_id (uuid, FK users)
- read_at (timestamptz)
- confirmation_signature_id (uuid, FK electronic_signatures, nullable)
- UNIQUE (distribution_id, user_id)

**document_links**
- id (uuid, PK)
- document_id (uuid, FK documents)
- linked_object_type (varchar 100) -- system, protocol, requirement, change_request, capa
- linked_object_id (uuid)
- link_type (varchar 50) -- reference, implements, supersedes, relates_to
- created_at, created_by

---

### 4.12 Workflow Engine

**workflow_definitions**
- id (uuid, PK)
- workflow_ref (varchar 50, unique, not null) -- WF-0001
- site_id (uuid, FK sites, nullable)
- name (varchar 512, not null)
- description (text)
- trigger_object_type (varchar 100, not null) -- document, protocol, change_request, capa, etc.
- trigger_event (varchar 100) -- on_create, on_status_change, on_field_change, manual, scheduled
- trigger_conditions (text) -- JSON: [{field, operator, value}] conditions that activate this workflow
- is_active (boolean, default true)
- allow_parallel_stages (boolean, default false)
- require_all_approvers (boolean, default true) -- vs. any one approver
- allow_self_approval (boolean, default false)
- notify_on_completion (boolean, default true)
- version (int, default 1)
- created_at, updated_at, created_by, updated_by

**workflow_stages**
- id (uuid, PK)
- definition_id (uuid, FK workflow_definitions)
- stage_number (int, not null)
- name (varchar 255, not null)
- description (text)
- stage_type (varchar 50) -- review, approval, notification, task, conditional, parallel
- assignee_type (varchar 50) -- specific_user, role, department, record_field, previous_stage_actor
- assignee_user_id (uuid, FK users, nullable)
- assignee_role_id (uuid, FK roles, nullable)
- assignee_department_id (uuid, FK departments, nullable)
- assignee_field (varchar 100, nullable) -- e.g. owner_id, technical_owner_id on the target object
- sla_hours (int) -- hours to complete this stage
- escalation_hours (int) -- hours after SLA before escalating
- escalate_to_user_id (uuid, FK users, nullable)
- escalate_to_role_id (uuid, FK roles, nullable)
- allow_delegation (boolean, default true)
- required_signature_meaning_id (uuid, FK signature_meanings, nullable)
- embedded_form_id (uuid, FK form_definitions, nullable) -- additional data capture in this stage
- instructions (text) -- shown to the assignee
- rejection_goes_to_stage (int, nullable) -- which stage number to return to on rejection
- sort_order (int, not null)
- is_optional (boolean, default false)
- created_at, updated_at, created_by, updated_by

**workflow_stage_conditions**
- id (uuid, PK)
- stage_id (uuid, FK workflow_stages)
- condition_type (varchar 50) -- skip_if, execute_if
- field_path (varchar 255) -- e.g. severity, gxp_relevant
- operator (varchar 50) -- equals, not_equals, greater_than, contains, is_null
- value (varchar 512)
- created_at, updated_at, created_by, updated_by

**workflow_transitions**
- id (uuid, PK)
- definition_id (uuid, FK workflow_definitions)
- from_stage_id (uuid, FK workflow_stages, nullable) -- null = start
- to_stage_id (uuid, FK workflow_stages, nullable) -- null = end
- condition (text) -- JSON condition set, null = unconditional
- transition_type (varchar 50) -- approve, reject, delegate, escalate, auto

**workflow_instances**
- id (uuid, PK)
- instance_ref (varchar 50, unique, not null) -- WFI-0001
- definition_id (uuid, FK workflow_definitions)
- object_type (varchar 100, not null)
- object_id (uuid, not null)
- current_stage_id (uuid, FK workflow_stages, nullable)
- status (varchar 50) -- active, completed, cancelled, suspended, escalated
- initiated_by (uuid, FK users)
- initiated_at (timestamptz, not null)
- completed_at (timestamptz, nullable)
- cancelled_at (timestamptz, nullable)
- cancel_reason (text)
- context_data (text) -- JSON snapshot of the triggering object

**workflow_instance_stages**
- id (uuid, PK)
- instance_id (uuid, FK workflow_instances)
- stage_id (uuid, FK workflow_stages)
- assigned_to (uuid, FK users, not null)
- assigned_at (timestamptz)
- due_at (timestamptz)
- status (varchar 50) -- pending, in_progress, completed, skipped, escalated
- started_at (timestamptz)
- completed_at (timestamptz)
- action_taken (varchar 50) -- approved, rejected, delegated
- delegated_to (uuid, FK users, nullable)
- comments (text)
- form_submission_id (uuid, FK form_submissions, nullable)
- signature_id (uuid, FK electronic_signatures, nullable)

**workflow_escalations**
- id (uuid, PK)
- instance_stage_id (uuid, FK workflow_instance_stages)
- escalated_at (timestamptz)
- escalated_to (uuid, FK users)
- escalation_reason (varchar 255)
- resolved_at (timestamptz)
- resolution (varchar 255)

---

### 4.13 Form Builder

**form_definitions**
- id (uuid, PK)
- form_ref (varchar 50, unique, not null)
- site_id (uuid, FK sites, nullable)
- name (varchar 512, not null)
- description (text)
- form_purpose (varchar 100) -- standalone, workflow_stage, protocol_step, deviation_capture, risk_input
- is_active (boolean, default true)
- version (int, default 1)
- created_at, updated_at, created_by, updated_by

**form_sections**
- id (uuid, PK)
- form_id (uuid, FK form_definitions)
- title (varchar 512)
- description (text)
- sort_order (int, not null)
- is_repeatable (boolean, default false) -- for dynamic row groups
- repeat_label (varchar 255) -- "Add another item"
- conditional_show_field (varchar 100, nullable) -- show section only if this field has value
- conditional_show_value (varchar 512, nullable)

**form_fields**
- id (uuid, PK)
- section_id (uuid, FK form_sections)
- field_key (varchar 100, not null) -- internal key used in JSON submission
- label (varchar 512, not null)
- help_text (text)
- field_type (varchar 50, not null) -- text, textarea, number, date, datetime, select, multiselect, radio, checkbox, file_upload, signature, user_picker, rich_text, table, calculated
- is_required (boolean, default false)
- is_readonly (boolean, default false)
- placeholder (varchar 512)
- default_value (varchar 512)
- min_length (int, nullable)
- max_length (int, nullable)
- min_value (decimal, nullable)
- max_value (decimal, nullable)
- regex_pattern (varchar 512, nullable)
- regex_message (varchar 512)
- lookup_category_id (uuid, FK lookup_categories, nullable)
- options (text) -- JSON array for select/radio/checkbox
- table_columns (text) -- JSON for table field type
- calculation_formula (text) -- for calculated fields
- signature_meaning_id (uuid, FK signature_meanings, nullable)
- conditional_show_field_key (varchar 100, nullable)
- conditional_show_value (varchar 512, nullable)
- regulatory_citation (varchar 512)
- sort_order (int, not null)

**form_submissions**
- id (uuid, PK)
- submission_ref (varchar 50, unique, not null)
- form_id (uuid, FK form_definitions)
- form_version (int, not null)
- object_type (varchar 100, nullable) -- if linked to a record
- object_id (uuid, nullable)
- context (varchar 100) -- workflow_stage, protocol_step, standalone
- status (varchar 50) -- draft, submitted, approved, rejected
- submitted_by (uuid, FK users)
- submitted_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**form_submission_data**
- id (uuid, PK)
- submission_id (uuid, FK form_submissions)
- field_id (uuid, FK form_fields)
- field_key (varchar 100, not null) -- snapshot of key
- value_text (text)
- value_number (decimal)
- value_date (date)
- value_datetime (timestamptz)
- value_boolean (boolean)
- value_json (text) -- for multi-select, table, complex fields
- file_id (uuid, FK file_store, nullable)
- signature_id (uuid, FK electronic_signatures, nullable)
- entered_at (timestamptz)
- entered_by (uuid, FK users)

---

### 4.14 Notifications

**notification_templates**
- id (uuid, PK)
- code (varchar 100, unique, not null)
- name (varchar 255, not null)
- description (text)
- channel (varchar 50) -- email, in_app, both
- subject_template (varchar 512)
- body_template (text) -- supports {{variable}} placeholders
- available_variables (text) -- JSON
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**notification_rules**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable)
- name (varchar 255, not null)
- template_id (uuid, FK notification_templates)
- trigger_event (varchar 255, not null) -- e.g. protocol.status_changed, deviation.raised
- trigger_conditions (text) -- JSON conditions
- recipient_type (varchar 50) -- user, role, department, record_field
- recipient_user_id (uuid, FK users, nullable)
- recipient_role_id (uuid, FK roles, nullable)
- recipient_field (varchar 100, nullable) -- field on the triggering object to get recipient
- delay_minutes (int, default 0)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**notifications**
- id (uuid, PK)
- rule_id (uuid, FK notification_rules, nullable)
- recipient_id (uuid, FK users, not null)
- template_id (uuid, FK notification_templates)
- subject (varchar 512)
- body (text)
- object_type (varchar 100)
- object_id (uuid)
- object_display (varchar 512) -- human readable reference
- channel (varchar 50)
- is_read (boolean, default false)
- read_at (timestamptz)
- sent_at (timestamptz)
- email_status (varchar 50) -- pending, sent, failed, bounced
- email_error (text)
- created_at (timestamptz)

---

### 4.15 Change Control

**change_requests**
- id (uuid, PK)
- cr_ref (varchar 50, unique, not null) -- CR-0001
- site_id (uuid, FK sites)
- title (varchar 512, not null)
- description (text, not null)
- change_type (varchar 100) -- planned, emergency, administrative
- change_category (varchar 100) -- software_upgrade, configuration, hardware, procedure, process, infrastructure
- rationale (text, not null)
- business_benefit (text)
- affected_systems (text) -- JSON array of system IDs
- affected_documents (text) -- JSON array of document IDs
- affected_equipment (text) -- JSON array of equipment IDs
- validation_impact (varchar 50) -- major_revalidation, partial_revalidation, no_impact, assessment_required
- validation_impact_justification (text)
- regulatory_impact (boolean, default false)
- regulatory_impact_description (text)
- risk_level (varchar 50) -- high, medium, low
- risk_assessment_id (uuid, FK risk_assessments, nullable)
- proposed_implementation_date (date)
- actual_implementation_date (date, nullable)
- rollback_plan (text)
- status (varchar 50) -- draft, submitted, impact_assessment, in_review, approved, rejected, implementing, implemented, verified, closed, cancelled
- emergency_justification (text, nullable)
- requestor_id (uuid, FK users)
- owner_id (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**change_request_versions**
- id (uuid, PK)
- cr_id (uuid, FK change_requests)
- version_number (int, not null)
- change_summary (text)
- snapshot (text) -- JSON
- created_at, created_by

**change_impact_assessments**
- id (uuid, PK)
- cr_id (uuid, FK change_requests)
- assessed_by (uuid, FK users)
- assessment_date (date)
- gxp_impact (boolean)
- gxp_impact_description (text)
- systems_impacted (text) -- JSON
- documents_requiring_update (text) -- JSON
- testing_required (boolean)
- testing_scope (text)
- training_required (boolean)
- training_description (text)
- downtime_required (boolean)
- estimated_downtime_hours (decimal)
- risk_summary (text)
- overall_recommendation (varchar 50) -- proceed, proceed_with_conditions, reject
- conditions (text)
- signature_id (uuid, FK electronic_signatures)

**change_tasks**
- id (uuid, PK)
- cr_id (uuid, FK change_requests)
- task_ref (varchar 50, unique)
- title (varchar 512, not null)
- description (text)
- task_type (varchar 100) -- implementation, testing, documentation, training, verification
- assigned_to (uuid, FK users)
- due_date (date)
- status (varchar 50) -- not_started, in_progress, completed, cancelled
- completion_notes (text)
- completed_at (timestamptz)
- completed_by (uuid, FK users)
- requires_evidence (boolean, default false)
- created_at, updated_at, created_by, updated_by

**change_verifications**
- id (uuid, PK)
- cr_id (uuid, FK change_requests)
- verified_by (uuid, FK users)
- verification_date (date)
- verification_method (varchar 255)
- outcome (varchar 50) -- successful, unsuccessful, partial
- notes (text)
- signature_id (uuid, FK electronic_signatures)
- created_at, updated_at, created_by, updated_by

---

### 4.16 CAPA Management

**capas**
- id (uuid, PK)
- capa_ref (varchar 50, unique, not null) -- CAPA-0001
- site_id (uuid, FK sites)
- title (varchar 512, not null)
- description (text, not null)
- capa_type (varchar 50) -- corrective, preventive, both
- source_type (varchar 100) -- deviation, nonconformance, audit_finding, complaint, trend, self_identified
- source_id (uuid, nullable) -- FK to the source record
- source_description (text) -- description if no linked record
- severity (varchar 50) -- critical, major, minor
- gxp_impact (boolean, default false)
- regulatory_reportable (boolean, default false)
- problem_statement (text, not null)
- immediate_action (text)
- root_cause_method (varchar 100) -- fishbone, 5why, fmea, fault_tree, pareto
- root_cause_description (text)
- root_cause_category (varchar 100) -- people, process, equipment, materials, environment, measurement
- status (varchar 50) -- draft, open, in_progress, effectiveness_check, closed, cancelled
- target_completion_date (date)
- actual_completion_date (date, nullable)
- owner_id (uuid, FK users)
- qa_owner_id (uuid, FK users)
- effectiveness_check_required (boolean, default true)
- effectiveness_check_date (date, nullable)
- effectiveness_check_result (varchar 50) -- effective, not_effective, partially_effective
- effectiveness_check_notes (text)
- closure_justification (text)
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**capa_actions**
- id (uuid, PK)
- capa_id (uuid, FK capas)
- action_number (int, not null)
- action_type (varchar 50) -- corrective, preventive, containment
- title (varchar 512, not null)
- description (text, not null)
- responsible_id (uuid, FK users)
- target_date (date)
- actual_completion_date (date, nullable)
- status (varchar 50) -- not_started, in_progress, completed, overdue, cancelled
- completion_evidence (text)
- verified_by (uuid, FK users, nullable)
- verified_at (timestamptz, nullable)
- verification_notes (text)
- created_at, updated_at, created_by, updated_by

**capa_root_cause_analysis**
- id (uuid, PK)
- capa_id (uuid, FK capas)
- analysis_method (varchar 100) -- 5why, fishbone, fault_tree
- analysis_content (text) -- JSON structured analysis
- facilitator_id (uuid, FK users)
- analysis_date (date)
- participants (text) -- JSON array of user IDs
- conclusions (text)
- created_at, updated_at, created_by, updated_by

**capa_links**
- id (uuid, PK)
- capa_id (uuid, FK capas)
- linked_object_type (varchar 100) -- system, change_request, protocol, document
- linked_object_id (uuid)
- link_type (varchar 50) -- caused_by, resulted_in, relates_to, prevents
- created_at, created_by

---

### 4.17 Nonconformance

**nonconformances**
- id (uuid, PK)
- nc_ref (varchar 50, unique, not null) -- NC-0001
- site_id (uuid, FK sites)
- title (varchar 512, not null)
- description (text, not null)
- nc_type (varchar 100) -- system_outage, data_integrity, procedure_deviation, access_control, backup_failure, vendor
- affected_system_id (uuid, FK systems, nullable)
- affected_equipment_id (uuid, FK equipment, nullable)
- gxp_impact (boolean, default false)
- impact_description (text)
- immediate_action (text)
- reported_by (uuid, FK users)
- reported_at (timestamptz, not null)
- incident_date (date)
- incident_time (time, nullable)
- discovered_by (uuid, FK users)
- disposition (varchar 50) -- pending, acceptable, not_acceptable, requires_capa
- disposition_rationale (text)
- capa_required (boolean, default false)
- capa_id (uuid, FK capas, nullable)
- status (varchar 50) -- open, under_investigation, closed, voided
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**nc_investigations**
- id (uuid, PK)
- nc_id (uuid, FK nonconformances)
- investigator_id (uuid, FK users)
- investigation_start_date (date)
- investigation_end_date (date)
- timeline_of_events (text)
- root_cause (text)
- contributing_factors (text)
- extent_of_impact (text)
- patient_safety_impact (boolean, default false)
- product_quality_impact (boolean, default false)
- data_integrity_impact (boolean, default false)
- recommendations (text)
- created_at, updated_at, created_by, updated_by

---

### 4.18 Periodic Review

**periodic_review_schedules**
- id (uuid, PK)
- site_id (uuid, FK sites)
- object_type (varchar 100, not null) -- system, document, equipment, vendor
- object_id (uuid, not null)
- review_interval_months (int, not null)
- last_review_date (date)
- next_review_date (date, not null)
- lead_time_days (int, default 30) -- days before to send notification
- reviewer_id (uuid, FK users)
- secondary_reviewer_id (uuid, FK users, nullable)
- qa_reviewer_id (uuid, FK users, nullable)
- is_active (boolean, default true)
- notes (text)
- created_at, updated_at, created_by, updated_by

**periodic_reviews**
- id (uuid, PK)
- review_ref (varchar 50, unique, not null) -- PR-0001
- schedule_id (uuid, FK periodic_review_schedules)
- object_type (varchar 100, not null)
- object_id (uuid, not null)
- review_type (varchar 50) -- scheduled, triggered, initial
- review_period_start (date)
- review_period_end (date)
- review_date (date)
- status (varchar 50) -- scheduled, in_progress, completed, overdue, waived
- reviewer_id (uuid, FK users)
- outcome (varchar 50) -- continue_as_is, requires_update, revalidation_required, decommission
- outcome_description (text)
- findings_summary (text)
- recommendations (text)
- next_review_date (date)
- completed_at (timestamptz)
- approved_by (uuid, FK users)
- approved_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**periodic_review_items**
- id (uuid, PK)
- review_id (uuid, FK periodic_reviews)
- item_category (varchar 100) -- change_history, incident_history, deviation_summary, training_status, calibration_status, vendor_changes
- item_description (text, not null)
- finding (varchar 50) -- satisfactory, concern, action_required
- finding_detail (text)
- action_required (boolean, default false)
- action_description (text)
- action_owner (uuid, FK users, nullable)
- action_due_date (date, nullable)
- sort_order (int)
- created_at, updated_at, created_by, updated_by

**periodic_review_findings**
- id (uuid, PK)
- review_id (uuid, FK periodic_reviews)
- finding_number (int, not null)
- category (varchar 100)
- description (text, not null)
- severity (varchar 50)
- requires_capa (boolean, default false)
- capa_id (uuid, FK capas, nullable)
- status (varchar 50)
- created_at, updated_at, created_by, updated_by

---

### 4.19 Traceability

**traceability_links**
- id (uuid, PK)
- site_id (uuid, FK sites)
- source_type (varchar 50, not null) -- requirement
- source_id (uuid, not null) -- requirement ID
- target_type (varchar 50, not null) -- protocol_step, test_execution_step, document, risk_item
- target_id (uuid, not null)
- link_type (varchar 50) -- verified_by, implemented_by, documented_in, mitigated_by
- created_at, created_by

**traceability_matrices**
- id (uuid, PK)
- matrix_ref (varchar 50, unique, not null)
- system_id (uuid, FK systems)
- title (varchar 512)
- generated_at (timestamptz)
- generated_by (uuid, FK users)
- status (varchar 50) -- current, superseded
- coverage_percentage (decimal) -- computed: % of requirements with test coverage
- total_requirements (int)
- requirements_with_tests (int)
- requirements_tested_and_passed (int)
- snapshot (text) -- JSON full matrix at generation time
- is_approved (boolean, default false)
- approved_by (uuid, FK users, nullable)
- approved_at (timestamptz, nullable)

---

### 4.20 Vendor and Supplier

**vendors**
- id (uuid, PK)
- vendor_ref (varchar 50, unique, not null) -- VEND-0001
- name (varchar 512, not null)
- legal_name (varchar 512)
- vendor_type (varchar 100) -- software, equipment, services, materials, contract_lab
- website (varchar 512)
- address_line1, address_line2, city, state, postal_code, country
- primary_contact_name (varchar 255)
- primary_contact_email (varchar 255)
- primary_contact_phone (varchar 50)
- qualification_status (varchar 50) -- not_qualified, qualified, conditionally_qualified, disqualified
- qualification_date (date)
- requalification_date (date)
- risk_level (varchar 50) -- critical, major, minor
- is_gxp_critical (boolean, default false)
- notes (text)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**vendor_contacts**
- id (uuid, PK)
- vendor_id (uuid, FK vendors)
- name (varchar 255, not null)
- title (varchar 100)
- email (varchar 255)
- phone (varchar 50)
- contact_type (varchar 100) -- technical, quality, commercial, regulatory, escalation
- is_primary (boolean, default false)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**vendor_qualifications**
- id (uuid, PK)
- qualification_ref (varchar 50, unique)
- vendor_id (uuid, FK vendors)
- qualification_type (varchar 100) -- initial, periodic, for_cause
- qualification_date (date)
- next_qualification_date (date)
- scope (text)
- outcome (varchar 50) -- qualified, conditionally_qualified, not_qualified
- conditions (text)
- notes (text)
- qualified_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**vendor_audits**
- id (uuid, PK)
- audit_ref (varchar 50, unique)
- vendor_id (uuid, FK vendors)
- audit_date (date)
- audit_type (varchar 100) -- on_site, remote, questionnaire
- lead_auditor_id (uuid, FK users)
- co_auditors (text) -- JSON array of user IDs
- scope (text)
- outcome (varchar 50) -- satisfactory, minor_findings, major_findings, critical_findings
- findings_count_critical (int, default 0)
- findings_count_major (int, default 0)
- findings_count_minor (int, default 0)
- observations_count (int, default 0)
- report_status (varchar 50)
- created_at, updated_at, created_by, updated_by

---

### 4.21 Audit Management (Internal/External)

**audits**
- id (uuid, PK)
- audit_ref (varchar 50, unique, not null) -- AUD-0001
- site_id (uuid, FK sites)
- audit_type (varchar 50) -- internal, external, regulatory, supplier
- audit_name (varchar 512, not null)
- auditing_body (varchar 255) -- FDA, EMA, ISO Registrar, internal, client
- scope (text)
- start_date (date)
- end_date (date)
- lead_auditor (varchar 255) -- external auditor name
- internal_coordinator_id (uuid, FK users)
- status (varchar 50) -- scheduled, in_progress, completed, response_due, closed
- outcome (varchar 50) -- no_findings, observations_only, minor_findings, major_findings, warning_letter
- response_due_date (date)
- created_at, updated_at, created_by, updated_by

**audit_findings**
- id (uuid, PK)
- finding_ref (varchar 50, unique, not null)
- audit_id (uuid, FK audits)
- finding_number (int, not null)
- category (varchar 100) -- data_integrity, procedure, training, documentation, equipment, capa, change_control
- cfr_citation (varchar 512)
- description (text, not null)
- severity (varchar 50) -- observation, minor, major, critical
- system_id (uuid, FK systems, nullable)
- document_id (uuid, FK documents, nullable)
- status (varchar 50) -- open, response_submitted, accepted, closed
- response_due_date (date)
- response_text (text)
- response_submitted_by (uuid, FK users)
- response_submitted_at (timestamptz)
- capa_required (boolean, default false)
- capa_id (uuid, FK capas, nullable)
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

---

### 4.22 Training Records

**training_requirements**
- id (uuid, PK)
- site_id (uuid, FK sites)
- name (varchar 512, not null)
- description (text)
- training_type (varchar 100) -- document_read, instructor_led, computer_based, on_the_job, qualification
- linked_document_id (uuid, FK documents, nullable)
- required_for_roles (text) -- JSON array of role IDs
- required_for_departments (text) -- JSON array of department IDs
- frequency (varchar 50) -- once, annual, biennial, on_change, on_hire
- frequency_months (int, nullable)
- requires_assessment (boolean, default false)
- passing_score (int, nullable)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**training_assignments**
- id (uuid, PK)
- requirement_id (uuid, FK training_requirements)
- user_id (uuid, FK users)
- assigned_at (timestamptz)
- due_date (date)
- status (varchar 50) -- assigned, in_progress, completed, overdue, waived
- waived_by (uuid, FK users, nullable)
- waiver_reason (text)
- created_at, updated_at, created_by, updated_by

**training_records**
- id (uuid, PK)
- training_ref (varchar 50, unique)
- assignment_id (uuid, FK training_assignments, nullable)
- requirement_id (uuid, FK training_requirements)
- user_id (uuid, FK users)
- completion_date (date, not null)
- training_method (varchar 100)
- trainer_id (uuid, FK users, nullable)
- assessment_score (int, nullable)
- assessment_passed (boolean, nullable)
- expiry_date (date, nullable)
- certificate_number (varchar 255)
- notes (text)
- signature_id (uuid, FK electronic_signatures)
- created_at, updated_at, created_by, updated_by

---

### 4.23 Reports and Dashboards

**report_definitions**
- id (uuid, PK)
- report_ref (varchar 50, unique, not null)
- site_id (uuid, FK sites, nullable)
- name (varchar 512, not null)
- description (text)
- report_type (varchar 100) -- tabular, chart, matrix, executive_summary, compliance_status, traceability
- data_source (varchar 100) -- module identifier
- query_config (text) -- JSON: filters, grouping, sorting, columns
- chart_config (text) -- JSON: chart type, x-axis, y-axis, series
- output_formats (text) -- JSON array: pdf, excel, csv, html
- is_system_report (boolean, default false)
- is_active (boolean, default true)
- created_at, updated_at, created_by, updated_by

**report_runs**
- id (uuid, PK)
- definition_id (uuid, FK report_definitions)
- run_by (uuid, FK users)
- parameters (text) -- JSON filters applied
- status (varchar 50) -- queued, running, completed, failed
- started_at (timestamptz)
- completed_at (timestamptz)
- output_format (varchar 20)
- file_id (uuid, FK file_store, nullable)
- row_count (int)
- error_message (text)
- created_at (timestamptz)

**report_schedules**
- id (uuid, PK)
- definition_id (uuid, FK report_definitions)
- name (varchar 255)
- schedule_type (varchar 50) -- daily, weekly, monthly, quarterly
- schedule_cron (varchar 100)
- parameters (text) -- JSON
- output_format (varchar 20)
- recipients (text) -- JSON array of user IDs or email addresses
- is_active (boolean)
- last_run_at (timestamptz)
- next_run_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**dashboard_configs**
- id (uuid, PK)
- site_id (uuid, FK sites, nullable)
- name (varchar 512, not null)
- description (text)
- is_default (boolean, default false)
- target_roles (text) -- JSON array of role IDs (null = all)
- layout (text) -- JSON grid layout
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**dashboard_widgets**
- id (uuid, PK)
- dashboard_id (uuid, FK dashboard_configs)
- widget_type (varchar 100) -- kpi_card, pie_chart, bar_chart, line_chart, table, activity_feed, calendar, countdown
- title (varchar 512)
- data_source (varchar 100)
- query_config (text) -- JSON
- display_config (text) -- JSON: colors, labels, thresholds
- position_x (int)
- position_y (int)
- width (int)
- height (int)
- refresh_minutes (int, default 60)
- sort_order (int)

**user_dashboard_preferences**
- id (uuid, PK)
- user_id (uuid, FK users)
- dashboard_id (uuid, FK dashboard_configs)
- custom_layout (text) -- JSON: user overrides
- is_favorite (boolean, default false)
- updated_at (timestamptz)

---

### 4.24 System Configuration

**site_settings**
- id (uuid, PK)
- site_id (uuid, FK sites, unique)
- setting_key (varchar 255, not null)
- setting_value (text)
- setting_type (varchar 50) -- string, integer, boolean, json
- description (text)
- is_sensitive (boolean, default false) -- masked in UI
- updated_at (timestamptz)
- updated_by (uuid, FK users)

**feature_flags**
- id (uuid, PK)
- flag_key (varchar 100, unique, not null)
- display_name (varchar 255)
- description (text)
- is_enabled (boolean, default false)
- enabled_for_sites (text) -- JSON array, null = all
- updated_at, updated_by

**smtp_configs**
- id (uuid, PK)
- site_id (uuid, FK sites)
- host (varchar 512, not null)
- port (int, not null)
- use_tls (boolean, default true)
- use_ssl (boolean, default false)
- username (varchar 255)
- encrypted_password (text)
- from_address (varchar 255, not null)
- from_name (varchar 255)
- is_active (boolean, default true)
- last_tested_at (timestamptz)
- last_test_result (varchar 50)
- created_at, updated_at, created_by, updated_by

**ldap_configs**
- id (uuid, PK)
- site_id (uuid, FK sites)
- server_url (varchar 512, not null)
- bind_dn (varchar 512)
- encrypted_bind_password (text)
- base_dn (varchar 512, not null)
- user_search_filter (varchar 512)
- username_attribute (varchar 100, default 'sAMAccountName')
- email_attribute (varchar 100, default 'mail')
- full_name_attribute (varchar 100, default 'displayName')
- group_search_base (varchar 512)
- group_filter (varchar 512)
- is_active (boolean, default true)
- last_sync_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**integration_configs**
- id (uuid, PK)
- site_id (uuid, FK sites)
- integration_type (varchar 100) -- trackwise, lims, erp, slack, teams, jira
- name (varchar 255)
- config (text) -- encrypted JSON
- is_active (boolean)
- last_health_check_at (timestamptz)
- health_check_status (varchar 50)
- created_at, updated_at, created_by, updated_by

**integration_logs**
- id (uuid, PK)
- config_id (uuid, FK integration_configs)
- direction (varchar 20) -- inbound, outbound
- event_type (varchar 100)
- payload_summary (text)
- status (varchar 50) -- success, failed, partial
- error_message (text)
- executed_at (timestamptz)
- duration_ms (int)

**webhooks**
- id (uuid, PK)
- site_id (uuid, FK sites)
- name (varchar 255)
- url (varchar 1024, not null)
- secret (varchar 255) -- for HMAC signature verification
- events (text) -- JSON array of event types to send
- is_active (boolean)
- failure_count (int, default 0)
- last_triggered_at (timestamptz)
- last_success_at (timestamptz)
- created_at, updated_at, created_by, updated_by

**webhook_deliveries**
- id (uuid, PK)
- webhook_id (uuid, FK webhooks)
- event_type (varchar 100)
- payload (text) -- JSON
- response_status_code (int)
- response_body (text)
- duration_ms (int)
- success (boolean)
- delivered_at (timestamptz)
- retry_count (int, default 0)

**system_health_log**
- id (uuid, PK)
- check_type (varchar 100) -- database, disk, redis, celery, smtp, audit_chain
- status (varchar 50) -- healthy, degraded, unhealthy
- details (text)
- checked_at (timestamptz)

---

## 5. Phase Plan

### Summary Timeline

| Phase | Name | Months | Deliverable |
|---|---|---|---|
| 0 | Foundation and SDL | 1-2 | Project infrastructure, base architecture, auth |
| 1 | Core Data Layer | 2-3 | Complete DB schema deployed, seed data |
| 2 | Application Shell | 3-4 | Full UI shell, navigation, design system |
| 3 | System Inventory | 4-5 | System and equipment inventory modules |
| 4 | Risk Assessment | 5-6 | Risk assessment engine |
| 5 | Requirements | 6-7 | Requirements management |
| 6 | Protocol Engine | 7-9 | Protocol builder and test execution |
| 7 | Document Management | 9-11 | Document library and template engine |
| 8 | Workflow Engine | 11-13 | Low-code workflow builder |
| 9 | Change Control | 13-14 | Change control module |
| 10 | CAPA and NCE | 14-15 | CAPA and nonconformance modules |
| 11 | Periodic Review | 15-16 | Review scheduler and execution |
| 12 | Traceability and RTM | 16-17 | Automated traceability matrix |
| 13 | Reporting | 17-18 | Report builder and dashboards |
| 14 | Vendor and Audit | 18-19 | Vendor qualification, audit management |
| 15 | Training Records | 19-20 | Training management |
| 16 | Validation Package | 20-21 | Self-contained IQ/OQ/PQ for OpenVAL |
| 17 | Template Library | 21-22 | Full pharma template library |
| 18 | Administration | 22-23 | LDAP, SSO, integrations, API |
| 19 | Hardening | 23-24 | Performance, security audit, pen test |
| 20 | Packaging | 24+ | Docker option, installer polish, community |

---

### Phase 0: Foundation and SDL (Months 1-2)

**Goal:** Establish the development environment, SDL documentation, and core backend structure. Every subsequent phase builds on this.

**Backend Tasks**
- [ ] Initialize FastAPI project structure
- [ ] Configure SQLAlchemy 2.0 with async support
- [ ] Set up Alembic for migrations
- [ ] Implement core configuration management (environment-based)
- [ ] Build database session management with connection pooling
- [ ] Implement JWT authentication with refresh token rotation
- [ ] Implement TOTP MFA (PyOTP) with backup codes
- [ ] Build audit trail engine as middleware (intercepts all writes)
- [ ] Build electronic signature engine with re-authentication
- [ ] Implement RBAC permission checking middleware
- [ ] Set up Celery + Redis for background tasks
- [ ] Configure structured logging (JSON format, request correlation IDs)
- [ ] Set up Pytest with factory_boy fixtures

**Frontend Tasks**
- [ ] Initialize React 18 + TypeScript + Vite project
- [ ] Configure Tailwind CSS with custom design tokens
- [ ] Implement Zustand store architecture
- [ ] Build API client (Axios with interceptors for auth, error handling, retry)
- [ ] Build AppShell component (header + sidebar + content)
- [ ] Build authentication pages (login, MFA entry, password reset, password change)
- [ ] Build base UI component library (Button, Input, Select, Modal, Toast, Badge, Table skeleton)
- [ ] Implement route protection and RBAC-based UI gating
- [ ] Set up React Hook Form + Zod for all forms

**Infrastructure Tasks**
- [ ] Write install.sh bare metal installer (PostgreSQL, Redis, Python env, Node, Nginx, systemd)
- [ ] Write systemd unit files for API server and Celery worker
- [ ] Write Nginx configuration template
- [ ] Write environment variable template (.env.example)
- [ ] Write database initialization script with seed data
- [ ] Write backup.sh and restore.sh scripts

**SDL Documentation Tasks**
- [ ] Write Software Development Lifecycle (SDL) document
- [ ] Write Software Description document
- [ ] Write Architecture Decision Record template
- [ ] Establish branching strategy and release process
- [ ] Write CHANGELOG format specification with validation impact classification
- [ ] Set up GitHub issue templates (bug, feature, change, regulatory_impact)

---

### Phase 1: Core Data Layer (Month 2-3)

**Goal:** All 100+ tables defined in the schema deployed and tested. Seed data populates all lookup tables.

**Tasks**
- [ ] Generate all Alembic migrations from schema
- [ ] Write seed data scripts:
  - All signature_meanings (APPROVED, REVIEWED, AUTHORED, EXECUTED, WITNESSED, VERIFIED)
  - All lookup_categories and base lookup_values (GAMP categories, risk levels, protocol types, document types, NC types, CAPA sources, etc.)
  - Default roles (System Admin, QA Manager, QA Associate, Validation Engineer, Technical Owner, Business Owner, Read Only, Auditor)
  - Default permissions matrix (all module/action combinations)
  - Default risk matrix (5x5 probability/impact, FMEA)
  - Default notification templates for all system events
  - Base regulatory references (21 CFR 11, 21 CFR 211, 21 CFR 820, Annex 11, GAMP 5)
  - Feature to regulatory citation mappings
- [ ] Write database integrity check script (validates audit trail hash chain)
- [ ] Write row-level security policies for audit_log and electronic_signatures (append-only enforcement)
- [ ] Write database backup verification script

---

### Phase 2: Application Shell and Design System (Months 3-4)

**Goal:** Every page in the application has a consistent, professional shell. Users can navigate, search, and manage their profile.

**Tasks**
- [ ] Build full AppShell with responsive sidebar (collapsible on mobile)
- [ ] Build Header with site selector, global search, notification bell, user menu
- [ ] Build Sidebar with grouped navigation, active state, badge counts (tasks, notifications)
- [ ] Build Breadcrumb component (auto-generated from route)
- [ ] Build PageHeader component (title, subtitle, action buttons)
- [ ] Build complete DataTable component (sortable, filterable, paginated, column config, bulk actions, export)
- [ ] Build FilterBar component (search + multi-filter with saved filters)
- [ ] Build StatusBadge universal component
- [ ] Build DetailPanel (slide-in right panel for record preview)
- [ ] Build SignatureCapture modal (re-auth + meaning selection + confirmation)
- [ ] Build TimelineView (audit trail display)
- [ ] Build CommentThread component
- [ ] Build VersionSelector component
- [ ] Build ApprovalPanel component
- [ ] Build ProgressTracker component
- [ ] Build RichTextEditor (TipTap with toolbar: headings, bold, italic, lists, tables, links, images)
- [ ] Build FileUpload (drag-drop, multiple files, preview, progress)
- [ ] Build EmptyState components for each module
- [ ] Build LoadingSkeleton components
- [ ] Build NotificationToast system
- [ ] Build ConfirmDialog
- [ ] Build user profile page (personal info, MFA setup, password change, preferences)
- [ ] Build notification center (in-app notification list, mark read, filters)
- [ ] Build global search results page
- [ ] Build home dashboard shell (empty state with widget placeholders)
- [ ] Build site/organization settings page (admin only)

---

### Phase 3: System and Equipment Inventory (Months 4-5)

**Goal:** Complete system and equipment inventory with GAMP 5 classification, GxP impact assessment, lifecycle tracking, and validation status visibility.

**System Inventory Tasks**
- [ ] System list page (DataTable: ref, name, GAMP category, status, validated status, owner, next review)
- [ ] System detail page with tabbed layout:
  - Overview (all fields, quick actions)
  - Components tab
  - Interfaces tab
  - Environments tab
  - Documents tab (linked documents)
  - Protocols tab (linked protocols)
  - Change History tab
  - Periodic Reviews tab
  - Audit Trail tab
- [ ] System create/edit form with GAMP 5 classification wizard
- [ ] GxP Impact Assessment wizard (guided questions mapping to impact areas)
- [ ] System version history view
- [ ] System interfaces diagram (visual dependency map)
- [ ] System data flow documentation
- [ ] Bulk import from CSV
- [ ] Validation status dashboard widget

**Equipment Tasks**
- [ ] Equipment list page
- [ ] Equipment detail page with tabs (Overview, Calibration, Maintenance, Documents, Protocols, Audit)
- [ ] Calibration record management (log, view history, upcoming calibrations calendar)
- [ ] Maintenance record management
- [ ] Equipment status board (overdue calibrations highlighted)

---

### Phase 4: Risk Assessment (Months 5-6)

**Goal:** Full FMEA and probability/impact risk assessment engine with configurable matrices, mitigation tracking, and approval workflow.

**Tasks**
- [ ] Risk assessment list page with filter by system, status, risk level
- [ ] Risk assessment detail page:
  - Header (assessment info, overall risk level, status)
  - Risk items table (inline add/edit with scoring)
  - Residual risk summary
  - Risk heat map visualization
  - Approval section
  - Audit trail
- [ ] FMEA-style entry form (hazard, effect, controls, P, I, D, RPN, mitigation, residual)
- [ ] Configurable risk matrix editor (admin)
- [ ] Risk heat map chart (Recharts scatter plot with quadrant coloring)
- [ ] RPN trend chart for FMEA assessments
- [ ] Risk assessment approval workflow integration
- [ ] Risk assessment version comparison
- [ ] Risk register view (across all systems, filterable)
- [ ] Export to PDF and Excel

---

### Phase 5: Requirements Management (Months 6-7)

**Goal:** Full URS/FS/DS/CS authoring with requirement hierarchy, linking, traceability foundation, and approval workflow.

**Tasks**
- [ ] Requirement set list page (group by system, type)
- [ ] Requirement set detail with:
  - Requirements list (tree view for hierarchy)
  - Inline add/edit/reorder
  - Status filter and search
  - Coverage indicator (% with test coverage)
- [ ] Rich text requirement editor
- [ ] Requirement link manager (link parent/child, link between sets)
- [ ] Requirement set approval workflow integration
- [ ] Import requirements from CSV/Excel template
- [ ] Export requirements to Excel and PDF
- [ ] Traceability coverage panel on requirement set page

---

### Phase 6: Protocol Builder and Test Execution Engine (Months 7-9)

**Goal:** The heart of the system. Protocol creation from templates, execution step-by-step exactly like Kneat, inline deviation capture, attachments and screenshots per step, electronic signatures, and automated result tracking.

**Protocol Builder Tasks**
- [ ] Protocol list page (filter by type, system, status)
- [ ] Protocol builder (split-view: section/step outline left, editor right)
  - Add/remove/reorder sections and steps
  - Step type selection (action, check, data entry, observation, signature, screenshot)
  - Expected result field with rich text
  - Requirement linking per step
  - Regulatory citation per step
  - Script attachment per step
- [ ] Protocol template library (browse, preview, create from template)
- [ ] Protocol version management
- [ ] Protocol approval workflow

**Test Execution Engine Tasks**
- [ ] Execution view (full-screen optimized for step-by-step execution)
  - Left panel: step list with status indicators
  - Main area: current step detail (description, expected result, input area)
  - Actual result text area (or data entry field depending on step type)
  - Pass / Fail / N/A buttons
  - Deviation button (opens inline deviation capture)
  - Screenshot capture / file attach per step
  - Annotation tool on screenshots
  - Electronic signature modal when step requires it
  - Step timer (records duration per step)
  - Witness signature support
- [ ] Execution progress bar (steps completed / total)
- [ ] Execution summary page (after completion: results by section, deviation list, overall result)
- [ ] Deviation capture modal (inline during execution: type, severity, description, impact, disposition)
- [ ] Re-execution workflow (when protocol fails and must be re-run)
- [ ] Execution report generation (PDF: all steps, actual results, attachments, signatures, deviations)
- [ ] Script execution view (display and run test scripts, capture output as evidence)

---

### Phase 7: Document Management (Months 9-11)

**Goal:** Full controlled document management system with template engine, variable substitution, rich text authoring, version control, review and approval workflows, distribution, and read confirmation.

**Tasks**
- [ ] Document library page (folder tree + document list)
- [ ] Document detail page (current version content, version history, approvals, distributions, links)
- [ ] Document editor (TipTap full-screen with section management)
- [ ] Template engine:
  - Template library browser
  - Variable input form when creating from template
  - Template editor (admin)
  - Variable placeholder insertion in editor
- [ ] Document version comparison (side-by-side diff view)
- [ ] Document approval workflow (multi-stage with signatures)
- [ ] Document distribution management
- [ ] Read confirmation tracking (who has read, who is overdue)
- [ ] Document search (full text)
- [ ] PDF export with site header/footer, watermark for draft status
- [ ] Document linking to systems, protocols, change records

---

### Phase 8: Low-Code Workflow Engine (Months 11-13)

**Goal:** Visual drag-and-drop workflow builder that non-developers can use to define review and approval processes for any module. Configurable stages, routing rules, SLA enforcement, and escalation.

**Tasks**
- [ ] Workflow definition list page
- [ ] Visual workflow builder:
  - Stage canvas (drag-to-add stages, draw connections)
  - Stage configuration panel (assignee, SLA, signature requirement, embedded form, conditions)
  - Condition builder (if/then logic for stage routing)
  - Trigger configuration (which module, which event, which conditions)
  - Preview and simulate workflow path
- [ ] Workflow instance list (active, completed, overdue)
- [ ] My Tasks page (all workflow stages assigned to current user)
- [ ] Task action panel (review content inline, approve/reject with comment and signature)
- [ ] SLA monitoring and overdue highlighting
- [ ] Escalation engine (Celery task: check SLA hourly, trigger escalation notifications)
- [ ] Workflow history timeline view
- [ ] Workflow definition versioning

---

### Phase 9: Change Control (Months 13-14)

**Goal:** Full GMP-aligned change control with impact assessment, task management, implementation tracking, and verification.

**Tasks**
- [ ] Change request list page (Kanban view option + table view)
- [ ] Change request form with dynamic sections based on change type
- [ ] Impact assessment form (guided wizard)
- [ ] Task board for change implementation tasks
- [ ] Verification and closure workflow
- [ ] Emergency change handling path
- [ ] Integration hooks: when a change is approved, automatically flag affected system for revalidation if required
- [ ] Change control metrics dashboard (cycle time, open by category, overdue)

---

### Phase 10: CAPA and Nonconformance (Months 14-15)

**Tasks**
- [ ] CAPA list page with status filters and overdue highlighting
- [ ] CAPA detail with:
  - Problem statement and source linking
  - Root cause analysis tool (5 Whys, Fishbone diagram builder)
  - Action plan with task assignment and due dates
  - Effectiveness check scheduling and execution
  - Closure with signature
- [ ] NC list and detail pages
- [ ] NC investigation module
- [ ] Linking: NC -> CAPA -> Change Record -> Protocol (bidirectional)
- [ ] CAPA metrics: open by category, overdue, average cycle time
- [ ] Regulatory reporting flag and tracking

---

### Phase 11: Periodic Review (Months 15-16)

**Tasks**
- [ ] Periodic review schedule management
- [ ] Review calendar (shows all upcoming reviews by type)
- [ ] Review execution page:
  - Review period summary
  - Auto-populated checklist items (changes since last review, deviations, NCEs, training gaps, calibration status)
  - Finding capture
  - Outcome selection with justification
  - Signature and approval
- [ ] Review report generation
- [ ] Overdue review alerts (Celery scheduled tasks)
- [ ] Review history view per system/document/equipment

---

### Phase 12: Traceability Matrix (Months 16-17)

**Tasks**
- [ ] Traceability link management (requirement -> test step linking, bulk from protocol builder)
- [ ] RTM live view (requirements as rows, test steps as columns, pass/fail/not_tested indicators)
- [ ] Coverage calculator (% requirements with at least one passing test)
- [ ] Gap analysis report (requirements with no test coverage)
- [ ] RTM snapshot generation with approval and electronic signature
- [ ] RTM export to Excel and PDF

---

### Phase 13: Report Builder and Dashboards (Months 17-18)

**Tasks**
- [ ] Report builder (select module, choose fields, apply filters, group/sort, preview)
- [ ] Scheduled report configuration
- [ ] System compliance status report (validation status of all systems)
- [ ] Periodic review overdue report
- [ ] CAPA aging report
- [ ] Deviation trend report
- [ ] Training compliance matrix (users x required trainings)
- [ ] Audit trail export report (21 CFR Part 11 compliant)
- [ ] Executive dashboard (KPI cards: % systems validated, open CAPAs, overdue reviews, pending signatures)
- [ ] QA dashboard (deviations by severity, CAPA status, change control pipeline)
- [ ] Validation engineer dashboard (protocol execution status, upcoming revalidations, open deviations)
- [ ] Widget library and drag-to-configure dashboard builder

---

### Phase 14: Vendor Management and Audit Management (Months 18-19)

**Tasks**
- [ ] Vendor directory with qualification status indicators
- [ ] Vendor qualification workflow
- [ ] Vendor audit scheduling and findings management
- [ ] Audit (internal/external) management module
- [ ] Audit finding response and CAPA linking
- [ ] Audit calendar
- [ ] Regulatory inspection preparation checklist

---

### Phase 15: Training Records (Months 19-20)

**Tasks**
- [ ] Training requirement configuration (linked to documents and roles)
- [ ] Training assignment management
- [ ] Training completion recording with signature
- [ ] Training compliance matrix report
- [ ] Expiry tracking and renewal notifications
- [ ] Training gap analysis on document distribution (did everyone read the new SOP?)

---

### Phase 16: Validation Package for OpenVAL Itself (Months 20-21)

**Goal:** OpenVAL ships with a complete, pre-authored, site-executable validation package that follows GAMP 5 Category 4 approach.

**Documents to Author**
- [ ] VP-001: Software Description
- [ ] VP-002: GAMP 5 Category Assessment and Justification
- [ ] VP-003: Software Development Lifecycle (SDL) Description
- [ ] VP-004: User Requirements Specification (URS) for PHAROLON
- [ ] VP-005: Risk Assessment (FMEA)
- [ ] VP-006: Validation Plan
- [ ] VP-007: Installation Qualification (IQ) Protocol
- [ ] VP-008: Operational Qualification (OQ) Protocol (covers all major functions)
- [ ] VP-009: Performance Qualification (PQ) Protocol (end-to-end scenarios)
- [ ] VP-010: Traceability Matrix (URS -> Risk -> OQ/PQ steps)
- [ ] VP-011: Validation Summary Report (template for sites to complete)
- [ ] VP-012: Periodic Review SOP template
- [ ] VP-013: Change Control SOP for managing OpenVAL upgrades

---

### Phase 17: Pharma Template Library (Months 21-22)

**Goal:** Ship ready-to-use, professionally authored templates for common pharmaceutical validation scenarios.

**Protocol Templates**
- [ ] IQ: LIMS installation qualification (generic)
- [ ] OQ: LIMS operational qualification
- [ ] PQ: LIMS performance qualification (end-to-end workflows)
- [ ] IQ: Infrastructure server installation (Windows/Linux)
- [ ] OQ: Network and infrastructure OQ
- [ ] IQ: Laboratory instrument IQ
- [ ] OQ: Laboratory instrument OQ
- [ ] PQ: Laboratory instrument PQ
- [ ] UAT: Generic application UAT template
- [ ] MAV: Method validation template
- [ ] CSV: Retrospective CSV assessment template
- [ ] DQ: Design qualification template

**Document Templates**
- [ ] SOP: Computer System Validation Procedure
- [ ] SOP: Electronic Records and Signatures Procedure
- [ ] SOP: Change Control for Validated Systems
- [ ] SOP: Periodic Review of Validated Systems
- [ ] SOP: Data Integrity and ALCOA+
- [ ] SOP: User Access Management
- [ ] SOP: Backup and Restoration
- [ ] SOP: Disaster Recovery Testing
- [ ] SOP: Audit Trail Review
- [ ] Policy: GxP Computerized System Policy
- [ ] Template: Risk Assessment (FMEA)
- [ ] Template: Validation Plan
- [ ] Template: Validation Summary Report

---

### Phase 18: Administration, Integrations, and API (Months 22-23)

**Tasks**
- [ ] LDAP/Active Directory sync (user provisioning and role mapping)
- [ ] SAML/OIDC SSO integration
- [ ] REST API documentation (auto-generated via FastAPI + Swagger/ReDoc)
- [ ] API key management for integrations
- [ ] Webhook configuration
- [ ] Slack/Teams notification integration
- [ ] TrackWise export format (for sites running parallel systems)
- [ ] System health monitoring page (database, Redis, Celery, disk, audit chain integrity)
- [ ] Backup management UI
- [ ] Upgrade management (version check, upgrade guide, migration notes)

---

### Phase 19: Security Hardening and Performance (Months 23-24)

**Tasks**
- [ ] Penetration testing (external engagement)
- [ ] OWASP Top 10 review and remediation
- [ ] SQL injection hardening (parameterized queries audit)
- [ ] XSS protection audit (CSP headers, output encoding)
- [ ] CSRF protection audit
- [ ] Rate limiting (login, API endpoints)
- [ ] File upload security (extension whitelist, virus scanning hook, size limits)
- [ ] Session management hardening (absolute timeout, idle timeout, concurrent session control)
- [ ] Encryption audit (passwords, MFA secrets, LDAP credentials, API keys)
- [ ] Database performance profiling (slow query log analysis, index optimization)
- [ ] Frontend performance audit (bundle size, lazy loading, virtualized tables)
- [ ] Load testing (define supported concurrent user targets per hardware tier)
- [ ] Memory and connection leak testing

---

### Phase 20: Docker Option and Community Launch (Month 24+)

**Tasks**
- [ ] docker-compose.yml for development environment
- [ ] Docker Compose production configuration
- [ ] Docker Hub image publishing pipeline
- [ ] Community documentation site
- [ ] Contributing guide
- [ ] Code of conduct
- [ ] Security disclosure policy
- [ ] Commercial support licensing framework
- [ ] First stable release (v1.0.0) with validation impact classification

---

## 6. Module Specifications

### 6.1 Electronic Signature Flow

Every action that requires a signature follows this exact sequence:

1. User clicks sign/approve/execute action button
2. System presents the SignatureCapture modal
3. Modal displays:
   - The record being signed (ref, title, version)
   - The meaning to be applied (from signature_meanings table)
   - Username field (pre-populated, read-only)
   - Password field (required re-entry, even if logged in)
   - MFA token field (if MFA enabled for this meaning or user)
   - Confirmation checkbox: "I understand the meaning of this electronic signature"
4. User submits
5. System re-authenticates credentials server-side
6. If valid: creates electronic_signatures record, creates audit_log record for SIGN action
7. Updates the target record status
8. Returns signed confirmation to UI with signature timestamp
9. If invalid: returns specific error, increments failed attempt count, modal remains open

### 6.2 Audit Trail Architecture

The audit engine is implemented as a SQLAlchemy event listener. Every session.flush() that includes an INSERT, UPDATE, or DELETE is intercepted. The engine:

- Serializes old and new values for the affected row
- Computes SHA-256 hashes of old and new values
- Reads the current user from the request context (FastAPI dependency)
- Reads IP address and user agent from the request context
- Creates the audit_log record within the same database transaction
- Creates the audit_log_integrity record with hash chain

This means no code path can bypass the audit trail. It is not opt-in.

### 6.3 Audit Trail Integrity Verification

A scheduled Celery task runs nightly:

1. Reads the last verified audit_log_integrity record
2. Walks forward through all subsequent records
3. For each record, recomputes the expected chain_hash
4. If the stored chain_hash does not match, flags a tamper event
5. Writes result to system_health_log
6. Sends alert notification if tamper detected

This implements a blockchain-style hash chain that makes retroactive modification detectable.

---

## 7. Compliance Framework Mapping

### 21 CFR Part 11 Controls

| Requirement | CFR Citation | OpenVAL Implementation |
|---|---|---|
| Closed system controls | 11.10 | Full auth, RBAC, session management |
| Audit trails | 11.10(e) | Immutable audit_log with hash chain |
| Audit trail review | 11.10(e) | Audit trail viewer, review workflow, scheduled review |
| Access controls | 11.10(d) | Role-based permissions, unique user accounts |
| Electronic signatures | 11.50, 11.100 | Signature engine: meaning, identity, date/time |
| Signature manifestation | 11.50(a) | Displayed on all signed records |
| Re-authentication | 11.200(a) | Password re-entry + TOTP at signing |
| Signature linking | 11.70 | Hash of record content at signing time |
| Authority checks | 11.10(g) | RBAC permission checks on all actions |
| Device checks | 11.10(h) | Session validation, IP logging |
| Operational checks | 11.10(f) | Workflow sequencing enforced by engine |
| Training | 11.10(i) | Training records module linked to system access |
| Distribution controls | 11.10(c) | Document distribution with read confirmation |
| Record retention | 11.10(c) | No delete at application layer, archive capability |
| System validation | 11.10(a) | Bundled validation package (Phase 16) |

### ALCOA+ Data Integrity Matrix

| Principle | Definition | OpenVAL Implementation |
|---|---|---|
| Attributable | Who created/changed the record | user_id, created_by, updated_by on all records |
| Legible | Readable throughout retention | Structured database, standardized formats |
| Contemporaneous | Recorded at time of activity | Server-side timestamps, no client-provided timestamps for audit |
| Original | First capture of data | Immutable first record, versions preserved |
| Accurate | Correct and truthful | Validation on input, no retroactive modification |
| Complete | Full record, nothing missing | Mandatory fields, workflow completion gates |
| Consistent | Consistent format and sequence | Schema-enforced data types, lookup tables |
| Enduring | Retained for required period | No delete at application layer, archive strategy |
| Available | Accessible when needed | Search, export, no data locking |

---

## 8. Validation Package Specification

See `docs/validation_package/` for full pre-authored documents. The package follows GAMP 5 Category 4 approach:

- OpenVAL is classified as GAMP 5 Category 4 (configured product)
- The SDL is documented in the repository (public, versioned)
- Site executes IQ against their installed instance
- Site executes OQ against configured functionality
- Site executes PQ using representative business processes
- All evidence is generated within OpenVAL itself
- Validation Summary Report is authored by site QA and signed
- Revalidation triggers are defined: version upgrade (major), configuration changes to validated workflows, infrastructure changes

---

## 9. API Design Standards

- All endpoints: `/api/v1/{module}/{resource}`
- Authentication: Bearer token (JWT) in Authorization header
- All responses: `{ success: bool, data: any, message: str, errors: [] }`
- All list endpoints: `{ items: [], total: int, page: int, per_page: int, pages: int }`
- Pagination: `?page=1&per_page=25`
- Filtering: `?field=value&field2=value` or `?filters=JSON`
- Sorting: `?sort_by=field&sort_dir=asc|desc`
- All create/update/delete: audit trail entry created automatically
- OpenAPI spec: auto-generated at `/api/docs` and `/api/redoc`
- Rate limiting: 60 req/min for standard endpoints, 10 req/min for auth endpoints
- Versioning: `/api/v1/` prefix. Breaking changes increment version, old versions maintained for 2 major releases.

---

## 10. Security Architecture

### Authentication
- Passwords: bcrypt with minimum cost factor 12
- JWT access tokens: 15 minute expiry
- Refresh tokens: 7 day expiry, rotated on use, stored hashed
- MFA: TOTP (RFC 6238), 10 backup codes (hashed, single use)
- Account lockout: 5 failed attempts, 15 minute lockout
- Password policy: minimum 12 characters, complexity requirements, 12-version history
- Session: absolute timeout 8 hours, idle timeout 30 minutes (configurable)
- Concurrent sessions: configurable limit (default: 3)

### Data Protection
- MFA secrets: AES-256 encrypted at application layer
- LDAP bind passwords: AES-256 encrypted
- API keys: stored as SHA-256 hash, displayed once on creation
- File uploads: server-side only, no direct URL access, served through authenticated endpoint
- Sensitive fields in audit_log: masked (passwords never logged)

### Infrastructure
- All inter-service communication: localhost only (no external exposure of Redis, PostgreSQL)
- Nginx: TLS 1.2+, HSTS, security headers (CSP, X-Frame-Options, X-Content-Type-Options)
- File permissions: application runs as dedicated non-root user
- PostgreSQL: dedicated application user with minimum required permissions (no superuser)

---

## 11. Bare Metal Deployment

### Service Architecture

```
/etc/systemd/system/
  openval-api.service       # Gunicorn + Uvicorn: FastAPI application
  openval-worker.service    # Celery worker: background tasks
  openval-beat.service      # Celery beat: scheduled tasks

/etc/nginx/sites-available/
  openval                   # Nginx virtual host configuration

/opt/openval/               # Application root
  backend/                  # Python application
  frontend/dist/            # Built React application (served by Nginx)
  media/                    # Uploaded files (outside web root)
  logs/                     # Application logs
  backups/                  # Database backup staging

/opt/openval/.env           # Environment configuration (chmod 600)
```

### Environment Variables

```
# Database
DATABASE_URL=postgresql+asyncpg://openval:password@localhost/openval

# Redis
REDIS_URL=redis://localhost:6379/0

# Security
SECRET_KEY=                 # 64-character random string
ENCRYPTION_KEY=             # 32-byte AES key for sensitive fields
JWT_ALGORITHM=HS256

# Application
SITE_NAME=
SITE_URL=https://openval.yoursite.com
ALLOWED_HOSTS=openval.yoursite.com
DEBUG=false
LOG_LEVEL=INFO

# Email
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASSWORD=
SMTP_FROM_ADDRESS=

# File Storage
MEDIA_ROOT=/opt/openval/media
MAX_UPLOAD_SIZE_MB=50
ALLOWED_EXTENSIONS=pdf,doc,docx,xls,xlsx,ppt,pptx,png,jpg,jpeg,gif,txt,csv,zip

# Celery
CELERY_BROKER_URL=redis://localhost:6379/1
CELERY_RESULT_BACKEND=redis://localhost:6379/2
```

---

## 12. Future Roadmap

Items considered but deferred beyond Phase 20:

- Native mobile applications (iOS/Android) for execution-only workflows
- Offline protocol execution with sync on reconnect
- AI-assisted protocol generation from URS requirements
- AI-assisted risk item suggestions based on system type and GAMP category
- AI-assisted deviation disposition recommendations
- Real-time collaboration on document authoring
- Digital twin integration for equipment qualification
- Integration with common LIMS systems (LabWare, STARLIMS, Labvantage)
- Integration with common ERP systems (SAP, Oracle)
- Integration with quality systems (TrackWise, Veeva Vault QualityDocs)
- Multi-tenant SaaS deployment option
- Federated multi-site with central reporting
- Electronic batch record (eBR) extension module
- 21 CFR Part 820 design control module for medical devices
- Environmental monitoring data integration
- Stability study management
- Method validation tracking
- GMP training management expansion (assessments, ILT scheduling, e-learning integration)

---

*End of Master Plan v1.0.0*
*Next review: After Phase 0 completion*
