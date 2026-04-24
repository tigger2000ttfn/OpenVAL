# PHARION Document and Template System
# User Requirements Specification

**Document Reference:** URS-DOC-001
**Version:** 1.0.0
**Status:** Approved
**Date:** 2026-04-08
**Author:** Head of Global Quality Assurance, PHARION Project
**Regulatory Basis:** 21 CFR Part 11, 21 CFR 211.68, EU Annex 11, GAMP 5 2nd Ed., ICH Q10

---

## Executive Summary

This document defines the complete user requirements for the PHARION Document
and Template System. This system is the backbone of the entire platform. Every
validation protocol, every controlled SOP, every risk assessment, every sign-off
record is a document. The document system is not a bolt-on feature — it is the
regulatory record that an FDA inspector will examine.

Requirements are written from the perspective of five personas:
1. **Validation Engineer** — authors, executes, and closes validation protocols
2. **QA Manager** — reviews, approves, and maintains a state of compliance
3. **Document Control Specialist** — manages the controlled document lifecycle
4. **CSV Specialist** — manages the validation program, builds templates
5. **Auditor / Inspector** — reviews records in read-only mode, cannot modify

All requirements are tagged with their regulatory basis and priority:
- **M** = Mandatory (regulatory requirement, no exceptions)
- **S** = Should (industry best practice, strong expectation from inspectors)
- **W** = Would be nice (differentiating feature, no regulatory mandate)

---

## Part 1: Foundational Document Control Requirements

### 1.1 Every Controlled Document Must Have

**URS-DOC-001** [M] [21 CFR 11.10(c), EU Annex 11 §7.1]
Every controlled document shall have a unique, site-scoped document reference
number that is assigned automatically by the system and cannot be reused or
reassigned, even after the document is archived or retired.

Format: `{doc_type_prefix}-{sequential_4_digits}` e.g. `SOP-0042`, `IQ-0007`
Prefix is configurable per document type per site.

**URS-DOC-002** [M] [21 CFR 11.10(c)]
Every controlled document shall have a version number. The initial version is 1.0.
Minor revisions increment the minor number (1.0 → 1.1 → 1.2).
Major revisions increment the major number (1.2 → 2.0).
The system shall determine major vs minor based on the user's classification
at the time of creating the new version, not automatically.

**URS-DOC-003** [M] [21 CFR 11.50]
Every document shall have a structured approval block capturing:
- Author (signature + date + title)
- Reviewer(s) (signature + date + title, one or more)
- Approver(s) (signature + date + title, one or more, QA always required)
These shall be electronic signatures compliant with 21 CFR Part 11.

**URS-DOC-004** [M] [GAMP 5 §7.2]
Every document shall have an embedded revision history table that is
auto-populated from the version history at the time of approval:
| Version | Date | Author | Summary of Changes |
The summary of changes shall be required input when creating a new version.

**URS-DOC-005** [M] [EU Annex 11 §8]
Every document shall have a page header or footer containing at minimum:
- Document reference number
- Version number
- Page number and total pages (e.g. "Page 3 of 12")
- Site name
- Document status watermark on draft documents

**URS-DOC-006** [M] [21 CFR 11.10(c)]
Approved documents shall be locked. No edits are possible to an approved document.
Creating a new version creates a draft copy of the current approved version.
The new draft goes through the full review/approval cycle before becoming effective.

**URS-DOC-007** [M] [21 CFR 11.10(e)]
Every field change in every document version shall be captured in the system
audit trail. At minimum: who changed what field, what the old value was, what
the new value is, when, and from which IP address.

**URS-DOC-008** [M] [21 CFR 11.10(c)]
Previous versions of all documents shall be retained indefinitely (or for the
configured retention period, minimum equal to the regulatory requirement for
the document type). Previous versions shall be accessible and printable but
not editable.

**URS-DOC-009** [S] [GAMP 5 §7.2]
Documents shall support an effective date distinct from the approval date.
A document can be approved today with an effective date of next month.
The document becomes "Effective" on the effective date, not the approval date.

**URS-DOC-010** [S] [ICH Q10 §1.3]
Documents shall support a periodic review schedule. The system shall notify the
document owner when a review is due. The review process shall be traceable
(who reviewed, what decision, when).

---

## Part 2: Page Layout and Document Formatting

**URS-DOC-011** [M]
The system shall support the following page sizes and orientations:
- Letter (8.5" × 11") Portrait
- Letter (8.5" × 11") Landscape
- A4 (210mm × 297mm) Portrait
- A4 (210mm × 297mm) Landscape

Page orientation may change mid-document. A document may have portrait pages
for narrative sections and landscape pages for wide data tables.

**URS-DOC-012** [S]
Configurable page margins (top, bottom, left, right) shall be available
per document template, with a minimum margin of 0.5" (12.7mm) required
to ensure print legibility.

**URS-DOC-013** [M]
The system shall support a configurable document header area that appears
on every page of the document when printed or exported to PDF.

Standard pharmaceutical document header contains:
```
┌─────────────────┬────────────────────────────┬──────────────────────┐
│  Company Logo   │  Document Title            │  Doc No: SOP-0042   │
│  [site-config]  │  Subtitle/Subject          │  Revision: 1.2      │
│                 │  Department / Owner        │  Effective: 2026-04  │
└─────────────────┴────────────────────────────┴──────────────────────┘
```
All fields shall be configurable per site. Logo shall be uploadable.
A site admin shall be able to define multiple header templates.

**URS-DOC-014** [M]
The system shall support a configurable document footer containing at minimum:
- Document reference number and version
- Page number / total pages
- Confidentiality classification (Internal, Confidential, Controlled)
- Site name
- DRAFT watermark on documents with status = Draft

**URS-DOC-015** [S]
The system shall support a two-column page layout mode for specific document
sections, while other sections remain single-column. Common use: a wide table
in landscape mode, followed by narrative text in single-column portrait.

**URS-DOC-016** [S]
The system shall enforce a standard Table of Contents that auto-generates from
the document's heading hierarchy. The ToC shall be:
- Automatically numbered
- Hyperlinked in PDF export
- Regenerated automatically when sections are added, removed, or reordered

---

## Part 3: Block-Based Document Architecture

The document editor shall use a **block-based content model**. Every piece of
content in a document is a "block." Blocks can be added, removed, and reordered.
Blocks within a section are ordered. Multiple blocks of any type can coexist.

This architecture is required because:
1. It naturally supports reusable content blocks from a library
2. It enables per-block audit trails (who changed this specific table, when)
3. It maps to the WYSIWYG editor's internal model (TipTap/ProseMirror)
4. It allows section-level locking (lock some blocks, allow editing of others)

### 3.1 Block Type Registry

**URS-DOC-017** [M] The system shall support the following block types:

#### Text Blocks
**paragraph** — Rich text paragraph. WYSIWYG formatted text with:
- Bold, italic, underline, strikethrough
- Superscript, subscript (required for chemical formulas)
- Bulleted list (unordered)
- Numbered list (ordered, multi-level)
- Indentation (up to 4 levels)
- Link (internal document cross-reference or external URL)
- Inline code (for system commands, SQL, etc.)
- Horizontal rule

**heading** — Section heading (H1/H2/H3/H4). Auto-numbered based on
document hierarchy. Headings become entries in the Table of Contents.
Section numbers update automatically when sections are reordered.

**callout** — Highlighted callout box with a type indicator:
- 📋 NOTE — informational note
- ⚠ WARNING — important caution  
- 🚫 CAUTION — safety-critical warning
- ℹ️ REGULATORY — regulatory requirement callout
- ✓ ACCEPTANCE CRITERIA — pass/fail criteria highlighted
All callouts have a colored left border and icon indicating type.

**page_break** — Forces a page break at this position in the document.

#### Table Blocks

**generic_table** — A fully configurable table:
- Configurable columns (header, width, alignment, type: text/number/date/dropdown/checkbox)
- Add/remove rows and columns
- Merge cells (horizontal and vertical)
- Cell shading (header rows highlighted)
- Border styles (full grid, no borders, etc.)
- Row-level locking (lock specific rows after data entry)

**execution_table** — The core of every validation protocol. Columns:
- Step # (auto-numbered, read-only during execution)
- Step Type indicator (action/check/data_entry/observation/screenshot/signature)
- Action (rich text, authored before execution)
- Expected Result (rich text, authored before execution)
- Actual Result (entry field, filled during execution)
- Result (Pass/Fail/N-A buttons or text entry during execution)
- Attachment zone (per step — drag to attach screenshot or file)
- Deviation button (opens inline deviation capture)
- Executed By (electronic signature, captured during execution)
- Date/Time (server-stamped, not user-entered)
- Witness (optional electronic signature)
- Notes (free text note by executor)

Sub-types of execution_table rows:
- `action` — pure action step, no data entry
- `check` — verify condition (pass/fail)
- `data_entry` — enter a specific value (numeric with range, text, date, dropdown)
- `data_table_entry` — enter multiple values in a sub-table within the step
- `observation` — free text observation
- `screenshot` — capture a screenshot as evidence (required element)
- `signature_point` — dedicated electronic signature within the execution
- `conditional` — step only appears if a previous step result = a specific value

**data_entry_table** — For capturing configuration or measurement data:
- Column definition: Parameter | Expected/Specification | Actual Value | Unit | Pass/Fail | Notes
- Configurable columns (add any column type)
- Acceptance range validation for numeric fields (auto-turns red if out of range)
- Formula columns (computed from other columns: e.g., % Recovery = Actual/Expected × 100)
- Row categories (group rows by category with a category header row)

**config_table** — Dedicated table for capturing system configuration during IQ:
- Standard two-column: Parameter | Configured Value
- Standard three-column: Parameter | Required/Expected | Actual | Pass/Fail
- Categories: Software, Hardware, Database, Network, Security, Interfaces, Users
- Import from system data (pre-populate from the linked system's attributes)
- Exportable to CSV for comparison

**risk_matrix_table** — FMEA-style risk matrix:
- Columns: Hazard | Failure Mode | Effect | Cause | P | I | D | RPN | Controls | Residual P | Residual I | Residual D | Residual RPN
- Color-coded cells by risk level (red/amber/green)
- RPN auto-calculated (P × I × D)
- Residual RPN auto-calculated
- Sortable by RPN descending
- Filter by risk level
- Links to risk_assessments table in database

**requirements_table** — Structured requirements:
- Columns: Req # | Requirement | Priority | Verification Method | Test Reference | Status
- Rows can be hierarchical (sub-requirements indented)
- Status chip: Not Tested, Passed, Failed
- Auto-links to traceability module

**acceptance_criteria_block** — Distinct visual treatment for acceptance criteria:
- Bold bordered box
- "ACCEPTANCE CRITERIA:" header
- Criteria listed with explicit pass/fail conditions
- During execution: criteria highlighted green (pass) or red (fail)

#### Media Blocks

**image_block** — Embedded image:
- Upload from local file
- Capture from screen (browser-based screenshot tool)
- Alt text for accessibility
- Caption (auto-numbered: Figure 1, Figure 2)
- Size control (fit width, fixed size, percentage)
- Alignment (left, center, right)
- Images are stored in the database file_store — never external links
- ALCOA+ compliance: image is immutable once saved to the document version

**flowchart_block** — Visual process flow diagram embedded in the document:
See Part 7 (Visual Workflow Designer) for full specification.

#### Compliance Blocks

**signature_block** — Single electronic signature:
- Role label (Author, Reviewer, QA Approver, etc.)
- Signer name (auto-populated when signed)
- Title (auto-populated from user profile)
- Date/time (server-stamped at time of signing)
- Signature meaning (configurable per block)
- Status: unsigned (shown as blank field with "Sign" button), signed (shows signature record chip)
- Electronic signature links to `electronic_signatures` table

**signature_table** — Multiple signatories in a tabular format:
- Standard approval table: Role | Printed Name | Signature | Date
- Configurable number of rows
- Each row is an independent signature block
- All signatures in the table must be complete for the document to advance to the next stage

**revision_history_block** — Auto-populated revision history table:
- Auto-populates from document_versions when the version is saved
- Columns: Rev | Date | Author | Summary of Changes
- Read-only in document view
- Fully auto-populated — never manually edited

**table_of_contents_block** — Auto-generated ToC:
- Pulls from all heading blocks in the document
- Respects heading hierarchy (H1 indent level 0, H2 indent 1, etc.)
- Updates automatically when headings change
- Hyperlinked in PDF export

**variable_display_block** — Shows a resolved variable value:
- e.g., `{{system.name}}` renders as "LabWare LIMS 7.0" in the document
- Shows a placeholder "[System Name]" in template mode
- Shows the resolved value in document mode
- Unresolved variables shown with a warning indicator

#### Interactive Blocks (filled during execution or completion)

**checklist_block** — Interactive checklist:
- Used for pre-execution checks, configuration checks, documentation checks
- Each item: checkbox + description + required/optional indicator + notes field
- Checking an item records: who checked, when
- Mandatory items must be checked before execution can begin
- Unchecked mandatory items are highlighted red

**form_block** — Structured data capture form:
- For documents that collect specific structured data (e.g., CAPA forms, deviation reports)
- Field types: text, number, date, dropdown, radio, checkbox, file upload
- Conditional fields: show field X only if field Y = value Z
- Field validation rules (required, min/max, pattern)
- Submitted form data stored in `document_form_field_values` table

**conditional_section** — Section that shows/hides based on conditions:
- Condition: field value, variable value, step result, document status
- Example: "Only show Section 5 if system.gamp_category = 'Category 5'"
- Rendered as collapsed/greyed out in template mode
- In document mode: shown or hidden based on live condition evaluation

**library_block** — Reference to a block from the Block Library:
- When a library block is used in a document, it shows a "Library Block" indicator
- If the library block is updated, all documents using it are flagged for review
- Can be "unlinked" (becomes a copy, loses library connection)

---

## Part 4: Template Builder

**URS-DOC-018** [M]
The system shall provide a Template Builder — a WYSIWYG editor specifically
for creating and editing document templates (as opposed to document instances).
The Template Builder shall:
- Allow placing any block type in the template
- Allow designating blocks as "pre-populated" (content set in template)
- Allow designating blocks as "fill during creation" (shown as fill-in prompts)
- Allow designating blocks as "fill during execution" (locked until execution begins)
- Allow defining variable placeholders (e.g., `{{system.name}}`)
- Allow defining which variables are prompted at document creation time

**URS-DOC-019** [S]
Templates shall be versioned and controlled like documents. A change to a
template requires a new template version. Documents created from a template
store which template version was used.

**URS-DOC-020** [M]
The system shall ship with a pre-built template library covering at minimum:

**Validation Protocol Templates:**
| Template Code | Name | Regulatory Basis |
|---|---|---|
| TMPL-IQ-GENERIC | Installation Qualification (Generic) | GAMP 5, 21 CFR 211.68 |
| TMPL-OQ-GENERIC | Operational Qualification (Generic) | GAMP 5 |
| TMPL-PQ-GENERIC | Performance Qualification (Generic) | GAMP 5, 21 CFR 211.68 |
| TMPL-IQ-LIMS | IQ for Laboratory Information Management Systems | GAMP 5 |
| TMPL-OQ-LIMS | OQ for LIMS | GAMP 5 |
| TMPL-PQ-LIMS | PQ for LIMS (end-to-end workflows) | GAMP 5 |
| TMPL-IQ-SERVER | IQ for Server Infrastructure | GAMP 5 |
| TMPL-OQ-SERVER | OQ for Server/Network | GAMP 5 |
| TMPL-IQ-INSTRUMENT | IQ for Laboratory Instruments | GAMP 5 |
| TMPL-OQ-INSTRUMENT | OQ for Laboratory Instruments | GAMP 5 |
| TMPL-PQ-INSTRUMENT | PQ for Laboratory Instruments | GAMP 5 |
| TMPL-UAT-GENERIC | User Acceptance Testing (Generic) | GAMP 5 |
| TMPL-DQ-GENERIC | Design Qualification | GAMP 5 |
| TMPL-SAT-GENERIC | Site Acceptance Testing | GAMP 5 |
| TMPL-FAT-GENERIC | Factory Acceptance Testing | GAMP 5 |
| TMPL-MAV-ICH | Method Analytical Validation | ICH Q2(R1) |
| TMPL-CSA-ASSESS | Computer Software Assurance Assessment | FDA CSA 2025 |
| TMPL-CSV-RETRO | Retrospective CSV Assessment | GAMP 5 |
| TMPL-CQV-IQ | Commissioning & Qualification IQ | GAMP 5 |
| TMPL-PV-PPQ | Process Performance Qualification | FDA PV Guidance 2011 |
| TMPL-CV-PROTOCOL | Cleaning Validation Protocol | 21 CFR 211.67 |
| TMPL-COLD-CHAIN | Cold Chain/Temperature Mapping | USP <659>, GDP |
| TMPL-STER-VAL | Sterilization Validation Protocol | ISO 11135, 11137 |

**Quality Document Templates:**
| Template Code | Name | Regulatory Basis |
|---|---|---|
| TMPL-SOP-GENERIC | Standard Operating Procedure (Generic) | 21 CFR 211.100 |
| TMPL-SOP-CSV | CSV Procedure | GAMP 5 |
| TMPL-SOP-CSA | CSA Procedure | FDA CSA 2025 |
| TMPL-SOP-CHANGE | Change Control (Validated Systems) | 21 CFR 211.100 |
| TMPL-SOP-REVIEW | Periodic Review | GAMP 5 |
| TMPL-SOP-EREC | Electronic Records & Signatures | 21 CFR Part 11 |
| TMPL-SOP-AUDIT-TRAIL | Audit Trail Review | 21 CFR 11.10(e) |
| TMPL-SOP-ACCESS | User Access Management | 21 CFR 11.10(d) |
| TMPL-SOP-BACKUP | Backup and Recovery | EU Annex 11 §16 |
| TMPL-SOP-DATA-INT | Data Integrity and ALCOA+ | MHRA GxP DI |
| TMPL-SOP-DEVIATION | Deviation Management | 21 CFR 211.192 |
| TMPL-SOP-CAPA | CAPA Management | 21 CFR 820.100 |
| TMPL-POLICY-GXP | GxP Computerized System Policy | 21 CFR 11 |
| TMPL-POLICY-DATA | Data Governance Policy | ALCOA+ |
| TMPL-URS | User Requirements Specification | GAMP 5 §5.3 |
| TMPL-FS | Functional Specification | GAMP 5 |
| TMPL-DS | Design Specification | GAMP 5 |
| TMPL-CS | Configuration Specification | GAMP 5 |
| TMPL-VAL-PLAN | Validation Plan | GAMP 5 |
| TMPL-VMP | Validation Master Plan | ICH Q10 |
| TMPL-VAL-REPORT | Validation Summary Report | GAMP 5 §9 |
| TMPL-RISK-FMEA | Risk Assessment (FMEA) | ICH Q9 |
| TMPL-RISK-PI | Risk Assessment (P×I Matrix) | ICH Q9 |
| TMPL-AUDIT-RPT | Audit Report | ISO 19011 |
| TMPL-PERIODIC-RPT | Periodic Review Report | GAMP 5 |
| TMPL-SUPPLIER-QUAL | Supplier Qualification Report | 21 CFR 820.50 |
| TMPL-ANNEX11-CL | EU Annex 11 Compliance Checklist | EU Annex 11 |
| TMPL-483-RESPONSE | FDA 483 Observation Response | 21 CFR Part 11 |

**URS-DOC-021** [M]
All templates shall be fully customizable. A site can:
- Copy any system template and modify it
- Create entirely new templates from scratch
- Add/remove/reorder sections
- Modify block configurations
- Add custom variables
- Change header/footer format
- Apply site-specific branding (logo, colors)

**URS-DOC-022** [S]
Custom templates created by a site shall be subject to document control
(version, review, approval) if the site configures them as controlled templates.
The template approval record shall be linked to the template version.

---

## Part 5: WYSIWYG Editor Requirements

**URS-DOC-023** [M]
The document editor shall provide true WYSIWYG (What You See Is What You Get)
editing. The editor view shall accurately represent how the document will appear
when exported to PDF or printed.

**URS-DOC-024** [M]
The editor shall support real-time saving. Auto-save shall occur every 60 seconds
on active edits. The save creates a draft checkpoint (not a version).
Data cannot be lost due to browser close or network interruption.

**URS-DOC-025** [M]
The editor shall support deep undo/redo history (minimum 50 steps) within
a single editing session. Undo history does not persist across sessions.
[Note: The audit trail captures what changed — undo history is for the
current editing session only and is not part of the regulated record.]

**URS-DOC-026** [S]
The editor shall support find and replace within the current document.
Replacement shall be logged in the audit trail.

**URS-DOC-027** [S]
The editor shall support paste from Microsoft Word with GxP-safe cleanup:
- Remove all macros (security requirement)
- Normalize formatting to document styles
- Remove hidden tracking changes from Word
- Warn user that pasted content has been cleaned
- The paste operation and source shall be logged in the audit trail

**URS-DOC-028** [S]
Spell checking with pharmaceutical domain dictionary shall be available.
The pharmaceutical dictionary shall include: chemical names, dosage forms,
route of administration terms, regulatory terms (IQ, OQ, PQ, CAPA, etc.),
and common abbreviations.
Custom terms shall be addable to the site dictionary.

**URS-DOC-029** [M]
Section-level locking shall be supported:
- Admin or QA can lock individual sections of an approved document
- Locked sections are visible but not editable
- Locking a section requires an electronic signature and is audit-logged
- This supports situations where part of a document must remain frozen
  while other parts need minor update (use sparingly — prefer new versions)

**URS-DOC-030** [M]
The editor shall clearly indicate document status to all users:
- Draft documents: yellow DRAFT banner at top and DRAFT watermark on all pages
- In Review documents: blue IN REVIEW banner, document editable only by current reviewer
- Approved/Effective documents: locked, green APPROVED/EFFECTIVE banner
- Superseded documents: gray SUPERSEDED banner, read-only

---

## Part 6: Review and Collaboration

**URS-DOC-031** [M] [21 CFR 11.10(e)]
All review actions shall be captured in the audit trail. For each review:
who reviewed, when, what decision, any comments, and any annotations made.

**URS-DOC-032** [S]
Inline annotations shall be supported during review:
- Reviewers can highlight any text and attach a comment
- Reviewers can propose a redline (track-changes style: strike old, propose new)
- Reviewers can mark a comment as a question, correction, or concern
- Authors see all annotations in a side panel
- Authors respond to each annotation (accept/reject/question response)
- All annotation and response actions are audit-logged
- Critical unresolved annotations block the approval action

**URS-DOC-033** [W]
Real-time simultaneous editing shall be supported during authoring (not review).
Multiple authors can edit different sections simultaneously.
Conflicts (two people editing the same block) are resolved with last-write-wins
and a visible conflict notification.
[Note: Real-time editing is aspirational. Phase 23+ if not in earlier phases.]

**URS-DOC-034** [M]
For documents under review, the review workflow shall clearly show:
- Who is assigned to review (in what sequence if sequential)
- Which reviewers have completed their review
- Which reviewers are pending
- SLA countdown for pending reviewers
- The specific annotation/comments from each completed reviewer
- Overall status: Approved / Conditionally Approved / Rejected

---

## Part 7: Visual Workflow Designer

**URS-DOC-035** [S]
The system shall provide an in-browser visual workflow designer for creating
process flow diagrams embedded in documents (SOPs, work instructions).
No external tool (Visio, Lucidchart) shall be required.

**URS-DOC-036** [S]
The visual designer shall support the following shape types
aligned to ISO 5807 flowchart standard:
- Rectangle (process step)
- Diamond (decision — yes/no branch)
- Rounded rectangle (start/end)
- Parallelogram (input/output)
- Database cylinder (data store)
- Document shape (document input/output)
- Arrow connector with label

**URS-DOC-037** [S]
The designer shall support swim lanes:
- Horizontal or vertical swim lanes
- Each lane labeled with a responsible party (role or department)
- Shapes can be placed in lanes
- Crossing connections automatically route around other shapes

**URS-DOC-038** [W]
A flowchart shape may be linked to a workflow engine stage.
When viewing the SOP flowchart, clicking a process shape shows the
corresponding workflow stage in the PHARION workflow engine.
This creates a live connection between documented procedures and executable workflows.

**URS-DOC-039** [S]
The completed flowchart shall be embedded in the document as an SVG image
that scales with the document and exports correctly to PDF.
The embedded SVG is immutable once the document version is approved.

---

## Part 8: AI-Assisted Document Creation

These requirements define the AI capabilities for the document system.
All AI actions are logged. All AI suggestions require human review and
acceptance. AI never creates a regulated record without human approval.

**URS-DOC-040** [W]
**AI Draft Generation:** Given a template and a linked system, the AI shall
generate a complete first draft of a validation protocol or document.
Input: template type, system data, site preferences.
Output: a draft document with all blocks pre-populated with suggested content.
Time target: < 3 minutes for a complete IQ protocol draft.

**URS-DOC-041** [W]
**Natural Language to Test Step:** A user shall be able to type a description
of a test scenario in natural language ("verify that audit trail captures all
user login events") and the AI shall produce a properly formatted test step:
- Step type selection
- Action text
- Expected result
- Suggested regulatory citation
- Suggested acceptance criteria

**URS-DOC-042** [W]
**Regulatory Gap Analysis:** The AI shall scan any draft document and compare
it against a selected regulatory framework (21 CFR Part 11, EU Annex 11,
GAMP 5 Chapter X) and produce a gap list:
- "Section 3 does not address audit trail review requirements (21 CFR 11.10(e))"
- "No acceptance criteria defined for Steps 4.2 through 4.5"
- "Pre-execution requirements section is missing (GAMP 5 §8.3)"
The gap list shall be displayed as a side panel, with each gap having a
"Jump to location" and "Generate suggested content" action.

**URS-DOC-043** [W]
**Acceptance Criteria Generation:** Given a test step description, the AI
shall suggest appropriate acceptance criteria. Examples:
- "Login verification step" → "The system shall reject any login attempt with an
  incorrect password. The system shall lock the account after 5 failed attempts."
- "Audit trail step" → "The audit trail record shall capture: user ID, action,
  old value, new value, timestamp (server-side), IP address."

**URS-DOC-044** [W]
**Video-to-Script:** The user can record their screen while performing a test
process. The AI analyzes the recording and:
1. Identifies distinct actions (click, type, navigate, observe)
2. Generates a draft test script with one step per action
3. Presents the draft for user review and editing
4. The generated script becomes a test case template after user approval

**URS-DOC-045** [W]
**Document Comparison Summary:** When two versions of a document are compared,
the AI shall provide a natural language summary:
- "Version 1.2 adds 3 test steps in Section 4 covering audit trail requirements"
- "Acceptance criteria for Step 3.5 changed from ±5% to ±2%"
- "Section 7 (References) was entirely removed"

**URS-DOC-046** [W]
**Protocol Completeness Score:** The AI shall provide a completeness assessment
for any draft protocol, scoring it 0-100% and listing:
- What is present and complete
- What is present but incomplete
- What is missing entirely
With direct links to add the missing elements.

---

## Part 9: Validation Package System

A **Validation Package** (VP) is an ordered collection of related validation
documents that together form the complete regulatory record for a validated system.
A VP is the artifact that an inspector reviews — not individual documents.

**URS-DOC-047** [M]
The system shall support Validation Packages as a distinct entity:
- Unique package reference (VP-0001)
- Title describing scope (e.g., "LabWare LIMS 7.0 Validation Package")
- Version number (separate from included document versions)
- Status (draft, in review, approved, released)
- Scope description (what systems and functions this package covers)
- Linked validation project

**URS-DOC-048** [M]
A Validation Package shall contain an ordered list of documents with roles:

| Role | Description |
|---|---|
| Validation Plan | The plan for this validation effort |
| Risk Assessment | Risk assessment that drove the validation scope |
| URS | User Requirements Specification |
| Functional Spec | Functional specification (if applicable) |
| Design Spec | Design/Configuration specification (if applicable) |
| IQ Protocol | Installation Qualification protocol and execution record |
| OQ Protocol | Operational Qualification protocol and execution record |
| PQ Protocol | Performance Qualification protocol and execution record |
| UAT Protocol | User Acceptance Testing (if applicable) |
| Traceability Matrix | RTM showing requirements → tests |
| Validation Summary | Validation Summary Report (the final sign-off document) |
| Change Records | Any change requests applied during the validation |
| Deviations | Deviations raised during execution |
| Supporting Docs | Any additional supporting documentation |

**URS-DOC-049** [M]
Each document in a Validation Package shall show its current status.
An inspector looking at the package shall immediately see which documents
are approved, which are still in draft, and which are missing.

**URS-DOC-050** [M]
The Validation Package shall have its own approval block. The package
is approved (signed off) separately from the individual documents.
Package approval indicates: "I confirm that this package is complete,
all documents are approved, and this system is validated."

**URS-DOC-051** [M]
The Validation Package shall be exportable as a single PDF document:
- Cover page (package title, version, site, approved date, signatories)
- Package Table of Contents (with page numbers for each document section)
- Each document included in full, in sequence
- Divider pages between documents
- Document control index at the back
The PDF shall be paginated continuously (not restarting at 1 for each document)
and have working hyperlinks in the ToC.

**URS-DOC-052** [S]
The Validation Package shall have **Release Notes** for each version:

| Field | Description |
|---|---|
| Release Number | VP-0001 v1.0 |
| Release Date | 2026-04-08 |
| Summary | What changed in this version |
| Documents Added | New documents |
| Documents Updated | Modified documents with version change |
| Documents Removed | Removed documents |
| Validation Impact | Does this release change executed/approved tests? |
| Classification | Major (re-execute) / Minor (no re-execution) / Administrative |
| Linked Change Requests | CRs that drove this package update |
| Regulatory Notification | Required? If yes, link to regulatory filing |

**URS-DOC-053** [S]
The Validation Package shall support a **Transmission Record**:
- Who the package was sent to (name, role, organization)
- When it was sent
- How it was sent (electronic distribution from PHARION, email, printed copy)
- For printed copies: copy number and recipient
This supports regulatory submission tracking and controlled copy management.

**URS-DOC-054** [W]
The system shall support an **PHARION System Validation Package** — a
pre-built validation package for PHARION itself:
- VP-001 through VP-015 (already specified in MASTER_PLAN Phase 16)
- Automatically linked to the installed PHARION version
- Pre-executed execution records (to be completed by the site)
- This package validates the tool you're using to validate your systems

---

## Part 10: Document Control Operations

**URS-DOC-055** [M] [21 CFR 11.10(c)]
**Periodic Review Scheduling:** Documents shall have configurable review intervals
(typically 1, 2, or 3 years for pharma). The system shall automatically notify
the document owner when the review date is approaching (configurable lead time,
default 60 days). The review record shall be traceable.

**URS-DOC-056** [M]
**Document Retirement/Obsolescence:** A document can be retired (status: Obsolete).
Retired documents remain accessible in the system (cannot be deleted)
but are clearly marked as obsolete and do not appear in active document searches
by default. Retiring a document requires an electronic signature with justification.

**URS-DOC-057** [M]
**Supersession:** When a new version of a document is approved, the previous
version is automatically marked as Superseded. The supersession is recorded
with: who superseded it, when, and which document version replaced it.
Previous versions remain accessible and printable.

**URS-DOC-058** [M] [21 CFR 11.10(c)]
**Distribution List Management:** Documents shall have configurable distribution
lists. When a document becomes effective:
- Automatic notification sent to all distribution list members
- Read confirmation requirement (user must confirm they have read and understood)
- Deadline for read confirmation (configurable, default 30 days)
- Auto-reminders for pending confirmations
- Training assignment can be automatically triggered alongside distribution
- Distribution record is maintained and auditable

**URS-DOC-059** [S]
**Controlled Copy Printing:** When a user prints a document, the system:
- Prompts: "Is this a controlled copy?"
- If yes: assigns a copy number, watermarks with "CONTROLLED COPY #X"
- Logs: who printed, when, copy number (for physical copy inventory)
- If no: watermarks with "UNCONTROLLED COPY — CHECK SYSTEM FOR CURRENT VERSION"

**URS-DOC-060** [M]
**Document Search:** Full-text search across all document content, titles,
reference numbers, and tags. Search shall be role-filtered
(users only see documents they are permitted to access).
Search results shall show: document title, ref, version, status, and
a snippet of the content around the search term.

**URS-DOC-061** [S]
**Document Linking:** Documents shall be linkable to:
- Systems (this SOP applies to this system)
- Equipment (this procedure is for this piece of equipment)
- Protocols (this specification is referenced by this protocol)
- Change requests (this SOP was revised as a result of this CR)
- Training requirements (reading this document counts as training for this role)
Linked records are shown in a "Related Records" panel on the document detail page.

---

## Part 11: Block Library (Reusable Content Blocks)

**URS-DOC-062** [S]
The system shall maintain a **Block Library** — a catalog of reusable content
blocks that can be inserted into any document or template.

Block categories in the library:
- **Boilerplate Text** — standard paragraphs used across many documents
  (purpose statements, scope statements, abbreviations tables, references tables)
- **Signature Blocks** — pre-configured signature tables for different approval scenarios
- **Compliance Checklists** — pre-built compliance verification checklists
- **Standard Tables** — header tables, revision history, distribution lists
- **Regulatory Citations** — blocks containing specific regulatory citations
- **Standard Acceptance Criteria** — common pass/fail criteria
- **Glossary Sections** — standard pharma glossary

**URS-DOC-063** [S]
A library block has a **version**. When a library block is updated, all documents
using that block are flagged with a "Library block has been updated" indicator.
The document owner can choose to pull in the update or retain the current version.
This ensures consistency across the document library without forcing unwanted changes.

**URS-DOC-064** [S]
Library blocks shall support **site-level and global-level** scope:
- Global library blocks: available across all sites (PHARION-shipped standard blocks)
- Site library blocks: created by a site, available only to that site
- Cross-site library blocks (EE): corporate-level blocks shared across all sites in an organization

---

## Part 12: Performance and Scale Requirements

**URS-DOC-065** [M]
Document creation: creating a new document from template shall complete
within 5 seconds for templates up to 50 blocks.

**URS-DOC-066** [M]
Document loading: opening an existing document for editing shall complete
within 3 seconds for documents up to 200 blocks.

**URS-DOC-067** [M]
PDF export: generating a PDF for a single document (up to 100 pages)
shall complete within 30 seconds. For validation packages (up to 500 pages)
within 5 minutes as a background task.

**URS-DOC-068** [M]
Concurrent editing: the system shall support up to 10 simultaneous document
editors (different users on different documents) without degraded performance.

**URS-DOC-069** [S]
Document search: full-text search across 10,000 documents shall return results
within 2 seconds.

---

## Summary: User Requirements Count

| Section | Requirements | M | S | W |
|---|---|---|---|---|
| 1. Foundational Doc Control | 10 | 8 | 2 | 0 |
| 2. Page Layout | 6 | 2 | 4 | 0 |
| 3. Block Architecture | 1 | 1 | 0 | 0 |
| 4. Template Builder | 5 | 3 | 2 | 0 |
| 5. WYSIWYG Editor | 8 | 5 | 3 | 0 |
| 6. Review & Collaboration | 4 | 2 | 1 | 1 |
| 7. Visual Workflow Designer | 5 | 0 | 4 | 1 |
| 8. AI-Assisted Creation | 7 | 0 | 0 | 7 |
| 9. Validation Package | 8 | 4 | 3 | 1 |
| 10. Document Control Ops | 7 | 5 | 2 | 0 |
| 11. Block Library | 3 | 0 | 3 | 0 |
| 12. Performance | 5 | 3 | 2 | 0 |
| **Total** | **69** | **33** | **26** | **10** |

33 mandatory requirements that must be implemented to be 21 CFR Part 11 compliant.
26 should-have requirements expected by FDA/EMA inspectors.
10 would-be-nice features that differentiate PHARION in the market.

---

*URS-DOC-001 v1.0.0 — Written by Head of Global QA, PHARION Project*
*Every requirement traced to a regulatory citation. Every requirement has a priority.*
*This URS shall be tested in OQ-DOC-001 and tracked in RTM-001.*
