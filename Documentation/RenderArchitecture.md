# Sedulous Renderer Architecture

Living document describing the rendering architecture.

## Overview

The renderer is **scene-independent**. It receives flat render data and draws it.
Scene integration is a layer above (`Engine.Render`). The renderer can be used
standalone for sandboxes, tools, and tests without any scene infrastructure.

```
Sedulous.Renderer (scene-independent)
├── RenderContext          - shared infrastructure (GPU resources, materials, lights, shaders,
│                            shadows, sprites, debug draw, registered renderers)
│                            CurrentSceneDepthView for depth-dependent effects
├── Pipeline               - per-view pass execution, render graph (output target provided by caller)
├── IRenderingPipeline     - interface shared by Pipeline + ShadowPipeline
├── PipelinePass           - base class for render/compute/copy passes
├── Renderer               - abstract per-type drawer base (ezRenderer pattern)
│   ├── MeshRenderer       - draws MeshRenderData (Opaque, Masked, Transparent)
│   ├── SpriteRenderer     - draws SpriteRenderData (Transparent, GPU instanced)
│   └── DecalRenderer      - draws DecalRenderData (Decal, own pipeline layout)
├── PostProcessStack       - ordered chain of post-process effects on Pipeline
├── PipelineStateCache     - on-demand GPU pipeline creation, MRT support
├── RenderView             - camera + viewport + frame state + extracted data (owns ExtractedRenderData)
├── RenderViewPool         - per-frame view reuse for multi-view rendering
├── ExtractedRenderData    - per-view container of polymorphic render data per category
├── FrameAllocator         - per-frame bump allocator for render data (Sedulous.Core.Memory)
├── GPUResourceManager     - handle-based GPU resource pool
├── Shadows/
│   ├── ShadowSystem       - atlas + data buffer + comparison sampler + bind groups
│   ├── ShadowAtlas         - hierarchical 3-tier depth atlas (Large/Medium/Small)
│   ├── ShadowPipeline      - standalone per-view shadow rendering
│   └── ShadowMatrices      - spot/point/directional cascade matrix computation
├── Debug/
│   ├── DebugDraw           - immediate-mode wire shapes + text API
│   └── DebugDrawSystem     - font atlas + per-frame vertex buffers
├── SpriteSystem           - sprite material template + per-frame instance buffers
├── IRenderDataProvider    - extraction interface for scene modules
├── RenderExtractionContext - view info + RenderContext ref passed to providers
└── BindGroupFrequency     - 5-level bind group convention (Frame/Pass/Material/DrawCall/Shadow)

Sedulous.Particles (self-contained, depends on Renderer)
├── Simulation
│   ├── ParticleStream/CPUStream/GPUStream - SoA data channels with on-demand allocation
│   ├── ParticleSimulator/CPUSimulator     - behavior execution on streams
│   ├── ParticleSystem                     - orchestrator (emitter + behaviors + initializers + streams)
│   ├── ParticleEffect/ParticleEffectInstance - multi-system grouping + sub-emitter routing
│   ├── 12 behaviors + 6 initializers      - composable, declare stream requirements
│   └── Curves, shapes, ranges             - Hermite curves, 7 emission shapes, randomized values
├── Render/
│   ├── ParticlePass        - own render pass with ReadDepth + ReadTexture for soft particles
│   ├── ParticleRenderer    - Renderer subclass for Particle category, per-blend-mode pipelines
│   ├── ParticleGPUResources - custom pipeline layout (Frame+Depth+Material+DrawCall), buffers
│   └── ParticleRenderExtractor - streams -> vertex array, sorting, AABB, trail ribbon mesh
└── Sedulous.Particles.Resources - serialization (ParticleEffectResource, type registry)
```

## RenderContext (Shared Infrastructure)

The `RenderContext` class (formerly Renderer) owns GPU resources, systems, and
registered per-type drawers shared across all views/pipelines:

- `GPUResourceManager` - meshes, textures, bone buffers with deferred deletion
- `MaterialSystem` - bind group lifecycle, default textures, per-instance GPU resources
- `PipelineStateCache` - cached GPU pipelines by config hash, MRT support
- `LightBuffer` - per-frame light data upload (max 128 lights)
- `ShadowSystem` - hierarchical shadow atlas + shadow data buffer + comparison sampler
- `SkinningSystem` - compute skinning dispatch + per-mesh output buffers
- `SpriteSystem` - shared sprite material template + per-frame instance buffers
- `DebugDrawSystem` - font atlas + per-frame line/overlay vertex buffers
- `DebugDraw` - immediate-mode API for wire shapes, text, screen overlays
- `FrameAllocator` - per-frame bump allocator for render data, reset each BeginFrame
- Registered renderers (MeshRenderer, SpriteRenderer, DecalRenderer) - shared across pipelines
- Shared bind group layouts (Frame set 0, DrawCall set 3, Shadow set 4)

One RenderContext per application. Multiple Pipelines reference the same context.

## Pipeline (Per-View Execution)

The `Pipeline` is a lightweight per-view pass execution engine. It owns:
- List of `PipelinePass` objects
- `PostProcessStack` (optional, chains post-process effects)
- Per-frame resources (double-buffered uniform buffers + bind groups)
- `RenderGraph` instance
- Output dimensions (width/height) for internal transient sizing
- References shared infrastructure from `RenderContext`

### Pipeline Output

The Pipeline renders to a **caller-provided output texture**, NOT to an internally
owned texture. The caller (EngineApplication via ISceneRenderer) creates the output
target (RGBA16Float), clears it, and passes it to `Pipeline.Render()`.

Benefits:
- Pipeline doesn't know about swapchains or who owns the output
- Same code renders to swapchain blit target, editor viewport texture, or offscreen buffer
- Application controls output lifetime, sizing, and format
- No texture create/destroy in Pipeline.OnResize - just dimension updates

### Frame Flow

```
Pipeline.Render(encoder, view, outputTexture, outputTextureView, frameIndex):
  1. Upload scene uniforms (per-frame, double-buffered)
  2. Upload light data to LightBuffer
  3. Rebuild frame bind group (scene uniforms + light buffer)
  4. Process deferred GPU resource deletions
  5. renderGraph.BeginFrame(frameIndex)
  6. If post-processing active:
       Import caller's output as "FinalOutput"
       Create transient "PipelineOutput" (HDR, internal)
     Else:
       Import caller's output as "PipelineOutput"
  7. Each PipelinePass.AddPasses(graph, view, pipeline)
     (ForwardOpaquePass uses LoadOp.Clear - no separate clear pass needed)
  8. PostProcessStack.Execute() chains: PipelineOutput -> effects -> FinalOutput
  9. renderGraph.Execute(encoder)
  10. renderGraph.EndFrame()
```

The caller (application) clears the output target before calling Render().
The transient HDR texture (post-processing path) is cleared by ForwardOpaquePass's
LoadOp.Clear - no explicit ClearOutput pass.

## PipelinePass

Base class for all pipeline stages. A pass adds one or more render graph nodes
(render, compute, or copy). The render graph handles ordering based on resource
dependencies - no explicit dependency declarations needed.

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

### Registered Passes (execution order)

| Pass | Type | Reads | Writes | Description |
|------|------|-------|--------|-------------|
| SkinningPass | Compute | SkinnedMesh VBs | Skinned output VBs | Pre-skins vertices for all downstream passes |
| DepthPrepass | Render | - | SceneDepth | Depth-only for opaque, establishes early-Z |
| ForwardOpaquePass | Render | SceneDepth | PipelineOutput, SceneNormals, MotionVectors | PBR lit opaque + masked (MRT: 3 color targets) |
| DecalPass | Render | SceneDepth (sampled) | PipelineOutput | Projected decals via depth reconstruction |
| SkyPass | Render | SceneDepth | PipelineOutput | HDR sky, fills where depth == far |
| ForwardTransparentPass | Render | SceneDepth | PipelineOutput | Transparent + sprites, alpha blend, back-to-front |
| ParticlePass | Render | SceneDepth (ReadDepth + ReadTexture) | PipelineOutput | Particles with depth testing + soft fade |
| DebugPass | Render | SceneDepth | PipelineOutput | 3D debug lines with depth test |
| OverlayPass | Render | - | PipelineOutput | 2D text + rectangles, no depth |

Sky runs between opaque and transparent so transparent/sprite draws
blend over the sky backdrop rather than being overwritten by it.

ParticlePass declares both ReadDepth and ReadTexture on SceneDepth, which
transitions the depth buffer to DEPTH_STENCIL_READ_ONLY_OPTIMAL - allowing
simultaneous depth testing and soft-particle shader sampling. Particles render
in their own Particle category (not Transparent) with a custom 4-set pipeline
layout (Frame + Depth + Material + DrawCall).

## Post-Processing

### PostProcessStack

Owned by Pipeline (per-view). Chains `PostProcessEffect` instances via render graph passes.

```
PostProcessStack.Execute(graph, view, sceneColor, sceneDepth, pipelineOutput):
  For each enabled effect:
    effect.AddPasses(graph, view, renderer, ctx)
    ctx.Input -> effect -> ctx.Output
  Last effect writes to pipelineOutput
```

All intermediate textures are render graph transients - no manual texture management.

### PostProcessEffect

Base class for effects. Each effect adds render graph passes that read from
`ctx.Input` and write to `ctx.Output`. Effects can produce auxiliary textures
(e.g., bloom -> "BloomTexture") via `ctx.SetAux()` for downstream effects.

### Active Effects

| Effect | Description |
|--------|-------------|
| BloomEffect | 5-level downsample/upsample chain. Produces "BloomTexture" aux via ctx.SetAux. Does NOT modify the main chain (ctx.Output = ctx.Input). |
| TonemapEffect | ACES filmic. Composites BloomTexture in HDR space (hdr += bloom) before tone curve. Falls back to 1×1 black when bloom is absent. |

### Bloom Compositing Design

Bloom must be added to the scene color in **HDR space before tone mapping**.
If added after tonemapping (in LDR), the bloom values would clip at 1.0 and
the soft glow would look harsh and banded. The HDR range that makes bloom
look natural would be lost.

The compositing is merged into the TonemapEffect shader (`hdr += bloom` then
ACES) as an optimization - one fewer fullscreen pass vs a separate composite
step. This couples tonemap to the "BloomTexture" aux, but the fallback to a
black texture means tonemap works unchanged when bloom is disabled.

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

All render data types are classes inheriting from `RenderData` (abstract base).
Allocated from RenderContext.FrameAllocator - trivially destructible, valid
for one frame only.

- `MeshRenderData` - GPUMeshHandle, submesh index, world + prev world matrices, material bind group, IsSkinned
- `LightRenderData` - type (directional/point/spot), color, intensity, direction, range, shadow config, ShadowIndex
- `DecalRenderData` - world + inverse world matrices, color, angle fade, material bind group
- `SpriteRenderData` - position, size, tint, UV rect, orientation mode, material bind group

No entity/component references - just GPU handles and flat data.

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
Application.PresentFrame():
  1. Wait frame fence, reset command pool, create encoder
  2. Clear output target (render pass with LoadOp.Clear)
  3. sceneRenderer.RenderScene(encoder, colorTarget, ..., frameIndex)
  4. Acquire swapchain image
  5. Blit output -> swapchain (BlitHelper fullscreen triangle)
  6. Run IOverlayRenderers (sorted by OverlayOrder)
  7. Transition swapchain to Present, submit, present
  8. Advance frame index

RenderSubsystem.RenderScene(encoder, colorTexture, colorTarget, w, h, frameIndex):
  1. viewPool.BeginFrame() - clears previous frame's render data lists
  2. renderContext.BeginFrame() - resets FrameAllocator + ShadowSystem
  3. Acquire main view from pool, populate from active camera
  4. ExtractIntoView(mainView) - runs all IRenderDataProviders
  5. SetupShadows(mainView) - allocate atlas regions per shadow caster,
     compute matrices, acquire shadow views, extract per shadow view
  6. pipeline.BeginFrame(frameIndex) + shadowPipeline.BeginFrame(frameIndex)
  7. RenderShadows(encoder, frameIndex) - ShadowPipeline.RenderAll(jobs)
  8. pipeline.Render(encoder, mainView, colorTexture, colorTarget, frameIndex)
  9. renderContext.DebugDraw.Clear()
  10. Transition output to ShaderRead (for blit sampling)
  11. Save current VP as PrevViewProjectionMatrix for next frame
```

RenderSubsystem implements `ISceneRenderer`. The application owns frame pacing
(fence, command pools, frame index), output textures, swapchain, blit, and
presentation. RenderSubsystem focuses purely on scene rendering.

EngineUISubsystem implements `IOverlayRenderer` and delegates to ScreenUIView.
The application queries both interfaces from Context at startup:
- `Context.GetSubsystemByInterface<ISceneRenderer>()` - first match
- `Context.GetSubsystemsByInterface<IOverlayRenderer>()` - all, sorted by OverlayOrder

### Cross-Subsystem Discovery

Any engine subsystem can provide render data by implementing IRenderDataProvider
on its scene modules:

```
Engine.Render     -> MeshComponentManager : IRenderDataProvider
Engine.Render     -> SkinnedMeshComponentManager : IRenderDataProvider
Engine.Render     -> LightComponentManager : IRenderDataProvider
Engine.Render     -> SpriteComponentManager : IRenderDataProvider
Engine.Render     -> DecalComponentManager : IRenderDataProvider
Engine.Particles  -> ParticleComponentManager : IRenderDataProvider (future)
```

### Visibility / Culling (Future)

Currently: providers extract everything.
Future: scene-level spatial structure (octree/BVH) produces a visibility set.
The `RenderExtractionContext` will carry the visibility set. Providers check it.
Culling is centralized - one frustum test per entity, not per component type.

## GPU Resource Management

### GPUResourceManager

Handle-based pool of GPU resources (meshes, textures, bone buffers):

- `UploadMesh(MeshUploadDesc)` -> `GPUMeshHandle`
- `UploadTexture(TextureUploadDesc)` -> `GPUTextureHandle`
- `CreateBoneBuffer(boneCount)` -> `GPUBoneBufferHandle`
- Reference counting + deferred deletion (safe for in-flight frames)
- Scene-independent - takes raw data, returns handles

### PipelineStateCache

Creates GPU render pipeline objects on demand from `PipelineConfig`:

- Key: shader + vertex layout + render state + target format
- `GetPipeline(config, vertexBuffers, materialLayout, colorFormat)` -> cached pipeline
- `GetPipelineForMaterial(material, ...)` -> derives config from MaterialInstance
- Caches pipeline layouts for the 4-level bind group model
- Owned by Renderer (shared across pipelines)

## Bind Group Frequency Model

Shaders use HLSL register spaces 0-4 by convention:

| Set | Space | Frequency | Contents | Rebuilt |
|-----|-------|-----------|----------|---------|
| 0 | space0 | Per-frame | VP matrices (incl. PrevVP), time, lights. Dynamic offset for scene UBO ring buffer | Once per view |
| 1 | space1 | Per-pass | Pass-specific inputs (e.g., SceneDepth for decals) | Once per pass |
| 2 | space2 | Per-material | Textures, params, samplers | On material change |
| 3 | space3 | Per-draw | Object/decal transforms (dynamic offset into ring buffer) | Per draw call |
| 4 | space4 | Shadow | Shadow atlas + comparison sampler + ShadowDataBuffer | Once per frame |

No shader reflection - convention-based. Shaders put resources in the right space,
renderer builds matching layouts in code. DecalRenderer uses its own 4-set pipeline
layout (no shadow set) with depth sampling at set 1.

## Material System

`MaterialSystem` manages material bind groups, default textures, and per-instance GPU resources.
Owned by Renderer. Key operations:

- `PrepareInstance(MaterialInstance)` - creates/updates uniform buffer + bind group
- `GetOrCreateLayout(Material)` - builds bind group layout from material property definitions
- `ReleaseInstance(MaterialInstance)` - frees GPU resources for an instance
- Provides default textures (white, normal, black, depth) for unset material slots

Materials are created via factory methods in `Materials` static class:
- `CreatePBR(name, shader, albedo, sampler)` - standard PBR
- `CreateUnlit(name, shader)` - emissive only
- `CreateSkybox(name, shader, cubemap, sampler)` - cubemap sky
- `CreateSprite(name, shader, texture, sampler)` - 2D sprites

## Shader System

`ShaderSystem` handles compilation and caching (memory -> disk -> compile from source).
Created by EngineApplication, set on Renderer.

Shaders are HLSL files in `Assets/shaders/`. The system auto-discovers source paths
and caches compiled SPIRV/DXIL to `Assets/cache/shaders/`.

### Shader Inventory

| Shader | Purpose |
|--------|---------|
| forward | PBR lit geometry with MRT output (color + normals + velocity), shadow sampling |
| depth_only | Depth prepass + shadow depth rendering |
| fullscreen | Shared fullscreen-triangle vertex shader for all post-process passes |
| blit | Fullscreen copy to swapchain |
| tonemap | ACES tone mapping + bloom composite (frag only, uses fullscreen vert) |
| bloom_downsample | 13-tap downsample with threshold extract (frag only) |
| bloom_upsample | 9-tap tent upsample + blend (frag only) |
| sky | Equirectangular HDR sky + procedural fallback |
| sprite | GPU-instanced billboard sprites (SV_VertexID quad + per-instance data) |
| decal | Projected decals via depth reconstruction (cube SV_VertexID + depth sample) |
| debug_line | Unlit colored lines for DebugDraw |
| debug_overlay | 2D screen-space text + rectangles via DebugFont atlas |
| skinning | Compute shader for vertex skinning (72->48 byte transform) |
| unlit | Unlit/emissive rendering |

## Blit / Presentation

`BlitHelper` copies the scene output to the swapchain via a fullscreen triangle shader.
The application (EngineApplication) owns the blit helper, swapchain, and output textures.
RenderSubsystem has no knowledge of presentation.

```
Application clears   -> ColorTarget (RGBA16Float, black)
RenderScene()        -> Pipeline renders to ColorTarget
                       + SceneNormals (RG16Float, view-space XY)
                       + MotionVectors (RG16Float, screen-space delta)
  -> PostProcessStack -> BloomEffect (produces BloomTexture aux, passes main through)
                     -> TonemapEffect (composites bloom in HDR, ACES curves)
                     -> FinalOutput (RGBA16Float, linear LDR)
                     ColorTarget transitioned to ShaderRead
BlitHelper.Blit()    -> Swapchain (BGRA8UnormSrgb, sRGB gamma applied by hardware)
IOverlayRenderers    -> Screen UI, debug HUD composited with LoadOp.Load
Present              -> Screen
```

## Profiling

Profiler scopes instrument the render path:

```
Pipeline.Render
  UploadUniforms
  RenderGraph.Execute
    GPUSkinning
    DepthPrepass
    ForwardOpaque
    DecalPass
    Sky
    ForwardTransparent
    DebugLines
    Overlay
    Bloom (downsample chain + upsample chain)
    Tonemap
  Blit
ShadowSetup
ShadowRender
  ShadowPipeline.RenderAll
SceneExtraction
```

Press P at runtime to print a sorted profile frame with init time.
