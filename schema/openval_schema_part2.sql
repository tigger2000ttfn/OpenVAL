-- ============================================================
-- OpenVAL Schema - Part 2: Indexes, Sequences, RLS, and Seed Data
-- ============================================================

-- ============================================================
-- SEQUENCES (for human-readable reference numbers)
-- ============================================================

CREATE SEQUENCE seq_system_ref START 1;
CREATE SEQUENCE seq_equipment_ref START 1;
CREATE SEQUENCE seq_risk_assessment_ref START 1;
CREATE SEQUENCE seq_requirement_set_ref START 1;
CREATE SEQUENCE seq_protocol_ref START 1;
CREATE SEQUENCE seq_test_execution_ref START 1;
CREATE SEQUENCE seq_deviation_ref START 1;
CREATE SEQUENCE seq_document_ref START 1;
CREATE SEQUENCE seq_change_request_ref START 1;
CREATE SEQUENCE seq_capa_ref START 1;
CREATE SEQUENCE seq_nc_ref START 1;
CREATE SEQUENCE seq_periodic_review_ref START 1;
CREATE SEQUENCE seq_traceability_matrix_ref START 1;
CREATE SEQUENCE seq_vendor_ref START 1;
CREATE SEQUENCE seq_vendor_qualification_ref START 1;
CREATE SEQUENCE seq_vendor_audit_ref START 1;
CREATE SEQUENCE seq_audit_ref START 1;
CREATE SEQUENCE seq_audit_finding_ref START 1;
CREATE SEQUENCE seq_training_ref START 1;
CREATE SEQUENCE seq_report_ref START 1;
CREATE SEQUENCE seq_workflow_ref START 1;
CREATE SEQUENCE seq_workflow_instance_ref START 1;
CREATE SEQUENCE seq_form_ref START 1;
CREATE SEQUENCE seq_form_submission_ref START 1;
CREATE SEQUENCE seq_signature_id START 1;
CREATE SEQUENCE seq_audit_event_id START 1;
CREATE SEQUENCE seq_file_ref START 1;
CREATE SEQUENCE seq_change_task_ref START 1;
CREATE SEQUENCE seq_calibration_ref START 1;
CREATE SEQUENCE seq_maintenance_ref START 1;

-- ============================================================
-- INDEXES
-- ============================================================

-- Audit log (most critical - queried constantly)
CREATE INDEX idx_audit_log_table_record ON audit_log (table_name, record_id);
CREATE INDEX idx_audit_log_timestamp ON audit_log (timestamp DESC);
CREATE INDEX idx_audit_log_user_id ON audit_log (user_id);
CREATE INDEX idx_audit_log_action ON audit_log (action);
CREATE INDEX idx_audit_log_module ON audit_log (module);
CREATE INDEX idx_audit_log_parent ON audit_log (parent_table, parent_record_id);

-- Audit integrity chain
CREATE INDEX idx_audit_integrity_log_id ON audit_log_integrity (audit_log_id);

-- Electronic signatures
CREATE INDEX idx_esig_table_record ON electronic_signatures (table_name, record_id);
CREATE INDEX idx_esig_signer_id ON electronic_signatures (signer_id);
CREATE INDEX idx_esig_signed_at ON electronic_signatures (signed_at DESC);
CREATE INDEX idx_esig_valid ON electronic_signatures (is_valid);

-- Users
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_username ON users (username);
CREATE INDEX idx_users_site ON users (site_id);
CREATE INDEX idx_users_department ON users (department_id);
CREATE INDEX idx_users_active ON users (is_active);

-- User sessions
CREATE INDEX idx_sessions_user ON user_sessions (user_id);
CREATE INDEX idx_sessions_token ON user_sessions (session_token);
CREATE INDEX idx_sessions_expires ON user_sessions (expires_at);

-- Login attempts
CREATE INDEX idx_login_attempts_ip ON login_attempts (ip_address, attempted_at DESC);
CREATE INDEX idx_login_attempts_user ON login_attempts (username_attempted, attempted_at DESC);

-- Systems
CREATE INDEX idx_systems_site ON systems (site_id);
CREATE INDEX idx_systems_status ON systems (status);
CREATE INDEX idx_systems_validated_status ON systems (validated_status);
CREATE INDEX idx_systems_gamp ON systems (gamp_category);
CREATE INDEX idx_systems_review_date ON systems (next_periodic_review_date);
CREATE INDEX idx_systems_business_owner ON systems (business_owner_id);
CREATE INDEX idx_systems_technical_owner ON systems (technical_owner_id);

-- Equipment
CREATE INDEX idx_equipment_site ON equipment (site_id);
CREATE INDEX idx_equipment_status ON equipment (status);
CREATE INDEX idx_equipment_calibration_due ON equipment (next_calibration_date);
CREATE INDEX idx_equipment_maintenance_due ON equipment (next_maintenance_date);

-- Risk assessments
CREATE INDEX idx_risk_assessments_system ON risk_assessments (system_id);
CREATE INDEX idx_risk_assessments_status ON risk_assessments (status);
CREATE INDEX idx_risk_items_assessment ON risk_items (assessment_id);
CREATE INDEX idx_risk_items_status ON risk_items (status);

-- Requirements
CREATE INDEX idx_req_sets_system ON requirement_sets (system_id);
CREATE INDEX idx_req_sets_status ON requirement_sets (status);
CREATE INDEX idx_requirements_set ON requirements (set_id);
CREATE INDEX idx_requirements_parent ON requirements (parent_req_id);
CREATE INDEX idx_requirements_status ON requirements (status);
CREATE INDEX idx_requirements_gxp ON requirements (gxp_critical);

-- Protocols
CREATE INDEX idx_protocols_system ON protocols (system_id);
CREATE INDEX idx_protocols_equipment ON protocols (equipment_id);
CREATE INDEX idx_protocols_type ON protocols (protocol_type);
CREATE INDEX idx_protocols_status ON protocols (status);
CREATE INDEX idx_protocol_sections_protocol ON protocol_sections (protocol_id);
CREATE INDEX idx_protocol_steps_protocol ON protocol_steps (protocol_id);
CREATE INDEX idx_protocol_steps_section ON protocol_steps (section_id);

-- Test executions
CREATE INDEX idx_executions_protocol ON test_executions (protocol_id);
CREATE INDEX idx_executions_status ON test_executions (status);
CREATE INDEX idx_executions_executed_by ON test_executions (executed_by);
CREATE INDEX idx_execution_steps_execution ON test_execution_steps (execution_id);
CREATE INDEX idx_execution_steps_step ON test_execution_steps (step_id);
CREATE INDEX idx_execution_steps_status ON test_execution_steps (status);

-- Deviations
CREATE INDEX idx_deviations_execution ON deviations (execution_id);
CREATE INDEX idx_deviations_protocol ON deviations (protocol_id);
CREATE INDEX idx_deviations_system ON deviations (system_id);
CREATE INDEX idx_deviations_status ON deviations (status);
CREATE INDEX idx_deviations_severity ON deviations (severity);
CREATE INDEX idx_deviations_capa ON deviations (capa_id);

-- Documents
CREATE INDEX idx_documents_site ON documents (site_id);
CREATE INDEX idx_documents_category ON documents (category_id);
CREATE INDEX idx_documents_status ON documents (status);
CREATE INDEX idx_documents_review_date ON documents (next_review_date);
CREATE INDEX idx_documents_system ON documents (system_id);
CREATE INDEX idx_doc_versions_document ON document_versions (document_id);
CREATE INDEX idx_doc_versions_status ON document_versions (status);
CREATE INDEX idx_doc_approvals_version ON document_approvals (version_id);
CREATE INDEX idx_doc_approvals_approver ON document_approvals (approver_id, status);
CREATE INDEX idx_doc_reviews_version ON document_reviews (version_id);
CREATE INDEX idx_doc_reviews_reviewer ON document_reviews (reviewer_id, status);

-- Workflow
CREATE INDEX idx_wf_definitions_type ON workflow_definitions (trigger_object_type);
CREATE INDEX idx_wf_instances_object ON workflow_instances (object_type, object_id);
CREATE INDEX idx_wf_instances_status ON workflow_instances (status);
CREATE INDEX idx_wf_instance_stages_instance ON workflow_instance_stages (instance_id);
CREATE INDEX idx_wf_instance_stages_assigned ON workflow_instance_stages (assigned_to, status);
CREATE INDEX idx_wf_instance_stages_due ON workflow_instance_stages (due_at);

-- Notifications
CREATE INDEX idx_notifications_recipient ON notifications (recipient_id);
CREATE INDEX idx_notifications_read ON notifications (recipient_id, is_read);
CREATE INDEX idx_notifications_object ON notifications (object_type, object_id);
CREATE INDEX idx_notifications_created ON notifications (created_at DESC);

-- Change control
CREATE INDEX idx_cr_site ON change_requests (site_id);
CREATE INDEX idx_cr_status ON change_requests (status);
CREATE INDEX idx_cr_requestor ON change_requests (requestor_id);
CREATE INDEX idx_cr_implementation_date ON change_requests (proposed_implementation_date);
CREATE INDEX idx_change_tasks_cr ON change_tasks (cr_id);
CREATE INDEX idx_change_tasks_assigned ON change_tasks (assigned_to, status);

-- CAPA
CREATE INDEX idx_capas_site ON capas (site_id);
CREATE INDEX idx_capas_status ON capas (status);
CREATE INDEX idx_capas_owner ON capas (owner_id);
CREATE INDEX idx_capas_due_date ON capas (target_completion_date);
CREATE INDEX idx_capa_actions_capa ON capa_actions (capa_id);
CREATE INDEX idx_capa_actions_responsible ON capa_actions (responsible_id, status);

-- Nonconformances
CREATE INDEX idx_nc_site ON nonconformances (site_id);
CREATE INDEX idx_nc_status ON nonconformances (status);
CREATE INDEX idx_nc_system ON nonconformances (affected_system_id);
CREATE INDEX idx_nc_reported_at ON nonconformances (reported_at DESC);

-- Periodic reviews
CREATE INDEX idx_pr_schedules_object ON periodic_review_schedules (object_type, object_id);
CREATE INDEX idx_pr_schedules_next_date ON periodic_review_schedules (next_review_date);
CREATE INDEX idx_periodic_reviews_status ON periodic_reviews (status);
CREATE INDEX idx_periodic_reviews_schedule ON periodic_reviews (schedule_id);
CREATE INDEX idx_pr_items_review ON periodic_review_items (review_id);

-- Traceability
CREATE INDEX idx_traceability_source ON traceability_links (source_type, source_id);
CREATE INDEX idx_traceability_target ON traceability_links (target_type, target_id);

-- Vendors and audits
CREATE INDEX idx_vendors_status ON vendors (qualification_status);
CREATE INDEX idx_vendor_audits_vendor ON vendor_audits (vendor_id);
CREATE INDEX idx_audits_site ON audits (site_id);
CREATE INDEX idx_audits_status ON audits (status);
CREATE INDEX idx_audit_findings_audit ON audit_findings (audit_id);
CREATE INDEX idx_audit_findings_status ON audit_findings (status);
CREATE INDEX idx_audit_findings_capa ON audit_findings (capa_id);

-- Training
CREATE INDEX idx_training_assignments_user ON training_assignments (user_id, status);
CREATE INDEX idx_training_assignments_due ON training_assignments (due_date);
CREATE INDEX idx_training_records_user ON training_records (user_id);
CREATE INDEX idx_training_records_requirement ON training_records (requirement_id);

-- File management
CREATE INDEX idx_file_attachments_object ON file_attachments (object_type, object_id);
CREATE INDEX idx_file_access_log_file ON file_access_log (file_id);
CREATE INDEX idx_file_access_log_user ON file_access_log (user_id);

-- Object tags
CREATE INDEX idx_object_tags_object ON object_tags (object_type, object_id);
CREATE INDEX idx_object_tags_tag ON object_tags (tag_id);

-- Full-text search indexes (pg_trgm)
CREATE INDEX idx_systems_name_trgm ON systems USING gin (name gin_trgm_ops);
CREATE INDEX idx_documents_title_trgm ON documents USING gin (title gin_trgm_ops);
CREATE INDEX idx_protocols_title_trgm ON protocols USING gin (title gin_trgm_ops);
CREATE INDEX idx_requirements_title_trgm ON requirements USING gin (title gin_trgm_ops);
CREATE INDEX idx_capas_title_trgm ON capas USING gin (title gin_trgm_ops);
CREATE INDEX idx_change_requests_title_trgm ON change_requests USING gin (title gin_trgm_ops);

-- ============================================================
-- ROW-LEVEL SECURITY: APPEND-ONLY ENFORCEMENT
-- ============================================================

-- Prevent any UPDATE or DELETE on audit_log at the database level
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_log_select ON audit_log FOR SELECT USING (true);
CREATE POLICY audit_log_insert ON audit_log FOR INSERT WITH CHECK (true);
-- No UPDATE policy = no updates permitted
-- No DELETE policy = no deletes permitted

ALTER TABLE audit_log_integrity ENABLE ROW LEVEL SECURITY;
CREATE POLICY audit_integrity_select ON audit_log_integrity FOR SELECT USING (true);
CREATE POLICY audit_integrity_insert ON audit_log_integrity FOR INSERT WITH CHECK (true);

ALTER TABLE electronic_signatures ENABLE ROW LEVEL SECURITY;
CREATE POLICY esig_select ON electronic_signatures FOR SELECT USING (true);
CREATE POLICY esig_insert ON electronic_signatures FOR INSERT WITH CHECK (true);
-- Signatures are never updated. Invalidation is a new record + a flag via a separate UPDATE
-- that is itself audit-logged.

-- ============================================================
-- FUNCTIONS AND TRIGGERS
-- ============================================================

-- Auto-update updated_at on all tables that have it
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at trigger to all relevant tables
DO $$
DECLARE
    t TEXT;
BEGIN
    FOR t IN
        SELECT table_name
        FROM information_schema.columns
        WHERE column_name = 'updated_at'
          AND table_schema = 'public'
    LOOP
        EXECUTE format(
            'CREATE TRIGGER trg_updated_at_%s
             BEFORE UPDATE ON %I
             FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at()',
            t, t
        );
    END LOOP;
END;
$$;

-- Function: generate human-readable reference IDs
CREATE OR REPLACE FUNCTION generate_ref(prefix TEXT, seq_name TEXT, pad INT DEFAULT 4)
RETURNS TEXT AS $$
BEGIN
    RETURN prefix || '-' || LPAD(nextval(seq_name::regclass)::TEXT, pad, '0');
END;
$$ LANGUAGE plpgsql;

-- Function: compute risk score and level from matrix
CREATE OR REPLACE FUNCTION compute_risk_level(
    probability INT,
    impact INT,
    matrix_id UUID
) RETURNS TABLE (score INT, level VARCHAR) AS $$
DECLARE
    thresholds TEXT;
    threshold_record JSONB;
BEGIN
    SELECT risk_thresholds INTO thresholds FROM risk_matrices WHERE id = matrix_id;

    score := probability * impact;

    FOR threshold_record IN SELECT * FROM jsonb_array_elements(thresholds::jsonb)
    LOOP
        IF score >= (threshold_record->>'min_score')::INT
           AND score <= (threshold_record->>'max_score')::INT THEN
            level := threshold_record->>'level';
            RETURN NEXT;
            RETURN;
        END IF;
    END LOOP;

    level := 'unknown';
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Function: get traceability coverage for a system
CREATE OR REPLACE FUNCTION get_traceability_coverage(p_system_id UUID)
RETURNS TABLE (
    total_requirements INT,
    requirements_with_links INT,
    coverage_pct DECIMAL
) AS $$
BEGIN
    SELECT
        COUNT(r.id)::INT,
        COUNT(tl.source_id)::INT,
        CASE
            WHEN COUNT(r.id) = 0 THEN 0
            ELSE ROUND((COUNT(tl.source_id)::DECIMAL / COUNT(r.id)) * 100, 2)
        END
    INTO total_requirements, requirements_with_links, coverage_pct
    FROM requirements r
    JOIN requirement_sets rs ON r.set_id = rs.id
    LEFT JOIN traceability_links tl ON tl.source_id = r.id AND tl.source_type = 'requirement'
    WHERE rs.system_id = p_system_id
      AND r.status != 'deprecated';

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Function: check if a user has a specific permission
CREATE OR REPLACE FUNCTION user_has_permission(
    p_user_id UUID,
    p_module TEXT,
    p_action TEXT,
    p_resource TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
    has_perm BOOLEAN := FALSE;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN role_permissions rp ON rp.role_id = ur.role_id
        JOIN permissions p ON p.id = rp.permission_id
        WHERE ur.user_id = p_user_id
          AND (ur.expires_at IS NULL OR ur.expires_at > NOW())
          AND p.module = p_module
          AND p.action = p_action
          AND (p_resource IS NULL OR p.resource = p_resource OR p.resource IS NULL)
    ) INTO has_perm;

    RETURN has_perm;
END;
$$ LANGUAGE plpgsql;

-- View: overdue_items (dashboard quick view)
CREATE OR REPLACE VIEW v_overdue_items AS
SELECT
    'periodic_review' AS item_type,
    pr.id AS item_id,
    prs.object_type AS context,
    prs.object_id AS context_id,
    'Periodic review overdue' AS description,
    prs.next_review_date AS due_date,
    prs.reviewer_id AS owner_id,
    prs.site_id
FROM periodic_review_schedules prs
LEFT JOIN periodic_reviews pr ON pr.schedule_id = prs.id AND pr.status NOT IN ('completed','waived')
WHERE prs.is_active = TRUE AND prs.next_review_date < NOW()

UNION ALL

SELECT
    'capa_action' AS item_type,
    ca.id,
    'capa' AS context,
    ca.capa_id,
    'CAPA action overdue: ' || ca.title,
    ca.target_date,
    ca.responsible_id,
    c.site_id
FROM capa_actions ca
JOIN capas c ON c.id = ca.capa_id
WHERE ca.status NOT IN ('completed','cancelled')
  AND ca.target_date < NOW()

UNION ALL

SELECT
    'workflow_stage' AS item_type,
    wis.id,
    'workflow_instance',
    wis.instance_id,
    'Workflow task overdue',
    wis.due_at::DATE,
    wis.assigned_to,
    wd.site_id
FROM workflow_instance_stages wis
JOIN workflow_instances wi ON wi.id = wis.instance_id
JOIN workflow_definitions wd ON wd.id = wi.definition_id
WHERE wis.status IN ('pending','in_progress')
  AND wis.due_at < NOW()

UNION ALL

SELECT
    'document_review' AS item_type,
    d.id,
    'document',
    d.id,
    'Document overdue for review: ' || d.doc_ref,
    d.next_review_date,
    d.owner_id,
    d.site_id
FROM documents d
WHERE d.status = 'effective'
  AND d.next_review_date < NOW()

UNION ALL

SELECT
    'calibration_due' AS item_type,
    e.id,
    'equipment',
    e.id,
    'Calibration overdue: ' || e.name,
    e.next_calibration_date,
    e.owner_id,
    e.site_id
FROM equipment e
WHERE e.calibration_required = TRUE
  AND e.status = 'active'
  AND e.next_calibration_date < NOW();

-- View: system_validation_status (compliance dashboard)
CREATE OR REPLACE VIEW v_system_validation_status AS
SELECT
    s.id,
    s.site_id,
    s.system_ref,
    s.name,
    s.gamp_category,
    s.gxp_relevant,
    s.validated_status,
    s.status,
    s.next_periodic_review_date,
    s.revalidation_due_date,
    s.business_owner_id,
    s.technical_owner_id,
    s.qa_owner_id,
    (SELECT COUNT(*) FROM protocols p WHERE p.system_id = s.id AND p.status = 'executed') AS executed_protocols,
    (SELECT COUNT(*) FROM protocols p WHERE p.system_id = s.id AND p.status IN ('draft','in_review','approved')) AS pending_protocols,
    (SELECT COUNT(*) FROM deviations d WHERE d.system_id = s.id AND d.status = 'open') AS open_deviations,
    (SELECT COUNT(*) FROM change_requests cr WHERE s.id = ANY(ARRAY(SELECT jsonb_array_elements_text(cr.affected_systems::jsonb))::UUID[]) AND cr.status NOT IN ('closed','cancelled')) AS active_changes
FROM systems s;

-- View: my_tasks (per-user task view)
CREATE OR REPLACE VIEW v_my_tasks AS
SELECT
    wis.id AS task_id,
    wis.assigned_to AS user_id,
    ws.name AS stage_name,
    ws.stage_type,
    wi.object_type,
    wi.object_id,
    wd.name AS workflow_name,
    wis.due_at,
    wis.status,
    wis.assigned_at,
    CASE
        WHEN wis.due_at < NOW() AND wis.status IN ('pending','in_progress') THEN TRUE
        ELSE FALSE
    END AS is_overdue,
    wi.instance_ref
FROM workflow_instance_stages wis
JOIN workflow_instances wi ON wi.id = wis.instance_id
JOIN workflow_stages ws ON ws.id = wis.stage_id
JOIN workflow_definitions wd ON wd.id = wi.definition_id
WHERE wis.status IN ('pending','in_progress');

-- View: document_pending_approvals
CREATE OR REPLACE VIEW v_document_pending_approvals AS
SELECT
    da.id AS approval_id,
    da.approver_id,
    da.approver_role,
    da.sequence_number,
    da.status,
    da.due_date,
    da.assigned_at,
    dv.id AS version_id,
    dv.version_number,
    d.id AS document_id,
    d.doc_ref,
    d.title,
    d.site_id,
    CASE WHEN da.due_date < NOW() THEN TRUE ELSE FALSE END AS is_overdue
FROM document_approvals da
JOIN document_versions dv ON dv.id = da.version_id
JOIN documents d ON d.id = dv.document_id
WHERE da.status = 'pending';

-- View: training_compliance_matrix
CREATE OR REPLACE VIEW v_training_compliance AS
SELECT
    ta.user_id,
    u.full_name AS user_full_name,
    u.department_id,
    tr_req.id AS requirement_id,
    tr_req.name AS requirement_name,
    tr_req.frequency,
    ta.status AS assignment_status,
    ta.due_date,
    rec.completion_date,
    rec.expiry_date,
    CASE
        WHEN rec.expiry_date IS NOT NULL AND rec.expiry_date < NOW() THEN 'expired'
        WHEN ta.status = 'completed' THEN 'current'
        WHEN ta.due_date < NOW() THEN 'overdue'
        ELSE ta.status
    END AS compliance_status
FROM training_assignments ta
JOIN users u ON u.id = ta.user_id
JOIN training_requirements tr_req ON tr_req.id = ta.requirement_id
LEFT JOIN training_records rec ON rec.assignment_id = ta.id
WHERE u.is_active = TRUE;

-- ============================================================
-- SEED DATA: SIGNATURE MEANINGS
-- ============================================================

INSERT INTO signature_meanings (id, code, display_name, description, regulatory_citation, applicable_modules, requires_mfa, is_active)
VALUES
    (uuid_generate_v4(), 'AUTHORED', 'I am the author of this record', 'Confirms the signer is the original author and the content is accurate', '21 CFR 11.50(a)', '["documents","protocols","requirements"]', false, true),
    (uuid_generate_v4(), 'REVIEWED', 'I have reviewed this record and find it acceptable', 'Technical or quality review approval', '21 CFR 11.50(a)', '["documents","protocols","risk_assessments","change_requests"]', false, true),
    (uuid_generate_v4(), 'APPROVED', 'I approve this record for its intended use', 'Final approval for a controlled record to take effect', '21 CFR 11.50(a)', '["documents","protocols","risk_assessments","change_requests","capas"]', true, true),
    (uuid_generate_v4(), 'EXECUTED', 'I performed this test step and recorded the actual result', 'Execution of a test protocol step', '21 CFR 11.50(a)', '["test_executions"]', false, true),
    (uuid_generate_v4(), 'WITNESSED', 'I witnessed the execution of this test step', 'Independent witness to a test step execution', '21 CFR 11.50(a)', '["test_executions"]', false, true),
    (uuid_generate_v4(), 'VERIFIED', 'I have verified the accuracy and completeness of this record', 'Quality verification of a completed record', '21 CFR 11.50(a)', '["test_executions","deviations","capas"]', false, true),
    (uuid_generate_v4(), 'READ_CONFIRMED', 'I confirm I have read and understood this document', 'Document read and understand confirmation', '21 CFR 11.50(a)', '["documents"]', false, true),
    (uuid_generate_v4(), 'CLOSED', 'I authorize the closure of this record', 'Closure of a CAPA, deviation, or nonconformance', '21 CFR 11.50(a)', '["capas","deviations","nonconformances","change_requests"]', true, true),
    (uuid_generate_v4(), 'QA_APPROVED', 'Quality Assurance approval', 'Specific QA department approval for GxP-critical records', '21 CFR 11.50(a)', '["documents","protocols","change_requests","capas"]', true, true),
    (uuid_generate_v4(), 'DELEGATED_APPROVED', 'Approved on behalf of (delegated authority)', 'Approval made under documented delegation of authority', '21 CFR 11.50(a)', '["documents","protocols","change_requests"]', true, true);

-- ============================================================
-- SEED DATA: LOOKUP CATEGORIES AND VALUES
-- ============================================================

INSERT INTO lookup_categories (id, code, display_name, description, is_system) VALUES
    (uuid_generate_v4(), 'GAMP_CATEGORY', 'GAMP 5 Categories', 'GAMP 5 software category classifications', true),
    (uuid_generate_v4(), 'SYSTEM_TYPE', 'System Types', 'Types of computerized systems', true),
    (uuid_generate_v4(), 'HOSTING_TYPE', 'Hosting Types', 'Infrastructure hosting classifications', true),
    (uuid_generate_v4(), 'VALIDATION_STATUS', 'Validation Status', 'Validation lifecycle status values', true),
    (uuid_generate_v4(), 'VALIDATION_BASIS', 'Validation Basis', 'Basis for system validation approach', true),
    (uuid_generate_v4(), 'RISK_LEVEL', 'Risk Levels', 'Risk classification levels', true),
    (uuid_generate_v4(), 'SEVERITY', 'Severity Levels', 'Severity classifications for deviations, findings, etc.', true),
    (uuid_generate_v4(), 'PROTOCOL_TYPE', 'Protocol Types', 'Validation protocol type classifications', true),
    (uuid_generate_v4(), 'DOCUMENT_TYPE', 'Document Types', 'Types of controlled documents', true),
    (uuid_generate_v4(), 'CHANGE_TYPE', 'Change Types', 'Classifications for change requests', true),
    (uuid_generate_v4(), 'CHANGE_CATEGORY', 'Change Categories', 'Categories of change activity', true),
    (uuid_generate_v4(), 'VALIDATION_IMPACT', 'Validation Impact', 'Impact of a change on validated state', true),
    (uuid_generate_v4(), 'CAPA_TYPE', 'CAPA Types', 'Corrective and preventive action types', true),
    (uuid_generate_v4(), 'CAPA_SOURCE', 'CAPA Sources', 'Source of a CAPA initiation', true),
    (uuid_generate_v4(), 'ROOT_CAUSE_CATEGORY', 'Root Cause Categories', 'Categories for root cause classification', true),
    (uuid_generate_v4(), 'NC_TYPE', 'Nonconformance Types', 'Types of nonconformance events', true),
    (uuid_generate_v4(), 'DEVIATION_TYPE', 'Deviation Types', 'Types of test execution deviations', true),
    (uuid_generate_v4(), 'EQUIPMENT_TYPE', 'Equipment Types', 'Classification of equipment categories', true),
    (uuid_generate_v4(), 'VENDOR_TYPE', 'Vendor Types', 'Types of vendor or supplier', true),
    (uuid_generate_v4(), 'AUDIT_TYPE', 'Audit Types', 'Types of audits conducted', true),
    (uuid_generate_v4(), 'TRAINING_TYPE', 'Training Types', 'Types of training activities', true),
    (uuid_generate_v4(), 'TRAINING_FREQUENCY', 'Training Frequency', 'How often training must be repeated', true),
    (uuid_generate_v4(), 'REQ_TYPE', 'Requirement Types', 'Classification of requirement types', true),
    (uuid_generate_v4(), 'REQ_PRIORITY', 'Requirement Priority', 'Priority/criticality of requirements', true),
    (uuid_generate_v4(), 'ALCOA_ATTRIBUTE', 'ALCOA+ Attributes', 'Data integrity ALCOA+ principle attributes', true),
    (uuid_generate_v4(), 'GXP_IMPACT_AREA', 'GxP Impact Areas', 'Areas of GxP regulatory impact', true),
    (uuid_generate_v4(), 'APPLICABLE_REGULATION', 'Applicable Regulations', 'Regulatory frameworks that may apply to systems', true),
    (uuid_generate_v4(), 'DEPARTMENT_TYPE', 'Department Types', 'Functional department classifications', true),
    (uuid_generate_v4(), 'DATA_CLASSIFICATION', 'Data Classification', 'Sensitivity and criticality of data', true),
    (uuid_generate_v4(), 'REVIEW_OUTCOME', 'Periodic Review Outcomes', 'Possible outcomes of a periodic review', true);

-- GAMP Categories
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CAT_1', 'Category 1 - Infrastructure Software', 'Operating systems, database engines, network software. No configuration records required.', 10, true FROM lookup_categories WHERE code = 'GAMP_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CAT_3', 'Category 3 - Non-configured Software', 'Standard software products used without modification. Instruments, devices. Verification focus.', 20, true FROM lookup_categories WHERE code = 'GAMP_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CAT_4', 'Category 4 - Configured Software', 'Standard products configured to meet user requirements. LIMS, MES, ERP. Full IQ/OQ/PQ expected.', 30, true FROM lookup_categories WHERE code = 'GAMP_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CAT_5', 'Category 5 - Custom Software', 'Bespoke or custom-developed software. Full SDL, code review, and testing required.', 40, true FROM lookup_categories WHERE code = 'GAMP_CATEGORY';

-- Protocol Types
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'IQ', 'Installation Qualification', 'Verifies the system is installed correctly per approved specifications.', 10, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'OQ', 'Operational Qualification', 'Verifies the system operates as intended throughout its operating ranges.', 20, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PQ', 'Performance Qualification', 'Verifies the system performs consistently in the production environment.', 30, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'UAT', 'User Acceptance Testing', 'User-driven testing to confirm the system meets business requirements.', 40, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'MAV', 'Method/Analytical Validation', 'Validation of an analytical or test method.', 50, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'DQ', 'Design Qualification', 'Documents that the proposed design is suitable for intended purpose.', 60, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'FAT', 'Factory Acceptance Test', 'Testing performed at the vendor site prior to installation.', 70, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'SAT', 'Site Acceptance Test', 'Testing at the installation site following FAT.', 80, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'RETRO', 'Retrospective Assessment', 'Retrospective CSV assessment for legacy or already-deployed systems.', 90, true FROM lookup_categories WHERE code = 'PROTOCOL_TYPE';

-- Document Types
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'SOP', 'Standard Operating Procedure', 10, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'POL', 'Policy', 20, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'SPEC', 'Specification', 30, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'RPT', 'Report', 40, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'FORM', 'Form / Template', 50, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PLAN', 'Validation Plan', 60, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'URS', 'User Requirements Specification', 70, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'WI', 'Work Instruction', 80, true FROM lookup_categories WHERE code = 'DOCUMENT_TYPE';

-- Severity Levels
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CRITICAL', 'Critical', 'Potential patient safety risk, data integrity failure, or regulatory violation. Immediate action required.', 10, true FROM lookup_categories WHERE code = 'SEVERITY';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'MAJOR', 'Major', 'Significant impact to GxP data or process but not immediately life-threatening.', 20, true FROM lookup_categories WHERE code = 'SEVERITY';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'MINOR', 'Minor', 'Limited impact, correctable without significant risk.', 30, true FROM lookup_categories WHERE code = 'SEVERITY';

-- ALCOA+ Attributes
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ATTRIBUTABLE', 'Attributable', 'Who created or changed the record, and when', 10, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'LEGIBLE', 'Legible', 'The record is readable throughout its retention period', 20, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CONTEMPORANEOUS', 'Contemporaneous', 'Recorded at the time of activity', 30, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ORIGINAL', 'Original', 'First capture of information, or a certified copy', 40, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ACCURATE', 'Accurate', 'Correct and truthful', 50, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'COMPLETE', 'Complete', 'All data is present, nothing missing', 60, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'CONSISTENT', 'Consistent', 'Same format, same method, consistent sequence', 70, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ENDURING', 'Enduring', 'Retained for required retention period', 80, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'AVAILABLE', 'Available', 'Accessible when needed throughout retention period', 90, true FROM lookup_categories WHERE code = 'ALCOA_ATTRIBUTE';

-- Root Cause Categories
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PEOPLE', 'People', 10, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PROCESS', 'Process / Procedure', 20, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'EQUIPMENT', 'Equipment / Instrument', 30, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'MATERIALS', 'Materials / Reagents', 40, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ENVIRONMENT', 'Environment / Facility', 50, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'MEASUREMENT', 'Measurement / Data', 60, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'VENDOR', 'Vendor / Supplier', 70, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'SOFTWARE', 'Software / System', 80, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'UNKNOWN', 'Unknown / Undetermined', 90, true FROM lookup_categories WHERE code = 'ROOT_CAUSE_CATEGORY';

-- Applicable Regulations
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, '21CFR11', '21 CFR Part 11', 'Electronic Records and Electronic Signatures', 10, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, '21CFR210', '21 CFR Part 210', 'cGMP Manufacturing Drugs (General)', 20, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, '21CFR211', '21 CFR Part 211', 'cGMP Finished Pharmaceuticals', 30, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, '21CFR820', '21 CFR Part 820', 'Quality System Regulation (Medical Devices)', 40, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, '21CFR58', '21 CFR Part 58', 'Good Laboratory Practice for Nonclinical Studies', 50, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'EU_ANNEX11', 'EU Annex 11', 'EMA Computerised Systems Annex 11', 60, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'GAMP5', 'GAMP 5', 'ISPE GAMP 5 - Risk-Based Approach to GxP Computerized Systems', 70, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';
INSERT INTO lookup_values (id, category_id, code, display_name, description, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'ISO13485', 'ISO 13485', 'Medical Devices Quality Management Systems', 80, true FROM lookup_categories WHERE code = 'APPLICABLE_REGULATION';

-- GxP Impact Areas
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'DATA_INTEGRITY', 'Data Integrity', 10, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PRODUCT_QUALITY', 'Product Quality', 20, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PATIENT_SAFETY', 'Patient Safety', 30, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'AUDIT_TRAIL', 'Audit Trail', 40, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'GXP_RECORDS', 'GxP Records', 50, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'PROCESS_CONTROL', 'Process Control', 60, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'LAB_DATA', 'Laboratory Data', 70, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';
INSERT INTO lookup_values (id, category_id, code, display_name, sort_order, is_system)
SELECT uuid_generate_v4(), id, 'REGULATORY_SUBMISSION', 'Regulatory Submissions', 80, true FROM lookup_categories WHERE code = 'GXP_IMPACT_AREA';

-- ============================================================
-- SEED DATA: DEFAULT ROLES
-- ============================================================

INSERT INTO roles (id, name, display_name, description, is_system_role, is_active) VALUES
    (uuid_generate_v4(), 'system_admin', 'System Administrator', 'Full system access including user management and site configuration', true, true),
    (uuid_generate_v4(), 'qa_manager', 'QA Manager', 'Quality assurance management: approve documents, CAPAs, change control, protocols', true, true),
    (uuid_generate_v4(), 'qa_associate', 'QA Associate', 'Quality assurance tasks: review and approve documents and records', true, true),
    (uuid_generate_v4(), 'validation_engineer', 'Validation Engineer', 'Create and execute protocols, manage risk assessments and requirements', true, true),
    (uuid_generate_v4(), 'technical_owner', 'Technical Owner', 'Technical ownership of systems: manage system inventory, components, change assessment', true, true),
    (uuid_generate_v4(), 'business_owner', 'Business Owner', 'Business ownership: review and approve validation deliverables for owned systems', true, true),
    (uuid_generate_v4(), 'document_author', 'Document Author', 'Create and revise controlled documents', true, true),
    (uuid_generate_v4(), 'execution_only', 'Protocol Executor', 'Execute approved protocols only. No create or edit permissions.', true, true),
    (uuid_generate_v4(), 'read_only', 'Read Only', 'View all records with no create, edit, or delete permissions', true, true),
    (uuid_generate_v4(), 'auditor', 'Auditor', 'Read access to all records including audit trail for audit purposes', true, true),
    (uuid_generate_v4(), 'training_coordinator', 'Training Coordinator', 'Manage training requirements, assignments, and records', true, true);

-- ============================================================
-- SEED DATA: DEFAULT RISK MATRIX (5x5)
-- ============================================================

INSERT INTO risk_matrices (id, name, description, matrix_type, probability_scale, impact_scale, detectability_scale, risk_thresholds, is_default, is_active)
VALUES (
    uuid_generate_v4(),
    'Default 5x5 GxP Risk Matrix',
    'Standard 5x5 probability x impact risk matrix for GxP computerized system validation. Risk score = Probability x Impact.',
    'probability_impact',
    5, 5, NULL,
    '[
        {"min_score": 1,  "max_score": 4,  "level": "low",      "color": "#00875A", "action_required": false},
        {"min_score": 5,  "max_score": 9,  "level": "medium",   "color": "#FF8B00", "action_required": true},
        {"min_score": 10, "max_score": 15, "level": "high",     "color": "#DE350B", "action_required": true},
        {"min_score": 16, "max_score": 25, "level": "critical", "color": "#6B2D0F", "action_required": true}
    ]',
    true,
    true
);

INSERT INTO risk_matrices (id, name, description, matrix_type, probability_scale, impact_scale, detectability_scale, risk_thresholds, is_default, is_active)
VALUES (
    uuid_generate_v4(),
    'Default FMEA Risk Matrix',
    'Failure Mode and Effects Analysis (FMEA) matrix. RPN = Probability x Impact x Detectability. Scale 1-5 each.',
    'fmea',
    5, 5, 5,
    '[
        {"min_score": 1,  "max_score": 29,  "level": "low",      "color": "#00875A", "action_required": false},
        {"min_score": 30, "max_score": 59,  "level": "medium",   "color": "#FF8B00", "action_required": true},
        {"min_score": 60, "max_score": 99,  "level": "high",     "color": "#DE350B", "action_required": true},
        {"min_score": 100,"max_score": 125, "level": "critical", "color": "#6B2D0F", "action_required": true}
    ]',
    false,
    true
);

-- ============================================================
-- SEED DATA: REGULATORY REFERENCES
-- ============================================================

INSERT INTO regulatory_references (id, framework, citation, title, summary) VALUES
    (uuid_generate_v4(), '21CFR', '21 CFR Part 11', 'Electronic Records; Electronic Signatures', 'Establishes criteria under which electronic records and signatures are considered trustworthy, reliable, and equivalent to paper records and handwritten signatures.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(a)', 'System Validation', 'Validation of systems to ensure accuracy, reliability, consistent intended performance, and the ability to discern invalid or altered records.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(b)', 'Record Generation', 'Ability to generate accurate and complete copies of records in both human readable and electronic form.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(c)', 'Record Protection and Retention', 'Protection of records to enable their accurate and ready retrieval throughout the records retention period.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(d)', 'Access Controls', 'Limiting system access to authorized individuals.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(e)', 'Audit Trails', 'Use of secure, computer-generated, time-stamped audit trails to independently record the date and time of operator entries and actions.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(g)', 'Authority Checks', 'Use of authority checks to ensure that only authorized individuals can use the system, electronically sign a record, access the operation or computer system input or output device, alter a record, or perform the operation at hand.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.10(i)', 'Training', 'Determination that persons who develop, maintain, or use electronic record/electronic signature systems have the education, training, and experience to perform their assigned tasks.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.50', 'Signature Manifestations', 'Signed electronic records shall contain information associated with the signing that clearly indicates: printed name of the signer, date and time when the signature was executed, and the meaning associated with the signature.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.70', 'Signature/Record Linking', 'Electronic signatures and handwritten signatures executed to electronic records shall be linked to their respective electronic records to ensure that the signatures cannot be excised, copied, or otherwise transferred to falsify an electronic record.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.100', 'General Signature Requirements', 'Each electronic signature shall be unique to one individual and shall not be reused by, or reassigned to, anyone else.'),
    (uuid_generate_v4(), '21CFR', '21 CFR 11.200', 'Electronic Signature Components', 'Electronic signatures that are not based upon biometrics shall employ at least two distinct identification components such as an identification code and password.'),
    (uuid_generate_v4(), '21CFR', '21 CFR Part 211', 'Current Good Manufacturing Practice for Finished Pharmaceuticals', 'Minimum cGMP requirements for finished pharmaceutical products.'),
    (uuid_generate_v4(), '21CFR', '21 CFR Part 820', 'Quality System Regulation', 'Quality system requirements for medical device manufacturers.'),
    (uuid_generate_v4(), '21CFR', '21 CFR Part 58', 'Good Laboratory Practice for Nonclinical Laboratory Studies', 'GLP regulations for nonclinical safety studies.'),
    (uuid_generate_v4(), 'EU_ANNEX11', 'EU Annex 11', 'Computerised Systems', 'EU GMP Annex 11 requirements for computerised systems used in GMP manufacturing.'),
    (uuid_generate_v4(), 'EU_ANNEX11', 'EU Annex 11, §4', 'Validation', 'The application should be validated; IT infrastructure should be qualified.'),
    (uuid_generate_v4(), 'EU_ANNEX11', 'EU Annex 11, §9', 'Audit Trails', 'Consideration should be given to building into the system the creation of a record of all GMP-relevant changes and deletions.'),
    (uuid_generate_v4(), 'GAMP5', 'GAMP 5', 'A Risk-Based Approach to GxP Computerized Systems', 'ISPE GAMP 5 framework for validation of GxP computerized systems including software categorization.'),
    (uuid_generate_v4(), 'ICH', 'ICH Q9', 'Quality Risk Management', 'Principles and examples of tools for quality risk management that apply to pharmaceutical development, manufacturing, and distribution.'),
    (uuid_generate_v4(), 'ICH', 'ICH Q10', 'Pharmaceutical Quality System', 'Model for an effective pharmaceutical quality system based on ICH Q8 and Q9, and ISO quality concepts.');

-- ============================================================
-- SEED DATA: DEFAULT NOTIFICATION TEMPLATES
-- ============================================================

INSERT INTO notification_templates (id, code, name, channel, subject_template, body_template, is_active) VALUES
    (uuid_generate_v4(), 'WORKFLOW_TASK_ASSIGNED', 'Workflow Task Assigned', 'both',
     'Action Required: {{workflow_name}} - {{stage_name}}',
     'You have been assigned a task in workflow {{workflow_name}}.\n\nRecord: {{object_ref}} - {{object_title}}\nStage: {{stage_name}}\nDue: {{due_date}}\n\nInstructions: {{stage_instructions}}\n\nPlease log in to OpenVAL to complete this task.', true),

    (uuid_generate_v4(), 'WORKFLOW_TASK_OVERDUE', 'Workflow Task Overdue', 'both',
     'OVERDUE: Action Required - {{workflow_name}}',
     'Your task in workflow {{workflow_name}} is overdue.\n\nRecord: {{object_ref}} - {{object_title}}\nStage: {{stage_name}}\nDue: {{due_date}}\n\nPlease complete this task immediately or contact your manager.', true),

    (uuid_generate_v4(), 'WORKFLOW_COMPLETE', 'Workflow Completed', 'in_app',
     'Workflow Completed: {{object_ref}}',
     'The workflow for {{object_ref}} - {{object_title}} has been completed.\nOutcome: {{outcome}}', true),

    (uuid_generate_v4(), 'WORKFLOW_REJECTED', 'Workflow Rejected', 'both',
     'Rejected: {{object_ref}} - {{workflow_name}}',
     '{{object_ref}} - {{object_title}} was rejected by {{rejector_name}} at stage {{stage_name}}.\n\nReason: {{rejection_reason}}\n\nPlease review and resubmit.', true),

    (uuid_generate_v4(), 'DEVIATION_RAISED', 'Deviation Raised During Execution', 'both',
     'Deviation Raised: {{deviation_ref}} - {{protocol_ref}}',
     'A {{severity}} deviation has been raised during execution of {{protocol_ref}}.\n\nDeviation: {{deviation_ref}}\nTitle: {{deviation_title}}\nStep: {{step_ref}}\nRaised by: {{raised_by}}\n\nPlease review and assign disposition.', true),

    (uuid_generate_v4(), 'PERIODIC_REVIEW_DUE', 'Periodic Review Due', 'both',
     'Periodic Review Due: {{object_ref}}',
     'A periodic review is due for {{object_type}} {{object_ref}} - {{object_title}}.\n\nDue Date: {{due_date}}\nAssigned Reviewer: {{reviewer_name}}\n\nPlease initiate the periodic review.', true),

    (uuid_generate_v4(), 'PERIODIC_REVIEW_OVERDUE', 'Periodic Review Overdue', 'both',
     'OVERDUE: Periodic Review - {{object_ref}}',
     'The periodic review for {{object_ref}} is overdue by {{days_overdue}} days.\n\nPlease complete this review immediately.', true),

    (uuid_generate_v4(), 'CALIBRATION_DUE', 'Equipment Calibration Due', 'both',
     'Calibration Due: {{equipment_ref}} - {{equipment_name}}',
     'Calibration is due for {{equipment_ref}} - {{equipment_name}}.\n\nDue Date: {{due_date}}\nLocation: {{location}}\n\nPlease schedule calibration.', true),

    (uuid_generate_v4(), 'CAPA_OVERDUE', 'CAPA Action Overdue', 'both',
     'OVERDUE: CAPA Action - {{capa_ref}}',
     'A CAPA action is overdue.\n\nCAPA: {{capa_ref}} - {{capa_title}}\nAction: {{action_title}}\nResponsible: {{responsible_name}}\nDue: {{due_date}}\n\nPlease complete this action or request an extension.', true),

    (uuid_generate_v4(), 'DOCUMENT_EFFECTIVE', 'Document Now Effective', 'in_app',
     'Now Effective: {{doc_ref}} - {{doc_title}}',
     'Document {{doc_ref}} - {{doc_title}} is now effective as of {{effective_date}}.\n\nVersion: {{version}}\nCategory: {{category}}\n\nPlease review this document if it applies to your role.', true),

    (uuid_generate_v4(), 'TRAINING_ASSIGNED', 'Training Assignment', 'both',
     'Training Required: {{training_name}}',
     'You have been assigned training: {{training_name}}\n\nDue Date: {{due_date}}\nType: {{training_type}}\n\nPlease complete this training by the due date.', true),

    (uuid_generate_v4(), 'AUDIT_TRAIL_INTEGRITY_FAIL', 'Audit Trail Integrity Check Failed', 'both',
     'CRITICAL: Audit Trail Integrity Failure',
     'The scheduled audit trail integrity check has detected a potential tamper event.\n\nFailed at event ID: {{event_id}}\nTimestamp: {{timestamp}}\n\nImmediate investigation is required. Contact your System Administrator.', true),

    (uuid_generate_v4(), 'SYSTEM_REVALIDATION_DUE', 'System Revalidation Due', 'both',
     'Revalidation Due: {{system_ref}} - {{system_name}}',
     'System {{system_ref}} - {{system_name}} requires revalidation.\n\nDue Date: {{due_date}}\nTrigger: {{trigger}}\nTechnical Owner: {{technical_owner}}\n\nPlease initiate the revalidation process.', true);

-- ============================================================
-- SEED DATA: FEATURE FLAGS
-- ============================================================

INSERT INTO feature_flags (id, flag_key, display_name, description, is_enabled) VALUES
    (uuid_generate_v4(), 'mfa_required_for_all', 'Require MFA for All Users', 'When enabled, all users must set up MFA before accessing the system', false),
    (uuid_generate_v4(), 'mfa_required_for_signatures', 'Require MFA for Signatures', 'When enabled, MFA is required for all electronic signature actions', true),
    (uuid_generate_v4(), 'allow_self_registration', 'Allow User Self-Registration', 'When enabled, users can register themselves (pending admin approval)', false),
    (uuid_generate_v4(), 'enable_ldap_sync', 'Enable LDAP/AD Sync', 'Enable Active Directory user provisioning', false),
    (uuid_generate_v4(), 'enable_sso', 'Enable SSO', 'Enable SAML/OIDC single sign-on', false),
    (uuid_generate_v4(), 'enable_webhooks', 'Enable Webhooks', 'Allow outbound webhooks to external systems', false),
    (uuid_generate_v4(), 'enable_api_access', 'Enable API Key Access', 'Allow external API access via API keys', true),
    (uuid_generate_v4(), 'strict_audit_chain', 'Strict Audit Chain Verification', 'Run audit trail hash chain verification on every write (performance impact)', false),
    (uuid_generate_v4(), 'require_deviation_signature', 'Require Signature on Deviations', 'Require electronic signature when raising a deviation', true),
    (uuid_generate_v4(), 'enable_script_execution', 'Enable Test Script Execution', 'Allow test scripts to be executed from within protocol execution', false);

-- ============================================================
-- DONE
-- ============================================================

COMMENT ON TABLE audit_log IS '21 CFR Part 11 compliant audit trail. Append-only enforced via RLS. Never UPDATE or DELETE.';
COMMENT ON TABLE audit_log_integrity IS 'Hash chain integrity verification records. Each row links to an audit_log entry and stores a chained SHA-256 hash for tamper detection.';
COMMENT ON TABLE electronic_signatures IS '21 CFR Part 11 compliant electronic signatures. Append-only. Invalidation adds a new record, never modifies existing.';
COMMENT ON TABLE systems IS 'GxP computerized system inventory. GAMP 5 categorization and full validation lifecycle tracking.';
COMMENT ON TABLE protocols IS 'Validation protocol definitions. IQ, OQ, PQ, UAT, MAV, DQ, FAT, SAT, RETRO types supported.';
COMMENT ON TABLE test_executions IS 'Individual execution runs of a protocol. Multiple executions per protocol supported for re-executions.';
COMMENT ON TABLE traceability_links IS 'Links requirements to test steps, risk items, and documents. Basis for automated RTM generation.';
