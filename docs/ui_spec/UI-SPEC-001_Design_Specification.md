# PHAROLON UI/UX Design Specification

**Document Reference:** UI-SPEC-001
**Version:** 2.0.0
**Date:** 2026-04-08
**Status:** Approved for Development

---

## 1. Brand Identity

### PHAROLON — Two Ancient Wonders, One Mark

**Name:** PHAROLON = PHAROS (the Pharos of Alexandria lighthouse) + -LON  
**Version:** UI-SPEC-001 v2.4 — updated for PHAROLON brand finalisation  
**Icon locked:** 2026-04-23

PHAROLON is not Kneat (navy/purple). Not Veeva (corporate blue). Not SWARE (generic SaaS light).
The brand references two of the Seven Wonders of the Ancient World — both Egyptian, both eternal.

---

### The Icon

The PHAROLON mark is a **upward pyramid (△) inside a compass ring (◎)**.

| Element | Meaning |
|---|---|
| Nested triangles (gold/teal/purple) | The Great Pyramid of Giza — built to last |
| Compass ring + cardinal ticks | Navigation through regulatory complexity |
| Dashed horizon line | The sea — the regulatory danger the lighthouse stands above |
| Apex beacon (triple-flash) | The Pharos lighthouse — guiding every vessel |
| Ghost pyramid (draws itself in) | The form that only appears when you look closely enough |
| Beam rays from apex | Light emanating from the lighthouse tip |

**Outer △:** `#C9981A` gold — monumental, primary  
**Mid △:** `#00A090` teal — quality, precision  
**Inner △:** `#8B5CF6` purple — AI, enterprise intelligence  
**Apex dot:** `#F5D060` warm gold — the lighthouse beacon  

The compass ring ticks rotate slowly (100s full rotation). The apex triple-flashes like a real
lighthouse (4.5s cycle). The ghost outer pyramid draws itself in transparently every 11s.
Beam rays originate precisely from the apex tip (cx=55 cy=14 in the 110×110 viewBox).

---

### Wordmark

```
Font:           Syne 800
Letter-spacing: 0  (no stretch — Syne 800 is naturally wide)
P treatment:    translateY(0.14em) — drops like a lowercase descender
Gradient:       180deg · #F5D060 → #E2A837 → #B8820E → #8A5F08
```

The P descends below the baseline of the remaining letters, echoing the lighthouse
standing below the horizon line in the icon. Deliberate. Precise. Not accidental.

**Icon-as-A variant:** The pyramid icon replaces the A in PHAROLON — PH△ROLON.
Available as a secondary wordmark for contexts where the icon and letterform are unified.
### Acronym — pH

**pH** is the official short-form acronym for PHAROLON. Always written as `pH` — lowercase p, uppercase H — matching the chemistry notation for potential of Hydrogen.

This is intentional on four levels:
1. **pH = PHAROLON** — the platform acronym
2. **pH = potential of Hydrogen** — the universal chemistry notation fundamental to pharmaceutical manufacturing, biotech, food safety, and all regulated science
3. **pH wordmark** — the descending P in the wordmark (translateY 0.14em) directly references the lowercase p in pH notation. The descent was always semantic, not decorative.
4. **H stands tall** — the uppercase H is the fixed reference point, the lighthouse, the thing that doesn't move

> Never `PH`. Never `Ph`. Always `pH`.



---

### Typography

```
Wordmark:   Syne 800
UI/Nav:     Syne 700
Body:       DM Mono 400
References: DM Mono 500 (protocol IDs, record refs, metadata)
Display:    Cormorant Garamond 300 (editorial, pull quotes, hero text)
```

### Personality

- Ancient but precise — the weight of millennia, the accuracy of a calibrated instrument
- Serious but not sterile — pharmaceutical rigour without corporate grey
- Dense but not cluttered — 418 tables, rendered with clarity
- Mysterious but trustworthy — the lighthouse you navigate by, not admire from a distance

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
    () => (localStorage.getItem('pharolon-theme') as Theme) ?? 'system'
  );
  
  const resolved = useMediaQuery('(prefers-color-scheme: dark)')
    ? 'dark' : 'light';
  
  const active = preference === 'system' ? resolved : preference;
  
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', active);
    localStorage.setItem('pharolon-theme', preference);
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
│  [≡]  PHAROLON          [◆ MATC Madison ▼]     [⌘K Search...]  [🔔3][👤] │
└──────────────────────────────────────────────────────────────────────┘
```

- Always dark background (`--bg-header`)
- PHAROLON wordmark: white, Inter SemiBold
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
# pharolon-api.service      → Gunicorn
# pharolon-worker.service   → Celery
# pharolon-beat.service     → Celery Beat
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

Validation is project work. PHAROLON needs a project management layer.

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
PHAROLON Project    ↔  Jira Project
PHAROLON Protocol   ↔  Jira Epic
PHAROLON Test Step  ↔  Jira Task
PHAROLON Deviation  ↔  Jira Bug
PHAROLON CAPA Task  ↔  Jira Story
```
PHAROLON is GxP system of record. Jira reflects status.
Jira closure does not auto-close PHAROLON (requires e-signature).

### Integration: Zephyr Scale (EE)

```
PHAROLON Test Case Template  ↔  Zephyr Test Case
PHAROLON Protocol            ↔  Zephyr Test Cycle
PHAROLON Execution Results   ↔  Zephyr Execution
```
For orgs using Jira/Zephyr as central test repository.

### Integration: Veeva Vault (EE)

```
PHAROLON Deviation    → Vault Quality Event
PHAROLON CAPA         ↔  Vault CAPA (status sync)
PHAROLON Change Req   ↔  Vault Change Control
PHAROLON Document     → Vault Document (publish)
```

### Integration: ServiceNow (EE)

```
PHAROLON System       ↔  ServiceNow CMDB CI
PHAROLON Change Req   ↔  ServiceNow RFC
PHAROLON NCE          ↔  ServiceNow Incident
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
*UI-SPEC-001 v2.0.0 — Dark Teal. Modal-first. Light + Dark. PHAROLON's own identity.*

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


---

## 3. Modal System — Complete Specification

### Modal Types

**Type 1: Create Record Modal (560px)**
Used for creating any new record: protocol, CAPA, deviation, user, workspace.
- Header: icon + action title ("New Validation Protocol")
- Body: form fields with type-appropriate inputs
- Footer: Cancel (left) + Create [Record Type] (right, teal gradient)
- Tab key navigates between fields
- Enter submits when in last field

**Type 2: Destructive Confirmation Modal (400px)**
For void, delete, archive, retire actions.
- Header: dark red-tinted background to signal danger
- Body: warning box with icon + title "This action cannot be undone" + explanation
- Confirmation input: user must type the record reference to confirm
- Footer: Cancel + [Destructive Action] (red button, right)
- Escape ALWAYS cancels, never confirms

**Type 3: Electronic Signature Modal (560px)**
For all electronic signature actions (21 CFR Part 11).
- Header: teal accent header
- Body: signed record summary (read-only) + signature meaning (pre-selected) + password field + TOTP field + acknowledgment checkbox
- Footer: Cancel + Sign Record (teal gradient, disabled until checkbox checked)
- Failed auth increments counter, locks after 5 attempts

**Type 4: Success State Modal (400px)**
Replaces toast for significant actions (signing, approvals, major saves).
- Header: green-tinted background, green checkmark icon
- Body: success icon + title + what was done + list of automated actions triggered
- Footer: Close + View Record (primary action)
- Auto-dismiss available but optional (default: user dismisses)

**Type 5: Detail Preview Panel (50% screen width, right slide-in)**
Opened by single-clicking any table row. Not a full modal — slides in from right.
- Header: record ref + type + close button
- Body: key fields in a clean two-column layout
- Footer: quick action buttons (Open Full Record, Approve, Execute)
- Does not block the table (can still scroll/interact with table)
- Double-click or "Open" button navigates to full record page

**Type 6: Large Form Modal (720px)**
For complex forms: edit system details, configure workflow, build template.
- Two-column layout for dense forms
- Scrollable body (header and footer sticky)
- Section headers within modal body
- "Save Draft" secondary action alongside primary "Save"

### Modal Rules (hard standards)

```
✓ USE MODAL FOR              ✗ NEVER TOAST FOR
─────────────────────        ───────────────────
Create any record             Record saved/created → use success modal
Delete / void / retire        Validation errors → inline field errors
Electronic signature          Warning about action → confirmation modal
Bulk action confirmation      Any action needing user decision
Approve / reject             
Upload a file                TOAST IS ONLY FOR
Configure a module            Background task complete
View record details           Nightly audit verification result
Any irreversible action       License expiry (once/session)
                              Network reconnection
```

---

## 4. Navigation Architecture

### Top Navigation Dropdowns

The charcoal header contains a top navigation bar with 4 dropdown menus for quick access:

**Validation ▾**
- Validation Projects (all active work)
- Protocols (IQ/OQ/PQ/UAT/MAV)
- Test Executions (running and completed)
- ─────
- Validation Wizard (build a project in 15 min)
- Test Case Library (EE)
- Traceability Matrix

**Quality ▾**
- CAPA
- Change Control
- Deviations
- OOS / OOT (EE)
- Complaints (EE)
- Periodic Reviews
- Audit Management

**Documents ▾**
- Document Library
- Templates
- Pending Approvals (with count badge)
- Drawing Management (EE)
- Validation Packages

**Reports ▾**
- Standard Reports
- Dashboards
- Inspection Readiness (EE)
- Validation Debt (EE)
- Custom Reports (EE)

**+ Create ▾** (always visible, right side of header)
Dropdown of quick-create options for any record type.
Keyboard shortcut: `N` (new) when not in a text field.

### Breadcrumb Bar

Below the header, a persistent breadcrumb shows exact location:
```
MATC Madison / IT Validation / SAP Suite / SAP ERP 2026 / OQ-0043 · Execution
```
Every segment is clickable. Clicking navigates to that level.

---

## 5. Folder/Tree Architecture for Validation Plans

### Hierarchy

```
🏢 Site
└── 📁 Workspace (data isolation scope, team assignment)
    └── 📂 Portfolio (compliance score aggregation)
        └── 🗂 Validation Project (one system's full lifecycle)
            ├── 📋 Validation Plan
            ├── ⚠  Risk Assessment
            ├── 📝 URS / FS / DS / CS
            ├── 🧪 IQ Protocol
            │   ├── Protocol Document (authored)
            │   └── Execution Record(s)
            ├── 🧪 OQ Protocol
            │   ├── Protocol Document
            │   └── Execution Records
            ├── 🧪 PQ Protocol
            ├── 🔗 Traceability Matrix (auto-generated)
            └── 📊 Validation Summary Report
```

### Tree Behavior

- **Expand/collapse**: click triangle toggle
- **Status badges**: every item shows its current lifecycle status
- **Selection**: click item → loads in main content area
- **Right-click context menu**: open, create child, rename, move, export, archive
- **Drag to reorder**: within same parent only
- **Search within tree**: filter nodes by name or reference
- **Persistent state**: expanded/collapsed state saved to user preference
- **Document + Execution together**: protocol node shows both the authored document and execution records as sub-items

### Status Visual Language in Tree

- ✓ Green badge = Passed/Approved/Effective
- ◉ Blue badge = In Review/In Progress
- ⚠ Gold badge = In Progress / Pending Action
- — Gray badge = Not Started
- ✗ Red badge = Failed/Rejected

---

## 2.4 Color Refinements — v2.4 (Final)

### Removing Harsh Cyan as Text Color

`#5EEADF` (--teal-300) was being overused as text color. It is too high-contrast
(cyan against dark = eye strain on extended use). Replace all teal-300 text with:

| Was | Now | Why |
|---|---|---|
| Active nav label (#5EEADF) | White #fff | Clean, legible, professional |
| Record reference in table (#5EEADF) | Off-white monospace #B2CCD6 | Softer, still distinct |
| "Approved" badge text | Teal-400 #00D4C4 | Still teal, 30% less aggressive |
| Success checkmarks | Lime #86C140 | Semantically correct (pass = green) |
| Active state indicators | Gold #E2A837 | Warmer, more premium |

Keep teal-300 ONLY for: left border on active nav item, focus ring glow, teal callout border.

### Lighter Input Fields in Dark Mode

Old: `background: #1E2837` (almost invisible against dark cards)
New: `background: #243040` (slate-blue — clearly a fillable field)
New border: `#2E4055` (visible against field background)
Focus border: `rgba(0,160,144, 0.6)` (teal-600 with slight transparency)
Text: `#E8EDF2` (warm off-white, not pure white, not harsh)

### Callout Box Color Personality (7 Types)

All callouts have: tinted background + matching left border (3px) + matching text.

| Type | Background | Left Border | Text Color | Usage |
|---|---|---|---|---|
| Teal/Info | rgba(0,160,144,.10) | #00A090 | #00D4C4 | Regulatory note, reference |
| Blue | rgba(59,130,246,.10) | #3B82F6 | #93C5FD | In-progress, scheduled |
| Gold | rgba(226,168,55,.10) | #E2A837 | #F0C040 | Action required, due soon |
| Orange | rgba(249,115,22,.10) | #F97316 | #FDBA74 | Deviation, flag, warning |
| Red/Coral | rgba(229,75,46,.10) | #E54B2E | #FCA5A5 | Blocking error, critical |
| Green/Pass | rgba(134,193,64,.08) | #86C140 | #BEF264 | All criteria met, complete |
| Purple | rgba(139,92,246,.10) | #8B5CF6 | #C4B5FD | AI suggestion, EE feature |

Light theme versions: same borders but light tinted backgrounds (e.g., #EFF6FF for blue).

### Modal Header Variants by Action Type

| Modal Type | Header Treatment |
|---|---|
| Standard / Create | Charcoal #141414 |
| Signature (approved) | Teal gradient overlay on charcoal |
| Success | Lime-green gradient overlay |
| Destructive | Dark red tint (#1A0808) |
| Warning / Flag | Orange tint overlay |
| AI-assisted | Purple tint overlay |
| Gold / Priority | Gold tint overlay |

