# Sedulous Architecture

Living document describing the full engine architecture - foundation libraries,
rendering pipeline, engine subsystems, application models, and how they compose.

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Applications                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌─────────────┐ │
│  │ Game          │  │ Editor        │  │ UISandbox     │  │ RHI Sample  │ │
│  │ (Engine.App)  │  │ (Editor.App)  │  │ (Rt.Client)   │  │ (Rt.Client) │ │
│  │ full engine   │  │ multi-window  │  │ UI framework  │  │ raw GPU     │ │
│  │ auto-subsys   │  │ viewports     │  │ no engine     │  │ no engine   │ │
│  └──────┬────────┘  └──────┬────────┘  └──────┬────────┘  └──────┬──────┘ │
├─────────▼──────────────────▼──────────────────▼──────────────────▼─────────┤
│  Engine Layer (Sedulous.Engine.*)                                           │
│  Context + Subsystems: Input, Physics, Animation, Audio, Navigation,       │
│  Render (ISceneRenderer), UI (IOverlayRenderer)                            │
│  EngineApplication owns swapchain, output targets, frame pacing, blit      │
├─────────────────────────────────────────────────────────────────────────────┤
│  Scene Layer (Sedulous.Scenes)                                              │
│  Entity handles, ComponentManager<T>, hierarchical transforms,              │
│  SceneModule lifecycle, serialization                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  Renderer Layer (Sedulous.Renderer)                                         │
│  RenderContext (shared) + Pipeline (per-view passes) + PostProcessStack     │
│  Materials, PipelineStateCache, Shadows, Particles                          │
│  ISceneRenderer / IOverlayRenderer interfaces                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Foundation Layer                                                           │
│  RHI (Vulkan, DX12)  │  Shell (SDL3)  │  VG + Fonts  │  UI + Toolkit      │
│  Resources  │  Jobs  │  Shaders  │  Physics (Jolt)  │  Audio  │  Animation │
│  Core.Mathematics  │  Serialization  │  Imaging  │  Geometry  │  Profiler  │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Foundation Layer

Self-contained libraries with no engine dependency. Can be used independently
in tools, sandboxes, and tests.

### Core

| Library | Purpose |
|---------|---------|
| **Sedulous.Core** | Base abstractions, common utilities |
| **Sedulous.Core.Mathematics** | Vector, Matrix, Quaternion, Ray, Plane, BoundingBox, Transform |
| **Sedulous.Core.Collections** | Extended data structures |
| **Sedulous.Core.Logging** | ILogger abstractions |

### Platform Abstraction

| Library | Purpose |
|---------|---------|
| **Sedulous.Shell** | Platform abstraction - IShell, IWindow, IWindowManager, IInputManager (keyboard, mouse, gamepad, touch), IClipboard, CursorType |
| **Sedulous.Shell.SDL3** | SDL3 implementation of IShell (cross-platform) |

### Rendering Hardware Interface (RHI)

WebGPU-inspired but lower-level. Interface-based - backends are swappable.

| Library | Purpose |
|---------|---------|
| **Sedulous.RHI** | Core interfaces: IBackend, IDevice, IQueue, ICommandEncoder, IRenderPassEncoder, IBuffer, ITexture, ISwapChain, IFence, IPipeline, IBindGroup. Descriptors and enums for all resources |
| **Sedulous.RHI.Vulkan** | Vulkan backend (via Bulkan binding) |
| **Sedulous.RHI.DX12** | DirectX 12 backend (via Win32 binding) |
| **Sedulous.RHI.Validation** | Debug validation wrapper for any backend |
| **Sedulous.RHI.Null** | No-op backend for headless/testing |

### Runtime Framework

| Library | Purpose |
|---------|---------|
| **Sedulous.Runtime** | Context (subsystem registry + lifecycle), Subsystem base class (UpdateOrder, OnInit/OnReady/OnPrepareShutdown/OnShutdown), interface-based subsystem queries |
| **Sedulous.Runtime.Client** | Application base class - lightweight app with Shell + RHI + SwapChain. Owns device, window, frame loop. For sandboxes and tools that don't need the engine |
| **Sedulous.Jobs** | JobSystem singleton - runs jobs immediately, ProcessCompletions in Context update |
| **Sedulous.Resources** | ResourceSystem - async loading, caching, per-type ResourceManagers, hot-reload ready |
| **Sedulous.Profiler** | SProfiler - per-frame scoped profiling (BeginFrame/Begin/End) |

### Graphics & Rendering

| Library | Purpose |
|---------|---------|
| **Sedulous.Shaders** | ShaderSystem - HLSL compilation to SPIR-V/DXIL, shader pair loading, caching |
| **Sedulous.Renderer** | Scene-independent rendering: RenderContext, Pipeline, PipelinePass, PostProcessStack, PipelineStateCache, ISceneRenderer, IOverlayRenderer, IRenderDataProvider. Shadows, debug draw, sprites |
| **Sedulous.RenderGraph** | Dependency-driven render graph with transient texture pool, barrier solver |
| **Sedulous.Materials** | Material templates, MaterialInstance (ref-counted), bind group lifecycle |
| **Sedulous.Particles** | Self-contained particle system: CPU simulation, billboard/trail rendering, sub-emitters, LOD. ParticlePass + ParticleRenderer |
| **Sedulous.Geometry** | Mesh formats, vertex definitions, OBJ/glTF loading (via Tooling variant) |
| **Sedulous.Textures** | Texture metadata and resource types |
| **Sedulous.ImageData** | In-memory image abstractions (IImageData, OwnedImageData) |
| **Sedulous.Imaging** | Image loading - STB and SDL variants |
| **Sedulous.DebugFont** | Built-in bitmap font for debug text overlay |

### Vector Graphics & Text

| Library | Purpose |
|---------|---------|
| **Sedulous.VG** | NanoVG-inspired vector graphics - paths, fills, strokes, text layout. Draws to VGContext, produces VGBatch |
| **Sedulous.VG.Renderer** | GPU renderer for VGBatch (uploads + draws) |
| **Sedulous.VG.SVG** | SVG parsing and rendering |
| **Sedulous.Fonts** | FontService - font loading, glyph caching, atlas management |
| **Sedulous.Fonts.TTF** | TrueType support (stb_truetype) |

### UI Framework

| Library | Purpose |
|---------|---------|
| **Sedulous.UI** | Android-inspired retained-mode UI: View/ViewGroup/RootView hierarchy, MeasureSpec layout, theme system, input routing, animation, drag-drop, overlays. Renders via VGContext. No engine dependency - runs headless for tests |
| **Sedulous.UI.Shell** | Bridge: UIInputHelper (Shell -> UI input routing), InputMapping, ShellClipboardAdapter |
| **Sedulous.UI.Runtime** | UISubsystem for standalone apps (owns UIContext + VGRenderer). Used by UISandbox |
| **Sedulous.UI.Toolkit** | Advanced widgets: DockManager, SplitView, MenuBar, StatusBar, Toolbar, PropertyGrid, TreeView, ColorPicker, TabView (closable), DraggableTreeView, IFloatingWindowHost |
| **Sedulous.UI.Resources** | ThemeResource, UILayoutResource, ThemeXmlParser |

### Physics, Audio, Animation

| Library | Purpose |
|---------|---------|
| **Sedulous.Physics** | Physics abstractions (shapes, bodies, queries) |
| **Sedulous.Physics.Jolt** | Jolt Physics integration (multi-threaded, production-quality) |
| **Sedulous.Audio** | Audio abstractions (playback, mixing, spatial) |
| **Sedulous.Audio.SDL3** | SDL3 audio backend |
| **Sedulous.Animation** | Skeletal clips, animation graphs, property animation |
| **Sedulous.Scenes** | Scene, EntityHandle, ComponentManager<T>, Transform hierarchy, SceneModule, serialization |

### Serialization & Data

| Library | Purpose |
|---------|---------|
| **Sedulous.Serialization** | Base serialization interfaces |
| **Sedulous.Serialization.OpenDDL** | OpenDDL format provider |
| **Sedulous.Xml** | XML parsing |
| **Sedulous.OpenDDL** | OpenDDL parser |

## Application Models

### Runtime.Client.Application - Lightweight Apps

For sandboxes, tools, demos, and anything that needs Shell + RHI without the full engine.

**Owns:** Shell, Backend, Device, Window, SwapChain, CommandPools, Fence, DepthBuffer.

**Features:**
- Multi-window support (secondary windows with shared device)
- Fixed timestep simulation
- Frame pacing with configurable target framerate
- Asset directory discovery (searches up for "Assets" with ".assets" marker)
- Virtual hooks: OnInitialize, OnUpdate, OnRenderFrame, OnResize, etc.
- Can optionally create a Context with subsystems (e.g., UISubsystem)

**Used by:** UISandbox, VGSandbox, DrawingSandbox, AudioSandbox, FontRendering, RHI samples

### EngineApplication - Full Engine

For games and interactive applications with scenes, physics, rendering, audio, etc.

**Owns:** Shell, Backend, Device, Window + all presentation (SwapChain, OutputTargets,
CommandPools, Fence, BlitHelper, frame index). Creates Context with all standard subsystems.

**Features:**
- Automatic subsystem registration (Input, Physics, Animation, Audio, Navigation, UI, Render)
- ShaderSystem initialization
- Presentation pipeline: clear -> ISceneRenderer.RenderScene -> blit -> IOverlayRenderers -> present
- Caches ISceneRenderer + IOverlayRenderer queries at startup
- Scene management via SceneSubsystem
- Virtual hooks: OnConfigure, OnStartup, OnUpdate, OnShutdown

**Used by:** EngineSandbox, EngineRenderStressTest

### EditorApplication - Future Editor

Standalone app (not EngineApplication subclass). Creates its own RuntimeContext with
engine subsystems for preview. Owns the editor UI directly. See EditorRoadmap.md.

## Context and Subsystems

The `Context` is the central lifecycle hub. It owns subsystems and a resource system.
Subsystems are registered by type and updated in `UpdateOrder` priority.

**Subsystem** - 1 instance per application. Provides app-wide services.
**Scene Module (ComponentManager)** - 1 instance per scene. Owns per-scene data.

### Subsystem Update Order

| Subsystem | Order | Role | Interfaces |
|-----------|-------|------|------------|
| InputSubsystem | -900 | Input device state | - |
| SceneSubsystem | -500 | Scene lifecycle, lockstep scene updates | - |
| PhysicsSubsystem | -100 | Owns Jolt physics engine | ISceneAware |
| AnimationSubsystem | 100 | Owns animation clip cache | ISceneAware |
| AudioSubsystem | 200 | Owns audio device, mixer | ISceneAware |
| NavigationSubsystem | 300 | Owns NavMesh settings | ISceneAware |
| EngineUISubsystem | 400 | Screen + world UI | ISceneAware, IWindowAware, IOverlayRenderer |
| RenderSubsystem | 500 | Scene rendering | ISceneAware, IWindowAware, ISceneRenderer |

### Subsystem Lifecycle

```
Context.Startup():
  for each subsystem: Init()    -> OnInit() - individual setup
  for each subsystem: Ready()   -> OnReady() - cross-subsystem wiring (all inits done)

Per frame:
  BeginFrame(dt)    -> InitializePendingComponents, poll input
  FixedUpdate(dt)   -> physics, navigation (0-N times per frame)
  Update(dt)        -> scene phases, gameplay, UI input
  PostUpdate(dt)    -> late updates, dirty view collection
  EndFrame()        -> minimal (RenderSubsystem no longer renders here)

Application.PresentFrame():
  -> clear output -> RenderScene -> blit -> overlays -> present

Context.Shutdown():
  PrepareShutdown() -> detach cross-references (all subsystems, reverse order)
  Shutdown()        -> OnShutdown() (reverse order)
```

OnReady runs after all OnInit calls. Safe to access other subsystems for wiring
(e.g., EngineUISubsystem registers WorldUIPass with Pipeline).
Mirror of OnPrepareShutdown (which detaches references before shutdown).

### Interface-Based Subsystem Queries

```beef
// First subsystem implementing the interface (searches in update order)
let renderer = context.GetSubsystemByInterface<ISceneRenderer>();

// All subsystems implementing the interface (sorted by update order)
let overlays = scope List<IOverlayRenderer>();
context.GetSubsystemsByInterface<IOverlayRenderer>(overlays);
```

Used by the application to find renderers without knowing concrete types.

## Rendering Architecture

The renderer is **scene-independent**. It receives flat render data and draws it.
Scene integration is a layer above (Engine.Render). The renderer can be used
standalone for sandboxes, tools, and tests without any scene infrastructure.

### RenderContext (Shared Infrastructure)

One per application. Owns GPU resources, systems, and registered per-type drawers:

- `GPUResourceManager` - meshes, textures, bone buffers with deferred deletion
- `MaterialSystem` - bind group lifecycle, default textures, per-instance GPU resources
- `PipelineStateCache` - cached GPU pipelines by config hash, MRT support
- `LightBuffer` - per-frame light data upload (max 128 lights)
- `ShadowSystem` - hierarchical shadow atlas + shadow data buffer + comparison sampler
- `SkinningSystem` - compute skinning dispatch + per-mesh output buffers
- `SpriteSystem` - shared sprite material template + per-frame instance buffers
- `DebugDrawSystem` + `DebugDraw` - font atlas + per-frame vertex buffers, immediate-mode API
- `FrameAllocator` - per-frame bump allocator for render data
- Registered renderers (MeshRenderer, SpriteRenderer, DecalRenderer, ParticleRenderer)
- Shared bind group layouts (Frame set 0, DrawCall set 3, Shadow set 4)

### Pipeline (Per-View Execution)

Lightweight per-view pass execution engine. Owns:
- List of `PipelinePass` objects
- `PostProcessStack` (optional)
- Per-frame resources (double-buffered uniform buffers + bind groups)
- `RenderGraph` instance
- Output dimensions (width/height) for internal transient sizing

The Pipeline renders to a **caller-provided output texture**. The application owns
the output target, clears it, and passes it to `Pipeline.Render()`.

#### Frame Flow

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

The caller clears the output target before calling Render(). The internal transient
HDR texture (post-processing path) is cleared by ForwardOpaquePass's LoadOp.Clear.

### Pipeline Passes

| Pass | Type | Reads | Writes | Description |
|------|------|-------|--------|-------------|
| SkinningPass | Compute | SkinnedMesh VBs | Skinned output VBs | Pre-skins vertices |
| DepthPrepass | Render | - | SceneDepth | Depth-only, establishes early-Z |
| ForwardOpaquePass | Render | SceneDepth | PipelineOutput, SceneNormals, MotionVectors | PBR lit opaque + masked (3 MRT targets) |
| DecalPass | Render | SceneDepth (sampled) | PipelineOutput | Projected decals via depth reconstruction |
| SkyPass | Render | SceneDepth | PipelineOutput | HDR sky, fills where depth == far |
| ForwardTransparentPass | Render | SceneDepth | PipelineOutput | Transparent + sprites, alpha blend |
| ParticlePass | Render | SceneDepth (ReadDepth + ReadTexture) | PipelineOutput | Particles with depth test + soft fade |
| DebugPass | Render | SceneDepth | PipelineOutput | 3D debug lines with depth test |
| OverlayPass | Render | - | PipelineOutput | 2D text + rectangles, no depth |

### Post-Processing

`PostProcessStack` chains `PostProcessEffect` instances via render graph passes:

| Effect | Description |
|--------|-------------|
| BloomEffect | 5-level downsample/upsample chain. Produces "BloomTexture" aux. |
| TonemapEffect | ACES filmic. Composites bloom in HDR space before tone curve. |

Bloom is composited in **HDR space before tone mapping** - the soft glow preserves
HDR range. Merged into the TonemapEffect shader (`hdr += bloom` then ACES) for efficiency.

### Shadows

- Hierarchical shadow atlas (4096², 3 tiers: Large 2048²×2, Medium 1024²×4, Small 512²×16)
- Cascaded directional (4 cascades, sphere-fit ortho, 15% blend zone)
- Point cubemap (6 faces, 92.3° FOV for seam overlap)
- Spot (single perspective)
- ShadowPipeline - standalone per-view pipeline, single RenderAll(jobs) per frame
- 5×5 box PCF with hardware DepthBias + SlopeScale

### Presentation

The application owns presentation - RenderSubsystem has no swapchain knowledge.

```
Application.PresentFrame():
  1. Wait frame fence, reset command pool, create encoder
  2. Clear output target (render pass with LoadOp.Clear)
  3. sceneRenderer.RenderScene(encoder, colorTarget, ..., frameIndex)
     -> extraction + shadows + pipeline -> output in ShaderRead state
  4. Acquire swapchain image
  5. Blit output -> swapchain (BlitHelper fullscreen triangle, tonemap shader)
  6. Run IOverlayRenderers (sorted by OverlayOrder, LoadOp.Load)
  7. Transition swapchain to Present, submit with fence, present
  8. Advance frame index
```

`BlitHelper` copies HDR pipeline output (RGBA16Float) to swapchain (BGRA8UnormSrgb)
via a fullscreen triangle with the "blit" shader. The application owns the BlitHelper.

### Render Data & Extraction

Render data is categorized for sorting and pass routing:

| Category | Sort | Purpose |
|----------|------|---------|
| Opaque | Front-to-back | Lit opaque geometry |
| Masked | Front-to-back | Alpha-tested (AlphaCutoff + discard) |
| Transparent | Back-to-front | Blended geometry |
| Sky | None | Sky rendering |
| Decal | Sort order | Projected decals |
| Light | None | Consumed by lighting system |
| Particle | Back-to-front | Particle rendering |

All render data types inherit from `RenderData` (abstract base). Allocated from
FrameAllocator - trivially destructible, valid for one frame only. No entity/component
references - just GPU handles and flat data.

#### Extraction Flow

```
RenderSubsystem.RenderScene(encoder, targets, frameIndex):
  1. viewPool.BeginFrame() - clears previous frame's data
  2. renderContext.BeginFrame() - resets FrameAllocator + ShadowSystem
  3. Acquire main view, populate from active camera
  4. ExtractIntoView(mainView) - runs all IRenderDataProviders
  5. SetupShadows(mainView) - allocate atlas, compute matrices, extract shadow views
  6. pipeline.BeginFrame(frameIndex) + shadowPipeline.BeginFrame(frameIndex)
  7. RenderShadows(encoder, frameIndex) - ShadowPipeline.RenderAll(jobs)
  8. pipeline.Render(encoder, mainView, outputTexture, outputView, frameIndex)
  9. DebugDraw.Clear()
  10. Transition output to ShaderRead
```

Any subsystem can provide render data by implementing `IRenderDataProvider`
on its scene modules (MeshComponentManager, LightComponentManager, etc.).

### Bind Group Frequency Model

| Set | Space | Frequency | Contents |
|-----|-------|-----------|----------|
| 0 | space0 | Per-frame | VP matrices, time, lights (dynamic offset ring buffer) |
| 1 | space1 | Per-pass | Pass-specific inputs (e.g., SceneDepth for decals) |
| 2 | space2 | Per-material | Textures, params, samplers |
| 3 | space3 | Per-draw | Object transforms (dynamic offset ring buffer) |
| 4 | space4 | Shadow | Shadow atlas + comparison sampler + ShadowDataBuffer |

Convention-based - no shader reflection. Shaders place resources in the right space.

### Shader Inventory

| Shader | Purpose |
|--------|---------|
| forward | PBR lit geometry with MRT output + shadow sampling |
| depth_only | Depth prepass + shadow depth |
| fullscreen | Shared fullscreen-triangle vertex shader |
| blit | Fullscreen copy to swapchain |
| tonemap | ACES + bloom composite |
| bloom_downsample | 13-tap downsample with threshold |
| bloom_upsample | 9-tap tent upsample + blend |
| sky | Equirectangular HDR + procedural fallback |
| sprite | GPU-instanced billboards (SV_VertexID) |
| decal | Projected decals via depth reconstruction |
| debug_line | Unlit colored lines |
| debug_overlay | 2D screen-space text + rectangles |
| skinning | Compute vertex skinning |
| unlit | Unlit/emissive rendering |

## Scene System

### Entity-Component Model

- **Entity** - lightweight handle (index + generation + Guid). No entity class.
- **Component** - ref type, pooled per type in ComponentManager<T>. Has `Initialized` flag.
- **ComponentManager<T>** - owns pool, registers update functions, handles lifecycle.
- **Transform** - not a component. Every entity has one. Hierarchical parent-child with dirty-flag propagation.

### Component Lifecycle

```
CreateComponent(entity)         -> OnComponentCreated (properties NOT set yet)
[app sets properties]           -> Shape, BodyType, clip refs, etc.
InitializePendingComponents()   -> OnComponentInitialized (properties set, safe for
                                   physics body creation, resource resolution)
[simulation runs]               -> FixedUpdate, Update phases
DestroyComponent() / entity     -> OnComponentDestroyed
```

InitializePendingComponents is called by Scene at the start of each frame
(in SceneSubsystem.BeginFrame) before FixedUpdate.

### Scene Update Phases

Run inside SceneSubsystem.Update(). Multiple scenes run in lockstep per phase.

```
1. Initialize      - init newly created components
2. PreUpdate        - physics results readback, input application
3. Update           - gameplay, AI, scene mutation
4. AsyncUpdate      - PARALLEL: independent per-component work (opt-in)
5. PostUpdate       - read async results, constraints, late logic
6. TransformUpdate  - propagate dirty transforms down hierarchy
7. PostTransform    - render extraction, spatial index update
8. Cleanup          - deferred entity/component destruction
```

### ISceneAware

Subsystems implement ISceneAware to inject their scene modules:

```beef
class RenderSubsystem : Subsystem, ISceneAware, ISceneRenderer
{
    void OnSceneCreated(Scene scene)
    {
        scene.AddModule(new MeshComponentManager());
        scene.AddModule(new CameraComponentManager());
        scene.AddModule(new LightComponentManager());
        // + Sprite, Decal, SkinnedMesh, Particle managers
    }
}
```

## Engine Modules

### Engine.Input
Subsystem-only (no components). InputSubsystem manages priority-ordered stack of
InputContexts with named InputActions and typed InputBindings (Key, MouseButton,
MouseAxis, GamepadButton, GamepadAxis, GamepadStick, CompositeBinding).

### Engine.Physics
PhysicsSubsystem creates JoltPhysicsWorld per scene. RigidBodyComponent with full
config (body type, mass, friction, ShapeConfig). FixedUpdate: kinematic sync -> step ->
dispatch contacts -> dynamic sync. RayCast with entity handle decoding.
Contact events: OnContactAdded (return false to reject), OnContactPersisted, OnContactRemoved.

### Engine.Animation
Three component types: SkeletalAnimationComponent (clip playback),
AnimationGraphComponent (state machine), PropertyAnimationComponent (property binders).
SkinnedMeshComponent decoupled - reads bone matrices from animation components.

### Engine.Audio
AudioSubsystem creates SDL3AudioSystem. Volume categories (Master × SFX/Music),
music streaming, one-shot API. AudioSourceComponent + AudioListenerComponent.
3D position sync in PostTransform.

### Engine.Navigation
NavMesh + NavMeshBuilder + NavMeshQuery + CrowdManager + TileCache (recastnavigation).
NavAgentComponent (radius, height, speed, move target). NavObstacleComponent.

### Engine.UI
EngineUISubsystem (IOverlayRenderer, ISceneAware). Screen-space: ScreenUIView
renders VG onto swapchain after blit. World-space: UIComponent + UIComponentManager
with per-component UIContext, render-to-texture via WorldUIPass, input raycasting
(CameraFacing, CameraFacingY, WorldAligned).

### Engine.Render
RenderSubsystem (ISceneRenderer, ISceneAware). Injects component managers per scene.
Extracts render data, sets up shadows, calls Pipeline.Render with application-provided
output targets. Does not own swapchain or presentation.

## Material Lifecycle

MaterialInstance is ref-counted (RefCounted base). Components call AddRef/ReleaseRef
via SetMaterial. GPU resources (bind group, uniform buffer) cleaned up in destructor
when last ref released. MaterialSystem.ClearCache detaches all instances before
destroying GPU resources.

## Serialization

Format-independent via ISerializerProvider:
```beef
context.Resources.SetSerializerProvider(new OpenDDLSerializerProvider());
```

SceneSerializer writes entities, transforms, hierarchy, components. Components
implement ISerializableComponent. ResourceType hash validates on load.

## Reference Engines

- **ezEngine** - extraction pattern, world modules, bind group frequency, component lifecycle
- **Traktor** - GatherView flat data bundle, deferred render context, entity renderer pattern
