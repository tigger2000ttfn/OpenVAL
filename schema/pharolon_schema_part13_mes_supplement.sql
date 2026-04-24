-- ============================================================
-- PHAROLON Schema Part 13 Supplement — MES Advanced Coverage
-- ============================================================
-- Adds: Lyophilisation, aseptic fill/finish, media fills,
--       automated visual inspection, hold time studies,
--       packaging line qualification, label control
-- ============================================================

-- ── LYOPHILISATION (FREEZE-DRYING) ───────────────────────────

CREATE TABLE mes_lyophilisation_recipes (
  id                    BIGSERIAL PRIMARY KEY,
  recipe_code           VARCHAR(50) UNIQUE NOT NULL,
  recipe_version        INTEGER DEFAULT 1,
  product_id            BIGINT REFERENCES mes_products(id),
  lyo_cycle_type        VARCHAR(30), -- pharmaceutical, biological, diagnostic
  -- Loading conditions
  shelf_loading_temp_c  NUMERIC(6,2),
  loading_time_min      INTEGER,
  -- Freezing phase
  freezing_rate_c_per_min NUMERIC(6,3),
  target_freeze_temp_c  NUMERIC(6,2),
  freeze_hold_min       INTEGER,
  -- Primary drying
  primary_drying_shelf_temp_c NUMERIC(6,2),
  primary_drying_pressure_mtorr NUMERIC(8,3),
  primary_drying_duration_hrs NUMERIC(8,2),
  product_temp_target_c NUMERIC(6,2),
  -- Secondary drying
  secondary_drying_shelf_temp_c NUMERIC(6,2),
  secondary_drying_pressure_mtorr NUMERIC(8,3),
  secondary_drying_duration_hrs NUMERIC(8,2),
  -- Stoppering
  stoppering_pressure   VARCHAR(30),
  backfill_gas          VARCHAR(20), -- nitrogen, argon
  -- Endpoints
  residual_moisture_spec_pct NUMERIC(6,4),
  reconstitution_time_limit_sec INTEGER,
  approved_by_user_id   BIGINT REFERENCES users(id),
  approval_date         DATE,
  status                VARCHAR(20) DEFAULT 'approved',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_lyophilisation_cycles (
  id                    BIGSERIAL PRIMARY KEY,
  batch_record_id       BIGINT REFERENCES mes_batch_records(id),
  recipe_id             BIGINT REFERENCES mes_lyophilisation_recipes(id),
  lyo_unit_id           BIGINT REFERENCES mes_equipment(id),
  cycle_number          VARCHAR(50) UNIQUE NOT NULL,
  cycle_start           TIMESTAMPTZ,
  cycle_end             TIMESTAMPTZ,
  units_loaded          INTEGER,
  shelf_area_m2         NUMERIC(8,4),
  fill_volume_ml        NUMERIC(8,3),
  actual_freeze_temp_c  NUMERIC(6,3),
  primary_drying_completed BOOLEAN DEFAULT FALSE,
  primary_drying_endpoint_method VARCHAR(50), -- pirani, MTM, product_temp_rise
  secondary_drying_completed BOOLEAN DEFAULT FALSE,
  stoppering_completed  BOOLEAN DEFAULT FALSE,
  backfill_gas_confirmed BOOLEAN DEFAULT FALSE,
  cycle_status          VARCHAR(20) DEFAULT 'in_progress',
  operator_user_id      BIGINT REFERENCES users(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_lyo_cycle_parameters (
  id                    BIGSERIAL PRIMARY KEY,
  cycle_id              BIGINT REFERENCES mes_lyophilisation_cycles(id),
  timestamp             TIMESTAMPTZ NOT NULL,
  phase                 VARCHAR(20), -- loading, freezing, primary_drying, secondary_drying, stoppering
  shelf_temp_c          NUMERIC(6,3),
  condenser_temp_c      NUMERIC(6,3),
  chamber_pressure_mtorr NUMERIC(10,4),
  product_temp_c        NUMERIC(6,3), -- thermocouple reading
  pirani_pressure_mtorr NUMERIC(10,4),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON mes_lyo_cycle_parameters(cycle_id, timestamp);

CREATE TABLE mes_lyo_endpoint_tests (
  id                    BIGSERIAL PRIMARY KEY,
  cycle_id              BIGINT REFERENCES mes_lyophilisation_cycles(id),
  test_type             VARCHAR(30), -- karl_fischer, pirani_capacitance_comparison, visual
  test_date             TIMESTAMPTZ,
  vials_tested          INTEGER,
  result_value          NUMERIC(10,6),
  result_unit           VARCHAR(20),
  specification         VARCHAR(100),
  pass_fail             VARCHAR(10),
  analyst_user_id       BIGINT REFERENCES users(id),
  test_result_id        BIGINT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── ASEPTIC FILL/FINISH ──────────────────────────────────────

CREATE TABLE mes_filling_lines (
  id                    BIGSERIAL PRIMARY KEY,
  equipment_id          BIGINT REFERENCES mes_equipment(id),
  line_name             VARCHAR(100) NOT NULL,
  room_id               BIGINT REFERENCES mes_rooms(id),
  iso_class             VARCHAR(10), -- ISO 5, ISO 7
  line_type             VARCHAR(50), -- vial, syringe, cartridge, ampoule, bag
  fill_volume_range_ml  NUMRANGE,
  fill_speed_units_per_hr INTEGER,
  stopper_type          VARCHAR(100),
  crimp_type            VARCHAR(50),
  last_media_fill_date  DATE,
  qualification_status  VARCHAR(30) DEFAULT 'qualified',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_fill_operations (
  id                    BIGSERIAL PRIMARY KEY,
  batch_record_id       BIGINT REFERENCES mes_batch_records(id),
  filling_line_id       BIGINT REFERENCES mes_filling_lines(id),
  fill_start            TIMESTAMPTZ,
  fill_end              TIMESTAMPTZ,
  fill_volume_target_ml NUMERIC(8,4),
  fill_speed_uph        INTEGER,
  temperature_c         NUMERIC(5,2),
  humidity_pct          NUMERIC(5,2),
  operator_user_id      BIGINT REFERENCES users(id),
  units_filled          INTEGER,
  units_rejected_visual INTEGER DEFAULT 0,
  units_rejected_weight INTEGER DEFAULT 0,
  fill_weight_checks_passed BOOLEAN DEFAULT TRUE,
  status                VARCHAR(20) DEFAULT 'in_progress',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_fill_weight_iqc (
  id                    BIGSERIAL PRIMARY KEY,
  fill_operation_id     BIGINT REFERENCES mes_fill_operations(id),
  check_time            TIMESTAMPTZ NOT NULL,
  operator_user_id      BIGINT REFERENCES users(id),
  sample_size           INTEGER DEFAULT 5,
  fill_weights_g        NUMERIC(10,4)[],
  mean_fill_g           NUMERIC(10,4),
  range_fill_g          NUMERIC(10,4),
  target_fill_g         NUMERIC(10,4),
  lower_limit_g         NUMERIC(10,4),
  upper_limit_g         NUMERIC(10,4),
  action_limit_g        NUMERIC(10,4),
  within_limits         BOOLEAN,
  action_taken          TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_container_closure_integrity (
  id                    BIGSERIAL PRIMARY KEY,
  batch_record_id       BIGINT REFERENCES mes_batch_records(id),
  test_method           VARCHAR(50), -- HVLD, vacuum_decay, dye_ingress, headspace_analysis
  test_date             TIMESTAMPTZ,
  sample_size           INTEGER,
  units_tested          INTEGER,
  units_passed          INTEGER,
  units_failed          INTEGER,
  failure_rate_pct      NUMERIC(5,4),
  acceptance_criterion  VARCHAR(100),
  pass_fail             VARCHAR(10),
  instrument_id         BIGINT REFERENCES mes_equipment(id),
  operator_user_id      BIGINT REFERENCES users(id),
  test_result_id        BIGINT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_stopper_crimp_records (
  id                    BIGSERIAL PRIMARY KEY,
  fill_operation_id     BIGINT REFERENCES mes_fill_operations(id),
  check_time            TIMESTAMPTZ NOT NULL,
  crimp_force_n         NUMERIC(8,3),
  crimp_force_target_n  NUMERIC(8,3),
  crimp_force_lsl_n     NUMERIC(8,3),
  crimp_force_usl_n     NUMERIC(8,3),
  visual_inspection_ok  BOOLEAN DEFAULT TRUE,
  defects_observed      TEXT,
  operator_user_id      BIGINT REFERENCES users(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── PROCESS SIMULATION (MEDIA FILL) ─────────────────────────

CREATE TABLE mes_media_fill_programs (
  id                    BIGSERIAL PRIMARY KEY,
  filling_line_id       BIGINT REFERENCES mes_filling_lines(id),
  program_name          VARCHAR(200),
  rationale             TEXT,
  frequency_per_year    INTEGER DEFAULT 2,
  minimum_units         INTEGER DEFAULT 5000,
  incubation_temp_c     NUMERIC(5,2) DEFAULT 30.0,
  incubation_duration_days INTEGER DEFAULT 14,
  inspection_method     VARCHAR(50),
  acceptance_criterion  TEXT,
  last_run_date         DATE,
  next_run_due          DATE,
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_media_fills (
  id                    BIGSERIAL PRIMARY KEY,
  program_id            BIGINT REFERENCES mes_media_fill_programs(id),
  batch_number          VARCHAR(100) UNIQUE NOT NULL,
  media_type            VARCHAR(100), -- SCDB, FTM, TSB
  media_lot             VARCHAR(100),
  media_growth_promotion_ok BOOLEAN DEFAULT TRUE,
  growth_promotion_date DATE,
  fill_date             TIMESTAMPTZ,
  shift_covered         VARCHAR(20), -- day, evening, night
  operators_involved    VARCHAR(500),
  line_interventions    TEXT,
  units_filled          INTEGER,
  units_incubated       INTEGER,
  incubation_start      DATE,
  incubation_end        DATE,
  units_contaminated    INTEGER DEFAULT 0,
  contamination_rate_ppm NUMERIC(10,4),
  outcome               VARCHAR(20), -- pass, fail
  failure_investigation_id BIGINT REFERENCES capas(id),
  report_doc_id         BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_media_fill_interventions (
  id                    BIGSERIAL PRIMARY KEY,
  media_fill_id         BIGINT REFERENCES mes_media_fills(id),
  intervention_time     TIMESTAMPTZ,
  intervention_type     VARCHAR(50), -- line_stoppage, machine_jam, glove_change, stopper_replenishment
  description           TEXT,
  duration_minutes      INTEGER,
  operator_user_id      BIGINT REFERENCES users(id),
  risk_assessed         BOOLEAN DEFAULT TRUE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── AUTOMATED VISUAL INSPECTION ─────────────────────────────

CREATE TABLE mes_avi_systems (
  id                    BIGSERIAL PRIMARY KEY,
  equipment_id          BIGINT REFERENCES mes_equipment(id),
  avi_system_name       VARCHAR(100),
  manufacturer          VARCHAR(100),
  container_type        VARCHAR(50), -- vial, syringe, cartridge, ampoule
  inspection_types      TEXT[], -- particulate, cosmetic, fill_level, stopper, crimp
  camera_count          INTEGER,
  inspection_speed_uph  INTEGER,
  validation_status     VARCHAR(30) DEFAULT 'validated',
  last_validation_date  DATE,
  revalidation_due      DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_avi_test_sets (
  id                    BIGSERIAL PRIMARY KEY,
  avi_system_id         BIGINT REFERENCES mes_avi_systems(id),
  set_name              VARCHAR(100),
  set_code              VARCHAR(50) UNIQUE,
  preparation_date      DATE,
  prepared_by_user_id   BIGINT REFERENCES users(id),
  container_type        VARCHAR(50),
  total_units           INTEGER,
  defect_units          INTEGER,
  good_units            INTEGER,
  knurled_units         INTEGER,
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_avi_defect_categories (
  id                    BIGSERIAL PRIMARY KEY,
  test_set_id           BIGINT REFERENCES mes_avi_test_sets(id),
  defect_type           VARCHAR(100), -- glass_particle, fibre, stopper_defect, cosmetic
  severity              VARCHAR(20), -- critical, major, minor
  units_in_set          INTEGER,
  required_detection_pct NUMERIC(5,2),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_avi_qualification_runs (
  id                    BIGSERIAL PRIMARY KEY,
  avi_system_id         BIGINT REFERENCES mes_avi_systems(id),
  test_set_id           BIGINT REFERENCES mes_avi_test_sets(id),
  run_date              TIMESTAMPTZ,
  operator_user_id      BIGINT REFERENCES users(id),
  run_speed_uph         INTEGER,
  units_inspected       INTEGER,
  true_positives        INTEGER,  -- defective units correctly rejected
  false_negatives       INTEGER,  -- defective units passed (missed)
  false_positives       INTEGER,  -- good units rejected
  true_negatives        INTEGER,  -- good units passed
  sensitivity_pct       NUMERIC(8,4),
  specificity_pct       NUMERIC(8,4),
  pass_fail             VARCHAR(10),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_avi_production_records (
  id                    BIGSERIAL PRIMARY KEY,
  batch_record_id       BIGINT REFERENCES mes_batch_records(id),
  avi_system_id         BIGINT REFERENCES mes_avi_systems(id),
  inspection_date       TIMESTAMPTZ,
  inspection_speed_uph  INTEGER,
  units_presented       INTEGER,
  units_passed          INTEGER,
  units_rejected        INTEGER,
  reject_rate_pct       NUMERIC(8,4),
  reject_categories     JSONB,  -- counts by defect type
  false_reject_sample   INTEGER,
  human_inspection_override INTEGER DEFAULT 0,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── HOLD TIME STUDIES ────────────────────────────────────────

CREATE TABLE mes_hold_time_studies (
  id                    BIGSERIAL PRIMARY KEY,
  study_code            VARCHAR(50) UNIQUE NOT NULL,
  material_name         VARCHAR(200),
  material_type         VARCHAR(50), -- bulk_drug_substance, in_process_intermediate, formulated_bulk
  product_id            BIGINT REFERENCES mes_products(id),
  hold_conditions       TEXT,
  temperature_c         NUMERIC(6,2),
  humidity_pct          NUMERIC(5,2),
  container_type        VARCHAR(100),
  protocol_doc_id       BIGINT REFERENCES documents(id),
  start_date            DATE,
  status                VARCHAR(20) DEFAULT 'ongoing',
  report_doc_id         BIGINT REFERENCES documents(id),
  approved_hold_time    VARCHAR(50),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE mes_hold_time_timepoints (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES mes_hold_time_studies(id),
  planned_day           INTEGER,
  actual_sampling_date  DATE,
  tests_performed       TEXT[],
  pass_fail             VARCHAR(10),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

