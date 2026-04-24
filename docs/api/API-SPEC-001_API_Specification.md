# PHAROLON API Specification

**Document Reference:** API-SPEC-001
**Version:** 1.0
**Base URL:** `/api/v1`
**Auth:** Bearer JWT in `Authorization: Bearer <token>` header

---

## 1. Standards and Conventions

### Request / Response Envelope

All responses use a consistent envelope:

```json
// Success (single record)
{
  "success": true,
  "data": { ... },
  "message": "System created successfully"
}

// Success (list)
{
  "success": true,
  "data": {
    "items": [ ... ],
    "total": 247,
    "page": 1,
    "per_page": 25,
    "pages": 10
  }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "One or more fields are invalid",
    "details": [
      { "field": "title", "message": "Title is required" },
      { "field": "gamp_category", "message": "Must be one of: 1, 3, 4, 5" }
    ]
  }
}
```

### HTTP Status Codes

| Code | Meaning | When Used |
|---|---|---|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST (record created) |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Business rule violation, invalid state transition |
| 401 | Unauthorized | Missing or invalid JWT |
| 403 | Forbidden | JWT valid but insufficient permissions |
| 404 | Not Found | Record does not exist (or not visible to this user) |
| 409 | Conflict | Duplicate record, concurrent modification |
| 422 | Unprocessable Entity | Input validation failure (Pydantic) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected server error |

### Query Parameters (list endpoints)

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | int | 1 | Page number |
| `per_page` | int | 25 | Items per page (max 100) |
| `sort_by` | string | created_at | Field to sort by |
| `sort_dir` | asc/desc | desc | Sort direction |
| `q` | string | — | Full-text search |
| `status` | string | — | Filter by status |
| `site_id` | uuid | — | Filter by site |

Module-specific filters are documented per endpoint.

### Audit Trail Headers

Every mutating request (POST, PUT, PATCH, DELETE) may include:

```
X-Change-Reason: Brief reason for the change (logged in audit_log.reason_text)
X-Change-Code: ROUTINE | CORRECTION | EMERGENCY | ADMINISTRATIVE
```

---

## 2. Authentication Endpoints

### POST `/auth/login`
Authenticate with username and password.

**Request:**
```json
{
  "username": "mescamilla",
  "password": "SecurePassword123!",
  "mfa_token": "123456"      // Optional: if MFA enabled
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "access_token": "eyJ...",
    "refresh_token": "abc123...",
    "token_type": "bearer",
    "expires_in": 900,
    "requires_mfa": false,
    "requires_password_change": false,
    "user": {
      "id": "uuid",
      "username": "mescamilla",
      "full_name": "Michael Escamilla",
      "email": "mescamilla@example.com",
      "site_id": "uuid",
      "roles": ["validation_engineer"],
      "permissions": ["protocols:create", "protocols:execute", ...]
    }
  }
}
```

**Response 200 (MFA required, not yet provided):**
```json
{
  "success": true,
  "data": {
    "requires_mfa": true,
    "mfa_token": "temp-session-token-for-mfa-completion"
  }
}
```

**Response 401:**
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid username or password"
  }
}
```

**Response 403 (account locked):**
```json
{
  "success": false,
  "error": {
    "code": "ACCOUNT_LOCKED",
    "message": "Account locked. Please contact your administrator.",
    "locked_until": "2026-04-06T15:30:00Z"
  }
}
```

---

### POST `/auth/refresh`
Exchange a refresh token for a new access token.

**Request:**
```json
{ "refresh_token": "abc123..." }
```

**Response 200:** Same as login, new access + refresh tokens.

---

### POST `/auth/logout`
Revoke the current session.

**Response 204:** No content. Session revoked.

---

### POST `/auth/verify-signature`
Re-authenticate for electronic signature. Does NOT create a new session.

**Request:**
```json
{
  "password": "SecurePassword123!",
  "mfa_token": "123456",
  "record_type": "protocols",
  "record_id": "uuid",
  "meaning_code": "APPROVED"
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "verified": true,
    "signature_token": "one-time-token-for-signing",
    "expires_at": "2026-04-06T14:30:00Z"
  }
}
```

This token is then passed in the subsequent record update request to attach the signature.

---

### POST `/auth/mfa/setup`
Initiate MFA setup for the authenticated user.

**Response 200:**
```json
{
  "success": true,
  "data": {
    "secret": "BASE32SECRET...",
    "qr_code_url": "data:image/png;base64,...",
    "otpauth_url": "otpauth://totp/PHAROLON:mescamilla?..."
  }
}
```

---

### POST `/auth/mfa/verify-setup`
Confirm MFA setup by providing a valid TOTP token.

**Request:**
```json
{ "totp_token": "123456" }
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "backup_codes": ["abc123def", "xyz789uvw", ...],
    "mfa_enabled": true
  }
}
```

---

### POST `/auth/password/change`
Change the authenticated user's password.

**Request:**
```json
{
  "current_password": "OldPassword!",
  "new_password": "NewPassword!",
  "confirm_password": "NewPassword!"
}
```

---

## 3. User Management Endpoints

### GET `/users`
List users. Requires `users:read` permission.

**Filters:** `site_id`, `department_id`, `role_id`, `is_active`, `q` (search name/email/username)

**Response 200:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "username": "mescamilla",
        "email": "mescamilla@site.com",
        "full_name": "Michael Escamilla",
        "title": "Principal Systems Administrator",
        "department": { "id": "uuid", "name": "MTS" },
        "site": { "id": "uuid", "name": "MATC", "code": "MATC" },
        "roles": [{ "id": "uuid", "name": "validation_engineer", "display_name": "Validation Engineer" }],
        "is_active": true,
        "is_locked": false,
        "mfa_enabled": true,
        "last_login_at": "2026-04-06T09:15:00Z",
        "created_at": "2025-06-01T00:00:00Z"
      }
    ],
    "total": 24,
    "page": 1,
    "per_page": 25,
    "pages": 1
  }
}
```

---

### POST `/users`
Create a user. Requires `users:create`.

**Request:**
```json
{
  "username": "rpandey",
  "email": "rpandey@site.com",
  "full_name": "Ruchi Pandey",
  "title": "Senior Scientist",
  "department_id": "uuid",
  "site_id": "uuid",
  "role_ids": ["uuid-validation-engineer"],
  "send_welcome_email": true
}
```

---

### GET `/users/{user_id}`
Get a single user with full detail.

---

### PUT `/users/{user_id}`
Update user. Requires `users:update`.

---

### POST `/users/{user_id}/lock`
Lock a user account. Requires `users:lock`.

**Request:**
```json
{ "reason": "Security investigation" }
```

---

### POST `/users/{user_id}/unlock`
Unlock a user account. Requires `users:lock`.

---

### GET `/users/me`
Get the currently authenticated user. No permission required.

---

## 4. System Inventory Endpoints

### GET `/systems`
List systems. Requires `systems:read`.

**Filters:** `site_id`, `status`, `validated_status`, `gamp_category`, `gxp_relevant`, `business_owner_id`, `technical_owner_id`, `revalidation_required`, `q`

---

### POST `/systems`
Create a system. Requires `systems:create`.

**Request:**
```json
{
  "site_id": "uuid",
  "name": "LabWare LIMS 7.0",
  "description": "Laboratory Information Management System...",
  "system_type": "software",
  "gamp_category": "4",
  "gamp_category_justification": "Standard configured software...",
  "gxp_relevant": true,
  "gxp_impact_areas": ["data_integrity", "gxp_records", "audit_trail"],
  "gxp_justification": "Stores and manages GxP laboratory data...",
  "applicable_regulations": ["21CFR11", "21CFR211"],
  "business_owner_id": "uuid",
  "technical_owner_id": "uuid",
  "qa_owner_id": "uuid",
  "vendor_id": "uuid",
  "vendor_product_name": "LabWare LIMS",
  "vendor_product_version": "7.0.3",
  "hosting_type": "on_premise",
  "environment": "production",
  "location": "MATC Server Room / ESX-04",
  "periodic_review_interval_months": 12
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "system_ref": "SYS-0042",
    "name": "LabWare LIMS 7.0",
    ...
  },
  "message": "System SYS-0042 created successfully"
}
```

---

### GET `/systems/{system_id}`
Get full system detail including computed fields.

**Response 200 - additional computed fields:**
```json
{
  "data": {
    "id": "uuid",
    "system_ref": "SYS-0042",
    ...
    "_computed": {
      "protocol_count": 6,
      "executed_protocol_count": 4,
      "open_deviation_count": 1,
      "active_change_count": 0,
      "traceability_coverage_pct": 87.5,
      "days_to_next_review": 90
    }
  }
}
```

---

### PUT `/systems/{system_id}`
Update system. Requires `systems:update`. Change reason header recommended.

---

### POST `/systems/{system_id}/retire`
Retire a system. Requires `systems:retire`.

**Request:**
```json
{
  "retirement_date": "2026-12-31",
  "retirement_reason": "System decommissioned and replaced by LabWare LIMS 8.0",
  "signature_token": "one-time-sig-token"
}
```

---

### GET `/systems/{system_id}/components`
List system components.

### POST `/systems/{system_id}/components`
Add a component.

### GET `/systems/{system_id}/interfaces`
List system interfaces.

### POST `/systems/{system_id}/interfaces`
Add an interface.

### GET `/systems/{system_id}/environments`
List environments.

### POST `/systems/{system_id}/environments`
Add an environment record.

---

## 5. Risk Assessment Endpoints

### GET `/risk-assessments`
List assessments. Filters: `system_id`, `equipment_id`, `status`, `overall_risk_level`, `assessment_type`

### POST `/risk-assessments`
Create assessment.

**Request:**
```json
{
  "system_id": "uuid",
  "assessment_type": "system_validation",
  "title": "LabWare LIMS 7.0 FMEA Risk Assessment",
  "methodology": "fmea",
  "matrix_id": "uuid",
  "scope": "Covers all GxP-relevant functions of LabWare LIMS..."
}
```

### GET `/risk-assessments/{id}`
Get assessment with all risk items.

### POST `/risk-assessments/{id}/items`
Add a risk item.

**Request:**
```json
{
  "item_number": "001",
  "category": "data_integrity",
  "hazard": "Audit trail disabled by unauthorized configuration change",
  "potential_effect": "Loss of GxP record integrity, inability to demonstrate data traceability",
  "existing_controls": "RBAC restricts configuration access to System Administrators",
  "probability_score": 2,
  "probability_rationale": "Low probability due to existing access controls",
  "impact_score": 5,
  "impact_rationale": "Critical: affects patient safety and regulatory compliance",
  "detectability_score": 3,
  "detectability_rationale": "Periodic audit trail review would detect within review cycle",
  "mitigation_required": true,
  "mitigation_actions": "Implement automated daily check of audit trail status; alert on disable event",
  "residual_probability_score": 1,
  "residual_impact_score": 5,
  "residual_detectability_score": 1,
  "owner_id": "uuid",
  "target_date": "2026-06-30"
}
```

### POST `/risk-assessments/{id}/approve`
Approve the assessment. Requires signature.

**Request:**
```json
{
  "signature_token": "one-time-token",
  "comments": "Risk assessment reviewed and approved."
}
```

---

## 6. Requirements Endpoints

### GET `/requirement-sets`
List sets. Filters: `system_id`, `set_type`, `status`

### POST `/requirement-sets`
Create a requirement set.

### GET `/requirement-sets/{id}/requirements`
List requirements with hierarchy (tree structure).

### POST `/requirement-sets/{id}/requirements`
Add a requirement.

**Request:**
```json
{
  "req_number": "URS-001",
  "section": "1. Data Integrity",
  "title": "Audit Trail",
  "description": "The system shall maintain a complete, accurate, and tamper-evident audit trail of all GxP-relevant data creation, modification, and deletion events.",
  "rationale": "Required by 21 CFR 11.10(e) and EU Annex 11 §9",
  "req_type": "functional",
  "priority": "mandatory",
  "testability": "testable",
  "regulatory_citation": "21 CFR 11.10(e)",
  "gxp_critical": true,
  "alcoa_attribute": "attributable",
  "acceptance_criteria": "All create, update, and delete operations generate audit entries with user, timestamp, old value, and new value. Audit entries cannot be modified or deleted.",
  "sort_order": 1
}
```

### POST `/requirement-sets/{id}/import`
Import requirements from CSV/Excel.

### GET `/requirement-sets/{id}/traceability`
Get real-time traceability coverage for this requirement set.

---

## 7. Protocol Endpoints

### GET `/protocols`
List protocols. Filters: `system_id`, `equipment_id`, `protocol_type`, `status`, `executed_by`

### POST `/protocols`
Create a protocol (optionally from template).

**Request:**
```json
{
  "system_id": "uuid",
  "protocol_type": "IQ",
  "title": "LabWare LIMS 7.0 Installation Qualification",
  "template_id": "uuid",          // Optional: creates from template
  "environment_id": "uuid",
  "objective": "To verify that LabWare LIMS 7.0 has been installed correctly...",
  "scope": "This protocol covers the installation of LabWare LIMS 7.0...",
  "prerequisites": "1. Server hardware commissioned\n2. PostgreSQL 15 installed...",
  "acceptance_criteria": "All steps pass or are documented as N/A with justification..."
}
```

### GET `/protocols/{id}`
Full protocol with sections and steps.

### PUT `/protocols/{id}`
Update protocol (only in draft status).

### POST `/protocols/{id}/sections`
Add a section.

### POST `/protocols/{id}/sections/{section_id}/steps`
Add a step.

**Request:**
```json
{
  "step_number": "2.4",
  "title": "Verify PostgreSQL Service Status",
  "description": "Navigate to the server console...",
  "expected_result": "The PostgreSQL service status shows 'active (running)'...",
  "step_type": "action",
  "input_type": "pass_fail",
  "is_mandatory": true,
  "requires_screenshot": true,
  "requires_signature": false,
  "linked_requirement_ids": ["uuid-urs-001", "uuid-urs-042"],
  "regulatory_citation": "21 CFR 11.10(a)",
  "sort_order": 40
}
```

### POST `/protocols/{id}/submit`
Submit for approval workflow.

### POST `/protocols/{id}/approve`
Approve. Requires signature. Triggers workflow if defined.

---

## 8. Test Execution Endpoints

### POST `/protocols/{id}/executions`
Start a new execution of an approved protocol.

**Request:**
```json
{
  "environment_id": "uuid",
  "executed_by": "uuid",
  "witnessed_by": "uuid",          // Optional
  "notes": "Execution of IQ as part of go-live qualification"
}
```

**Response 201:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "execution_ref": "TE-0089",
    "protocol_id": "uuid",
    "status": "in_progress",
    "started_at": "2026-04-06T14:00:00Z",
    "steps": [
      {
        "id": "uuid",
        "sequence_number": 1,
        "status": "not_started",
        "step": { ... full protocol step ... }
      }
    ]
  }
}
```

### GET `/executions/{id}`
Get full execution with all step results.

### PATCH `/executions/{id}/steps/{step_id}`
Record result for a single step.

**Request:**
```json
{
  "status": "passed",
  "actual_result": "PostgreSQL service status shows 'active (running)'. Service is enabled and set to start on boot. Verified using 'systemctl status postgresql' command.",
  "pass_fail": "pass",
  "entered_value": null,
  "comments": null,
  "signature_token": null          // Required if step has requires_signature = true
}
```

**Response 200:**
```json
{
  "success": true,
  "data": {
    "step_id": "uuid",
    "status": "passed",
    "executed_at": "2026-04-06T14:23:05Z",
    "executed_by": "Michael Escamilla",
    "execution_progress": {
      "total": 24,
      "passed": 11,
      "failed": 0,
      "deviation": 0,
      "remaining": 13
    }
  }
}
```

### POST `/executions/{id}/steps/{step_id}/deviations`
Raise a deviation for a step.

### POST `/executions/{id}/steps/{step_id}/attachments`
Upload attachment to a step. Multipart form data.

### POST `/executions/{id}/complete`
Mark execution as complete.

**Request:**
```json
{
  "overall_result": "pass_with_deviations",
  "conclusion": "The installation qualification was completed successfully with one minor deviation documented as DEV-0003...",
  "signature_token": "uuid"
}
```

### GET `/executions/{id}/report`
Generate execution report as PDF. Returns file download.

---

## 9. Document Management Endpoints

### GET `/documents`
List documents. Filters: `site_id`, `category_id`, `status`, `doc_type`, `system_id`, `review_overdue`, `q`

### POST `/documents`
Create a document (optionally from template).

**Request:**
```json
{
  "site_id": "uuid",
  "category_id": "uuid",
  "template_id": "uuid",           // Optional
  "title": "Computer System Validation Procedure",
  "doc_type": "SOP",
  "system_id": null,
  "owner_id": "uuid",
  "author_id": "uuid",
  "review_interval_months": 24,
  "requires_training": true,
  "training_roles": ["uuid-validation-engineer", "uuid-qa-associate"],
  "variable_values": {             // If created from template
    "site_name": "MATC",
    "department": "Manufacturing Technology Support",
    "effective_date": "2026-05-01"
  }
}
```

### GET `/documents/{id}`
Get document with current version content.

### GET `/documents/{id}/versions`
List all versions.

### POST `/documents/{id}/versions`
Create a new version (starts as draft).

**Request:**
```json
{
  "change_type": "minor",
  "change_summary": "Updated section 4.2 to reflect GAMP 5 2nd edition requirements",
  "change_reason": "Annual review - regulatory update",
  "body_content": { ... TipTap JSON ... }
}
```

### GET `/documents/{id}/versions/{version_id}/diff`
Show diff between this version and previous version.

### POST `/documents/{id}/versions/{version_id}/submit`
Submit version for review/approval workflow.

### POST `/documents/{id}/versions/{version_id}/approve`
Approve version. Requires signature.

### GET `/documents/{id}/versions/{version_id}/pdf`
Export version as PDF.

---

## 10. Change Control Endpoints

### GET `/change-requests`
List CRs. Filters: `site_id`, `status`, `change_type`, `change_category`, `requestor_id`, `validation_impact`, `q`

### POST `/change-requests`
Create a change request.

**Request:**
```json
{
  "site_id": "uuid",
  "title": "LabWare LIMS Upgrade from 7.0.3 to 7.0.4",
  "description": "Vendor-released patch correcting a defect in the environmental monitoring module...",
  "change_type": "planned",
  "change_category": "software_upgrade",
  "rationale": "Vendor patch corrects a defect that affects EM trending report accuracy.",
  "affected_systems": ["uuid-sys-0042"],
  "affected_documents": [],
  "validation_impact": "assessment_required",
  "validation_impact_justification": "Patch release - impact assessment required to determine if requalification needed",
  "proposed_implementation_date": "2026-05-15",
  "rollback_plan": "Restore from snapshot taken pre-upgrade"
}
```

### POST `/change-requests/{id}/impact-assessment`
Submit impact assessment.

### POST `/change-requests/{id}/submit`
Submit for approval.

### POST `/change-requests/{id}/approve`
Approve. Requires signature.

### POST `/change-requests/{id}/tasks`
Add an implementation task.

### PATCH `/change-requests/{id}/tasks/{task_id}`
Update task status.

### POST `/change-requests/{id}/verify`
Record implementation verification. Requires signature.

### POST `/change-requests/{id}/close`
Close the change record. Requires signature.

---

## 11. CAPA Endpoints

### GET `/capas`
List CAPAs. Filters: `site_id`, `status`, `capa_type`, `severity`, `owner_id`, `source_type`, `overdue`

### POST `/capas`
Create CAPA.

### GET `/capas/{id}`
Full CAPA detail with actions.

### POST `/capas/{id}/actions`
Add an action.

### PATCH `/capas/{id}/actions/{action_id}`
Update action status/completion.

### POST `/capas/{id}/effectiveness-check`
Record effectiveness check result.

### POST `/capas/{id}/close`
Close CAPA. Requires signature.

---

## 12. Workflow Endpoints

### GET `/workflow-definitions`
List workflow definitions.

### POST `/workflow-definitions`
Create a workflow definition.

**Request:**
```json
{
  "name": "GxP Document Approval",
  "description": "Standard approval workflow for all GxP-controlled documents",
  "trigger_object_type": "document_version",
  "trigger_event": "on_status_change",
  "trigger_conditions": [
    { "field": "status", "operator": "equals", "value": "submitted_for_review" }
  ],
  "require_all_approvers": true,
  "allow_self_approval": false,
  "stages": [
    {
      "stage_number": 1,
      "name": "Technical Review",
      "stage_type": "review",
      "assignee_type": "record_field",
      "assignee_field": "technical_reviewer_id",
      "sla_hours": 72,
      "escalation_hours": 120,
      "required_signature_meaning_id": "uuid-reviewed-meaning"
    },
    {
      "stage_number": 2,
      "name": "QA Approval",
      "stage_type": "approval",
      "assignee_type": "role",
      "assignee_role_id": "uuid-qa-manager-role",
      "sla_hours": 48,
      "escalation_hours": 96,
      "required_signature_meaning_id": "uuid-qa-approved-meaning",
      "rejection_goes_to_stage": 1
    }
  ]
}
```

### GET `/workflows/my-tasks`
Get all workflow tasks assigned to the current user.

### POST `/workflows/instances/{id}/stages/{stage_id}/approve`
Approve a workflow stage. Requires signature.

### POST `/workflows/instances/{id}/stages/{stage_id}/reject`
Reject a workflow stage.

**Request:**
```json
{
  "comments": "Section 4.2 requires revision to reference GAMP 5 2nd edition.",
  "signature_token": "uuid"
}
```

### POST `/workflows/instances/{id}/stages/{stage_id}/delegate`
Delegate a task to another user.

---

## 13. Audit Trail Endpoints

### GET `/audit-log`
Query the audit log. Requires `audit:read` permission. All results are read-only.

**Filters:** `table_name`, `record_id`, `user_id`, `action`, `module`, `date_from`, `date_to`, `q`

**Response:**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "uuid",
        "event_id": "EVT-00042",
        "table_name": "protocols",
        "record_id": "uuid",
        "record_display": "IQ-LIMS-001 v1.0",
        "action": "APPROVE",
        "field_name": null,
        "old_value": "in_review",
        "new_value": "approved",
        "user_id": "uuid",
        "user_name": "mescamilla",
        "user_full_name": "Michael Escamilla",
        "ip_address": "10.0.1.42",
        "module": "protocols",
        "cfr_citation": "21 CFR 11.10(e)",
        "timestamp": "2026-04-06T14:23:05Z"
      }
    ],
    "total": 8847
  }
}
```

### GET `/audit-log/integrity-status`
Get the current hash chain integrity status.

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "last_verified_at": "2026-04-06T02:15:00Z",
    "total_records_verified": 8847,
    "last_chain_hash": "a1b2c3...",
    "any_failures": false
  }
}
```

### GET `/audit-log/export`
Export audit log as CSV or PDF. Audit-logged as EXPORT action.

---

## 14. Reports Endpoints

### GET `/reports`
List report definitions.

### POST `/reports/{id}/run`
Execute a report. Returns run ID.

**Request:**
```json
{
  "parameters": {
    "site_id": "uuid",
    "date_from": "2026-01-01",
    "date_to": "2026-04-06",
    "status": ["open", "in_progress"]
  },
  "output_format": "pdf"
}
```

### GET `/reports/runs/{run_id}`
Poll report run status.

### GET `/reports/runs/{run_id}/download`
Download completed report file.

---

## 15. Notification Endpoints

### GET `/notifications`
Get notifications for current user.

**Filters:** `is_read` (true/false), `object_type`, `date_from`

### POST `/notifications/mark-read`
Mark notifications as read.

**Request:**
```json
{
  "notification_ids": ["uuid1", "uuid2"],
  "mark_all": false
}
```

### GET `/notifications/count`
Get unread notification count. Lightweight endpoint for polling.

**Response:**
```json
{ "success": true, "data": { "unread": 3 } }
```

---

## 16. Periodic Review Endpoints

### GET `/periodic-review-schedules`
List all active review schedules. Filters: `object_type`, `overdue`, `site_id`

### GET `/periodic-reviews`
List review records.

### POST `/periodic-reviews`
Initiate a review.

### PATCH `/periodic-reviews/{id}`
Update review (add findings, outcome).

### POST `/periodic-reviews/{id}/complete`
Complete and approve the review. Requires signature.

---

## 17. Administration Endpoints

### GET `/admin/site-settings`
Get all site settings. Requires `admin:settings`.

### PUT `/admin/site-settings`
Update site settings in bulk.

### GET `/admin/feature-flags`
List feature flags.

### PATCH `/admin/feature-flags/{flag_key}`
Toggle a feature flag.

### POST `/admin/smtp/test`
Send a test email to verify SMTP configuration.

### POST `/admin/ldap/sync`
Trigger manual LDAP user sync.

### GET `/admin/system-health`
Get system health status (DB, Redis, Celery, disk, audit chain).

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "checks": {
      "database": { "status": "healthy", "response_ms": 4 },
      "redis": { "status": "healthy", "response_ms": 1 },
      "celery": { "status": "healthy", "active_workers": 2 },
      "disk": { "status": "healthy", "used_pct": 34, "free_gb": 412 },
      "audit_chain": { "status": "healthy", "last_verified": "2026-04-06T02:15:00Z" },
      "smtp": { "status": "healthy", "last_test": "2026-04-05T09:00:00Z" }
    }
  }
}
```

---

## 18. Rate Limiting

| Endpoint Group | Limit |
|---|---|
| `/auth/login` | 10 requests / minute per IP |
| `/auth/verify-signature` | 5 requests / minute per user |
| `/auth/*` (other) | 20 requests / minute per IP |
| All other endpoints | 120 requests / minute per user |
| `/reports/*/run` | 10 requests / minute per user |
| `/admin/*` | 30 requests / minute per user |

Rate limit headers on every response:
```
X-RateLimit-Limit: 120
X-RateLimit-Remaining: 117
X-RateLimit-Reset: 1712415360
```

---

## 19. Webhook Payload Format

Outbound webhook payloads follow this structure:

```json
{
  "event": "protocol.approved",
  "event_id": "EVT-00042",
  "timestamp": "2026-04-06T14:23:05Z",
  "site_id": "uuid",
  "object_type": "protocol",
  "object_id": "uuid",
  "object_ref": "IQ-LIMS-001",
  "actor": {
    "id": "uuid",
    "username": "mescamilla",
    "full_name": "Michael Escamilla"
  },
  "data": {
    "id": "uuid",
    "protocol_ref": "IQ-LIMS-001",
    "title": "LabWare LIMS 7.0 Installation Qualification",
    "status": "approved",
    "approved_at": "2026-04-06T14:23:05Z"
  }
}
```

Payloads are signed with HMAC-SHA256 using the webhook secret:
```
X-PHAROLON-Signature: sha256=<hex_digest>
```

---

*API-SPEC-001 v1.0 - This specification governs all PHAROLON API development.*
*All endpoints will be auto-documented via FastAPI at `/api/docs`.*
