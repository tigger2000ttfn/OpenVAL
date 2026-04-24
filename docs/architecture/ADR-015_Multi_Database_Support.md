# ADR-015: Multi-Database Support Strategy

**Date:** 2026-04-08
**Status:** Accepted
**Supersedes:** Parts of ADR-002 (PostgreSQL as sole supported database)

---

## Context

The original architecture (ADR-002) selected PostgreSQL as the sole supported
database, citing Row Level Security (RLS) as essential for audit trail
append-only enforcement — a hard 21 CFR Part 11 requirement.

The project now requires support for:
- **PostgreSQL 15+** (primary, bare metal and cloud)
- **Oracle 19c+** (large pharma enterprise, SAP environments, many regulated sites)
- **MySQL 8.0+** / **MariaDB 10.6+** (smaller sites, cloud-hosted)

This requires rethinking the architecture without compromising 21 CFR Part 11
compliance on any supported database.

---

## Decision

**SQLAlchemy ORM is the primary database abstraction layer.**

PHARION does not write raw SQL in application code. All database interactions
go through SQLAlchemy 2.0 ORM models and Core expressions with parameterized
queries. SQLAlchemy handles dialect translation automatically for PostgreSQL,
Oracle, and MySQL.

The raw DDL `.sql` files in `schema/` are **reference documentation only** —
they are PostgreSQL-flavored for human readability. The authoritative schema
definition is the SQLAlchemy ORM models in `backend/app/models/`. Alembic
generates database-specific migrations from the ORM for any supported backend.

---

## Database-Specific Feature Handling

### UUID Primary Keys

All three databases support UUID storage, via different mechanisms:

| Database | SQLAlchemy Type | Notes |
|---|---|---|
| PostgreSQL | `UUID(as_uuid=True)` | Native UUID type, `gen_random_uuid()` |
| Oracle | `String(36)` | Stored as VARCHAR2(36), `SYS_GUID()` via trigger |
| MySQL | `String(36)` | Stored as CHAR(36), `UUID()` function |

**Implementation:**
```python
# models/base.py
import uuid
from sqlalchemy import String
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.orm import DeclarativeBase, mapped_column, Mapped
from app.core.config import settings

def uuid_pk():
    """Database-agnostic UUID primary key."""
    if settings.DB_DIALECT == "postgresql":
        return mapped_column(PG_UUID(as_uuid=True), primary_key=True,
                             default=uuid.uuid4)
    else:
        return mapped_column(String(36), primary_key=True,
                             default=lambda: str(uuid.uuid4()))
```

### Timestamps with Timezone

| Database | SQLAlchemy Type | Storage |
|---|---|---|
| PostgreSQL | `DateTime(timezone=True)` → `TIMESTAMPTZ` | Native TZ storage |
| Oracle | `DateTime(timezone=True)` → `TIMESTAMP WITH TIME ZONE` | Native TZ storage |
| MySQL | `DateTime(timezone=True)` → `DATETIME` | UTC normalized at app layer |

**MySQL note:** MySQL `DATETIME` does not store timezone info. PHARION normalizes
all timestamps to UTC before writing on MySQL. The application layer enforces this.
Audit trail timestamps are always UTC. This satisfies 21 CFR 11.10(e) because
the timestamp is unambiguous even without stored timezone.

### Text / JSON Storage

JSON data is stored as `TEXT`/`LONGTEXT`/`CLOB` across all databases.
No database-native JSON column type is used. This is already implemented
in the schema (all JSON fields are `TEXT` with `-- JSON` comment).

PHARION validates JSON structure at the application layer (Pydantic).
This is more portable and equally safe.

### Sequences / Auto-increment

Human-readable reference numbers (SYS-0001, CAPA-0042) use database sequences.

| Database | Mechanism | SQLAlchemy |
|---|---|---|
| PostgreSQL | `CREATE SEQUENCE` | `Sequence('seq_name')` |
| Oracle | `CREATE SEQUENCE` (native) | `Sequence('seq_name')` |
| MySQL | `AUTO_INCREMENT` helper table | Application-layer sequence table |

**MySQL sequence workaround:**
```python
# For MySQL, a dedicated sequence table is used:
# CREATE TABLE id_sequences (
#     seq_name VARCHAR(100) PRIMARY KEY,
#     current_value BIGINT NOT NULL DEFAULT 0
# );
# Application atomically increments and reads via SELECT FOR UPDATE.
```

### Full-Text Search

The `pg_trgm` trigram indexes used in PostgreSQL do not exist in Oracle or MySQL.

**Strategy:**
- Remove `gin_trgm_ops` indexes from Oracle/MySQL migrations
- Replace trigram search with `LIKE`/`ILIKE` for basic search (acceptable for
  < 100k records per table)
- For large deployments (any database): optional MeiliSearch or Elasticsearch
  integration handles full-text search at the application layer
- This is configured via `SEARCH_BACKEND = postgresql_trgm | meilisearch | basic`

### Boolean Columns

| Database | Storage |
|---|---|
| PostgreSQL | Native `BOOLEAN` |
| Oracle | `NUMBER(1)` with CHECK (0 or 1) |
| MySQL | `TINYINT(1)` |

SQLAlchemy's `Boolean` type handles all three correctly. No action needed.

---

## Audit Trail Append-Only Enforcement

This is the most critical difference across databases for 21 CFR Part 11.

### PostgreSQL (Tier 1 — strongest)
- Row Level Security policies block UPDATE and DELETE at the database layer
- The application database user (`pharion_app`) physically cannot modify
  `audit_log` or `electronic_signatures` rows regardless of application code
- Hash chain verification provides tamper detection
- **Assessment:** Strongest possible protection. Exceeds 21 CFR 11.10(e).

### Oracle (Tier 1 — equivalent)
- Virtual Private Database (VPD) provides equivalent row-level security
- Oracle Label Security can be applied to `audit_log` table
- Oracle Audit Vault integration available for additional monitoring
- Hash chain verification still applied at application layer
- **Implementation:**
  ```sql
  -- Oracle VPD policy for audit_log (no UPDATE/DELETE)
  CREATE OR REPLACE FUNCTION audit_log_policy(
      schema_name IN VARCHAR2, table_name IN VARCHAR2
  ) RETURN VARCHAR2 AS
  BEGIN
      IF SYS_CONTEXT('USERENV', 'ACTION') IN ('UPDATE', 'DELETE') THEN
          RAISE_APPLICATION_ERROR(-20001, 'Audit log is immutable');
      END IF;
      RETURN NULL;
  END;
  ```
- **Assessment:** Equivalent to PostgreSQL RLS. Meets 21 CFR 11.10(e).

### MySQL (Tier 2 — application-layer enforcement)
- MySQL 8.0 has no native row-level security equivalent
- Append-only is enforced at the **application layer** via:
  1. The SQLAlchemy event listener never emits UPDATE/DELETE on audit tables
  2. The `pharion_app` MySQL user is granted only `SELECT, INSERT` on
     `audit_log` and `electronic_signatures` (no UPDATE, no DELETE)
  3. Hash chain verification detects any out-of-band tampering
  4. MySQL binary log (binlog) provides additional tamper evidence
- **Assessment:** Meets 21 CFR 11.10(e) when properly documented.
  The user-level permission restriction is a validated control.
  The validation package for MySQL deployments must document this
  as an application-layer control rather than database-layer control.

**All three tiers satisfy 21 CFR Part 11 when the validation package
documents the actual control mechanism used.**

---

## Database-Specific Migration Files

```
schema/
  postgresql/           # PostgreSQL 15+ DDL (primary, most feature-rich)
    part1_core.sql
    part2_indexes_seed.sql
    part3_modules.sql
    part4_license.sql
    part5_workflows.sql
    part6_gaps.sql
  oracle/               # Oracle 19c+ DDL
    part1_core.sql      # CLOB instead of TEXT, NUMBER(1) for bool, etc.
    part2_indexes.sql   # No pg_trgm, Oracle-specific index syntax
    part3_seed.sql      # Seed data (INSERT syntax differences)
  mysql/                # MySQL 8.0+ / MariaDB 10.6+ DDL
    part1_core.sql      # LONGTEXT for TEXT, DATETIME for TIMESTAMPTZ
    part2_indexes.sql   # No pg_trgm, FULLTEXT indexes instead
    part3_seed.sql
    sequences.sql       # Sequence simulation table
```

The `schema/` root keeps the PostgreSQL version as the human-readable
reference. Database-specific subdirectories are generated via:
```bash
python scripts/generate_schema.py --dialect oracle
python scripts/generate_schema.py --dialect mysql
```

---

## SQLAlchemy Engine Configuration

```python
# app/core/database.py

from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

def build_engine():
    url = settings.DATABASE_URL
    
    # Dialect-specific options
    if "postgresql" in url or "asyncpg" in url:
        engine_kwargs = {
            "pool_size": 20,
            "max_overflow": 40,
            "pool_timeout": 30,
            "echo": settings.DATABASE_ECHO,
        }
    elif "oracle" in url or "cx_oracle" in url or "oracledb" in url:
        engine_kwargs = {
            "pool_size": 10,
            "max_overflow": 20,
            "pool_timeout": 30,
            "echo": settings.DATABASE_ECHO,
        }
    elif "mysql" in url or "mariadb" in url:
        engine_kwargs = {
            "pool_size": 20,
            "max_overflow": 40,
            "pool_timeout": 30,
            "pool_recycle": 3600,  # MySQL connection timeout mitigation
            "echo": settings.DATABASE_ECHO,
        }
    else:
        engine_kwargs = {"echo": settings.DATABASE_ECHO}

    return create_async_engine(url, **engine_kwargs)
```

### Supported Database URLs

```bash
# PostgreSQL (recommended)
DATABASE_URL=postgresql+asyncpg://user:pass@host/db

# Oracle (python-oracledb async driver)
DATABASE_URL=oracle+oracledb_async://user:pass@host:1521/ORCL

# MySQL 8.0+
DATABASE_URL=mysql+aiomysql://user:pass@host/db

# MariaDB 10.6+
DATABASE_URL=mysql+aiomysql://user:pass@host/db?charset=utf8mb4
```

---

## Required Python Drivers

```toml
# pyproject.toml additions for multi-DB support
asyncpg = "^0.29.0"           # PostgreSQL (already included)
python-oracledb = "^1.4.0"   # Oracle (optional, install for Oracle deployments)
aiomysql = "^0.2.0"           # MySQL/MariaDB (optional)
```

The installer (`install.sh`) prompts for database type and installs
the appropriate driver:
```bash
read -p "Database: [1] PostgreSQL (default)  [2] Oracle  [3] MySQL: " DB_CHOICE
```

---

## Validation Package Impact

Sites deploying on Oracle or MySQL must note in their validation package:

**Oracle:** "Audit trail append-only enforcement uses Oracle Virtual Private
Database (VPD) policy applied to the audit_log and electronic_signatures tables.
This provides equivalent protection to PostgreSQL Row Level Security."

**MySQL:** "Audit trail append-only enforcement is implemented at the application
layer via SQLAlchemy ORM event listener and database user permission restriction
(INSERT and SELECT only on audit tables). The MySQL binary log provides additional
tamper evidence. Hash chain integrity verification runs nightly."

Both are defensible to FDA and EMA inspectors when properly documented.

---

## Conclusion

PHARION supports PostgreSQL, Oracle, and MySQL through SQLAlchemy ORM abstraction.
PostgreSQL remains the recommended database for new deployments due to native RLS.
Oracle is the preferred option for enterprise sites with existing Oracle infrastructure.
MySQL is supported for smaller sites.

21 CFR Part 11 compliance is maintained on all three databases with
database-appropriate controls documented in the validation package.

---

*ADR-015 v1.0 — Accepted 2026-04-08*
