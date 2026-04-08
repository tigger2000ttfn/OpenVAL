-- ============================================================
-- OpenVAL Schema - Part 5: Comprehensive GxP Validation Workflows
-- Version: 1.0.0
-- Run after Parts 1-4
--
-- This part adds every table needed for a complete, Kneat-equivalent
-- validation lifecycle management system. The generic workflow engine
-- in Part 1 handles routing and approvals. These tables handle the
-- domain-specific GxP validation workflow states, lifecycle tracking,
-- sign-off matrices, execution management, and all the granular
-- record-keeping that regulators actually inspect.
-- ============================================================

-- ============================================================
-- SECTION 1: VALIDATION PROJECTS
-- The top-level container for a system validation effort.
-- Groups risk assessment + requirements + protocols + documents
-- into a single trackable project with milestone management.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_val_project_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_val_plan_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_val_report_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_protocol_amendment_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_open_item_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_config_baseline_ref START 1;

CREATE TABLE validation_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_ref VARCHAR(50) UNIQUE NOT NULL,  -- VP-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    title VARCHAR(512) NOT NULL,
    description TEXT,
    project_type VARCHAR(100) NOT NULL DEFAULT 'new_system',
    -- new_system | major_upgrade | minor_upgrade | periodic_revalidation
    -- retrospective | decommission | change_control
    validation_approach VARCHAR(100) NOT NULL DEFAULT 'full_iqoqpq',
    -- full_iqoqpq | risk_based | retrospective | vendor_assessment | verification_only
    approach_justification TEXT,
    gamp_category VARCHAR(10),
    applicable_regulations TEXT,         -- JSON array

    -- Lifecycle
    status VARCHAR(50) NOT NULL DEFAULT 'planning',
    -- planning | approved | active | execution | review | complete | cancelled | on_hold

    -- Key personnel
    validation_lead_id UUID REFERENCES users(id),
    qa_lead_id UUID REFERENCES users(id),
    technical_lead_id UUID REFERENCES users(id),
    business_owner_id UUID REFERENCES users(id),

    -- Key dates
    planned_start_date DATE,
    planned_completion_date DATE,
    actual_start_date DATE,
    actual_completion_date DATE,

    -- Scope
    scope_narrative TEXT,
    exclusions TEXT,
    assumptions TEXT,
    regulatory_strategy TEXT,

    -- Links to key documents
    validation_plan_id UUID,             -- FK to validation_plans (deferred)
    risk_assessment_id UUID REFERENCES risk_assessments(id),
    change_request_id UUID REFERENCES change_requests(id),

    -- Completion
    conclusion TEXT,
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),

    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ── Project milestones ──────────────────────────────────────
CREATE TABLE validation_project_milestones (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES validation_projects(id),
    milestone_name VARCHAR(512) NOT NULL,
    milestone_type VARCHAR(100) NOT NULL,
    -- validation_plan_approved | risk_assessment_approved | urs_approved
    -- iq_protocol_approved | oq_protocol_approved | pq_protocol_approved
    -- iq_executed | oq_executed | pq_executed
    -- all_deviations_resolved | validation_report_approved | system_released
    planned_date DATE,
    actual_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending | in_progress | complete | overdue | waived
    owner_id UUID REFERENCES users(id),
    completion_notes TEXT,
    linked_object_type VARCHAR(100),     -- protocol, document, risk_assessment etc.
    linked_object_id UUID,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ── Protocol membership in project ─────────────────────────
CREATE TABLE validation_project_protocols (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES validation_projects(id),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    protocol_sequence INT NOT NULL DEFAULT 1, -- execution order within project
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    dependency_protocol_id UUID REFERENCES protocols(id), -- must pass before this runs
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (project_id, protocol_id)
);

-- ── Document membership in project ─────────────────────────
CREATE TABLE validation_project_documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES validation_projects(id),
    document_id UUID NOT NULL REFERENCES documents(id),
    document_role VARCHAR(100) NOT NULL,
    -- validation_plan | risk_assessment | urs | functional_spec | design_spec
    -- iq_protocol | oq_protocol | pq_protocol | validation_report | traceability_matrix
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (project_id, document_id)
);

-- ── Requirement set membership in project ──────────────────
CREATE TABLE validation_project_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES validation_projects(id),
    requirement_set_id UUID NOT NULL REFERENCES requirement_sets(id),
    set_role VARCHAR(100) NOT NULL DEFAULT 'URS', -- URS | FS | DS | CS
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (project_id, requirement_set_id)
);

-- ============================================================
-- SECTION 2: VALIDATION PLANS
-- Formal document (separate from generic documents) that captures
-- the validation strategy for a project.
-- ============================================================

CREATE TABLE validation_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_ref VARCHAR(50) UNIQUE NOT NULL,   -- VPLAN-0001
    project_id UUID REFERENCES validation_projects(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- draft | in_review | approved | superseded

    -- Plan content (structured fields, not just a document blob)
    system_description TEXT,
    validation_scope TEXT NOT NULL,
    validation_exclusions TEXT,
    regulatory_basis TEXT,               -- Which regulations apply and why
    gamp_classification TEXT,
    validation_approach TEXT NOT NULL,   -- Detailed approach narrative
    risk_approach TEXT,                  -- How risk drives testing depth
    testing_strategy TEXT,               -- IQ/OQ/PQ scope description
    traceability_strategy TEXT,
    deviation_handling TEXT,
    change_control_approach TEXT,
    documentation_list TEXT,             -- JSON array of planned documents
    roles_and_responsibilities TEXT,     -- JSON array of roles

    -- Key dates
    planned_iq_start DATE,
    planned_oq_start DATE,
    planned_pq_start DATE,
    planned_completion DATE,

    -- Approval
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id),
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Backfill FK from validation_projects
ALTER TABLE validation_projects
    ADD CONSTRAINT fk_vp_plan
    FOREIGN KEY (validation_plan_id) REFERENCES validation_plans(id);

-- ============================================================
-- SECTION 3: PROTOCOL REVIEW WORKFLOW
-- Separate from the generic workflow engine. Protocols need a
-- dedicated reviewer matrix: who reviews what, per role, with
-- inline comments, per-section review, and final sign-off.
-- This mirrors how Kneat handles protocol authoring and review.
-- ============================================================

CREATE TABLE protocol_reviewer_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    protocol_version VARCHAR(20) NOT NULL,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    reviewer_role VARCHAR(100) NOT NULL,
    -- author | technical_reviewer | qa_reviewer | subject_matter_expert
    -- regulatory_reviewer | approver | qa_approver
    sequence_number INT NOT NULL DEFAULT 1,  -- review order
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    due_date DATE,

    -- Review outcome
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending | in_review | approved | approved_with_comments | rejected | delegated
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    decision VARCHAR(50),
    comments TEXT,                       -- overall reviewer comments
    signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE (protocol_id, protocol_version, reviewer_id, reviewer_role)
);

-- Per-section review comments during protocol review
CREATE TABLE protocol_review_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    assignment_id UUID NOT NULL REFERENCES protocol_reviewer_assignments(id),
    section_id UUID REFERENCES protocol_sections(id),
    step_id UUID REFERENCES protocol_steps(id),
    comment_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    -- comment | question | correction | critical | suggestion
    comment_text TEXT NOT NULL,
    referenced_field VARCHAR(100),       -- which field the comment is on
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 4: REQUIREMENT SET REVIEWS
-- Per-reviewer sign-off on requirement sets.
-- Mirrors document_reviews but specific to requirements.
-- ============================================================

CREATE TABLE requirement_set_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID NOT NULL REFERENCES requirement_sets(id),
    set_version VARCHAR(20) NOT NULL,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    reviewer_role VARCHAR(100) NOT NULL,
    -- author | technical_reviewer | qa_reviewer | business_owner | approver
    sequence_number INT NOT NULL DEFAULT 1,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    due_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    decision VARCHAR(50),
    -- approved | approved_with_comments | rejected
    comments TEXT,
    comment_count INT NOT NULL DEFAULT 0,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Inline comments on individual requirements during review
CREATE TABLE requirement_review_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES requirement_set_reviews(id),
    requirement_id UUID NOT NULL REFERENCES requirements(id),
    comment_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    comment_text TEXT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 5: PRE-EXECUTION CHECKLIST
-- Before an execution begins, the executor must confirm all
-- prerequisites are met: environment ready, personnel qualified,
-- instruments calibrated, approved protocol in hand, etc.
-- 21 CFR 211.68 and Annex 11 §4 support this requirement.
-- ============================================================

CREATE TABLE protocol_pre_execution_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    check_category VARCHAR(100) NOT NULL,
    -- personnel | environment | equipment | documentation | system_state | safety
    check_description TEXT NOT NULL,    -- what must be confirmed
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    requires_evidence BOOLEAN NOT NULL DEFAULT FALSE,
    regulatory_citation VARCHAR(255),
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Results of pre-execution checks for a specific execution
CREATE TABLE execution_pre_check_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES test_executions(id),
    check_id UUID NOT NULL REFERENCES protocol_pre_execution_checks(id),
    check_description TEXT NOT NULL,    -- snapshot
    result VARCHAR(20) NOT NULL,        -- confirmed | not_confirmed | not_applicable
    confirmed_by UUID REFERENCES users(id),
    confirmed_at TIMESTAMPTZ,
    comments TEXT,
    evidence_file_id UUID REFERENCES file_store(id),
    UNIQUE (execution_id, check_id)
);

-- ============================================================
-- SECTION 6: EXECUTION WITNESS LOG
-- Detailed witness records for steps that require independent
-- witness. Separate from the executed_by fields on steps.
-- Supports 21 CFR Part 211 manufacturing documentation
-- requirements and Annex 11 data integrity.
-- ============================================================

CREATE TABLE execution_witness_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES test_executions(id),
    step_execution_id UUID REFERENCES test_execution_steps(id),
    -- NULL = witnessing entire execution, not a specific step
    witness_id UUID NOT NULL REFERENCES users(id),
    witness_role VARCHAR(100) NOT NULL DEFAULT 'witness',
    -- witness | second_reviewer | independent_verifier | qa_observer
    witnessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    scope_description TEXT,             -- what was witnessed
    observations TEXT,                  -- any observations noted
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 7: EXECUTION PAUSE/RESUME LOG
-- When an execution is paused (shift change, equipment failure,
-- environmental exceedance, etc.) the reason and duration must
-- be documented. Required for audit trail completeness.
-- ============================================================

CREATE TABLE execution_pause_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES test_executions(id),
    paused_by UUID NOT NULL REFERENCES users(id),
    paused_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    pause_reason VARCHAR(100) NOT NULL,
    -- planned_break | shift_change | equipment_issue | environmental_event
    -- deviation_investigation | emergency | end_of_day | awaiting_materials
    pause_description TEXT NOT NULL,
    resumed_by UUID REFERENCES users(id),
    resumed_at TIMESTAMPTZ,
    resume_notes TEXT,
    last_completed_step_ref VARCHAR(50),  -- which step was last completed
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SECTION 8: TEST STEP TABULAR DATA ENTRIES
-- For protocol steps with input_type = 'table'.
-- The step defines column structure in input_options.
-- This table stores the actual row data entered.
-- Critical for IQ steps like "record all installed components"
-- or OQ steps like "record 5 replicates and calculate RSD".
-- ============================================================

CREATE TABLE test_step_table_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_step_id UUID NOT NULL REFERENCES test_execution_steps(id),
    row_number INT NOT NULL,
    column_key VARCHAR(100) NOT NULL,   -- matches column definition in step input_options
    column_label VARCHAR(255) NOT NULL, -- snapshot of column label
    cell_value TEXT,
    cell_value_numeric DECIMAL(20,6),   -- parsed numeric if applicable
    is_within_spec BOOLEAN,             -- computed against acceptance criteria
    spec_lower_limit DECIMAL(20,6),
    spec_upper_limit DECIMAL(20,6),
    unit VARCHAR(50),
    entered_by UUID REFERENCES users(id),
    entered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (execution_step_id, row_number, column_key)
);

-- Computed summary for a table step (e.g., mean, std dev, RSD)
CREATE TABLE test_step_table_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_step_id UUID NOT NULL REFERENCES test_execution_steps(id),
    column_key VARCHAR(100) NOT NULL,
    summary_type VARCHAR(50) NOT NULL,  -- mean | std_dev | rsd | min | max | count | sum
    computed_value DECIMAL(20,6),
    unit VARCHAR(50),
    acceptance_limit VARCHAR(255),      -- e.g. "≤ 2.0%"
    meets_acceptance BOOLEAN,
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (execution_step_id, column_key, summary_type)
);

-- ============================================================
-- SECTION 9: PROTOCOL OPEN ITEMS
-- Items identified during execution or review that need
-- resolution before the protocol can be closed.
-- Not the same as a deviation — an open item might be a
-- clarification needed, a documentation gap, or a follow-up
-- action that doesn't invalidate the test result.
-- ============================================================

CREATE TABLE protocol_open_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_ref VARCHAR(50) UNIQUE NOT NULL,  -- OI-0001
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    execution_id UUID REFERENCES test_executions(id),
    step_id UUID REFERENCES protocol_steps(id),
    raised_by UUID NOT NULL REFERENCES users(id),
    raised_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    item_type VARCHAR(100) NOT NULL,
    -- clarification | documentation_gap | follow_up_action | pending_calibration
    -- data_reconciliation | configuration_verification | vendor_response
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'minor',
    -- minor | moderate | major
    -- major open items prevent protocol closure
    blocks_closure BOOLEAN NOT NULL DEFAULT FALSE,
    assigned_to UUID REFERENCES users(id),
    target_resolution_date DATE,
    resolution TEXT,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    -- open | in_progress | resolved | accepted | cancelled
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 10: PROTOCOL AMENDMENTS
-- When a protocol must be changed during execution
-- (e.g., a test step needs rewording, a tolerance discovered
-- to be incorrect), an amendment is the GxP-compliant path.
-- The amendment is reviewed, approved, and logged before
-- execution continues. 21 CFR 211.192 supports this.
-- ============================================================

CREATE TABLE protocol_amendments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    amendment_ref VARCHAR(50) UNIQUE NOT NULL,  -- AMD-0001
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    execution_id UUID REFERENCES test_executions(id),
    -- NULL = amendment before execution starts
    title VARCHAR(512) NOT NULL,
    rationale TEXT NOT NULL,
    amendment_type VARCHAR(100) NOT NULL,
    -- editorial | step_modification | acceptance_criteria_change
    -- scope_change | procedure_addition | step_removal
    gxp_impact_assessment TEXT,
    regulatory_impact BOOLEAN NOT NULL DEFAULT FALSE,
    requires_retest BOOLEAN NOT NULL DEFAULT FALSE,
    retest_scope TEXT,

    -- What changed
    affected_sections TEXT,             -- JSON array of section IDs
    affected_steps TEXT,                -- JSON array of step IDs
    change_description TEXT NOT NULL,   -- before/after narrative
    original_text TEXT,
    revised_text TEXT,

    -- Approval
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- draft | submitted | approved | rejected | withdrawn
    submitted_by UUID REFERENCES users(id),
    submitted_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES users(id),
    reviewed_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    rejection_reason TEXT,

    -- Applied
    applied_at TIMESTAMPTZ,
    applied_by UUID REFERENCES users(id),
    application_notes TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 11: EXECUTION REVIEW (POST-EXECUTION QA REVIEW)
-- After execution completes, QA reviews the entire execution
-- record before it can be formally closed and signed.
-- This is the GxP review step between "execution complete"
-- and "protocol closed". Standard in all validated environments.
-- ============================================================

CREATE TABLE execution_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES test_executions(id),
    reviewer_id UUID NOT NULL REFERENCES users(id),
    reviewer_role VARCHAR(100) NOT NULL DEFAULT 'qa_reviewer',
    -- technical_reviewer | qa_reviewer | independent_reviewer | approver
    sequence_number INT NOT NULL DEFAULT 1,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    due_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    decision VARCHAR(50),
    -- approved | approved_with_conditions | rejected | requires_additional_testing
    conditions TEXT,                    -- if approved_with_conditions
    rejection_reason TEXT,
    overall_comments TEXT,
    -- Checklist items reviewed
    steps_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    deviations_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    attachments_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    open_items_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    data_integrity_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    alcoa_compliance_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    -- Sign-off
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Comments raised during execution review
CREATE TABLE execution_review_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES execution_reviews(id),
    step_execution_id UUID REFERENCES test_execution_steps(id),
    deviation_id UUID REFERENCES deviations(id),
    open_item_id UUID REFERENCES protocol_open_items(id),
    comment_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    -- comment | critical | question | correction | data_integrity_concern
    comment_text TEXT NOT NULL,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_text TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 12: CONFIGURATION BASELINES
-- At time of validation, the exact configuration of the system
-- must be documented and locked. Changes to the configuration
-- after validation are tracked against this baseline.
-- This is the technical equivalent of "what was validated".
-- Required by GAMP 5 and 21 CFR Part 11.
-- ============================================================

CREATE TABLE configuration_baselines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baseline_ref VARCHAR(50) UNIQUE NOT NULL,  -- CB-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    execution_id UUID REFERENCES test_executions(id),
    -- Which execution established this baseline
    project_id UUID REFERENCES validation_projects(id),
    title VARCHAR(512) NOT NULL,
    description TEXT,
    baseline_type VARCHAR(100) NOT NULL DEFAULT 'validated_state',
    -- validated_state | pre_upgrade_snapshot | post_change_baseline
    baseline_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- draft | approved | superseded

    -- System state captured
    software_version VARCHAR(255),
    database_version VARCHAR(255),
    os_version VARCHAR(255),
    infrastructure_details TEXT,        -- JSON
    network_configuration TEXT,         -- JSON (IPs, ports, protocols)
    user_accounts_snapshot TEXT,        -- JSON (list of accounts at baseline time)
    installed_components TEXT,          -- JSON array
    interface_configuration TEXT,       -- JSON (interface states)
    security_configuration TEXT,        -- JSON (roles, permissions summary)
    backup_configuration TEXT,
    audit_trail_configuration TEXT,     -- Confirm audit trail enabled, settings

    -- Approved
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),

    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Individual configuration items within a baseline
CREATE TABLE configuration_baseline_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baseline_id UUID NOT NULL REFERENCES configuration_baselines(id),
    category VARCHAR(100) NOT NULL,
    -- software | hardware | database | network | security | audit | backup | interface
    item_name VARCHAR(512) NOT NULL,
    item_key VARCHAR(255),              -- configuration parameter key
    item_value TEXT,                    -- value at baseline
    expected_value TEXT,                -- what the validation requires
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,
    -- critical items trigger revalidation if changed
    gxp_relevant BOOLEAN NOT NULL DEFAULT FALSE,
    validated BOOLEAN NOT NULL DEFAULT TRUE,
    deviation_from_urs BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_justification TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

-- Changes to configuration after baseline (tracked against baseline)
CREATE TABLE configuration_change_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    baseline_id UUID NOT NULL REFERENCES configuration_baselines(id),
    item_id UUID REFERENCES configuration_baseline_items(id),
    change_description TEXT NOT NULL,
    old_value TEXT,
    new_value TEXT,
    change_reason TEXT NOT NULL,
    change_request_id UUID REFERENCES change_requests(id),
    revalidation_required BOOLEAN NOT NULL DEFAULT FALSE,
    revalidation_rationale TEXT,
    changed_by UUID NOT NULL REFERENCES users(id),
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id)
);

-- ============================================================
-- SECTION 13: VALIDATION SUMMARY REPORTS
-- The formal document that summarizes all validation activities
-- for a system, references all protocols, test results, open items,
-- deviations, and declares the system validated.
-- Signed by QA, Technical Owner, and Business Owner.
-- ============================================================

CREATE TABLE validation_summary_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_ref VARCHAR(50) UNIQUE NOT NULL,   -- VSR-0001
    project_id UUID REFERENCES validation_projects(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    title VARCHAR(512) NOT NULL,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- Report metadata
    report_period_start DATE,
    report_period_end DATE,
    prepared_by UUID REFERENCES users(id),
    prepared_at DATE,

    -- Summary narratives
    executive_summary TEXT,
    system_description TEXT,
    validation_scope TEXT,
    validation_approach_summary TEXT,
    regulatory_basis TEXT,
    testing_summary TEXT,
    deviation_summary TEXT,
    open_items_summary TEXT,
    training_summary TEXT,

    -- Overall conclusion
    validation_conclusion VARCHAR(100),
    -- validated | conditionally_validated | not_validated | requires_follow_up
    conclusion_narrative TEXT NOT NULL,

    -- References (JSON arrays of IDs)
    referenced_protocol_ids TEXT,
    referenced_execution_ids TEXT,
    referenced_document_ids TEXT,
    referenced_deviation_ids TEXT,
    referenced_capa_ids TEXT,

    -- Metrics (auto-computed when generated)
    total_requirements INT,
    requirements_tested INT,
    requirements_passed INT,
    total_test_steps INT,
    steps_passed INT,
    steps_failed INT,
    steps_with_deviations INT,
    total_deviations INT,
    deviations_resolved INT,
    open_deviations INT,
    total_open_items INT,
    open_items_resolved INT,
    open_items_remaining INT,

    -- Residual risks
    accepted_residual_risks TEXT,       -- JSON array

    -- Approval sign-offs (structured, not just workflow)
    author_id UUID REFERENCES users(id),
    author_signed_at TIMESTAMPTZ,
    author_signature_id UUID REFERENCES electronic_signatures(id),
    technical_reviewer_id UUID REFERENCES users(id),
    technical_reviewer_signed_at TIMESTAMPTZ,
    technical_reviewer_signature_id UUID REFERENCES electronic_signatures(id),
    qa_approver_id UUID REFERENCES users(id),
    qa_approved_at TIMESTAMPTZ,
    qa_signature_id UUID REFERENCES electronic_signatures(id),
    business_owner_id UUID REFERENCES users(id),
    business_owner_signed_at TIMESTAMPTZ,
    business_owner_signature_id UUID REFERENCES electronic_signatures(id),

    -- After all signatures, system is formally validated
    effective_date DATE,

    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 14: SYSTEM VALIDATION SIGN-OFF MATRIX
-- The formal, structured sign-off that a system is validated.
-- Multiple signatories from multiple roles. Each signs
-- independently. When all sign, the system validated_status
-- is updated to 'validated'. This is the GxP equivalent of
-- a completion certificate.
-- ============================================================

CREATE TABLE system_validation_signoffs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES systems(id),
    project_id UUID REFERENCES validation_projects(id),
    report_id UUID REFERENCES validation_summary_reports(id),
    signoff_type VARCHAR(100) NOT NULL DEFAULT 'initial_validation',
    -- initial_validation | revalidation | change_related_validation
    -- retrospective_validation | validation_extension

    title VARCHAR(512) NOT NULL,
    -- e.g. "LabWare LIMS 7.0 Initial Validation Sign-Off"
    validation_conclusion VARCHAR(50) NOT NULL,
    -- validated | conditionally_validated
    conditions TEXT,                    -- if conditionally validated
    condition_resolution_date DATE,
    condition_resolved BOOLEAN NOT NULL DEFAULT FALSE,

    effective_date DATE NOT NULL,
    next_periodic_review_date DATE,
    revalidation_triggers TEXT,         -- JSON: list of events that would trigger revalidation

    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending | partially_signed | complete | superseded

    -- The sign-off is complete when all required signatories have signed
    all_signed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,

    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Individual signatory records
CREATE TABLE system_validation_signatories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    signoff_id UUID NOT NULL REFERENCES system_validation_signoffs(id),
    signatory_id UUID NOT NULL REFERENCES users(id),
    signatory_role VARCHAR(100) NOT NULL,
    -- technical_owner | business_owner | qa_manager | validation_lead | it_manager
    sequence_number INT NOT NULL DEFAULT 1,
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date DATE,
    signed_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    comments TEXT,
    UNIQUE (signoff_id, signatory_id, signatory_role)
);

-- ============================================================
-- SECTION 15: WORKFLOW ENGINE ENHANCEMENTS
-- Tables missing from the generic workflow engine that are
-- needed for a complete GxP workflow system.
-- ============================================================

-- Workflow definition versioning (changes to workflow definitions are tracked)
CREATE TABLE workflow_definition_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    definition_id UUID NOT NULL REFERENCES workflow_definitions(id),
    version_number INT NOT NULL,
    change_summary TEXT,
    change_type VARCHAR(50) NOT NULL DEFAULT 'minor',
    -- minor | major (major = requires re-approval of in-flight instances)
    validation_impact VARCHAR(50) NOT NULL DEFAULT 'none',
    snapshot TEXT NOT NULL,             -- full JSON snapshot of definition + stages
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (definition_id, version_number)
);

-- Workflow stage comments (separate from action_taken field)
CREATE TABLE workflow_stage_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_stage_id UUID NOT NULL REFERENCES workflow_instance_stages(id),
    author_id UUID NOT NULL REFERENCES users(id),
    comment_text TEXT NOT NULL,
    comment_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    -- comment | question | condition | concern | information
    is_private BOOLEAN NOT NULL DEFAULT FALSE,
    -- private = only visible to same role, not the submitter
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Approval routing overrides (emergency re-routing of workflow)
CREATE TABLE workflow_routing_overrides (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES workflow_instances(id),
    original_stage_id UUID REFERENCES workflow_stages(id),
    override_type VARCHAR(50) NOT NULL,
    -- reassign | skip_stage | add_stage | emergency_approve | cancel
    justification TEXT NOT NULL,
    new_assignee_id UUID REFERENCES users(id),
    override_approved_by UUID NOT NULL REFERENCES users(id),
    override_approved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    override_signature_id UUID REFERENCES electronic_signatures(id),
    -- All routing overrides require an e-signature (21 CFR 11 requirement)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- Workflow SLA tracking (separate from escalations, tracks SLA performance)
CREATE TABLE workflow_sla_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_stage_id UUID NOT NULL REFERENCES workflow_instance_stages(id),
    event_type VARCHAR(50) NOT NULL,
    -- sla_warning | sla_breach | escalation_triggered | escalation_resolved
    sla_hours INT,
    actual_hours_elapsed DECIMAL(10,2),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notified_users TEXT                 -- JSON array of user IDs notified
);

-- ============================================================
-- SECTION 16: DOCUMENT VERSION DIFFS
-- Stores a computed diff between consecutive document versions.
-- Used in the review UI to show exactly what changed.
-- Critical for reviewers of updated SOPs and protocols.
-- ============================================================

CREATE TABLE document_version_diffs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id),
    from_version_id UUID NOT NULL REFERENCES document_versions(id),
    to_version_id UUID NOT NULL REFERENCES document_versions(id),
    diff_format VARCHAR(50) NOT NULL DEFAULT 'unified',
    -- unified | rich_text | section_level
    diff_content TEXT NOT NULL,         -- computed diff (JSON or HTML)
    change_stats TEXT,
    -- JSON: {added_words, removed_words, changed_sections, unchanged_sections}
    computed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (from_version_id, to_version_id)
);

-- ============================================================
-- SECTION 17: VALIDATION LIFECYCLE STATE MACHINE
-- Defines valid status transitions for each validated object type.
-- Enforced by the application. Prevents invalid state changes
-- (e.g., can't execute a protocol that hasn't been approved).
-- Documents the regulatory basis for each allowed transition.
-- ============================================================

CREATE TABLE lifecycle_state_machines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    object_type VARCHAR(100) NOT NULL,
    -- protocols | documents | risk_assessments | requirement_sets | capas
    -- change_requests | deviations | validation_projects | validation_summary_reports
    -- system_validation_signoffs | periodic_reviews
    machine_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE (object_type)
);

CREATE TABLE lifecycle_state_transitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    machine_id UUID NOT NULL REFERENCES lifecycle_state_machines(id),
    from_status VARCHAR(50) NOT NULL,   -- NULL = initial state (any -> this)
    to_status VARCHAR(50) NOT NULL,
    transition_name VARCHAR(100) NOT NULL,
    -- submit_for_review | approve | reject | execute | complete | close | void | etc.
    description TEXT,
    requires_permission VARCHAR(255),   -- module:action string
    requires_signature BOOLEAN NOT NULL DEFAULT FALSE,
    signature_meaning_code VARCHAR(50) REFERENCES signature_meanings(code),
    requires_workflow BOOLEAN NOT NULL DEFAULT FALSE,
    requires_fields TEXT,               -- JSON: fields that must be populated
    conditions TEXT,                    -- JSON: additional business rule conditions
    regulatory_citation VARCHAR(512),
    is_reversible BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0
);

-- Seed the lifecycle state machines for key objects
INSERT INTO lifecycle_state_machines (object_type, machine_name, description) VALUES
('protocols', 'Protocol Lifecycle',
 'Governs the lifecycle of a validation protocol from draft through approved, executed, and closed.'),
('documents', 'Document Lifecycle',
 'Governs controlled document lifecycle from draft through effective and eventual obsolescence.'),
('requirement_sets', 'Requirements Lifecycle',
 'Governs requirement set lifecycle from draft through approved.'),
('risk_assessments', 'Risk Assessment Lifecycle',
 'Governs risk assessment lifecycle from draft through approved.'),
('change_requests', 'Change Request Lifecycle',
 'Governs GMP change request lifecycle from draft through closed.'),
('capas', 'CAPA Lifecycle',
 'Governs CAPA lifecycle from open through effectiveness check and closure.'),
('deviations', 'Deviation Lifecycle',
 'Governs deviation lifecycle from raised through investigated and closed.'),
('validation_projects', 'Validation Project Lifecycle',
 'Governs the overall validation project lifecycle.'),
('test_executions', 'Test Execution Lifecycle',
 'Governs individual protocol execution lifecycle.'),
('validation_summary_reports', 'Validation Summary Report Lifecycle',
 'Governs validation summary report lifecycle.'),
('system_validation_signoffs', 'System Sign-Off Lifecycle',
 'Governs the formal system validation sign-off process.');

-- Protocol lifecycle transitions
INSERT INTO lifecycle_state_transitions
    (machine_id, from_status, to_status, transition_name, description,
     requires_permission, requires_signature, signature_meaning_code,
     requires_workflow, regulatory_citation, sort_order)
SELECT m.id,
    t.from_status, t.to_status, t.transition_name, t.description,
    t.requires_permission, t.requires_signature::BOOLEAN,
    t.sig_meaning, t.requires_workflow::BOOLEAN, t.reg_citation, t.sort_order
FROM lifecycle_state_machines m,
(VALUES
    ('draft',       'in_review',   'submit_for_review',  'Submit protocol for peer review',
     'protocols:submit',     'false', NULL,      'false', '21 CFR 11.10(a)', 10),
    ('in_review',   'approved',    'approve',            'Approve protocol for execution',
     'protocols:approve',    'true',  'APPROVED', 'true',  '21 CFR 11.10(a)', 20),
    ('in_review',   'draft',       'reject',             'Return protocol to author for revision',
     'protocols:approve',    'true',  'REVIEWED', 'false', NULL, 30),
    ('approved',    'executing',   'begin_execution',    'Begin execution of approved protocol',
     'protocols:execute',    'false', NULL,       'false', '21 CFR 11.10(a)', 40),
    ('executing',   'completed',   'complete_execution', 'Mark execution as completed',
     'protocols:execute',    'false', NULL,       'false', NULL, 50),
    ('completed',   'in_review',   'submit_for_review',  'Submit completed execution for QA review',
     'protocols:submit',     'false', NULL,       'true',  NULL, 60),
    ('completed',   'passed',      'close_pass',         'Close protocol with passing result',
     'protocols:close',      'true',  'APPROVED', 'false', '21 CFR 11.10(a)', 70),
    ('completed',   'failed',      'close_fail',         'Close protocol with failing result',
     'protocols:close',      'true',  'APPROVED', 'false', NULL, 80),
    ('passed',      'voided',      'void',               'Void an approved/closed protocol',
     'protocols:void',       'true',  'QA_APPROVED','false','21 CFR 11.10(k)', 90),
    ('approved',    'voided',      'void',               'Void an approved protocol before execution',
     'protocols:void',       'true',  'QA_APPROVED','false','21 CFR 11.10(k)', 100),
    ('draft',       'voided',      'void',               'Void a draft protocol',
     'protocols:void',       'false', NULL,       'false', NULL, 110)
) AS t(from_status, to_status, transition_name, description,
       requires_permission, requires_signature, sig_meaning,
       requires_workflow, reg_citation, sort_order)
WHERE m.object_type = 'protocols';

-- Document lifecycle transitions
INSERT INTO lifecycle_state_transitions
    (machine_id, from_status, to_status, transition_name, description,
     requires_permission, requires_signature, signature_meaning_code,
     requires_workflow, regulatory_citation, sort_order)
SELECT m.id,
    t.from_status, t.to_status, t.transition_name, t.description,
    t.requires_permission, t.requires_signature::BOOLEAN,
    t.sig_meaning, t.requires_workflow::BOOLEAN, t.reg_citation, t.sort_order
FROM lifecycle_state_machines m,
(VALUES
    ('draft',      'in_review',   'submit',           'Submit document for review and approval',
     'documents:submit',    'false', NULL,       'true',  NULL, 10),
    ('in_review',  'approved',    'approve',          'Approve document',
     'documents:approve',   'true',  'APPROVED', 'false', '21 CFR 11.10(a)', 20),
    ('in_review',  'draft',       'reject',           'Return to author for revision',
     'documents:approve',   'true',  'REVIEWED', 'false', NULL, 30),
    ('approved',   'effective',   'make_effective',   'Set document as effective',
     'documents:approve',   'false', NULL,       'false', NULL, 40),
    ('effective',  'in_review',   'initiate_revision','Start new revision of effective document',
     'documents:update',    'false', NULL,       'false', NULL, 50),
    ('effective',  'obsolete',    'obsolete',         'Mark document as obsolete',
     'documents:approve',   'true',  'QA_APPROVED','false','NULL', 60),
    ('effective',  'superseded',  'supersede',        'Supersede with new version',
     'documents:approve',   'false', NULL,       'false', NULL, 70),
    ('approved',   'withdrawn',   'withdraw',         'Withdraw approved document before effective',
     'documents:approve',   'true',  'QA_APPROVED','false', NULL, 80)
) AS t(from_status, to_status, transition_name, description,
       requires_permission, requires_signature, sig_meaning,
       requires_workflow, reg_citation, sort_order)
WHERE m.object_type = 'documents';

-- ============================================================
-- SECTION 18: VALIDATION METRICS AND COMPLIANCE VIEWS
-- Pre-computed and on-demand views for compliance dashboards
-- and inspection readiness.
-- ============================================================

-- View: current validation status per system with full detail
CREATE OR REPLACE VIEW v_validation_project_status AS
SELECT
    vp.id AS project_id,
    vp.project_ref,
    vp.site_id,
    vp.title,
    vp.status AS project_status,
    s.system_ref,
    s.name AS system_name,
    s.gamp_category,
    s.validated_status,
    vp.validation_lead_id,
    ul.full_name AS validation_lead_name,
    vp.planned_completion_date,
    vp.actual_completion_date,
    -- Protocol counts
    (SELECT COUNT(*) FROM validation_project_protocols vpp
     JOIN protocols p ON p.id = vpp.protocol_id
     WHERE vpp.project_id = vp.id AND p.status = 'passed') AS protocols_passed,
    (SELECT COUNT(*) FROM validation_project_protocols vpp
     WHERE vpp.project_id = vp.id) AS protocols_total,
    -- Open deviations
    (SELECT COUNT(*) FROM deviations d
     JOIN test_executions te ON te.id = d.execution_id
     JOIN validation_project_protocols vpp ON vpp.protocol_id = te.protocol_id
     WHERE vpp.project_id = vp.id AND d.status = 'open') AS open_deviations,
    -- Open items
    (SELECT COUNT(*) FROM protocol_open_items poi
     WHERE poi.protocol_id IN (
         SELECT protocol_id FROM validation_project_protocols WHERE project_id = vp.id
     ) AND poi.status = 'open' AND poi.blocks_closure = TRUE) AS blocking_open_items,
    -- Milestone progress
    (SELECT COUNT(*) FROM validation_project_milestones vpm
     WHERE vpm.project_id = vp.id AND vpm.status = 'complete') AS milestones_complete,
    (SELECT COUNT(*) FROM validation_project_milestones vpm
     WHERE vpm.project_id = vp.id) AS milestones_total,
    -- Sign-off status
    (SELECT COUNT(*) FROM system_validation_signatories svs
     JOIN system_validation_signoffs svo ON svo.id = svs.signoff_id
     WHERE svo.project_id = vp.id AND svs.status = 'pending') AS pending_signatures
FROM validation_projects vp
JOIN systems s ON s.id = vp.system_id
LEFT JOIN users ul ON ul.id = vp.validation_lead_id;

-- View: execution completeness check (what's needed for closure)
CREATE OR REPLACE VIEW v_execution_closure_readiness AS
SELECT
    te.id AS execution_id,
    te.execution_ref,
    p.protocol_ref,
    p.protocol_type,
    te.status,
    te.overall_result,
    te.steps_passed,
    te.steps_failed,
    te.steps_with_deviations,
    te.deviation_count,
    -- Open deviations blocking closure
    (SELECT COUNT(*) FROM deviations d
     WHERE d.execution_id = te.id AND d.status = 'open') AS open_deviations,
    -- Blocking open items
    (SELECT COUNT(*) FROM protocol_open_items poi
     WHERE poi.execution_id = te.id
       AND poi.status NOT IN ('resolved','accepted','cancelled')
       AND poi.blocks_closure = TRUE) AS blocking_open_items,
    -- Pre-execution checks completed?
    (SELECT COUNT(*) FROM execution_pre_check_results epc
     WHERE epc.execution_id = te.id AND epc.result != 'not_applicable') AS checks_completed,
    (SELECT COUNT(*) FROM protocol_pre_execution_checks ppec
     WHERE ppec.protocol_id = p.id AND ppec.is_mandatory = TRUE) AS checks_required,
    -- QA review status
    (SELECT COUNT(*) FROM execution_reviews er
     WHERE er.execution_id = te.id AND er.status = 'pending') AS pending_reviews,
    -- Witness signatures
    (SELECT COUNT(*) FROM execution_witness_log ewl
     WHERE ewl.execution_id = te.id) AS witness_signatures_captured,
    -- Is it ready to close?
    CASE
        WHEN te.overall_result IS NULL THEN FALSE
        WHEN (SELECT COUNT(*) FROM deviations d
              WHERE d.execution_id = te.id AND d.status = 'open') > 0 THEN FALSE
        WHEN (SELECT COUNT(*) FROM protocol_open_items poi
              WHERE poi.execution_id = te.id
                AND poi.status NOT IN ('resolved','accepted','cancelled')
                AND poi.blocks_closure = TRUE) > 0 THEN FALSE
        WHEN (SELECT COUNT(*) FROM execution_reviews er
              WHERE er.execution_id = te.id AND er.status = 'pending') > 0 THEN FALSE
        ELSE TRUE
    END AS is_ready_for_closure
FROM test_executions te
JOIN protocols p ON p.id = te.protocol_id;

-- View: sign-off matrix status for active projects
CREATE OR REPLACE VIEW v_signoff_matrix_status AS
SELECT
    svo.id AS signoff_id,
    svo.system_id,
    s.system_ref,
    s.name AS system_name,
    svo.signoff_type,
    svo.status AS signoff_status,
    svo.effective_date,
    svo.all_signed,
    svs.signatory_id,
    u.full_name AS signatory_name,
    svs.signatory_role,
    svs.sequence_number,
    svs.is_required,
    svs.status AS signatory_status,
    svs.signed_at,
    svs.due_date,
    CASE
        WHEN svs.status = 'pending' AND svs.due_date < NOW()::DATE THEN TRUE
        ELSE FALSE
    END AS is_overdue
FROM system_validation_signoffs svo
JOIN systems s ON s.id = svo.system_id
JOIN system_validation_signatories svs ON svs.signoff_id = svo.id
JOIN users u ON u.id = svs.signatory_id
WHERE svo.status != 'superseded'
ORDER BY svo.system_id, svs.sequence_number;

-- ============================================================
-- SECTION 19: INDEXES FOR ALL NEW TABLES
-- ============================================================

CREATE INDEX idx_val_projects_site ON validation_projects (site_id);
CREATE INDEX idx_val_projects_system ON validation_projects (system_id);
CREATE INDEX idx_val_projects_status ON validation_projects (status);
CREATE INDEX idx_val_projects_lead ON validation_projects (validation_lead_id);

CREATE INDEX idx_val_milestones_project ON validation_project_milestones (project_id);
CREATE INDEX idx_val_milestones_status ON validation_project_milestones (status);
CREATE INDEX idx_val_milestones_date ON validation_project_milestones (planned_date);

CREATE INDEX idx_val_proj_protocols_project ON validation_project_protocols (project_id);
CREATE INDEX idx_val_proj_protocols_protocol ON validation_project_protocols (protocol_id);

CREATE INDEX idx_val_plans_system ON validation_plans (system_id);
CREATE INDEX idx_val_plans_status ON validation_plans (status);

CREATE INDEX idx_proto_reviewers_protocol ON protocol_reviewer_assignments (protocol_id);
CREATE INDEX idx_proto_reviewers_reviewer ON protocol_reviewer_assignments (reviewer_id, status);

CREATE INDEX idx_proto_review_comments_protocol ON protocol_review_comments (protocol_id);
CREATE INDEX idx_proto_review_comments_assignment ON protocol_review_comments (assignment_id);
CREATE INDEX idx_proto_review_comments_resolved ON protocol_review_comments (is_resolved);

CREATE INDEX idx_req_set_reviews_set ON requirement_set_reviews (set_id);
CREATE INDEX idx_req_set_reviews_reviewer ON requirement_set_reviews (reviewer_id, status);

CREATE INDEX idx_pre_exec_checks_protocol ON protocol_pre_execution_checks (protocol_id);
CREATE INDEX idx_exec_pre_check_results_execution ON execution_pre_check_results (execution_id);

CREATE INDEX idx_witness_log_execution ON execution_witness_log (execution_id);
CREATE INDEX idx_witness_log_witness ON execution_witness_log (witness_id);
CREATE INDEX idx_witness_log_step ON execution_witness_log (step_execution_id);

CREATE INDEX idx_pause_log_execution ON execution_pause_log (execution_id);

CREATE INDEX idx_step_table_entries_step ON test_step_table_entries (execution_step_id);
CREATE INDEX idx_step_table_entries_row ON test_step_table_entries (execution_step_id, row_number);

CREATE INDEX idx_step_table_summaries_step ON test_step_table_summaries (execution_step_id);

CREATE INDEX idx_open_items_protocol ON protocol_open_items (protocol_id);
CREATE INDEX idx_open_items_execution ON protocol_open_items (execution_id);
CREATE INDEX idx_open_items_status ON protocol_open_items (status);
CREATE INDEX idx_open_items_assigned ON protocol_open_items (assigned_to, status);

CREATE INDEX idx_amendments_protocol ON protocol_amendments (protocol_id);
CREATE INDEX idx_amendments_execution ON protocol_amendments (execution_id);
CREATE INDEX idx_amendments_status ON protocol_amendments (status);

CREATE INDEX idx_exec_reviews_execution ON execution_reviews (execution_id);
CREATE INDEX idx_exec_reviews_reviewer ON execution_reviews (reviewer_id, status);

CREATE INDEX idx_exec_review_comments_review ON execution_review_comments (review_id);
CREATE INDEX idx_exec_review_comments_resolved ON execution_review_comments (is_resolved);

CREATE INDEX idx_config_baselines_system ON configuration_baselines (system_id);
CREATE INDEX idx_config_baselines_status ON configuration_baselines (status);
CREATE INDEX idx_config_baseline_items_baseline ON configuration_baseline_items (baseline_id);
CREATE INDEX idx_config_change_log_baseline ON configuration_change_log (baseline_id);
CREATE INDEX idx_config_change_log_cr ON configuration_change_log (change_request_id);

CREATE INDEX idx_vsr_system ON validation_summary_reports (system_id);
CREATE INDEX idx_vsr_project ON validation_summary_reports (project_id);
CREATE INDEX idx_vsr_status ON validation_summary_reports (status);

CREATE INDEX idx_sys_signoff_system ON system_validation_signoffs (system_id);
CREATE INDEX idx_sys_signoff_project ON system_validation_signoffs (project_id);
CREATE INDEX idx_sys_signoff_status ON system_validation_signoffs (status);
CREATE INDEX idx_sys_signatories_signoff ON system_validation_signatories (signoff_id);
CREATE INDEX idx_sys_signatories_user ON system_validation_signatories (signatory_id, status);

CREATE INDEX idx_wf_def_versions_def ON workflow_definition_versions (definition_id);
CREATE INDEX idx_wf_stage_comments_stage ON workflow_stage_comments (instance_stage_id);
CREATE INDEX idx_wf_routing_overrides_instance ON workflow_routing_overrides (instance_id);
CREATE INDEX idx_wf_sla_events_stage ON workflow_sla_events (instance_stage_id);

CREATE INDEX idx_doc_version_diffs_doc ON document_version_diffs (document_id);
CREATE INDEX idx_doc_version_diffs_versions ON document_version_diffs (from_version_id, to_version_id);

CREATE INDEX idx_lifecycle_transitions_machine ON lifecycle_state_transitions (machine_id);
CREATE INDEX idx_lifecycle_transitions_from ON lifecycle_state_transitions (machine_id, from_status);

-- ============================================================
-- SECTION 20: ADDITIONAL SEQUENCES
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_val_signoff_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_config_baseline_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_execution_review_ref START 1;

-- ============================================================
-- FINAL TABLE COUNT
-- ============================================================

SELECT
    COUNT(*) AS total_tables,
    COUNT(*) FILTER (WHERE table_name LIKE 'validation_%') AS validation_tables,
    COUNT(*) FILTER (WHERE table_name LIKE 'workflow_%') AS workflow_tables,
    COUNT(*) FILTER (WHERE table_name LIKE 'protocol_%' OR table_name LIKE 'execution_%') AS protocol_tables,
    COUNT(*) FILTER (WHERE table_name LIKE '%lifecycle%') AS lifecycle_tables
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
