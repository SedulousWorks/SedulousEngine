# Scenes and Entities

The scene system is the foundation of Sedulous. Every object in the world is an entity in a scene, and behavior is added through components attached to entities.

## Scenes

A scene is a container for entities and their components. Scenes are created and destroyed through `SceneSubsystem`, which manages their lifecycle and ensures all engine subsystems inject their component managers.

```beef
let sceneSub = Context.GetSubsystem<SceneSubsystem>();
let scene = sceneSub.CreateScene("GameScene");
```

When a scene is created, every subsystem that implements `ISceneAware` injects its component managers. For example, `RenderSubsystem` adds `MeshComponentManager`, `LightComponentManager`, `CameraComponentManager`, and others. This means the scene is immediately ready to receive components of any registered type.

### Multiple Scenes

You can create multiple scenes simultaneously. Each has independent entities, transforms, and component state. This is useful for:

- Editor: each open scene file is a separate Scene
- UI scene overlaid on a game scene
- Loading screens with a separate scene

### Simulation Control

Scenes have a `SimulationEnabled` flag that controls whether simulation-only update functions run (physics stepping, animation advance, particle ticking). The editor disables simulation for preview-only rendering.

```beef
scene.SimulationEnabled = false;  // Editor mode: render only
scene.SimulationEnabled = true;   // Game mode: full simulation
```

## Entities

Entities are lightweight -- just an index and a generation counter packed into an `EntityHandle`. They have no data of their own beyond a name, a transform, and parent-child relationships.

### Creating and Destroying

```beef
let entity = scene.CreateEntity("Player");

// With a specific GUID (for serialization)
let entity = scene.CreateEntity(myGuid, "Player");

// Destroy
scene.DestroyEntity(entity);
```

Entity destruction is deferred during scene updates to prevent invalidating iterators. The entity is removed at the end of the current update cycle.

### Validity

Always check validity before using an entity handle that may have been destroyed:

```beef
if (scene.IsValid(entity))
{
    // Safe to use
    let name = scene.GetEntityName(entity);
}
```

Handles use generation counters -- if an entity is destroyed and its slot is reused, old handles become invalid instead of pointing to the new entity.

### Naming

Entity names are for debugging and editor display. They are not unique identifiers.

```beef
scene.SetEntityName(entity, "Boss");
let name = scene.GetEntityName(entity);  // returns StringView
```

### Active State

Entities can be deactivated. Inactive entities and their children are skipped by component managers during updates and rendering.

```beef
scene.SetActive(entity, false);  // Deactivate
let active = scene.IsActive(entity);
```

## Transforms

Every entity has a local transform (position, rotation, scale) relative to its parent. The scene computes world transforms automatically from the hierarchy.

```beef
// Set local transform
scene.SetLocalTransform(entity, .() {
    Position = .(5, 0, 3),
    Rotation = Quaternion.CreateFromYawPitchRoll(Math.PI_f * 0.25f, 0, 0),
    Scale = .(2, 2, 2)
});

// Read back
let local = scene.GetLocalTransform(entity);
let worldMatrix = scene.GetWorldMatrix(entity);
```

The `Transform` struct has three fields:

| Field | Type | Default |
|-------|------|---------|
| `Position` | `Vector3` | `(0, 0, 0)` |
| `Rotation` | `Quaternion` | `Identity` |
| `Scale` | `Vector3` | `(1, 1, 1)` |

### Look-At Helper

`Transform.CreateLookAt` creates a transform facing a target position:

```beef
scene.SetLocalTransform(camera, Transform.CreateLookAt(
    .(0, 5, 10),  // eye position
    .(0, 0, 0)    // look-at target
));
```

## Parent-Child Hierarchy

Entities can be parented to form a hierarchy. Child transforms are relative to their parent.

```beef
let parent = scene.CreateEntity("Tank");
let turret = scene.CreateEntity("Turret");
let barrel = scene.CreateEntity("Barrel");

scene.SetParent(turret, parent);
scene.SetParent(barrel, turret);
```

Children inherit their parent's world transform. Moving the parent moves all descendants. Rotating the turret rotates the barrel with it.

```beef
// Unparent
scene.SetParent(turret, .Invalid);

// Query
let parentHandle = scene.GetParent(turret);
```

### Iterating Children

```beef
let children = scope List<EntityHandle>();
scene.GetChildren(parent, children);
for (let child in children)
{
    let childName = scene.GetEntityName(child);
    // ...
}
```

## Components

Components add data and behavior to entities. Each component type is managed by a `ComponentManager<T>` (a `SceneModule`). The manager creates, stores, and updates all components of its type.

### Adding a Component

Components are created through their manager, not directly on the entity:

```beef
let meshMgr = scene.GetModule<MeshComponentManager>();
let handle = meshMgr.CreateComponent(entity);

// Configure the component
if (let mesh = meshMgr.Get(handle))
{
    var meshRef = ResourceRef(.Empty, "builtin://primitives/cube.mesh");
    defer meshRef.Dispose();
    mesh.SetMeshRef(meshRef);
}
```

### Querying Components

Check if an entity has a specific component:

```beef
let comp = meshMgr.GetForEntity(entity);
if (comp != null)
{
    // Entity has a MeshComponent
}
```

Get all components on an entity (across all managers):

```beef
let components = scope List<Component>();
scene.GetComponents(entity, components);
```

### Component Lifecycle

Components go through these states:

1. **Created** -- `CreateComponent()` called, component exists but not yet initialized
2. **Initialized** -- manager's `OnComponentInitialized` runs (resource resolution, GPU setup)
3. **Active** -- updated each frame by the manager
4. **Destroyed** -- entity destroyed or component explicitly removed

### Serialization

Components that implement `ISerializableComponent` are saved and loaded with the scene. The serialization type ID on the component manager (`SerializationTypeId`) identifies the component type in scene files.

```beef
class MyComponent : Component, ISerializableComponent
{
    public int32 SerializationVersion => 1;

    [Property]
    public float Health = 100;

    [Property]
    private ResourceRef mMeshRef ~ _.Dispose();

    public void Serialize(IComponentSerializer s)
    {
        s.Float("Health", ref Health);
        s.ResourceRef("MeshRef", ref mMeshRef);
    }
}
```

The `[Property]` attribute marks fields as editable in the editor inspector. See [Editor Integration](12_Editor.md) for details.

## Scene Modules

Component managers are a type of `SceneModule` -- per-scene systems that can register update functions. Non-component modules are used for scene-wide state like render settings.

```beef
// Access a module
let renderSettings = scene.GetModule<RenderSceneModule>();

// Iterate all modules
for (let module in scene.Modules)
{
    // ...
}
```

### Module-Level Serialization

Modules implementing `IModuleSerializer` can save scene-wide data (not per-entity). This is used for render settings (sky, ambient, exposure) and similar scene-level configuration.

## Iterating Entities

```beef
for (let entity in scene.Entities)
{
    if (!scene.IsValid(entity)) continue;
    let name = scene.GetEntityName(entity);
    let worldPos = scene.GetWorldMatrix(entity).Translation;
    // ...
}
```

## Finding Entities

Find an entity by its persistent GUID:

```beef
let entity = scene.FindEntity(someGuid);
if (entity.IsAssigned)
{
    // Found
}
```

## Update Phases

Scene modules register update functions for specific phases, executed each frame in order:

| Phase | Purpose | Example |
|-------|---------|---------|
| `Initialize` | Initialize newly created components | Component setup |
| `PreUpdate` | Input processing, physics readback | Input manager |
| `Update` | Main game logic | Gameplay, AI, simulation |
| `AsyncUpdate` | Parallel per-component work (own pool only) | Particle simulation |
| `PostUpdate` | Post-logic work, resource resolution | Material resolution, animation |
| `TransformUpdate` | Propagate dirty transforms (internal) | Scene hierarchy |
| `PostTransform` | After transforms are final | Render data extraction |
| `Cleanup` | Deferred entity/component destruction | Scene cleanup |

Each registered function has a priority (higher = runs earlier within the phase) and a `simulationOnly` flag.

## Next Steps

- [Resources](02_Resources.md) -- loading and managing assets
- [Rendering](03_Rendering.md) -- cameras, lights, materials, sky
