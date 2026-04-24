# PHAROLON Master Plan - Addendum 1

**Addendum Reference:** MASTER-ADD-001
**Version:** 1.0
**Date:** 2026-04-07
**Supersedes:** Sections of MASTER_PLAN.md Phases 10, 14, 15, 18, and Future Roadmap
**Purpose:** Incorporate competitive research findings, new modules, extended phases

---

## Summary of Changes from Research

After reviewing DCP (Roche/Genentech), MasterControl, TrackWise/Honeywell,
Veeva Vault, ETQ Reliance, LabWare, and AmpleLogic, the following additions
and enhancements have been approved for the PHAROLON roadmap.

### New Modules Added
1. OOS/OOT Management (Phase 10 extension)
2. Complaint Management (Phase 10 extension)
3. Environmental Monitoring (Phase 15 extension)
4. Stability Study Management (Phase 15 extension)
5. Batch and Lot Management (Phase 15 extension)
6. Inspection Readiness Mode (Phase 14 extension)
7. Closed-Loop Automation Engine (Phase 8 extension)
8. Validation Setup Wizard (Phase 3 extension)
9. Statistical Process Control (Phase 21 - new)
10. Manufacturing Analytics Extension (Phase 21 - new)
11. AI Assistance Layer Phase 1 (Phase 22 - new)
12. AI Governance Framework (Phase 22 - new)
13. AI Assistance Layer Phase 2 (Phase 23 - new)

### Cross-Cutting Enhancements Added
- GxP API flag in all responses (Phase 0)
- External reference columns on key tables (Phase 18)
- Cross-site document distribution (Phase 18)
- Organization-level settings with site override (Phase 18)
- Automation rules engine (Phase 8)

### Schema Additions
- 25+ new tables in Part 3 schema
- External reference columns on change_requests, capas, nonconformances, deviations
- AI governance tables (ai_suggestions, ai_model_registry)
- Manufacturing analytics tables (process_parameters, process_data_points)

---

## Updated Phase 10: CAPA, NCE, OOS/OOT, and Complaints (Months 14-16)

Phase 10 is extended to two months to accommodate the new modules.

### Original Phase 10 Tasks (retained)
- [ ] CAPA list page with status filters and overdue highlighting
- [ ] CAPA detail with root cause analysis tools (5 Whys, Fishbone)
- [ ] Action plan with task assignment
- [ ] Effectiveness check scheduling and execution
- [ ] Closure with signature
- [ ] NC list and detail pages
- [ ] NC investigation module
- [ ] Bidirectional linking (NC → CAPA → Change → Protocol)
- [ ] CAPA metrics dashboard

### New Tasks: OOS/OOT Module

**Phase 1 Investigation Screen:**
- [ ] OOS record creation from manual entry or LIMS webhook
- [ ] Phase 1 investigation form (lab error assessment)
- [ ] Lab error found path: invalidate result, log retest
- [ ] No lab error found: escalate to Phase 2 automatically
- [ ] Retest record capture (up to 3 retest cycles)

**Phase 2 Investigation Screen:**
- [ ] Phase 2 full investigation form with root cause
- [ ] Disposition options: reject, pass with justification, retest
- [ ] Lot/batch impact assessment
- [ ] CAPA linkage if required
- [ ] OOS closure with signature

**OOT Module:**
- [ ] Control limit configuration per test/product
- [ ] OOT detection algorithm (statistical trend detection)
- [ ] OOT record creation (manual or automated from SPC)
- [ ] Investigation workflow similar to OOS Phase 2

**List and Dashboard Views:**
- [ ] OOS/OOT list page with filter by type, status, test, product
- [ ] Phase aging report (time in Phase 1, time in Phase 2)
- [ ] OOS rate trend chart by test type and time period

### New Tasks: Complaint Management Module

- [ ] Complaint intake form (receipt method, complainant info, product)
- [ ] Triage view (is this reportable? severity assessment)
- [ ] Investigation form with lot disposition
- [ ] Regulatory reportability determination workflow
- [ ] Response drafting and tracking
- [ ] CAPA linkage
- [ ] Complaint closure with signature
- [ ] Complaint metrics: by type, product, severity, closure time
- [ ] Regulatory report tracker (MDR, field safety)
- [ ] Integration hook: complaint → LIMS for lot testing

---

## Updated Phase 14: Vendor, Audit, and Inspection Readiness (Months 18-20)

### Original Phase 14 Tasks (retained)
- [ ] Vendor directory with qualification status indicators
- [ ] Vendor qualification workflow
- [ ] Vendor audit scheduling and findings management
- [ ] Audit (internal/external) management module
- [ ] Audit finding response and CAPA linking
- [ ] Audit calendar
- [ ] Regulatory inspection preparation checklist

### New Tasks: Inspection Readiness Module

**Readiness Dashboard:**
- [ ] Real-time compliance scorecard (red/amber/green per area)
- [ ] Automated checks: overdue CAPAs, expired validations, training gaps, overdue reviews
- [ ] Open audit findings from all sources (internal, external, vendor)
- [ ] Systems with upcoming revalidation (next 90/180 days)
- [ ] Documents overdue for review
- [ ] Training compliance matrix (clickable to drill down)
- [ ] Open OOS/OOT investigations
- [ ] Open complaints (with reportable flag highlighted)
- [ ] Active change requests with regulatory impact

**Inspection Simulation:**
- [ ] Framework selector (FDA GMP 21 CFR 211, FDA GLP, EMA GMP, ISO 13485)
- [ ] Auto-generated list of records an inspector would likely request
- [ ] Gap highlighting (records with missing evidence, incomplete fields)
- [ ] Export as pre-inspection report

**Mock Inspection Checklists:**
- [ ] Pre-built checklists aligned to FDA 483 common observations (by area)
- [ ] Completable per area with evidence links
- [ ] Pass/fail per checklist item with notes

**Active Inspection Management:**
- [ ] Log active inspection: agency, date, scope, inspectors
- [ ] Track document requests and responses in real time
- [ ] Verbal commitment tracking
- [ ] Post-inspection finding capture
- [ ] Link inspection findings to CAPA

---

## Updated Phase 15: Training, EM, Stability, Batch (Months 20-23)

Phase 15 is extended to three months.

### Original Phase 15 Tasks (retained)
- [ ] Training requirement configuration (linked to documents and roles)
- [ ] Training assignment management
- [ ] Training completion recording with signature
- [ ] Training compliance matrix report
- [ ] Expiry tracking and renewal notifications
- [ ] Training gap analysis on document distribution

### Closed-Loop: Auto-Assign Training on Document Approval
- [ ] When document is approved and effective, automation rule triggers
  training assignment for all users in required_roles
- [ ] Training assignments include link to new document version
- [ ] Users see "New Training Required" banner on login

### New Tasks: Environmental Monitoring Module

**Location and Sample Point Setup:**
- [ ] EM location builder (rooms, zones, ISO class, EU GMP grade)
- [ ] Sample point configuration per location (type, frequency, limits)
- [ ] EM program summary view (all locations, sample points, frequencies)

**Scheduling:**
- [ ] EM schedule configuration (which points, how often)
- [ ] EM calendar view (upcoming sessions, overdue sessions)
- [ ] Session creation from schedule (auto-generates from due dates)

**Result Entry:**
- [ ] EM session execution screen (step through each sample point)
- [ ] Result entry with organism identification
- [ ] Automatic limit comparison on entry
- [ ] Excursion auto-creation when result exceeds alert or action limit
- [ ] Session summary and sign-off

**Excursion Management:**
- [ ] Excursion list with filter by location, type, status
- [ ] Excursion investigation workflow
- [ ] CAPA linkage if required
- [ ] Recheck scheduling
- [ ] Excursion closure

**Reporting and Trending:**
- [ ] EM trending charts by location, sample type, time period
- [ ] Monthly EM summary report (suitable for quality review)
- [ ] Excursion rate by location and time
- [ ] SPC chart for EM data (integrated with SPC module in Phase 21)

### New Tasks: Stability Study Management

- [ ] Stability study setup form (product, conditions, ICH guidance)
- [ ] Time point configuration and auto-calculation of pull dates
- [ ] Pull calendar (upcoming pulls highlighted)
- [ ] Result entry per time point and test
- [ ] Trending charts (parameter vs time point, multi-study overlay)
- [ ] Stability summary report generation
- [ ] OOS auto-link when stability result is OOS
- [ ] Study closure workflow

### New Tasks: Batch and Lot Management

- [ ] Batch creation form
- [ ] Batch status board (in testing, hold, released, rejected)
- [ ] Test request assignment (QC tests required for this batch)
- [ ] Hold management (reason, notification, resolution)
- [ ] Lot release workflow with QA signature
- [ ] Certificate of Analysis (CoA) generation (auto-populated from batch + test results)
- [ ] CoA approval and e-signature
- [ ] CoA version history
- [ ] Integration hook: LabWare lot disposition → PHAROLON batch status

---

## Updated Phase 18: Administration, Integrations, and Multi-Site (Months 23-25)

### Original Phase 18 Tasks (retained)
- [ ] LDAP/Active Directory sync
- [ ] SAML/OIDC SSO integration
- [ ] REST API documentation
- [ ] API key management
- [ ] Webhook configuration
- [ ] Slack/Teams notification integration
- [ ] System health monitoring page
- [ ] Backup management UI
- [ ] Upgrade management

### New Tasks: Integration Management

**LabWare LIMS Integration:**
- [ ] LabWare connection configuration (URL, API key, site code)
- [ ] Bidirectional system status sync
- [ ] EM excursion webhook receiver
- [ ] OOS result webhook receiver
- [ ] Audit trail comparison tool (PHAROLON periodic review vs LabWare audit export)
- [ ] Connection health monitoring

**TrackWise Integration:**
- [ ] TrackWise connection configuration
- [ ] Change request sync (inbound TrackWise → PHAROLON CR)
- [ ] CAPA sync (configurable: TW as master or OV as master)
- [ ] Export: PHAROLON records in TrackWise XML format

**MES Integration:**
- [ ] MES event webhook receiver
- [ ] Batch event auto-processing (create batch record, link process deviations)
- [ ] Process parameter ingestion endpoint
- [ ] Tempo MES specific configuration (MATC environment)

**Cross-Site Features:**
- [ ] Corporate document publishing (source site → target sites)
- [ ] Controlled copy management
- [ ] Cross-site compliance dashboard (requires multi-site deployment)
- [ ] Organization-level settings with site override controls
- [ ] Harmonized lookup table management (corporate-managed values)

**TrackWise Export Tool:**
- [ ] Select change requests, CAPAs, or NCs from date range
- [ ] Generate TrackWise-compatible XML export
- [ ] Validation: verify all required fields are populated before export

---

## New Phase 21: Manufacturing Analytics (Month 25-26)

**Goal:** Optional analytics module for process monitoring and SPC.
Non-GxP unless specifically validated. Clearly labeled in UI (DCP pattern).

### SPC Module
- [ ] SPC chart builder (select data source, chart type, parameters)
- [ ] Control limit calculation from historical data (automatic)
- [ ] Nelson rules engine for out-of-control detection
- [ ] Out-of-control event list with acknowledge/investigate workflow
- [ ] SPC chart dashboard (all active charts, status indicators)
- [ ] SPC alert → OOT record auto-creation (configurable)
- [ ] Charts for: EM data, stability data, OOS rates, CAPA cycle times

### Manufacturing Analytics
- [ ] Process parameter ingestion endpoint (REST API)
- [ ] Real-time parameter monitoring dashboard (Grafana-style)
- [ ] Batch evolution chart (parameter trends over batch duration)
- [ ] Batch-to-batch comparison (overlay multiple batches)
- [ ] CPP/CQA correlation analysis (scatter plot with regression)
- [ ] Process capability report (Cp, Cpk per parameter)
- [ ] Batch process summary auto-generation on batch completion
- [ ] Process deviation auto-creation when action limit breached
- [ ] GxP/non-GxP boundary labeling in UI (DCP-inspired)

---

## New Phase 22: AI Assistance - Phase 1 (Month 26-28)

**Goal:** Embed AI assistance into everyday workflows. Human-in-the-loop always.
All AI interactions logged in ai_suggestions table.

### Prerequisite: AI Governance Framework
- [ ] AI model registry (track what models are deployed and their validation status)
- [ ] AI suggestion logging (every suggestion, accepted/rejected, user modification)
- [ ] AI audit trail (AI involvement clearly noted on records where AI assisted)
- [ ] AI transparency display (users can see if AI assisted in creating a record)
- [ ] AI configuration page (enable/disable features per site)

### Document AI Features
- [ ] SOP draft assistant: enter title + scope → AI generates first draft
- [ ] Regulatory gap checker: compare SOP against selected CFR section
- [ ] Document similarity search (before creating, find existing similar docs)
- [ ] Cross-reference validator: flags references to superseded documents

### CAPA Intelligence
- [ ] Root cause suggestions: given deviation description → top 3 root cause categories
- [ ] Similar CAPA finder: shows historical CAPAs with similar characteristics
- [ ] Action effectiveness predictor: based on action type + root cause type
- [ ] Overdue risk scoring: CAPA risk dashboard with AI-driven priority

### Deviation Pattern Analysis
- [ ] Recurring deviation detector: same system + same type
- [ ] Cross-system pattern detector: site-wide pattern identification
- [ ] Severity trend alerting: escalating deviation severity over time

### Risk Item Suggestions
- [ ] Based on system type + GAMP category: suggest common risk items
- [ ] Control effectiveness scoring from natural language description
- [ ] Residual risk suggestions

### User Experience
- [ ] AI suggestions appear as inline callout boxes (visually distinct)
- [ ] Clear "AI Suggested" label on all AI-generated content
- [ ] One-click accept or dismiss for each suggestion
- [ ] Accepted suggestions become editable (user must review, not blindly accept)
- [ ] Feedback mechanism: users can rate suggestion quality

---

## New Phase 23: AI Assistance - Phase 2 (Month 28+)

### Inspection Readiness AI
- [ ] Predicted inspection focus areas based on quality event history
- [ ] Common 483 observation response library (by area and observation type)
- [ ] Data integrity risk scanner (analyzes audit trail for anomaly patterns)

### Document Intelligence
- [ ] Semantic search across all controlled documents
- [ ] Automatic document classification and metadata tagging
- [ ] Regulatory change impact analysis (given new FDA guidance, which SOPs need update)
- [ ] Translation assistance for multi-language sites

### Predictive Quality
- [ ] Quality event prediction using leading indicators
- [ ] Process trend monitoring with predictive alerts
- [ ] Risk score updates based on recent quality event history

---

## Updated Market Context

From competitive research:

- The global pharmaceutical Quality Management Software market was valued at $1.87 billion in 2024 and is expected to more than double by 2030 at ~12.99% CAGR.
- Cloud deployment dominates at ~77% of QMS market share in 2024. PHAROLON's self-hosted positioning addresses the 23% that cannot or will not go cloud.
- AI-embedded CAPA investigation is estimated to reduce investigation time by 50-70% compared with conventional investigations. PHAROLON Phase 22 targets this.
- MasterControl's patented Accelerated Validation reduces validation time from weeks to minutes. PHAROLON's Guided Validation Wizard (Phase 3) is our open source equivalent.

PHAROLON does not compete with MasterControl or Veeva on enterprise feature depth in year one.
PHAROLON competes on: open source, self-hosted, bundled validation package, and no licensing cost.
The market exists. The gap exists. The plan is sound.

---

## Updated Complete Phase Summary

| Phase | Name | Months | Status |
|---|---|---|---|
| 0 | Foundation and SDL | 1-2 | Plan complete |
| 1 | Core Data Layer | 2-3 | Plan complete |
| 2 | Application Shell | 3-4 | Plan complete |
| 3 | System Inventory + Validation Wizard | 4-5 | Plan complete |
| 4 | Risk Assessment | 5-6 | Plan complete |
| 5 | Requirements Management | 6-7 | Plan complete |
| 6 | Protocol Builder | 7-9 | Plan complete |
| 7 | Document Management | 9-11 | Plan complete |
| 8 | Workflow Engine + Automation Rules | 11-13 | Plan complete |
| 9 | Change Control | 13-14 | Plan complete |
| 10 | CAPA + NCE + OOS/OOT + Complaints | 14-16 | Plan complete |
| 11 | Periodic Review | 16-17 | Plan complete |
| 12 | Traceability Matrix | 17-18 | Plan complete |
| 13 | Reporting and Dashboards | 18-19 | Plan complete |
| 14 | Vendor + Audit + Inspection Readiness | 19-21 | Plan complete |
| 15 | Training + EM + Stability + Batch/Lot | 21-24 | Plan complete |
| 16 | Validation Package for PHAROLON | 24-25 | Plan complete |
| 17 | Pharma Template Library | 25-26 | Plan complete |
| 18 | Admin + Integrations + Multi-Site | 26-28 | Plan complete |
| 19 | Security Hardening + Performance | 28-29 | Plan complete |
| 20 | Docker Option + Community Launch | 29-30 | Plan complete |
| 21 | SPC + Manufacturing Analytics | 30-32 | Plan complete |
| 22 | AI Assistance Phase 1 + Governance | 32-34 | Plan complete |
| 23 | AI Assistance Phase 2 | 34+ | Plan complete |

---

*MASTER-ADD-001 v1.0 - This addendum updates the living plan.*
*The MASTER_PLAN.md will be revised to incorporate these changes at next scheduled update.*
