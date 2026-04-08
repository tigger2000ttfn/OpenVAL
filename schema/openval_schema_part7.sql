-- ============================================================
-- OpenVAL Schema - Part 7: Complete Validation Disciplines
-- Version: 1.0.0
-- Run after Parts 1-6
--
-- Adds every table needed for:
-- - Electronic Logbook Management (Kneat-equivalent)
-- - Drawing / P&ID Management
-- - Technology Transfer
-- - Cleaning Validation (with MACO/ADE/LD50 calculations)
-- - Cold Chain / Temperature Mapping Validation
-- - Commissioning & Qualification (CQV) packages
-- - Process Validation Stages 1/2/3 (PPQ + CPV)
-- - Sterilization Validation
-- - Reusable Test Case Library (Kneat Entity system)
-- - Audit Collections / Audit War Rooms
-- - Validation Master Plan (VMP) structured document
-- - Computer Software Assurance (CSA) mode records
-- - Document Annotation and Redlining
-- - Validation Debt Tracker
-- - Quality by Design (QbD) framework
-- ============================================================

-- ============================================================
-- 1. ELECTRONIC LOGBOOK MANAGEMENT
-- Paperless logbooks replacing paper binders.
-- Equipment logs, area logs, instrument logs, batch logs.
-- Fully 21 CFR Part 11 / EU Annex 11 compliant.
-- Kneat eLogbook equivalent.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_logbook_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_logbook_entry_ref START 1;

CREATE TABLE electronic_logbooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    logbook_ref VARCHAR(50) UNIQUE NOT NULL,      -- LB-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    logbook_name VARCHAR(512) NOT NULL,
    logbook_type VARCHAR(100) NOT NULL,
    -- equipment | area | instrument | batch | reagent | solution
    -- personnel | training | maintenance | environmental | custom
    linked_equipment_id UUID REFERENCES equipment(id),
    linked_system_id UUID REFERENCES systems(id),
    linked_area VARCHAR(255),                     -- Cleanroom, lab area name
    purpose TEXT NOT NULL,
    regulatory_basis VARCHAR(255),
    gxp_relevant BOOLEAN NOT NULL DEFAULT TRUE,
    requires_witness BOOLEAN NOT NULL DEFAULT FALSE,
    -- Entry requirements
    requires_reason_for_correction BOOLEAN NOT NULL DEFAULT TRUE,
    allows_concurrent_entries BOOLEAN NOT NULL DEFAULT FALSE,
    auto_close_after_days INT,                    -- NULL = never auto-close
    -- Approval
    owner_id UUID REFERENCES users(id),
    qa_reviewer_id UUID REFERENCES users(id),
    effective_date DATE,
    review_interval_months INT NOT NULL DEFAULT 12,
    next_review_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    -- active | under_review | retired | archived
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE logbook_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_ref VARCHAR(50) UNIQUE NOT NULL,        -- LB-0001-E-0042
    logbook_id UUID NOT NULL REFERENCES electronic_logbooks(id),
    entry_type VARCHAR(100) NOT NULL DEFAULT 'routine',
    -- routine | maintenance | calibration | cleaning | deviation
    -- instrument_use | reagent_preparation | access_record | custom
    entry_date DATE NOT NULL,
    entry_time TIME,
    -- Structured fields (flexible per logbook type)
    subject VARCHAR(512) NOT NULL,
    body TEXT NOT NULL,
    structured_data TEXT,                         -- JSON key-value pairs for structured fields
    -- Equipment-specific fields
    equipment_status_before VARCHAR(100),
    equipment_status_after VARCHAR(100),
    reading_before DECIMAL(20,6),
    reading_after DECIMAL(20,6),
    unit VARCHAR(50),
    -- Personnel
    performed_by UUID NOT NULL REFERENCES users(id),
    witnessed_by UUID REFERENCES users(id),
    -- Correction
    is_correction BOOLEAN NOT NULL DEFAULT FALSE,
    corrects_entry_id UUID REFERENCES logbook_entries(id),
    correction_reason TEXT,
    -- Deviation flag
    deviation_observed BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_id UUID REFERENCES deviations(id),
    -- Sign-off
    signed_off BOOLEAN NOT NULL DEFAULT FALSE,
    signed_off_by UUID REFERENCES users(id),
    signed_off_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    -- Audit fields
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE logbook_entry_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entry_id UUID NOT NULL REFERENCES logbook_entries(id),
    file_id UUID NOT NULL REFERENCES file_store(id),
    attachment_type VARCHAR(50) NOT NULL DEFAULT 'evidence',
    caption TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 2. DRAWING / P&ID MANAGEMENT
-- Engineering drawings linked to validation protocols.
-- P&ID walkdowns with protocol access.
-- Kneat Drawing Management Module equivalent.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_drawing_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_walkdown_ref START 1;

CREATE TABLE drawings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    drawing_ref VARCHAR(50) UNIQUE NOT NULL,      -- DWG-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    drawing_number VARCHAR(255) UNIQUE NOT NULL,
    title VARCHAR(512) NOT NULL,
    drawing_type VARCHAR(100) NOT NULL,
    -- pid | pfd | isometric | layout | electrical | mechanical
    -- hvac | instrumentation | loop_diagram | cause_effect
    revision VARCHAR(20) NOT NULL DEFAULT 'A',
    status VARCHAR(50) NOT NULL DEFAULT 'current',
    -- current | superseded | obsolete | draft | under_review
    discipline VARCHAR(100),
    -- process | mechanical | electrical | civil | structural
    linked_system_id UUID REFERENCES systems(id),
    linked_equipment_id UUID REFERENCES equipment(id),
    file_id UUID REFERENCES file_store(id),       -- Actual drawing file
    external_dms_ref VARCHAR(512),                -- Reference to external DMS if applicable
    owner_id UUID REFERENCES users(id),
    effective_date DATE,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE drawing_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    drawing_id UUID NOT NULL REFERENCES drawings(id),
    revision VARCHAR(20) NOT NULL,
    change_description TEXT,
    file_id UUID REFERENCES file_store(id),
    superseded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- P&ID Walkdown: execute a protocol while walking the P&ID
CREATE TABLE drawing_walkdowns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    walkdown_ref VARCHAR(50) UNIQUE NOT NULL,     -- WD-0001
    drawing_id UUID NOT NULL REFERENCES drawings(id),
    execution_id UUID REFERENCES test_executions(id),
    title VARCHAR(512) NOT NULL,
    walkdown_type VARCHAR(100) NOT NULL DEFAULT 'verification',
    -- verification | redline_capture | as_built_check | commissioning
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    performed_by UUID REFERENCES users(id),
    performed_at TIMESTAMPTZ,
    overall_result VARCHAR(20),
    -- pass | fail | pass_with_deviations
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE drawing_walkdown_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    walkdown_id UUID NOT NULL REFERENCES drawing_walkdowns(id),
    item_number INT NOT NULL,
    tag_number VARCHAR(100),                      -- Equipment/instrument tag
    description TEXT NOT NULL,
    expected_state TEXT,
    actual_state TEXT,
    result VARCHAR(20),                           -- pass | fail | not_applicable
    deviation_observed BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_id UUID REFERENCES deviations(id),
    redline_note TEXT,                            -- Markup note for drawing update
    photo_file_id UUID REFERENCES file_store(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. TECHNOLOGY TRANSFER MODULE
-- Structured technology transfer from development to manufacturing,
-- site-to-site, or scale-up. Common in CDMO environments.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_tt_ref START 1;

CREATE TABLE technology_transfers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tt_ref VARCHAR(50) UNIQUE NOT NULL,           -- TT-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    transfer_type VARCHAR(100) NOT NULL,
    -- development_to_manufacturing | site_to_site | scale_up
    -- scale_down | manufacturing_to_cdmo | process_acquisition
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    dosage_form VARCHAR(100),
    sending_site VARCHAR(512),
    receiving_site VARCHAR(512),
    receiving_site_id UUID REFERENCES sites(id),
    sending_team_lead UUID REFERENCES users(id),
    receiving_team_lead UUID REFERENCES users(id),
    qa_lead_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'planning',
    -- planning | approved | active | complete | on_hold | cancelled
    planned_start_date DATE,
    planned_completion_date DATE,
    actual_start_date DATE,
    actual_completion_date DATE,
    scope_description TEXT NOT NULL,
    transfer_strategy TEXT,
    -- What will be transferred: formulas, equipment, SOPs, etc.
    acceptance_criteria TEXT,
    regulatory_submissions_required BOOLEAN NOT NULL DEFAULT FALSE,
    regulatory_strategy TEXT,
    conclusion TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE technology_transfer_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_id UUID NOT NULL REFERENCES technology_transfers(id),
    item_category VARCHAR(100) NOT NULL,
    -- formulation | analytical_method | manufacturing_process | cleaning_method
    -- equipment_specification | raw_material | packaging | regulatory_filing
    -- sop | training_record | validation_data | stability_data
    item_description TEXT NOT NULL,
    responsible_id UUID REFERENCES users(id),
    target_completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    completion_notes TEXT,
    completed_at TIMESTAMPTZ,
    linked_document_id UUID REFERENCES documents(id),
    linked_protocol_id UUID REFERENCES protocols(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 4. CLEANING VALIDATION
-- Full cleaning validation lifecycle with MACO/ADE/LD50 calculations,
-- equipment groupings, agent qualification, and CPK trending.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_cleaning_study_ref START 1;

CREATE TABLE cleaning_validation_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,        -- CL-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    study_type VARCHAR(100) NOT NULL DEFAULT 'prospective',
    -- prospective | concurrent | retrospective | revalidation
    cleaning_agent_name VARCHAR(512) NOT NULL,
    cleaning_agent_concentration VARCHAR(100),
    equipment_ids TEXT NOT NULL,                  -- JSON array of equipment IDs
    worst_case_product VARCHAR(512),              -- Most difficult to clean / most toxic
    worst_case_basis VARCHAR(100),                -- solubility | toxicity | activity
    product_contact_materials TEXT,              -- JSON array
    -- Acceptance limits
    limit_approach VARCHAR(50) NOT NULL DEFAULT 'health_based',
    -- health_based (ADE/PDE) | dose_based (MACO) | LD50 | 10ppm | visual
    maco_value DECIMAL(20,8),
    maco_unit VARCHAR(50),
    ade_value DECIMAL(20,8),
    ade_unit VARCHAR(50),
    ld50_value DECIMAL(20,8),
    ld50_unit VARCHAR(50),
    calculated_limit DECIMAL(20,8),
    limit_unit VARCHAR(50),
    safety_factor DECIMAL(10,4),
    surface_area_cm2 DECIMAL(20,4),
    batch_size_kg DECIMAL(20,4),
    -- Sampling strategy
    sampling_type VARCHAR(50) NOT NULL DEFAULT 'swab',
    -- swab | rinse | placebo | visual
    sampling_points TEXT,                         -- JSON array with locations
    analytical_method VARCHAR(512),
    lod_value DECIMAL(20,8),
    loq_value DECIMAL(20,8),
    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    validation_conclusion VARCHAR(50),
    -- validated | conditionally_validated | not_validated | requires_revalidation
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    next_review_date DATE,
    change_request_id UUID REFERENCES change_requests(id),
    protocol_id UUID REFERENCES protocols(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE cleaning_validation_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID NOT NULL REFERENCES cleaning_validation_studies(id),
    run_number INT NOT NULL,
    run_date DATE NOT NULL,
    sample_id VARCHAR(100) NOT NULL,
    sample_location VARCHAR(512) NOT NULL,
    sampling_type VARCHAR(50) NOT NULL,
    result_value DECIMAL(20,8) NOT NULL,
    result_unit VARCHAR(50) NOT NULL,
    limit_value DECIMAL(20,8) NOT NULL,
    meets_limit BOOLEAN NOT NULL,
    recovery_factor DECIMAL(10,4),
    corrected_result DECIMAL(20,8),
    analyst_id UUID REFERENCES users(id),
    instrument_id UUID REFERENCES equipment(id),
    analysis_date DATE,
    oos_id UUID REFERENCES oos_oot_records(id),   -- Auto-link if fails
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 5. COLD CHAIN / TEMPERATURE MAPPING VALIDATION
-- Temperature mapping of cold rooms, freezers, refrigerators,
-- and shipping containers. GDP/USP<659>/ICH Q1A aligned.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_thermal_study_ref START 1;

CREATE TABLE thermal_mapping_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,        -- TM-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    study_type VARCHAR(100) NOT NULL,
    -- empty_chamber | loaded_chamber | shipping | transport | worst_case
    target_temperature_range VARCHAR(100) NOT NULL,
    -- e.g., "2-8°C" or "-20°C" or "-80°C"
    equipment_id UUID REFERENCES equipment(id),
    equipment_description VARCHAR(512),           -- If not in equipment table
    chamber_volume_m3 DECIMAL(10,4),
    loaded_percentage DECIMAL(5,2),              -- % of capacity loaded
    sensor_count INT NOT NULL,
    sensor_ids TEXT,                              -- JSON array of sensor IDs/labels
    sensor_placement_description TEXT,
    duration_hours DECIMAL(10,2) NOT NULL,
    logging_interval_minutes INT NOT NULL DEFAULT 5,
    -- Temperature specifications
    min_acceptable DECIMAL(10,4) NOT NULL,
    max_acceptable DECIMAL(10,4) NOT NULL,
    unit VARCHAR(20) NOT NULL DEFAULT '°C',
    -- Regulatory requirements
    regulatory_basis VARCHAR(255),               -- GDP, USP <659>, ICH Q1A
    -- Results
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    study_start_datetime TIMESTAMPTZ,
    study_end_datetime TIMESTAMPTZ,
    min_recorded DECIMAL(10,4),
    max_recorded DECIMAL(10,4),
    mean_temperature DECIMAL(10,4),
    std_deviation DECIMAL(10,4),
    number_of_excursions INT NOT NULL DEFAULT 0,
    hot_spots TEXT,                               -- JSON array of sensor IDs with locations
    cold_spots TEXT,
    mapping_conclusion VARCHAR(50),
    -- pass | fail | conditional
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    protocol_id UUID REFERENCES protocols(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE thermal_mapping_data (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID NOT NULL REFERENCES thermal_mapping_studies(id),
    sensor_id VARCHAR(100) NOT NULL,
    sensor_label VARCHAR(255),                    -- e.g., "Top-Front-Left"
    recorded_at TIMESTAMPTZ NOT NULL,
    temperature DECIMAL(10,4) NOT NULL,
    humidity DECIMAL(10,4),
    is_within_range BOOLEAN NOT NULL,
    excursion_id UUID,                            -- FK to cold chain excursion if outside range
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cold_chain_excursions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    study_id UUID REFERENCES thermal_mapping_studies(id),
    equipment_id UUID REFERENCES equipment(id),
    excursion_start TIMESTAMPTZ NOT NULL,
    excursion_end TIMESTAMPTZ,
    duration_minutes DECIMAL(10,2),
    max_deviation_from_range DECIMAL(10,4),
    temperature_unit VARCHAR(20) NOT NULL DEFAULT '°C',
    products_potentially_impacted TEXT,          -- JSON array
    root_cause VARCHAR(100),
    root_cause_description TEXT,
    immediate_action TEXT,
    product_disposition VARCHAR(100),
    -- quarantine | release_with_justification | reject | return_to_vendor
    disposition_rationale TEXT,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE,
    capa_id UUID REFERENCES capas(id),
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 6. COMMISSIONING & QUALIFICATION (CQV) PACKAGES
-- Structured commissioning packages used in facility/equipment
-- CQV projects. Paperless handover packages.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_cqv_package_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_punch_item_ref START 1;

CREATE TABLE commissioning_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_ref VARCHAR(50) UNIQUE NOT NULL,      -- CQV-PKG-0001
    project_id UUID REFERENCES validation_projects(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    package_name VARCHAR(512) NOT NULL,
    package_type VARCHAR(100) NOT NULL DEFAULT 'equipment',
    -- equipment | system | utility | facility | area
    description TEXT,
    equipment_ids TEXT,                           -- JSON array
    system_ids TEXT,                              -- JSON array
    cqv_stage VARCHAR(50) NOT NULL DEFAULT 'commissioning',
    -- commissioning | iq | oq | pq | pv_stage1 | pv_stage2 | pv_stage3
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    -- open | in_progress | ready_for_handover | handed_over | complete
    responsible_id UUID REFERENCES users(id),
    qa_reviewer_id UUID REFERENCES users(id),
    target_handover_date DATE,
    actual_handover_date DATE,
    handover_signature_id UUID REFERENCES electronic_signatures(id),
    handover_accepted_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE commissioning_package_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES commissioning_packages(id),
    item_type VARCHAR(100) NOT NULL,
    -- test_protocol | sop | drawing | calibration_cert | vendor_doc
    -- punch_item | inspection_record | training_record | spare_parts_list
    title VARCHAR(512) NOT NULL,
    description TEXT,
    document_ref VARCHAR(255),
    linked_protocol_id UUID REFERENCES protocols(id),
    linked_document_id UUID REFERENCES documents(id),
    file_id UUID REFERENCES file_store(id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    responsible_id UUID REFERENCES users(id),
    due_date DATE,
    completed_at TIMESTAMPTZ,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Punch items: open items specific to CQV/commissioning
-- Similar to protocol_open_items but pre-execution
CREATE TABLE punch_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_ref VARCHAR(50) UNIQUE NOT NULL,         -- PUNCH-0001
    package_id UUID REFERENCES commissioning_packages(id),
    project_id UUID REFERENCES validation_projects(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    category VARCHAR(50) NOT NULL DEFAULT 'category_b',
    -- category_a (safety/critical, blocks handover)
    -- category_b (functional, blocks startup)
    -- category_c (aesthetic/minor, tracked only)
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    location VARCHAR(255),
    drawing_ref VARCHAR(255),
    tag_number VARCHAR(100),
    raised_by UUID REFERENCES users(id),
    raised_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_to UUID REFERENCES users(id),
    target_date DATE,
    resolution TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    -- open | in_progress | resolved | accepted | cancelled
    photo_file_id UUID REFERENCES file_store(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 7. PROCESS VALIDATION - STAGES 1, 2, 3
-- FDA Process Validation Guidance (2011): Stage 1 = Process Design,
-- Stage 2 = Process Qualification (PPQ), Stage 3 = Continued
-- Process Verification (CPV).
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_pv_study_ref START 1;

CREATE TABLE process_validation_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,        -- PV-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    process_name VARCHAR(512) NOT NULL,
    product_name VARCHAR(512),
    product_code VARCHAR(100),
    dosage_form VARCHAR(100),
    process_type VARCHAR(100) NOT NULL DEFAULT 'manufacturing',
    -- manufacturing | aseptic | packaging | sterilization | cleaning | analytical
    study_type VARCHAR(50) NOT NULL,
    -- stage_1_design | stage_2_ppq | stage_3_cpv | revalidation
    stage VARCHAR(20) NOT NULL,                   -- stage_1 | stage_2 | stage_3
    status VARCHAR(50) NOT NULL DEFAULT 'planning',
    -- planning | active | complete | cancelled
    -- Stage 1: Process Design
    control_strategy TEXT,
    critical_process_parameters TEXT,             -- JSON array of CPPs
    critical_quality_attributes TEXT,             -- JSON array of CQAs
    design_space TEXT,
    risk_assessment_id UUID REFERENCES risk_assessments(id),
    -- Stage 2: PPQ
    ppq_batches_required INT,
    ppq_batches_completed INT NOT NULL DEFAULT 0,
    acceptance_criteria TEXT,
    ppq_protocol_id UUID REFERENCES protocols(id),
    -- Stage 3: CPV
    cpv_monitoring_plan TEXT,                     -- JSON
    cpv_annual_product_review_date DATE,
    cpv_reporting_frequency VARCHAR(50),
    -- Outcome
    validation_conclusion VARCHAR(50),
    conclusion_narrative TEXT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE process_validation_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID NOT NULL REFERENCES process_validation_studies(id),
    batch_id UUID REFERENCES batches(id),
    batch_number VARCHAR(100) NOT NULL,
    batch_sequence INT NOT NULL,
    manufacture_date DATE,
    batch_size DECIMAL(20,4),
    batch_size_unit VARCHAR(50),
    -- PPQ specific
    deviations_during_manufacture BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_ids TEXT,                          -- JSON array
    -- Results summary
    all_cpp_within_range BOOLEAN,
    all_cqa_met BOOLEAN,
    batch_result VARCHAR(50),
    -- pass | fail | conditional
    batch_conclusion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 8. STERILIZATION VALIDATION
-- F0 calculations, bioburden monitoring, SAL validation.
-- Common in sterile manufacturing, medical devices, biologics.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_steril_ref START 1;

CREATE TABLE sterilization_validation_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,        -- STER-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    sterilization_method VARCHAR(100) NOT NULL,
    -- moist_heat | dry_heat | ethylene_oxide | radiation | filtration | vaporized_h2o2
    process_name VARCHAR(512),
    equipment_id UUID REFERENCES equipment(id),
    product_or_component VARCHAR(512) NOT NULL,
    sal_target VARCHAR(50) NOT NULL DEFAULT '1e-6',
    bioburden_limit DECIMAL(20,8),
    bioburden_unit VARCHAR(50) NOT NULL DEFAULT 'CFU/item',
    regulatory_standard VARCHAR(255),
    -- ISO 11135 | ISO 11137 | ISO 17665 | USP <1211> | PDA TR#1
    -- Method-specific parameters
    method_parameters TEXT,
    -- JSON: for steam = {min_temp, exposure_time, F0_requirement}
    -- for EtO = {concentration, temperature, humidity, exposure_time}
    -- for radiation = {dose_range, dose_mapping_points}
    f0_requirement DECIMAL(10,4),                -- For moist heat
    z_value DECIMAL(10,4),                       -- Thermal death time
    d_value DECIMAL(10,4),                       -- Decimal reduction time
    -- Results
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    validation_conclusion VARCHAR(50),
    biological_indicator_organism VARCHAR(255),  -- Geobacillus stearothermophilus etc.
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    protocol_id UUID REFERENCES protocols(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE sterilization_cycle_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID NOT NULL REFERENCES sterilization_validation_studies(id),
    cycle_number INT NOT NULL,
    cycle_date DATE NOT NULL,
    cycle_type VARCHAR(50) NOT NULL,             -- validation | monitoring | production
    -- Cycle parameters (flexible JSON for method-specific data)
    cycle_parameters TEXT NOT NULL,              -- JSON
    f0_achieved DECIMAL(10,4),                   -- For moist heat
    bioburden_count DECIMAL(20,8),
    bi_result VARCHAR(50),                       -- pass | fail | not_run
    residuals_result VARCHAR(50),                -- For EtO: aeration result
    cycle_result VARCHAR(20) NOT NULL,           -- pass | fail
    notes TEXT,
    analyst_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 9. REUSABLE TEST CASE LIBRARY (KNEAT ENTITY SYSTEM)
-- Standalone, reusable test cases that can be instantiated
-- into protocols. Kneat's killer feature: write once, reuse
-- everywhere. Changes to the template propagate to linked protocols.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_test_case_ref START 1;

CREATE TABLE test_case_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_ref VARCHAR(50) UNIQUE NOT NULL,         -- TC-0001
    site_id UUID NOT NULL REFERENCES sites(id),   -- NULL = global/shared
    title VARCHAR(512) NOT NULL,
    description TEXT,
    test_category VARCHAR(100) NOT NULL DEFAULT 'functional',
    -- functional | performance | security | installation | configuration
    -- connectivity | data_integrity | backup_recovery | user_management
    -- access_control | audit_trail | report | interface | workflow
    applicable_protocol_types TEXT,              -- JSON: ["IQ","OQ","UAT"]
    applicable_system_types TEXT,                -- JSON: ["LIMS","MES","ERP"]
    regulatory_citations TEXT,                   -- JSON: ["21 CFR 11.10(e)"]
    prerequisite_description TEXT,
    acceptance_criteria TEXT NOT NULL,
    -- Versioning
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- draft | active | deprecated
    is_global BOOLEAN NOT NULL DEFAULT FALSE,    -- If true, available across all sites
    usage_count INT NOT NULL DEFAULT 0,          -- How many protocols use this
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE test_case_template_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES test_case_templates(id),
    step_number INT NOT NULL,
    action TEXT NOT NULL,
    expected_result TEXT NOT NULL,
    input_type VARCHAR(50) NOT NULL DEFAULT 'pass_fail',
    -- pass_fail | text | number | date | dropdown | table | screenshot
    input_options TEXT,                          -- JSON for dropdown/table types
    acceptance_range TEXT,                       -- For numeric inputs
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    requires_screenshot BOOLEAN NOT NULL DEFAULT FALSE,
    requires_witness BOOLEAN NOT NULL DEFAULT FALSE,
    regulatory_citation VARCHAR(255),
    sort_order INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- When a test case template is used in a protocol
CREATE TABLE test_case_usages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES test_case_templates(id),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    protocol_section_id UUID REFERENCES protocol_sections(id),
    instance_title VARCHAR(512),                 -- Override title for this instance
    instance_notes TEXT,
    template_version_at_usage VARCHAR(20),       -- Which version was used
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (template_id, protocol_id, protocol_section_id)
);

-- ============================================================
-- 10. AUDIT COLLECTIONS / WAR ROOMS
-- Approved documents staged in a read-only area for auditors.
-- Kneat Collections feature: virtual audit war rooms.
-- Inspectors see only what's in the collection, in read-only mode.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_collection_ref START 1;

CREATE TABLE audit_collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_ref VARCHAR(50) UNIQUE NOT NULL,   -- COLL-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    purpose TEXT,
    collection_type VARCHAR(50) NOT NULL DEFAULT 'inspection',
    -- inspection | audit | routine_review | regulatory_submission
    scope_description TEXT,
    agency VARCHAR(255),                          -- FDA, EMA, customer, internal
    inspection_id UUID REFERENCES inspection_records(id),
    status VARCHAR(50) NOT NULL DEFAULT 'staging',
    -- staging | active | closed | archived
    access_start_date DATE,
    access_end_date DATE,
    created_by_id UUID NOT NULL REFERENCES users(id),
    -- External auditor access
    auditor_access_code VARCHAR(255),             -- One-time access token for auditors
    auditor_names TEXT,                           -- JSON array of auditor names
    auditor_email TEXT,                           -- For sending access
    total_documents INT NOT NULL DEFAULT 0,
    view_count INT NOT NULL DEFAULT 0,
    last_accessed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE audit_collection_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES audit_collections(id),
    item_type VARCHAR(50) NOT NULL,
    -- document | protocol | execution | report | validation_summary | capa | change_request
    document_id UUID REFERENCES documents(id),
    document_version_id UUID REFERENCES document_versions(id),
    protocol_id UUID REFERENCES protocols(id),
    execution_id UUID REFERENCES test_executions(id),
    object_type VARCHAR(100),
    object_id UUID,
    title VARCHAR(512) NOT NULL,
    rationale TEXT,                              -- Why included in this collection
    is_read_only BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by UUID NOT NULL REFERENCES users(id)
);

CREATE TABLE audit_collection_access_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id UUID NOT NULL REFERENCES audit_collections(id),
    accessed_by_type VARCHAR(50) NOT NULL DEFAULT 'internal',
    -- internal (OpenVAL user) | external (auditor via access code)
    user_id UUID REFERENCES users(id),
    auditor_name VARCHAR(255),                   -- For external access
    item_id UUID REFERENCES audit_collection_items(id),
    action VARCHAR(50) NOT NULL DEFAULT 'view', -- view | download | print
    accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ip_address VARCHAR(45)
);

-- ============================================================
-- 11. VALIDATION MASTER PLAN (VMP)
-- Corporate/site-level document defining the validation program.
-- Different from individual validation plans (which cover one system).
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_vmp_ref START 1;

CREATE TABLE validation_master_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vmp_ref VARCHAR(50) UNIQUE NOT NULL,          -- VMP-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    organization_id UUID REFERENCES organizations(id),
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    scope VARCHAR(50) NOT NULL DEFAULT 'site',
    -- site | corporate | department
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- Structured content
    validation_policy TEXT,
    organizational_structure TEXT,
    -- Who does what: QA, Validation, IT, Engineering
    scope_and_exclusions TEXT,
    applicable_regulations TEXT,                  -- JSON array
    applicable_guidelines TEXT,                   -- JSON array
    validation_approach TEXT,
    -- GAMP 5 category approach, risk-based decisions
    csa_approach TEXT,                            -- CSA strategy for computer systems
    protocol_lifecycle_description TEXT,
    document_control_approach TEXT,
    change_control_approach TEXT,
    periodic_review_approach TEXT,
    -- What and how often
    training_requirements TEXT,
    supplier_qualification_approach TEXT,
    validation_lifecycle_activities TEXT,
    -- IQ/OQ/PQ descriptions
    systems_in_scope TEXT,                        -- JSON array of system IDs
    revalidation_criteria TEXT,
    -- GxP Inventory (summary table of all GxP systems)
    total_gxp_systems INT,
    systems_fully_validated INT,
    systems_in_validation INT,
    systems_requiring_validation INT,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    next_review_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE vmp_system_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vmp_id UUID NOT NULL REFERENCES validation_master_plans(id),
    system_id UUID REFERENCES systems(id),
    system_name VARCHAR(512) NOT NULL,
    gamp_category VARCHAR(10),
    validation_status VARCHAR(50) NOT NULL,
    last_validated_date DATE,
    next_review_date DATE,
    risk_level VARCHAR(20),
    notes TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

-- ============================================================
-- 12. CSA (COMPUTER SOFTWARE ASSURANCE) RECORDS
-- FDA Final Guidance Sept 24, 2025.
-- CSA Mode: risk-based, intended-use focused, less documentation.
-- Supports both traditional CSV and modern CSA approaches.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_csa_ref START 1;

CREATE TABLE csa_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_ref VARCHAR(50) UNIQUE NOT NULL,   -- CSA-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    approach VARCHAR(20) NOT NULL DEFAULT 'csa',  -- csv | csa | hybrid
    -- If hybrid, some features use CSV rigor, others use CSA risk-based
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- Intended Use Summary
    intended_use_summary TEXT NOT NULL,
    -- What the system is used for in this GxP context
    business_processes_supported TEXT NOT NULL,
    -- Which GxP processes rely on this system
    software_type VARCHAR(100) NOT NULL,
    -- infrastructure_software | non-configured_product | configured_product
    -- custom_application | automated_equipment | edms | lims | erp | mes
    gamp_category VARCHAR(10) NOT NULL,
    overall_risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    -- critical | high | medium | low
    risk_rationale TEXT NOT NULL,
    -- Assessment outcome
    assurance_activities_summary TEXT,
    -- What testing/verification was done and why
    vendor_documentation_leveraged BOOLEAN NOT NULL DEFAULT FALSE,
    vendor_testing_accepted TEXT,
    -- Description of vendor testing accepted as evidence
    unscripted_testing_used BOOLEAN NOT NULL DEFAULT FALSE,
    unscripted_testing_description TEXT,
    critical_thinking_rationale TEXT NOT NULL,
    -- The "thinking" behind the approach - CSA requirement
    -- Conclusion
    system_fit_for_purpose BOOLEAN,
    conclusion_narrative TEXT NOT NULL,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    related_validation_project_id UUID REFERENCES validation_projects(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE csa_intended_use_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES csa_assessments(id),
    feature_or_function VARCHAR(512) NOT NULL,
    -- Specific software feature being assessed
    intended_use_description TEXT NOT NULL,
    -- How this feature is actually used in the GxP process
    gxp_process_supported TEXT NOT NULL,
    failure_impact_description TEXT NOT NULL,
    -- What would happen if this feature failed
    patient_safety_impact VARCHAR(20) NOT NULL DEFAULT 'none',
    -- critical | high | medium | low | none
    product_quality_impact VARCHAR(20) NOT NULL DEFAULT 'none',
    data_integrity_impact VARCHAR(20) NOT NULL DEFAULT 'none',
    overall_risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    assurance_approach VARCHAR(100) NOT NULL DEFAULT 'scripted_testing',
    -- no_testing_required | vendor_documentation | unscripted_testing
    -- scripted_testing | automated_testing | peer_review
    assurance_rationale TEXT NOT NULL,           -- Why this approach is appropriate
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE csa_assurance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES csa_assessments(id),
    intended_use_item_id UUID REFERENCES csa_intended_use_items(id),
    activity_type VARCHAR(100) NOT NULL,
    -- scripted_test | unscripted_exploration | peer_review | vendor_doc_review
    -- automated_test | configuration_review | system_log_review | audit_trail_review
    activity_description TEXT NOT NULL,
    activity_date DATE,
    performed_by UUID REFERENCES users(id),
    evidence_description TEXT NOT NULL,
    -- What evidence was captured
    issues_found BOOLEAN NOT NULL DEFAULT FALSE,
    issues_description TEXT,
    issues_resolution TEXT,
    result VARCHAR(20) NOT NULL DEFAULT 'satisfactory',
    -- satisfactory | unsatisfactory | conditional
    linked_protocol_id UUID REFERENCES protocols(id),
    linked_execution_id UUID REFERENCES test_executions(id),
    file_id UUID REFERENCES file_store(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 13. DOCUMENT ANNOTATION AND REDLINING
-- Inline comments, highlights, and redlines during document
-- review. Critical for collaborative authoring and review.
-- Replaces printing-redlining-scanning cycle entirely.
-- ============================================================

CREATE TABLE document_annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    document_version_id UUID NOT NULL REFERENCES document_versions(id),
    section_id UUID REFERENCES document_sections(id),
    annotation_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    -- comment | redline | highlight | question | approval_note | rejection_note
    selected_text TEXT,                          -- The text that was highlighted/selected
    text_position_start INT,                     -- Character position in section content
    text_position_end INT,
    annotation_text TEXT NOT NULL,               -- The actual comment/redline content
    redline_replacement TEXT,                    -- For redlines: the proposed replacement text
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_action VARCHAR(50),
    -- accepted | rejected | noted | superseded
    resolution_note TEXT,
    author_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE annotation_replies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    annotation_id UUID NOT NULL REFERENCES document_annotations(id),
    reply_text TEXT NOT NULL,
    author_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Protocol step annotations (separate from document annotations)
CREATE TABLE protocol_step_annotations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    step_id UUID NOT NULL REFERENCES protocol_steps(id),
    annotation_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    annotation_text TEXT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    author_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 14. VALIDATION DEBT TRACKER
-- Track the "debt" of unvalidated or under-validated systems.
-- SWARE's concept: surface hidden validation backlog risk.
-- ============================================================

CREATE TABLE validation_debt_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    debt_type VARCHAR(100) NOT NULL,
    -- never_validated | overdue_periodic_review | expired_validation
    -- change_without_impact_assessment | missing_urs | missing_risk_assessment
    -- partial_validation | documentation_gap | outdated_protocol
    -- vendor_qualification_expired | training_gap
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'medium',
    -- critical | high | medium | low
    regulatory_risk VARCHAR(20) NOT NULL DEFAULT 'medium',
    -- What's the risk at next inspection
    age_days INT,                                -- How long this has been open
    estimated_effort_hours DECIMAL(10,2),
    estimated_cost DECIMAL(15,2),
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    -- open | in_progress | resolved | accepted_risk | waived
    resolution_plan TEXT,
    target_resolution_date DATE,
    resolved_at TIMESTAMPTZ,
    resolved_by UUID REFERENCES users(id),
    linked_validation_project_id UUID REFERENCES validation_projects(id),
    auto_detected BOOLEAN NOT NULL DEFAULT FALSE,
    -- If true, detected by the system automatically
    detection_rule VARCHAR(255),                 -- Which rule detected it
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 15. QUALITY BY DESIGN (QbD) FRAMEWORK
-- ICH Q8/Q9/Q10. Links QbD studies to validation activities.
-- Design Space, Control Strategy, and PAT integration.
-- ValGenesis iRisk equivalent.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_qbd_ref START 1;

CREATE TABLE qbd_studies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,        -- QBD-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    process_step VARCHAR(255),
    study_type VARCHAR(100) NOT NULL DEFAULT 'product_development',
    -- product_development | process_development | design_space_definition
    -- design_space_verification | continuous_improvement
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    -- Quality Target Product Profile (QTPP)
    qtpp_description TEXT NOT NULL,
    patient_safety_focus TEXT,
    target_indication VARCHAR(512),
    dosage_form VARCHAR(100),
    -- Design Space
    design_space_description TEXT,
    normal_operating_range TEXT,                  -- JSON
    proven_acceptable_range TEXT,                 -- JSON
    -- Control Strategy
    control_strategy_description TEXT,
    pat_tools TEXT,                               -- JSON: Process Analytical Technology
    risk_assessment_id UUID REFERENCES risk_assessments(id),
    process_validation_id UUID REFERENCES process_validation_studies(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 16. INDEXES FOR ALL NEW TABLES (PART 7)
-- ============================================================

CREATE INDEX idx_electronic_logbooks_site ON electronic_logbooks (site_id, status);
CREATE INDEX idx_logbook_entries_logbook ON logbook_entries (logbook_id);
CREATE INDEX idx_logbook_entries_date ON logbook_entries (entry_date DESC);
CREATE INDEX idx_logbook_entries_correction ON logbook_entries (is_correction, corrects_entry_id);

CREATE INDEX idx_drawings_site ON drawings (site_id, status);
CREATE INDEX idx_drawings_system ON drawings (linked_system_id);
CREATE INDEX idx_drawings_equipment ON drawings (linked_equipment_id);
CREATE INDEX idx_drawing_walkdowns_drawing ON drawing_walkdowns (drawing_id);

CREATE INDEX idx_tech_transfers_site ON technology_transfers (site_id, status);
CREATE INDEX idx_tech_transfer_items ON technology_transfer_items (transfer_id);

CREATE INDEX idx_cleaning_studies_site ON cleaning_validation_studies (site_id, status);
CREATE INDEX idx_cleaning_results_study ON cleaning_validation_results (study_id, run_number);

CREATE INDEX idx_thermal_studies_site ON thermal_mapping_studies (site_id, status);
CREATE INDEX idx_thermal_data_study ON thermal_mapping_data (study_id, sensor_id, recorded_at DESC);
CREATE INDEX idx_cold_chain_excursions ON cold_chain_excursions (site_id, status);

CREATE INDEX idx_commissioning_packages_project ON commissioning_packages (project_id, status);
CREATE INDEX idx_commissioning_items_package ON commissioning_package_items (package_id);
CREATE INDEX idx_punch_items_package ON punch_items (package_id, status);
CREATE INDEX idx_punch_items_category ON punch_items (category, status);

CREATE INDEX idx_pv_studies_site ON process_validation_studies (site_id, stage, status);
CREATE INDEX idx_pv_batches_study ON process_validation_batches (study_id);

CREATE INDEX idx_steril_studies_site ON sterilization_validation_studies (site_id, status);
CREATE INDEX idx_steril_cycles_study ON sterilization_cycle_records (study_id);

CREATE INDEX idx_test_case_templates_site ON test_case_templates (site_id, status);
CREATE INDEX idx_test_case_template_steps ON test_case_template_steps (template_id, sort_order);
CREATE INDEX idx_test_case_usages_template ON test_case_usages (template_id);
CREATE INDEX idx_test_case_usages_protocol ON test_case_usages (protocol_id);

CREATE INDEX idx_audit_collections_site ON audit_collections (site_id, status);
CREATE INDEX idx_audit_collection_items ON audit_collection_items (collection_id);
CREATE INDEX idx_audit_collection_access ON audit_collection_access_log (collection_id, accessed_at DESC);

CREATE INDEX idx_vmp_site ON validation_master_plans (site_id, status);
CREATE INDEX idx_vmp_system_entries ON vmp_system_entries (vmp_id);

CREATE INDEX idx_csa_assessments_system ON csa_assessments (system_id, status);
CREATE INDEX idx_csa_intended_use_items ON csa_intended_use_items (assessment_id);
CREATE INDEX idx_csa_assurance_records ON csa_assurance_records (assessment_id);

CREATE INDEX idx_doc_annotations_document ON document_annotations (document_id, document_version_id);
CREATE INDEX idx_doc_annotations_resolved ON document_annotations (is_resolved, author_id);
CREATE INDEX idx_annotation_replies ON annotation_replies (annotation_id);
CREATE INDEX idx_protocol_step_annotations ON protocol_step_annotations (protocol_id, step_id);

CREATE INDEX idx_validation_debt_site ON validation_debt_items (site_id, status, severity);
CREATE INDEX idx_validation_debt_system ON validation_debt_items (system_id);

CREATE INDEX idx_qbd_studies_site ON qbd_studies (site_id, status);

-- ============================================================
-- SEQUENCES
-- ============================================================
CREATE SEQUENCE IF NOT EXISTS seq_logbook_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_logbook_entry_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_drawing_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_walkdown_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_tt_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_cleaning_study_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_thermal_study_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_cqv_package_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_punch_item_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_pv_study_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_steril_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_test_case_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_collection_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_vmp_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_csa_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_qbd_ref START 1;

-- ============================================================
-- FINAL TABLE COUNT (PARTS 1-7)
-- ============================================================
SELECT
    COUNT(*) AS total_tables,
    'All tables across Parts 1-7' AS note
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
