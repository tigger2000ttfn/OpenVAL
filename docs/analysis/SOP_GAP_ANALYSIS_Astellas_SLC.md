# OpenVAL Gap Analysis — Astellas GxP System Life Cycle SOP

**Analysis Date:** 2026-04-08
**Source Document:** Astellas SOP — GxP System Life Cycle (SLC)
**Analyst:** Head of Global QA, OpenVAL Project
**Purpose:** Identify templates, roles, processes, and schema tables that the
Astellas enterprise SLC reveals as missing or incomplete in OpenVAL.

---

## Executive Summary

This analysis is based on a real enterprise pharmaceutical CSV SOP from a
top-tier company (Astellas). It reveals 19 specific gaps — whole document types,
role structures, risk-based testing infrastructure, and branched process flows
that do not yet exist in OpenVAL. This document maps every gap with the
required fix.

**Coverage before analysis: ~80%**
**Estimated coverage after all fixes: ~97%**

---

## Section 1: Missing Document Templates / Types

### 1.1 Regulatory Assessment and System Categorization (RASC)
**Astellas Template:** STL-1905 | **Status:** ❌ MISSING

The RASC is the first and most important deliverable for every new system.
It is the classification engine that drives every downstream decision.

Fields the RASC captures:
- GxP Compliance: Is this system GxP? (yes/no + justification)
- Risk Level: High / Medium / Low
- Applicable Validation Regulations (21 CFR 211, 820, 58, etc.)
- GAMP Category (1, 3, 4, 5)
- JSOX / SOX Compliance requirement
- Data Protection / Privacy assessment trigger (GDPR/CCPA)
- Data Retention period and regulatory basis
- Direct vs Indirect patient/product impact
- System category: OOTB / Configured / Custom

The RASC OUTPUT drives:
- Which validation deliverables are required
- The minimum testing level (see Section 2.3)
- The QA review percentage
- Whether an Externally Hosted Security Assessment is needed
- Whether a Data Migration Plan is needed

**Fixes Required:**
- [ ] New document type: `Regulatory_System_Categorization`
- [ ] New template: `TMPL-RASC`
- [ ] New schema table: `regulatory_system_categorizations`
- [ ] Fields to add to `systems`: `direct_indirect_impact`, `sox_compliance_required`, `data_protection_required`
- [ ] RASC drives Guided Validation Wizard — determines required deliverables automatically

---

### 1.2 Business and Functional Risk Assessment (BFRA)
**Astellas Template:** STL-1888 | **Status:** ⚠️ PARTIAL

BFRA is distinct from FMEA. It answers: "What business process risks exist
for using this system, and what controls mitigate them?"

Key differences from OpenVAL's generic risk assessment:
- Focuses on business process failure, not system failure modes
- Updated continuously throughout the project (it's a living document)
- Residual risks must be explicitly stated in the Validation Summary Report
- Must be approved before VSR is finalized

**Fixes Required:**
- [ ] Add `bfra` as a risk assessment sub-type
- [ ] Add `residual_risk_summary` field to risk_assessments
- [ ] Add `is_living_document` flag — BFRA persists and updates unlike FMEA snapshots
- [ ] New template: `TMPL-RISK-BFRA`
- [ ] Add BFRA final approval as VSR prerequisite in lifecycle state machine

---

### 1.3 System Maintenance Manual (SMM)
**Astellas Template:** STL-728 | **Status:** ❌ MISSING

The SMM is a permanent system-level document (not per-project) that is the
technical operations bible for each validated system. It must cover:
- Backup and restore strategy (with RTO and RPO explicitly defined)
- Access and security management procedures
- IT Service Management procedures (incident, problem, change, patch)
- System administration procedures
- System-specific monitoring requirements

Every validated system must have an SMM as a system-level deliverable.
It survives the entire lifecycle and is updated via change control.

**Fixes Required:**
- [ ] New document type: `System_Maintenance_Manual`
- [ ] New template: `TMPL-SMM`
- [ ] New schema table: `system_maintenance_manuals`
- [ ] Key fields: `rto_hours`, `rpo_hours`, `backup_strategy`, `patch_procedure`, `access_management_sop_ref`
- [ ] Link to systems table (one SMM per system)
- [ ] SMM shown in system detail page as a required deliverable

---

### 1.4 System Recovery Plan (SRP)
**Astellas Template:** STL-1909 | **Status:** ⚠️ PARTIAL

A formal per-system recovery plan is required. Different from the SMM:
the SMM covers routine backup/restore. The SRP covers disaster recovery.

SRP must document:
- Primary objective (minimize downtime and data loss)
- RTO and RPO (must match what is in the SMM)
- Recovery procedures step by step
- Escalation contacts
- Recovery testing schedule and results

**Fixes Required:**
- [ ] New document type: `System_Recovery_Plan`
- [ ] New template: `TMPL-SRP`
- [ ] New schema table: `system_recovery_plans` with `last_tested_date`, `test_result`, `next_test_date`
- [ ] Link to system (system-level deliverable, permanent)
- [ ] DR test results linked from `disaster_recovery_tests` in Part 6

---

### 1.5 System End of Life Plan and Report
**Astellas Templates:** STL-1893 and STL-1894 | **Status:** ❌ MISSING

Every system retirement requires formal documentation in two phases:

**EOL Plan (before retirement):**
- Retirement reason and target date
- Data retention approach: archive / migrate to new system / delete (with justification)
- Data migration plan reference
- User notification plan
- Regulatory notification required? (if yes, which agencies)
- Records retention compliance confirmation

**EOL Report (after retirement):**
- Actual activities performed vs planned
- Confirmation of data retention compliance
- Archive location reference
- Decommission confirmation with signature

**Fixes Required:**
- [ ] New document types: `System_EOL_Plan` and `System_EOL_Report`
- [ ] New templates: `TMPL-EOL-PLAN` and `TMPL-EOL-REPORT`
- [ ] New schema table: `system_eol_records`
- [ ] System lifecycle state: add `decommissioned` to systems.status
- [ ] Systems in decommissioned state: read-only, accessible, retained per policy

---

### 1.6 System Release Statement (SRS)
**Astellas Template:** STL-1910 | **Status:** ❌ MISSING

For Operational Changes (not full validations), the SRS replaces the VSR.
It is a shorter go-live authorization for patches, minor config changes,
and SaaS vendor releases.

SRS contents:
- Pre-go-live checklist completion confirmation
- All change control tasks completed
- Training completed for affected users
- Documentation updated
- Go-live authorization signature

**Fixes Required:**
- [ ] New document type: `System_Release_Statement`
- [ ] New template: `TMPL-SRS`
- [ ] Lifecycle branch: Operational Change ends with SRS, not VSR
- [ ] Wizard: "Is this a full implementation/upgrade?" → VSR  |  "Operational change?" → SRS

---

### 1.7 Requirements in Agile User Story Format
**Astellas Template:** STL-4509 | **Status:** ⚠️ PARTIAL

Astellas calls requirements "User Stories" aligned to Agile methodology:
```
As a [role]
I want [feature/function]
So that [business outcome]
Acceptance Criteria: [testable, measurable criteria]
```

OpenVAL has traditional numbered requirements but not this Agile format.
Many pharma IT teams have moved to Agile delivery and need this.

**Fixes Required:**
- [ ] Add `requirement_format` field to requirements: `traditional` | `user_story`
- [ ] Add user story fields: `as_a_role`, `i_want`, `so_that`
- [ ] Template: `TMPL-URS-AGILE`
- [ ] Wizard: offer both formats at project creation

---

### 1.8 Externally Hosted Security Assessment (EHSA)
**Astellas Template:** STL-4145 | **Status:** ❌ MISSING

Required for any cloud-hosted or vendor-hosted GxP system. Assesses:
- Data sovereignty (where does data physically reside?)
- Security controls (encryption at rest, in transit)
- Access management (who at the vendor can see our data?)
- Penetration testing results
- Business continuity and disaster recovery at vendor
- GDPR/CCPA/privacy compliance

Triggered by the RASC: if `is_cloud_hosted = true`, EHSA is required.

**Fixes Required:**
- [ ] New document type: `Externally_Hosted_Security_Assessment`
- [ ] New template: `TMPL-EHSA`
- [ ] New schema table: `externally_hosted_security_assessments`
- [ ] Auto-trigger from RASC when cloud_hosted flag set
- [ ] Link to vendor/supplier record

---

## Section 2: Missing Process Flows

### 2.1 Operational Change vs System Implementation (Two-Path Lifecycle)

Astellas has TWO distinct lifecycle paths. OpenVAL only has Path A.

**Path A: System Implementation or Upgrade**
```
RASC → Change Request → Validation Plan → Design/Config Spec →
Requirements → BFRA → Test Scripts → Execute → Traceability Matrix →
BFRA Final → Validation Summary Report → Go-Live
```

**Path B: Operational Change (patches, minor changes, SaaS updates)**
```
Change Request → Impact Assessment → Test Scripts (if needed) →
Execute (if tested) → System Release Statement → Go-Live
```

**Fixes Required:**
- [ ] Add `change_category` to validation_projects:
  `system_implementation | system_upgrade | operational_change | emergency_change`
- [ ] Conditional required deliverables based on change_category
- [ ] Operational change workflow: abbreviated, ends with SRS not VSR
- [ ] Wizard asks at project creation: which type of change?

---

### 2.2 SaaS Vendor Release Management

Astellas explicitly defines this: "Routine, Periodic Release of SaaS Systems —
must follow the Operational Change approach. Impact assessment of release notes
and regression testing must be performed prior to acceptance of the release."

This is the most common day-to-day scenario in pharma IT. LIMS patches,
SAP support packs, SFDC releases — all need a lightweight validated process.

**Fixes Required:**
- [ ] New workflow: `Vendor_Release_Assessment`
- [ ] Fields: vendor_release_version, release_notes_reviewed, impact_level (none/minor/major), testing_required
- [ ] New table: `vendor_release_assessments`
- [ ] Auto-trigger: periodic Celery task polls linked integrations for new vendor releases
- [ ] If testing_required: auto-create operational change record

---

### 2.3 Risk-Based Testing Matrix (Attachment 3)

Astellas defines a precise matrix for minimum testing level:

| Direct/Indirect | System Risk | Feature Type | Req Risk | → Testing Required |
|---|---|---|---|---|
| Direct | High | Custom/Configured | High | Scripted – Robust |
| Direct | High | Configured | Medium | Scripted – Limited |
| Direct | High | OOTB | Low | Minimal or Vendor |
| Direct | Medium | Custom/Configured | High | Scripted – Robust |
| Indirect | Low | OOTB | Any | No testing, vendor only |
| ... | ... | ... | ... | ... |

This matrix is the backbone of risk-based testing. OpenVAL has risk scoring
but not the specific testing-level determination that auditors expect.

**Fixes Required:**
- [ ] New table: `risk_based_testing_decisions`
- [ ] Seed all matrix rows per Astellas Attachment 3
- [ ] RASC + BFRA outputs auto-suggest the testing level
- [ ] Testing level shown prominently on every protocol (ROBUST / LIMITED / MINIMAL / VENDOR)
- [ ] Override with justification allowed and audit-logged

---

### 2.4 Emergency Change Path

Astellas references an Emergency Change path: go-live immediately with
abbreviated approval, retrospective documentation within defined timeframe.

**Fixes Required:**
- [ ] Add `is_emergency` flag to change_requests
- [ ] Emergency change: single approver, go-live first, full docs within 30 days
- [ ] Emergency rationale captured with signature at point of emergency action
- [ ] KPI: emergency change ratio tracked on Quality dashboard

---

## Section 3: Missing Roles

The Astellas Reviewer/Approver Matrix reveals roles missing from OpenVAL:

| Astellas Role | OpenVAL Equivalent | Gap |
|---|---|---|
| Business Process Owner (BPO) | business_owner | ⚠️ Add formal approval rights |
| System Owner (SO) | system_owner | ⚠️ Add formal approval rights |
| Digital & Business Compliance | compliance_reviewer | ❌ Add new role |
| Records & Information Management (RIM) | records_manager | ❌ Add new role |
| E&C Data Privacy | data_privacy_officer | ❌ Add new role |
| TechX / Cyber Security | security_reviewer | ❌ Add new role |
| Quality Assurance (independent) | qa_manager | ✅ Exists |

**Critical Gap: Percentage-Based QA Sampling**
The Astellas matrix uses percentage-based QA review of test scripts:
- High GxP risk → QA reviews 100% of test scripts
- Medium GxP risk → QA reviews 50% of test scripts
- Low GxP risk → QA reviews 25% of test scripts

This concept — QA statistical sampling of scripts — does not exist anywhere
in OpenVAL. It is common in large enterprise pharma programs.

**Fixes Required:**
- [ ] Seed new default roles in `roles` table
- [ ] New table: `document_approval_matrix_configs` per site
- [ ] Add `qa_review_percentage` to `regulatory_system_categorizations`
- [ ] Implement sampling: when test script batch is approved, QA randomly assigned to N%

---

## Section 4: New Templates Summary

Templates to add in Phase 17 of the Master Plan (new total: 58 templates):

| Template Code | Name | Regulatory Basis |
|---|---|---|
| TMPL-RASC | Regulatory Assessment & System Categorization | GAMP 5, 21 CFR 211.68 |
| TMPL-BFRA | Business & Functional Risk Assessment | ICH Q9, GAMP 5 |
| TMPL-SMM | System Maintenance Manual | 21 CFR 211.68, EU Annex 11 §16 |
| TMPL-SRP | System Recovery Plan | EU Annex 11 §16, 21 CFR 211.68 |
| TMPL-SRS | System Release Statement | GAMP 5 §9 |
| TMPL-EOL-PLAN | System End of Life Plan | 21 CFR 211.180, ICH Q10 |
| TMPL-EOL-REPORT | System End of Life Report | 21 CFR 211.180 |
| TMPL-EHSA | Externally Hosted Security Assessment | EU Annex 11 §7, GAMP 5 |
| TMPL-URS-AGILE | Requirements Spec (User Story format) | GAMP 5 §5.3 |

---

## Section 5: Full Deliverable Coverage After Fixes

| Astellas Template | OpenVAL Status After Fix |
|---|---|
| STL-1905 RASC | ✅ Add (new) |
| STL-4767 CMDB Load | ✅ Via ServiceNow integration |
| STL-4145 EHSA | ✅ Add (new) |
| STL-1903 Validation Plan | ✅ Exists |
| STL-1897 Design/Config Spec | ✅ Exists |
| STL-4509 User Stories | ✅ Enhanced |
| STL-1888 BFRA | ✅ Add sub-type |
| STL-1912 Test Scripts | ✅ Protocol engine |
| STL-1891 Data Migration Plan | ✅ Exists (Part 6) |
| STL-1892 Data Migration Report | ✅ Exists (Part 6) |
| STL-1914 Defect Report | ✅ Deviation records |
| STL-1915 Trace Matrix | ✅ Auto-generated RTM |
| STL-1904 Validation Summary Report | ✅ Exists |
| STL-1910 System Release Statement | ✅ Add (new) |
| STL-728 System Maintenance Manual | ✅ Add (new) |
| STL-1909 System Recovery Plan | ✅ Add (new) |
| STL-1893 EOL Plan | ✅ Add (new) |
| STL-1894 EOL Report | ✅ Add (new) |
| STL-3719 Periodic Review Report | ✅ Exists |

**100% coverage of Astellas deliverables after fixes.**

---

*OpenVAL Gap Analysis | Based on Astellas GxP SLC SOP*
*Generated by Head of Global QA, OpenVAL Project | 2026-04-08*
