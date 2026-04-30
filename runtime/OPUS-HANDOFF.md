# Opus Handoff — Hbtech.Vision pre-architecture package

## Current state
Hbtech.Vision remains in **pre-architecture / research** mode. Do not treat this as an active coding order unless Igor explicitly reprioritizes Opus onto this project.

## Locked planning docs
These are the current source docs to trust first:
- `planning/DECISIONS.md`
- `planning/API-CONTRACT-DRAFT.md`
- `planning/TEST-ASSET-SPEC.md`
- `planning/MVP-1-SPEC-DRAFT.md`
- `planning/ROADMAP.md`

### Locked principles already agreed
- MVP-1 = black-box render core only
- Input = control image + JSON payload
- Output = Preview + Final render
- No BOQ / IFC automation in visual MVP core
- No Telegram bot / UI / SEO / PDF packaging in MVP-1
- Fast Path = Revit Depth Cueing export
- Deep Path = glTF-based geometry/control artifact generation
- Human-in-the-loop is mandatory
- Preview/Final split is mandatory
- Base64 is acceptable for testing only; production path should use signed URLs or object storage paths
- First golden dataset batch must keep one fixed Depth Cueing polarity
- At least one A/B test scene is required: with cube / without cube

## What was prepared for future development
A minimal RunPod infra smoke-test pack now exists under `infra/runpod/`:
- `prepare-runpod-smoke-worker.sh`
- `create-runpod-smoke-endpoint.sh`
- `test-runpod-endpoint.sh`

Purpose of this pack:
- validate pure RunPod platform path before any heavy AI image/weights work
- measure cold-ish platform overhead separately from model load time
- avoid false debugging caused by public templates or heavy ComfyUI containers

## Status of RunPod validation
Validated so far:
- Moscow server can reach RunPod over network
- RunPod API key auth works
- account is readable
- account had no existing endpoints/templates/pods at time of check

Not yet durably completed in this session:
- push of smoke worker image to Docker Hub
- creation of smoke template/endpoint
- first measured cold-start run

## What Opus should do later when reprioritized
1. Treat current docs as architectural constraints, not suggestions.
2. Start with the RunPod smoke-test path before building real rendering workers.
3. Only after smoke infra works, design the first real render worker baseline.
4. Keep API contract stable even if internal graph/model stack changes.
5. Do not expand scope into BOQ/IFC/SEO/UI during MVP-1.

## Open execution preconditions
Before Opus starts real implementation on Hbtech.Vision, confirm:
- Igor has reprioritized Opus onto Hbtech.Vision
- first Revit test assets exist
- RunPod smoke-test path has been executed successfully or consciously deferred
