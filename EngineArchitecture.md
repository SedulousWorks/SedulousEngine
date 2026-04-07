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

The `Context` is the central lifecycle hub. It owns subsystems, a job system, and a resource system. Subsystems are registered by type and updated in `UpdateOrder` priority.

**Subsystem** — 1 instance per application. Provides app-wide services.
**Scene Module (ComponentManager)** — 1 instance per scene. Owns per-scene data.

### Subsystem Update Order

| Subsystem | Order | Role |
|-----------|-------|------|
| InputSubsystem | -900 | Input device state |
| SceneSubsystem | -500 | Scene lifecycle, lockstep scene updates |
| PhysicsSubsystem | -100 | Owns physics engine (Jolt), shared config |
| AnimationSubsystem | 100 | Owns animation clip cache |
| AudioSubsystem | 200 | Owns audio device, mixer |
| NavigationSubsystem | 300 | Owns NavMesh settings |
| GUISubsystem | 400 | UI framework |
| RenderSubsystem | 500 | Rendering, GPU frame pacing |

### Frame Loop

```
Application main loop:
  SProfiler.BeginFrame()
  ProcessEvents()
  FixedUpdate (0-N times)     → Context.FixedUpdate() → each subsystem
  Context.BeginFrame()        → each subsystem
  Context.Update()            → each subsystem in order
  Context.PostUpdate()        → each subsystem
  Context.EndFrame()          → RenderSubsystem renders + presents
  SProfiler.EndFrame()

Shutdown sequence:
  Shutdown()                  → Device.WaitIdle() → OnShutdown() (app releases GPU refs)
  Context.Shutdown()          → subsystems shut down
  Cleanup()                   → OnCleanup() → delete context → destroy device
```

## Scenes

### Entity-Component Model

- **Entity** — lightweight handle (index + generation + Guid). No entity class — `EntityHandle` IS the entity.
- **Component** — ref type, pooled per type in a `ComponentManager<T>`.
- **ComponentManager<T>** — IS-A SceneModule. Owns the pool, registers update functions, handles lifecycle.
- **Transform** — not a component. Every entity has one. Hierarchical parent-child with dirty-flag propagation.

### Scene Update Phases

Phases run inside `SceneSubsystem.Update()`. Multiple scenes run in lockstep per phase.

```
1. Initialize      — init newly created components
2. PreUpdate        — physics results readback, input application
3. Update           — gameplay, AI, simulation
4. PostUpdate       — animation, constraints, late logic
5. TransformUpdate  — propagate dirty transforms down hierarchy
6. PostTransform    — render extraction, spatial index update
7. Cleanup          — deferred entity/component destruction
```

### Scene Modules and ISceneAware

Subsystems implement `ISceneAware` to inject their scene modules when scenes are created:

```
class RenderSubsystem : Subsystem, ISceneAware
{
    void OnSceneCreated(Scene scene)
    {
        scene.AddModule(new MeshComponentManager());
        scene.AddModule(new CameraComponentManager());
        scene.AddModule(new LightComponentManager());
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

All resource managers and the scene serializer use the provider — no direct format dependencies.

### Scene Serialization

- `SceneSerializer` writes/reads entities, transforms, hierarchy, and components
- Components implement `ISerializableComponent` for their data
- `ComponentTypeRegistry` maps type IDs to manager factories for deserialization
- `EntityRef` carries persistent Guid + cached runtime handle for cross-entity references
- `IModuleSerializer` — scene modules can serialize module-level data (non-entity state like environment settings)

### Resource Serialization

- `Resource.SaveToFile(path, provider)` — generic text save via provider
- `TextureResource` overrides with binary sidecar (text metadata + `.bin` pixel data)
- Resource managers load via `SerializerProvider.CreateReader(text)` — format-independent
- `ResourceType` hash (uint64) validates resource type on load

## Application Stack

### Level 1: Runtime.Client.Application (RHI samples)
Raw RHI access. No engine, no scenes, no subsystems.

### Level 2: Engine.App.EngineApplication (games)
Full engine. Creates Context, auto-registers all subsystems, discovers asset directory, creates ShaderSystem and device. Game logic lives in components and subsystems.

### Level 3: Tools.Core.EditorApplication (future)
Multi-window, viewport rendering, editor panels.

## Reference Engines

- **ezEngine** — extraction pattern, world modules, bind group frequency, component managers
- **Traktor** — GatherView flat data bundle, deferred render context, entity renderer pattern
