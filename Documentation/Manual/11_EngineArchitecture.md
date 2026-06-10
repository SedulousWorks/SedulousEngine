# Engine Architecture

This chapter covers the internal architecture of the Sedulous engine -- how subsystems are organized, how to build your own, and how the update loop works. You don't need this for basic engine use, but it's essential for extending the engine with custom gameplay systems.

## Context

The `Context` is the central hub that owns and manages all engine subsystems. It handles registration, initialization order, per-frame updates, and shutdown.

`EngineApplication` creates a Context automatically. You access it via `Context` from within any application method:

```beef
let sceneSub = Context.GetSubsystem<SceneSubsystem>();
let audioSub = Context.GetSubsystem<AudioSubsystem>();
```

## Subsystems

A `Subsystem` is a self-contained engine module registered with the Context. Each subsystem has a lifecycle and an update priority.

### Standard Subsystems

`EngineApplication` registers these by default:

| Subsystem | Purpose | UpdateOrder |
|-----------|---------|-------------|
| `SceneSubsystem` | Scene lifecycle, entity management | 0 |
| `PhysicsSubsystem` | Rigid body simulation, collision | 100 |
| `AnimationSubsystem` | Skeletal, property, and graph animation | 150 |
| `AudioSubsystem` | Sound playback, 3D spatialization | 200 |
| `NavigationSubsystem` | AI pathfinding, navmesh | 300 |
| `EngineUISubsystem` | Screen-space and world-space UI | 400 |
| `RenderSubsystem` | 3D rendering, shadows, post-processing | 500 |

Lower `UpdateOrder` runs first. Physics updates before animation, animation before audio, all before rendering.

### Lifecycle

| Method | When | Order |
|--------|------|-------|
| `OnInit()` | Context.Startup() | Registration order |
| `OnReady()` | After all OnInit() completes | Registration order |
| `Update(float dt)` | Every frame | Sorted by UpdateOrder |
| `PostUpdate(float dt)` | After all Update() calls | Sorted by UpdateOrder |
| `OnPrepareShutdown()` | Before shutdown begins | Reverse order |
| `OnShutdown()` | Context.Shutdown() | Reverse order |

`OnReady` is called after all subsystems are initialized, enabling cross-subsystem wiring that can't happen during `OnInit` (because the other subsystem might not exist yet).

### Creating a Custom Subsystem

```beef
using Sedulous.Runtime;

class GameSubsystem : Subsystem
{
    public override int32 UpdateOrder => 50;  // After scenes, before physics

    protected override void OnInit()
    {
        // Initialize game state, load configs
    }

    public override void Update(float deltaTime)
    {
        // Game logic that runs every frame
    }

    protected override void OnShutdown()
    {
        // Cleanup
    }
}
```

Register it in `OnConfigure` (called before Context.Startup):

```beef
protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new GameSubsystem());
}
```

### ISceneAware

Subsystems that implement `ISceneAware` are notified when scenes are created and destroyed. This is how engine subsystems inject their component managers into scenes automatically.

```beef
class GameSubsystem : Subsystem, ISceneAware
{
    public void OnSceneCreated(Scene scene)
    {
        // Inject custom component managers
        scene.AddModule(new EnemyComponentManager());
        scene.AddModule(new InventoryComponentManager());
    }

    public void OnSceneReady(Scene scene) { }

    public void OnSceneDestroyed(Scene scene)
    {
        // Cleanup per-scene state
    }
}
```

When `SceneSubsystem.CreateScene()` is called, it notifies all `ISceneAware` subsystems. This is why scenes automatically have `MeshComponentManager`, `LightComponentManager`, etc. -- `RenderSubsystem` injects them via `ISceneAware`.

## ResourceSystem

`ResourceSystem` is owned by the application, not the context. It manages:

- **Registries** -- GUID-to-path mapping with protocol prefixes (`builtin://`, `project://`)
- **Resource managers** -- type-specific loaders (one per resource type)
- **Cache** -- prevents duplicate loads
- **Hot-reload** -- detects file changes via FileWatcher

Access it from `EngineApplication`:

```beef
// Load a resource
if (ResourceSystem.LoadResource<TextureResource>(path) case .Ok(let handle))
{
    let tex = handle.Resource;
    // ...
}

// Add a programmatic resource
let mesh = StaticMeshResource.CreateCube();
ResourceSystem.AddResource<StaticMeshResource>(mesh);
```

Subsystems register their resource managers during `OnInit`. For example, `RenderSubsystem` registers `StaticMeshResourceManager`, `TextureResourceManager`, and `MaterialResourceManager`. `AudioSubsystem` registers `AudioClipResourceManager` and `SoundCueResourceManager`.

See [Resources](02_Resources.md) for full details.

## Messaging

`Sedulous.Messaging` provides a typed pub/sub message bus for decoupled communication between systems.

### Setup

```beef
using Sedulous.Messaging.Runtime;

protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new MessagingSubsystem());
}
```

`MessagingSubsystem` drains queued messages each frame at `UpdateOrder = -500` (before everything else).

### Defining Messages

Messages are structs -- zero-allocation dispatch via pass-by-reference:

```beef
struct EnemyKilledMessage
{
    public EntityHandle Entity;
    public int32 ScoreValue;
}

struct WaveCompletedMessage
{
    public int32 WaveNumber;
}
```

### Publishing and Subscribing

```beef
let bus = Context.GetSubsystem<MessagingSubsystem>().Bus;

// Subscribe
bus.Subscribe<EnemyKilledMessage>(new (ref msg) => {
    mScore += msg.ScoreValue;
    SpawnParticleAt(msg.Entity);
});

// Publish (immediate dispatch to all subscribers)
EnemyKilledMessage msg = .() { Entity = enemyHandle, ScoreValue = 100 };
bus.Publish<EnemyKilledMessage>(ref msg);

// Or queue for deferred dispatch (processed during MessagingSubsystem.Update)
bus.Queue<EnemyKilledMessage>(msg);
```

### Use Cases

- **Game events** -- enemy killed, wave completed, item collected
- **Cross-system communication** -- audio reacts to gameplay without direct coupling
- **UI updates** -- score display subscribes to score change messages
- **Hot-reload notifications** -- resource system publishes reload events

Use immediate `Publish` for events that need instant response (UI updates). Use `Queue`/drain for events that should batch (spawning, scoring).

## Update Loop

The full frame loop in `EngineApplication`:

```
1. Shell.ProcessEvents()              -- OS window events, input
2. JobSystem.ProcessCompletions()     -- Async job callbacks
3. ResourceSystem.Update()            -- Hot-reload, async load completions
4. Context.BeginFrame(dt)
5. Context.Update(dt)                 -- All subsystems in UpdateOrder
6. Context.PostUpdate(dt)             -- All subsystems in UpdateOrder
7. Context.EndFrame()
8. Frame()                            -- Render + present
```

Within `Context.Update`, each subsystem's `Update(dt)` runs. Scene subsystem ticks all scenes, which run their scene module update phases (PreUpdate, Update, AsyncUpdate, PostUpdate, TransformUpdate, PostTransform, Cleanup).

## Scene Module vs Subsystem

Both are update-driven systems, but at different levels:

| | Subsystem | SceneModule |
|---|---|---|
| **Scope** | Global (one per context) | Per-scene (one per scene) |
| **Lifecycle** | Context startup/shutdown | Scene create/destroy |
| **Update** | `Context.Update` | `Scene.Update` (within phases) |
| **Access** | `Context.GetSubsystem<T>()` | `scene.GetModule<T>()` |
| **Use for** | Cross-scene services, IO, networking | Per-entity components, scene-specific logic |

Most gameplay code lives in `SceneModule` subclasses (component managers). Use `Subsystem` for services that span multiple scenes or don't belong to any scene.

## Custom Component Managers

The most common way to extend the engine is with custom `ComponentManager<T>`:

```beef
class HealthComponent : Component, ISerializableComponent
{
    [Property]
    public float MaxHealth = 100;

    [Property]
    public float CurrentHealth = 100;

    public int32 SerializationVersion => 1;

    public void Serialize(IComponentSerializer s)
    {
        s.Float("MaxHealth", ref MaxHealth);
        s.Float("CurrentHealth", ref CurrentHealth);
    }
}

class HealthComponentManager : ComponentManager<HealthComponent>
{
    public override StringView SerializationTypeId => "Game.HealthComponent";

    protected override void OnRegisterUpdateFunctions()
    {
        RegisterUpdate(.Update, new => OnUpdate, simulationOnly: true);
    }

    private void OnUpdate(float deltaTime)
    {
        for (let comp in ActiveComponents)
        {
            if (!comp.IsActive) continue;

            // Regeneration
            if (comp.CurrentHealth < comp.MaxHealth)
                comp.CurrentHealth = Math.Min(comp.CurrentHealth + deltaTime * 5, comp.MaxHealth);
        }
    }
}
```

Register the manager type so it can be deserialized from scene files:

```beef
// In your GameSubsystem (ISceneAware):
public void OnSceneCreated(Scene scene)
{
    scene.AddModule(new HealthComponentManager());
}

// Register with ComponentTypeRegistry for scene serialization:
typeRegistry.Register("Game.HealthComponent", () => new HealthComponentManager());
```

## Next Steps

- [Editor](12_Editor.md) -- scene authoring, asset browser, inspector
