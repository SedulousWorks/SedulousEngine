# Renderer Roadmap

Targeted feature set for game-readiness. Not a port of the old renderer — each feature is implemented fresh with our ezEngine-inspired architecture.

## Current State

- Forward PBR with Cook-Torrance BRDF
- Directional, point, and spot lights (max 128, LightBuffer)
- Depth prepass with early-Z → forward pass handoff
- MaterialSystem integration (bind group lifecycle, default textures)
- PBR texture sampling (albedo, normal, metallic/roughness, occlusion, emissive)
- Material instances with per-instance overrides
- PipelineStateCache for on-demand GPU pipeline creation
- RenderGraph with barrier solver, ReadWrite access types
- 8 render categories with sorting (Opaque, Masked, Transparent, Sky, Decal, Light, ReflectionProbe, GUI)
- GPU resource manager (meshes, textures, bone buffers with deferred deletion)
- SkinnedMesh vertex layout (80 bytes) and GPUBoneBuffer defined
- DecalRenderData defined
- Profiler instrumentation (Shift+P)
- **Renderer/Pipeline split** — shared infrastructure (Renderer) separated from per-view pass execution (Pipeline)
- **Post-processing stack** — PostProcessStack with TonemapEffect (ACES filmic), sRGB swapchain gamma
- **Masked rendering** — BlendMode.Masked with AlphaCutoff, drawn in ForwardOpaquePass
- **Transparent rendering** — ForwardTransparentPass with alpha blending, back-to-front sorted
- **Sky rendering** — Equirectangular HDR environment map with procedural gradient fallback
- **IModuleSerializer** — scene module-level serialization support (for non-entity scene data)
- **Compute skinning** — SkinningSystem + SkinningPass pre-skins vertices via compute shader (72→48 bytes), all passes draw skinned meshes as static
- **SkinnedMeshComponent** — owns AnimationPlayer, manager evaluates animation + uploads bone matrices + auto-creates bone buffer
- **Resource pipeline integration** — RenderSubsystem registers resource managers (StaticMesh, SkinnedMesh, Texture, Material); AnimationSubsystem registers Skeleton + AnimationClip managers
- **RenderResourceResolver** — shared service for mesh/material/texture resolution with GPU upload, texture cache, automatic MaterialInstance preparation
- **ResolvedResource<T>** — generic tracking for first load, deferred retry, and hot reload detection
- **Component ResourceRef pattern** — components store ResourceRef (deep-copy setters), managers resolve per-frame via resolver
- **Material ownership** — SetMaterial AddRefs, component destructor ReleaseRefs; resolver releases after handoff

## Phase 5: Tone Mapping & Post-Processing Foundation

HDR pipeline outputs RGBA16Float — need tone mapping at minimum to see correct colors.

### 5.1 — PostProcessStack + TonemapEffect
Build the post-processing infrastructure and first effect together.

**PostProcessStack** (`Sedulous.Renderer/src/PostProcessStack.bf`):
- Owned by Pipeline (per-view, since Pipeline is per-view)
- Ordered list of `PostProcessEffect` instances
- `Execute(graph, view, renderer, sceneColor, sceneDepth)` → returns final output handle
- Manages ping-pong: creates transient intermediates, last effect writes to PipelineOutput
- Pass-through when empty (no effects → scene color flows directly to blit)

**PostProcessEffect** (`Sedulous.Renderer/src/PostProcessEffect.bf`):
- Base class for effects, simpler than PipelinePass
- `AddPasses(graph, view, renderer, ctx)` — adds render graph passes
- `DeclareOutputs(ctx)` — register auxiliary textures (e.g., bloom → "BloomTexture")
- PostProcessContext provides: Input handle, Output handle, SceneDepth, aux texture map
- Effects hold GPU state (shaders, constant buffers), built once, parameters updated per-frame

**TonemapEffect** (`Sedulous.Renderer/src/Effects/TonemapEffect.bf`):
- First concrete effect — ACES filmic tone mapping + gamma correction
- Reads ctx.Input (HDR), optional ctx.GetAux("BloomTexture")
- Writes ctx.Output (LDR)
- Properties: Exposure (manual), WhitePoint
- Shader: `tonemap.frag.hlsl` — fullscreen triangle

**Configuration model:**
- Code-driven now: `pipeline.PostProcessStack.AddEffect(new TonemapEffect())`
- RenderSubsystem builds default stack when creating pipeline
- Future: CameraComponent holds PostProcessProfile (data), RenderSubsystem resolves to runtime stack

### 5.2 — Bloom
- `BloomEffect` in `Sedulous.Renderer/src/Effects/`
- Gaussian pyramid: extract bright → downsample chain → upsample + blur chain
- Produces auxiliary "BloomTexture" via `ctx.SetAux()` — consumed by TonemapEffect
- Does NOT modify the main chain (passes through input → output unchanged)
- Properties: Threshold, Intensity, Radius

### 5.3 — Additional Effects (as needed)
- SSAO, DoF, motion blur, color grading — each a PostProcessEffect
- Added to the stack in order, chained automatically

**Dependencies:** None. Can start immediately.

## Phase 6: Transparency & Masked Rendering

### 6.1 — Masked Pass
- Fold into ForwardOpaquePass or create separate pass
- Same shader (forward.frag.hlsl already has `AlphaCutoff` + `discard`)
- Processes `RenderCategories.Masked` batch
- Depth write enabled (masked geometry is opaque after cutoff)
- Front-to-back sorting (same as opaque)

### 6.2 — Transparent Forward Pass
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

### 7.1 — Infrastructure
- `ShadowAtlas` — depth texture (default 2048×2048, configurable). Fixed-size
  cell allocator: 4×4 grid of 512×512 cells (16 cells), simple bitset.
- `ShadowSystem` — owned by `RenderContext`. Manages atlas + shadow data buffer
  + per-frame allocation. Provides shadow bind group.
- `GPUShadowData` — `LightViewProj`, `AtlasUVRect`, `Bias`, `NormalBias`,
  cascade metadata. Stored in a `StructuredBuffer<GPUShadowData>` indexed by
  `Light.ShadowIndex` (-1 = no shadow).
- `LightBuffer` gains `ShadowIndex` per light, populated after `ShadowSystem`
  allocates regions.
- New shadow bind group at **set 4**: t0=ShadowAtlas (depth, sampled),
  s0=shadow comparison sampler, t1=ShadowDataBuffer.
- Renderer registry moves from `Pipeline` to `RenderContext` (shared).
- Scene UBO becomes a ring buffer with dynamic offset (Frame layout binding 0)
  so each per-frame view can write its own scene uniforms.

### 7.2 — Spot light shadows
- `ShadowPipeline` standalone class (not a `Pipeline` subclass). Owns its own
  render graph + per-frame resources. `Render(encoder, shadowView, atlas, region)`
  imports the atlas, sets viewport/scissor to the region, dispatches Opaque +
  Masked categories with `RenderBatchFlags.None`.
- Atlas cleared once per frame via explicit clear pass at frame start
  (`ShadowSystem.BeginShadowFrame`); subsequent shadow renders use Load.
- Spot light view-proj computed from light pose, outer cone (FOV), range.
- `RenderSubsystem` flow: extract main view → discover shadow casters → build
  shadow `RenderView`s → extract per shadow view → ShadowPipeline.Render per
  view → main `Pipeline.Render`.
- `forward.frag.hlsl` samples shadow atlas with PCF 3×3 hardware bilinear,
  applies per-light bias.

### 7.3 — Cascaded directional shadows
- 4 cascades per directional light. Splits computed via logarithmic + linear
  blend over the main view's near/far range.
- Per cascade: ortho projection fit around view-frustum slice transformed into
  light space.
- Each cascade allocates one atlas cell; one `GPUShadowData` per cascade,
  contiguous by cascade index.
- Fragment shader picks cascade by view-space depth comparison against split
  distances stored in `GPUShadowData`.

### 7.4 — Validation
- Sandbox: spot + directional shadow casters. Verify no peter-panning, no
  excessive self-shadow acne, correct cascade transitions.

### 7.5 — Deferred polish
- **Hierarchical allocator** with mixed cell sizes (e.g., 1024 for nearest
  cascade, 256 for distant spots). Replaces fixed 512 cell grid. Needed when
  shadow resolution per light varies meaningfully.
- Point-light cubemap shadows (6 atlas regions per light).
- Per-view frustum culling at extraction time (currently each view extracts
  all entries — same providers, no spatial filter yet).
- Receiver-plane depth bias / normal-offset bias polish.
- PCSS / VSM / contact-hardening as quality upgrades.

**Dependencies:** None, but large scope.

## Phase 8: Compute Skinning

Compute shader pre-skins vertices into a standard Mesh vertex buffer. All render
passes (depth, forward, shadow) draw skinned meshes as if they were static — no
shader variants needed. Renderer does not reference the animation project.

### 8.1 — SkinningSystem on Renderer
- `SkinningSystem` class owned by `Renderer` (shared infrastructure)
- Manages `SkinningInstance` per skinned mesh: output buffer, bind group, params buffer
- `CreateInstance(sourceVB, boneBufferHandle, vertexCount, boneCount)` → SkinningInstanceHandle
- `DestroyInstance(handle)` — releases output buffer and bind group
- `GetSkinnedVertexBuffer(handle)` → IBuffer (48 bytes/vertex, Mesh layout)
- Output buffers persist across frames (not recreated per dispatch)
- Shared across pipeline runs — multiple views reuse the same skinned buffers

### 8.2 — Compute Shader
- `skinning.comp.hlsl` — workgroup size 64
- Input: SkinnedVertex (72 bytes) as ByteAddressBuffer + bone matrices as StructuredBuffer
- Output: Mesh vertex (48 bytes) as RWByteAddressBuffer — strips joint indices/weights
- Blends 4 bones per vertex (indices packed as 4x uint16 in 2x uint32 = 8 bytes)
- Transforms position, normal, tangent by blended bone matrix
- Bind group: b0=SkinningParams, t0=BoneMatrices, t1=SourceVertices, u0=OutputVertices

### 8.3 — SkinningPass (PipelinePass, compute)
- Runs first in the pipeline, before DepthPrepass
- Iterates skinned meshes in render data
- For each: looks up SkinningInstance on Renderer.SkinningSystem, dispatches compute
- Render graph tracks compute-write → vertex-read barriers automatically
- Pass itself is stateless — SkinningSystem owns all GPU resources

### 8.4 — Mesh Upload Changes
- `MeshUploadDesc` gets `IsSkinned` flag
- When set: GPUResourceManager adds `.Storage` to vertex buffer usage (compute read)
- `GPUMesh.IsSkinned` flag set on upload

### 8.5 — MeshRenderData Changes
- Add `GPUBoneBufferHandle BoneBufferHandle` — bone matrices (storage buffer)
- Add `SkinningInstanceHandle SkinningHandle` — maps to skinned output buffer
- Add `bool IsSkinned`

### 8.6 — ForwardOpaquePass / DepthPrepass Changes
- If `mesh.IsSkinned`: bind skinned vertex buffer from SkinningSystem (48 byte Mesh layout)
- Else: bind original vertex buffer
- Same shader, same pipeline — skinned output IS a standard Mesh vertex buffer

### 8.7 — SkinnedMeshComponent (Engine.Render)
- `SkinnedMeshComponent` + `SkinnedMeshComponentManager`
- Holds: Skeleton ref, AnimationPlayer ref, GPUBoneBufferHandle, SkinningInstanceHandle
- Each frame: evaluate animation → compute skinning matrices → upload to bone buffer
- Extraction: emits MeshRenderData with BoneBufferHandle + SkinningHandle + IsSkinned
- Bridge between animation (Sedulous.Animation) and renderer — Engine.Render references
  both but Renderer references neither

### 8.8 — Vertex Layout Update
- Pack bone indices as 4x uint16 in 2x uint32 (8 bytes, matches old engine)
- SkinnedMesh vertex stride: 72 bytes (down from 80)
- Update VertexLayoutHelper: SkinnedMeshAttributes uses Uint32x2 for joints

**Dependencies:** AnimationSubsystem needs to provide bone poses. Shader + SkinningSystem can be built independently.

**Dependencies:** AnimationSubsystem needs to provide bone poses. Shader + component can be built independently.

## Phase 9: Decals

### 9.1 — Decal Pass
- New `DecalPass` — runs after forward opaque, before transparent
- Reads SceneDepth to reconstruct world position
- Projects decal texture onto surfaces within the decal volume
- Processes `RenderCategories.Decal` batch (already sorted by SortOrder)

### 9.2 — Decal Shader
- `decal.frag.hlsl` — reconstructs world pos from depth, transforms into decal local space
- Clips pixels outside [0,1] decal volume
- Samples albedo texture, applies color tint and opacity
- Angle fade for surfaces facing away from decal projection direction
- DecalRenderData already has all needed fields (world matrix, inverse, color, angle fade)

### 9.3 — Decal Component
- `DecalComponent` + `DecalComponentManager` in Engine.Render
- Box volume in local space, projected along local -Z
- Material instance for decal texture
- Extracts as DecalRenderData via IRenderDataProvider

**Dependencies:** Needs depth buffer access (already available from prepass).

## Phase 10: Particles

Separate subsystem, following ezEngine's ParticlePlugin pattern.

### 10.1 — Project Structure
- New project: `Sedulous.Particles` (Foundation layer)
- Depends on: Core.Mathematics, RHI (for buffer types)
- Does NOT depend on Renderer — renderer pulls data from it

### 10.2 — Particle System Core
- `ParticleEffect` — top-level container, owns multiple systems
- `ParticleSystem` — owns emitters, behaviors, renderers
- `ParticleEmitter` — spawning (burst, continuous, distance-based)
- `ParticleBehavior` — per-frame update (gravity, velocity, color over lifetime, size over lifetime)
- SoA data layout (streams of Position, Velocity, Color, Size, Lifetime, Age)
- CPU simulation, GPU rendering only

### 10.3 — Particle Rendering
- `ParticleComponentManager` in Engine.Render — implements IRenderDataProvider
- Extraction creates render data (quad billboard, trail, point) per system
- Submits to `RenderCategories.Transparent` (additive or alpha-blended)
- Renderer uploads particle data to GPU buffer, draws instanced quads

### 10.4 — Particle Pass
- New `ParticlePass` or fold into TransparentForwardPass
- Billboard vertex shader (camera-facing quads from particle position + size)
- Particle fragment shader (texture sampling, color, soft particles via depth)

### 10.5 — Particle Subsystem
- `ParticleSubsystem` in Engine layer — manages particle world module
- Updates particle effects during Update phase
- ParticleComponent on entities triggers effect playback

**Dependencies:** Transparency pass (Phase 6) for blended particles. Can build core simulation independently.

## Phase 11: Sky

### 11.1 — Sky Pass Implementation
- Finish `SkyPass` (currently a stub)
- Cubemap skybox: sample environment cubemap, render at depth == far plane
- Uses `Materials.CreateSkybox()` (already exists)
- Shader: `skybox.vert/frag.hlsl` — position-only vertices, cubemap sample
- Depth test: LessEqual, no write (renders only where nothing else drew)

**Dependencies:** None. Small scope.

## Phase 12: Debug & Overlay Rendering

Immediate-mode debug drawing for development: lines, wireframes, bounding boxes, text. Essential for debugging physics, navigation, AI, and gameplay.

### 12.1 — DebugDraw API
- `DebugDraw` static class in `Sedulous.Renderer` — immediate-mode API
- `DrawLine(from, to, color)`, `DrawBox(bounds, color)`, `DrawSphere(center, radius, color, segments)`
- `DrawWireBox`, `DrawWireSphere`, `DrawFrustum`, `DrawAxis(transform, size)`
- `DrawText3D(position, text, color)` — screen-projected text at world position
- Accumulates vertices per frame into a transient buffer, flushed during render

### 12.2 — Debug Pass
- New `DebugPass` — runs after forward opaque (and after transparent once that exists)
- Renders lines with depth test (occluded lines dimmed or hidden)
- Unlit shader (position + color vertex format, already in `DebugVertex.bf`)
- Line list topology, no face culling
- Optional: depth-tested vs always-on-top modes

### 12.3 — Overlay Pass
- New `OverlayPass` — runs last, no depth test
- 2D screen-space drawing: text, rectangles, debug stats
- Uses `Sedulous.DebugFont` for text rendering (project already exists)
- Screen-space coordinate system (0,0 top-left)
- FPS counter, entity count, render stats (draw calls, triangles)

### 12.4 — Integration
- `DebugDraw` accessible from anywhere (static API, similar to ezEngine's `ezDebugRenderer`)
- Game code calls `DebugDraw.DrawBox(entity.Bounds, .Green)` during Update
- Renderer collects and renders all debug geometry at end of frame
- Compile-out or no-op in release builds via `#if DEBUG`

**Dependencies:** None. Can be implemented at any time. High value for development workflow.

## Phase 13: Sprites

Textured-quad rendering for billboards, in-world icons, 2D HUD elements, and
animated sprite sheets. Separate from the particle system (particles use their
own specialised billboard path) but shares the underlying quad rendering.

### 13.1 — Sprite Component + Data
- `SpriteComponent` in Engine.Render — owns texture ResourceRef, size, color,
  UV rect, orientation mode (camera-facing billboard, fixed axis, world-aligned)
- `SpriteRenderData : RenderData` — world matrix or world position, size,
  UV rect, material bind group, blend mode
- Animation: optional frame index + sprite-sheet UV rect override

### 13.2 — SpriteRenderer (per-type drawer)
- Extends the `Renderer` base class; registered against `Transparent` and
  (optionally) `Opaque` / `Masked` categories depending on the sprite's blend
- Batches sprites sharing a material into instanced draw calls
- Supports three orientation modes:
  - **Camera-facing** — quad vertices rotated to face the camera every frame
  - **World-aligned** — quad with fixed orientation in world space (decals-ish)
  - **Axis-aligned** — quad rotates around one world axis (e.g., Y for foliage)

### 13.3 — Shaders
- `sprite.vert.hlsl` — constructs quad corners from center + size + orientation
- `sprite.frag.hlsl` — texture sampling with color tint, alpha test / blend

### 13.4 — 2D/Screen-space sprites
- Screen-space mode for HUD: quad positioned in pixels, bypasses view-proj
- Bound in `OverlayPass` (Phase 12) or a dedicated `UIPass`

**Dependencies:** Transparency pass (Phase 6, done), Debug/Overlay (Phase 12)
for the 2D screen-space path. Quad rendering infrastructure is also useful for
particles later.

## Priority Order

Recommended implementation order based on dependencies and game impact:

1. ~~**Phase 5.1** — Tone mapping~~ DONE
2. ~~**Phase 11** — Sky~~ DONE
3. ~~**Phase 6** — Transparency + masked~~ DONE
4. ~~**Phase 8** — Compute skinning~~ DONE
5. ~~**Phase 7** — Shadows~~ DONE (7.5 polish deferred)
6. **Phase 12** — Debug & overlay rendering (essential for development)
7. **Phase 13** — Sprites (billboards, HUD, icons)
8. **Phase 9** — Decals (environmental detail)
9. **Phase 10** — Particles (effects, separate project)
10. **Phase 5.2-5.3** — Bloom and post-processing effects (polish)

## Architecture Notes

### ezEngine Patterns We Follow
- **Pipeline passes as graph nodes** — our PipelinePass + RenderGraph serves the same role as ezEngine's RenderPipelinePass with pins
- **Pull-based extraction** — IRenderDataProvider extracts render data from components, same as ezEngine's extractor system
- **Bind group frequency model** — Frame/Pass/Material/DrawCall maps to ezEngine's resource binding hierarchy
- **Separate particle project** — ezEngine's ParticlePlugin is a standalone module; our Sedulous.Particles follows the same split

### Resource Resolution (RenderResourceResolver)
Shared resource resolution service in Engine.Render, used by all render component managers.
Handles the resolve-upload-track pattern for meshes, materials, and textures.

- **Mesh resolution** — ResourceRef → StaticMeshResource/SkinnedMeshResource → GPU upload → GPUMeshHandle
- **Material resolution** — ResourceRef → MaterialResource → MaterialInstance → PrepareInstance (bind group)
- **Texture resolution** — ResourceRef → TextureResource → GPU upload → ITextureView → set on MaterialInstance
- **Texture cache** — same texture used by multiple materials uploads once
- **Change detection** — BoundResource comparison handles first load and hot reload uniformly
- **ResolvedResource<T>** — generic tracking struct (handle + bound resource + resolve method)

Component managers (MeshComponentManager, SkinnedMeshComponentManager, DecalComponentManager)
call into the resolver instead of duplicating the resolve-upload-track logic.

### Principles
- Each feature targets what we actually need for the game
- Build features properly — follow established engine architecture patterns, not shortcuts that need rework later
- Test each phase with the sandbox before moving on
- Shader variants via `ShaderFlags` when needed (e.g., skinned vs static)
