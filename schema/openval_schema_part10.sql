-- ============================================================
-- OpenVAL Schema - Part 10: Gap Fill from Astellas SLC SOP
-- Version: 1.0.0
-- Run after Parts 1-9
--
-- Tables identified as missing by analyzing Astellas GxP
-- System Life Cycle SOP:
--
--  1.  Regulatory Assessment & System Categorization (RASC)
--  2.  Business & Functional Risk Assessment (BFRA) enhancements
--  3.  System Maintenance Manuals (SMM)
--  4.  System Recovery Plans (SRP)
--  5.  System End of Life Plan and Report
--  6.  System Release Statements (SRS) for operational changes
--  7.  Vendor Release Assessments (SaaS periodic releases)
--  8.  Risk-Based Testing Decision Matrix
--  9.  Externally Hosted Security Assessments
-- 10.  Document Approval Matrix Configurations
-- 11.  User Story format requirements
-- 12.  Emergency change tracking enhancements
-- 13.  GxP roles seed additions
-- ============================================================

-- ============================================================
-- 1. REGULATORY ASSESSMENT AND SYSTEM CATEGORIZATION (RASC)
-- First deliverable for every new system implementation.
-- Drives ALL downstream validation decisions.
-- Astellas: STL-1905
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_rasc_ref START 1;

CREATE TABLE regulatory_system_categorizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rasc_ref VARCHAR(50) UNIQUE NOT NULL,        -- RASC-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- GxP Classification
    is_gxp BOOLEAN NOT NULL DEFAULT TRUE,
    gxp_justification TEXT NOT NULL,
    applicable_regulations TEXT NOT NULL,        -- JSON: ["21 CFR 211.68", "EU Annex 11"]
    applicable_guidelines TEXT,                  -- JSON: ["GAMP 5", "ICH Q10"]

    -- Risk Level
    overall_risk_level VARCHAR(20) NOT NULL DEFAULT 'medium', -- high | medium | low
    risk_justification TEXT NOT NULL,

    -- GAMP Classification
    gamp_category VARCHAR(10) NOT NULL,          -- 1 | 3 | 4 | 5
    gamp_justification TEXT NOT NULL,
    software_category VARCHAR(50) NOT NULL DEFAULT 'configured',
    -- ootb (out of the box) | configured | custom | hybrid

    -- Patient/Product Impact
    patient_safety_impact VARCHAR(20) NOT NULL DEFAULT 'indirect',
    -- direct | indirect | none
    product_quality_impact VARCHAR(20) NOT NULL DEFAULT 'indirect',
    data_integrity_impact VARCHAR(20) NOT NULL DEFAULT 'direct',
    direct_indirect_classification VARCHAR(20) NOT NULL DEFAULT 'indirect',
    -- direct | indirect (the key Astellas distinction)
    impact_justification TEXT NOT NULL,

    -- Compliance Requirements
    jsox_sox_required BOOLEAN NOT NULL DEFAULT FALSE,
    data_protection_assessment_required BOOLEAN NOT NULL DEFAULT FALSE,
    -- GDPR/CCPA — triggers privacy review
    data_protection_regulation TEXT,             -- Which regulation applies
    externally_hosted BOOLEAN NOT NULL DEFAULT FALSE,
    -- If true → EHSA required

    -- Data Retention
    data_retention_years INT,
    data_retention_regulation TEXT,
    records_management_review_required BOOLEAN NOT NULL DEFAULT FALSE,

    -- Outputs — drive downstream deliverables
    required_deliverables TEXT,                  -- JSON: list of required deliverable types
    validation_approach VARCHAR(50) NOT NULL DEFAULT 'csv',
    -- csv | csa | hybrid | no_validation_required
    minimum_testing_level VARCHAR(50),
    -- robust_scripted | limited_scripted | minimal_scripted | vendor_only
    qa_review_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.0,
    -- Percentage of test scripts QA must review (100% High, 50% Med, 25% Low)

    -- Change Impact
    previous_rasc_id UUID REFERENCES regulatory_system_categorizations(id),
    change_reason TEXT,                          -- Why RASC was updated

    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    next_review_date DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 2. SYSTEM MAINTENANCE MANUAL (SMM)
-- Permanent per-system technical operations document.
-- Covers backup/restore with RTO/RPO, access management,
-- ITSM procedures specific to this system.
-- Astellas: STL-728
-- ============================================================

CREATE TABLE system_maintenance_manuals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    smm_ref VARCHAR(50) UNIQUE NOT NULL,         -- SMM-0001
    system_id UUID NOT NULL REFERENCES systems(id) UNIQUE,
    site_id UUID NOT NULL REFERENCES sites(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- Backup and Restore
    backup_strategy_description TEXT NOT NULL,
    backup_frequency VARCHAR(100) NOT NULL,      -- daily | weekly | real_time | per_schedule
    backup_retention_policy TEXT NOT NULL,
    rto_hours DECIMAL(8,2) NOT NULL,             -- Recovery Time Objective
    rpo_hours DECIMAL(8,2) NOT NULL,             -- Recovery Point Objective
    backup_location TEXT NOT NULL,
    restore_procedure_reference TEXT,            -- Reference to full restore SOP

    -- Access and Security Management
    access_management_description TEXT NOT NULL,
    access_review_frequency VARCHAR(50) NOT NULL DEFAULT 'annual',
    privileged_access_procedure TEXT,
    password_policy_reference TEXT,

    -- IT Service Management
    incident_management_procedure TEXT,
    problem_management_procedure TEXT,
    change_management_procedure TEXT,            -- How changes to this system are managed
    patch_management_procedure TEXT NOT NULL,
    -- Especially critical for SaaS: how are vendor patches handled?
    configuration_management_procedure TEXT,

    -- System Administration
    admin_accounts TEXT,                         -- JSON: list of admin account types (not credentials)
    monitoring_tools TEXT,                       -- JSON: what monitoring is in place
    alert_procedures TEXT,                       -- What to do when alerts fire

    -- Approval
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

-- ============================================================
-- 3. SYSTEM RECOVERY PLANS (SRP)
-- Disaster recovery for each validated system.
-- Different from SMM: SMM = routine ops, SRP = disaster.
-- Must be tested periodically. RTO/RPO must match SMM.
-- Astellas: STL-1909
-- ============================================================

CREATE TABLE system_recovery_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    srp_ref VARCHAR(50) UNIQUE NOT NULL,         -- SRP-0001
    system_id UUID NOT NULL REFERENCES systems(id) UNIQUE,
    site_id UUID NOT NULL REFERENCES sites(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- Objectives
    primary_objective TEXT NOT NULL,
    rto_hours DECIMAL(8,2) NOT NULL,             -- Must match SMM
    rpo_hours DECIMAL(8,2) NOT NULL,             -- Must match SMM

    -- Recovery Procedures
    activation_criteria TEXT NOT NULL,           -- When is the plan invoked?
    activation_authority TEXT NOT NULL,          -- Who authorizes activation?
    recovery_team_roles TEXT NOT NULL,           -- JSON: roles + responsibilities
    recovery_procedures TEXT NOT NULL,           -- Step-by-step recovery steps
    communication_plan TEXT NOT NULL,            -- Who to notify, in what order
    vendor_contacts TEXT,                        -- JSON: key vendor support contacts

    -- Alternative Recovery
    alternative_processing TEXT,                 -- Manual workarounds during outage

    -- Testing
    test_frequency VARCHAR(50) NOT NULL DEFAULT 'annual',
    last_test_date DATE,
    last_test_result VARCHAR(50),
    last_test_notes TEXT,
    next_test_date DATE,

    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 4. SYSTEM END OF LIFE PLAN AND REPORT
-- Formal decommissioning documentation.
-- Astellas: STL-1893 (Plan) and STL-1894 (Report)
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_eol_ref START 1;

CREATE TABLE system_eol_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    eol_ref VARCHAR(50) UNIQUE NOT NULL,         -- EOL-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),

    -- Plan phase
    plan_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    plan_status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- Retirement details
    retirement_reason TEXT NOT NULL,
    target_retirement_date DATE NOT NULL,
    replacement_system_id UUID REFERENCES systems(id),

    -- Data handling
    data_retention_approach VARCHAR(50) NOT NULL,
    -- archive | migrate_to_new_system | transfer_to_external | delete_with_justification
    data_retention_justification TEXT NOT NULL,
    data_retention_location TEXT,
    data_retention_until DATE,
    data_migration_plan_id UUID,                 -- FK to data migration records

    -- Regulatory
    regulatory_notification_required BOOLEAN NOT NULL DEFAULT FALSE,
    regulatory_notification_agencies TEXT,       -- JSON: which agencies
    user_notification_plan TEXT,

    -- Approvals for plan
    plan_approved_by UUID REFERENCES users(id),
    plan_approved_at TIMESTAMPTZ,
    plan_signature_id UUID REFERENCES electronic_signatures(id),

    -- Report phase (after decommission)
    report_version VARCHAR(20),
    report_status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    actual_retirement_date DATE,
    decommission_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    archive_location_confirmed TEXT,
    data_migration_completed BOOLEAN,
    regulatory_notifications_sent BOOLEAN,
    all_users_notified BOOLEAN,
    report_conclusion TEXT,

    -- Final approval
    report_approved_by UUID REFERENCES users(id),
    report_approved_at TIMESTAMPTZ,
    report_signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 5. SYSTEM RELEASE STATEMENTS (SRS)
-- For operational changes (not full implementations).
-- Go-live authorization document. Replaces VSR for minor changes.
-- Astellas: STL-1910
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_srs_ref START 1;

CREATE TABLE system_release_statements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    srs_ref VARCHAR(50) UNIQUE NOT NULL,         -- SRS-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    change_request_id UUID REFERENCES change_requests(id),
    validation_project_id UUID REFERENCES validation_projects(id),

    -- Change summary
    change_description TEXT NOT NULL,
    change_category VARCHAR(50) NOT NULL DEFAULT 'operational_change',
    -- operational_change | saas_vendor_release | emergency_change | administrative

    -- Pre-go-live checklist
    testing_complete BOOLEAN NOT NULL DEFAULT FALSE,
    testing_summary TEXT,
    defects_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    open_defects_risk_accepted BOOLEAN NOT NULL DEFAULT FALSE,
    open_defects_description TEXT,
    documentation_updated BOOLEAN NOT NULL DEFAULT FALSE,
    training_complete BOOLEAN NOT NULL DEFAULT FALSE,
    training_confirmation TEXT,
    configuration_management_updated BOOLEAN NOT NULL DEFAULT FALSE,
    rollback_plan_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    rollback_procedure TEXT,

    -- Release
    target_release_date DATE NOT NULL,
    actual_release_date DATE,
    release_environment VARCHAR(50) NOT NULL DEFAULT 'production',

    -- Sign-off
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 6. VENDOR RELEASE ASSESSMENTS
-- SaaS/vendor periodic release management.
-- Every vendor update to a validated cloud system must be
-- assessed and documented. Common reality for SAP, Salesforce,
-- LIMS SaaS, etc.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_vra_ref START 1;

CREATE TABLE vendor_release_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vra_ref VARCHAR(50) UNIQUE NOT NULL,         -- VRA-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),

    -- Release details
    vendor_name VARCHAR(512) NOT NULL,
    release_version VARCHAR(100) NOT NULL,
    release_date DATE NOT NULL,
    release_type VARCHAR(50) NOT NULL DEFAULT 'patch',
    -- patch | minor | major | hotfix | security

    -- Impact assessment
    release_notes_reviewed BOOLEAN NOT NULL DEFAULT FALSE,
    release_notes_reviewed_by UUID REFERENCES users(id),
    release_notes_reviewed_at TIMESTAMPTZ,
    impact_level VARCHAR(20) NOT NULL DEFAULT 'none',
    -- none | low | medium | high
    impact_justification TEXT NOT NULL,
    affected_validated_functions TEXT,           -- JSON: which validated functions are impacted
    testing_required BOOLEAN NOT NULL DEFAULT FALSE,
    testing_scope TEXT,

    -- Decision
    decision VARCHAR(50) NOT NULL DEFAULT 'pending_assessment',
    -- accept_without_testing | accept_after_testing | defer | reject
    decision_justification TEXT,
    decision_by UUID REFERENCES users(id),
    decision_at TIMESTAMPTZ,

    -- Linked records
    srs_id UUID REFERENCES system_release_statements(id),
    operational_change_id UUID REFERENCES change_requests(id),

    -- Status
    status VARCHAR(50) NOT NULL DEFAULT 'in_assessment',
    implemented_date DATE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 7. RISK-BASED TESTING DECISION MATRIX
-- The Astellas Attachment 3 matrix: given impact level,
-- system risk, feature type, and requirement risk → determines
-- minimum testing approach required.
-- ============================================================

CREATE TABLE risk_based_testing_matrix (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),           -- NULL = global/system default
    -- Inputs
    direct_indirect VARCHAR(20) NOT NULL,        -- direct | indirect
    system_risk_level VARCHAR(20) NOT NULL,      -- high | medium | low
    feature_type VARCHAR(20) NOT NULL,           -- ootb | configured | custom | hybrid
    requirement_risk_level VARCHAR(20) NOT NULL, -- high | medium | low | any
    -- Output
    required_testing_approach VARCHAR(50) NOT NULL,
    -- robust_scripted | limited_scripted | minimal_scripted | vendor_only | no_testing
    description TEXT,                            -- Human-readable explanation
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed the complete Astellas Attachment 3 matrix
INSERT INTO risk_based_testing_matrix (direct_indirect, system_risk_level, feature_type, requirement_risk_level, required_testing_approach, description) VALUES
('direct', 'high', 'custom',     'high',   'robust_scripted',    'Step-by-step test cases, pre/post execution approval, screenshots'),
('direct', 'high', 'configured', 'high',   'robust_scripted',    'Step-by-step test cases, pre/post execution approval, screenshots'),
('direct', 'high', 'configured', 'medium', 'limited_scripted',   'Limited test cases, no step-by-step required, screenshots optional'),
('direct', 'high', 'ootb',       'low',    'minimal_scripted',   'High-level objectives only, or vendor assurance'),
('direct', 'medium','custom',    'high',   'robust_scripted',    'Full scripted testing required'),
('direct', 'medium','configured','medium', 'limited_scripted',   'Limited scripted testing'),
('direct', 'medium','configured','low',    'minimal_scripted',   'Minimal scripted or vendor assurance'),
('direct', 'medium','ootb',      'low',    'minimal_scripted',   'Minimal scripted or vendor assurance'),
('direct', 'low',  'custom',     'medium', 'limited_scripted',   'Limited scripted for custom development'),
('direct', 'low',  'configured', 'medium', 'robust_scripted',    'More robust due to custom configuration'),
('direct', 'low',  'configured', 'low',    'minimal_scripted',   'Minimal scripted or vendor assurance'),
('direct', 'low',  'ootb',       'low',    'vendor_only',        'Vendor documentation only, no additional testing'),
('indirect','high','configured', 'high',   'robust_scripted',    'Robust scripted despite indirect impact'),
('indirect','high','custom',     'medium', 'limited_scripted',   'Limited scripted'),
('indirect','high','configured', 'medium', 'limited_scripted',   'Limited scripted'),
('indirect','high','ootb',       'low',    'minimal_scripted',   'Minimal or vendor assurance'),
('indirect','medium','custom',   'medium', 'limited_scripted',   'Limited scripted testing'),
('indirect','medium','configured','low',   'minimal_scripted',   'Minimal or vendor assurance'),
('indirect','medium','ootb',     'low',    'vendor_only',        'Vendor assurance only'),
('indirect','low', 'custom',     'medium', 'limited_scripted',   'Limited scripted minimum'),
('indirect','low', 'configured', 'low',    'minimal_scripted',   'Minimal scripted or vendor assurance'),
('indirect','low', 'ootb',       'low',    'no_testing',         'Vendor assurance only — no additional testing required')
ON CONFLICT DO NOTHING;

-- Per-protocol testing decision record (which matrix row was selected and why)
CREATE TABLE protocol_testing_decisions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    rasc_id UUID REFERENCES regulatory_system_categorizations(id),
    matrix_id UUID REFERENCES risk_based_testing_matrix(id),
    -- Selected approach
    direct_indirect_used VARCHAR(20) NOT NULL,
    system_risk_used VARCHAR(20) NOT NULL,
    feature_type_used VARCHAR(20) NOT NULL,
    req_risk_used VARCHAR(20) NOT NULL,
    determined_approach VARCHAR(50) NOT NULL,
    approach_overridden BOOLEAN NOT NULL DEFAULT FALSE,
    override_justification TEXT,
    override_approved_by UUID REFERENCES users(id),
    determined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    determined_by UUID REFERENCES users(id)
);

-- ============================================================
-- 8. EXTERNALLY HOSTED SECURITY ASSESSMENTS (EHSA)
-- Required for any cloud or vendor-hosted GxP system.
-- Triggered automatically when RASC has externally_hosted=true.
-- Astellas: STL-4145 / SOP-2448
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_ehsa_ref START 1;

CREATE TABLE externally_hosted_security_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ehsa_ref VARCHAR(50) UNIQUE NOT NULL,        -- EHSA-0001
    system_id UUID NOT NULL REFERENCES systems(id),
    site_id UUID NOT NULL REFERENCES sites(id),
    rasc_id UUID REFERENCES regulatory_system_categorizations(id),
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',

    -- Hosting details
    vendor_name VARCHAR(512) NOT NULL,
    hosting_model VARCHAR(50) NOT NULL,          -- saas | paas | iaas | private_cloud | managed_hosting
    data_center_locations TEXT NOT NULL,         -- JSON: countries/regions
    data_sovereignty_acceptable BOOLEAN,
    data_sovereignty_notes TEXT,

    -- Data classification
    data_types_hosted TEXT NOT NULL,             -- JSON: what types of data
    pii_stored BOOLEAN NOT NULL DEFAULT FALSE,
    phi_stored BOOLEAN NOT NULL DEFAULT FALSE,
    gxp_data_stored BOOLEAN NOT NULL DEFAULT TRUE,

    -- Security controls
    encryption_at_rest BOOLEAN,
    encryption_in_transit BOOLEAN,
    access_management_review_performed BOOLEAN,
    privileged_access_controls TEXT,
    soc2_report_available BOOLEAN,
    iso27001_certified BOOLEAN,
    penetration_testing_results_reviewed BOOLEAN,
    vulnerability_management_process TEXT,

    -- Business continuity
    vendor_bcp_reviewed BOOLEAN,
    vendor_rto_hours DECIMAL(8,2),
    vendor_rpo_hours DECIMAL(8,2),
    vendor_sla_meets_requirements BOOLEAN,

    -- Privacy
    gdpr_applicable BOOLEAN NOT NULL DEFAULT FALSE,
    gdpr_dpa_signed BOOLEAN,                     -- Data Processing Agreement
    ccpa_applicable BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_assessment_outcome TEXT,

    -- Overall assessment
    assessment_result VARCHAR(50),               -- acceptable | conditional | not_acceptable
    conditions TEXT,                             -- If conditional, what conditions
    risk_acceptance_required BOOLEAN NOT NULL DEFAULT FALSE,
    overall_notes TEXT,

    -- Approval
    assessed_by UUID REFERENCES users(id),
    security_reviewer_id UUID REFERENCES users(id),
    privacy_reviewer_id UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    next_review_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 9. DOCUMENT APPROVAL MATRIX CONFIGURATIONS
-- Configurable per site: which roles must approve which
-- document types at which system risk levels.
-- Based on Astellas Attachment 1 Reviewer/Approver Matrix.
-- ============================================================

CREATE TABLE document_approval_matrix_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),           -- NULL = system default
    doc_type VARCHAR(100) NOT NULL,
    system_risk_level VARCHAR(20) NOT NULL,      -- high | medium | low | any
    -- Required approvers
    required_approver_roles TEXT NOT NULL,       -- JSON: [role_code, ...]
    optional_reviewer_roles TEXT,               -- JSON: [role_code, ...]
    qa_review_required BOOLEAN NOT NULL DEFAULT TRUE,
    qa_review_percentage DECIMAL(5,2) NOT NULL DEFAULT 100.0,
    bpo_approval_required BOOLEAN NOT NULL DEFAULT FALSE,
    system_owner_approval_required BOOLEAN NOT NULL DEFAULT TRUE,
    requires_independent_qa BOOLEAN NOT NULL DEFAULT TRUE,
    -- Notes
    notes TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (site_id, doc_type, system_risk_level)
);

-- Seed the default Astellas-aligned approval matrix
INSERT INTO document_approval_matrix_configs
    (doc_type, system_risk_level, required_approver_roles, qa_review_percentage, bpo_approval_required, system_owner_approval_required)
VALUES
('RASC',                      'any',    '["business_process_owner","system_owner","qa_manager"]',  100.0, true, true),
('Validation_Plan',           'high',   '["system_owner","qa_manager"]',                           100.0, false, true),
('Validation_Plan',           'medium', '["system_owner","qa_manager"]',                           100.0, false, true),
('Validation_Plan',           'low',    '["system_owner","qa_manager"]',                            25.0, false, true),
('Requirements',              'high',   '["business_process_owner","system_owner","qa_manager"]',  100.0, true, true),
('Requirements',              'medium', '["business_process_owner","system_owner"]',                50.0, true, true),
('Requirements',              'low',    '["business_process_owner"]',                               25.0, true, false),
('Test_Script',               'high',   '["system_owner","qa_manager"]',                           100.0, false, true),
('Test_Script',               'medium', '["system_owner","qa_manager"]',                            50.0, false, true),
('Test_Script',               'low',    '["system_owner"]',                                         25.0, false, true),
('Validation_Summary_Report', 'high',   '["business_process_owner","system_owner","qa_manager"]',  100.0, true, true),
('Validation_Summary_Report', 'medium', '["business_process_owner","system_owner","qa_manager"]',  100.0, true, true),
('Validation_Summary_Report', 'low',    '["business_process_owner","system_owner","qa_manager"]',   25.0, true, true),
('System_Maintenance_Manual', 'any',    '["business_process_owner","system_owner"]',               100.0, true, true),
('System_Recovery_Plan',      'any',    '["system_owner"]',                                        100.0, false, true),
('System_EOL_Plan',           'any',    '["business_process_owner","system_owner","qa_manager"]',  100.0, true, true),
('System_Release_Statement',  'any',    '["system_owner","qa_manager"]',                           100.0, false, true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- 10. USER STORY FORMAT REQUIREMENTS
-- Agile/Scrum format requirements alongside traditional URS.
-- Astellas uses "User Stories" (STL-4509) as their requirements.
-- ============================================================

CREATE TABLE user_story_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    story_ref VARCHAR(50) UNIQUE NOT NULL,       -- US-0001
    requirement_set_id UUID REFERENCES requirement_sets(id),
    system_id UUID NOT NULL REFERENCES systems(id),
    -- User Story fields
    as_a_role VARCHAR(512) NOT NULL,             -- "As a [lab analyst]"
    i_want TEXT NOT NULL,                        -- "I want to [enter sample results]"
    so_that TEXT NOT NULL,                       -- "So that [batch release can proceed]"
    -- Additional context
    background_context TEXT,
    acceptance_criteria TEXT NOT NULL,           -- Testable, specific criteria
    story_points INT,
    sprint VARCHAR(50),
    -- Priority and categorization
    priority VARCHAR(20) NOT NULL DEFAULT 'medium',
    story_type VARCHAR(50) NOT NULL DEFAULT 'functional',
    -- functional | non_functional | technical | security | performance | compliance
    gxp_critical BOOLEAN NOT NULL DEFAULT TRUE,
    regulatory_citation TEXT,
    -- Status and traceability
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    test_coverage_count INT NOT NULL DEFAULT 0,  -- How many tests validate this
    -- Approval
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- 11. CHANGE CATEGORY ENHANCEMENTS
-- Add change_category to validation_projects to distinguish
-- System Implementation / Upgrade / Operational Change / Emergency
-- ============================================================

ALTER TABLE validation_projects
    ADD COLUMN IF NOT EXISTS change_category VARCHAR(50) NOT NULL DEFAULT 'system_implementation',
    -- system_implementation | system_upgrade | operational_change | emergency_change | routine_maintenance
    ADD COLUMN IF NOT EXISTS is_emergency_change BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS emergency_justification TEXT,
    ADD COLUMN IF NOT EXISTS emergency_activation_time TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS retrospective_docs_due_date DATE,
    -- For emergency changes: documentation must be completed by this date
    ADD COLUMN IF NOT EXISTS rasc_id UUID REFERENCES regulatory_system_categorizations(id),
    ADD COLUMN IF NOT EXISTS srs_id UUID REFERENCES system_release_statements(id);

-- ============================================================
-- 12. INDEXES FOR PART 10
-- ============================================================

CREATE INDEX idx_rasc_system ON regulatory_system_categorizations (system_id, status);
CREATE INDEX idx_rasc_site ON regulatory_system_categorizations (site_id);
CREATE INDEX idx_smm_system ON system_maintenance_manuals (system_id);
CREATE INDEX idx_srp_system ON system_recovery_plans (system_id);
CREATE INDEX idx_eol_system ON system_eol_records (system_id, plan_status);
CREATE INDEX idx_srs_system ON system_release_statements (system_id, status);
CREATE INDEX idx_srs_change ON system_release_statements (change_request_id);
CREATE INDEX idx_vra_system ON vendor_release_assessments (system_id, status);
CREATE INDEX idx_vra_date ON vendor_release_assessments (release_date DESC);
CREATE INDEX idx_rbtm_matrix ON risk_based_testing_matrix (direct_indirect, system_risk_level, feature_type);
CREATE INDEX idx_protocol_testing_decisions ON protocol_testing_decisions (protocol_id);
CREATE INDEX idx_ehsa_system ON externally_hosted_security_assessments (system_id, status);
CREATE INDEX idx_approval_matrix ON document_approval_matrix_configs (doc_type, system_risk_level);
CREATE INDEX idx_user_stories ON user_story_requirements (requirement_set_id, status);
CREATE INDEX idx_user_stories_system ON user_story_requirements (system_id);

-- ============================================================
-- FINAL TABLE COUNT (PARTS 1-10)
-- Part 1:130 Part 3:31 Part 4:4 Part 5:33 Part 6:16
-- Part 7:37 Part 8:20 Part 9:91 Part 10:~15
-- GRAND TOTAL: ~377 tables
-- ============================================================
