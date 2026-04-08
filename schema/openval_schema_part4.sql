-- ============================================================
-- OpenVAL Schema - Part 4: License Management and Open Core
-- Version: 1.0.0
-- Run after Parts 1, 2, and 3
-- ============================================================

-- ============================================================
-- LICENSE MANAGEMENT
-- ============================================================

CREATE TABLE license_cache (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    site_id UUID NOT NULL REFERENCES sites(id) UNIQUE,
    edition VARCHAR(50) NOT NULL DEFAULT 'community',
    tier VARCHAR(50) NOT NULL DEFAULT 'community',
    licensed_features TEXT NOT NULL DEFAULT '[]',
    max_users INT NOT NULL DEFAULT 50,
    max_sites INT NOT NULL DEFAULT 1,
    expires_at TIMESTAMPTZ,
    is_valid BOOLEAN NOT NULL DEFAULT FALSE,
    validation_error VARCHAR(512),
    last_validated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    license_key_hash VARCHAR(64)
);

CREATE TABLE license_audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_type VARCHAR(100) NOT NULL, -- validated, expired, renewed, invalid, feature_accessed
    edition VARCHAR(50),
    tier VARCHAR(50),
    feature_code VARCHAR(100), -- for feature_accessed events
    result VARCHAR(50) NOT NULL, -- success, denied, error
    message TEXT,
    ip_address VARCHAR(45),
    user_id UUID REFERENCES users(id),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- UPDATED FEATURE FLAGS SEED DATA
-- Complete CE/EE feature flag definitions
-- ============================================================

-- Clear old feature flags and replace with complete set
DELETE FROM feature_flags WHERE flag_key NOT IN (
    'mfa_required_for_all',
    'mfa_required_for_signatures',
    'allow_self_registration',
    'enable_ldap_sync',
    'enable_sso',
    'enable_webhooks',
    'enable_api_access',
    'strict_audit_chain',
    'require_deviation_signature',
    'enable_script_execution'
);

-- CE Features (always available, no license required)
INSERT INTO feature_flags (flag_key, display_name, description, is_enabled) VALUES
-- Core validation
('system_inventory',        'System Inventory',             'CE: System and equipment inventory module', true),
('risk_assessment',         'Risk Assessment',              'CE: Risk assessment engine (FMEA, probability/impact)', true),
('requirements',            'Requirements Management',      'CE: URS, FS, DS, CS authoring', true),
('protocols',               'Protocol Builder',             'CE: IQ/OQ/PQ/UAT protocol creation', true),
('test_execution',          'Test Execution Engine',        'CE: Step-by-step protocol execution', true),
('deviations',              'Deviation Management',         'CE: Inline deviation capture and management', true),
('documents',               'Document Management',          'CE: Controlled document library and templates', true),
('workflows_basic',         'Workflow Engine (Basic)',       'CE: Up to 5-stage workflow builder', true),
('change_control',          'Change Control',               'CE: Full change control lifecycle', true),
('capa',                    'CAPA Management',              'CE: Corrective and preventive action management', true),
('nonconformances',         'Nonconformances',              'CE: Nonconformance event management', true),
('periodic_review',         'Periodic Review',              'CE: Review scheduler and execution', true),
('traceability',            'Traceability Matrix',          'CE: Automated RTM generation', true),
('audit_log_viewer',        'Audit Log Viewer',             'CE: View and export audit trail', true),
('vendors_basic',           'Vendor Management (Basic)',    'CE: Vendor directory and basic qualification', true),
('audits_basic',            'Audit Management (Basic)',     'CE: Internal and external audit management', true),
('training_basic',          'Training Records (Basic)',     'CE: Training assignment and completion', true),
('reports_standard',        'Standard Reports',             'CE: Pre-built compliance reports', true),
('notifications_email',     'Email Notifications',          'CE: SMTP email notifications', true),
('file_storage',            'File Storage',                 'CE: File attachment management', true),
('api_read',                'API Read Access',              'CE: Read-only API access', true),
('ldap_basic',              'LDAP Sync (Basic)',            'CE: Basic LDAP user import', true),
('single_site',             'Single Site',                  'CE: Single site management', true),
('validation_wizard_basic', 'Validation Wizard (Basic)',    'CE: Guided validation setup for single system', true)
ON CONFLICT (flag_key) DO UPDATE SET display_name = EXCLUDED.display_name;

-- EE Features (require valid Enterprise license)
INSERT INTO feature_flags (flag_key, display_name, description, is_enabled) VALUES
-- Quality modules
('oos_oot',                 'OOS/OOT Management',           'EE: Out of specification/trend investigation', false),
('complaints',              'Complaint Management',          'EE: Product complaint lifecycle (21 CFR 211.198)', false),
('em_monitoring',           'Environmental Monitoring',      'EE: Full EM program management', false),
('stability_studies',       'Stability Studies',             'EE: ICH Q1A/Q1B stability study management', false),
('batch_lot',               'Batch/Lot Management',          'EE: Batch tracking and lot release', false),
('certificates_of_analysis','Certificate of Analysis',       'EE: CoA generation and approval', false),
('inspection_readiness',    'Inspection Readiness',          'EE: Automated inspection readiness checks', false),

-- Advanced workflow and forms
('workflows_advanced',      'Advanced Workflows',            'EE: Unlimited stages, conditional logic, parallel approvals', false),
('form_builder',            'Form Builder',                  'EE: Low-code form builder for workflow stages', false),
('automation_rules',        'Automation Rules',              'EE: Closed-loop quality automation triggers', false),
('custom_fields',           'Custom Fields',                 'EE: Add custom fields to any module record', false),
('validation_wizard_portfolio','Validation Portfolio Wizard', 'EE: Multi-system validation portfolio planning', false),

-- Analytics
('spc',                     'Statistical Process Control',   'EE: SPC charts, control limits, Nelson rules', false),
('manufacturing_analytics', 'Manufacturing Analytics',       'EE: Process parameter monitoring, batch analytics', false),
('process_parameters',      'Process Parameter Ingestion',   'EE: Ingest and monitor real-time process data', false),

-- AI
('ai_phase1',               'AI Assistance Phase 1',         'EE: SOP drafting, CAPA intelligence, deviation patterns', false),
('ai_phase2',               'AI Assistance Phase 2',         'EE: Semantic search, predictive quality, inspection AI', false),

-- Multi-site
('multi_site',              'Multi-Site Management',         'EE: Unlimited sites, cross-site dashboard', false),
('cross_site_documents',    'Cross-Site Document Publishing','EE: Publish documents across sites', false),
('org_dashboard',           'Organization Dashboard',         'EE: Executive cross-site compliance dashboard', false),

-- Advanced integrations
('labware_integration',     'LabWare Integration',           'EE: Bidirectional LabWare LIMS sync', false),
('trackwise_integration',   'TrackWise Integration',         'EE: TrackWise change/CAPA sync', false),
('sap_integration',         'SAP/Oracle Integration',        'EE: Equipment and vendor master sync', false),
('mes_integration',         'MES Integration',               'EE: Manufacturing execution system batch events', false),
('webhooks_outbound',       'Outbound Webhooks',             'EE: Push events to external systems', false),
('api_write',               'API Write Access',              'EE: Full read+write API access', false),
('teams_slack',             'Teams and Slack Notifications', 'EE: Push notifications to Teams/Slack channels', false),

-- Advanced identity
('sso_saml',                'SAML/OIDC SSO',                 'EE: Single sign-on via SAML 2.0 or OIDC', false),
('ldap_advanced',           'Advanced LDAP',                 'EE: Group-to-role mapping, attribute sync', false),
('scim',                    'SCIM Provisioning',             'EE: Automated user provisioning via SCIM', false),
('ip_allowlist',            'IP Address Allowlist',          'EE: Restrict access by IP address range', false),

-- Advanced reporting
('reports_custom',          'Custom Report Builder',         'EE: Drag-and-drop report builder', false),
('reports_scheduled',       'Scheduled Reports',             'EE: Auto-generate and distribute reports on schedule', false),
('reports_cross_site',      'Cross-Site Reports',            'EE: Reports spanning multiple sites', false),
('export_api',              'Data Export API',               'EE: Bulk data export via API', false)
ON CONFLICT (flag_key) DO UPDATE SET display_name = EXCLUDED.display_name, description = EXCLUDED.description;

-- ============================================================
-- CE/EE FEATURE MAPPING TABLE
-- Documents which features belong to which tier
-- Used by the upgrade page and license documentation
-- ============================================================

CREATE TABLE feature_tier_definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    feature_code VARCHAR(100) UNIQUE NOT NULL REFERENCES feature_flags(flag_key),
    tier VARCHAR(20) NOT NULL CHECK (tier IN ('community','enterprise','enterprise_addon')),
    display_name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    benefits TEXT NOT NULL, -- JSON array of benefit strings
    icon_name VARCHAR(50), -- lucide-react icon name
    upgrade_cta VARCHAR(512), -- call to action text for upgrade page
    docs_url VARCHAR(512), -- link to feature documentation
    sort_order INT NOT NULL DEFAULT 0
);

-- Populate CE features
INSERT INTO feature_tier_definitions (feature_code, tier, display_name, description, benefits, icon_name, sort_order)
SELECT
    flag_key,
    'community',
    display_name,
    description,
    '["Available in all editions"]',
    'check-circle',
    0
FROM feature_flags
WHERE flag_key IN (
    'system_inventory','risk_assessment','requirements','protocols','test_execution',
    'deviations','documents','workflows_basic','change_control','capa',
    'nonconformances','periodic_review','traceability','audit_log_viewer',
    'vendors_basic','audits_basic','training_basic','reports_standard',
    'notifications_email','file_storage','api_read','ldap_basic','single_site',
    'validation_wizard_basic'
)
ON CONFLICT (feature_code) DO NOTHING;

-- Key EE features with full descriptions
INSERT INTO feature_tier_definitions (feature_code, tier, display_name, description, benefits, icon_name, sort_order) VALUES
('oos_oot', 'enterprise', 'OOS/OOT Investigation Management',
 'Manage the full investigation lifecycle for out-of-specification and out-of-trend laboratory results.',
 '["Structured Phase 1 and Phase 2 investigation workflows","Automatic retest scheduling","Integrated CAPA creation","OOS rate trending by test type","21 CFR 211 compliant documentation"]',
 'flask', 10),

('complaints', 'enterprise', 'Complaint Management',
 'Track, investigate, and resolve product complaints and adverse events.',
 '["21 CFR 211.198 and 820.198 compliant","Reportability determination workflow","Regulatory report tracking (MDR, field safety)","Lot disposition management","Response tracking"]',
 'message-square', 20),

('em_monitoring', 'enterprise', 'Environmental Monitoring Module',
 'Complete EM program management: scheduling, results, excursions, and trending.',
 '["Full EM program configuration","Automated session scheduling","Real-time excursion detection","SPC trending charts","Monthly EM summary reports"]',
 'activity', 30),

('stability_studies', 'enterprise', 'Stability Study Management',
 'ICH Q1A/Q1B stability protocol management with time point tracking and trending.',
 '["Real-time, accelerated, and stress study types","Pull schedule calendar","Trending charts by parameter and time point","OOS auto-linkage","Study summary report generation"]',
 'timer', 40),

('batch_lot', 'enterprise', 'Batch and Lot Management',
 'Batch lifecycle tracking from manufacture through lot release.',
 '["Batch status board","QC test request management","Hold management with notifications","Lot release workflow with e-signature","Certificate of Analysis generation"]',
 'package', 50),

('inspection_readiness', 'enterprise', 'Inspection Readiness Module',
 'Real-time compliance scorecard and inspection simulation to prepare for regulatory inspections.',
 '["Automated compliance checks across all modules","Mock inspection against FDA and EMA frameworks","Active inspection document request tracking","Verbal commitment management","Pre-inspection gap report"]',
 'shield-check', 60),

('spc', 'enterprise', 'Statistical Process Control',
 'Apply SPC to quality data: EM results, OOS rates, CAPA cycle times, stability trends.',
 '["I-MR, X-bar R, and CUSUM chart types","Nelson and Western Electric rules","Automated out-of-control detection","OOT record auto-creation","Process capability indices (Cp, Cpk)"]',
 'trending-up', 70),

('manufacturing_analytics', 'enterprise', 'Manufacturing Analytics Extension',
 'Real-time process parameter monitoring and batch analytics (DCP-compatible).',
 '["Process parameter ingestion (REST API)","Real-time monitoring dashboard","Batch evolution charts","Batch-to-batch comparison","CPP/CQA correlation analysis"]',
 'bar-chart-2', 80),

('ai_phase1', 'enterprise', 'AI Assistance (Phase 1)',
 'AI-powered quality assistance with full human-in-the-loop governance.',
 '["SOP draft generation from title and scope","Regulatory gap checker vs CFR citations","Root cause suggestion engine","Similar CAPA finder with effectiveness history","Deviation pattern analysis"]',
 'cpu', 90),

('multi_site', 'enterprise', 'Multi-Site Management',
 'Manage unlimited sites from a single OpenVAL installation.',
 '["Unlimited sites","Cross-site compliance dashboard","Executive KPI view across all sites","Cross-site trending","Organization-level settings"]',
 'globe', 100),

('labware_integration', 'enterprise', 'LabWare LIMS Integration',
 'Bidirectional integration with LabWare LIMS for EM, OOS, and system status synchronization.',
 '["EM excursion webhook receiver","OOS result auto-creation","System validation status sync","Audit trail comparison","Instrument calibration status feed"]',
 'link', 110),

('trackwise_integration', 'enterprise', 'TrackWise Integration',
 'Synchronize change requests and CAPAs with TrackWise (Sparta/Honeywell).',
 '["Change request bidirectional sync","CAPA synchronization","Impact assessment workflow linkage","TrackWise XML export","External reference tracking"]',
 'link', 120),

('sso_saml', 'enterprise', 'SAML 2.0 / OIDC SSO',
 'Delegate authentication to your corporate identity provider.',
 '["Azure AD/Entra ID support","Okta support","Any SAML 2.0 or OIDC IdP","E-signature re-authentication via IdP","SCIM user provisioning"]',
 'key', 130),

('workflows_advanced', 'enterprise', 'Advanced Workflow Engine',
 'Unlimited stages, conditional logic, parallel approvals, and embedded forms.',
 '["Unlimited workflow stages","Conditional if/then routing","Parallel approval stages","Embedded form capture in stages","Advanced escalation chains","Workflow simulation mode"]',
 'git-branch', 140),

('reports_custom', 'enterprise', 'Custom Report Builder',
 'Build any report from any data in the system with drag-and-drop field selection.',
 '["Drag-and-drop field selection","Multi-module data joining","Chart and table output","Scheduled delivery to email/Teams/Slack","Cross-site reporting"]',
 'file-bar-chart', 150),

('ai_phase2', 'enterprise', 'AI Assistance (Phase 2)',
 'Advanced AI: semantic search, predictive quality monitoring, inspection AI.',
 '["Semantic full-text search across all documents","Regulatory change impact analysis","Predictive quality event detection","Common 483 observation response library","Data integrity risk scanner"]',
 'sparkles', 160)
ON CONFLICT (feature_code) DO NOTHING;

-- ============================================================
-- INDEXES FOR LICENSE TABLES
-- ============================================================

CREATE INDEX idx_license_cache_site ON license_cache (site_id);
CREATE INDEX idx_license_audit_log_type ON license_audit_log (event_type, occurred_at DESC);
CREATE INDEX idx_license_audit_log_user ON license_audit_log (user_id, occurred_at DESC);
CREATE INDEX idx_feature_tier_tier ON feature_tier_definitions (tier);
CREATE INDEX idx_feature_tier_sort ON feature_tier_definitions (sort_order);

-- ============================================================
-- MODULE REGISTRY TABLE
-- Tracks which modules are loaded in the current installation
-- Used for health checks and support diagnostics
-- ============================================================

CREATE TABLE module_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    module_code VARCHAR(100) UNIQUE NOT NULL,
    module_name VARCHAR(255) NOT NULL,
    tier VARCHAR(20) NOT NULL DEFAULT 'community',
    version VARCHAR(50),
    is_loaded BOOLEAN NOT NULL DEFAULT FALSE,
    load_error TEXT,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_health_check TIMESTAMPTZ,
    health_status VARCHAR(50) DEFAULT 'unknown'
);

-- CE modules always registered on startup
INSERT INTO module_registry (module_code, module_name, tier, is_loaded) VALUES
('auth',             'Authentication',          'community', false),
('users',            'User Management',         'community', false),
('systems',          'System Inventory',        'community', false),
('equipment',        'Equipment Management',    'community', false),
('risk',             'Risk Assessment',         'community', false),
('requirements',     'Requirements Management', 'community', false),
('protocols',        'Protocol Builder',        'community', false),
('executions',       'Test Execution',          'community', false),
('deviations',       'Deviation Management',    'community', false),
('documents',        'Document Management',     'community', false),
('workflows',        'Workflow Engine',         'community', false),
('change_control',   'Change Control',          'community', false),
('capa',             'CAPA Management',         'community', false),
('nonconformances',  'Nonconformance Mgmt',     'community', false),
('periodic_review',  'Periodic Review',         'community', false),
('traceability',     'Traceability Matrix',     'community', false),
('vendors',          'Vendor Management',       'community', false),
('audits',           'Audit Management',        'community', false),
('training',         'Training Records',        'community', false),
('reports',          'Reports',                 'community', false),
('notifications',    'Notifications',           'community', false),
('files',            'File Management',         'community', false),
('audit_log',        'Audit Log',               'community', false),
('admin',            'Administration',          'community', false),
-- EE modules registered but not loaded until licensed
('oos_oot',          'OOS/OOT Management',      'enterprise', false),
('complaints',       'Complaint Management',    'enterprise', false),
('em',               'Environmental Monitoring','enterprise', false),
('stability',        'Stability Studies',       'enterprise', false),
('batch_lot',        'Batch/Lot Management',    'enterprise', false),
('inspection',       'Inspection Readiness',    'enterprise', false),
('spc',              'Statistical Process Control','enterprise', false),
('analytics',        'Manufacturing Analytics', 'enterprise', false),
('ai',               'AI Assistance',           'enterprise', false),
('multi_site',       'Multi-Site Management',   'enterprise', false),
('advanced_wf',      'Advanced Workflows',      'enterprise', false),
('integrations',     'Advanced Integrations',   'enterprise', false),
('advanced_reports', 'Advanced Reports',        'enterprise', false)
ON CONFLICT (module_code) DO NOTHING;

-- ============================================================
-- COMMENTS
-- ============================================================

COMMENT ON TABLE license_cache IS 'Cached and parsed license key state. Updated hourly by Celery. Never manually edited.';
COMMENT ON TABLE license_audit_log IS 'Log of all license validation events and feature access attempts for EE features. Append-only.';
COMMENT ON TABLE feature_tier_definitions IS 'Documents which features belong to CE vs EE. Used by upgrade pages and license documentation.';
COMMENT ON TABLE module_registry IS 'Registry of all available modules and their load status. Used for health monitoring and support diagnostics.';
