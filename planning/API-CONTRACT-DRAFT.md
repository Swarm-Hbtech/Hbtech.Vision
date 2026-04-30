# Hbtech.Vision — API Contract Draft

**Status:** Draft  
**Purpose:** Define the black-box contract for MVP-1 render core.

---

## 1. Design goal

The API must allow upstream systems (future CRM, Telegram edge, scripts, dashboard, or manual operator tools) to request architectural renders without knowing internal ComfyUI graph details.

The API contract should remain stable even if graph internals evolve.

---

## 2. MVP-1 request contract

```json
{
  "request_id": "uuid-or-external-id",
  "mode": "preview",
  "control_image": "signed_url_or_object_storage_path_or_base64_for_testing",
  "prompt": {
    "style": "modern minimalist",
    "materials": "white stucco, dark wood, black metal window frames",
    "scene": "detached modular house, exterior, eye-level perspective",
    "lighting": "soft daylight",
    "negative": "distorted geometry, extra windows, wrong proportions, blurry output",
    "scale_anchor": "1 meter cyan cube present in scene"
  },
  "options": {
    "aspect_ratio": "16:9",
    "seed": 123456,
    "return_intermediates": false,
    "target_resolution": "preview"
  },
  "meta": {
    "source_system": "manual-test",
    "source_project_id": "optional-project-id",
    "source_view_id": "optional-view-id"
  }
}
```

---

## 3. Required request fields

### `request_id`
Unique external correlation id.

### `mode`
Allowed values:
- `preview`
- `final`

Any other value must be rejected with `UNSUPPORTED_MODE`.

### `control_image`
MVP-1 accepts one control input.

Allowed forms:
- signed URL (**preferred for production**)
- internal object-storage path (**preferred for production**)
- base64 string (**allowed for testing, not preferred for production**)

Production priority should be:
1. signed URL
2. object-storage path
3. base64 only for local/manual testing

### `prompt`
Must include structured text fields rather than one opaque mega-prompt where possible.

Minimum expected fields:
- `style`
- `materials`
- `scene`
- `lighting`
- `negative`
- `scale_anchor`

---

## 4. Optional request fields

### `options.aspect_ratio`
Examples:
- `1:1`
- `3:4`
- `16:9`
- `4:3`

### `options.seed`
Allows reproducibility when needed.

### `options.return_intermediates`
If true, future versions may return preview artifacts / masks / metadata.
For MVP-1, may remain ignored.

### `options.target_resolution`
Examples:
- `preview`
- `1024`
- `2048`
- `4k`

---

## 5. MVP-1 response contract

```json
{
  "request_id": "uuid-or-external-id",
  "status": "completed",
  "mode": "preview",
  "result": {
    "image_url": "https://...",
    "artifact_type": "image",
    "output_format": "png",
    "width": 1024,
    "height": 576,
    "seed": 123456
  },
  "metrics": {
    "generation_time_s": 18.4,
    "estimated_cost_usd": 0.03,
    "model_family": "sdxl-lcm"
  },
  "debug": {
    "graph_version": "mvp1-preview-r1",
    "notes": []
  }
}
```

---

## 6. Error response contract

```json
{
  "request_id": "uuid-or-external-id",
  "status": "failed",
  "error": {
    "code": "VRAM_OOM",
    "message": "Preview branch exceeded available VRAM",
    "retryable": true
  }
}
```

Suggested error codes:
- `INVALID_PAYLOAD`
- `UNSUPPORTED_MODE`
- `CONTROL_IMAGE_FETCH_FAILED`
- `VRAM_OOM`
- `MODEL_NOT_AVAILABLE`
- `GRAPH_EXECUTION_FAILED`
- `TIMEOUT`

---

## 7. Preview vs Final semantic contract

### Preview mode
Goal:
- fast composition check
- cheap iteration
- enough quality for human decision making

Target characteristics:
- < 20 seconds ideal
- lower resolution acceptable
- lower fidelity acceptable
- must preserve major geometry and lighting intent

### Final mode
Goal:
- approval-grade architectural render
- higher realism
- stronger material fidelity

Target characteristics:
- slower execution acceptable
- better geometry/material fidelity
- suitable for future downstream packaging

---

## 8. Non-goals for MVP-1 API

Do not include in initial API contract:
- BOQ output
- SEO fields
- infographic fields
- marketplace publishing fields
- Telegram-specific transport fields

Those belong to future layers, not render-core contract.

---

## 9. Future extension points

Reserved future request fields may include:
- `reference_images[]`
- `camera`
- `environment`
- `brand_template`
- `boq_profile_id`
- `marketplace_profile`
- `output_bundle`

These should not be implemented prematurely in MVP-1, but the contract should be designed so they can be added without breaking consumers.
