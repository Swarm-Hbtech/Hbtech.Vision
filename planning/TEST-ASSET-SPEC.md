# Hbtech.Vision — Test Asset Specification

**Status:** Draft  
**Purpose:** Define the minimum “golden dataset” artifacts needed to evaluate MVP-1 render core meaningfully.

---

## 1. Goal

Before Opus.Dev assembles production-grade graph logic, the project needs a compact but high-value set of canonical test assets.

These assets must help answer one question:

> Can the render core preserve architecture from control input in a stable and commercially useful way?

---

## 2. Golden dataset — first batch

### Required project count
Prepare **2–3 representative modular house projects**.

They should be typical, not exotic.
No curved/experimental geometry unless specifically needed later.

---

## 3. For each project, export these artifacts

### A. Human-readable source image
A normal visual export / screenshot of the chosen Revit view so the team understands what the control image is supposed to represent.

### B. Depth-like control image
A black-to-white (or white-to-black, but consistent) **Depth Cueing export** from Revit.
This is the main MVP-1 control input candidate.

### C. Short scene note
For each asset, include a short text note with:
- project name / ID
- view type
- exterior or interior
- what geometry is critical to preserve
- what would count as obvious failure

### D. Optional style references
For each project, attach 3–5 reference images if there is a desired visual target.

---

## 4. Preferred asset types for first batch

The first golden batch should include variety, but controlled variety.

### Recommended composition
1. **One simple exterior**
   - clear facade
   - obvious windows/openings
   - easy roofline

2. **One medium-complexity exterior**
   - porch / terrace / overhang / facade articulation
   - more chances for geometric drift

3. **Optional interior or edge case**
   - only if useful and not distracting

Priority is exterior architecture first.

---

## 5. Required Revit export settings for Depth Cueing test images

Recommended starting configuration:
- 3D view
- display mode: **Hidden Lines**
- background: **white**
- textures: **off**
- shadows: **off**
- unnecessary annotations: **off**
- Depth Cueing: **on**
- fade direction: keep consistent across all exports

If possible, also apply:
- **line thickening** for cleaner edge readability
- stable export resolution across all samples

---

## 6. Resolution requirements

For the first batch, consistency matters more than extremal quality.

Recommended starting export:
- one consistent high-enough PNG resolution
- target range: **2048 px** on the long side (or another fixed standard chosen once and reused)

Important rule:
- all first-batch control images should use the **same export standard** where possible

---

## 7. Scale anchor requirements

Where possible, test variants should include the **1x1x1 meter cyan reference cube** in a deliberate, repeatable placement.

For each test scene record:
- whether cube is present
- where it is placed
- whether it visually interferes with architecture

This will help compare:
- with cube
- without cube
- cube near
- cube offset

---

## 8. Naming convention

Recommended naming structure:

```text
project01_exterior_source.png
project01_exterior_depthcue.png
project01_exterior_notes.md
project01_refs_01.jpg
project01_refs_02.jpg
```

This keeps the dataset machine-readable and easy to hand off.

---

## 9. What makes a good first-batch test asset

A good asset has:
- clear geometry
- clear openings
- meaningful facade logic
- easy visual comparison between source and generated result
- minimal ambiguity about what “wrong” looks like

A bad asset has:
- overloaded annotations
- too much decorative noise
- unclear viewpoint
- no obvious geometry anchor
- no human note describing critical success/failure criteria

---

## 10. Suggested human review checklist per asset

For each generated result, reviewers should ask:
- Are the window positions preserved?
- Is the building mass preserved?
- Is the roofline preserved?
- Did the model invent or remove large architectural elements?
- Does the reference style feel directionally correct?
- Is this useful enough for preview or approval workflow?

---

## 11. Immediate minimum deliverable from Igor

To unblock Stage 1 evaluation, the absolute minimum first shipment may be:
- **2 Depth Cueing control PNGs**
- **2 matching human-readable source images**
- **2 short scene notes**
- **5–10 visual style references total**

This is enough to start meaningful render-core testing without waiting for a huge dataset.
