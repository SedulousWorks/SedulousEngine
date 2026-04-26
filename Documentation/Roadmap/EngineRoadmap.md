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

**MaterialInstance sharing -- DONE.** `RenderResourceResolver.ResolveMaterial()`
caches MaterialInstances by `MaterialResource.Id` (GUID). All components using
`SetMaterialRef()` with the same MaterialResource share one instance and bind
group, enabling MeshRenderer draw call batching automatically.

Components using `SetMaterial()` with a manually-created instance bypass the
cache and get their own private instance. Per-entity material overrides use
`SetMaterial()` with a cloned/custom instance.

### Resource SourcePath Coverage

All resources have a `SourcePath` field (on `Resource` base class, serialized)
for tracking the original source asset. This enables rebuilding dedup contexts
from previously baked resources across editor sessions.

**Covered (model import pipeline):**
- Textures -- resolved file path (external) or modelPath#textureN (embedded)
- Materials -- material name
- Static meshes, skinned meshes, skeletons, animations -- model file path

**Future -- needs offline importers:**
- Audio clips -- set SourcePath from source audio file when audio importer is built
- Scenes -- created at runtime, no source file (unless editor scene save/load added)
- Themes -- set SourcePath from XML file when theme importer is formalized
- UI layouts -- set SourcePath from layout file when layout importer is formalized

**Cross-session dedup context rebuild (editor):**
At editor startup, load previously baked resources from disk, iterate them, and
populate an `ImportDeduplicationContext` from their `SourcePath` fields. New
imports will then skip re-creating resources that already exist from prior sessions.

### What the old engine does that we don't yet
- 14 post-processing effects (we have 2)
- Reflection probes with scene capture
- Cluster lighting for many lights
- Hi-Z occlusion culling
- Comprehensive component serialization (ComponentData pattern)
- Scene system tests

### Resource GUID Remapping

When baked assets are regenerated (e.g. primitive meshes deleted and recreated),
they get new GUIDs. Existing scene files reference the old GUIDs which no longer
match the registry. The ResourceSystem needs a remapping mechanism:

- Detect GUID mismatch: scene references a GUID not in any registry
- Fall back to path-based loading (already works via `LoadByRef` cascade)
- Optionally update the scene's GUIDs to match the current registry (remap)
- Could be automatic (remap on load + mark scene dirty) or manual (editor tool)
- Registry could store a history of previous GUIDs for an asset to assist remapping

For now, path-based fallback in `LoadByRef` provides a degraded workaround --
if the `ResourceRef` has both a GUID and a path, the path resolves even when
the GUID doesn't. But this only works if the path hasn't changed.

## Hot Reload Resource Lifecycle

**Problem:** `MaterialResourceManager.ReloadFromFile` calls `OnSerialize` on the
existing resource, but `OnSerialize` doesn't know it's reloading vs first loading.
For materials, this creates a new `Material` object inside an existing
`MaterialResource`, but the old `Material` and its GPU state (bind group, layout,
uniform buffer) are not cleaned up. Similar issues may exist for other resource
types that own GPU or runtime objects.

**Options to investigate:**

1. **Resource.OnReload virtual method** — resources override `OnReload()` to tear
   down old state before `OnSerialize` re-populates. The manager calls `OnReload()`
   before `ReloadFromFile`. Resources that don't support reload return `.NotSupported`
   (already exists in the error enum). Simple, explicit.

2. **Serialize with reload flag** — pass a context flag to `OnSerialize` indicating
   reload mode. The resource can clean up old state conditionally. Avoids adding a
   new virtual method but makes serialization aware of lifecycle, which may be
   undesirable.

3. **Manager-level reload** — the manager handles teardown entirely. For materials:
   dispose old Material, call Load to create fresh, swap into the existing
   ResourceHandle. The resource itself is stateless between loads. Cleanest
   separation but requires managers to know resource internals.

**Critical constraint:** Resources cannot be destroyed and replaced because other
systems hold direct references to the instance (e.g. `MaterialInstance` holds a
pointer to `Material`). Destroying the old resource causes use-after-free crashes.
Resources must be **updated in place** during hot-reload.

**Known crash:** `MaterialResource.OnSerialize` in read mode creates a new
`Material` and calls `SetMaterial(mat, true)` which `delete`s the old one. Any
`MaterialInstance` still referencing the old `Material` crashes. The fix: on
reload, clear and repopulate the existing `Material`'s properties, uniforms, and
shader name in place rather than creating a new one.

**Recommendation:** Option 1 (OnReload) with in-place update semantics. A virtual
`OnReload()` on Resource prepares for re-serialization by clearing mutable state
without destroying the object. For `MaterialResource`: clear property defs, reset
uniform buffer, clear texture refs — then `OnSerialize` repopulates the same
`Material` instance. `MaterialInstance` stays valid, marks bind group dirty for
GPU re-upload. For resources that can't reload in place, return `.NotSupported`.

**Affected resource types:**
- `MaterialResource` — owns a `Material` object (may own textures, samplers)
- `StaticMeshResource` / `SkinnedMeshResource` — own mesh data, GPU handles cached externally
- `TextureResource` — owns pixel data, GPU texture cached externally
- `SceneResource` — complex; full scene reload may not be practical via hot-reload
- `AudioClipResource` — owns audio clip data
- `ParticleEffectResource` — owns effect definition

**GPU resource invalidation:** When a resource reloads, any cached GPU handles
(in `RenderResourceResolver`'s caches) may point to stale data. The resolver's
`ResolvedResource<T>` uses `BoundResource` pointer comparison to detect changes —
if the resource object stays the same but its contents change, the resolver won't
re-upload. May need a version counter or dirty flag on resources that resolvers
check.
