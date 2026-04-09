# OpenVAL Licensing Strategy and Business Model

**Document Reference:** BIZ-001
**Version:** 1.0
**Date:** 2026-04-07
**Status:** Approved

---

## 1. Model: Open Core

OpenVAL follows the **Open Core** model, the same model used by GitLab,
Metabase, Mattermost, Posthog, Airbyte, and many other successful open
source infrastructure companies.

The core platform is genuinely free and open source. It is not crippled.
It is not a demo. It is a complete, production-grade CSV platform that
delivers real value without payment.

Enterprise features that specifically serve multi-site organizations,
advanced analytics, AI assistance, and deep integrations are commercial.

This is not a bait-and-switch. The CE/EE boundary is documented upfront
and enforced transparently.

---

## 2. Editions

### Community Edition (CE)

**License:** GNU Affero General Public License v3.0 (AGPL-3.0)
**Price:** Free forever
**Hosting:** Self-hosted (bare metal or Docker)
**Support:** Community (GitHub Issues, Discussions)
**Validation Package:** Bundled, execute yourself

CE is the right choice for:
- Small to mid-size pharmaceutical sites (up to ~100 users)
- Single-site operations
- Clinical-stage biotechs and academic GMP facilities
- CDMOs that want full data ownership
- Any site where IT has the capability to self-host
- Sites transitioning from paper or SharePoint

CE is a complete CSV platform. It replaces the need for Kneat or Valgenesis
for the majority of single-site validation programs.

### Enterprise Edition (EE)

**License:** OpenVAL Enterprise License (commercial, proprietary for EE features)
**Price:** See Section 7
**Hosting:** Self-hosted (bare metal or Docker) — same deployment as CE
**Support:** Standard or Premium tier (see Section 8)
**Validation Package:** Bundled for CE core features; EE features include
their own validation documentation (addendum to CE package)

EE adds features on top of CE. EE is not a separate codebase. It is CE plus
a licensed set of additional modules that are unlocked by a license key.

EE is the right choice for:
- Multi-site pharmaceutical networks
- Organizations needing AI-assisted quality workflows
- Sites with deep integration requirements (SAP, TrackWise, MES)
- Large organizations needing SPC/manufacturing analytics
- Sites that want priority support SLA

### Cloud Edition (Future — Phase 25+)

A managed cloud offering of OpenVAL EE, hosted by the OpenVAL team.
For organizations that prefer SaaS over self-hosting.
Pricing: per-user per-month with annual commitment option.

---

## 3. Feature Split: CE vs EE

The guiding principle for the CE/EE boundary:

> CE contains everything needed to replace paper and SharePoint
> for a complete CSV program at a single site.
> EE contains everything that makes OpenVAL an enterprise platform.

### Community Edition Features (free, AGPL)

**Validation Core**
- System and equipment inventory (unlimited records)
- GAMP 5 classification and GxP impact assessment
- Guided Validation Wizard (single-system)
- Risk assessment engine (FMEA and probability/impact)
- Requirements management (URS, FS, DS, CS)
- Protocol builder (IQ, OQ, PQ, UAT, MAV, DQ, FAT, SAT)
- Test execution engine with step-by-step execution
- Screenshot and attachment capture per step
- Inline deviation capture during execution
- Electronic signatures (21 CFR Part 11)
- Immutable audit trail with hash chain integrity
- Traceability matrix (automated, real-time)
- Periodic review scheduler and execution

**Quality Management**
- Change control (full lifecycle)
- CAPA management (full lifecycle)
- Nonconformance management
- Deviation management
- Vendor qualification (basic)
- Audit management (basic)
- Training records (basic)

**Document Management**
- Document library (unlimited documents)
- Template engine with variable substitution
- Rich text editor (TipTap)
- Version control with diff view
- Approval workflows (up to 3 stages)
- Document distribution and read confirmation

**Workflow Engine**
- Visual workflow builder
- Up to 5 workflow stages per definition
- Role-based and user-based routing
- SLA and escalation
- Email notifications

**Reporting**
- Pre-built system reports (15 standard reports)
- Validation status dashboard
- Compliance scorecard (single site)
- Audit trail viewer and export

**Administration**
- Single site / single organization
- Up to 50 user accounts
- Local authentication (username + password + TOTP MFA)
- LDAP/AD user sync (basic: import users)
- Role-based access control
- Email (SMTP) notifications
- Bare metal installer (Ubuntu + RHEL)
- Backup and restore scripts
- Bundled IQ/OQ/PQ validation package

**Integrations (CE)**
- REST API (read-only endpoints)
- Inbound webhooks (receive from external systems)
- CSV/Excel import and export

### Enterprise Edition Features (commercial license)

**Advanced Validation**
- Multi-site management (unlimited sites, central dashboard)
- Cross-site document publishing and controlled copy management
- Organization-level compliance dashboard (all sites)
- OOS/OOT management module
- Complaint management module (21 CFR 211.198 / 820.198)
- Environmental monitoring module (full EM program management)
- Stability study management (ICH Q1A/Q1B)
- Batch and lot management with lot release workflows
- Certificate of Analysis generation and approval
- Inspection readiness module (automated checks, mock inspection)
- Validation Setup Wizard (multi-system portfolio planning)

**Advanced Workflow and Forms**
- Unlimited workflow stages
- Conditional stage routing (if/then logic)
- Parallel approval stages
- Low-code form builder (embedded forms in workflow stages)
- Advanced escalation chains (multi-level)
- Workflow simulation and testing mode
- Custom field definitions on any module record

**Advanced Analytics**
- Statistical Process Control (SPC) module
- Nelson and Western Electric rules engine
- Out-of-control detection with automated OOT creation
- SPC charts for EM, stability, OOS rates, CAPA cycle times
- Process capability indices (Cp, Cpk)
- Batch evolution charts
- Cross-system trend analysis

**Manufacturing Analytics**
- Process parameter ingestion (REST API and file drop)
- Real-time process monitoring dashboard
- Batch-to-batch comparison charts
- CPP/CQA correlation analysis
- Manufacturing analytics extension (DCP-inspired)
- Non-GxP analytics module with clear GxP boundary labeling

**AI Assistance (EE only)**
- SOP draft assistant (AI-generated first draft from title + scope)
- Regulatory gap checker (compare SOP vs CFR citation)
- Similar document finder
- Root cause suggestion engine (CAPA)
- Similar CAPA finder with effectiveness outcomes
- Deviation pattern analysis (recurring, cross-system)
- Risk item suggestion engine
- Training gap predictor
- AI governance framework (model registry, suggestion audit log)
- AI transparency labeling on all AI-assisted records
- Phase 2 AI: semantic document search, predictive quality

**Advanced Integrations**
- Full REST API (read + write)
- LabWare LIMS deep integration (bidirectional sync, EM/OOS webhooks)
- TrackWise integration (change record and CAPA sync)
- SAP/Oracle equipment master sync
- MES integration (batch events, process parameters)
- Tempo MES specific integration
- Outbound webhooks to external systems
- Microsoft Teams and Slack notification integration
- Integration health monitoring dashboard
- Custom integration framework (build your own)

**Advanced Identity and Security**
- SAML 2.0 and OIDC SSO
- Advanced LDAP (group-to-role mapping, attribute sync)
- SCIM user provisioning
- IP address allowlist
- Concurrent session limit enforcement
- Advanced password policies (configurable per site)
- Session activity monitoring

**Advanced Reporting**
- Custom report builder (drag-and-drop field selection)
- Scheduled report delivery (email, Teams, Slack)
- Cross-site reports and dashboards
- Executive dashboard (KPI across all sites)
- Data export API (bulk export of records in JSON/CSV)
- Report template library

**Priority Support**
- Named support contact
- SLA-backed response times
- Access to product roadmap and beta features
- Dedicated onboarding assistance

---

## 4. What Is Never Paywalled

The following are core to OpenVAL's regulatory value proposition
and will never be moved to EE:

- Audit trail (immutable, hash-chain integrity)
- Electronic signatures (21 CFR Part 11 compliant)
- ALCOA+ data integrity architecture
- Full protocol execution engine
- Bundled IQ/OQ/PQ validation package for the CE core
- Access controls and RBAC
- All data export (users own their data, always)
- API access for read operations
- The SDL and architecture documentation

OpenVAL will never hold a site's validation data hostage behind a license.
Any site can export all their data at any time regardless of edition.

---

## 5. Technical Enforcement Model

### License Key System

Enterprise features are unlocked via a license key stored in the database.
The license key encodes:

- Organization name and ID
- Licensed edition (EE)
- Licensed features (JSON array of feature codes)
- Licensed user count
- Licensed site count
- Expiry date
- Issued by (OpenVAL team signature)
- Cryptographic signature (RSA-2048) to prevent tampering

License keys are validated:
1. At application startup
2. Once per hour by a background task
3. At every request to an EE-gated endpoint

If a license expires, EE features become read-only (no new records, no edits)
for 30 days. After 30 days, EE features become inaccessible. CE features
always remain fully functional regardless of license state.

### Feature Flag Integration

EE features are controlled via the existing `feature_flags` table.
License validation sets feature flags automatically. Site admins cannot
manually enable EE feature flags without a valid license.

```python
# Backend: checking EE feature access
from app.core.license import require_feature

@require_feature("oos_oot_management")
async def create_oos_record(...)
    ...

# Returns 402 Payment Required if feature not licensed
# Returns 403 Forbidden if user lacks permission
# Returns 200 if both licensed and permitted
```

### UI Gating

EE features in the sidebar are visible to all users with a clear label:

```
⭐ Environmental Monitoring  [Enterprise]
⭐ Stability Studies         [Enterprise]  
⭐ Manufacturing Analytics   [Enterprise]
```

Clicking an EE feature without a license shows an upgrade page
(not a dead end or an error). The upgrade page includes:
- What the feature does
- How it would help their specific role
- Link to get a license
- Link to request a demo

This approach is used by Metabase, Posthog, and GitLab because it works.
Users understand the value before being asked to pay.

---

## 6. Code Architecture for Open Core

### Repository Structure

```
openval/                          Single repository (monorepo)
  backend/
    app/
      modules/
        community/                AGPL-3.0 code
          systems/
          protocols/
          documents/
          workflows/
          change_control/
          capa/
          ...
        enterprise/               Commercial license code
          oos_oot/
          complaints/
          em/
          stability/
          batch_lot/
          inspection_readiness/
          spc/
          manufacturing_analytics/
          ai_assistance/
          advanced_integrations/
          multi_site/
          ...
      core/                       Core infrastructure (AGPL)
        audit.py
        signatures.py
        license.py                License validation engine
        feature_flags.py
        ...
  frontend/
    src/
      community/                  AGPL components and pages
      enterprise/                 EE components (loaded conditionally)
        oos_oot/
        em/
        stability/
        ...
```

### How EE Modules Load

```python
# app/main.py

from app.modules.community import register_community_routers
from app.core.license import get_license

def create_app():
    app = FastAPI()
    register_community_routers(app)
    
    license = get_license()
    if license.is_valid and license.has_feature("oos_oot"):
        from app.modules.enterprise.oos_oot import router
        app.include_router(router, prefix="/api/v1")
    
    if license.is_valid and license.has_feature("ai_assistance"):
        from app.modules.enterprise.ai_assistance import router
        app.include_router(router, prefix="/api/v1")
    
    # ... etc
    return app
```

### Frontend Conditional Loading

```typescript
// hooks/useFeature.ts
export function useFeature(featureCode: string): boolean {
  const { features } = useAuthStore()
  return features.includes(featureCode)
}

// In sidebar:
{useFeature('em_monitoring') ? (
  <NavItem to="/em" label="Environmental Monitoring" />
) : (
  <NavItemLocked to="/upgrade/em" label="Environmental Monitoring" tier="enterprise" />
)}
```

### Build Process

**CE Build:**
```bash
# Strips enterprise/ directories from build
npm run build:community
python build_ce.py  # generates CE distribution without enterprise/ modules
```

**EE Build:**
```bash
# Includes all modules
npm run build:enterprise
python build_ee.py  # full distribution
```

CE distributions are published to GitHub as open source releases.
EE distributions are provided to licensed customers via a private package registry.

### Database Schema

All tables (CE and EE) are defined in the schema files. This means:
- CE installations have all the tables (empty, unused EE tables)
- Migrating from CE to EE requires only adding a license key, not a schema migration
- No data is lost if a license expires (data stays, features become read-only)

This is the correct approach. Tying schema to license tier creates upgrade pain.

---

## 7. Pricing Tiers

### Community Edition
**Free** — No credit card required.

### Enterprise Edition

| Tier | Users | Sites | Price | Notes |
|---|---|---|---|---|
| EE Starter | Up to 25 | 1 | TBD | Ideal for small sites or clinical biotechs |
| EE Growth | Up to 100 | Up to 3 | $14,400/year | Mid-size single-company operations |
| EE Scale | Up to 300 | Up to 10 | $36,000/year | Multi-site pharmaceutical networks |
| EE Enterprise | Unlimited | Unlimited | Custom | Global pharmaceutical companies |

All EE tiers include:
- All EE features
- Annual license key
- Standard support (email, 5 business day SLA)

**Premium Support Add-on** (any EE tier): +$6,000/year
- Named support contact
- 24-hour response SLA for critical issues
- Dedicated onboarding session (8 hours)
- Quarterly product roadmap briefing
- Beta feature access

**Implementation Services** (optional):
- OpenVAL Setup and Configuration: $3,500 (remote, up to 3 days)
- Validation Package Execution Support: $2,500 (remote, up to 2 days)
- Integration Development: custom quote
- Training (for validation/QA teams): $1,500/day

### Pricing Rationale

Kneat and Valgenesis pricing is not public but based on industry knowledge:
- Kneat: approximately $30,000-80,000/year for mid-size sites
- Valgenesis: approximately $60,000-200,000/year for enterprise

OpenVAL EE is significantly cheaper than
Kneat for comparable functionality. The value proposition is real.

The goal is not to maximize price. The goal is to maximize adoption by
making the cost low enough that budget approval is trivial for any site
that has faced a regulatory finding about their CSV program.

---

## 8. Open Source Sustainability Model

OpenVAL's sustainability depends on:

1. **EE license revenue** — Primary revenue source
2. **Implementation services** — One-time revenue from new deployments
3. **Support contracts** — Recurring revenue from Premium support
4. **Cloud Edition** (future) — Recurring SaaS revenue

**What this funds:**
- Core maintainer salaries
- Security infrastructure and audits
- Documentation and content
- Community management

**What this does NOT change:**
- The CE remains genuinely free and open source
- CE features are never removed or paywalled
- The codebase remains publicly visible
- Contributors retain attribution
- Sites can always self-host CE at zero cost

---

## 9. Competitive Moat

OpenVAL's sustainable advantage over commercial competitors:

**vs Kneat and Valgenesis:**
- Free CE removes the "we can't afford it" objection
- Self-hosted removes the "we can't put GxP data in cloud" objection
- Bundled validation package removes the "validating the validator is too hard" objection
- Open source removes vendor lock-in concern

**vs generic open source tools (OpenProject, JIRA):**
- Purpose-built for CSV, not adapted from generic PM tools
- Ships with pharmaceutical-specific templates
- Compliance controls built into the architecture, not bolted on
- No GxP gap analysis required — it was designed for GxP from the start

**vs another CSV tool building on the same model:**
- First-mover advantage in open source GxP CSV space
- Community network effects (shared templates, shared validation packages)
- Growing template library that gets better with every contributor

---

## 10. Community Edition Limits and Upgrade Triggers

### Soft Limits (enforced with warning, not hard block)

| Resource | CE Limit | EE |
|---|---|---|
| User accounts | 50 | Unlimited |
| Sites | 1 | Per tier |
| Workflow stages per definition | 5 | Unlimited |
| Stored files | 20 GB | Unlimited |

When CE limits are approached (80%), a banner appears:
"You are approaching the Community Edition limit for [resource].
Upgrade to Enterprise for unlimited [resource]."

Hard enforcement kicks in at the limit. No silent failure.

### Natural Upgrade Triggers

Sites naturally outgrow CE when they:
- Need a second or third site
- Need OOS/OOT investigation workflows
- Need full LIMS or TrackWise integration
- Need AI-assisted quality workflows
- Need the inspection readiness module
- Grow beyond 50 users
- Need manufacturing analytics

---

## 11. License Compliance for OpenVAL Itself

OpenVAL must be validated like any other GxP system. The validation package
covers CE features. EE features require:

- EE Feature Addendum to the Validation Plan
- Additional OQ test cases for EE modules
- Updated URS covering EE requirements
- Updated RTM

These documents are provided to EE licensees as part of the license.

---

*BIZ-001 v1.0 - OpenVAL Licensing Strategy and Business Model*
