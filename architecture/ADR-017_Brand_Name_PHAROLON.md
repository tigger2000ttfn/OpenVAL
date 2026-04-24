# ADR-017 — Brand Name: PHAROLON

**Status:** Accepted  
**Date:** 2026-04-23  
**Deciders:** Head of Global QA  

---

## Context

The platform required a permanent brand name. The original working title "OpenVAL" had a USPTO trademark conflict (Atorus Research, Registration #97737837, May 2025, Classes 9 and 42). A systematic search of candidates was conducted against USPTO TESS, active domains, and software product registries.

## Candidates Eliminated

| Name | Conflict |
|---|---|
| OpenVAL | Atorus Research USPTO #97737837 — Class 9 + 42, registered May 2025 |
| PHAROS | Pharos Systems USA — PHAROS BLUEPRINT registered and renewed June 2024 |
| CLAROS | Hach Company — water quality software, USPTO #5530753 |
| LUMARIS | Lutron Electronics — LED lighting, USPTO #7774431, registered April 2025 |
| FARO | FARO Technologies — 3D measurement, USPTO #1775007, registered 1993 |
| CLAROS | Claros Group — management consulting, common law conflict |

## Decision

**PHAROLON** — from PHAROS (the Pharos of Alexandria lighthouse) + -LON suffix.

No USPTO conflicts found in Classes 9 (software) or 42 (SaaS/technology services) as of 2026-04-23. No active software products using this name identified.

## Rationale

### Etymology is the brand story

PHAROLON encodes the entire platform mission in its name:

- **PHAROS** — the Pharos of Alexandria, one of the Seven Wonders of the Ancient World. The ancient lighthouse that guided every vessel through the Mediterranean for over a thousand years. Not one industry. Every industry.
- **-LON** — an extending suffix that carries the lighthouse forward in time, into the regulatory era.

The name is the story: the fixed reference point that guides any regulated organisation through compliance complexity, regardless of industry, geography, or framework.

### The Icon — A Second Hidden Wonder

The pyramid icon encodes a second Egyptian Seven Wonder: the **Great Pyramid of Giza**. Together, two of the most enduring human constructions ever built are referenced in a single mark — the lighthouse (name) and the pyramid (icon).

This dual-wonder reference is intentional, layered, and — for most users — invisible until it is explained. Exactly right for a platform built on precision, depth, and the kind of rigour that regulators demand.

### Icon Anatomy

| Element | Reference |
|---|---|
| Upward nested △ (gold/teal/purple) | Great Pyramid of Giza — three nested stone courses |
| Compass ring + cardinal/intercardinal ticks | Navigation instrument — regulatory complexity |
| Dashed horizon line at pyramid base | The sea — the danger the lighthouse stands above |
| Apex beacon, triple-flash animation | The Pharos lighthouse — the signal |
| Ghost outer pyramid, self-drawing animation | The form only visible to those who look closely |
| Beam rays from apex | Light from the lighthouse tip |
| Compass ring slow rotation (100s) | Continuous orientation — always finding true north |

### Wordmark

Syne 800, letter-spacing:0, P descends 0.14em below baseline — echoing the lighthouse standing below the horizon line in the icon. The descent is not decorative. It is semantic.

**PH△ROLON** — secondary variant where the pyramid icon replaces the A letterform, unifying mark and wordmark into a single typographic object.

## Consequences

- All documentation rebranded from OpenVAL/PHARION to PHAROLON
- GitHub repo to be renamed from OpenVAL to PHAROLON
- Trademark attorney to file Classes 9 and 42 (intent-to-use) before public launch
- Domain registration: pharolon.io and pharolon.com to be verified and secured
- The brand story (two Egyptian wonders) to be disclosed progressively — not upfront — as users and partners discover the layers

## Acronym — pH

**pH** is the official short-form acronym for PHAROLON.

This is the fourth layer of the brand, and the most technically elegant:

| Reference | Meaning |
|---|---|
| **pH** = PHAROLON | The platform acronym |
| **pH** = potential of Hydrogen | The universal chemistry notation for acidity/alkalinity — fundamental to pharmaceutical manufacturing, biotech, food safety, and every regulated science |
| **p** lowercase | Mirrors the dropped P in the wordmark (P descends 0.14em below baseline — like the lowercase p in pH notation) |
| **H** uppercase | The standing letter — the lighthouse, the fixed reference point |

The wordmark's descending P was always referencing pH. The chemistry is in the letterform.

Usage: `pH` in running text, `pH PHAROLON` on first use, `pH` alone in contexts where
the brand is established. Never `PH`, never `Ph` — always the chemistry notation casing.

---

## Actions Required

- [ ] Register pharolon.io / pharolon.com
- [ ] Engage trademark attorney — Classes 9 and 42 ITU filing
- [ ] Rename GitHub repo: Settings → Repository name → PHAROLON
- [ ] Enable GitHub Pages: Settings → Pages → main /docs folder
