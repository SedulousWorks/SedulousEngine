# Navigation

Sedulous integrates Recast/Detour for navigation mesh generation and AI pathfinding. Agents navigate the world using baked navigation meshes, and obstacles dynamically modify the navmesh at runtime.

## Setup

```beef
using Sedulous.Engine.Navigation;

protected override void OnConfigure(Context context)
{
    context.RegisterSubsystem(new NavigationSubsystem());
}
```

## Navigation Agent

Entities that need pathfinding get a `NavAgentComponent`:

```beef
let navMgr = scene.GetModule<NavigationComponentManager>();
if (let agent = navMgr.Get(navMgr.CreateComponent(entity)))
{
    agent.MaxSpeed = 3.5f;
    agent.Radius = 0.6f;
    agent.Height = 2.0f;
    agent.MaxAcceleration = 8.0f;
}
```

### Moving an Agent

Set a target position and the agent will pathfind and move toward it:

```beef
agent.MoveTarget = targetPosition;

// Clear target to stop
agent.MoveTarget = null;
```

## Navigation Obstacles

Dynamic obstacles that carve out the navmesh at runtime:

```beef
let obstacleMgr = scene.GetModule<NavObstacleComponentManager>();
if (let obstacle = obstacleMgr.Get(obstacleMgr.CreateComponent(entity)))
{
    obstacle.Radius = 1.0f;
    obstacle.Height = 2.0f;
}
```

## Next Steps

- [Engine Architecture](11_EngineArchitecture.md) -- Context, subsystems, custom gameplay systems
- [Editor](12_Editor.md) -- scene authoring, asset browser, inspector
