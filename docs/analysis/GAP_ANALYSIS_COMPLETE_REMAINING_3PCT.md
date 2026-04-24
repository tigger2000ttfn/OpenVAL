# PHAROLON Complete Gap Analysis — Remaining 3%
**Date:** 2026-04-09
**Research Basis:** Live regulatory research, current FDA/EMA/ICH/PIC/S guidance
**Analyst:** Head of Global QA, PHAROLON Project

---

## Context

After the Astellas SLC SOP analysis brought coverage to ~97%, this document
researches the remaining gaps systematically across six dimensions:
1. FDA QMSR (21 CFR Part 820) — NOW IN EFFECT
2. EU GMP Annex 1 (2022) — Sterile manufacturing
3. ICH Q12/Q13/Q14 — Post-approval change and continuous manufacturing
4. GCP / Clinical trial systems
5. ATMP / Cell & gene therapy
6. GDP / Distribution and cold chain
7. Data integrity — PIC/S PI 041-1
8. Design documentation completeness
9. DCS/SCADA/process control system validation

Each gap is rated:
- 🔴 BLOCKING — must be in V1, affects core customers
- 🟡 HIGH — should be in V1 or early EE, broad customer base
- 🟢 FUTURE — EE module, specialist customers, post-V1

---

## Gap 1: FDA QMSR (21 CFR Part 820) — IN EFFECT FEBRUARY 2, 2026

### What Changed
The Quality System Regulation (QSR) is now the Quality Management System
Regulation (QMSR). It incorporates ISO 13485:2016 by reference. The enforcement
date was February 2, 2026 — this is already law.

### Critical New Requirements vs Old QSR

| Area | Old QSR | New QMSR | PHAROLON Gap |
|---|---|---|---|
| Design Control traceability | Best practice | **Mandatory** — design inputs must trace to outputs | ❌ No design control module |
| Management Review records | Protected from FDA inspection | **NOW INSPECTABLE** | 🟡 No management review module |
| Internal Audit records | Protected from FDA inspection | **NOW INSPECTABLE** | 🟡 Audit records must be more careful |
| Supplier Audit records | Protected from FDA inspection | **NOW INSPECTABLE** | 🟡 Supplier audit docs need better content guidance |
| Risk Management | Word "risk" appeared ONCE | Risk-based approach **throughout QMS** (25+ occurrences in ISO 13485) | 🟡 Risk linkage to all QMS activities |
| Device Master Record (DMR) | Required | **DMR concept replaced** by MDF (Manufacturing Documentation File) | 🟡 New document type |
| Design History File (DHF) | Required | Maintained but design traceability now mandatory | ❌ No DHF structure |
| ISO 14971 alignment | Not referenced | ISO 13485 incorporates ISO 14971 principles | ❌ No formal ISO 14971 risk management workflow |

### PHAROLON Impact — What Must Be Added

**🔴 Design Control Module (New EE Module)**
Any PHAROLON customer making a medical device or combination product now needs:
- Design History File (DHF) structure — a folder that holds ALL design records
- Design Input capture (functional requirements, performance specs, safety requirements)
- Design Output linkage (drawings, DMF/MDF, specifications)
- Mandatory Design Input → Output traceability matrix (separate from URS RTM)
- Design Verification records (proves outputs meet inputs)
- Design Validation records (proves device meets user needs)
- Design Transfer documentation (from development to manufacturing)
- Design Change control with DHF linkage
- ISO 14971 Risk Management file integration

**🟡 Management Review Module**
Now that FDA can inspect management review records, these need to be:
- Formally documented with specific agenda items (per ISO 13485 clause 5.6)
- Traceable actions with owners and due dates
- Linked to quality KPIs, CAPA status, audit results, regulatory updates
- Signed off electronically

**New Tables Required:**
- `design_history_files` (per product/device)
- `design_inputs` (requirements from user and regulatory perspective)
- `design_outputs` (specifications, drawings, procedures that result from design)
- `design_verification_records` (test results proving outputs meet inputs)
- `design_validation_records` (clinical/usability evidence)
- `design_changes` (linked to DHF)
- `management_review_meetings` (agenda, attendees, decisions, actions)
- `management_review_inputs` (quality data going into the review)

**New Templates:**
- TMPL-DHF-INDEX (Design History File index document)
- TMPL-DESIGN-INPUT (Design Input record)
- TMPL-DESIGN-VERIFICATION (Verification protocol)
- TMPL-DESIGN-VALIDATION (Validation protocol — clinical/usability)
- TMPL-MGMT-REVIEW (Management Review meeting record)

**Severity: 🔴 BLOCKING for any med device or combination product customer**

---

## Gap 2: EU GMP Annex 1 (2022) — Enforced August 25, 2023

### Three Entirely New Document Types

#### 2.1 Contamination Control Strategy (CCS) 🔴
The CCS is now a mandatory, living document for any sterile manufacturer.
It is NOT a protocol — it is a strategic document that:
- Defines the overall approach to contamination control for the entire facility
- Covers: facility design, HVAC, equipment, utilities, personnel, procedures, monitoring
- Must be formally reviewed and updated when anything changes that could affect it
- Is referenced by inspectors as evidence of quality culture

This is a new **system-level document type** similar to the SMM — it persists
for the lifetime of the facility and is updated via change control.

**Tables needed:**
- `contamination_control_strategies` (facility-level, not per-system)
- `ccs_elements` (individual control measures documented within the CCS)
- `ccs_reviews` (periodic review records with outcomes)

**Template needed:** TMPL-CCS

#### 2.2 Aseptic Process Simulation (APS) Protocol 🟡
Previously called "media fill." Now:
- Zero contamination tolerance — any contaminated unit = failed APS
- After failure: full investigation + 3 consecutive successful APS runs required
- Specific personnel monitoring requirements during the APS
- Frequency requirements based on product, process, and risk

This is a **new protocol type** — distinct from standard IQ/OQ/PQ.
The existing sterilization_validations table is insufficient.

**Tables needed:**
- `aps_protocols` (aseptic process simulation design)
- `aps_executions` (individual run records)
- `aps_organisms` (which organisms grew, if any)
- `aps_failure_investigations` (when contamination occurs)

**Template needed:** TMPL-APS

#### 2.3 PUPSIT Validation Record 🟡
Pre-Use Post-Sterilization Integrity Testing for sterilizing-grade filters.
Now a default regulatory requirement (with exceptions requiring strong justification).

- Test must be performed after sterilization, before use
- Results must be documented with pass/fail criteria
- If PUPSIT cannot be performed, written risk-based justification is required
- Justification must be reviewed periodically

**Tables needed:**
- `pupsit_records` (per filter lot per batch)
- `pupsit_justifications` (documented exceptions with risk assessment)

**Template needed:** TMPL-PUPSIT

---

## Gap 3: ICH Q12 — Post-Approval Change Management

### What ICH Q12 Introduces
ICH Q12 (finalized 2019, still being implemented globally as of 2025) introduces
three concepts that PHAROLON's change control module doesn't capture:

**3.1 Established Conditions (ECs) 🟡**
Regulatory commitments embedded in the marketing authorization dossier.
An EC is a specific manufacturing parameter or characteristic that is:
- Formally registered with the regulatory agency
- Only changeable through a formal variation procedure
- Tracked throughout the product lifecycle

PHAROLON has no concept of "this change requires a regulatory submission" vs
"this is just an internal change."

**3.2 Post-Approval Change Management Protocol (PACMP) 🟢**
A pre-agreed plan with the regulator for future changes. Company says:
"When we change [X], we will do [studies Y and Z], and the agency agrees
in advance to accept that evidence."

This accelerates post-approval changes from 3-5 years down to months.

**3.3 Product Lifecycle Management Document (PLCM) 🟢**
A comprehensive document for each product that maps all ECs and describes
the change management philosophy for that product across its entire lifecycle.

**New Tables Required:**
- `established_conditions` (per product, linked to regulatory submissions)
- `pac_management_protocols` (PACMP — pre-agreed change plans)
- `product_lifecycle_management_docs` (PLCM per product)

**Template needed:** TMPL-PACMP, TMPL-PLCM

---

## Gap 4: ICH Q13 — Continuous Manufacturing

### What This Means for PHAROLON
Continuous manufacturing (CM) is fundamentally different from batch manufacturing.
The process validation approach, the batch definition, and the CPV approach all change:

**4.1 Batch Definition Problem 🟡**
In CM, a "batch" can be defined by time, quantity, or process parameters — not
by a single discrete production run. PHAROLON's current batch/lot model assumes
discrete batches. CM requires flexible batch definition with justification.

**4.2 Residence Time Distribution (RTD) 🟡**
A CM-specific concept — the statistical distribution of time that material
spends in the continuous process. RTD models are used to:
- Define batch boundaries
- Identify diversion points (material that must be diverted due to disturbances)
- Support real-time release testing

**4.3 Real-Time Release Testing (RTRT) 🟢**
Instead of traditional final product testing, CM uses in-process data and
process analytical technology (PAT) to release product in real time.
This requires a completely different validation approach.

**4.4 Disturbance Management 🟡**
When a process disturbance occurs in CM, material must be diverted.
The disturbance management system must be validated, and the diversion
events must be documented.

**New Tables Required:**
- `cm_batch_definitions` (flexible batch definition records per product)
- `rtd_models` (residence time distribution validation)
- `cm_disturbance_events` (diversion records)
- `rtrt_models` (real-time release testing method validation)

**Template needed:** TMPL-CM-PROCESS-VALIDATION

---

## Gap 5: GCP — Clinical Trial System Validation

### Regulatory Basis
21 CFR Part 312 (IND), 21 CFR Part 11, ICH E6(R3) GCP guidelines.
FDA's October 2024 guidance clarified Part 11 enforcement for clinical systems.
ICH E6(R3) finalization significantly updated electronic systems expectations.

### What Clinical Trial Systems Need That PHAROLON Doesn't Have

**5.1 GCP-Specific System Categories 🟡**
Clinical trial systems have different validation requirements from GMP systems:
- Electronic Data Capture (EDC) — subject data entry, validation rules
- Clinical Trial Management System (CTMS) — site management, monitoring
- Interactive Response Technology (IRT/IVRS/IXRS) — randomization, drug supply
- eTMF (Electronic Trial Master File) — regulatory document management
- CDMS (Clinical Data Management System) — data cleaning, coding

Each has specific validation expectations under ICH E6(R3).

**5.2 Investigator Site Qualification 🟡**
Before a site can use a clinical system, the site must be qualified:
- System training completion (with test)
- User access provisioning
- Site-specific configuration testing
- Ongoing monitoring visit records

**5.3 Decentralized Clinical Trial (DCT) Elements 🟢**
FDA finalized DCT guidance in 2024. New validation requirements for:
- Remote patient monitoring devices
- Telemedicine platform validation
- Digital endpoint capture

**New Tables Required:**
- `clinical_system_categories` (GCP-specific system type taxonomy)
- `investigator_site_qualifications` (site-level system qualification)
- `edm_user_access_logs` (clinical trial user access per study)

**Template needed:** TMPL-GCP-VALIDATION-PLAN

---

## Gap 6: ATMP / Cell & Gene Therapy

### Why This Is Fundamentally Different
ATMPs (Advanced Therapy Medicinal Products) — including CAR-T, gene therapy,
and tissue-engineered products — require validation capabilities that do not
exist anywhere in PHAROLON and are unlike any other pharmaceutical product.

**6.1 Chain of Identity (COI) 🟡**
The most critical unique requirement for autologous therapies.
Every patient's cells must be tracked with a unique identifier from:
- Apheresis/collection at the hospital
- Transport to the manufacturing facility
- All manufacturing steps
- QC testing
- Cryopreservation and storage
- Transport back to the hospital
- Administration to the patient

A mix-up at ANY point is a patient safety catastrophe.
COI is permanent, bidirectional, and every handoff must be documented.

**6.2 Chain of Custody (COC) 🟡**
Documents who has physical custody of the patient-specific material at every
step. COC + COI together create the full traceability record.

**6.3 Donor Eligibility Testing Integration 🟢**
Each donor/patient must have eligibility testing performed and documented
before their material can be used in manufacturing.

**6.4 Patient-Specific Manufacturing Records 🟡**
Each manufacturing batch is for ONE patient. The standard eBR model (one
batch record per batch of product) maps to one patient record, but the data
relationships are different — the patient identity is the primary key,
not the batch number.

**New Tables Required:**
- `atmp_chain_of_identity` (unique COI per patient, per therapy)
- `atmp_custody_transfers` (every handoff with timestamp and signature)
- `atmp_donor_eligibility_records` (eligibility testing results)
- `atmp_patient_specific_batches` (one-to-one batch-to-patient mapping)

**This is a major EE module. Significant competitive opportunity — no open source ATMP validation platform exists.**

---

## Gap 7: DCS/SCADA/Process Control System Validation

### What Makes This Different from CSV
DCS (Distributed Control System), SCADA (Supervisory Control and Data Acquisition),
and process historians (OSIsoft PI, Honeywell PHD) present unique validation
challenges that standard CSV approaches don't fully address:

**7.1 Instrument Calibration Integration 🟡**
DCS validation requires:
- Loop calibration records (every instrument in the loop, not just standalone equipment)
- Instrument loop diagrams (P&IDs) as validation evidence
- Loop testing (the full signal path from sensor to HMI display)
- Alarm setpoint verification (every alarm must be tested)

**7.2 Process Historian Validation 🟡**
OSIsoft PI and similar systems are validated as data acquisition systems.
Their validation must demonstrate:
- Data fidelity (value stored matches value measured)
- Time synchronization accuracy
- No data gaps under normal conditions
- Compression algorithm validation (that lossy compression doesn't affect batch release data)

**7.3 DCS Recipe Validation 🟡**
Manufacturing recipes embedded in the DCS must be validated as configuration.
This is GAMP 5 Category 4 — configured system with significant impact.

**7.4 Alarm Management Validation 🟢**
EEMUA Publication 191 / IEC 62682 alarm management — the validated alarm
rationalization process. Every alarm that could affect product quality must
have documented rationalization.

**New Tables Required:**
- `instrument_loops` (P&ID instrument loop definitions)
- `loop_calibrations` (loop calibration records)
- `process_historian_configurations` (validated historian settings)
- `dcs_recipes` (validated manufacturing recipes)
- `alarm_rationalizations` (alarm management records)

---

## Gap 8: GDP — Good Distribution Practice

### What PHAROLON Has vs. What's Needed

PHAROLON has cold chain / temperature mapping (Part 7 schema). What's missing:

**8.1 Qualified Distribution Lane Records 🟡**
GDP requires that transport routes be qualified:
- Lane qualification protocol and report
- Worst-case season testing (hot summer, cold winter)
- Qualified packaging selection and documentation
- Re-qualification triggers

**8.2 Transport Excursion Management 🟡**
Every temperature excursion during transport must be:
- Detected (via logger data or carrier report)
- Investigated (product impact assessment)
- Dispositioned (reject/release/quarantine)
- Traced back to the specific shipment and recipient

**8.3 Responsible Person (RP) Records 🟡**
EU GDP requires a nominated Responsible Person:
- RP qualification record
- RP designation and scope document
- RP activities log

**8.4 Counterfeiting Controls 🟢**
EU FMD (Falsified Medicines Directive) compliance:
- Serialization verification at receiving
- EMVS (European Medicines Verification System) query log

**New Tables Required:**
- `distribution_lane_qualifications` (route qualification records)
- `transport_excursion_investigations` (excursion event management)
- `responsible_person_records` (RP designation and activities)

---

## Gap 9: PIC/S PI 041-1 — Data Integrity

### What PI 041-1 Requires That PHAROLON Doesn't Explicitly Document

PIC/S PI 041-1 is written "by inspectors, for inspectors." It raises expectations
above and beyond what 21 CFR Part 11 requires:

**9.1 Data Governance Framework 🟡**
PI 041-1 explicitly requires a documented data governance framework covering:
- Organizational values and quality culture commitments to data integrity
- Roles and responsibilities for data governance
- Procedures for data review and verification
- Self-inspection program specifically for data integrity

PHAROLON has the audit trail engine but no "data governance document" type.

**9.2 Hybrid Systems Management 🟡**
When paper and electronic records coexist for the same data (hybrid systems),
PI 041-1 requires specific controls:
- Which record is the authoritative original
- Procedure for ensuring the paper and electronic records match
- Controls preventing transcription errors
- Periodic review of hybrid system controls

**9.3 Software Update Validation 🟡**
PI 041-1 section specifically addresses security patches and application upgrades:
- Security patches should be applied in a timely manner
- Old data must still be readable after software updates
- If data format changes, migration validation is required

PHAROLON's vendor release assessment covers this partially but not explicitly
with the data migration/readability angle.

**9.4 Retrospective Data Review 🟡**
PI 041-1 expects periodic retrospective review of electronic audit trails
to detect anomalies — not just preserving the trail but actively reviewing it.

This maps to PHAROLON's planned periodic review module but must explicitly
include audit trail anomaly detection as a review item.

**New Tables Required:**
- `data_governance_frameworks` (site-level data governance document)
- `hybrid_system_controls` (per system, if hybrid)
- `audit_trail_review_records` (periodic retrospective review)
- `data_integrity_self_inspections` (DI-specific internal audit records)

---

## Gap 10: Design Documentation Completeness

### Missing from UI-SPEC-001 (Developer-Blocking Gaps)

These are not optional — a developer cannot build certain screens without them:

| Missing Spec | Blocking | Notes |
|---|---|---|
| Mobile / tablet execution mode | 🔴 | How a validation engineer runs a protocol on an iPad in the lab. Different layout, different interaction model. Fundamentally architectural. |
| Full-screen protocol execution mode | 🔴 | Distraction-free mode for active test execution. No sidebar, no nav. Just the current step, pass/fail, deviation flag. |
| Print / PDF output layout | 🔴 | Every protocol, CAPA, deviation must be printable with GxP-required headers (doc ref, version, page N of N, classification). This is a regulatory requirement. |
| Empty states | 🟡 | Every major list view needs a designed empty state. "No protocols yet — create your first one →" This is first-run UX. |
| Loading / skeleton screen patterns | 🟡 | What does the app look like while data is loading? Need defined skeleton shapes for tables, cards, charts. |
| Email notification templates | 🟡 | Workflow emails, signature requests, overdue alerts, system announcements. Need HTML email designs. |
| Onboarding wizard screens | 🟡 | First-run experience for new sites — guided setup wizard, team invitation, first system creation. |
| Error pages | 🟡 | 404, 403, session timeout, maintenance mode, network error. All need designed states. |
| Accessibility spec | 🟡 | WCAG 2.1 AA target. Keyboard navigation map. Screen reader labels. Color contrast ratios (already good but not documented). |
| Icon mapping guide | 🟡 | Which Lucide React icon maps to which action/concept across the platform. Without this, developers use inconsistent icons. |
| React component API spec | 🔴 | The moodboards show what things look like. Developers need props, variants, states. Button: variant="primary|ghost|danger", size="sm|md|lg", loading, disabled. |
| Dark/light theme token reference | 🟡 | Every CSS variable mapped to its dark and light value. Currently documented in prose but not as a reference table. |

---

## Priority Summary and Recommended Action Plan

### Must resolve before Phase 0 code starts (schema decisions)

1. **Design Control / QMSR module** — affects schema for DHF, design inputs/outputs
2. **Contamination Control Strategy** — new document type, facility-level
3. **APS and PUPSIT** — new protocol/test types, sterilization module expansion
4. **Management Review module** — ISO 13485 requirement, now FDA-inspectable
5. **Mobile/print design spec** — architectural, not cosmetic

### Should resolve before Phase 2 App Shell starts (design blocking)

6. React component API specification
7. Full-screen execution mode design
8. PDF/print layout specification
9. Empty states and loading patterns
10. Icon mapping guide

### EE modules to spec before Phase 15-20 (EE development)

11. ATMP Chain of Identity/Custody module
12. DCS/SCADA validation module
13. GCP clinical trial system module
14. ICH Q12/Q13 post-approval and CM modules
15. GDP distribution lane qualification module

### Future research items (post-V1)

- ICH Q14 (analytical procedure development, ATP concept)
- FDA GMLP / AI in manufacturing validation
- Combination products (21 CFR Part 4 dual jurisdiction)
- MDSAP (Medical Device Single Audit Program)
- PIC/S PI 041-1 data governance framework doc type

---

## New Template Library Additions (Total now 67 templates)

| Code | Template Name | Gap Area |
|---|---|---|
| TMPL-DHF-INDEX | Design History File Index | QMSR / ISO 13485 |
| TMPL-DESIGN-INPUT | Design Input Specification | QMSR Design Control |
| TMPL-DESIGN-VERIFICATION | Design Verification Protocol | QMSR Design Control |
| TMPL-DESIGN-VALIDATION | Design Validation Protocol | QMSR Design Control |
| TMPL-MGMT-REVIEW | Management Review Record | ISO 13485 §5.6 |
| TMPL-CCS | Contamination Control Strategy | EU GMP Annex 1 (2022) |
| TMPL-APS | Aseptic Process Simulation Protocol | EU GMP Annex 1 §9 |
| TMPL-PUPSIT | PUPSIT Validation Record | EU GMP Annex 1 §8 |
| TMPL-PACMP | Post-Approval Change Management Protocol | ICH Q12 |
| TMPL-CM-PV | Continuous Manufacturing Process Validation | ICH Q13 |
| TMPL-GCP-VAL | GCP System Validation Plan | ICH E6(R3), 21 CFR Part 11 |
| TMPL-COI | Chain of Identity Master Record | ATMP / EMA ATMP Regulation |
| TMPL-LANE-QUAL | Distribution Lane Qualification | EU GDP, WHO TRS 961 |
| TMPL-DI-GOVERNANCE | Data Integrity Governance Framework | PIC/S PI 041-1 |
| TMPL-DI-AUDIT-REVIEW | Audit Trail Retrospective Review | PIC/S PI 041-1 §9 |
| TMPL-HYBRID-CONTROL | Hybrid System Control Procedure | PIC/S PI 041-1 §6 |
| TMPL-LOOP-CAL | Instrument Loop Calibration Record | GAMP 5, 21 CFR 211.68 |
| TMPL-ALARM-RATIONALE | Alarm Rationalization Record | EEMUA 191, IEC 62682 |

**Previous template count: 58**
**New additions: 18**
**Total: 67 templates**

---

*Gap Analysis complete. Research basis: FDA QMSR FAQ (Feb 2026), EU GMP Annex 1
(Aug 2022 revision), ICH Q12/Q13/Q14, PIC/S PI 041-1 (2021), ICH E6(R3),
GMLP Guiding Principles (IMDRF Jan 2025), EMA ATMP Regulation.*
