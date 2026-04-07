# Sedulous Renderer Architecture

Living document describing the rendering architecture.

## Overview

The renderer is **scene-independent**. It receives flat render data and draws it.
Scene integration is a layer above (`Engine.Render`). The renderer can be used
standalone for sandboxes, tools, and tests without any scene infrastructure.

```
Sedulous.Renderer (scene-independent)
├── Renderer              — shared infrastructure (GPU resources, materials, lights, shaders)
├── Pipeline              — per-view pass execution, output texture, render graph
├── PipelinePass          — base class for render/compute/copy passes
├── PostProcessStack      — ordered chain of post-process effects on Pipeline
├── PipelineStateCache    — on-demand GPU pipeline creation from material config
├── RenderView            — camera + viewport + frame state + extracted data
├── ExtractedRenderData   — per-view container of categorized render data
├── GPUResourceManager    — handle-based GPU resource pool
├── IRenderDataProvider   — extraction interface for scene modules
├── RenderExtractionContext — view info passed to providers during extraction
└── BindGroupFrequency    — 4-level bind group convention
```

## Renderer (Shared Infrastructure)

The `Renderer` class owns GPU resources and systems shared across all views/pipelines:
- `GPUResourceManager` — meshes, textures, bone buffers with deferred deletion
- `MaterialSystem` — bind group lifecycle, default textures, per-instance GPU resources
- `PipelineStateCache` — cached GPU pipelines by config hash
- `LightBuffer` — per-frame light data upload (max 128 lights)
- `ShaderSystem` reference — compilation and caching
- Shared bind group layouts (Frame set 0, DrawCall set 3)
- Default material and draw call bind groups

One Renderer per application. Multiple Pipelines reference the same Renderer.

## Pipeline (Per-View Execution)

The `Pipeline` is a lightweight per-view pass execution engine. It owns:
- List of `PipelinePass` objects
- `PostProcessStack` (optional, chains post-process effects)
- Per-frame resources (double-buffered uniform buffers + bind groups)
- `RenderGraph` instance
- Output texture (RGBA16Float, owned by pipeline)
- References shared infrastructure from `Renderer`

### Pipeline Output

The Pipeline renders to its own internal output texture, NOT to the swapchain.
The caller (RenderSubsystem) blits the output to the final target.

Benefits:
- Pipeline doesn't know about swapchains
- Same output can go to swapchain, editor viewport, screenshot, offscreen buffer
- Resolution independence (pipeline renders at internal res, blit scales)

### Frame Flow

```
Pipeline.Render(encoder, view):
  1. Upload scene uniforms (per-frame, double-buffered)
  2. Upload light data to LightBuffer
  3. Rebuild frame bind group (scene uniforms + light buffer)
  4. Process deferred GPU resource deletions
  5. renderGraph.BeginFrame(frameIndex)
  6. If post-processing active:
       Import output as "FinalOutput", create transient "PipelineOutput" (HDR)
     Else:
       Import output as "PipelineOutput"
  7. Add ClearOutput pass
  8. Each PipelinePass.AddPasses(graph, view, pipeline)
  9. PostProcessStack.Execute() chains: PipelineOutput → effects → FinalOutput
  10. renderGraph.Execute(encoder)
  11. renderGraph.EndFrame()
```

## PipelinePass

Base class for all pipeline stages. A pass adds one or more render graph nodes
(render, compute, or copy). The render graph handles ordering based on resource
dependencies — no explicit dependency declarations needed.

```
abstract class PipelinePass
{
    StringView Name;
    Result<void> OnInitialize(Pipeline pipeline);
    void OnShutdown();
    void OnResize(uint32 width, uint32 height);
    void AddPasses(RenderGraph graph, RenderView view, Pipeline pipeline);
}
```

### Registered Passes

| Pass | Type | Reads | Writes | Description |
|------|------|-------|--------|-------------|
| DepthPrepass | Render | — | SceneDepth | Depth-only, establishes early-Z |
| ForwardOpaquePass | Render | SceneDepth | PipelineOutput | PBR lit opaque + masked geometry |
| ForwardTransparentPass | Render | SceneDepth | PipelineOutput | PBR lit transparent, alpha blend, back-to-front |
| SkyPass | Render | SceneDepth | PipelineOutput | Equirectangular HDR sky or procedural gradient |

Future:
- `GPUSkinningPass` — compute pass, transforms vertices
- `ShadowPass` — render pass, depth-only from light perspective
- `DecalPass` — render pass, screen-space projected decals

## Post-Processing

### PostProcessStack

Owned by Pipeline (per-view). Chains `PostProcessEffect` instances via render graph passes.

```
PostProcessStack.Execute(graph, view, sceneColor, sceneDepth, pipelineOutput):
  For each enabled effect:
    effect.AddPasses(graph, view, renderer, ctx)
    ctx.Input → effect → ctx.Output
  Last effect writes to pipelineOutput
```

All intermediate textures are render graph transients — no manual texture management.

### PostProcessEffect

Base class for effects. Each effect adds render graph passes that read from
`ctx.Input` and write to `ctx.Output`. Effects can produce auxiliary textures
(e.g., bloom → "BloomTexture") via `ctx.SetAux()` for downstream effects.

### Active Effects

| Effect | Description |
|--------|-------------|
| TonemapEffect | ACES filmic tone mapping. sRGB swapchain handles gamma. |

## Render Data

### Categories

Render data is categorized for sorting and pass routing:

| Category | Sort | Purpose |
|----------|------|---------|
| Opaque | Front-to-back (material, then depth) | Lit opaque geometry |
| Masked | Front-to-back | Alpha-tested geometry (AlphaCutoff + discard) |
| Transparent | Back-to-front | Blended geometry |
| Sky | None | Sky rendering |
| Decal | Sort order | Projected decals |
| Light | None | Consumed by lighting system |
| ReflectionProbe | None | Consumed by probe system |
| GUI | None | Screen-space UI |

### ExtractedRenderData

Per-view container. Providers add data, then `SortAndBatch()` sorts by category-specific
keys. Passes iterate sorted batches.

### Render Data Types

- `MeshRenderData` — GPUMeshHandle, submesh index, world matrix, material bind group
- `LightRenderData` — type (directional/point/spot), color, intensity, direction, range, shadow config
- `DecalRenderData` — world matrix, color, textures

All are structs (value types). No entity/component references — just GPU handles and flat data.

## Render Extraction

### Interface

```
interface IRenderDataProvider
{
    void ExtractRenderData(in RenderExtractionContext context);
}
```

### Extraction Flow

```
RenderSubsystem.EndFrame():
  1. Build RenderExtractionContext from camera
  2. Create/clear ExtractedRenderData
  3. For each active scene:
     For each scene module implementing IRenderDataProvider:
       provider.ExtractRenderData(context)
  4. renderData.SortAndBatch()
  5. pipeline.Render(encoder, view)
  6. BlitToSwapchain
  7. Present
```

### Cross-Subsystem Discovery

Any engine subsystem can provide render data by implementing IRenderDataProvider
on its scene modules:

```
Engine.Render     → MeshComponentManager : IRenderDataProvider
Engine.Render     → LightComponentManager : IRenderDataProvider
Engine.Particles  → ParticleComponentManager : IRenderDataProvider (future)
Engine.Render     → DecalComponentManager : IRenderDataProvider (future)
```

### Visibility / Culling (Future)

Currently: providers extract everything.
Future: scene-level spatial structure (octree/BVH) produces a visibility set.
The `RenderExtractionContext` will carry the visibility set. Providers check it.
Culling is centralized — one frustum test per entity, not per component type.

## GPU Resource Management

### GPUResourceManager

Handle-based pool of GPU resources (meshes, textures, bone buffers):

- `UploadMesh(MeshUploadDesc)` → `GPUMeshHandle`
- `UploadTexture(TextureUploadDesc)` → `GPUTextureHandle`
- `CreateBoneBuffer(boneCount)` → `GPUBoneBufferHandle`
- Reference counting + deferred deletion (safe for in-flight frames)
- Scene-independent — takes raw data, returns handles

### PipelineStateCache

Creates GPU render pipeline objects on demand from `PipelineConfig`:

- Key: shader + vertex layout + render state + target format
- `GetPipeline(config, vertexBuffers, materialLayout, colorFormat)` → cached pipeline
- `GetPipelineForMaterial(material, ...)` → derives config from MaterialInstance
- Caches pipeline layouts for the 4-level bind group model
- Owned by Renderer (shared across pipelines)

## Bind Group Frequency Model

Shaders use HLSL register spaces 0-3 by convention:

| Set | Space | Frequency | Contents | Rebuilt |
|-----|-------|-----------|----------|---------|
| 0 | space0 | Per-frame | VP matrices, time, lights | Once per frame |
| 1 | space1 | Per-pass | Sky params, shadow maps | Once per pass |
| 2 | space2 | Per-material | Textures, params, samplers | On material change |
| 3 | space3 | Per-draw | Object transforms (dynamic offset) | Per draw call |

No shader reflection — convention-based. Shaders put resources in the right space,
renderer builds matching layouts in code.

## Material System

`MaterialSystem` manages material bind groups, default textures, and per-instance GPU resources.
Owned by Renderer. Key operations:

- `PrepareInstance(MaterialInstance)` — creates/updates uniform buffer + bind group
- `GetOrCreateLayout(Material)` — builds bind group layout from material property definitions
- `ReleaseInstance(MaterialInstance)` — frees GPU resources for an instance
- Provides default textures (white, normal, black, depth) for unset material slots

Materials are created via factory methods in `Materials` static class:
- `CreatePBR(name, shader, albedo, sampler)` — standard PBR
- `CreateUnlit(name, shader)` — emissive only
- `CreateSkybox(name, shader, cubemap, sampler)` — cubemap sky
- `CreateSprite(name, shader, texture, sampler)` — 2D sprites

## Shader System

`ShaderSystem` handles compilation and caching (memory → disk → compile from source).
Created by EngineApplication, set on Renderer.

Shaders are HLSL files in `Assets/shaders/`. The system auto-discovers source paths
and caches compiled SPIRV/DXIL to `Assets/cache/shaders/`.

### Shader Inventory

| Shader | Purpose |
|--------|---------|
| forward | PBR lit geometry (vert + frag) |
| depth_only | Depth prepass |
| blit | Fullscreen copy to swapchain |
| tonemap | ACES tone mapping |
| sky | Equirectangular HDR sky + procedural fallback |
| unlit | Unlit/emissive rendering |
| drawing | Vector graphics |
| vg | Vector graphics variant |
| slug | Text rendering |

## Blit / Presentation

`BlitHelper` copies pipeline output to the swapchain via a fullscreen triangle shader.
The RenderSubsystem owns the blit helper and calls it after pipeline rendering.

```
Pipeline.Render()  → PipelineOutput (RGBA16Float, linear HDR)
  → PostProcessStack → TonemapEffect → FinalOutput (RGBA16Float, linear LDR)
BlitHelper.Blit()  → Swapchain (BGRA8UnormSrgb, sRGB gamma applied by hardware)
Present            → Screen
```

## Profiling

Profiler scopes instrument the render path:

```
Pipeline.Render
  UploadUniforms
  RenderGraph.Execute
    DepthPrepass
    ForwardOpaque
    ForwardTransparent
    Sky
    Tonemap
  Blit
```

Press Shift+P at runtime to print a sorted profile frame with init time.
