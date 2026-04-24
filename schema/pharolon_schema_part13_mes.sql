-- ============================================================
-- PHAROLON Schema Part 13 — Native MES
-- Manufacturing Execution System
-- All levels of pharma: small biotech → large enterprise
-- Discrete API + Solid Dose + Liquid + Bioprocess + ATMP MFG
-- ============================================================
-- Tables: ~150
-- Regulatory: 21 CFR 211.68/100/101/103/105/110/111/113,
--             EU GMP Annex 11/15, ICH Q8/Q9/Q10/Q11/Q12/Q13,
--             ISPE GAMP 5, 21 CFR Part 11
-- ============================================================

-- ─────────────────────────────────────────
-- 13.01  PRODUCTS & MATERIALS (MES-SIDE)
-- ─────────────────────────────────────────
CREATE TABLE mes_products (
    id                  VARCHAR(36)  PRIMARY KEY,
    product_code        VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    product_type        VARCHAR(50)  NOT NULL, -- api|finished_dose|intermediate|biologic|cgt|vaccine|device_drug_combo
    dosage_form         VARCHAR(50), -- tablet|capsule|injection|infusion|topical|inhalation|suppository|patch|ophthalmic|biologic_dp|cell_therapy
    route_of_admin      VARCHAR(50),
    therapeutic_area    VARCHAR(100),
    regulatory_status   VARCHAR(50), -- investigational|nda|anda|bla|maa|approved
    site_id             VARCHAR(36),
    lifecycle_stage     VARCHAR(30)  DEFAULT 'development', -- development|clinical|commercial|discontinued
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_materials (
    id                  VARCHAR(36)  PRIMARY KEY,
    material_code       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    material_type       VARCHAR(50)  NOT NULL, -- api|excipient|raw_material|packaging_primary|packaging_secondary|consumable|solvent|gas|water|intermediate
    grade               VARCHAR(50), -- pharma|usp|ep|jp|food|industrial
    supplier_qualified  BOOLEAN      DEFAULT FALSE,
    controlled_substance BOOLEAN     DEFAULT FALSE,
    hazardous           BOOLEAN      DEFAULT FALSE,
    cold_chain_required BOOLEAN      DEFAULT FALSE,
    retest_period_months INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_material_lots (
    id                  VARCHAR(36)  PRIMARY KEY,
    material_id         VARCHAR(36)  NOT NULL REFERENCES mes_materials(id),
    lot_number          VARCHAR(100) NOT NULL,
    supplier_lot        VARCHAR(100),
    supplier_id         VARCHAR(36),
    received_date       DATE,
    expiry_date         DATE,
    retest_date         DATE,
    quantity_received   NUMERIC(15,4),
    quantity_unit       VARCHAR(20),
    quantity_available  NUMERIC(15,4),
    quantity_reserved   NUMERIC(15,4),
    storage_location    VARCHAR(200),
    status              VARCHAR(30)  DEFAULT 'quarantine', -- quarantine|approved|released|hold|rejected|expired|consumed
    release_date        DATE,
    released_by         VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.02  MASTER BATCH RECORDS (MBR)
-- The validated template — never executed directly
-- ─────────────────────────────────────────
CREATE TABLE mes_master_batch_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_number          VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    version             VARCHAR(20)  NOT NULL DEFAULT '1.0',
    status              VARCHAR(30)  DEFAULT 'draft', -- draft|in_review|approved|superseded|obsolete
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    batch_size          NUMERIC(15,4),
    batch_size_unit     VARCHAR(20),
    batch_size_range_min NUMERIC(15,4),
    batch_size_range_max NUMERIC(15,4),
    manufacturing_site  VARCHAR(36),
    process_type        VARCHAR(50)  NOT NULL, -- api_synthesis|granulation|compression|coating|filling|lyophilisation|bioprocess|cgt|continuous_mfg
    gmp_applicable      BOOLEAN      DEFAULT TRUE,
    validation_status   VARCHAR(30)  DEFAULT 'not_validated',
    validation_protocol_id VARCHAR(36),
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    effective_date      DATE,
    review_date         DATE,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE mes_mbr_phases (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    phase_number        INTEGER      NOT NULL,
    phase_name          VARCHAR(200) NOT NULL,
    phase_type          VARCHAR(50), -- dispensing|manufacturing|in_process_control|cleaning|packaging|sampling|transfer
    is_critical         BOOLEAN      DEFAULT FALSE,
    estimated_duration_min INTEGER,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_steps (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    phase_id            VARCHAR(36)  REFERENCES mes_mbr_phases(id),
    step_number         VARCHAR(20)  NOT NULL,
    step_title          VARCHAR(300) NOT NULL,
    instructions        TEXT         NOT NULL,
    step_type           VARCHAR(50)  NOT NULL, -- instruction|parameter|ipc|equipment|material|documentation|signature|calculation|decision|note
    is_critical_step    BOOLEAN      DEFAULT FALSE,
    requires_witness    BOOLEAN      DEFAULT FALSE,
    requires_calculation BOOLEAN     DEFAULT FALSE,
    mandatory           BOOLEAN      DEFAULT TRUE,
    estimated_duration_min INTEGER,
    next_step_id        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_materials (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_mbr_steps(id),
    material_id         VARCHAR(36)  NOT NULL REFERENCES mes_materials(id),
    sequence_number     INTEGER,
    theoretical_quantity NUMERIC(15,6) NOT NULL,
    quantity_unit       VARCHAR(20)  NOT NULL,
    quantity_formula    VARCHAR(500), -- formula based on batch size
    tolerance_pct       NUMERIC(5,2),
    overages_pct        NUMERIC(5,2),
    is_api              BOOLEAN      DEFAULT FALSE,
    dispensing_required BOOLEAN      DEFAULT TRUE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_process_parameters (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_mbr_steps(id),
    parameter_name      VARCHAR(200) NOT NULL,
    parameter_code      VARCHAR(50),
    is_cpp              BOOLEAN      DEFAULT FALSE, -- critical process parameter
    is_kpp              BOOLEAN      DEFAULT FALSE, -- key process parameter
    target_value        NUMERIC(15,6),
    lower_limit         NUMERIC(15,6),
    upper_limit         NUMERIC(15,6),
    action_lower        NUMERIC(15,6),
    action_upper        NUMERIC(15,6),
    unit                VARCHAR(50),
    data_source         VARCHAR(50), -- manual|dcs|scada|sensor|pi_historian
    recording_frequency VARCHAR(50), -- once|continuous|per_interval|per_cycle
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_critical_quality_attributes (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    cqa_name            VARCHAR(200) NOT NULL,
    description         TEXT,
    acceptance_criteria VARCHAR(500),
    measurement_method  VARCHAR(200),
    linked_spec_test_id VARCHAR(36)  REFERENCES lims_specification_tests(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_in_process_controls (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_mbr_steps(id),
    ipc_name            VARCHAR(200) NOT NULL,
    ipc_type            VARCHAR(50)  NOT NULL, -- appearance|weight|hardness|friability|dissolution|assay|moisture|ph|osmolality|viscosity|particle_size|fill_volume|torque|seal_integrity|bioburden|endotoxin|temperature|pressure|time|flow_rate
    frequency           VARCHAR(100) NOT NULL,
    acceptance_lower    NUMERIC(15,6),
    acceptance_upper    NUMERIC(15,6),
    acceptance_criteria VARCHAR(500),
    unit                VARCHAR(50),
    on_fail_action      VARCHAR(50)  NOT NULL, -- continue|hold|investigate|reject|reprocess
    sampling_plan       VARCHAR(200),
    linked_spec_test_id VARCHAR(36)  REFERENCES lims_specification_tests(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_equipment_requirements (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_mbr_steps(id),
    equipment_type      VARCHAR(100) NOT NULL,
    equipment_tag       VARCHAR(100),
    minimum_size        VARCHAR(100),
    cleaned_required    BOOLEAN      DEFAULT TRUE,
    cleaning_procedure  VARCHAR(100),
    setup_requirements  TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_mbr_versions (
    id                  VARCHAR(36)  PRIMARY KEY,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    version             VARCHAR(20)  NOT NULL,
    change_summary      TEXT,
    change_type         VARCHAR(30), -- minor|major|administrative
    change_control_id   VARCHAR(36),
    approved_by         VARCHAR(36),
    approved_at         TIMESTAMPTZ,
    effective_date      DATE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.03  ELECTRONIC BATCH RECORDS (eBR)
-- Executed instances of the MBR
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_number        VARCHAR(50)  UNIQUE NOT NULL,
    mbr_id              VARCHAR(36)  NOT NULL REFERENCES mes_master_batch_records(id),
    mbr_version         VARCHAR(20)  NOT NULL,
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    batch_type          VARCHAR(30)  DEFAULT 'commercial', -- commercial|clinical|validation|exhibit|engineering|stability
    status              VARCHAR(30)  DEFAULT 'planned', -- planned|dispensing|in_progress|in_process_qa|completed|released|rejected|recalled
    manufacturing_site  VARCHAR(36),
    manufacturing_line  VARCHAR(100),
    planned_start       TIMESTAMPTZ,
    actual_start        TIMESTAMPTZ,
    planned_end         TIMESTAMPTZ,
    actual_end          TIMESTAMPTZ,
    theoretical_yield   NUMERIC(15,4),
    actual_yield        NUMERIC(15,4),
    yield_unit          VARCHAR(20),
    yield_pct           NUMERIC(8,4),
    expiry_date         DATE,
    manufacturing_date  DATE,
    qa_review_by        VARCHAR(36),
    qa_review_at        TIMESTAMPTZ,
    released_by         VARCHAR(36),
    released_at         TIMESTAMPTZ,
    disposition         VARCHAR(30), -- release|reject|rework|additional_testing|pending
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW(),
    created_by          VARCHAR(36)
);

CREATE TABLE mes_batch_record_steps (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    mbr_step_id         VARCHAR(36)  NOT NULL REFERENCES mes_mbr_steps(id),
    step_number         VARCHAR(20)  NOT NULL,
    status              VARCHAR(30)  DEFAULT 'pending', -- pending|in_progress|complete|skipped|deviated
    performed_by        VARCHAR(36),
    performed_at        TIMESTAMPTZ,
    witnessed_by        VARCHAR(36),
    witnessed_at        TIMESTAMPTZ,
    actual_value        VARCHAR(500), -- recorded value for data entry steps
    notes               TEXT,
    deviation_raised    BOOLEAN      DEFAULT FALSE,
    deviation_id        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_batch_record_signatures (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_batch_record_steps(id),
    signature_role      VARCHAR(50)  NOT NULL, -- operator|witness|supervisor|qa|reviewer|approver
    signed_by           VARCHAR(36)  NOT NULL,
    signed_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    meaning             VARCHAR(200),
    signature_hash      VARCHAR(64),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.04  BILL OF MATERIALS & DISPENSING
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_materials (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    mbr_material_id     VARCHAR(36)  NOT NULL REFERENCES mes_mbr_materials(id),
    material_id         VARCHAR(36)  NOT NULL REFERENCES mes_materials(id),
    material_lot_id     VARCHAR(36)  REFERENCES mes_material_lots(id),
    theoretical_qty     NUMERIC(15,6) NOT NULL,
    dispensed_qty       NUMERIC(15,6),
    actual_used_qty     NUMERIC(15,6),
    reconciled_qty      NUMERIC(15,6),
    unit                VARCHAR(20)  NOT NULL,
    status              VARCHAR(30)  DEFAULT 'required', -- required|reserved|dispensed|issued|consumed|reconciled
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_dispensing_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    dispense_number     VARCHAR(50)  UNIQUE NOT NULL,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    batch_material_id   VARCHAR(36)  NOT NULL REFERENCES mes_batch_materials(id),
    material_lot_id     VARCHAR(36)  NOT NULL REFERENCES mes_material_lots(id),
    target_quantity     NUMERIC(15,6) NOT NULL,
    actual_quantity     NUMERIC(15,6),
    unit                VARCHAR(20)  NOT NULL,
    tolerance_pct       NUMERIC(5,2),
    within_tolerance    BOOLEAN,
    balance_id          VARCHAR(36),
    balance_calibration_valid BOOLEAN DEFAULT TRUE,
    container_id        VARCHAR(50),
    dispensed_by        VARCHAR(36)  NOT NULL,
    dispensed_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    verified_by         VARCHAR(36),
    verified_at         TIMESTAMPTZ,
    label_printed       BOOLEAN      DEFAULT FALSE,
    label_number        VARCHAR(100),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_weighing_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    dispensing_id       VARCHAR(36)  NOT NULL REFERENCES mes_dispensing_records(id),
    tare_weight         NUMERIC(15,6),
    gross_weight        NUMERIC(15,6),
    net_weight          NUMERIC(15,6),
    unit                VARCHAR(20)  NOT NULL,
    balance_reading     VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_material_reconciliation (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    material_id         VARCHAR(36)  NOT NULL REFERENCES mes_materials(id),
    theoretical_qty     NUMERIC(15,6),
    dispensed_qty       NUMERIC(15,6),
    used_qty            NUMERIC(15,6),
    returned_qty        NUMERIC(15,6),
    waste_qty           NUMERIC(15,6),
    reconciled_qty      NUMERIC(15,6),
    unit                VARCHAR(20),
    reconciliation_pct  NUMERIC(8,4),
    acceptable          BOOLEAN,
    discrepancy_noted   BOOLEAN      DEFAULT FALSE,
    discrepancy_explanation TEXT,
    reconciled_by       VARCHAR(36),
    reconciled_at       TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.05  EQUIPMENT MANAGEMENT
-- ─────────────────────────────────────────
CREATE TABLE mes_equipment (
    id                  VARCHAR(36)  PRIMARY KEY,
    equipment_id        VARCHAR(50)  UNIQUE NOT NULL,
    tag_number          VARCHAR(50)  UNIQUE,
    name                VARCHAR(200) NOT NULL,
    equipment_type      VARCHAR(100) NOT NULL, -- granulator|blender|tablet_press|coating_pan|capsule_filler|autoclave|lyophiliser|bioreactor|fermenter|chromatography_skid|filtration_system|filling_line|inspection_machine|packaging_line|centrifuge|dryer|mill|mixer|pump|vessel|heat_exchanger|freeze_dryer|isolator|rabs
    manufacturer        VARCHAR(200),
    model               VARCHAR(100),
    serial_number       VARCHAR(100),
    asset_number        VARCHAR(100),
    year_installed      INTEGER,
    site_id             VARCHAR(36),
    area_id             VARCHAR(36),
    room_id             VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'available', -- available|in_use|cleaning|maintenance|qualification|out_of_service|retired|cleaning_in_progress
    cleaning_status     VARCHAR(30)  DEFAULT 'clean', -- clean|dirty|cleaning_in_progress|quarantine
    last_cleaned        TIMESTAMPTZ,
    last_used_at        TIMESTAMPTZ,
    last_used_batch     VARCHAR(100),
    calibration_due     DATE,
    pm_due              DATE,          -- preventive maintenance
    qualification_status VARCHAR(30)  DEFAULT 'qualified',
    qualification_id    VARCHAR(36),
    max_batch_size      NUMERIC(15,4),
    min_batch_size      NUMERIC(15,4),
    capacity_unit       VARCHAR(20),
    automation_level    VARCHAR(30),  -- manual|semi_automated|fully_automated|dcs_controlled
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_equipment_logbooks (
    id                  VARCHAR(36)  PRIMARY KEY,
    equipment_id        VARCHAR(36)  NOT NULL REFERENCES mes_equipment(id),
    entry_type          VARCHAR(50)  NOT NULL, -- use|cleaning|maintenance|calibration|breakdown|repair|qualification|inspection|transfer_in|transfer_out
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    start_time          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    end_time            TIMESTAMPTZ,
    performed_by        VARCHAR(36)  NOT NULL,
    witnessed_by        VARCHAR(36),
    description         TEXT         NOT NULL,
    status_before       VARCHAR(30),
    status_after        VARCHAR(30),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_equipment_cleaning_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    equipment_id        VARCHAR(36)  NOT NULL REFERENCES mes_equipment(id),
    cleaning_number     VARCHAR(50)  UNIQUE NOT NULL,
    cleaning_procedure  VARCHAR(100) NOT NULL,
    procedure_version   VARCHAR(20),
    previous_product    VARCHAR(200),
    previous_batch      VARCHAR(100),
    cleaning_agent      VARCHAR(200),
    cleaning_agent_lot  VARCHAR(100),
    cleaned_by          VARCHAR(36)  NOT NULL,
    cleaning_start      TIMESTAMPTZ  NOT NULL,
    cleaning_end        TIMESTAMPTZ,
    verified_by         VARCHAR(36),
    verified_at         TIMESTAMPTZ,
    visual_inspection   VARCHAR(20), -- pass|fail|pending
    swab_results_id     VARCHAR(36),
    rinse_results_id    VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'in_progress',
    next_product        VARCHAR(200),
    holds_clean_until   TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_equipment_maintenance (
    id                  VARCHAR(36)  PRIMARY KEY,
    equipment_id        VARCHAR(36)  NOT NULL REFERENCES mes_equipment(id),
    maintenance_number  VARCHAR(50)  UNIQUE NOT NULL,
    maintenance_type    VARCHAR(50)  NOT NULL, -- preventive|corrective|calibration|qualification|emergency|inspection
    scheduled_date      DATE,
    actual_start        TIMESTAMPTZ,
    actual_end          TIMESTAMPTZ,
    performed_by        VARCHAR(36),
    work_performed      TEXT,
    parts_replaced      TEXT,
    next_maintenance    DATE,
    equipment_returned_clean BOOLEAN DEFAULT TRUE,
    status              VARCHAR(30)  DEFAULT 'scheduled', -- scheduled|in_progress|complete|cancelled|overdue
    work_order_number   VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_line_clearances (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    equipment_id        VARCHAR(36)  REFERENCES mes_equipment(id),
    clearance_type      VARCHAR(30)  NOT NULL, -- pre_batch|post_batch|between_products|shift_change
    performed_by        VARCHAR(36)  NOT NULL,
    performed_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    witnessed_by        VARCHAR(36),
    witnessed_at        TIMESTAMPTZ,
    checklist_complete  BOOLEAN      DEFAULT FALSE,
    previous_product_cleared BOOLEAN DEFAULT FALSE,
    labels_removed      BOOLEAN      DEFAULT FALSE,
    equipment_clean     BOOLEAN      DEFAULT FALSE,
    area_clean          BOOLEAN      DEFAULT FALSE,
    correct_materials   BOOLEAN      DEFAULT FALSE,
    documentation_in_order BOOLEAN  DEFAULT FALSE,
    result              VARCHAR(20)  NOT NULL, -- approved|rejected|conditional
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.06  FACILITIES, ROOMS & CLEANROOMS
-- ─────────────────────────────────────────
CREATE TABLE mes_manufacturing_areas (
    id                  VARCHAR(36)  PRIMARY KEY,
    area_code           VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    area_type           VARCHAR(50), -- manufacturing|packaging|warehouse|laboratory|utility|corridor|airlock|cge_suite
    site_id             VARCHAR(36),
    classification_id   VARCHAR(36)  REFERENCES lims_cleanroom_classifications(id),
    hvac_zone           VARCHAR(50),
    status              VARCHAR(30)  DEFAULT 'operational',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_rooms (
    id                  VARCHAR(36)  PRIMARY KEY,
    room_number         VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    area_id             VARCHAR(36)  NOT NULL REFERENCES mes_manufacturing_areas(id),
    classification_id   VARCHAR(36)  REFERENCES lims_cleanroom_classifications(id),
    floor_area_m2       NUMERIC(8,2),
    status              VARCHAR(30)  DEFAULT 'available', -- available|in_use|cleaning|maintenance|quarantine|decommissioned
    cleaning_status     VARCHAR(30)  DEFAULT 'clean',
    temperature_setpoint_c NUMERIC(5,1),
    humidity_setpoint_pct  NUMERIC(5,1),
    differential_pressure_pa NUMERIC(8,2),
    pressure_relationship VARCHAR(20), -- positive|negative|neutral
    air_changes_per_hour NUMERIC(8,2),
    last_cleaned        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_room_logs (
    id                  VARCHAR(36)  PRIMARY KEY,
    room_id             VARCHAR(36)  NOT NULL REFERENCES mes_rooms(id),
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    entry_type          VARCHAR(50)  NOT NULL,
    event_time          TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    recorded_by         VARCHAR(36)  NOT NULL,
    temperature_c       NUMERIC(5,1),
    humidity_pct        NUMERIC(5,1),
    pressure_pa         NUMERIC(8,2),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.07  IN-PROCESS CONTROLS
-- ─────────────────────────────────────────
CREATE TABLE mes_ipc_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_batch_record_steps(id),
    mbr_ipc_id          VARCHAR(36)  NOT NULL REFERENCES mes_mbr_in_process_controls(id),
    sample_number       INTEGER      NOT NULL,
    tested_at           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    tested_by           VARCHAR(36)  NOT NULL,
    instrument_id       VARCHAR(36)  REFERENCES lims_instruments(id),
    result_value        NUMERIC(15,6),
    result_text         VARCHAR(300),
    unit                VARCHAR(50),
    pass_fail           VARCHAR(20)  NOT NULL, -- pass|fail|conditional|void
    action_taken        TEXT,
    deviation_id        VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_process_parameter_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_batch_record_steps(id),
    mbr_parameter_id    VARCHAR(36)  NOT NULL REFERENCES mes_mbr_process_parameters(id),
    recorded_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    recorded_by         VARCHAR(36),
    actual_value        NUMERIC(15,6) NOT NULL,
    unit                VARCHAR(50),
    within_limits       BOOLEAN      NOT NULL DEFAULT TRUE,
    is_cpp              BOOLEAN      DEFAULT FALSE,
    alarm_triggered     BOOLEAN      DEFAULT FALSE,
    source              VARCHAR(30)  DEFAULT 'manual', -- manual|dcs|scada|sensor|pi
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.08  YIELD & RECONCILIATION
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_yields (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_batch_record_steps(id),
    yield_stage         VARCHAR(100) NOT NULL, -- granulation|blending|compression|coating|filling|inspection|final
    theoretical_qty     NUMERIC(15,4) NOT NULL,
    actual_qty          NUMERIC(15,4),
    unit                VARCHAR(20)  NOT NULL,
    yield_pct           NUMERIC(8,4),
    rejection_qty       NUMERIC(15,4) DEFAULT 0,
    rejection_reason    TEXT,
    acceptable          BOOLEAN,
    lower_yield_limit   NUMERIC(5,2),
    upper_yield_limit   NUMERIC(5,2),
    recorded_by         VARCHAR(36),
    recorded_at         TIMESTAMPTZ  DEFAULT NOW(),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.09  PRODUCTION ORDERS & PLANNING
-- ─────────────────────────────────────────
CREATE TABLE mes_production_orders (
    id                  VARCHAR(36)  PRIMARY KEY,
    order_number        VARCHAR(50)  UNIQUE NOT NULL,
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    order_type          VARCHAR(30)  DEFAULT 'commercial', -- commercial|clinical|stability|validation|sample
    status              VARCHAR(30)  DEFAULT 'planned', -- planned|released|in_progress|complete|cancelled|on_hold
    planned_batches     INTEGER      NOT NULL DEFAULT 1,
    planned_quantity    NUMERIC(15,4),
    quantity_unit       VARCHAR(20),
    requested_by        DATE,
    planned_start       DATE,
    planned_end         DATE,
    priority            VARCHAR(20)  DEFAULT 'normal',
    erp_order_number    VARCHAR(100),
    created_by          VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_production_schedules (
    id                  VARCHAR(36)  PRIMARY KEY,
    order_id            VARCHAR(36)  NOT NULL REFERENCES mes_production_orders(id),
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    manufacturing_line  VARCHAR(100),
    site_id             VARCHAR(36),
    scheduled_start     TIMESTAMPTZ,
    scheduled_end       TIMESTAMPTZ,
    equipment_reserved  TEXT,        -- JSON array of equipment IDs
    status              VARCHAR(30)  DEFAULT 'planned',
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.10  BATCH RELEASE
-- ─────────────────────────────────────────
CREATE TABLE mes_batch_release_workflow (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id) UNIQUE,
    status              VARCHAR(30)  DEFAULT 'pending_review', -- pending_review|qa_review|qa_approved|released|rejected|conditionally_released|recall_initiated
    ebr_complete        BOOLEAN      DEFAULT FALSE,
    lims_tests_complete BOOLEAN      DEFAULT FALSE,
    deviations_closed   BOOLEAN      DEFAULT FALSE,
    capa_closed         BOOLEAN      DEFAULT FALSE,
    yield_acceptable    BOOLEAN      DEFAULT FALSE,
    packaging_complete  BOOLEAN      DEFAULT FALSE,
    qa_reviewer         VARCHAR(36),
    qa_reviewed_at      TIMESTAMPTZ,
    qa_approver         VARCHAR(36),
    qa_approved_at      TIMESTAMPTZ,
    disposition         VARCHAR(30), -- release|reject|additional_testing|rework|scrap
    disposition_reason  TEXT,
    certificate_number  VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_batch_release_checklist (
    id                  VARCHAR(36)  PRIMARY KEY,
    release_id          VARCHAR(36)  NOT NULL REFERENCES mes_batch_release_workflow(id),
    item_category       VARCHAR(50)  NOT NULL, -- documentation|testing|deviations|equipment|materials|environmental|yield
    item_description    VARCHAR(300) NOT NULL,
    is_complete         BOOLEAN      DEFAULT FALSE,
    checked_by          VARCHAR(36),
    checked_at          TIMESTAMPTZ,
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.11  DEVIATIONS (MES-SIDE)
-- ─────────────────────────────────────────
CREATE TABLE mes_manufacturing_deviations (
    id                  VARCHAR(36)  PRIMARY KEY,
    deviation_number    VARCHAR(50)  UNIQUE NOT NULL,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_batch_record_steps(id),
    deviation_type      VARCHAR(50)  NOT NULL, -- process|equipment|material|environmental|documentation|personnel|utility
    category            VARCHAR(30)  DEFAULT 'unplanned', -- planned|unplanned
    severity            VARCHAR(20)  DEFAULT 'minor', -- minor|major|critical
    description         TEXT         NOT NULL,
    detected_by         VARCHAR(36)  NOT NULL,
    detected_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    impact_assessment   TEXT,
    batch_impact        VARCHAR(30), -- no_impact|potential_impact|confirmed_impact
    patient_safety_risk BOOLEAN      DEFAULT FALSE,
    regulatory_impact   BOOLEAN      DEFAULT FALSE,
    immediate_action    TEXT,
    root_cause          TEXT,
    proposed_disposition VARCHAR(30), -- release|reject|rework|additional_testing|scrap
    final_disposition   VARCHAR(30),
    qa_approval_by      VARCHAR(36),
    qa_approval_at      TIMESTAMPTZ,
    status              VARCHAR(30)  DEFAULT 'open', -- open|under_investigation|pending_qa|closed
    capa_required       BOOLEAN      DEFAULT FALSE,
    capa_id             VARCHAR(36),
    closed_by           VARCHAR(36),
    closed_at           TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW(),
    updated_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.12  SPC / CONTROL CHARTS
-- ICH Q10 Pharmaceutical Quality System
-- ─────────────────────────────────────────
CREATE TABLE mes_spc_charts (
    id                  VARCHAR(36)  PRIMARY KEY,
    chart_name          VARCHAR(200) NOT NULL,
    chart_type          VARCHAR(30)  NOT NULL, -- xbar_r|xbar_s|individuals|cusum|ewma|p_chart|np_chart|c_chart|u_chart
    product_id          VARCHAR(36)  REFERENCES mes_products(id),
    parameter_name      VARCHAR(200) NOT NULL,
    ipc_type            VARCHAR(50),
    unit                VARCHAR(50),
    target_value        NUMERIC(15,6),
    ucl                 NUMERIC(15,6), -- upper control limit
    lcl                 NUMERIC(15,6), -- lower control limit
    uwl                 NUMERIC(15,6), -- upper warning limit
    lwl                 NUMERIC(15,6), -- lower warning limit
    sample_size         INTEGER,
    subgroup_size       INTEGER,
    specification_upper NUMERIC(15,6),
    specification_lower NUMERIC(15,6),
    cpk_target          NUMERIC(5,3)  DEFAULT 1.33,
    review_frequency    VARCHAR(30),
    status              VARCHAR(20)  DEFAULT 'active',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_spc_data_points (
    id                  VARCHAR(36)  PRIMARY KEY,
    chart_id            VARCHAR(36)  NOT NULL REFERENCES mes_spc_charts(id),
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    ipc_result_id       VARCHAR(36)  REFERENCES mes_ipc_results(id),
    subgroup_number     INTEGER,
    sample_number       INTEGER,
    value               NUMERIC(15,6) NOT NULL,
    xbar                NUMERIC(15,6),
    range_r             NUMERIC(15,6),
    std_dev_s           NUMERIC(15,6),
    recorded_at         TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    violation_rules     TEXT,        -- JSON: which Nelson/Western Electric rules violated
    is_in_control       BOOLEAN      DEFAULT TRUE,
    cpk                 NUMERIC(8,4),
    ppk                 NUMERIC(8,4),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_spc_violations (
    id                  VARCHAR(36)  PRIMARY KEY,
    chart_id            VARCHAR(36)  NOT NULL REFERENCES mes_spc_charts(id),
    data_point_id       VARCHAR(36)  NOT NULL REFERENCES mes_spc_data_points(id),
    rule_violated       VARCHAR(100) NOT NULL, -- rule_1_beyond_3sigma|rule_2_nine_one_side|rule_3_six_trend|etc
    violation_type      VARCHAR(30)  NOT NULL, -- warning|out_of_control
    action_required     VARCHAR(200),
    investigated_by     VARCHAR(36),
    investigation_notes TEXT,
    resolved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.13  SERIALIZATION & TRACK / TRACE
-- ─────────────────────────────────────────
CREATE TABLE mes_serialization_configs (
    id                  VARCHAR(36)  PRIMARY KEY,
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    gtin_14             VARCHAR(14)  UNIQUE NOT NULL,
    ndc_code            VARCHAR(20),
    regulation          VARCHAR(50), -- dscsa|falsified_medicines_directive|brazil_anvisa|china_nmpa|saudi_sfda
    serial_number_format VARCHAR(200),
    lot_format          VARCHAR(100),
    expiry_format       VARCHAR(50),
    aggregation_levels  TEXT,        -- JSON: ["unit","case","pallet"]
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_serial_numbers (
    id                  VARCHAR(36)  PRIMARY KEY,
    config_id           VARCHAR(36)  NOT NULL REFERENCES mes_serialization_configs(id),
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    serial_number       VARCHAR(100) NOT NULL,
    gtin                VARCHAR(14),
    lot_number          VARCHAR(100),
    expiry_date         DATE,
    level               VARCHAR(20)  NOT NULL, -- unit|case|pallet|bundle
    parent_serial       VARCHAR(100),
    status              VARCHAR(30)  DEFAULT 'commissioned', -- commissioned|aggregated|shipped|returned|decommissioned|reported_stolen
    commissioned_at     TIMESTAMPTZ  DEFAULT NOW(),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_serialization_events (
    id                  VARCHAR(36)  PRIMARY KEY,
    serial_id           VARCHAR(36)  NOT NULL REFERENCES mes_serial_numbers(id),
    event_type          VARCHAR(50)  NOT NULL, -- commission|aggregate|ship|receive|decommission|return|sample|destroy
    event_timestamp     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    location            VARCHAR(200),
    trading_partner_id  VARCHAR(200),
    transaction_id      VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.14  BIOPROCESS / BIOREACTOR
-- Biologics: mAb, vaccines, recombinant proteins
-- ─────────────────────────────────────────
CREATE TABLE mes_cell_banks (
    id                  VARCHAR(36)  PRIMARY KEY,
    bank_code           VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    bank_type           VARCHAR(30)  NOT NULL, -- mcb|wcb|pcwb|research -- master|working|post_cell_working
    cell_line           VARCHAR(200),
    passage_number      INTEGER,
    viability_pct       NUMERIC(6,3),
    vials_total         INTEGER,
    vials_remaining     INTEGER,
    storage_location_id VARCHAR(36)  REFERENCES lims_storage_locations(id),
    storage_temp_c      NUMERIC(5,1) DEFAULT -196.0, -- LN2
    manufacture_date    DATE,
    expiry_date         DATE,
    qualification_status VARCHAR(30) DEFAULT 'qualified',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cell_bank_vials (
    id                  VARCHAR(36)  PRIMARY KEY,
    bank_id             VARCHAR(36)  NOT NULL REFERENCES mes_cell_banks(id),
    vial_number         VARCHAR(50)  UNIQUE NOT NULL,
    storage_position    VARCHAR(100),
    status              VARCHAR(20)  DEFAULT 'available', -- available|reserved|retrieved|depleted
    retrieved_at        TIMESTAMPTZ,
    retrieved_by        VARCHAR(36),
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_bioreactor_runs (
    id                  VARCHAR(36)  PRIMARY KEY,
    run_number          VARCHAR(50)  UNIQUE NOT NULL,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    bioreactor_id       VARCHAR(36)  NOT NULL REFERENCES mes_equipment(id),
    run_type            VARCHAR(30)  NOT NULL, -- seed_train|production|perfusion|fed_batch|batch
    inoculation_date    TIMESTAMPTZ,
    inoculation_source  VARCHAR(36)  REFERENCES mes_cell_bank_vials(id),
    harvest_date        TIMESTAMPTZ,
    volume_liters       NUMERIC(10,3),
    status              VARCHAR(30)  DEFAULT 'planned', -- planned|seeding|growing|fed_batch|harvesting|complete|failed|aborted
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_bioreactor_parameters (
    id                  VARCHAR(36)  PRIMARY KEY,
    run_id              VARCHAR(36)  NOT NULL REFERENCES mes_bioreactor_runs(id),
    timestamp           TIMESTAMPTZ  NOT NULL,
    temperature_c       NUMERIC(6,3),
    ph                  NUMERIC(5,3),
    dissolved_oxygen_pct NUMERIC(7,3),
    dissolved_co2_pct   NUMERIC(7,3),
    agitation_rpm       NUMERIC(8,2),
    aeration_slpm       NUMERIC(8,3),
    vessel_pressure_bar NUMERIC(7,4),
    viable_cell_density NUMERIC(15,4), -- cells/mL
    viability_pct       NUMERIC(6,3),
    glucose_g_l         NUMERIC(8,4),
    lactate_g_l         NUMERIC(8,4),
    glutamine_mm        NUMERIC(8,4),
    ammonium_mm         NUMERIC(8,4),
    product_titer_mg_l  NUMERIC(10,4),
    feed_volume_ml      NUMERIC(10,3),
    base_volume_ml      NUMERIC(10,3),
    data_source         VARCHAR(30)  DEFAULT 'dcs',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_seed_train_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    passage_number      INTEGER      NOT NULL,
    vessel_id           VARCHAR(36)  REFERENCES mes_equipment(id),
    start_date          TIMESTAMPTZ,
    end_date            TIMESTAMPTZ,
    seed_density        NUMERIC(12,4), -- cells/mL
    harvest_density     NUMERIC(12,4),
    volume_liters       NUMERIC(10,3),
    viability_pct       NUMERIC(6,3),
    passed_to_next_passage BOOLEAN   DEFAULT TRUE,
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_harvest_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    bioreactor_run_id   VARCHAR(36)  REFERENCES mes_bioreactor_runs(id),
    harvest_date        TIMESTAMPTZ  NOT NULL,
    harvested_volume_l  NUMERIC(10,3),
    cell_density        NUMERIC(15,4),
    viability_pct       NUMERIC(6,3),
    product_titer_mg_l  NUMERIC(10,4),
    total_product_g     NUMERIC(10,4),
    harvest_method      VARCHAR(50), -- centrifugation|depth_filtration|tangential_flow
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_downstream_steps (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_sequence       INTEGER      NOT NULL,
    step_type           VARCHAR(50)  NOT NULL, -- centrifugation|depth_filtration|protein_a_chromatography|ion_exchange|hydrophobic_interaction|size_exclusion|viral_inactivation|nanofiltration|ultrafiltration_diafiltration|formulation|fill_finish
    equipment_id        VARCHAR(36)  REFERENCES mes_equipment(id),
    start_time          TIMESTAMPTZ,
    end_time            TIMESTAMPTZ,
    input_volume_l      NUMERIC(10,3),
    output_volume_l     NUMERIC(10,3),
    yield_pct           NUMERIC(8,4),
    step_yield_g        NUMERIC(10,4),
    key_parameters      TEXT,        -- JSON: step-specific parameters
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_viral_clearance_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  NOT NULL REFERENCES mes_downstream_steps(id),
    step_type           VARCHAR(50)  NOT NULL, -- low_ph_inactivation|solvent_detergent|nanofiltration|uv_inactivation
    ph_value            NUMERIC(5,3),
    temperature_c       NUMERIC(5,1),
    hold_time_min       INTEGER,
    detergent_name      VARCHAR(100),
    detergent_pct       NUMERIC(7,4),
    filter_size_nm      NUMERIC(8,2),
    log_reduction_value NUMERIC(8,3),
    performed_by        VARCHAR(36),
    reviewed_by         VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.15  SOLID DOSAGE MANUFACTURING
-- ─────────────────────────────────────────
CREATE TABLE mes_granulation_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    granulation_type    VARCHAR(30)  NOT NULL, -- wet|dry|fluid_bed|hot_melt_extrusion
    equipment_id        VARCHAR(36)  REFERENCES mes_equipment(id),
    binder_solution     VARCHAR(200),
    binder_qty_kg       NUMERIC(10,4),
    mixing_time_min     NUMERIC(8,2),
    impeller_speed_rpm  NUMERIC(8,2),
    chopper_speed_rpm   NUMERIC(8,2),
    granulation_end_point VARCHAR(200),
    drying_method       VARCHAR(50),
    drying_temp_c       NUMERIC(5,1),
    drying_time_min     NUMERIC(8,2),
    loi_target_pct      NUMERIC(6,3),  -- loss on ignition/drying
    loi_actual_pct      NUMERIC(6,3),
    granule_yield_kg    NUMERIC(10,4),
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_blending_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    blender_id          VARCHAR(36)  REFERENCES mes_equipment(id),
    blend_order         INTEGER      NOT NULL,
    total_weight_kg     NUMERIC(10,4),
    speed_rpm           NUMERIC(8,2),
    blend_time_min      NUMERIC(8,2),
    blend_uniformity_result VARCHAR(20), -- pass|fail|pending
    rsd_pct             NUMERIC(8,4),  -- relative standard deviation
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_compression_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    press_id            VARCHAR(36)  REFERENCES mes_equipment(id),
    tooling_id          VARCHAR(100),
    target_weight_mg    NUMERIC(8,2),
    weight_lower_mg     NUMERIC(8,2),
    weight_upper_mg     NUMERIC(8,2),
    target_hardness_n   NUMERIC(6,2),
    hardness_lower_n    NUMERIC(6,2),
    hardness_upper_n    NUMERIC(6,2),
    target_thickness_mm NUMERIC(6,3),
    disintegration_target_sec INTEGER,
    friability_target_pct NUMERIC(6,3),
    speed_rpm           NUMERIC(8,2),
    pre_compression_force_kn NUMERIC(8,3),
    main_compression_force_kn NUMERIC(8,3),
    compression_start   TIMESTAMPTZ,
    compression_end     TIMESTAMPTZ,
    tablets_produced    BIGINT,
    rejects_count       BIGINT,
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_coating_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    coater_id           VARCHAR(36)  REFERENCES mes_equipment(id),
    coating_type        VARCHAR(50)  NOT NULL, -- film|enteric|modified_release|sugar|functional
    coating_system      VARCHAR(200),
    coating_solution_pct NUMERIC(6,3),
    spray_rate_g_min    NUMERIC(8,3),
    inlet_air_temp_c    NUMERIC(5,1),
    outlet_air_temp_c   NUMERIC(5,1),
    pan_speed_rpm       NUMERIC(6,2),
    atomising_air_bar   NUMERIC(6,3),
    target_weight_gain_pct NUMERIC(6,3),
    actual_weight_gain_pct NUMERIC(6,3),
    start_time          TIMESTAMPTZ,
    end_time            TIMESTAMPTZ,
    performed_by        VARCHAR(36),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.16  CONTINUOUS MANUFACTURING (ICH Q13)
-- ─────────────────────────────────────────
CREATE TABLE mes_cm_process_models (
    id                  VARCHAR(36)  PRIMARY KEY,
    model_name          VARCHAR(200) NOT NULL,
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    process_type        VARCHAR(50)  NOT NULL, -- direct_compression|wet_granulation_cm|hot_melt_extrusion|spray_drying
    batch_definition_method VARCHAR(100), -- time|mass|volume|fixed_interval
    rtrt_enabled        BOOLEAN      DEFAULT FALSE, -- real-time release testing
    diversion_enabled   BOOLEAN      DEFAULT TRUE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cm_batch_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    model_id            VARCHAR(36)  NOT NULL REFERENCES mes_cm_process_models(id),
    run_start           TIMESTAMPTZ  NOT NULL,
    run_end             TIMESTAMPTZ,
    total_mass_kg       NUMERIC(15,4),
    released_mass_kg    NUMERIC(15,4),
    diverted_mass_kg    NUMERIC(15,4),
    diversion_events    INTEGER      DEFAULT 0,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cm_diversion_events (
    id                  VARCHAR(36)  PRIMARY KEY,
    cm_batch_id         VARCHAR(36)  NOT NULL REFERENCES mes_cm_batch_records(id),
    event_timestamp     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    diversion_reason    VARCHAR(200) NOT NULL, -- startup|shutdown|parameter_excursion|pat_failure|equipment_fault|material_change|unplanned
    diverted_quantity   NUMERIC(12,4),
    unit                VARCHAR(20),
    parameter_violated  VARCHAR(200),
    actual_value        NUMERIC(15,6),
    limit_value         NUMERIC(15,6),
    duration_sec        INTEGER,
    disposition         VARCHAR(30), -- scrap|rework|additional_testing
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cm_rtrt_results (
    id                  VARCHAR(36)  PRIMARY KEY,
    cm_batch_id         VARCHAR(36)  NOT NULL REFERENCES mes_cm_batch_records(id),
    measurement_time    TIMESTAMPTZ  NOT NULL,
    attribute           VARCHAR(100) NOT NULL, -- potency|blend_uniformity|particle_size|moisture|dissolution
    predicted_value     NUMERIC(15,6),
    measured_value      NUMERIC(15,6),
    unit                VARCHAR(50),
    model_accuracy_pct  NUMERIC(8,4),
    within_spec         BOOLEAN      NOT NULL DEFAULT TRUE,
    pat_instrument_id   VARCHAR(36)  REFERENCES lims_instruments(id),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.17  CELL & GENE THERAPY (CGT) MFG
-- ATMP-specific manufacturing
-- ─────────────────────────────────────────
CREATE TABLE mes_cgt_patient_orders (
    id                  VARCHAR(36)  PRIMARY KEY,
    order_number        VARCHAR(50)  UNIQUE NOT NULL,
    patient_id_hashed   VARCHAR(64)  NOT NULL, -- SHA-256 hashed — HIPAA compliant
    product_id          VARCHAR(36)  NOT NULL REFERENCES mes_products(id),
    treatment_site      VARCHAR(200),
    treating_physician  VARCHAR(200),
    order_date          TIMESTAMPTZ  NOT NULL,
    requested_delivery  TIMESTAMPTZ,
    clinical_trial_id   VARCHAR(100),
    coi_id              VARCHAR(36), -- chain of identity link
    batch_id            VARCHAR(36)  REFERENCES mes_batch_records(id),
    status              VARCHAR(30)  DEFAULT 'received', -- received|scheduled|in_manufacture|qa_review|released|shipped|administered|cancelled
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cgt_collection_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    order_id            VARCHAR(36)  NOT NULL REFERENCES mes_cgt_patient_orders(id),
    collection_type     VARCHAR(30)  NOT NULL, -- leukapheresis|bone_marrow|biopsy|skin|blood
    collection_date     TIMESTAMPTZ  NOT NULL,
    collection_site     VARCHAR(200),
    collected_by        VARCHAR(200),
    volume_ml           NUMERIC(10,3),
    cell_count          BIGINT,
    viability_pct       NUMERIC(6,3),
    transport_temp_c    NUMERIC(5,1),
    transport_time_hr   NUMERIC(6,2),
    receipt_datetime    TIMESTAMPTZ,
    received_by         VARCHAR(36),
    receipt_condition   VARCHAR(50), -- acceptable|unacceptable|conditional
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cgt_manufacturing_steps (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    order_id            VARCHAR(36)  REFERENCES mes_cgt_patient_orders(id),
    step_type           VARCHAR(50)  NOT NULL, -- cell_selection|activation|transduction|expansion|harvest|formulation|fill_finish|cryopreservation|thaw_and_formulate
    step_number         INTEGER      NOT NULL,
    start_time          TIMESTAMPTZ,
    end_time            TIMESTAMPTZ,
    equipment_id        VARCHAR(36)  REFERENCES mes_equipment(id),
    operator_id         VARCHAR(36),
    key_parameters      TEXT,        -- JSON: step-specific parameters
    cell_count_in       BIGINT,
    cell_count_out      BIGINT,
    viability_pct       NUMERIC(6,3),
    fold_expansion      NUMERIC(8,3),
    pass_fail           VARCHAR(20)  DEFAULT 'pending',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cgt_transduction_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    step_id             VARCHAR(36)  NOT NULL REFERENCES mes_cgt_manufacturing_steps(id),
    vector_lot          VARCHAR(100),
    vector_id           VARCHAR(36),
    moi                 NUMERIC(10,4), -- multiplicity of infection
    vector_volume_ul    NUMERIC(10,3),
    transduction_efficiency_pct NUMERIC(7,3),
    vg_per_cell         NUMERIC(12,4), -- vector genomes per cell
    transgene_expression_pct NUMERIC(7,3),
    method              VARCHAR(50), -- lentiviral|retroviral|aav|electroporation|lipofection|crispr
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_cgt_cryopreservation_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    step_id             VARCHAR(36)  REFERENCES mes_cgt_manufacturing_steps(id),
    cryoprotectant      VARCHAR(100),
    fill_volume_ml      NUMERIC(8,3),
    units_filled        INTEGER,
    cell_count_per_unit BIGINT,
    viability_pre_cryo  NUMERIC(6,3),
    controlled_rate_freeze BOOLEAN   DEFAULT TRUE,
    freeze_rate_c_per_min NUMERIC(6,3),
    storage_temp_c      NUMERIC(6,1),
    storage_location_id VARCHAR(36)  REFERENCES lims_storage_locations(id),
    performed_by        VARCHAR(36),
    performed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.18  PACKAGING & LABELLING
-- ─────────────────────────────────────────
CREATE TABLE mes_packaging_orders (
    id                  VARCHAR(36)  PRIMARY KEY,
    packaging_number    VARCHAR(50)  UNIQUE NOT NULL,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    packaging_configuration VARCHAR(200),
    planned_units       INTEGER,
    actual_units        INTEGER,
    reject_units        INTEGER,
    reconciliation_pct  NUMERIC(8,4),
    line_id             VARCHAR(36),
    status              VARCHAR(30)  DEFAULT 'planned',
    start_time          TIMESTAMPTZ,
    end_time            TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_labelling_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    packaging_id        VARCHAR(36)  NOT NULL REFERENCES mes_packaging_orders(id),
    label_type          VARCHAR(30)  NOT NULL, -- primary|secondary|tertiary|insert|auxiliary
    artwork_version     VARCHAR(50)  NOT NULL,
    artwork_approval_id VARCHAR(36),
    label_quantity      INTEGER,
    reconciled_quantity INTEGER,
    destroyed_quantity  INTEGER,
    reconciliation_acceptable BOOLEAN DEFAULT TRUE,
    performed_by        VARCHAR(36),
    performed_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.19  PAT — PROCESS ANALYTICAL TECHNOLOGY
-- ICH Q8, FDA PAT Guidance 2004
-- ─────────────────────────────────────────
CREATE TABLE mes_pat_instruments (
    id                  VARCHAR(36)  PRIMARY KEY,
    instrument_id       VARCHAR(50)  UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    pat_type            VARCHAR(50)  NOT NULL, -- nir|raman|ft_ir|uv_vis_inline|particle_size|acoustic|rheology|mass_flow|image_analysis
    manufacturer        VARCHAR(200),
    model               VARCHAR(100),
    installation_type   VARCHAR(30), -- inline|online|atline|offline
    equipment_id        VARCHAR(36)  REFERENCES mes_equipment(id),
    calibration_due     DATE,
    status              VARCHAR(30)  DEFAULT 'active',
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_pat_models (
    id                  VARCHAR(36)  PRIMARY KEY,
    model_name          VARCHAR(200) NOT NULL,
    instrument_id       VARCHAR(36)  NOT NULL REFERENCES mes_pat_instruments(id),
    product_id          VARCHAR(36)  REFERENCES mes_products(id),
    model_type          VARCHAR(50)  NOT NULL, -- pca|pls|pcr|ann|mlr|svm
    attribute_predicted VARCHAR(100) NOT NULL,
    validation_status   VARCHAR(30)  DEFAULT 'development', -- development|validated|approved
    r_squared           NUMERIC(8,6),
    rmsecv              NUMERIC(12,6),
    rmsep               NUMERIC(12,6),
    version             VARCHAR(20),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_pat_real_time_data (
    id                  VARCHAR(36)  PRIMARY KEY,
    batch_id            VARCHAR(36)  NOT NULL REFERENCES mes_batch_records(id),
    instrument_id       VARCHAR(36)  NOT NULL REFERENCES mes_pat_instruments(id),
    model_id            VARCHAR(36)  REFERENCES mes_pat_models(id),
    timestamp           TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    spectrum_reference  VARCHAR(500),
    predicted_value     NUMERIC(15,6),
    unit                VARCHAR(50),
    confidence          NUMERIC(8,6),
    within_spec         BOOLEAN      DEFAULT TRUE,
    control_action      VARCHAR(100),
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

-- ─────────────────────────────────────────
-- 13.20  MES ↔ EXTERNAL INTEGRATIONS
-- ERP (SAP/Oracle), DCS, Historians, LIMS
-- ─────────────────────────────────────────
CREATE TABLE mes_integration_connectors (
    id                  VARCHAR(36)  PRIMARY KEY,
    connector_name      VARCHAR(100) NOT NULL, -- SAP_ERP|Oracle_ECC|Emerson_DeltaV|Siemens_PCS7|Honeywell_PKS|OSIsoft_PI|AspenTech|LabVantage|STARLIMS
    connector_type      VARCHAR(50)  NOT NULL, -- erp|dcs|scada|historian|lims|mes|edms|serialization
    version             VARCHAR(50),
    endpoint            VARCHAR(500),
    auth_method         VARCHAR(50),
    sync_direction      VARCHAR(20)  NOT NULL, -- inbound|outbound|bidirectional
    is_active           BOOLEAN      DEFAULT TRUE,
    site_id             VARCHAR(36),
    notes               TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_erp_sync_records (
    id                  VARCHAR(36)  PRIMARY KEY,
    connector_id        VARCHAR(36)  NOT NULL REFERENCES mes_integration_connectors(id),
    sync_type           VARCHAR(50)  NOT NULL, -- batch|material|order|goods_movement|inventory|cost
    erp_document_number VARCHAR(100),
    pharolon_reference  VARCHAR(100),
    direction           VARCHAR(20),
    sync_status         VARCHAR(20)  DEFAULT 'pending', -- pending|synced|failed|conflict
    synced_at           TIMESTAMPTZ,
    error_message       TEXT,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

CREATE TABLE mes_dcs_parameter_feeds (
    id                  VARCHAR(36)  PRIMARY KEY,
    connector_id        VARCHAR(36)  NOT NULL REFERENCES mes_integration_connectors(id),
    tag_name            VARCHAR(200) NOT NULL, -- DCS/SCADA tag
    parameter_id        VARCHAR(36)  REFERENCES mes_mbr_process_parameters(id),
    unit                VARCHAR(50),
    scan_rate_sec       INTEGER      DEFAULT 60,
    last_value          NUMERIC(15,6),
    last_read_at        TIMESTAMPTZ,
    is_active           BOOLEAN      DEFAULT TRUE,
    created_at          TIMESTAMPTZ  DEFAULT NOW()
);

