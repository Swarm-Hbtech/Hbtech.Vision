# OC-GD Architecture Design v1.0

**Created:** 2026-04-17 20:28 UTC  
**Model:** Claude Opus 4.6 (reasoning mode)  
**Owner:** Igor Dvoretskiy / ООО "Технологии Домостроения"

---

## Executive Summary

**Goal:** Build open-source photorealistic rendering pipeline for architectural projects that:
1. Generates marketing visuals from CAD files (DWG/FBX)
2. Maintains geometric accuracy (>95%)
3. Costs 10x less than Veras ($0.03-0.20 vs $0.50+ per render)
4. Integrates with Gamacchi workflow
5. Runs on RunPod Serverless GPU

**Philosophy:** AI-assisted rendering, not AI-generated architecture. Geometry comes from Revit (trusted), AI adds photorealism.

---

## System Architecture

### High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        OC-GD Pipeline                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Input      │────▶│ Preprocessing│────▶│  AI Render   │
│   (CAD)      │     │  (Geometry)  │     │   (GPU)      │
└──────────────┘     └──────────────┘     └──────────────┘
│                    │                    │
├─ DWG/DXF          ├─ Depth maps        ├─ SDXL base
├─ FBX/OBJ          ├─ Normal maps       ├─ ControlNet
├─ PNG plans        ├─ Edge detection    ├─ IP-Adapter
└─ Material specs   └─ Scale anchors     └─ LoRA models
                              │
                              ▼
                    ┌──────────────┐
                    │Postprocessing│
                    │  (Quality)   │
                    └──────────────┘
                              │
                              ▼
                    ┌──────────────┐
                    │   Output     │
                    │  (4K PNG)    │
                    └──────────────┘
                    │
                    ├─ 4K renders
                    ├─ Metadata JSON
                    ├─ Material list
                    └─ Camera info
```

---

## Component Design

### 1. Input Handler

**Responsibility:** Parse and validate CAD files

**Supported Formats:**
- **2D:** DWG, DXF, PNG (floor plans, elevations)
- **3D:** FBX, OBJ, SAT/ACIS (geometry + materials)
- **Metadata:** IFC (BIM data), JSON (material specs)

**Validation:**
- Scale detection (find reference dimension)
- Unit conversion (mm → meters)
- Completeness check (walls, openings, furniture)
- Material mapping verification

**Output:**
- Normalized geometry (meters, origin-centered)
- Material assignments (diffuse, roughness, metallic)
- Camera positions (auto-calculated or specified)
- Scale metadata (for downstream accuracy)

**Technology:**
- **DWG parsing:** ezdxf (Python) or LibreCAD headless
- **FBX parsing:** Blender Python API
- **Validation:** Custom heuristics + LLM verification (Opus checks completeness)

---

### 2. Preprocessing Engine

**Responsibility:** Convert geometry to AI control signals

**Pipeline:**

```
CAD Geometry
    │
    ├─ 2D Path (DWG/PNG)
    │  ├─ Rasterize to PNG (scale-accurate)
    │  ├─ Canny edge detection
    │  ├─ Semantic segmentation (walls/windows/doors)
    │  └─ Depth estimation (MiDaS v3)
    │
    └─ 3D Path (FBX)
       ├─ Blender headless render
       ├─ Depth pass (Z-buffer)
       ├─ Normal pass (surface normals)
       ├─ Mask pass (object IDs)
       └─ Material pass (base color)
```

**Key Innovation: Scale Anchors**

Problem: AI models don't understand metric scale.

Solution:
1. Embed scale reference in control image (e.g., "5m wall" annotation)
2. Train LoRA on scale-aware dataset
3. Post-process verification: measure rendered objects against known dimensions

**Output:**
- Control images (1024x1024 or 2048x2048)
- Depth map (grayscale, 16-bit)
- Normal map (RGB, tangent space)
- Edge map (binary)
- Prompt embedding (text description)

---

### 3. AI Rendering Core

**Model Stack:**

```
Base Model: SDXL 1.0 Turbo (fast inference)
    │
    ├─ ControlNet Depth (architectural geometry)
    ├─ ControlNet Canny (precise edges)
    ├─ ControlNet Normal (surface lighting)
    │
    ├─ IP-Adapter (style consistency across views)
    │
    └─ LoRA fine-tunes:
       ├─ architectural-realistic-v2 (lighting, materials)
       ├─ scale-aware-architecture (metric understanding)
       └─ russian-residential (local construction styles)
```

**Multi-Conditioning Strategy:**

Instead of single ControlNet, use weighted blend:
- Depth: 0.6 (primary geometry)
- Canny: 0.3 (edge precision)
- Normal: 0.4 (surface detail)
- IP-Adapter: 0.7 (style consistency)

**Prompt Engineering:**

Template:
```
"Photorealistic architectural rendering, {room_type}, {style}, 
professional photography, natural lighting, 4K, sharp focus, 
detailed materials: {material_list}, 
scale reference: {dimensions}"

Negative: cartoon, sketch, watercolor, distorted, blurry, 
low quality, incorrect proportions
```

**Inference Parameters:**
- Steps: 30 (SDXL Turbo allows fewer)
- CFG Scale: 7.5
- Sampler: DPM++ 2M Karras
- Resolution: 1024x1024 → upscale to 4K (Real-ESRGAN)

---

### 4. Postprocessing & QA

**Quality Checks:**

1. **Geometric Accuracy (>95% target)**
   - Measure key dimensions in render
   - Compare against CAD ground truth
   - Flag deviations >5%

2. **Material Correctness**
   - Check specified materials visible
   - Verify color accuracy (LAB space)
   - Detect AI hallucinations (e.g., added furniture)

3. **Photorealism Score**
   - CLIP image quality score
   - Human evaluation (future: A/B testing)

**Refinement Loop:**

If accuracy <95%:
1. Adjust ControlNet weights
2. Regenerate with stricter geometry guidance
3. Apply inpainting to fix specific areas

**Output Packaging:**

```json
{
  "render_id": "uuid",
  "source_file": "project_123.dwg",
  "mode": "layout_to_render",
  "timestamp": "2026-04-17T20:30:00Z",
  "resolution": "4096x4096",
  "accuracy_score": 0.97,
  "materials": [
    {"name": "brick_red", "coverage": 0.6, "accuracy": 0.95},
    {"name": "wood_oak", "coverage": 0.3, "accuracy": 0.92}
  ],
  "camera": {
    "position": [0, 1.6, -5],
    "target": [0, 1.6, 0],
    "fov": 60
  },
  "cost_usd": 0.032,
  "generation_time_s": 125
}
```

---

## Three Operating Modes (Detailed)

### Mode 1: Layout → Render (2D to 3D)

**Use Case:** Floor plan → interior visualization

**Input:**
- DWG floor plan (walls, doors, windows)
- Material specifications (JSON or text)
- Style reference (optional image)

**Process:**
1. Parse DWG → extract room boundaries
2. Semantic segmentation → identify room type
3. Generate depth map (pseudo-3D from 2D)
4. ControlNet Depth + Canny → render interior
5. Apply style via IP-Adapter
6. Upscale to 4K

**Output:**
- Photorealistic interior render
- View: eye-level (1.6m height), looking into room

**Time:** ~2 minutes  
**Cost:** $0.03 per render

**Accuracy Target:** 92-95% (harder from 2D, some interpretation needed)

---

### Mode 2: 3D Model → Multi-View Render

**Use Case:** FBX model → exterior views (N/S/E/W) + aerial

**Input:**
- FBX with geometry + materials
- Lighting conditions (time of day, season)
- Environment (urban, rural, empty lot)

**Process:**
1. Import FBX to Blender
2. Generate 5 camera angles:
   - North elevation (front)
   - South elevation (back)
   - East elevation (side)
   - West elevation (side)
   - Aerial (45° angle, 20m altitude)
3. For each view:
   - Blender renders depth + normal + material
   - Feed to SDXL + ControlNet
   - Add environment (sky, ground, context buildings)
4. Style consistency via IP-Adapter across all 5 views

**Output:**
- 5 x 4K PNG renders
- Consistent style and lighting
- Accurate geometry from all angles

**Time:** ~5 minutes per view = 25 minutes total  
**Cost:** ~$0.07 per view = $0.35 total

**Accuracy Target:** 96-98% (strong 3D geometry guidance)

---

### Mode 3: Style Transfer with Material Variations

**Use Case:** Generate multiple facade options with different materials

**Input:**
- Base 3D model (from Mode 2)
- Material catalog (brick, wood, stucco, etc.)
- Style references (modern, traditional, minimalist)

**Process:**
1. Load base geometry (fixed)
2. For each material combination:
   - Update Blender material assignments
   - Render material pass
   - Apply via ControlNet + IP-Adapter
   - Maintain geometric consistency
3. Generate grid view (3x3 material combinations)

**Output:**
- 9 variations (3 facades × 3 styles)
- Side-by-side comparison
- Client can choose preferred option

**Time:** ~15 minutes (parallel generation)  
**Cost:** ~$0.20 per set

**Use Case:** Present client with options before construction

---

## Technology Stack

### Software Components

| Component | Technology | Version | Purpose |
|-----------|-----------|---------|---------|
| Base Model | SDXL 1.0 Turbo | latest | Fast inference |
| ControlNet | Multi-ControlNet | v1.1 | Geometry guidance |
| Upscaler | Real-ESRGAN | x4 | 1K → 4K |
| 3D Engine | Blender | 4.0+ | FBX processing |
| CAD Parser | ezdxf | latest | DWG reading |
| Depth Est. | MiDaS v3 | DPT-Large | 2D → depth |
| Segmentation | SAM | vit_h | Object masks |
| Backend | FastAPI | 0.110+ | REST API |
| Queue | Celery + Redis | latest | Async tasks |
| Storage | MinIO | latest | S3-compatible |

### Hardware Requirements

**Development:**
- GPU: RTX 4090 (24GB VRAM) or A40
- RAM: 32GB+
- Storage: 500GB SSD

**Production (RunPod Serverless):**
- GPU: A40 (48GB VRAM) or A100
- Billing: pay-per-second
- Auto-scaling: 0 → N instances
- Cost: ~$0.40/hour A40 (only while rendering)

---

## RunPod Integration Architecture

### Container Structure

```dockerfile
FROM nvidia/cuda:12.1.0-runtime-ubuntu22.04

# Python 3.11 + dependencies
RUN apt-get update && apt-get install -y \
    python3.11 python3-pip \
    libgl1 libglib2.0-0 \
    blender \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
COPY requirements.txt /app/
RUN pip3 install -r /app/requirements.txt

# Download models (baked into image for fast cold start)
RUN python3 -c "
from diffusers import StableDiffusionXLPipeline, ControlNetModel
pipe = StableDiffusionXLPipeline.from_pretrained('stabilityai/sdxl-turbo')
cnet = ControlNetModel.from_pretrained('lllyasviel/control_v11p_sd15_canny')
"

COPY src/ /app/src/
WORKDIR /app

CMD ["python3", "src/runpod_handler.py"]
```

### API Endpoint

```python
# runpod_handler.py
import runpod
from src.pipeline import OCGDPipeline

pipeline = OCGDPipeline()  # Load models once

def handler(event):
    """
    Input:
    {
        "mode": "layout_to_render",
        "input_url": "https://s3.../plan.dwg",
        "materials": {"walls": "brick", "roof": "tile"},
        "style": "modern",
        "output_format": "png"
    }
    
    Output:
    {
        "render_url": "https://s3.../output.png",
        "metadata_url": "https://s3.../meta.json",
        "accuracy": 0.96,
        "cost": 0.032,
        "time_s": 127
    }
    """
    mode = event["input"]["mode"]
    input_url = event["input"]["input_url"]
    
    # Download input
    input_path = download_file(input_url)
    
    # Run pipeline
    result = pipeline.render(
        mode=mode,
        input_path=input_path,
        **event["input"]
    )
    
    # Upload output
    output_url = upload_to_s3(result.image_path)
    meta_url = upload_to_s3(result.metadata_path)
    
    return {
        "render_url": output_url,
        "metadata_url": meta_url,
        "accuracy": result.accuracy_score,
        "cost": result.cost_usd,
        "time_s": result.generation_time
    }

runpod.serverless.start({"handler": handler})
```

### Deployment

```bash
# Build image
docker build -t oc-gd:v1 .

# Push to RunPod registry
docker tag oc-gd:v1 registry.runpod.io/username/oc-gd:v1
docker push registry.runpod.io/username/oc-gd:v1

# Create serverless endpoint
runpod create endpoint \
  --name oc-gd-render \
  --image registry.runpod.io/username/oc-gd:v1 \
  --gpu-type "NVIDIA A40" \
  --min-workers 0 \
  --max-workers 10 \
  --timeout 300
```

---

## Gamacchi Integration

### API Endpoint (Local Server)

```python
# /opt/oc-gd-service/api.py
from fastapi import FastAPI, UploadFile
import requests

app = FastAPI()

RUNPOD_ENDPOINT = "https://api.runpod.ai/v2/oc-gd-render/run"
RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY")

@app.post("/api/render")
async def create_render(
    file: UploadFile,
    mode: str = "layout_to_render",
    materials: dict = {},
    style: str = "modern"
):
    """
    Client uploads DWG/FBX → we send to RunPod → return render URL
    """
    # Upload to S3
    input_url = upload_to_s3(file)
    
    # Call RunPod
    response = requests.post(
        RUNPOD_ENDPOINT,
        headers={"Authorization": f"Bearer {RUNPOD_API_KEY}"},
        json={
            "input": {
                "mode": mode,
                "input_url": input_url,
                "materials": materials,
                "style": style
            }
        }
    )
    
    job_id = response.json()["id"]
    
    # Poll for completion (or use webhook)
    result = poll_job(job_id)
    
    return {
        "render_url": result["output"]["render_url"],
        "metadata": result["output"]["metadata_url"],
        "cost": result["output"]["cost"]
    }
```

### Telegram Bot Commands

```javascript
// /opt/gamacchi-prod/index.js

bot.onText(/\/render (.+)/, async (msg, match) => {
    const chatId = msg.chat.id;
    
    bot.sendMessage(chatId, "⏳ Загрузите DWG файл планировки...");
    
    // Wait for file upload
    bot.once('document', async (fileMsg) => {
        const fileId = fileMsg.document.file_id;
        const file = await bot.getFile(fileId);
        
        // Download from Telegram
        const fileUrl = `https://api.telegram.org/file/bot${token}/${file.file_path}`;
        
        // Send to OC-GD service
        const result = await axios.post('http://localhost:8080/api/render', {
            input_url: fileUrl,
            mode: 'layout_to_render',
            style: 'modern'
        });
        
        bot.sendPhoto(chatId, result.data.render_url, {
            caption: `✅ Визуализация готова!\n\nСтоимость: ${result.data.cost} USD\nВремя: ${result.data.time}с`
        });
    });
});
```

---

## Cost Analysis

### Per-Render Economics

| Mode | Time | GPU Cost | Total Cost | Official (Veras) | Savings |
|------|------|----------|------------|------------------|---------|
| Layout → Render | 2 min | $0.013 | **$0.03** | $0.50 | 94% |
| 3D Multi-view (5) | 25 min | $0.167 | **$0.35** | $2.50 | 86% |
| Style Transfer (9) | 15 min | $0.100 | **$0.20** | $1.50 | 87% |

**Monthly Cost Estimate (100 projects):**

Assume per project:
- 1 layout render
- 5 exterior views
- 2 style variations

Total: 800 renders/month

Cost: **$11-12/month** (vs Veras $200-400/month minimum)

**ROI:** 95% cost reduction + full control + customization

---

## Quality Benchmarks

### Target Metrics

| Metric | Target | How Measured |
|--------|--------|--------------|
| Geometric Accuracy | >95% | Measure key dimensions |
| Material Accuracy | >90% | Color diff (LAB) |
| Photorealism | CLIP >0.75 | CLIP similarity to real photos |
| Generation Speed | <3 min | End-to-end |
| Consistency (multi-view) | >92% | IP-Adapter similarity |

### Comparison vs Veras

| Aspect | OC-GD | Veras |
|--------|-------|-------|
| Geometric Accuracy | 95%+ | ~92.5% |
| Cost | $0.03-0.35 | $0.50+ |
| Speed | 2-5 min | ~5-10 min |
| Customization | Full control | Limited "magic" slider |
| Material Library | Unlimited (custom LoRA) | Pre-defined |
| Open Source | Yes | Proprietary |

---

## Development Phases

### Phase 1: MVP (Week 1-2)

**Goal:** Single mode working end-to-end

**Deliverables:**
- Mode 1 (Layout → Render) functional
- Basic DWG parsing
- SDXL + ControlNet Depth working
- FastAPI local endpoint
- Telegram bot command `/render`

**Testing:**
- 10 sample floor plans
- Accuracy >90%
- Generation time <5 min

### Phase 2: 3D Pipeline (Week 3)

**Goal:** Add Mode 2 (3D → Multi-view)

**Deliverables:**
- FBX import via Blender
- Multi-angle rendering
- IP-Adapter for style consistency
- Batch processing

**Testing:**
- 5 sample 3D models
- 5 views per model
- Consistency score >90%

### Phase 3: RunPod Deployment (Week 4)

**Goal:** Production-ready serverless

**Deliverables:**
- Docker container
- RunPod endpoint configured
- Webhook for async results
- S3 storage integration

**Testing:**
- Load test (10 concurrent requests)
- Cold start <30s
- Cost validation

### Phase 4: Gamacchi Integration (Week 5)

**Goal:** Seamless workflow

**Deliverables:**
- Telegram bot `/render` command
- Web interface for render gallery
- Admin panel for render queue
- Billing/usage tracking

**Testing:**
- End-to-end user journey
- 20 real projects

---

## Risk Mitigation

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Geometric accuracy <95% | High | Medium | Multi-ControlNet, iterative refinement |
| AI hallucinations | Medium | High | Strict ControlNet weights, validation |
| Slow generation | Medium | Low | SDXL Turbo, RunPod GPUs |
| High cost | High | Low | Serverless = pay only when used |
| Model availability | Low | Low | Open-source models, local hosting option |

### Business Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Client expectations too high | Medium | Set realistic 95% accuracy target, show samples |
| Veras price drop | Low | Our cost is 10x lower, room for competition |
| Regulatory (AI copyright) | Low | Input geometry from Revit (owned), AI just renders |

---

## Success Criteria

**Technical:**
✅ 95%+ geometric accuracy  
✅ <3 min generation time  
✅ $0.03-0.35 cost per render  
✅ 10 concurrent requests supported

**Business:**
✅ 50+ projects visualized  
✅ Positive client feedback  
✅ Cost savings validated ($11 vs $200/month)  
✅ Integration with Gamacchi seamless

**Stretch Goals:**
🎯 Train custom LoRA on Russian residential styles  
🎯 Video fly-through (4D: 3D + time)  
🎯 VR export for client walk-through  
🎯 Real-time preview (lower quality, instant feedback)

---

## Next Steps (Immediate)

1. **Set up development environment** (1 hour)
   - Install SDXL, ControlNet, Blender
   - Test on RTX 4090 or rent A40 on RunPod

2. **Download sample CAD files** (30 min)
   - 5 DWG floor plans
   - 3 FBX 3D models
   - Prepare test dataset

3. **Build MVP pipeline** (Day 1-3)
   - DWG → PNG → ControlNet → SDXL → 4K
   - Measure accuracy on test set

4. **Create RunPod container** (Day 4-5)
   - Dockerfile with all dependencies
   - Test cold start time
   - Deploy to RunPod serverless

5. **Integrate with Gamacchi** (Day 6-7)
   - FastAPI endpoint
   - Telegram bot command
   - First real render for client

---

**Status:** Architecture complete. Ready to start Phase 1 MVP.

**Estimated Total Development Time:** 5-6 weeks (one developer, part-time)

**Estimated Total Cost:**
- Development GPU: $100-200 (RunPod rental)
- Production (first month): $20-30 (100 projects)

**Expected ROI:** 10x cost savings vs Veras, full customization, IP ownership

---

**Approved by:** Igor Dvoretskiy  
**Next Action:** Start Phase 1 MVP tomorrow after Hetzner migration

🎨 **OC-GD: Open-source visualization pipeline for Технологии Домостроения!**
