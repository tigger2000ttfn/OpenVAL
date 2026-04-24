# PHAROLON Module Extensions and Enhancements
## Informed by Competitive Research: DCP, MasterControl, TrackWise, Veeva Vault, ETQ Reliance, LabWare ELN

**Document Reference:** MODULE-EXT-001
**Version:** 1.0
**Date:** 2026-04-07
**Status:** Approved for Planning

---

## Overview

This document captures all module extensions, new modules, and enhancements
identified through analysis of the competitive landscape and open source
ecosystem. Each item includes its source of inspiration, the gap it fills in
the current PHAROLON plan, and its target phase.

---

## 1. Closed-Loop Quality Automation

**Inspired by:** MasterControl, TrackWise, Veeva Vault
**Gap:** Current plan treats modules as independent. Commercial leaders
differentiate on automated linkages between quality events.

### What This Means for PHAROLON

The system must automatically initiate downstream actions when upstream events occur.
This is not a separate module. It is a cross-cutting enhancement to the workflow
engine that adds trigger-based automation rules.

### Closed-Loop Triggers to Implement

| Trigger Event | Automated Response | Config |
|---|---|---|
| Document approved and effective | Assign training to all users in required_roles | Configurable per document category |
| Document version superseded | Cancel pending training assignments for old version | Automatic |
| Deviation severity = critical | Auto-create CAPA, notify QA manager | Configurable |
| Deviation raised during execution | Auto-create CAPA if capa_required flag set | Configurable per deviation type |
| CAPA effectiveness check failed | Re-open CAPA, notify owner | Automatic |
| System revalidation_required = true | Create periodic review, notify technical owner | Configurable |
| Change request implemented | Flag affected systems for impact review | Automatic |
| Change request approved with testing_required | Create UAT protocol task | Configurable |
| Equipment calibration_due in X days | Create calibration reminder task | Configurable |
| OOS result recorded | Auto-create deviation, notify lab supervisor | Configurable |
| OOT trend detected | Auto-create CAPA recommendation | Configurable |
| Audit finding raised | Create CAPA if capa_required | Configurable |
| Periodic review outcome = revalidation_required | Create change request, flag system | Automatic |
| Training assignment expired | Re-assign training, notify user | Configurable |
| Vendor qualification expiring in X days | Create requalification task | Configurable |

### Database Table Addition

**automation_rules**
- id (uuid, PK)
- site_id (uuid, FK sites)
- rule_name (varchar 255)
- trigger_object_type (varchar 100) -- deviation, document_version, capa, etc.
- trigger_event (varchar 100) -- created, status_changed, field_changed
- trigger_conditions (text) -- JSON conditions
- action_type (varchar 100) -- create_capa, assign_training, create_task, send_notification, update_field, start_workflow
- action_config (text) -- JSON action parameters
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**automation_rule_executions**
- id (uuid, PK)
- rule_id (uuid, FK automation_rules)
- trigger_object_type (varchar 100)
- trigger_object_id (uuid)
- status (varchar 50) -- success, failed, skipped
- result_object_type (varchar 100) -- what was created
- result_object_id (uuid)
- executed_at (timestamptz)
- error_message (text)

### Target Phase: Phase 8 (Workflow Engine) - extend during build

---

## 2. Validation Setup Wizard ("Guided Validation")

**Inspired by:** MasterControl "Validation on Demand" / "Accelerated Validation"
**Gap:** Current plan requires users to manually create system records, risk assessments,
requirement sets, and protocols separately. MasterControl's wizard cuts this setup
time dramatically for non-expert users.

### What This Means for PHAROLON

A step-by-step guided wizard that walks a user through setting up a complete
validation project for a new system, starting from nothing and generating a full
scaffold in minutes.

### Wizard Steps

**Step 1: System Classification**
- Enter system name, description, vendor
- Answer GAMP 5 classification questions (guided, with explanations)
- System recommends GAMP category with justification text
- Select applicable regulations (checkboxes)
- Identify GxP impact areas (guided questions)

**Step 2: Validation Approach**
- Based on GAMP category, wizard recommends validation scope
- User selects: Full IQ/OQ/PQ, Risk-Based, Retrospective, Verification Only
- Wizard generates validation plan outline

**Step 3: Risk Assessment Scaffold**
- Based on system type and GAMP category, pre-populate common risk items from template library
- User reviews and customizes
- Risk matrix auto-selected based on category

**Step 4: Requirements Generation**
- Wizard generates a URS skeleton from system type template
- Pre-populated with common regulatory requirements for the regulation set selected
- User customizes

**Step 5: Protocol Selection**
- Based on system type, wizard recommends IQ/OQ/PQ template combination
- Creates protocols from templates with system information pre-filled

**Step 6: Workflow Assignment**
- Assign owners, reviewers, QA approvers
- Set target dates
- Activate relevant notification rules

**Step 7: Summary**
- Shows everything that was created
- Link to validation dashboard for this system
- Estimated timeline

### Target Phase: Phase 3 (System Inventory) - add as enhanced creation path

---

## 3. OOS / OOT Management Module

**Inspired by:** AmpleLogic, LabWare, TrackWise
**Gap:** Out of Specification and Out of Trend management is missing from current plan.
This is a core QC/QA function in any pharmaceutical lab environment.

### Module Purpose

Manage the full investigation lifecycle for laboratory results that fall outside
specification limits (OOS) or trend outside defined control limits (OOT).

### OOS/OOT Workflow

```
Sample tested → Result entered →
  If within spec: normal → no OOS
  If outside spec: Phase 1 Investigation (lab error check)
    → Lab error found: invalidate, retest
    → No lab error: Phase 2 Investigation (full investigation)
      → Root cause identified
      → Disposition: reject | pass with justification | retest
      → CAPA if required
      → Report generated with e-signatures
```

### Database Tables

**oos_oot_records**
- id (uuid, PK)
- record_ref (varchar 50, unique) -- OOS-0001
- site_id (uuid, FK sites)
- record_type (varchar 10) -- OOS, OOT
- system_id (uuid, FK systems, nullable) -- if from LIMS integration
- product_name (varchar 255)
- batch_lot_number (varchar 100)
- sample_id (varchar 255)
- test_name (varchar 512)
- specification_limit (varchar 255)
- result_obtained (varchar 255)
- unit (varchar 50)
- percent_deviation (decimal)
- analyst_id (uuid, FK users)
- instrument_id (uuid, FK equipment, nullable)
- test_date (date)
- phase (varchar 20) -- phase_1, phase_2, closed
- phase1_investigation_text (text)
- phase1_outcome (varchar 50) -- lab_error, no_lab_error
- phase1_completed_by (uuid, FK users)
- phase1_completed_at (timestamptz)
- phase2_root_cause (text)
- phase2_investigation_text (text)
- phase2_outcome (varchar 50) -- retest_required, reject, pass_with_justification
- disposition (varchar 50)
- disposition_rationale (text)
- capa_required (boolean)
- capa_id (uuid, FK capas, nullable)
- status (varchar 50) -- open, phase1, phase2, closed
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**oot_control_limits**
- id (uuid, PK)
- site_id (uuid, FK sites)
- test_name (varchar 512)
- product_name (varchar 255)
- limit_type (varchar 50) -- action_limit, alert_limit, trend_limit
- lower_limit (decimal)
- upper_limit (decimal)
- unit (varchar 50)
- statistical_basis (varchar 255)
- effective_from (date)
- effective_to (date, nullable)
- created_at, updated_at, created_by, updated_by

**oos_retest_records**
- id (uuid, PK)
- oos_id (uuid, FK oos_oot_records)
- retest_number (int)
- retest_result (varchar 255)
- retest_date (date)
- analyst_id (uuid, FK users)
- instrument_id (uuid, FK equipment, nullable)
- pass_fail (varchar 10)
- notes (text)
- created_at, created_by

### Target Phase: Phase 10 (add alongside CAPA) - NEW

---

## 4. Complaint Management Module

**Inspired by:** MasterControl, AmpleLogic, Veeva Vault, ETQ Reliance
**Gap:** Entirely missing from current plan. Required for 21 CFR 211.198 (complaint files)
and 21 CFR 820.198 (complaint handling for devices).

### Module Purpose

Track, investigate, and resolve product complaints, adverse events, and
customer feedback in a GxP-compliant manner.

### Complaint Workflow

```
Complaint received → Triage → Investigation → 
  Reportable? → MDR/NDA/BLA reporting decision
  Root cause → CAPA if required
  Response to complainant → Close
```

### Database Tables

**complaints**
- id (uuid, PK)
- complaint_ref (varchar 50, unique) -- COMP-0001
- site_id (uuid, FK sites)
- received_date (date, not null)
- received_by (uuid, FK users)
- receipt_method (varchar 100) -- phone, email, written, field_report, regulatory_report
- complainant_name (varchar 255)
- complainant_type (varchar 100) -- patient, healthcare_professional, distributor, regulatory
- complainant_contact (text)
- product_name (varchar 512)
- product_lot_number (varchar 100)
- product_batch_number (varchar 100)
- complaint_type (varchar 100) -- product_quality, adverse_event, device_malfunction, packaging, labeling, other
- complaint_description (text, not null)
- patient_impact (boolean, default false)
- adverse_event_occurred (boolean, default false)
- adverse_event_description (text)
- severity (varchar 50)
- is_reportable (boolean, nullable) -- null = not yet assessed
- reportable_reason (text)
- regulatory_report_type (varchar 100) -- MDR, field_safety, NDA_supplement
- regulatory_report_submitted_at (timestamptz)
- regulatory_report_ref (varchar 255)
- investigation_required (boolean, default true)
- root_cause (text)
- root_cause_category (varchar 100)
- corrective_action_taken (text)
- capa_required (boolean, default false)
- capa_id (uuid, FK capas, nullable)
- response_required (boolean, default true)
- response_due_date (date)
- response_sent_at (timestamptz)
- response_content (text)
- status (varchar 50) -- open, under_investigation, pending_response, closed, on_hold
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**complaint_investigations**
- id (uuid, PK)
- complaint_id (uuid, FK complaints)
- investigator_id (uuid, FK users)
- investigation_start_date (date)
- investigation_end_date (date)
- lot_disposition (varchar 100) -- recall, quarantine, no_action, field_correction
- test_results (text)
- findings (text, not null)
- timeline_of_events (text)
- created_at, updated_at, created_by, updated_by

### Target Phase: Phase 10 (add alongside CAPA/NCE) - NEW

---

## 5. Environmental Monitoring Module

**Inspired by:** LabWare EM workflows, AmpleLogic EM monitoring
**Gap:** Michael's direct experience with EM LIMS go-live. Current plan references
EM only as a template. Needs a full module.

### Module Purpose

Manage environmental monitoring program: schedule sampling, capture results,
manage excursions, trend data, and generate EM reports for GMP compliance.

### Key Concepts

- Monitoring locations (rooms, surfaces, air, personnel)
- Sample points within locations with defined frequency
- Alert and action limits per sample point and organism type
- Exceedance management (similar to OOS)
- Trend analysis (SPC charts over time)
- EM program review

### Database Tables

**em_locations**
- id (uuid, PK)
- site_id (uuid, FK sites)
- location_code (varchar 50, unique)
- location_name (varchar 512)
- location_type (varchar 100) -- cleanroom, corridor, controlled_area, critical_zone
- iso_class (varchar 20) -- ISO 5, ISO 7, ISO 8
- eu_gmp_grade (varchar 5) -- A, B, C, D
- department_id (uuid, FK departments, nullable)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**em_sample_points**
- id (uuid, PK)
- location_id (uuid, FK em_locations)
- point_code (varchar 50, unique)
- point_name (varchar 512)
- sample_type (varchar 100) -- active_air, passive_air, surface_contact, surface_swab, personnel_glove, personnel_gown, water
- monitoring_frequency (varchar 100) -- every_batch, weekly, monthly, quarterly
- alert_limit (decimal, nullable) -- CFU threshold
- action_limit (decimal, nullable)
- unit (varchar 50, default 'CFU')
- organism_targets (text) -- JSON array of organism types to monitor
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**em_schedules**
- id (uuid, PK)
- site_id (uuid, FK sites)
- schedule_name (varchar 512)
- sample_point_ids (text) -- JSON array of sample point IDs
- schedule_frequency (varchar 100)
- next_due_date (date)
- responsible_id (uuid, FK users)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**em_sessions**
- id (uuid, PK)
- session_ref (varchar 50, unique) -- EM-SESSION-0001
- site_id (uuid, FK sites)
- session_date (date, not null)
- session_type (varchar 100) -- routine, excursion_recheck, triggered
- status (varchar 50) -- scheduled, in_progress, complete, cancelled
- sampled_by (uuid, FK users)
- reviewed_by (uuid, FK users, nullable)
- total_samples (int)
- samples_within_limits (int)
- samples_at_alert (int)
- samples_at_action (int)
- notes (text)
- created_at, updated_at, created_by, updated_by

**em_results**
- id (uuid, PK)
- session_id (uuid, FK em_sessions)
- sample_point_id (uuid, FK em_sample_points)
- sample_id (varchar 100) -- lab sample ID
- result_value (decimal)
- result_unit (varchar 50)
- result_status (varchar 50) -- within_limits, at_alert, at_action, no_growth, too_numerous_to_count
- organisms_identified (text) -- JSON array
- sampled_by (uuid, FK users)
- sampled_at (timestamptz)
- incubation_start (timestamptz)
- read_at (timestamptz)
- read_by (uuid, FK users)
- excursion_id (uuid, FK em_excursions, nullable)
- comments (text)
- created_at, updated_at, created_by, updated_by

**em_excursions**
- id (uuid, PK)
- excursion_ref (varchar 50, unique) -- EM-EXC-0001
- site_id (uuid, FK sites)
- session_id (uuid, FK em_sessions)
- sample_point_id (uuid, FK em_sample_points)
- excursion_type (varchar 50) -- alert, action
- result_value (decimal)
- limit_exceeded (varchar 50) -- alert, action
- immediate_action_taken (text)
- investigation_required (boolean)
- root_cause (text)
- capa_required (boolean)
- capa_id (uuid, FK capas, nullable)
- recheck_required (boolean)
- recheck_date (date)
- status (varchar 50) -- open, under_investigation, closed
- closed_at (timestamptz)
- closed_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

### Target Phase: Phase 15 (Operations) - NEW module alongside training

---

## 6. Stability Study Management

**Inspired by:** LabWare stability module, ICH Q1A
**Gap:** Missing from current plan. Required for drug products and biologics.

### Module Purpose

Manage stability protocols, pull schedules, test results, and trending for
pharmaceutical products under ICH Q1A/Q1B stability guidance.

### Database Tables

**stability_studies**
- id (uuid, PK)
- study_ref (varchar 50, unique) -- STAB-0001
- site_id (uuid, FK sites)
- product_name (varchar 512)
- product_code (varchar 100)
- batch_numbers (text) -- JSON array
- study_type (varchar 100) -- real_time, accelerated, intermediate, stress, photostability
- study_purpose (varchar 100) -- registration, ongoing, forced_degradation
- container_closure (text)
- storage_conditions (text) -- JSON: [{temp, humidity, light}]
- protocol_id (uuid, FK documents, nullable) -- linked stability protocol SOP
- study_start_date (date)
- study_end_date (date, nullable)
- status (varchar 50) -- active, completed, cancelled, on_hold
- owner_id (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**stability_time_points**
- id (uuid, PK)
- study_id (uuid, FK stability_studies)
- time_point (varchar 50) -- T0, T3M, T6M, T9M, T12M, T18M, T24M, T36M
- nominal_days (int)
- pull_due_date (date)
- actual_pull_date (date)
- status (varchar 50) -- scheduled, due, pulled, testing, complete, missed
- pulled_by (uuid, FK users, nullable)
- created_at, updated_at, created_by, updated_by

**stability_results**
- id (uuid, PK)
- time_point_id (uuid, FK stability_time_points)
- test_name (varchar 512)
- specification (varchar 255)
- result_value (varchar 255)
- result_status (varchar 50) -- pass, fail, oos
- tested_by (uuid, FK users)
- tested_date (date)
- instrument_id (uuid, FK equipment, nullable)
- oos_id (uuid, FK oos_oot_records, nullable)
- comments (text)
- created_at, updated_at, created_by, updated_by

### Target Phase: Phase 15 - NEW

---

## 7. Batch and Lot Management

**Inspired by:** LabWare LIMS lot release, AmpleLogic batch hold/release
**Gap:** No batch tracking or lot release in current plan.
Needed for QC sample tracking and lot disposition.

### Module Purpose

Track the lifecycle of product batches and lots from sampling through
release or rejection, integrating with QC testing and quality events.

### Database Tables

**batches**
- id (uuid, PK)
- batch_ref (varchar 50, unique) -- BATCH-0001
- site_id (uuid, FK sites)
- product_name (varchar 512)
- product_code (varchar 100)
- batch_number (varchar 100, not null)
- lot_number (varchar 100)
- batch_type (varchar 100) -- commercial, clinical, validation, development
- manufacture_date (date)
- expiry_date (date)
- batch_size (decimal)
- batch_size_unit (varchar 50)
- status (varchar 50) -- in_testing, hold, approved, rejected, released, expired
- hold_reason (text)
- hold_initiated_by (uuid, FK users)
- hold_initiated_at (timestamptz)
- disposition (varchar 50) -- release, reject, reprocess, return_to_vendor
- disposition_rationale (text)
- disposed_by (uuid, FK users)
- disposed_at (timestamptz)
- released_at (timestamptz)
- released_by (uuid, FK users)
- created_at, updated_at, created_by, updated_by

**batch_test_requests**
- id (uuid, PK)
- batch_id (uuid, FK batches)
- test_type (varchar 100) -- identity, assay, sterility, endotoxin, em, stability
- requested_by (uuid, FK users)
- requested_at (timestamptz)
- due_date (date)
- status (varchar 50) -- pending, in_testing, complete, cancelled
- result_summary (varchar 50) -- pass, fail, oos
- completed_at (timestamptz)
- notes (text)
- created_at, updated_at, created_by, updated_by

**certificates_of_analysis**
- id (uuid, PK)
- coa_ref (varchar 50, unique) -- COA-0001
- batch_id (uuid, FK batches)
- generated_at (timestamptz)
- generated_by (uuid, FK users)
- approved_by (uuid, FK users)
- approved_at (timestamptz)
- signature_id (uuid, FK electronic_signatures)
- file_id (uuid, FK file_store)
- is_current (boolean, default true)
- created_at, created_by

### Target Phase: Phase 15 - NEW

---

## 8. Inspection Readiness Module

**Inspired by:** Veeva Vault, MasterControl inspection readiness features
**Gap:** Current plan has no dedicated inspection readiness capability.
Sites often scramble before an FDA or EMA inspection.

### Module Purpose

Provide a dedicated inspection readiness view that aggregates all potential
regulatory observations into one place before an inspection occurs.

### Key Features

**Inspection Readiness Dashboard**
- Real-time compliance scorecard across all modules
- Red/amber/green status per area: documents, training, CAPAs, systems, deviations
- Overdue items list with days overdue
- Open audit findings from previous inspections
- CAPA effectiveness checks pending
- Systems with expired validations or overdue periodic reviews
- Training compliance matrix (who is out of compliance)
- Open change requests with regulatory impact
- Open OOS/OOT investigations
- Open complaints with reportable flag

**Inspection Simulation**
- Select a regulatory framework (FDA GMP, FDA GLP, EMA, ISO 13485)
- System generates a list of records an inspector would likely request
- User can review and flag any gaps before the real inspection

**Inspection Record**
- Log an actual inspection: date, inspector, scope, agency
- Track questions asked and documents provided
- Capture verbal commitments made during inspection
- Convert to formal audit findings after inspection

**Mock Inspection Checklist**
- Pre-built checklists aligned to FDA 483 common observations
- Site-completable with status and evidence links

### Database Tables

**inspection_readiness_checks**
- id (uuid, PK)
- site_id (uuid, FK sites)
- check_name (varchar 512)
- check_category (varchar 100)
- regulatory_citation (varchar 255)
- check_type (varchar 50) -- automated, manual
- query_config (text) -- JSON for automated checks
- last_evaluated_at (timestamptz)
- status (varchar 50) -- pass, fail, warning, not_evaluated
- finding_count (int)
- created_at, updated_at, created_by, updated_by

**inspection_records**
- id (uuid, PK)
- inspection_ref (varchar 50, unique)
- site_id (uuid, FK sites)
- agency (varchar 255) -- FDA, EMA, ISO Registrar, PMDA, etc.
- inspection_type (varchar 100) -- routine, for_cause, pre_approval, surveillance
- start_date (date)
- end_date (date)
- lead_inspector_name (varchar 255)
- inspector_names (text) -- JSON array
- scope (text)
- status (varchar 50) -- scheduled, in_progress, closed_out, response_submitted
- verbal_commitments (text)
- closeout_date (date)
- created_at, updated_at, created_by, updated_by

**inspection_document_requests**
- id (uuid, PK)
- inspection_id (uuid, FK inspection_records)
- request_number (int)
- description (text)
- requested_at (timestamptz)
- provided_at (timestamptz)
- provided_by (uuid, FK users)
- linked_object_type (varchar 100)
- linked_object_id (uuid)
- notes (text)
- created_at, updated_at, created_by, updated_by

### Target Phase: Phase 14 (Audit Management) - extend - NEW capability

---

## 9. GxP API Flag in Responses

**Inspired by:** DCP's `isValidated` response header
**Gap:** No way for API consumers to know the GxP validation status
of the system or data they are receiving.

### Implementation

Add a standard header to all API responses:

```
X-PHAROLON-System-Validated: true
X-PHAROLON-GxP-Context: true
X-PHAROLON-Site-Code: MATC
X-PHAROLON-API-Version: 1.0
```

For data endpoints, include in response envelope:
```json
{
  "success": true,
  "data": { ... },
  "_meta": {
    "gxp_context": true,
    "system_validated": true,
    "data_as_of": "2026-04-07T14:00:00Z"
  }
}
```

### Target Phase: Phase 0 (Foundation) - add to response middleware

---

## 10. Statistical Process Control (SPC) Module

**Inspired by:** DCP's SPC capabilities, AmpleLogic trending
**Gap:** No process trending or statistical monitoring in current plan.

### Module Purpose

Apply statistical process control to any numeric data series tracked in PHAROLON:
EM results, OOS trends, CAPA cycle times, deviation rates, stability data.

### Chart Types

- X-bar and R charts (process control)
- Individual and Moving Range (I-MR) charts
- CUSUM (Cumulative Sum) charts for detecting small shifts
- Pareto charts for deviation/CAPA categorization
- Run charts with trend detection
- Box plots for stability trending

### Control Limit Management

- Calculate UCL/LCL from historical data (± 3 sigma)
- Alert limits at ± 2 sigma
- Nelson rules for out-of-control detection
- Western Electric rules
- User-defined limits override statistical limits

### Database Tables

**spc_charts**
- id (uuid, PK)
- site_id (uuid, FK sites)
- chart_name (varchar 512)
- chart_type (varchar 50) -- xbar_r, imr, cusum, pareto, run
- data_source_type (varchar 100) -- em_results, oos_results, stability_results, custom
- data_source_config (text) -- JSON query config
- x_axis_field (varchar 100)
- y_axis_field (varchar 100)
- grouping_field (varchar 100, nullable)
- ucl_value (decimal, nullable)
- lcl_value (decimal, nullable)
- center_line_value (decimal, nullable)
- alert_upper (decimal, nullable)
- alert_lower (decimal, nullable)
- auto_recalculate_limits (boolean, default true)
- recalculate_period_months (int, default 12)
- last_recalculated_at (timestamptz)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**spc_out_of_control_events**
- id (uuid, PK)
- chart_id (uuid, FK spc_charts)
- detected_at (timestamptz)
- rule_violated (varchar 100) -- nelson_1, nelson_2, western_electric_a, etc.
- rule_description (text)
- data_point_value (decimal)
- acknowledged (boolean, default false)
- acknowledged_by (uuid, FK users)
- acknowledged_at (timestamptz)
- action_taken (text)
- oot_created (boolean, default false)
- oot_id (uuid, FK oos_oot_records, nullable)

### Target Phase: Phase 21+ (Manufacturing Analytics) - NEW

---

## 11. AI Assistance Layer

**Inspired by:** MasterControl Insights AI, Veeva Vault AI, TrackWise predictive quality
**Gap:** No AI in current plan. Market is moving rapidly here.

### Guiding Principle

AI in PHAROLON is always **human-in-the-loop**. AI makes suggestions.
Humans make decisions. Every AI-generated suggestion that a human acts on
is attributed to the human, not the AI, in the audit trail. AI suggestions
themselves are logged separately with their confidence score.

This is required for 21 CFR Part 11 compliance. The system must know who
made the regulated decision.

### Phase 1 AI Features (Phase 22)

**Smart Document Assistance**
- AI-assisted SOP authoring: given a title and scope, generates a first draft
- Gap analysis: compare a draft SOP against regulatory requirements for the selected CFR section
- Cross-reference checker: flags when a document references another document that is superseded
- Similar document finder: before creating a new document, finds existing documents with similar content

**CAPA Intelligence**
- Root cause suggestions: given a deviation description, suggests likely root cause categories based on historical patterns from the site
- Similar CAPA finder: shows CAPAs with similar problem statements and their effectiveness outcomes
- CAPA action effectiveness predictor: based on action type and root cause, predicts likelihood of success
- Overdue risk scoring: flags CAPAs at high risk of becoming overdue based on complexity and assignee workload

**Deviation Pattern Analysis**
- Recurring deviation detection: identifies when the same type of deviation keeps occurring for the same system
- Cross-system pattern detection: spots when a deviation pattern appears across multiple systems (may indicate a site-wide issue)
- Severity trend analysis: flags when deviation severity is trending upward for a system

**Risk Assessment Assistance**
- Pre-populated risk item suggestions based on system type and GAMP category (sourced from template library patterns)
- Control effectiveness scoring: based on the controls described, suggests a probability score
- Residual risk calculator: suggests residual scores based on mitigation quality

**Training Gap Prediction**
- Identifies users likely to have training gaps based on their role, recent document changes, and training history
- Recommends training assignments proactively

### Phase 2 AI Features (Phase 23+)

**Inspection Readiness AI**
- Predicts likely inspection focus areas based on recent quality events
- Generates suggested responses to common FDA 483 observations
- Identifies data integrity risks in the audit trail

**Document NLP**
- Full-text semantic search across all documents (not just keyword matching)
- Automatic metadata tagging and classification
- Regulatory change impact analysis: given a new FDA guidance, identifies which SOPs may need updating

**Predictive Quality**
- Quality event prediction: identifies leading indicators of upcoming deviations or OOS results
- Process trend monitoring: flags systems showing deteriorating quality metrics before they become problems

### AI Governance Tables

**ai_suggestions**
- id (uuid, PK)
- suggestion_type (varchar 100) -- root_cause, risk_item, document_gap, similar_capa
- source_object_type (varchar 100)
- source_object_id (uuid)
- model_version (varchar 50)
- suggestion_content (text) -- JSON
- confidence_score (decimal)
- presented_to (uuid, FK users)
- presented_at (timestamptz)
- accepted (boolean, nullable) -- null = not yet acted on
- accepted_at (timestamptz)
- accepted_by (uuid, FK users)
- user_modification (text) -- how user modified the suggestion before accepting
- dismissed_reason (varchar 255)

**ai_model_registry**
- id (uuid, PK)
- model_name (varchar 255)
- model_version (varchar 50)
- model_type (varchar 100) -- nlp, classification, regression, recommendation
- validation_status (varchar 50) -- not_validated, validated, retired
- validation_date (date)
- validation_document_id (uuid, FK documents, nullable)
- deployed_at (timestamptz)
- retired_at (timestamptz)
- description (text)
- created_at, updated_at, created_by, updated_by

### Target Phase: Phase 22-23 - NEW

---

## 12. Manufacturing Analytics Extension

**Inspired by:** DCP (Roche/Genentech), Grafana patterns for time-series
**Gap:** Process monitoring, real-time data, batch analytics missing.

### Scope

This is an optional extension module that bridges PHAROLON's quality/validation
world with manufacturing process data. It is non-GxP unless explicitly validated.
The GxP/non-GxP boundary is clearly labeled in the UI (DCP pattern).

### Data Sources

- Direct instrument/sensor data via REST API ingestion
- Manual data entry for batch parameters
- LIMS result feeds
- MES batch record data

### Capabilities

- Real-time process parameter monitoring with configurable limits
- Batch evolution charts (how did this batch's CPP/CQA behave over time)
- Batch-to-batch comparison charts
- CPP (Critical Process Parameter) trend monitoring
- CQA (Critical Quality Attribute) correlation analysis
- Process capability indices (Cp, Cpk)
- Control chart generation for process parameters
- Automated report generation for batch review meetings

### Integration with PHAROLON Quality Modules

- Process parameter exceedance auto-creates a deviation
- Batch-to-batch trending feeding into SPC module
- Manufacturing data linking to batch and lot records

### Database Tables (Extensions)

**process_parameters**
- id (uuid, PK)
- site_id (uuid, FK sites)
- parameter_name (varchar 512)
- parameter_code (varchar 100)
- parameter_type (varchar 50) -- cpp, cqa, kpi, monitoring
- unit (varchar 50)
- normal_lower (decimal)
- normal_upper (decimal)
- alert_lower (decimal)
- alert_upper (decimal)
- action_lower (decimal)
- action_upper (decimal)
- equipment_id (uuid, FK equipment, nullable)
- is_gxp_relevant (boolean)
- is_active (boolean)
- created_at, updated_at, created_by, updated_by

**process_data_points**
- id (uuid, PK)
- parameter_id (uuid, FK process_parameters)
- batch_id (uuid, FK batches, nullable)
- timestamp (timestamptz, not null)
- value (decimal, not null)
- status (varchar 20) -- normal, alert, action
- source (varchar 50) -- instrument, manual, lims, mes
- created_at (timestamptz)

**batch_process_summaries**
- id (uuid, PK)
- batch_id (uuid, FK batches)
- parameter_id (uuid, FK process_parameters)
- min_value (decimal)
- max_value (decimal)
- mean_value (decimal)
- std_deviation (decimal)
- time_in_normal (decimal) -- percentage
- time_in_alert (decimal)
- time_in_action (decimal)
- exceedance_count (int)
- summary_generated_at (timestamptz)

### Target Phase: Phase 21 - NEW (after core is stable)

---

## 13. Multi-Site Enterprise Features

**Inspired by:** Veeva Vault multi-site, MasterControl global deployment,
DCP's network-wide standardization across 9+ Roche sites
**Gap:** Current plan has site-level separation but lacks true enterprise
cross-site capabilities.

### New Capabilities

**Cross-Site Document Publishing**
- Publish a document from a parent/global site to child sites
- Child sites receive as a controlled copy (read-only or locally-adaptable)
- Global SOPs push to all sites; site-specific SOPs stay local

**Cross-Site System Templates**
- Corporate validation team creates master system templates
- Site teams deploy validated versions with site-specific configuration
- Central RTM covers global requirements; local IQ/OQ covers site-specific install

**Network Compliance Dashboard**
- Executive-level view across all sites
- Per-site compliance scorecard
- Network-wide open CAPA aging
- Cross-site periodic review status
- Training compliance matrix across all sites

**Harmonized Lookup Tables**
- Corporate-managed lookup values (cannot be edited at site level)
- Site-extensible lookups (site can add values, cannot delete corporate values)

### Database Additions

**document_cross_site_distributions**
- id (uuid, PK)
- source_document_id (uuid, FK documents)
- source_version_id (uuid, FK document_versions)
- target_site_id (uuid, FK sites)
- distribution_type (varchar 50) -- controlled_copy, reference, adaptable
- status (varchar 50) -- active, superseded, withdrawn
- distributed_at (timestamptz)
- distributed_by (uuid, FK users)
- local_adaptation_allowed (boolean, default false)

**organization_settings**
- id (uuid, PK)
- organization_id (uuid, FK organizations)
- setting_key (varchar 255)
- setting_value (text)
- is_site_overridable (boolean, default true)
- updated_at, updated_by

### Target Phase: Phase 18 (Administration) - extend - NEW

---

## Summary: Updated Phase Plan Additions

| New Module / Enhancement | Target Phase | Priority |
|---|---|---|
| GxP API flag in responses | Phase 0 | High |
| Closed-loop automation rules | Phase 8 | High |
| Validation Setup Wizard | Phase 3 | High |
| OOS/OOT Management | Phase 10 | High |
| Complaint Management | Phase 10 | High |
| Inspection Readiness Mode | Phase 14 | High |
| Environmental Monitoring | Phase 15 | Medium |
| Stability Study Management | Phase 15 | Medium |
| Batch and Lot Management | Phase 15 | Medium |
| Multi-site Enterprise | Phase 18 | Medium |
| SPC Module | Phase 21 | Medium |
| Manufacturing Analytics | Phase 21 | Medium |
| AI Assistance - Phase 1 | Phase 22 | Future |
| AI Governance Framework | Phase 22 | Future |
| AI Assistance - Phase 2 | Phase 23 | Future |

---

*MODULE-EXT-001 v1.0 - All extensions to be incorporated into MASTER_PLAN.md at next update.*
