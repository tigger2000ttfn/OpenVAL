-- ============================================================
-- OpenVAL Schema - Part 9: Complete Gap Fill
-- Version: 1.0.0
-- Run after Parts 1-8
--
-- Adds every missing domain that a DBA would expect to find
-- in an enterprise GxP validation platform. Designed to be
-- complete for all current and future modules.
--
-- Sections:
--  1.  Workspace / Portfolio / Site-Segregation System
--  2.  Team Management
--  3.  Calendar & Scheduling
--  4.  Training Management (complete)
--  5.  Equipment Management (complete)
--  6.  Electronic Batch Records (eBR)
--  7.  Regulatory Submissions & Agency Management
--  8.  Integration Infrastructure
--  9.  Dashboard & Widget System (WP Bakery style)
-- 10.  Quality KPIs & Metrics
-- 11.  AI Model Registry & Governance
-- 12.  Inspection Findings & FDA 483 Tracking
-- 13.  Signature Delegation
-- 14.  Audit Management (complete)
-- 15.  Data Retention & Archival
-- 16.  Template Content Library
-- 17.  Document Numbering & Site Prefixes
-- 18.  Distribution Groups
-- 19.  Risk Management (complete)
-- 20.  Process Validation Enhancements
-- 21.  System Health & Operations
-- 22.  User Onboarding & Announcements
-- 23.  Reference Data Library
-- 24.  Project Templates
-- 25.  Access Requests & Delegation
-- 26.  License Usage & Billing
-- ============================================================

-- ============================================================
-- 1. WORKSPACE / PORTFOLIO / SITE-SEGREGATION SYSTEM
--
-- The workspace hierarchy gives complete flexibility for how
-- organisations want to segregate their data:
--
--   Organisation (AstraZeneca)
--   └── Region (North America)
--       ├── Site (Madison MATC)  ← already exists
--       │   ├── Workspace (IT Validation Program)
--       │   │   └── Portfolio (SAP ERP Suite)
--       │   └── Workspace (Lab Systems)
--       └── Site (Chicago)
--
-- A workspace is a logical grouping that controls:
-- - Who can see what
-- - Which data is shared vs site-specific
-- - Which teams work in it
-- ============================================================

CREATE TABLE workspaces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_ref VARCHAR(50) UNIQUE NOT NULL,
    organization_id UUID REFERENCES organizations(id),
    site_id UUID REFERENCES sites(id),          -- NULL = cross-site workspace
    parent_workspace_id UUID REFERENCES workspaces(id),
    name VARCHAR(512) NOT NULL,
    code VARCHAR(50),                           -- Short code, e.g. "ITVAL", "LAB"
    workspace_type VARCHAR(50) NOT NULL DEFAULT 'program',
    -- program | department | team | project_group | portfolio | region | site
    description TEXT,
    purpose TEXT,
    owner_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    -- Settings
    inherits_parent_settings BOOLEAN NOT NULL DEFAULT TRUE,
    data_isolation_level VARCHAR(50) NOT NULL DEFAULT 'shared',
    -- shared: members see all data in parent site
    -- restricted: members only see data explicitly in this workspace
    -- strict: full segregation, no cross-workspace visibility without explicit grant
    default_validation_approach VARCHAR(20) DEFAULT 'csv',  -- csv | csa | hybrid
    gxp_classification VARCHAR(50) DEFAULT 'gxp',          -- gxp | non_gxp | both
    -- Display
    color_hex VARCHAR(7),                       -- For visual differentiation in UI
    icon_key VARCHAR(50),                       -- Icon identifier from UI icon set
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE workspace_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id),
    user_id UUID NOT NULL REFERENCES users(id),
    role_in_workspace VARCHAR(100) NOT NULL DEFAULT 'member',
    -- owner | lead | qa_lead | member | reviewer | read_only | external
    can_create_records BOOLEAN NOT NULL DEFAULT TRUE,
    can_approve_records BOOLEAN NOT NULL DEFAULT FALSE,
    can_manage_members BOOLEAN NOT NULL DEFAULT FALSE,
    added_by UUID REFERENCES users(id),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (workspace_id, user_id)
);

CREATE TABLE portfolios (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_ref VARCHAR(50) UNIQUE NOT NULL,
    workspace_id UUID NOT NULL REFERENCES workspaces(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    name VARCHAR(512) NOT NULL,
    description TEXT,
    portfolio_type VARCHAR(100) NOT NULL DEFAULT 'system_suite',
    -- system_suite | validation_program | product_line | department | clinical_program
    owner_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    -- Metrics (auto-computed by background tasks)
    total_systems INT NOT NULL DEFAULT 0,
    validated_systems INT NOT NULL DEFAULT 0,
    systems_in_validation INT NOT NULL DEFAULT 0,
    open_capa_count INT NOT NULL DEFAULT 0,
    overdue_review_count INT NOT NULL DEFAULT 0,
    compliance_score DECIMAL(5,2),              -- 0-100 computed health score
    compliance_score_updated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE portfolio_systems (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    portfolio_id UUID NOT NULL REFERENCES portfolios(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    role_in_portfolio VARCHAR(100),             -- core | dependent | interface | peripheral
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by UUID REFERENCES users(id),
    UNIQUE (portfolio_id, system_id)
);

CREATE TABLE workspace_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID NOT NULL REFERENCES workspaces(id) UNIQUE,
    -- Document numbering
    use_custom_prefixes BOOLEAN NOT NULL DEFAULT FALSE,
    prefix_overrides TEXT,                      -- JSON: {IQ: "IQ", SOP: "SOP", ...}
    -- Approval workflows
    default_protocol_approvers TEXT,            -- JSON: [user_id, ...]
    default_qa_approver_id UUID REFERENCES users(id),
    require_witness_by_default BOOLEAN NOT NULL DEFAULT FALSE,
    -- Notifications
    escalation_email VARCHAR(512),
    -- Compliance
    default_periodic_review_months INT DEFAULT 24,
    auto_create_validation_debt BOOLEAN NOT NULL DEFAULT TRUE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 2. TEAM MANAGEMENT
-- Teams are cross-functional groups that work within workspaces.
-- Teams can span sites (for multi-site validation programs).
-- ============================================================

CREATE TABLE teams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID REFERENCES sites(id),          -- NULL = cross-site team
    workspace_id UUID REFERENCES workspaces(id),
    name VARCHAR(512) NOT NULL,
    team_type VARCHAR(100) NOT NULL DEFAULT 'validation',
    -- validation | quality | it | engineering | laboratory | cross_functional
    description TEXT,
    lead_id UUID REFERENCES users(id),
    backup_lead_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    max_concurrent_projects INT,                -- Workload limit
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id),
    user_id UUID NOT NULL REFERENCES users(id),
    role_in_team VARCHAR(100) NOT NULL DEFAULT 'member',
    -- lead | senior_member | member | part_time | contractor | stakeholder
    fte_allocation DECIMAL(4,2),                -- 0.0-1.0: fraction of FTE on this team
    start_date DATE,
    end_date DATE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    added_by UUID REFERENCES users(id),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (team_id, user_id)
);

CREATE TABLE team_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id UUID NOT NULL REFERENCES teams(id),
    object_type VARCHAR(100) NOT NULL,          -- validation_project | workflow_instance | task
    object_id UUID NOT NULL,
    assignment_type VARCHAR(50) NOT NULL DEFAULT 'primary',
    -- primary | supporting | reviewing | consulting
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id)
);

CREATE TABLE user_unavailability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    unavailability_type VARCHAR(50) NOT NULL DEFAULT 'vacation',
    -- vacation | sick | training | conference | parental_leave | other
    notes TEXT,
    backup_user_id UUID REFERENCES users(id),   -- Who covers this person's tasks?
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 3. CALENDAR & SCHEDULING
-- Validation events on a shared calendar.
-- Resource booking (equipment, labs, rooms).
-- ============================================================

CREATE TABLE validation_calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    workspace_id UUID REFERENCES workspaces(id),
    title VARCHAR(512) NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    -- protocol_execution | review_deadline | approval_due | periodic_review_due
    -- calibration_due | maintenance_due | audit | inspection | training | milestone
    -- change_freeze | go_live | package_release
    start_datetime TIMESTAMPTZ NOT NULL,
    end_datetime TIMESTAMPTZ NOT NULL,
    all_day BOOLEAN NOT NULL DEFAULT FALSE,
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
    recurrence_rule TEXT,                       -- iCal RRULE format
    color_hex VARCHAR(7),
    -- Linked record
    object_type VARCHAR(100),
    object_id UUID,
    -- People
    organizer_id UUID REFERENCES users(id),
    attendee_ids TEXT,                          -- JSON: [user_id, ...]
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    -- scheduled | completed | cancelled | rescheduled
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE resource_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    resource_type VARCHAR(50) NOT NULL,         -- equipment | lab | room | instrument | server
    resource_id UUID NOT NULL,                  -- equipment.id, room registry, etc.
    resource_name VARCHAR(512) NOT NULL,        -- Snapshot of resource name
    booked_by UUID NOT NULL REFERENCES users(id),
    booking_start TIMESTAMPTZ NOT NULL,
    booking_end TIMESTAMPTZ NOT NULL,
    purpose TEXT,
    linked_execution_id UUID REFERENCES test_executions(id),
    status VARCHAR(50) NOT NULL DEFAULT 'confirmed',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE site_working_hours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    day_of_week INT NOT NULL,                   -- 0=Sunday, 1=Monday, ..., 6=Saturday
    start_time TIME NOT NULL DEFAULT '08:00',
    end_time TIME NOT NULL DEFAULT '17:00',
    is_working_day BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE site_holidays (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    holiday_date DATE NOT NULL,
    name VARCHAR(255) NOT NULL,
    holiday_type VARCHAR(50) NOT NULL DEFAULT 'public_holiday',
    -- public_holiday | company_holiday | shutdown | validation_freeze
    UNIQUE (site_id, holiday_date)
);

-- ============================================================
-- 4. TRAINING MANAGEMENT (COMPLETE)
-- Beyond basic training_records: structured courses, assessments,
-- competency matrix, GxP qualification records.
-- ============================================================

CREATE TABLE training_courses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID REFERENCES sites(id),          -- NULL = global course
    title VARCHAR(512) NOT NULL,
    description TEXT,
    course_type VARCHAR(100) NOT NULL DEFAULT 'gxp_training',
    -- gxp_training | sop_reading | technical | safety | regulatory | onboarding
    delivery_method VARCHAR(50) NOT NULL DEFAULT 'self_study',
    -- self_study | instructor_led | elearning | on_the_job | external
    duration_minutes INT,
    valid_for_months INT DEFAULT 24,            -- How long certification lasts
    passing_score_percent DECIMAL(5,2) DEFAULT 80.0,
    requires_manager_sign_off BOOLEAN NOT NULL DEFAULT FALSE,
    linked_document_id UUID REFERENCES documents(id),
    linked_sop_ref VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE training_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    course_id UUID NOT NULL REFERENCES training_courses(id),
    title VARCHAR(512) NOT NULL,
    instructions TEXT,
    time_limit_minutes INT,
    max_attempts INT DEFAULT 3,
    randomize_questions BOOLEAN NOT NULL DEFAULT FALSE,
    show_answers_after_completion BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE training_assessment_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES training_assessments(id),
    question_text TEXT NOT NULL,
    question_type VARCHAR(50) NOT NULL DEFAULT 'multiple_choice',
    -- multiple_choice | true_false | short_answer | multi_select
    options TEXT,                               -- JSON: [{option_text, is_correct}]
    correct_answer TEXT,                        -- For short_answer: sample correct response
    explanation TEXT,                           -- Shown after attempt
    points DECIMAL(5,2) NOT NULL DEFAULT 1.0,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE training_assessment_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES training_assessments(id),
    assignment_id UUID REFERENCES training_assignments(id),
    user_id UUID NOT NULL REFERENCES users(id),
    attempt_number INT NOT NULL DEFAULT 1,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    score_percent DECIMAL(5,2),
    passed BOOLEAN,
    answers TEXT,                               -- JSON: [{question_id, given_answer, is_correct}]
    time_taken_minutes INT,
    UNIQUE (assessment_id, user_id, attempt_number)
);

CREATE TABLE competency_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),          -- NULL = global
    competency_code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(512) NOT NULL,
    description TEXT,
    competency_type VARCHAR(100) NOT NULL,
    -- technical | regulatory | safety | quality | leadership | operational
    required_for_roles TEXT,                    -- JSON: [role_id, ...]
    assessment_method VARCHAR(100),             -- exam | practical | observation | portfolio
    valid_for_months INT DEFAULT 24,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE personnel_competency_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    competency_id UUID NOT NULL REFERENCES competency_definitions(id),
    status VARCHAR(50) NOT NULL DEFAULT 'not_assessed',
    -- not_assessed | in_progress | competent | needs_improvement | expired
    assessed_date DATE,
    assessed_by UUID REFERENCES users(id),
    expiry_date DATE,
    evidence_description TEXT,
    linked_training_record_id UUID REFERENCES training_records(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, competency_id)
);

CREATE TABLE gxp_qualification_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    qualified_for VARCHAR(512) NOT NULL,        -- e.g., "Protocol Execution", "QA Approval"
    qualification_type VARCHAR(100) NOT NULL,   -- initial | requalification | extension
    qualified_date DATE NOT NULL,
    qualified_by UUID REFERENCES users(id),     -- Who signed off qualification
    expiry_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    linked_training_records TEXT,               -- JSON: [training_record_id, ...]
    signature_id UUID REFERENCES electronic_signatures(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 5. EQUIPMENT MANAGEMENT (COMPLETE)
-- Equipment type hierarchy, groups, calibration details,
-- work orders, location history, manuals.
-- ============================================================

CREATE TABLE equipment_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    parent_type_id UUID REFERENCES equipment_types(id),
    type_name VARCHAR(255) NOT NULL,
    type_category VARCHAR(100) NOT NULL,        -- analytical | manufacturing | utility | laboratory
    default_calibration_interval_months INT,
    default_maintenance_interval_months INT,
    default_qualification_scope TEXT,           -- JSON: default IQ/OQ/PQ scope for this type
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE equipment_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    group_name VARCHAR(512) NOT NULL,
    rationale TEXT NOT NULL,                    -- Why these are grouped for qualification
    representative_equipment_id UUID REFERENCES equipment(id),
    qualification_approach VARCHAR(100),        -- bracket | worst_case | all_units
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE equipment_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES equipment_groups(id),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    is_representative BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (group_id, equipment_id)
);

CREATE TABLE calibration_standards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    standard_id VARCHAR(100) NOT NULL,          -- Internal ID, e.g. "STD-0001"
    name VARCHAR(512) NOT NULL,
    type VARCHAR(100) NOT NULL,                 -- weight | volumetric | electrical | temperature
    nominal_value DECIMAL(20,8),
    unit VARCHAR(50),
    tolerance DECIMAL(20,8),
    certificate_number VARCHAR(255),
    calibrated_by VARCHAR(512),                 -- External calibration lab name
    calibration_date DATE,
    expiry_date DATE,
    traceable_to VARCHAR(255),                  -- NIST, BIPM, etc.
    certificate_file_id UUID REFERENCES file_store(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE calibration_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    calibration_record_id UUID NOT NULL REFERENCES equipment_calibration_records(id),
    point_number INT NOT NULL,
    nominal_value DECIMAL(20,8) NOT NULL,
    standard_value DECIMAL(20,8),
    measured_value DECIMAL(20,8) NOT NULL,
    unit VARCHAR(50) NOT NULL,
    tolerance_plus DECIMAL(20,8),
    tolerance_minus DECIMAL(20,8),
    within_tolerance BOOLEAN NOT NULL,
    temperature_at_measurement DECIMAL(10,4),
    humidity_at_measurement DECIMAL(10,4),
    standard_id UUID REFERENCES calibration_standards(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE maintenance_work_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    work_order_ref VARCHAR(50) UNIQUE NOT NULL,
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    work_order_type VARCHAR(50) NOT NULL DEFAULT 'preventive',
    -- preventive | corrective | emergency | inspection | overhaul
    title VARCHAR(512) NOT NULL,
    description TEXT,
    scheduled_date DATE,
    completed_date DATE,
    performed_by UUID REFERENCES users(id),
    external_vendor VARCHAR(512),
    labor_hours DECIMAL(8,2),
    parts_used TEXT,                            -- JSON: [{part_number, description, quantity}]
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    outcome TEXT,
    equipment_status_after VARCHAR(100),        -- operational | out_of_service | decommissioned
    calibration_required_after BOOLEAN NOT NULL DEFAULT FALSE,
    requalification_required BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE equipment_location_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    location_from VARCHAR(512),
    location_to VARCHAR(512) NOT NULL,
    moved_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    moved_by UUID REFERENCES users(id),
    reason VARCHAR(255),
    requalification_required BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE equipment_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    attachment_type VARCHAR(100) NOT NULL,
    -- manual | certificate | drawing | specification | service_record
    title VARCHAR(512) NOT NULL,
    file_id UUID NOT NULL REFERENCES file_store(id),
    version VARCHAR(50),
    expiry_date DATE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    uploaded_by UUID REFERENCES users(id)
);

-- ============================================================
-- 6. ELECTRONIC BATCH RECORDS (eBR)
-- Full eBR lifecycle: master record template → batch instance
-- → execution → review → release.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_ebr_master_ref START 1;
CREATE SEQUENCE IF NOT EXISTS seq_ebr_instance_ref START 1;

CREATE TABLE ebr_master_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100) NOT NULL,
    batch_size DECIMAL(20,4),
    batch_size_unit VARCHAR(50),
    process_description TEXT,
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE ebr_master_sections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    master_id UUID NOT NULL REFERENCES ebr_master_records(id),
    section_number VARCHAR(20) NOT NULL,
    title VARCHAR(512) NOT NULL,
    section_type VARCHAR(100) NOT NULL DEFAULT 'instruction',
    -- instruction | material_addition | in_process_control | equipment_use
    -- environment_check | critical_step | signature_required | documentation
    instructions TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE ebr_batch_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_ref VARCHAR(50) UNIQUE NOT NULL,
    master_id UUID NOT NULL REFERENCES ebr_master_records(id),
    master_version_at_use VARCHAR(20) NOT NULL,
    batch_id UUID REFERENCES batches(id),
    batch_number VARCHAR(100) NOT NULL,
    manufacture_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    -- in_progress | complete | in_review | released | rejected
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    production_operator_id UUID REFERENCES users(id),
    reviewer_id UUID REFERENCES users(id),
    release_signature_id UUID REFERENCES electronic_signatures(id),
    release_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE ebr_material_additions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID NOT NULL REFERENCES ebr_batch_instances(id),
    section_id UUID REFERENCES ebr_master_sections(id),
    material_name VARCHAR(512) NOT NULL,
    lot_number VARCHAR(100) NOT NULL,
    expiry_date DATE,
    required_quantity DECIMAL(20,4) NOT NULL,
    required_unit VARCHAR(50) NOT NULL,
    actual_quantity DECIMAL(20,4) NOT NULL,
    actual_unit VARCHAR(50) NOT NULL,
    within_tolerance BOOLEAN NOT NULL,
    added_by UUID REFERENCES users(id),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    witnessed_by UUID REFERENCES users(id),
    deviation_id UUID REFERENCES deviations(id)
);

CREATE TABLE ebr_in_process_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    instance_id UUID NOT NULL REFERENCES ebr_batch_instances(id),
    control_name VARCHAR(512) NOT NULL,
    specification TEXT NOT NULL,
    actual_result TEXT NOT NULL,
    numeric_result DECIMAL(20,6),
    unit VARCHAR(50),
    meets_spec BOOLEAN NOT NULL,
    tested_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    tested_by UUID REFERENCES users(id),
    instrument_id UUID REFERENCES equipment(id),
    deviation_id UUID REFERENCES deviations(id)
);

-- ============================================================
-- 7. REGULATORY SUBMISSIONS & AGENCY MANAGEMENT
-- Track regulatory filings, agency relationships,
-- commitments and queries.
-- ============================================================

CREATE TABLE regulatory_agencies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    agency_code VARCHAR(20) UNIQUE NOT NULL,    -- FDA | EMA | MHRA | TGA | PMDA | HC | ANVISA
    name VARCHAR(512) NOT NULL,
    full_name VARCHAR(1024),
    country_code VARCHAR(3),
    region VARCHAR(100),
    agency_type VARCHAR(100),                   -- drug | device | combination | food
    contact_info TEXT,
    primary_framework VARCHAR(100),             -- 21_cfr_211 | eu_gmp | mhra_gmp
    notes TEXT
);

CREATE TABLE regulatory_submissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    submission_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    agency_id UUID NOT NULL REFERENCES regulatory_agencies(id),
    submission_type VARCHAR(100) NOT NULL,
    -- nda | bla | anda | ind | maa | cta | dmf | annual_report | supplement | variation
    submission_title VARCHAR(512) NOT NULL,
    product_name VARCHAR(512),
    product_code VARCHAR(100),
    submission_date DATE,
    acceptance_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'preparing',
    -- preparing | submitted | accepted | under_review | approved | rejected | withdrawn
    regulatory_contact_id UUID REFERENCES users(id),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE regulatory_commitments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    agency_id UUID REFERENCES regulatory_agencies(id),
    submission_id UUID REFERENCES regulatory_submissions(id),
    inspection_id UUID REFERENCES inspection_records(id),
    commitment_text TEXT NOT NULL,
    commitment_type VARCHAR(100) NOT NULL,
    -- post_approval_study | labeling_change | manufacturing_change | capa
    due_date DATE NOT NULL,
    completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    responsible_id UUID REFERENCES users(id),
    evidence_description TEXT,
    linked_capa_id UUID REFERENCES capas(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE regulatory_queries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    agency_id UUID NOT NULL REFERENCES regulatory_agencies(id),
    submission_id UUID REFERENCES regulatory_submissions(id),
    query_ref VARCHAR(100),                     -- Agency's reference number
    query_text TEXT NOT NULL,
    received_date DATE NOT NULL,
    response_due_date DATE,
    response_date DATE,
    response_text TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    responsible_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 8. INTEGRATION INFRASTRUCTURE
-- Full API/webhook/external ID mapping infrastructure.
-- Every integration call is logged for GxP traceability.
-- ============================================================

CREATE TABLE integration_configurations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),          -- NULL = org-wide
    integration_code VARCHAR(50) UNIQUE NOT NULL,
    -- jira | zephyr | veeva | servicenow | labware | trackwise | sap
    -- ms_teams | slack | ldap | saml | oidc | sharepoint | ms365 | custom
    integration_name VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    auth_type VARCHAR(50) NOT NULL DEFAULT 'api_key',
    -- api_key | oauth2_client_credentials | oauth2_auth_code | basic | mtls
    base_url VARCHAR(1024),
    auth_config TEXT,                           -- Encrypted JSON: credentials, tokens, keys
    field_mappings TEXT,                        -- JSON: OpenVAL field → external field
    sync_config TEXT,                           -- JSON: frequency, direction, filters
    last_sync_at TIMESTAMPTZ,
    last_sync_status VARCHAR(50),
    webhook_secret VARCHAR(255),                -- For verifying inbound webhooks
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE integration_event_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID NOT NULL REFERENCES integration_configurations(id),
    direction VARCHAR(20) NOT NULL,             -- inbound | outbound
    event_type VARCHAR(100) NOT NULL,           -- sync | webhook | create | update | delete | auth
    http_method VARCHAR(10),
    endpoint_url VARCHAR(2048),
    request_payload TEXT,                       -- Sanitized (credentials removed)
    response_status INT,
    response_payload TEXT,
    error_message TEXT,
    duration_ms INT,
    object_type VARCHAR(100),                   -- What OpenVAL object was involved
    object_id UUID,
    success BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE external_id_mappings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    integration_id UUID NOT NULL REFERENCES integration_configurations(id),
    openval_object_type VARCHAR(100) NOT NULL,  -- system | protocol | capa | change_request
    openval_object_id UUID NOT NULL,
    external_system_code VARCHAR(50) NOT NULL,  -- jira | sap | veeva | etc.
    external_id VARCHAR(512) NOT NULL,          -- The ID in the external system
    external_url VARCHAR(2048),                 -- Direct link to record in external system
    sync_status VARCHAR(50) NOT NULL DEFAULT 'synced',
    last_synced_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (integration_id, openval_object_type, openval_object_id)
);

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    key_hash VARCHAR(255) NOT NULL UNIQUE,      -- SHA-256 of the actual key; never store plain key
    key_prefix VARCHAR(20) NOT NULL,            -- First 12 chars shown to user for identification
    scopes TEXT NOT NULL,                       -- JSON: ["read:protocols", "write:executions"]
    created_by UUID NOT NULL REFERENCES users(id),
    expires_at TIMESTAMPTZ,
    last_used_at TIMESTAMPTZ,
    last_used_ip VARCHAR(45),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE webhook_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),
    name VARCHAR(255) NOT NULL,
    target_url VARCHAR(2048) NOT NULL,
    event_types TEXT NOT NULL,                  -- JSON: ["protocol.approved", "capa.created"]
    secret_hash VARCHAR(255),                   -- For HMAC signature verification
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    failure_count INT NOT NULL DEFAULT 0,
    last_triggered_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

-- ============================================================
-- 9. DASHBOARD & WIDGET SYSTEM (WP BAKERY STYLE)
-- Fully configurable dashboards. Users drag widgets into
-- layouts. Each widget has its own config. No-code.
-- ============================================================

CREATE TABLE dashboard_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),          -- NULL = system-wide default
    workspace_id UUID REFERENCES workspaces(id),
    name VARCHAR(255) NOT NULL,
    dashboard_type VARCHAR(100) NOT NULL DEFAULT 'personal',
    -- personal | role_default | site_default | workspace_default
    intended_role VARCHAR(100),
    -- validation_engineer | qa_manager | executive | csv_specialist | all
    is_system_default BOOLEAN NOT NULL DEFAULT FALSE,
    layout_columns INT NOT NULL DEFAULT 12,     -- 12-column grid (like Bootstrap)
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE widget_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    widget_code VARCHAR(100) UNIQUE NOT NULL,
    category VARCHAR(100) NOT NULL,
    -- overview | validation | quality | documents | operations | analytics | custom
    name VARCHAR(255) NOT NULL,
    description TEXT,
    icon_key VARCHAR(50),
    component_name VARCHAR(255) NOT NULL,       -- React component name to render
    default_config TEXT,                        -- JSON: default configuration object
    config_schema TEXT,                         -- JSON Schema for the config (drives no-code config UI)
    default_width INT NOT NULL DEFAULT 4,       -- Grid columns wide
    default_height INT NOT NULL DEFAULT 3,      -- Grid rows tall (each row = ~80px)
    min_width INT NOT NULL DEFAULT 2,
    min_height INT NOT NULL DEFAULT 2,
    requires_ee BOOLEAN NOT NULL DEFAULT FALSE,
    requires_module VARCHAR(100),               -- Which EE module it belongs to
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed the widget library
INSERT INTO widget_library (widget_code, category, name, description, component_name, default_config, default_width, default_height) VALUES
('metric_systems_validated',    'overview',    'Validated Systems',       'Count and % of validated systems',  'MetricValidatedSystems',  '{"show_percentage":true}', 3, 2),
('metric_open_capas',           'quality',     'Open CAPAs',              'Open CAPAs with aging breakdown',    'MetricOpenCAPAs',         '{"show_overdue":true}',    3, 2),
('metric_pending_signatures',   'overview',    'Pending Signatures',       'Records awaiting my signature',      'MetricPendingSignatures', '{}',                       3, 2),
('metric_validation_debt',      'overview',    'Validation Debt',          'Debt severity summary',              'MetricValidationDebt',    '{"show_by_severity":true}',3, 2),
('chart_validation_status',     'validation',  'Validation Status Donut',  'Systems by validation status',       'ChartValidationStatus',   '{}',                       4, 4),
('chart_capa_aging',            'quality',     'CAPA Aging',               'Horizontal bar: CAPA by age bucket', 'ChartCAPAAging',          '{"buckets":[30,60,90]}',   6, 4),
('chart_deviation_trend',       'quality',     'Deviation Trend',          'Deviations per month by severity',   'ChartDeviationTrend',     '{"months":12}',            6, 4),
('chart_protocol_velocity',     'validation',  'Protocol Velocity',        'Protocols completed per week',        'ChartProtocolVelocity',   '{"weeks":12}',             6, 3),
('table_my_tasks',              'overview',    'My Tasks',                  'Workflow tasks assigned to me',       'TableMyTasks',            '{"max_rows":8}',           12,4),
('table_upcoming_reviews',      'overview',    'Upcoming Reviews',          'Periodic reviews in next 90 days',    'TableUpcomingReviews',    '{"days":90}',              6, 4),
('table_recent_deviations',     'quality',     'Recent Deviations',         'Deviations in last 30 days',          'TableRecentDeviations',   '{"days":30}',              6, 4),
('chart_inspection_score',      'overview',    'Inspection Readiness',      'Real-time compliance scorecard',      'ChartInspectionScore',    '{}',                       4, 4),
('timeline_milestones',         'validation',  'Project Milestones',        'Upcoming validation milestones',      'TimelineMilestones',      '{"days_ahead":90}',        12,4),
('chart_spc_sparklines',        'analytics',   'SPC Sparklines',            'Mini SPC charts for key parameters',  'ChartSPCSparklines',      '{}',                       12,5),
('calendar_mini',               'overview',    'Validation Calendar',       'Upcoming events mini calendar',        'CalendarMini',            '{"days_ahead":30}',        4, 4),
('feed_activity',               'overview',    'Activity Feed',             'Recent system activity',               'FeedActivity',            '{"max_items":10}',         4, 6)
ON CONFLICT (widget_code) DO NOTHING;

CREATE TABLE dashboard_widget_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_id UUID NOT NULL REFERENCES dashboard_definitions(id),
    widget_id UUID NOT NULL REFERENCES widget_library(id),
    -- Grid position (12-column grid)
    grid_col INT NOT NULL DEFAULT 0,            -- 0-11
    grid_row INT NOT NULL DEFAULT 0,
    grid_width INT NOT NULL DEFAULT 4,          -- Columns spanned
    grid_height INT NOT NULL DEFAULT 3,         -- Rows spanned
    -- Widget-specific configuration (overrides widget defaults)
    config TEXT,                                -- JSON: user-configured options
    title_override VARCHAR(255),                -- User can rename the widget
    is_visible BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_dashboards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    dashboard_id UUID REFERENCES dashboard_definitions(id),
    -- If NULL, user has a personal layout stored directly
    personal_layout TEXT,                       -- JSON: widget positions/configs for personal dash
    active_tab VARCHAR(100) DEFAULT 'overview',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, site_id)
);

-- ============================================================
-- 10. QUALITY KPIS & METRICS
-- Configurable KPI definitions. Background jobs calculate
-- snapshots. Trending rules trigger alerts.
-- ============================================================

CREATE TABLE quality_metric_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100) NOT NULL,
    -- validation | quality | compliance | operations | training | regulatory
    calculation_type VARCHAR(50) NOT NULL DEFAULT 'count',
    -- count | percentage | ratio | average | sum | custom
    sql_query TEXT,                             -- Safe parameterized query to calculate
    unit VARCHAR(50),
    target_value DECIMAL(15,4),
    target_direction VARCHAR(20) DEFAULT 'lower_is_better',
    -- lower_is_better | higher_is_better | within_range
    threshold_warning DECIMAL(15,4),
    threshold_critical DECIMAL(15,4),
    calculation_frequency VARCHAR(50) DEFAULT 'daily',
    -- real_time | hourly | daily | weekly | monthly
    is_system_metric BOOLEAN NOT NULL DEFAULT TRUE,
    requires_ee BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE quality_metric_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_id UUID NOT NULL REFERENCES quality_metric_definitions(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    snapshot_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    calculated_value DECIMAL(15,4) NOT NULL,
    data_payload TEXT,                          -- JSON: breakdown details
    status VARCHAR(20) NOT NULL DEFAULT 'normal',
    -- normal | warning | critical
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE quality_trend_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_id UUID NOT NULL REFERENCES quality_metric_definitions(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    alert_type VARCHAR(50) NOT NULL,
    -- threshold_breach | trend_worsening | milestone_missed
    alert_message TEXT NOT NULL,
    triggered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ
);

-- ============================================================
-- 11. AI MODEL REGISTRY & GOVERNANCE
-- Every AI model deployed gets registered, versioned, and
-- validated. AI-generated content is traceable.
-- ============================================================

CREATE TABLE ai_model_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_code VARCHAR(100) UNIQUE NOT NULL,    -- e.g., "doc-draft-v1", "gap-analysis-v2"
    model_name VARCHAR(255) NOT NULL,
    provider VARCHAR(100) NOT NULL,             -- anthropic | openai | internal
    model_version VARCHAR(100) NOT NULL,
    deployment_environment VARCHAR(50) NOT NULL, -- production | staging | development
    intended_use TEXT NOT NULL,                 -- What this model does
    input_types TEXT NOT NULL,                  -- JSON: ["text", "document_content"]
    output_types TEXT NOT NULL,                 -- JSON: ["text", "structured_json"]
    validation_status VARCHAR(50) NOT NULL DEFAULT 'not_validated',
    -- not_validated | in_validation | validated | deprecated
    validation_summary TEXT,
    bias_assessment_completed BOOLEAN NOT NULL DEFAULT FALSE,
    risk_level VARCHAR(20) NOT NULL DEFAULT 'medium',
    human_review_required BOOLEAN NOT NULL DEFAULT TRUE,
    confidence_threshold DECIMAL(5,4) DEFAULT 0.7,
    deployed_at TIMESTAMPTZ,
    deprecated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE ai_usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    model_id UUID NOT NULL REFERENCES ai_model_registry(id),
    site_id UUID REFERENCES sites(id),
    user_id UUID REFERENCES users(id),
    feature_code VARCHAR(100) NOT NULL,         -- Which AI feature was used
    input_tokens INT,
    output_tokens INT,
    latency_ms INT,
    success BOOLEAN NOT NULL DEFAULT TRUE,
    error_code VARCHAR(50),
    object_type VARCHAR(100),                   -- What was being worked on
    object_id UUID,
    human_accepted BOOLEAN,                     -- Did user accept the AI suggestion?
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 12. INSPECTION FINDINGS & FDA 483 TRACKING
-- Post-inspection management: 483 observations, warning letters,
-- commitments and responses with full traceability.
-- ============================================================

CREATE TABLE inspection_findings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    finding_ref VARCHAR(50) UNIQUE NOT NULL,
    inspection_id UUID NOT NULL REFERENCES inspection_records(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    finding_type VARCHAR(50) NOT NULL DEFAULT 'observation',
    -- observation | warning_letter_item | critical | major | minor | informational
    finding_number VARCHAR(50),                 -- e.g., "Observation 3"
    title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL,
    regulation_cited TEXT,                      -- e.g., "21 CFR 211.68(a)"
    inspector_name VARCHAR(255),
    finding_date DATE NOT NULL,
    -- Response
    response_due_date DATE,
    response_submitted_date DATE,
    response_text TEXT,
    -- Outcome
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    -- open | response_submitted | closed | escalated_to_warning_letter
    severity VARCHAR(50) NOT NULL DEFAULT 'observation',
    linked_capa_id UUID REFERENCES capas(id),
    linked_change_request_id UUID REFERENCES change_requests(id),
    closed_at TIMESTAMPTZ,
    closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE warning_letter_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    agency_id UUID REFERENCES regulatory_agencies(id),
    warning_letter_ref VARCHAR(100) NOT NULL,   -- Agency's WL number
    issue_date DATE NOT NULL,
    response_due_date DATE,
    item_number INT NOT NULL,
    item_text TEXT NOT NULL,
    regulation_cited TEXT,
    response_text TEXT,
    response_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    linked_inspection_finding_id UUID REFERENCES inspection_findings(id),
    linked_capa_id UUID REFERENCES capas(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 13. SIGNATURE DELEGATION
-- Formal delegation agreements allowing one person to sign
-- on behalf of another within defined parameters.
-- ============================================================

CREATE TABLE signature_delegation_agreements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    delegator_id UUID NOT NULL REFERENCES users(id),    -- Person delegating authority
    delegate_id UUID NOT NULL REFERENCES users(id),     -- Person receiving authority
    delegation_type VARCHAR(100) NOT NULL DEFAULT 'limited',
    -- limited (specific document types) | full (all signature rights) | temporary
    scope_description TEXT NOT NULL,                    -- What can be signed
    applicable_signature_meanings TEXT NOT NULL,        -- JSON: [meaning_code, ...]
    applicable_doc_types TEXT,                          -- JSON: [doc_type, ...]
    valid_from DATE NOT NULL,
    valid_until DATE,
    reason TEXT NOT NULL,                               -- Why delegation is needed
    approved_by UUID NOT NULL REFERENCES users(id),     -- Manager/QA approval
    approval_signature_id UUID REFERENCES electronic_signatures(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    revoked_at TIMESTAMPTZ,
    revoked_by UUID REFERENCES users(id),
    revocation_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 14. AUDIT MANAGEMENT (COMPLETE)
-- Planned audit schedule, checklists, finding details,
-- corrective responses, and follow-up actions.
-- ============================================================

CREATE TABLE audit_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    fiscal_year INT NOT NULL,
    audit_type VARCHAR(100) NOT NULL,
    -- internal_gmp | internal_it | supplier | external_regulatory | customer | iso
    planned_date DATE NOT NULL,
    scope_description TEXT NOT NULL,
    lead_auditor_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'planned',
    linked_audit_id UUID REFERENCES audit_records(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE audit_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),
    name VARCHAR(255) NOT NULL,
    audit_type VARCHAR(100) NOT NULL,
    regulatory_framework VARCHAR(100),          -- 21_cfr_211 | eu_gmp | iso_9001 | iso_13485
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE audit_checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checklist_id UUID NOT NULL REFERENCES audit_checklists(id),
    item_number VARCHAR(20) NOT NULL,
    area VARCHAR(255),                          -- Computer Systems, Change Control, etc.
    question TEXT NOT NULL,
    regulation_reference TEXT,
    guidance_notes TEXT,
    expected_evidence TEXT,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE audit_finding_responses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    finding_id UUID NOT NULL REFERENCES audit_findings(id),
    response_type VARCHAR(50) NOT NULL DEFAULT 'initial',
    -- initial | follow_up | closure_evidence | escalation
    response_text TEXT NOT NULL,
    response_date DATE NOT NULL DEFAULT CURRENT_DATE,
    submitted_by UUID REFERENCES users(id),
    accepted_by_auditor BOOLEAN,
    auditor_comments TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 15. DATA RETENTION & ARCHIVAL
-- Configurable retention policies per record type.
-- Archival workflow with legal hold support.
-- ============================================================

CREATE TABLE retention_policies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),          -- NULL = org-wide
    policy_name VARCHAR(255) NOT NULL,
    record_type VARCHAR(100) NOT NULL,
    -- document | protocol | execution | capa | deviation | audit_log | training_record
    retention_years INT NOT NULL,
    regulatory_basis TEXT,                      -- Why this retention period
    archive_after_years INT,                    -- Move to cold storage after N years
    auto_purge_after_years INT,                 -- Hard delete after N years (if permitted)
    requires_legal_review_before_purge BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE archival_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    requested_by UUID NOT NULL REFERENCES users(id),
    record_type VARCHAR(100) NOT NULL,
    record_ids TEXT NOT NULL,                   -- JSON: [uuid, ...]
    reason TEXT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending | approved | in_progress | archived | rejected
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    archive_location TEXT,                      -- Where archived (storage path or external ref)
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE legal_holds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    hold_ref VARCHAR(50) UNIQUE NOT NULL,
    title VARCHAR(512) NOT NULL,
    reason TEXT NOT NULL,                       -- Legal/regulatory reason
    affected_record_types TEXT NOT NULL,        -- JSON: list of affected record types
    filter_criteria TEXT,                       -- JSON: date ranges, system IDs, etc.
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    released_by UUID REFERENCES users(id),
    released_at TIMESTAMPTZ
);

-- ============================================================
-- 16. TEMPLATE CONTENT LIBRARY
-- Pre-written test steps, boilerplate paragraphs, acceptance
-- criteria, and glossary — all reusable across templates.
-- ============================================================

CREATE TABLE template_step_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_code VARCHAR(100) UNIQUE NOT NULL,
    site_id UUID REFERENCES sites(id),          -- NULL = global
    category VARCHAR(100) NOT NULL,
    -- audit_trail | access_control | data_entry | report | backup | interface
    -- configuration | user_management | performance | security | data_integrity
    title VARCHAR(512) NOT NULL,
    step_type VARCHAR(50) NOT NULL DEFAULT 'check',
    action_text TEXT NOT NULL,
    expected_result_text TEXT NOT NULL,
    acceptance_criteria TEXT,
    regulatory_citations TEXT,                  -- JSON: ["21 CFR 11.10(e)", ...]
    applicable_gamp_categories TEXT,            -- JSON: ["3","4","5"]
    applicable_protocol_types TEXT,             -- JSON: ["OQ","UAT"]
    usage_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE template_boilerplate_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    boilerplate_code VARCHAR(100) UNIQUE NOT NULL,
    site_id UUID REFERENCES sites(id),
    category VARCHAR(100) NOT NULL,
    -- purpose_statement | scope_statement | abbreviations | references
    -- regulatory_background | document_control_policy | gxp_notice
    title VARCHAR(255) NOT NULL,
    content_html TEXT NOT NULL,                 -- TipTap JSON-serializable rich text
    variables_used TEXT,                        -- JSON: variable keys used in content
    applicable_doc_types TEXT,                  -- JSON: doc types this applies to
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE template_acceptance_criteria_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    criteria_code VARCHAR(100) UNIQUE NOT NULL,
    site_id UUID REFERENCES sites(id),
    category VARCHAR(100) NOT NULL,
    -- performance | security | data_integrity | availability | audit_trail
    criteria_text TEXT NOT NULL,
    verification_method TEXT,
    regulatory_basis TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id)
);

CREATE TABLE gxp_glossary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    term VARCHAR(255) UNIQUE NOT NULL,
    abbreviation VARCHAR(50),
    definition TEXT NOT NULL,
    regulatory_source TEXT,
    category VARCHAR(100) NOT NULL DEFAULT 'general',
    -- general | regulatory | validation | quality | manufacturing | laboratory
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ============================================================
-- 17. DOCUMENT NUMBERING & SITE PREFIXES
-- Configurable document numbering: every site can have
-- different prefixes and numbering formats.
-- ============================================================

CREATE TABLE document_numbering_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    doc_type VARCHAR(100) NOT NULL,
    prefix VARCHAR(20) NOT NULL,                -- e.g., "SOP", "IQ", "OQ", "CAPA"
    separator VARCHAR(5) NOT NULL DEFAULT '-',  -- Between prefix and number
    number_length INT NOT NULL DEFAULT 4,       -- Zero-padded to this length
    current_sequence INT NOT NULL DEFAULT 0,
    suffix VARCHAR(20),                         -- Optional suffix
    reset_on_year_change BOOLEAN NOT NULL DEFAULT FALSE,
    include_year BOOLEAN NOT NULL DEFAULT FALSE,
    example_output VARCHAR(100),                -- Auto-computed: "SOP-2026-0042"
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (site_id, doc_type)
);

-- ============================================================
-- 18. DISTRIBUTION GROUPS
-- Pre-configured groups for document distribution.
-- Instead of manually selecting users each time.
-- ============================================================

CREATE TABLE distribution_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID NOT NULL REFERENCES sites(id),
    group_ref VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    group_type VARCHAR(100) NOT NULL DEFAULT 'manual',
    -- manual | role_based | department | team | site_all
    role_filter VARCHAR(100),                   -- For role_based type
    department_filter VARCHAR(255),             -- For department type
    team_id UUID REFERENCES teams(id),
    requires_read_confirmation BOOLEAN NOT NULL DEFAULT TRUE,
    read_confirmation_days INT NOT NULL DEFAULT 30,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE distribution_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES distribution_groups(id),
    user_id UUID NOT NULL REFERENCES users(id),
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    added_by UUID REFERENCES users(id),
    UNIQUE (group_id, user_id)
);

-- ============================================================
-- 19. RISK MANAGEMENT (COMPLETE)
-- Risk controls as a separate entity. Risk review events.
-- Formal risk acceptance records. Escalation tracking.
-- ============================================================

CREATE TABLE risk_controls (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_item_id UUID NOT NULL REFERENCES risk_items(id),
    control_description TEXT NOT NULL,
    control_type VARCHAR(100) NOT NULL DEFAULT 'procedural',
    -- procedural | technical | administrative | detective | preventive
    control_owner_id UUID REFERENCES users(id),
    implementation_status VARCHAR(50) NOT NULL DEFAULT 'planned',
    -- planned | in_progress | implemented | verified | not_required
    implementation_date DATE,
    effectiveness_rating VARCHAR(20),           -- high | medium | low | not_assessed
    linked_sop_id UUID REFERENCES documents(id),
    linked_change_request_id UUID REFERENCES change_requests(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE risk_review_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    assessment_id UUID NOT NULL REFERENCES risk_assessments(id),
    review_date DATE NOT NULL DEFAULT CURRENT_DATE,
    review_type VARCHAR(50) NOT NULL DEFAULT 'periodic',
    -- periodic | triggered | post_incident | post_change
    trigger_reason TEXT,
    reviewer_id UUID NOT NULL REFERENCES users(id),
    outcome VARCHAR(50) NOT NULL,
    -- no_change | risk_reduced | risk_increased | assessment_closed
    changes_made TEXT,
    next_review_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE risk_acceptance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    risk_item_id UUID NOT NULL REFERENCES risk_items(id),
    residual_risk_level VARCHAR(20) NOT NULL,   -- critical | high | medium | low
    acceptance_rationale TEXT NOT NULL,
    accepted_by UUID NOT NULL REFERENCES users(id),
    accepted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_by UUID REFERENCES users(id),      -- QA countersignature
    signature_id UUID REFERENCES electronic_signatures(id),
    expiry_date DATE,                           -- Acceptance may expire
    conditions TEXT                             -- Conditions under which risk is accepted
);

-- ============================================================
-- 20. PROCESS VALIDATION ENHANCEMENTS
-- Stage 3 monitoring plans, CPV data, APR structure.
-- ============================================================

CREATE TABLE process_monitoring_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    study_id UUID NOT NULL REFERENCES process_validation_studies(id),
    parameter_name VARCHAR(512) NOT NULL,
    parameter_type VARCHAR(50) NOT NULL,        -- cpp | cqa | kpi
    specification_text TEXT NOT NULL,
    monitoring_frequency VARCHAR(100) NOT NULL, -- every_batch | monthly | quarterly | annual
    sampling_method TEXT,
    analytical_method TEXT,
    control_chart_type VARCHAR(50),             -- xbar_r | individuals | cusum | ewma
    usl DECIMAL(20,8),                          -- Upper spec limit
    lsl DECIMAL(20,8),                          -- Lower spec limit
    ucl DECIMAL(20,8),                          -- Upper control limit
    lcl DECIMAL(20,8),                          -- Lower control limit
    action_trigger TEXT,                        -- What triggers an investigation
    responsible_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE cpv_data_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id UUID NOT NULL REFERENCES process_monitoring_plans(id),
    batch_id UUID REFERENCES batches(id),
    batch_number VARCHAR(100) NOT NULL,
    measurement_date DATE NOT NULL,
    value DECIMAL(20,8) NOT NULL,
    unit VARCHAR(50),
    within_spec BOOLEAN NOT NULL,
    within_control BOOLEAN,
    out_of_control_rule_violated VARCHAR(100),  -- Which control rule was violated
    investigation_required BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_id UUID REFERENCES deviations(id),
    measured_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE annual_product_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apr_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id),
    product_name VARCHAR(512) NOT NULL,
    product_code VARCHAR(100),
    review_year INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress',
    batches_manufactured INT,
    batches_rejected INT,
    cpv_summary TEXT,
    oos_summary TEXT,
    deviation_summary TEXT,
    capa_summary TEXT,
    change_summary TEXT,
    stability_summary TEXT,
    conclusion TEXT,
    recommendations TEXT,
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 21. SYSTEM HEALTH & OPERATIONS
-- Health monitoring, backup records, upgrade history,
-- performance metrics for the OpenVAL platform itself.
-- ============================================================

CREATE TABLE system_health_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    check_type VARCHAR(100) NOT NULL,
    -- audit_chain_integrity | database_connection | redis_connection | celery_workers
    -- file_storage | backup_age | disk_space | license_expiry | api_health
    status VARCHAR(50) NOT NULL,                -- healthy | degraded | critical | unknown
    message TEXT,
    details TEXT,                               -- JSON: additional diagnostic data
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE backup_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    backup_type VARCHAR(50) NOT NULL DEFAULT 'full',
    -- full | incremental | transaction_log | media_only
    status VARCHAR(50) NOT NULL,
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    file_path TEXT,
    file_size_bytes BIGINT,
    checksum_sha256 VARCHAR(64),
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    verified_at TIMESTAMPTZ,
    triggered_by VARCHAR(100) NOT NULL DEFAULT 'scheduled',
    -- scheduled | manual | pre_upgrade
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE upgrade_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_version VARCHAR(50) NOT NULL,
    to_version VARCHAR(50) NOT NULL,
    upgrade_type VARCHAR(50) NOT NULL DEFAULT 'patch',
    -- patch | minor | major
    validation_impact VARCHAR(50) NOT NULL,     -- none | minor | major
    started_at TIMESTAMPTZ NOT NULL,
    completed_at TIMESTAMPTZ,
    performed_by UUID REFERENCES users(id),
    backup_id UUID REFERENCES backup_history(id),
    migration_scripts_run TEXT,                 -- JSON: list of scripts
    success BOOLEAN NOT NULL DEFAULT TRUE,
    rollback_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 22. USER ONBOARDING & ANNOUNCEMENTS
-- First-run experience, help popups, system-wide announcements.
-- ============================================================

CREATE TABLE onboarding_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_code VARCHAR(100) NOT NULL,            -- Which role this checklist is for
    name VARCHAR(255) NOT NULL,
    description TEXT,
    estimated_minutes INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE onboarding_checklist_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    checklist_id UUID NOT NULL REFERENCES onboarding_checklists(id),
    title VARCHAR(512) NOT NULL,
    description TEXT,
    action_type VARCHAR(50) NOT NULL,           -- navigate | watch | read | complete | tour
    action_target TEXT,                         -- URL path or feature code
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE user_onboarding_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    checklist_id UUID NOT NULL REFERENCES onboarding_checklists(id),
    completed_item_ids TEXT NOT NULL DEFAULT '[]', -- JSON: [item_id, ...]
    is_complete BOOLEAN NOT NULL DEFAULT FALSE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,                   -- User dismissed without completing
    UNIQUE (user_id, checklist_id)
);

CREATE TABLE system_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),          -- NULL = all sites
    title VARCHAR(512) NOT NULL,
    body TEXT NOT NULL,
    announcement_type VARCHAR(50) NOT NULL DEFAULT 'info',
    -- info | warning | critical | maintenance | feature | upgrade
    priority INT NOT NULL DEFAULT 5,            -- 1-10, 10 = highest
    display_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    display_until TIMESTAMPTZ,
    show_as_banner BOOLEAN NOT NULL DEFAULT FALSE,
    show_as_modal BOOLEAN NOT NULL DEFAULT FALSE,
    requires_acknowledgment BOOLEAN NOT NULL DEFAULT FALSE,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE announcement_acknowledgments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_id UUID NOT NULL REFERENCES system_announcements(id),
    user_id UUID NOT NULL REFERENCES users(id),
    acknowledged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (announcement_id, user_id)
);

-- ============================================================
-- 23. REFERENCE DATA LIBRARY
-- Standard lookups that all modules draw from.
-- ============================================================

CREATE TABLE reference_organisms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organism_name VARCHAR(512) NOT NULL UNIQUE,
    gram_stain VARCHAR(20),                     -- positive | negative | variable
    organism_type VARCHAR(100),                 -- bacteria | yeast | mold | endospore
    usm_challenge_organism BOOLEAN NOT NULL DEFAULT FALSE,
    bi_organism BOOLEAN NOT NULL DEFAULT FALSE, -- Used as biological indicator
    typical_d_value DECIMAL(10,4),
    typical_z_value DECIMAL(10,4),
    notes TEXT
);

CREATE TABLE reference_chemicals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chemical_name VARCHAR(512) NOT NULL,
    cas_number VARCHAR(50),
    chemical_formula VARCHAR(255),
    molecular_weight DECIMAL(15,4),
    ld50_rat_oral DECIMAL(20,8),
    ld50_unit VARCHAR(50) DEFAULT 'mg/kg',
    ade_value DECIMAL(20,8),
    ade_unit VARCHAR(50) DEFAULT 'mg/day',
    pde_value DECIMAL(20,8),
    pde_unit VARCHAR(50),
    therapeutic_daily_dose DECIMAL(20,8),
    solubility_water VARCHAR(100),
    regulatory_category VARCHAR(100),           -- API | excipient | cleaning_agent | solvent
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE regulatory_frameworks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    framework_code VARCHAR(50) UNIQUE NOT NULL, -- 21_cfr_211 | eu_gmp_annex11 | gamp_5 | ich_q9
    name VARCHAR(512) NOT NULL,
    full_name VARCHAR(1024),
    issuing_body VARCHAR(255),                  -- FDA | EMA | ISPE | ICH
    current_version VARCHAR(100),
    effective_date DATE,
    document_url VARCHAR(2048),
    applicable_to TEXT,                         -- JSON: ["drug", "device", "biologics"]
    notes TEXT
);

CREATE TABLE country_regulatory_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    country_code VARCHAR(3) NOT NULL,
    country_name VARCHAR(255) NOT NULL,
    primary_agency_id UUID REFERENCES regulatory_agencies(id),
    applicable_framework_ids TEXT,              -- JSON: [framework_id, ...]
    electronic_records_regulation VARCHAR(512),
    electronic_signature_regulation VARCHAR(512),
    notes TEXT
);

-- ============================================================
-- 24. PROJECT TEMPLATES
-- Validation project templates. Select a template and get a
-- pre-populated project scaffold with phases, milestones,
-- and deliverables.
-- ============================================================

CREATE TABLE project_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(512) NOT NULL,
    description TEXT,
    project_type VARCHAR(100) NOT NULL,
    -- csv_full | csv_fast_track | csa | equipment_qual | method_val | cleaning_val
    estimated_weeks INT,
    is_system_template BOOLEAN NOT NULL DEFAULT TRUE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE project_template_phases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES project_templates(id),
    phase_name VARCHAR(255) NOT NULL,
    phase_code VARCHAR(50) NOT NULL,
    description TEXT,
    estimated_weeks INT,
    depends_on_phase_code VARCHAR(50),          -- Previous phase that must complete first
    sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE project_template_deliverables (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phase_id UUID NOT NULL REFERENCES project_template_phases(id),
    deliverable_name VARCHAR(512) NOT NULL,
    deliverable_type VARCHAR(100) NOT NULL,
    -- document | protocol | execution | sign_off | report | training
    linked_doc_template_code VARCHAR(100),      -- Creates from this template
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    responsible_role VARCHAR(100),
    sort_order INT NOT NULL DEFAULT 0
);

-- ============================================================
-- 25. ACCESS REQUESTS
-- Formal access request workflow. Users request access.
-- Managers approve. Audit-logged per 21 CFR 11.10(d).
-- ============================================================

CREATE TABLE access_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    request_ref VARCHAR(50) UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    requested_role_id UUID REFERENCES roles(id),
    requested_workspace_id UUID REFERENCES workspaces(id),
    justification TEXT NOT NULL,
    business_need TEXT NOT NULL,
    manager_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending | approved | rejected | expired
    decision_by UUID REFERENCES users(id),
    decision_at TIMESTAMPTZ,
    decision_reason TEXT,
    access_expires_at DATE,                     -- Time-limited access
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 26. LICENSE USAGE & BILLING SNAPSHOTS
-- Monthly snapshots of license usage for compliance and
-- potential billing purposes.
-- ============================================================

CREATE TABLE license_usage_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    snapshot_month DATE NOT NULL,               -- First day of the month
    site_id UUID REFERENCES sites(id),
    active_users INT NOT NULL DEFAULT 0,
    total_users INT NOT NULL DEFAULT 0,
    protocols_created INT NOT NULL DEFAULT 0,
    executions_completed INT NOT NULL DEFAULT 0,
    documents_created INT NOT NULL DEFAULT 0,
    storage_gb DECIMAL(10,4) NOT NULL DEFAULT 0,
    ai_tokens_used INT NOT NULL DEFAULT 0,
    edition VARCHAR(20) NOT NULL DEFAULT 'ce', -- ce | ee
    licensed_user_limit INT,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (snapshot_month, site_id)
);

-- ============================================================
-- INDEXES FOR ALL PART 9 TABLES
-- ============================================================

CREATE INDEX idx_workspaces_site ON workspaces (site_id, status);
CREATE INDEX idx_workspaces_org ON workspaces (organization_id);
CREATE INDEX idx_workspace_members_workspace ON workspace_members (workspace_id, user_id);
CREATE INDEX idx_workspace_members_user ON workspace_members (user_id);
CREATE INDEX idx_portfolios_workspace ON portfolios (workspace_id);
CREATE INDEX idx_portfolio_systems ON portfolio_systems (portfolio_id, system_id);

CREATE INDEX idx_teams_site ON teams (site_id, status);
CREATE INDEX idx_team_members_team ON team_members (team_id, is_active);
CREATE INDEX idx_team_members_user ON team_members (user_id, is_active);
CREATE INDEX idx_user_unavailability ON user_unavailability (user_id, start_date, end_date);

CREATE INDEX idx_cal_events_site ON validation_calendar_events (site_id, start_datetime);
CREATE INDEX idx_cal_events_workspace ON validation_calendar_events (workspace_id);
CREATE INDEX idx_resource_bookings ON resource_bookings (resource_id, booking_start, booking_end);

CREATE INDEX idx_training_courses_site ON training_courses (site_id, status);
CREATE INDEX idx_training_attempts ON training_assessment_attempts (user_id, assessment_id);
CREATE INDEX idx_competency_records ON personnel_competency_records (user_id, status);
CREATE INDEX idx_gxp_qualifications ON gxp_qualification_records (user_id, site_id, status);

CREATE INDEX idx_equipment_types ON equipment_types (parent_type_id);
CREATE INDEX idx_equipment_groups ON equipment_groups (site_id);
CREATE INDEX idx_calibration_points ON calibration_points (calibration_record_id);
CREATE INDEX idx_maintenance_work_orders ON maintenance_work_orders (equipment_id, status);
CREATE INDEX idx_equipment_location_history ON equipment_location_history (equipment_id);

CREATE INDEX idx_ebr_master_site ON ebr_master_records (site_id, status);
CREATE INDEX idx_ebr_instances ON ebr_batch_instances (master_id, status);
CREATE INDEX idx_ebr_material_additions ON ebr_material_additions (instance_id);
CREATE INDEX idx_ebr_ipc ON ebr_in_process_controls (instance_id);

CREATE INDEX idx_reg_submissions_site ON regulatory_submissions (site_id, status);
CREATE INDEX idx_reg_commitments ON regulatory_commitments (site_id, status, due_date);
CREATE INDEX idx_reg_queries ON regulatory_queries (site_id, status);

CREATE INDEX idx_integration_configs ON integration_configurations (integration_code, is_enabled);
CREATE INDEX idx_integration_event_log ON integration_event_log (integration_id, created_at DESC);
CREATE INDEX idx_external_id_mappings ON external_id_mappings (integration_id, openval_object_type, openval_object_id);
CREATE INDEX idx_api_keys ON api_keys (key_hash, is_active);
CREATE INDEX idx_webhook_subscriptions ON webhook_subscriptions (site_id, is_active);

CREATE INDEX idx_dashboard_definitions ON dashboard_definitions (site_id, dashboard_type);
CREATE INDEX idx_dashboard_widget_instances ON dashboard_widget_instances (dashboard_id);
CREATE INDEX idx_user_dashboards ON user_dashboards (user_id, site_id);

CREATE INDEX idx_quality_metric_snapshots ON quality_metric_snapshots (metric_id, site_id, snapshot_at DESC);
CREATE INDEX idx_quality_trend_alerts ON quality_trend_alerts (site_id, acknowledged_at);

CREATE INDEX idx_ai_usage_logs ON ai_usage_logs (model_id, created_at DESC);

CREATE INDEX idx_inspection_findings ON inspection_findings (inspection_id, status);
CREATE INDEX idx_warning_letter_items ON warning_letter_items (site_id, status);

CREATE INDEX idx_sig_delegation ON signature_delegation_agreements (delegator_id, delegate_id, status);

CREATE INDEX idx_audit_schedules ON audit_schedules (site_id, planned_date);
CREATE INDEX idx_audit_checklist_items ON audit_checklist_items (checklist_id, sort_order);

CREATE INDEX idx_retention_policies ON retention_policies (record_type);
CREATE INDEX idx_legal_holds ON legal_holds (site_id, status);

CREATE INDEX idx_template_step_library ON template_step_library (category, is_active);
CREATE INDEX idx_boilerplate_library ON template_boilerplate_library (category);
CREATE INDEX idx_acceptance_criteria_library ON template_acceptance_criteria_library (category);

CREATE INDEX idx_document_numbering ON document_numbering_configs (site_id, doc_type);

CREATE INDEX idx_distribution_groups ON distribution_groups (site_id, is_active);
CREATE INDEX idx_distribution_group_members ON distribution_group_members (group_id);

CREATE INDEX idx_risk_controls ON risk_controls (risk_item_id);
CREATE INDEX idx_risk_review_events ON risk_review_events (assessment_id);
CREATE INDEX idx_risk_acceptance ON risk_acceptance_records (risk_item_id);

CREATE INDEX idx_monitoring_plans ON process_monitoring_plans (study_id);
CREATE INDEX idx_cpv_data_points ON cpv_data_points (plan_id, measurement_date DESC);
CREATE INDEX idx_annual_product_reviews ON annual_product_reviews (site_id, review_year, product_code);

CREATE INDEX idx_system_health_checks ON system_health_checks (check_type, checked_at DESC);
CREATE INDEX idx_backup_history ON backup_history (started_at DESC, status);

CREATE INDEX idx_onboarding_progress ON user_onboarding_progress (user_id, is_complete);
CREATE INDEX idx_system_announcements ON system_announcements (site_id, display_from, display_until);

CREATE INDEX idx_access_requests ON access_requests (user_id, site_id, status);

CREATE INDEX idx_license_snapshots ON license_usage_snapshots (snapshot_month, site_id);

-- ============================================================
-- FINAL TABLE COUNT
-- ============================================================
-- Part 1: 130 | Part 3: 31 | Part 4: 4  | Part 5: 33
-- Part 6: 16  | Part 7: 37 | Part 8: 20 | Part 9: ~75
-- TOTAL: ~346 tables
