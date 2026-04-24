-- ============================================================
-- PHAROLON Schema Part 12 — Native LIMS
-- Laboratory Information Management System
-- Targets: all pharma levels — small biotech → large enterprise
-- Regulatory: 21 CFR 211, USP/EP/JP, ICH Q2/Q6/Q8, EU GMP
-- ============================================================

-- ─────────────────────────────────────────
-- 12.01 SAMPLE MANAGEMENT
-- ─────────────────────────────────────────
CREATE TABLE lims_sample_types (
    id                  VARCHAR(36) PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,
    name                VARCHAR(200) NOT NULL,
    category            VARCHAR(100), -- API, excipient, FP, RM, ENV, water, swab, biologic
    matrix              VARCHAR(100), -- solid, liquid, gas, semi-solid, biological
    default_container   VARCHAR(100),
    requires_chain      BOOLEAN DEFAULT FALSE, -- chain of custody required
    default_storage_conditions VARCHAR(200),
    stability_data      TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active           BOOLEAN DEFAULT TRUE
);

CREATE TABLE lims_samples (
    id                  VARCHAR(36) PRIMARY KEY,
    sample_number       VARCHAR(100) NOT NULL UNIQUE,
    barcode             VARCHAR(200) UNIQUE,
    qr_code             TEXT,
    sample_type_id      VARCHAR(36) REFERENCES lims_sample_types(id),
    description         VARCHAR(500),
    -- Source
    source_type         VARCHAR(100), -- batch, stability, environmental, method_val, clinical, supplier
    source_reference    VARCHAR(200), -- batch number, study ID, etc.
    product_id          VARCHAR(36),
    material_lot_id     VARCHAR(36),
    supplier_id         VARCHAR(36),
    -- Collection
    collected_at        TIMESTAMP WITH TIME ZONE,
    collected_by        VARCHAR(36) REFERENCES users(id),
    collection_site     VARCHAR(200),
    collection_point    VARCHAR(200),
    sample_quantity     DECIMAL(12,4),
    sample_unit         VARCHAR(50),
    -- Status
    status              VARCHAR(50) DEFAULT 'received', -- received, logged, in_testing, complete, disposed, rejected
    receipt_date        TIMESTAMP WITH TIME ZONE,
    received_by         VARCHAR(36) REFERENCES users(id),
    condition_on_receipt VARCHAR(200),
    -- Storage
    storage_location_id VARCHAR(36),
    storage_position    VARCHAR(100),
    storage_temperature VARCHAR(50),
    expiry_date         DATE,
    -- Testing
    priority            VARCHAR(50) DEFAULT 'routine', -- urgent, high, routine, low
    required_by         TIMESTAMP WITH TIME ZONE,
    turnaround_target   INTEGER, -- hours
    -- Traceability
    parent_sample_id    VARCHAR(36) REFERENCES lims_samples(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    site_id             VARCHAR(36) REFERENCES sites(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          VARCHAR(36) REFERENCES users(id),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_sample_aliquots (
    id                  VARCHAR(36) PRIMARY KEY,
    parent_sample_id    VARCHAR(36) NOT NULL REFERENCES lims_samples(id),
    aliquot_number      VARCHAR(100) NOT NULL,
    barcode             VARCHAR(200) UNIQUE,
    quantity            DECIMAL(12,4),
    unit                VARCHAR(50),
    status              VARCHAR(50) DEFAULT 'available',
    storage_location_id VARCHAR(36),
    storage_position    VARCHAR(100),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          VARCHAR(36) REFERENCES users(id)
);

CREATE TABLE lims_sample_chain_of_custody (
    id                  VARCHAR(36) PRIMARY KEY,
    sample_id           VARCHAR(36) NOT NULL REFERENCES lims_samples(id),
    event_type          VARCHAR(100), -- received, transferred, stored, retrieved, tested, disposed
    from_location       VARCHAR(200),
    to_location         VARCHAR(200),
    from_custodian      VARCHAR(36) REFERENCES users(id),
    to_custodian        VARCHAR(36) REFERENCES users(id),
    transferred_at      TIMESTAMP WITH TIME ZONE NOT NULL,
    temperature_at_transfer VARCHAR(50),
    condition           VARCHAR(200),
    notes               TEXT,
    signature_id        VARCHAR(36),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_sample_login_batches (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_number        VARCHAR(100) NOT NULL UNIQUE,
    description         VARCHAR(500),
    sample_count        INTEGER DEFAULT 0,
    status              VARCHAR(50) DEFAULT 'open',
    logged_by           VARCHAR(36) REFERENCES users(id),
    logged_at           TIMESTAMP WITH TIME ZONE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_sample_login_batch_items (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_id            VARCHAR(36) NOT NULL REFERENCES lims_sample_login_batches(id),
    sample_id           VARCHAR(36) NOT NULL REFERENCES lims_samples(id),
    sequence_number     INTEGER,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.02 STORAGE LOCATIONS
-- ─────────────────────────────────────────
CREATE TABLE lims_storage_units (
    id                  VARCHAR(36) PRIMARY KEY,
    code                VARCHAR(50) NOT NULL UNIQUE,
    name                VARCHAR(200) NOT NULL,
    type                VARCHAR(100), -- freezer, fridge, ambient, incubator, liq_nitrogen, flammable
    location_description VARCHAR(500),
    temperature_setpoint VARCHAR(50),
    temperature_min     DECIMAL(6,2),
    temperature_max     DECIMAL(6,2),
    humidity_setpoint   VARCHAR(50),
    capacity_positions  INTEGER,
    site_id             VARCHAR(36) REFERENCES sites(id),
    room                VARCHAR(100),
    monitoring_system   VARCHAR(200),
    is_qualified        BOOLEAN DEFAULT FALSE,
    qualification_ref   VARCHAR(200),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_storage_positions (
    id                  VARCHAR(36) PRIMARY KEY,
    unit_id             VARCHAR(36) NOT NULL REFERENCES lims_storage_units(id),
    position_code       VARCHAR(100) NOT NULL,
    shelf               VARCHAR(50),
    rack                VARCHAR(50),
    row                 VARCHAR(50),
    column              VARCHAR(50),
    is_occupied         BOOLEAN DEFAULT FALSE,
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    aliquot_id          VARCHAR(36) REFERENCES lims_sample_aliquots(id),
    UNIQUE(unit_id, position_code)
);

-- ─────────────────────────────────────────
-- 12.03 SPECIFICATIONS & LIMITS
-- ─────────────────────────────────────────
CREATE TABLE lims_specifications (
    id                  VARCHAR(36) PRIMARY KEY,
    spec_number         VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    version             VARCHAR(50) NOT NULL DEFAULT '1.0',
    status              VARCHAR(50) DEFAULT 'draft', -- draft, approved, superseded, obsolete
    spec_type           VARCHAR(100), -- raw_material, excipient, API, FP, intermediate, packaging, in_process
    product_id          VARCHAR(36),
    material_code       VARCHAR(100),
    compendial_ref      VARCHAR(200), -- USP, EP, JP, BP, IP
    regulatory_basis    VARCHAR(200),
    approved_at         TIMESTAMP WITH TIME ZONE,
    approved_by         VARCHAR(36) REFERENCES users(id),
    effective_date      DATE,
    review_date         DATE,
    supersedes_id       VARCHAR(36) REFERENCES lims_specifications(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          VARCHAR(36) REFERENCES users(id),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_specification_tests (
    id                  VARCHAR(36) PRIMARY KEY,
    spec_id             VARCHAR(36) NOT NULL REFERENCES lims_specifications(id),
    test_method_id      VARCHAR(36),
    test_name           VARCHAR(300) NOT NULL,
    test_category       VARCHAR(100), -- identity, assay, purity, impurity, micro, physical, dissolution
    sequence_number     INTEGER,
    is_mandatory        BOOLEAN DEFAULT TRUE,
    is_release_test     BOOLEAN DEFAULT TRUE,
    is_stability_test   BOOLEAN DEFAULT FALSE,
    frequency           VARCHAR(100), -- every_batch, periodic, skip_lot
    compendial_ref      VARCHAR(200),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_specification_limits (
    id                  VARCHAR(36) PRIMARY KEY,
    spec_test_id        VARCHAR(36) NOT NULL REFERENCES lims_specification_tests(id),
    parameter_name      VARCHAR(300) NOT NULL,
    limit_type          VARCHAR(50), -- NMT, NLT, range, exact, report_only, conform
    lower_limit         DECIMAL(20,8),
    upper_limit         DECIMAL(20,8),
    exact_value         VARCHAR(200),
    unit                VARCHAR(100),
    -- Stage-specific limits (e.g., dissolution Q values)
    stage               VARCHAR(50),
    -- Alert / action limits (for trending)
    alert_lower         DECIMAL(20,8),
    alert_upper         DECIMAL(20,8),
    action_lower        DECIMAL(20,8),
    action_upper        DECIMAL(20,8),
    -- Regulatory
    regulatory_limit    VARCHAR(200),
    compendial_limit    VARCHAR(200),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_compendial_methods (
    id                  VARCHAR(36) PRIMARY KEY,
    code                VARCHAR(100) NOT NULL UNIQUE,
    compendium          VARCHAR(50), -- USP, EP, JP, BP, IP, ICH
    chapter_number      VARCHAR(100),
    chapter_title       VARCHAR(300),
    version             VARCHAR(50),
    effective_date      DATE,
    test_category       VARCHAR(100),
    description         TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.04 TEST METHODS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_methods (
    id                  VARCHAR(36) PRIMARY KEY,
    method_number       VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    version             VARCHAR(50) NOT NULL DEFAULT '1.0',
    status              VARCHAR(50) DEFAULT 'draft',
    category            VARCHAR(100), -- HPLC, GC, UV, titration, wet_chem, micro, physical, dissolution, IR, NMR, ICP, ELISA, PCR
    technique           VARCHAR(200),
    is_compendial       BOOLEAN DEFAULT FALSE,
    compendial_ref      VARCHAR(200),
    is_validated        BOOLEAN DEFAULT FALSE,
    validation_ref      VARCHAR(200),
    instrument_type     VARCHAR(200),
    sample_prep         TEXT,
    procedure_summary   TEXT,
    calculation_method  TEXT,
    system_suitability  TEXT,
    acceptance_criteria TEXT,
    run_time_minutes    INTEGER,
    sample_size_required DECIMAL(10,4),
    sample_unit         VARCHAR(50),
    regulatory_refs     TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          VARCHAR(36) REFERENCES users(id),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_test_method_versions (
    id                  VARCHAR(36) PRIMARY KEY,
    method_id           VARCHAR(36) NOT NULL REFERENCES lims_test_methods(id),
    version             VARCHAR(50) NOT NULL,
    change_summary      TEXT,
    approved_by         VARCHAR(36) REFERENCES users(id),
    approved_at         TIMESTAMP WITH TIME ZONE,
    effective_date      DATE,
    content_snapshot    TEXT, -- full method text at this version
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.05 TEST REQUESTS & ASSIGNMENTS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_requests (
    id                  VARCHAR(36) PRIMARY KEY,
    request_number      VARCHAR(100) NOT NULL UNIQUE,
    sample_id           VARCHAR(36) NOT NULL REFERENCES lims_samples(id),
    spec_id             VARCHAR(36) REFERENCES lims_specifications(id),
    request_type        VARCHAR(100), -- release, stability, investigation, method_val, retest
    priority            VARCHAR(50) DEFAULT 'routine',
    requested_by        VARCHAR(36) REFERENCES users(id),
    requested_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    required_by         TIMESTAMP WITH TIME ZONE,
    status              VARCHAR(50) DEFAULT 'pending', -- pending, assigned, in_progress, complete, cancelled
    completed_at        TIMESTAMP WITH TIME ZONE,
    disposition         VARCHAR(50), -- pass, fail, inconclusive, invalid
    notes               TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_test_request_items (
    id                  VARCHAR(36) PRIMARY KEY,
    request_id          VARCHAR(36) NOT NULL REFERENCES lims_test_requests(id),
    spec_test_id        VARCHAR(36) REFERENCES lims_specification_tests(id),
    test_method_id      VARCHAR(36) REFERENCES lims_test_methods(id),
    test_name           VARCHAR(300) NOT NULL,
    status              VARCHAR(50) DEFAULT 'pending',
    assigned_to         VARCHAR(36) REFERENCES users(id),
    assigned_at         TIMESTAMP WITH TIME ZONE,
    instrument_id       VARCHAR(36),
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    result_status       VARCHAR(50), -- pass, fail, oos, oot, invalid, inconclusive
    sequence_number     INTEGER,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.06 TEST RESULTS
-- ─────────────────────────────────────────
CREATE TABLE lims_test_results (
    id                  VARCHAR(36) PRIMARY KEY,
    request_item_id     VARCHAR(36) NOT NULL REFERENCES lims_test_request_items(id),
    result_number       VARCHAR(100) NOT NULL UNIQUE,
    test_name           VARCHAR(300) NOT NULL,
    analyst_id          VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    instrument_id       VARCHAR(36),
    instrument_run_id   VARCHAR(36),
    -- Result
    result_type         VARCHAR(50), -- numeric, text, pass_fail, conforming
    numeric_result      DECIMAL(20,8),
    text_result         TEXT,
    unit                VARCHAR(100),
    calculation_shown   TEXT,
    -- Limit comparison
    lower_limit         DECIMAL(20,8),
    upper_limit         DECIMAL(20,8),
    limit_type          VARCHAR(50),
    result_status       VARCHAR(50), -- pass, fail, oos, oot, atypical, invalid
    -- Review
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    reviewed_at         TIMESTAMP WITH TIME ZONE,
    review_status       VARCHAR(50), -- pending, approved, rejected
    review_comments     TEXT,
    -- System suitability
    system_suit_passed  BOOLEAN,
    system_suit_data    TEXT,
    -- Raw data
    raw_data_ref        VARCHAR(500),
    attachments_count   INTEGER DEFAULT 0,
    notes               TEXT,
    is_invalidated      BOOLEAN DEFAULT FALSE,
    invalidation_reason TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_result_values (
    id                  VARCHAR(36) PRIMARY KEY,
    result_id           VARCHAR(36) NOT NULL REFERENCES lims_test_results(id),
    parameter_name      VARCHAR(300) NOT NULL,
    raw_value           DECIMAL(20,8),
    calculated_value    DECIMAL(20,8),
    unit                VARCHAR(100),
    replicate_number    INTEGER,
    injection_number    INTEGER,
    data_point_label    VARCHAR(200),
    is_excluded         BOOLEAN DEFAULT FALSE,
    exclusion_reason    TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_result_attachments (
    id                  VARCHAR(36) PRIMARY KEY,
    result_id           VARCHAR(36) NOT NULL REFERENCES lims_test_results(id),
    file_name           VARCHAR(500) NOT NULL,
    file_type           VARCHAR(100), -- chromatogram, spectrum, image, calculation, raw_data
    file_size_bytes     BIGINT,
    storage_path        VARCHAR(1000),
    checksum_sha256     VARCHAR(64),
    uploaded_by         VARCHAR(36) REFERENCES users(id),
    uploaded_at         TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    notes               VARCHAR(500)
);

CREATE TABLE lims_test_worksheets (
    id                  VARCHAR(36) PRIMARY KEY,
    worksheet_number    VARCHAR(100) NOT NULL UNIQUE,
    title               VARCHAR(300),
    analyst_id          VARCHAR(36) REFERENCES users(id),
    instrument_id       VARCHAR(36),
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    status              VARCHAR(50) DEFAULT 'open',
    sample_count        INTEGER DEFAULT 0,
    test_method_id      VARCHAR(36) REFERENCES lims_test_methods(id),
    notes               TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_worksheet_samples (
    id                  VARCHAR(36) PRIMARY KEY,
    worksheet_id        VARCHAR(36) NOT NULL REFERENCES lims_test_worksheets(id),
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    request_item_id     VARCHAR(36) REFERENCES lims_test_request_items(id),
    position            INTEGER,
    sample_type_label   VARCHAR(100), -- sample, standard, blank, QC, system_suit
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.07 INSTRUMENTS & ANALYTICAL EQUIPMENT
-- ─────────────────────────────────────────
CREATE TABLE lims_instruments (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id_code  VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    type                VARCHAR(100), -- HPLC, GC, UV-Vis, FTIR, NMR, ICP-MS, dissolution, balance, pH_meter, KF, TOC, particle_size
    manufacturer        VARCHAR(200),
    model               VARCHAR(200),
    serial_number       VARCHAR(200) UNIQUE,
    asset_tag           VARCHAR(100),
    location            VARCHAR(200),
    room                VARCHAR(100),
    site_id             VARCHAR(36) REFERENCES sites(id),
    -- Status
    status              VARCHAR(50) DEFAULT 'qualified', -- qualified, unqualified, maintenance, quarantine, retired
    qualification_due   DATE,
    calibration_due     DATE,
    maintenance_due     DATE,
    -- Software
    software_name       VARCHAR(200),
    software_version    VARCHAR(100),
    software_validated  BOOLEAN DEFAULT FALSE,
    -- Qualification
    iq_ref              VARCHAR(200),
    oq_ref              VARCHAR(200),
    pq_ref              VARCHAR(200),
    -- Support
    service_provider    VARCHAR(200),
    service_contract_expiry DATE,
    -- Integration
    has_lims_interface  BOOLEAN DEFAULT FALSE,
    interface_type      VARCHAR(100), -- API, file_import, manual
    is_active           BOOLEAN DEFAULT TRUE,
    notes               TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_instrument_calibrations (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id       VARCHAR(36) NOT NULL REFERENCES lims_instruments(id),
    calibration_number  VARCHAR(100) NOT NULL UNIQUE,
    calibration_type    VARCHAR(100), -- performance_check, calibration, verification
    performed_at        TIMESTAMP WITH TIME ZONE,
    performed_by        VARCHAR(36) REFERENCES users(id),
    next_due_date       DATE,
    standards_used      TEXT,
    results_summary     TEXT,
    pass_fail           VARCHAR(20),
    certificate_ref     VARCHAR(200),
    traceable_to        VARCHAR(200), -- NIST, BIPM, etc.
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_instrument_maintenance (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id       VARCHAR(36) NOT NULL REFERENCES lims_instruments(id),
    maintenance_type    VARCHAR(100), -- preventive, corrective, emergency
    performed_at        TIMESTAMP WITH TIME ZONE,
    performed_by        VARCHAR(200),
    description         TEXT,
    parts_replaced      TEXT,
    downtime_hours      DECIMAL(6,2),
    requires_requalification BOOLEAN DEFAULT FALSE,
    requalification_ref VARCHAR(200),
    next_maintenance_due DATE,
    cost                DECIMAL(10,2),
    currency            VARCHAR(10) DEFAULT 'USD',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_instrument_reservations (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id       VARCHAR(36) NOT NULL REFERENCES lims_instruments(id),
    reserved_by         VARCHAR(36) REFERENCES users(id),
    start_time          TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time            TIMESTAMP WITH TIME ZONE NOT NULL,
    purpose             VARCHAR(300),
    request_ids         TEXT, -- JSON array of request IDs
    status              VARCHAR(50) DEFAULT 'confirmed',
    notes               VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_instrument_runs (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id       VARCHAR(36) NOT NULL REFERENCES lims_instruments(id),
    run_identifier      VARCHAR(200),
    run_type            VARCHAR(100), -- sequence, single, batch
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    analyst_id          VARCHAR(36) REFERENCES users(id),
    method_file         VARCHAR(500),
    sequence_file       VARCHAR(500),
    sample_count        INTEGER DEFAULT 0,
    system_suit_passed  BOOLEAN,
    raw_data_location   VARCHAR(1000),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.08 REFERENCE STANDARDS
-- ─────────────────────────────────────────
CREATE TABLE lims_reference_standards (
    id                  VARCHAR(36) PRIMARY KEY,
    catalog_number      VARCHAR(200) NOT NULL,
    name                VARCHAR(300) NOT NULL,
    standard_type       VARCHAR(100), -- CRS, primary, working, in_house, impurity, QC_mix
    supplier            VARCHAR(200),
    supplier_lot        VARCHAR(200),
    internal_lot        VARCHAR(100),
    potency             DECIMAL(10,6),
    potency_unit        VARCHAR(50),
    potency_basis       VARCHAR(100), -- anhydrous, as_is, dried
    certificate_of_analysis TEXT,
    assigned_by         VARCHAR(200), -- USP, EP, WHO, in_house
    -- Inventory
    quantity_received   DECIMAL(10,4),
    quantity_remaining  DECIMAL(10,4),
    unit                VARCHAR(50),
    storage_conditions  VARCHAR(200),
    storage_location_id VARCHAR(36) REFERENCES lims_storage_units(id),
    -- Dates
    received_date       DATE,
    opened_date         DATE,
    expiry_date         DATE,
    retest_date         DATE,
    -- Status
    status              VARCHAR(50) DEFAULT 'active', -- active, expired, depleted, quarantine
    is_active           BOOLEAN DEFAULT TRUE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_reference_standard_usages (
    id                  VARCHAR(36) PRIMARY KEY,
    standard_id         VARCHAR(36) NOT NULL REFERENCES lims_reference_standards(id),
    used_by             VARCHAR(36) REFERENCES users(id),
    used_at             TIMESTAMP WITH TIME ZONE,
    quantity_used       DECIMAL(10,4),
    unit                VARCHAR(50),
    quantity_after      DECIMAL(10,4),
    purpose             VARCHAR(300),
    result_id           VARCHAR(36) REFERENCES lims_test_results(id),
    worksheet_id        VARCHAR(36) REFERENCES lims_test_worksheets(id),
    notes               VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.09 OOS / OOT INVESTIGATIONS
-- ─────────────────────────────────────────
CREATE TABLE lims_oos_investigations (
    id                  VARCHAR(36) PRIMARY KEY,
    oos_number          VARCHAR(100) NOT NULL UNIQUE,
    result_id           VARCHAR(36) NOT NULL REFERENCES lims_test_results(id),
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    investigation_type  VARCHAR(50), -- OOS, OOT, atypical
    -- Phase 1 — Immediate lab investigation
    phase1_opened_at    TIMESTAMP WITH TIME ZONE,
    phase1_analyst      VARCHAR(36) REFERENCES users(id),
    phase1_supervisor   VARCHAR(36) REFERENCES users(id),
    phase1_conclusion   VARCHAR(100), -- assignable_cause, no_assignable_cause
    phase1_completed_at TIMESTAMP WITH TIME ZONE,
    assignable_cause     VARCHAR(300),
    -- Phase 2 — Full investigation
    phase2_required     BOOLEAN DEFAULT FALSE,
    phase2_opened_at    TIMESTAMP WITH TIME ZONE,
    phase2_investigator VARCHAR(36) REFERENCES users(id),
    phase2_completed_at TIMESTAMP WITH TIME ZONE,
    -- Retesting
    retest_authorized   BOOLEAN DEFAULT FALSE,
    retest_authorized_by VARCHAR(36) REFERENCES users(id),
    retest_result_ids   TEXT, -- JSON array
    -- Conclusion
    root_cause_category VARCHAR(200), -- analyst_error, instrument, reagent, calculation, sample, genuine
    root_cause_description TEXT,
    disposition         VARCHAR(100), -- invalidated, confirmed_oos, retested_pass, batch_rejected
    -- CAPA
    capa_required       BOOLEAN DEFAULT FALSE,
    capa_id             VARCHAR(36),
    -- Status
    status              VARCHAR(50) DEFAULT 'open',
    closed_at           TIMESTAMP WITH TIME ZONE,
    closed_by           VARCHAR(36) REFERENCES users(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_oot_trends (
    id                  VARCHAR(36) PRIMARY KEY,
    oot_number          VARCHAR(100) NOT NULL UNIQUE,
    spec_test_id        VARCHAR(36) REFERENCES lims_specification_tests(id),
    product_id          VARCHAR(36),
    trend_type          VARCHAR(100), -- shift, drift, variability, outlier
    detected_at         TIMESTAMP WITH TIME ZONE,
    detected_by         VARCHAR(36) REFERENCES users(id),
    data_points         INTEGER,
    trend_description   TEXT,
    statistical_method  VARCHAR(100), -- CUSUM, Shewhart, Runs_test, regression
    p_value             DECIMAL(8,6),
    action_taken        TEXT,
    investigation_id    VARCHAR(36) REFERENCES lims_oos_investigations(id),
    status              VARCHAR(50) DEFAULT 'open',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.10 STABILITY STUDIES
-- ─────────────────────────────────────────
CREATE TABLE lims_stability_studies (
    id                  VARCHAR(36) PRIMARY KEY,
    study_number        VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    study_type          VARCHAR(100), -- formal, supportive, stress, photostability, freeze_thaw, in_use
    product_id          VARCHAR(36),
    spec_id             VARCHAR(36) REFERENCES lims_specifications(id),
    batch_numbers       TEXT, -- JSON array
    -- ICH storage conditions
    long_term_condition VARCHAR(100), -- 25C_60RH, 30C_65RH, 5C, etc.
    accelerated_condition VARCHAR(100), -- 40C_75RH, 25C_60RH
    intermediate_condition VARCHAR(100),
    -- Protocol
    protocol_ref        VARCHAR(200),
    container_closure   VARCHAR(300),
    pack_size           VARCHAR(100),
    orientation         VARCHAR(100),
    -- Timepoints
    timepoints_planned  TEXT, -- JSON: [0,1,3,6,9,12,18,24,36,48,60]
    timepoints_completed TEXT, -- JSON
    -- Dates
    study_start_date    DATE,
    study_end_date      DATE,
    first_expiry_date   DATE,
    -- ICH Q1E stats
    statistical_method  VARCHAR(100), -- poolability, regression, lower_confidence_bound
    shelf_life_months   INTEGER,
    shelf_life_basis    TEXT,
    -- Status
    status              VARCHAR(50) DEFAULT 'active',
    regulatory_commitment BOOLEAN DEFAULT FALSE,
    regulatory_ref      VARCHAR(200),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_stability_stations (
    id                  VARCHAR(36) PRIMARY KEY,
    study_id            VARCHAR(36) NOT NULL REFERENCES lims_stability_studies(id),
    station_name        VARCHAR(200) NOT NULL,
    condition           VARCHAR(100) NOT NULL, -- 25C_60RH, 40C_75RH, 5C
    temperature_target  DECIMAL(5,2),
    humidity_target     DECIMAL(5,2),
    timepoints          TEXT, -- JSON array of planned timepoints in months
    chamber_id          VARCHAR(36),
    status              VARCHAR(50) DEFAULT 'active',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_stability_pulls (
    id                  VARCHAR(36) PRIMARY KEY,
    study_id            VARCHAR(36) NOT NULL REFERENCES lims_stability_studies(id),
    station_id          VARCHAR(36) REFERENCES lims_stability_stations(id),
    timepoint_months    DECIMAL(5,1) NOT NULL,
    timepoint_label     VARCHAR(50), -- T0, T1, T3, T6, T9, T12, T18, T24, T36
    planned_pull_date   DATE,
    actual_pull_date    DATE,
    pulled_by           VARCHAR(36) REFERENCES users(id),
    samples_pulled      INTEGER,
    test_request_id     VARCHAR(36) REFERENCES lims_test_requests(id),
    status              VARCHAR(50) DEFAULT 'scheduled', -- scheduled, pulled, complete, missed
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_stability_chambers (
    id                  VARCHAR(36) PRIMARY KEY,
    chamber_code        VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(200),
    manufacturer        VARCHAR(200),
    model               VARCHAR(200),
    serial_number       VARCHAR(200),
    location            VARCHAR(200),
    temperature_setpoint DECIMAL(5,2),
    humidity_setpoint   DECIMAL(5,2),
    temperature_range   VARCHAR(50),
    humidity_range      VARCHAR(50),
    capacity_units      INTEGER,
    is_qualified        BOOLEAN DEFAULT FALSE,
    qualification_ref   VARCHAR(200),
    monitoring_system   VARCHAR(200),
    is_active           BOOLEAN DEFAULT TRUE,
    site_id             VARCHAR(36) REFERENCES sites(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.11 ENVIRONMENTAL MONITORING
-- ─────────────────────────────────────────
CREATE TABLE lims_em_programs (
    id                  VARCHAR(36) PRIMARY KEY,
    program_code        VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    site_id             VARCHAR(36) REFERENCES sites(id),
    area_classification VARCHAR(50), -- ISO_5, ISO_6, ISO_7, ISO_8, grade_A, grade_B, grade_C, grade_D
    eu_gmp_grade        VARCHAR(10),  -- A, B, C, D
    program_type        VARCHAR(100), -- routine, qualification, investigation
    sampling_frequency  VARCHAR(100),
    status              VARCHAR(50) DEFAULT 'active',
    sop_ref             VARCHAR(200),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_em_locations (
    id                  VARCHAR(36) PRIMARY KEY,
    program_id          VARCHAR(36) NOT NULL REFERENCES lims_em_programs(id),
    location_code       VARCHAR(100) NOT NULL,
    description         VARCHAR(300),
    room                VARCHAR(200),
    area_classification VARCHAR(50),
    location_type       VARCHAR(100), -- active_air, passive_air, surface, personnel, water
    x_coordinate        DECIMAL(8,3),
    y_coordinate        DECIMAL(8,3),
    floor_plan_ref      VARCHAR(200),
    sampling_method     VARCHAR(100), -- RCS, SAS, agar_settle_plate, contact_plate, swab, water_sample
    agar_type           VARCHAR(100), -- TSA, SDA, both
    incubation_temp     DECIMAL(5,2),
    incubation_time_hours INTEGER,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_em_limits (
    id                  VARCHAR(36) PRIMARY KEY,
    location_id         VARCHAR(36) REFERENCES lims_em_locations(id),
    program_id          VARCHAR(36) REFERENCES lims_em_programs(id),
    classification      VARCHAR(50),
    limit_type          VARCHAR(50), -- alert, action
    media_type          VARCHAR(100), -- active_air, settle_plate, contact, glove
    unit                VARCHAR(100), -- CFU_m3, CFU_plate, CFU_contact
    limit_value         INTEGER,
    regulatory_basis    VARCHAR(100), -- EU_GMP, ISO_14644, USP_1116
    effective_date      DATE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_em_samples (
    id                  VARCHAR(36) PRIMARY KEY,
    sample_number       VARCHAR(100) NOT NULL UNIQUE,
    program_id          VARCHAR(36) REFERENCES lims_em_programs(id),
    location_id         VARCHAR(36) REFERENCES lims_em_locations(id),
    sample_type         VARCHAR(100),
    sampled_at          TIMESTAMP WITH TIME ZONE,
    sampled_by          VARCHAR(36) REFERENCES users(id),
    batch_reference     VARCHAR(200), -- manufacturing batch being monitored
    activity_monitored  VARCHAR(200), -- filling, weighing, at_rest, etc.
    air_volume_sampled  DECIMAL(8,2),
    volume_unit         VARCHAR(20),
    agar_type           VARCHAR(100),
    incubation_start    TIMESTAMP WITH TIME ZONE,
    incubation_end      TIMESTAMP WITH TIME ZONE,
    status              VARCHAR(50) DEFAULT 'incubating',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_em_results (
    id                  VARCHAR(36) PRIMARY KEY,
    em_sample_id        VARCHAR(36) NOT NULL REFERENCES lims_em_samples(id),
    read_at             TIMESTAMP WITH TIME ZONE,
    read_by             VARCHAR(36) REFERENCES users(id),
    colony_count        INTEGER,
    unit                VARCHAR(100),
    -- Comparison to limits
    alert_limit         INTEGER,
    action_limit        INTEGER,
    alert_exceeded      BOOLEAN DEFAULT FALSE,
    action_exceeded     BOOLEAN DEFAULT FALSE,
    result_status       VARCHAR(50), -- within, alert, action, invalid
    -- Identification
    organism_identified BOOLEAN DEFAULT FALSE,
    identification_method VARCHAR(100), -- MALDI-TOF, API, morphology, 16S
    organisms           TEXT, -- JSON array of identified organisms
    -- Investigation
    investigation_required BOOLEAN DEFAULT FALSE,
    investigation_id    VARCHAR(36) REFERENCES lims_oos_investigations(id),
    notes               TEXT,
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    reviewed_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_em_exceedances (
    id                  VARCHAR(36) PRIMARY KEY,
    exceedance_number   VARCHAR(100) NOT NULL UNIQUE,
    result_id           VARCHAR(36) NOT NULL REFERENCES lims_em_results(id),
    location_id         VARCHAR(36) REFERENCES lims_em_locations(id),
    exceedance_type     VARCHAR(50), -- alert, action
    exceeded_limit      INTEGER,
    actual_count        INTEGER,
    investigation_summary TEXT,
    root_cause          VARCHAR(300),
    corrective_actions  TEXT,
    batch_impact_assessed BOOLEAN DEFAULT FALSE,
    batches_affected    TEXT,
    capa_required       BOOLEAN DEFAULT FALSE,
    capa_id             VARCHAR(36),
    status              VARCHAR(50) DEFAULT 'open',
    closed_at           TIMESTAMP WITH TIME ZONE,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_micro_organisms (
    id                  VARCHAR(36) PRIMARY KEY,
    name                VARCHAR(300) NOT NULL,
    genus               VARCHAR(200),
    species             VARCHAR(200),
    gram_stain          VARCHAR(20), -- positive, negative, variable
    morphology          VARCHAR(100), -- cocci, bacilli, yeast, mould, actinomycetes
    aerobic_status      VARCHAR(50), -- aerobic, anaerobic, facultative, microaerophilic
    is_objectionable    BOOLEAN DEFAULT FALSE,
    regulatory_concern  BOOLEAN DEFAULT FALSE,
    regulatory_basis    VARCHAR(200),
    common_sources      TEXT,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.12 WATER SYSTEMS
-- ─────────────────────────────────────────
CREATE TABLE lims_water_systems (
    id                  VARCHAR(36) PRIMARY KEY,
    system_code         VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(200),
    system_type         VARCHAR(100), -- PW, WFI, clean_steam, RODI, potable
    site_id             VARCHAR(36) REFERENCES sites(id),
    design_standard     VARCHAR(100), -- USP, EP, WHO, ICH
    qualification_status VARCHAR(50),
    qualification_ref   VARCHAR(200),
    monitoring_program_id VARCHAR(36) REFERENCES lims_em_programs(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_water_sampling_points (
    id                  VARCHAR(36) PRIMARY KEY,
    system_id           VARCHAR(36) NOT NULL REFERENCES lims_water_systems(id),
    point_code          VARCHAR(100) NOT NULL,
    description         VARCHAR(300),
    location            VARCHAR(200),
    point_type          VARCHAR(100), -- loop, point_of_use, storage, pre_treatment, post_treatment
    sampling_frequency  VARCHAR(100),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_water_results (
    id                  VARCHAR(36) PRIMARY KEY,
    sample_number       VARCHAR(100) NOT NULL UNIQUE,
    system_id           VARCHAR(36) REFERENCES lims_water_systems(id),
    sampling_point_id   VARCHAR(36) REFERENCES lims_water_sampling_points(id),
    sampled_at          TIMESTAMP WITH TIME ZONE,
    sampled_by          VARCHAR(36) REFERENCES users(id),
    -- Results
    conductivity_us_cm  DECIMAL(10,4),
    toc_ppb             DECIMAL(10,4),
    ph                  DECIMAL(5,3),
    bioburden_cfu_ml    DECIMAL(10,2),
    endotoxin_eu_ml     DECIMAL(10,4),
    -- Alert/Action
    conductivity_status VARCHAR(20),
    toc_status          VARCHAR(20),
    bioburden_status    VARCHAR(20),
    endotoxin_status    VARCHAR(20),
    overall_status      VARCHAR(50), -- pass, alert, action, fail
    investigation_id    VARCHAR(36) REFERENCES lims_oos_investigations(id),
    notes               TEXT,
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    reviewed_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.13 REAGENTS & PREPARED SOLUTIONS
-- ─────────────────────────────────────────
CREATE TABLE lims_reagents (
    id                  VARCHAR(36) PRIMARY KEY,
    catalog_number      VARCHAR(200) NOT NULL,
    name                VARCHAR(300) NOT NULL,
    reagent_grade       VARCHAR(100), -- HPLC, ACS, analytical, technical
    supplier            VARCHAR(200),
    current_lot         VARCHAR(200),
    quantity_on_hand    DECIMAL(10,4),
    unit                VARCHAR(50),
    location_id         VARCHAR(36) REFERENCES lims_storage_units(id),
    storage_conditions  VARCHAR(200),
    expiry_date         DATE,
    hazard_class        VARCHAR(100),
    sds_ref             VARCHAR(200),
    minimum_stock_level DECIMAL(10,4),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_reagent_lots (
    id                  VARCHAR(36) PRIMARY KEY,
    reagent_id          VARCHAR(36) NOT NULL REFERENCES lims_reagents(id),
    lot_number          VARCHAR(200) NOT NULL,
    supplier_lot        VARCHAR(200),
    quantity_received   DECIMAL(10,4),
    quantity_remaining  DECIMAL(10,4),
    unit                VARCHAR(50),
    received_date       DATE,
    expiry_date         DATE,
    coa_ref             VARCHAR(200),
    is_tested           BOOLEAN DEFAULT FALSE,
    test_result_id      VARCHAR(36),
    status              VARCHAR(50) DEFAULT 'available',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_prepared_solutions (
    id                  VARCHAR(36) PRIMARY KEY,
    solution_number     VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    solution_type       VARCHAR(100), -- mobile_phase, buffer, titrant, diluent, standard_solution, reagent_solution
    concentration       VARCHAR(200),
    volume_prepared_ml  DECIMAL(10,2),
    prepared_by         VARCHAR(36) REFERENCES users(id),
    prepared_at         TIMESTAMP WITH TIME ZONE,
    expiry_date         DATE,
    expiry_time         TIMESTAMP WITH TIME ZONE,
    storage_conditions  VARCHAR(200),
    preparation_sop     VARCHAR(200),
    calculation_shown   TEXT,
    status              VARCHAR(50) DEFAULT 'active', -- active, expired, discarded
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_solution_components (
    id                  VARCHAR(36) PRIMARY KEY,
    solution_id         VARCHAR(36) NOT NULL REFERENCES lims_prepared_solutions(id),
    component_type      VARCHAR(50), -- reagent, standard, solution
    reagent_id          VARCHAR(36) REFERENCES lims_reagents(id),
    reagent_lot_id      VARCHAR(36) REFERENCES lims_reagent_lots(id),
    standard_id         VARCHAR(36) REFERENCES lims_reference_standards(id),
    parent_solution_id  VARCHAR(36) REFERENCES lims_prepared_solutions(id),
    quantity_used       DECIMAL(10,6),
    unit                VARCHAR(50),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.14 CERTIFICATE OF ANALYSIS
-- ─────────────────────────────────────────
CREATE TABLE lims_certificates_of_analysis (
    id                  VARCHAR(36) PRIMARY KEY,
    coa_number          VARCHAR(100) NOT NULL UNIQUE,
    coa_type            VARCHAR(50), -- release, stability, retest, supplier
    product_name        VARCHAR(300),
    product_code        VARCHAR(100),
    batch_number        VARCHAR(100),
    batch_quantity      VARCHAR(200),
    manufacturing_date  DATE,
    expiry_date         DATE,
    release_date        DATE,
    spec_id             VARCHAR(36) REFERENCES lims_specifications(id),
    -- Status
    status              VARCHAR(50) DEFAULT 'draft', -- draft, pending_approval, approved, issued, recalled
    approved_by         VARCHAR(36) REFERENCES users(id),
    approved_at         TIMESTAMP WITH TIME ZONE,
    issued_by           VARCHAR(36) REFERENCES users(id),
    issued_at           TIMESTAMP WITH TIME ZONE,
    -- Template
    template_id         VARCHAR(36),
    -- Content
    compliance_statement TEXT,
    notes               TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_coa_line_items (
    id                  VARCHAR(36) PRIMARY KEY,
    coa_id              VARCHAR(36) NOT NULL REFERENCES lims_certificates_of_analysis(id),
    test_name           VARCHAR(300) NOT NULL,
    method_ref          VARCHAR(200),
    acceptance_criteria VARCHAR(500),
    result              VARCHAR(500),
    unit                VARCHAR(100),
    result_status       VARCHAR(50), -- complies, does_not_comply, not_tested
    result_id           VARCHAR(36) REFERENCES lims_test_results(id),
    sequence_number     INTEGER,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_coa_distributions (
    id                  VARCHAR(36) PRIMARY KEY,
    coa_id              VARCHAR(36) NOT NULL REFERENCES lims_certificates_of_analysis(id),
    recipient_name      VARCHAR(300),
    recipient_company   VARCHAR(300),
    recipient_email     VARCHAR(200),
    distribution_method VARCHAR(100), -- email, portal, physical, API
    distributed_at      TIMESTAMP WITH TIME ZONE,
    access_token        VARCHAR(200) UNIQUE,
    accessed_at         TIMESTAMP WITH TIME ZONE,
    notes               VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.15 MICROBIOLOGY SPECIFIC
-- ─────────────────────────────────────────
CREATE TABLE lims_sterility_tests (
    id                  VARCHAR(36) PRIMARY KEY,
    test_number         VARCHAR(100) NOT NULL UNIQUE,
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    method              VARCHAR(100), -- membrane_filtration, direct_inoculation
    sop_ref             VARCHAR(200),
    analyst_id          VARCHAR(36) REFERENCES users(id),
    started_at          TIMESTAMP WITH TIME ZONE,
    incubation_period_days INTEGER DEFAULT 14,
    incubation_temp_fluid DECIMAL(5,2) DEFAULT 32.5,
    incubation_temp_solid DECIMAL(5,2) DEFAULT 22.5,
    -- Controls
    positive_control    VARCHAR(200),
    negative_control    VARCHAR(200),
    bacteriostasis_pass BOOLEAN,
    fungistasis_pass    BOOLEAN,
    -- Result
    fluid_thioglycollate_result VARCHAR(50), -- sterile, fail, invalid
    soybean_casein_result VARCHAR(50),
    overall_result      VARCHAR(50), -- sterile, fail, invalid
    result_date         DATE,
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_bioburden_results (
    id                  VARCHAR(36) PRIMARY KEY,
    test_number         VARCHAR(100) NOT NULL UNIQUE,
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    method              VARCHAR(100), -- membrane_filtration, pour_plate, spread_plate
    analyst_id          VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    -- Results
    aerobic_count_cfu   DECIMAL(10,2),
    aerobic_unit        VARCHAR(50), -- CFU/ml, CFU/g, CFU/cm2
    fungi_count_cfu     DECIMAL(10,2),
    specified_organisms TEXT, -- JSON: E.coli, Salmonella, etc. results
    -- Limits
    aerobic_limit       DECIMAL(10,2),
    fungi_limit         DECIMAL(10,2),
    result_status       VARCHAR(50),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_endotoxin_results (
    id                  VARCHAR(36) PRIMARY KEY,
    test_number         VARCHAR(100) NOT NULL UNIQUE,
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    method              VARCHAR(100), -- gel_clot, turbidimetric_kinetic, chromogenic, rFC
    analyst_id          VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    dilution_factor     DECIMAL(10,4),
    endotoxin_eu_ml     DECIMAL(10,6),
    endotoxin_eu_dose   DECIMAL(10,6),
    limit_eu_ml         DECIMAL(10,6),
    limit_basis         VARCHAR(200),
    mvd_calculated      DECIMAL(10,2),
    inhibition_enhancement_pass BOOLEAN,
    positive_control_pass BOOLEAN,
    negative_control_pass BOOLEAN,
    result_status       VARCHAR(50),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.16 LIMS INTEGRATION CONNECTORS
-- ─────────────────────────────────────────
CREATE TABLE lims_external_connectors (
    id                  VARCHAR(36) PRIMARY KEY,
    connector_name      VARCHAR(200) NOT NULL,
    connector_type      VARCHAR(100), -- LabVantage, Sapio, LabWare, STARLIMS, custom
    version             VARCHAR(100),
    endpoint_url        VARCHAR(1000),
    auth_type           VARCHAR(50), -- API_key, OAuth2, SAML, basic
    is_active           BOOLEAN DEFAULT TRUE,
    sync_direction      VARCHAR(50), -- inbound, outbound, bidirectional
    sync_entities       TEXT, -- JSON: ["samples","results","specs"]
    last_sync_at        TIMESTAMP WITH TIME ZONE,
    sync_status         VARCHAR(50),
    site_id             VARCHAR(36) REFERENCES sites(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE lims_connector_sync_logs (
    id                  VARCHAR(36) PRIMARY KEY,
    connector_id        VARCHAR(36) NOT NULL REFERENCES lims_external_connectors(id),
    sync_started_at     TIMESTAMP WITH TIME ZONE,
    sync_completed_at   TIMESTAMP WITH TIME ZONE,
    records_sent        INTEGER DEFAULT 0,
    records_received    INTEGER DEFAULT 0,
    errors_count        INTEGER DEFAULT 0,
    error_details       TEXT,
    status              VARCHAR(50),
    triggered_by        VARCHAR(100), -- scheduled, manual, webhook
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.17 WORKLOAD & TURNAROUND
-- ─────────────────────────────────────────
CREATE TABLE lims_analyst_workloads (
    id                  VARCHAR(36) PRIMARY KEY,
    analyst_id          VARCHAR(36) NOT NULL REFERENCES users(id),
    date                DATE NOT NULL,
    pending_tests       INTEGER DEFAULT 0,
    in_progress_tests   INTEGER DEFAULT 0,
    completed_tests     INTEGER DEFAULT 0,
    overdue_tests       INTEGER DEFAULT 0,
    capacity_hours      DECIMAL(5,2) DEFAULT 8.0,
    utilized_hours      DECIMAL(5,2) DEFAULT 0,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(analyst_id, date)
);

CREATE TABLE lims_turnaround_tracking (
    id                  VARCHAR(36) PRIMARY KEY,
    request_id          VARCHAR(36) NOT NULL REFERENCES lims_test_requests(id),
    target_hours        INTEGER,
    actual_hours        DECIMAL(8,2),
    is_on_time          BOOLEAN,
    delay_reason        VARCHAR(300),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 12.18 LIMS AUDIT TRAIL (dedicated)
-- ─────────────────────────────────────────
CREATE TABLE lims_audit_entries (
    id                  VARCHAR(36) PRIMARY KEY,
    entity_type         VARCHAR(100) NOT NULL,
    entity_id           VARCHAR(36) NOT NULL,
    action              VARCHAR(100) NOT NULL,
    field_name          VARCHAR(200),
    old_value           TEXT,
    new_value           TEXT,
    reason              TEXT,
    user_id             VARCHAR(36) REFERENCES users(id),
    user_name           VARCHAR(300),
    ip_address          VARCHAR(50),
    session_id          VARCHAR(200),
    performed_at        TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    hash_chain          VARCHAR(64) -- SHA-256 chain link
);
