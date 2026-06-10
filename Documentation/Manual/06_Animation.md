# Animation

Sedulous supports three animation systems: skeletal animation (bone-driven mesh deformation), property animation (keyframed value tracks), and animation graphs (state machines with blend trees).

## Skeletal Animation

For character animation. A skeleton defines the bone hierarchy, and animation clips contain per-bone keyframes. The renderer uses compute skinning to deform the mesh on the GPU.

### Components

Attach both a `SkinnedMeshComponent` and a `SkeletalAnimationComponent` to the same entity:

```beef
// Skinned mesh
let skinnedMgr = scene.GetModule<SkinnedMeshComponentManager>();
if (let mesh = skinnedMgr.Get(skinnedMgr.CreateComponent(entity)))
{
    var meshRef = ResourceRef(.Empty, "project://models/character.mesh");
    defer meshRef.Dispose();
    mesh.SetMeshRef(meshRef);
}

// Skeletal animation
let animMgr = scene.GetModule<SkeletalAnimationComponentManager>();
if (let anim = animMgr.Get(animMgr.CreateComponent(entity)))
{
    var skelRef = ResourceRef(.Empty, "project://models/character.skeleton");
    defer skelRef.Dispose();
    anim.SetSkeletonRef(skelRef);

    var clipRef = ResourceRef(.Empty, "project://animations/walk.animation");
    defer clipRef.Dispose();
    anim.SetClipRef(clipRef);

    anim.AutoPlay = true;
    anim.Loop = true;
    anim.Speed = 1.0f;
}
```

### Animation Player

The `SkeletalAnimationComponent` creates an `AnimationPlayer` internally. You can control playback:

```beef
if (anim.Player != null)
{
    anim.Player.Play(clip);
    anim.Player.Pause();
    anim.Player.Stop();
    anim.Player.Speed = 0.5f;  // Half speed
}
```

## Animation Graphs

For complex animation logic -- blending between walk, run, idle based on game parameters. Uses a state machine with blend nodes.

```beef
let graphMgr = scene.GetModule<AnimationGraphComponentManager>();
if (let graph = graphMgr.Get(graphMgr.CreateComponent(entity)))
{
    var skelRef = ResourceRef(.Empty, "project://models/character.skeleton");
    defer skelRef.Dispose();
    graph.SetSkeletonRef(skelRef);

    var graphRef = ResourceRef(.Empty, "project://animations/character.animgraph");
    defer graphRef.Dispose();
    graph.SetGraphRef(graphRef);
}
```

### Setting Parameters

Animation graphs expose parameters that game code can set to drive transitions:

```beef
if (graph.GraphPlayer != null)
{
    graph.GraphPlayer.SetFloat("Speed", playerSpeed);
    graph.GraphPlayer.SetBool("IsGrounded", isGrounded);
    graph.GraphPlayer.SetTrigger("Jump");
}
```

## Property Animation

For animating any property over time -- transform position, color, intensity, etc. Useful for doors, platforms, UI animations, and environmental effects.

```beef
using Sedulous.Animation;

// Create a clip programmatically
let clip = new PropertyAnimationClip("OrbitPath", 12.0f, true);

let posTrack = clip.AddVector3Track("Transform.Position");
posTrack.AddKeyframe(0.0f, .(5, 0, 0));
posTrack.AddKeyframe(3.0f, .(0, 0, 5));
posTrack.AddKeyframe(6.0f, .(-5, 0, 0));
posTrack.AddKeyframe(9.0f, .(0, 0, -5));
posTrack.AddKeyframe(12.0f, .(5, 0, 0));
```

### Component

```beef
let propAnimMgr = scene.GetModule<PropertyAnimationComponentManager>();
if (let propAnim = propAnimMgr.Get(propAnimMgr.CreateComponent(entity)))
{
    var clipRef = ResourceRef(.Empty, "project://animations/orbit.propanim");
    defer clipRef.Dispose();
    propAnim.SetClipRef(clipRef);
    propAnim.AutoPlay = true;
    propAnim.Loop = true;
}
```

### Property Binding

Property animation tracks target properties by path (e.g., `"Transform.Position"`). The `PropertyBinderRegistry` maps these paths to actual component fields. Built-in bindings include:

- `Transform.Position` -- entity local position
- `Transform.Rotation` -- entity local rotation
- `Transform.Scale` -- entity local scale

Custom binders can be registered for game-specific properties.

## Resource Types

| Type | Extension | Description |
|------|-----------|-------------|
| `SkeletonResource` | `.skeleton` | Bone hierarchy (names, parent indices, bind poses) |
| `AnimationClipResource` | `.animation` | Skeletal animation keyframes |
| `AnimationGraphResource` | `.animgraph` | State machine + blend tree |
| `PropertyAnimationClipResource` | `.propanim` | Property keyframe tracks |

## Next Steps

- [User Interface](07_UI.md) -- screen-space and world-space UI
- [Physics](08_Physics.md) -- rigid bodies, collision, raycasting
