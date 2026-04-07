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
- **Transparent rendering** — TransparentForwardPass with alpha blending, back-to-front sorted
- **Sky rendering** — Equirectangular HDR environment map with procedural gradient fallback
- **IModuleSerializer** — scene module-level serialization support (for non-entity scene data)

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

### 7.1 — Shadow Atlas
- Single large depth texture atlas (e.g., 4096x4096)
- Allocate rectangular regions per shadow-casting light
- Directional: cascaded shadow maps (2-4 cascades, each a region in the atlas)
- Point: cubemap faces packed into atlas (6 regions)
- Spot: single region per light

### 7.2 — Shadow Pass
- New `ShadowPass` — runs before depth prepass
- For each shadow-casting light: render scene from light's perspective into atlas region
- Uses depth-only shader (already exists: `depth_only.vert/frag.hlsl`)
- Light-space view-projection matrices stored per light

### 7.3 — Shadow Sampling in Forward Shader
- Forward shader receives shadow atlas + per-light shadow matrices
- Sample shadow map with PCF (percentage-closer filtering)
- Cascade selection for directional lights (based on view-space depth)
- Shadow data in frame bind group (set 0) or separate shadow bind group

### 7.4 — Shadow Data Pipeline
- LightRenderData already has `CastsShadows`, `ShadowBias`, `ShadowNormalBias`
- LightBuffer needs shadow matrix + atlas region per light
- Pipeline manages shadow atlas texture lifecycle

**Dependencies:** None, but large scope. Can parallelize atlas allocation and pass implementation.

## Phase 8: GPU Skinning

### 8.1 — Skinning Shader
- New `skinned_forward.vert.hlsl` (or variant of forward.vert.hlsl)
- Reads bone matrices from storage buffer (set 3 or dedicated set)
- Transforms position, normal, tangent by weighted bone matrices
- 4 bones per vertex (JointIndices uint4 + JointWeights float4)

### 8.2 — Skinned Mesh Component
- `SkinnedMeshComponent` + `SkinnedMeshComponentManager` in Engine.Render
- Holds bone hierarchy, current pose (joint matrices)
- Uploads bone matrices to GPUBoneBuffer each frame
- Extracts as MeshRenderData with skinned pipeline config

### 8.3 — Animation Integration
- AnimationSubsystem drives bone transforms
- SkinnedMeshComponent receives final pose from animation system
- Extraction writes bone buffer offset into render data
- Forward pass binds bone buffer at draw time

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

## Priority Order

Recommended implementation order based on dependencies and game impact:

1. ~~**Phase 5.1** — Tone mapping~~ DONE
2. ~~**Phase 11** — Sky~~ DONE
3. ~~**Phase 6** — Transparency + masked~~ DONE
4. **Phase 12** — Debug & overlay rendering (essential for development)
5. **Phase 7** — Shadows (major visual quality jump)
6. **Phase 8** — GPU skinning (characters)
7. **Phase 9** — Decals (environmental detail)
8. **Phase 10** — Particles (effects, separate project)
9. **Phase 5.2-5.3** — Bloom and post-processing effects (polish)

## Architecture Notes

### ezEngine Patterns We Follow
- **Pipeline passes as graph nodes** — our PipelinePass + RenderGraph serves the same role as ezEngine's RenderPipelinePass with pins
- **Pull-based extraction** — IRenderDataProvider extracts render data from components, same as ezEngine's extractor system
- **Bind group frequency model** — Frame/Pass/Material/DrawCall maps to ezEngine's resource binding hierarchy
- **Separate particle project** — ezEngine's ParticlePlugin is a standalone module; our Sedulous.Particles follows the same split

### Principles
- Each feature targets what we actually need for the game
- Build features properly — follow established engine architecture patterns, not shortcuts that need rework later
- Test each phase with the sandbox before moving on
- Shader variants via `ShaderFlags` when needed (e.g., skinned vs static)
