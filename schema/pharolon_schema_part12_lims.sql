-- ============================================================
-- PHAROLON Schema Part 12 — Native LIMS
-- Laboratory Information Management System
-- Targeting all levels of pharma: small biotech → large enterprise
-- Integrates natively with Validation Suite (same DB = JOINs not APIs)
-- ============================================================
-- Tables: ~120
-- Regulatory: 21 CFR 211.68/84/160/165/173/192, EU GMP Annex 11,
--             ICH Q2R1/Q3A/Q6A/Q6B, USP <1058>, EP 2.2.x
-- ============================================================

-- ─────────────────────────────────────────
-- 12.01  SAMPLE TYPES & MATRICES
-- ─────────────────────────────────────────
CREATE TABLE lims_sample_matrices (
    id                  VARCHAR(36)  PRIMARY KEY,
    code                VARCHAR(20)  UNIQUE NOT NULL,
    name                VARCHAR(100) NOT NULL,
    category            VARCHAR(50)  NOT NULL, -- api|excipient|finished_product|intermediate|raw_material|environmental|water|microbiological|clinical|stability
    requires_chain      BOOLEAN      DEFAULT TRUE,
    default_storage     VARCHAR(50),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_container_types (
    id                  VARCHAR(36)  PRIMARY KEY,
    name                VARCHAR(100) NOT NULL,
    material            VARCHAR(50),  -- glass|hdpe|pp|ss316|amber_glass
    volume_ml           NUMERIC(10,3),
    closure_type        VARCHAR(50),
    light_sensitive     BOOLEAN      DEFAULT FALSE,
    temperature_min_c   NUMERIC(5,1),
    temperature_max_c   NUMERIC(5,1),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.02  SAMPLE REGISTRATION & CHAIN OF CUSTODY
-- ─────────────────────────────────────────
CREATE TABLE lims_samples (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_number       VARCHAR(50)  UNIQUE NOT NULL,
    barcode             VARCHAR(100) UNIQUE,
    matrix_id           VARCHAR(36)  REFERENCES lims_sample_matrices(id),
    description         VARCHAR(500),
    source_type         VARCHAR(50)  NOT NULL, -- batch|stability_pull|environmental|clinical|supplier|in_process|water
    source_reference    VARCHAR(100), -- batch number, stability study ID, etc
    product_id          VARCHAR(36),  -- FK to products table
    supplier_id         VARCHAR(36),
    lot_number          VARCHAR(100),
    expiry_date         DATE,
    received_date       TIMESTAMPTZ,
    received_by         VARCHAR(36),
    quantity_received   NUMERIC(12,4),
    quantity_unit       VARCHAR(20),
    quantity_remaining  NUMERIC(12,4),
    storage_location_id VARCHAR(36),
    storage_temp_c      NUMERIC(5,1),
    status              VARCHAR(30)  DEFAULT 'received', -- received|logged|in_testing|tested|retained|disposed|rejected
    priority            VARCHAR(20)  DEFAULT 'routine', -- routine|urgent|stat
    requested_by        VARCHAR(36),
    site_id             VARCHAR(36),
    workspace_id        VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE lims_sample_aliquots (
    id                  VARCHAR(36)  PRIMARY KEY,
    parent_sample_id    VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    aliquot_number      VARCHAR(50)  UNIQUE NOT NULL,
    barcode             VARCHAR(100) UNIQUE,
    container_type_id   VARCHAR(36)  REFERENCES lims_container_types(id),
    volume_ml           NUMERIC(10,3),
    mass_g              NUMERIC(10,4),
    status              VARCHAR(30)  DEFAULT 'available',
    storage_location_id VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE lims_sample_login_batches (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_number        VARCHAR(50)  UNIQUE NOT NULL,
    login_date          TIMESTAMPTZ  NOT NULL,
    logged_by           VARCHAR(36)  NOT NULL,
    sample_count        INTEGER,
    source_type         VARCHAR(50),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_sample_login_batch_items (
    id                  VARCHAR(36)  PRIMARY KEY,
    login_batch_id      VARCHAR(36)  NOT NULL REFERENCES lims_sample_login_batches(id),
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    sequence_number     INTEGER
);

CREATE TABLE lims_chain_of_custody (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    event_type          VARCHAR(50)  NOT NULL, -- received|transferred|aliquoted|stored|retrieved|tested|retained|disposed|shipped
    from_location       VARCHAR(200),
    to_location         VARCHAR(200),
    from_person         VARCHAR(36),
    to_person           VARCHAR(36),
    event_timestamp     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    temperature_c       NUMERIC(5,1),
    condition           VARCHAR(50),  -- intact|damaged|compromised
    notes               TEXT,
    signature_id        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_storage_locations (
    id                  VARCHAR(36)  PRIMARY KEY,
    location_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    location_type       VARCHAR(50)  NOT NULL, -- freezer|refrigerator|ambient|incubator|stability_chamber|vault
    temperature_setpoint_c  NUMERIC(5,1),
    temperature_min_c   NUMERIC(5,1),
    temperature_max_c   NUMERIC(5,1),
    humidity_setpoint_pct   NUMERIC(5,1),
    site_id             VARCHAR(36),
    room_id             VARCHAR(36),
    parent_location_id  VARCHAR(36)  REFERENCES lims_storage_locations(id), -- freezer → shelf → rack → position
    capacity            INTEGER,
    current_occupancy   INTEGER      DEFAULT 0,
    monitored           BOOLEAN      DEFAULT TRUE,
    monitoring_system   VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_sample_disposal (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    disposal_method     VARCHAR(100) NOT NULL, -- incineration|chemical_neutralisation|sewer|return_to_supplier|archive
    disposal_date       DATE         NOT NULL,
    disposed_by         VARCHAR(36)  NOT NULL,
    approved_by         VARCHAR(36),
    quantity_disposed   NUMERIC(12,4),
    unit                VARCHAR(20),
    waste_category      VARCHAR(50),
    disposal_company    VARCHAR(200),
    manifest_number     VARCHAR(100),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.03  SPECIFICATIONS & LIMITS
-- ─────────────────────────────────────────
CREATE TABLE lims_specifications (
    id                  VARCHAR(36)  PRIMARY KEY,
    spec_number         VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    version             VARCHAR(20)  NOT NULL DEFAULT '1.0',
    status              VARCHAR(30)  DEFAULT 'draft', -- draft|approved|superseded|obsolete
    spec_type           VARCHAR(50)  NOT NULL, -- release|in_process|stability|raw_material|excipient|packaging|water|environmental
    product_id          VARCHAR(36),
    material_code       VARCHAR(100),
    compendial_ref      VARCHAR(200), -- USP <xxx>, EP x.x.x, JP
    pharmacopoeial_version VARCHAR(50),
    effective_date      DATE,
    review_date         DATE,
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE lims_specification_tests (
    id                  VARCHAR(36)  PRIMARY KEY,
    specification_id    VARCHAR(36)  NOT NULL REFERENCES lims_specifications(id),
    test_method_id      VARCHAR(36),
    test_name           VARCHAR(200) NOT NULL,
    sequence_number     INTEGER,
    test_category       VARCHAR(50), -- identification|assay|related_substances|dissolution|microbiology|physical|appearance
    is_mandatory        BOOLEAN      DEFAULT TRUE,
    limit_type          VARCHAR(30)  NOT NULL, -- nmt|nlt|range|exact|report|conforms|passes
    limit_lower         NUMERIC(15,6),
    limit_upper         NUMERIC(15,6),
    limit_exact         NUMERIC(15,6),
    unit                VARCHAR(50),
    limit_description   TEXT,        -- e.g. "White to off-white crystalline powder"
    action_limit_lower  NUMERIC(15,6),
    action_limit_upper  NUMERIC(15,6),
    alert_limit_lower   NUMERIC(15,6),
    alert_limit_upper   NUMERIC(15,6),
    significant_figures INTEGER,
    rounding_rule       VARCHAR(50),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_compendial_methods (
    id                  VARCHAR(36)  PRIMARY KEY,
    pharmacopoeia       VARCHAR(20)  NOT NULL, -- USP|EP|JP|BP|IP|ChP
    chapter_number      VARCHAR(50),
    chapter_title       VARCHAR(200),
    edition             VARCHAR(50),
    effective_date      DATE,
    method_type         VARCHAR(50),
    description         TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.04  TEST METHODS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_methods (
    id                  VARCHAR(36)  PRIMARY KEY,
    method_number       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    version             VARCHAR(20)  NOT NULL DEFAULT '1.0',
    status              VARCHAR(30)  DEFAULT 'draft',
    method_type         VARCHAR(50)  NOT NULL, -- hplc|gc|titrimetry|uv_vis|ftir|karl_fischer|dissolution|microbiological|pharmacopoeial|gravimetric|wet_chemistry|atomic_absorption|nmr|ms|lal|particle_size|viscosity|osmolality|ph|conductivity
    compendial_ref      VARCHAR(200),
    compendial_method_id VARCHAR(36) REFERENCES lims_compendial_methods(id),
    instrument_type     VARCHAR(100),
    validation_status   VARCHAR(30)  DEFAULT 'not_validated', -- not_validated|validated|transferred|revalidation_required
    validation_protocol_id VARCHAR(36), -- links to validation suite
    validation_report_id   VARCHAR(36),
    run_time_min        NUMERIC(8,2),
    sample_prep_time_min NUMERIC(8,2),
    detection_limit     NUMERIC(15,8),
    quantitation_limit  NUMERIC(15,8),
    linearity_range_low NUMERIC(15,6),
    linearity_range_high NUMERIC(15,6),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE lims_test_method_versions (
    id                  VARCHAR(36)  PRIMARY KEY,
    method_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_methods(id),
    version             VARCHAR(20)  NOT NULL,
    change_summary      TEXT,
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    effective_date      DATE,
    obsolete_date       DATE,
    document_ref        VARCHAR(200),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_method_parameters (
    id                  VARCHAR(36)  PRIMARY KEY,
    method_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_methods(id),
    parameter_name      VARCHAR(100) NOT NULL,
    parameter_value     VARCHAR(200),
    unit                VARCHAR(50),
    is_critical         BOOLEAN      DEFAULT FALSE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.05  TEST REQUESTS & ASSIGNMENTS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_requests (
    id                  VARCHAR(36)  PRIMARY KEY,
    request_number      VARCHAR(50)  UNIQUE NOT NULL,
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    specification_id    VARCHAR(36)  REFERENCES lims_specifications(id),
    request_type        VARCHAR(50)  NOT NULL, -- release|stability|in_process|environmental|method_validation|reference_check|investigation|repeat
    requested_by        VARCHAR(36)  NOT NULL,
    requested_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    required_by         TIMESTAMPTZ,
    priority            VARCHAR(20)  DEFAULT 'routine',
    status              VARCHAR(30)  DEFAULT 'pending', -- pending|in_progress|complete|cancelled|on_hold
    completed_at        TIMESTAMPTZ,
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_request_items (
    id                  VARCHAR(36)  PRIMARY KEY,
    request_id          VARCHAR(36)  NOT NULL REFERENCES lims_test_requests(id),
    spec_test_id        VARCHAR(36)  REFERENCES lims_specification_tests(id),
    method_id           VARCHAR(36)  REFERENCES lims_test_methods(id),
    test_name           VARCHAR(200) NOT NULL,
    status              VARCHAR(30)  DEFAULT 'pending',
    assigned_to         VARCHAR(36),
    assigned_at         TIMESTAMPTZ,
    instrument_id       VARCHAR(36),
    sequence_number     INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_assignments (
    id                  VARCHAR(36)  PRIMARY KEY,
    request_item_id     VARCHAR(36)  NOT NULL REFERENCES lims_test_request_items(id),
    analyst_id          VARCHAR(36)  NOT NULL,
    instrument_id       VARCHAR(36),
    scheduled_start     TIMESTAMPTZ,
    scheduled_end       TIMESTAMPTZ,
    actual_start        TIMESTAMPTZ,
    actual_end          TIMESTAMPTZ,
    status              VARCHAR(30)  DEFAULT 'assigned',
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.06  TEST RESULTS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_number       VARCHAR(50)  UNIQUE NOT NULL,
    request_item_id     VARCHAR(36)  NOT NULL REFERENCES lims_test_request_items(id),
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    method_id           VARCHAR(36)  REFERENCES lims_test_methods(id),
    analyst_id          VARCHAR(36)  NOT NULL,
    instrument_id       VARCHAR(36),
    test_date           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    result_type         VARCHAR(30)  NOT NULL, -- numeric|text|pass_fail|conforms|count
    result_numeric      NUMERIC(20,8),
    result_text         VARCHAR(500),
    result_pass_fail    BOOLEAN,
    unit                VARCHAR(50),
    judgement           VARCHAR(20)  NOT NULL DEFAULT 'pending', -- pass|fail|oot|atypical|invalid|pending
    out_of_spec         BOOLEAN      DEFAULT FALSE,
    out_of_trend        BOOLEAN      DEFAULT FALSE,
    reviewed_by         VARCHAR(36),
    reviewed_at         TIMESTAMPTZ,
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    invalidated         BOOLEAN      DEFAULT FALSE,
    invalidation_reason TEXT,
    retest_of_id        VARCHAR(36)  REFERENCES lims_test_results(id),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_result_data_points (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    replicate_number    INTEGER      NOT NULL,
    data_point_label    VARCHAR(100),
    value               NUMERIC(20,8),
    unit                VARCHAR(50),
    is_outlier          BOOLEAN      DEFAULT FALSE,
    outlier_reason      TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_result_attachments (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    file_type           VARCHAR(50)  NOT NULL, -- chromatogram|spectrum|image|calculation_sheet|sequence_file|raw_data
    file_name           VARCHAR(500) NOT NULL,
    file_path           VARCHAR(1000),
    file_size_bytes     BIGINT,
    checksum_sha256     VARCHAR(64),
    uploaded_by         VARCHAR(36),
    uploaded_at         TIMESTAMPTZ  DEFAULT NOW(),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_calculations (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    calculation_name    VARCHAR(200) NOT NULL,
    formula             TEXT,
    inputs              TEXT,        -- JSON: {factor: 1.0256, dilution: 10, ...}
    calculated_value    NUMERIC(20,8),
    unit                VARCHAR(50),
    calculation_order   INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_worksheets (
    id                  VARCHAR(36)  PRIMARY KEY,
    worksheet_number    VARCHAR(50)  UNIQUE NOT NULL,
    method_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_methods(id),
    analyst_id          VARCHAR(36)  NOT NULL,
    test_date           DATE         NOT NULL,
    instrument_id       VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'open', -- open|complete|reviewed|approved
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_test_worksheet_items (
    id                  VARCHAR(36)  PRIMARY KEY,
    worksheet_id        VARCHAR(36)  NOT NULL REFERENCES lims_test_worksheets(id),
    result_id           VARCHAR(36)  REFERENCES lims_test_results(id),
    sample_id           VARCHAR(36)  REFERENCES lims_samples(id),
    sequence_position   INTEGER,
    sample_type         VARCHAR(30), -- sample|standard|blank|spiked|qc_check
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.07  OOS / OOT INVESTIGATION
-- Full 21 CFR 211.192 two-phase workflow
-- ─────────────────────────────────────────
CREATE TABLE lims_oos_investigations (
    id                  VARCHAR(36)  PRIMARY KEY,
    oos_number          VARCHAR(50)  UNIQUE NOT NULL,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    investigation_type  VARCHAR(20)  NOT NULL DEFAULT 'oos', -- oos|oot|atypical
    initiated_by        VARCHAR(36)  NOT NULL,
    initiated_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    phase               VARCHAR(20)  DEFAULT 'phase_1', -- phase_1|phase_2|closed|invalidated
    status              VARCHAR(30)  DEFAULT 'open', -- open|phase_1_complete|phase_2_open|closed|invalidated
    phase1_conclusion   VARCHAR(50), -- laboratory_error|instrument_error|no_assignable_cause|confirmed_oos
    phase1_completed_by VARCHAR(36),
    phase1_completed_at TIMESTAMPTZ,
    phase2_triggered    BOOLEAN      DEFAULT FALSE,
    phase2_conclusion   VARCHAR(50), -- process_error|raw_material|batch_failure|unexplained
    phase2_completed_by VARCHAR(36),
    phase2_completed_at TIMESTAMPTZ,
    final_disposition   VARCHAR(50), -- retest|reject|rework|additional_testing|release|invalidated
    batch_impact        BOOLEAN,
    batch_impact_detail TEXT,
    capa_required       BOOLEAN      DEFAULT FALSE,
    capa_id             VARCHAR(36), -- links to QMS CAPA
    closed_by           VARCHAR(36),
    closed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_oos_investigation_steps (
    id                  VARCHAR(36)  PRIMARY KEY,
    investigation_id    VARCHAR(36)  NOT NULL REFERENCES lims_oos_investigations(id),
    phase               VARCHAR(20)  NOT NULL,
    step_number         INTEGER      NOT NULL,
    step_name           VARCHAR(200) NOT NULL,
    step_description    TEXT,
    completed_by        VARCHAR(36),
    completed_at        TIMESTAMPTZ,
    outcome             TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_oos_retest_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    investigation_id    VARCHAR(36)  NOT NULL REFERENCES lims_oos_investigations(id),
    retest_result_id    VARCHAR(36)  REFERENCES lims_test_results(id),
    retest_type         VARCHAR(50), -- same_analyst|different_analyst|different_instrument|different_aliquot
    retest_number       INTEGER,
    retest_result       VARCHAR(20), -- pass|fail|oos_confirmed
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_oot_trend_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_id           VARCHAR(36)  REFERENCES lims_samples(id),
    spec_test_id        VARCHAR(36)  REFERENCES lims_specification_tests(id),
    trending_method     VARCHAR(50)  NOT NULL, -- linear_regression|ewma|cusum|shewhart
    trend_start_date    DATE,
    trend_end_date      DATE,
    data_points_count   INTEGER,
    trend_detected      BOOLEAN      DEFAULT FALSE,
    trend_direction     VARCHAR(20), -- increasing|decreasing|cyclic
    slope               NUMERIC(15,8),
    r_squared           NUMERIC(8,6),
    investigation_triggered BOOLEAN  DEFAULT FALSE,
    investigation_id    VARCHAR(36)  REFERENCES lims_oos_investigations(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.08  REFERENCE STANDARDS
-- ─────────────────────────────────────────
CREATE TABLE lims_reference_standards (
    id                  VARCHAR(36)  PRIMARY KEY,
    standard_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    standard_type       VARCHAR(50)  NOT NULL, -- primary|secondary|working|in_house|crs|bpcrs|usp_rs
    supplier            VARCHAR(200),
    catalogue_number    VARCHAR(100),
    potency_pct         NUMERIC(8,4),
    potency_unit        VARCHAR(50),
    cas_number          VARCHAR(50),
    molecular_weight    NUMERIC(10,4),
    storage_conditions  VARCHAR(200),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_reference_standard_lots (
    id                  VARCHAR(36)  PRIMARY KEY,
    standard_id         VARCHAR(36)  NOT NULL REFERENCES lims_reference_standards(id),
    lot_number          VARCHAR(100) NOT NULL,
    quantity_received   NUMERIC(12,4),
    quantity_unit       VARCHAR(20),
    quantity_remaining  NUMERIC(12,4),
    received_date       DATE,
    expiry_date         DATE,
    certificate_of_analysis TEXT,
    status              VARCHAR(30)  DEFAULT 'quarantine', -- quarantine|approved|in_use|exhausted|expired|rejected
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    storage_location_id VARCHAR(36)  REFERENCES lims_storage_locations(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_reference_standard_usages (
    id                  VARCHAR(36)  PRIMARY KEY,
    lot_id              VARCHAR(36)  NOT NULL REFERENCES lims_reference_standard_lots(id),
    result_id           VARCHAR(36)  REFERENCES lims_test_results(id),
    worksheet_id        VARCHAR(36)  REFERENCES lims_test_worksheets(id),
    quantity_used       NUMERIC(12,4),
    unit                VARCHAR(20),
    used_by             VARCHAR(36),
    used_at             TIMESTAMPTZ  DEFAULT NOW(),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.09  STABILITY STUDIES (ICH Q1A-Q1E)
-- ─────────────────────────────────────────
CREATE TABLE lims_stability_conditions (
    id                  VARCHAR(36)  PRIMARY KEY,
    condition_code      VARCHAR(30)  UNIQUE NOT NULL,
    name                VARCHAR(100) NOT NULL,
    temperature_c       NUMERIC(5,1) NOT NULL,
    rh_pct              NUMERIC(5,1),
    light_lux           NUMERIC(8,1),
    uv_watts_m2         NUMERIC(8,3),
    study_type          VARCHAR(50)  NOT NULL, -- long_term|accelerated|intermediate|stress|photostability|freeze_thaw
    ich_zone            VARCHAR(10), -- I|II|III|IV|IVa|IVb
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_chambers (
    id                  VARCHAR(36)  PRIMARY KEY,
    chamber_code        VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    manufacturer        VARCHAR(200),
    model               VARCHAR(100),
    serial_number       VARCHAR(100),
    condition_id        VARCHAR(36)  REFERENCES lims_stability_conditions(id),
    capacity_units      INTEGER,
    temperature_setpoint NUMERIC(5,1),
    rh_setpoint         NUMERIC(5,1),
    calibration_due     DATE,
    qualification_status VARCHAR(30) DEFAULT 'qualified',
    site_id             VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_studies (
    id                  VARCHAR(36)  PRIMARY KEY,
    study_number        VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    study_type          VARCHAR(50)  NOT NULL, -- formal|ongoing|commitment|bracketing|matrixing
    product_id          VARCHAR(36),
    batch_numbers       TEXT,
    study_purpose       TEXT,
    protocol_id         VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'planned', -- planned|active|paused|complete|cancelled
    start_date          DATE,
    planned_end_date    DATE,
    actual_end_date     DATE,
    retest_period_months INTEGER,
    shelf_life_months   INTEGER,
    storage_statement   VARCHAR(500),
    created_by          VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_conditions_map (
    id                  VARCHAR(36)  PRIMARY KEY,
    study_id            VARCHAR(36)  NOT NULL REFERENCES lims_stability_studies(id),
    condition_id        VARCHAR(36)  NOT NULL REFERENCES lims_stability_conditions(id),
    chamber_id          VARCHAR(36)  REFERENCES lims_stability_chambers(id),
    planned_timepoints  TEXT,        -- JSON array: [0,1,3,6,9,12,18,24,36]
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_timepoints (
    id                  VARCHAR(36)  PRIMARY KEY,
    study_id            VARCHAR(36)  NOT NULL REFERENCES lims_stability_studies(id),
    condition_id        VARCHAR(36)  NOT NULL REFERENCES lims_stability_conditions(id),
    timepoint_months    NUMERIC(5,1) NOT NULL,
    planned_date        DATE,
    pull_window_days    INTEGER      DEFAULT 7,
    actual_pull_date    DATE,
    status              VARCHAR(30)  DEFAULT 'planned', -- planned|samples_pulled|testing|complete|missed
    pulled_by           VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_samples (
    id                  VARCHAR(36)  PRIMARY KEY,
    timepoint_id        VARCHAR(36)  NOT NULL REFERENCES lims_stability_timepoints(id),
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    sample_position     VARCHAR(50), -- chamber shelf/rack position
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    timepoint_id        VARCHAR(36)  NOT NULL REFERENCES lims_stability_timepoints(id),
    sample_id           VARCHAR(36)  NOT NULL REFERENCES lims_samples(id),
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    spec_test_id        VARCHAR(36)  REFERENCES lims_specification_tests(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_stability_trending (
    id                  VARCHAR(36)  PRIMARY KEY,
    study_id            VARCHAR(36)  NOT NULL REFERENCES lims_stability_studies(id),
    condition_id        VARCHAR(36)  NOT NULL REFERENCES lims_stability_conditions(id),
    spec_test_id        VARCHAR(36)  NOT NULL REFERENCES lims_specification_tests(id),
    analysis_date       DATE,
    regression_type     VARCHAR(30)  NOT NULL, -- linear|quadratic|cubic
    slope               NUMERIC(15,8),
    intercept           NUMERIC(15,8),
    r_squared           NUMERIC(8,6),
    predicted_shelf_life_months NUMERIC(8,2),
    confidence_level    NUMERIC(5,2) DEFAULT 95.0,
    ich_q1e_compliant   BOOLEAN      DEFAULT TRUE,
    analyst_id          VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.10  ENVIRONMENTAL MONITORING
-- EU GMP Grade A/B/C/D + ISO 5-8
-- ─────────────────────────────────────────
CREATE TABLE lims_cleanroom_classifications (
    id                  VARCHAR(36)  PRIMARY KEY,
    code                VARCHAR(20)  UNIQUE NOT NULL,
    eu_gmp_grade        VARCHAR(5),  -- A|B|C|D
    iso_class           INTEGER,     -- 5|6|7|8
    at_rest_limit_cfu_m3   NUMERIC(10,2),
    in_operation_limit_cfu_m3 NUMERIC(10,2),
    particle_0_5um_at_rest NUMERIC(15,0),
    particle_0_5um_in_op   NUMERIC(15,0),
    particle_5um_at_rest   NUMERIC(15,0),
    particle_5um_in_op     NUMERIC(15,0),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_programs (
    id                  VARCHAR(36)  PRIMARY KEY,
    program_code        VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    classification_id   VARCHAR(36)  REFERENCES lims_cleanroom_classifications(id),
    site_id             VARCHAR(36),
    room_id             VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'active',
    review_frequency    VARCHAR(30), -- monthly|quarterly|annually
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_locations (
    id                  VARCHAR(36)  PRIMARY KEY,
    location_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    program_id          VARCHAR(36)  NOT NULL REFERENCES lims_em_programs(id),
    location_type       VARCHAR(50)  NOT NULL, -- settle_plate|active_air|surface_contact|surface_swab|glove_print|personnel|particle_counter|water
    classification_id   VARCHAR(36)  REFERENCES lims_cleanroom_classifications(id),
    coordinates_x       NUMERIC(8,2),
    coordinates_y       NUMERIC(8,2),
    coordinates_z       NUMERIC(8,2),
    sampling_frequency  VARCHAR(30)  NOT NULL, -- per_shift|daily|weekly|monthly
    is_critical         BOOLEAN      DEFAULT FALSE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_limits (
    id                  VARCHAR(36)  PRIMARY KEY,
    classification_id   VARCHAR(36)  NOT NULL REFERENCES lims_cleanroom_classifications(id),
    sample_type         VARCHAR(50)  NOT NULL, -- settle_plate|active_air|surface_contact|glove_print|personnel
    alert_limit_cfu     NUMERIC(8,2),
    action_limit_cfu    NUMERIC(8,2),
    specification_limit_cfu NUMERIC(8,2),
    exposure_time_min   NUMERIC(8,2),
    volume_l            NUMERIC(8,2),
    plate_diameter_mm   NUMERIC(6,1),
    media_type          VARCHAR(100),
    incubation_temp_c   NUMERIC(5,1),
    incubation_days     INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_samples (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_number       VARCHAR(50)  UNIQUE NOT NULL,
    location_id         VARCHAR(36)  NOT NULL REFERENCES lims_em_locations(id),
    program_id          VARCHAR(36)  NOT NULL REFERENCES lims_em_programs(id),
    sample_type         VARCHAR(50)  NOT NULL,
    monitoring_session  VARCHAR(50),  -- at_rest|in_operation
    sample_date         TIMESTAMPTZ  NOT NULL,
    sampled_by          VARCHAR(36)  NOT NULL,
    media_lot           VARCHAR(100),
    media_expiry        DATE,
    plate_number        VARCHAR(50),
    incubation_start    TIMESTAMPTZ,
    incubation_end      TIMESTAMPTZ,
    incubation_temp_c   NUMERIC(5,1),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    em_sample_id        VARCHAR(36)  NOT NULL REFERENCES lims_em_samples(id),
    colony_count        INTEGER,
    cfu_m3              NUMERIC(10,2),
    cfu_per_plate       NUMERIC(8,2),
    result_type         VARCHAR(20)  DEFAULT 'numeric', -- numeric|tntc|no_growth|void
    tntc                BOOLEAN      DEFAULT FALSE,     -- too numerous to count
    no_growth           BOOLEAN      DEFAULT FALSE,
    alert_exceeded      BOOLEAN      DEFAULT FALSE,
    action_exceeded     BOOLEAN      DEFAULT FALSE,
    spec_exceeded       BOOLEAN      DEFAULT FALSE,
    read_by             VARCHAR(36)  NOT NULL,
    read_at             TIMESTAMPTZ  NOT NULL,
    reviewed_by         VARCHAR(36),
    reviewed_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_organisms (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_em_results(id),
    organism_name       VARCHAR(200),
    identification_method VARCHAR(50), -- maldi_tof|api|morphology|16s_rrna|vitek
    gram_stain          VARCHAR(20),  -- positive|negative|not_determined
    morphology          VARCHAR(100),
    objectionable       BOOLEAN      DEFAULT FALSE,
    objectionable_reason TEXT,
    investigation_triggered BOOLEAN  DEFAULT FALSE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_organism_library (
    id                  VARCHAR(36)  PRIMARY KEY,
    organism_name       VARCHAR(200) UNIQUE NOT NULL,
    genus               VARCHAR(100),
    species             VARCHAR(100),
    gram_stain          VARCHAR(20),
    objectionable_for   TEXT,        -- sterile_products|oral_solid|topical
    typical_source      VARCHAR(200), -- skin|environment|water|soil
    risk_level          VARCHAR(20)  DEFAULT 'low', -- low|medium|high|critical
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_exceedances (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_em_results(id),
    exceedance_type     VARCHAR(30)  NOT NULL, -- alert|action|specification
    investigation_required BOOLEAN   DEFAULT TRUE,
    investigation_id    VARCHAR(36)  REFERENCES lims_oos_investigations(id),
    capa_id             VARCHAR(36),
    root_cause          TEXT,
    corrective_action   TEXT,
    effectiveness_check DATE,
    closed_by           VARCHAR(36),
    closed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_em_trend_analysis (
    id                  VARCHAR(36)  PRIMARY KEY,
    location_id         VARCHAR(36)  NOT NULL REFERENCES lims_em_locations(id),
    analysis_period_start DATE,
    analysis_period_end DATE,
    sample_count        INTEGER,
    positive_count      INTEGER,
    contamination_rate_pct NUMERIC(8,4),
    trend_detected      BOOLEAN      DEFAULT FALSE,
    trend_description   TEXT,
    action_required     BOOLEAN      DEFAULT FALSE,
    reviewed_by         VARCHAR(36),
    reviewed_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.11  INSTRUMENTS (LIMS-SIDE)
-- ─────────────────────────────────────────
CREATE TABLE lims_instruments (
    id                  VARCHAR(36)  PRIMARY KEY,
    instrument_id       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    instrument_type     VARCHAR(50)  NOT NULL, -- hplc|gc|uv_vis|ftir|ir|nmr|ms|lcms|gcms|icp|aas|balance|ph_meter|osmometer|viscometer|toc|lal_reader|dissolution|particle_sizer|kf_titrator|potentiostat|spectrofluorometer|plate_reader|pcr|flow_cytometer
    manufacturer        VARCHAR(200),
    model               VARCHAR(100),
    serial_number       VARCHAR(100) UNIQUE,
    asset_number        VARCHAR(100),
    location_id         VARCHAR(36),
    site_id             VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'available', -- available|in_use|maintenance|calibration|qualification|out_of_service|retired
    calibration_due     DATE,
    maintenance_due     DATE,
    qualification_id    VARCHAR(36), -- links to validation suite
    software_version    VARCHAR(50),
    data_system         VARCHAR(100), -- Empower|Chromeleon|MassLynx|OpenLab|etc
    audit_trail_enabled BOOLEAN      DEFAULT TRUE,
    21_cfr_part11_compliant BOOLEAN  DEFAULT TRUE,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_instrument_calibrations (
    id                  VARCHAR(36)  PRIMARY KEY,
    instrument_id       VARCHAR(36)  NOT NULL REFERENCES lims_instruments(id),
    calibration_type    VARCHAR(50)  NOT NULL, -- performance_check|calibration|verification|suitability
    performed_by        VARCHAR(36)  NOT NULL,
    performed_at        TIMESTAMPTZ  NOT NULL,
    due_date            DATE,
    next_calibration    DATE,
    result              VARCHAR(20)  NOT NULL, -- pass|fail|adjusted
    reference_standard  VARCHAR(200),
    certificate_number  VARCHAR(100),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_instrument_reservations (
    id                  VARCHAR(36)  PRIMARY KEY,
    instrument_id       VARCHAR(36)  NOT NULL REFERENCES lims_instruments(id),
    reserved_by         VARCHAR(36)  NOT NULL,
    reserved_from       TIMESTAMPTZ  NOT NULL,
    reserved_until      TIMESTAMPTZ  NOT NULL,
    purpose             VARCHAR(200),
    method_id           VARCHAR(36)  REFERENCES lims_test_methods(id),
    status              VARCHAR(20)  DEFAULT 'reserved', -- reserved|in_use|complete|cancelled
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_instrument_runs (
    id                  VARCHAR(36)  PRIMARY KEY,
    instrument_id       VARCHAR(36)  NOT NULL REFERENCES lims_instruments(id),
    run_number          VARCHAR(50)  UNIQUE,
    run_type            VARCHAR(30)  NOT NULL, -- sequence|single|batch
    method_id           VARCHAR(36)  REFERENCES lims_test_methods(id),
    analyst_id          VARCHAR(36)  NOT NULL,
    start_time          TIMESTAMPTZ  NOT NULL,
    end_time            TIMESTAMPTZ,
    system_suitability_pass BOOLEAN,
    sample_count        INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.12  REAGENTS & PREPARED SOLUTIONS
-- ─────────────────────────────────────────
CREATE TABLE lims_reagents (
    id                  VARCHAR(36)  PRIMARY KEY,
    reagent_code        VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    grade               VARCHAR(50), -- acs|hplc|lc_ms|analytical|reagent|technical|pharmacopoeial
    supplier            VARCHAR(200),
    catalogue_number    VARCHAR(100),
    cas_number          VARCHAR(50),
    storage_conditions  VARCHAR(200),
    hazard_class        VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_reagent_lots (
    id                  VARCHAR(36)  PRIMARY KEY,
    reagent_id          VARCHAR(36)  NOT NULL REFERENCES lims_reagents(id),
    lot_number          VARCHAR(100) NOT NULL,
    received_date       DATE,
    expiry_date         DATE,
    quantity_received   NUMERIC(12,4),
    quantity_unit       VARCHAR(20),
    quantity_remaining  NUMERIC(12,4),
    status              VARCHAR(30)  DEFAULT 'approved', -- quarantine|approved|in_use|exhausted|expired|rejected
    storage_location_id VARCHAR(36)  REFERENCES lims_storage_locations(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_prepared_solutions (
    id                  VARCHAR(36)  PRIMARY KEY,
    solution_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    solution_type       VARCHAR(50), -- buffer|mobile_phase|diluent|standard_solution|titrant|reagent_solution
    preparation_sop     VARCHAR(100),
    concentration       VARCHAR(100),
    concentration_unit  VARCHAR(50),
    valid_for_days      INTEGER,
    storage_conditions  VARCHAR(200),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_solution_preparations (
    id                  VARCHAR(36)  PRIMARY KEY,
    solution_id         VARCHAR(36)  NOT NULL REFERENCES lims_prepared_solutions(id),
    prep_number         VARCHAR(50)  UNIQUE NOT NULL,
    prepared_by         VARCHAR(36)  NOT NULL,
    preparation_date    TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    expiry_date         DATE         NOT NULL,
    quantity_prepared   NUMERIC(12,4),
    unit                VARCHAR(20),
    verified_by         VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'active', -- active|expired|discarded
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_solution_prep_components (
    id                  VARCHAR(36)  PRIMARY KEY,
    preparation_id      VARCHAR(36)  NOT NULL REFERENCES lims_solution_preparations(id),
    reagent_lot_id      VARCHAR(36)  REFERENCES lims_reagent_lots(id),
    component_name      VARCHAR(200),
    quantity_used       NUMERIC(12,4),
    unit                VARCHAR(20),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.13  WATER SYSTEMS
-- 21 CFR 211.68, USP <1231>, EP 3.1.1/3.1.2
-- ─────────────────────────────────────────
CREATE TABLE lims_water_systems (
    id                  VARCHAR(36)  PRIMARY KEY,
    system_code         VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    water_type          VARCHAR(50)  NOT NULL, -- purified_water|wfi|highly_purified_water|clean_steam|potable
    standard            VARCHAR(50)  NOT NULL, -- usp|ep|jp
    qualification_status VARCHAR(30) DEFAULT 'qualified',
    site_id             VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_water_sampling_points (
    id                  VARCHAR(36)  PRIMARY KEY,
    system_id           VARCHAR(36)  NOT NULL REFERENCES lims_water_systems(id),
    point_code          VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    point_type          VARCHAR(50), -- use_point|loop_point|storage|pre_filter|post_filter|return
    location_description VARCHAR(500),
    sampling_frequency  VARCHAR(30)  NOT NULL, -- daily|weekly|monthly
    is_critical         BOOLEAN      DEFAULT FALSE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_water_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_point_id     VARCHAR(36)  NOT NULL REFERENCES lims_water_sampling_points(id),
    sample_date         TIMESTAMPTZ  NOT NULL,
    sampled_by          VARCHAR(36)  NOT NULL,
    test_type           VARCHAR(50)  NOT NULL, -- conductivity|toc|bioburden|endotoxin|nitrates|ph|appearance|sterility
    result_numeric      NUMERIC(15,6),
    result_text         VARCHAR(200),
    unit                VARCHAR(50),
    alert_limit         NUMERIC(15,6),
    action_limit        NUMERIC(15,6),
    specification_limit NUMERIC(15,6),
    alert_exceeded      BOOLEAN      DEFAULT FALSE,
    action_exceeded     BOOLEAN      DEFAULT FALSE,
    spec_exceeded       BOOLEAN      DEFAULT FALSE,
    reviewed_by         VARCHAR(36),
    reviewed_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.14  MICROBIOLOGY SPECIFIC
-- ─────────────────────────────────────────
CREATE TABLE lims_micro_test_types (
    id                  VARCHAR(36)  PRIMARY KEY,
    test_code           VARCHAR(30)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    method_type         VARCHAR(50), -- sterility|bioburden|endotoxin|mycoplasma|viral|identification|apt|gpt|mic|mbc|preservative_efficacy
    compendial_ref      VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_sterility_tests (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    method              VARCHAR(50)  NOT NULL, -- membrane_filtration|direct_inoculation
    incubation_temp1_c  NUMERIC(5,1),
    incubation_days1    INTEGER,
    incubation_temp2_c  NUMERIC(5,1),
    incubation_days2    INTEGER,
    bacteria_result     VARCHAR(20), -- no_growth|growth
    fungi_result        VARCHAR(20),
    positive_control    VARCHAR(50),
    negative_control    VARCHAR(50),
    environment_monitoring_at_test TEXT,
    invalidation_required BOOLEAN   DEFAULT FALSE,
    invalidation_reason TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_endotoxin_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    result_id           VARCHAR(36)  NOT NULL REFERENCES lims_test_results(id),
    method              VARCHAR(30)  NOT NULL, -- gel_clot|turbidimetric_kinetic|chromogenic_kinetic|rfc_recombinant
    lambda              NUMERIC(10,4),         -- sensitivity EU/mL
    sample_dilution     NUMERIC(10,4),
    mvd                 NUMERIC(10,2),          -- maximum valid dilution
    endotoxin_limit     NUMERIC(10,4),          -- EU/mL or EU/mg or EU/device
    result_eu_ml        NUMERIC(10,4),
    passes_limit        BOOLEAN,
    ppc_recovery_pct    NUMERIC(8,2),           -- positive product control
    cspc_cv_pct         NUMERIC(8,2),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_growth_promotion_tests (
    id                  VARCHAR(36)  PRIMARY KEY,
    media_lot           VARCHAR(100) NOT NULL,
    media_type          VARCHAR(100) NOT NULL,
    test_date           DATE         NOT NULL,
    tested_by           VARCHAR(36)  NOT NULL,
    organisms_tested    TEXT,        -- JSON array of organisms
    result              VARCHAR(20)  NOT NULL, -- pass|fail
    observations        TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.15  CERTIFICATE OF ANALYSIS
-- ─────────────────────────────────────────
CREATE TABLE lims_coa_templates (
    id                  VARCHAR(36)  PRIMARY KEY,
    template_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    product_type        VARCHAR(50),
    header_content      TEXT,
    footer_content      TEXT,
    logo_path           VARCHAR(500),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_certificates_of_analysis (
    id                  VARCHAR(36)  PRIMARY KEY,
    coa_number          VARCHAR(50)  UNIQUE NOT NULL,
    template_id         VARCHAR(36)  REFERENCES lims_coa_templates(id),
    product_id          VARCHAR(36),
    product_name        VARCHAR(200),
    batch_number        VARCHAR(100),
    manufacturing_date  DATE,
    expiry_date         DATE,
    retest_date         DATE,
    specification_id    VARCHAR(36)  REFERENCES lims_specifications(id),
    overall_result      VARCHAR(20)  NOT NULL, -- pass|fail|conditional
    generated_by        VARCHAR(36),
    generated_at        TIMESTAMPTZ,
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    issued_to           VARCHAR(500),
    issued_at           TIMESTAMPTZ,
    revision            INTEGER      DEFAULT 1,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_coa_line_items (
    id                  VARCHAR(36)  PRIMARY KEY,
    coa_id              VARCHAR(36)  NOT NULL REFERENCES lims_certificates_of_analysis(id),
    test_name           VARCHAR(200) NOT NULL,
    method_reference    VARCHAR(200),
    specification       VARCHAR(300),
    result              VARCHAR(300),
    judgement           VARCHAR(20), -- pass|fail|conforms|does_not_conform
    sequence_number     INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.16  WORKLOAD & TURNAROUND
-- ─────────────────────────────────────────
CREATE TABLE lims_lab_workload (
    id                  VARCHAR(36)  PRIMARY KEY,
    date_period         DATE         NOT NULL,
    period_type         VARCHAR(20)  NOT NULL, -- daily|weekly|monthly
    lab_section         VARCHAR(100),
    site_id             VARCHAR(36),
    samples_received    INTEGER      DEFAULT 0,
    tests_requested     INTEGER      DEFAULT 0,
    tests_completed     INTEGER      DEFAULT 0,
    tests_pending       INTEGER      DEFAULT 0,
    overdue_count       INTEGER      DEFAULT 0,
    analyst_count       INTEGER,
    capacity_pct        NUMERIC(5,2),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_turnaround_targets (
    id                  VARCHAR(36)  PRIMARY KEY,
    sample_type         VARCHAR(50),
    test_type           VARCHAR(50),
    priority            VARCHAR(20),
    target_hours        NUMERIC(8,2) NOT NULL,
    warning_hours       NUMERIC(8,2),
    site_id             VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.17  LIMS ↔ EXTERNAL SYSTEM INTEGRATIONS
-- ─────────────────────────────────────────
CREATE TABLE lims_integration_connectors (
    id                  VARCHAR(36)  PRIMARY KEY,
    connector_name      VARCHAR(100) NOT NULL, -- LabVantage|LabWare|STARLIMS|Sapio|Empower|Chromeleon|SAP|custom
    connector_type      VARCHAR(50)  NOT NULL, -- lims|chromatography_ds|erp|mes|edms
    version             VARCHAR(50),
    endpoint_url        VARCHAR(500),
    auth_method         VARCHAR(50),
    is_active           BOOLEAN      DEFAULT TRUE,
    sync_direction      VARCHAR(20)  NOT NULL, -- inbound|outbound|bidirectional
    site_id             VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE lims_integration_sync_logs (
    id                  VARCHAR(36)  PRIMARY KEY,
    connector_id        VARCHAR(36)  NOT NULL REFERENCES lims_integration_connectors(id),
    sync_type           VARCHAR(50)  NOT NULL, -- sample|result|method|spec|reference_standard
    direction           VARCHAR(20)  NOT NULL,
    records_sent        INTEGER,
    records_received    INTEGER,
    records_failed      INTEGER,
    started_at          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    completed_at        TIMESTAMPTZ,
    status              VARCHAR(20)  DEFAULT 'running', -- running|complete|failed|partial
    error_detail        TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

