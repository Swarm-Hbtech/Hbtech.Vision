# Hbtech.Vision

**Hbtech.Vision** is the project repository for the OC-GD architectural AI visualization pipeline.

## Mission
Build a controllable AI-assisted rendering system for architectural / modular-house workflows that bridges:
- BIM / Revit design sources
- deterministic control signals (depth / geometry / scale)
- AI render core
- future commercial packaging layers

## Current status
Project is in **pre-architecture / MVP definition** stage.
The current confirmed focus is:
- define MVP-1 render core boundary
- collect research
- build roadmap
- preserve open questions

## Canonical documents
- `planning/ROADMAP.md` — approved roadmap v3.1
- `planning/MVP-1-SPEC-DRAFT.md` — staged engineering brief draft
- `research/oc-gd-overview.md` — synthesized overview
- `research/oc-gd-open-questions.md` — unresolved questions
- `research/archive/` — imported historical research notes

## MVP-1 boundary
MVP-1 is an isolated black-box render core:
- input: control image + JSON prompt/settings
- output: Preview + Final architectural render

Excluded from MVP-1:
- UI
- Telegram integration
- BOQ / IFC automation
- SEO
- marketplace packaging
- final PDF deliverables
