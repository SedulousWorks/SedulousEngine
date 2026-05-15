# Renderer Roadmap

Targeted feature set for game-readiness. Not a port of the old renderer - each feature is implemented fresh with our ezEngine-inspired architecture.

## Current State

### Core Architecture
- **RenderContext/Pipeline split** - shared infrastructure (RenderContext) separated from per-view pass execution (Pipeline). IRenderingPipeline interface lets both Pipeline and ShadowPipeline dispatch through the same registered renderers
- **ISceneRenderer/IOverlayRenderer** - RenderSubsystem implements ISceneRenderer, EngineUISubsystem implements IOverlayRenderer. Application owns swapchain, output textures, frame pacing, and presentation. Pipeline receives output targets instead of owning them. OnReady lifecycle hook enables cross-subsystem wiring after all inits complete
- **ezEngine-style per-type drawers** - Renderer base class with `GetSupportedCategories()` + `RenderBatch()`. MeshRenderer, SpriteRenderer, DecalRenderer registered on RenderContext. Passes call `pipeline.RenderCategory(category)` which dispatches to all matching drawers
- **Polymorphic render data** - RenderData abstract class hierarchy (MeshRenderData, LightRenderData, DecalRenderData, SpriteRenderData). FrameAllocator (Sedulous.Core.Memory) provides per-frame bump allocation with Reset()
- **Per-view extraction** - RenderViewPool creates independent RenderView + ExtractedRenderData per view (main camera + shadow casters). Each view extracts independently for future per-view culling
- **RenderGraph with barrier solver** - ReadWrite access types, transient texture pool, persistent resources, hierarchical pass ordering

### Rendering
- **Forward PBR** with Cook-Torrance BRDF, directional/point/spot lights (max 128, LightBuffer)
- **Depth prepass** with early-Z -> forward pass handoff (ReadWrite so masked geometry writes depth)
- **Mini G-buffer** - ForwardOpaquePass writes 3 MRT targets: SceneColor (RGBA16F), SceneNormals (RG16F view-space XY), MotionVectors (RG16F screen-space delta). Always present for post-FX consumption (SSAO, TAA, motion blur)
- **Masked rendering** - BlendMode.Masked with AlphaCutoff + discard, drawn in ForwardOpaquePass
- **Transparent rendering** - ForwardTransparentPass with alpha blending, back-to-front sorted
- **Sky rendering** - equirectangular HDR environment map with procedural gradient fallback. Runs after opaque but before transparent
- **Compute skinning** - SkinningSystem + SkinningPass pre-skins vertices via compute shader (72->48 bytes)
- **Decal rendering** - DecalRenderer draws unit cube, fragment shader reads SceneDepth, reconstructs world position, transforms to local decal space, clips + angle-fades. Own 4-set pipeline layout with depth sampling at set 1
- **GPU-instanced sprites** - SpriteRenderer uses SV_VertexID for quad corners + per-instance vertex buffer (64 B/sprite). Three orientation modes: CameraFacing, CameraFacingY, WorldAligned

### Shadows
- **Hierarchical shadow atlas** - 4096² Depth32Float, 3 tiers: Large (2048²×2), Medium (1024²×4), Small (512²×16)
- **Cascaded directional shadows** - 4-cascade PSSM with sphere-fit ortho, cascade blending at split boundaries (15% blend zone)
- **Point light cubemap shadows** - 6 cube faces, 92.3° FOV for seam overlap, face selection via dominant axis
- **Spot light shadows** - single shadow map per spot, perspective projection
- **ShadowPipeline** - standalone per-view pipeline. Single RenderAll(jobs) per frame
- **5×5 box PCF** - hardware DepthBias + SlopeScale prevents acne

### Post-Processing
- **PostProcessStack** - ordered effect chain. Auxiliary texture communication via ctx.SetAux/GetAux (ezEngine pipeline pin pattern)
- **SSAOEffect** - 16-sample hemisphere sampling with bilateral blur. Reads SceneDepth + SceneNormals, produces "AOTexture" aux (R8Unorm). Tonemap multiplies scene color by AO before tone curve
- **BloomEffect** - 5-level downsample/upsample chain. Produces "BloomTexture" aux without modifying the main chain. Bloom is composited in HDR space before tone mapping so the soft glow preserves HDR range
- **TAAEffect** - temporal resolve with history ping-pong, motion vector reprojection, neighborhood box clamping (ClipToAABB), luminance-adaptive blend. Halton(2,3) jitter applied to projection matrix by Pipeline. MRT output to both chain and history buffer
- **TonemapEffect** - ACES filmic. Composites AOTexture + BloomTexture before the tone curve. Falls back to white/black textures when effects are inactive
- **FXAAEffect** - FXAA 3.11 quality variant. Spatial AA on LDR after tonemap. Luminance-based edge detection with 12-step directional search

### PBR Shading
- **Height-correlated Smith GGX** visibility (joint approximation) for accurate specular
- **Fresnel firefly prevention** via F90 clamping: `saturate(50 * luminance(F0))`
- **Geometric specular AA** (Tokuyoshi & Kaplanyan 2019) - ddx/ddy normal-based roughness widening

### Debug & Development
- **DebugDraw** - immediate-mode API: lines, wire shapes, screen text/rects, 3D-positioned text
- **Light debug gizmos** - auto-drawn per light type (directional arrow, point sphere, spot cone)
- **Camera fly-through** - WASD + Q/E + right-click look + Tab capture

### Infrastructure
- **MaterialSystem** - flexible material templates, bind group lifecycle, default textures
- **PipelineStateCache** - on-demand pipelines, MRT support (ColorFormats[MaxColorAttachments])
- **Resource pipeline** - RenderResourceResolver with texture cache, ResolvedResource<T> change detection
- **Scene PrevWorldMatrix** - per-entity previous frame transform for motion vectors
- **5-set bind group model** - Frame (0), RenderPass (1), Material (2), DrawCall (3), Shadow (4)
- **Profiler instrumentation** - press P for profile frame

## Multi-Scene Rendering

ISceneRenderer uses an explicit `BeginRendering`/`EndRendering` frame wrapper.
`BeginRendering` resets shared per-frame state once (frame allocator, view pool,
shadow atlas, shadow pipeline ring buffers). Multiple `RenderScene` calls
between begin/end share the shadow atlas and frame allocator without clobbering
each other. Each scene renders only its own shadow jobs via range-based dispatch.

Per-scene resources on Pipeline (not shared on RenderContext):
- **LightBuffer** - each scene uploads its own lights; forward pass binds the
  pipeline's buffer. Prevents lighting bleed between scenes.
- **Line vertex buffers** - each pipeline has its own per-frame debug line VBs.
  DebugPass uploads merged local+global vertices into the pipeline's buffer.
  Prevents gizmo/debug draw bleed between scenes.
- **PrevViewProjectionMatrix** - each pipeline tracks its own camera history
  for correct per-scene motion vectors.

Shared on RenderContext (read-only or spatially partitioned):
- Shadow atlas (each scene gets different cells)
- Shadow data buffer (cumulative writes, indices preserved)
- PipelineStateCache, MaterialSystem, GPUResources, SkinningSystem
- DebugDrawSystem font atlas + overlay vertex buffers (screen-space, not per-scene)

The editor additionally skips rendering for viewports in inactive dock tabs
(`IsViewEffectivelyVisible` ancestor walk) to avoid unnecessary GPU work.

## Phase 5: Tone Mapping & Post-Processing Foundation

HDR pipeline outputs RGBA16Float - need tone mapping at minimum to see correct colors.

### 5.1 - PostProcessStack + TonemapEffect
Build the post-processing infrastructure and first effect together.

**PostProcessStack** (`Sedulous.Renderer/src/PostProcessStack.bf`):
- Owned by Pipeline (per-view, since Pipeline is per-view)
- Ordered list of `PostProcessEffect` instances
- `Execute(graph, view, renderer, sceneColor, sceneDepth)` -> returns final output handle
- Manages ping-pong: creates transient intermediates, last effect writes to PipelineOutput
- Pass-through when empty (no effects -> scene color flows directly to blit)

**PostProcessEffect** (`Sedulous.Renderer/src/PostProcessEffect.bf`):
- Base class for effects, simpler than PipelinePass
- `AddPasses(graph, view, renderer, ctx)` - adds render graph passes
- `DeclareOutputs(ctx)` - register auxiliary textures (e.g., bloom -> "BloomTexture")
- PostProcessContext provides: Input handle, Output handle, SceneDepth, aux texture map
- Effects hold GPU state (shaders, constant buffers), built once, parameters updated per-frame

**TonemapEffect** (`Sedulous.Renderer/src/Effects/TonemapEffect.bf`):
- First concrete effect - ACES filmic tone mapping + gamma correction
- Reads ctx.Input (HDR), optional ctx.GetAux("BloomTexture")
- Writes ctx.Output (LDR)
- Properties: Exposure (manual), WhitePoint
- Shader: `tonemap.frag.hlsl` - fullscreen triangle

**Configuration model:**
- Code-driven now: `pipeline.PostProcessStack.AddEffect(new TonemapEffect())`
- RenderSubsystem builds default stack when creating pipeline
- Future: CameraComponent holds PostProcessProfile (data), RenderSubsystem resolves to runtime stack

### 5.2 - Bloom
- `BloomEffect` in `Sedulous.Renderer/src/Effects/`
- Gaussian pyramid: extract bright -> downsample chain -> upsample + blur chain
- Produces auxiliary "BloomTexture" via `ctx.SetAux()` - consumed by TonemapEffect
- Does NOT modify the main chain (passes through input -> output unchanged)
- Properties: Threshold, Intensity, Radius

### 5.3 - Additional Effects (as needed)
- SSAO, DoF, motion blur, color grading - each a PostProcessEffect
- Added to the stack in order, chained automatically

**Dependencies:** None. Can start immediately.

## Phase 6: Transparency & Masked Rendering

### 6.1 - Masked Pass
- Fold into ForwardOpaquePass or create separate pass
- Same shader (forward.frag.hlsl already has `AlphaCutoff` + `discard`)
- Processes `RenderCategories.Masked` batch
- Depth write enabled (masked geometry is opaque after cutoff)
- Front-to-back sorting (same as opaque)

### 6.2 - Transparent Forward Pass
- New `TransparentForwardPass`
- Reads SceneDepth (depth test, no write)
- Processes `RenderCategories.Transparent` batch
- Back-to-front sorting (already defined in RenderCategories)
- Alpha blending enabled
- Same forward PBR shader, different pipeline state (blend + depth read-only)

**Dependencies:** None. Can start immediately.

## Phase 7: Shadow Mapping

Architecture follows ezEngine: per-view shadow rendering through a separate
`ShadowPipeline`. Each shadow-casting light gets its own `RenderView` with
light-space matrices; per-view extraction (independent of the main view)
enables future frustum culling. Renderer registry moves to `RenderContext`
so both `Pipeline` and `ShadowPipeline` dispatch to the same `MeshRenderer`.

### 7.1 - Infrastructure
- `ShadowAtlas` - depth texture (default 2048×2048, configurable). Fixed-size
  cell allocator: 4×4 grid of 512×512 cells (16 cells), simple bitset.
- `ShadowSystem` - owned by `RenderContext`. Manages atlas + shadow data buffer
  + per-frame allocation. Provides shadow bind group.
- `GPUShadowData` - `LightViewProj`, `AtlasUVRect`, `Bias`, `NormalBias`,
  cascade metadata. Stored in a `StructuredBuffer<GPUShadowData>` indexed by
  `Light.ShadowIndex` (-1 = no shadow).
- `LightBuffer` gains `ShadowIndex` per light, populated after `ShadowSystem`
  allocates regions.
- New shadow bind group at **set 4**: t0=ShadowAtlas (depth, sampled),
  s0=shadow comparison sampler, t1=ShadowDataBuffer.
- Renderer registry moves from `Pipeline` to `RenderContext` (shared).
- Scene UBO becomes a ring buffer with dynamic offset (Frame layout binding 0)
  so each per-frame view can write its own scene uniforms.

### 7.2 - Spot light shadows
- `ShadowPipeline` standalone class (not a `Pipeline` subclass). Owns its own
  render graph + per-frame resources. `Render(encoder, shadowView, atlas, region)`
  imports the atlas, sets viewport/scissor to the region, dispatches Opaque +
  Masked categories with `RenderBatchFlags.None`.
- Atlas cleared once per frame via explicit clear pass at frame start
  (`ShadowSystem.BeginShadowFrame`); subsequent shadow renders use Load.
- Spot light view-proj computed from light pose, outer cone (FOV), range.
- `RenderSubsystem` flow: extract main view -> discover shadow casters -> build
  shadow `RenderView`s -> extract per shadow view -> ShadowPipeline.Render per
  view -> main `Pipeline.Render`.
- `forward.frag.hlsl` samples shadow atlas with PCF 3×3 hardware bilinear,
  applies per-light bias.

### 7.3 - Cascaded directional shadows
- 4 cascades per directional light. Splits computed via logarithmic + linear
  blend over the main view's near/far range.
- Per cascade: ortho projection fit around view-frustum slice transformed into
  light space.
- Each cascade allocates one atlas cell; one `GPUShadowData` per cascade,
  contiguous by cascade index.
- Fragment shader picks cascade by view-space depth comparison against split
  distances stored in `GPUShadowData`.

### 7.4 - Validation
- Sandbox: spot + directional shadow casters. Verify no peter-panning, no
  excessive self-shadow acne, correct cascade transitions.

### 7.5 - Deferred polish
- **Hierarchical allocator** with mixed cell sizes (e.g., 1024 for nearest
  cascade, 256 for distant spots). Replaces fixed 512 cell grid. Needed when
  shadow resolution per light varies meaningfully.
- Point-light cubemap shadows (6 atlas regions per light).
- Per-view frustum culling at extraction time (currently each view extracts
  all entries - same providers, no spatial filter yet).
- Receiver-plane depth bias / normal-offset bias polish.
- PCSS / VSM / contact-hardening as quality upgrades.

**Dependencies:** None, but large scope.

## Phase 8: Compute Skinning

Compute shader pre-skins vertices into a standard Mesh vertex buffer. All render
passes (depth, forward, shadow) draw skinned meshes as if they were static - no
shader variants needed. Renderer does not reference the animation project.

### 8.1 - SkinningSystem on Renderer
- `SkinningSystem` class owned by `Renderer` (shared infrastructure)
- Manages `SkinningInstance` per skinned mesh: output buffer, bind group, params buffer
- `CreateInstance(sourceVB, boneBufferHandle, vertexCount, boneCount)` -> SkinningInstanceHandle
- `DestroyInstance(handle)` - releases output buffer and bind group
- `GetSkinnedVertexBuffer(handle)` -> IBuffer (48 bytes/vertex, Mesh layout)
- Output buffers persist across frames (not recreated per dispatch)
- Shared across pipeline runs - multiple views reuse the same skinned buffers

### 8.2 - Compute Shader
- `skinning.comp.hlsl` - workgroup size 64
- Input: SkinnedVertex (72 bytes) as ByteAddressBuffer + bone matrices as StructuredBuffer
- Output: Mesh vertex (48 bytes) as RWByteAddressBuffer - strips joint indices/weights
- Blends 4 bones per vertex (indices packed as 4x uint16 in 2x uint32 = 8 bytes)
- Transforms position, normal, tangent by blended bone matrix
- Bind group: b0=SkinningParams, t0=BoneMatrices, t1=SourceVertices, u0=OutputVertices

### 8.3 - SkinningPass (PipelinePass, compute)
- Runs first in the pipeline, before DepthPrepass
- Iterates skinned meshes in render data
- For each: looks up SkinningInstance on Renderer.SkinningSystem, dispatches compute
- Render graph tracks compute-write -> vertex-read barriers automatically
- Pass itself is stateless - SkinningSystem owns all GPU resources

### 8.4 - Mesh Upload Changes
- `MeshUploadDesc` gets `IsSkinned` flag
- When set: GPUResourceManager adds `.Storage` to vertex buffer usage (compute read)
- `GPUMesh.IsSkinned` flag set on upload

### 8.5 - MeshRenderData Changes
- Add `GPUBoneBufferHandle BoneBufferHandle` - bone matrices (storage buffer)
- Add `SkinningInstanceHandle SkinningHandle` - maps to skinned output buffer
- Add `bool IsSkinned`

### 8.6 - ForwardOpaquePass / DepthPrepass Changes
- If `mesh.IsSkinned`: bind skinned vertex buffer from SkinningSystem (48 byte Mesh layout)
- Else: bind original vertex buffer
- Same shader, same pipeline - skinned output IS a standard Mesh vertex buffer

### 8.7 - SkinnedMeshComponent (Engine.Render)
- `SkinnedMeshComponent` + `SkinnedMeshComponentManager`
- Holds: Skeleton ref, AnimationPlayer ref, GPUBoneBufferHandle, SkinningInstanceHandle
- Each frame: evaluate animation -> compute skinning matrices -> upload to bone buffer
- Extraction: emits MeshRenderData with BoneBufferHandle + SkinningHandle + IsSkinned
- Bridge between animation (Sedulous.Animation) and renderer - Engine.Render references
  both but Renderer references neither

### 8.8 - Vertex Layout Update
- Pack bone indices as 4x uint16 in 2x uint32 (8 bytes, matches old engine)
- SkinnedMesh vertex stride: 72 bytes (down from 80)
- Update VertexLayoutHelper: SkinnedMeshAttributes uses Uint32x2 for joints

**Dependencies:** AnimationSubsystem needs to provide bone poses. Shader + SkinningSystem can be built independently.

**Dependencies:** AnimationSubsystem needs to provide bone poses. Shader + component can be built independently.

## Phase 9: Decals

### 9.1 - Decal Pass
- New `DecalPass` - runs after forward opaque, before transparent
- Reads SceneDepth to reconstruct world position
- Projects decal texture onto surfaces within the decal volume
- Processes `RenderCategories.Decal` batch (already sorted by SortOrder)

### 9.2 - Decal Shader
- `decal.frag.hlsl` - reconstructs world pos from depth, transforms into decal local space
- Clips pixels outside [0,1] decal volume
- Samples albedo texture, applies color tint and opacity
- Angle fade for surfaces facing away from decal projection direction
- DecalRenderData already has all needed fields (world matrix, inverse, color, angle fade)

### 9.3 - Decal Component
- `DecalComponent` + `DecalComponentManager` in Engine.Render
- Box volume in local space, projected along local -Z
- Material instance for decal texture
- Extracts as DecalRenderData via IRenderDataProvider

**Dependencies:** Needs depth buffer access (already available from prepass).

## Phase 10: Particles - DONE (core), with gaps

Self-contained particle system following ezEngine's ParticlePlugin pattern.
The core simulation, rendering, and resource pipeline are functional and
in production use, but several declared features on `ParticleRenderMode`
are stubs that fall through to `Billboard` - see "Missing render modes"
below. Authoring surface (editor) is complete.

### Architecture
- **Sedulous.Particles** - simulation + rendering, and resource pipeline. Depends on Core.Mathematics, RHI, Renderer, Materials, Resources, Serialization. (The previous `Sedulous.Particles.Resources` companion project was folded back into the parent once `Sedulous.Particles` was allowed to depend on `Sedulous.Resources`. Namespace `Sedulous.Particles.Resources` is preserved.)
- **Engine.Render** - ParticleComponent, ParticleComponentManager (IRenderDataProvider). Component holds only the effect ref; texture lives per-system on the asset.

### Simulation
- **ParticleStream abstraction** - `ParticleStream` base, `CPUStream<T>` (system memory), `GPUStream` (storage buffer stub). `ParticleStreamContainer` owns streams, provides typed accessors, handles swap-remove compaction
- **ParticleSimulator** base -> `CPUSimulator` (iterates behaviors on SoA arrays), `GPUSimulator` (compute dispatch stub)
- **ParticleSystem** - orchestrator owning emitter + behaviors + initializers + streams + simulator. Selects CPU/GPU backend based on SimulationMode + behavior support. LOD distance culling. Birth/death event collection for sub-emitters
- **ParticleEmitter** - spawning logic only (continuous, burst, combined). Spawn rate scaling by LOD
- **ParticleEffect** - top-level container grouping multiple ParticleSystems. SubEmitterLinks for cross-system event routing
- **ParticleEffectInstance** - runtime instance, routes sub-emitter events between systems
- **13 behaviors** - Gravity, Drag, Wind, Turbulence, Vortex, Attractor, RadialForce, VelocityIntegration, ColorOverLifetime, SizeOverLifetime, SpeedOverLifetime, AlphaOverLifetime, RotationOverLifetime
- **6 initializers** - Position (emission shape), Velocity, Lifetime, Color, Size, Rotation
- **Curves** - ParticleCurveFloat/Color/Vector2 with Hermite interpolation, factory methods
- **Emission shapes** - Point, Sphere, Hemisphere, Cone, Box, Circle, Edge with volume/surface/arc
- **Range values** - RangeFloat, RangeVector2, RangeColor for randomized initialization

### Rendering
- **ParticleRenderer** - Renderer subclass for Transparent category. Groups by material + blend mode, creates per-blend-mode pipeline variants, instanced draw (6 verts × N particles)
- **ParticleGPUResources** - per-frame instance buffers (CpuToGpu), material template, default bind group (white texture fallback)
- **ParticleRenderExtractor** - CPU-side extraction: streams -> ParticleVertex[] with sorting, stretched billboard projection, AABB computation
- **Particle shaders** - `particle.vert.hlsl` (SV_VertexID billboard + rotation + stretched), `particle.frag.hlsl` (texture × color)
- **Per-system blend mode** - ParticleBlendMode (Alpha, Additive, Premultiplied, Multiply) correctly applied to pipeline state

### Engine Integration
- **ParticleComponent** - holds the effect ref only (the runtime instance is created by the manager). No per-component texture; visuals come from each ParticleSystem on the asset.
- **ParticleComponentManager** - resolves the effect resource, walks the effect's systems each frame, resolves `system.TextureRef` per system, looks up (or creates) a shared MaterialInstance keyed by ITextureView (dedupes across all systems and components), and stores per-(component, system) material references. ExtractRenderData binds the per-system material when building each batch. LOD via stored camera position (one-frame delay).
- **RenderSubsystem** - registers ParticleRenderer + ParticleComponentManager automatically

### Render modes - status by value

`ParticleRenderMode` declares six values; five share the billboard draw
path and select orientation via a per-particle `RenderMode` field in
`ParticleVertex` read by the vertex shader. `Mesh` is the only value
still without an implementation.

| Value | Status | Notes |
|---|---|---|
| `Billboard` | ✅ DONE | Camera-facing with per-particle rotation around the camera forward axis. |
| `StretchedBillboard` | ✅ DONE | Elongated along velocity. The extractor only sets `Velocity2D` for this mode, and the shader uses a non-zero `Velocity2D` as the implicit gate, so this branch takes precedence over the explicit `RenderMode` value when present. |
| `HorizontalBillboard` | ✅ DONE | Quad in the XZ plane with normal +Y. Per-particle rotation spins around the Y axis. Ground decals, shockwaves, dust puffs. |
| `VerticalBillboard` | ✅ DONE | World-up locked; right is horizontal-camera-facing (with a degenerate-camera fallback when looking straight up/down). Rotation intentionally skipped - grass / flame sprites typically don't roll. |
| `Trail` | ⚠️ Partial | Separate trail shader + draw path (`particle_trail.vert/frag.hlsl`), camera-facing ribbon mesh generation. Two rough edges: (1) the trail only records when both `RenderMode == .Trail` **and** `system.Trail.IsActive == true` - the second isn't implied by the first, so changing render mode alone produces nothing visible. (2) The billboard draw loop has no `RenderMode` filter, so trail particles still render their head sprite alongside the ribbon. Acceptable if you want a comet/meteor head, surprising if you wanted trail-only. Worth a small follow-up: either auto-enable `Trail.IsActive` when `RenderMode == .Trail` is selected (or hide the flag), and decide whether to suppress the billboard head for trail mode. |
| `Mesh` | ❌ TODO | Significant new work - see "Missing: Mesh render mode" below. |

### Missing: Mesh render mode

`Mesh` is the one `ParticleRenderMode` value still falling through to the
billboard branch. It needs a parallel draw path, not just a shader
variant. Concrete work:

- **Foundation**: `[Property] [ResourceRefType(".mesh")] ResourceRef Mesh`
  on `ParticleSystem` alongside the existing `TextureRef`. Serializer
  round-trip via the same per-system serialize hook pattern.
- **Engine**: `ParticleComponentManager` resolves `system.MeshRef` per
  system (mirror of the per-system texture resolution), caches by
  `MeshResource`/vertex+index buffer pair.
- **Renderer**: separate draw path next to the billboard `Draw(6, count)`.
  Per-particle transform instance buffer (position + 3D rotation +
  scale, not the current billboard quad data). Instanced indexed draw
  over the resolved mesh's buffers. New vertex shader keyed on
  `RenderMode == Mesh` or compiled as a distinct shader (`particle_mesh`).
- **Extractor**: build per-particle transforms instead of billboard
  quad data when `RenderMode == .Mesh`. Likely a separate vertex
  layout (or extended `ParticleVertex` with an optional transform
  block).
- **Rotation upgrade**: current `RotationInitializer` and
  `RotationOverLifetimeBehavior` are 1D (rotation around the camera
  forward axis). Mesh particles want 3D rotation (quaternion or euler
  triplet). Either add new 3D variants or upgrade the existing ones
  to be 3D when render mode is Mesh.

Scope ~600-1000 LOC. 1-2 weeks of focused work. Worth a dedicated phase
when there's a real game need.

### Deferred
- **Grid-based atlas animation** - ParticleVertex already has TexCoordOffset/TexCoordScale fields. Needs AtlasColumns/AtlasRows/AtlasFPS/AtlasLoop on ParticleSystem and UV computation in ParticleRenderExtractor (port from old engine's CPUParticleEmitter atlas logic). Consider generic atlas format for shared use across particles, sprites, and UI
- ~~**Trail rendering**~~ DONE - per-particle ring buffer recording, camera-facing ribbon mesh generation, separate trail shader + draw path
- **GPU simulation** - GPUSimulator stub exists. Needs compute shaders per behavior, GPU compaction (prefix sum + scatter), GPU sorting (bitonic/radix for transparent). Start with additive-only GPU particles (no sort needed)
- ~~**Soft particles**~~ DONE - dedicated ParticlePass with ReadDepth + ReadTexture (DEPTH_STENCIL_READ_ONLY_OPTIMAL), depth linearization in fragment shader

## Phase 11: Sky

### 11.1 - Sky Pass Implementation
- Finish `SkyPass` (currently a stub)
- Cubemap skybox: sample environment cubemap, render at depth == far plane
- Uses `Materials.CreateSkybox()` (already exists)
- Shader: `skybox.vert/frag.hlsl` - position-only vertices, cubemap sample
- Depth test: LessEqual, no write (renders only where nothing else drew)

**Dependencies:** None. Small scope.

## Phase 12: Debug & Overlay Rendering

Immediate-mode debug drawing for development: lines, wireframes, bounding boxes, text. Essential for debugging physics, navigation, AI, and gameplay.

### 12.1 - DebugDraw API
- `DebugDraw` static class in `Sedulous.Renderer` - immediate-mode API
- `DrawLine(from, to, color)`, `DrawBox(bounds, color)`, `DrawSphere(center, radius, color, segments)`
- `DrawWireBox`, `DrawWireSphere`, `DrawFrustum`, `DrawAxis(transform, size)`
- `DrawText3D(position, text, color)` - screen-projected text at world position
- Accumulates vertices per frame into a transient buffer, flushed during render

### 12.2 - Debug Pass
- New `DebugPass` - runs after forward opaque (and after transparent once that exists)
- Renders lines with depth test (occluded lines dimmed or hidden)
- Unlit shader (position + color vertex format, already in `DebugVertex.bf`)
- Line list topology, no face culling
- Optional: depth-tested vs always-on-top modes

### 12.3 - Overlay Pass
- New `OverlayPass` - runs last, no depth test
- 2D screen-space drawing: text, rectangles, debug stats
- Uses `Sedulous.DebugFont` for text rendering (project already exists)
- Screen-space coordinate system (0,0 top-left)
- FPS counter, entity count, render stats (draw calls, triangles)

### 12.4 - Integration
- `DebugDraw` accessible from anywhere (static API, similar to ezEngine's `ezDebugRenderer`)
- Game code calls `DebugDraw.DrawBox(entity.Bounds, .Green)` during Update
- Renderer collects and renders all debug geometry at end of frame
- Compile-out or no-op in release builds via `#if DEBUG`

**Dependencies:** None. Can be implemented at any time. High value for development workflow.

## Phase 13: Sprites

Textured-quad rendering for billboards, in-world icons, 2D HUD elements, and
animated sprite sheets. Separate from the particle system (particles use their
own specialised billboard path) but shares the underlying quad rendering.

### 13.1 - Sprite Component + Data
- `SpriteComponent` in Engine.Render - owns texture ResourceRef, size, color,
  UV rect, orientation mode (camera-facing billboard, fixed axis, world-aligned)
- `SpriteRenderData : RenderData` - world matrix or world position, size,
  UV rect, material bind group, blend mode
- Animation: optional frame index + sprite-sheet UV rect override

### 13.2 - SpriteRenderer (per-type drawer)
- Extends the `Renderer` base class; registered against `Transparent` and
  (optionally) `Opaque` / `Masked` categories depending on the sprite's blend
- Batches sprites sharing a material into instanced draw calls
- Supports three orientation modes:
  - **Camera-facing** - quad vertices rotated to face the camera every frame
  - **World-aligned** - quad with fixed orientation in world space (decals-ish)
  - **Axis-aligned** - quad rotates around one world axis (e.g., Y for foliage)

### 13.3 - Shaders
- `sprite.vert.hlsl` - constructs quad corners from center + size + orientation
- `sprite.frag.hlsl` - texture sampling with color tint, alpha test / blend

### 13.4 - 2D/Screen-space sprites
- Screen-space mode for HUD: quad positioned in pixels, bypasses view-proj
- Bound in `OverlayPass` (Phase 12) or a dedicated `UIPass`

**Dependencies:** Transparency pass (Phase 6, done), Debug/Overlay (Phase 12)
for the 2D screen-space path. Quad rendering infrastructure is also useful for
particles later.

## Priority Order

Recommended implementation order based on dependencies and game impact:

1. ~~**Phase 5.1** - Tone mapping~~ DONE
2. ~~**Phase 11** - Sky~~ DONE
3. ~~**Phase 6** - Transparency + masked~~ DONE
4. ~~**Phase 8** - Compute skinning~~ DONE
5. ~~**Phase 7** - Shadows~~ DONE
6. ~~**Phase 7.5** - Shadow polish (point cubemap, hierarchical atlas, cascade blending)~~ DONE
7. ~~**Phase 12** - Debug & overlay rendering~~ DONE
8. ~~**Phase 13** - Sprites (GPU instanced, 3 orientation modes)~~ DONE
9. ~~**Phase 9** - Decals (depth-reconstructed projected decals)~~ DONE
10. ~~**Phase 5.2** - Bloom (downsample/upsample chain + tonemap composite)~~ DONE
11. ~~**Mini G-buffer** - SceneNormals + MotionVectors MRT~~ DONE
12. ~~**Phase 10** - Particles (self-contained system, CPU simulation, billboard rendering, sub-emitters, LOD)~~ DONE
13. ~~**Phase 5.3** - FXAA, TAA, SSAO~~ DONE (motion blur, color grading deferred)

## Shader hot-reload (TODO, newly tractable)

`Sedulous.Renderer` and `Sedulous.Particles` now depend on
`Sedulous.Resources` directly (the foundation-may-not-depend-on-Resources
rule was deliberately dropped for libraries that need cross-asset refs
and hot-reload - see EngineRoadmap "Hot Reload Resource Lifecycle"). That
unblocks turning shaders into first-class resources and getting in-editor
hot-reload for them, which has been deferred since the rule made the
plumbing awkward.

Concrete shape:

- **`ShaderResource`** wrapping the existing `ShaderModule` pair, owned
  by a `ShaderResourceManager` that loads source from disk via the
  `ResourceSystem` + the existing `ShaderCompiler`. The on-disk source
  files in `Assets/shaders/` become resource-system-addressable assets.
- **Hot reload**: ResourceSystem's `PollHotReload` already exists; the
  manager's `Reload(resource, ctx)` would re-read the source, recompile
  via the shader system's disk-cache-bypass path, swap the bound
  ShaderModule(s) in place, and increment Resource.Generation.
- **Pipeline cache invalidation**: `PipelineStateCache` keys on
  `ShaderName + ShaderHash`. Pipelines pinned to a specific shader
  generation get evicted when generation increments; next render
  recreates them. (Same generation-driven pattern materials already
  use.)
- **Subscription**: consumer renderers (mesh, particles, decals, etc.)
  subscribe to their specific shader resources via the per-handle
  subscription API TODO in `EngineRoadmap`. When fired, they invalidate
  their cached pipelines.
- **Editor wins**: live shader edits update the running viewport
  without restart. Particle/material/post-FX shader iteration goes from
  "edit, restart editor, re-open asset" to "edit, save, see result".

Scope ~300-500 LOC across Sedulous.Shaders + Sedulous.Renderer +
Sedulous.Resources (the per-handle subscription API is the main shared
dependency). The existing shader-compiler infrastructure handles disk
reads + caching + reflection already; this work is primarily wrapping
it in the Resource lifecycle.

## Architecture Notes

### ezEngine Patterns We Follow
- **Pipeline passes as graph nodes** - our PipelinePass + RenderGraph serves the same role as ezEngine's RenderPipelinePass with pins
- **Per-type drawers (ezRenderer pattern)** - Renderer base class with `GetSupportedCategories()` + `RenderBatch()`. Passes call `pipeline.RenderCategory(category)` which dispatches to all registered renderers. Adding a new render data type (e.g., ParticleRenderer) requires zero pass modifications - just register the renderer and it gets called automatically for its supported categories
- **Pull-based extraction** - IRenderDataProvider extracts render data from components, same as ezEngine's extractor system
- **Bind group frequency model** - Frame/RenderPass/Material/DrawCall/Shadow maps to ezEngine's resource binding hierarchy
- **Auxiliary textures (pipeline pins)** - PostProcessContext.SetAux/GetAux lets effects communicate side-channel textures. BloomEffect produces "BloomTexture" aux consumed by TonemapEffect
- **Separate particle project** - ezEngine's ParticlePlugin is a standalone module; our Sedulous.Particles follows the same split

### Post-Processing Design
- Bloom is composited in **HDR space before tone mapping** so the soft glow preserves HDR range. If added after tonemapping in LDR, bloom values would clip at 1.0 and the glow would look harsh
- The compositing happens inside the TonemapEffect shader (`hdr += bloom`) as an optimization - one fewer fullscreen pass vs a separate composite step. The two operations are logically distinct (bloom composite vs tone curve) but merged for efficiency
- When BloomEffect is absent, TonemapEffect binds a 1×1 black texture as bloom fallback so the shader works unchanged (hdr += black = no change)

### Resource Resolution (RenderResourceResolver)
Shared resource resolution service in Engine.Render, used by all render component managers.
Handles the resolve-upload-track pattern for meshes, materials, and textures.

- **Mesh resolution** - ResourceRef -> StaticMeshResource/SkinnedMeshResource -> GPU upload -> GPUMeshHandle
- **Material resolution** - ResourceRef -> MaterialResource -> MaterialInstance -> PrepareInstance (bind group)
- **Texture resolution** - ResourceRef -> TextureResource -> GPU upload -> ITextureView -> set on MaterialInstance
- **Standalone texture resolution** - ResolveTexture for sprites/decals needing direct texture views
- **Texture cache** - same texture used by multiple materials uploads once
- **Change detection** - BoundResource comparison handles first load and hot reload uniformly
- **ResolvedResource<T>** - generic tracking struct (handle + bound resource + resolve method)

Component managers (MeshComponentManager, SkinnedMeshComponentManager, DecalComponentManager,
SpriteComponentManager) call into the resolver instead of duplicating the resolve-upload-track logic.

### Masked Geometry and Depth Prepass

**Problem:** Overlapping alpha-tested geometry (foliage, fences) can produce
rendering artifacts if the depth prepass writes depth for the full quad rather
than just the visible pixels. The transparent regions of the quad block geometry
behind them since the depth buffer doesn't know about the alpha test.

**Current solution:** The depth prepass only renders `RenderCategories.Opaque`.
Masked geometry (`RenderCategories.Masked`) is skipped in the depth prepass and
only rendered in the forward pass where the fragment shader samples the albedo
texture and discards below `AlphaCutoff`. This matches the old renderer's
approach and is correct -- no stale depth from masked quads.

**Future optimization: alpha-tested depth prepass.** The `depth_only` fragment
shader is currently empty (depth written from SV_Position.z only). To give
masked geometry early-Z benefits:
- Add a `depth_only` shader variant with `AlphaTest` flag that samples the
  albedo texture and calls `discard` below the cutoff
- The depth prepass would render masked geometry with this variant, binding
  the material's albedo texture (requires `.BindMaterial` flag for masked category)
- Only pixels surviving the alpha test write depth
- Forward pass then benefits from early-Z for masked geometry
- Cost: extra texture sampling in depth prepass for masked materials

This is an optimization, not a correctness fix. Current behavior is correct.

### Per-Material Pipeline State in MeshRenderer

MeshRenderer now builds GPU pipeline variants per material, not per pass.
The pass provides shader name, formats, depth mode. The material provides
cull mode, blend mode, fill mode, shader flags. This enables double-sided
materials (`CullMode = .None`), per-material shader variants, and future
material-driven render state without pass-level changes.

Pipeline switches only occur when material render state differs between
batch groups. Same-state materials share one pipeline (no switch). The
`PipelineStateCache` handles caching by config hash.

### Known Issue: PipelineStateCache Keyed by Hash, Not Key Struct

`PipelineStateCache` uses `Dictionary<int, IRenderPipeline>` and
`Dictionary<int, IPipelineLayout>` keyed by the **computed hash value**
of `PipelineStateCacheKey`, not the struct itself. On cache lookup
(line 116), if two different pipeline configurations produce the same
hash, the second silently gets the first's pipeline - no `Equals` check
is ever performed.

Additionally, the `materialLayout` pointer is mixed into the hash
*after* `BuildKey()` (line 112-113), so even `PipelineStateCacheKey.Equals()`
wouldn't cover the full key if it were used.

The hash function uses `* 31` polynomial chains with small enum inputs,
so effective entropy is lower than the full 64-bit range. With typical
pipeline counts (< 100), collision probability is very low but nonzero.
A collision would cause silent rendering corruption (wrong blend mode,
wrong shader, wrong vertex layout) that would be extremely hard to
diagnose.

**Fix:** Key the dictionary on the full `PipelineStateCacheKey` struct
(extended to include materialLayout) so `Equals` handles collisions.
Or add a secondary equality check on cache hit.

### Known Issue: Validation Errors When No Scene Renders

When an application runs without calling `RenderScene` (e.g., empty app with
no scene created yet), the Pipeline Output color target remains in
`VK_IMAGE_LAYOUT_UNDEFINED`. The blit-to-swapchain pass attempts to sample it,
triggering validation errors about expected `SHADER_READ_ONLY_OPTIMAL` layout.

The engine should handle this gracefully -- either skip the blit when no scene
has rendered this frame, or transition the color target to a valid state (clear
+ transition) unconditionally in `PresentFrame` before the blit.

## Debug View Mode

Visualize intermediate render data in the viewport for debugging materials, lighting, and post-processing. Two complementary mechanisms:

### Shader Debug Output (per-pixel material properties)

A `DebugViewMode` enum field in the scene uniforms buffer. The forward shader checks it early and outputs a direct visualization instead of the full PBR calculation:

- **None** - normal rendering (default)
- **Albedo** - base color after texture × tint
- **WorldNormals** - world-space normals mapped to [0,1] RGB
- **Roughness** - grayscale roughness
- **Metallic** - grayscale metallic
- **Emissive** - emissive channel only
- **AO** - ambient occlusion (from material, not SSAO)

One `switch` in `forward.frag.hlsl` after material sampling, before PBR evaluation. No extra passes, no extra textures. Skips lighting entirely when a debug mode is active - outputs the raw value as the final color. MRT targets (normals, motion vectors) are still written normally so debug view doesn't break dependent passes.

### Pipeline Intermediate Blit (render graph textures)

For textures that exist as render graph intermediates - SceneDepth, SceneNormals, MotionVectors, AOTexture (SSAO), BloomTexture - a debug blit pass at the end of the pipeline replaces the final output with the selected texture. Reuses the existing fullscreen triangle infrastructure.

- **Depth** - linearized depth, near=white far=black
- **SceneNormals** - view-space normal XY from mini G-buffer
- **MotionVectors** - screen-space velocity, visualized as RG color
- **SSAO** - raw AO texture before composite
- **Bloom** - bloom texture before tonemap composite

### Integration

- `DebugViewMode` enum in `Sedulous.Renderer` covering both shader and blit modes
- Scene uniforms struct gets a `DebugMode` uint32 field (already uploaded per-frame per-view)
- `RenderSceneModule` gets a `[Property]` field for the mode - shows as dropdown in inspector when no entity is selected
- Editor viewport toolbar gets a debug view dropdown (separate from the inspector, for quick access)
- `ApplyRenderSettings` pushes the mode to the pipeline; Pipeline writes it to scene uniforms
- For blit modes, Pipeline checks the mode after post-processing and substitutes the output

### Principles
- Each feature targets what we actually need for the game
- Build features properly - follow established engine architecture patterns, not shortcuts that need rework later
- Test each phase with the sandbox before moving on
- Shader variants via `ShaderFlags` when needed (e.g., skinned vs static)
