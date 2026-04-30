# OC-GD: Direct Revit File Integration Research

**Created:** 2026-04-17 21:09 UTC  
**Model:** Claude Opus 4.6 (deep technical analysis)  
**Task:** Investigate using Revit files (.rvt) directly for:
1. Visual rendering (source for AI generation)
2. Material extraction & quantity takeoff (BIM data)

---

## Executive Summary

**Goal:** Bypass intermediate exports (DWG/FBX) → work directly with native Revit files

**Benefits:**
- **Single source of truth** (no export drift)
- **Rich BIM data** (materials, quantities, costs)
- **Parametric updates** (change in Revit → auto-regenerate renders)
- **Automated BOQ** (Bill of Quantities) from same file used for visuals

**Challenges:**
- Revit files are proprietary binary format
- No direct Python/open-source parser
- Requires Revit API or third-party tools

**Verdict:** **Feasible with Revit API + pyRevit**, or **IFC as open alternative**

---

## Aspect 1: Revit as Visual Source (Исходник для визуала)

### Current Workflow (Intermediate Export)

```
Revit (.rvt) 
    ↓
Export DWG/FBX
    ↓
OC-GD Pipeline
    ↓
Render
```

**Problems:**
- Manual export step
- Version drift (Revit updated, export outdated)
- Loss of metadata (materials, room names, etc.)

---

### Proposed: Direct Revit Integration

```
Revit (.rvt)
    ↓
Revit API (pyRevit)
    ↓
Extract:
  - 3D geometry (vertices, faces)
  - Camera views (floor plans, elevations, 3D)
  - Materials (textures, colors, properties)
  - Annotations (room names, dimensions)
    ↓
OC-GD Pipeline (no manual export!)
    ↓
Render
```

---

### Technology Options

#### Option A: Revit API + pyRevit (Recommended)

**What is Revit API?**
- Official Autodesk API for Revit automation
- Access to full BIM database
- C# / Python (via pyRevit)

**What is pyRevit?**
- Open-source Python wrapper for Revit API
- Runs Python scripts inside Revit
- Community-supported, actively developed

**Installation:**
```bash
# 1. Install pyRevit
# Download from: https://github.com/eirannejad/pyRevit
# Run installer → installs into Revit

# 2. Access Revit API from Python
from pyrevit import revit, DB
from Autodesk.Revit.DB import *
```

**Extract Geometry:**

```python
# Script runs inside Revit via pyRevit
from pyrevit import revit, DB

def export_geometry_for_ocgd(revit_file_path):
    """
    Extract 3D geometry from Revit model
    
    Output: OBJ file + material mapping JSON
    """
    doc = revit.doc  # Current Revit document
    
    # Get all 3D elements (walls, floors, roofs, etc.)
    collector = DB.FilteredElementCollector(doc)
    elements = collector.OfCategory(DB.BuiltInCategory.OST_Walls) \
                       .WhereElementIsNotElementType() \
                       .ToElements()
    
    geometry_data = []
    
    for element in elements:
        # Get geometry
        geom_element = element.get_Geometry(DB.Options())
        
        for geom_obj in geom_element:
            if isinstance(geom_obj, DB.Solid):
                # Extract vertices and faces
                for face in geom_obj.Faces:
                    mesh = face.Triangulate()
                    
                    vertices = []
                    for i in range(mesh.NumTriangles):
                        triangle = mesh.get_Triangle(i)
                        vertices.extend([
                            (triangle.get_Vertex(0).X, 
                             triangle.get_Vertex(0).Y, 
                             triangle.get_Vertex(0).Z),
                            (triangle.get_Vertex(1).X, 
                             triangle.get_Vertex(1).Y, 
                             triangle.get_Vertex(1).Z),
                            (triangle.get_Vertex(2).X, 
                             triangle.get_Vertex(2).Y, 
                             triangle.get_Vertex(2).Z)
                        ])
                    
                    # Get material
                    material_id = face.MaterialElementId
                    material = doc.GetElement(material_id)
                    
                    geometry_data.append({
                        'element_id': element.Id.IntegerValue,
                        'category': element.Category.Name,
                        'vertices': vertices,
                        'material': material.Name if material else 'Default'
                    })
    
    # Export to OBJ format (compatible with Blender)
    export_to_obj(geometry_data, 'revit_model.obj')
    
    return geometry_data
```

**Extract Camera Views:**

```python
def export_views_for_rendering(doc):
    """
    Extract all floor plans, elevations, 3D views
    
    Output: PNG images + camera parameters
    """
    views = DB.FilteredElementCollector(doc) \
              .OfClass(DB.View) \
              .ToElements()
    
    exported_views = []
    
    for view in views:
        if view.ViewType in [DB.ViewType.FloorPlan, 
                              DB.ViewType.Elevation,
                              DB.ViewType.ThreeD]:
            
            # Export view as PNG (Revit can render internally)
            image_options = DB.ImageExportOptions()
            image_options.ZoomType = DB.ZoomFitType.FitToPage
            image_options.PixelSize = 2048  # High-res
            image_options.FilePath = f"view_{view.Name}.png"
            image_options.FitDirection = DB.FitDirectionType.Horizontal
            
            doc.ExportImage(image_options)
            
            # Extract camera parameters
            if view.ViewType == DB.ViewType.ThreeD:
                view_3d = view  # Cast to View3D
                eye = view_3d.GetOrientation().EyePosition
                target = view_3d.GetOrientation().ForwardDirection
                up = view_3d.GetOrientation().UpDirection
                
                camera_params = {
                    'eye': (eye.X, eye.Y, eye.Z),
                    'target': (target.X, target.Y, target.Z),
                    'up': (up.X, up.Y, up.Z),
                    'fov': 60  # Default, Revit doesn't expose FOV
                }
            else:
                camera_params = None
            
            exported_views.append({
                'name': view.Name,
                'type': str(view.ViewType),
                'image_path': f"view_{view.Name}.png",
                'camera': camera_params
            })
    
    return exported_views
```

**Extract Materials:**

```python
def extract_material_library(doc):
    """
    Get all materials with textures and properties
    
    Output: Material catalog for AI prompt generation
    """
    materials = DB.FilteredElementCollector(doc) \
                  .OfClass(DB.Material) \
                  .ToElements()
    
    material_catalog = []
    
    for mat in materials:
        # Get appearance asset (textures, colors)
        appearance = mat.AppearanceAssetId
        
        if appearance != DB.ElementId.InvalidElementId:
            asset = doc.GetElement(appearance)
            
            # Extract properties
            color = mat.Color  # RGB
            transparency = mat.Transparency  # 0-100
            shininess = mat.Shininess  # 0-128
            
            material_info = {
                'name': mat.Name,
                'color': (color.Red, color.Green, color.Blue),
                'transparency': transparency,
                'shininess': shininess,
                'category': mat.MaterialCategory,
                'texture_path': None  # Would need to extract from asset
            }
        else:
            material_info = {
                'name': mat.Name,
                'color': (128, 128, 128),  # Default gray
                'category': 'Generic'
            }
        
        material_catalog.append(material_info)
    
    return material_catalog
```

**Advantages:**
- ✅ Direct access to BIM data
- ✅ No manual export needed
- ✅ Always up-to-date (script runs on demand)
- ✅ Full material information
- ✅ Parametric: change Revit → rerun script → new render

**Disadvantages:**
- ❌ Requires Revit installed (not headless)
- ❌ Windows-only (Revit is Windows-only)
- ❌ pyRevit learning curve
- ❌ Slower than direct file parsing (Revit must be running)

**Recommendation:**
- Use pyRevit for **development/testing** (full access)
- For **production**, consider headless option (see below)

---

#### Option B: Headless Revit via Forge Design Automation

**What is Forge?**
- Autodesk cloud service
- Runs Revit in cloud (headless)
- REST API (no local Revit needed)

**Workflow:**

```
Upload .rvt to Forge
    ↓
Call Design Automation API
    ↓
Forge runs Revit plugin (extracts geometry)
    ↓
Download OBJ + materials JSON
    ↓
OC-GD Pipeline
```

**API Example:**

```python
import requests

FORGE_CLIENT_ID = "your_client_id"
FORGE_CLIENT_SECRET = "your_secret"

def upload_rvt_to_forge(rvt_path):
    """
    Upload Revit file to Autodesk Forge
    """
    # Get OAuth token
    auth_response = requests.post(
        "https://developer.api.autodesk.com/authentication/v1/authenticate",
        data={
            "client_id": FORGE_CLIENT_ID,
            "client_secret": FORGE_CLIENT_SECRET,
            "grant_type": "client_credentials",
            "scope": "data:write data:read"
        }
    )
    token = auth_response.json()["access_token"]
    
    # Upload file to Forge bucket
    with open(rvt_path, 'rb') as f:
        upload_response = requests.put(
            "https://developer.api.autodesk.com/oss/v2/buckets/oc-gd/objects/model.rvt",
            headers={"Authorization": f"Bearer {token}"},
            data=f
        )
    
    file_urn = upload_response.json()["objectId"]
    return file_urn, token

def extract_geometry_forge(file_urn, token):
    """
    Run Design Automation workitem to extract geometry
    """
    workitem = {
        "activityId": "YourActivity+prod",
        "arguments": {
            "inputRvt": {
                "url": f"https://developer.api.autodesk.com/oss/v2/buckets/oc-gd/objects/{file_urn}"
            },
            "outputObj": {
                "verb": "put",
                "url": "https://your-server.com/upload_obj"
            }
        }
    }
    
    response = requests.post(
        "https://developer.api.autodesk.com/da/us-east/v3/workitems",
        headers={"Authorization": f"Bearer {token}"},
        json=workitem
    )
    
    workitem_id = response.json()["id"]
    
    # Poll for completion
    while True:
        status = requests.get(
            f"https://developer.api.autodesk.com/da/us-east/v3/workitems/{workitem_id}",
            headers={"Authorization": f"Bearer {token}"}
        ).json()
        
        if status["status"] == "success":
            output_url = status["reportUrl"]
            break
        elif status["status"] == "failed":
            raise Exception("Forge extraction failed")
        
        time.sleep(5)
    
    # Download extracted geometry
    obj_file = requests.get(output_url).content
    return obj_file
```

**Advantages:**
- ✅ Headless (no local Revit needed)
- ✅ Scalable (cloud processing)
- ✅ Cross-platform (API works anywhere)
- ✅ Automated pipeline

**Disadvantages:**
- ❌ Requires Forge subscription ($$$)
- ❌ Network dependency
- ❌ More complex setup
- ❌ Slower (upload/download overhead)

**Recommendation:**
- For **enterprise/production** with many Revit files
- Not needed for MVP (use pyRevit first)

---

#### Option C: IFC as Open Alternative (Recommended for Open-Source)

**What is IFC?**
- Industry Foundation Classes
- Open BIM standard (ISO 16739)
- Revit can export to IFC (.ifc)
- Readable by open-source tools

**Advantages over proprietary .rvt:**
- ✅ Open standard (no vendor lock-in)
- ✅ Cross-platform parsers (IfcOpenShell)
- ✅ Human-readable (text-based)
- ✅ Preserves BIM data (geometry + metadata)

**Python Library: IfcOpenShell**

```bash
pip install ifcopenshell
```

**Extract Geometry from IFC:**

```python
import ifcopenshell
import ifcopenshell.geom

def extract_ifc_geometry(ifc_path):
    """
    Parse IFC file, extract 3D geometry
    
    Much simpler than Revit API!
    """
    ifc_file = ifcopenshell.open(ifc_path)
    
    # Get all building elements
    walls = ifc_file.by_type('IfcWall')
    slabs = ifc_file.by_type('IfcSlab')
    roofs = ifc_file.by_type('IfcRoof')
    
    elements = walls + slabs + roofs
    
    geometry_data = []
    
    settings = ifcopenshell.geom.settings()
    settings.set(settings.USE_WORLD_COORDS, True)
    
    for element in elements:
        # Get geometry
        shape = ifcopenshell.geom.create_shape(settings, element)
        
        # Extract vertices and faces
        vertices = shape.geometry.verts  # Flat list [x1,y1,z1, x2,y2,z2, ...]
        faces = shape.geometry.faces      # Indices into vertices
        
        # Get material
        material_name = None
        if element.HasAssociations:
            for association in element.HasAssociations:
                if association.is_a('IfcRelAssociatesMaterial'):
                    material = association.RelatingMaterial
                    if material.is_a('IfcMaterial'):
                        material_name = material.Name
        
        geometry_data.append({
            'element_id': element.GlobalId,
            'type': element.is_a(),
            'name': element.Name if hasattr(element, 'Name') else None,
            'vertices': vertices,
            'faces': faces,
            'material': material_name
        })
    
    return geometry_data

def export_ifc_to_obj(geometry_data, output_path):
    """
    Convert IFC geometry to OBJ (for Blender)
    """
    with open(output_path, 'w') as obj_file:
        vertex_offset = 1
        
        for geom in geometry_data:
            obj_file.write(f"o {geom['name'] or geom['element_id']}\n")
            
            # Write vertices
            verts = geom['vertices']
            for i in range(0, len(verts), 3):
                obj_file.write(f"v {verts[i]} {verts[i+1]} {verts[i+2]}\n")
            
            # Write faces
            faces = geom['faces']
            for i in range(0, len(faces), 3):
                # OBJ indices are 1-based
                f1 = faces[i] + vertex_offset
                f2 = faces[i+1] + vertex_offset
                f3 = faces[i+2] + vertex_offset
                obj_file.write(f"f {f1} {f2} {f3}\n")
            
            vertex_offset += len(verts) // 3
```

**Extract Materials from IFC:**

```python
def extract_ifc_materials(ifc_file):
    """
    Get material catalog from IFC
    """
    materials = ifc_file.by_type('IfcMaterial')
    
    material_catalog = []
    
    for mat in materials:
        # Get properties
        properties = {}
        if mat.HasProperties:
            for prop_set in mat.HasProperties:
                if prop_set.is_a('IfcMaterialProperties'):
                    for prop in prop_set.Properties:
                        properties[prop.Name] = prop.NominalValue.wrappedValue
        
        material_catalog.append({
            'name': mat.Name,
            'category': mat.Category if hasattr(mat, 'Category') else 'Generic',
            'properties': properties
        })
    
    return material_catalog
```

**Advantages:**
- ✅ No Revit needed (works on Linux!)
- ✅ Open-source tools
- ✅ Fast (direct file parsing)
- ✅ Preserves BIM metadata
- ✅ Future-proof (ISO standard)

**Disadvantages:**
- ❌ Requires Revit → IFC export (one-time step)
- ❌ Some Revit-specific features lost
- ❌ Less mature than Revit API

**Recommendation:**
- **Best for open-source pipeline**
- One-time export: Revit → IFC (can be automated via Revit API)
- Then: pure Python workflow (IfcOpenShell)

---

### Comparison Matrix

| Approach | Pros | Cons | Use Case |
|----------|------|------|----------|
| **pyRevit (Revit API)** | Full BIM access, no export | Requires Revit, Windows-only | Development, testing |
| **Forge Design Automation** | Headless, scalable | Costly, complex | Enterprise, cloud |
| **IFC + IfcOpenShell** | Open, cross-platform, fast | One-time export needed | **Production (recommended)** |

---

## Aspect 2: Material Extraction & Quantity Takeoff (Объем и материалы)

### Goal: Bill of Quantities (BOQ) from BIM

**What is needed:**
- Total area (m²) by material type
- Volume (m³) for concrete, brick, etc.
- Linear meters for beams, trim
- Count for windows, doors, fixtures

**Why from Revit/IFC?**
- BIM models have precise geometric data
- Materials tagged at element level
- No manual measurement needed

---

### Implementation with IFC (Recommended)

```python
def calculate_quantities_from_ifc(ifc_path):
    """
    Extract Bill of Quantities from IFC file
    
    Output: Dictionary of materials → quantities
    """
    ifc_file = ifcopenshell.open(ifc_path)
    
    quantities = {
        'walls': {},      # Material → m² area
        'slabs': {},      # Material → m² area
        'volumes': {},    # Material → m³ volume
        'lengths': {},    # Type → m length
        'counts': {}      # Type → count
    }
    
    # 1. Walls (area by material)
    walls = ifc_file.by_type('IfcWall')
    for wall in walls:
        # Get material
        material = get_material_name(wall)
        
        # Get quantity set
        for definition in wall.IsDefinedBy:
            if definition.is_a('IfcRelDefinesByProperties'):
                prop_set = definition.RelatingPropertyDefinition
                
                if prop_set.is_a('IfcElementQuantity'):
                    for quantity in prop_set.Quantities:
                        if quantity.is_a('IfcQuantityArea'):
                            area = quantity.AreaValue
                            
                            if material not in quantities['walls']:
                                quantities['walls'][material] = 0
                            quantities['walls'][material] += area
    
    # 2. Slabs (floors, roofs)
    slabs = ifc_file.by_type('IfcSlab')
    for slab in slabs:
        material = get_material_name(slab)
        area = get_net_area(slab)  # From IfcQuantityArea
        
        if material not in quantities['slabs']:
            quantities['slabs'][material] = 0
        quantities['slabs'][material] += area
    
    # 3. Volumes (concrete, brick, etc.)
    volume_elements = ifc_file.by_type('IfcWall') + ifc_file.by_type('IfcColumn')
    for element in volume_elements:
        material = get_material_name(element)
        volume = get_net_volume(element)  # From IfcQuantityVolume
        
        if material not in quantities['volumes']:
            quantities['volumes'][material] = 0
        quantities['volumes'][material] += volume
    
    # 4. Linear elements (beams, trim)
    beams = ifc_file.by_type('IfcBeam')
    for beam in beams:
        beam_type = beam.ObjectType
        length = get_length(beam)  # From IfcQuantityLength
        
        if beam_type not in quantities['lengths']:
            quantities['lengths'][beam_type] = 0
        quantities['lengths'][beam_type] += length
    
    # 5. Countable items (windows, doors)
    windows = ifc_file.by_type('IfcWindow')
    doors = ifc_file.by_type('IfcDoor')
    
    quantities['counts']['windows'] = len(windows)
    quantities['counts']['doors'] = len(doors)
    
    # Group windows by type
    window_types = {}
    for window in windows:
        window_type = window.ObjectType
        window_types[window_type] = window_types.get(window_type, 0) + 1
    
    quantities['counts']['windows_by_type'] = window_types
    
    return quantities

def get_material_name(element):
    """
    Extract material name from IFC element
    """
    if element.HasAssociations:
        for assoc in element.HasAssociations:
            if assoc.is_a('IfcRelAssociatesMaterial'):
                material = assoc.RelatingMaterial
                
                if material.is_a('IfcMaterial'):
                    return material.Name
                elif material.is_a('IfcMaterialLayerSetUsage'):
                    # Composite material (e.g., wall layers)
                    layer_set = material.ForLayerSet
                    # Return dominant layer (thickest)
                    layers = sorted(layer_set.MaterialLayers, 
                                    key=lambda l: l.LayerThickness, 
                                    reverse=True)
                    return layers[0].Material.Name if layers else 'Unknown'
    
    return 'Unspecified'

def get_net_area(element):
    """
    Get area from IFC quantity set
    """
    for definition in element.IsDefinedBy:
        if definition.is_a('IfcRelDefinesByProperties'):
            prop_set = definition.RelatingPropertyDefinition
            
            if prop_set.is_a('IfcElementQuantity'):
                for quantity in prop_set.Quantities:
                    if quantity.Name == 'NetSideArea' or quantity.Name == 'GrossSideArea':
                        if quantity.is_a('IfcQuantityArea'):
                            return quantity.AreaValue
    
    return 0.0

def get_net_volume(element):
    """
    Get volume from IFC quantity set
    """
    for definition in element.IsDefinedBy:
        if definition.is_a('IfcRelDefinesByProperties'):
            prop_set = definition.RelatingPropertyDefinition
            
            if prop_set.is_a('IfcElementQuantity'):
                for quantity in prop_set.Quantities:
                    if quantity.Name == 'NetVolume' or quantity.Name == 'GrossVolume':
                        if quantity.is_a('IfcQuantityVolume'):
                            return quantity.VolumeValue
    
    return 0.0
```

---

### Example Output (BOQ)

```json
{
  "walls": {
    "Brick_Red": 245.6,         // m²
    "Concrete_Block": 128.3,    // m²
    "Drywall_Standard": 89.2    // m²
  },
  "slabs": {
    "Concrete_C25": 156.4,      // m²
    "Wood_Oak_Parquet": 142.1   // m²
  },
  "volumes": {
    "Brick_Red": 6.14,          // m³
    "Concrete_C25": 18.96       // m³
  },
  "lengths": {
    "Steel_I_Beam_200": 24.5,   // m
    "Wood_Trim_50x50": 112.8    // m
  },
  "counts": {
    "windows": 18,
    "doors": 8,
    "windows_by_type": {
      "Double_Hung_1200x1500": 12,
      "Casement_800x1200": 6
    }
  }
}
```

---

### Cost Estimation from BOQ

```python
def calculate_cost_estimate(quantities, price_catalog):
    """
    BOQ + unit prices → total cost estimate
    
    price_catalog example:
    {
        "Brick_Red": {"unit": "m²", "price": 850},  // руб/м²
        "Concrete_C25": {"unit": "m³", "price": 4500},
        ...
    }
    """
    total_cost = 0
    cost_breakdown = {}
    
    # Walls
    for material, area in quantities['walls'].items():
        if material in price_catalog:
            unit_price = price_catalog[material]['price']
            cost = area * unit_price
            total_cost += cost
            cost_breakdown[material] = {
                'quantity': area,
                'unit': 'm²',
                'unit_price': unit_price,
                'total': cost
            }
    
    # Volumes
    for material, volume in quantities['volumes'].items():
        if material in price_catalog:
            unit_price = price_catalog[material]['price']
            cost = volume * unit_price
            total_cost += cost
            cost_breakdown[material] = {
                'quantity': volume,
                'unit': 'm³',
                'unit_price': unit_price,
                'total': cost
            }
    
    # ... similar for other categories
    
    return {
        'total_cost': total_cost,
        'breakdown': cost_breakdown,
        'currency': 'RUB'
    }
```

---

### Integration with Gamacchi Workflow

**Scenario:** Client requests project → auto-generate:
1. Visual renders (OC-GD from Revit/IFC)
2. Bill of Quantities (IfcOpenShell)
3. Cost estimate (BOQ + price catalog)

**Unified API:**

```python
# gamacchi-web/routes/projects.js

@app.post("/api/projects/:id/generate")
async def generate_project_deliverables(project_id):
    """
    From single Revit/IFC file → produce:
    - Renders (4K PNG)
    - BOQ (JSON)
    - Cost estimate (PDF)
    """
    project = db.get_project(project_id)
    ifc_path = project.ifc_file_path
    
    # 1. Extract geometry for rendering
    geometry = extract_ifc_geometry(ifc_path)
    
    # 2. Generate renders via OC-GD
    renders = []
    for view_type in ['north', 'south', 'aerial']:
        render_url = await ocgd_api.render(
            geometry=geometry,
            view=view_type,
            style='modern'
        )
        renders.append(render_url)
    
    # 3. Calculate BOQ
    quantities = calculate_quantities_from_ifc(ifc_path)
    
    # 4. Cost estimate
    price_catalog = db.get_price_catalog()  # From database
    cost_estimate = calculate_cost_estimate(quantities, price_catalog)
    
    # 5. Generate PDF report
    pdf_path = generate_project_pdf(
        renders=renders,
        boq=quantities,
        cost=cost_estimate,
        project_info=project
    )
    
    return {
        "renders": renders,
        "boq": quantities,
        "cost_estimate": cost_estimate,
        "pdf_report": pdf_path
    }
```

---

## Recommended Workflow

### Phase 1: IFC-Based Pipeline (Immediate)

```
Revit (.rvt)
    ↓
[Manual] Export to IFC (.ifc)  ← One-time step
    ↓
┌────────────────────┐
│  IfcOpenShell      │
│  (Python)          │
└────────────────────┘
    ↓              ↓
Geometry      Quantities
    ↓              ↓
OC-GD         BOQ + Cost
Renders       Estimate
    ↓              ↓
Unified Project Report (PDF)
```

**Advantages:**
- Open-source (no licensing costs)
- Cross-platform (Linux OK)
- Fast (direct file parsing)
- Single source for visuals + data

**Manual Step:**
- Revit → File → Export → IFC
- Can be automated via pyRevit script if needed

---

### Phase 2: Automated IFC Export (Future)

```
Revit (.rvt)
    ↓
[Automated] pyRevit script: Export to IFC on save
    ↓
IfcOpenShell pipeline
    ↓
...
```

**pyRevit auto-export script:**

```python
from pyrevit import revit, DB
from pyrevit.framework import Forms

def auto_export_ifc_on_save(sender, args):
    """
    Event handler: export IFC whenever Revit file is saved
    """
    doc = args.Document
    
    # Get file path
    rvt_path = doc.PathName
    ifc_path = rvt_path.replace('.rvt', '.ifc')
    
    # Export IFC
    ifc_options = DB.IFCExportOptions()
    doc.Export(ifc_path, ifc_options)
    
    Forms.alert(f"IFC exported: {ifc_path}")

# Register event handler
app = revit.HOST_APP.app
app.DocumentSaved += auto_export_ifc_on_save
```

---

## Summary & Recommendations

### For Visual Rendering

**Recommended:** IFC + IfcOpenShell
- Export Revit → IFC (one-time or automated)
- Python script extracts geometry
- Feed to OC-GD pipeline

**Alternative:** pyRevit for direct extraction (development only)

---

### For Material Quantities

**Recommended:** IFC + IfcOpenShell
- Read IfcQuantityArea, IfcQuantityVolume directly
- No manual measurement
- Export to JSON/Excel/PDF

**Advantages over manual takeoff:**
- 100% accurate (from BIM)
- Updates automatically (change model → rerun script)
- Faster (seconds vs hours)

---

### Combined Benefits

**Single IFC file provides:**
1. ✅ 3D geometry for AI rendering
2. ✅ Material catalog for style prompts
3. ✅ Quantities for BOQ
4. ✅ Cost estimation
5. ✅ Project metadata (rooms, levels, etc.)

**Unified deliverable:**
- Client gets: Renders + BOQ + Cost in single PDF
- All from one source file (no version drift)

---

## Implementation Roadmap

### Week 1: IFC Integration

- [x] Research IfcOpenShell capabilities
- [ ] Install IfcOpenShell on dev machine
- [ ] Export sample Revit project → IFC
- [ ] Parse IFC → extract geometry
- [ ] Validate geometry vs Revit original

### Week 2: BOQ Extraction

- [ ] Implement quantity extraction (walls, slabs, volumes)
- [ ] Test on 5 real projects
- [ ] Compare against manual takeoff (validate accuracy)
- [ ] Create price catalog database

### Week 3: Integration with OC-GD

- [ ] IFC geometry → OBJ export
- [ ] OBJ → Blender → depth/normal maps
- [ ] Feed to SDXL pipeline
- [ ] Test rendering quality vs DWG export

### Week 4: Unified API

- [ ] Create `/api/projects/:id/generate` endpoint
- [ ] Integrate rendering + BOQ + cost
- [ ] Generate PDF report
- [ ] Test end-to-end workflow

---

## Technical Challenges

### Challenge 1: IFC Complexity

**Problem:** IFC files can be large (100+ MB), complex hierarchy

**Solution:**
- Use spatial structure tree (IfcProject → IfcSite → IfcBuilding → IfcStorey)
- Filter by type (only load needed elements)
- Cache parsed geometry

### Challenge 2: Material Mapping

**Problem:** IFC materials may not match texture library

**Solution:**
- Build material mapping table (IFC name → texture name)
- Use fuzzy matching (e.g., "Brick Red 240mm" → "brick_red")
- Allow manual overrides in UI

### Challenge 3: Coordinate Systems

**Problem:** IFC uses different units/origin than rendering pipeline

**Solution:**
- Normalize to meters (IFC can be mm, cm, m)
- Re-center geometry at origin
- Apply transformation matrix from IFC → world coords

---

## Questions for Igor

1. **IFC Export:**
   - Do you currently export IFC from Revit?
   - What IFC version (2x3, 4, 4.3)?
   - Any export settings/templates used?

2. **BOQ Workflow:**
   - Current method for quantity takeoff (manual, Revit schedules, other)?
   - Time spent on typical project BOQ?
   - Price catalog exists (Excel, database)?

3. **Materials:**
   - How many material types typical (10, 50, 100+)?
   - Material naming convention consistent?
   - Need for material layered breakdowns (e.g., wall = brick + insulation + drywall)?

4. **Deliverables:**
   - Current format for BOQ (Excel, PDF, both)?
   - Cost estimate shown to clients (yes/no, detailed/summary)?
   - Would unified PDF (renders + BOQ + cost) be valuable?

---

## Expected Results

**Time Savings:**
- BOQ generation: 4 hours → **5 minutes** (automated)
- Rendering: 2 hours manual setup → **2 minutes** (AI)
- Cost estimate: 1 hour → **instant** (from BOQ + prices)

**Accuracy:**
- BOQ: Manual ~90% → **100%** (from BIM)
- Cost: depends on price catalog accuracy

**Client Value:**
- Professional deliverable (renders + data)
- Faster iterations (change model → regenerate)
- Transparency (see exactly what they're paying for)

---

**Status:** IFC-based pipeline is **highly feasible and recommended**

**Next:** Answer questions above → implement Phase 1 (IFC integration) → validate on real project

🏗️ **OC-GD + IFC: From BIM to beautiful renders + accurate takeoffs!**
