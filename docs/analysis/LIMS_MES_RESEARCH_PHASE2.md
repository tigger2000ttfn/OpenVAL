# PHAROLON LIMS & MES — Phase 2 Research Analysis
**Date:** 2026-04-23  
**Analyst:** Head of Global QA, PHAROLON Project  
**Basis:** Live regulatory research — EU GDP 2013/C 343/01, ICH Q12/Q13, ISO 17025:2017, GCP 21 CFR Part 11 (2024 finalized guidance), ICH E6(R3), IATA TCR, WHO TRS 961 Annex 9

---

## LIMS Part 12 — Coverage Gaps Identified

### Current Coverage (72 tables)
Core sample lifecycle, test methods, OOS/OOT, stability, EM monitoring, instruments, reagents, water systems, microbiology, CoA, integration connectors.

### Missing Coverage — Must Add

#### 1. Method Transfer Validation
Regulatory basis: ICH Q2(R2), USP <1224>, EMA method transfer guidance  
Required when: Lab moves method between sites, labs, or instruments  
Gap: No structured method transfer protocol or acceptance criteria tracking

Required tables:
- `lims_method_transfer_studies` — scope, sending/receiving lab, method ID
- `lims_method_transfer_protocols` — pre-defined acceptance criteria
- `lims_method_transfer_experiments` — run data at both labs
- `lims_method_transfer_comparisons` — statistical equivalence results
- `lims_method_transfer_conclusions` — pass/fail, approval, regulatory filing

#### 2. ISO 17025:2017 Accreditation Management
Regulatory basis: ISO/IEC 17025:2017 — General requirements for competence of testing and calibration laboratories  
Key clauses: 6.5 (Metrological traceability), 7.7 (Ensuring validity of results), 7.4 (Method validation), 6.6 (Externally provided products/services)  
Gap: No accreditation scope tracking, no proficiency testing program management, no measurement uncertainty records

Required tables:
- `lims_accreditation_scopes` — test methods under accreditation scope (UKAS/A2LA/DAkkS/COFRAC)
- `lims_accreditation_assessments` — scheduled/completed assessments, findings, corrective actions
- `lims_accreditation_scope_items` — individual test/matrix combinations in scope
- `lims_proficiency_testing_schemes` — PT provider, analyte, frequency, acceptance criteria
- `lims_proficiency_testing_rounds` — individual PT round participation records
- `lims_proficiency_testing_results` — z-scores, En numbers, reported values vs assigned values
- `lims_measurement_uncertainty_budgets` — uncertainty contributions per test method
- `lims_mu_components` — individual uncertainty sources (repeatability, calibration, reference std, etc.)
- `lims_decision_rules` — how MU is applied to conformity statements per ISO 17025 cl. 7.8.6
- `lims_interlaboratory_comparisons` — bilateral or multilateral comparison programs

#### 3. Lab Notebook / Electronic Lab Notebook (ELN) Integration
Regulatory basis: 21 CFR Part 11, ALCOA+ principles  
Gap: No structured ELN record linkage — experiment records are a blind spot  

Required tables:
- `lims_lab_notebooks` — notebook registry, assigned analyst, project linkage
- `lims_notebook_entries` — individual experiment records with timestamps
- `lims_notebook_entry_attachments` — raw data files, spectra, chromatograms
- `lims_notebook_reviews` — supervisor review and signature records
- `lims_raw_data_files` — immutable raw data store with checksum

#### 4. Extractables & Leachables (E&L) Testing
Regulatory basis: USP <1663>/<1664>, ICH Q3E (in development), EMA E&L guidelines  
Gap: Completely absent — critical for container-closure integrity and drug packaging validation  

Required tables:
- `lims_el_studies` — study scope, product, container type, regulatory framework
- `lims_el_study_conditions` — extraction solvents, temperatures, duration
- `lims_el_compounds` — detected or targeted compounds with CAS, structure
- `lims_el_results` — detected levels, analytical method, reporting thresholds
- `lims_el_toxicological_assessments` — SCT/AET/TTC thresholds, safety evaluation
- `lims_el_study_conclusions` — qualification status, regulatory filing reference

#### 5. Chromatography Data System (CDS) Integration
Regulatory basis: OECD SINALP, USP <1058>, MHRA GXP data integrity guide  
Gap: No structured CDS audit trail linkage — critical data integrity gap  

Required tables:
- `lims_cds_systems` — registered CDS instances (Empower, Chromeleon, OpenLAB)
- `lims_cds_integration_maps` — which test methods pull results from which CDS
- `lims_cds_injections` — individual chromatographic injections with sequence context
- `lims_cds_peak_results` — peak area, RT, purity, assigned compound
- `lims_cds_audit_trail_entries` — CDS-sourced audit events imported for review
- `lims_sequence_files` — injection sequence metadata

#### 6. Dissolution Testing (Specialized)
Regulatory basis: USP <711>, <1092>, FDA dissolution guidance  
Gap: Generic result tables don't capture paddle/basket speed, vessel temperatures, media composition, f2 calculations  

Required tables:
- `lims_dissolution_methods` — apparatus type, RPM, medium, volume, temperature, sampling times
- `lims_dissolution_runs` — batch, product, method, analyst, instrument
- `lims_dissolution_vessels` — per-vessel results at each timepoint
- `lims_dissolution_f2_calculations` — comparator profile, f2 factor, pass/fail

#### 7. Particle Size & Elemental Analysis
Required tables:
- `lims_particle_size_results` — D10/D50/D90, span, instrument, method
- `lims_elemental_impurity_results` — ICP-MS/ICP-OES per element, PDEs, safety thresholds (ICH Q3D)
- `lims_icp_calibration_standards` — elemental standard lots used per run

---

## MES Part 13 — Coverage Gaps Identified

### Current Coverage (70 tables)
Master batch records, batch execution, dispensing, equipment, bioreactor, downstream, CGT, serialisation, PAT, ERP/DCS integration.

### Missing Coverage — Must Add

#### 1. Lyophilisation (Freeze-Drying) Records
Regulatory basis: EU GMP Annex 1 (2022), FDA Process Validation Guidance  
Gap: No lyophilisation cycle records despite being critical for sterile biologics  

Required tables:
- `mes_lyophilisation_recipes` — shelf temp ramp rates, pressure setpoints, primary/secondary drying
- `mes_lyophilisation_cycles` — batch, equipment, recipe version, start/end
- `mes_lyophilisation_cycle_parameters` — time-series shelf temp, condenser temp, chamber pressure
- `mes_lyophilisation_endpoints` — residual moisture results, Karl Fischer linkage
- `mes_lyophilisation_deviations` — cycle excursions, impact assessment

#### 2. Aseptic Fill/Finish Records
Regulatory basis: EU GMP Annex 1 (2022), FDA Aseptic Processing Guidance 2004/2023 update  
Gap: Generic batch record steps don't capture fill weight checks, container integrity, stopper insertion, crimp force  

Required tables:
- `mes_fill_finish_orders` — product, batch, filling line, fill volume target
- `mes_fill_weight_checks` — periodic fill weight data, AQL sampling
- `mes_container_integrity_tests` — vacuum/HV/HVLD results per container sample
- `mes_stopper_crimp_records` — crimp force data, visual inspection results
- `mes_aseptic_technique_observations` — operator behaviour observations during media fill
- `mes_fill_line_speeds` — fill rate records by time interval

#### 3. Process Simulation (Media Fill)
Regulatory basis: EU GMP Annex 1 cl. 9.35, FDA Aseptic Processing Guide  
Frequency: 2× per year per filling line per shift, or after any significant change  
Gap: Media fill records only exist as general batch records — no structured program  

Required tables:
- `mes_media_fill_programs` — filling line, frequency, scope definition
- `mes_media_fill_runs` — run date, operators, line conditions, units filled
- `mes_media_fill_units` — individual unit records, incubation, inspection results
- `mes_media_fill_failures` — contaminated unit investigations
- `mes_media_fill_conclusions` — pass/fail, AQL criteria, regulatory submission ref

#### 4. Automated Visual Inspection (AVI) System Validation
Regulatory basis: EU GMP Annex 1 (2022) cl. 9.44-9.45, USP <790>  
Gap: AVI validation completely absent — significant for parenteral manufacturers  

Required tables:
- `mes_avi_systems` — system registration, manufacturer, inspection parameters
- `mes_avi_validation_studies` — knurled set preparation, defect categories
- `mes_avi_test_sets` — spiked container sets with known defect types and counts
- `mes_avi_detection_rates` — sensitivity/specificity by defect category
- `mes_avi_run_records` — production AVI run with units inspected, rejected
- `mes_avi_reject_samples` — retained rejected units, secondary inspection disposition

#### 5. Hold Time Studies
Regulatory basis: ICH Q1A, FDA guidance, in-process hold time is critical GMP requirement  
Gap: No structured hold time study management  

Required tables:
- `mes_hold_time_studies` — material/intermediate, hold conditions, study type
- `mes_hold_time_timepoints` — sampling schedule
- `mes_hold_time_results` — test results at each timepoint, acceptance criteria
- `mes_hold_time_conclusions` — approved hold time limits referenced in batch record

#### 6. Packaging Line Qualification  
Regulatory basis: EU GMP Annex 15, 21 CFR Part 211.68  
Gap: Packaging equipment IQ/OQ/PQ not systematically tracked beyond generic protocol  

Required tables:
- `mes_packaging_line_specs` — line ID, components, rated speeds, container types
- `mes_labelling_control_records` — label lot, issue/reconciliation at batch level
- `mes_blister_pack_records` — forming temp, sealing temp, leak test, peel strength
- `mes_aggregation_records` — case, pallet level serialisation events

---

## Part 14 — GDP / Good Distribution Practice Schema

### Regulatory Basis
- EU GDP Guidelines 2013/C 343/01 (Chapters 1-9)
- WHO TRS 961 Annex 9 — Time/temperature sensitive products
- USP <1079> — Good storage and distribution practices
- IATA TCR (Temperature Control Regulations) — air freight
- EU FMD (Falsified Medicines Directive) 2011/62/EU
- HPRA, MHRA national GDP guidance

### Key Requirements Mapped to Tables

#### Chapter 3: Premises & Equipment
- Warehouse thermal mapping (3× — empty, summer, winter) per EU GDP 3.2.1
- Temperature logger calibration with ISO 17025-traceable standards
- Quarantine area management with clear segregation records

#### Chapter 5: Operations  
- Distribution lanes (routes) — must be qualified with transport validation
- Qualification of temperature-controlled packaging systems
- Carrier/3PL qualification and ongoing monitoring

#### Chapter 6: Complaints, Returns, Falsified Products
- Return goods handling with risk assessment before reintroduction to stock
- Falsified medicines identification and segregation records
- Recall effectiveness tracking down to patient/pharmacy level

#### Chapter 9: Transportation
- Transport route qualification studies
- MKT (Mean Kinetic Temperature) calculations for excursion assessment
- Shipper qualification — performance testing at ambient, cold (+2-8°C), frozen (-20°C, -80°C)

Required new tables: 48 (see pharolon_schema_part14_gdp.sql)

---

## Part 15 — GCP / Clinical Trial System Schema

### Regulatory Basis
- ICH E6(R3) — GCP (finalized 2023, in effect)
- 21 CFR Part 11 (finalized guidance October 2024 — electronic records in clinical investigations)
- 21 CFR Part 312 — Investigational New Drug requirements
- EU Clinical Trials Regulation (CTR) No 536/2014
- ICH E9 — Statistical principles for clinical trials
- DIA eTMF Reference Model (v3.0+)

### Key Requirements

#### Electronic Trial Master File (eTMF)
ICH E6(R3) section 8 mandates essential document retention.  
DIA TMF Reference Model defines 5 zones, 21 sections, 230+ artifact types.  
FDA final guidance (Oct 2024): eTMF must meet 21 CFR Part 11 fully.

#### Investigational Product Accountability
21 CFR 312.62: investigational product must be accounted for at all times.  
Sponsor and investigator responsibilities differ.  
Chain of custody from manufacture → site → patient → return/destruction.

#### Informed Consent Versioning
ICH E6(R3): All ICF versions must be tracked. Re-consent required when protocol changes affect risk.  
eConsent must capture patient identity verification and comprehension checks.

Required new tables: 52 (see pharolon_schema_part15_gcp.sql)

---

## Summary of New Tables Planned

| Schema Part | Domain | New Tables | Status |
|---|---|---|---|
| Part 12 supplement | LIMS — ISO 17025, E&L, CDS, Method Transfer | +35 | To build |
| Part 13 supplement | MES — Lyophilisation, Media Fill, AVI, Hold Time | +28 | To build |
| Part 14 | GDP / Cold Chain Distribution | 48 | To build |
| Part 15 | GCP / Clinical Trial Systems | 52 | To build |
| Part 16 | ISO 17025 Accreditation (standalone) | 22 | To build |
| Part 17 | PAT / RTRT / Spectral Libraries | 18 | To build |

**Total new tables this phase: ~203**  
**Projected total schema: ~876 tables**

---

## Research Priority Order

1. 🔴 **Part 14 GDP** — High inspection frequency, broad customer base (wholesalers, 3PLs, MAHs)  
2. 🔴 **Part 12 supplement** — ISO 17025 + CDS gaps are real audit findings in QC labs  
3. 🟡 **Part 13 supplement** — Lyophilisation + media fill critical for sterile manufacturers  
4. 🟡 **Part 15 GCP** — Needed for sponsors/CROs; Oct 2024 FDA guidance makes this urgent  
5. 🟢 **Part 16 ISO 17025** — Consolidation of accreditation into dedicated module  
6. 🟢 **Part 17 PAT/RTRT** — Enterprise Edition differentiation  

