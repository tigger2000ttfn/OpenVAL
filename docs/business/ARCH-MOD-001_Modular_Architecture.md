# PHAROLON Modular Architecture Specification

**Document Reference:** ARCH-MOD-001
**Version:** 1.0
**Date:** 2026-04-07
**Status:** Approved for Development

---

## 1. Architecture Philosophy

PHAROLON is built as a **modular monolith**. This is intentional.

A modular monolith has the organizational cleanliness of microservices
(clear module boundaries, no cross-cutting dependencies) with the operational
simplicity of a monolith (one process, one database, one deployment unit).

This is the right choice for:
- Bare metal deployment at sites with modest IT capability
- CE users who cannot run a container orchestration platform
- Keeping the system easy to reason about during a regulatory inspection
- Keeping validation scope manageable (one system to validate, not ten microservices)

The module boundary is enforced by convention and linting, not by network calls.
EE modules load conditionally based on license state.

---

## 2. Directory Structure

```
pharolon/
├── backend/
│   └── app/
│       ├── main.py                    # App factory, conditional module loading
│       ├── core/                      # Infrastructure (always loaded)
│       │   ├── config.py              # Settings from environment
│       │   ├── database.py            # SQLAlchemy session, engine
│       │   ├── audit.py               # Audit trail event listener
│       │   ├── signatures.py          # Electronic signature engine
│       │   ├── license.py             # License key validation
│       │   ├── feature_flags.py       # Feature flag evaluation
│       │   ├── security.py            # JWT, TOTP, bcrypt
│       │   ├── permissions.py         # RBAC checking
│       │   ├── notifications.py       # Notification dispatch
│       │   ├── celery_app.py          # Celery configuration
│       │   └── exceptions.py          # Custom exception types
│       ├── modules/
│       │   ├── __init__.py            # Module registry
│       │   ├── community/             # AGPL-3.0 modules
│       │   │   ├── __init__.py        # Registers all CE routers
│       │   │   ├── auth/
│       │   │   ├── users/
│       │   │   ├── sites/
│       │   │   ├── systems/
│       │   │   ├── equipment/
│       │   │   ├── risk/
│       │   │   ├── requirements/
│       │   │   ├── protocols/
│       │   │   ├── executions/
│       │   │   ├── deviations/
│       │   │   ├── documents/
│       │   │   ├── workflows/
│       │   │   ├── change_control/
│       │   │   ├── capa/
│       │   │   ├── nonconformances/
│       │   │   ├── periodic_review/
│       │   │   ├── traceability/
│       │   │   ├── vendors/
│       │   │   ├── audits/
│       │   │   ├── training/
│       │   │   ├── reports/
│       │   │   ├── notifications/
│       │   │   ├── files/
│       │   │   ├── audit_log/
│       │   │   └── admin/
│       │   └── enterprise/            # Commercial license modules
│       │       ├── __init__.py        # EE module registry
│       │       ├── oos_oot/           # EE: OOS/OOT management
│       │       ├── complaints/        # EE: Complaint management
│       │       ├── em/                # EE: Environmental monitoring
│       │       ├── stability/         # EE: Stability studies
│       │       ├── batch_lot/         # EE: Batch/lot management
│       │       ├── inspection/        # EE: Inspection readiness
│       │       ├── spc/               # EE: Statistical process control
│       │       ├── analytics/         # EE: Manufacturing analytics
│       │       ├── ai/                # EE: AI assistance
│       │       ├── multi_site/        # EE: Cross-site management
│       │       ├── advanced_wf/       # EE: Advanced workflow features
│       │       ├── integrations/      # EE: Deep integrations
│       │       └── advanced_reports/  # EE: Report builder + scheduled
│       ├── models/                    # SQLAlchemy ORM models (all tables)
│       ├── schemas/                   # Pydantic schemas (all modules)
│       └── tasks/
│           ├── community/             # CE Celery tasks
│           └── enterprise/            # EE Celery tasks
├── frontend/
│   └── src/
│       ├── community/                 # CE pages and components
│       │   ├── systems/
│       │   ├── protocols/
│       │   ├── documents/
│       │   ├── workflows/
│       │   └── ...
│       └── enterprise/                # EE pages and components
│           ├── oos_oot/
│           ├── em/
│           ├── stability/
│           ├── batch_lot/
│           ├── inspection/
│           ├── spc/
│           ├── analytics/
│           ├── ai/
│           └── multi_site/
└── schema/
    ├── pharolon_schema_part1.sql       # All DDL (CE + EE tables)
    ├── pharolon_schema_part2.sql       # Indexes, sequences, seed data
    └── pharolon_schema_part3.sql       # New module tables
```

---

## 3. Module Internal Structure

Every module (CE or EE) follows the same internal layout:

```
modules/community/systems/
├── __init__.py       # Exports: router, service, models reference
├── router.py         # FastAPI APIRouter with all endpoints
├── service.py        # Business logic (no HTTP, no DB queries directly)
├── schemas.py        # Pydantic request/response models
├── tasks.py          # Celery tasks specific to this module (optional)
└── tests/
    ├── test_router.py
    ├── test_service.py
    └── test_audit.py
```

This structure is enforced by a custom Ruff plugin rule:
`no-cross-module-import` — CE modules cannot import from EE modules.
EE modules CAN import from CE modules and core.

---

## 4. License Engine

### License Key Structure

A license key is a base64-encoded JSON payload signed with RSA-2048.

```json
{
  "license_id": "LIC-2026-00042",
  "organization_name": "Astellas Pharma US",
  "organization_id": "org-uuid",
  "edition": "enterprise",
  "tier": "scale",
  "max_users": 300,
  "max_sites": 10,
  "features": [
    "oos_oot",
    "complaints",
    "em_monitoring",
    "stability_studies",
    "batch_lot",
    "inspection_readiness",
    "spc",
    "manufacturing_analytics",
    "ai_phase1",
    "multi_site",
    "advanced_workflows",
    "labware_integration",
    "trackwise_integration",
    "advanced_reports",
    "sso_saml",
    "ldap_advanced",
    "webhooks_outbound",
    "api_write"
  ],
  "issued_at": "2026-04-01T00:00:00Z",
  "expires_at": "2027-04-01T00:00:00Z",
  "issued_by": "pharolon_team",
  "signature": "RSA_SIGNATURE_HEX"
}
```

### License Validation Flow

```python
# app/core/license.py

import json
import base64
from datetime import datetime, timezone
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from app.core.config import settings

PHAROLON_PUBLIC_KEY = """
-----BEGIN PUBLIC KEY-----
[PHAROLON RSA-2048 public key embedded in application]
-----END PUBLIC KEY-----
"""

class License:
    def __init__(self, key_string: str | None):
        self._raw = key_string
        self._payload = None
        self._valid = False
        self._error = None
        self._parse()

    def _parse(self):
        if not self._raw:
            self._error = "No license key configured"
            return
        try:
            parts = self._raw.split(".")
            payload_b64, signature_hex = parts[0], parts[1]
            payload_bytes = base64.b64decode(payload_b64)
            signature_bytes = bytes.fromhex(signature_hex)

            # Verify signature
            public_key = serialization.load_pem_public_key(
                PHAROLON_PUBLIC_KEY.encode()
            )
            public_key.verify(
                signature_bytes,
                payload_bytes,
                padding.PSS(
                    mgf=padding.MGF1(hashes.SHA256()),
                    salt_length=padding.PSS.MAX_LENGTH
                ),
                hashes.SHA256()
            )

            self._payload = json.loads(payload_bytes.decode())
            expires = datetime.fromisoformat(self._payload["expires_at"])
            if expires < datetime.now(timezone.utc):
                self._error = "License expired"
                return

            self._valid = True

        except Exception as e:
            self._error = f"Invalid license key: {e}"

    @property
    def is_valid(self) -> bool:
        return self._valid

    @property
    def edition(self) -> str:
        if not self._valid:
            return "community"
        return self._payload.get("edition", "community")

    @property
    def tier(self) -> str:
        if not self._valid:
            return "community"
        return self._payload.get("tier", "community")

    @property
    def max_users(self) -> int:
        if not self._valid:
            return 50  # CE limit
        return self._payload.get("max_users", 50)

    @property
    def max_sites(self) -> int:
        if not self._valid:
            return 1  # CE limit
        return self._payload.get("max_sites", 1)

    def has_feature(self, feature_code: str) -> bool:
        if not self._valid:
            return False
        return feature_code in self._payload.get("features", [])

    @property
    def expires_at(self) -> datetime | None:
        if not self._payload:
            return None
        return datetime.fromisoformat(self._payload["expires_at"])

    @property
    def days_until_expiry(self) -> int | None:
        if not self.expires_at:
            return None
        delta = self.expires_at - datetime.now(timezone.utc)
        return delta.days

    @property
    def error(self) -> str | None:
        return self._error


# Singleton - loaded once at startup
_license: License | None = None

def get_license() -> License:
    global _license
    if _license is None:
        from app.core.config import settings
        _license = License(settings.LICENSE_KEY)
    return _license

def reload_license():
    global _license
    _license = None
    return get_license()
```

### Feature Guard Decorator

```python
# app/core/feature_flags.py

from functools import wraps
from fastapi import HTTPException
from app.core.license import get_license

def require_feature(feature_code: str):
    """
    Decorator for FastAPI route handlers.
    Returns 402 if the feature is not licensed.
    Returns 403 if the user lacks the required permission (handled separately).
    """
    def decorator(func):
        @wraps(func)
        async def wrapper(*args, **kwargs):
            license = get_license()
            if not license.has_feature(feature_code):
                raise HTTPException(
                    status_code=402,
                    detail={
                        "code": "FEATURE_NOT_LICENSED",
                        "message": f"The '{feature_code}' feature requires an Enterprise license.",
                        "feature": feature_code,
                        "upgrade_url": "https://pharolon.io/upgrade",
                    }
                )
            return await func(*args, **kwargs)
        return wrapper
    return decorator

# Usage in EE router:
# @router.post("/oos-records")
# @require_feature("oos_oot")
# @require_permission("oos:create")
# async def create_oos_record(...)
```

### CE Limit Enforcement

```python
# app/core/limits.py

from app.core.license import get_license
from app.core.database import AsyncSession
from app.models.users import User
from sqlalchemy import func, select

async def check_user_limit(db: AsyncSession, site_id: str):
    license = get_license()
    count = await db.scalar(
        select(func.count()).select_from(User)
        .where(User.site_id == site_id, User.is_active == True)
    )
    if count >= license.max_users:
        raise HTTPException(
            status_code=402,
            detail={
                "code": "USER_LIMIT_REACHED",
                "message": f"Your {license.tier} edition allows up to {license.max_users} users.",
                "current_count": count,
                "limit": license.max_users,
                "upgrade_url": "https://pharolon.io/upgrade"
            }
        )
```

---

## 5. App Factory with Conditional Module Loading

```python
# app/main.py

from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.license import get_license
from app.core.audit import register_audit_listener
from app.modules.community import register_community_modules

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    license = get_license()
    app.state.license = license
    yield
    # Shutdown

def create_app() -> FastAPI:
    app = FastAPI(
        title="PHAROLON",
        version=settings.APP_VERSION,
        docs_url="/api/docs" if settings.DEBUG else None,
        redoc_url="/api/redoc" if settings.DEBUG else None,
        lifespan=lifespan,
    )

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_HOSTS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Register audit trail listener on all sessions
    register_audit_listener()

    # Always load: CE modules
    register_community_modules(app)

    # Conditionally load: EE modules based on license
    license = get_license()
    _load_enterprise_modules(app, license)

    return app


def _load_enterprise_modules(app: FastAPI, license):
    """
    Load EE modules conditionally based on licensed features.
    Import errors are caught and logged — a missing EE module
    never prevents the CE from starting.
    """
    ee_modules = [
        ("oos_oot",                "app.modules.enterprise.oos_oot",        "/api/v1"),
        ("complaints",             "app.modules.enterprise.complaints",      "/api/v1"),
        ("em_monitoring",          "app.modules.enterprise.em",              "/api/v1"),
        ("stability_studies",      "app.modules.enterprise.stability",       "/api/v1"),
        ("batch_lot",              "app.modules.enterprise.batch_lot",       "/api/v1"),
        ("inspection_readiness",   "app.modules.enterprise.inspection",      "/api/v1"),
        ("spc",                    "app.modules.enterprise.spc",             "/api/v1"),
        ("manufacturing_analytics","app.modules.enterprise.analytics",       "/api/v1"),
        ("ai_phase1",              "app.modules.enterprise.ai",              "/api/v1"),
        ("multi_site",             "app.modules.enterprise.multi_site",      "/api/v1"),
        ("advanced_workflows",     "app.modules.enterprise.advanced_wf",     "/api/v1"),
        ("api_write",              "app.modules.enterprise.api_write",       "/api/v1"),
        ("advanced_reports",       "app.modules.enterprise.advanced_reports","/api/v1"),
    ]

    for feature_code, module_path, prefix in ee_modules:
        if license.has_feature(feature_code):
            try:
                import importlib
                module = importlib.import_module(module_path)
                app.include_router(module.router, prefix=prefix)
            except ImportError:
                import logging
                logging.warning(
                    f"EE feature '{feature_code}' is licensed but module "
                    f"'{module_path}' could not be imported. "
                    "This is expected in CE builds."
                )
            except Exception as e:
                import logging
                logging.error(f"Failed to load EE module '{module_path}': {e}")
```

---

## 6. Frontend Module Architecture

### Feature Store

```typescript
// store/license.store.ts
import { create } from 'zustand'

interface LicenseState {
  edition: 'community' | 'enterprise'
  tier: string
  features: string[]
  maxUsers: number
  maxSites: number
  expiresAt: string | null
  daysUntilExpiry: number | null
  isValid: boolean
}

export const useLicenseStore = create<LicenseState>(() => ({
  edition: 'community',
  tier: 'community',
  features: [],
  maxUsers: 50,
  maxSites: 1,
  expiresAt: null,
  daysUntilExpiry: null,
  isValid: false,
}))

// Populated from /api/v1/auth/me response on login
```

### Feature Hook

```typescript
// hooks/useFeature.ts
import { useLicenseStore } from '@/store/license.store'

export function useFeature(featureCode: string): boolean {
  const features = useLicenseStore(state => state.features)
  return features.includes(featureCode)
}

export function useEdition(): 'community' | 'enterprise' {
  return useLicenseStore(state => state.edition)
}
```

### Locked Navigation Item Component

```typescript
// components/ui/NavItemLocked.tsx
import { Lock } from 'lucide-react'
import { useNavigate } from 'react-router-dom'

interface NavItemLockedProps {
  label: string
  featureCode: string
  icon: React.ComponentType
}

export function NavItemLocked({ label, featureCode, icon: Icon }: NavItemLockedProps) {
  const navigate = useNavigate()
  
  return (
    <button
      onClick={() => navigate(`/upgrade/${featureCode}`)}
      className="flex items-center gap-2 px-3 py-2 w-full text-left
                 text-neutral-400 hover:bg-neutral-50 rounded-md group"
    >
      <Icon className="w-4 h-4 text-neutral-300" />
      <span className="text-sm flex-1">{label}</span>
      <span className="text-xs bg-amber-100 text-amber-700 px-1.5 py-0.5 
                       rounded font-medium opacity-0 group-hover:opacity-100 
                       transition-opacity">
        Enterprise
      </span>
      <Lock className="w-3 h-3 text-neutral-300" />
    </button>
  )
}
```

### Upgrade Page Component

```typescript
// pages/upgrade/UpgradePage.tsx
// Shown when a user navigates to a locked EE feature

interface UpgradePageProps {
  featureCode: string
}

const FEATURE_DESCRIPTIONS: Record<string, {
  title: string
  description: string
  benefits: string[]
  icon: string
}> = {
  oos_oot: {
    title: "OOS / OOT Investigation Management",
    description: "Manage the full investigation lifecycle for out-of-specification " +
                 "and out-of-trend laboratory results with Phase 1 and Phase 2 " +
                 "investigation workflows, retest tracking, and CAPA linkage.",
    benefits: [
      "Structured Phase 1 and Phase 2 investigation workflows",
      "Automatic retest scheduling and result capture",
      "Integrated CAPA creation for Phase 2 escalations",
      "OOS rate trending by test type and product",
      "21 CFR 211 compliant investigation documentation"
    ],
    icon: "flask"
  },
  em_monitoring: {
    title: "Environmental Monitoring Module",
    description: "Manage your complete EM program: sample point configuration, " +
                 "session scheduling, result entry, excursion management, and trend analysis.",
    benefits: [
      "Full EM program configuration (rooms, sample points, limits)",
      "Automated session scheduling and calendar view",
      "Real-time excursion detection and investigation workflow",
      "SPC trending charts for EM data",
      "Monthly EM summary report generation"
    ],
    icon: "activity"
  },
  // ... etc for all EE features
}
```

---

## 7. API License Response

Every API response from an authenticated endpoint includes license context:

```json
{
  "success": true,
  "data": { ... },
  "_license": {
    "edition": "enterprise",
    "tier": "scale",
    "features": ["oos_oot", "em_monitoring", ...],
    "days_until_expiry": 359,
    "gxp_context": true,
    "system_validated": true
  }
}
```

This is included in the `/auth/me` response on login and cached in the
frontend license store. It does not need to be fetched on every request.

The `/api/v1/license/status` endpoint returns real-time license status
for the admin panel.

---

## 8. License Status Database Table

```sql
-- License information is stored in site_settings but also cached here
-- for performance (avoids re-parsing the key on every request)

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
    license_key_hash VARCHAR(64)  -- SHA-256 of the key, for change detection
);
```

The Celery beat task `validate_license` runs hourly:
1. Reads LICENSE_KEY from environment
2. Validates it
3. Updates license_cache
4. If validation fails: sends admin alert
5. If expiry < 30 days: sends renewal reminder

---

## 9. CE/EE Feature Matrix in Admin Panel

The Administration > License page shows:

```
PHAROLON Enterprise License
─────────────────────────────────────────────────────────
Organization:    Astellas Pharma US
Edition:         Enterprise Scale
Licensed Sites:  10  (using 3)
Licensed Users:  300 (using 47)
Expires:         2027-04-01  (359 days)
Status:          ✓ Valid

LICENSED FEATURES
────────────────────────────────────────────────
✓ OOS/OOT Management
✓ Complaint Management
✓ Environmental Monitoring
✓ Stability Studies
✓ Batch/Lot Management
✓ Inspection Readiness
✓ Statistical Process Control
✗ Manufacturing Analytics      [Not in current license]
✗ AI Assistance Phase 1        [Not in current license]
✓ Multi-Site Management
✓ Advanced Workflows
✓ LabWare Integration
✓ TrackWise Integration
✓ Advanced Reports
✓ SAML/OIDC SSO
✓ Advanced LDAP
✓ Outbound Webhooks
✓ Full API Access (read + write)

[Update License Key]    [Contact Sales]    [Download Invoice]
```

---

## 10. Build Pipeline for CE and EE Distributions

### CE Build (Public, GitHub)

```bash
# scripts/build_ce.sh

#!/bin/bash
set -e

echo "Building PHAROLON Community Edition..."

# Backend: exclude enterprise modules from distribution
rsync -av --exclude='enterprise/' backend/ dist_ce/backend/

# Frontend: exclude enterprise pages and components
npm --prefix frontend run build:community

# Package
tar -czf pharolon-ce-${VERSION}.tar.gz dist_ce/

echo "CE build complete: pharolon-ce-${VERSION}.tar.gz"
```

### EE Build (Private, Customer Distribution)

```bash
# scripts/build_ee.sh (runs in private CI)

#!/bin/bash
set -e

echo "Building PHAROLON Enterprise Edition..."

# Full backend including enterprise modules
cp -r backend/ dist_ee/backend/

# Full frontend including enterprise pages
npm --prefix frontend run build:enterprise

# Generate EE-specific docs
python scripts/generate_ee_docs.py

# Package with checksums
tar -czf pharolon-ee-${VERSION}.tar.gz dist_ee/
sha256sum pharolon-ee-${VERSION}.tar.gz > pharolon-ee-${VERSION}.sha256

echo "EE build complete"
```

### install.sh Detects Edition

```bash
# The installer detects which edition it is installing
if [ -d "backend/app/modules/enterprise" ]; then
    EDITION="Enterprise"
    echo "Installing PHAROLON Enterprise Edition"
else
    EDITION="Community"
    echo "Installing PHAROLON Community Edition"
fi
```

---

## 11. Testing Strategy for CE/EE Modules

### CE Module Tests

Standard pytest tests. Run in standard CI on every PR.

```python
# tests must pass without a license key in the environment
# CE features must work with LICENSE_KEY unset
```

### EE Module Tests

```python
# EE tests require a test license key in CI environment variable
# EE_TEST_LICENSE_KEY provides a valid but non-production license
# for all EE features in test environments

@pytest.mark.enterprise
@pytest.mark.require_feature("oos_oot")
async def test_create_oos_record(client, db, ee_license):
    response = await client.post(
        "/api/v1/oos-records",
        json={...},
        headers={"Authorization": f"Bearer {ee_license.access_token}"}
    )
    assert response.status_code == 201
```

### Upgrade Boundary Tests

```python
# Tests that CE returns correct 402 for EE endpoints
@pytest.mark.ce_boundary
async def test_oos_endpoint_returns_402_without_license(client_ce, db):
    response = await client_ce.post("/api/v1/oos-records", json={...})
    assert response.status_code == 402
    assert response.json()["error"]["code"] == "FEATURE_NOT_LICENSED"
```

---

## 12. Documentation Split

| Document | CE | EE |
|---|---|---|
| README.md | ✓ public | mentions EE |
| MASTER_PLAN.md | ✓ public | includes EE phases |
| SDL-001 | ✓ public | covers CE core |
| API-SPEC-001 | CE endpoints public | EE endpoints in private docs |
| INSTALL-001 | ✓ public | EE install notes private |
| Validation Package | CE bundled in repo | EE addendum to licensees |
| Pricing | BIZ-001 public | — |
| EE Feature Docs | Summary public | Full docs to licensees |

---

*ARCH-MOD-001 v1.0 - PHAROLON Modular Architecture Specification*
