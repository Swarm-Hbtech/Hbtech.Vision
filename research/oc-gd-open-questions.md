# OC-GD Open Questions

**Updated:** 2026-04-30 13:18 UTC
**Mode:** Parallel pre-architecture session
**Purpose:** Collect unresolved questions and non-final decisions while Igor continues loading source materials and Gemini discussion.

---

## 1. MVP Boundary

### Q1. What is the first commercially useful OC-GD output that must work reliably?
Candidate directions:
- single photoreal exterior render from Revit view
- batch marketplace card generation
- material-accurate facade pack
- operator review UI with HITL
- unified report: render + BOQ + cost estimate

### Q2. What is explicitly **out of scope** for MVP-1?
We need a hard boundary to avoid building the whole factory at once.

---

## 2. Source of Truth / Input Strategy

### Q3. What is the canonical primary source for geometry in MVP-1?
Options currently on the table:
- Revit API / pyRevit
- Revit MCP
- IFC export + IfcOpenShell
- glTF export
- hybrid split by responsibility

### Q4. Do we treat IFC as:
- semantic lane only,
- semantic + BOQ lane,
- or also a fallback geometry lane?

### Q5. What is the canonical visual lane for GPU pipeline?
Strong candidate: glTF + raster/control maps.
Still not fully frozen.

---

## 3. Revit / Lumion / Depth Truth

### Q6. Can Revit export true depth maps directly in a stable automated way?

### Q7. If not, can the workflow reliably use:
Revit → FBX → Lumion → real Z-depth export?

### Q8. If real depth is available, is it mandatory for MVP-1 or an enhancement for MVP-2?

### Q9. What other auxiliary passes can be exported reliably from current toolchain?
- depth
- normals
- hidden line
- shadow
- material pass
- object masks

---

## 4. Scale / Control / Preprocessing

### Q10. Should the 1x1x1m reference cube become a required invariant in the pipeline?

### Q11. Do we need a **single** scale cube or **dual cubes** at different depths for perspective conditioning?

### Q12. Should scale tags be embedded in image pixels, passed in prompt text, or both?

### Q13. What is the sweet spot for line thickening before rasterization?
Candidates mentioned:
- 0.3 mm
- 0.5 mm
- 0.7 mm

### Q14. Which preprocessing artifacts are mandatory in MVP-1?
Candidates:
- thicker lines
- noise cleanup
- depth
- MLSD / Canny
- AO / shadow cueing
- text tags
- material hints

### Q15. Should shadows/AO be part of mandatory control stack or deferred until after basic geometry success is proven?

---

## 5. Generative Core

### Q16. Is FLUX.2 the primary generator for MVP-1, or only the primary candidate?

### Q17. What exact role does SDXL play?
Options:
- fallback branch
- preview branch
- budget branch
- special stylization branch

### Q18. Does preview mode use:
- LCM over SDXL,
- SDXL Turbo,
- FLUX preview variant,
- or a hybrid routing strategy?

### Q19. What is the acceptable quality delta between preview and final?

---

## 6. Material Consistency

### Q20. What is the first-level strategy for material fidelity?
Candidates:
- prompt only
- IP-Adapter Plus
- native multi-reference FLUX
- custom LoRA
- hybrid

### Q21. At what point do we escalate from dynamic references to custom LoRA training?

### Q22. Do we already have enough high-quality portfolio / material imagery to support LoRA or reference library creation?

### Q23. Are material names/catalogs already normalized enough for AI mapping, or does that require a dedicated cleanup phase?

---

## 7. BOQ / Cost / Unified Deliverable

### Q24. Is BOQ generation part of MVP-1 or MVP-2?

### Q25. Is the target commercial artifact eventually:
- image set only,
- image set + SEO,
- render + BOQ,
- or unified PDF commercial proposal?

### Q26. Does price catalog infrastructure already exist in a form usable for automated cost estimation?
If yes: where does it live?

### Q27. For client delivery, which format matters most first?
- PDF
- Excel
- JSON internal only
- marketplace cards only

---

## 8. UI / HITL / User Persona

### Q28. Who is the first real operator persona?
- architect
- marketer
- sales manager
- Igor personally
- mixed role

### Q29. Is Streamlit the final operator UI, or just the fastest first control surface?

### Q30. What exact HITL gates are mandatory?
At minimum likely:
- preview approve / reject
- final approve / reject
But this still needs formalization.

### Q31. Is Telegram `/render` considered:
- a test/debug interface,
- a real operational interface,
- or just an auxiliary quick-access control path?

---

## 9. Site Context / Aesthetic Context

### Q32. For backgrounds and environmental context, what is preferred first?
- generic context
- project-type templates
- site-specific context
- geolocation-driven context

### Q33. Do we have site plans / coordinates / neighboring-building context often enough to productize this early?

### Q34. Are curved/organic forms genuinely out of scope for the foreseeable path, allowing pipeline optimization around rectilinear architecture?
Current indication: mostly yes, but should be confirmed as a product assumption.

---

## 10. Russian Market / Style Localization

### Q35. Do we need a dedicated Russian residential style LoRA in MVP-1, or can we postpone until after structural reliability is solved?

### Q36. What are the canonical local material/style clusters we should model first?
Examples mentioned implicitly:
- brick
- siding
- metal roof
- prefab / modular aesthetics

### Q37. Is authenticity to local market more important than raw photorealism in the first release?

---

## 11. Compute / Deployment

### Q38. Is RunPod just the leading candidate, or do we want a formal compute bake-off before locking it in?

### Q39. Which parts should run where in the long run?
- Revit-side preprocessing
- local Python preprocessing
- serverless GPU inference
- postprocessing / infographic composition

### Q40. What are the hard business constraints on:
- per-render cost
- cold-start tolerance
- preview latency
- final render latency

---

## 12. Decision Hygiene

### Q41. Which currently attractive ideas must be treated as **strong hypotheses**, not final decisions?
Current list includes:
- Revit MCP as primary bridge
- FLUX.2 as final main model
- RunPod as final compute layer
- Streamlit as final UI
- Skia/html2pic-like composition as final infographic engine
- BOQ inside MVP-1

---

## 13. Strong hypotheses already emerging

These are **not fully frozen**, but currently have strong support:
- split semantics and visual geometry into separate lanes
- preserve geometry with deterministic controls, not prompt-only magic
- HITL is mandatory
- thicker lines / input cleanup likely matter a lot
- true depth maps could be a major quality breakthrough
- preview/final dual-tier render flow likely improves economics and usability
- BOQ from IFC is strategically attractive

---

## 14. Operating note for this session

At this stage we are still:
- collecting source material
- recovering earlier engineering insights
- reconciling Gemini, Opus, Igor, and archived research

Therefore:
**do not cement implementation decisions prematurely.**

Next safe step after more source loading:
1. cluster stable decisions vs open questions
2. choose MVP-1 explicitly
3. draft roadmap from chosen MVP boundary
