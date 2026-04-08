# OpenVAL

**Open Source Enterprise Computer System Validation Platform**
*Built for Pharmaceutical, Biotech, and Medical Device Organizations*

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![21 CFR Part 11](https://img.shields.io/badge/21_CFR-Part_11-orange.svg)]()
[![GAMP 5: Category 4](https://img.shields.io/badge/GAMP_5-Category_4-blue.svg)]()

---

> OpenVAL is a fully open source, self-hosted CSV platform providing enterprise-grade
> validation lifecycle management, document control, electronic signatures, low-code
> workflow automation, and built-in GMP compliance tooling.
>
> **Community Edition** is free forever under AGPL-3.0.
> **Enterprise Edition** adds advanced modules for multi-site operations,
> manufacturing analytics, AI assistance, and deep integrations.

---

## Why OpenVAL

Commercial CSV platforms (Kneat, Valgenesis) are excellent and expensive.
OpenVAL fills the gap: a professionally designed, fully compliant, self-hostable
alternative that ships with its own validation package. No licensing cost for CE.
No vendor lock-in. Your data, your server.

---

## Editions at a Glance

| | Community (Free) | Enterprise (from $4,800/yr) |
|---|:---:|:---:|
| Full CSV lifecycle (IQ/OQ/PQ/UAT) | ✓ | ✓ |
| Document control and templates | ✓ | ✓ |
| Change control, CAPA, NCE | ✓ | ✓ |
| 21 CFR Part 11 audit trail + e-signatures | ✓ | ✓ |
| Traceability matrix | ✓ | ✓ |
| Bundled validation package | ✓ | ✓ |
| Single site / up to 50 users | ✓ | — |
| OOS/OOT investigation management | — | ✓ |
| Complaint management | — | ✓ |
| Environmental monitoring | — | ✓ |
| Stability studies | — | ✓ |
| Batch/lot management and CoA | — | ✓ |
| Inspection readiness module | — | ✓ |
| Statistical process control (SPC) | — | ✓ |
| Manufacturing analytics | — | ✓ |
| AI assistance (CAPA intelligence, SOP drafting) | — | ✓ |
| Multi-site management (unlimited) | — | ✓ |
| Advanced workflow builder | — | ✓ |
| LabWare / TrackWise / SAP / MES integrations | — | ✓ |
| SAML/OIDC SSO | — | ✓ |
| Custom report builder | — | ✓ |

[Full feature comparison →](docs/business/BIZ-001_Licensing_Strategy.md)

---

## Regulatory Coverage

21 CFR Part 11, 210/211, 820, 58 · EU Annex 11 · GAMP 5 · ICH Q9/Q10 · ALCOA+

---

## Quick Start (Bare Metal)

```bash
git clone https://github.com/YOUR_ORG/openval.git
cd openval
sudo bash scripts/install.sh
```

Ubuntu 22.04 LTS or RHEL 9 · Python 3.11+ · PostgreSQL 15+ · No Docker required

Full guide: [docs/install/INSTALL-001_Installation_Guide.md](docs/install/INSTALL-001_Installation_Guide.md)

---

## Architecture

Modular monolith. Community modules (AGPL) + Enterprise modules (commercial,
loaded conditionally via license key). One deployment, one database, one
validation scope. EE features unlock without schema migration.

[Modular architecture spec →](docs/business/ARCH-MOD-001_Modular_Architecture.md)

---

## Documentation Index

| Document | Purpose |
|---|---|
| [MASTER_PLAN.md](MASTER_PLAN.md) | 23-phase development roadmap (living doc) |
| [CHANGELOG.md](CHANGELOG.md) | Version history with validation impact classification |
| [SDL-001](docs/sdl/SDL-001_Software_Development_Lifecycle.md) | Software Development Lifecycle (GAMP 5) |
| [ADR](docs/architecture/ADR_Architecture_Decision_Records.md) | Architecture Decision Records |
| [API-SPEC-001](docs/api/API-SPEC-001_API_Specification.md) | Full API specification |
| [UI-SPEC-001](docs/ui_spec/UI-SPEC-001_Design_Specification.md) | UI/UX design specification |
| [INSTALL-001](docs/install/INSTALL-001_Installation_Guide.md) | Bare metal installation |
| [INT-SPEC-001](docs/INT-SPEC-001_Integration_Specification.md) | Integration specification |
| [BIZ-001](docs/business/BIZ-001_Licensing_Strategy.md) | Licensing and business model |
| [ARCH-MOD-001](docs/business/ARCH-MOD-001_Modular_Architecture.md) | Open core module architecture |
| [MODULE-EXT-001](docs/MODULE_EXTENSIONS_001.md) | Module extensions from competitive research |

---

## Enterprise Edition

[Contact us](https://openval.io/contact) · [Request demo](https://openval.io/demo)
Pricing from $4,800/year (25 users, 1 site).

---

## License

Community Edition: **AGPL-3.0**. Enterprise Edition: **Commercial**.
Your data belongs to you. Full export available in all editions, always.
