<div align="center">

<br/>

```
██████╗ ██╗  ██╗ █████╗ ██████╗ ██╗ ██████╗ ███╗   ██╗
██╔══██╗██║  ██║██╔══██╗██╔══██╗██║██╔═══██╗████╗  ██║
██████╔╝███████║███████║██████╔╝██║██║   ██║██╔██╗ ██║
██╔═══╝ ██╔══██║██╔══██║██╔══██╗██║██║   ██║██║╚██╗██║
██║     ██║  ██║██║  ██║██║  ██║██║╚██████╔╝██║ ╚████║
╚═╝     ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```

### Quality Intelligence for Regulated Industries

**The fixed reference point that guides any organisation through regulatory complexity.**

*Pharmaceutical · Medical Device · Biotech · Food Safety · Aerospace · Clinical Research · Cell & Gene Therapy*

<br/>

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-teal.svg)](https://www.gnu.org/licenses/agpl-3.0)
[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://python.org)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.110+-009688.svg)](https://fastapi.tiangolo.com)
[![React](https://img.shields.io/badge/React-18+-61DAFB.svg)](https://react.dev)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791.svg)](https://postgresql.org)
[![Oracle](https://img.shields.io/badge/Oracle-19c%2B-F80000.svg)](https://oracle.com)
[![21 CFR Part 11](https://img.shields.io/badge/21_CFR_Part_11-Compliant-brightgreen.svg)](docs/)
[![Tables](https://img.shields.io/badge/Database-418_tables-009688.svg)](schema/)

> **🎨 Brand Identity & Design Preview:** [**pharolon.design →**](https://tigger2000ttfn.github.io/OpenVAL/) — Full design showcase with dark/light themes, component library, and interface preview.

<br/>

</div>

---

## What is PHAROLON?

The Pharos of Alexandria — one of the Seven Wonders of the Ancient World — guided every vessel through dangerous waters for over a thousand years. Not just one trade. Not just one kingdom. Every ship, every cargo, every destination.

**PHAROLON** carries that mission into the age of regulated industry. The quality intelligence platform that guides any organisation through the complexity of compliance, validation, and quality management — wherever regulatory waters run dangerous.

> **Short-form:** `pH` — the chemistry notation for potential of Hydrogen, and the PHAROLON acronym. Lowercase p (the descending P in the wordmark), uppercase H (the fixed reference point). Four hidden references in one brand: the Pharos lighthouse, the Great Pyramid, the pH notation, and the compass.


Not just pharmaceutical. Not just validation. **The complete quality intelligence platform for every regulated industry.**

```
Authoring → Review → Approval → Execution → Deviation → Closure → Periodic Review
     ↑                                                                     ↓
     └─────────── Immutable Audit Trail · E-Signatures · ALCOA+ ──────────┘
```

---

## Why PHAROLON?

| Pain | PHAROLON |
|---|---|
| Kneat / ValGenesis cost $30K–$200K/year | Free Community Edition — no per-user fees |
| Paper and SharePoint fail audits | Immutable audit trail, SHA-256 hash chain verified nightly |
| One tool per discipline — LIMS, QMS, CSV, drawing | 30+ disciplines in a single unified platform |
| CSV and CSA are handled differently | Native dual-mode: CSV and FDA CSA (Final Guidance Sept 2025) |
| Cloud-only vendors — no data control | Self-hosted. Your server. Your data. Always. |
| Black-box tools that are hard to validate | Ships with its own validation package VP-001 through VP-015 |
| No platform for ATMP / cell & gene therapy | Chain of Identity + Chain of Custody module (EE) |
| Oracle mandate but no good open source option | Full Oracle 19c+, 21c, 23ai, Autonomous Database support |

---

## Industries Served

PHAROLON is designed for **any** regulated industry, with deep specialisation in:

**Pharmaceutical & Biotech** — CSV, process validation, cleaning, sterilization, stability  
**Medical Device** — QMSR/ISO 13485 design control, DHF, MDSAP, combination products  
**Sterile Manufacturing** — EU GMP Annex 1 (2022): CCS, APS, PUPSIT  
**Cell & Gene Therapy** — ATMP Chain of Identity, Chain of Custody, donor eligibility  
**Clinical Research** — GCP system validation, EDC, CTMS, ICH E6(R3)  
**Food & Beverage** — FDA 21 CFR, HACCP, supplier qualification  
**Aerospace & Defence** — AS9100, validation lifecycle, change control  
**Contract Manufacturing** — Multi-client isolation, site segregation, GDP distribution  

---

## Platform Modules

**Validation Suite** (CE + EE)
CSV · CSA · Equipment Qualification · CQV · Analytical Instrument · Method Validation  
Process Validation (Stage 1/2/3) · Cleaning Validation · Sterilization · Cold Chain  

**Quality Management** (CE + EE)
CAPA · Change Control · Deviations · OOS/OOT · Complaints · Audit Management  
Periodic Review · Validation Debt · Inspection Readiness (FDA 483, Warning Letters)

**Document Intelligence** (CE + EE)
Controlled Documents · Block-based WYSIWYG Editor · 67 Protocol Templates  
**SOP Visualizer** — AI-powered process flowchart generation from any SOP  
**Validation Package Visualizer** — Live lifecycle map + RTM heat map

**LIMS** (EE — Phase 18-20)
Sample registration · Testing workflows · OOS/OOT investigation · CoA generation  
Stability scheduling · Instrument calibration integration  

**ATMP Suite** (EE)
Chain of Identity (COI) · Chain of Custody (COC) · Donor eligibility · Patient-specific batches

**AI Intelligence** (EE)
Draft generation · Gap analysis · Video-to-script · Audit trail anomaly detection  
Completeness scoring · Regulatory citation mapping  

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
│ PostgreSQL 15+│  Oracle 21c+    │  Redis 7+        │
│ (primary)     │  Oracle 23ai    │  (cache / queue) │
│               │  MySQL 8.0+     │                  │
└───────────────┘  (all supported)└──────────────────┘
```

**Backend:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 async · Alembic · Celery  
**Frontend:** React 18 · TypeScript · Vite · Zustand · TipTap · Recharts  
**Infrastructure:** Nginx · Gunicorn · systemd · Ubuntu 22.04/24.04 · RHEL 9

---

## Design System

PHAROLON has a purpose-built design language — dark, premium, and instantly distinctive.

- **Gold `#E2A837`** primary identity — the lighthouse gold, not another tech teal
- **Dark Teal `#00A090`** secondary — validated systems, quality assurance
- **Cormorant Garamond** display typeface — editorial weight for a platform that takes safety seriously
- **Always-dark chrome** — charcoal `#141414` header + dark teal sidebar in both themes
- **Warm pass/fail** — lime `#86C140` for pass, coral `#E54B2E` for fail
- **`#c1c1c1` light background** — white cards on medium gray, premium not sterile
- **Modal-first** — every deliberate action uses a modal. Toasts only for background events.
- **Collapsible sidebar** — 192px expanded labels, 52px collapsed icon-only with tooltips
- **SOP Visualizer** — pharma's first AI-powered interactive process flowchart

---

## 21 CFR Part 11 Compliance Architecture

| Requirement | Implementation |
|---|---|
| Audit trails `11.10(e)` | `before_flush` intercepts every write. SHA-256 chain. Nightly Celery verification. |
| Electronic signatures `11.50` | Re-authentication at every signing. Server-side timestamp only. Content hash linked at signing. |
| Access controls `11.10(d)` | RBAC, unique user IDs, concurrent session limits, periodic access review workflow. |
| System validation `11.10(a)` | Ships with validation package VP-001 through VP-015. |
| ALCOA+ | Attributable · Contemporaneous · Original · Enduring · Available — enforced by architecture. |
| FDA CSA 2025 | Dual-mode CSV/CSA. Intended use per feature. Unscripted testing capture. |
| EU GMP Annex 1 (2022) | CCS, APS, PUPSIT document types. Continuous EM. RABS/isolator protocols. |
| QMSR (Feb 2026) | Design History File, design input/output traceability, ISO 13485 management review. |

---

## Database: 418 Tables Across 11 Schema Parts

| Part | Tables | Domain |
|---|---|---|
| 1 | 130 | Core: auth, audit trail, systems, protocols, documents, workflows, CAPA |
| 3 | 31 | Quality: OOS/OOT, EM, stability, batch, complaints, inspection, SPC |
| 4 | 4 | License management |
| 5 | 33 | Validation workflows: projects, plans, sign-offs, state machines |
| 6 | 16 | Gap closure: access reviews, DR tests, method validation, supplier |
| 7 | 37 | Disciplines: logbooks, drawings, tech transfer, cleaning, cold chain, CQV |
| 8 | 20 | Document system: block model, flowcharts, validation packages |
| 9 | 91 | Platform: workspaces, teams, calendar, training, equipment, eBR, dashboards |
| 10 | 11 | Astellas SLC: RASC, SMM, SRP, EOL, SRS, EHSA, vendor releases |
| 11 | 45 | All gaps: QMSR DHF, Annex 1 CCS/APS/PUPSIT, ATMP COI, DCS, GDP, PI 041-1 |
| **Total** | **418** | UUID PKs · UTC timestamps · JSON as TEXT · No hard deletes anywhere |

---

## Oracle Full Support

PHAROLON provides genuine first-class Oracle support — not a degraded compatibility mode.

| Oracle Version | Status |
|---|---|
| Oracle 19c LTR | ✅ Primary enterprise target |
| Oracle 21c | ✅ Native JSON type (preferred) |
| Oracle 23ai | ✅ JSON Relational Duality views |
| Oracle Autonomous Database | ✅ Cloud deployments |

See `docs/architecture/ADR-016_Oracle_Full_Compatibility.md` for complete type mappings, VPD policies, DBMS_CRYPTO audit chain, and wallet-based connections.

---

## Workspace / Portfolio Hierarchy

```
Organisation
└── Site (MATC Madison)
    ├── Workspace (IT Validation)       ← data isolation + team scoping
    │   ├── Portfolio (ERP Suite)
    │   │   ├── Project: SAP Upgrade 2026
    │   │   │   ├── RASC              [Approved ✓]
    │   │   │   ├── Validation Plan   [Approved ✓]
    │   │   │   ├── IQ + Execution    [Passed   ✓]
    │   │   │   ├── OQ + Execution    [In Review ◉]
    │   │   │   ├── PQ Protocol       [Not Started]
    │   │   │   ├── RTM               [Auto-generated]
    │   │   │   └── VSR               [Pending]
    │   └── Portfolio (Lab Systems)
    └── Workspace (Manufacturing Qual)
```

Three data isolation levels: `shared` · `restricted` · `strict`

---

## CE vs EE

**Community Edition (Free, AGPL-3.0)** — Complete for single-site deployments:

Full validation lifecycle · E-signatures · Immutable audit trail · RTM · Change control  
CAPA · NCE · Deviations · Controlled documents · Low-code workflows · Periodic review  
15 standard reports · Bare metal installer · **Bundled validation package VP-001–VP-015**

**Enterprise Edition (Commercial)**

Everything in CE plus: OOS/OOT · Complaints · EM · Stability · Electronic logbooks  
Drawings/P&ID · Tech transfer · Cleaning validation · Cold chain · CQV · Process validation  
Sterilization · CSA mode · Test case library · Audit war rooms · Multi-site · SPC  
AI assistance · ATMP Chain of Identity · DCS/SCADA · GCP clinical systems  
Jira/Zephyr/Veeva/ServiceNow integrations · SAML/SSO · Custom reports

---

## Quick Start

```bash
# Requires Ubuntu 22.04+ or RHEL 9 · PostgreSQL 15+ · Redis 7+ · Node.js 20+ · Python 3.11+
git clone https://github.com/tigger2000ttfn/PHAROLON.git pharolon
cd pharolon && sudo ./scripts/install.sh
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
# → http://localhost:3000
```

---

## Project Status

| Deliverable | Status |
|---|---|
| Schema (418 tables, 11 parts) | ✅ Complete |
| Master Plan (26 phases, 30+ disciplines) | ✅ Complete |
| Design System — PHAROLON brand identity | ✅ Complete |
| URS-DOC-001 (69 document requirements) | ✅ Complete |
| Astellas SLC gap analysis (97% coverage) | ✅ Complete |
| Oracle full compatibility (ADR-016) | ✅ Complete |
| SOP Visualizer architecture | ✅ Designed |
| Validation Package Visualizer | ✅ Designed |
| Phase 0: Foundation (audit trail, e-sig, auth) | 🔨 Starting |
| Phase 1: ORM Layer (418 models) | ⏳ Upcoming |
| Phase 2: App Shell (React + PHAROLON design) | ⏳ Upcoming |

---

## Documentation

| | |
|---|---|
| [MASTER_PLAN.md](MASTER_PLAN.md) | 26-phase roadmap, all 30+ disciplines, complete addendums |
| [UI-SPEC-001](docs/ui_spec/UI-SPEC-001_Design_Specification.md) | Complete design system — PHAROLON brand |
| [ADR-016](docs/architecture/ADR-016_Oracle_Full_Compatibility.md) | Oracle 19c+ full compatibility |
| [ADR-015](docs/architecture/ADR-015_Multi_Database_Support.md) | Multi-database architecture |
| [BIZ-001](docs/business/BIZ-001_Licensing_Strategy.md) | CE/EE licensing strategy |
| [SOP Gap Analysis](docs/analysis/SOP_GAP_ANALYSIS_Astellas_SLC.md) | Astellas SLC SOP analysis |
| [3% Gap Analysis](docs/analysis/GAP_ANALYSIS_COMPLETE_REMAINING_3PCT.md) | QMSR, Annex 1, ATMP, DCS, GDP |

---

## Regulatory Coverage

- **US FDA:** 21 CFR Part 11 · 21 CFR 210/211 · 21 CFR 820 (QMSR, Feb 2026) · 21 CFR 58
- **European:** EU GMP Annex 11 · EU GMP Annex 15 · EU GMP Annex 1 (2022)
- **International:** GAMP 5 (2nd Ed.) · ICH Q2/Q8/Q9/Q10/Q11/Q12/Q13
- **CSA:** FDA Final Guidance September 24, 2025
- **Data Integrity:** ALCOA+ · MHRA GxP DI · PIC/S PI 041-1 (2021)
- **Medical Device:** ISO 13485:2016 · QMSR · MDSAP · ISO 14971

---

## Contributing

PHAROLON is built for the regulated industry community, by regulated industry professionals.

**All contributions must be GxP-aware.** Changes affecting regulated functionality require audit trail coverage and compliance test cases. See [CONTRIBUTING.md](CONTRIBUTING.md).

**We need help with:**
- Phase 0: audit trail engine, e-signature system, JWT authentication
- Template content: authoring the 67 protocol and document templates  
- Validation package: VP-001 through VP-015 documents
- Oracle dialect testing and verification

---

## License

**Community Edition:** [GNU Affero General Public License v3.0](LICENSE)

**Enterprise Edition:** Commercial license. Contact for pricing.

---

<div align="center">

*The Pharos stood for a thousand years.*  
*PHAROLON is built to last.*

**PHAROLON · Quality Intelligence for Regulated Industries**

[Design Preview](https://tigger2000ttfn.github.io/OpenVAL/) · [Docs](docs/) · [Issues](https://github.com/tigger2000ttfn/OpenVAL/issues) · [Discussions](https://github.com/tigger2000ttfn/OpenVAL/discussions)

</div>
