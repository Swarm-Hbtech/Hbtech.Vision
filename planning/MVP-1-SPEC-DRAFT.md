# Hbtech.Vision — MVP-1 Spec Draft

**Status:** Parked engineering brief draft
**Activation rule:** Not active for implementation until Igor explicitly re-prioritizes Opus.Dev into Hbtech.Vision delivery lane.

## Main goal
Create a headless ComfyUI render core that accepts:
- control image
- prompt/settings payload
- mode selector

and returns:
- Preview render
- Final render

## Target JSON contract
```json
{
  "mode": "preview",
  "control_image": "base64_string...",
  "prompt": {
    "style": "modern minimalist",
    "materials": "white stucco, dark wood, black metal window frames",
    "scale_anchor": "1 meter cyan cube present in scene"
  }
}
```

## Stage 1 draft backlog
### 1.1 Baseline graph
- FLUX.2 as primary final-quality candidate
- SDXL / LCM branch as preview/fallback candidate

### 1.2 Scale anchors
- 1x1x1 meter cyan cube logic
- masking / cleanup strategy for final output

### 1.3 Preview/Final contract
- preview for speed and iteration
- final for quality and approval

### 1.4 Deployment dependency pack for Swarm
- custom nodes
- model checkpoints
- VRAM notes
- docker bake requirements

## Expected artifacts
- `workflow_api.json`
- dependency list
- implementation notes
