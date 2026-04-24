-- ============================================================
-- PHAROLON Schema Part 14 — GDP / Good Distribution Practice
-- ============================================================
-- Regulatory basis:
--   EU GDP Guidelines 2013/C 343/01
--   WHO TRS 961 Annex 9 (time/temperature sensitive products)
--   USP <1079> Good storage and distribution practices
--   IATA TCR (Temperature Control Regulations)
--   EU FMD Directive 2011/62/EU (falsified medicines)
--   ICH Q10 (pharmaceutical quality system — distribution elements)
-- ============================================================

-- ── RESPONSIBLE PERSON & GDP ORGANISATION ──────────────────

CREATE TABLE gdp_responsible_persons (
  id                    BIGSERIAL PRIMARY KEY,
  site_id               BIGINT REFERENCES sites(id),
  user_id               BIGINT REFERENCES users(id),
  qualification_evidence TEXT,
  appointment_date      DATE NOT NULL,
  competent_authority_notified BOOLEAN DEFAULT FALSE,
  notification_date     DATE,
  notification_reference VARCHAR(100),
  gdwp_licence_number   VARCHAR(100),
  scope_of_responsibility TEXT,
  deputy_rp_user_id     BIGINT REFERENCES users(id),
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_wholesale_licences (
  id                    BIGSERIAL PRIMARY KEY,
  organisation_id       BIGINT REFERENCES organizations(id),
  licence_number        VARCHAR(100) UNIQUE NOT NULL,
  issuing_authority     VARCHAR(200),
  country_code          CHAR(2),
  licence_type          VARCHAR(50), -- WDA(H), WDA(V), API, broker
  issue_date            DATE NOT NULL,
  expiry_date           DATE,
  scope_description     TEXT,
  product_categories    TEXT[], -- human, veterinary, controlled, narcotic
  authorised_activities TEXT[],
  status                VARCHAR(20) DEFAULT 'active',
  last_inspection_date  DATE,
  next_inspection_due   DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_broker_registrations (
  id                    BIGSERIAL PRIMARY KEY,
  organisation_id       BIGINT REFERENCES organizations(id),
  broker_name           VARCHAR(200) NOT NULL,
  registration_number   VARCHAR(100),
  competent_authority   VARCHAR(200),
  country_code          CHAR(2),
  registration_date     DATE,
  expiry_date           DATE,
  scope                 TEXT,
  quality_system_verified BOOLEAN DEFAULT FALSE,
  verification_date     DATE,
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── WAREHOUSE / PREMISES ────────────────────────────────────

CREATE TABLE gdp_warehouses (
  id                    BIGSERIAL PRIMARY KEY,
  site_id               BIGINT REFERENCES sites(id),
  warehouse_name        VARCHAR(200) NOT NULL,
  warehouse_code        VARCHAR(50) UNIQUE,
  address               TEXT,
  gps_coordinates       POINT,
  gdp_licence_id        BIGINT REFERENCES gdp_wholesale_licences(id),
  temperature_zones     TEXT[], -- ambient, +2-8C, +15-25C, frozen, ultra-frozen
  total_area_sqm        NUMERIC(10,2),
  controlled_area_sqm   NUMERIC(10,2),
  controlled_substance_capability BOOLEAN DEFAULT FALSE,
  narcotics_vault       BOOLEAN DEFAULT FALSE,
  status                VARCHAR(20) DEFAULT 'operational',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_warehouse_zones (
  id                    BIGSERIAL PRIMARY KEY,
  warehouse_id          BIGINT REFERENCES gdp_warehouses(id),
  zone_name             VARCHAR(100) NOT NULL,
  zone_code             VARCHAR(20),
  zone_type             VARCHAR(50), -- receiving, quarantine, approved, rejected, dispatch, cold, frozen
  temperature_min_c     NUMERIC(6,2),
  temperature_max_c     NUMERIC(6,2),
  humidity_min_pct      NUMERIC(5,2),
  humidity_max_pct      NUMERIC(5,2),
  area_sqm              NUMERIC(10,2),
  access_controlled     BOOLEAN DEFAULT TRUE,
  cctv_monitored        BOOLEAN DEFAULT FALSE,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── TEMPERATURE MAPPING ─────────────────────────────────────

CREATE TABLE gdp_mapping_studies (
  id                    BIGSERIAL PRIMARY KEY,
  warehouse_id          BIGINT REFERENCES gdp_warehouses(id),
  zone_id               BIGINT REFERENCES gdp_warehouse_zones(id),
  study_code            VARCHAR(50) UNIQUE NOT NULL,
  mapping_type          VARCHAR(30), -- empty, occupied, summer, winter, loaded
  season                VARCHAR(10),
  study_purpose         TEXT,
  protocol_doc_id       BIGINT REFERENCES documents(id),
  start_date            TIMESTAMPTZ,
  end_date              TIMESTAMPTZ,
  duration_hours        INTEGER,
  number_of_loggers     INTEGER,
  logger_placement_map  TEXT, -- reference to drawing/diagram
  ambient_conditions    TEXT, -- external weather conditions during study
  hvac_operational      BOOLEAN DEFAULT TRUE,
  status                VARCHAR(20) DEFAULT 'planned',
  conclusion            TEXT,
  report_doc_id         BIGINT REFERENCES documents(id),
  approved_by_user_id   BIGINT REFERENCES users(id),
  approval_date         TIMESTAMPTZ,
  next_mapping_due      DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_mapping_loggers (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES gdp_mapping_studies(id),
  instrument_id         BIGINT,
  logger_serial         VARCHAR(100),
  placement_location    TEXT NOT NULL,
  x_position_m          NUMERIC(6,2),
  y_position_m          NUMERIC(6,2),
  z_height_m            NUMERIC(6,2),
  calibration_cert_ref  VARCHAR(100),
  calibration_date      DATE,
  calibration_due       DATE,
  iso17025_traceable    BOOLEAN DEFAULT TRUE,
  data_file_ref         VARCHAR(500),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_mapping_data_points (
  id                    BIGSERIAL PRIMARY KEY,
  logger_id             BIGINT REFERENCES gdp_mapping_loggers(id),
  timestamp             TIMESTAMPTZ NOT NULL,
  temperature_c         NUMERIC(6,3),
  humidity_pct          NUMERIC(5,2),
  is_excursion          BOOLEAN GENERATED ALWAYS AS (FALSE) STORED,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_mapping_conclusions (
  id                    BIGSERIAL PRIMARY KEY,
  study_id              BIGINT REFERENCES gdp_mapping_studies(id),
  min_temp_c            NUMERIC(6,3),
  max_temp_c            NUMERIC(6,3),
  mean_temp_c           NUMERIC(6,3),
  temp_uniformity_ok    BOOLEAN,
  hot_spots_identified  BOOLEAN,
  hot_spot_locations    TEXT,
  cold_spots_identified BOOLEAN,
  cold_spot_locations   TEXT,
  mkt_c                 NUMERIC(6,3),
  recommended_storage_zones TEXT,
  restrictions          TEXT,
  requalification_trigger TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── TEMPERATURE MONITORING (CONTINUOUS) ─────────────────────

CREATE TABLE gdp_monitoring_devices (
  id                    BIGSERIAL PRIMARY KEY,
  warehouse_zone_id     BIGINT REFERENCES gdp_warehouse_zones(id),
  device_serial         VARCHAR(100) NOT NULL,
  device_type           VARCHAR(50), -- datalogger, wireless, IoT, NIST-traceable
  manufacturer          VARCHAR(100),
  model                 VARCHAR(100),
  measurement_range_min NUMERIC(6,2),
  measurement_range_max NUMERIC(6,2),
  accuracy_c            NUMERIC(4,3),
  resolution_c          NUMERIC(4,3),
  logging_interval_min  INTEGER,
  alarm_low_c           NUMERIC(6,2),
  alarm_high_c          NUMERIC(6,2),
  calibration_due       DATE,
  last_calibration      DATE,
  calibration_cert      VARCHAR(200),
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_temperature_records (
  id                    BIGSERIAL PRIMARY KEY,
  device_id             BIGINT REFERENCES gdp_monitoring_devices(id),
  timestamp             TIMESTAMPTZ NOT NULL,
  temperature_c         NUMERIC(6,3) NOT NULL,
  humidity_pct          NUMERIC(5,2),
  alarm_triggered       BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX ON gdp_temperature_records(device_id, timestamp);

CREATE TABLE gdp_temperature_excursions (
  id                    BIGSERIAL PRIMARY KEY,
  device_id             BIGINT REFERENCES gdp_monitoring_devices(id),
  warehouse_zone_id     BIGINT REFERENCES gdp_warehouse_zones(id),
  excursion_start       TIMESTAMPTZ NOT NULL,
  excursion_end         TIMESTAMPTZ,
  duration_minutes      INTEGER,
  min_temp_c            NUMERIC(6,3),
  max_temp_c            NUMERIC(6,3),
  mkt_c                 NUMERIC(6,3),
  root_cause            TEXT,
  products_affected     TEXT,
  batches_affected      TEXT[],
  immediate_action      TEXT,
  disposition_decision  VARCHAR(50), -- approved_release, quarantine, reject, use_as_is
  disposition_rationale TEXT,
  quality_risk_assessment TEXT,
  capa_id               BIGINT REFERENCES capas(id),
  deviation_id          BIGINT REFERENCES deviations(id),
  closed_by_user_id     BIGINT REFERENCES users(id),
  closed_at             TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── SUPPLIER & 3PL QUALIFICATION ────────────────────────────

CREATE TABLE gdp_suppliers (
  id                    BIGSERIAL PRIMARY KEY,
  organisation_id       BIGINT REFERENCES organizations(id),
  supplier_name         VARCHAR(200) NOT NULL,
  supplier_type         VARCHAR(50), -- manufacturer, wholesaler, 3PL, broker, carrier
  country_code          CHAR(2),
  gdp_licence_number    VARCHAR(100),
  qualification_status  VARCHAR(30) DEFAULT 'pending',
  initial_qualification_date DATE,
  last_audit_date       DATE,
  next_audit_due        DATE,
  risk_rating           VARCHAR(10), -- low, medium, high
  approved_for_products TEXT[],
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_carrier_qualifications (
  id                    BIGSERIAL PRIMARY KEY,
  supplier_id           BIGINT REFERENCES gdp_suppliers(id),
  carrier_name          VARCHAR(200),
  transport_modes       TEXT[], -- air, road, sea, rail, courier
  temperature_capability TEXT[], -- ambient, cold, frozen, ultra-frozen
  iata_ceiv_certified   BOOLEAN DEFAULT FALSE,
  ceiv_cert_number      VARCHAR(100),
  ceiv_expiry           DATE,
  lane_qualification_required BOOLEAN DEFAULT TRUE,
  qualification_status  VARCHAR(30),
  qualification_date    DATE,
  requalification_due   DATE,
  approved_lanes        TEXT,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── TRANSPORT LANE QUALIFICATION ────────────────────────────

CREATE TABLE gdp_transport_lanes (
  id                    BIGSERIAL PRIMARY KEY,
  origin_site_id        BIGINT REFERENCES sites(id),
  destination_site_id   BIGINT REFERENCES sites(id),
  origin_description    TEXT,
  destination_description TEXT,
  carrier_id            BIGINT REFERENCES gdp_suppliers(id),
  transport_mode        VARCHAR(30),
  temperature_zone      VARCHAR(30),
  typical_duration_hours NUMERIC(6,1),
  seasonal_risk         VARCHAR(20), -- low, medium, high
  lane_code             VARCHAR(50) UNIQUE,
  qualification_status  VARCHAR(30) DEFAULT 'pending',
  last_qualified_date   DATE,
  requalification_due   DATE,
  approved_for_products TEXT[],
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_lane_qualification_studies (
  id                    BIGSERIAL PRIMARY KEY,
  lane_id               BIGINT REFERENCES gdp_transport_lanes(id),
  study_code            VARCHAR(50) UNIQUE NOT NULL,
  study_type            VARCHAR(30), -- prospective, retrospective, challenge
  packaging_system_id   BIGINT,
  season                VARCHAR(10),
  ambient_conditions    TEXT,
  number_of_runs        INTEGER,
  protocol_doc_id       BIGINT REFERENCES documents(id),
  start_date            DATE,
  end_date              DATE,
  status                VARCHAR(20) DEFAULT 'planned',
  outcome               VARCHAR(20), -- pass, fail, conditional
  report_doc_id         BIGINT REFERENCES documents(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── PACKAGING SYSTEM QUALIFICATION ──────────────────────────

CREATE TABLE gdp_packaging_systems (
  id                    BIGSERIAL PRIMARY KEY,
  system_name           VARCHAR(200) NOT NULL,
  manufacturer          VARCHAR(200),
  system_type           VARCHAR(50), -- passive, active, hybrid
  temperature_zone      VARCHAR(30),
  payload_volume_l      NUMERIC(8,2),
  ice_pack_type         VARCHAR(100),
  pcm_type              VARCHAR(100),
  rated_duration_hours  NUMERIC(6,1),
  qualification_status  VARCHAR(30) DEFAULT 'pending',
  qualification_date    DATE,
  requalification_due   DATE,
  validated_lanes       TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_packaging_qualification_runs (
  id                    BIGSERIAL PRIMARY KEY,
  packaging_system_id   BIGINT REFERENCES gdp_packaging_systems(id),
  run_date              DATE NOT NULL,
  ambient_temp_c        NUMERIC(5,2),
  condition_type        VARCHAR(30), -- summer, winter, extreme, standard
  payload_mass_kg       NUMERIC(8,3),
  duration_hours        NUMERIC(6,2),
  outcome               VARCHAR(20), -- pass, fail
  max_payload_temp_c    NUMERIC(6,3),
  min_payload_temp_c    NUMERIC(6,3),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── DISTRIBUTION ORDERS & SHIPMENTS ─────────────────────────

CREATE TABLE gdp_distribution_orders (
  id                    BIGSERIAL PRIMARY KEY,
  order_number          VARCHAR(100) UNIQUE NOT NULL,
  origin_warehouse_id   BIGINT REFERENCES gdp_warehouses(id),
  destination_type      VARCHAR(30), -- wholesaler, pharmacy, hospital, site, MAH
  destination_name      VARCHAR(200),
  destination_address   TEXT,
  customer_licence      VARCHAR(100),
  carrier_id            BIGINT REFERENCES gdp_suppliers(id),
  lane_id               BIGINT REFERENCES gdp_transport_lanes(id),
  packaging_system_id   BIGINT REFERENCES gdp_packaging_systems(id),
  planned_dispatch      TIMESTAMPTZ,
  actual_dispatch       TIMESTAMPTZ,
  expected_delivery     TIMESTAMPTZ,
  actual_delivery       TIMESTAMPTZ,
  temperature_zone      VARCHAR(30),
  order_status          VARCHAR(30) DEFAULT 'draft',
  dispatched_by_user_id BIGINT REFERENCES users(id),
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_shipment_lines (
  id                    BIGSERIAL PRIMARY KEY,
  order_id              BIGINT REFERENCES gdp_distribution_orders(id),
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  expiry_date           DATE,
  quantity              NUMERIC(12,3),
  unit_of_measure       VARCHAR(20),
  serialisation_required BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_shipment_temperature_logs (
  id                    BIGSERIAL PRIMARY KEY,
  order_id              BIGINT REFERENCES gdp_distribution_orders(id),
  logger_serial         VARCHAR(100),
  timestamp             TIMESTAMPTZ NOT NULL,
  temperature_c         NUMERIC(6,3),
  excursion_flag        BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_delivery_receipts (
  id                    BIGSERIAL PRIMARY KEY,
  order_id              BIGINT REFERENCES gdp_distribution_orders(id),
  received_by           VARCHAR(200),
  receipt_timestamp     TIMESTAMPTZ NOT NULL,
  condition_on_receipt  VARCHAR(30), -- acceptable, damaged, temperature_excursion
  temperature_at_receipt NUMERIC(6,3),
  packaging_integrity   BOOLEAN,
  mkt_in_transit_c      NUMERIC(6,3),
  excursion_during_transit BOOLEAN DEFAULT FALSE,
  excursion_investigation_id BIGINT REFERENCES gdp_temperature_excursions(id),
  accepted              BOOLEAN,
  rejection_reason      TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── RETURN GOODS ────────────────────────────────────────────

CREATE TABLE gdp_return_orders (
  id                    BIGSERIAL PRIMARY KEY,
  return_number         VARCHAR(100) UNIQUE NOT NULL,
  original_order_id     BIGINT REFERENCES gdp_distribution_orders(id),
  return_reason         VARCHAR(100),
  return_reason_detail  TEXT,
  returned_by           VARCHAR(200),
  receipt_date          TIMESTAMPTZ,
  warehouse_id          BIGINT REFERENCES gdp_warehouses(id),
  initial_quarantine    BOOLEAN DEFAULT TRUE,
  risk_assessment_required BOOLEAN DEFAULT TRUE,
  risk_assessment_doc_id BIGINT REFERENCES documents(id),
  disposition           VARCHAR(30), -- restock, destroy, return_to_manufacturer, quarantine
  disposition_rationale TEXT,
  disposed_by_user_id   BIGINT REFERENCES users(id),
  disposition_date      DATE,
  status                VARCHAR(30) DEFAULT 'received',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_return_lines (
  id                    BIGSERIAL PRIMARY KEY,
  return_id             BIGINT REFERENCES gdp_return_orders(id),
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  quantity              NUMERIC(12,3),
  unit_of_measure       VARCHAR(20),
  condition             VARCHAR(30), -- good, damaged, expired, temperature_compromised
  storage_condition_maintained BOOLEAN,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── FALSIFIED MEDICINES (EU FMD) ────────────────────────────

CREATE TABLE gdp_fmd_system_registrations (
  id                    BIGSERIAL PRIMARY KEY,
  organisation_id       BIGINT REFERENCES organizations(id),
  nmvs_connection_id    VARCHAR(100), -- EU NMVS (National Medicines Verification System)
  country_code          CHAR(2),
  registration_date     DATE,
  system_supplier       VARCHAR(100),
  interface_type        VARCHAR(50), -- direct, via_MAH, via_3PL
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_serialisation_events (
  id                    BIGSERIAL PRIMARY KEY,
  order_id              BIGINT REFERENCES gdp_distribution_orders(id),
  serial_number         VARCHAR(200) NOT NULL,
  batch_number          VARCHAR(100),
  product_code          VARCHAR(100),
  event_type            VARCHAR(30), -- verification, supply, decommission, alert
  event_timestamp       TIMESTAMPTZ NOT NULL,
  performed_at_site_id  BIGINT REFERENCES sites(id),
  nmvs_response         VARCHAR(30), -- success, failure, unknown, alert_raised
  nmvs_response_code    VARCHAR(20),
  nmvs_response_detail  TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_falsified_medicine_alerts (
  id                    BIGSERIAL PRIMARY KEY,
  alert_source          VARCHAR(50), -- nmvs, regulator, internal, supplier
  alert_reference       VARCHAR(100),
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  serial_number         VARCHAR(200),
  alert_description     TEXT,
  received_date         TIMESTAMPTZ,
  investigation_required BOOLEAN DEFAULT TRUE,
  quarantine_initiated  BOOLEAN DEFAULT FALSE,
  outcome               TEXT,
  regulatory_notification_required BOOLEAN DEFAULT FALSE,
  regulatory_notified_date DATE,
  closed_at             TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── GDP SELF-INSPECTIONS ─────────────────────────────────────

CREATE TABLE gdp_self_inspections (
  id                    BIGSERIAL PRIMARY KEY,
  warehouse_id          BIGINT REFERENCES gdp_warehouses(id),
  inspection_date       DATE NOT NULL,
  lead_inspector_user_id BIGINT REFERENCES users(id),
  scope                 TEXT,
  gdp_chapter_coverage  TEXT[],
  findings_count_critical INTEGER DEFAULT 0,
  findings_count_major   INTEGER DEFAULT 0,
  findings_count_minor   INTEGER DEFAULT 0,
  report_doc_id         BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'planned',
  closed_at             DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_self_inspection_findings (
  id                    BIGSERIAL PRIMARY KEY,
  inspection_id         BIGINT REFERENCES gdp_self_inspections(id),
  finding_number        VARCHAR(20),
  gdp_chapter_ref       VARCHAR(20),
  classification        VARCHAR(10), -- critical, major, minor, observation
  description           TEXT NOT NULL,
  evidence              TEXT,
  root_cause            TEXT,
  capa_id               BIGINT REFERENCES capas(id),
  due_date              DATE,
  closed_date           DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── MKT CALCULATION RECORDS ─────────────────────────────────

CREATE TABLE gdp_mkt_calculations (
  id                    BIGSERIAL PRIMARY KEY,
  excursion_id          BIGINT REFERENCES gdp_temperature_excursions(id),
  shipment_id           BIGINT REFERENCES gdp_distribution_orders(id),
  calculation_date      TIMESTAMPTZ DEFAULT NOW(),
  activation_energy_kj  NUMERIC(8,3) DEFAULT 83.14,
  delta_h_j_mol         NUMERIC(10,2),
  reference_temp_c      NUMERIC(6,2),
  data_points_used      INTEGER,
  time_interval_hours   NUMERIC(6,2),
  mkt_c                 NUMERIC(6,3) NOT NULL,
  mkt_within_spec       BOOLEAN,
  specification_max_c   NUMERIC(6,2),
  calculated_by_user_id BIGINT REFERENCES users(id),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);


-- ── CONTROLLED SUBSTANCES DISTRIBUTION ──────────────────────

CREATE TABLE gdp_controlled_substance_licences (
  id                    BIGSERIAL PRIMARY KEY,
  organisation_id       BIGINT REFERENCES organizations(id),
  licence_number        VARCHAR(100) UNIQUE NOT NULL,
  issuing_authority     VARCHAR(200),
  country_code          CHAR(2),
  schedule_categories   TEXT[], -- schedule 1-5, class A/B/C
  product_types_covered TEXT[],
  issue_date            DATE NOT NULL,
  expiry_date           DATE,
  storage_conditions    TEXT,
  status                VARCHAR(20) DEFAULT 'active',
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_controlled_substance_transactions (
  id                    BIGSERIAL PRIMARY KEY,
  licence_id            BIGINT REFERENCES gdp_controlled_substance_licences(id),
  transaction_type      VARCHAR(30), -- receipt, issue, destruction, return, loss
  transaction_date      TIMESTAMPTZ NOT NULL,
  product_name          VARCHAR(200),
  batch_number          VARCHAR(100),
  schedule_category     VARCHAR(20),
  quantity_in           NUMERIC(12,4),
  quantity_out          NUMERIC(12,4),
  balance_after         NUMERIC(12,4),
  unit_of_measure       VARCHAR(20),
  supplier_or_recipient VARCHAR(200),
  authorised_by_user_id BIGINT REFERENCES users(id),
  witness_user_id       BIGINT REFERENCES users(id),
  regulatory_report_ref VARCHAR(100),
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── IMPORT / EXPORT COMPLIANCE ───────────────────────────────

CREATE TABLE gdp_import_export_records (
  id                    BIGSERIAL PRIMARY KEY,
  direction             VARCHAR(10) NOT NULL, -- import, export
  shipment_id           BIGINT REFERENCES gdp_distribution_orders(id),
  customs_declaration_ref VARCHAR(100),
  country_of_origin     CHAR(2),
  destination_country   CHAR(2),
  import_licence_ref    VARCHAR(100),
  export_licence_ref    VARCHAR(100),
  customs_clearance_date TIMESTAMPTZ,
  hs_code               VARCHAR(20),
  declared_value        NUMERIC(14,2),
  currency              CHAR(3),
  cold_chain_maintained BOOLEAN,
  customs_inspection    BOOLEAN DEFAULT FALSE,
  customs_inspection_date TIMESTAMPTZ,
  result                VARCHAR(20), -- cleared, held, rejected
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

-- ── GDP QUALITY MANAGEMENT RECORDS ──────────────────────────

CREATE TABLE gdp_quality_agreements (
  id                    BIGSERIAL PRIMARY KEY,
  supplier_id           BIGINT REFERENCES gdp_suppliers(id),
  agreement_title       VARCHAR(200),
  agreement_version     VARCHAR(20),
  effective_date        DATE,
  expiry_date           DATE,
  scope                 TEXT,
  responsibilities_matrix TEXT,
  gdp_chapters_covered  TEXT[],
  document_id           BIGINT REFERENCES documents(id),
  status                VARCHAR(20) DEFAULT 'active',
  last_reviewed_date    DATE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_product_recalls (
  id                    BIGSERIAL PRIMARY KEY,
  recall_number         VARCHAR(100) UNIQUE NOT NULL,
  recall_type           VARCHAR(30), -- voluntary, mandatory
  recall_class          VARCHAR(10), -- Class I, II, III
  product_name          VARCHAR(200),
  batch_numbers         TEXT[],
  reason               TEXT NOT NULL,
  regulatory_notification_date TIMESTAMPTZ,
  competent_authority   VARCHAR(200),
  rapid_alert_system    VARCHAR(50), -- RASFF, RAS, state_level
  distribution_list     TEXT,
  recall_effectiveness_target NUMERIC(5,2), -- % recovered
  units_distributed     INTEGER,
  units_recovered       INTEGER,
  effectiveness_check_date DATE,
  status                VARCHAR(30) DEFAULT 'initiated',
  closed_at             TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE gdp_recall_distribution_map (
  id                    BIGSERIAL PRIMARY KEY,
  recall_id             BIGINT REFERENCES gdp_product_recalls(id),
  recipient_type        VARCHAR(50), -- wholesaler, pharmacy, hospital, patient
  recipient_name        VARCHAR(200),
  recipient_country     CHAR(2),
  quantity_supplied     INTEGER,
  quantity_returned     INTEGER DEFAULT 0,
  notification_sent_at  TIMESTAMPTZ,
  acknowledgement_received_at TIMESTAMPTZ,
  return_expected_by    DATE,
  return_completed      BOOLEAN DEFAULT FALSE,
  created_at            TIMESTAMPTZ DEFAULT NOW()
);

