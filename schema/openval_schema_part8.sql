-- ============================================================
-- OpenVAL Schema - Part 8: Complete Document & Template System
-- Version: 1.0.0
-- Run after Parts 1-7
--
-- Implements the block-based document architecture defined in
-- URS-DOC-001. Replaces the basic document_sections table with
-- a proper block model that supports reusable content, typed
-- content blocks, template variables, and validation packages.
-- ============================================================

-- ============================================================
-- SECTION 1: DOCUMENT LAYOUT CONFIGURATIONS
-- Configurable page layout per template: size, orientation,
-- margins, header/footer format.
-- ============================================================

CREATE TABLE document_layout_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    site_id UUID REFERENCES sites(id),              -- NULL = global
    config_name VARCHAR(255) NOT NULL,
    page_size VARCHAR(20) NOT NULL DEFAULT 'letter', -- letter | a4
    default_orientation VARCHAR(20) NOT NULL DEFAULT 'portrait', -- portrait | landscape
    margin_top_mm DECIMAL(6,2) NOT NULL DEFAULT 25.4,
    margin_bottom_mm DECIMAL(6,2) NOT NULL DEFAULT 25.4,
    margin_left_mm DECIMAL(6,2) NOT NULL DEFAULT 25.4,
    margin_right_mm DECIMAL(6,2) NOT NULL DEFAULT 25.4,
    -- Header configuration
    header_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    header_height_mm DECIMAL(6,2) NOT NULL DEFAULT 30.0,
    header_template TEXT,                            -- JSON: {left, center, right} zones with field refs
    header_logo_file_id UUID REFERENCES file_store(id),
    -- Footer configuration
    footer_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    footer_height_mm DECIMAL(6,2) NOT NULL DEFAULT 15.0,
    footer_template TEXT,                            -- JSON: {left, center, right}
    -- Watermarks
    draft_watermark_text VARCHAR(50) DEFAULT 'DRAFT',
    controlled_copy_watermark_text VARCHAR(100) DEFAULT 'CONTROLLED COPY',
    obsolete_watermark_text VARCHAR(50) DEFAULT 'OBSOLETE',
    -- Typography
    body_font VARCHAR(100) DEFAULT 'Inter',
    heading_font VARCHAR(100) DEFAULT 'Inter',
    monospace_font VARCHAR(100) DEFAULT 'JetBrains Mono',
    base_font_size_pt DECIMAL(5,2) DEFAULT 10.0,
    -- Colors
    heading_color VARCHAR(7) DEFAULT '#0F172A',
    accent_color VARCHAR(7) DEFAULT '#00A090',
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 2: BLOCK LIBRARY
-- Reusable content blocks that can be inserted into any document.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_block_ref START 1;

CREATE TABLE block_library (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_ref VARCHAR(50) UNIQUE NOT NULL,           -- BLK-0001
    site_id UUID REFERENCES sites(id),               -- NULL = global block
    title VARCHAR(512) NOT NULL,
    description TEXT,
    block_type VARCHAR(100) NOT NULL,
    -- All block types: paragraph | heading | callout | generic_table
    -- execution_table | data_entry_table | config_table | risk_matrix_table
    -- requirements_table | acceptance_criteria_block | image_block
    -- signature_block | signature_table | revision_history_block
    -- table_of_contents_block | variable_display_block | checklist_block
    -- form_block | conditional_section | flowchart_block | page_break
    category VARCHAR(100) NOT NULL,
    -- boilerplate_text | signature_block | compliance_checklist
    -- standard_table | regulatory_citation | acceptance_criteria | glossary
    content_config TEXT NOT NULL,                    -- JSON: full block definition
    tags TEXT,                                       -- JSON array of tags
    applicable_doc_types TEXT,                       -- JSON: ["SOP","IQ","OQ"]
    regulatory_citations TEXT,                       -- JSON: ["21 CFR 11.10(e)"]
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'active',    -- draft | active | deprecated
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,        -- locked = cannot be edited
    usage_count INT NOT NULL DEFAULT 0,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE block_library_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES block_library(id),
    version VARCHAR(20) NOT NULL,
    content_config TEXT NOT NULL,
    change_summary TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (block_id, version)
);

-- ============================================================
-- SECTION 3: TEMPLATE VARIABLE SYSTEM
-- Variables auto-populate document content from system data.
-- ============================================================

CREATE TABLE template_variable_sources (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_key VARCHAR(100) UNIQUE NOT NULL,         -- e.g., "system.name"
    display_name VARCHAR(255) NOT NULL,              -- "System Name"
    description TEXT,
    source_type VARCHAR(100) NOT NULL,               -- database_field | expression | user_input | constant
    source_config TEXT,                              -- JSON: how to resolve this variable
    data_type VARCHAR(50) NOT NULL DEFAULT 'string', -- string | date | number | boolean
    example_value VARCHAR(512),
    category VARCHAR(100) NOT NULL,
    -- system | site | user | document | date | equipment | custom
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- Seed the standard variable sources
INSERT INTO template_variable_sources
    (source_key, display_name, description, source_type, data_type, category, sort_order)
VALUES
-- System variables
('system.name',             'System Name',          'Name of the linked GxP system', 'database_field', 'string', 'system', 10),
('system.ref',              'System Reference',     'System reference number', 'database_field', 'string', 'system', 20),
('system.version',          'System Version',       'Software version number', 'database_field', 'string', 'system', 30),
('system.vendor',           'System Vendor',        'Software vendor name', 'database_field', 'string', 'system', 40),
('system.gamp_category',    'GAMP Category',        'GAMP 5 classification', 'database_field', 'string', 'system', 50),
('system.gxp_impact',       'GxP Impact',           'Overall GxP impact rating', 'database_field', 'string', 'system', 60),
-- Site variables
('site.name',               'Site Name',            'Site/facility name', 'database_field', 'string', 'site', 10),
('site.address',            'Site Address',         'Full site address', 'database_field', 'string', 'site', 20),
('site.contact_person',     'Site Contact',         'Primary QA contact', 'database_field', 'string', 'site', 30),
-- Document variables
('document.number',         'Document Number',      'Unique document reference', 'database_field', 'string', 'document', 10),
('document.version',        'Document Version',     'Current version number', 'database_field', 'string', 'document', 20),
('document.title',          'Document Title',       'Document title', 'database_field', 'string', 'document', 30),
('document.effective_date', 'Effective Date',       'Document effective date', 'database_field', 'date', 'document', 40),
('document.owner',          'Document Owner',       'Document owner full name', 'database_field', 'string', 'document', 50),
-- Date variables
('date.today',              'Today''s Date',        'Current date', 'expression', 'date', 'date', 10),
('date.year',               'Current Year',         'Current year', 'expression', 'string', 'date', 20),
-- User variables (person creating/editing)
('user.name',               'Current User Name',    'Full name of current user', 'database_field', 'string', 'user', 10),
('user.title',              'Current User Title',   'Job title of current user', 'database_field', 'string', 'user', 20),
-- Equipment variables
('equipment.name',          'Equipment Name',       'Equipment name', 'database_field', 'string', 'equipment', 10),
('equipment.serial',        'Serial Number',        'Equipment serial number', 'database_field', 'string', 'equipment', 20),
('equipment.asset_number',  'Asset Number',         'Internal asset/tag number', 'database_field', 'string', 'equipment', 30),
('equipment.manufacturer',  'Manufacturer',         'Equipment manufacturer', 'database_field', 'string', 'equipment', 40),
('equipment.model',         'Model',                'Model number', 'database_field', 'string', 'equipment', 50)
ON CONFLICT (source_key) DO NOTHING;

-- ============================================================
-- SECTION 4: DOCUMENT BLOCK MODEL
-- The core of the block-based document architecture.
-- Every piece of content in a document is a block.
-- ============================================================

CREATE TABLE document_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    -- Block identity
    block_type VARCHAR(100) NOT NULL,               -- See block type list in URS-DOC-017
    section_path VARCHAR(255),                      -- e.g., "3" or "3.2" or "3.2.1" for nested sections
    sort_order INT NOT NULL DEFAULT 0,              -- Position within the document
    -- Library linkage
    library_block_id UUID REFERENCES block_library(id),
    library_block_version VARCHAR(20),              -- Which version of library block was used
    is_library_linked BOOLEAN NOT NULL DEFAULT FALSE,
    library_update_available BOOLEAN NOT NULL DEFAULT FALSE,
    -- Content (JSON configuration varies by block_type)
    content TEXT,                                   -- For paragraph, heading: rich text (TipTap JSON)
    config TEXT,                                    -- For tables, forms: column definitions, layout config
    data TEXT,                                      -- For data tables: actual row data
    -- Execution state (filled during protocol execution)
    execution_data TEXT,                            -- JSON: execution results per row/field
    execution_status VARCHAR(50),                   -- not_started | in_progress | complete
    executed_by UUID REFERENCES users(id),
    executed_at TIMESTAMPTZ,
    -- Access control
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,       -- Locked blocks cannot be edited
    locked_by UUID REFERENCES users(id),
    locked_at TIMESTAMPTZ,
    locked_reason TEXT,
    -- Page layout override for this block
    orientation_override VARCHAR(20),               -- portrait | landscape (overrides document default for this block)
    -- Metadata
    heading_level INT,                              -- 1-4 for heading blocks
    section_number_display VARCHAR(20),             -- Auto-computed: "3.2.1"
    is_toc_entry BOOLEAN NOT NULL DEFAULT FALSE,    -- Include in table of contents?
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Execution step detail (one row per step in an execution_table block)
CREATE TABLE document_block_execution_steps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES document_blocks(id),
    step_number INT NOT NULL,
    step_ref VARCHAR(50),                           -- e.g., "3.2.1" or user-defined "Step 4a"
    step_type VARCHAR(50) NOT NULL DEFAULT 'check',
    action_content TEXT,                            -- Rich text: what the executor must do
    expected_result_content TEXT,                   -- Rich text: what should happen
    acceptance_criteria TEXT,                       -- JSON: {min, max, unit, pattern, options}
    input_type VARCHAR(50) NOT NULL DEFAULT 'pass_fail',
    -- pass_fail | text | number | date | dropdown | table | screenshot | signature
    input_options TEXT,                             -- JSON: dropdown options, table columns, etc.
    is_critical BOOLEAN NOT NULL DEFAULT FALSE,     -- Critical steps get enhanced attention
    requires_screenshot BOOLEAN NOT NULL DEFAULT FALSE,
    requires_witness BOOLEAN NOT NULL DEFAULT FALSE,
    conditional_show_if TEXT,                       -- JSON: show this step only if condition met
    linked_requirement_ids TEXT,                    -- JSON: requirement IDs this step validates
    regulatory_citation VARCHAR(255),
    test_case_template_step_id UUID REFERENCES test_case_template_steps(id),
    sort_order INT NOT NULL,
    -- Execution results (filled during execution)
    actual_result TEXT,
    actual_value DECIMAL(20,6),                     -- Parsed numeric value
    actual_value_unit VARCHAR(50),
    pass_fail VARCHAR(20),                          -- pass | fail | not_applicable | deviation
    executed_by UUID REFERENCES users(id),
    executed_at TIMESTAMPTZ,
    witness_id UUID REFERENCES users(id),
    witness_at TIMESTAMPTZ,
    witness_signature_id UUID REFERENCES electronic_signatures(id),
    deviation_id UUID REFERENCES deviations(id),
    execution_signature_id UUID REFERENCES electronic_signatures(id),
    execution_notes TEXT,
    -- Table data (for steps with input_type = table)
    table_rows TEXT,                                -- JSON array of row objects
    table_summary_stats TEXT,                       -- JSON: mean, rsd, etc.
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id),
    UNIQUE (block_id, step_number)
);

-- Attachments per execution step
CREATE TABLE block_step_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    step_id UUID NOT NULL REFERENCES document_block_execution_steps(id),
    file_id UUID NOT NULL REFERENCES file_store(id),
    attachment_type VARCHAR(50) NOT NULL DEFAULT 'screenshot',
    -- screenshot | evidence_file | instrument_output | calibration_cert | photo
    caption TEXT,
    sequence_number INT NOT NULL DEFAULT 1,
    uploaded_by UUID REFERENCES users(id),
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Form field definitions within form_block type blocks
CREATE TABLE document_form_fields (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES document_blocks(id),
    field_key VARCHAR(100) NOT NULL,                -- Internal key, not shown to user
    field_label VARCHAR(512) NOT NULL,
    field_type VARCHAR(50) NOT NULL,
    -- text | number | date | datetime | dropdown | radio | checkbox | file | textarea | signature
    field_options TEXT,                             -- JSON: dropdown/radio options
    is_required BOOLEAN NOT NULL DEFAULT FALSE,
    validation_rules TEXT,                          -- JSON: {min, max, pattern, custom_rule}
    help_text TEXT,
    placeholder TEXT,
    conditional_show_if TEXT,                       -- JSON: show this field only if condition met
    sort_order INT NOT NULL,
    UNIQUE (block_id, field_key)
);

-- Filled form field values (per document instance)
CREATE TABLE document_form_field_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    field_id UUID NOT NULL REFERENCES document_form_fields(id),
    field_key VARCHAR(100) NOT NULL,                -- Snapshot
    value_text TEXT,
    value_number DECIMAL(20,6),
    value_date DATE,
    value_datetime TIMESTAMPTZ,
    value_boolean BOOLEAN,
    value_file_id UUID REFERENCES file_store(id),
    filled_by UUID REFERENCES users(id),
    filled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (version_id, field_id)
);

-- ============================================================
-- SECTION 5: FLOWCHART / WORKFLOW DIAGRAMS
-- Visual workflow diagrams embedded in documents (SOPs, WIs).
-- ============================================================

CREATE TABLE flowchart_diagrams (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    block_id UUID NOT NULL REFERENCES document_blocks(id) UNIQUE,
    title VARCHAR(512),
    diagram_type VARCHAR(50) NOT NULL DEFAULT 'flowchart',
    -- flowchart | swimlane | data_flow | process_map
    orientation VARCHAR(20) NOT NULL DEFAULT 'vertical',
    -- vertical (top-to-bottom) | horizontal (left-to-right)
    -- Swimlane config
    has_swimlanes BOOLEAN NOT NULL DEFAULT FALSE,
    swimlane_config TEXT,                           -- JSON: [{label, orientation, color}]
    -- Diagram serialization
    diagram_json TEXT NOT NULL DEFAULT '{}',        -- Complete diagram state in JSON
    svg_snapshot TEXT,                              -- Last rendered SVG (cached)
    svg_generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE flowchart_shapes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diagram_id UUID NOT NULL REFERENCES flowchart_diagrams(id),
    shape_ref VARCHAR(20) NOT NULL,                 -- Short ID within diagram: S1, S2
    shape_type VARCHAR(50) NOT NULL,
    -- rectangle | diamond | rounded_rect | parallelogram | cylinder | document_shape
    -- oval | hexagon | manual_input
    label TEXT,
    sublabel TEXT,                                  -- Secondary label (e.g., responsible party)
    swimlane_index INT,                             -- Which swimlane this shape belongs to
    position_x DECIMAL(10,2) NOT NULL,
    position_y DECIMAL(10,2) NOT NULL,
    width_px DECIMAL(10,2) NOT NULL DEFAULT 120,
    height_px DECIMAL(10,2) NOT NULL DEFAULT 60,
    style_config TEXT,                              -- JSON: fill_color, border_color, font_size
    -- Link to workflow engine
    workflow_stage_id UUID REFERENCES workflow_stages(id),
    hyperlink_url VARCHAR(1024),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE flowchart_connections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    diagram_id UUID NOT NULL REFERENCES flowchart_diagrams(id),
    from_shape_id UUID NOT NULL REFERENCES flowchart_shapes(id),
    to_shape_id UUID NOT NULL REFERENCES flowchart_shapes(id),
    label VARCHAR(255),                             -- e.g., "Yes", "No", "If deviation"
    line_style VARCHAR(50) DEFAULT 'solid',         -- solid | dashed | dotted
    arrow_type VARCHAR(50) DEFAULT 'end',           -- none | end | both | start
    route_points TEXT,                              -- JSON: [{x, y}] bend points
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SECTION 6: VALIDATION PACKAGES
-- Bundles of related validation documents as a complete package.
-- ============================================================

CREATE SEQUENCE IF NOT EXISTS seq_val_package_ref START 1;

CREATE TABLE validation_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_ref VARCHAR(50) UNIQUE NOT NULL,        -- VPKG-0001
    site_id UUID NOT NULL REFERENCES sites(id),
    project_id UUID REFERENCES validation_projects(id),
    system_id UUID REFERENCES systems(id),
    title VARCHAR(512) NOT NULL,
    description TEXT,
    package_type VARCHAR(100) NOT NULL DEFAULT 'full_lifecycle',
    -- full_lifecycle | csv_only | csa_only | equipment | method | process
    version VARCHAR(20) NOT NULL DEFAULT '1.0',
    status VARCHAR(50) NOT NULL DEFAULT 'draft',
    -- draft | in_review | approved | released | superseded | retired
    -- Scope
    scope_description TEXT NOT NULL,
    applicable_regulations TEXT,                    -- JSON array
    -- Approval
    package_lead_id UUID REFERENCES users(id),
    qa_approver_id UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,
    approved_by UUID REFERENCES users(id),
    effective_date DATE,
    signature_id UUID REFERENCES electronic_signatures(id),
    -- Completeness metrics (auto-computed)
    total_documents INT NOT NULL DEFAULT 0,
    documents_approved INT NOT NULL DEFAULT 0,
    documents_in_review INT NOT NULL DEFAULT 0,
    documents_draft INT NOT NULL DEFAULT 0,
    documents_missing INT NOT NULL DEFAULT 0,
    is_complete BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

CREATE TABLE validation_package_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES validation_packages(id),
    document_id UUID REFERENCES documents(id),      -- NULL if document not yet created
    role VARCHAR(100) NOT NULL,
    -- validation_plan | risk_assessment | urs | functional_spec | design_spec
    -- iq_protocol | iq_execution | oq_protocol | oq_execution
    -- pq_protocol | pq_execution | uat_protocol | uat_execution
    -- csa_assessment | traceability_matrix | validation_summary
    -- change_record | deviation_record | supporting_doc
    is_required BOOLEAN NOT NULL DEFAULT TRUE,
    status VARCHAR(50) NOT NULL DEFAULT 'not_started',
    -- not_started | draft | in_review | approved | not_applicable
    notes TEXT,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Package version history with release notes
CREATE TABLE validation_package_releases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES validation_packages(id),
    version VARCHAR(20) NOT NULL,
    release_date DATE NOT NULL,
    release_type VARCHAR(50) NOT NULL DEFAULT 'minor',
    -- major (re-execute required) | minor (no re-execution) | administrative
    release_summary TEXT NOT NULL,
    documents_added TEXT,                           -- JSON: [{doc_ref, doc_title, role}]
    documents_updated TEXT,                         -- JSON: [{doc_ref, old_version, new_version, change_summary}]
    documents_removed TEXT,                         -- JSON: [{doc_ref, reason}]
    validation_impact_assessment TEXT NOT NULL,
    requires_re_execution BOOLEAN NOT NULL DEFAULT FALSE,
    re_execution_scope TEXT,                        -- If re_execution required: what needs to run
    linked_change_request_ids TEXT,                 -- JSON: [cr_ref, ...]
    regulatory_notification_required BOOLEAN NOT NULL DEFAULT FALSE,
    regulatory_filing_ref VARCHAR(255),
    prepared_by UUID REFERENCES users(id),
    approved_by UUID REFERENCES users(id),
    signature_id UUID REFERENCES electronic_signatures(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    UNIQUE (package_id, version)
);

-- Transmission record: who received the package
CREATE TABLE validation_package_transmissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES validation_packages(id),
    version VARCHAR(20) NOT NULL,
    transmitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    transmitted_by UUID REFERENCES users(id),
    transmission_method VARCHAR(100) NOT NULL,
    -- electronic_system | email | printed | regulatory_submission | courier
    recipient_name VARCHAR(255) NOT NULL,
    recipient_role VARCHAR(255),
    recipient_organization VARCHAR(255),
    recipient_email VARCHAR(255),
    controlled_copy_number INT,                     -- For printed copies
    notes TEXT,
    acknowledgment_received BOOLEAN NOT NULL DEFAULT FALSE,
    acknowledgment_date DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SECTION 7: DOCUMENT CONCURRENT EDITING SESSIONS
-- Tracks who is currently editing which document to prevent conflicts.
-- ============================================================

CREATE TABLE document_edit_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    user_id UUID NOT NULL REFERENCES users(id),
    session_token VARCHAR(255) NOT NULL UNIQUE,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_heartbeat_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    current_block_id UUID REFERENCES document_blocks(id),
    -- If another user is editing the same block
    conflict_detected BOOLEAN NOT NULL DEFAULT FALSE
);

-- ============================================================
-- SECTION 8: DOCUMENT COMMENTS (REVIEW ANNOTATIONS DETAIL)
-- Per-block comments during the review cycle.
-- The document_annotations table in Part 7 handles text highlights.
-- This table handles block-level comments with threading.
-- ============================================================

CREATE TABLE document_review_comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES documents(id),
    version_id UUID NOT NULL REFERENCES document_versions(id),
    block_id UUID REFERENCES document_blocks(id),   -- NULL = document-level comment
    step_id UUID REFERENCES document_block_execution_steps(id),
    review_assignment_id UUID REFERENCES document_reviews(id),
    comment_type VARCHAR(50) NOT NULL DEFAULT 'comment',
    -- comment | question | correction | critical | redline | regulatory_concern
    comment_text TEXT NOT NULL,
    -- For redlines: what text should be replaced with what
    redline_original_text TEXT,
    redline_proposed_text TEXT,
    -- Resolution
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_by UUID REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolution_action VARCHAR(50),
    -- accepted | rejected | noted | superseded_by_other_comment
    resolution_note TEXT,
    -- Threading
    parent_comment_id UUID REFERENCES document_review_comments(id),
    author_id UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SECTION 9: DOCUMENT AI ASSISTANCE LOG
-- All AI-generated content suggestions specific to documents.
-- Complements the global ai_suggestions table in Part 3.
-- ============================================================

CREATE TABLE document_ai_interactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID REFERENCES documents(id),
    template_id UUID REFERENCES document_templates(id),
    block_id UUID REFERENCES document_blocks(id),
    interaction_type VARCHAR(100) NOT NULL,
    -- draft_generation | test_step_generation | gap_analysis | acceptance_criteria
    -- video_to_script | natural_language_to_step | completeness_score
    -- regulatory_citation | requirement_tracing | document_comparison
    prompt_description TEXT NOT NULL,               -- What the user asked for
    model_version VARCHAR(50),
    tokens_used INT,
    suggested_content TEXT,                         -- The AI's output
    confidence_score DECIMAL(5,4),
    -- User action
    accepted BOOLEAN,
    accepted_at TIMESTAMPTZ,
    accepted_by UUID REFERENCES users(id),
    modification_before_accept TEXT,                -- What user changed
    dismissed_reason VARCHAR(255),
    -- Compliance metadata
    human_review_confirmed BOOLEAN NOT NULL DEFAULT FALSE,
    ai_assisted_label_shown BOOLEAN NOT NULL DEFAULT TRUE,
    interaction_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    user_id UUID REFERENCES users(id)
);

-- ============================================================
-- SECTION 10: TEMPLATE SYSTEM IMPROVEMENTS
-- Replace the basic document_templates with a richer version.
-- Add template block definitions.
-- ============================================================

-- Template block instances (the pre-configured blocks in a template)
CREATE TABLE template_blocks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_id UUID NOT NULL REFERENCES document_templates(id),
    block_type VARCHAR(100) NOT NULL,
    section_path VARCHAR(255),                      -- e.g., "3" or "3.2"
    sort_order INT NOT NULL DEFAULT 0,
    heading_level INT,                              -- For heading blocks
    heading_text VARCHAR(512),                      -- Default heading text
    -- Content configuration
    content_mode VARCHAR(50) NOT NULL DEFAULT 'pre_populated',
    -- pre_populated: content set in template, copied to document as-is
    -- fill_on_creation: user fills when creating the document
    -- fill_on_execution: user fills during protocol execution
    -- auto_populated: system fills from linked data/variables
    content TEXT,                                   -- Pre-populated content (TipTap JSON)
    config TEXT,                                    -- Block configuration (table columns, etc.)
    fill_prompt TEXT,                               -- Guidance shown to user when filling
    fill_is_required BOOLEAN NOT NULL DEFAULT FALSE,
    library_block_id UUID REFERENCES block_library(id),
    is_locked BOOLEAN NOT NULL DEFAULT FALSE,       -- Cannot be modified in document instances
    conditional_show_if TEXT,                       -- JSON condition
    variable_bindings TEXT,                         -- JSON: {placeholder: source_key}
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    updated_by UUID REFERENCES users(id)
);

-- Add columns to document_templates for richer config
ALTER TABLE document_templates
    ADD COLUMN IF NOT EXISTS layout_config_id UUID REFERENCES document_layout_configs(id),
    ADD COLUMN IF NOT EXISTS section_numbering_format VARCHAR(50) DEFAULT 'numeric',
    -- numeric (1.1.1) | alpha (A.1.a) | roman (I.A.1)
    ADD COLUMN IF NOT EXISTS toc_enabled BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS revision_history_enabled BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS watermark_draft VARCHAR(50) DEFAULT 'DRAFT',
    ADD COLUMN IF NOT EXISTS document_type_prefix VARCHAR(20),
    -- SOP | IQ | OQ | PQ | UAT | DQ | CS | FS | DS | URS | CAPA | etc.
    ADD COLUMN IF NOT EXISTS approval_stage_count INT DEFAULT 2,
    ADD COLUMN IF NOT EXISTS requires_qa_approval BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS review_interval_months INT DEFAULT 24,
    ADD COLUMN IF NOT EXISTS regulatory_framework TEXT,
    -- JSON: ["21 CFR Part 11", "EU Annex 11", "GAMP 5"]
    ADD COLUMN IF NOT EXISTS ai_generation_supported BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS template_category VARCHAR(100) DEFAULT 'protocol';
    -- protocol | sop | specification | report | plan | assessment

-- ============================================================
-- SECTION 11: INDEXES
-- ============================================================

CREATE INDEX idx_doc_layout_configs_site ON document_layout_configs (site_id);
CREATE INDEX idx_block_library_site ON block_library (site_id, status);
CREATE INDEX idx_block_library_type ON block_library (block_type, category);
CREATE INDEX idx_document_blocks_version ON document_blocks (version_id, sort_order);
CREATE INDEX idx_document_blocks_type ON document_blocks (block_type);
CREATE INDEX idx_document_blocks_locked ON document_blocks (is_locked, version_id);
CREATE INDEX idx_block_exec_steps_block ON document_block_execution_steps (block_id, step_number);
CREATE INDEX idx_block_exec_steps_result ON document_block_execution_steps (pass_fail);
CREATE INDEX idx_block_attachments_step ON block_step_attachments (step_id);
CREATE INDEX idx_form_fields_block ON document_form_fields (block_id, sort_order);
CREATE INDEX idx_form_field_values_doc ON document_form_field_values (document_id, version_id);
CREATE INDEX idx_flowchart_diagrams_block ON flowchart_diagrams (block_id);
CREATE INDEX idx_flowchart_shapes_diagram ON flowchart_shapes (diagram_id);
CREATE INDEX idx_flowchart_connections_diagram ON flowchart_connections (diagram_id);
CREATE INDEX idx_val_packages_site ON validation_packages (site_id, status);
CREATE INDEX idx_val_packages_system ON validation_packages (system_id);
CREATE INDEX idx_val_package_items_package ON validation_package_items (package_id, sort_order);
CREATE INDEX idx_val_package_releases ON validation_package_releases (package_id);
CREATE INDEX idx_val_package_transmissions ON validation_package_transmissions (package_id);
CREATE INDEX idx_doc_edit_sessions_active ON document_edit_sessions (document_id, is_active);
CREATE INDEX idx_doc_review_comments_doc ON document_review_comments (document_id, version_id);
CREATE INDEX idx_doc_review_comments_block ON document_review_comments (block_id, is_resolved);
CREATE INDEX idx_doc_ai_interactions_doc ON document_ai_interactions (document_id);
CREATE INDEX idx_template_blocks_template ON template_blocks (template_id, sort_order);

-- ============================================================
-- FINAL COUNT
-- ============================================================
SELECT
    COUNT(*) AS total_tables,
    'All tables across Parts 1-8' AS note
FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';
