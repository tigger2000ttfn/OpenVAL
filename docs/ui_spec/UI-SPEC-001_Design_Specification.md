# OpenVAL UI/UX Design Specification

**Document Reference:** UI-SPEC-001
**Version:** 1.0
**Status:** Approved for Development
**Applies To:** All phases of frontend development

---

## 1. Design Philosophy

OpenVAL users are validation engineers, QA managers, and system owners. They are professionals who need efficiency, not novelty. Every design decision prioritizes:

- **Clarity over cleverness.** Labels, buttons, and status indicators must be unambiguous. A validation engineer executing a protocol at 11pm during a go-live must not misread a UI element.
- **Consistency over creativity.** Every page follows the same shell. Status badges look the same everywhere. Table interactions work the same everywhere. Users learn the system once.
- **Density with breathing room.** Pharmaceutical validation involves a lot of fields and a lot of records. The UI must show enough information without feeling cluttered.
- **Audit everywhere.** Every significant action shows who did it and when. The UI reinforces the same culture the regulation requires.

---

## 2. Design Tokens

These tokens are defined in `frontend/src/styles/tokens.css` and Tailwind config. No hex codes appear in component code directly.

### Colors

```css
/* Primary Brand */
--color-primary:        #1B4F8A;   /* Deep regulatory blue */
--color-primary-light:  #2D6BB5;
--color-primary-dark:   #0F3060;
--color-primary-50:     #EBF2FC;   /* Very light blue for hover backgrounds */

/* Status / Semantic */
--color-success:        #00875A;   /* Pass, approved, effective */
--color-success-light:  #E3FCEF;
--color-warning:        #FF8B00;   /* Review, pending, caution */
--color-warning-light:  #FFFAE6;
--color-danger:         #DE350B;   /* Fail, rejected, critical */
--color-danger-light:   #FFEBE6;
--color-info:           #0065FF;   /* Informational */
--color-info-light:     #DEEBFF;

/* Neutrals */
--color-neutral-900:    #172B4D;   /* Primary text */
--color-neutral-700:    #344563;   /* Secondary text */
--color-neutral-500:    #5E6C84;   /* Tertiary text, placeholders */
--color-neutral-300:    #B3BAC5;   /* Disabled text */
--color-neutral-200:    #DFE1E6;   /* Borders, dividers */
--color-neutral-100:    #F4F5F7;   /* Page background, sidebar bg */
--color-neutral-50:     #FAFBFC;   /* Subtle backgrounds */
--color-white:          #FFFFFF;   /* Card background, content areas */

/* Risk Level Colors (used in risk matrix, badges) */
--color-risk-critical:  #6B2D0F;
--color-risk-high:      #DE350B;
--color-risk-medium:    #FF8B00;
--color-risk-low:       #00875A;
```

### Typography

```css
--font-family:          'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
--font-mono:            'JetBrains Mono', 'Fira Code', monospace;

/* Scale */
--text-xs:    12px / 1.4;
--text-sm:    13px / 1.4;
--text-base:  14px / 1.5;
--text-md:    15px / 1.5;
--text-lg:    18px / 1.4;
--text-xl:    22px / 1.3;
--text-2xl:   28px / 1.2;

/* Weights */
--font-regular:  400;
--font-medium:   500;
--font-semibold: 600;
--font-bold:     700;
```

### Spacing

Base unit: 4px
```
space-1:  4px
space-2:  8px
space-3:  12px
space-4:  16px
space-5:  20px
space-6:  24px
space-8:  32px
space-10: 40px
space-12: 48px
space-16: 64px
```

### Border Radius
```
radius-sm:  4px    (inputs, small elements)
radius-md:  6px    (cards, panels)
radius-lg:  8px    (modals, large cards)
radius-xl:  12px   (full-page cards)
radius-full: 9999px (badges, pills, avatars)
```

### Shadows
```
shadow-sm:  0 1px 2px rgba(23,43,77,0.08)
shadow-md:  0 2px 8px rgba(23,43,77,0.12)
shadow-lg:  0 8px 24px rgba(23,43,77,0.16)
shadow-xl:  0 16px 48px rgba(23,43,77,0.20)
```

---

## 3. Application Shell

Every authenticated page renders inside the AppShell component. There are no exceptions.

### Shell Dimensions

```
Header height:          64px (fixed)
Sidebar width (open):   240px (fixed)
Sidebar width (closed): 56px (icon-only mode)
Breadcrumb bar height:  36px
Content area:           height: calc(100vh - 64px - 36px), overflow-y: auto
```

### Header Specification

**Left:**
- OpenVAL logo (SVG, 28px height) + wordmark "OpenVAL" in --font-semibold, --color-primary
- Site selector dropdown (if user has access to multiple sites)

**Center:**
- Global search bar (480px wide)
  - Placeholder: "Search systems, protocols, documents..."
  - Keyboard shortcut: Cmd/Ctrl + K
  - Opens search results panel below header

**Right (left to right):**
1. Notification bell icon with unread count badge (red dot if > 0)
2. Help icon (links to documentation)
3. User avatar (initials fallback) + name + caret for dropdown menu

**User dropdown menu:**
- My Profile
- My Tasks (count badge)
- Preferences
- divider
- Sign Out

### Sidebar Specification

The sidebar has two modes: expanded (240px) and collapsed (56px, icon only). State persists in user preferences.

**Header within sidebar:**
- Collapsed toggle button (chevron icon)
- In expanded mode: "NAVIGATION" label in --text-xs, --color-neutral-500, uppercase, letter-spacing

**Navigation Groups:**

Each group has a section header (uppercase, small, --color-neutral-500) and list items.

```
VALIDATION
  [icon] System Inventory
  [icon] Risk Assessments
  [icon] Requirements
  [icon] Protocols
  [icon] Test Executions
  [icon] Traceability Matrix

QUALITY
  [icon] Change Control
  [icon] CAPA
  [icon] Nonconformances
  [icon] Deviations
  [icon] Periodic Reviews

DOCUMENTS
  [icon] Document Library
  [icon] Templates
  [icon] Pending Approvals   [count badge]

WORKFLOWS
  [icon] My Tasks            [count badge]
  [icon] Workflow Builder
  [icon] Active Workflows

OPERATIONS
  [icon] Equipment
  [icon] Vendors
  [icon] Training Records
  [icon] Audit Management

REPORTS
  [icon] Report Builder
  [icon] Dashboards
  [icon] Scheduled Reports

ADMINISTRATION
  [icon] User Management
  [icon] Roles & Permissions
  [icon] Site Settings
  [icon] Lookup Tables
  [icon] Email Templates
  [icon] Integrations
  [icon] Audit Log Viewer
  [icon] System Health
```

**Active state:** Left border 3px --color-primary, background --color-primary-50, text --color-primary, icon --color-primary.

**Hover state:** Background --color-neutral-100.

**Collapsed mode:** Shows only icons with tooltips on hover.

### Breadcrumb Bar

Full-width bar below header, height 36px, background --color-white, border-bottom 1px --color-neutral-200.

Content: `Home > Module > Sub-section > Record Title`

Separator: `/` in --color-neutral-300
All items except last are links in --color-primary.
Last item (current page) is plain text in --color-neutral-700.

### Content Area

Background: --color-neutral-100
Padding: 24px on all sides
Max-width: 1440px centered (for very large screens)

---

## 4. Universal Component Library

### 4.1 PageHeader

Used at the top of every content page.

```
+-------------------------------------------------------------------+
| [Optional back arrow]                                             |
| Page Title                                [Action Button(s)]     |
| Subtitle / record ref / status badge                             |
+-------------------------------------------------------------------+
```

- Title: --text-2xl, --font-bold, --color-neutral-900
- Subtitle / ref: --text-sm, --color-neutral-500
- Status badge placed inline after title or subtitle
- Action buttons: right-aligned, maximum 3 buttons (Primary, Secondary, More dropdown for additional)

### 4.2 StatusBadge

Pill-shaped badge with icon prefix. Used universally for status display.

```tsx
<StatusBadge status="approved" />
<StatusBadge status="in_review" />
<StatusBadge status="failed" size="sm" />
```

| Status Value | Label | Background | Text | Icon |
|---|---|---|---|---|
| `draft` | Draft | neutral-100 | neutral-700 | pencil |
| `in_review` | In Review | info-light | info | clock |
| `approved` | Approved | success-light | success | check-circle |
| `effective` | Effective | success-light | success | check-circle |
| `rejected` | Rejected | danger-light | danger | x-circle |
| `executed` | Executed | success-light | success | check |
| `passed` | Passed | success-light | success | check |
| `failed` | Failed | danger-light | danger | x |
| `deviation` | Deviation | warning-light | warning | alert-triangle |
| `voided` | Voided | neutral-100 | neutral-500 | ban |
| `superseded` | Superseded | neutral-100 | neutral-500 | archive |
| `overdue` | Overdue | danger-light | danger | clock-x |
| `not_started` | Not Started | neutral-100 | neutral-500 | circle |
| `in_progress` | In Progress | info-light | info | loader |
| `completed` | Completed | success-light | success | check-circle |
| `cancelled` | Cancelled | neutral-100 | neutral-500 | x |
| `open` | Open | warning-light | warning | circle-dot |
| `closed` | Closed | neutral-100 | neutral-500 | check-circle |
| `critical` | Critical | danger | white | alert-octagon |
| `high` | High | danger-light | danger | alert-triangle |
| `medium` | Medium | warning-light | warning | alert-triangle |
| `low` | Low | success-light | success | info |

Sizes: `sm` (12px text, 4px/8px padding), `md` (13px, 6px/10px - default), `lg` (14px, 8px/12px)

### 4.3 DataTable

The core list view component. Used on every module list page.

**Features:**
- Column sorting (click header, toggle asc/desc, shows sort indicator)
- Pagination (bottom bar: items per page dropdown, page navigator, total count)
- Column visibility toggle (gear icon top-right opens column picker)
- Row selection (checkboxes for bulk actions when bulk actions configured)
- Row click opens record (navigates to detail page or opens DetailPanel)
- Inline action menu per row (three-dot icon, right-aligned)
- Empty state (illustrated, with primary action button)
- Loading skeleton (animated placeholder rows while fetching)
- Sticky header (scrolls content, not header)
- Column resizing (drag column borders)
- Filter bar integration (sits above table)
- Export button (CSV, Excel - top-right of table header)

**Pagination:**
```
[←] [1] [2] [3] ... [12] [→]     Showing 26-50 of 247 records     [25 per page ▾]
```

**Empty State:**
```
     [Illustrated empty state SVG - unique per module]
     
     No systems found
     
     Add your first computerized system to begin tracking
     validation status and compliance.
     
              [+ Add System]
```

### 4.4 FilterBar

Sits above DataTable on list pages.

```
[🔍 Search...                    ] [Status ▾] [GAMP Category ▾] [Owner ▾] [+ More Filters] [Clear]
```

- Search field: 320px, searches across key text fields server-side
- Each filter is a dropdown with checkboxes for multi-select
- Active filter count shown in button label: `Status (2)`
- "Clear" removes all filters and resets search
- Saved filter presets: "Save as..." button, loads named filter sets
- Filter state persists in URL params for shareable filtered views

### 4.5 DetailPanel

A 480px panel that slides in from the right side of the screen when a record is clicked in a list view (without navigating away). Used for quick-view before opening the full detail page.

```
+------------------------------------------+
| [←] SYS-0042                    [Open ↗] |
|------------------------------------------|
| LabWare LIMS 7.0                         |
| GAMP 5 Category 4 | GxP: Yes             |
|                                          |
| [Validated] [Active]                     |
|                                          |
| Owner: M. Escamilla                      |
| QA Owner: R. Pandey                      |
| Next Review: 2026-10-15  ⚠️ 90 days     |
|                                          |
| ── Recent Activity ─────────────────     |
| CR-0024 approved   2d ago                |
| OQ executed        14d ago               |
| IQ approved        45d ago               |
|                                          |
| [View Full Record] [New Protocol]        |
+------------------------------------------+
```

### 4.6 SignatureCapture Modal

Used for every electronic signature action. Blocks interaction with background.

```
+------------------------------------------------------+
| Electronic Signature Required               [×]      |
|------------------------------------------------------|
| You are about to sign:                               |
|                                                      |
| IQ-LIMS-001 v1.0 - LabWare LIMS Installation         |
| Qualification Protocol                               |
|                                                      |
| Signing as:   Michael Escamilla                      |
| Meaning:      I approve this record for its          |
|               intended use (21 CFR 11.50(a))         |
|                                                      |
|  Password  [________________________]                |
|  MFA Token [________________________]                |
|                                                      |
| ☐ I understand the meaning of this electronic        |
|   signature and the regulatory implications of       |
|   signing this record.                               |
|                                                      |
| [Cancel]                       [Sign Record]         |
+------------------------------------------------------+
```

**States:**
- Default: fields empty, Sign button disabled
- Typing: Sign button enabled when password + confirmation checked
- Loading: spinner on Sign button, fields disabled, "Verifying..." text
- Error: red inline error "Incorrect password" or "Invalid MFA token", field highlighted
- Success: modal closes, success toast appears, page updates

**MFA field:** Only shown if MFA is enabled for the user, or if the signature meaning has `requires_mfa = true`.

### 4.7 RichTextEditor (TipTap)

Used for all narrative fields throughout the system.

**Toolbar (top of editor):**
```
[H1] [H2] [H3] | [B] [I] [U] [S] | [≡] [1.] | [Link] [Table] [Image] | [Undo] [Redo]
```

- H1, H2, H3: Heading levels
- B, I, U, S: Bold, Italic, Underline, Strikethrough
- ≡, 1.: Bullet list, Numbered list
- Link: Insert hyperlink dialog
- Table: Insert table (rows/cols picker)
- Image: Attach image from file store

**Read-only mode:** Renders formatted content, no toolbar.

**Compact mode (protocol step descriptions):** Single toolbar row, no heading levels.

**Word count:** Shown bottom-right of editor: "234 words"

### 4.8 FileUpload

```
+-------------------------------------------+
|                                           |
|   Drag and drop files here, or            |
|   [Browse Files]                          |
|                                           |
|   Supported: PDF, DOC, DOCX, XLS, XLSX,  |
|   PNG, JPG, TXT, CSV (max 50 MB each)    |
+-------------------------------------------+
| evidence_report.pdf         2.4 MB  [×]  |
| screenshot_step_12.png      340 KB  [×]  |
+-------------------------------------------+
```

- Files show in list below drop zone after selection
- Progress bar per file during upload
- SHA-256 hash verified on server, error shown if mismatch
- Virus scan status indicator (spinner -> checkmark or warning)

### 4.9 TimelineView (Audit Trail Display)

Vertical timeline used for audit trail and workflow history.

```
◉ Approved                                    Michael Escamilla
  Status changed from In Review to Approved   Today at 14:23
  Signature: ESIG-0042 (I approve this record...)

◉ Reviewed                                    Ruchi Pandey
  Document submitted for review               Yesterday at 09:15

◉ Updated                                     Michael Escamilla
  Field 'scope' modified                      2 days ago
  Old: "covers production LIMS"
  New: "covers production and staging LIMS"

◉ Created                                     Michael Escamilla
  Record created                              5 days ago
```

Events are sorted newest-first. Each entry shows: action icon, action type, user, timestamp, details (expandable if long). Signature entries link to the electronic_signatures record.

### 4.10 CommentThread

Inline comment system attached to any record.

```
Comments (3)

[Avatar] Michael Escamilla  ·  2 days ago
         This step needs clarification on the expected PostgreSQL
         version number. Updated accordingly.
         [Reply] [Edit] [Delete]

  [Avatar] Ruchi Pandey  ·  Yesterday
           Confirmed, the version in step 3.1 is now correct.
           [Reply]

[Avatar] Sahar Bonollo  ·  Today at 09:00
         QA has reviewed. No further comments.
         [Reply]

[Add a comment...                                          ]
                                             [Post Comment]
```

### 4.11 ProgressTracker

Used in protocol execution and workflow progress display.

**Protocol Execution:**
```
IQ-LIMS-001 Execution Progress

Section 1: Pre-Installation    ████████████  6/6  ✓
Section 2: Installation        ████████░░░░  4/6  ●  ← current
Section 3: Verification        ░░░░░░░░░░░░  0/8
Section 4: Documentation       ░░░░░░░░░░░░  0/4
                               
Overall: 10/24 steps  (42%)   [1 deviation]
```

**Workflow:**
```
● Authored → ● Reviewed → ○ Approved → ○ QA Approved
                ↑ In progress
              Due: 2026-04-09  (3 days remaining)
```

### 4.12 VersionSelector

Dropdown allowing navigation between versions of a record.

```
Version  [v1.2 (Current - Effective) ▾]
          v1.1 (Superseded - 2025-11-01)
          v1.0 (Superseded - 2025-06-15)
```

Selecting a previous version shows a banner: "You are viewing Version 1.1 (Superseded). [View Current Version]"

---

## 5. Module-Level UI Specifications

### 5.1 System Inventory

**List Page Layout:**
```
Systems                                          [+ Add System] [⬆ Import]

[🔍 Search systems...] [Status ▾] [GAMP Cat ▾] [Validated ▾] [Owner ▾] [Clear]

┌────────────┬──────────────────────────┬──────┬──────┬───────────┬────────────┬──────────────┐
│ Ref        │ Name                     │ GAMP │ GxP  │ Validated │ Owner      │ Next Review  │
├────────────┼──────────────────────────┼──────┼──────┼───────────┼────────────┼──────────────┤
│ SYS-0042   │ LabWare LIMS 7.0         │ Cat4 │ ●Yes │ Validated │ Escamilla  │ ⚠️ Oct 2026  │
│ SYS-0041   │ FCS Express 7 Server     │ Cat4 │ ●Yes │ In Qual.  │ Pandey     │ Jan 2027     │
│ SYS-0038   │ CCure 9000               │ Cat4 │ ●Yes │ Validated │ Escamilla  │ Mar 2027     │
│ SYS-0031   │ Windows Server 2022      │ Cat1 │ ○No  │ N/A       │ Escamilla  │ —            │
└────────────┴──────────────────────────┴──────┴──────┴───────────┴────────────┴──────────────┘

Showing 1-25 of 38 records   [25 per page ▾]   [← 1 2 →]
```

**System Detail Page - Tab Layout:**
```
SYS-0042 · LabWare LIMS 7.0
[Validated] [Active]                          [+ New Protocol] [Edit] [···]

[Overview] [Components] [Interfaces] [Environments] [Documents] [Protocols] [Changes] [Reviews] [Audit]

── Overview ──────────────────────────────────────────────────────────────────────

CLASSIFICATION                          VALIDATION STATUS
GAMP Category:  Category 4             Validated Status:   Validated
GxP Relevant:   Yes                    Validation Basis:   IQ/OQ/PQ
Applicable Regs: 21 CFR Part 11        Go-Live Date:       2025-10-15
                 21 CFR Part 211        Revalidation Due:   —

OWNERSHIP                               NEXT PERIODIC REVIEW
Business Owner: J. Rodriguez            Due Date:   2026-10-15  ⚠️ 90 days
Technical Owner: M. Escamilla           Reviewer:   M. Escamilla
QA Owner:        R. Pandey

VENDOR
Vendor:          LabWare Inc.
Product:         LabWare LIMS
Version:         7.0.3 Build 2241
License Expires: 2027-06-30

HOSTING
Type:            On-Premise
Environment:     Production
Location:        MATC Server Room / ESX-04

DESCRIPTION
[Rich text display of system description]
```

### 5.2 Protocol Execution Engine

The execution engine is the most complex UI in the system. It gets its own full-screen layout.

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│ [← Exit] IQ-LIMS-001 v1.0 - LabWare LIMS IQ          Executed by: M.Escamilla │
│ Progress: ████████░░░░░░░░░░  10/24 steps  42%         [Pause] [Complete Report]│
├─────────────────┬───────────────────────────────────────────────────────────────┤
│ SECTIONS        │ STEP 2.4 of Section 2: Installation Verification              │
│                 │                                                               │
│ ✓ 1. Pre-Install│ Verify PostgreSQL Service Status                              │
│ ● 2. Install    │                                                               │
│   ✓ 2.1        │ DESCRIPTION                                                   │
│   ✓ 2.2        │ Navigate to the server console and verify that the             │
│   ✓ 2.3        │ PostgreSQL 15 service is running and enabled.                  │
│ → 2.4 [current] │                                                               │
│   2.5          │ EXPECTED RESULT                                                │
│   2.6          │ The PostgreSQL service status shows "active (running)".        │
│ ○ 3. Verify     │ The service is enabled (starts on boot).                      │
│ ○ 4. Document   │                                                               │
│                 │ REGULATORY CITATION                                           │
│                 │ 21 CFR 11.10(a) - System Validation                           │
│                 │ Linked Requirements: URS-001, URS-042                         │
│                 │                                                               │
│                 │ ACTUAL RESULT                                                 │
│                 │ ┌─────────────────────────────────────────────────────────┐  │
│                 │ │                                                         │  │
│                 │ │ [Actual result text area - required]                    │  │
│                 │ │                                                         │  │
│                 │ └─────────────────────────────────────────────────────────┘  │
│                 │                                                               │
│                 │ [📎 Attach Screenshot]  [📁 Attach File]                     │
│                 │                                                               │
│                 │ Step started: 14:23:05        [⚠️ Raise Deviation]           │
│                 │                                                               │
│                 │ [    FAIL    ]  [N/A]  [         PASS         ]              │
├─────────────────┴───────────────────────────────────────────────────────────────┤
│ Comments for this step:  [Add a comment...]                                     │
└─────────────────────────────────────────────────────────────────────────────────┘
```

**Pass / Fail button behavior:**
- PASS: Large green button, right side. On click: marks step passed, records timestamp, advances to next step
- FAIL: Red button, left side. On click: opens "Confirm Failure" dialog, then raises deviation automatically
- N/A: Secondary button, middle. On click: marks step not applicable with required reason

**If step requires signature:** After PASS is clicked, SignatureCapture modal opens before the step is recorded as passed.

**Deviation capture (inline):**
```
┌─────────────────────────────────────────────────────┐
│ Raise Deviation for Step 2.4               [×]      │
│                                                      │
│ Title *         [________________________________]  │
│ Type *          [Unexpected Result            ▾]   │
│ Severity *      ○ Minor  ● Major  ○ Critical         │
│                                                      │
│ Description *                                        │
│ ┌─────────────────────────────────────────────┐     │
│ │ [What was observed vs what was expected?]   │     │
│ └─────────────────────────────────────────────┘     │
│                                                      │
│ Immediate Action Taken                               │
│ ┌─────────────────────────────────────────────┐     │
│ │                                             │     │
│ └─────────────────────────────────────────────┘     │
│                                                      │
│ Impact on Validation                                 │
│ ○ Non-invalidating   ○ Requires evaluation           │
│ ○ Invalidating                                       │
│                                                      │
│ [Cancel]                  [Raise Deviation]          │
└─────────────────────────────────────────────────────┘
```

### 5.3 Document Editor

Full-screen document editing mode.

```
┌──────────────────────────────────────────────────────────────────────┐
│ [← Back] SOP-MATC-0042 · Computer System Validation Procedure  [···] │
│ Version 1.2 (Draft)  ·  Last saved 2 minutes ago            [Submit] │
├──────────────────────────────────────────────────────────────────────┤
│ [H1][H2][H3] | [B][I][U] | [≡][1.] | [Link][Table][Image] | [↩][↪] │
├─────────────────────────────────────┬────────────────────────────────┤
│ SECTIONS                            │                                │
│                                     │  [HEADER - renders site logo   │
│ 1. Purpose              [+]         │   and document metadata]       │
│ 2. Scope                [+]         │                                │
│ 3. Responsibilities     [+]         │ ══════════════════════════════ │
│ 4. Procedure          ← active      │ 4. Procedure                  │
│   4.1 System Classification         │                                │
│   4.2 Risk Assessment               │ 4.1 System Classification      │
│   4.3 Validation Planning           │                                │
│   4.4 Protocol Development          │ [Rich text content here. Full  │
│   4.5 Protocol Execution            │  width, comfortable reading    │
│   4.6 Validation Report             │  width, 720px max for text.    │
│ 5. References           [+]         │  Page-like appearance with     │
│ 6. Revision History                 │  white background, shadow.]    │
│                                     │                                │
│ [+ Add Section]                     │                                │
│                                     │  [FOOTER - page number,        │
│ DOCUMENT INFO                       │   doc ref, version, status]    │
│ Doc Ref: SOP-MATC-0042              │                                │
│ Version: 1.2 (Draft)                │                                │
│ Owner: M. Escamilla                 │                                │
│ Category: Validation SOPs           │                                │
│ Review Due: 2027-04-06              │                                │
└─────────────────────────────────────┴────────────────────────────────┘
```

### 5.4 Workflow Builder

Visual drag-and-drop workflow definition.

```
Workflow: Document Approval - GxP Documents
Trigger: Document version status changes to "Submitted for Review"
                                            [Test Workflow] [Save] [Activate]

Canvas:
                                                          
  [Start]  ──────►  [Technical Review]  ──────►  [QA Review]  ──────►  [End: Approved]
                         │                            │
                    (Rejected)                   (Rejected)
                         │                            │
                         ▼                            ▼
                    [Return to Author] ◄──────────────┘
                    
                    
[+ Add Stage]  [+ Add Condition]  [Save Draft]


SELECTED STAGE: QA Review
────────────────────────────
Stage Name:     QA Review
Stage Type:     Approval
Assignee:       Role ▾  [QA Manager              ▾]
SLA:            [3] days
Escalate After: [5] days to [QA Director          ▾]
Signature:      Required ☑
Sig Meaning:    [QA Approved (21 CFR 11.50(a))    ▾]
Instructions:   [Review technical review comments
                 and confirm GxP compliance...]
Rejection:      Goes back to stage [Technical Review ▾]
Optional:       ☐
────────────────────────────
[Delete Stage]
```

### 5.5 Risk Assessment

```
RA-0007 - LabWare LIMS 7.0 System Risk Assessment
[Approved]                                  [New Version] [Export PDF]

[Overview] [Risk Items] [Heat Map] [Audit]

── Risk Items ──────────────────────────────────────────────────────

[+ Add Risk Item]  [Import from CSV]          Filter: [All Items ▾]

┌─────┬────────────────┬──────────────┬─────┬─────┬────────────────┬─────┐
│  #  │ Hazard         │ Effect       │  P  │  I  │ Inherent Risk  │ RPN │
├─────┼────────────────┼──────────────┼─────┼─────┼────────────────┼─────┤
│ 001 │ Audit trail    │ Data         │  2  │  5  │ 🔴 High (10)   │  —  │
│     │ disabled by    │ integrity    │     │     │ Residual: 🟡    │     │
│     │ unauthorized   │ loss         │     │     │ Medium (4)     │     │
│     │ user           │              │     │     │                │     │
├─────┼────────────────┼──────────────┼─────┼─────┼────────────────┼─────┤
│ 002 │ Backup failure │ Loss of GxP  │  2  │  4  │ 🟡 Medium (8)  │  —  │
│     │                │ records      │     │     │ Residual: 🟢    │     │
│     │                │              │     │     │ Low (2)        │     │
└─────┴────────────────┴──────────────┴─────┴─────┴────────────────┴─────┘

── Heat Map ─────────────────────────────────────────────────────────

        IMPACT →
        1        2        3        4        5
P  5  [       ][       ][       ][  🔴   ][  🔴   ]
R  4  [       ][       ][  🟡   ][  🟡   ][  🔴   ]
O  3  [       ][  🟢   ][  🟡   ][  🟡   ][  🔴   ]
B  2  [  🟢   ][  🟢   ][  🟢   ][  🟡  ●][  🟡  ●]
↑  1  [  🟢   ][  🟢   ][  🟢   ][  🟢   ][  🟡   ]

● = residual risk position after mitigation
```

### 5.6 Dashboard

```
OpenVAL                                         Good morning, Michael

┌─────────────────────────────────────────────────────────────────────┐
│ MY TASKS                                          3 pending tasks    │
│ ───────────────────────────────────────────────────────────────────  │
│ ⏰ Approve IQ-LIMS-001 v1.0         Due today        [Review]        │
│ 📋 Review SOP-MATC-0042 v1.2        Due Apr 10       [Review]        │
│ ✅ Complete CAPA-0011 action #2     Due Apr 12       [View]          │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│  Systems     │  │  Open CAPAs  │  │  Protocols   │  │ Reviews Due  │
│     38       │  │     7        │  │  In Progress │  │  Next 30d    │
│              │  │              │  │     3        │  │     5        │
│ 29 Validated │  │ 2 Overdue 🔴 │  │              │  │ 1 Overdue 🔴 │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘

┌────────────────────────────────┐  ┌────────────────────────────────┐
│ VALIDATION STATUS              │  │ RECENT ACTIVITY                │
│                                │  │                                │
│  [Donut chart]                 │  │ IQ-LIMS-001 Approved           │
│                                │  │ M. Escamilla · 2 hours ago     │
│  29 Validated     (76%)        │  │                                │
│   4 In Qual.      (11%)        │  │ CAPA-0011 action completed     │
│   3 Not Validated  (8%)        │  │ R. Pandey · Yesterday          │
│   2 Revalidation   (5%)        │  │                                │
│     Required                   │  │ SOP-MATC-0039 Effective        │
│                                │  │ S. Bonollo · 2 days ago        │
└────────────────────────────────┘  └────────────────────────────────┘
```

---

## 6. Interaction Patterns

### 6.1 Confirmation Dialogs

Used for destructive or irreversible actions.

```
Delete System: LabWare LIMS 7.0?

This action cannot be undone. The system record SYS-0042 and all
associated data will be permanently deleted.

Confirm by typing the system reference number: [              ]

[Cancel]                                        [Delete System]
```

For deletion of records with children (protocols, documents): Show a warning list of what will also be deleted.

### 6.2 Toast Notifications

Non-blocking feedback messages. Appear top-right, auto-dismiss after 5 seconds.

```
✓  Protocol IQ-LIMS-001 approved successfully.
   Workflow has been initiated for QA review.                     [×]

✕  Failed to save. Please check your connection and try again.   [×]

⚠  Audit chain verification failed. Contact your administrator.  [×]
```

Types: success (green), error (red), warning (amber), info (blue)

### 6.3 Loading States

Every data fetch shows a loading skeleton matching the shape of the loaded content. No spinners on empty white backgrounds.

```
// Table loading skeleton
┌─────────────┬──────────────────────────────┬────────┬──────────┐
│ ▓▓▓▓▓▓▓▓    │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓         │ ▓▓▓▓   │ ▓▓▓▓▓▓▓  │
├─────────────┼──────────────────────────────┼────────┼──────────┤
│ ▓▓▓▓▓▓▓▓    │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓             │ ▓▓▓▓   │ ▓▓▓▓▓▓▓  │
│ ▓▓▓▓▓▓▓▓    │ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │ ▓▓▓▓   │ ▓▓▓▓▓▓▓  │
└─────────────┴──────────────────────────────┴────────┴──────────┘
```

Skeleton blocks animate with a shimmer effect (left-to-right gradient sweep).

### 6.4 Form Validation

All forms validate using React Hook Form + Zod.

- Fields validate on blur (not on every keystroke) to avoid aggressive error messages
- Required field indicator: red asterisk after label
- Error messages appear below the field in red, --text-sm
- On submit: any invalid fields scroll into view and are highlighted
- Success: form resets or navigates away with success toast

```
Title *
[LabWare LIMS OQ Protocol                  ]
 
Scope *
[                                           ]
⚠  Scope is required.
```

---

## 7. Accessibility Requirements

- All interactive elements must have accessible labels (aria-label or visible text)
- Color is never the sole indicator of state (icons and text accompany color)
- Keyboard navigation fully supported across all components
- Tab order follows visual reading order
- WCAG 2.1 Level AA compliance target
- Focus indicators visible on all interactive elements (2px solid --color-primary)
- StatusBadge icons include aria-label matching the status label

---

## 8. Responsive Behavior

OpenVAL is optimized for desktop use (1280px+). Tablet support (768px+) is a secondary target. Mobile is not a primary target for the authoring interface, but the execution engine will have a simplified mobile view in a future phase.

**Breakpoints:**
- `sm`:  640px  (sidebar collapses automatically)
- `md`:  768px
- `lg`:  1024px
- `xl`:  1280px  (primary target)
- `2xl`: 1536px

**At sm/md:** Sidebar hides behind hamburger menu. PageHeader stacks vertically. DataTable switches to card layout.

---

*UI-SPEC-001 v1.0 - This document governs all OpenVAL frontend development.*
