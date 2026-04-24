# ADR-016: Oracle 19c+ Full Compatibility

**Date:** 2026-04-09  **Status:** Approved

## Decision

Full first-class Oracle 19c+ support. Oracle is the dominant database in large
pharma enterprises (Astellas, Pfizer, J&J, AstraZeneca, Roche all mandate Oracle).
PostgreSQL is primary for CE/smaller deployments. Oracle is required for enterprise
EE sales. "Full support" = identical schema, behaviour, and GxP audit trail integrity.

---

## Complete Type Mapping

| PostgreSQL | Oracle 19c | Oracle 21c | Notes |
|---|---|---|---|
| UUID / gen_random_uuid() | VARCHAR2(36) / generate_uuid() | Same | Custom UUID function below |
| TEXT | CLOB | CLOB or VARCHAR2(32767) | NCLOB for multilingual |
| BOOLEAN | NUMBER(1,0) CHECK IN (0,1) | Same | SQLAlchemy maps automatically |
| TIMESTAMPTZ | TIMESTAMP WITH TIME ZONE | Same | Always UTC |
| VARCHAR(n) | VARCHAR2(n CHAR) | Same | CHAR = character count, not bytes |
| BIGINT | NUMBER(19,0) | Same | |
| INT | NUMBER(10,0) | Same | |
| DECIMAL(x,y) | NUMBER(x,y) | Same | |
| SERIAL | GENERATED ALWAYS AS IDENTITY | Same | Oracle 12c+ |
| BYTEA | BLOB | BLOB | File content |
| DEFAULT NOW() | DEFAULT CURRENT_TIMESTAMP | Same | |
| DEFAULT TRUE | DEFAULT 1 | Same | |
| ILIKE | REGEXP_LIKE(col, val, 'i') | Same | |
| JSON field (TEXT) | CLOB CHECK (col IS JSON) | JSON native | 21c native type |
| LIMIT n | FETCH FIRST n ROWS ONLY | Same | Oracle 12c+ |
| ON CONFLICT DO NOTHING | MERGE statement | Same | |
| DISTINCT ON | ROW_NUMBER() window function | Same | |
| RETURNING id | Not supported | Not supported | Handle in app layer |

---

## UUID Strategy

Oracle SYS_GUID() returns RAW(16). Store as VARCHAR2(36) for readability in GxP audit logs.

```sql
CREATE OR REPLACE FUNCTION generate_uuid RETURN VARCHAR2 IS
BEGIN
  RETURN LOWER(
    SUBSTR(RAWTOHEX(SYS_GUID()),1,8)||'-'||
    SUBSTR(RAWTOHEX(SYS_GUID()),9,4)||'-'||
    SUBSTR(RAWTOHEX(SYS_GUID()),13,4)||'-'||
    SUBSTR(RAWTOHEX(SYS_GUID()),17,4)||'-'||
    SUBSTR(RAWTOHEX(SYS_GUID()),21,12));
END;/
```

SQLAlchemy UUIDType compiles to VARCHAR2(36) on Oracle dialect automatically.

---

## Row-Level Security: VPD vs RLS

```sql
-- PostgreSQL (what we have in schema)
ALTER TABLE systems ENABLE ROW LEVEL SECURITY;
CREATE POLICY site_isolation ON systems
    USING (site_id = current_setting('app.current_site_id')::uuid);

-- Oracle Virtual Private Database equivalent
CREATE OR REPLACE FUNCTION site_isolation_policy(
    schema_name IN VARCHAR2, table_name IN VARCHAR2
) RETURN VARCHAR2 IS
BEGIN
    RETURN 'SITE_ID = SYS_CONTEXT(''PHAROLON_CTX'', ''CURRENT_SITE_ID'')';
END;/

BEGIN
    DBMS_RLS.ADD_POLICY(
        object_schema   => 'PHAROLON',
        object_name     => 'SYSTEMS',
        policy_name     => 'SITE_ISOLATION',
        function_schema => 'PHAROLON',
        policy_function => 'SITE_ISOLATION_POLICY',
        statement_types => 'SELECT,INSERT,UPDATE,DELETE',
        enable          => TRUE
    );
END;/
```

---

## Audit Trail Hash Chain — Oracle

SHA-256 hash chain using DBMS_CRYPTO (requires EXECUTE grant on DBMS_CRYPTO):

```sql
CREATE OR REPLACE FUNCTION compute_audit_hash(
    p_table_name VARCHAR2, p_record_id VARCHAR2,
    p_action VARCHAR2, p_data_snapshot CLOB,
    p_previous_hash VARCHAR2, p_timestamp TIMESTAMP WITH TIME ZONE
) RETURN VARCHAR2 IS
    v_payload VARCHAR2(32767);
    v_hash_raw RAW(32);
BEGIN
    v_payload := p_table_name||'|'||p_record_id||'|'||p_action||'|'||
                 DBMS_LOB.SUBSTR(p_data_snapshot,16000,1)||'|'||
                 NVL(p_previous_hash,'GENESIS')||'|'||
                 TO_CHAR(p_timestamp AT TIME ZONE 'UTC',
                         'YYYY-MM-DD"T"HH24:MI:SS.FF3"Z"');
    v_hash_raw := DBMS_CRYPTO.HASH(
        src => UTL_I18N.STRING_TO_RAW(v_payload,'AL32UTF8'),
        typ => DBMS_CRYPTO.HASH_SH256);
    RETURN LOWER(RAWTOHEX(v_hash_raw));
END;/
```

---

## JSON Storage

Oracle 19c: `CLOB CHECK (col IS JSON)` constraint  
Oracle 21c: Native `JSON` type (preferred)

```python
# SQLAlchemy model column
config = Column(JSON().with_variant(oracle_dialect.CLOB, 'oracle'))
```

---

## Partitioning (Large Tables)

audit_trail will be enormous. Range partition by month:

```sql
CREATE TABLE audit_trail (
    id         VARCHAR2(36) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    -- ... other columns
) PARTITION BY RANGE (created_at)
  INTERVAL (INTERVAL '1' MONTH)
(PARTITION p_initial VALUES LESS THAN
    (TIMESTAMP WITH TIME ZONE '2026-01-01 00:00:00 UTC'));
```

---

## Full-Text Search

PostgreSQL uses tsvector. Oracle Text equivalent:

```sql
CREATE INDEX idx_documents_fulltext ON documents (content_text)
    INDEXTYPE IS CTXSYS.CONTEXT;

-- Query
SELECT id, title FROM documents
WHERE CONTAINS(content_text, 'validation AND audit', 1) > 0;
```

---

## Alembic Multi-Dialect Migration Pattern

```python
def upgrade():
    dialect = op.get_bind().dialect.name

    if dialect == 'oracle':
        op.execute("""
            ALTER TABLE systems ADD (
                new_field VARCHAR2(512 CHAR),
                config    CLOB CONSTRAINT chk_cfg CHECK (config IS JSON)
            )
        """)
    elif dialect == 'postgresql':
        op.add_column('systems', sa.Column('new_field', sa.String(512)))
        op.add_column('systems', sa.Column('config', postgresql.JSONB))
    else:  # MySQL 8+
        op.add_column('systems', sa.Column('new_field', sa.String(512)))
        op.add_column('systems', sa.Column('config', sa.JSON))
```

---

## Oracle Certification Matrix

| Version | Support | Notes |
|---|---|---|
| Oracle 11g | ❌ | Too old — no identity columns |
| Oracle 12c R2 | ⚠️ Limited | Missing JSON type |
| Oracle 18c | ⚠️ Limited | End of Extended Support |
| Oracle 19c | ✅ Full | Long Term Release — primary target |
| Oracle 21c | ✅ Full | Native JSON type preferred |
| Oracle 23ai | ✅ Full | JSON Relational Duality views |
| Oracle Autonomous DB | ✅ Full | Compatible with 19c/21c |

---

## Oracle Wallet / Connection Security

```python
# Encrypted wallet (zero credentials in config files)
engine = create_engine(
    "oracle+cx_oracle:///@prod_wallet_alias",
    connect_args={"wallet_location": "/opt/pharolon/wallet"}
)
```

This is critical for pharma Oracle deployments — credentials never in plaintext.

---

## GRANT Requirements

The pharolon application user needs these Oracle grants:

```sql
-- Minimum required grants
GRANT CREATE SESSION TO pharolon_app;
GRANT CREATE TABLE TO pharolon_app;
GRANT CREATE SEQUENCE TO pharolon_app;
GRANT CREATE PROCEDURE TO pharolon_app;
GRANT EXECUTE ON DBMS_CRYPTO TO pharolon_app;  -- for SHA-256 audit chain
GRANT EXECUTE ON DBMS_RLS TO pharolon_app;     -- for VPD policies
GRANT EXECUTE ON DBMS_LOCK TO pharolon_app;    -- for advisory locks

-- For Oracle Text (full-text search)
GRANT CTXAPP TO pharolon_app;
EXECUTE CTX_DDL.SYNC_INDEX('idx_documents_fulltext');
```
