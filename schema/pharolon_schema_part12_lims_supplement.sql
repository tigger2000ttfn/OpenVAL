-- ============================================================
-- PHAROLON Schema Part 12 Supplement — LIMS Advanced Coverage
-- ============================================================
-- Adds: ISO 17025 accreditation, method transfer, ELN integration,
--       E&L testing, CDS integration, dissolution, elemental analysis,
--       proficiency testing, measurement uncertainty
-- ============================================================

-- ── ISO 17025 ACCREDITATION MANAGEMENT ─────────────────────

CREATE TABLE lims_accreditation_bodies (
  id                    BIGSERIAL PRIMARY KEY,
  body_name             VARCHAR(100) NOT NULL, -- UKAS, A2LA, DAkkS, COFRAC, ILAC member
  country_code          CHAR(2),
  ilac_member           BOOLEAN DEFAULT TRUE,
  website               VARCHAR(300),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_accreditation_scopes (
  id                    BIGSERIAL PRIMARY KEY,
  site_id               BIGINT REFERENCES sites(id),
  accreditation_body_id BIGINT REFERENCES lims_accreditation_bodies(id),
  certificate_number    VARCHAR(100) UNIQUE NOT NULL,
  certificate_date      DATE NOT NULL,
  expiry_date           DATE NOT NULL,
  last_assessment_date  DATE,
  next_assessment_due   DATE,
  scope_document_id     BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_accreditation_scope_items (
  id                    BIGSERIAL PRIMARY KEY,
  scope_id              BIGINT REFERENCES lims_accreditation_scopes(id),
  test_method_id        BIGINT REFERENCES lims_test_methods(id),
  test_description      VARCHAR(300),
  matrix_type           VARCHAR(100), -- API, finished product, water, raw material
  measurand             VARCHAR(200),
  technique             VARCHAR(100), -- HPLC, GC, ICP-MS, UV-Vis
  range_lower           NUMERIC(18,6),
  range_upper           NUMERIC(18,6),
  range_unit            VARCHAR(30),
  standard_reference    VARCHAR(200), -- Ph Eur, USP, ISO, in-house
  scope_item_status     VARCHAR(20) DEFAULT 'active',
  withdrawal_date       DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_measurement_uncertainty_budgets (
  id                    BIGSERIAL PRIMARY KEY,
  test_method_id        BIGINT REFERENCES lims_test_methods(id),
  version               INTEGER DEFAULT 1,
  effective_date        DATE NOT NULL,
  measurand             VARCHAR(200),
  unit                  VARCHAR(30),
  coverage_factor_k     NUMERIC(6,3) DEFAULT 2.0,
  confidence_level_pct  NUMERIC(5,2) DEFAULT 95.45,
  combined_uncertainty_u NUMERIC(18,8),
  expanded_uncertainty_U NUMERIC(18,8),
  relative_expanded_pct NUMERIC(8,4),
  decision_rule         TEXT,
  document_id           BIGINT REFERENCES documents(id),
  reviewed_by_user_id   BIGINT REFERENCES users(id),
  status                VARCHAR(20) DEFAULT 'current',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_mu_components (
  id                    BIGSERIAL PRIMARY KEY,
  budget_id             BIGINT REFERENCES lims_measurement_uncertainty_budgets(id),
  component_name        VARCHAR(100), -- repeatability, reproducibility, calibration, reference_std, temp
  source_description    TEXT,
  uncertainty_type      VARCHAR(5), -- A (statistical), B (other means)
  distribution          VARCHAR(20), -- normal, rectangular, triangular
  standard_value        NUMERIC(18,8),
  divisor               NUMERIC(6,3),
  standard_uncertainty  NUMERIC(18,8),
  sensitivity_coefficient NUMERIC(18,8) DEFAULT 1,
  contribution_pct      NUMERIC(6,2),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROFICIENCY TESTING PROGRAMME ───────────────────────────

CREATE TABLE lims_pt_schemes (
  id                    BIGSERIAL PRIMARY KEY,
  scheme_name           VARCHAR(200) NOT NULL,
  provider_name         VARCHAR(200),
  provider_country      CHAR(2),
  analyte_group         VARCHAR(100),
  frequency_per_year    INTEGER,
  joining_date          DATE,
  ilac_mra_endorsed     BOOLEAN DEFAULT TRUE,
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_pt_rounds (
  id                    BIGSERIAL PRIMARY KEY,
  scheme_id             BIGINT REFERENCES lims_pt_schemes(id),
  round_code            VARCHAR(50),
  round_year            INTEGER,
  round_number          INTEGER,
  sample_receipt_date   DATE,
  reporting_deadline    DATE,
  assigned_value        NUMERIC(18,6),
  assigned_value_unit   VARCHAR(30),
  uncertainty_of_assigned NUMERIC(18,8),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_pt_results (
  id                    BIGSERIAL PRIMARY KEY,
  round_id              BIGINT REFERENCES lims_pt_rounds(id),
  test_method_id        BIGINT REFERENCES lims_test_methods(id),
  analyst_user_id       BIGINT REFERENCES users(id),
  reported_value        NUMERIC(18,6),
  unit                  VARCHAR(30),
  reported_uncertainty  NUMERIC(18,8),
  submission_date       TIMESTAMPTZ,
  z_score               NUMERIC(8,4),
  en_number             NUMERIC(8,4), -- En = |x - X| / sqrt(U²lab + U²ref)
  performance_score     VARCHAR(10), -- satisfactory, questionable, unsatisfactory
  provider_feedback     TEXT,
  corrective_action_required BOOLEAN DEFAULT FALSE,
  capa_id               BIGINT REFERENCES capas(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── METHOD TRANSFER VALIDATION ───────────────────────────────

CREATE TABLE lims_method_transfer_studies (
  id                    BIGSERIAL PRIMARY KEY,
  study_code            VARCHAR(50) UNIQUE NOT NULL,
  test_method_id        BIGINT REFERENCES lims_test_methods(id),
  transfer_type         VARCHAR(30), -- complete, partial, co_validation, technology_transfer
  sending_lab_site_id   BIGINT REFERENCES sites(id),
  receiving_lab_site_id BIGINT REFERENCES sites(id),
  rationale             TEXT,
  protocol_doc_id       BIGINT REFERENCES documents(id),
  planned_start_date    DATE,
  actual_start_date     DATE,
  completion_date       DATE,
  status                VARCHAR(20) DEFAULT 'planned',
  outcome               VARCHAR(20), -- pass, fail, conditional
  report_doc_id         BIGINT REFERENCES documents(id),
  approved_by_user_id   BIGINT REFERENCES users(id),
  approval_date         DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_method_transfer_acceptance_criteria (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES lims_method_transfer_studies(id),
  parameter             VARCHAR(100), -- precision, bias, linearity, LOD, LOQ
  acceptance_criterion  TEXT,
  statistical_test      VARCHAR(50), -- t-test, F-test, equivalence_test
  significance_level    NUMERIC(5,4) DEFAULT 0.05,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_method_transfer_results (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES lims_method_transfer_studies(id),
  parameter             VARCHAR(100),
  sending_lab_result    NUMERIC(18,6),
  receiving_lab_result  NUMERIC(18,6),
  unit                  VARCHAR(30),
  statistical_result    NUMERIC(18,6),
  p_value               NUMERIC(10,8),
  criterion_met         BOOLEAN,
  comment               TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── EXTRACTABLES & LEACHABLES ────────────────────────────────

CREATE TABLE lims_el_studies (
  id                    BIGSERIAL PRIMARY KEY,
  study_code            VARCHAR(50) UNIQUE NOT NULL,
  study_type            VARCHAR(30), -- extractables, leachables, both
  product_name          VARCHAR(200),
  dosage_form           VARCHAR(100),
  route_of_administration VARCHAR(50),
  container_closure_system TEXT,
  regulatory_framework  TEXT[], -- ICH Q3E, USP 1663/1664, EMA guideline
  phase                 VARCHAR(20), -- development, registration, post_approval
  protocol_doc_id       BIGINT REFERENCES documents(id),
  start_date            DATE,
  end_date              DATE,
  status                VARCHAR(20) DEFAULT 'planned',
  report_doc_id         BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_el_detected_compounds (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES lims_el_studies(id),
  compound_name         VARCHAR(200) NOT NULL,
  cas_number            VARCHAR(20),
  compound_class        VARCHAR(100), -- polymer_additive, degradant, process_chemical
  detection_method      VARCHAR(100),
  extraction_condition  VARCHAR(100),
  detected_concentration NUMERIC(18,8),
  concentration_unit    VARCHAR(30),
  scl_threshold         NUMERIC(18,8), -- Screening Concentration Limit
  aet_threshold         NUMERIC(18,8), -- Analytical Evaluation Threshold
  ttc_value             NUMERIC(18,8), -- Threshold of Toxicological Concern
  exceeds_aet           BOOLEAN GENERATED ALWAYS AS (FALSE) STORED,
  toxicological_assessment_required BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── ELECTRONIC LAB NOTEBOOK ──────────────────────────────────

CREATE TABLE lims_lab_notebooks (
  id                    BIGSERIAL PRIMARY KEY,
  notebook_number       VARCHAR(50) UNIQUE NOT NULL,
  notebook_type         VARCHAR(30), -- electronic, paper_scan, hybrid
  project_id            BIGINT,
  assigned_user_id      BIGINT REFERENCES users(id),
  department_id         BIGINT REFERENCES departments(id),
  open_date             DATE NOT NULL,
  close_date            DATE,
  status                VARCHAR(20) DEFAULT 'open',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_notebook_entries (
  id                    BIGSERIAL PRIMARY KEY,
  notebook_id           BIGINT REFERENCES lims_lab_notebooks(id),
  entry_number          INTEGER NOT NULL,
  entry_date            TIMESTAMPTZ NOT NULL,
  title                 VARCHAR(300),
  experiment_type       VARCHAR(100),
  objective             TEXT,
  procedure_summary     TEXT,
  results_summary       TEXT,
  conclusions           TEXT,
  author_user_id        BIGINT REFERENCES users(id),
  witness_user_id       BIGINT REFERENCES users(id),
  witness_date          TIMESTAMPTZ,
  linked_test_results   BIGINT[],
  status                VARCHAR(20) DEFAULT 'draft',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_raw_data_files (
  id                    BIGSERIAL PRIMARY KEY,
  notebook_entry_id     BIGINT REFERENCES lims_notebook_entries(id),
  test_result_id        BIGINT REFERENCES lims_test_results(id),
  file_name             VARCHAR(300) NOT NULL,
  file_type             VARCHAR(50), -- raw, processed, spectrum, chromatogram, image
  instrument_id         BIGINT REFERENCES lims_instruments(id),
  acquisition_timestamp TIMESTAMPTZ,
  file_path             VARCHAR(500),
  file_size_bytes       BIGINT,
  checksum_sha256       VARCHAR(64),
  is_original           BOOLEAN DEFAULT TRUE,
  part11_compliant      BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── CDS INTEGRATION ──────────────────────────────────────────

CREATE TABLE lims_cds_systems (
  id                    BIGSERIAL PRIMARY KEY,
  system_name           VARCHAR(100) NOT NULL, -- Empower, Chromeleon, OpenLAB, MassLynx
  vendor                VARCHAR(100),
  version               VARCHAR(50),
  validation_status     VARCHAR(30),
  validation_date       DATE,
  site_id               BIGINT REFERENCES sites(id),
  audit_trail_enabled   BOOLEAN DEFAULT TRUE,
  electronic_signatures BOOLEAN DEFAULT TRUE,
  data_integrity_controls TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_cds_sequences (
  id                    BIGSERIAL PRIMARY KEY,
  cds_system_id         BIGINT REFERENCES lims_cds_systems(id),
  instrument_id         BIGINT REFERENCES lims_instruments(id),
  sequence_name         VARCHAR(200),
  run_date              TIMESTAMPTZ,
  analyst_user_id       BIGINT REFERENCES users(id),
  method_file           VARCHAR(300),
  test_result_id        BIGINT REFERENCES lims_test_results(id),
  number_of_injections  INTEGER,
  cds_sequence_id       VARCHAR(100),
  status                VARCHAR(20) DEFAULT 'complete',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── DISSOLUTION TESTING ──────────────────────────────────────

CREATE TABLE lims_dissolution_methods (
  id                    BIGSERIAL PRIMARY KEY,
  test_method_id        BIGINT REFERENCES lims_test_methods(id),
  apparatus_type        VARCHAR(20), -- Type I, II, III, IV
  rotation_speed_rpm    INTEGER,
  medium                VARCHAR(200),
  medium_volume_ml      NUMERIC(8,2),
  medium_temperature_c  NUMERIC(5,2),
  sampling_times_min    INTEGER[],
  sink_conditions       BOOLEAN,
  filter_type           VARCHAR(100),
  detection_method      VARCHAR(100),
  acceptance_criteria   TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_dissolution_runs (
  id                    BIGSERIAL PRIMARY KEY,
  dissolution_method_id BIGINT REFERENCES lims_dissolution_methods(id),
  test_request_id       BIGINT REFERENCES lims_test_requests(id),
  instrument_id         BIGINT REFERENCES lims_instruments(id),
  run_date              TIMESTAMPTZ,
  analyst_user_id       BIGINT REFERENCES users(id),
  temperature_actual_c  NUMERIC(5,2),
  medium_ph_actual      NUMERIC(5,3),
  number_of_vessels     INTEGER DEFAULT 6,
  status                VARCHAR(20) DEFAULT 'in_progress',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE lims_dissolution_vessel_results (
  id                    BIGSERIAL PRIMARY KEY,
  run_id                BIGINT REFERENCES lims_dissolution_runs(id),
  vessel_number         INTEGER NOT NULL,
  sampling_time_min     INTEGER,
  dissolved_pct         NUMERIC(8,4),
  cumulative_dissolved_pct NUMERIC(8,4),
  absorbance            NUMERIC(10,6),
  concentration_mgml    NUMERIC(12,6),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── ELEMENTAL IMPURITY TESTING (ICH Q3D) ────────────────────

CREATE TABLE lims_elemental_impurity_results (
  id                    BIGSERIAL PRIMARY KEY,
  test_result_id        BIGINT REFERENCES lims_test_results(id),
  element_name          VARCHAR(50) NOT NULL,
  element_symbol        VARCHAR(10),
  instrument_technique  VARCHAR(20), -- ICP-MS, ICP-OES, AAS
  class_ich_q3d         VARCHAR(10), -- Class 1, 2A, 2B, 3
  route_pde_mcg_day     NUMERIC(12,4), -- Permitted Daily Exposure
  measured_concentration NUMERIC(18,8),
  unit                  VARCHAR(30),
  daily_dose_mcg        NUMERIC(18,4),
  pde_percentage        NUMERIC(8,4),
  exceeds_30pct_pde     BOOLEAN DEFAULT FALSE,
  exceeds_pde           BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

