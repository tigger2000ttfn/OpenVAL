# PHAROLON Integration Specification

**Document Reference:** INT-SPEC-001
**Version:** 1.0
**Date:** 2026-04-07
**Status:** Approved for Planning

---

## 1. Integration Philosophy

PHAROLON is the system of record for validation lifecycle management.
It is not an island. Pharmaceutical sites run LIMS, MES, ERP, QMS, and
ticketing systems. PHAROLON must connect to them bidirectionally.

**Design Principles:**
- All integrations are optional. PHAROLON functions fully without any of them.
- All data crossing integration boundaries is logged in the audit trail.
- Integrations do not bypass PHAROLON's access controls or audit requirements.
- Data received from external systems is attributed to the integration source in the audit trail.
- No integration writes directly to audit_log or electronic_signatures tables.
- Integration failures are logged, alerted, and never silently swallowed.

---

## 2. Integration Architecture

### Standard Integration Patterns

**Pattern A: REST API (Outbound)**
PHAROLON calls external system APIs to push or pull data.
Used for: ERP, LIMS, MES, ticketing systems.

**Pattern B: Webhook (Inbound)**
External systems call PHAROLON APIs when events occur.
Used for: LIMS result feeds, MES batch events, instrument data.

**Pattern C: File-Based ETL**
Scheduled file import/export for systems without APIs.
Used for: legacy LIMS, older ERP systems, CSV-based data exchange.

**Pattern D: Database-to-Database (Read-Only)**
PHAROLON reads from external database views (never writes to external DB).
Used for: read-only reporting integration with LIMS or MES.

**Pattern E: LDAP/AD (Identity)**
User identity and group membership synchronization.
Used for: Active Directory, OpenLDAP.

**Pattern F: SSO (Authentication)**
Delegated authentication. PHAROLON does not hold passwords for SSO users.
Used for: SAML 2.0, OIDC, Azure AD.

---

## 3. Identity Integrations

### 3.1 Active Directory / LDAP

**Purpose:** User provisioning, role mapping, and authentication delegation.

**Configuration:**
```
Server URL:           ldaps://dc01.yoursite.com:636
Base DN:              OU=Users,DC=yoursite,DC=com
Bind DN:              CN=pharolon_svc,OU=Service,DC=yoursite,DC=com
User Search Filter:   (&(objectClass=person)(sAMAccountName={username}))
Group Search Base:    OU=Groups,DC=yoursite,DC=com
Username Attribute:   sAMAccountName
Email Attribute:      mail
Full Name Attribute:  displayName
```

**Role Mapping:**
AD groups map to PHAROLON roles via configurable mapping table.
```
AD Group                    → PHAROLON Role
MTS_Admins                 → system_admin
QA_Managers                → qa_manager
QA_Associates              → qa_associate
Validation_Engineers       → validation_engineer
All_Staff                  → read_only
```

**Sync Behavior:**
- Nightly sync: creates new users, deactivates removed users, updates role assignments
- Manual sync: available via Admin > Integrations > LDAP > Sync Now
- New users created via LDAP sync must_change_password = false (no local password)
- Users removed from AD are deactivated in PHAROLON, not deleted (preserves audit trail)
- Users can still be authenticated locally if AD is unavailable (configurable)

**Audit Trail:**
Every LDAP-sourced change generates an audit_log entry with user_id = SYSTEM and
reason_code = LDAP_SYNC.

### 3.2 SAML 2.0 / OIDC SSO

**Purpose:** Delegate authentication to corporate identity provider.

**Supported Providers:**
- Azure Active Directory / Entra ID
- Okta
- ADFS
- Any SAML 2.0 or OIDC-compliant IdP

**SAML Configuration:**
```
Entity ID:            https://pharolon.yoursite.com/auth/saml/metadata
ACS URL:              https://pharolon.yoursite.com/auth/saml/callback
SLO URL:              https://pharolon.yoursite.com/auth/saml/logout
Attribute Mapping:
  email:              http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
  full_name:          http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name
  username:           http://schemas.xmlsoap.org/ws/2005/05/identity/claims/upn
  groups:             http://schemas.microsoft.com/ws/2008/06/identity/claims/groups
```

**Electronic Signature Consideration:**
21 CFR Part 11 requires re-authentication at signing time. SSO users must still
re-authenticate via the IdP at signature time (IdP re-auth prompt is triggered)
or fall back to a local PIN set specifically for signature purposes.

---

## 4. LabWare LIMS Integration

**Purpose:** Bidirectional integration between PHAROLON (validation/quality) and
LabWare LIMS (laboratory operations). Relevant to Michael's direct environment.

### 4.1 System Record Synchronization

PHAROLON is the system of record for the LabWare system record, validation status,
and all CSV documentation. LabWare does not hold validation records.

**From PHAROLON to LabWare (informational):**
- Validation status (validated / in qualification / requires revalidation)
- Active change requests affecting LabWare
- Upcoming periodic review dates

**From LabWare to PHAROLON:**
- LabWare version/build number (triggers revalidation assessment if changed)
- Active users list (for access control audit comparison)
- Instrument calibration status (feeds equipment module)

### 4.2 Environmental Monitoring Results

LabWare manages EM sample results. PHAROLON manages the EM program and excursion workflow.

**Data Flow:**
```
LabWare records EM result →
  If OOS/exceedance: LabWare sends result to PHAROLON via webhook →
    PHAROLON creates em_excursion record automatically →
    Notification sent to EM Coordinator →
    Investigation workflow initiated
```

**Webhook Payload from LabWare:**
```json
{
  "event": "em_result_oos",
  "sample_id": "EM-2026-04-001",
  "sample_point_code": "BR-01-SURFACE-A",
  "result_value": 12,
  "limit_type": "action",
  "action_limit": 5,
  "unit": "CFU",
  "sampled_date": "2026-04-06",
  "analyst_name": "M. Escamilla",
  "organisms_identified": ["Staphylococcus epidermidis"]
}
```

### 4.3 OOS Results

**Data Flow:**
```
LabWare OOS result recorded →
  LabWare sends event to PHAROLON webhook →
    PHAROLON creates oos_oot_record →
    Phase 1 investigation assigned to analyst's supervisor →
    If Phase 2: CAPA created automatically
```

### 4.4 Audit Trail Comparison

PHAROLON can pull LabWare audit trail exports (CSV or API) for comparison
during periodic review. The review checklist item "audit trail review completed"
links to the imported LabWare audit trail snapshot stored in PHAROLON file_store.

### 4.5 Configuration

```
Integration Type:  REST API + Webhook
Authentication:    API key (PHAROLON sends X-API-Key header to LabWare)
LabWare Endpoint:  https://lims.yoursite.com/api/
PHAROLON Webhook:   https://pharolon.yoursite.com/api/v1/integrations/labware/inbound
Sync Frequency:    Real-time (webhook) + Nightly reconciliation
```

---

## 5. TrackWise Integration

**Purpose:** Bidirectional integration between PHAROLON and TrackWise (Sparta/Honeywell).
Common in large pharma where TrackWise handles change control and CAPAs at the
enterprise level while PHAROLON manages the detailed validation lifecycle.

### 5.1 Change Control Synchronization

In environments where TrackWise is the enterprise change control system,
PHAROLON acts as a sub-system that handles the technical validation aspects.

**Data Flow:**
```
TrackWise change request approved →
  TrackWise notifies PHAROLON via webhook →
    PHAROLON creates linked change_request record →
    Validation impact assessment triggered in PHAROLON →
    PHAROLON sends assessment result back to TrackWise →
    Protocol created/executed in PHAROLON →
    Completion status sent to TrackWise
```

**Mapping: TrackWise → PHAROLON**
```
TW Change Request ID  → cr_ref (stored as external_ref in change_requests)
TW Change Type        → change_type
TW Priority           → risk_level
TW Affected Systems   → affected_systems (system_ref lookup)
TW Target Date        → proposed_implementation_date
```

### 5.2 CAPA Synchronization

**Scenario A: TrackWise is master CAPA system**
TrackWise holds the CAPA record. PHAROLON holds the validation-specific actions.
PHAROLON receives CAPA ID from TrackWise and creates linked actions locally.

**Scenario B: PHAROLON is master CAPA system**
PHAROLON creates CAPA. Export capability generates TrackWise-compatible XML.

### 5.3 Nonconformance Linkage

PHAROLON NCs (system outages, access control failures) can be exported as
TrackWise NCR format for sites that require enterprise NCR management.

### 5.4 Configuration

```
Integration Type:  Webhook (inbound) + REST API (outbound)
TrackWise Version: 8.x or Digital
Authentication:    OAuth 2.0 client credentials
Export Formats:    TrackWise XML schema, CSV
```

**external_references table addition:**
```sql
ALTER TABLE change_requests ADD COLUMN external_ref VARCHAR(255);
ALTER TABLE change_requests ADD COLUMN external_system VARCHAR(100);
ALTER TABLE capas ADD COLUMN external_ref VARCHAR(255);
ALTER TABLE capas ADD COLUMN external_system VARCHAR(100);
ALTER TABLE nonconformances ADD COLUMN external_ref VARCHAR(255);
ALTER TABLE nonconformances ADD COLUMN external_system VARCHAR(100);
```

---

## 6. ERP Integration (SAP / Oracle)

**Purpose:** Equipment master data, vendor/supplier data, cost center assignment.

### 6.1 Equipment Master Sync

**Data Flow (SAP → PHAROLON):**
- Equipment created in SAP Plant Maintenance (PM module)
- PHAROLON pulls equipment master via SAP BAPI or RFC
- Creates/updates equipment record in PHAROLON
- SAP equipment number stored as asset_number

**Fields mapped:**
```
SAP Equipment Number    → equipment.asset_number
SAP Functional Location → equipment.location
SAP Object Type         → equipment.equipment_type
SAP Manufacturer        → equipment.manufacturer
SAP Model Number        → equipment.manufacturer_model
SAP Serial Number       → equipment.serial_number
SAP Maintenance Plan    → equipment.maintenance_interval_days
```

### 6.2 Vendor Master Sync

SAP vendor master (LFA1) syncs to PHAROLON vendor records.
PHAROLON qualification status does not sync back to SAP (one-directional).

### 6.3 Cost Center Assignment

Change requests and validation projects can be tagged with SAP cost centers
for financial reporting. Cost center list synced from SAP CO module.

---

## 7. MES Integration

**Purpose:** Connect batch manufacturing events to PHAROLON quality workflows.

### 7.1 Supported MES Platforms

- Tempo MES (Astellas-specific, relevant to Michael's environment)
- Rockwell PharmaSuite
- Werum PAS-X
- AVEVA MES

### 7.2 Batch Events to PHAROLON

**Events that trigger PHAROLON actions:**

| MES Event | PHAROLON Action |
|---|---|
| Batch started | Create batch record in PHAROLON batch module |
| Critical process parameter exceedance | Create process deviation |
| Batch completed with deviations | Flag batch for QC review |
| Equipment alarm triggered | Create equipment maintenance request |
| Cleaning procedure not completed | Create nonconformance |
| Batch placed on hold | Update batch status to hold |

### 7.3 Tempo MES Specific (MATC)

Given Michael's environment, Tempo MES integration is prioritized.

**Tempo API endpoint configuration:**
```
Base URL:           https://tempo.matc.astellas.com/api/
Authentication:     JWT (Tempo service account)
Events subscribed:  batch.started, batch.deviation, batch.completed, batch.hold
Webhook target:     https://pharolon.matc.astellas.com/api/v1/integrations/tempo/inbound
```

---

## 8. Notification Channel Integrations

### 8.1 Microsoft Teams

**Purpose:** Send PHAROLON notifications to Teams channels.

**Configuration:**
```
Integration Type:   Incoming Webhook (Teams)
Channel Mapping:    Configurable per notification type
  - Protocol executions → #validation-activity
  - CAPA overdue alerts → #quality-events
  - System health alerts → #it-alerts
```

**Payload format:**
```json
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "DE350B",
  "summary": "CAPA Action Overdue",
  "sections": [{
    "activityTitle": "CAPA-0011: Action #2 Overdue",
    "activitySubtitle": "Responsible: M. Escamilla",
    "facts": [
      {"name": "Due Date", "value": "2026-04-01"},
      {"name": "Days Overdue", "value": "6"},
      {"name": "CAPA Title", "value": "FCS Express server migration deviation"}
    ],
    "markdown": true
  }],
  "potentialAction": [{
    "@type": "OpenUri",
    "name": "View in PHAROLON",
    "targets": [{"os": "default", "uri": "https://pharolon.yoursite.com/capas/CAPA-0011"}]
  }]
}
```

### 8.2 Slack

**Purpose:** Send notifications to Slack channels via Incoming Webhooks.

**Payload format:**
```json
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*CAPA Action Overdue* :red_circle:\n*CAPA-0011* action #2 is 6 days overdue.\nResponsible: M. Escamilla"
      }
    },
    {
      "type": "actions",
      "elements": [{
        "type": "button",
        "text": {"type": "plain_text", "text": "View in PHAROLON"},
        "url": "https://pharolon.yoursite.com/capas/CAPA-0011"
      }]
    }
  ]
}
```

### 8.3 Email (SMTP)

Already covered in base architecture. All notification templates support email.
Email is the fallback if Teams/Slack is not configured.

---

## 9. Instrument / Equipment Data Integration

### 9.1 Purpose

Allow laboratory instruments to feed calibration results, test data, and
process parameters directly into PHAROLON without manual transcription.
Eliminates ALCOA+ concerns about manual data entry from instruments.

### 9.2 Supported Integration Methods

**Method A: REST API Push (modern instruments)**
Instruments with modern software send results directly to PHAROLON API.

**Method B: LabWare Instrument Interface Bridge**
LabWare already has instrument interfaces for many instruments.
PHAROLON receives the processed result from LabWare (via Section 4 above)
rather than directly from the instrument.

**Method C: File Drop + Parser**
Instrument exports result file (CSV, XML, JSON) to a monitored directory.
PHAROLON file watcher (Celery task) picks up and parses.

**Method D: PI Historian Bridge (future)**
For process instruments connected to OSIsoft PI Historian.
PHAROLON queries PI via REST API for specific tag values at defined intervals.

### 9.3 Instrument Data Webhook Endpoint

`POST /api/v1/integrations/instruments/data`

**Request:**
```json
{
  "instrument_id": "EQ-0012",
  "data_type": "calibration_result",
  "timestamp": "2026-04-06T14:23:05Z",
  "result": {
    "tolerance_as_found": "±0.02°C",
    "tolerance_as_left": "±0.01°C",
    "result": "pass",
    "certificate_number": "CAL-2026-0042"
  },
  "api_key": "instrument-api-key-hash"
}
```

---

## 10. Regulatory Submission Integration

### 10.1 FDA Electronic Submissions

**Purpose:** Export PHAROLON records in formats compatible with FDA electronic submissions.

**Supported Export Formats:**
- eCTD (electronic Common Technical Document) structured reference
- FDA 21 CFR Part 11 compliant audit trail export (for inspection requests)
- CSV export for FDA data integrity investigations
- PDF/A (archival PDF) for long-term retention

### 10.2 eSUB Integration (Future)

Future integration with FDA Electronic Submissions Gateway for direct submission
of validation-related regulatory correspondence.

---

## 11. Cloud Storage Integration (Future)

### 11.1 Azure Blob Storage

For sites running PHAROLON in cloud or hybrid mode:
- File attachments stored in Azure Blob Storage instead of local filesystem
- Validation-appropriate blob container with immutability policies
- AES-256 encryption at rest

### 11.2 AWS S3

Similar to Azure, for AWS-hosted deployments.

**Note:** Cloud storage is deferred to Phase 20+. Base deployment uses local filesystem.

---

## 12. Integration Health Monitoring

### Status Dashboard

Administration > Integrations shows a live status board:

```
INTEGRATION STATUS
─────────────────────────────────────────────────────
Integration       | Status   | Last Check      | Events (24h)
──────────────────┼──────────┼─────────────────┼──────────────
LabWare LIMS      | ● Healthy| 2 min ago       | 42 received
Active Directory  | ● Healthy| 15 min ago      | 3 synced
TrackWise         | ⚠ Warn   | 5 min ago       | API timeout
Tempo MES         | ○ Disabled| —              | —
Microsoft Teams   | ● Healthy| 1 min ago       | 8 sent
SMTP              | ● Healthy| 10 min ago      | 24 sent
─────────────────────────────────────────────────────
```

### Health Check Implementation

Each integration has a `health_check()` method called by a Celery task
every 15 minutes. Results stored in `integration_logs` and visible in the dashboard.

### Failure Handling

- Failed integration calls are retried with exponential backoff (3 attempts)
- After 3 failures: integration flagged as degraded, admin notification sent
- All integration errors logged in `integration_logs` with full payload
- Circuit breaker pattern: after 10 consecutive failures, integration is paused
  and admin must manually re-enable after investigating

---

## 13. Integration Security Requirements

- All outbound integration calls use TLS 1.2+
- API keys for integrations are stored AES-256 encrypted in `integration_configs.config`
- Integration credentials are never exposed in API responses or logs
- Each integration has a dedicated service account with minimum required permissions
- Integration activity is logged in `audit_log` with `module = integration`
- Inbound webhook payloads are verified via HMAC-SHA256 signature where supported
- Integration service accounts cannot sign electronic records
- Integration-created records are attributed to the integration source in audit trail

---

## 14. Integration Testing

Every integration must have:

1. **Unit tests:** Mock the external API, test request/response handling
2. **Integration tests:** Test against a sandboxed/test instance of the external system
3. **Failure tests:** Test all failure modes (timeout, 401, 500, malformed payload)
4. **Audit trail tests:** Verify that integration-generated records appear correctly in audit log

Integration tests are tagged `@pytest.mark.integration` and are excluded from
the standard CI run (require external systems to be available). They run
nightly against test environments.

---

*INT-SPEC-001 v1.0 - PHAROLON Integration Specification*
