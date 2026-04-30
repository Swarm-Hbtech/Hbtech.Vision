# OC-GD Roadmap v3.1

**Created:** 2026-04-30 13:50 UTC
**Status:** Approved MVP boundary
**Owners:** Igor (process architect), Swarm (research / structure / ops bridge), Opus.Dev (implementation), Gemini (architectural review support)

---

## 1. Core principle

OC-GD must be built **зернышко за зернышком**.
We do not build the full factory first.
We first prove the base physics of the rendering system.

---

## 2. Official MVP-1 boundary

### What MVP-1 is

MVP-1 is an isolated **black-box render core**:

> An API microservice (target runtime: RunPod) that accepts an incoming control signal
> (`Depth / Control image + JSON prompt/settings payload`)
> and predictably generates a **two-tier architectural render**:
> **Preview + Final**.

### Success criteria for MVP-1

#### 1. Geometry
- Load-bearing structure, openings, windows, and overall dimensions do not collapse
- Visual geometry preservation target: **>90% match** to source drawing/control input

#### 2. Control
- Two-tier generation works:
  - **Preview** = fast / cheap / iterative
  - **Final** = slower / photoreal / approval-grade

#### 3. Reproducibility
- Pipeline runs through API
- Does not crash from VRAM instability
- Fits target economics
- Working cost target: **up to ~$0.10 per generation** as an upper MVP sanity bound

---

## 3. What is explicitly OUT of MVP-1

The following are intentionally excluded from MVP-1:

- Streamlit UI
- Telegram bot integration
- BOQ / IFC parsing
- SEO generation
- Infographic generation
- Marketplace packaging (Ozon / Wildberries / Yandex Market)
- Unified PDF commercial report

For MVP-1, API can be driven via:
- Postman
- curl
- minimal test scripts

---

## 4. Working hypotheses approved for the next stage

### Input path hypotheses
- **Fast test path:** Revit Depth Cueing export as depth-like control image
- **Deep production path:** glTF-based geometry path for true server-side mask generation
- **IFC lane:** semantics / BOQ / metadata lane, not core visual MVP lane

### Render-core hypotheses
- **FLUX.2** = primary candidate for final-quality generation
- **SDXL / LCM / related fast branch** = preview and/or fallback candidate
- These are treated as **Sprint 1 working hypotheses**, not irreversible doctrine

---

## 5. Roadmap structure

## Stage 1 — Render Core MVP
**Goal:** Prove that control input can be transformed into a commercially meaningful architectural render.

### 1.1. Baseline graph (Opus.Dev)
Build a ComfyUI render core with candidate branches for:
- FLUX.2
- preview/fallback fast branch (SDXL / LCM or equivalent)

### 1.2. Scale anchors (Opus.Dev)
Introduce reference-cube logic for stable proportional control.

### 1.3. Two-tier generation contract (Opus.Dev)
Define and implement:
- Preview mode
- Final mode

### 1.4. Infrastructure packaging (Swarm)
Package graph + weights + runtime into deployable container and prepare RunPod-compatible black-box API service.

**Stage 1 success condition:**
A control image + JSON payload goes in, predictable preview/final render comes out.

---

## Stage 2 — Revit Bridge
**Goal:** Stabilize and improve input extraction from source design environment.

### 2A. Fast bridge
- Revit Depth Cueing export
- thicker lines
- export discipline for test-ready control PNGs

### 2B. Deep bridge
- glTF export path
- true server-side mask generation
- deeper Revit automation path (MCP / future automation options)

### 2C. Adjacent optional track
- IFC / IfcOpenShell / BOQ research and extraction
- kept outside MVP-1 critical path

---

## Stage 3 — HITL Control Surface
**Goal:** Add explicit human quality control.

### 3.1. Operator dashboard (Opus.Dev)
Streamlit control surface with:
- Generate Preview
- Generate Final
- Approve / Regenerate logic

### 3.2. Telegram edge (Swarm)
Optional operational shortcut through `/render` once API core is stable.

---

## Stage 4 — Commercial Packaging
**Goal:** Turn render outputs into business-ready deliverables.

### 4.1. Marketplace formatting
- crop ratios
- image packaging

### 4.2. SEO and text automation
- titles
- descriptions
- bullets

### 4.3. Infographic rendering
- HTML/CSS → image composition

### 4.4. Unified proposal artifact
- renders
- supporting visuals
- optional BOQ/cost layer
- final PDF

---

## 6. Operating rule for the team

No one is allowed to expand scope by mixing downstream business features into Stage 1.

Stage 1 is about one thing only:
> proving the render core physics and economics.

---

## 7. Immediate next action

Next artifact to produce:
- **Engineering spec for Stage 1.1 + 1.2 (+ explicit Preview/Final contract)**

This spec should be handed to Opus.Dev as the implementation brief for MVP-1 core assembly.
