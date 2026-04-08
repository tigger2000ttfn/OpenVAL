-- ============================================================
-- OpenVAL Complete Database Schema - Part 1: All Core Tables
-- PostgreSQL 15+  |  Version 1.0.0
-- ============================================================
-- This is the single authoritative DDL for OpenVAL.
-- Run Part 1 first, then Part 2 (indexes, sequences, seed data).
-- NEVER alter audit_log or electronic_signatures rows after insert.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- ============================================================
-- ORGANIZATIONS AND SITES
-- ============================================================

CREATE TABLE organizations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    legal_name VARCHAR(255),
    duns_number VARCHAR(20),
    fda_establishment_number VARCHAR(50),
    address_line1 VARCHAR(512), address_line2 VARCHAR(512),
    city VARCHAR(255), state VARCHAR(100), postal_code VARCHAR(20), country VARCHAR(100),
    phone VARCHAR(50), email VARCHAR(255), website VARCHAR(512),
    logo_path VARCHAR(512),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, updated_by UUID
);

CREATE TABLE sites (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organization_id UUID NOT NULL REFERENCES organizations(id),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(50) UNIQUE NOT NULL,
    site_type VARCHAR(100),
    address_line1 VARCHAR(512), address_line2 VARCHAR(512),
    city VARCHAR(255), state VARCHAR(100), postal_code VARCHAR(20), country VARCHAR(100),
    phone VARCHAR(50), email VARCHAR(255),
    fda_facility_number VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, updated_by UUID
);

CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    name VARCHAR(255) NOT NULL, code VARCHAR(50),
    department_type VARCHAR(100),
    manager_id UUID,
    parent_department_id UUID REFERENCES departments(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, updated_by UUID
);

CREATE TABLE cost_centers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    code VARCHAR(50) NOT NULL, name VARCHAR(255),
    department_id UUID REFERENCES departments(id),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, updated_by UUID
);

-- ============================================================
-- USERS AND AUTH
-- ============================================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    title VARCHAR(100),
    department_id UUID REFERENCES departments(id),
    site_id UUID REFERENCES sites(id),
    hashed_password VARCHAR(255) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    lock_reason TEXT, locked_at TIMESTAMPTZ, locked_by UUID,
    must_change_password BOOLEAN NOT NULL DEFAULT FALSE,
    last_login_at TIMESTAMPTZ, last_login_ip VARCHAR(45),
    failed_login_count INT NOT NULL DEFAULT 0,
    password_changed_at TIMESTAMPTZ,
    mfa_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    mfa_secret VARCHAR(255),
    mfa_backup_codes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID, updated_by UUID
);

ALTER TABLE departments ADD CONSTRAINT fk_dept_manager FOREIGN KEY (manager_id) REFERENCES users(id);
ALTER TABLE organizations ADD CONSTRAINT fk_org_cb FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE organizations ADD CONSTRAINT fk_org_ub FOREIGN KEY (updated_by) REFERENCES users(id);
ALTER TABLE sites ADD CONSTRAINT fk_site_cb FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE sites ADD CONSTRAINT fk_site_ub FOREIGN KEY (updated_by) REFERENCES users(id);
ALTER TABLE departments ADD CONSTRAINT fk_dept_cb FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE departments ADD CONSTRAINT fk_dept_ub FOREIGN KEY (updated_by) REFERENCES users(id);
ALTER TABLE cost_centers ADD CONSTRAINT fk_cc_cb FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE cost_centers ADD CONSTRAINT fk_cc_ub FOREIGN KEY (updated_by) REFERENCES users(id);
ALTER TABLE users ADD CONSTRAINT fk_users_locked_by FOREIGN KEY (locked_by) REFERENCES users(id);
ALTER TABLE users ADD CONSTRAINT fk_users_cb FOREIGN KEY (created_by) REFERENCES users(id);
ALTER TABLE users ADD CONSTRAINT fk_users_ub FOREIGN KEY (updated_by) REFERENCES users(id);

CREATE TABLE roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_system_role BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module VARCHAR(100) NOT NULL, action VARCHAR(100) NOT NULL, resource VARCHAR(100),
    display_name VARCHAR(255), description TEXT,
    UNIQUE (module, action, resource)
);

CREATE TABLE role_permissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    granted_by UUID REFERENCES users(id),
    UNIQUE (role_id, permission_id)
);

CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    site_id UUID REFERENCES sites(id),
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    assigned_by UUID REFERENCES users(id),
    expires_at TIMESTAMPTZ,
    UNIQUE (user_id, role_id, site_id)
);

CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token VARCHAR(512) UNIQUE NOT NULL,
    refresh_token VARCHAR(512) UNIQUE,
    ip_address VARCHAR(45), user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL,
    last_active_at TIMESTAMPTZ,
    revoked_at TIMESTAMPTZ, revoked_reason VARCHAR(255)
);

CREATE TABLE password_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    hashed_password VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE login_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username_attempted VARCHAR(255), ip_address VARCHAR(45), user_agent TEXT,
    success BOOLEAN NOT NULL, failure_reason VARCHAR(255),
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL, key_prefix VARCHAR(12) NOT NULL,
    hashed_key VARCHAR(255) NOT NULL UNIQUE,
    scopes TEXT, last_used_at TIMESTAMPTZ, expires_at TIMESTAMPTZ, revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE sso_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL, provider_type VARCHAR(50) NOT NULL,
    config TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE, is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE sso_user_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    provider_id UUID NOT NULL REFERENCES sso_providers(id),
    external_user_id VARCHAR(255) NOT NULL, external_email VARCHAR(255), last_synced_at TIMESTAMPTZ,
    UNIQUE (provider_id, external_user_id)
);

CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    timezone VARCHAR(100) NOT NULL DEFAULT 'UTC',
    date_format VARCHAR(50), items_per_page INT NOT NULL DEFAULT 25,
    sidebar_collapsed BOOLEAN NOT NULL DEFAULT FALSE, theme VARCHAR(50) NOT NULL DEFAULT 'light',
    notification_preferences TEXT, dashboard_layout TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- AUDIT TRAIL AND SIGNATURES (APPEND-ONLY TABLES)
-- ============================================================

CREATE TABLE signature_meanings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) UNIQUE NOT NULL, display_name VARCHAR(255) NOT NULL,
    description TEXT, regulatory_citation VARCHAR(255), applicable_modules TEXT,
    requires_mfa BOOLEAN NOT NULL DEFAULT FALSE, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE electronic_signatures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    signature_id VARCHAR(50) UNIQUE NOT NULL,
    table_name VARCHAR(100) NOT NULL, record_id UUID NOT NULL, record_version INT,
    signer_id UUID NOT NULL REFERENCES users(id),
    signer_username VARCHAR(100) NOT NULL, signer_full_name VARCHAR(255) NOT NULL, signer_title VARCHAR(100),
    meaning_id UUID REFERENCES signature_meanings(id),
    meaning_text VARCHAR(512) NOT NULL,
    signed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    auth_method VARCHAR(50) NOT NULL, ip_address VARCHAR(45),
    signature_hash VARCHAR(64) NOT NULL, manifested_data_hash VARCHAR(64),
    is_valid BOOLEAN NOT NULL DEFAULT TRUE,
    invalidated_at TIMESTAMPTZ, invalidated_by UUID REFERENCES users(id), invalidation_reason TEXT
);

CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id VARCHAR(50) UNIQUE NOT NULL,
    table_name VARCHAR(100) NOT NULL, record_id UUID NOT NULL, record_display VARCHAR(512),
    action VARCHAR(20) NOT NULL CHECK (action IN (
        'CREATE','UPDATE','DELETE','EXECUTE','APPROVE','REJECT',
        'SIGN','LOGIN','LOGOUT','EXPORT','PRINT','VIEW','ARCHIVE','RESTORE','LOCK','UNLOCK'
    )),
    field_name VARCHAR(100), old_value TEXT, new_value TEXT,
    old_value_hash VARCHAR(64), new_value_hash VARCHAR(64),
    user_id UUID NOT NULL REFERENCES users(id),
    user_name VARCHAR(100) NOT NULL, user_full_name VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45), user_agent TEXT,
    session_id UUID REFERENCES user_sessions(id),
    reason_code VARCHAR(100), reason_text TEXT,
    module VARCHAR(100), parent_table VARCHAR(100), parent_record_id UUID,
    cfr_citation VARCHAR(255),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE audit_log_integrity (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_log_id UUID UNIQUE NOT NULL REFERENCES audit_log(id),
    record_hash VARCHAR(64) NOT NULL,
    chain_hash VARCHAR(64) NOT NULL,
    verified_at TIMESTAMPTZ
);

CREATE TABLE signature_delegates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    delegator_id UUID NOT NULL REFERENCES users(id), delegate_id UUID NOT NULL REFERENCES users(id),
    meaning_ids TEXT, module VARCHAR(100),
    start_date DATE NOT NULL, end_date DATE NOT NULL,
    reason TEXT, approved_by UUID REFERENCES users(id), is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- LOOKUP AND REFERENCE DATA
-- ============================================================

CREATE TABLE lookup_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) UNIQUE NOT NULL, display_name VARCHAR(255) NOT NULL, description TEXT,
    is_system BOOLEAN NOT NULL DEFAULT FALSE, allow_custom_values BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE lookup_values (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    category_id UUID NOT NULL REFERENCES lookup_categories(id),
    code VARCHAR(100) NOT NULL, display_name VARCHAR(255) NOT NULL, description TEXT,
    sort_order INT NOT NULL DEFAULT 0, metadata TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE, is_system BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id),
    UNIQUE (category_id, code)
);

CREATE TABLE regulatory_references (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    framework VARCHAR(100) NOT NULL, citation VARCHAR(255) NOT NULL,
    title VARCHAR(512), summary TEXT, full_text_url VARCHAR(512), is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE feature_regulatory_mappings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_code VARCHAR(100) NOT NULL,
    regulatory_reference_id UUID NOT NULL REFERENCES regulatory_references(id),
    compliance_note TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), category VARCHAR(100) NOT NULL,
    name VARCHAR(100) NOT NULL, color VARCHAR(7), is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id),
    UNIQUE (site_id, category, name)
);

CREATE TABLE object_tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tag_id UUID NOT NULL REFERENCES tags(id),
    object_type VARCHAR(100) NOT NULL, object_id UUID NOT NULL,
    tagged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), tagged_by UUID REFERENCES users(id)
);

CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), title VARCHAR(512) NOT NULL, body TEXT NOT NULL,
    priority VARCHAR(20) NOT NULL DEFAULT 'info' CHECK (priority IN ('info','warning','critical')),
    start_at TIMESTAMPTZ, end_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE announcement_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    announcement_id UUID NOT NULL REFERENCES announcements(id),
    user_id UUID NOT NULL REFERENCES users(id),
    read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (announcement_id, user_id)
);

CREATE TABLE countries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    iso_code VARCHAR(3) UNIQUE NOT NULL, name VARCHAR(255) NOT NULL, is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- ============================================================
-- FILE MANAGEMENT
-- ============================================================

CREATE TABLE file_store (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_ref VARCHAR(50) UNIQUE NOT NULL,
    original_filename VARCHAR(512) NOT NULL, stored_filename VARCHAR(512) NOT NULL,
    storage_path VARCHAR(1024) NOT NULL, file_size_bytes BIGINT,
    mime_type VARCHAR(255), extension VARCHAR(20),
    sha256_hash VARCHAR(64) NOT NULL,
    is_virus_scanned BOOLEAN NOT NULL DEFAULT FALSE,
    virus_scan_result VARCHAR(50), virus_scanned_at TIMESTAMPTZ,
    is_encrypted BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_by UUID NOT NULL REFERENCES users(id),
    site_id UUID REFERENCES sites(id),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE file_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES file_store(id),
    object_type VARCHAR(100) NOT NULL, object_id UUID NOT NULL,
    attachment_type VARCHAR(100), display_name VARCHAR(512), description TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    attached_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), attached_by UUID REFERENCES users(id)
);

CREATE TABLE file_access_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    file_id UUID NOT NULL REFERENCES file_store(id), user_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(50) NOT NULL CHECK (action IN ('view','download','print','delete')),
    ip_address VARCHAR(45), accessed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- VENDORS (needed before systems)
-- ============================================================

CREATE TABLE vendors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_ref VARCHAR(50) UNIQUE NOT NULL, name VARCHAR(512) NOT NULL, legal_name VARCHAR(512),
    vendor_type VARCHAR(100), website VARCHAR(512),
    address_line1 VARCHAR(512), address_line2 VARCHAR(512),
    city VARCHAR(255), state VARCHAR(100), postal_code VARCHAR(20), country VARCHAR(100),
    primary_contact_name VARCHAR(255), primary_contact_email VARCHAR(255), primary_contact_phone VARCHAR(50),
    qualification_status VARCHAR(50) NOT NULL DEFAULT 'not_qualified',
    qualification_date DATE, requalification_date DATE,
    risk_level VARCHAR(50), is_gxp_critical BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SYSTEM AND EQUIPMENT INVENTORY
-- ============================================================

CREATE TABLE systems (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID NOT NULL REFERENCES sites(id),
    name VARCHAR(512) NOT NULL, description TEXT,
    system_type VARCHAR(100) NOT NULL DEFAULT 'software',
    gamp_category VARCHAR(10), gamp_category_justification TEXT,
    gxp_relevant BOOLEAN NOT NULL, gxp_impact_areas TEXT, gxp_justification TEXT,
    applicable_regulations TEXT,
    classification_status VARCHAR(50) NOT NULL DEFAULT 'draft',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    validated_status VARCHAR(50) NOT NULL DEFAULT 'not_validated',
    validation_basis VARCHAR(100), version VARCHAR(100),
    vendor_id UUID REFERENCES vendors(id),
    vendor_product_name VARCHAR(255), vendor_product_version VARCHAR(100),
    license_type VARCHAR(100), license_expiry_date DATE,
    location VARCHAR(512), hosting_type VARCHAR(100), environment VARCHAR(50),
    business_owner_id UUID REFERENCES users(id),
    technical_owner_id UUID REFERENCES users(id),
    qa_owner_id UUID REFERENCES users(id),
    installation_date DATE, go_live_date DATE, retirement_date DATE,
    revalidation_required BOOLEAN NOT NULL DEFAULT FALSE,
    revalidation_due_date DATE, revalidation_trigger VARCHAR(255),
    periodic_review_interval_months INT NOT NULL DEFAULT 12,
    next_periodic_review_date DATE,
    criticality VARCHAR(50),
    backup_frequency VARCHAR(100), disaster_recovery_rto VARCHAR(100), disaster_recovery_rpo VARCHAR(100),
    data_classification VARCHAR(100), notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE system_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES systems(id),
    version_number VARCHAR(100) NOT NULL, version_date DATE, change_summary TEXT,
    validation_impact VARCHAR(50), revalidation_required BOOLEAN NOT NULL DEFAULT FALSE,
    release_notes TEXT, retired_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE system_components (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES systems(id),
    name VARCHAR(255) NOT NULL, component_type VARCHAR(100), version VARCHAR(100),
    vendor VARCHAR(255), gxp_relevant BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE system_interfaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    source_system_id UUID NOT NULL REFERENCES systems(id),
    target_system_id UUID NOT NULL REFERENCES systems(id),
    interface_name VARCHAR(255), interface_type VARCHAR(100),
    direction VARCHAR(20) CHECK (direction IN ('inbound','outbound','bidirectional')),
    data_types TEXT, gxp_relevant BOOLEAN NOT NULL DEFAULT FALSE,
    validated BOOLEAN NOT NULL DEFAULT FALSE, description TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE system_environments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES systems(id),
    environment_name VARCHAR(50) NOT NULL,
    server_hostname VARCHAR(255), server_ip VARCHAR(45), url VARCHAR(512),
    os_version VARCHAR(100), database_version VARCHAR(100), application_version VARCHAR(100),
    is_validated BOOLEAN NOT NULL DEFAULT FALSE, notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE system_data_flows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    system_id UUID NOT NULL REFERENCES systems(id),
    data_type VARCHAR(255) NOT NULL, source VARCHAR(255), destination VARCHAR(255),
    contains_gxp_data BOOLEAN NOT NULL DEFAULT FALSE, contains_pii BOOLEAN NOT NULL DEFAULT FALSE,
    encryption_in_transit BOOLEAN NOT NULL DEFAULT FALSE, encryption_at_rest BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE equipment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_ref VARCHAR(50) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id), department_id UUID REFERENCES departments(id),
    name VARCHAR(512) NOT NULL, description TEXT, equipment_type VARCHAR(100),
    manufacturer VARCHAR(255), manufacturer_model VARCHAR(255),
    serial_number VARCHAR(255), asset_number VARCHAR(255),
    gxp_relevant BOOLEAN NOT NULL DEFAULT FALSE, gamp_category VARCHAR(10),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    validated_status VARCHAR(50) NOT NULL DEFAULT 'not_validated',
    location VARCHAR(512), installation_date DATE,
    owner_id UUID REFERENCES users(id), vendor_id UUID REFERENCES vendors(id),
    calibration_required BOOLEAN NOT NULL DEFAULT FALSE,
    calibration_interval_days INT, last_calibration_date DATE, next_calibration_date DATE,
    maintenance_interval_days INT, last_maintenance_date DATE, next_maintenance_date DATE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE equipment_calibration_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    calibration_ref VARCHAR(50) UNIQUE NOT NULL,
    performed_by UUID REFERENCES users(id), performed_date DATE NOT NULL, due_date DATE,
    result VARCHAR(50), certificate_number VARCHAR(255), calibrating_lab VARCHAR(255),
    standard_used VARCHAR(255), tolerance_as_found VARCHAR(255), tolerance_as_left VARCHAR(255),
    deviation_noted BOOLEAN NOT NULL DEFAULT FALSE, deviation_description TEXT, notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE equipment_maintenance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    equipment_id UUID NOT NULL REFERENCES equipment(id),
    maintenance_ref VARCHAR(50) UNIQUE NOT NULL, maintenance_type VARCHAR(100),
    performed_by UUID REFERENCES users(id), performed_date DATE NOT NULL, description TEXT,
    parts_replaced TEXT, revalidation_required BOOLEAN NOT NULL DEFAULT FALSE,
    validation_impact_notes TEXT, completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- RISK ASSESSMENT
-- ============================================================

CREATE TABLE risk_matrices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), name VARCHAR(255) NOT NULL, description TEXT,
    matrix_type VARCHAR(50) NOT NULL DEFAULT 'probability_impact',
    probability_scale INT NOT NULL DEFAULT 5, impact_scale INT NOT NULL DEFAULT 5, detectability_scale INT DEFAULT 5,
    risk_thresholds TEXT, is_default BOOLEAN NOT NULL DEFAULT FALSE, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE risk_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_ref VARCHAR(50) UNIQUE NOT NULL,
    system_id UUID REFERENCES systems(id), equipment_id UUID REFERENCES equipment(id),
    assessment_type VARCHAR(100) NOT NULL, title VARCHAR(512) NOT NULL, scope TEXT,
    methodology VARCHAR(100), matrix_id UUID REFERENCES risk_matrices(id),
    version INT NOT NULL DEFAULT 1, status VARCHAR(50) NOT NULL DEFAULT 'draft',
    assessment_date DATE, review_date DATE, next_review_date DATE,
    overall_risk_level VARCHAR(50), overall_residual_risk_level VARCHAR(50),
    conclusion TEXT, approved_at TIMESTAMPTZ, approved_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE risk_assessment_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES risk_assessments(id),
    version_number INT NOT NULL, change_summary TEXT, snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id),
    UNIQUE (assessment_id, version_number)
);

CREATE TABLE risk_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), name VARCHAR(255) NOT NULL, description TEXT,
    sort_order INT NOT NULL DEFAULT 0, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE risk_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    assessment_id UUID NOT NULL REFERENCES risk_assessments(id),
    item_number VARCHAR(20) NOT NULL, category VARCHAR(100),
    hazard TEXT NOT NULL, potential_effect TEXT NOT NULL, existing_controls TEXT,
    probability_score INT NOT NULL, probability_rationale TEXT,
    impact_score INT NOT NULL, impact_rationale TEXT,
    detectability_score INT, detectability_rationale TEXT,
    inherent_risk_score INT, inherent_risk_level VARCHAR(50), rpn INT,
    mitigation_required BOOLEAN NOT NULL DEFAULT FALSE, mitigation_actions TEXT,
    residual_probability_score INT, residual_impact_score INT, residual_detectability_score INT,
    residual_risk_score INT, residual_rpn INT, residual_risk_level VARCHAR(50),
    risk_accepted BOOLEAN NOT NULL DEFAULT FALSE, acceptance_rationale TEXT,
    owner_id UUID REFERENCES users(id), target_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'open', sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- REQUIREMENTS
-- ============================================================

CREATE TABLE requirement_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_ref VARCHAR(50) UNIQUE NOT NULL, system_id UUID NOT NULL REFERENCES systems(id),
    set_type VARCHAR(20) NOT NULL CHECK (set_type IN ('URS','FS','DS','CS','SRS')),
    title VARCHAR(512) NOT NULL, version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    scope TEXT, purpose TEXT, references TEXT,
    approved_at TIMESTAMPTZ, effective_date DATE, expiry_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE requirement_set_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    set_id UUID NOT NULL REFERENCES requirement_sets(id),
    version_number VARCHAR(20) NOT NULL, change_summary TEXT, snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id)
);

CREATE TABLE requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    req_ref VARCHAR(50) UNIQUE NOT NULL, set_id UUID NOT NULL REFERENCES requirement_sets(id),
    parent_req_id UUID REFERENCES requirements(id),
    req_number VARCHAR(50) NOT NULL, section VARCHAR(255),
    title VARCHAR(512) NOT NULL, description TEXT NOT NULL, rationale TEXT,
    req_type VARCHAR(50), priority VARCHAR(20) DEFAULT 'mandatory', testability VARCHAR(20) DEFAULT 'testable',
    regulatory_citation VARCHAR(512), gxp_critical BOOLEAN NOT NULL DEFAULT FALSE,
    alcoa_attribute VARCHAR(50), status VARCHAR(50) NOT NULL DEFAULT 'draft',
    acceptance_criteria TEXT, notes TEXT, sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE requirement_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_req_id UUID NOT NULL REFERENCES requirements(id),
    child_req_id UUID NOT NULL REFERENCES requirements(id),
    link_type VARCHAR(50) NOT NULL DEFAULT 'derives_from',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id),
    UNIQUE (parent_req_id, child_req_id, link_type)
);

-- ============================================================
-- PROTOCOLS AND TEST EXECUTION
-- ============================================================

CREATE TABLE protocol_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_ref VARCHAR(50) UNIQUE NOT NULL, name VARCHAR(512) NOT NULL, description TEXT,
    protocol_type VARCHAR(20) NOT NULL, category VARCHAR(100), industry VARCHAR(100), regulatory_scope TEXT,
    is_system_template BOOLEAN NOT NULL DEFAULT FALSE, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    version VARCHAR(20) NOT NULL DEFAULT '1.0', sections TEXT, steps TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE protocols (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_ref VARCHAR(50) UNIQUE NOT NULL,
    system_id UUID REFERENCES systems(id), equipment_id UUID REFERENCES equipment(id),
    protocol_type VARCHAR(20) NOT NULL CHECK (protocol_type IN ('IQ','OQ','PQ','UAT','MAV','CSV','DQ','SAT','FAT','RETRO')),
    title VARCHAR(512) NOT NULL, version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    objective TEXT, scope TEXT, prerequisites TEXT,
    hardware_requirements TEXT, software_requirements TEXT, personnel_requirements TEXT,
    references TEXT, acceptance_criteria TEXT,
    template_id UUID REFERENCES protocol_templates(id),
    environment_id UUID REFERENCES system_environments(id),
    approved_at TIMESTAMPTZ, approved_by UUID REFERENCES users(id),
    execution_start_at TIMESTAMPTZ, execution_end_at TIMESTAMPTZ,
    executed_by UUID REFERENCES users(id),
    overall_result VARCHAR(20), conclusion TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE protocol_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    version_number VARCHAR(20) NOT NULL, change_summary TEXT, change_type VARCHAR(50), snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id),
    UNIQUE (protocol_id, version_number)
);

CREATE TABLE protocol_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    section_number VARCHAR(20) NOT NULL, title VARCHAR(512) NOT NULL,
    description TEXT, section_type VARCHAR(50), sort_order INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE protocol_steps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    step_ref VARCHAR(50) NOT NULL,
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    section_id UUID NOT NULL REFERENCES protocol_sections(id),
    step_number VARCHAR(20) NOT NULL, title VARCHAR(512) NOT NULL,
    description TEXT NOT NULL, expected_result TEXT NOT NULL,
    step_type VARCHAR(50) NOT NULL DEFAULT 'action',
    input_type VARCHAR(50) NOT NULL DEFAULT 'pass_fail', input_options TEXT,
    is_mandatory BOOLEAN NOT NULL DEFAULT TRUE,
    requires_signature BOOLEAN NOT NULL DEFAULT FALSE,
    signature_meaning_id UUID REFERENCES signature_meanings(id),
    requires_screenshot BOOLEAN NOT NULL DEFAULT FALSE,
    requires_attachment BOOLEAN NOT NULL DEFAULT FALSE,
    linked_requirement_ids TEXT, regulatory_citation VARCHAR(512),
    alcoa_applicable BOOLEAN NOT NULL DEFAULT TRUE, sort_order INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE test_scripts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    script_ref VARCHAR(50) UNIQUE NOT NULL,
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    step_id UUID REFERENCES protocol_steps(id),
    title VARCHAR(512) NOT NULL, description TEXT,
    script_type VARCHAR(50) NOT NULL DEFAULT 'manual',
    script_language VARCHAR(50), script_content TEXT, expected_output TEXT,
    version VARCHAR(20) NOT NULL DEFAULT '1.0', is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE test_data_sets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    protocol_id UUID NOT NULL REFERENCES protocols(id),
    name VARCHAR(255) NOT NULL, description TEXT, data_content TEXT,
    is_representative BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE test_executions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_ref VARCHAR(50) UNIQUE NOT NULL,
    protocol_id UUID NOT NULL REFERENCES protocols(id), execution_number INT NOT NULL DEFAULT 1,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    environment_id UUID REFERENCES system_environments(id),
    executed_by UUID REFERENCES users(id), witnessed_by UUID REFERENCES users(id),
    started_at TIMESTAMPTZ, completed_at TIMESTAMPTZ, overall_result VARCHAR(50),
    total_steps INT, steps_passed INT NOT NULL DEFAULT 0,
    steps_failed INT NOT NULL DEFAULT 0, steps_with_deviations INT NOT NULL DEFAULT 0,
    steps_not_executed INT NOT NULL DEFAULT 0, deviation_count INT NOT NULL DEFAULT 0,
    conclusion TEXT, notes TEXT,
    is_reexecution BOOLEAN NOT NULL DEFAULT FALSE, reexecution_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- Deviations created before execution_steps to allow FK in both directions
CREATE TABLE deviations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deviation_ref VARCHAR(50) UNIQUE NOT NULL,
    execution_id UUID REFERENCES test_executions(id),
    execution_step_id UUID, -- FK added after test_execution_steps
    protocol_id UUID REFERENCES protocols(id), system_id UUID REFERENCES systems(id),
    title VARCHAR(512) NOT NULL, description TEXT NOT NULL,
    deviation_type VARCHAR(100), severity VARCHAR(20) NOT NULL DEFAULT 'minor',
    impact_on_validation VARCHAR(50), impact_description TEXT,
    immediate_action_taken TEXT, root_cause TEXT,
    disposition VARCHAR(50), disposition_rationale TEXT,
    retest_required BOOLEAN NOT NULL DEFAULT FALSE, retest_steps TEXT,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE, capa_id UUID, -- FK added after capas
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    raised_by UUID NOT NULL REFERENCES users(id), raised_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_by UUID REFERENCES users(id), closed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE test_execution_steps (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_id UUID NOT NULL REFERENCES test_executions(id),
    step_id UUID NOT NULL REFERENCES protocol_steps(id),
    sequence_number INT NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    actual_result TEXT, entered_value TEXT, pass_fail VARCHAR(20),
    executed_by UUID REFERENCES users(id), executed_at TIMESTAMPTZ,
    witnessed_by UUID REFERENCES users(id), witnessed_at TIMESTAMPTZ,
    deviation_raised BOOLEAN NOT NULL DEFAULT FALSE,
    deviation_id UUID REFERENCES deviations(id),
    comments TEXT, time_started TIMESTAMPTZ, time_completed TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE deviations ADD CONSTRAINT fk_dev_exec_step FOREIGN KEY (execution_step_id) REFERENCES test_execution_steps(id);

CREATE TABLE test_step_annotations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    execution_step_id UUID NOT NULL REFERENCES test_execution_steps(id),
    annotation_type VARCHAR(50) NOT NULL, content TEXT, position_data TEXT,
    file_attachment_id UUID REFERENCES file_attachments(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id)
);

CREATE TABLE deviation_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    deviation_id UUID NOT NULL REFERENCES deviations(id),
    reviewer_id UUID NOT NULL REFERENCES users(id), reviewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    disposition VARCHAR(50), comments TEXT,
    signature_id UUID REFERENCES electronic_signatures(id)
);

-- ============================================================
-- DOCUMENT MANAGEMENT
-- ============================================================

CREATE TABLE document_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id),
    parent_category_id UUID REFERENCES document_categories(id),
    name VARCHAR(255) NOT NULL, code VARCHAR(50), description TEXT,
    numbering_prefix VARCHAR(20), numbering_format VARCHAR(100),
    default_review_interval_months INT NOT NULL DEFAULT 24,
    requires_periodic_review BOOLEAN NOT NULL DEFAULT TRUE,
    is_controlled BOOLEAN NOT NULL DEFAULT TRUE, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE document_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_ref VARCHAR(50) UNIQUE NOT NULL,
    category_id UUID REFERENCES document_categories(id),
    name VARCHAR(512) NOT NULL, description TEXT, doc_type VARCHAR(100) NOT NULL,
    industry VARCHAR(100), regulatory_scope TEXT,
    is_system_template BOOLEAN NOT NULL DEFAULT FALSE, version VARCHAR(20) NOT NULL DEFAULT '1.0',
    body_content TEXT, available_variables TEXT, header_content TEXT, footer_content TEXT,
    page_layout TEXT, sections TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE document_template_variables (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    template_id UUID NOT NULL REFERENCES document_templates(id),
    variable_name VARCHAR(100) NOT NULL, display_name VARCHAR(255) NOT NULL,
    variable_type VARCHAR(50) NOT NULL,
    lookup_category_id UUID REFERENCES lookup_categories(id),
    default_value VARCHAR(512), is_required BOOLEAN NOT NULL DEFAULT FALSE,
    help_text TEXT, sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    doc_ref VARCHAR(100) UNIQUE NOT NULL,
    site_id UUID NOT NULL REFERENCES sites(id), category_id UUID NOT NULL REFERENCES document_categories(id),
    template_id UUID REFERENCES document_templates(id), system_id UUID REFERENCES systems(id),
    title VARCHAR(512) NOT NULL, current_version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft', doc_type VARCHAR(100) NOT NULL,
    effective_date DATE, expiry_date DATE, next_review_date DATE, review_interval_months INT NOT NULL DEFAULT 24,
    scope TEXT, purpose TEXT, regulatory_citations TEXT,
    is_controlled BOOLEAN NOT NULL DEFAULT TRUE, requires_training BOOLEAN NOT NULL DEFAULT FALSE,
    training_roles TEXT, owner_id UUID REFERENCES users(id), author_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE document_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version_number VARCHAR(20) NOT NULL, change_type VARCHAR(50), change_summary TEXT, change_reason TEXT,
    body_content TEXT NOT NULL, header_content TEXT, footer_content TEXT,
    variable_values TEXT, rendered_html TEXT, word_count INT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    drafted_by UUID REFERENCES users(id), drafted_at TIMESTAMPTZ,
    submitted_for_review_at TIMESTAMPTZ, approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id), effective_date DATE, superseded_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (document_id, version_number)
);

CREATE TABLE document_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    section_number VARCHAR(20), title VARCHAR(512), content TEXT,
    sort_order INT NOT NULL DEFAULT 0, is_locked BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE document_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    reviewer_id UUID NOT NULL REFERENCES users(id),
    review_type VARCHAR(50) NOT NULL DEFAULT 'technical', status VARCHAR(50) NOT NULL DEFAULT 'pending',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), due_date DATE, completed_at TIMESTAMPTZ,
    decision VARCHAR(50), comments TEXT, signature_id UUID REFERENCES electronic_signatures(id)
);

CREATE TABLE document_approvals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    approver_id UUID NOT NULL REFERENCES users(id), approver_role VARCHAR(100),
    sequence_number INT NOT NULL DEFAULT 1, status VARCHAR(50) NOT NULL DEFAULT 'pending',
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), due_date DATE, actioned_at TIMESTAMPTZ,
    decision VARCHAR(50), comments TEXT, signature_id UUID REFERENCES electronic_signatures(id)
);

CREATE TABLE document_distributions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    distributed_to_type VARCHAR(50) NOT NULL, distributed_to_id UUID,
    distributed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), distributed_by UUID REFERENCES users(id),
    read_confirmation_required BOOLEAN NOT NULL DEFAULT FALSE, read_deadline DATE
);

CREATE TABLE document_reads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    distribution_id UUID NOT NULL REFERENCES document_distributions(id),
    user_id UUID NOT NULL REFERENCES users(id), read_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confirmation_signature_id UUID REFERENCES electronic_signatures(id),
    UNIQUE (distribution_id, user_id)
);

CREATE TABLE document_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    document_id UUID NOT NULL REFERENCES documents(id),
    linked_object_type VARCHAR(100) NOT NULL, linked_object_id UUID NOT NULL,
    link_type VARCHAR(50) NOT NULL DEFAULT 'reference',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id)
);

-- ============================================================
-- FORM BUILDER (needed before workflows)
-- ============================================================

CREATE TABLE form_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID REFERENCES sites(id),
    name VARCHAR(512) NOT NULL, description TEXT,
    form_purpose VARCHAR(100) NOT NULL DEFAULT 'standalone',
    is_active BOOLEAN NOT NULL DEFAULT TRUE, version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE form_sections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    form_id UUID NOT NULL REFERENCES form_definitions(id),
    title VARCHAR(512), description TEXT, sort_order INT NOT NULL,
    is_repeatable BOOLEAN NOT NULL DEFAULT FALSE, repeat_label VARCHAR(255),
    conditional_show_field VARCHAR(100), conditional_show_value VARCHAR(512)
);

CREATE TABLE form_fields (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    section_id UUID NOT NULL REFERENCES form_sections(id),
    field_key VARCHAR(100) NOT NULL, label VARCHAR(512) NOT NULL, help_text TEXT,
    field_type VARCHAR(50) NOT NULL, is_required BOOLEAN NOT NULL DEFAULT FALSE,
    is_readonly BOOLEAN NOT NULL DEFAULT FALSE, placeholder VARCHAR(512), default_value VARCHAR(512),
    min_length INT, max_length INT, min_value DECIMAL, max_value DECIMAL,
    regex_pattern VARCHAR(512), regex_message VARCHAR(512),
    lookup_category_id UUID REFERENCES lookup_categories(id),
    options TEXT, table_columns TEXT, calculation_formula TEXT,
    signature_meaning_id UUID REFERENCES signature_meanings(id),
    conditional_show_field_key VARCHAR(100), conditional_show_value VARCHAR(512),
    regulatory_citation VARCHAR(512), sort_order INT NOT NULL
);

CREATE TABLE form_submissions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_ref VARCHAR(50) UNIQUE NOT NULL,
    form_id UUID NOT NULL REFERENCES form_definitions(id), form_version INT NOT NULL,
    object_type VARCHAR(100), object_id UUID, context VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    submitted_by UUID REFERENCES users(id), submitted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE form_submission_data (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    submission_id UUID NOT NULL REFERENCES form_submissions(id),
    field_id UUID NOT NULL REFERENCES form_fields(id), field_key VARCHAR(100) NOT NULL,
    value_text TEXT, value_number DECIMAL, value_date DATE, value_datetime TIMESTAMPTZ,
    value_boolean BOOLEAN, value_json TEXT,
    file_id UUID REFERENCES file_store(id), signature_id UUID REFERENCES electronic_signatures(id),
    entered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), entered_by UUID REFERENCES users(id)
);

-- ============================================================
-- WORKFLOW ENGINE
-- ============================================================

CREATE TABLE workflow_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    workflow_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID REFERENCES sites(id),
    name VARCHAR(512) NOT NULL, description TEXT,
    trigger_object_type VARCHAR(100) NOT NULL, trigger_event VARCHAR(100) NOT NULL,
    trigger_conditions TEXT, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    allow_parallel_stages BOOLEAN NOT NULL DEFAULT FALSE,
    require_all_approvers BOOLEAN NOT NULL DEFAULT TRUE,
    allow_self_approval BOOLEAN NOT NULL DEFAULT FALSE,
    notify_on_completion BOOLEAN NOT NULL DEFAULT TRUE, version INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE workflow_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    definition_id UUID NOT NULL REFERENCES workflow_definitions(id),
    stage_number INT NOT NULL, name VARCHAR(255) NOT NULL, description TEXT,
    stage_type VARCHAR(50) NOT NULL DEFAULT 'approval', assignee_type VARCHAR(50) NOT NULL,
    assignee_user_id UUID REFERENCES users(id), assignee_role_id UUID REFERENCES roles(id),
    assignee_department_id UUID REFERENCES departments(id), assignee_field VARCHAR(100),
    sla_hours INT, escalation_hours INT,
    escalate_to_user_id UUID REFERENCES users(id), escalate_to_role_id UUID REFERENCES roles(id),
    allow_delegation BOOLEAN NOT NULL DEFAULT TRUE,
    required_signature_meaning_id UUID REFERENCES signature_meanings(id),
    embedded_form_id UUID REFERENCES form_definitions(id),
    instructions TEXT, rejection_goes_to_stage INT,
    sort_order INT NOT NULL, is_optional BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE workflow_stage_conditions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    stage_id UUID NOT NULL REFERENCES workflow_stages(id),
    condition_type VARCHAR(50) NOT NULL, field_path VARCHAR(255) NOT NULL,
    operator VARCHAR(50) NOT NULL, value VARCHAR(512),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE workflow_transitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    definition_id UUID NOT NULL REFERENCES workflow_definitions(id),
    from_stage_id UUID REFERENCES workflow_stages(id),
    to_stage_id UUID REFERENCES workflow_stages(id),
    condition TEXT, transition_type VARCHAR(50) NOT NULL DEFAULT 'approve'
);

CREATE TABLE workflow_instances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_ref VARCHAR(50) UNIQUE NOT NULL,
    definition_id UUID NOT NULL REFERENCES workflow_definitions(id),
    object_type VARCHAR(100) NOT NULL, object_id UUID NOT NULL,
    current_stage_id UUID REFERENCES workflow_stages(id),
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    initiated_by UUID NOT NULL REFERENCES users(id), initiated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ, cancelled_at TIMESTAMPTZ, cancel_reason TEXT, context_data TEXT
);

CREATE TABLE workflow_instance_stages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_id UUID NOT NULL REFERENCES workflow_instances(id),
    stage_id UUID NOT NULL REFERENCES workflow_stages(id),
    assigned_to UUID NOT NULL REFERENCES users(id), assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_at TIMESTAMPTZ, status VARCHAR(50) NOT NULL DEFAULT 'pending',
    started_at TIMESTAMPTZ, completed_at TIMESTAMPTZ,
    action_taken VARCHAR(50), delegated_to UUID REFERENCES users(id), comments TEXT,
    form_submission_id UUID REFERENCES form_submissions(id),
    signature_id UUID REFERENCES electronic_signatures(id)
);

CREATE TABLE workflow_escalations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    instance_stage_id UUID NOT NULL REFERENCES workflow_instance_stages(id),
    escalated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    escalated_to UUID REFERENCES users(id), escalation_reason VARCHAR(255),
    resolved_at TIMESTAMPTZ, resolution VARCHAR(255)
);

-- ============================================================
-- NOTIFICATIONS
-- ============================================================

CREATE TABLE notification_templates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(100) UNIQUE NOT NULL, name VARCHAR(255) NOT NULL, description TEXT,
    channel VARCHAR(50) NOT NULL DEFAULT 'both',
    subject_template VARCHAR(512), body_template TEXT, available_variables TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE notification_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), name VARCHAR(255) NOT NULL,
    template_id UUID NOT NULL REFERENCES notification_templates(id),
    trigger_event VARCHAR(255) NOT NULL, trigger_conditions TEXT,
    recipient_type VARCHAR(50) NOT NULL,
    recipient_user_id UUID REFERENCES users(id), recipient_role_id UUID REFERENCES roles(id),
    recipient_field VARCHAR(100), delay_minutes INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rule_id UUID REFERENCES notification_rules(id),
    recipient_id UUID NOT NULL REFERENCES users(id),
    template_id UUID REFERENCES notification_templates(id),
    subject VARCHAR(512), body TEXT,
    object_type VARCHAR(100), object_id UUID, object_display VARCHAR(512),
    channel VARCHAR(50) NOT NULL DEFAULT 'in_app',
    is_read BOOLEAN NOT NULL DEFAULT FALSE, read_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ, email_status VARCHAR(50), email_error TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- CHANGE CONTROL
-- ============================================================

CREATE TABLE change_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cr_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL, description TEXT NOT NULL,
    change_type VARCHAR(100) NOT NULL DEFAULT 'planned', change_category VARCHAR(100),
    rationale TEXT NOT NULL, business_benefit TEXT,
    affected_systems TEXT, affected_documents TEXT, affected_equipment TEXT,
    validation_impact VARCHAR(50), validation_impact_justification TEXT,
    regulatory_impact BOOLEAN NOT NULL DEFAULT FALSE, regulatory_impact_description TEXT,
    risk_level VARCHAR(50), risk_assessment_id UUID REFERENCES risk_assessments(id),
    proposed_implementation_date DATE, actual_implementation_date DATE, rollback_plan TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'draft', emergency_justification TEXT,
    requestor_id UUID NOT NULL REFERENCES users(id), owner_id UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE change_request_versions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cr_id UUID NOT NULL REFERENCES change_requests(id),
    version_number INT NOT NULL, change_summary TEXT, snapshot TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id),
    UNIQUE (cr_id, version_number)
);

CREATE TABLE change_impact_assessments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cr_id UUID NOT NULL REFERENCES change_requests(id),
    assessed_by UUID NOT NULL REFERENCES users(id), assessment_date DATE,
    gxp_impact BOOLEAN NOT NULL DEFAULT FALSE, gxp_impact_description TEXT,
    systems_impacted TEXT, documents_requiring_update TEXT,
    testing_required BOOLEAN NOT NULL DEFAULT FALSE, testing_scope TEXT,
    training_required BOOLEAN NOT NULL DEFAULT FALSE, training_description TEXT,
    downtime_required BOOLEAN NOT NULL DEFAULT FALSE, estimated_downtime_hours DECIMAL,
    risk_summary TEXT, overall_recommendation VARCHAR(50), conditions TEXT,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE change_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cr_id UUID NOT NULL REFERENCES change_requests(id),
    task_ref VARCHAR(50) UNIQUE NOT NULL, title VARCHAR(512) NOT NULL, description TEXT,
    task_type VARCHAR(100), assigned_to UUID REFERENCES users(id), due_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started', completion_notes TEXT,
    completed_at TIMESTAMPTZ, completed_by UUID REFERENCES users(id),
    requires_evidence BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE change_verifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cr_id UUID NOT NULL REFERENCES change_requests(id),
    verified_by UUID NOT NULL REFERENCES users(id), verification_date DATE,
    verification_method VARCHAR(255), outcome VARCHAR(50), notes TEXT,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- CAPA
-- ============================================================

CREATE TABLE capas (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capa_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL, description TEXT NOT NULL,
    capa_type VARCHAR(50) NOT NULL DEFAULT 'corrective',
    source_type VARCHAR(100), source_id UUID, source_description TEXT,
    severity VARCHAR(50) NOT NULL DEFAULT 'minor',
    gxp_impact BOOLEAN NOT NULL DEFAULT FALSE, regulatory_reportable BOOLEAN NOT NULL DEFAULT FALSE,
    problem_statement TEXT NOT NULL, immediate_action TEXT,
    root_cause_method VARCHAR(100), root_cause_description TEXT, root_cause_category VARCHAR(100),
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    target_completion_date DATE, actual_completion_date DATE,
    owner_id UUID REFERENCES users(id), qa_owner_id UUID REFERENCES users(id),
    effectiveness_check_required BOOLEAN NOT NULL DEFAULT TRUE,
    effectiveness_check_date DATE, effectiveness_check_result VARCHAR(50), effectiveness_check_notes TEXT,
    closure_justification TEXT, closed_at TIMESTAMPTZ, closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

ALTER TABLE deviations ADD CONSTRAINT fk_dev_capa FOREIGN KEY (capa_id) REFERENCES capas(id);

CREATE TABLE capa_actions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capa_id UUID NOT NULL REFERENCES capas(id), action_number INT NOT NULL,
    action_type VARCHAR(50) NOT NULL, title VARCHAR(512) NOT NULL, description TEXT NOT NULL,
    responsible_id UUID REFERENCES users(id), target_date DATE, actual_completion_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started', completion_evidence TEXT,
    verified_by UUID REFERENCES users(id), verified_at TIMESTAMPTZ, verification_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE capa_root_cause_analysis (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capa_id UUID NOT NULL REFERENCES capas(id), analysis_method VARCHAR(100), analysis_content TEXT,
    facilitator_id UUID REFERENCES users(id), analysis_date DATE, participants TEXT, conclusions TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE capa_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    capa_id UUID NOT NULL REFERENCES capas(id),
    linked_object_type VARCHAR(100) NOT NULL, linked_object_id UUID NOT NULL,
    link_type VARCHAR(50) NOT NULL DEFAULT 'relates_to',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id)
);

-- ============================================================
-- NONCONFORMANCE
-- ============================================================

CREATE TABLE nonconformances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nc_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID NOT NULL REFERENCES sites(id),
    title VARCHAR(512) NOT NULL, description TEXT NOT NULL, nc_type VARCHAR(100),
    affected_system_id UUID REFERENCES systems(id), affected_equipment_id UUID REFERENCES equipment(id),
    gxp_impact BOOLEAN NOT NULL DEFAULT FALSE, impact_description TEXT, immediate_action TEXT,
    reported_by UUID NOT NULL REFERENCES users(id), reported_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    incident_date DATE, incident_time TIME, discovered_by UUID REFERENCES users(id),
    disposition VARCHAR(50), disposition_rationale TEXT,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE, capa_id UUID REFERENCES capas(id),
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    closed_at TIMESTAMPTZ, closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE nc_investigations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    nc_id UUID NOT NULL REFERENCES nonconformances(id),
    investigator_id UUID REFERENCES users(id),
    investigation_start_date DATE, investigation_end_date DATE, timeline_of_events TEXT,
    root_cause TEXT, contributing_factors TEXT, extent_of_impact TEXT,
    patient_safety_impact BOOLEAN NOT NULL DEFAULT FALSE,
    product_quality_impact BOOLEAN NOT NULL DEFAULT FALSE,
    data_integrity_impact BOOLEAN NOT NULL DEFAULT FALSE, recommendations TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- PERIODIC REVIEW
-- ============================================================

CREATE TABLE periodic_review_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    object_type VARCHAR(100) NOT NULL, object_id UUID NOT NULL,
    review_interval_months INT NOT NULL,
    last_review_date DATE, next_review_date DATE NOT NULL, lead_time_days INT NOT NULL DEFAULT 30,
    reviewer_id UUID REFERENCES users(id), secondary_reviewer_id UUID REFERENCES users(id),
    qa_reviewer_id UUID REFERENCES users(id), is_active BOOLEAN NOT NULL DEFAULT TRUE, notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE periodic_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_ref VARCHAR(50) UNIQUE NOT NULL,
    schedule_id UUID NOT NULL REFERENCES periodic_review_schedules(id),
    object_type VARCHAR(100) NOT NULL, object_id UUID NOT NULL,
    review_type VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    review_period_start DATE, review_period_end DATE, review_date DATE,
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled',
    reviewer_id UUID REFERENCES users(id), outcome VARCHAR(50),
    outcome_description TEXT, findings_summary TEXT, recommendations TEXT,
    next_review_date DATE, completed_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id), approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE periodic_review_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES periodic_reviews(id),
    item_category VARCHAR(100) NOT NULL, item_description TEXT NOT NULL,
    finding VARCHAR(50), finding_detail TEXT,
    action_required BOOLEAN NOT NULL DEFAULT FALSE, action_description TEXT,
    action_owner UUID REFERENCES users(id), action_due_date DATE, sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE periodic_review_findings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    review_id UUID NOT NULL REFERENCES periodic_reviews(id),
    finding_number INT NOT NULL, category VARCHAR(100), description TEXT NOT NULL,
    severity VARCHAR(50), requires_capa BOOLEAN NOT NULL DEFAULT FALSE, capa_id UUID REFERENCES capas(id),
    status VARCHAR(50) NOT NULL DEFAULT 'open',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- TRACEABILITY
-- ============================================================

CREATE TABLE traceability_links (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id),
    source_type VARCHAR(50) NOT NULL DEFAULT 'requirement', source_id UUID NOT NULL,
    target_type VARCHAR(50) NOT NULL, target_id UUID NOT NULL,
    link_type VARCHAR(50) NOT NULL DEFAULT 'verified_by',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), created_by UUID REFERENCES users(id)
);

CREATE TABLE traceability_matrices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    matrix_ref VARCHAR(50) UNIQUE NOT NULL, system_id UUID NOT NULL REFERENCES systems(id),
    title VARCHAR(512), generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    generated_by UUID REFERENCES users(id), status VARCHAR(50) NOT NULL DEFAULT 'current',
    coverage_percentage DECIMAL(5,2), total_requirements INT,
    requirements_with_tests INT, requirements_tested_and_passed INT,
    snapshot TEXT, is_approved BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by UUID REFERENCES users(id), approved_at TIMESTAMPTZ
);

-- ============================================================
-- VENDOR QUALIFICATION AND AUDITS
-- ============================================================

CREATE TABLE vendor_contacts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    vendor_id UUID NOT NULL REFERENCES vendors(id),
    name VARCHAR(255) NOT NULL, title VARCHAR(100), email VARCHAR(255), phone VARCHAR(50),
    contact_type VARCHAR(100), is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE vendor_qualifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    qualification_ref VARCHAR(50) UNIQUE NOT NULL, vendor_id UUID NOT NULL REFERENCES vendors(id),
    qualification_type VARCHAR(100), qualification_date DATE, next_qualification_date DATE,
    scope TEXT, outcome VARCHAR(50), conditions TEXT, notes TEXT,
    qualified_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE vendor_audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_ref VARCHAR(50) UNIQUE NOT NULL, vendor_id UUID NOT NULL REFERENCES vendors(id),
    audit_date DATE, audit_type VARCHAR(100), lead_auditor_id UUID REFERENCES users(id),
    co_auditors TEXT, scope TEXT, outcome VARCHAR(50),
    findings_count_critical INT NOT NULL DEFAULT 0, findings_count_major INT NOT NULL DEFAULT 0,
    findings_count_minor INT NOT NULL DEFAULT 0, observations_count INT NOT NULL DEFAULT 0,
    report_status VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE audits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    audit_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID NOT NULL REFERENCES sites(id),
    audit_type VARCHAR(50) NOT NULL, audit_name VARCHAR(512) NOT NULL,
    auditing_body VARCHAR(255), scope TEXT, start_date DATE, end_date DATE,
    lead_auditor VARCHAR(255), internal_coordinator_id UUID REFERENCES users(id),
    status VARCHAR(50) NOT NULL DEFAULT 'scheduled', outcome VARCHAR(50), response_due_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE audit_findings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    finding_ref VARCHAR(50) UNIQUE NOT NULL, audit_id UUID NOT NULL REFERENCES audits(id),
    finding_number INT NOT NULL, category VARCHAR(100), cfr_citation VARCHAR(512),
    description TEXT NOT NULL, severity VARCHAR(50) NOT NULL DEFAULT 'minor',
    system_id UUID REFERENCES systems(id), document_id UUID REFERENCES documents(id),
    status VARCHAR(50) NOT NULL DEFAULT 'open', response_due_date DATE, response_text TEXT,
    response_submitted_by UUID REFERENCES users(id), response_submitted_at TIMESTAMPTZ,
    capa_required BOOLEAN NOT NULL DEFAULT FALSE, capa_id UUID REFERENCES capas(id),
    closed_at TIMESTAMPTZ, closed_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- TRAINING
-- ============================================================

CREATE TABLE training_requirements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id), name VARCHAR(512) NOT NULL, description TEXT,
    training_type VARCHAR(100) NOT NULL,
    linked_document_id UUID REFERENCES documents(id),
    required_for_roles TEXT, required_for_departments TEXT,
    frequency VARCHAR(50) NOT NULL DEFAULT 'once', frequency_months INT,
    requires_assessment BOOLEAN NOT NULL DEFAULT FALSE, passing_score INT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE training_assignments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    requirement_id UUID NOT NULL REFERENCES training_requirements(id),
    user_id UUID NOT NULL REFERENCES users(id), assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    due_date DATE, status VARCHAR(50) NOT NULL DEFAULT 'assigned',
    waived_by UUID REFERENCES users(id), waiver_reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE training_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    training_ref VARCHAR(50) UNIQUE NOT NULL,
    assignment_id UUID REFERENCES training_assignments(id),
    requirement_id UUID NOT NULL REFERENCES training_requirements(id),
    user_id UUID NOT NULL REFERENCES users(id), completion_date DATE NOT NULL,
    training_method VARCHAR(100), trainer_id UUID REFERENCES users(id),
    assessment_score INT, assessment_passed BOOLEAN, expiry_date DATE,
    certificate_number VARCHAR(255), notes TEXT,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- REPORTS AND DASHBOARDS
-- ============================================================

CREATE TABLE report_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    report_ref VARCHAR(50) UNIQUE NOT NULL, site_id UUID REFERENCES sites(id),
    name VARCHAR(512) NOT NULL, description TEXT, report_type VARCHAR(100) NOT NULL,
    data_source VARCHAR(100) NOT NULL, query_config TEXT, chart_config TEXT, output_formats TEXT,
    is_system_report BOOLEAN NOT NULL DEFAULT FALSE, is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE report_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    definition_id UUID NOT NULL REFERENCES report_definitions(id),
    run_by UUID NOT NULL REFERENCES users(id), parameters TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'queued',
    started_at TIMESTAMPTZ, completed_at TIMESTAMPTZ, output_format VARCHAR(20),
    file_id UUID REFERENCES file_store(id), row_count INT, error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE report_schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    definition_id UUID NOT NULL REFERENCES report_definitions(id),
    name VARCHAR(255) NOT NULL, schedule_type VARCHAR(50) NOT NULL, schedule_cron VARCHAR(100),
    parameters TEXT, output_format VARCHAR(20) NOT NULL DEFAULT 'pdf', recipients TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE, last_run_at TIMESTAMPTZ, next_run_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE dashboard_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID REFERENCES sites(id), name VARCHAR(512) NOT NULL, description TEXT,
    is_default BOOLEAN NOT NULL DEFAULT FALSE, target_roles TEXT, layout TEXT,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE dashboard_widgets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    dashboard_id UUID NOT NULL REFERENCES dashboard_configs(id),
    widget_type VARCHAR(100) NOT NULL, title VARCHAR(512), data_source VARCHAR(100),
    query_config TEXT, display_config TEXT,
    position_x INT NOT NULL DEFAULT 0, position_y INT NOT NULL DEFAULT 0,
    width INT NOT NULL DEFAULT 4, height INT NOT NULL DEFAULT 3,
    refresh_minutes INT NOT NULL DEFAULT 60, sort_order INT NOT NULL DEFAULT 0
);

CREATE TABLE user_dashboard_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    dashboard_id UUID NOT NULL REFERENCES dashboard_configs(id),
    custom_layout TEXT, is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, dashboard_id)
);

-- ============================================================
-- SYSTEM CONFIGURATION
-- ============================================================

CREATE TABLE site_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id), setting_key VARCHAR(255) NOT NULL,
    setting_value TEXT, setting_type VARCHAR(50) NOT NULL DEFAULT 'string',
    description TEXT, is_sensitive BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_by UUID REFERENCES users(id),
    UNIQUE (site_id, setting_key)
);

CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    flag_key VARCHAR(100) UNIQUE NOT NULL, display_name VARCHAR(255), description TEXT,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE, enabled_for_sites TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_by UUID REFERENCES users(id)
);

CREATE TABLE smtp_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id),
    host VARCHAR(512) NOT NULL, port INT NOT NULL,
    use_tls BOOLEAN NOT NULL DEFAULT TRUE, use_ssl BOOLEAN NOT NULL DEFAULT FALSE,
    username VARCHAR(255), encrypted_password TEXT,
    from_address VARCHAR(255) NOT NULL, from_name VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE, last_tested_at TIMESTAMPTZ, last_test_result VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE ldap_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id), server_url VARCHAR(512) NOT NULL,
    bind_dn VARCHAR(512), encrypted_bind_password TEXT, base_dn VARCHAR(512) NOT NULL,
    user_search_filter VARCHAR(512),
    username_attribute VARCHAR(100) NOT NULL DEFAULT 'sAMAccountName',
    email_attribute VARCHAR(100) NOT NULL DEFAULT 'mail',
    full_name_attribute VARCHAR(100) NOT NULL DEFAULT 'displayName',
    group_search_base VARCHAR(512), group_filter VARCHAR(512),
    is_active BOOLEAN NOT NULL DEFAULT TRUE, last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE integration_configs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id), integration_type VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL, config TEXT, is_active BOOLEAN NOT NULL DEFAULT FALSE,
    last_health_check_at TIMESTAMPTZ, health_check_status VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE integration_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    config_id UUID NOT NULL REFERENCES integration_configs(id),
    direction VARCHAR(20) NOT NULL, event_type VARCHAR(100), payload_summary TEXT,
    status VARCHAR(50) NOT NULL, error_message TEXT,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), duration_ms INT
);

CREATE TABLE webhooks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id), name VARCHAR(255) NOT NULL,
    url VARCHAR(1024) NOT NULL, secret VARCHAR(255), events TEXT,
    is_active BOOLEAN NOT NULL DEFAULT FALSE, failure_count INT NOT NULL DEFAULT 0,
    last_triggered_at TIMESTAMPTZ, last_success_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id), updated_by UUID REFERENCES users(id)
);

CREATE TABLE webhook_deliveries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    webhook_id UUID NOT NULL REFERENCES webhooks(id), event_type VARCHAR(100), payload TEXT,
    response_status_code INT, response_body TEXT, duration_ms INT, success BOOLEAN NOT NULL,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), retry_count INT NOT NULL DEFAULT 0
);

CREATE TABLE system_health_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    check_type VARCHAR(100) NOT NULL, status VARCHAR(50) NOT NULL, details TEXT,
    checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table count check
SELECT COUNT(*) AS total_tables FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
