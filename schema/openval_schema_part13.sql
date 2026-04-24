-- ============================================================
-- PHAROLON Schema Part 13 — Native MES
-- Manufacturing Execution System
-- Targets: all pharma MFG — discrete, bioprocess, ATMP, CM
-- Regulatory: 21 CFR 210/211, EU GMP, ICH Q7/Q8/Q10/Q13
-- ============================================================

-- ─────────────────────────────────────────
-- 13.01 MASTER BATCH RECORDS (MBR)
-- ─────────────────────────────────────────
CREATE TABLE mes_master_batch_records (
    id                  VARCHAR(36) PRIMARY KEY,
    mbr_number          VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300) NOT NULL,
    version             VARCHAR(50) NOT NULL DEFAULT '1.0',
    status              VARCHAR(50) DEFAULT 'draft', -- draft, review, approved, obsolete
    product_id          VARCHAR(36),
    product_name        VARCHAR(300),
    product_code        VARCHAR(100),
    dosage_form         VARCHAR(100), -- tablet, capsule, liquid, lyophilized, semi-solid, biological
    process_type        VARCHAR(100), -- synthetic, biological, sterile, non_sterile, ATMP, continuous
    -- Batch sizing
    batch_size          DECIMAL(14,4),
    batch_size_unit     VARCHAR(50),
    batch_size_min      DECIMAL(14,4),
    batch_size_max      DECIMAL(14,4),
    -- Process
    theoretical_yield   DECIMAL(8,4),
    yield_unit          VARCHAR(50),
    yield_acceptable_range VARCHAR(100),
    total_steps         INTEGER DEFAULT 0,
    estimated_duration_hours DECIMAL(8,2),
    -- Regulatory
    registration_ref    VARCHAR(200),
    manufacturing_site  VARCHAR(200),
    -- Approval
    prepared_by         VARCHAR(36) REFERENCES users(id),
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    approved_by         VARCHAR(36) REFERENCES users(id),
    approved_at         TIMESTAMP WITH TIME ZONE,
    effective_date      DATE,
    supersedes_id       VARCHAR(36) REFERENCES mes_master_batch_records(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_mbr_versions (
    id                  VARCHAR(36) PRIMARY KEY,
    mbr_id              VARCHAR(36) NOT NULL REFERENCES mes_master_batch_records(id),
    version             VARCHAR(50) NOT NULL,
    change_type         VARCHAR(100), -- minor, major, critical
    change_description  TEXT,
    changed_by          VARCHAR(36) REFERENCES users(id),
    approved_by         VARCHAR(36) REFERENCES users(id),
    approved_at         TIMESTAMP WITH TIME ZONE,
    content_snapshot    TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_mbr_phases (
    id                  VARCHAR(36) PRIMARY KEY,
    mbr_id              VARCHAR(36) NOT NULL REFERENCES mes_master_batch_records(id),
    phase_number        INTEGER NOT NULL,
    phase_code          VARCHAR(100),
    name                VARCHAR(300) NOT NULL,
    phase_type          VARCHAR(100), -- granulation, blending, compression, coating, filling, sterilization, inspection
    description         TEXT,
    estimated_duration_hours DECIMAL(8,2),
    requires_separate_approval BOOLEAN DEFAULT FALSE,
    sequence_order      INTEGER,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_mbr_steps (
    id                  VARCHAR(36) PRIMARY KEY,
    mbr_id              VARCHAR(36) NOT NULL REFERENCES mes_master_batch_records(id),
    phase_id            VARCHAR(36) REFERENCES mes_mbr_phases(id),
    step_number         VARCHAR(20) NOT NULL, -- e.g., "3.2.1"
    title               VARCHAR(300) NOT NULL,
    step_type           VARCHAR(100), -- instruction, verification, ipc, equipment_prep, material_addition, sampling, sign_off
    instructions        TEXT NOT NULL,
    -- Parameters
    parameters          TEXT, -- JSON: [{name, target, min, max, unit, is_cpp}]
    -- Verification
    requires_verification BOOLEAN DEFAULT FALSE,
    verifier_role       VARCHAR(100),
    is_critical_step    BOOLEAN DEFAULT FALSE,
    -- IPC
    has_ipc             BOOLEAN DEFAULT FALSE,
    ipc_frequency       VARCHAR(100),
    -- Time controls
    time_limit_minutes  INTEGER,
    hold_time_max_hours DECIMAL(8,2),
    -- Conditional
    is_conditional      BOOLEAN DEFAULT FALSE,
    condition_logic     TEXT,
    -- Materials
    materials_required  TEXT, -- JSON array
    equipment_required  TEXT, -- JSON array
    sequence_order      INTEGER,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.02 BILL OF MATERIALS
-- ─────────────────────────────────────────
CREATE TABLE mes_bill_of_materials (
    id                  VARCHAR(36) PRIMARY KEY,
    mbr_id              VARCHAR(36) NOT NULL REFERENCES mes_master_batch_records(id),
    version             VARCHAR(50) DEFAULT '1.0',
    is_current          BOOLEAN DEFAULT TRUE,
    approved_by         VARCHAR(36) REFERENCES users(id),
    approved_at         TIMESTAMP WITH TIME ZONE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_bom_items (
    id                  VARCHAR(36) PRIMARY KEY,
    bom_id              VARCHAR(36) NOT NULL REFERENCES mes_bill_of_materials(id),
    line_number         INTEGER,
    material_code       VARCHAR(100) NOT NULL,
    material_name       VARCHAR(300) NOT NULL,
    material_type       VARCHAR(100), -- API, excipient, solvent, packaging, process_aid, label
    quantity_per_batch  DECIMAL(16,8) NOT NULL,
    quantity_unit       VARCHAR(50) NOT NULL,
    quantity_overages   DECIMAL(8,4), -- % overage
    quantity_with_overage DECIMAL(16,8),
    grade_required      VARCHAR(100),
    spec_id             VARCHAR(36),
    is_critical         BOOLEAN DEFAULT FALSE,
    usage_in_step_ids   TEXT, -- JSON array of step IDs
    substitutions_allowed BOOLEAN DEFAULT FALSE,
    substitute_codes    TEXT, -- JSON array
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.03 PRODUCTS & MATERIALS REGISTRY (MES)
-- ─────────────────────────────────────────
CREATE TABLE mes_products (
    id                  VARCHAR(36) PRIMARY KEY,
    product_code        VARCHAR(100) NOT NULL UNIQUE,
    product_name        VARCHAR(300) NOT NULL,
    product_family      VARCHAR(200),
    therapeutic_area    VARCHAR(200),
    dosage_form         VARCHAR(100),
    strength            VARCHAR(200),
    route_of_administration VARCHAR(100),
    -- Regulatory
    regulatory_status   VARCHAR(100), -- commercial, clinical, development, discontinued
    registration_numbers TEXT, -- JSON: {US:"NDA123", EU:"EU/1/XX", JP:"XX"}
    product_type        VARCHAR(100), -- small_molecule, biologic, ATMP, biosimilar, generic
    -- Manufacturing
    manufacturing_category VARCHAR(100), -- sterile, non_sterile, controlled
    dea_schedule        VARCHAR(50),
    cold_chain_required BOOLEAN DEFAULT FALSE,
    storage_conditions  VARCHAR(200),
    -- Commercial
    brand_name          VARCHAR(200),
    inn_name            VARCHAR(200),
    cas_number          VARCHAR(100),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active           BOOLEAN DEFAULT TRUE
);

CREATE TABLE mes_materials (
    id                  VARCHAR(36) PRIMARY KEY,
    material_code       VARCHAR(100) NOT NULL UNIQUE,
    material_name       VARCHAR(300) NOT NULL,
    material_type       VARCHAR(100),
    cas_number          VARCHAR(100),
    pharmacopeial_grade VARCHAR(100),
    hazard_classification VARCHAR(200),
    controlled_substance BOOLEAN DEFAULT FALSE,
    requires_cold_chain BOOLEAN DEFAULT FALSE,
    storage_temperature VARCHAR(100),
    retest_period_months INTEGER,
    shelf_life_months   INTEGER,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_material_lots (
    id                  VARCHAR(36) PRIMARY KEY,
    material_id         VARCHAR(36) NOT NULL REFERENCES mes_materials(id),
    lot_number          VARCHAR(200) NOT NULL,
    supplier_id         VARCHAR(36),
    supplier_lot        VARCHAR(200),
    po_number           VARCHAR(100),
    -- Quantity
    quantity_received   DECIMAL(16,6),
    quantity_available  DECIMAL(16,6),
    quantity_reserved   DECIMAL(16,6),
    quantity_used       DECIMAL(16,6),
    quantity_unit       VARCHAR(50),
    -- Dates
    received_date       DATE,
    manufacture_date    DATE,
    retest_date         DATE,
    expiry_date         DATE NOT NULL,
    -- Status
    status              VARCHAR(50) DEFAULT 'quarantine', -- quarantine, released, rejected, expired, recalled
    release_date        DATE,
    released_by         VARCHAR(36) REFERENCES users(id),
    -- Quality
    coa_ref             VARCHAR(200),
    spec_id             VARCHAR(36),
    -- Storage
    storage_location    VARCHAR(200),
    storage_conditions  VARCHAR(200),
    -- Traceability
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    site_id             VARCHAR(36) REFERENCES sites(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(material_id, lot_number)
);

-- ─────────────────────────────────────────
-- 13.04 PRODUCTION ORDERS & SCHEDULING
-- ─────────────────────────────────────────
CREATE TABLE mes_production_orders (
    id                  VARCHAR(36) PRIMARY KEY,
    order_number        VARCHAR(100) NOT NULL UNIQUE,
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    mbr_id              VARCHAR(36) REFERENCES mes_master_batch_records(id),
    batch_number        VARCHAR(100) NOT NULL,
    batch_size          DECIMAL(14,4),
    batch_size_unit     VARCHAR(50),
    -- Scheduling
    planned_start_date  DATE,
    planned_end_date    DATE,
    actual_start_date   DATE,
    actual_end_date     DATE,
    manufacturing_area  VARCHAR(200),
    campaign_id         VARCHAR(36),
    -- Priority & Type
    order_type          VARCHAR(100), -- commercial, clinical, validation, development, reprocess
    priority            INTEGER DEFAULT 5,
    -- Status
    status              VARCHAR(50) DEFAULT 'planned', -- planned, released, in_progress, complete, cancelled, rejected
    -- Demand
    demand_reference    VARCHAR(200),
    customer_ref        VARCHAR(200),
    -- Notes
    special_instructions TEXT,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    site_id             VARCHAR(36) REFERENCES sites(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by          VARCHAR(36) REFERENCES users(id),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_campaigns (
    id                  VARCHAR(36) PRIMARY KEY,
    campaign_code       VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300),
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    campaign_type       VARCHAR(100), -- multi_batch, dedicated_equipment, clinical
    planned_batches     INTEGER,
    completed_batches   INTEGER DEFAULT 0,
    start_date          DATE,
    end_date            DATE,
    manufacturing_area  VARCHAR(200),
    status              VARCHAR(50) DEFAULT 'planned',
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.05 ELECTRONIC BATCH RECORDS (eBR)
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_records (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_number VARCHAR(100) NOT NULL UNIQUE,
    production_order_id VARCHAR(36) NOT NULL REFERENCES mes_production_orders(id),
    mbr_id              VARCHAR(36) NOT NULL REFERENCES mes_master_batch_records(id),
    mbr_version         VARCHAR(50),
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    batch_number        VARCHAR(100) NOT NULL,
    batch_size_actual   DECIMAL(14,4),
    batch_size_unit     VARCHAR(50),
    -- Status
    status              VARCHAR(50) DEFAULT 'initiated', -- initiated, in_progress, complete, under_review, approved, rejected
    -- Dates
    manufacturing_date  DATE,
    expiry_date         DATE,
    -- Yield
    theoretical_yield   DECIMAL(14,4),
    actual_yield        DECIMAL(14,4),
    yield_percentage    DECIMAL(6,3),
    yield_status        VARCHAR(50), -- acceptable, low, high, requires_investigation
    -- Review & Release
    qa_review_by        VARCHAR(36) REFERENCES users(id),
    qa_review_at        TIMESTAMP WITH TIME ZONE,
    qa_review_status    VARCHAR(50),
    qa_review_comments  TEXT,
    released_by         VARCHAR(36) REFERENCES users(id),
    released_at         TIMESTAMP WITH TIME ZONE,
    -- Exception summary
    deviation_count     INTEGER DEFAULT 0,
    open_deviations     INTEGER DEFAULT 0,
    -- Manufacturing area
    manufacturing_area_id VARCHAR(36),
    site_id             VARCHAR(36) REFERENCES sites(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_batch_record_steps (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    mbr_step_id         VARCHAR(36) REFERENCES mes_mbr_steps(id),
    step_number         VARCHAR(20) NOT NULL,
    title               VARCHAR(300),
    instructions        TEXT,
    -- Execution
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    performed_by        VARCHAR(36) REFERENCES users(id),
    -- Verification
    verified_by         VARCHAR(36) REFERENCES users(id),
    verified_at         TIMESTAMP WITH TIME ZONE,
    verification_comment TEXT,
    -- Status
    status              VARCHAR(50) DEFAULT 'pending', -- pending, in_progress, complete, skipped, deviated
    is_deviated         BOOLEAN DEFAULT FALSE,
    deviation_id        VARCHAR(36),
    -- Operator comments
    operator_comments   TEXT,
    actual_duration_minutes INTEGER,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_batch_record_parameters (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    parameter_name      VARCHAR(300) NOT NULL,
    is_cpp              BOOLEAN DEFAULT FALSE,
    -- Limits
    target_value        DECIMAL(20,8),
    lower_limit         DECIMAL(20,8),
    upper_limit         DECIMAL(20,8),
    unit                VARCHAR(100),
    -- Actual
    actual_value        DECIMAL(20,8),
    actual_text         VARCHAR(500),
    recorded_at         TIMESTAMP WITH TIME ZONE,
    recorded_by         VARCHAR(36) REFERENCES users(id),
    -- Assessment
    within_limits       BOOLEAN,
    deviation_id        VARCHAR(36),
    notes               VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_batch_record_signatures (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    signature_type      VARCHAR(100), -- operator, verifier, supervisor, qa_review, batch_release
    meaning             VARCHAR(300),
    signed_by           VARCHAR(36) REFERENCES users(id),
    signed_at           TIMESTAMP WITH TIME ZONE,
    signature_hash      VARCHAR(64),
    ip_address          VARCHAR(50),
    comments            VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.06 MATERIAL DISPENSING & WEIGHING
-- ─────────────────────────────────────────
CREATE TABLE mes_material_dispensing_records (
    id                  VARCHAR(36) PRIMARY KEY,
    dispensing_number   VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    bom_item_id         VARCHAR(36) REFERENCES mes_bom_items(id),
    -- Material
    material_id         VARCHAR(36) REFERENCES mes_materials(id),
    material_lot_id     VARCHAR(36) REFERENCES mes_material_lots(id),
    material_name       VARCHAR(300),
    -- Quantities
    quantity_required   DECIMAL(16,8),
    quantity_dispensed  DECIMAL(16,8),
    quantity_unit       VARCHAR(50),
    quantity_difference DECIMAL(16,8),
    within_tolerance    BOOLEAN,
    tolerance_pct       DECIMAL(6,3),
    -- Weighing
    tare_weight         DECIMAL(16,8),
    gross_weight        DECIMAL(16,8),
    net_weight          DECIMAL(16,8),
    weight_unit         VARCHAR(50),
    balance_id          VARCHAR(36) REFERENCES lims_instruments(id),
    balance_calibration_valid BOOLEAN,
    -- Personnel
    dispensed_by        VARCHAR(36) REFERENCES users(id),
    verified_by         VARCHAR(36) REFERENCES users(id),
    dispensed_at        TIMESTAMP WITH TIME ZONE,
    -- Container
    container_id        VARCHAR(36),
    container_label     VARCHAR(200),
    -- Status
    status              VARCHAR(50) DEFAULT 'complete',
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_material_reconciliation (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    material_id         VARCHAR(36) REFERENCES mes_materials(id),
    material_lot_id     VARCHAR(36) REFERENCES mes_material_lots(id),
    quantity_dispensed  DECIMAL(16,8),
    quantity_in_product DECIMAL(16,8),
    quantity_waste      DECIMAL(16,8),
    quantity_sample     DECIMAL(16,8),
    quantity_returned   DECIMAL(16,8),
    quantity_unaccounted DECIMAL(16,8),
    reconciliation_pct  DECIMAL(8,4),
    is_acceptable       BOOLEAN,
    acceptable_range    VARCHAR(100),
    performed_by        VARCHAR(36) REFERENCES users(id),
    verified_by         VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.07 EQUIPMENT REGISTRY (MES)
-- ─────────────────────────────────────────
CREATE TABLE mes_equipment (
    id                  VARCHAR(36) PRIMARY KEY,
    equipment_id_code   VARCHAR(100) NOT NULL UNIQUE,
    equipment_name      VARCHAR(300) NOT NULL,
    equipment_type      VARCHAR(100), -- reactor, mixer, blender, granulator, dryer, compressor, filling, autoclave, lyophilizer, bioreactor, centrifuge, CIP, SIP
    manufacturer        VARCHAR(200),
    model               VARCHAR(200),
    serial_number       VARCHAR(200),
    asset_tag           VARCHAR(100),
    -- Location
    area_id             VARCHAR(36),
    room                VARCHAR(100),
    site_id             VARCHAR(36) REFERENCES sites(id),
    -- Capacity
    working_volume_min  DECIMAL(12,4),
    working_volume_max  DECIMAL(12,4),
    volume_unit         VARCHAR(50),
    -- Status
    status              VARCHAR(50) DEFAULT 'available', -- available, in_use, cleaning, maintenance, qualification, quarantine, retired
    current_batch_id    VARCHAR(36) REFERENCES mes_batch_records(id),
    -- Qualification
    is_qualified        BOOLEAN DEFAULT FALSE,
    qualification_status VARCHAR(50),
    iq_ref              VARCHAR(200),
    oq_ref              VARCHAR(200),
    pq_ref              VARCHAR(200),
    requalification_due DATE,
    -- Cleaning
    cleaning_procedure_ref VARCHAR(200),
    cleaning_status     VARCHAR(50), -- dirty, cleaning_in_progress, cleaned, released
    cleaned_at          TIMESTAMP WITH TIME ZONE,
    next_cleaning_due   TIMESTAMP WITH TIME ZONE,
    -- Calibration
    requires_calibration BOOLEAN DEFAULT FALSE,
    calibration_due     DATE,
    -- Maintenance
    maintenance_due     DATE,
    -- Dedicated use
    is_dedicated        BOOLEAN DEFAULT FALSE,
    dedicated_to_product VARCHAR(200),
    -- Notes
    notes               TEXT,
    is_active           BOOLEAN DEFAULT TRUE,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_equipment_use_logs (
    id                  VARCHAR(36) PRIMARY KEY,
    equipment_id        VARCHAR(36) NOT NULL REFERENCES mes_equipment(id),
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    started_at          TIMESTAMP WITH TIME ZONE,
    ended_at            TIMESTAMP WITH TIME ZONE,
    operator_id         VARCHAR(36) REFERENCES users(id),
    purpose             VARCHAR(300),
    status_before       VARCHAR(50),
    status_after        VARCHAR(50),
    -- Readings
    run_hours           DECIMAL(8,2),
    parameters_recorded TEXT, -- JSON
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_equipment_cleaning_records (
    id                  VARCHAR(36) PRIMARY KEY,
    equipment_id        VARCHAR(36) NOT NULL REFERENCES mes_equipment(id),
    cleaning_number     VARCHAR(100) NOT NULL UNIQUE,
    cleaning_type       VARCHAR(100), -- manual, CIP, SIP, automated
    cleaning_procedure  VARCHAR(200),
    previous_product    VARCHAR(200),
    previous_batch      VARCHAR(200),
    -- Execution
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    cleaned_by          VARCHAR(36) REFERENCES users(id),
    verified_by         VARCHAR(36) REFERENCES users(id),
    cleaning_agent      VARCHAR(200),
    rinse_agent         VARCHAR(200),
    -- Verification
    visual_pass         BOOLEAN,
    analytical_required BOOLEAN DEFAULT FALSE,
    swab_sample_id      VARCHAR(36) REFERENCES lims_samples(id),
    rinse_sample_id     VARCHAR(36) REFERENCES lims_samples(id),
    swab_result         VARCHAR(50),
    rinse_result        VARCHAR(50),
    -- Release
    released_for_use    BOOLEAN DEFAULT FALSE,
    released_by         VARCHAR(36) REFERENCES users(id),
    released_at         TIMESTAMP WITH TIME ZONE,
    next_product        VARCHAR(200),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_line_clearances (
    id                  VARCHAR(36) PRIMARY KEY,
    clearance_number    VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    area_id             VARCHAR(36),
    clearance_type      VARCHAR(50), -- pre_production, post_production, changeover
    -- Previous batch
    previous_product    VARCHAR(200),
    previous_batch      VARCHAR(200),
    -- Checks
    previous_labels_removed BOOLEAN,
    previous_materials_removed BOOLEAN,
    equipment_clean     BOOLEAN,
    area_clean          BOOLEAN,
    documentation_complete BOOLEAN,
    -- Personnel
    performed_by        VARCHAR(36) REFERENCES users(id),
    verified_by         VARCHAR(36) REFERENCES users(id),
    qa_confirmed_by     VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    verified_at         TIMESTAMP WITH TIME ZONE,
    -- Result
    clearance_granted   BOOLEAN DEFAULT FALSE,
    discrepancies_found TEXT,
    resolution          TEXT,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.08 FACILITIES & MANUFACTURING AREAS
-- ─────────────────────────────────────────
CREATE TABLE mes_manufacturing_areas (
    id                  VARCHAR(36) PRIMARY KEY,
    area_code           VARCHAR(100) NOT NULL UNIQUE,
    area_name           VARCHAR(300) NOT NULL,
    area_type           VARCHAR(100), -- manufacturing, packaging, warehouse, QC_lab, utility, corridor
    clean_room_class    VARCHAR(50), -- ISO_5, ISO_6, ISO_7, ISO_8, grade_A, grade_B, grade_C, grade_D, unclassified
    eu_gmp_grade        VARCHAR(10),
    -- HVAC
    air_changes_per_hour INTEGER,
    pressure_differential VARCHAR(50),
    temperature_range   VARCHAR(50),
    humidity_range      VARCHAR(50),
    -- Gowning
    gowning_level       VARCHAR(100),
    gowning_procedure_ref VARCHAR(200),
    -- Status
    status              VARCHAR(50) DEFAULT 'available', -- available, occupied, cleaning, maintenance, qualification
    current_batch_id    VARCHAR(36) REFERENCES mes_batch_records(id),
    -- Qualification
    is_qualified        BOOLEAN DEFAULT FALSE,
    qualification_ref   VARCHAR(200),
    requalification_due DATE,
    site_id             VARCHAR(36) REFERENCES sites(id),
    floor_plan_ref      VARCHAR(500),
    area_sqm            DECIMAL(10,2),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_room_logs (
    id                  VARCHAR(36) PRIMARY KEY,
    area_id             VARCHAR(36) NOT NULL REFERENCES mes_manufacturing_areas(id),
    log_date            DATE NOT NULL,
    entry_time          TIMESTAMP WITH TIME ZONE,
    exit_time           TIMESTAMP WITH TIME ZONE,
    person_id           VARCHAR(36) REFERENCES users(id),
    person_name         VARCHAR(300),
    activity            VARCHAR(300),
    batch_reference     VARCHAR(200),
    notes               VARCHAR(500),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_hvac_readings (
    id                  VARCHAR(36) PRIMARY KEY,
    area_id             VARCHAR(36) NOT NULL REFERENCES mes_manufacturing_areas(id),
    recorded_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    temperature_c       DECIMAL(6,3),
    humidity_pct        DECIMAL(6,3),
    pressure_pa         DECIMAL(8,3),
    particle_count_05   BIGINT,  -- 0.5 micron per m3
    particle_count_5    BIGINT,  -- 5.0 micron per m3
    air_velocity_ms     DECIMAL(6,3),
    hepa_dp_pa          DECIMAL(8,3),
    all_within_limits   BOOLEAN,
    alert_triggered     BOOLEAN DEFAULT FALSE,
    source              VARCHAR(100), -- BMS, manual, BAS
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.09 IN-PROCESS CONTROLS (IPC)
-- ─────────────────────────────────────────
CREATE TABLE mes_ipc_tests (
    id                  VARCHAR(36) PRIMARY KEY,
    ipc_number          VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    test_name           VARCHAR(300) NOT NULL,
    test_type           VARCHAR(100), -- hardness, friability, dissolution, weight, appearance, pH, viscosity, fill_weight, seal_integrity
    is_cqa              BOOLEAN DEFAULT FALSE,
    -- Sampling
    sample_size         INTEGER,
    sample_frequency    VARCHAR(100),
    sample_time         TIMESTAMP WITH TIME ZONE,
    sampled_by          VARCHAR(36) REFERENCES users(id),
    instrument_id       VARCHAR(36) REFERENCES lims_instruments(id),
    -- Limits
    lower_limit         DECIMAL(20,8),
    upper_limit         DECIMAL(20,8),
    target_value        DECIMAL(20,8),
    unit                VARCHAR(100),
    limit_type          VARCHAR(50),
    -- Result
    result_value        DECIMAL(20,8),
    result_text         VARCHAR(500),
    result_status       VARCHAR(50), -- pass, fail, borderline, invalid
    -- Action
    action_required     VARCHAR(100), -- continue, adjust, resample, stop
    action_taken        TEXT,
    -- Deviation
    deviation_raised    BOOLEAN DEFAULT FALSE,
    deviation_id        VARCHAR(36),
    -- Review
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_ipc_individual_results (
    id                  VARCHAR(36) PRIMARY KEY,
    ipc_test_id         VARCHAR(36) NOT NULL REFERENCES mes_ipc_tests(id),
    unit_number         INTEGER,
    value               DECIMAL(20,8),
    is_outlier          BOOLEAN DEFAULT FALSE,
    exclusion_reason    VARCHAR(300),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.10 SPC / PROCESS MONITORING
-- ─────────────────────────────────────────
CREATE TABLE mes_control_charts (
    id                  VARCHAR(36) PRIMARY KEY,
    chart_code          VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300),
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    parameter_name      VARCHAR(300),
    chart_type          VARCHAR(50), -- Xbar_R, Xbar_S, ImR, p, np, c, u, CUSUM, EWMA
    control_limit_basis VARCHAR(100), -- historical, theoretical, specification
    ucl                 DECIMAL(20,8),
    lcl                 DECIMAL(20,8),
    center_line         DECIMAL(20,8),
    uwl                 DECIMAL(20,8), -- Upper Warning Limit
    lwl                 DECIMAL(20,8),
    subgroup_size       INTEGER,
    -- Performance
    cpk                 DECIMAL(8,4),
    ppk                 DECIMAL(8,4),
    cp                  DECIMAL(8,4),
    sigma_level         DECIMAL(6,3),
    -- Status
    is_in_control       BOOLEAN DEFAULT TRUE,
    last_updated        TIMESTAMP WITH TIME ZONE,
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_control_chart_points (
    id                  VARCHAR(36) PRIMARY KEY,
    chart_id            VARCHAR(36) NOT NULL REFERENCES mes_control_charts(id),
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    ipc_test_id         VARCHAR(36) REFERENCES mes_ipc_tests(id),
    value               DECIMAL(20,8),
    subgroup_mean       DECIMAL(20,8),
    subgroup_range      DECIMAL(20,8),
    subgroup_stddev     DECIMAL(20,8),
    recorded_at         TIMESTAMP WITH TIME ZONE,
    -- Rule violations
    rules_violated      TEXT, -- JSON array of rule numbers violated
    is_out_of_control   BOOLEAN DEFAULT FALSE,
    investigation_required BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.11 YIELD & RECONCILIATION
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_yields (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id) UNIQUE,
    -- Theoretical
    theoretical_yield   DECIMAL(14,4),
    theoretical_unit    VARCHAR(50),
    -- Step yields
    step_yields         TEXT, -- JSON: [{step, theoretical, actual, pct}]
    -- Final
    actual_yield_units  DECIMAL(14,4),
    actual_yield_weight DECIMAL(14,4),
    yield_unit          VARCHAR(50),
    yield_pct           DECIMAL(8,4),
    -- Acceptable range
    yield_lower_limit   DECIMAL(8,4),
    yield_upper_limit   DECIMAL(8,4),
    yield_status        VARCHAR(50), -- acceptable, low, high
    -- Reconciliation
    samples_taken_weight DECIMAL(12,4),
    waste_weight        DECIMAL(12,4),
    retained_samples_weight DECIMAL(12,4),
    accounted_pct       DECIMAL(8,4),
    investigation_required BOOLEAN DEFAULT FALSE,
    investigation_id    VARCHAR(36),
    -- Review
    performed_by        VARCHAR(36) REFERENCES users(id),
    reviewed_by         VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.12 MANUFACTURING DEVIATIONS
-- ─────────────────────────────────────────
CREATE TABLE mes_manufacturing_deviations (
    id                  VARCHAR(36) PRIMARY KEY,
    deviation_number    VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    batch_number        VARCHAR(100),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    -- Classification
    deviation_type      VARCHAR(100), -- process_parameter, material, equipment, procedure, environmental, personnel, documentation
    severity            VARCHAR(50), -- critical, major, minor
    is_planned          BOOLEAN DEFAULT FALSE,
    -- Description
    description         TEXT NOT NULL,
    deviation_date      TIMESTAMP WITH TIME ZONE,
    detected_by         VARCHAR(36) REFERENCES users(id),
    -- Impact
    batch_impact        VARCHAR(100), -- none, potential, confirmed
    patient_safety_impact VARCHAR(100),
    product_quality_impact TEXT,
    affected_batches    TEXT,
    -- Investigation
    investigation_summary TEXT,
    root_cause          VARCHAR(300),
    root_cause_category VARCHAR(100),
    -- Disposition
    disposition         VARCHAR(100), -- continue, rework, reject, conditionally_release, quarantine, destroy
    disposition_basis   TEXT,
    disposition_by      VARCHAR(36) REFERENCES users(id),
    disposition_at      TIMESTAMP WITH TIME ZONE,
    -- CAPA
    capa_required       BOOLEAN DEFAULT FALSE,
    capa_id             VARCHAR(36),
    -- Regulatory
    regulatory_notification_required BOOLEAN DEFAULT FALSE,
    regulatory_notified BOOLEAN DEFAULT FALSE,
    -- Status
    status              VARCHAR(50) DEFAULT 'open',
    closed_at           TIMESTAMP WITH TIME ZONE,
    closed_by           VARCHAR(36) REFERENCES users(id),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.13 BATCH RELEASE
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_release_decisions (
    id                  VARCHAR(36) PRIMARY KEY,
    release_number      VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    batch_number        VARCHAR(100) NOT NULL,
    -- Checklist
    ebr_complete        BOOLEAN DEFAULT FALSE,
    all_ipcs_pass       BOOLEAN DEFAULT FALSE,
    all_release_tests_pass BOOLEAN DEFAULT FALSE,
    no_open_deviations  BOOLEAN DEFAULT FALSE,
    label_reconciled    BOOLEAN DEFAULT FALSE,
    yield_acceptable    BOOLEAN DEFAULT FALSE,
    -- QP/QA
    qp_review_by        VARCHAR(36) REFERENCES users(id),
    qp_review_at        TIMESTAMP WITH TIME ZONE,
    qp_comments         TEXT,
    -- Decision
    decision            VARCHAR(50), -- approved, rejected, conditional_release, quarantine
    decision_by         VARCHAR(36) REFERENCES users(id),
    decision_at         TIMESTAMP WITH TIME ZONE,
    rejection_reason    TEXT,
    conditions          TEXT,
    -- Distribution
    release_to_market   BOOLEAN DEFAULT FALSE,
    distribution_regions TEXT,
    -- CoC
    coc_id              VARCHAR(36),
    coa_id              VARCHAR(36),
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.14 BIOPROCESS — BIOREACTOR
-- ─────────────────────────────────────────
CREATE TABLE mes_bioreactors (
    id                  VARCHAR(36) PRIMARY KEY,
    equipment_id        VARCHAR(36) REFERENCES mes_equipment(id),
    bioreactor_code     VARCHAR(100) NOT NULL UNIQUE,
    bioreactor_type     VARCHAR(100), -- stirred_tank, wave_rocking, hollow_fiber, airlift, perfusion
    working_volume_L    DECIMAL(10,3),
    total_volume_L      DECIMAL(10,3),
    vessel_material     VARCHAR(100), -- glass, SS316L, single_use
    is_single_use       BOOLEAN DEFAULT FALSE,
    impeller_type       VARCHAR(100),
    sparger_type        VARCHAR(100),
    -- Sensors
    has_DO_sensor       BOOLEAN DEFAULT TRUE,
    has_pH_sensor       BOOLEAN DEFAULT TRUE,
    has_temp_sensor     BOOLEAN DEFAULT TRUE,
    has_CO2_sensor      BOOLEAN DEFAULT FALSE,
    has_viable_cell_probe BOOLEAN DEFAULT FALSE,
    -- Control
    control_system      VARCHAR(200),
    automation_level    VARCHAR(100), -- manual, semi_auto, fully_auto
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_bioreactor_runs (
    id                  VARCHAR(36) PRIMARY KEY,
    run_number          VARCHAR(100) NOT NULL UNIQUE,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    bioreactor_id       VARCHAR(36) NOT NULL REFERENCES mes_bioreactors(id),
    run_type            VARCHAR(100), -- seed, N_1, N_2, production, perfusion
    culture_type        VARCHAR(100), -- batch, fed_batch, perfusion, chemostat
    -- Cell line
    cell_line_id        VARCHAR(36),
    cell_line_name      VARCHAR(200),
    passage_number      INTEGER,
    seed_vial_id        VARCHAR(36),
    -- Timeline
    inoculation_at      TIMESTAMP WITH TIME ZONE,
    harvest_planned_at  TIMESTAMP WITH TIME ZONE,
    harvest_actual_at   TIMESTAMP WITH TIME ZONE,
    duration_hours      DECIMAL(8,2),
    -- Media
    media_type          VARCHAR(200),
    media_volume_L      DECIMAL(10,3),
    feed_strategy       TEXT,
    -- Setpoints
    temp_setpoint_c     DECIMAL(5,2) DEFAULT 37.0,
    ph_setpoint         DECIMAL(5,3) DEFAULT 7.0,
    do_setpoint_pct     DECIMAL(5,2) DEFAULT 40.0,
    agitation_rpm       INTEGER,
    aeration_vvm        DECIMAL(6,3),
    -- Status
    status              VARCHAR(50) DEFAULT 'inoculated',
    outcome             VARCHAR(100), -- successful, failed, contaminated, aborted, transferred
    failure_reason      TEXT,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_bioreactor_process_data (
    id                  VARCHAR(36) PRIMARY KEY,
    run_id              VARCHAR(36) NOT NULL REFERENCES mes_bioreactor_runs(id),
    recorded_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    elapsed_hours       DECIMAL(8,3),
    -- Critical parameters
    temperature_c       DECIMAL(6,3),
    ph                  DECIMAL(5,3),
    do_pct              DECIMAL(6,3),
    -- Gases
    co2_pct             DECIMAL(6,3),
    o2_supply_lpm       DECIMAL(8,3),
    air_supply_lpm      DECIMAL(8,3),
    n2_supply_lpm       DECIMAL(8,3),
    co2_addition_sccm   DECIMAL(8,3),
    -- Agitation
    agitation_rpm       DECIMAL(8,2),
    tip_speed_ms        DECIMAL(8,4),
    -- Feeds
    base_added_ml       DECIMAL(10,3),
    acid_added_ml       DECIMAL(10,3),
    feed_added_ml       DECIMAL(10,3),
    glucose_added_g     DECIMAL(10,4),
    -- Cell culture (offline samples)
    viable_cell_density  DECIMAL(14,4), -- cells/mL
    total_cell_density  DECIMAL(14,4),
    viability_pct       DECIMAL(6,3),
    glucose_mmol_L      DECIMAL(8,4),
    lactate_mmol_L      DECIMAL(8,4),
    glutamine_mmol_L    DECIMAL(8,4),
    ammonium_mmol_L     DECIMAL(8,4),
    osmolality_mOsmol   DECIMAL(8,2),
    titer_g_L           DECIMAL(10,6),
    -- Alarms
    alarms_active       TEXT,
    source              VARCHAR(50), -- historian, manual, SCADA
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_harvest_records (
    id                  VARCHAR(36) PRIMARY KEY,
    run_id              VARCHAR(36) NOT NULL REFERENCES mes_bioreactor_runs(id),
    harvest_number      VARCHAR(100) NOT NULL UNIQUE,
    harvest_type        VARCHAR(100), -- full, partial, perfusion_bleed
    harvest_at          TIMESTAMP WITH TIME ZONE,
    harvested_by        VARCHAR(36) REFERENCES users(id),
    harvest_volume_L    DECIMAL(10,4),
    -- Final run metrics
    final_vcd           DECIMAL(14,4),
    final_viability_pct DECIMAL(6,3),
    final_titer_g_L     DECIMAL(10,6),
    total_product_g     DECIMAL(12,6),
    -- Method
    harvest_method      VARCHAR(100), -- centrifugation, TFF, depth_filtration
    harvest_filter      VARCHAR(200),
    -- Downstream
    routed_to           VARCHAR(200),
    downstream_step_id  VARCHAR(36),
    -- Hold
    hold_conditions     VARCHAR(200),
    hold_start          TIMESTAMP WITH TIME ZONE,
    hold_expiry         TIMESTAMP WITH TIME ZONE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_cell_banks (
    id                  VARCHAR(36) PRIMARY KEY,
    bank_code           VARCHAR(100) NOT NULL UNIQUE,
    bank_type           VARCHAR(50), -- MCB, WCB, PCWB, end_of_production
    cell_line_id        VARCHAR(36),
    cell_line_name      VARCHAR(200),
    preparation_date    DATE,
    passage_number      INTEGER,
    vials_prepared      INTEGER,
    vials_available     INTEGER,
    storage_location    VARCHAR(200),
    storage_temp_c      DECIMAL(6,2) DEFAULT -196,
    characterization_status VARCHAR(100),
    sterility_status    VARCHAR(50),
    mycoplasma_status   VARCHAR(50),
    adventitious_virus_status VARCHAR(50),
    genetic_stability_status VARCHAR(50),
    viability_pct       DECIMAL(6,3),
    vcd_cells_ml        DECIMAL(14,4),
    -- Regulatory
    regulatory_acceptance_status VARCHAR(100),
    gmp_grade           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_cell_bank_vials (
    id                  VARCHAR(36) PRIMARY KEY,
    bank_id             VARCHAR(36) NOT NULL REFERENCES mes_cell_banks(id),
    vial_number         VARCHAR(100) NOT NULL,
    storage_position    VARCHAR(100),
    status              VARCHAR(50) DEFAULT 'available', -- available, reserved, used, destroyed
    used_at             TIMESTAMP WITH TIME ZONE,
    used_for            VARCHAR(200),
    run_id              VARCHAR(36) REFERENCES mes_bioreactor_runs(id),
    UNIQUE(bank_id, vial_number)
);

-- ─────────────────────────────────────────
-- 13.15 DOWNSTREAM PROCESSING
-- ─────────────────────────────────────────
CREATE TABLE mes_downstream_steps (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    step_number         INTEGER,
    step_name           VARCHAR(300),
    step_type           VARCHAR(100), -- centrifugation, depth_filtration, TFF, chromatography, viral_inactivation, viral_filtration, UF_DF, formulation, fill_finish
    equipment_id        VARCHAR(36) REFERENCES mes_equipment(id),
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    input_volume_L      DECIMAL(12,4),
    output_volume_L     DECIMAL(12,4),
    yield_pct           DECIMAL(8,3),
    purity_pct          DECIMAL(8,4),
    status              VARCHAR(50) DEFAULT 'pending',
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_chromatography_runs (
    id                  VARCHAR(36) PRIMARY KEY,
    downstream_step_id  VARCHAR(36) REFERENCES mes_downstream_steps(id),
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    run_number          VARCHAR(100) NOT NULL UNIQUE,
    column_id           VARCHAR(36),
    column_name         VARCHAR(200),
    resin_type          VARCHAR(200),
    chromatography_mode VARCHAR(100), -- affinity, IEX, HIC, SEC, mixed_mode
    -- Parameters
    load_volume_ml      DECIMAL(12,4),
    load_protein_g      DECIMAL(12,6),
    flow_rate_ml_min    DECIMAL(10,4),
    -- Buffers
    equilibration_buffer VARCHAR(200),
    wash_buffer         VARCHAR(200),
    elution_buffer      VARCHAR(200),
    -- Eluate
    eluate_volume_ml    DECIMAL(12,4),
    eluate_protein_g    DECIMAL(12,6),
    yield_pct           DECIMAL(8,3),
    purity_pct          DECIMAL(8,4),
    -- Viral safety
    log_reduction_value DECIMAL(6,3),
    -- Column history
    column_use_number   INTEGER,
    column_resin_lifetime_L DECIMAL(10,3),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_viral_clearance_records (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    step_type           VARCHAR(100), -- low_pH_inactivation, nanofiltration, solvent_detergent, heat_inactivation
    step_number         INTEGER,
    -- Conditions
    ph_target           DECIMAL(5,3),
    ph_actual           DECIMAL(5,3),
    temperature_c       DECIMAL(5,2),
    duration_min        INTEGER,
    -- Results
    hold_time_minutes   INTEGER,
    ph_maintained       BOOLEAN,
    -- Viral safety
    model_viruses_studied TEXT,
    log_reduction_claimed DECIMAL(6,3),
    validation_study_ref VARCHAR(200),
    -- Sample
    sample_taken        BOOLEAN DEFAULT FALSE,
    sample_id           VARCHAR(36) REFERENCES lims_samples(id),
    -- Status
    passed              BOOLEAN,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.16 CONTINUOUS MANUFACTURING
-- ─────────────────────────────────────────
CREATE TABLE mes_cm_processes (
    id                  VARCHAR(36) PRIMARY KEY,
    process_code        VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300),
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    process_type        VARCHAR(100), -- integrated, semi_continuous, fully_continuous
    rtrt_enabled        BOOLEAN DEFAULT FALSE,
    batch_definition    TEXT, -- how batch is defined (time, quantity, campaign)
    nominal_throughput  DECIMAL(10,4),
    throughput_unit     VARCHAR(50),
    pat_tools           TEXT, -- JSON: NIR, Raman, particle_size, etc.
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_cm_runs (
    id                  VARCHAR(36) PRIMARY KEY,
    run_number          VARCHAR(100) NOT NULL UNIQUE,
    process_id          VARCHAR(36) REFERENCES mes_cm_processes(id),
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    started_at          TIMESTAMP WITH TIME ZONE,
    ended_at            TIMESTAMP WITH TIME ZONE,
    duration_hours      DECIMAL(8,2),
    total_mass_produced_kg DECIMAL(12,4),
    diverted_mass_kg    DECIMAL(12,4),
    accepted_mass_kg    DECIMAL(12,4),
    status              VARCHAR(50) DEFAULT 'running',
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_cm_diversion_events (
    id                  VARCHAR(36) PRIMARY KEY,
    run_id              VARCHAR(36) NOT NULL REFERENCES mes_cm_runs(id),
    diversion_number    VARCHAR(100) NOT NULL UNIQUE,
    started_at          TIMESTAMP WITH TIME ZONE NOT NULL,
    ended_at            TIMESTAMP WITH TIME ZONE,
    diversion_type      VARCHAR(100), -- startup, shutdown, disturbance, failed_rtrt, equipment_fault
    trigger_description TEXT,
    mass_diverted_kg    DECIMAL(10,4),
    pat_value_at_trigger DECIMAL(20,8),
    limit_exceeded      VARCHAR(300),
    corrective_action   TEXT,
    investigation_required BOOLEAN DEFAULT FALSE,
    approved_by         VARCHAR(36) REFERENCES users(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.17 SERIALIZATION & TRACK/TRACE
-- ─────────────────────────────────────────
CREATE TABLE mes_serialization_configs (
    id                  VARCHAR(36) PRIMARY KEY,
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    market              VARCHAR(100),
    serialization_standard VARCHAR(100), -- DSCSA, EU_FMD, SFDA, Brazil_SCTLD
    gtin_unit           VARCHAR(50),
    gtin_case           VARCHAR(50),
    gtin_pallet         VARCHAR(50),
    ndc                 VARCHAR(50),
    pack_levels         TEXT, -- JSON: [unit, case, pallet]
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_serial_numbers (
    id                  VARCHAR(36) PRIMARY KEY,
    serial_number       VARCHAR(200) NOT NULL,
    gtin               VARCHAR(50),
    batch_number        VARCHAR(100),
    expiry_date         DATE,
    level               VARCHAR(50), -- unit, case, pallet
    parent_serial_id    VARCHAR(36) REFERENCES mes_serial_numbers(id),
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    status              VARCHAR(50) DEFAULT 'commissioned', -- commissioned, shipped, dispensed, returned, destroyed, recalled
    commissioned_at     TIMESTAMP WITH TIME ZONE,
    UNIQUE(serial_number, gtin)
);

-- ─────────────────────────────────────────
-- 13.18 ATMP / CELL & GENE THERAPY MFG
-- ─────────────────────────────────────────
CREATE TABLE mes_patient_manufacturing_orders (
    id                  VARCHAR(36) PRIMARY KEY,
    order_number        VARCHAR(100) NOT NULL UNIQUE,
    patient_alias       VARCHAR(100) NOT NULL, -- anonymized patient reference
    therapy_type        VARCHAR(100), -- CAR_T, CAR_NK, TIL, stem_cell, gene_therapy, tissue
    product_id          VARCHAR(36) REFERENCES mes_products(id),
    treating_site       VARCHAR(300),
    collection_date     DATE,
    scheduled_infusion_date DATE,
    -- Chain of identity link
    coi_id              VARCHAR(36),
    -- Manufacturing
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    slot_id             VARCHAR(36),
    -- Status
    status              VARCHAR(50) DEFAULT 'awaiting_material',
    workspace_id        VARCHAR(36) REFERENCES workspaces(id),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_atmp_manufacturing_steps (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    step_number         INTEGER,
    step_name           VARCHAR(300),
    step_type           VARCHAR(100), -- cell_isolation, activation, transduction, expansion, selection, cryopreservation, formulation, QC_hold, release
    started_at          TIMESTAMP WITH TIME ZONE,
    completed_at        TIMESTAMP WITH TIME ZONE,
    performed_by        VARCHAR(36) REFERENCES users(id),
    equipment_id        VARCHAR(36) REFERENCES mes_equipment(id),
    -- Key metrics (per step type)
    cell_count_input    DECIMAL(14,6),
    viability_input     DECIMAL(6,3),
    cell_count_output   DECIMAL(14,6),
    viability_output    DECIMAL(6,3),
    fold_expansion      DECIMAL(10,4),
    transduction_efficiency_pct DECIMAL(6,3),
    -- Materials
    vector_lot_id       VARCHAR(36),
    vector_moi          DECIMAL(8,4),
    -- Status
    status              VARCHAR(50) DEFAULT 'pending',
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_cryopreservation_records (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) NOT NULL REFERENCES mes_batch_records(id),
    cryo_number         VARCHAR(100) NOT NULL UNIQUE,
    cryo_type           VARCHAR(50), -- controlled_rate, LN2_vapor, DMSO_gradient
    -- Input
    cell_count_input    DECIMAL(14,6),
    viability_input     DECIMAL(6,3),
    volume_input_ml     DECIMAL(10,4),
    -- Formulation
    cryoprotectant      VARCHAR(200), -- DMSO%, glycerol, trehalose
    final_volume_ml     DECIMAL(10,4),
    cells_per_bag_vial  DECIMAL(14,6),
    -- Controlled rate
    cooling_rate_c_min  DECIMAL(6,3),
    controlled_rate_freezer_id VARCHAR(36),
    -- Output
    vials_bags_produced INTEGER,
    storage_location    VARCHAR(300),
    storage_temp_c      DECIMAL(6,2),
    -- Post-thaw QC
    post_thaw_viability DECIMAL(6,3),
    post_thaw_recovery  DECIMAL(6,3),
    -- Status
    performed_by        VARCHAR(36) REFERENCES users(id),
    performed_at        TIMESTAMP WITH TIME ZONE,
    notes               TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.19 PAT — PROCESS ANALYTICAL TECHNOLOGY
-- ─────────────────────────────────────────
CREATE TABLE mes_pat_instruments (
    id                  VARCHAR(36) PRIMARY KEY,
    instrument_id       VARCHAR(36) REFERENCES lims_instruments(id),
    pat_type            VARCHAR(100), -- NIR, Raman, FBRM, PVM, online_HPLC, online_GC, particle_size, viscometer
    measurement_target  VARCHAR(300), -- API content, particle size, moisture, endpoint
    model_id            VARCHAR(36),
    installation_point  VARCHAR(300),
    equipment_id        VARCHAR(36) REFERENCES mes_equipment(id),
    interface_type      VARCHAR(100), -- inline, atline, online, offline
    sampling_frequency_sec INTEGER,
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_pat_models (
    id                  VARCHAR(36) PRIMARY KEY,
    model_code          VARCHAR(100) NOT NULL UNIQUE,
    name                VARCHAR(300),
    instrument_id       VARCHAR(36) REFERENCES mes_pat_instruments(id),
    model_type          VARCHAR(100), -- PLS, PCR, ANN, multivariate, univariate
    target_attribute    VARCHAR(300),
    wavelength_range    VARCHAR(100),
    calibration_samples INTEGER,
    rmsec               DECIMAL(10,6),
    rmsecv              DECIMAL(10,6),
    r_squared           DECIMAL(8,6),
    validation_status   VARCHAR(50),
    validation_ref      VARCHAR(200),
    version             VARCHAR(50),
    is_active           BOOLEAN DEFAULT TRUE,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_pat_real_time_data (
    id                  VARCHAR(36) PRIMARY KEY,
    run_id              VARCHAR(36) REFERENCES mes_batch_records(id),
    instrument_id       VARCHAR(36) REFERENCES mes_pat_instruments(id),
    model_id            VARCHAR(36) REFERENCES mes_pat_models(id),
    recorded_at         TIMESTAMP WITH TIME ZONE NOT NULL,
    elapsed_min         DECIMAL(10,3),
    predicted_value     DECIMAL(20,8),
    prediction_unit     VARCHAR(100),
    confidence_interval DECIMAL(20,8),
    raw_spectrum_ref    VARCHAR(500),
    preprocessing_applied TEXT,
    is_outlier          BOOLEAN DEFAULT FALSE,
    endpoint_reached    BOOLEAN DEFAULT FALSE,
    control_action      VARCHAR(300),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.20 MES INTEGRATIONS
-- ─────────────────────────────────────────
CREATE TABLE mes_lims_sample_requests (
    id                  VARCHAR(36) PRIMARY KEY,
    batch_record_id     VARCHAR(36) REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36) REFERENCES mes_batch_record_steps(id),
    sample_type         VARCHAR(100), -- ipc, release, retain, stability, environmental
    requested_at        TIMESTAMP WITH TIME ZONE,
    requested_by        VARCHAR(36) REFERENCES users(id),
    lims_sample_id      VARCHAR(36) REFERENCES lims_samples(id),
    lims_request_id     VARCHAR(36) REFERENCES lims_test_requests(id),
    status              VARCHAR(50) DEFAULT 'pending',
    result_received_at  TIMESTAMP WITH TIME ZONE,
    result_summary      VARCHAR(300),
    result_status       VARCHAR(50),
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE mes_erp_integrations (
    id                  VARCHAR(36) PRIMARY KEY,
    erp_system          VARCHAR(100), -- SAP, Oracle_EBS, Microsoft_Dynamics, Infor
    transaction_type    VARCHAR(100), -- production_order, goods_receipt, goods_issue, batch_creation, stock_posting
    pharolon_entity_id  VARCHAR(36),
    pharolon_entity_type VARCHAR(100),
    erp_document_number VARCHAR(200),
    erp_plant          VARCHAR(50),
    erp_storage_location VARCHAR(50),
    sync_status         VARCHAR(50), -- pending, synced, failed, acknowledged
    synced_at           TIMESTAMP WITH TIME ZONE,
    error_message       TEXT,
    created_at          TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.21 MES AUDIT TRAIL
-- ─────────────────────────────────────────
CREATE TABLE mes_audit_entries (
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
    hash_chain          VARCHAR(64)
);

-- Indexes for performance
CREATE INDEX idx_mes_batch_records_status    ON mes_batch_records(status);
CREATE INDEX idx_mes_batch_records_batch_no  ON mes_batch_records(batch_number);
CREATE INDEX idx_mes_batch_records_product   ON mes_batch_records(product_id);
CREATE INDEX idx_mes_bioreactor_data_run     ON mes_bioreactor_process_data(run_id, recorded_at);
CREATE INDEX idx_mes_ipc_batch              ON mes_ipc_tests(batch_record_id);
CREATE INDEX idx_mes_deviations_batch       ON mes_manufacturing_deviations(batch_record_id);
CREATE INDEX idx_mes_pat_data_run           ON mes_pat_real_time_data(run_id, recorded_at);
CREATE INDEX idx_lims_samples_status        ON lims_samples(status);
CREATE INDEX idx_lims_samples_type          ON lims_samples(sample_type_id);
CREATE INDEX idx_lims_test_results_status   ON lims_test_results(result_status);
CREATE INDEX idx_lims_oos_status            ON lims_oos_investigations(status);
CREATE INDEX idx_lims_em_results_status     ON lims_em_results(result_status);
