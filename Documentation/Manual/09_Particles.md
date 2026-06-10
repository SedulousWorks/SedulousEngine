# Particles

Sedulous has a self-contained particle system following ezEngine's plugin pattern. Particle effects are defined as compositions of emitters, initializers, and behaviors.

## Architecture

```
ParticleEffect           -- top-level container, groups multiple systems
  ParticleSystem          -- one visual element (sparks, smoke, etc.)
    ParticleEmitter       -- spawning logic (continuous, burst)
    Initializers[]        -- set initial values (position, velocity, color, size)
    Behaviors[]           -- update per frame (gravity, drag, color over lifetime)
    ParticleStream        -- SoA storage for particle attributes
```

## Creating Effects in Code

```beef
using Sedulous.Particles;

let effect = new ParticleEffect();

// Create a system
let sparks = effect.AddSystem("Sparks", .AlphaBlend);
sparks.MaxParticles = 200;
sparks.SimulationMode = .CPU;

// Emitter: 50 particles per second
sparks.Emitter.SpawnRate = 50;
sparks.Emitter.BurstCount = 0;

// Initializers
sparks.AddInitializer(new PositionInitializer(.Sphere, radius: 0.1f));
sparks.AddInitializer(new VelocityInitializer(.(0, 3, 0), spread: 30));
sparks.AddInitializer(new LifetimeInitializer(0.5f, 1.5f));
sparks.AddInitializer(new SizeInitializer(0.05f, 0.15f));
sparks.AddInitializer(new ColorInitializer(.(1, 0.8f, 0.2f, 1)));

// Behaviors
sparks.AddBehavior(new GravityBehavior(.(0, -9.8f, 0)));
sparks.AddBehavior(new DragBehavior(0.5f));
sparks.AddBehavior(new AlphaOverLifetimeBehavior(.FadeOut));
sparks.AddBehavior(new SizeOverLifetimeBehavior(.ShrinkToZero));
```

## Component

Attach particle effects to entities via `ParticleComponent`:

```beef
let particleMgr = scene.GetModule<ParticleComponentManager>();
if (let particle = particleMgr.Get(particleMgr.CreateComponent(entity)))
{
    var effectRef = ResourceRef(.Empty, "project://effects/fire.particle");
    defer effectRef.Dispose();
    particle.SetEffectRef(effectRef);

    // Optional texture override
    var texRef = ResourceRef(.Empty, "project://textures/spark.texture");
    defer texRef.Dispose();
    particle.SetTextureRef(texRef);
}
```

## Available Behaviors

| Behavior | Description |
|----------|-------------|
| `Gravity` | Constant acceleration (typically downward) |
| `Drag` | Velocity damping |
| `Wind` | Directional force |
| `Turbulence` | Noise-based random displacement |
| `Vortex` | Rotational force around an axis |
| `Attractor` | Pull toward a point |
| `RadialForce` | Push away from a point |
| `VelocityIntegration` | Applies velocity to position |
| `ColorOverLifetime` | Interpolate color based on age |
| `SizeOverLifetime` | Scale size based on age |
| `AlphaOverLifetime` | Fade alpha based on age |
| `SpeedOverLifetime` | Scale velocity based on age |
| `RotationOverLifetime` | Spin particles |

## Emission Shapes

| Shape | Description |
|-------|-------------|
| `Point` | All particles spawn at origin |
| `Sphere` / `Hemisphere` | Volume or surface of a sphere |
| `Cone` | Cone volume with configurable angle |
| `Box` | Axis-aligned box volume |
| `Circle` | Ring or disk |
| `Edge` | Line between two points |

## Blend Modes

Each particle system specifies its blend mode:

- `.AlphaBlend` -- standard transparency
- `.Additive` -- additive glow (fire, sparks)
- `.PremultipliedAlpha` -- pre-multiplied alpha
- `.Multiply` -- darkening effect

## Soft Particles

Particles near surfaces can use depth-based fade to avoid hard clipping:

```beef
sparks.SoftParticles = true;
sparks.SoftParticleDistance = 0.5f;  // Fade distance in world units
```

## Next Steps

- [Navigation](10_Navigation.md) -- AI pathfinding
