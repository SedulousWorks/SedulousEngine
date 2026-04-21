# Sedulous Engine Architecture

Living document describing the engine's architecture, layers, and patterns.

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  Application Layer                                              │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐ │
│  │ EngineApp        │  │ EditorApp        │  │ RHI Sample   │ │
│  │ (Engine.App)     │  │ (Tools.Core)     │  │ (Rt.Client)  │ │
│  │ single window    │  │ multi-window     │  │ raw GPU      │ │
│  │ auto-subsystems  │  │ viewports+panels │  │ no engine    │ │
│  └──────┬───────────┘  └──────┬───────────┘  └──────────────┘ │
├─────────▼─────────────────────▼─────────────────────────────────┤
│  Engine Layer                                                   │
│  Context + Subsystems (Sedulous.Runtime)                        │
│  Engine.Render (RenderSubsystem, components, extraction)        │
├─────────────────────────────────────────────────────────────────┤
│  Scene Layer (Sedulous.Scenes)                                  │
├─────────────────────────────────────────────────────────────────┤
│  Renderer Layer                                                 │
│  Renderer (shared infrastructure) + Pipeline (per-view passes)  │
│  Materials, PostProcessStack, PipelineStateCache                │
├─────────────────────────────────────────────────────────────────┤
│  RHI (Sedulous.RHI)                                             │
│  Vulkan, DX12 backends                                          │
└─────────────────────────────────────────────────────────────────┘
```

## Context and Subsystems

The `Context` is a pure subsystem lifecycle manager. It does NOT own ResourceSystem or JobSystem — those are application concerns. Subsystems that need resources receive ResourceSystem as a constructor parameter (explicit dependency). Subsystems are registered by type and updated in `UpdateOrder` priority. Interface-based queries via `GetSubsystemByInterface<T>()`/`GetSubsystemsByInterface<T>()` allow decoupled access (e.g., ISceneRenderer, IOverlayRenderer).

**Subsystem** - 1 instance per application. Provides app-wide services.
**Scene Module (ComponentManager)** - 1 instance per scene. Owns per-scene data.

### Subsystem Update Order

| Subsystem | Order | Role |
|-----------|-------|------|
| InputSubsystem | -900 | Input device state |
| SceneSubsystem | -500 | Scene lifecycle, lockstep scene updates |
| PhysicsSubsystem | -100 | Owns physics engine (Jolt), shared config |
| AnimationSubsystem | 100 | Owns animation clip cache |
| AudioSubsystem | 200 | Owns audio device, mixer |
| NavigationSubsystem | 300 | Owns NavMesh settings |
| EngineUISubsystem | 400 | Screen + world UI (IOverlayRenderer) |
| RenderSubsystem | 500 | Scene rendering (ISceneRenderer) |

### Frame Loop

```
Application main loop:
  SProfiler.BeginFrame()
  ProcessEvents()
  JobSystem.ProcessCompletions()   → application-owned, not Context
  ResourceSystem.Update()          → application-owned, not Context
  Context.BeginFrame()             → input polling, InitializePendingComponents
  FixedUpdate (0-N times)          → Context.FixedUpdate() → physics, navigation
  Context.Update()                 → each subsystem in order (scene phases run here)
  Context.PostUpdate()             → each subsystem
  Context.EndFrame()               → subsystem EndFrame (RenderSubsystem is now minimal)
  PresentFrame()                   → application-owned: clear, RenderScene, blit, overlays, present
  SProfiler.EndFrame()
```

BeginFrame runs BEFORE FixedUpdate so input is fresh and newly initialized
components (physics bodies, audio sources) are ready for their first simulation step.

JobSystem and ResourceSystem are updated by the application before Context.BeginFrame,
not by Context itself. Subsystems that need resources receive ResourceSystem as a
constructor parameter (e.g., `new RenderSubsystem(mResourceSystem)`).

Presentation is owned by the application, not a subsystem. The application creates
the command encoder, clears output targets, calls ISceneRenderer.RenderScene(),
blits to swapchain, runs IOverlayRenderers, and presents. This enables the editor
to call the same ISceneRenderer with a viewport texture instead of a swapchain.

```
Startup sequence:
  Application: JobSystem.Initialize(), ResourceSystem.Startup()
  Context.Startup()
    for each subsystem: Init()    → individual setup (OnInit)
    for each subsystem: Ready()   → cross-subsystem wiring (OnReady)

Shutdown sequence:
  Context.PrepareShutdown()   → detach cross-references (physics worlds, etc.)
  Context.Shutdown()          → subsystems shut down (reverse order)
  Application: ResourceSystem.Shutdown(), JobSystem.Shutdown()
  Cleanup()                   → OnCleanup() → delete context → destroy device
```

OnReady runs on all subsystems after all OnInit calls complete. Subsystems can
safely access other subsystems here (e.g., EngineUISubsystem registers WorldUIPass
with RenderSubsystem's Pipeline). Mirror of OnPrepareShutdown at the other end.

PrepareShutdown runs on all subsystems before any Shutdown calls. Subsystems
detach cross-references (e.g., null physics world refs on component managers)
so component cleanup during scene teardown doesn't access destroyed resources.

## Scenes

### Entity-Component Model

- **Entity** - lightweight handle (index + generation + Guid). No entity class - `EntityHandle` IS the entity.
- **Component** - ref type, pooled per type in a `ComponentManager<T>`. Has `Initialized` flag.
- **ComponentManagerBase** - non-generic base between SceneModule and ComponentManager<T>. Owns `InitializePendingComponents`.
- **ComponentManager<T>** - extends ComponentManagerBase. Owns the pool, registers update functions, handles lifecycle.
- **Transform** - not a component. Every entity has one. Hierarchical parent-child with dirty-flag propagation.

### Component Lifecycle

```
CreateComponent(entity)         → OnComponentCreated (properties NOT set yet)
[app sets properties]           → Shape, BodyType, clip refs, etc.
InitializePendingComponents()   → OnComponentInitialized (properties set, safe for
                                   physics body creation, resource resolution, etc.)
[simulation runs]               → FixedUpdate, Update phases
DestroyComponent() / entity     → OnComponentDestroyed
```

`InitializePendingComponents` is called by Scene at the start of each frame
(in SceneSubsystem.BeginFrame) before FixedUpdate. This mirrors ezEngine's
`OnSimulationStarted` lifecycle hook.

### Scene Update Phases

Phases run inside `SceneSubsystem.Update()`. Multiple scenes run in lockstep per phase.

```
1. Initialize      - init newly created components
2. PreUpdate        - physics results readback, input application (sequential)
3. Update           - gameplay, AI, scene mutation (sequential)
4. AsyncUpdate      - PARALLEL: independent per-component work (opt-in)
5. PostUpdate       - read async results, constraints, late logic (sequential)
6. TransformUpdate  - propagate dirty transforms down hierarchy
7. PostTransform    - render extraction, spatial index update (sequential)
8. Cleanup          - deferred entity/component destruction
```

### AsyncUpdate Phase (Parallel)

The AsyncUpdate phase runs all registered managers concurrently via `JobSystem.ParallelFor`.
Inspired by ezEngine's Async phase. Managers opt in by registering for `.AsyncUpdate`
instead of `.Update`.

**Rules for AsyncUpdate:**
- Each manager iterates ONLY its own component pool - no cross-component access
- No entity creation/destruction, no hierarchy changes, no transform writes
- No dependencies between AsyncUpdate functions (enforced at registration)
- Read-only access to transforms is safe (transforms are finalized in TransformUpdate AFTER AsyncUpdate,
  but the PREVIOUS frame's transforms are stable during AsyncUpdate)

**Scene dispatches AsyncUpdate:**
```
// Scene.RunAsyncUpdate():
for each manager registered for AsyncUpdate:
    JobSystem.ParallelFor(0, manager.ActiveCount, (begin, end) => {
        manager.UpdateRange(begin, end, deltaTime);
    });
// All ParallelFor calls block - AsyncUpdate is fully complete before PostUpdate.
```

**Which managers use which phase:**

| Manager | Phase | Reason |
|---------|-------|--------|
| PhysicsComponentManager | PreUpdate + PostUpdate | Reads transforms, steps world, writes back |
| User gameplay managers | Update | May access any component, mutate scene |
| SkeletalAnimationManager | AsyncUpdate | Each player is independent |
| AnimationGraphManager | AsyncUpdate | Each graph evaluates independently |
| PropertyAnimationManager | AsyncUpdate | Per-entity, reads only own state |
| AudioSourceManager | AsyncUpdate | Per-source position sync, no cross-reads |
| NavigationComponentManager | Update | Crowd manager is not thread-safe |
| MeshComponentManager (extraction) | PostTransform | Reads finalized transforms |
| SkinnedMeshComponentManager | PostTransform | Reads bone matrices + transforms |

**Default is sequential.** User gameplay code registers for `Update` (safe, sequential).
Only engine managers with provably independent per-component work opt into `AsyncUpdate`.

### Internal Parallelization (separate from AsyncUpdate)

Some operations use `JobSystem.ParallelFor` internally without needing a new phase:

- **Scene Extraction** (PostTransform): split component iteration across threads,
  per-thread output lists merged after. Needs thread-local FrameAllocator.
- **SortAndBatch**: each render category sorted independently, one ParallelFor across categories.
- **Transform Propagation**: PrevWorldMatrix snapshot is a bulk memcpy (ParallelFor over entity range).
  Dirty root subtrees are independent and can be processed in parallel.

### Scene Modules and ISceneAware

Subsystems implement `ISceneAware` to inject their scene modules when scenes are created:

```
class RenderSubsystem : Subsystem, ISceneAware, IWindowAware, ISceneRenderer
{
    void OnSceneCreated(Scene scene)
    {
        scene.AddModule(new MeshComponentManager());
        scene.AddModule(new CameraComponentManager());
        scene.AddModule(new LightComponentManager());
        // + SpriteComponentManager, DecalComponentManager, etc.
    }

    // ISceneRenderer - called by application with encoder + output targets
    void RenderScene(encoder, colorTexture, colorTarget, w, h, frameIndex)
    {
        // extract scenes → setup shadows → render shadows → pipeline.Render()
    }
}

class EngineUISubsystem : Subsystem, ISceneAware, IWindowAware, IOverlayRenderer
{
    // IOverlayRenderer - called by application after blit
    void RenderOverlay(encoder, target, w, h, frameIndex)
    {
        // delegates to ScreenUIView → VGRenderer composites UI onto swapchain
    }
}
```

### IWindowAware

Subsystems implement `IWindowAware` to react to window resize events:

```
interface IWindowAware
{
    void OnWindowResized(IWindow window, int32 width, int32 height);
}
```

The app iterates all subsystems and broadcasts resize to any that implement it.

## Serialization

### ISerializerProvider

Format-independent serialization. One provider registered at app startup:

```
context.Resources.SetSerializerProvider(new OpenDDLSerializerProvider());
```

All resource managers and the scene serializer use the provider - no direct format dependencies.

### Scene Serialization

- `SceneSerializer` writes/reads entities, transforms, hierarchy, and components
- Components implement `ISerializableComponent` for their data
- `ComponentTypeRegistry` maps type IDs to manager factories for deserialization
- `EntityRef` carries persistent Guid + cached runtime handle for cross-entity references
- `IModuleSerializer` - scene modules can serialize module-level data (non-entity state like environment settings)

### Resource Serialization

- `Resource.SaveToFile(path, provider)` - generic text save via provider
- `TextureResource` overrides with binary sidecar (text metadata + `.bin` pixel data)
- Resource managers load via `SerializerProvider.CreateReader(text)` - format-independent
- `ResourceType` hash (uint64) validates resource type on load

## Application Stack

### Level 1: Runtime.Client.Application (RHI samples, tools, editor)
Shell + RHI + SwapChain. Owns device, window, frame loop. Virtual CreateLogger()
for custom logging. Both EngineApplication and EditorApplication extend this.

### Level 2: Engine.App.EngineApplication (games)
Full engine. Creates Context, auto-registers all subsystems (passing ResourceSystem
to those that need it), discovers asset directory, creates ShaderSystem. Owns
swapchain, output targets, frame pacing, BlitHelper. Calls ISceneRenderer.RenderScene
+ IOverlayRenderers for presentation.

### Level 3: Editor.App.EditorApplication
Extends Runtime.Client.Application directly (not EngineApplication). Owns UIContext
and VGRenderer directly. Creates a RuntimeContext with engine subsystems for scene
preview. EditorContext provides plugin system, page/panel management, commands.
ViewportView renders scene to texture via ISceneRenderer, displayed in UI via
VGRenderer.RegisterExternalTexture.

## Engine Modules

### Engine.Input
Subsystem-only (no components). InputSubsystem manages priority-ordered stack of
InputContexts, each containing named InputActions with typed InputBindings.
Binding types: Key (with modifiers), MouseButton, MouseAxis (delta/scroll),
GamepadButton, GamepadAxis (dead zone), GamepadStick (circular dead zone),
CompositeBinding (4 keys → Vector2, e.g. WASD).

### Engine.Physics
PhysicsSubsystem creates JoltPhysicsWorld per scene via ISceneAware.
RigidBodyComponent (data-rich: body type, mass, friction, ShapeConfig).
PhysicsComponentManager creates bodies in OnComponentInitialized, runs
FixedUpdate (kinematic sync → step → dispatch contacts → dynamic sync),
preserves entity scale. RayCast with entity handle decoding from body user data.
PrepareShutdown detaches managers before world destruction.

**Contact events:** PhysicsComponentManager implements IContactListener, registered
with the physics world automatically. Jolt callbacks are buffered during the physics
step (thread-safe via Monitor) and dispatched to components on the main thread after
the step completes. Both bodies in a contact are notified (normals/velocities flipped
for body2's perspective). Gameplay code sets delegates on RigidBodyComponent:
- `OnContactAdded(self, PhysicsContactEvent) → bool` - return false to reject contact
- `OnContactPersisted(self, PhysicsContactEvent)` - fires each frame while in contact
- `OnContactRemoved(self, EntityHandle otherEntity)` - fires when contact ends

All three callbacks provide valid EntityHandles. `OnContactRemoved` extracts
body IDs from the `JPH_SubShapeIDPair` struct passed by Jolt.

### Engine.Animation
Three component types:
- **SkeletalAnimationComponent** - simple clip playback via ResourceRefs (SkeletonRef + ClipRef). Priority 10.
- **AnimationGraphComponent** - state-machine-driven via graph. Priority 11 (overrides skeletal).
- **PropertyAnimationComponent** - animates entity properties via PropertyBinderRegistry.
AnimationSubsystem registers all 4 resource managers, owns PropertyBinderRegistry.
SkinnedMeshComponent decoupled from animation - reads bone matrices from animation components.

### Engine.Audio
AudioSubsystem creates SDL3AudioSystem, manages volume categories (Master × SFX/Music),
music streaming (PlayMusic/StopMusic), one-shot API (PlayOneShot/PlayOneShot3D).
AudioSourceComponent (clip ref, volume, pitch, spatial, autoplay, category).
AudioListenerComponent on camera entity. Managers sync 3D positions in PostTransform.

### Engine.Navigation
Infrastructure ported from old engine: NavMesh, NavMeshBuilder, NavMeshQuery,
CrowdManager, TileCache, NavWorld (all wrapping recastnavigation-Beef).
NavAgentComponent (radius, height, speed, move target, crowd agent index).
NavObstacleComponent (radius, height, obstacle ID).
NavigationSubsystem creates NavWorld per scene, PrepareShutdown detaches managers.
FixedUpdate steps crowd, Update creates agents and syncs positions.

### Material Lifecycle
MaterialInstance is ref-counted (RefCounted base). Components call AddRef/ReleaseRef
via SetMaterial. GPU resources (bind group, uniform buffer) are cleaned up in
MaterialInstance's destructor when the last ref is released - not by component managers.
MaterialSystem.ClearCache detaches all instances (SetMaterialSystem(null)) before
destroying GPU resources, so late-running destructors don't use-after-free.

## Reference Engines

- **ezEngine** - extraction pattern, world modules, bind group frequency, component managers, OnSimulationStarted lifecycle
- **Traktor** - GatherView flat data bundle, deferred render context, entity renderer pattern
