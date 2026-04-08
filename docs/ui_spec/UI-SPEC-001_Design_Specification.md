# OpenVAL UI/UX Design Specification

**Document Reference:** UI-SPEC-001
**Version:** 2.0.0
**Date:** 2026-04-08
**Status:** Approved for Development

---

## 1. Brand Identity

### OpenVAL Is Its Own Platform

OpenVAL is not Kneat (navy/purple). Not Veeva (corporate blue). Not SWARE (generic SaaS light).

**Identity:** Dark Teal. Open. Precise. Trusted.

Teal reads as: pharmaceutical precision, clean environments, scientific accuracy,
and technology — without the stale corporate-blue that every other pharma vendor uses.
The dark chrome (header + sidebar always dark) creates an authoritative frame around
content that feels like professional tooling, not a marketing website.

### Typography

```
Primary:    Inter (Google Fonts)
Monospace:  JetBrains Mono (for ref numbers, protocol steps, code)
```

### Personality

- Serious but not sterile
- Dense but not cluttered
- Professional but not gray-corporate-boring
- Clear but never dumbed-down

---

## 2. Color System — Complete Token Set

All values live in `frontend/src/styles/tokens.css`.
Tailwind config maps these. No hex values in component files.

### Brand Teal Scale

```css
:root {
  --teal-950: #00201E;
  --teal-900: #004D45;
  --teal-800: #006B61;
  --teal-700: #008577;
  --teal-600: #00A090;   /* PRIMARY — main CTAs, active states */
  --teal-500: #00B8A9;   /* Hover on primary */
  --teal-400: #00D4C4;
  --teal-300: #5EEADF;
  --teal-200: #A8F5F0;
  --teal-100: #D4FAF7;
  --teal-50:  #EDFFFE;
}
```

### Semantic Status Colors (theme-agnostic — same in both)

```css
:root {
  --color-pass:          #10B981;  /* Emerald - Pass / Approved / Validated */
  --color-pass-subtle:   #D1FAE5;
  --color-pass-on-dark:  #34D399;

  --color-fail:          #EF4444;  /* Red - Fail / Rejected / Critical */
  --color-fail-subtle:   #FEE2E2;
  --color-fail-on-dark:  #F87171;

  --color-warn:          #F59E0B;  /* Amber - Deviation / Pending / Due */
  --color-warn-subtle:   #FEF3C7;
  --color-warn-on-dark:  #FCD34D;

  --color-info:          #3B82F6;  /* Blue - In Review / In Progress */
  --color-info-subtle:   #DBEAFE;
  --color-info-on-dark:  #60A5FA;

  --color-ai:            #8B5CF6;  /* Purple - AI features, EE features */
  --color-ai-subtle:     #EDE9FE;
  --color-ai-on-dark:    #A78BFA;

  --color-accent:        #F97316;  /* Orange - high-energy actions */
  --color-accent-subtle: #FFEDD5;
  --color-accent-on-dark:#FB923C;
}
```

### Light Theme

```css
[data-theme="light"] {
  /* Backgrounds */
  --bg-page:          #F1F5F9;   /* Slate-100, not blinding white */
  --bg-surface:       #FFFFFF;   /* Cards, panels */
  --bg-surface-2:     #F8FAFC;   /* Nested surfaces */
  --bg-surface-3:     #F1F5F9;   /* Table zebra rows */
  --bg-header:        #0D2B2A;   /* Dark teal header — always dark */
  --bg-sidebar:       #0F3330;   /* Dark teal sidebar — always dark */
  --bg-sidebar-hover: #1A4A47;
  --bg-sidebar-active:#00A090;   /* teal-600 — active nav item */
  --bg-input:         #FFFFFF;
  --bg-input-focus:   #FFFFFF;
  --bg-code:          #F8FAFC;

  /* Borders */
  --border-default:   #E2E8F0;
  --border-strong:    #CBD5E1;
  --border-focus:     #00B8A9;   /* teal-500 focus ring */
  --border-error:     #EF4444;

  /* Text */
  --text-primary:     #0F172A;   /* Slate-900 */
  --text-secondary:   #475569;   /* Slate-600 */
  --text-tertiary:    #94A3B8;   /* Slate-400 */
  --text-disabled:    #CBD5E1;
  --text-on-dark:     #F1F5F9;   /* Text on dark header/sidebar */
  --text-on-teal:     #FFFFFF;
  --text-link:        #00A090;
  --text-link-hover:  #00B8A9;

  /* Shadows */
  --shadow-sm:   0 1px 2px rgba(0,0,0,0.05);
  --shadow-md:   0 4px 6px -1px rgba(0,0,0,0.10), 0 2px 4px -2px rgba(0,0,0,0.10);
  --shadow-lg:   0 10px 15px -3px rgba(0,0,0,0.10), 0 4px 6px -4px rgba(0,0,0,0.10);
  --shadow-modal:0 20px 60px rgba(0,0,0,0.20);
}
```

### Dark Theme

```css
[data-theme="dark"] {
  /* Backgrounds */
  --bg-page:          #0C1117;   /* Near-black with teal undertone */
  --bg-surface:       #161D26;
  --bg-surface-2:     #1E2837;
  --bg-surface-3:     #273447;
  --bg-header:        #060D0D;   /* Even darker header in dark mode */
  --bg-sidebar:       #0A1A19;
  --bg-sidebar-hover: #142B28;
  --bg-sidebar-active:#00A090;   /* Same teal active state */
  --bg-input:         #1E2837;
  --bg-input-focus:   #273447;
  --bg-code:          #0C1117;

  /* Borders */
  --border-default:   #1E3A38;
  --border-strong:    #2D4F4C;
  --border-focus:     #00B8A9;
  --border-error:     #EF4444;

  /* Text */
  --text-primary:     #F1F5F9;
  --text-secondary:   #94A3B8;
  --text-tertiary:    #64748B;
  --text-disabled:    #334155;
  --text-on-dark:     #F1F5F9;
  --text-on-teal:     #FFFFFF;
  --text-link:        #00D4C4;
  --text-link-hover:  #5EEADF;

  /* Shadows */
  --shadow-sm:   0 1px 2px rgba(0,0,0,0.30);
  --shadow-md:   0 4px 6px -1px rgba(0,0,0,0.40);
  --shadow-lg:   0 10px 15px -3px rgba(0,0,0,0.50);
  --shadow-modal:0 20px 60px rgba(0,0,0,0.70);
}
```

---

## 3. Theme System

### Three-Way Toggle

```
☀ Light  |  ⚙ System  |  ☾ Dark
```

- **System** follows OS dark/light preference (auto-switches)
- **Light/Dark** explicit user override
- Stored in `user_preferences.theme_preference` (server-synced across devices)
- Falls back to localStorage, then system preference

### Implementation (React hook)

```typescript
// frontend/src/hooks/useTheme.ts
type Theme = 'light' | 'dark' | 'system';

export function useTheme() {
  const [preference, setPreference] = useState<Theme>(
    () => (localStorage.getItem('openval-theme') as Theme) ?? 'system'
  );
  
  const resolved = useMediaQuery('(prefers-color-scheme: dark)')
    ? 'dark' : 'light';
  
  const active = preference === 'system' ? resolved : preference;
  
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', active);
    localStorage.setItem('openval-theme', preference);
  }, [active, preference]);
  
  return { preference, active, setPreference };
}
```

---

## 4. Spacing, Radius, Motion

```css
:root {
  /* Spacing (4px base) */
  --sp-1:  0.25rem;  /* 4px */
  --sp-2:  0.5rem;   /* 8px */
  --sp-3:  0.75rem;  /* 12px */
  --sp-4:  1rem;     /* 16px */
  --sp-6:  1.5rem;   /* 24px */
  --sp-8:  2rem;     /* 32px */
  --sp-10: 2.5rem;   /* 40px */
  --sp-12: 3rem;     /* 48px */
  --sp-16: 4rem;     /* 64px */

  /* Border Radius */
  --r-sm:   4px;    /* Badges, tags */
  --r-md:   6px;    /* Buttons, inputs */
  --r-lg:   8px;    /* Cards, dropdowns */
  --r-xl:   12px;   /* Modals */
  --r-full: 9999px; /* Pills, avatars */

  /* Motion */
  --motion-fast:   100ms ease-out;
  --motion-mid:    150ms ease-out;  /* Interactive elements */
  --motion-slow:   300ms ease-out;  /* Panel slides, modals */
  --motion-spring: 350ms cubic-bezier(0.34, 1.56, 0.64, 1);

  /* Layout */
  --header-h:      64px;
  --sidebar-w:     256px;
  --sidebar-w-min: 64px;   /* Collapsed icon-only mode */

  /* Modal widths */
  --modal-sm: 400px;
  --modal-md: 560px;
  --modal-lg: 720px;
  --modal-xl: 900px;
}
```

---

## 5. Application Shell

### Header (always dark, both themes)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [≡]  OPENVAL          [◆ MATC Madison ▼]     [⌘K Search...]  [🔔3][👤] │
└──────────────────────────────────────────────────────────────────────┘
```

- Always dark background (`--bg-header`)
- OpenVAL wordmark: white, Inter SemiBold
- Site selector dropdown: shows user's sites, switch with click (logs site change in audit)
- Global search: ⌘K / Ctrl+K opens full overlay
- Notification bell: badge count; click opens right-drawer panel (not dropdown)
- User avatar: initials or uploaded photo; click opens user menu

### Sidebar (always dark, both themes)

The sidebar is permanently dark in both light and dark themes.
This creates a strong, consistent chrome that visually anchors the entire app.

Active state: `--bg-sidebar-active` (teal-600), left border `--teal-300`, white text
Hover state: `--bg-sidebar-hover`
EE items: show `◆` diamond indicator in teal-300
Collapsed mode: 64px, icons only, tooltip on hover

See MASTER_PLAN.md Section 5 Phase 2 for full navigation structure.

---

## 6. Modal-First Interaction Design

### The Rule

**Modals for all deliberate decisions. No exceptions.**

Every action that:
- Creates, modifies, or deletes a record
- Requires user confirmation
- Requires an electronic signature
- Could have unintended consequences

...uses a modal.

### Toast Usage (exceptional — background system events only)

Toast notifications appear **bottom-left, 4 seconds auto-dismiss, max 3 stacked**.

ONLY for:
- Background task completion (report generated, backup done, import complete)
- License expiry notification (once per session)
- Network connectivity restored
- Audit chain nightly verification result

NEVER for:
- Record save success → success state inline or success modal
- Validation errors → inline form errors below the field
- Confirmation of destructive actions → confirmation modal
- Loading states → skeleton loaders

### Modal Anatomy

```
╔══════════════════════════════════════════════════════════════╗
║  [icon]  Modal Title                                    [✕]  ║  48px header
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Context: one or two sentences explaining what is            ║
║  happening and what the user must decide.                    ║
║                                                              ║
║  [Content — form fields, record summary, warning text]       ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  [Secondary action]            [Cancel]  [Primary action]   ║  60px footer
╚══════════════════════════════════════════════════════════════╝
```

Rules:
- Primary action: rightmost, teal if positive, red if destructive
- Cancel: always present and always works
- Escape key closes (unless data has been entered — then asks for confirmation)
- Click outside does NOT close (prevents accidental dismissal)
- Focus trapped inside for accessibility
- Max one modal layer (confirmation dialogs on top of modals allowed, no deeper)
- Overlay: 60% black on light theme, 70% black on dark theme

### Signature Modal (21 CFR Part 11)

```
╔══════════════════════════════════════════════════════════════╗
║  ✍  Electronic Signature Required                      [✕]  ║
╠══════════════════════════════════════════════════════════════╣
║  Signing:                                                    ║
║  ┌──────────────────────────────────────────────────────┐   ║
║  │  CAPA-0042 · Root Cause: Incorrect calibration       │   ║
║  │  Version 1.0 · Last modified 2026-04-08 14:23 UTC    │   ║
║  └──────────────────────────────────────────────────────┘   ║
║                                                              ║
║  Signature Meaning                                           ║
║  ● APPROVED — I approve this record for its intended use.   ║
║                                                              ║
║  Username   [m.escamilla                ] (read-only)       ║
║  Password   [••••••••••                 ]                    ║
║  MFA Token  [      ]  (required for approvals)              ║
║                                                              ║
║  ☐  I understand the meaning of this electronic signature   ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                              [Cancel]  [Sign Record     ]   ║
╚══════════════════════════════════════════════════════════════╝
```

---

## 7. User Profile System

### Profile Page /profile — Section Layout

**Identity:** Avatar upload/crop, full name, job title, department, email, phone, signature display name

**Site Access:** Sites with roles; request additional access button

**Security:**
- Change password panel
- MFA: status chip, setup wizard, backup codes
- Active sessions table (device, IP, location, last active, revoke button)
- Login history (last 20, from audit_log)

**Preferences:**
```
Theme:        [Light] [System] [Dark]
Date format:  [MM/DD/YYYY] [DD/MM/YYYY] [YYYY-MM-DD]
Time format:  [12h] [24h]
Timezone:     [Auto-detect] [select dropdown]
Language:     [English (US) ▼]
Rows/page:    [25 ▼]
Default dashboard: [Validation Engineer ▼]
Sidebar default:   [Expanded] [Collapsed]
```

**Notifications:**

| Event | Email | In-App | Teams | Slack |
|---|---|---|---|---|
| Task assigned to me | ✓ | ✓ | ○ | ○ |
| Task overdue | ✓ | ✓ | ○ | ○ |
| Document for signature | ✓ | ✓ | ○ | ○ |
| ... per event type ... | | | | |

**My Signatures:** Table of recent signed records with meaning, date, record link

---

## 8. DataTable (Universal List Component)

```
┌──────────────────────────────────────────────────────────────────────┐
│  [🔍 Search...]  [Type▼] [Status▼] [Assignee▼]  [Clear] [↑↓][Export▼]│
├──────┬────────┬──────────────────────────┬────────────┬──────────────┤
│  ☐   │ REF    │ TITLE                    │ STATUS     │ MODIFIED  ⋮ │
├──────┼────────┼──────────────────────────┼────────────┼──────────────┤
│  ☐   │CA-042  │ Calibration deviation... │ ●APPROVED  │ 2d ago     ⋮│
│  ☐   │CA-041  │ Training gap found       │ ●IN REVIEW │ 3d ago     ⋮│
│  ☑   │CA-040  │ OOS Phase 2 escalation  │ ⏰OVERDUE  │ 5d ago     ⋮│
├──────┴────────┴──────────────────────────┴────────────┴──────────────┤
│  1-25 of 127  [‹ Prev] [1][2][3]...[6] [Next ›]   25/page[▼]        │
│  1 selected  [Bulk Actions ▼]                                        │
└──────────────────────────────────────────────────────────────────────┘
```

Row click → opens DetailPanel slide-in (right, 50% width)
Row double-click → navigates to full record page
⋮ menu → context actions (view, edit, duplicate, export, archive, delete)

Column sorting, resizing, show/hide, persistent filter (URL params).

---

## 9. Architecture: Tech Stack Explained

### What React Is

React is a JavaScript library that runs in the user's **browser**. It renders
the interface. It sends HTTP requests to the backend API.

```
USER'S BROWSER                        YOUR SERVER
├── Downloads compiled React app      ├── Nginx (web server, port 443)
│   (HTML + CSS + JS files)           │   ├── Serves React files (static)
│                                     │   └── Proxies /api/* to FastAPI
├── React renders the UI              │
│                                     ├── FastAPI/Gunicorn (port 8000)
└── Click "Save CAPA"                 │   ├── Validates request
    └── POST /api/v1/capas ─────────────►  ├── Saves to PostgreSQL
        ◄─── { success: true } ─────────  └── Returns response
```

### What FastAPI Is (NOT Django)

FastAPI is a Python web framework. Django is a different Python web framework.
We chose FastAPI because:
- Async by default (more concurrent users)
- Auto-generates OpenAPI/Swagger docs (useful for validation)
- Type-safe with Pydantic validation
- More modern, faster, cleaner
- SQLAlchemy handles the database separately (more control)

### Development vs Production

**Development mode:**
```bash
# Terminal 1: Backend with hot-reload
cd backend && uvicorn app.main:app --reload --port 8000

# Terminal 2: Frontend with hot-reload (Vite)
cd frontend && npm run dev  → http://localhost:3000

# Features when DEBUG=true:
# - Swagger UI: http://localhost:8000/api/docs
# - All error stack traces visible
# - Development license (all EE features unlocked)
# - No rate limiting
# - Code changes reload instantly (HMR for frontend, uvicorn --reload for backend)
```

**Production mode:**
```bash
# 1. Build React to static files
cd frontend && npm run build → creates frontend/dist/

# 2. Run FastAPI with Gunicorn (4 workers)
gunicorn app.main:app --workers 4 --worker-class uvicorn.workers.UvicornWorker --bind 127.0.0.1:8000

# 3. Nginx serves everything:
#    - GET /             → serves frontend/dist/index.html (React app)
#    - GET /assets/*     → serves frontend/dist/assets/* (JS/CSS, cached 1yr)
#    - GET/POST /api/*   → proxied to localhost:8000 (FastAPI)

# Managed by systemd:
# openval-api.service      → Gunicorn
# openval-worker.service   → Celery
# openval-beat.service     → Celery Beat
```

### Supported Platforms

- **Ubuntu 22.04 LTS** (primary, recommended)
- **Ubuntu 24.04 LTS** (fully supported)
- **RHEL 9 / Rocky Linux 9 / AlmaLinux 9** (enterprise alternative)
- **Docker/Docker Compose** (Phase 20 — optional deployment method)
- **Windows Server** (via Docker only — not native Python support planned)

The install.sh detects the OS and uses apt (Ubuntu) or dnf (RHEL).
The application is OS-agnostic at the Python/Node level — the install.sh
handles the OS-specific parts.

---

## 10. Status Badge System

Universal across all modules. Never rely on color alone (text label always present).

```
Neutral/Gray:   DRAFT   VOIDED   SUPERSEDED   ARCHIVED
Blue:           IN REVIEW   IN PROGRESS   EXECUTING   SCHEDULED
Green/Pass:     APPROVED   EFFECTIVE   VALIDATED   PASSED   ACTIVE
Red/Fail:       REJECTED   FAILED   CRITICAL   CLOSED-FAIL
Amber/Warn:     PENDING   DEVIATION   DEVIATION   REVIEW DUE   ON HOLD
Red+Clock:      ⏰ OVERDUE
Amber+Clock:    ◷ DUE SOON
Teal+Diamond:   ◆ ENTERPRISE FEATURE
Purple+Star:    🤖 AI ASSISTED
Orange:         ⚡ ACTION REQUIRED
```

---

## 11. Project Management Module

Validation is project work. OpenVAL needs a project management layer.

### Project Board (Kanban)

Four default columns: Backlog → In Review → Approved → Executing → Complete
Cards: protocol ref, title, assignee avatar, due date chip, result badge
Drag within columns (reorder priority). Column transitions require proper lifecycle action.

### Milestone Timeline

Gantt-lite view: milestones as horizontal bars colored by status.
No day-level granularity needed — week-level is sufficient.
Click a milestone bar to view/edit the milestone detail.

### Resource View

Per team member: how many open tasks, which projects, workload indicator.
Who is overloaded? Who has capacity? 

### Integration: Jira (EE)

```
OpenVAL Project    ↔  Jira Project
OpenVAL Protocol   ↔  Jira Epic
OpenVAL Test Step  ↔  Jira Task
OpenVAL Deviation  ↔  Jira Bug
OpenVAL CAPA Task  ↔  Jira Story
```
OpenVAL is GxP system of record. Jira reflects status.
Jira closure does not auto-close OpenVAL (requires e-signature).

### Integration: Zephyr Scale (EE)

```
OpenVAL Test Case Template  ↔  Zephyr Test Case
OpenVAL Protocol            ↔  Zephyr Test Cycle
OpenVAL Execution Results   ↔  Zephyr Execution
```
For orgs using Jira/Zephyr as central test repository.

### Integration: Veeva Vault (EE)

```
OpenVAL Deviation    → Vault Quality Event
OpenVAL CAPA         ↔  Vault CAPA (status sync)
OpenVAL Change Req   ↔  Vault Change Control
OpenVAL Document     → Vault Document (publish)
```

### Integration: ServiceNow (EE)

```
OpenVAL System       ↔  ServiceNow CMDB CI
OpenVAL Change Req   ↔  ServiceNow RFC
OpenVAL NCE          ↔  ServiceNow Incident
```

---

## 12. Honest Completeness Assessment

### Comprehensively Covered (solid foundation)
- 251 database tables across 7 schema parts
- 26 development phases
- All 30 validation disciplines
- CSA (FDA 2025) + CSV dual mode
- CE/EE open core architecture
- PostgreSQL/Oracle/MySQL multi-database
- Electronic signature engine
- Audit trail hash chain
- All Kneat/SWARE/ValGenesis competitive features
- Integration specs: LabWare, TrackWise, SAP, MES, Jira, Zephyr, Veeva, ServiceNow

### Still Needs Full Authoring (next sessions)
- docs/validation_package/ — VP-001 through VP-015
- templates/ — all 30+ protocol and document template content
- API spec update for Phase 7 endpoints
- Performance requirements / load testing targets
- Onboarding first-run wizard spec
- Mobile/tablet execution mode spec

**The plan is comprehensive. Phase 0 code can begin.**

---
*UI-SPEC-001 v2.0.0 — Dark Teal. Modal-first. Light + Dark. OpenVAL's own identity.*

## 2.1 Design System Refinements (v2.1 — April 2026)

### Confirmed Design Decisions

**Header treatment (both themes):**
Dark theme header: `#141414` (pure charcoal — NOT teal)
Light theme header: `#141414` (same charcoal — less teal, unified identity)
Both: white text, gold notification bell, teal logo mark gradient

Rationale: the user found "too much teal on the header for light theme."
Charcoal header with teal sidebar = strong, premium chrome without teal overload.

**Gold accent system:**
```css
--gold-400: #F0C040;   /* Bright gold — active glow */
--gold-500: #E2A837;   /* Primary gold — notification bell, priority, milestones */
--gold-600: #C9981A;   /* Rich gold — text on light, second reviewer signatures */
--gold-700: #A87E14;   /* Deep gold — borders, EE indicator borders */
```

Gold is used for:
- Notification bell icon (always, both themes)
- Unread notification count badge (number on bell)
- Priority / action-required indicators
- Milestone markers and star bookmarks
- Overdue status indicators (instead of plain amber)
- EE Enterprise tier chip
- Second-level reviewer signatures (first reviewer = green, second = gold)
- Left-border accent on urgent KPI cards
- Pending approval count badges in sidebar

**Light theme page background: #c1c1c1**
Cards/surfaces: #FFFFFF (white cards on medium gray — strong contrast, premium feel)
Secondary surface: #F5F5F5
Not the white/off-white generic SaaS look

**Text rules (fixed):**
- ALL text on dark surfaces (header, sidebar, dark cards): use rgba(255,255,255,N)
- Primary text on dark: #FFFFFF / rgba(255,255,255,1.0)
- Secondary text on dark: rgba(255,255,255,0.55)
- Tertiary / meta on dark: rgba(255,255,255,0.35)
- NEVER use dark hex like #333, #555 on dark backgrounds
- Teal brand text on dark: var(--teal-300) = #5EEADF

**Icon treatment (Font Awesome-inspired):**
Use Lucide React icons (similar FA feel) in implementation.
In mockups: clean geometric unicode symbols at consistent weight.
Icon color on dark sidebar: rgba(255,255,255,0.4) for inactive, #5EEADF for active.
Gold icons: notification bell, star/bookmark, priority indicators.

**Status badge system (more creative, less gray):**
Every status has a distinct semantic color — avoid monochromatic gray overuse.
PASSED = emerald green · FAILED = red · IN REVIEW = blue · OVERDUE = gold (not gray amber)
APPROVED = teal · DRAFT = subtle gray · AI ASSISTED = purple · ENTERPRISE = teal outline

**Signature display:**
First approver (QA): green teal gradient avatar + green checkmark + green name
Second reviewer: gold gradient avatar + gold checkmark + gold name
Unsigned slot: dashed border + "Awaiting signature" placeholder text


---

## 2.2 Final Agreed Design System (v2.2 — April 2026 Moodboard Sign-off)

### Warm Accent Pass/Fail System

```css
/* PASS — warm lime-green (not cool emerald) */
--pass:        #86C140;
--pass-dark:   #4A7A18;
--pass-light:  #D4EDAA;

/* FAIL — warm coral-red (not pure red) */
--fail:        #E54B2E;
--fail-dark:   #9A2114;
--fail-light:  #FAC5BA;

/* DEVIATION — orange (warm, attention without alarm) */
--orange:      #F97316;
--orange-dark: #C2510D;
--orange-light:#FED7AA;
```

### Sidebar Collapse Behavior

**Expanded state:** 192px wide — icon + full label text
**Collapsed state:** 52px wide — icon only
**Toggle:** header hamburger button (◁ / ▷ direction indicates action)
**Transition:** 200ms ease slide — sidebar collapses left, content area expands
**Collapsed icons:** centered, 36×36px rounded squares, tooltip on hover
**Active state in collapsed:** same teal-600 background on the icon square
**Badge dots in collapsed:** small circle overlaid top-right of icon (gold = action needed, red = critical)
**User preference saved:** localStorage + user_preferences.sidebar_collapsed

### Signature Color Hierarchy

Three signatories each get a distinct warm accent:
1. QA Approver — **Green** (#86C140) avatar, name, checkmark
2. Reviewer/Validator — **Gold** (#E2A837) avatar, name, checkmark
3. Author/Originator — **Orange** (#F97316) avatar, name, checkmark

Unsigned slot: dashed border, ghost avatar with "+" symbol, "Awaiting signature" text

### Complete Status Badge Library

| Badge | Color | Use |
|---|---|---|
| PASSED | Warm green #86C140 | Protocol/step passed |
| FAILED | Warm coral #E54B2E | Protocol/step failed |
| DEVIATION | Orange #F97316 | Deviation flagged during execution |
| IN REVIEW | Blue #60A5FA | Awaiting reviewer action |
| OVERDUE | Gold #E2A837 | Past due date |
| APPROVED | Teal #00D4C4 | Approved and current |
| EFFECTIVE | Teal filled | Approved and in effect |
| DRAFT | Muted slate #94A3B8 | Being authored |
| AI ASSISTED | Purple #A78BFA | AI generated content |
| EE / ENTERPRISE | Teal outline | Enterprise feature |
| PRIORITY | Gold star | Starred / priority flag |
| SUPERSEDED | Gray | Replaced by newer version |
| REJECTED | Coral | Rejected in review |
| EXECUTING | Blue pulsing | Protocol actively being run |

