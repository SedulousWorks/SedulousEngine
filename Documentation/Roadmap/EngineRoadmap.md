# Engine Roadmap

Gap analysis and future work for the Sedulous engine. Compares against the old
Sedulous engine (BeefGFX_Workspace_Compare) and ezEngine as references.

## Current State - DONE

### Engine Modules
- ~~**Engine.Input**~~ - input action system (contexts, bindings, subsystem)
- ~~**Engine.Physics**~~ - Jolt integration (RigidBodyComponent, FixedUpdate sync, raycasting)
- ~~**Engine.Animation**~~ - skeletal clips, animation graphs, property animation
- ~~**Engine.Audio**~~ - SDL3 audio (sources, listener, volume categories, music streaming, one-shots)
- ~~**Engine.Navigation**~~ - Recast/Detour (navmesh, crowd, obstacles, pathfinding)
- ~~**Engine.UI**~~ - screen-space + world-space UI (EngineUISubsystem, ScreenUIView, UIComponent, WorldUIPass, input raycasting)

### Renderer
- ~~Forward PBR~~ with Cook-Torrance BRDF
- ~~Depth prepass~~ with masked geometry
- ~~Shadows~~ - cascaded directional (4 cascades), point cubemap, spot, hierarchical atlas
- ~~Compute skinning~~
- ~~Sky/HDR environment~~
- ~~Decals~~ - depth-reconstructed projected
- ~~Sprites~~ - GPU instanced, 3 orientation modes
- ~~Particles~~ - CPU simulation, billboard + trail rendering, soft particles, sub-emitters, LOD
- ~~Bloom~~ - 5-level downsample/upsample chain
- ~~Tonemap~~ - ACES filmic with bloom composite
- ~~Mini G-buffer~~ - SceneNormals + MotionVectors MRT (ready for SSAO/TAA/motion blur)
- ~~Debug draw~~ - wire shapes, screen text, light gizmos

### Architecture
- ~~Component lifecycle~~ - OnComponentInitialized (ezEngine-style deferred init)
- ~~Frame loop~~ - BeginFrame before FixedUpdate
- ~~PrepareShutdown~~ - cross-reference detachment before shutdown
- ~~Material ref counting~~ - destructor-based GPU cleanup, no premature bind group destruction

## Rendering Gaps

### High Priority (supersede old engine)

**Post-Processing Effects (Phase 5.3):**
Mini G-buffer already writes normals + motion vectors. These effects consume them.

| Effect | Effort | Notes |
|--------|--------|-------|
| SSAO | Medium | Reads SceneNormals + SceneDepth. Screen-space hemisphere sampling |
| TAA | Medium | Reads MotionVectors + history buffer. Jitter + resolve |
| FXAA | Small | Single fullscreen pass, no extra inputs |
| Motion Blur | Small | Reads MotionVectors. Per-pixel velocity blur |
| Color Grading | Small | LUT-based, single fullscreen pass |
| Auto Exposure | Medium | Luminance histogram + adaptation |
| DOF | Medium | Circle of confusion from depth |

**Reflection Probes:**
Old engine had capture-based reflection probes. Needed for PBR quality on
metallic/reflective surfaces. ezEngine has baked probes with light caching.

**Cluster Lighting:**
Old engine had ClusterGrid for efficient many-light rendering. Current engine
does linear light iteration in the forward shader. Needed when light count > 32.

### Medium Priority (match old engine features)

| Feature | Notes |
|---------|-------|
| Occlusion culling (Hi-Z) | Old engine had HiZOcclusionCuller. Important for complex scenes |
| SSR | Screen-space reflections. Medium effort, reads normals + depth |
| Volumetric fog | Old engine had VolumetricFogFeature. Large scope |
| ~~World-space UI~~ | DONE - EngineUISubsystem, UIComponent, WorldUIPass, input raycasting |

### Low Priority (ezEngine parity, advanced)

| Feature | ezEngine | Notes |
|---------|----------|-------|
| LOD system | LodComponent, LodAnimatedMeshComponent | Mesh + animation LOD |
| Grass/foliage | KrautPlugin procedural vegetation | Large scope |
| Terrain | HeightfieldComponent | Large scope |
| Lens flares | LensFlareComponent | Visual polish |
| Light shafts | LightShaftsComponent | Visual polish |
| Baked GI probes | BakedProbesComponent | Advanced lighting |

## Engine Gaps

### ~~High Priority~~

~~**Component Serialization:**~~ DONE
All 14 components implement ISerializableComponent. ResourceRef serialization
via Beef interface extension on IComponentSerializer (in Sedulous.Scenes.Resources).
SceneSerializer handles entities, transforms, hierarchy, components, and module data.
No intermediate ComponentData classes needed - components serialize directly.

### Medium Priority

| Feature | Old Engine | ezEngine | Notes |
|---------|-----------|----------|-------|
| ~~World-space UI~~ | ~~WorldUIComponent~~ | RmlUiPlugin | DONE - UIComponent + UIComponentManager, render-to-texture via WorldUIPass, input raycasting |
| IK (aim, two-bone) | ❌ | AimIKComponent, TwoBoneIKComponent | Animation quality |
| Motion matching | ❌ | MotionMatchingComponent | Advanced animation |
| Character controller | Via Jolt | Via Jolt | Already available via physics |
| Scene tests | 6 tests | Comprehensive | Need test coverage |

### Low Priority (future)

| Feature | ezEngine | Notes |
|---------|----------|-------|
| Prefab system | PrefabReferenceComponent | Entity templates |
| Visual scripting | VisualScriptPlugin | Node-based logic |
| Procedural generation | ProcGenPlugin | Level building |
| XR/VR support | OpenXRPlugin | VR rendering |
| Cloth/rope simulation | ClothSheetComponent | Physics-based |
| AI/behavior | SensorComponent | Perception system |
| Wind system | SimpleWindComponent | Global wind fields |

## Particle System Gaps

| Feature | Status |
|---------|--------|
| Grid-based atlas animation | Deferred - vertex UV fields ready |
| GPU compute simulation | Stub exists, needs compute shaders |

## Architecture Notes

### What we do BETTER than the old engine
- **Component lifecycle** - formal OnComponentInitialized (old engine had none)
- **Frame loop order** - BeginFrame before FixedUpdate (old engine had FixedUpdate first)
- **PrepareShutdown** - safe cross-reference detachment (old engine didn't have this)
- **Material ref counting** - destructor-based cleanup prevents premature bind group destruction
- **Particle architecture** - unified CPU/GPU API with stream abstraction (old engine was monolithic)
- **Animation decoupling** - animation separate from skinned mesh (old engine coupled them)
- **Render pass architecture** - cleaner pass-based pipeline vs old engine's feature-based system

### Material and Texture Deduplication

**Resource deduplication -- DONE.** `ImportDeduplicationContext` deduplicates
TextureResource and MaterialResource objects across multiple model imports.
Textures are keyed by source path (external: resolved file path, embedded:
`modelPath#textureN`). Materials are keyed by name. Pass the same context to
multiple `ResourceImportResult.ConvertFrom()` calls. Showcase sample validates
this: 44 models produce only 14 unique textures and 14 unique materials.

**MaterialInstance sharing -- outstanding.** Even with deduplicated resources,
`RenderResourceResolver.ResolveMaterial()` creates a new `MaterialInstance` per
component slot. Entities sharing the same MaterialResource get different
MaterialInstance pointers, preventing MeshRenderer from batching draw calls.
The Showcase works around this with manual shared MaterialInstances via
`SetMaterial()`.

Options for engine-level MaterialInstance sharing:

**Option A: Share by default, clone on override (copy-on-write)**
- Resolver shares instances automatically
- If a component calls SetFloat/SetColor on a shared instance, the component
  manager detects the shared ref count and clones into a private instance
- Pro: automatic, covers the common case (imported materials rarely overridden)
- Con: adds complexity to the component manager override path; need to track
  which instances are shared vs private

**Option B: Explicit opt-in via flag**
- A flag on the component or material (e.g. `SharedMaterial = true`)
- Shared materials batch; unique materials get their own instance as today
- Pro: simple, predictable, no hidden cloning
- Con: requires awareness from the user; imported materials would need the
  flag set by default in the converter

**Option C: Resolver-level instance cache**
- Resolver maintains `Dictionary<Guid, MaterialInstance>` keyed by
  MaterialResource.Id. Same resource = same instance (AddRef on reuse)
- Per-entity overrides clone explicitly via a new API (e.g. `CloneMaterial()`)
- Pro: clean separation -- sharing is a resource concern, overrides are explicit
- Con: requires explicit clone call for per-entity variation

Option C is likely the cleanest long-term approach. Most imported materials are
never overridden per-entity, so sharing by resource ID covers the common case.
The few entities needing unique properties call CloneMaterial() explicitly.

### What the old engine does that we don't yet
- 14 post-processing effects (we have 2)
- Reflection probes with scene capture
- Cluster lighting for many lights
- Hi-Z occlusion culling
- Comprehensive component serialization (ComponentData pattern)
- Scene system tests
