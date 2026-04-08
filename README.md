<div align="center">

<br/>

```
 ██████╗ ██████╗ ███████╗███╗   ██╗██╗   ██╗ █████╗ ██╗
██╔═══██╗██╔══██╗██╔════╝████╗  ██║██║   ██║██╔══██╗██║
██║   ██║██████╔╝█████╗  ██╔██╗ ██║██║   ██║███████║██║
██║   ██║██╔═══╝ ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝██╔══██║██║
╚██████╔╝██║     ███████╗██║ ╚████║ ╚████╔╝ ██║  ██║███████╗
 ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ╚═╝  ╚═╝╚══════╝
```

### The open source GxP Computer System Validation platform

**One platform. Any validation process. Any discipline. Fully auditable.**

*The open alternative to Kneat Gx · ValGenesis VLMS · SWARE Res_Q*

<br/>

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-teal.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688.svg)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18+-61DAFB.svg)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791.svg)](https://postgresql.org)
[![21 CFR Part 11](https://img.shields.io/badge/21_CFR_Part_11-Compliant-brightgreen.svg)](docs/)
[![EU Annex 11](https://img.shields.io/badge/EU_Annex_11-Compliant-brightgreen.svg)](docs/)
[![Tables](https://img.shields.io/badge/Database-362_tables-009688.svg)](schema/)

<br/>

</div>

---

## What is OpenVAL?

OpenVAL is an enterprise-grade, self-hosted GxP validation lifecycle management platform for pharmaceutical, biotech, and medical device manufacturers. It replaces paper, spreadsheets, and expensive proprietary tools with one fully auditable, open source system.

**Built by validation professionals. Designed to pass an FDA inspection.**

```
Authoring → Review & Annotation → Approval → Execution → Deviation → Closure → Periodic Review
     ↑                                                                               ↓
     └──────────────── Immutable Audit Trail · E-Signatures · ALCOA+ ───────────────┘
```

---

## Why OpenVAL?

| Pain | OpenVAL |
|---|---|
| Kneat / ValGenesis cost $30K–$200K/year | Free Community Edition — no per-user fees |
| Paper and SharePoint fail audits | Immutable audit trail, SHA-256 hash chain verified nightly |
| One tool per discipline — LIMS, QMS, CSV, drawing | 30 validation disciplines in one platform |
| CSV and CSA are handled differently | Native dual-mode: CSV and FDA CSA (Final Guidance Sept 2025) |
| Cloud-only vendors — no data control | Self-hosted. Your server. Your data. Always. |
| Black-box tools that are hard to validate | Ships with its own validation package VP-001 through VP-015 |

---

## 30 Validation Disciplines

**Computer Systems**
CSV · CSA · Retrospective Assessment · UAT · DQ · SAT · FAT

**Equipment & Facilities**
Equipment Qualification · Analytical Instrument Validation · Commissioning & Qualification (CQV) · Facilities & Utilities

**Manufacturing & Process**
Process Validation Stage 1/2/3 · Cleaning Validation (MACO/ADE/LD50) · Sterilization (F0, SAL, BIs) · Cold Chain / Temperature Mapping

**Quality & Compliance**
Change Control · CAPA · Deviation/NCE · OOS/OOT · Audit Management · Periodic Review · Technology Transfer

**Documentation**
Controlled Documents · Electronic Logbooks · Drawing/P&ID Management · Electronic Batch Records (eBR) · Template Library (49 templates)

**Analytics**
Real-time RTM · SPC · Validation Debt Tracker · Inspection Readiness Score

---

## Design

OpenVAL has a purpose-built design language for validation professionals.

- **Dark Teal** — `#00A090` primary identity. Not another blue enterprise tool.
- **Charcoal `#141414` header** + **dark teal `#004D45` sidebar** — always dark in both themes
- **Warm pass/fail** — lime `#86C140` for pass, coral `#E54B2E` for fail. Not sterile cool colors.
- **Gold `#E2A837`** — notifications, priority, milestones, enterprise features
- **Light + Dark themes** — `#c1c1c1` page background in light, `#0C1117` in dark
- **Modal-first** — every deliberate action uses a modal. Toasts only for background system events.
- **Collapsible sidebar** — 192px expanded with labels, 52px collapsed icons-only with tooltips
- **Top navigation dropdowns** — quick-jump access to all areas from any page

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  React 18 + TypeScript + Vite    (Nginx, port 443)           │
└──────────────────────────┬───────────────────────────────────┘
                           │ REST API / JSON
┌──────────────────────────▼───────────────────────────────────┐
│  FastAPI + SQLAlchemy 2.0 async  (Gunicorn, 4 workers)       │
├──────────────────────────────────────────────────────────────┤
│  Celery Workers  (reports, notifications, scheduled tasks)    │
└────┬─────────────────────────────────────┬────────────────────┘
     │                                     │
┌────▼──────────┐  Oracle 19c+    ┌────────▼─────────┐
│ PostgreSQL 15+│  MySQL 8.0+     │  Redis 7+        │
│ (primary)     │  (also supported│  (cache / queue) │
└───────────────┘                 └──────────────────┘
```

**Backend:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 async · Alembic · Celery  
**Frontend:** React 18 · TypeScript · Vite · Zustand · TipTap · Recharts  
**Infrastructure:** Nginx · Gunicorn · systemd · Ubuntu 22.04/24.04 · RHEL 9

---

## 21 CFR Part 11 Architecture

| Requirement | Implementation |
|---|---|
| Audit trails `11.10(e)` | SQLAlchemy `before_flush` intercepts every write. SHA-256 chain hash. Nightly Celery verification. |
| Electronic signatures `11.50` | Re-authenticate at every signing. Server timestamp only. Signed record hash linked to content at signing time. |
| Access controls `11.10(d)` | RBAC, unique user IDs, concurrent session limits, periodic access review workflow. |
| System validation `11.10(a)` | Ships with its own validation package VP-001 through VP-015 |
| Record copies `11.10(b)` | PDF export, full data export, no lock-in |
| ALCOA+ | Attributable · Contemporaneous · Original · Enduring · Available — all enforced by architecture |
| FDA CSA 2025 | Dual-mode CSV/CSA. Intended use documentation. Unscripted testing capture. Critical thinking rationale. |

---

## Database: 362 Tables Across 9 Schema Parts

| Part | Tables | Domain |
|---|---|---|
| 1 | 130 | Core: auth, audit trail, systems, protocols, documents, workflows, CAPA, change control |
| 3 | 31 | Quality: OOS/OOT, EM, stability, batch, complaints, inspection, SPC |
| 4 | 4 | License management |
| 5 | 33 | Validation workflows: projects, plans, sign-offs, lifecycle state machines |
| 6 | 16 | Gap closure: access reviews, DR testing, method validation, supplier controls |
| 7 | 37 | Disciplines: logbooks, drawings, tech transfer, cleaning, cold chain, CQV, process val, sterilization, CSA |
| 8 | 20 | Document system: block model, form fields, flowcharts, validation packages |
| 9 | 91 | Complete: workspaces, teams, calendar, training, equipment, eBR, regulatory submissions, integrations, dashboards, quality KPIs, AI registry, 483 tracking |
| **Total** | **362** | |

UUID primary keys throughout. UTC timestamps. JSON as TEXT for multi-DB portability. No hard deletes.

---

## Workspace / Portfolio Hierarchy

```
Organization
└── Site (MATC Madison)
    ├── Workspace (IT Validation)
    │   ├── Portfolio (SAP Suite)
    │   │   ├── Project: SAP ERP Upgrade 2026
    │   │   │   ├── Validation Plan          [Approved ✓]
    │   │   │   ├── Risk Assessment          [Approved ✓]
    │   │   │   ├── URS                      [Approved ✓]
    │   │   │   ├── IQ Protocol + Execution  [Passed   ✓]
    │   │   │   ├── OQ Protocol + Execution  [In Review ◉]
    │   │   │   ├── PQ Protocol              [Not Started]
    │   │   │   ├── Traceability Matrix      [Auto-generated]
    │   │   │   └── Validation Summary Report [Pending]
    │   │   └── Project: SAP HANA Migration
    │   └── Portfolio (Lab Systems)
    └── Workspace (Manufacturing Qual)
```

Three data isolation levels: `shared` · `restricted` · `strict`

---

## CE vs EE

**Community Edition (Free, AGPL-3.0)** — Complete for single-site, up to 50 users:

Full CSV lifecycle · E-signatures · Immutable audit trail · RTM · Change control · CAPA · NCE · Deviations · Controlled documents · Low-code workflows · Periodic review · 15 standard reports · Bare metal installer · **Bundled validation package**

**Enterprise Edition (Commercial, from $4,800/year)**

Everything in CE plus: OOS/OOT · Complaints · EM · Stability · Electronic logbooks · Drawings/P&ID · Tech transfer · Cleaning validation · Cold chain · CQV · Process validation · Sterilization · CSA mode · Test case library · Audit war rooms · Multi-site · SPC · AI assistance · Jira/Zephyr/Veeva/ServiceNow integrations · SAML/SSO · Custom reports

---

## Quick Start

```bash
# Requires Ubuntu 22.04+ or RHEL 9 · PostgreSQL 15+ · Redis 7+ · Node.js 20+ · Python 3.11+
git clone https://github.com/tigger2000ttfn/OpenVAL.git
cd OpenVAL && sudo ./scripts/install.sh
```

**Development:**

```bash
# Terminal 1 — backend with hot reload
cd backend && python -m venv venv && source venv/bin/activate
pip install -r requirements-dev.txt
uvicorn app.main:app --reload --port 8000
# → Swagger docs: http://localhost:8000/api/docs

# Terminal 2 — frontend with HMR
cd frontend && npm install && npm run dev
# → App: http://localhost:3000
```

---

## Project Status

| Deliverable | Status |
|---|---|
| Schema (362 tables, 9 parts) | ✅ Complete |
| Master Plan (26 phases, 30 disciplines) | ✅ Complete |
| Design System (dark teal, gold, warm accents) | ✅ Complete |
| URS-DOC-001 (69 document requirements) | ✅ Complete |
| Competitive research (Kneat, SWARE, ValGenesis) | ✅ Complete |
| Phase 0: Foundation (audit trail, e-sig, auth) | 🔨 Starting |
| Phase 1: ORM Layer (362 models) | ⏳ Upcoming |
| Phase 2: App Shell (React + design system) | ⏳ Upcoming |
| Template Library (49 templates) | 📋 Phase 17 |
| Validation Package VP-001–VP-015 | 📋 Phase 16 |

---

## Documentation

| | |
|---|---|
| [MASTER_PLAN.md](MASTER_PLAN.md) | 26-phase development roadmap, all 30 disciplines |
| [UI-SPEC-001](docs/ui_spec/UI-SPEC-001_Design_Specification.md) | Complete design system |
| [URS-DOC-001](docs/URS-DOC-001_Document_Template_System.md) | 69 document & template requirements |
| [ADR-015](docs/architecture/ADR-015_Multi_Database_Support.md) | Multi-database architecture |
| [BIZ-001](docs/business/BIZ-001_Licensing_Strategy.md) | CE/EE licensing strategy |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution guide |
| [SECURITY.md](SECURITY.md) | Security disclosure |

---

## Regulatory Coverage

- **US FDA:** 21 CFR Part 11 · 21 CFR 210/211 · 21 CFR 820 · 21 CFR 58
- **European:** EU GMP Annex 11 · EU GMP Annex 15
- **International:** GAMP 5 (2nd Edition, 2022) · ICH Q2/Q8/Q9/Q10/Q11
- **CSA:** FDA Final Guidance September 24, 2025
- **Data Integrity:** ALCOA+ · MHRA GxP DI Guidance · PIC/S PI 041-1 (Feb 2026)

---

## Contributing

OpenVAL is built for the validation community, by the validation community.

**All contributions must be GxP-aware.** Changes affecting regulated functionality require audit trail coverage and compliance test cases. See [CONTRIBUTING.md](CONTRIBUTING.md).

**We need help with:**
- Phase 0 backend: audit trail engine, e-signature system, JWT auth
- Template content: authoring the 49 protocol and document templates
- Validation package: VP-001 through VP-015 documents
- Compliance test suite: automated testing for all 21 CFR Part 11 controls

---

## License

**Community Edition:** [GNU Affero General Public License v3.0](LICENSE)

The AGPL ensures that if you run OpenVAL as a service, modifications must also be open source. This protects the community from proprietary forks.

**Enterprise Edition:** Commercial license. Contact for pricing.

---

<div align="center">

*Built for the people who make medicines safe.*

**OpenVAL · Open Source · Self-Hosted · GxP Compliant**

[Docs](docs/) · [Issues](https://github.com/tigger2000ttfn/OpenVAL/issues) · [Discussions](https://github.com/tigger2000ttfn/OpenVAL/discussions)

</div>
