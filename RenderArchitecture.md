# Sedulous Renderer Architecture

Living document describing the rendering architecture.

## Overview

The renderer is **scene-independent**. It receives flat render data and draws it.
Scene integration is a layer above (`Engine.Render`). The renderer can be used
standalone for sandboxes, tools, and tests without any scene infrastructure.

```
Sedulous.Renderer (scene-independent)
├── Pipeline              — orchestrates passes, per-frame resources, GPU resources
├── PipelinePass          — base class for render/compute/copy passes
├── PipelineStateCache    — on-demand GPU pipeline creation from material config
├── RenderView            — camera + viewport + frame state + extracted data
├── ExtractedRenderData   — per-view container of categorized render data
├── GPUResourceManager    — handle-based GPU resource pool
├── IRenderDataProvider   — extraction interface for scene modules
├── RenderExtractionContext — view info passed to providers during extraction
└── BindGroupFrequency    — 4-level bind group convention
```

## Pipeline

The `Pipeline` orchestrates rendering. It owns:
- List of `PipelinePass` objects
- Per-frame resources (double-buffered uniform buffers + bind groups)
- `GPUResourceManager` (meshes, textures, bone buffers)
- `RenderGraph` instance
- `PipelineStateCache` (on-demand GPU pipeline creation)
- Output texture (RGBA16Float, owned by pipeline)

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
  2. Process deferred GPU resource deletions
  3. renderGraph.BeginFrame(frameIndex)
  4. Import PipelineOutput into render graph
  5. Add ClearOutput pass (unconditional, guarantees known state)
  6. Each PipelinePass.AddPasses(graph, view, pipeline)
  7. renderGraph.Execute(encoder)
  8. renderGraph.EndFrame()
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

Examples:
- `DepthPrepass` — render pass, writes SceneDepth
- `ForwardOpaquePass` — render pass, reads SceneDepth, writes PipelineOutput
- `SkyPass` — render pass, reads SceneDepth, writes PipelineOutput
- `GPUSkinningPass` (future) — compute pass, transforms vertices
- `ParticleSimulationPass` (future) — compute pass, dispatches particle sim

## Render Data

### Categories

Render data is categorized for sorting and pass routing:

| Category | Sort | Purpose |
|----------|------|---------|
| Opaque | Front-to-back (material, then depth) | Lit opaque geometry |
| Masked | Front-to-back | Alpha-tested geometry |
| Transparent | Back-to-front | Blended geometry |
| Sky | None | Sky rendering |
| Decal | Sort order | Projected decals |
| Light | None | Consumed by lighting system |
| ReflectionProbe | None | Consumed by probe system |
| GUI | None | Screen-space UI |

### ExtractedRenderData

Per-view container. Providers add data, then `SortAndBatch()` sorts by category-specific
keys. Passes iterate sorted batches.

```
data.AddMesh(RenderCategories.Opaque, meshRenderData);
data.AddLight(lightRenderData);
data.SortAndBatch();

// In pass:
for (let entry in data.GetSortedBatch(RenderCategories.Opaque))
    let mesh = ref data.GetMesh(RenderCategories.Opaque, entry.Index);
```

### Render Data Types

- `MeshRenderData` — GPUMeshHandle, submesh index, world matrix, material bind group
- `LightRenderData` — type, color, intensity, direction, range, shadow config
- `DecalRenderData` — world matrix, color, textures

All are structs (value types). No entity/component references — just GPU handles and flat data.

## Render Extraction

### Interface

```
// In Sedulous.Renderer (scene-independent):
interface IRenderDataProvider
{
    void ExtractRenderData(in RenderExtractionContext context);
}

struct RenderExtractionContext
{
    ExtractedRenderData* RenderData;     // output
    Matrix ViewMatrix;                    // for sorting
    Matrix ViewProjectionMatrix;          // for frustum culling (future)
    Vector3 CameraPosition;              // for LOD, distance culling
    float NearPlane, FarPlane;
    int32 FrameIndex;
    uint32 LayerMask;                     // for filtering
    float LODBias;                        // for LOD selection
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
on its scene modules. The RenderSubsystem discovers providers via the interface
at extraction time — no coupling between subsystems:

```
Engine.Render     → MeshComponentManager : IRenderDataProvider
Engine.Render     → LightComponentManager : IRenderDataProvider
Engine.Particles  → ParticleComponentManager : IRenderDataProvider
Engine.Render     → DecalComponentManager : IRenderDataProvider
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

## Bind Group Frequency Model

Shaders use HLSL register spaces 0-3 by convention:

| Set | Space | Frequency | Contents | Rebuilt |
|-----|-------|-----------|----------|---------|
| 0 | space0 | Per-frame | VP matrices, time, global lighting | Once per frame |
| 1 | space1 | Per-pass | Shadow maps, GBuffer refs | Once per pass |
| 2 | space2 | Per-material | Textures, params, samplers | On material change |
| 3 | space3 | Per-draw | Object transforms (dynamic offset) | Per draw call |

No shader reflection — convention-based. Shaders put resources in the right space,
renderer builds matching layouts in code.

## Shader System

`ShaderSystem` handles compilation and caching (memory → disk → compile from source).
Created by EngineApplication, passed to RenderSubsystem and Pipeline.

Shaders are HLSL files in `Assets/shaders/`. The system auto-discovers source paths
and caches compiled SPIRV/DXIL to `Assets/cache/shaders/`.

## Blit / Presentation

`BlitHelper` copies pipeline output to the swapchain via a fullscreen triangle shader.
The RenderSubsystem owns the blit helper and calls it after pipeline rendering.

```
Pipeline.Render()  → PipelineOutput (RGBA16Float)
BlitHelper.Blit()  → Swapchain (BGRA8UnormSrgb)
Present            → Screen
```

## GPU Compute Work

GPU compute (particle simulation, skinning, cluster culling) is handled by
`PipelinePass` objects that add compute nodes to the render graph:

```
graph.AddComputePass("GPUSkinning", scope (builder) => {
    builder.ReadBuffer(boneBuffer);
    builder.ReadWriteStorage(vertexBuffer);
    builder.SetComputeExecute(new (encoder) => { ... });
});
```

The render graph handles ordering — a compute pass that writes a buffer followed
by a render pass that reads it gets correct barriers automatically.

Compute passes are registered with the Pipeline by their respective subsystems,
separate from render data extraction.
