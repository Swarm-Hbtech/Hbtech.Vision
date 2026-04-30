# Hbtech.Vision — Architecture Decisions

**Status:** Living ADR-style decision log  
**Purpose:** Preserve why core architectural choices were made, so future implementation does not drift into re-litigating settled principles.

---

## ADR-001 — Veras is excluded from core architecture

**Status:** Accepted

### Decision
Hbtech.Vision will not depend on Veras or similar proprietary AI-render plugins as a required component of the rendering pipeline.

### Why
- Project goal includes cost reduction versus proprietary AI rendering tools
- Vendor lock would destroy margin and long-term control
- Proprietary plugin dependency would make the architecture strategically fragile
- We need an open, inspectable, automatable pipeline

### Consequence
- Any use of third-party plugins is limited to research/reference only, not production dependency
- The rendering core must stand on open or controllable components

---

## ADR-002 — MVP-1 is only the render core

**Status:** Accepted

### Decision
MVP-1 is strictly limited to an isolated black-box rendering microservice:
- input: control image + JSON payload
- output: Preview + Final render

### Explicitly excluded from MVP-1
- Streamlit UI
- Telegram bot integration
- BOQ / IFC automation
- SEO generation
- infographics
- marketplace packaging
- final PDF report

### Why
- We must prove rendering physics before downstream business automation
- Scope control protects execution quality and time-to-first-proof
- WIP discipline matters because Opus.Dev already carries active project load elsewhere

### Consequence
- Any request to mix packaging/business features into Stage 1 should be rejected

---

## ADR-003 — Two-path input strategy

**Status:** Accepted as strategic direction

### Decision
Hbtech.Vision uses a dual-path input strategy:

#### Fast Path (MVP testing)
Revit Depth Cueing export as depth-like control image

#### Deep Path (target production path)
glTF-based geometry path for server-side generation of masks / depth / control artifacts

### Why
- Fast Path enables immediate low-cost testing without heavy Revit-side development
- Deep Path provides cleaner long-term production architecture and better true-depth opportunities
- This avoids blocking MVP on perfect extraction architecture

### Consequence
- MVP experiments may begin before full Revit bridge maturity
- Fast Path is not the final architecture; it is the first operational bridge

---

## ADR-004 — IFC is not part of visual MVP core

**Status:** Accepted

### Decision
IFC belongs to the semantics / BOQ / metadata lane, not to the visual MVP render-core lane.

### Why
- IFC is strategically valuable for quantities, materials, metadata, and future BOQ/cost workflows
- But it should not delay proof of the visual rendering core
- Mixing BOQ with visual MVP would create unnecessary coupling and schedule risk

### Consequence
- IFC and IfcOpenShell continue as adjacent research/engineering track
- Visual MVP can ship before BOQ automation exists

---

## ADR-005 — Two-tier render flow is mandatory

**Status:** Accepted

### Decision
The render core must support two modes from the start:
- **Preview** — fast, cheap, iterative
- **Final** — slower, approval-grade, photoreal

### Why
- Human-in-the-loop requires cheap early iteration
- Without preview mode, GPU cost and wait time will kill usability
- Preview/final split is both an economics decision and a UX decision

### Consequence
- All graph design should account for mode switching or mode-specific branches from day one

---

## ADR-006 — FLUX is primary candidate, not dogma

**Status:** Accepted as working hypothesis

### Decision
FLUX-family models are the primary final-quality candidate for Stage 1, pending empirical validation against speed, geometry fidelity, VRAM stability, and cost. This is not treated as irreversible doctrine.

### Why
- Current research suggests stronger spatial coherence and architectural fidelity
- However, architecture must remain empirical, not ideological

### Consequence
- SDXL / LCM / related branches remain legitimate preview or fallback candidates
- Stage 1 implementation should preserve optionality where practical

---

## ADR-007 — Human-in-the-loop is required

**Status:** Accepted

### Decision
Hbtech.Vision will not be designed as a blind autonomous image factory. Human approval is a required architectural quality gate.

### Why
- Commercial architectural visuals cannot tolerate silent hallucination
- Approval/regenerate gates are cheaper than downstream brand damage
- HITL preserves trust and commercial quality

### Consequence
- Preview/final workflow and future UI design must include explicit review and approval checkpoints

---

## ADR-008 — Depth Cueing beats MiDaS for early MVP if available

**Status:** Accepted as operational preference

### Decision
When Revit can provide usable depth-like signal via Depth Cueing export, that should be preferred over forcing the pipeline to estimate depth from flat 2D imagery with MiDaS.

### Why
- Better geometric discipline
- Lower ambiguity
- Faster MVP validation
- Uses trusted source environment rather than inferred depth guessing

### Consequence
- MiDaS remains a fallback/research tool, not preferred first-line path when better source signal exists
