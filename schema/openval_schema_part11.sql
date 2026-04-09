-- ============================================================
-- OpenVAL Schema - Part 11: All Unaddressed Gaps
-- Version: 1.0.0
-- Run after Parts 1-10
--
-- Sources:
--   - FDA QMSR (21 CFR Part 820) effective Feb 2, 2026
--   - EU GMP Annex 1 (2022 revision, enforced Aug 2023)
--   - ICH Q12 Post-Approval Change Management
--   - ICH Q13 Continuous Manufacturing
--   - ICH E6(R3) GCP / Clinical Trial Systems
--   - ATMP / Cell & Gene Therapy (EMA regulation)
--   - DCS/SCADA/Process Control (GAMP 5 Cat 4/5)
--   - EU GDP (Good Distribution Practice)
--   - PIC/S PI 041-1 Data Integrity Guidance
--   - OpenVAL SOP Visualizer (competitive differentiator)
--   - OpenVAL Validation Package Visualizer (competitive)
--
-- Sections:
--   1.  QMSR Design Control (DHF, design inputs/outputs)
--   2.  ISO 13485 Management Review Module
--   3.  EU GMP Annex 1 — CCS, APS, PUPSIT
--   4.  ICH Q12 — Post-Approval Change Management
--   5.  ICH Q13 — Continuous Manufacturing
--   6.  GCP — Clinical Trial System Validation
--   7.  ATMP — Chain of Identity / Chain of Custody
--   8.  DCS / SCADA / Process Control Validation
--   9.  GDP — Distribution Lane Qualification
--  10.  PIC/S PI 041-1 Data Integrity Governance
--  11.  SOP Visualizer Engine
--  12.  Validation Package Visualizer
-- ============================================================

-- ============================================================
-- 1. QMSR DESIGN CONTROL MODULE
-- Required for medical devices and combination products.
-- 21 CFR Part 820 QMSR (effective Feb 2, 2026) now mandates
-- documented traceability between design inputs and outputs.
-- ISO 14971 risk management integrated throughout.
-- ============================================================

CREATE TABLE design_history_files (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dhf_ref VARCHAR(50) UNIQUE NOT NULL,         -- DHF-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    device_class VARCHAR(20),                    -- class_i | class_ii | class_iii | ivd
    product_type VARCHAR(100) NOT NULL,          -- medical_device | ivd | combination_product | software_samd
    intended_use TEXT NOT NULL,
    indications_for_use TEXT,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'active',-- active | completed | archived | superseded
    design_phase VARCHAR(50) NOT NULL DEFAULT 'development',
    responsible_id UUID REFERENCES users(id),
    -- Document index (computed from linked records)
    total_design_inputs INT NOT NULL DEFAULT 0,
    total_design_outputs INT NOT NULL DEFAULT 0,
    total_verifications INT NOT NULL DEFAULT 0,
    total_validations INT NOT NULL DEFAULT 0,
    total_design_changes INT NOT NULL DEFAULT 0,
    -- Regulatory
    regulatory_submission_id UUID REFERENCES regulatory_submissions(id),
    mdsap_enrolled BOOLEAN NOT NULL DEFAULT FALSE,
    iso14971_risk_file_id UUID,                  -- FK to risk_assessments
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE design_inputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    input_ref VARCHAR(50) UNIQUE NOT NULL,       -- DI-0001
    dhf_id UUID NOT NULL REFERENCES design_history_files(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    input_type VARCHAR(100) NOT NULL,
    -- user_need | functional | performance | safety | regulatory | interface
    -- usability | biocompatibility | sterility | packaging | labeling | environmental
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    source VARCHAR(255),                         -- Where this requirement came from
    acceptance_criteria TEXT NOT NULL,           -- How verification will be assessed
    priority VARCHAR(20) NOT NULL DEFAULT 'shall', -- shall | should | may
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    iso14971_risk_item_id UUID,                  -- Link to ISO 14971 risk management
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE design_outputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    output_ref VARCHAR(50) UNIQUE NOT NULL,      -- DO-0001
    dhf_id UUID NOT NULL REFERENCES design_history_files(id),
    output_type VARCHAR(100) NOT NULL,
    -- drawing | specification | procedure | software | labeling | packaging
    -- manufacturing_spec | testing_spec | acceptance_criteria | component_spec
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    document_ref VARCHAR(255),                   -- Reference to the actual document
    document_id UUID REFERENCES documents(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    -- Traceability — the critical QMSR requirement
    input_ids TEXT,                              -- JSON: [design_input_id, ...] — what inputs does this satisfy?
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE design_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    verification_ref VARCHAR(50) UNIQUE NOT NULL, -- DV-0001
    dhf_id UUID NOT NULL REFERENCES design_history_files(id),
    title VARCHAR(512) NOT NULL,
    objective TEXT NOT NULL,
    -- Traceability
    input_ids TEXT NOT NULL,                     -- JSON: which design inputs are verified
    output_ids TEXT NOT NULL,                    -- JSON: which design outputs are tested
    verification_method VARCHAR(100) NOT NULL,   -- inspection | test | analysis | demonstration
    acceptance_criteria TEXT NOT NULL,
    -- Results
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    pass_fail VARCHAR(10),
    results_summary TEXT,
    performed_by UUID REFERENCES users(id),
    performed_date DATE,
    reviewed_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE design_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    validation_ref VARCHAR(50) UNIQUE NOT NULL,  -- DVL-0001
    dhf_id UUID NOT NULL REFERENCES design_history_files(id),
    title VARCHAR(512) NOT NULL,
    validation_type VARCHAR(100) NOT NULL,
    -- clinical_evaluation | usability | performance | simulated_use | animal
    objective TEXT NOT NULL,
    user_population TEXT,                        -- Who was the device validated on/with?
    use_environment TEXT,                        -- Where
    -- Traceability
    user_need_ids TEXT NOT NULL,                 -- JSON: which user needs are validated
    -- Results
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    pass_fail VARCHAR(10),
    results_summary TEXT,
    residual_risk_acceptable BOOLEAN,
    performed_by UUID REFERENCES users(id),
    performed_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE design_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    change_ref VARCHAR(50) UNIQUE NOT NULL,      -- DC-0001
    dhf_id UUID NOT NULL REFERENCES design_history_files(id),
    change_request_id UUID REFERENCES change_requests(id),
    description TEXT NOT NULL,
    reason TEXT NOT NULL,
    affected_inputs TEXT,                        -- JSON: [design_input_id, ...]
    affected_outputs TEXT,                       -- JSON: [design_output_id, ...]
    re_verification_required BOOLEAN NOT NULL DEFAULT FALSE,
    re_validation_required BOOLEAN NOT NULL DEFAULT FALSE,
    significant_change BOOLEAN NOT NULL DEFAULT FALSE,
    -- Significant changes to cleared/approved devices may require new submission
    regulatory_submission_required BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 2. ISO 13485 MANAGEMENT REVIEW MODULE
-- Now FDA-inspectable under QMSR (as of Feb 2, 2026).
-- Must be factual, documented, and fully auditable.
-- Covers: quality KPIs, CAPA status, audit results, complaints,
-- regulatory changes, resource needs, improvement opportunities.
-- ============================================================

CREATE TABLE management_review_meetings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_ref VARCHAR(50) UNIQUE NOT NULL,      -- MR-2026-001
    site_id UUID NOT NULL REFERENCES sites(id),
    review_type VARCHAR(50) NOT NULL DEFAULT 'annual',
    -- annual | semi_annual | quarterly | triggered | extraordinary
    meeting_date DATE NOT NULL,
    location TEXT,
    chair_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    -- Review outputs / decisions
    conclusions TEXT,
    actions_summary TEXT,
    quality_system_effectiveness_rating VARCHAR(50),
    -- adequate | adequate_with_improvements | inadequate
    resource_decisions TEXT,
    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE management_review_attendees (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES management_review_meetings(id),
    user_id UUID NOT NULL REFERENCES users(id),
    role_in_review VARCHAR(100),                 -- chair | presenter | attendee | minutes_taker
    attended BOOLEAN NOT NULL DEFAULT TRUE,
    UNIQUE (review_id, user_id)
);

CREATE TABLE management_review_inputs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES management_review_meetings(id),
    input_category VARCHAR(100) NOT NULL,
    -- audit_results | customer_feedback | process_performance | product_conformity
    -- preventive_corrective_actions | previous_review_followup | changes_affecting_qms
    -- recommendations_for_improvement | regulatory_changes | supplier_performance
    -- complaints | resource_adequacy | training_effectiveness
    title VARCHAR(512) NOT NULL,
    summary TEXT NOT NULL,
    data_period_from DATE,
    data_period_to DATE,
    trend_direction VARCHAR(20),                 -- improving | stable | worsening | insufficient_data
    kpi_value DECIMAL(15,4),
    kpi_unit VARCHAR(50),
    kpi_target DECIMAL(15,4),
    meets_target BOOLEAN,
    linked_object_type VARCHAR(100),             -- capa | audit | complaint | etc.
    linked_object_ids TEXT,                      -- JSON: related record IDs
    prepared_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE management_review_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_id UUID NOT NULL REFERENCES management_review_meetings(id),
    action_description TEXT NOT NULL,
    action_type VARCHAR(100) NOT NULL,           -- improvement | resource | process_change | training
    owner_id UUID REFERENCES users(id),
    due_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    linked_capa_id UUID REFERENCES capas(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. EU GMP ANNEX 1 (2022) — STERILE MANUFACTURING
-- Three new mandatory document types.
-- ============================================================

-- 3A: CONTAMINATION CONTROL STRATEGY (CCS)
-- Facility-level living document. Not per-system — per-facility.
CREATE TABLE contamination_control_strategies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ccs_ref VARCHAR(50) UNIQUE NOT NULL,         -- CCS-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    facility_name VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    scope_description TEXT NOT NULL,             -- Which manufacturing areas, product types
    -- CCS Elements (documented within the strategy)
    facility_design_controls TEXT,               -- Cleanroom classification, airlocks, pressure differentials
    hvac_controls TEXT,                          -- Filtration, air changes, temperature/humidity limits
    equipment_controls TEXT,                     -- Sterility assurance, maintenance
    utility_controls TEXT,                       -- WFI, clean steam, compressed gases
    personnel_controls TEXT,                     -- Gowning, behavior, training requirements
    environmental_monitoring_strategy TEXT,      -- EM frequency, locations, limits
    cleaning_disinfection_strategy TEXT,         -- Agents, frequencies, rotation
    process_controls TEXT,                       -- In-process controls, hold times, bioburden limits
    contamination_recovery_procedure TEXT,       -- What happens when limits are exceeded
    -- Review
    last_review_date DATE,
    next_review_date DATE,
    review_trigger_conditions TEXT,              -- What changes would require immediate CCS update
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE ccs_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ccs_id UUID NOT NULL REFERENCES contamination_control_strategies(id),
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    review_type VARCHAR(50) NOT NULL DEFAULT 'periodic', -- periodic | triggered | post_incident
    trigger_reason TEXT,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    outcome VARCHAR(50) NOT NULL,                -- no_change_required | updated | major_revision
    changes_made TEXT,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3B: ASEPTIC PROCESS SIMULATION (APS) / Media Fill
CREATE TABLE aps_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aps_ref VARCHAR(50) UNIQUE NOT NULL,         -- APS-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    facility_id UUID REFERENCES contamination_control_strategies(id),
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- Scope
    product_type VARCHAR(255) NOT NULL,          -- What the APS simulates
    process_type VARCHAR(100) NOT NULL,          -- aseptic_fill | lyophilization | assembly | reconstitution
    fill_volume_ml DECIMAL(10,4),
    minimum_units_required INT NOT NULL,         -- Regulatory minimum (typically 5000-10000)
    -- Success criteria (zero tolerance under Annex 1 2022)
    success_criteria TEXT NOT NULL DEFAULT 'Zero contaminated units. Any contamination = FAIL.',
    -- Frequency
    run_frequency VARCHAR(50) NOT NULL DEFAULT 'semi_annual',
    -- After failure: 3 consecutive passes required
    consecutive_passes_required INT NOT NULL DEFAULT 3,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE aps_executions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    execution_ref VARCHAR(50) UNIQUE NOT NULL,   -- APSE-0001
    protocol_id UUID NOT NULL REFERENCES aps_protocols(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    run_date DATE NOT NULL,
    run_number INT NOT NULL,                     -- 1, 2, 3 (for consecutive runs after failure)
    total_units_filled INT NOT NULL,
    -- Personnel during run (personnel monitoring data)
    operator_count INT,
    worst_case_interventions TEXT,               -- JSON: list of interventions performed
    environmental_conditions TEXT,               -- JSON: temp, RH, particle counts during run
    -- Results
    incubation_period_days INT NOT NULL DEFAULT 14,
    incubation_temp_c DECIMAL(5,2),
    units_examined INT NOT NULL,
    contaminated_units INT NOT NULL DEFAULT 0,
    pass_fail VARCHAR(10) NOT NULL,              -- PASS | FAIL
    contamination_details TEXT,                  -- If fail: what grew, where, investigation
    -- After failure tracking
    is_remediation_run BOOLEAN NOT NULL DEFAULT FALSE,
    failure_investigation_id UUID REFERENCES capas(id),
    reviewed_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3C: PUPSIT — Pre-Use Post-Sterilization Integrity Testing
CREATE TABLE pupsit_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pupsit_ref VARCHAR(50) UNIQUE NOT NULL,      -- PUPSIT-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    batch_id UUID REFERENCES batches(id),
    filter_id UUID REFERENCES equipment(id),
    filter_lot_number VARCHAR(100) NOT NULL,
    filter_manufacturer VARCHAR(255) NOT NULL,
    filter_pore_size VARCHAR(50) NOT NULL,       -- 0.22 micron, 0.45 micron, etc.
    -- Test
    test_method VARCHAR(100) NOT NULL,           -- bubble_point | diffusion | water_intrusion
    test_date TIMESTAMPTZ NOT NULL,
    tested_by UUID REFERENCES users(id),
    -- Acceptance criteria
    acceptance_value DECIMAL(10,4) NOT NULL,
    measured_value DECIMAL(10,4) NOT NULL,
    pass_fail VARCHAR(10) NOT NULL,
    -- If fail: batch must not be released
    failed_batch_disposition VARCHAR(100),       -- reject | quarantine | investigation
    deviation_id UUID REFERENCES deviations(id),
    -- Exception tracking (if PUPSIT cannot be performed)
    pupsit_performed BOOLEAN NOT NULL DEFAULT TRUE,
    exception_justification TEXT,               -- Required if pupsit_performed = false
    exception_risk_assessment_id UUID,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- PUPSIT exceptions — when PUPSIT cannot be performed, must be justified
CREATE TABLE pupsit_justifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    filter_type VARCHAR(255) NOT NULL,
    product_type VARCHAR(255) NOT NULL,
    technical_limitation TEXT NOT NULL,          -- Why PUPSIT cannot be done
    risk_assessment_summary TEXT NOT NULL,
    alternative_controls TEXT NOT NULL,          -- What compensating controls are in place
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    next_review_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 4. ICH Q12 — POST-APPROVAL CHANGE MANAGEMENT
-- ============================================================

CREATE TABLE established_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ec_ref VARCHAR(50) UNIQUE NOT NULL,          -- EC-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100) NOT NULL,
    regulatory_submission_id UUID REFERENCES regulatory_submissions(id),
    ec_type VARCHAR(100) NOT NULL,
    -- manufacturing_process | equipment | facility | control_method | specification | formula
    description TEXT NOT NULL,
    ctd_section VARCHAR(50),                     -- CTD section where this EC appears, e.g. "3.2.S.2.2"
    current_value TEXT NOT NULL,                 -- The approved value / parameter
    change_category VARCHAR(50) NOT NULL DEFAULT 'major',
    -- minor | moderate | major — determines reporting requirements
    change_reporting_timeframe TEXT,             -- e.g. "Prior approval needed" or "Annual report"
    last_change_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE pac_management_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pacmp_ref VARCHAR(50) UNIQUE NOT NULL,       -- PACMP-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- What change is pre-approved
    planned_change_description TEXT NOT NULL,
    change_type VARCHAR(100) NOT NULL,           -- site_change | process_change | specification_change
    -- Pre-agreed studies
    required_studies TEXT NOT NULL,              -- JSON: [{study_name, acceptance_criteria}]
    regulatory_agency_id UUID REFERENCES regulatory_agencies(id),
    agency_agreement_date DATE,
    -- Execution tracking
    studies_completed BOOLEAN NOT NULL DEFAULT FALSE,
    implementation_date DATE,
    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE product_lifecycle_management_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plcm_ref VARCHAR(50) UNIQUE NOT NULL,        -- PLCM-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    change_management_philosophy TEXT NOT NULL,
    established_condition_ids TEXT,              -- JSON: [ec_id, ...]
    post_approval_change_history TEXT,           -- JSON: [{date, change, outcome}]
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 5. ICH Q13 — CONTINUOUS MANUFACTURING
-- ============================================================

CREATE TABLE cm_batch_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    batch_definition_type VARCHAR(50) NOT NULL,  -- time_based | quantity_based | parameter_based
    time_duration_hours DECIMAL(10,4),           -- If time-based
    quantity_kg DECIMAL(20,6),                   -- If quantity-based
    definition_rationale TEXT NOT NULL,
    regulatory_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE rtd_models (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_ref VARCHAR(50) UNIQUE NOT NULL,       -- RTD-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    process_unit VARCHAR(255) NOT NULL,          -- Granulator, blender, tablet press, etc.
    model_type VARCHAR(100) NOT NULL,            -- tanks_in_series | axial_dispersion | empirical
    mean_residence_time_min DECIMAL(10,4) NOT NULL,
    variance DECIMAL(15,8),
    diversion_time_min DECIMAL(10,4) NOT NULL,   -- Material before and after disturbance to divert
    validation_status VARCHAR(50) NOT NULL DEFAULT 'draft',
    validated_ranges TEXT,                       -- JSON: validated operating ranges
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE cm_disturbance_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    event_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    process_unit VARCHAR(255) NOT NULL,
    disturbance_type VARCHAR(100) NOT NULL,      -- raw_material | equipment | utility | human_error
    disturbance_description TEXT NOT NULL,
    rtd_model_id UUID REFERENCES rtd_models(id),
    diversion_start TIMESTAMPTZ,
    diversion_end TIMESTAMPTZ,
    diverted_quantity_kg DECIMAL(20,6),
    diverted_material_disposition VARCHAR(100),  -- reject | reprocess | additional_testing
    deviation_id UUID REFERENCES deviations(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 6. GCP — CLINICAL TRIAL SYSTEM VALIDATION
-- ICH E6(R3), 21 CFR Part 11, 21 CFR Part 312
-- ============================================================

CREATE TABLE gcp_system_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type_code VARCHAR(50) UNIQUE NOT NULL,
    type_name VARCHAR(255) NOT NULL,
    description TEXT,
    applicable_regulation TEXT,
    validation_approach VARCHAR(100),
    typical_gamp_category VARCHAR(10)
);

INSERT INTO gcp_system_types (type_code, type_name, applicable_regulation, typical_gamp_category) VALUES
('EDC',   'Electronic Data Capture',              '21 CFR 11, ICH E6(R3)',    '4'),
('CTMS',  'Clinical Trial Management System',     '21 CFR 11, ICH E6(R3)',    '4'),
('IRT',   'Interactive Response Technology',      '21 CFR 11, ICH E6(R3)',    '4'),
('ETMF',  'Electronic Trial Master File',         '21 CFR 11, ICH E6(R3)',    '4'),
('CDMS',  'Clinical Data Management System',      '21 CFR 11, ICH E6(R3)',    '4'),
('RTSM',  'Randomization & Trial Supply Mgmt',    '21 CFR 11, ICH E6(R3)',    '4'),
('SAFETY','Safety / Pharmacovigilance System',    '21 CFR 312, ICH E2B',      '4'),
('DCT',   'Decentralized Trial Platform',         '21 CFR 11, FDA DCT 2024',  '4')
ON CONFLICT (type_code) DO NOTHING;

CREATE TABLE investigator_site_qualifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_qualification_ref VARCHAR(50) UNIQUE NOT NULL,
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    investigator_site_name VARCHAR(512) NOT NULL,
    investigator_site_number VARCHAR(100),
    study_protocol_number VARCHAR(100),
    -- Qualification checklist
    system_training_complete BOOLEAN NOT NULL DEFAULT FALSE,
    training_completion_date DATE,
    user_access_provisioned BOOLEAN NOT NULL DEFAULT FALSE,
    site_configuration_tested BOOLEAN NOT NULL DEFAULT FALSE,
    user_acceptance_sign_off BOOLEAN NOT NULL DEFAULT FALSE,
    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    qualified_date DATE,
    qualified_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 7. ATMP — CHAIN OF IDENTITY AND CHAIN OF CUSTODY
-- Cell & gene therapy. Most critical patient safety requirement.
-- A mix-up = potential patient death. Zero tolerance for error.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_coi_ref START 1;

CREATE TABLE atmp_products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_type VARCHAR(100) NOT NULL,
    -- autologous_cell | allogeneic_cell | gene_therapy | tissue_engineered | combined
    product_category VARCHAR(50) NOT NULL DEFAULT 'autologous',
    manufacturing_site VARCHAR(512),
    regulatory_framework TEXT,                   -- EMA ATMP, FDA 21 CFR 1271, etc.
    coi_format_description TEXT NOT NULL,        -- How COI identifiers are structured
    coi_barcode_standard VARCHAR(50),            -- ISBT128 | GS1 | proprietary
    cold_chain_temp_range TEXT,                  -- JSON: {min_c, max_c} or ranges
    maximum_hold_time_hours INT,                 -- From collection to manufacture start
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE atmp_chain_of_identity (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    coi_identifier VARCHAR(255) UNIQUE NOT NULL, -- The unique patient-product identifier
    atmp_product_id UUID NOT NULL REFERENCES atmp_products(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    -- Patient (de-identified in CE, patient data separate per privacy requirements)
    patient_pseudonym VARCHAR(100) NOT NULL,     -- De-identified patient reference
    patient_enrollment_date DATE NOT NULL,
    investigator_site_number VARCHAR(100),
    -- Status
    current_status VARCHAR(100) NOT NULL DEFAULT 'enrolled',
    -- enrolled | collected | in_transit_to_mfg | in_manufacture | qc_testing
    -- released | in_transit_to_site | administered | cancelled | destroyed
    current_custodian VARCHAR(512),
    current_location VARCHAR(512),
    -- Critical flags
    identity_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    identity_confirmation_date TIMESTAMPTZ,
    identity_confirmed_by UUID REFERENCES users(id),
    -- Outcome
    therapy_administered BOOLEAN NOT NULL DEFAULT FALSE,
    administration_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE atmp_custody_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_ref VARCHAR(50) UNIQUE NOT NULL,    -- COC-0001
    coi_id UUID NOT NULL REFERENCES atmp_chain_of_identity(id),
    transfer_sequence INT NOT NULL,              -- 1, 2, 3... in order
    -- Who is transferring
    from_party VARCHAR(512) NOT NULL,            -- Hospital, courier, manufacturer, QC lab
    from_location VARCHAR(512) NOT NULL,
    -- Who is receiving
    to_party VARCHAR(512) NOT NULL,
    to_location VARCHAR(512) NOT NULL,
    -- Transfer details
    transfer_type VARCHAR(100) NOT NULL,
    -- collection | transport_to_manufacturer | internal_transfer | transport_to_site | final_handoff
    transfer_datetime TIMESTAMPTZ NOT NULL,
    received_datetime TIMESTAMPTZ,
    -- Temperature during transfer
    temperature_logger_id VARCHAR(100),
    temperature_excursion BOOLEAN NOT NULL DEFAULT FALSE,
    temperature_excursion_details TEXT,
    -- Identity verification at each handoff
    coi_verified_at_handoff BOOLEAN NOT NULL DEFAULT FALSE,
    coi_verification_method VARCHAR(100),        -- barcode_scan | manual_check | system_verification
    -- Signatures — both parties sign
    transferring_signature_id UUID REFERENCES electronic_signatures(id),
    receiving_signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE atmp_donor_eligibility_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    eligibility_ref VARCHAR(50) UNIQUE NOT NULL, -- DEL-0001
    coi_id UUID NOT NULL REFERENCES atmp_chain_of_identity(id),
    -- Testing
    collection_date DATE NOT NULL,
    testing_laboratory VARCHAR(512),
    -- Infectious disease markers (required by regulation)
    hiv_result VARCHAR(20),
    hepatitis_b_result VARCHAR(20),
    hepatitis_c_result VARCHAR(20),
    htlv_result VARCHAR(20),
    syphilis_result VARCHAR(20),
    additional_tests TEXT,                       -- JSON: [{test_name, result}]
    -- Eligibility determination
    donor_eligible BOOLEAN NOT NULL,
    ineligible_reason TEXT,
    -- Sign-off
    determined_by UUID REFERENCES users(id),
    determination_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 8. DCS / SCADA / PROCESS CONTROL VALIDATION
-- GAMP 5 Category 4/5. Manufacturing automation systems.
-- ============================================================

CREATE TABLE instrument_loops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    loop_ref VARCHAR(50) UNIQUE NOT NULL,        -- LOOP-TI-1001
    site_id UUID NOT NULL REFERENCES sites(id),
    drawing_id UUID,                             -- Link to P&ID drawing
    loop_tag VARCHAR(100) NOT NULL,              -- e.g., TI-1001, FIC-2034
    loop_type VARCHAR(50) NOT NULL,              -- temperature | flow | pressure | level | pH | conductivity
    process_fluid VARCHAR(255),
    -- Instruments in this loop
    field_instrument_tag VARCHAR(100),
    transmitter_tag VARCHAR(100),
    controller_tag VARCHAR(100),
    final_element_tag VARCHAR(100),
    -- Acceptance criteria
    measurement_range_low DECIMAL(20,8),
    measurement_range_high DECIMAL(20,8),
    unit VARCHAR(50),
    accuracy_required DECIMAL(10,6),
    -- GxP impact
    gxp_critical BOOLEAN NOT NULL DEFAULT TRUE,
    product_contact BOOLEAN NOT NULL DEFAULT FALSE,
    alarm_setpoints TEXT,                        -- JSON: [{alarm_type, setpoint, action}]
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    last_calibration_date DATE,
    next_calibration_due DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE loop_calibrations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calibration_ref VARCHAR(50) UNIQUE NOT NULL, -- LCAL-0001
    loop_id UUID NOT NULL REFERENCES instrument_loops(id),
    calibration_date DATE NOT NULL,
    calibration_type VARCHAR(50) NOT NULL DEFAULT 'full_loop',
    -- loop_only | field_instrument_only | transmitter_only | as_found_as_left
    as_found_data TEXT,                          -- JSON: [{setpoint, measured, deviation}]
    as_left_data TEXT,                           -- JSON: after adjustment
    all_points_within_tolerance BOOLEAN NOT NULL,
    adjustment_made BOOLEAN NOT NULL DEFAULT FALSE,
    calibrated_by UUID REFERENCES users(id),
    reviewed_by UUID REFERENCES users(id),
    next_calibration_due DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE process_historian_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    validation_ref VARCHAR(50) UNIQUE NOT NULL,  -- PHV-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    historian_type VARCHAR(100) NOT NULL,        -- osisoft_pi | honeywell_phd | inductive_automation | aspentech
    version VARCHAR(100) NOT NULL,
    -- Data fidelity testing
    data_fidelity_tested BOOLEAN NOT NULL DEFAULT FALSE,
    compression_algorithm VARCHAR(100),          -- Which compression is used
    compression_validated BOOLEAN NOT NULL DEFAULT FALSE,
    compression_validation_approach TEXT,
    -- Time sync
    time_sync_method VARCHAR(100),               -- NTP | GPS | manual
    time_sync_accuracy_ms DECIMAL(10,4),
    time_sync_tested BOOLEAN NOT NULL DEFAULT FALSE,
    -- Data gaps
    max_acceptable_gap_seconds INT,
    gap_test_performed BOOLEAN NOT NULL DEFAULT FALSE,
    gap_test_result VARCHAR(50),
    -- Long-term readability
    data_readability_tested BOOLEAN NOT NULL DEFAULT FALSE,
    oldest_data_readable DATE,
    -- Validation outcome
    validation_status VARCHAR(50) NOT NULL DEFAULT 'planned',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE dcs_recipe_validations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipe_ref VARCHAR(50) UNIQUE NOT NULL,      -- RECIPE-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    recipe_name VARCHAR(512) NOT NULL,
    recipe_version VARCHAR(50) NOT NULL,
    recipe_type VARCHAR(100) NOT NULL,           -- master | control | procedure | operation | phase
    -- Parameters
    critical_parameters TEXT NOT NULL,           -- JSON: [{param_name, setpoint, range, gxp_critical}]
    parameter_count INT NOT NULL DEFAULT 0,
    -- Validation
    validation_protocol_id UUID REFERENCES protocols(id),
    validation_status VARCHAR(50) NOT NULL DEFAULT 'draft',
    configuration_locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE alarm_rationalizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    alarm_ref VARCHAR(50) UNIQUE NOT NULL,       -- ALARM-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    alarm_tag VARCHAR(100) NOT NULL,
    alarm_description VARCHAR(512) NOT NULL,
    -- Rationalization (per EEMUA 191 / IEC 62682)
    process_hazard TEXT NOT NULL,                -- What condition the alarm detects
    consequence_if_ignored TEXT NOT NULL,
    gxp_critical BOOLEAN NOT NULL DEFAULT FALSE,
    alarm_priority VARCHAR(20) NOT NULL,         -- critical | high | medium | low
    setpoint DECIMAL(20,8),
    setpoint_unit VARCHAR(50),
    allowable_response_time_min DECIMAL(10,4),  -- Time operator has to respond
    required_operator_action TEXT NOT NULL,
    -- Review
    rationalized_by UUID REFERENCES users(id),
    rationalized_date DATE,
    last_review_date DATE,
    next_review_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 9. GDP — DISTRIBUTION LANE QUALIFICATION
-- EU GDP (2013/C 343/01), WHO TRS 961
-- ============================================================

CREATE TABLE distribution_lane_qualifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lane_ref VARCHAR(50) UNIQUE NOT NULL,        -- LANE-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    origin_location VARCHAR(512) NOT NULL,
    destination_location VARCHAR(512) NOT NULL,
    transport_mode VARCHAR(50) NOT NULL,         -- road | air | sea | multimodal
    carrier_name VARCHAR(512) NOT NULL,
    -- Temperature requirements
    required_temp_min_c DECIMAL(8,4) NOT NULL,
    required_temp_max_c DECIMAL(8,4) NOT NULL,
    product_category VARCHAR(100) NOT NULL,      -- ambient | cold_chain | frozen | cryogenic
    -- Qualification
    qualification_status VARCHAR(50) NOT NULL DEFAULT 'pending',
    summer_qualification_complete BOOLEAN NOT NULL DEFAULT FALSE,
    winter_qualification_complete BOOLEAN NOT NULL DEFAULT FALSE,
    qualification_date DATE,
    requalification_interval_months INT NOT NULL DEFAULT 24,
    next_qualification_due DATE,
    -- Packaging
    qualified_packaging_types TEXT,              -- JSON: approved packaging solutions
    -- Results
    worst_case_excursion_temp_c DECIMAL(8,4),
    worst_case_excursion_duration_hours DECIMAL(10,4),
    results_acceptable BOOLEAN,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE transport_excursion_investigations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    excursion_ref VARCHAR(50) UNIQUE NOT NULL,   -- TEX-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    lane_id UUID REFERENCES distribution_lane_qualifications(id),
    shipment_tracking_number VARCHAR(255),
    excursion_detected_date DATE NOT NULL,
    excursion_type VARCHAR(50) NOT NULL,         -- temperature | humidity | shock | delay | loss
    -- Temperature excursion details
    excursion_temp_min_c DECIMAL(8,4),
    excursion_temp_max_c DECIMAL(8,4),
    excursion_duration_hours DECIMAL(10,4),
    -- Product impact
    products_affected TEXT NOT NULL,             -- JSON: [{product_name, quantity, lot_number}]
    impact_assessment TEXT NOT NULL,
    disposition VARCHAR(50) NOT NULL DEFAULT 'under_investigation',
    -- reject | release | additional_testing_required | quarantine
    disposition_rationale TEXT,
    linked_capa_id UUID REFERENCES capas(id),
    disposition_by UUID REFERENCES users(id),
    disposition_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE responsible_person_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rp_ref VARCHAR(50) UNIQUE NOT NULL,          -- RP-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    user_id UUID NOT NULL REFERENCES users(id),
    rp_type VARCHAR(50) NOT NULL DEFAULT 'gdp',  -- gdp | qp | rp_import | rp_distribution
    qualification_basis TEXT NOT NULL,           -- Education, experience, training
    scope_of_responsibility TEXT NOT NULL,
    designated_date DATE NOT NULL,
    designation_expiry_date DATE,
    backup_rp_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 10. PIC/S PI 041-1 — DATA INTEGRITY GOVERNANCE
-- Written by inspectors for inspectors.
-- Raises expectations above 21 CFR Part 11.
-- ============================================================

CREATE TABLE data_integrity_governance_docs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    di_ref VARCHAR(50) UNIQUE NOT NULL,          -- DIG-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- Scope
    scope_description TEXT NOT NULL,
    applicable_systems TEXT,                     -- JSON: [system_id, ...]
    -- Data governance framework elements (PI 041-1)
    quality_culture_statement TEXT NOT NULL,     -- Leadership commitment to DI
    roles_and_responsibilities TEXT NOT NULL,    -- Who is accountable for what
    data_lifecycle_description TEXT NOT NULL,    -- From creation to archive
    data_classification_scheme TEXT NOT NULL,    -- Critical, important, routine
    hybrid_system_controls TEXT,                 -- If any hybrid systems exist
    outsourced_data_management TEXT,             -- Third party controls
    -- Self-inspection
    self_inspection_frequency VARCHAR(50) NOT NULL DEFAULT 'annual',
    last_self_inspection_date DATE,
    next_self_inspection_date DATE,
    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    next_review_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE hybrid_system_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    system_id UUID NOT NULL REFERENCES systems(id) UNIQUE,
    site_id UUID NOT NULL REFERENCES sites(id),
    -- Define the hybrid
    electronic_record_description TEXT NOT NULL,
    paper_record_description TEXT NOT NULL,
    authoritative_record VARCHAR(20) NOT NULL,   -- electronic | paper
    -- Controls required by PI 041-1
    transcription_procedure TEXT NOT NULL,       -- How data is transferred between media
    verification_procedure TEXT NOT NULL,        -- How accuracy is confirmed
    reconciliation_frequency VARCHAR(50) NOT NULL,
    -- Cannot use hybrid without strong justification
    justification_for_hybrid TEXT NOT NULL,
    migration_plan_to_electronic TEXT,           -- When will this be fully electronic?
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_trail_review_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    review_ref VARCHAR(50) UNIQUE NOT NULL,      -- ATR-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    -- What was reviewed
    review_scope TEXT NOT NULL,
    records_reviewed INT,
    anomalies_detected INT NOT NULL DEFAULT 0,
    anomalies_description TEXT,
    -- Findings
    no_issues_found BOOLEAN NOT NULL DEFAULT TRUE,
    findings_description TEXT,
    actions_required TEXT,
    -- Outcome
    reviewer_id UUID NOT NULL REFERENCES users(id),
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    linked_capa_id UUID REFERENCES capas(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE data_integrity_self_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inspection_ref VARCHAR(50) UNIQUE NOT NULL,  -- DISI-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    inspection_date DATE NOT NULL,
    lead_inspector_id UUID NOT NULL REFERENCES users(id),
    scope_description TEXT NOT NULL,
    systems_reviewed TEXT,                       -- JSON: [system_id, ...]
    -- Findings
    total_findings INT NOT NULL DEFAULT 0,
    critical_findings INT NOT NULL DEFAULT 0,
    major_findings INT NOT NULL DEFAULT 0,
    minor_findings INT NOT NULL DEFAULT 0,
    observations INT NOT NULL DEFAULT 0,
    findings_summary TEXT,
    -- CAPA
    linked_capa_ids TEXT,                        -- JSON: [capa_id, ...]
    -- Sign-off
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 11. SOP VISUALIZER ENGINE
-- Competitive differentiator. Parse SOPs and process documents
-- into interactive visual flowcharts. AI-powered extraction.
-- Can also render validation package completion status visually.
-- ============================================================

CREATE TABLE sop_visualizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visualization_ref VARCHAR(50) UNIQUE NOT NULL, -- SOPVIZ-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    source_document_id UUID REFERENCES documents(id),
    source_document_title VARCHAR(512) NOT NULL,
    source_document_version VARCHAR(50),
    -- Visualization metadata
    visualization_type VARCHAR(50) NOT NULL DEFAULT 'flowchart',
    -- flowchart | swimlane | decision_tree | process_map | responsibility_matrix
    layout_algorithm VARCHAR(50) NOT NULL DEFAULT 'top_down',
    -- top_down | left_right | swimlane_horizontal | swimlane_vertical
    status VARCHAR(50) NOT NULL DEFAULT 'draft',  -- draft | published | archived
    -- Generation
    auto_generated BOOLEAN NOT NULL DEFAULT FALSE,
    ai_extraction_confidence DECIMAL(5,2),        -- 0-100: how confident the AI was
    manually_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    reviewed_by UUID REFERENCES users(id),
    -- Render data
    node_data TEXT NOT NULL,                      -- JSON: complete node/edge graph data
    layout_data TEXT,                             -- JSON: computed x/y positions
    theme VARCHAR(50) NOT NULL DEFAULT 'dark',    -- dark | light | print
    -- Publishing
    public_url_token VARCHAR(100),                -- For sharing outside the platform
    embed_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    view_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE sop_viz_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visualization_id UUID NOT NULL REFERENCES sop_visualizations(id),
    node_key VARCHAR(100) NOT NULL,               -- Unique key within the visualization
    node_type VARCHAR(50) NOT NULL,
    -- start | end | process | decision | subprocess | document | role
    -- wait | loop | annotation | swimlane_header | parallel_gateway
    label TEXT NOT NULL,
    description TEXT,
    -- Visual positioning
    pos_x DECIMAL(10,4) NOT NULL DEFAULT 0,
    pos_y DECIMAL(10,4) NOT NULL DEFAULT 0,
    width DECIMAL(10,4) NOT NULL DEFAULT 180,
    height DECIMAL(10,4) NOT NULL DEFAULT 60,
    -- Styling
    color_token VARCHAR(50),                      -- Maps to design system colors
    icon_key VARCHAR(50),
    -- Regulation/GxP metadata
    responsible_role VARCHAR(255),                -- Who performs this step
    regulatory_citation TEXT,                     -- 21 CFR 11.10(e), etc.
    gxp_critical BOOLEAN NOT NULL DEFAULT FALSE,
    -- Links
    linked_object_type VARCHAR(100),              -- system | protocol | capa | sop
    linked_object_id UUID,
    sort_order INT NOT NULL DEFAULT 0,
    UNIQUE (visualization_id, node_key)
);

CREATE TABLE sop_viz_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visualization_id UUID NOT NULL REFERENCES sop_visualizations(id),
    edge_key VARCHAR(100) NOT NULL,
    source_node_key VARCHAR(100) NOT NULL,
    target_node_key VARCHAR(100) NOT NULL,
    label TEXT,                                   -- Decision branch labels: "Yes" / "No"
    edge_type VARCHAR(50) NOT NULL DEFAULT 'sequence',
    -- sequence | conditional_yes | conditional_no | exception | loop_back | parallel
    color_token VARCHAR(50),
    is_critical_path BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    UNIQUE (visualization_id, edge_key)
);

CREATE TABLE sop_viz_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(512) NOT NULL,
    description TEXT,
    process_type VARCHAR(100) NOT NULL,
    -- validation_lifecycle | change_control | capa_workflow | deviation_process
    -- periodic_review | document_approval | onboarding | training
    node_data TEXT NOT NULL,                      -- JSON: pre-built node template
    is_system_template BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed visualization templates for common pharma processes
INSERT INTO sop_viz_templates (template_code, name, description, process_type, node_data) VALUES
('VIZ-CSV-LIFECYCLE',   'CSV Lifecycle Flow',        'System implementation lifecycle IQ/OQ/PQ',      'validation_lifecycle', '{}'),
('VIZ-CC-WORKFLOW',     'Change Control Workflow',    'Standard change control process flow',          'change_control',       '{}'),
('VIZ-CAPA-WORKFLOW',   'CAPA Workflow',             'CAPA initiation to closure swimlane',           'capa_workflow',        '{}'),
('VIZ-DEV-PROCESS',     'Deviation Management',      'Deviation detection to closure',                'deviation_process',    '{}'),
('VIZ-PERIODIC-REVIEW', 'Periodic Review Process',   'Periodic review scheduling to approval',        'periodic_review',      '{}'),
('VIZ-DOC-APPROVAL',    'Document Approval',         'Document authoring to effective status',        'document_approval',    '{}'),
('VIZ-SLC-ASTELLAS',    'Astellas SLC (System Impl)','Two-path SLC: Implementation vs Op Change',    'validation_lifecycle', '{}'),
('VIZ-APS-PROCESS',     'Aseptic Process Simulation','APS execution and disposition workflow',        'sterility_assurance',  '{}')
ON CONFLICT (template_code) DO NOTHING;

-- ============================================================
-- 12. VALIDATION PACKAGE VISUALIZER
-- Show the entire validation project as a visual completion map.
-- Dependency chains, RTM heat map, status at a glance.
-- ============================================================

CREATE TABLE validation_package_visualizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    viz_ref VARCHAR(50) UNIQUE NOT NULL,          -- VPV-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    validation_project_id UUID NOT NULL REFERENCES validation_projects(id),
    visualization_type VARCHAR(50) NOT NULL DEFAULT 'lifecycle_map',
    -- lifecycle_map | rtm_heatmap | gantt | dependency_tree | completion_wheel
    status VARCHAR(50) NOT NULL DEFAULT 'auto',   -- auto (always current) | snapshot (frozen)
    snapshot_date TIMESTAMPTZ,                    -- If snapshot
    -- Computed layout data (refreshed by background job)
    computed_data TEXT,                           -- JSON: positions, statuses, completion %
    last_computed_at TIMESTAMPTZ,
    -- Sharing
    shareable_token VARCHAR(100),                 -- Token for external share link
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- INDEXES FOR PART 11
-- ============================================================

CREATE INDEX idx_dhf_site ON design_history_files (site_id, status);
CREATE INDEX idx_design_inputs_dhf ON design_inputs (dhf_id, status);
CREATE INDEX idx_design_outputs_dhf ON design_outputs (dhf_id, status);
CREATE INDEX idx_design_verifications_dhf ON design_verifications (dhf_id, status);
CREATE INDEX idx_design_validations_dhf ON design_validations (dhf_id, status);

CREATE INDEX idx_mgmt_review_site ON management_review_meetings (site_id, meeting_date DESC);
CREATE INDEX idx_mgmt_review_inputs ON management_review_inputs (review_id, input_category);
CREATE INDEX idx_mgmt_review_actions ON management_review_actions (review_id, status);

CREATE INDEX idx_ccs_site ON contamination_control_strategies (site_id);
CREATE INDEX idx_aps_protocols_site ON aps_protocols (site_id);
CREATE INDEX idx_aps_executions_protocol ON aps_executions (protocol_id, run_date DESC);
CREATE INDEX idx_pupsit_records_batch ON pupsit_records (batch_id);
CREATE INDEX idx_pupsit_records_site ON pupsit_records (site_id, test_date DESC);

CREATE INDEX idx_established_conditions ON established_conditions (site_id, product_code);
CREATE INDEX idx_pac_protocols ON pac_management_protocols (site_id, status);

CREATE INDEX idx_cm_batch_definitions ON cm_batch_definitions (site_id);
CREATE INDEX idx_rtd_models ON rtd_models (site_id, validation_status);
CREATE INDEX idx_cm_disturbance_events ON cm_disturbance_events (site_id, event_date DESC);

CREATE INDEX idx_inv_site_quals ON investigator_site_qualifications (system_id, status);

CREATE INDEX idx_atmp_coi ON atmp_chain_of_identity (atmp_product_id, current_status);
CREATE INDEX idx_atmp_transfers ON atmp_custody_transfers (coi_id, transfer_sequence);
CREATE INDEX idx_atmp_donor ON atmp_donor_eligibility_records (coi_id);

CREATE INDEX idx_instrument_loops_site ON instrument_loops (site_id, loop_type, status);
CREATE INDEX idx_loop_calibrations ON loop_calibrations (loop_id, calibration_date DESC);
CREATE INDEX idx_historian_validations ON process_historian_validations (system_id);
CREATE INDEX idx_dcs_recipes ON dcs_recipe_validations (system_id, validation_status);
CREATE INDEX idx_alarm_rationalizations ON alarm_rationalizations (site_id, system_id);

CREATE INDEX idx_lane_qualifications ON distribution_lane_qualifications (site_id, qualification_status);
CREATE INDEX idx_transport_excursions ON transport_excursion_investigations (site_id, excursion_detected_date DESC);
CREATE INDEX idx_responsible_persons ON responsible_person_records (site_id, rp_type, status);

CREATE INDEX idx_di_governance ON data_integrity_governance_docs (site_id, status);
CREATE INDEX idx_audit_trail_reviews ON audit_trail_review_records (site_id, system_id, review_date DESC);
CREATE INDEX idx_di_self_inspections ON data_integrity_self_inspections (site_id, inspection_date DESC);

CREATE INDEX idx_sop_visualizations ON sop_visualizations (site_id, status);
CREATE INDEX idx_sop_viz_nodes ON sop_viz_nodes (visualization_id);
CREATE INDEX idx_sop_viz_edges ON sop_viz_edges (visualization_id, source_node_key);

CREATE INDEX idx_vp_visualizations ON validation_package_visualizations (validation_project_id);

-- ============================================================
-- FINAL TABLE COUNT
-- Part 1:130 Part 3:31 Part 4:4  Part 5:33 Part 6:16
-- Part 7:37  Part 8:20 Part 9:91 Part 10:11 Part 11:~55
-- GRAND TOTAL: ~428 tables
-- ============================================================
