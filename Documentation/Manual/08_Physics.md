# Physics

Sedulous integrates Jolt Physics for rigid body simulation, collision detection, and raycasting. Physics is managed by `PhysicsSubsystem` and driven by `RigidBodyComponent` on entities.

## Setup

Register the physics subsystem in `OnConfigure`:

```beef
using Sedulous.Engine.Physics;

protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new PhysicsSubsystem());
}
```

## Rigid Body Component

Add physics to an entity by attaching a `RigidBodyComponent`:

```beef
let physicsMgr = scene.GetModule<PhysicsComponentManager>();
if (let body = physicsMgr.Get(physicsMgr.CreateComponent(entity)))
{
    body.BodyType = .Dynamic;       // .Static, .Dynamic, .Kinematic
    body.Mass = 1.0f;
    body.Restitution = 0.3f;        // Bounciness
    body.Friction = 0.5f;

    // Collision shape
    body.Shape.Type = .Box;                   // .Box, .Sphere, .Capsule
    body.Shape.HalfExtents = .(0.5f, 0.5f, 0.5f);  // Box half-extents
}
```

### Body Types

| Type | Description |
|------|-------------|
| `Static` | Immovable. Used for ground, walls, platforms. Zero mass. |
| `Dynamic` | Fully simulated. Affected by forces, gravity, collisions. |
| `Kinematic` | Moved by code (set transform directly). Pushes dynamic bodies but isn't affected by forces. |

### Collision Shapes

| Shape | Properties |
|-------|------------|
| `Box` | `HalfExtents` -- Vector3 half-size per axis |
| `Sphere` | `Radius` -- sphere radius |
| `Capsule` | `Radius` + `HalfHeight` -- capsule dimensions |

## Fixed Update

Physics runs at a fixed timestep (default 60 Hz) independent of frame rate. Game logic that interacts with physics should use the fixed update:

```beef
// In a custom SceneModule:
protected override void OnRegisterUpdateFunctions()
{
    RegisterFixedUpdate(new => OnFixedUpdate);
}

private void OnFixedUpdate(float fixedDelta)
{
    // Physics queries and force application here
}
```

## Next Steps

- [Particles](09_Particles.md) -- particle effects
- [Navigation](10_Navigation.md) -- AI pathfinding
