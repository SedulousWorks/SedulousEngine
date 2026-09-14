using System;
using Sedulous.Core;
using Sedulous.Particles;

namespace Samples.ParticleFX;

/// Every effect the showcase runs, one builder per cell.
///
/// Each is a plain function over a caller owned effect rather than a factory, because the point
/// of the grid is COMPARISON: two cells can share a builder and differ only in the material,
/// which is what the two mesh cells do.
static class ShowcaseEffects
{
	/// Additive soft dots on a fast cone: the baseline billboard system.
	public static void Fountain(ParticleEffect effect)
	{
		let system = effect.AddSystem(30000);
		system.Name.Set("fountain");
		system.BlendMode = .Additive;
		system.RenderMode = .Billboard;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 3000.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.25f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.6f, 2.6f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 13.0f, 0.0f);
			velocity.Randomness = .(3.0f, 2.0f, 3.0f);
			velocity.Shape = .Cone(0.4f, 0.35f);
			velocity.ShapeDirectionSpeed = 4.0f;
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.35f, 0.35f));
		system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.55f, 0.15f, 1.0f),
			.(1.0f, 0.85f, 0.4f, 1.0f));

		system.AddBehavior<GravityBehavior>().Multiplier = 1.4f;
		system.AddBehavior<DragBehavior>().Drag = 0.25f;
		system.AddBehavior<ColorOverLifetimeBehavior>().Curve =
			.FadeAlpha(.(1.0f, 0.5f, 0.12f, 1.0f), 0.35f);
		system.AddBehavior<SizeOverLifetimeBehavior>().Curve =
			.Linear(.(0.4f, 0.4f), .(0.04f, 0.04f));
	}

	/// Light mode: each ember contributes a point light, so they paint moving pools on the
	/// floor. FEW of them on purpose: a dense cloud saturates the light clusters and the pools
	/// merge into a grid.
	public static void Embers(ParticleEffect effect)
	{
		let system = effect.AddSystem(400);
		system.Name.Set("embers");
		system.RenderMode = .Light;
		system.BlendMode = .Additive;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 12.0f; // about 45 alive, comfortably under the cap

		system.AddInitializer<PositionInitializer>().Shape = .Box(.(4.0f, 0.1f, 4.0f));
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(2.5f, 4.5f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 1.4f, 0.0f);
			velocity.Randomness = .(0.5f, 0.3f, 0.5f);
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.6f, 0.6f));
		system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.5f, 0.15f, 1.0f),
			.(1.0f, 0.75f, 0.3f, 1.0f));
		system.AddBehavior<DragBehavior>().Drag = 0.5f;
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.55f);
	}

	/// Big slow quads centred at floor level, so each one STRADDLES the ground plane. That is
	/// what makes the soft particle comparison legible: a hard clip line against the floor
	/// versus a fade.
	public static void Haze(ParticleEffect effect)
	{
		let system = effect.AddSystem(300);
		system.Name.Set("haze");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.SoftDistance = 2.0f; // a wide band, obvious either way
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 14.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Box(.(3.5f, 0.05f, 3.5f));
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(4.0f, 6.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 0.25f, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(2.0f, 2.0f));
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(0.35f, 0.28f, 0.45f, 1.0f));
		system.AddBehavior<DragBehavior>().Drag = 0.6f;
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.4f);
	}

	/// Trail mode: arcing sparks, each dragging a camera facing ribbon. Gravity is what curves
	/// them, and a straight ribbon would show nothing.
	public static void Trail(ParticleEffect effect)
	{
		let system = effect.AddSystem(2000);
		system.Name.Set("sparks");
		system.RenderMode = .Trail;
		system.BlendMode = .Additive;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 40.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.15f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.4f, 2.4f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 8.0f, 0.0f);
			velocity.Randomness = .(6.0f, 3.0f, 6.0f); // spray sideways so the ribbons curve
			velocity.Shape = .Cone(0.5f, 0.2f);
			velocity.ShapeDirectionSpeed = 3.0f;
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.2f, 0.2f));
		system.AddInitializer<ColorInitializer>().Color = .(.(0.2f, 0.7f, 1.0f, 1.0f),
			.(0.9f, 0.4f, 1.0f, 1.0f));

		system.AddBehavior<GravityBehavior>().Multiplier = 1.5f;
		system.AddBehavior<ColorOverLifetimeBehavior>().Curve =
			.FadeAlpha(.(0.5f, 0.6f, 1.0f, 1.0f), 0.3f);

		system.Trail.Enabled = true;
		system.Trail.MaxPoints = 32;
		system.Trail.RecordInterval = 0.02f;
		system.Trail.Lifetime = 0.6f; // how long a recorded point lingers, so the ribbon length
		system.Trail.WidthStart = 0.22f;
		system.Trail.WidthEnd = 0.0f; // taper to a point at the tail
		system.Trail.MinVertexDistance = 0.04f;
		system.Trail.UseParticleColor = true;
	}

	/// Rain bouncing off the world ground AND a drawn sphere. World space, so the collider
	/// centre is a world position that has to match where the sphere is drawn.
	public static void Collision(ParticleEffect effect, Float3 obstacle, float obstacleRadius)
	{
		let system = effect.AddSystem(4000);
		system.Name.Set("rain");
		system.RenderMode = .Billboard;
		system.BlendMode = .Alpha;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 500.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Box(.(3.0f, 0.1f, 3.0f));
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(3.0f, 4.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, -1.0f, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.12f, 0.12f));
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(0.5f, 0.75f, 1.0f, 0.9f));
		system.AddBehavior<GravityBehavior>().Multiplier = 1.0f;

		let collision = system.AddBehavior<CollisionBehavior>();
		collision.Planes[0] = .(.(0.0f, 1.0f, 0.0f), 0.0f); // the world ground
		collision.PlaneCount = 1;
		collision.Spheres[0] = .(obstacle, obstacleRadius);
		collision.SphereCount = 1;
		collision.Radius = 0.06f; // a drop sits ON the surface rather than in it
		collision.Bounce = 0.45f;
		collision.Friction = 0.15f;
		collision.LifetimeLoss = 0.2f; // lose life on each hit, so splashes settle
	}

	/// One flame, scaled. Shared by the fire cell and the campfire's base.
	public static void ConfigureFire(ParticleSystem system, float scale)
	{
		system.Name.Set("fire");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 160.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Circle(0.6f * scale);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.6f, 1.1f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 3.2f * scale, 0.0f);
			velocity.Randomness = .(0.7f, 0.6f, 0.7f);
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(1.0f * scale, 1.0f * scale));
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(1.0f, 0.9f, 0.5f, 1.0f));
		system.AddBehavior<TurbulenceBehavior>().Strength = 1.5f; // the flicker
		system.AddBehavior<SizeOverLifetimeBehavior>().Curve =
			.Linear(.(1.0f * scale, 1.0f * scale), .(0.15f * scale, 0.15f * scale));

		ParticleCurveColor ramp = .();
		ramp.AddKey(0.0f, .(1.0f, 0.95f, 0.7f, 1.0f));
		ramp.AddKey(0.35f, .(1.0f, 0.6f, 0.2f, 0.9f));
		ramp.AddKey(0.7f, .(0.9f, 0.2f, 0.05f, 0.5f));
		ramp.AddKey(1.0f, .(0.4f, 0.05f, 0.02f, 0.0f));
		system.AddBehavior<ColorOverLifetimeBehavior>().Curve = ramp;
	}

	/// One smoke column, scaled. Soft particles are OFF: the depth fade against the floor
	/// behind a RISING column zeroes its alpha, which is how smoke goes invisible.
	public static void ConfigureSmoke(ParticleSystem system, float scale, float rise)
	{
		system.Name.Set("smoke");
		system.RenderMode = .Billboard;
		system.BlendMode = .Alpha;
		system.SoftParticles = false;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 40.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Circle(0.5f * scale);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(3.0f, 5.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, rise, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(1.0f * scale, 1.0f * scale));
		// Near white rather than grey: grey smoke over a grey floor is invisible, and this has
		// to read against both the floor it starts over and the dark sky it climbs into.
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(0.78f, 0.78f, 0.82f, 1.0f));
		system.AddBehavior<TurbulenceBehavior>().Strength = 0.8f;
		system.AddBehavior<DragBehavior>().Drag = 0.12f; // light, so the column keeps climbing
		system.AddBehavior<SizeOverLifetimeBehavior>().Curve =
			.Linear(.(1.0f * scale, 1.0f * scale), .(3.5f * scale, 3.5f * scale));

		ParticleCurveFloat alpha = .();
		alpha.AddKey(0.0f, 0.0f);
		alpha.AddKey(0.15f, 0.9f);
		alpha.AddKey(0.6f, 0.7f);
		alpha.AddKey(1.0f, 0.0f);
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = alpha;
	}

	public static void Fire(ParticleEffect effect) => ConfigureFire(effect.AddSystem(2000), 1.0f);

	public static void Smoke(ParticleEffect effect) =>
		ConfigureSmoke(effect.AddSystem(1200), 1.0f, 3.0f);

	/// Fire and smoke in ONE effect, which is the multi system authoring case.
	public static void Campfire(ParticleEffect effect)
	{
		ConfigureFire(effect.AddSystem(2000), 0.7f);

		// A thin wisp scaled to the small flame rather than a billowing column.
		let smoke = effect.AddSystem(400);
		ConfigureSmoke(smoke, 0.35f, 2.0f);
		smoke.Emitter.SpawnRate = 12.0f;
	}

	/// Rockets that burst into sparks on death, through a sub emitter link that inherits the
	/// rocket's position AND colour.
	public static void Fireworks(ParticleEffect effect)
	{
		let rocket = effect.AddSystem(64);
		rocket.Name.Set("rocket");
		rocket.RenderMode = .Trail;
		rocket.BlendMode = .Additive;
		rocket.Emitter.Mode = .Continuous;
		rocket.Emitter.SpawnRate = 3.0f;
		rocket.AddInitializer<PositionInitializer>().Shape = .Circle(0.4f);
		rocket.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.4f);
		{
			let velocity = rocket.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 13.0f, 0.0f);
			velocity.Randomness = .(1.5f, 1.5f, 1.5f);
		}
		rocket.AddInitializer<SizeInitializer>().Size = .Constant(.(0.25f, 0.25f));
		// Warm hues, because blues wash out against the dark sky. The sparks inherit this.
		rocket.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.85f, 0.2f, 1.0f),
			.(1.0f, 0.25f, 0.7f, 1.0f));
		rocket.AddBehavior<GravityBehavior>().Multiplier = 1.0f; // arc to an apex, then die
		rocket.Trail.Enabled = true;
		rocket.Trail.MaxPoints = 20;
		rocket.Trail.Lifetime = 0.4f;
		rocket.Trail.WidthStart = 0.12f;
		rocket.Trail.WidthEnd = 0.0f;
		rocket.Trail.RecordInterval = 0.02f;

		// Spawned by rocket deaths only: no self emission, or they would rain from the ground.
		let sparks = effect.AddSystem(6000);
		sparks.Name.Set("sparks");
		sparks.RenderMode = .Billboard;
		sparks.BlendMode = .Additive;
		sparks.Emitter.IsEmitting = false;
		sparks.AddInitializer<PositionInitializer>().Shape = .Point();
		sparks.AddInitializer<LifetimeInitializer>().Lifetime = .(0.9f, 1.7f);
		{
			let velocity = sparks.AddInitializer<VelocityInitializer>();
			velocity.Shape = .Sphere(1.0f, true); // a SHELL, so the burst is radial
			velocity.ShapeDirectionSpeed = 7.0f;
			velocity.Randomness = .(1.0f, 1.0f, 1.0f);
		}
		sparks.AddInitializer<SizeInitializer>().Size = .Constant(.(0.16f, 0.16f));
		sparks.AddInitializer<ColorInitializer>().Color = .Constant(.(1.0f, 1.0f, 1.0f, 1.0f));
		sparks.AddBehavior<GravityBehavior>().Multiplier = 1.3f;
		sparks.AddBehavior<DragBehavior>().Drag = 0.6f;
		sparks.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.15f);

		SubEmitterLink link = .Default();
		link.Trigger = .OnDeath;
		link.ChildSystemIndex = 1;
		link.SpawnCount = 80;
		link.Probability = 1.0f;
		link.InheritPosition = true;
		link.InheritColor = true;
		effect.AddSubEmitterLink(link);
	}

	/// A dust column swirling up a vertical axis. LOCAL space keeps the vortex and attractor
	/// centres at the origin, so the funnel spins around itself rather than around the world.
	public static void Tornado(ParticleEffect effect)
	{
		let system = effect.AddSystem(4000);
		system.Name.Set("tornado");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.SoftParticles = false;
		system.SimulationSpace = .Local;
		system.PrewarmTime = 2.0f;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 600.0f;
		system.AddInitializer<PositionInitializer>().Shape = .Circle(1.6f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.6f, 2.8f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 4.5f, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.4f, 0.4f));
		system.AddInitializer<ColorInitializer>().Color = .(.(0.55f, 0.5f, 0.42f, 1.0f),
			.(0.4f, 0.36f, 0.3f, 1.0f));
		system.AddBehavior<VortexBehavior>().Strength = 12.0f;   // the tangential swirl
		system.AddBehavior<AttractorBehavior>().Strength = 3.5f; // pull in, tightening the funnel
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.1f);
	}

	/// Burst looping fireballs that play a 4x4 flipbook over their short life. The atlas comes
	/// from the component, which is what makes this the textured billboard case.
	public static void ExplosionBlast(ParticleEffect effect)
	{
		let system = effect.AddSystem(200);
		system.Name.Set("blast");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.SoftParticles = true; // soften where a fireball meets the ground
		system.SoftDistance = 1.0f;
		system.Emitter.Mode = .Burst;
		system.Emitter.BurstCount = 5;
		system.Emitter.BurstInterval = 1.7f;
		system.Emitter.BurstCycles = 0; // forever
		system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.5f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(0.7f, 0.9f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 1.5f, 0.0f);
			velocity.Randomness = .(2.0f, 1.0f, 2.0f);
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(3.5f, 3.5f));
		system.AddInitializer<ColorInitializer>().Color = .Constant(.(1.0f, 1.0f, 1.0f, 1.0f));
		system.AddBehavior<RadialForceBehavior>().Strength = 5.0f; // spread the cluster
		system.AddBehavior<DragBehavior>().Drag = 1.5f;
		system.Flipbook.Enabled = true;
		system.Flipbook.Columns = 4;
		system.Flipbook.Rows = 4;
		system.Flipbook.OverLifetime = true; // all sixteen frames across one life
	}

	/// The explosion's untextured half: velocity stretched debris and a flat ground shockwave,
	/// burst synced to the blast so they read as one event.
	public static void ExplosionFx(ParticleEffect effect)
	{
		let debris = effect.AddSystem(1200);
		debris.Name.Set("debris");
		debris.RenderMode = .StretchedBillboard;
		debris.BlendMode = .Additive;
		debris.SoftParticles = false;
		debris.Emitter.Mode = .Burst;
		debris.Emitter.BurstCount = 140;
		debris.Emitter.BurstInterval = 1.7f;
		debris.Emitter.BurstCycles = 0;
		debris.AddInitializer<PositionInitializer>().Shape = .Sphere(0.3f);
		debris.AddInitializer<LifetimeInitializer>().Lifetime = .(0.5f, 1.0f);
		{
			let velocity = debris.AddInitializer<VelocityInitializer>();
			velocity.Shape = .Sphere(1.0f, true);
			velocity.ShapeDirectionSpeed = 13.0f;
			velocity.Randomness = .(2.0f, 2.0f, 2.0f);
		}
		debris.AddInitializer<SizeInitializer>().Size = .Constant(.(0.14f, 0.14f));
		debris.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.85f, 0.35f, 1.0f),
			.(1.0f, 0.35f, 0.1f, 1.0f));
		debris.AddBehavior<GravityBehavior>().Multiplier = 1.4f;
		debris.AddBehavior<DragBehavior>().Drag = 1.0f;
		debris.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.2f);

		// ONE flat disc that expands and fades on the ground with each boom.
		let ring = effect.AddSystem(16);
		ring.Name.Set("shock");
		ring.RenderMode = .HorizontalBillboard;
		ring.BlendMode = .Additive;
		ring.SoftParticles = false;
		ring.Emitter.Mode = .Burst;
		ring.Emitter.BurstCount = 1;
		ring.Emitter.BurstInterval = 1.7f;
		ring.Emitter.BurstCycles = 0;
		ring.AddInitializer<PositionInitializer>();
		ring.AddInitializer<LifetimeInitializer>().Lifetime = .(0.6f, 0.6f);
		ring.AddInitializer<SizeInitializer>().Size = .Constant(.(1.0f, 1.0f));
		ring.AddInitializer<ColorInitializer>().Color = .Constant(.(1.0f, 0.7f, 0.3f, 1.0f));
		ring.AddBehavior<SizeOverLifetimeBehavior>().Curve = .Linear(.(1.0f, 1.0f), .(9.0f, 9.0f));
		ring.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.0f);
	}

	/// A ground flat rune ring with glyph sparks rising off it.
	public static void MagicCircle(ParticleEffect effect)
	{
		let rune = effect.AddSystem(400);
		rune.Name.Set("rune");
		rune.RenderMode = .HorizontalBillboard;
		rune.BlendMode = .Additive;
		rune.SoftParticles = false;
		rune.PrewarmTime = 1.5f;
		rune.Emitter.Mode = .Continuous;
		rune.Emitter.SpawnRate = 60.0f;
		rune.AddInitializer<PositionInitializer>().Shape = .Ring(2.6f);
		rune.AddInitializer<LifetimeInitializer>().Lifetime = .(1.4f, 1.8f);
		rune.AddInitializer<SizeInitializer>().Size = .Constant(.(0.5f, 0.5f));
		rune.AddInitializer<ColorInitializer>().Color = .Constant(.(0.3f, 0.8f, 1.0f, 1.0f));
		rune.AddInitializer<RotationInitializer>();
		rune.AddBehavior<RotationOverLifetimeBehavior>();
		rune.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .PeakAt(0.5f, 1.0f);

		let spark = effect.AddSystem(600);
		spark.Name.Set("glyph");
		spark.RenderMode = .Billboard;
		spark.BlendMode = .Additive;
		spark.SoftParticles = false;
		spark.Emitter.Mode = .Continuous;
		spark.Emitter.SpawnRate = 40.0f;
		spark.AddInitializer<PositionInitializer>().Shape = .Ring(2.6f);
		spark.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.8f);
		spark.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 1.6f, 0.0f);
		spark.AddInitializer<SizeInitializer>().Size = .Constant(.(0.18f, 0.18f));
		spark.AddInitializer<ColorInitializer>().Color = .Constant(.(0.4f, 0.9f, 1.0f, 1.0f));
		spark.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.2f);
	}

	/// Glowing points wandering on a gentle wind, twinkling through an oscillating alpha curve.
	public static void Fireflies(ParticleEffect effect)
	{
		let system = effect.AddSystem(700);
		system.Name.Set("fireflies");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.SoftParticles = false;
		system.PrewarmTime = 2.0f;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 40.0f;
		system.AddInitializer<PositionInitializer>().Shape = .Box(.(3.0f, 2.0f, 3.0f));
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(2.5f, 4.0f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 0.2f, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.16f, 0.16f));
		system.AddInitializer<ColorInitializer>().Color = .(.(0.8f, 1.0f, 0.3f, 1.0f),
			.(1.0f, 0.9f, 0.2f, 1.0f));
		{
			let wind = system.AddBehavior<WindBehavior>();
			wind.Force = .(0.5f, 0.0f, 0.3f);
			wind.Turbulence = 1.5f;
		}
		system.AddBehavior<TurbulenceBehavior>().Strength = 1.2f;

		ParticleCurveFloat twinkle = .();
		twinkle.AddKey(0.0f, 0.0f);
		twinkle.AddKey(0.15f, 1.0f);
		twinkle.AddKey(0.35f, 0.25f);
		twinkle.AddKey(0.55f, 1.0f);
		twinkle.AddKey(0.75f, 0.3f);
		twinkle.AddKey(0.9f, 0.9f);
		twinkle.AddKey(1.0f, 0.0f);
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = twinkle;
	}

	/// A tight puff that rides its orbiting emitter as a RIGID BODY, which is what local space
	/// means: the cloud does not trail behind.
	public static void Local(ParticleEffect effect)
	{
		let system = effect.AddSystem(2000);
		system.Name.Set("orbit");
		system.RenderMode = .Billboard;
		system.BlendMode = .Additive;
		system.SimulationSpace = .Local;
		system.PrewarmTime = 1.5f; // start already populated
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 200.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.3f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.0f, 1.6f);
		system.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 0.4f, 0.0f);
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.18f, 0.18f));
		system.AddInitializer<ColorInitializer>().Color = .(.(1.0f, 0.8f, 0.3f, 1.0f),
			.(1.0f, 0.4f, 0.1f, 1.0f));
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.2f);
	}

	/// Tumbling shards, used for BOTH mesh cells: identical simulation, and only the
	/// component's material differs. That is the whole comparison.
	public static void MeshShards(ParticleEffect effect)
	{
		let system = effect.AddSystem(2000);
		system.Name.Set("shards");
		system.RenderMode = .Mesh;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 80.0f;

		system.AddInitializer<PositionInitializer>().Shape = .Sphere(0.4f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.6f, 2.6f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 3.5f, 0.0f);
			velocity.Randomness = .(1.5f, 1.0f, 1.5f);
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.3f, 0.3f));
		system.AddInitializer<ColorInitializer>().Color = .(.(0.3f, 0.9f, 1.0f, 1.0f),
			.(0.5f, 0.3f, 1.0f, 1.0f));
		system.AddInitializer<RotationInitializer>();
		system.AddInitializer<MeshOrientationInitializer>();
		system.AddBehavior<RotationOverLifetimeBehavior>(); // the tumble
		system.AddBehavior<DragBehavior>().Drag = 0.5f;
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.1f);
	}

	/// What the cooked demo bakes: a cyan fountain, deliberately unlike cell zero's so a
	/// glance says whether the cooked one is the thing on screen.
	public static void Cooked(ParticleEffect effect)
	{
		let system = effect.AddSystem(4000);
		system.Name.Set("cooked");
		system.BlendMode = .Additive;
		system.RenderMode = .Billboard;
		system.Emitter.Mode = .Continuous;
		system.Emitter.SpawnRate = 400.0f;
		system.AddInitializer<PositionInitializer>().Shape = .Cone(0.3f, 0.5f);
		system.AddInitializer<LifetimeInitializer>().Lifetime = .(1.2f, 2.0f);
		{
			let velocity = system.AddInitializer<VelocityInitializer>();
			velocity.BaseVelocity = .(0.0f, 10.0f, 0.0f);
			velocity.Randomness = .(2.5f, 1.0f, 2.5f);
		}
		system.AddInitializer<SizeInitializer>().Size = .Constant(.(0.3f, 0.3f));
		system.AddInitializer<ColorInitializer>().Color = .(.(0.2f, 1.0f, 0.9f, 1.0f),
			.(0.4f, 0.6f, 1.0f, 1.0f));
		system.AddBehavior<GravityBehavior>().Multiplier = 1.2f;
		system.AddBehavior<AlphaOverLifetimeBehavior>().Curve = .FadeOut(1.0f, 0.3f);
	}
}
