-- ============================================================
-- OpenVAL Schema - Part 3: New Module Extensions
-- From Competitive Research and Gap Analysis
-- Version: 1.0.0
-- Run after Part 1 and Part 2
-- ============================================================

-- ============================================================
-- CLOSED-LOOP AUTOMATION ENGINE
-- ============================================================

CREATE TABLE automation_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id),
    rule_name VARCHAR(512) NOT NULL,
    rule_description TEXT,
    trigger_object_type VARCHAR(100) NOT NULL,
    trigger_event VARCHAR(100) NOT NULL,
    trigger_conditions TEXT,
    action_type VARCHAR(100) NOT NULL,
    action_config TEXT,
    run_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_triggered_at TIMESTAMPTZ,
    trigger_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE automation_rule_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID NOT NULL REFERENCES automation_rules(id),
    trigger_object_type VARCHAR(100) NOT NULL,
    trigger_object_id UUID NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'success',
    result_object_type VARCHAR(100),
    result_object_id UUID,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    error_message TEXT,
    execution_duration_ms INT
);

-- ============================================================
-- OOS / OOT MANAGEMENT
-- ============================================================

CREATE SEQUENCE seq_oos_ref START 1;

CREATE TABLE oos_oot_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    record_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    record_type VARCHAR(10) NOT NULL CHECK (record_type IN ('OOS','OOT')),
    system_id UUID REFERENCES systems(id),
    product_name VARCHAR(255),
    batch_lot_number VARCHAR(100),
    sample_id VARCHAR(255),
    test_name VARCHAR(512) NOT NULL,
    specification_limit VARCHAR(255),
    result_obtained VARCHAR(255) NOT NULL,
    unit VARCHAR(50),
    percent_deviation DECIMAL(10,4),
    analyst_id UUID REFERENCES users(id),
    instrument_id UUID REFERENCES equipment(id),
    test_date DATE NOT NULL,
    -- Phase 1 Investigation
    phase VARCHAR(20) NOT NULL DEFAULT 'phase_1',
    phase1_investigation_text TEXT,
    phase1_outcome VARCHAR(50),  -- lab_error, no_lab_error
    phase1_completed_by UUID REFERENCES users(id),
    phase1_completed_at TIMESTAMPTZ,
    -- Phase 2 Investigation
    phase2_root_cause TEXT,
    phase2_investigation_text TEXT,
    phase2_outcome VARCHAR(50),  -- retest_required, reject, pass_with_justification
    -- Disposition
    disposition VARCHAR(50),
    disposition_rationale TEXT,
    -- Links
    capa_required BOOLEAN NOT NULL DEFAULT FALSE,
    capa_id UUID REFERENCES capas(id),
    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE oot_control_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    test_name VARCHAR(512) NOT NULL,
    product_name VARCHAR(255),
    limit_type VARCHAR(50) NOT NULL CHECK (limit_type IN ('action_limit','alert_limit','trend_limit')),
    lower_limit DECIMAL(20,6),
    upper_limit DECIMAL(20,6),
    unit VARCHAR(50),
    statistical_basis VARCHAR(255),
    effective_from DATE NOT NULL,
    effective_to DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE oos_retest_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    oos_id UUID NOT NULL REFERENCES oos_oot_records(id),
    retest_number INT NOT NULL,
    retest_result VARCHAR(255) NOT NULL,
    retest_date DATE NOT NULL,
    analyst_id UUID REFERENCES users(id),
    instrument_id UUID REFERENCES equipment(id),
    pass_fail VARCHAR(10) NOT NULL CHECK (pass_fail IN ('pass','fail')),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- COMPLAINT MANAGEMENT
-- ============================================================

CREATE SEQUENCE seq_complaint_ref START 1;

CREATE TABLE complaints (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    received_date DATE NOT NULL,
    received_by UUID NOT NULL REFERENCES users(id),
    receipt_method VARCHAR(100),
    complainant_name VARCHAR(255),
    complainant_type VARCHAR(100),
    complainant_contact TEXT,
    product_name VARCHAR(512),
    product_lot_number VARCHAR(100),
    product_batch_number VARCHAR(100),
    complaint_type VARCHAR(100),
    complaint_description TEXT NOT NULL,
    patient_impact BOOLEAN NOT NULL DEFAULT FALSE,
    adverse_event_occurred BOOLEAN NOT NULL DEFAULT FALSE,
    adverse_event_description TEXT,
    severity VARCHAR(50),
    is_reportable BOOLEAN,
    reportable_reason TEXT,
    regulatory_report_type VARCHAR(100),
    regulatory_report_submitted_at TIMESTAMPTZ,
    regulatory_report_ref VARCHAR(255),
    investigation_required BOOLEAN NOT NULL DEFAULT TRUE,
    root_cause TEXT,
    root_cause_category VARCHAR(100),
    corrective_action_taken TEXT,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE,
    capa_id UUID REFERENCES capas(id),
    response_required BOOLEAN NOT NULL DEFAULT TRUE,
    response_due_date DATE,
    response_sent_at TIMESTAMPTZ,
    response_content TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE complaint_investigations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    complaint_id UUID NOT NULL REFERENCES complaints(id),
    investigator_id UUID REFERENCES users(id),
    investigation_start_date DATE,
    investigation_end_date DATE,
    lot_disposition VARCHAR(100),
    test_results TEXT,
    findings TEXT NOT NULL,
    timeline_of_events TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- ENVIRONMENTAL MONITORING
-- ============================================================

CREATE SEQUENCE seq_em_session_ref START 1;
CREATE SEQUENCE seq_em_excursion_ref START 1;

CREATE TABLE em_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    location_code VARCHAR(50) UNIQUE NOT NULL,
    location_name VARCHAR(512) NOT NULL,
    location_type VARCHAR(100),
    iso_class VARCHAR(20),
    eu_gmp_grade VARCHAR(5),
    department_id UUID REFERENCES departments(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE em_sample_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    location_id UUID NOT NULL REFERENCES em_locations(id),
    point_code VARCHAR(50) UNIQUE NOT NULL,
    point_name VARCHAR(512) NOT NULL,
    sample_type VARCHAR(100) NOT NULL,
    monitoring_frequency VARCHAR(100) NOT NULL,
    alert_limit DECIMAL(10,2),
    action_limit DECIMAL(10,2),
    unit VARCHAR(50) NOT NULL DEFAULT 'CFU',
    organism_targets TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE em_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    schedule_name VARCHAR(512) NOT NULL,
    sample_point_ids TEXT NOT NULL,
    schedule_frequency VARCHAR(100) NOT NULL,
    next_due_date DATE NOT NULL,
    responsible_id UUID REFERENCES users(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE em_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    session_date DATE NOT NULL,
    session_type VARCHAR(100) NOT NULL DEFAULT 'routine',
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    sampled_by UUID REFERENCES users(id),
    reviewed_by UUID REFERENCES users(id),
    total_samples INT NOT NULL DEFAULT 0,
    samples_within_limits INT NOT NULL DEFAULT 0,
    samples_at_alert INT NOT NULL DEFAULT 0,
    samples_at_action INT NOT NULL DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE em_excursions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    excursion_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    session_id UUID REFERENCES em_sessions(id),
    sample_point_id UUID NOT NULL REFERENCES em_sample_points(id),
    excursion_type VARCHAR(50) NOT NULL,
    result_value DECIMAL(10,2) NOT NULL,
    limit_exceeded VARCHAR(50) NOT NULL,
    organisms_identified TEXT,
    immediate_action_taken TEXT,
    investigation_required BOOLEAN NOT NULL DEFAULT TRUE,
    root_cause TEXT,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE,
    capa_id UUID REFERENCES capas(id),
    recheck_required BOOLEAN NOT NULL DEFAULT FALSE,
    recheck_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE em_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES em_sessions(id),
    sample_point_id UUID NOT NULL REFERENCES em_sample_points(id),
    sample_id VARCHAR(100),
    result_value DECIMAL(10,2),
    result_unit VARCHAR(50) NOT NULL DEFAULT 'CFU',
    result_status VARCHAR(50) NOT NULL,
    organisms_identified TEXT,
    sampled_by UUID REFERENCES users(id),
    sampled_at TIMESTAMPTZ,
    incubation_start TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    read_by UUID REFERENCES users(id),
    excursion_id UUID REFERENCES em_excursions(id),
    comments TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- STABILITY STUDY MANAGEMENT
-- ============================================================

CREATE SEQUENCE seq_stability_ref START 1;

CREATE TABLE stability_studies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    batch_numbers TEXT,
    study_type VARCHAR(100) NOT NULL,
    study_purpose VARCHAR(100),
    container_closure TEXT,
    storage_conditions TEXT,
    protocol_document_id UUID REFERENCES documents(id),
    study_start_date DATE NOT NULL,
    study_end_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    owner_id UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE stability_time_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_id UUID NOT NULL REFERENCES stability_studies(id),
    time_point VARCHAR(50) NOT NULL,
    nominal_days INT NOT NULL,
    pull_due_date DATE NOT NULL,
    actual_pull_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    pulled_by UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE stability_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    time_point_id UUID NOT NULL REFERENCES stability_time_points(id),
    test_name VARCHAR(512) NOT NULL,
    specification VARCHAR(255),
    result_value VARCHAR(255) NOT NULL,
    result_status VARCHAR(50) NOT NULL DEFAULT 'pass',
    tested_by UUID REFERENCES users(id),
    tested_date DATE NOT NULL,
    instrument_id UUID REFERENCES equipment(id),
    oos_id UUID REFERENCES oos_oot_records(id),
    comments TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- BATCH AND LOT MANAGEMENT
-- ============================================================

CREATE SEQUENCE seq_batch_ref START 1;
CREATE SEQUENCE seq_coa_ref START 1;

CREATE TABLE batches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    batch_number VARCHAR(100) NOT NULL,
    lot_number VARCHAR(100),
    batch_type VARCHAR(100) NOT NULL DEFAULT 'commercial',
    manufacture_date DATE,
    expiry_date DATE,
    batch_size DECIMAL(20,4),
    batch_size_unit VARCHAR(50),
    status VARCHAR(50) NOT NULL DEFAULT 'in_testing',
    hold_reason TEXT,
    hold_initiated_by UUID REFERENCES users(id),
    hold_initiated_at TIMESTAMPTZ,
    disposition VARCHAR(50),
    disposition_rationale TEXT,
    disposed_by UUID REFERENCES users(id),
    disposed_at TIMESTAMPTZ,
    released_at TIMESTAMPTZ,
    released_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE batch_test_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES batches(id),
    test_type VARCHAR(100) NOT NULL,
    requested_by UUID REFERENCES users(id),
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    result_summary VARCHAR(50),
    completed_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE certificates_of_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    coa_ref VARCHAR(50) UNIQUE NOT NULL,
    batch_id UUID NOT NULL REFERENCES batches(id),
    generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    generated_by UUID NOT NULL REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    file_id UUID REFERENCES file_store(id),
    is_current BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- INSPECTION READINESS
-- ============================================================

CREATE SEQUENCE seq_inspection_ref START 1;

CREATE TABLE inspection_readiness_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    check_name VARCHAR(512) NOT NULL,
    check_category VARCHAR(100) NOT NULL,
    regulatory_citation VARCHAR(255),
    check_type VARCHAR(50) NOT NULL DEFAULT 'automated',
    query_config TEXT,
    last_evaluated_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'not_evaluated',
    finding_count INT NOT NULL DEFAULT 0,
    finding_details TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE inspection_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    agency VARCHAR(255) NOT NULL,
    inspection_type VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    lead_inspector_name VARCHAR(255),
    inspector_names TEXT,
    scope TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    verbal_commitments TEXT,
    closeout_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE inspection_document_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inspection_id UUID NOT NULL REFERENCES inspection_records(id),
    request_number INT NOT NULL,
    description TEXT NOT NULL,
    requested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    provided_at TIMESTAMPTZ,
    provided_by UUID REFERENCES users(id),
    linked_object_type VARCHAR(100),
    linked_object_id UUID,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SPC CHARTS
-- ============================================================

CREATE TABLE spc_charts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    chart_name VARCHAR(512) NOT NULL,
    chart_type VARCHAR(50) NOT NULL,
    data_source_type VARCHAR(100) NOT NULL,
    data_source_config TEXT,
    x_axis_field VARCHAR(100),
    y_axis_field VARCHAR(100),
    grouping_field VARCHAR(100),
    ucl_value DECIMAL(20,6),
    lcl_value DECIMAL(20,6),
    center_line_value DECIMAL(20,6),
    alert_upper DECIMAL(20,6),
    alert_lower DECIMAL(20,6),
    auto_recalculate_limits BOOLEAN NOT NULL DEFAULT TRUE,
    recalculate_period_months INT NOT NULL DEFAULT 12,
    last_recalculated_at TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE spc_out_of_control_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chart_id UUID NOT NULL REFERENCES spc_charts(id),
    detected_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    rule_violated VARCHAR(100) NOT NULL,
    rule_description TEXT,
    data_point_value DECIMAL(20,6),
    acknowledged BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledged_by UUID REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ,
    action_taken TEXT,
    oot_created BOOLEAN NOT NULL DEFAULT FALSE,
    oot_id UUID REFERENCES oos_oot_records(id)
);

-- ============================================================
-- AI GOVERNANCE
-- ============================================================

CREATE TABLE ai_suggestions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    suggestion_type VARCHAR(100) NOT NULL,
    source_object_type VARCHAR(100) NOT NULL,
    source_object_id UUID NOT NULL,
    model_version VARCHAR(50),
    suggestion_content TEXT NOT NULL,
    confidence_score DECIMAL(5,4),
    presented_to UUID REFERENCES users(id),
    presented_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted BOOLEAN,
    accepted_at TIMESTAMPTZ,
    accepted_by UUID REFERENCES users(id),
    user_modification TEXT,
    dismissed_reason VARCHAR(255)
);

CREATE TABLE ai_model_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_name VARCHAR(255) NOT NULL,
    model_version VARCHAR(50) NOT NULL,
    model_type VARCHAR(100) NOT NULL,
    validation_status VARCHAR(50) NOT NULL DEFAULT 'not_validated',
    validation_date DATE,
    validation_document_id UUID REFERENCES documents(id),
    deployed_at TIMESTAMPTZ,
    retired_at TIMESTAMPTZ,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id),
    UNIQUE (model_name, model_version)
);

-- ============================================================
-- MANUFACTURING ANALYTICS EXTENSION
-- ============================================================

CREATE TABLE process_parameters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    parameter_name VARCHAR(512) NOT NULL,
    parameter_code VARCHAR(100) UNIQUE NOT NULL,
    parameter_type VARCHAR(50) NOT NULL DEFAULT 'monitoring',
    unit VARCHAR(50),
    normal_lower DECIMAL(20,6),
    normal_upper DECIMAL(20,6),
    alert_lower DECIMAL(20,6),
    alert_upper DECIMAL(20,6),
    action_lower DECIMAL(20,6),
    action_upper DECIMAL(20,6),
    equipment_id UUID REFERENCES equipment(id),
    is_gxp_relevant BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE process_data_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parameter_id UUID NOT NULL REFERENCES process_parameters(id),
    batch_id UUID REFERENCES batches(id),
    timestamp TIMESTAMPTZ NOT NULL,
    value DECIMAL(20,6) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'normal' CHECK (status IN ('normal','alert','action')),
    source VARCHAR(50) NOT NULL DEFAULT 'manual',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE batch_process_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    batch_id UUID NOT NULL REFERENCES batches(id),
    parameter_id UUID NOT NULL REFERENCES process_parameters(id),
    min_value DECIMAL(20,6),
    max_value DECIMAL(20,6),
    mean_value DECIMAL(20,6),
    std_deviation DECIMAL(20,6),
    time_in_normal_pct DECIMAL(5,2),
    time_in_alert_pct DECIMAL(5,2),
    time_in_action_pct DECIMAL(5,2),
    exceedance_count INT NOT NULL DEFAULT 0,
    summary_generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (batch_id, parameter_id)
);

-- ============================================================
-- CROSS-SITE ENTERPRISE FEATURES
-- ============================================================

CREATE TABLE document_cross_site_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_document_id UUID NOT NULL REFERENCES documents(id),
    source_version_id UUID NOT NULL REFERENCES document_versions(id),
    target_site_id UUID NOT NULL REFERENCES sites(id),
    distribution_type VARCHAR(50) NOT NULL DEFAULT 'controlled_copy',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    distributed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    distributed_by UUID REFERENCES users(id),
    local_adaptation_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (source_document_id, target_site_id)
);

CREATE TABLE organization_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    setting_key VARCHAR(255) NOT NULL,
    setting_value TEXT,
    setting_type VARCHAR(50) NOT NULL DEFAULT 'string',
    description TEXT,
    is_site_overridable BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id),
    UNIQUE (organization_id, setting_key)
);

-- ============================================================
-- EXTERNAL REFERENCE COLUMNS
-- (add external_ref to key tables for integration linkage)
-- ============================================================

ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS external_ref VARCHAR(255);
ALTER TABLE change_requests ADD COLUMN IF NOT EXISTS external_system VARCHAR(100);
ALTER TABLE capas ADD COLUMN IF NOT EXISTS external_ref VARCHAR(255);
ALTER TABLE capas ADD COLUMN IF NOT EXISTS external_system VARCHAR(100);
ALTER TABLE nonconformances ADD COLUMN IF NOT EXISTS external_ref VARCHAR(255);
ALTER TABLE nonconformances ADD COLUMN IF NOT EXISTS external_system VARCHAR(100);
ALTER TABLE deviations ADD COLUMN IF NOT EXISTS external_ref VARCHAR(255);
ALTER TABLE deviations ADD COLUMN IF NOT EXISTS external_system VARCHAR(100);

-- ============================================================
-- NEW SEQUENCES
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_oos_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_complaint_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_em_session_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_em_excursion_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_stability_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_batch_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_coa_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_inspection_ref START 1;

-- ============================================================
-- INDEXES FOR NEW TABLES
-- ============================================================

CREATE INDEX idx_automation_rules_site ON automation_rules (site_id, is_active);
CREATE INDEX idx_automation_rules_trigger ON automation_rules (trigger_object_type, trigger_event);
CREATE INDEX idx_automation_executions_rule ON automation_rule_executions (rule_id);
CREATE INDEX idx_automation_executions_object ON automation_rule_executions (trigger_object_type, trigger_object_id);

CREATE INDEX idx_oos_site ON oos_oot_records (site_id);
CREATE INDEX idx_oos_status ON oos_oot_records (status);
CREATE INDEX idx_oos_type ON oos_oot_records (record_type);
CREATE INDEX idx_oos_test_date ON oos_oot_records (test_date DESC);

CREATE INDEX idx_complaints_site ON complaints (site_id);
CREATE INDEX idx_complaints_status ON complaints (status);
CREATE INDEX idx_complaints_received ON complaints (received_date DESC);
CREATE INDEX idx_complaints_reportable ON complaints (is_reportable, status);

CREATE INDEX idx_em_sessions_site ON em_sessions (site_id);
CREATE INDEX idx_em_sessions_date ON em_sessions (session_date DESC);
CREATE INDEX idx_em_results_session ON em_results (session_id);
CREATE INDEX idx_em_results_point ON em_results (sample_point_id);
CREATE INDEX idx_em_results_status ON em_results (result_status);
CREATE INDEX idx_em_excursions_site ON em_excursions (site_id, status);

CREATE INDEX idx_stability_studies_site ON stability_studies (site_id, status);
CREATE INDEX idx_stability_time_points_due ON stability_time_points (pull_due_date, status);
CREATE INDEX idx_stability_results_time_point ON stability_results (time_point_id);

CREATE INDEX idx_batches_site ON batches (site_id);
CREATE INDEX idx_batches_status ON batches (status);
CREATE INDEX idx_batches_product ON batches (product_name, batch_number);
CREATE INDEX idx_batch_tests_batch ON batch_test_requests (batch_id);

CREATE INDEX idx_inspection_readiness_site ON inspection_readiness_checks (site_id, status);
CREATE INDEX idx_inspection_records_site ON inspection_records (site_id, status);
CREATE INDEX idx_inspection_doc_requests ON inspection_document_requests (inspection_id);

CREATE INDEX idx_process_data_param ON process_data_points (parameter_id, timestamp DESC);
CREATE INDEX idx_process_data_batch ON process_data_points (batch_id, timestamp DESC);
CREATE INDEX idx_process_data_status ON process_data_points (status);

CREATE INDEX idx_ai_suggestions_object ON ai_suggestions (source_object_type, source_object_id);
CREATE INDEX idx_ai_suggestions_user ON ai_suggestions (presented_to, accepted);

-- ============================================================
-- UPDATED TABLE COUNT
-- ============================================================

SELECT COUNT(*) AS total_tables
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Expected: ~140+ tables after all three schema parts
