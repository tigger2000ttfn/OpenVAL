-- ============================================================
-- PHAROLON Schema Part 15 — GCP / Clinical Trial Systems
-- ============================================================
-- Regulatory basis:
--   ICH E6(R3) — GCP (final 2023)
--   21 CFR Part 11 (finalized guidance October 2024)
--   21 CFR Part 312 — Investigational New Drug (IND)
--   EU Clinical Trials Regulation No 536/2014 (EUCT)
--   ICH E9 — Statistical principles for clinical trials
--   ICH E2A — Definitions and standards for expedited reporting (SAE/SUSAR)
--   DIA eTMF Reference Model v3.0
-- ============================================================

-- ── CLINICAL TRIAL REGISTRY ─────────────────────────────────

CREATE TABLE gcp_trials (
  id                    BIGSERIAL PRIMARY KEY,
  protocol_number       VARCHAR(100) UNIQUE NOT NULL,
  eudract_number        VARCHAR(50),  -- EU CT number
  ind_number            VARCHAR(50),  -- FDA IND
  ctgov_nct_number      VARCHAR(50),  -- ClinicalTrials.gov
  isrctn_number         VARCHAR(50),
  who_utn               VARCHAR(50),
  trial_title           VARCHAR(500) NOT NULL,
  short_title           VARCHAR(200),
  trial_phase           VARCHAR(10), -- Phase I, II, III, IV, 0, BA/BE
  indication            TEXT,
  investigational_product VARCHAR(200),
  route_of_administration VARCHAR(50),
  therapeutic_area      VARCHAR(100),
  sponsor_organisation_id BIGINT REFERENCES organizations(id),
  trial_type            VARCHAR(50), -- interventional, observational, expanded_access
  randomised            BOOLEAN DEFAULT TRUE,
  blinded               BOOLEAN DEFAULT TRUE,
  blinding_type         VARCHAR(30), -- open, single_blind, double_blind, triple_blind
  control_type          VARCHAR(50), -- placebo, active_comparator, no_treatment
  planned_subjects      INTEGER,
  enrolled_subjects     INTEGER DEFAULT 0,
  status                VARCHAR(30) DEFAULT 'setup', -- setup, active, suspended, completed, terminated
  planned_start_date    DATE,
  actual_start_date     DATE,
  planned_completion_date DATE,
  actual_completion_date DATE,
  primary_endpoint      TEXT,
  secondary_endpoints   TEXT,
  gcp_trained_monitor   BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_protocol_versions (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  version_number        VARCHAR(20) NOT NULL,
  version_date          DATE NOT NULL,
  amendment_summary     TEXT,
  amendment_reason      TEXT,
  irb_ec_approved       BOOLEAN DEFAULT FALSE,
  irb_ec_approval_date  DATE,
  regulatory_notified   BOOLEAN DEFAULT FALSE,
  document_id           BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'draft',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── ELECTRONIC TRIAL MASTER FILE (eTMF) ─────────────────────
-- Based on DIA TMF Reference Model v3.0
-- 5 Zones: 01-Trial Management, 02-Regulatory, 03-IRB/IEC,
--          04-Investigational Product, 05-Site Management

CREATE TABLE gcp_tmf_zones (
  id                    BIGSERIAL PRIMARY KEY,
  zone_code             VARCHAR(10) NOT NULL,  -- 01-05
  zone_name             VARCHAR(100) NOT NULL,
  description           TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_tmf_sections (
  id                    BIGSERIAL PRIMARY KEY,
  zone_id               BIGINT REFERENCES gcp_tmf_zones(id),
  section_code          VARCHAR(20) NOT NULL,  -- e.g. 01.01
  section_name          VARCHAR(200) NOT NULL,
  ich_e6_reference      VARCHAR(50),
  required              BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_tmf_artifacts (
  id                    BIGSERIAL PRIMARY KEY,
  section_id            BIGINT REFERENCES gcp_tmf_sections(id),
  artifact_code         VARCHAR(30) NOT NULL,  -- DIA TMF RM artifact code
  artifact_name         VARCHAR(200) NOT NULL,
  description           TEXT,
  required              BOOLEAN DEFAULT TRUE,
  level                 VARCHAR(20), -- trial, country, site
  retention_years       INTEGER,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_tmf_documents (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  artifact_id           BIGINT REFERENCES gcp_tmf_artifacts(id),
  site_id               BIGINT REFERENCES sites(id),  -- NULL if trial-level
  document_id           BIGINT REFERENCES documents(id),
  document_date         DATE,
  version               VARCHAR(20),
  expiry_date           DATE,
  status                VARCHAR(20) DEFAULT 'final', -- draft, final, superseded, missing
  qa_reviewed           BOOLEAN DEFAULT FALSE,
  qa_review_date        DATE,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_tmf_completeness_checks (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  check_date            DATE NOT NULL,
  checked_by_user_id    BIGINT REFERENCES users(id),
  milestone             VARCHAR(50), -- startup, mid_trial, closeout
  total_artifacts_required INTEGER,
  total_artifacts_present  INTEGER,
  completeness_pct      NUMERIC(5,2),
  critical_missing      INTEGER DEFAULT 0,
  findings              TEXT,
  action_plan           TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── INVESTIGATOR SITES ───────────────────────────────────────

CREATE TABLE gcp_investigator_sites (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_code             VARCHAR(50),
  institution_name      VARCHAR(200) NOT NULL,
  address               TEXT,
  country_code          CHAR(2),
  principal_investigator_user_id BIGINT REFERENCES users(id),
  pi_name               VARCHAR(200),
  pi_gcp_cert_date      DATE,
  pi_gcp_cert_expiry    DATE,
  sub_investigator_names TEXT[],
  ethical_approval_ref  VARCHAR(100),
  ethical_approval_date DATE,
  ethical_approval_expiry DATE,
  regulatory_approval_ref VARCHAR(100),
  site_initiation_date  DATE,
  site_activation_date  DATE,
  first_subject_enrolled_date DATE,
  last_subject_visit_date DATE,
  site_closeout_date    DATE,
  planned_subjects      INTEGER,
  enrolled_subjects     INTEGER DEFAULT 0,
  completed_subjects    INTEGER DEFAULT 0,
  withdrawn_subjects    INTEGER DEFAULT 0,
  status                VARCHAR(30) DEFAULT 'setup',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── IRB / ETHICS COMMITTEE ───────────────────────────────────

CREATE TABLE gcp_irb_committees (
  id                    BIGSERIAL PRIMARY KEY,
  committee_name        VARCHAR(200) NOT NULL,
  committee_type        VARCHAR(30), -- IRB, IEC, HREC, ERB
  country_code          CHAR(2),
  registration_number   VARCHAR(100),
  contact_name          VARCHAR(200),
  contact_email         VARCHAR(200),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_irb_submissions (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  irb_id                BIGINT REFERENCES gcp_irb_committees(id),
  submission_type       VARCHAR(30), -- initial, amendment, annual_renewal, safety, closeout
  submission_date       DATE NOT NULL,
  protocol_version_id   BIGINT REFERENCES gcp_protocol_versions(id),
  icf_version           VARCHAR(20),
  documents_submitted   TEXT[],
  outcome               VARCHAR(30), -- approved, approved_with_conditions, deferred, rejected, waived
  outcome_date          DATE,
  conditions            TEXT,
  approval_expiry       DATE,
  next_renewal_due      DATE,
  document_id           BIGINT REFERENCES documents(id),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── INFORMED CONSENT ─────────────────────────────────────────

CREATE TABLE gcp_icf_versions (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  icf_version           VARCHAR(20) NOT NULL,
  version_date          DATE NOT NULL,
  language              VARCHAR(20) DEFAULT 'en',
  amendment_reason      TEXT,
  irb_approved          BOOLEAN DEFAULT FALSE,
  irb_approval_date     DATE,
  document_id           BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'draft',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_subject_consents (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  subject_code          VARCHAR(50) NOT NULL,  -- anonymised ID
  icf_version_id        BIGINT REFERENCES gcp_icf_versions(id),
  consent_date          TIMESTAMPTZ NOT NULL,
  consent_type          VARCHAR(30), -- initial, re-consent, assent, LAR
  obtained_by_user_id   BIGINT REFERENCES users(id),
  subject_capacity_confirmed BOOLEAN DEFAULT TRUE,
  time_to_consider_given BOOLEAN DEFAULT TRUE,
  questions_answered    BOOLEAN DEFAULT TRUE,
  econsent_method       BOOLEAN DEFAULT FALSE,
  econsent_platform     VARCHAR(100),
  witness_required      BOOLEAN DEFAULT FALSE,
  witness_name          VARCHAR(100),
  withdrawal_date       TIMESTAMPTZ,
  withdrawal_reason     TEXT,
  data_use_consent      BOOLEAN DEFAULT TRUE,
  biological_sample_consent BOOLEAN,
  future_research_consent BOOLEAN,
  document_id           BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── INVESTIGATIONAL PRODUCT ACCOUNTABILITY ───────────────────
-- 21 CFR 312.62 — full chain of custody required

CREATE TABLE gcp_ip_shipments (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  destination_site_id   BIGINT REFERENCES gcp_investigator_sites(id),
  shipment_number       VARCHAR(100) UNIQUE NOT NULL,
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  quantity_shipped      NUMERIC(10,3),
  unit_of_measure       VARCHAR(30),
  expiry_date           DATE,
  storage_conditions    VARCHAR(50),
  randomisation_kit_numbers TEXT[],
  dispatch_date         TIMESTAMPTZ,
  dispatch_site_id      BIGINT REFERENCES sites(id),
  tracking_number       VARCHAR(100),
  temperature_monitoring BOOLEAN DEFAULT TRUE,
  received_date         TIMESTAMPTZ,
  quantity_received     NUMERIC(10,3),
  condition_on_receipt  VARCHAR(30),
  received_by_user_id   BIGINT REFERENCES users(id),
  discrepancy_noted     BOOLEAN DEFAULT FALSE,
  discrepancy_detail    TEXT,
  status                VARCHAR(20) DEFAULT 'dispatched',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_ip_dispensing_records (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  shipment_id           BIGINT REFERENCES gcp_ip_shipments(id),
  subject_code          VARCHAR(50) NOT NULL,
  visit_number          INTEGER,
  dispensing_date       TIMESTAMPTZ NOT NULL,
  kit_number            VARCHAR(100),
  product_batch         VARCHAR(100),
  quantity_dispensed    NUMERIC(10,3),
  unit_of_measure       VARCHAR(30),
  dispensed_by_user_id  BIGINT REFERENCES users(id),
  treatment_arm         VARCHAR(50),
  blinded               BOOLEAN DEFAULT TRUE,
  quantity_returned     NUMERIC(10,3) DEFAULT 0,
  compliance_pct        NUMERIC(5,2),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_ip_returns_destructions (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  return_type           VARCHAR(20), -- return_to_sponsor, on_site_destruction
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  kit_numbers           TEXT[],
  quantity              NUMERIC(10,3),
  unit_of_measure       VARCHAR(30),
  reason                VARCHAR(50), -- expiry, study_end, damaged, unused
  return_date           TIMESTAMPTZ,
  destruction_date      TIMESTAMPTZ,
  destruction_cert_ref  VARCHAR(100),
  witnessed_by_user_id  BIGINT REFERENCES users(id),
  document_id           BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── SAFETY REPORTING (SAE/SUSAR) ─────────────────────────────
-- ICH E2A — Clinical Safety Data Management

CREATE TABLE gcp_serious_adverse_events (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  sae_number            VARCHAR(50) UNIQUE NOT NULL,
  subject_code          VARCHAR(50) NOT NULL,
  event_description     TEXT NOT NULL,
  meddra_pt             VARCHAR(200),  -- MedDRA Preferred Term
  meddra_soc            VARCHAR(200),  -- System Organ Class
  event_onset_date      DATE,
  aware_date            DATE NOT NULL,  -- date sponsor/investigator became aware
  sae_criteria          TEXT[], -- death, life_threatening, hospitalisation, disability, congenital_anomaly, other
  outcome               VARCHAR(30), -- recovered, recovering, not_recovered, sequelae, fatal, unknown
  causality_assessment  VARCHAR(30), -- related, possibly_related, unlikely, not_related
  expectedness          VARCHAR(20), -- expected, unexpected
  treatment_blind_broken BOOLEAN DEFAULT FALSE,
  serious_unexpected_related BOOLEAN DEFAULT FALSE, -- SUSAR flag
  -- Regulatory reporting timelines
  initial_report_due    TIMESTAMPTZ,
  initial_report_sent   TIMESTAMPTZ,
  followup_report_due   TIMESTAMPTZ,
  followup_report_sent  TIMESTAMPTZ,
  regulatory_agencies_notified TEXT[],
  investigators_notified BOOLEAN DEFAULT FALSE,
  irb_notified          BOOLEAN DEFAULT FALSE,
  status                VARCHAR(20) DEFAULT 'open',
  narrative             TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── MONITORING / CRA VISITS ──────────────────────────────────

CREATE TABLE gcp_monitoring_visits (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  visit_type            VARCHAR(30), -- site_initiation, routine, closeout, for_cause, remote
  visit_date            DATE NOT NULL,
  cra_user_id           BIGINT REFERENCES users(id),
  subjects_reviewed     INTEGER,
  source_data_verified  INTEGER,
  sdv_pct_target        NUMERIC(5,2),
  sdv_pct_achieved      NUMERIC(5,2),
  critical_findings     INTEGER DEFAULT 0,
  major_findings        INTEGER DEFAULT 0,
  minor_findings        INTEGER DEFAULT 0,
  report_doc_id         BIGINT REFERENCES documents(id),
  pi_acknowledgement_date DATE,
  status                VARCHAR(20) DEFAULT 'planned',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_monitoring_findings (
  id                    BIGSERIAL PRIMARY KEY,
  visit_id              BIGINT REFERENCES gcp_monitoring_visits(id),
  finding_number        VARCHAR(20),
  category              VARCHAR(50), -- protocol_deviation, gcp_violation, data_query, regulatory, ip_accountability
  classification        VARCHAR(10), -- critical, major, minor, observation
  description           TEXT NOT NULL,
  subject_code          VARCHAR(50),
  ich_e6_reference      VARCHAR(50),
  site_response         TEXT,
  resolution_action     TEXT,
  due_date              DATE,
  resolved_date         DATE,
  status                VARCHAR(20) DEFAULT 'open',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── RANDOMISATION & BLINDING ─────────────────────────────────

CREATE TABLE gcp_randomisation_lists (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  list_version          VARCHAR(20),
  method                VARCHAR(50), -- central, blocked, stratified, minimisation
  stratification_factors TEXT[],
  block_sizes           INTEGER[],
  prepared_by           VARCHAR(200),
  prepared_date         DATE,
  statistician_name     VARCHAR(200),
  seed_number           VARCHAR(100),  -- random seed — critical for reproducibility
  stored_securely       BOOLEAN DEFAULT TRUE,
  unblinding_procedure_ref VARCHAR(200),
  document_id           BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_unblinding_events (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  subject_code          VARCHAR(50),
  kit_number            VARCHAR(100),
  unblinding_date       TIMESTAMPTZ NOT NULL,
  reason                VARCHAR(50), -- medical_emergency, study_completion, safety_review
  reason_detail         TEXT,
  authorised_by_user_id BIGINT REFERENCES users(id),
  treatment_arm_revealed VARCHAR(50),
  sponsor_notified_at   TIMESTAMPTZ,
  regulatory_reporting_required BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── eCRF SYSTEM VALIDATION RECORDS ──────────────────────────

CREATE TABLE gcp_ecrf_systems (
  id                    BIGSERIAL PRIMARY KEY,
  system_name           VARCHAR(200) NOT NULL,
  system_version        VARCHAR(50),
  vendor_name           VARCHAR(200),
  hosting_type          VARCHAR(30), -- SaaS, on_premise, hybrid
  part_11_validated     BOOLEAN DEFAULT FALSE,
  validation_date       DATE,
  validation_report_ref VARCHAR(200),
  audit_trail_enabled   BOOLEAN DEFAULT TRUE,
  electronic_signatures BOOLEAN DEFAULT TRUE,
  role_based_access     BOOLEAN DEFAULT TRUE,
  data_lock_mechanism   BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_trial_system_qualifications (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  system_id             BIGINT REFERENCES gcp_ecrf_systems(id),
  system_type           VARCHAR(50), -- eCRF, ePRO, eTMF, CTMS, IVRS, eConsent, safety
  qualification_type    VARCHAR(30), -- IQ, OQ, PQ, UAT
  qualification_date    DATE,
  qualified_by_user_id  BIGINT REFERENCES users(id),
  report_doc_id         BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'planned',
  requalification_trigger TEXT,
  next_review_date      DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROTOCOL DEVIATIONS ──────────────────────────────────────

CREATE TABLE gcp_protocol_deviations (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  deviation_number      VARCHAR(50) UNIQUE NOT NULL,
  subject_code          VARCHAR(50),
  deviation_date        DATE NOT NULL,
  discovered_date       DATE NOT NULL,
  deviation_description TEXT NOT NULL,
  protocol_section      VARCHAR(50),
  classification        VARCHAR(20), -- major, minor, administrative
  potential_impact_on_subject BOOLEAN DEFAULT FALSE,
  potential_impact_on_data BOOLEAN DEFAULT FALSE,
  root_cause            TEXT,
  immediate_action      TEXT,
  corrective_action     TEXT,
  irb_reportable        BOOLEAN DEFAULT FALSE,
  irb_report_date       DATE,
  sponsor_notified_date DATE,
  regulatory_reportable BOOLEAN DEFAULT FALSE,
  status                VARCHAR(20) DEFAULT 'open',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);


-- ── TRIAL SITES STAFFING & DELEGATION ───────────────────────

CREATE TABLE gcp_delegation_logs (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  staff_user_id         BIGINT REFERENCES users(id),
  staff_name            VARCHAR(200) NOT NULL,
  role_title            VARCHAR(100),
  delegated_tasks       TEXT[],
  gcp_training_date     DATE,
  gcp_cert_expiry       DATE,
  protocol_training_date DATE,
  delegation_start_date DATE NOT NULL,
  delegation_end_date   DATE,
  pi_signature_date     DATE,
  authorised_for_consent BOOLEAN DEFAULT FALSE,
  authorised_for_ip     BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── CLINICAL DATA MANAGEMENT ─────────────────────────────────

CREATE TABLE gcp_data_queries (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  site_id               BIGINT REFERENCES gcp_investigator_sites(id),
  query_number          VARCHAR(50) UNIQUE NOT NULL,
  subject_code          VARCHAR(50),
  visit_name            VARCHAR(50),
  form_name             VARCHAR(100),
  field_name            VARCHAR(100),
  query_text            TEXT NOT NULL,
  raised_by_user_id     BIGINT REFERENCES users(id),
  raised_date           TIMESTAMPTZ NOT NULL,
  response_text         TEXT,
  response_date         TIMESTAMPTZ,
  response_by           VARCHAR(200),
  resolution_action     TEXT,
  resolved_date         TIMESTAMPTZ,
  query_type            VARCHAR(30), -- data_clarification, missing_data, inconsistency
  status                VARCHAR(20) DEFAULT 'open',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gcp_database_locks (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  lock_type             VARCHAR(30), -- interim, final
  lock_date             TIMESTAMPTZ NOT NULL,
  performed_by_user_id  BIGINT REFERENCES users(id),
  database_version      VARCHAR(50),
  open_queries_at_lock  INTEGER DEFAULT 0,
  missing_data_flag     BOOLEAN DEFAULT FALSE,
  statistician_sign_off BOOLEAN DEFAULT TRUE,
  dm_sign_off           BOOLEAN DEFAULT TRUE,
  medical_monitor_sign_off BOOLEAN DEFAULT TRUE,
  document_id           BIGINT REFERENCES documents(id),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── REGULATORY SUBMISSIONS (CLINICAL) ───────────────────────

CREATE TABLE gcp_regulatory_submissions (
  id                    BIGSERIAL PRIMARY KEY,
  trial_id              BIGINT REFERENCES gcp_trials(id),
  submission_type       VARCHAR(50), -- IND_initial, IND_amendment, CTA, SAE_report, SUSAR, annual_report
  regulatory_agency     VARCHAR(100),
  country_code          CHAR(2),
  submission_date       DATE NOT NULL,
  submission_reference  VARCHAR(100),
  response_date         DATE,
  response_type         VARCHAR(30), -- acknowledgement, approval, clinical_hold, questions
  response_detail       TEXT,
  document_id           BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

