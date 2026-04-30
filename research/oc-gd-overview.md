# OC-GD Overview

**Created:** 2026-04-30 13:05 UTC
**Owner:** Igor Dvoretskiy
**Track:** Parallel pre-architecture session
**Source batch:** Research note — "Исследование оптимальной архитектуры Модуля AI-визуализации для Autodesk Revit"

---

## 1. What OC-GD is

**OC-GD** is a proposed AI visualization module for the AEC domain, centered on Autodesk Revit and intended to bridge:
- deterministic BIM models
- probabilistic image generation pipelines
- downstream marketing content generation for marketplaces

In practical terms, OC-GD aims to turn structured BIM/project data into:
- photorealistic architectural renders
- controlled marketing visuals
- SEO-ready product descriptions
- infographic-rich marketplace cards

---

## 2. Core product hypothesis

OC-GD should not be treated as “just an image generator”.
It is a **multi-stage production pipeline** that transforms Revit/BIM inputs into commercially usable visual and textual assets.

### The hypothesized value chain
1. Extract geometry + metadata from Revit
2. Build control layers for deterministic visual generation
3. Run AI render pipeline with structural constraints
4. Keep material/style consistency across output sets
5. Post-process outputs for marketplace formats
6. Generate SEO text + infographic overlays
7. Deliver operator-approved final assets

---

## 3. Strategic problem it solves

### Market problem
In modular / prefab / house-project commerce, visual presentation is a direct conversion lever.
The bottleneck is that BIM systems are structured and exact, while diffusion models are flexible but error-prone.

### OC-GD target
OC-GD aims to close this gap by creating a controlled architecture where:
- geometry remains trustworthy
- materials remain consistent
- camera framing remains predictable
- outputs become usable for sales, not just inspiration

---

## 4. Proposed high-level architecture from the research

### 4.1 Revit integration layer
Primary thesis from the source:
- move from classic hardcoded Revit plugin logic toward **Revit MCP** as the long-term orchestration interface
- still use Revit-native capabilities for deterministic extraction and view control

#### Candidate responsibilities
- open and activate target Revit view
- query scene / elements / parameters
- export views as raster base layers
- extract metadata for prompt/SEO generation
- extract camera parameters for perspective synchronization

### 4.2 Geometry / semantics split
The source strongly suggests a **hybrid export strategy**:

- **IFC** → used for semantic / metadata extraction only
- **glTF** → used for lightweight geometry transfer into visualization pipeline
- **FBX** → legacy / less preferred

#### Provisional design implication
OC-GD may need two parallel data lanes:
1. **semantic lane** (IFC / metadata / BIM meaning)
2. **visual lane** (glTF / raster / control maps)

### 4.3 Control-map generation
For deterministic image synthesis, OC-GD should rely on structural control layers such as:
- depth maps
- normal maps
- MLSD / line maps
- HED / soft edge maps

Strong idea from the source:
- generate as much of this as possible **before GPU inference**, ideally leveraging Revit output / graphics pipeline
- this reduces expensive cloud GPU work

### 4.4 Generative core
Research conclusion leans toward:
- **FLUX.2** as primary high-fidelity architectural generation engine
- **SDXL** as fallback / speed / budget branch

#### Why FLUX.2 is favored
- better spatial coherence
- stronger physical understanding
- better text rendering
- better structured prompt adherence

#### Why SDXL still matters
- faster
- mature ecosystem
- broad ControlNet / LoRA support
- useful for cheaper drafts / rapid iteration

### 4.5 Structural constraint layer
OC-GD should not rely on freeform prompting alone.
It likely needs a **ControlNet-governed deterministic path**, with combined control signals such as:
- Depth
- MLSD
- HED / SoftEdge

The source implies that geometry preservation is a non-negotiable requirement.

### 4.6 Material consistency layer
Two main mechanisms are proposed:
- **IP-Adapter Plus** for dynamic style/material transfer
- **custom LoRA** for hard consistency of recurring architectural forms/material systems

Likely future rule:
- use reference-driven methods first
- escalate to custom LoRA when consistency demands exceed prompt/control capabilities

### 4.7 Cloud inference layer
Primary compute candidate from the source:
- **RunPod Serverless**

But important note for our current planning:
- RunPod is still only a **candidate future execution option**, not yet a committed infrastructure decision

Reasoning from source:
- better price/performance balance
- container control
- suitable for ComfyUI graph execution
- supports baked-image strategy to reduce cold starts

### 4.8 Human-in-the-loop layer
A critical architectural point:
OC-GD should not be fully autonomous.

Proposed control pattern:
- operator launches generation
- system generates variants asynchronously
- user reviews results
- explicit approve / regenerate gate
- only approved result moves downstream

This is a classic **HITL** quality gate model.

### 4.9 UI / orchestration layer
The source argues for:
- **Streamlit** over Gradio

Reason:
- better multi-step state handling
- better dashboard / enterprise behavior
- stronger session-state pattern
- more suitable for long-running orchestration with approvals

### 4.10 Downstream marketing layer
OC-GD is expected to include automatic downstream transformation for:
- marketplace image formats
- SEO titles / descriptions / bullets
- infographic overlays

For graphic composition, the source favors an HTML/CSS-to-image approach over raw Pillow for complex layouts.

---

## 5. Candidate product scope

Based on the source, OC-GD may eventually span **four interconnected subsystems**:

### A. BIM extraction subsystem
- Revit integration
- geometry export
- metadata extraction
- camera sync

### B. AI render subsystem
- control maps
- ComfyUI graph execution
- model routing (FLUX.2 / SDXL)
- material consistency

### C. Review / approval subsystem
- operator UI
- HITL checkpoints
- regeneration loop
- final approval state

### D. Commercialization subsystem
- SEO generation
- infographic composition
- marketplace-specific output packaging

---

## 6. Important architectural insight

This source strongly suggests that OC-GD is **not one MVP** in the naive sense.
It is likely a staged system and must be decomposed.

A safe preliminary decomposition could be:
1. controlled render generation from existing Revit views
2. structural consistency and camera sync
3. material consistency
4. operator review workflow
5. marketplace output formatting
6. SEO and infographic automation

---

## 7. What looks strong in this research

### Strong signals
- clear recognition of BIM vs diffusion gap
- good separation between semantics and geometry
- strong emphasis on deterministic control
- recognition that human approval is necessary
- realistic cloud compute thinking
- good focus on business outputs, not just pretty renders

---

## 8. What is still hypothesis, not decision

The following are **not yet final decisions** and should stay provisional:
- Revit 2027 MCP as primary integration contract
- FLUX.2 as definitive main model
- RunPod as chosen compute layer
- Streamlit as final UI framework
- exact composition tool for infographic rendering
- exact split between what is done in Revit vs ComfyUI vs external services

---

## 9. Immediate implications for our roadmap work

This first research batch is enough to justify drafting:
1. `projects/oc-gd-roadmap.md`
2. `projects/oc-gd-architecture.md`
3. `projects/oc-gd-open-questions.md`

It is **not yet enough** to jump directly into detailed stage implementation specs without first defining:
- product boundary
- first MVP
- operator persona
- output types
- acceptable latency/cost
- source of truth for geometry and materials

---

## 10. Preliminary recommendation

Treat OC-GD as a **pipeline product**, not a feature.

Near-term objective:
- narrow OC-GD to a first operational MVP with controlled scope

Suggested first question for next step:
> What is the first commercially useful output that OC-GD must produce reliably?

Candidate answers might be:
- one photoreal exterior render from Revit view
- a batch of marketplace-ready house-card images
- a controlled material-accurate facade pack
- a review UI for architects/marketers

We should decide this before writing stage-by-stage technical specs.
