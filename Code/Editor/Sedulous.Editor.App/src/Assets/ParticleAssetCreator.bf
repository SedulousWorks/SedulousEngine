namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Particles;
using Sedulous.Particles.Resources;
using Sedulous.Resources;
using Sedulous.VFS;

/// Creates a default particle effect asset.
///
/// Ships a one-system "Sparks"-style default that exercises every
/// initializer and every behavior so each shows up in the editor tree
/// and can be inspected / tuned without rewriting the asset. Force
/// behaviors that would compound and obscure the simulation start at
/// neutral / off values; the user enables them by editing fields.
class ParticleAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Particle Effect";
	public StringView Category => "Rendering";
	public StringView Extension => ".particlefx";

	public Result<Guid> Create(IWritableMount mount, StringView locator, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let effect = new ParticleEffect("New Effect");
		effect.AddSystem(BuildDefaultSystem());

		let res = new ParticleEffectResource(effect);
		defer delete res;
		res.Name.Set("New Effect");

		let stream = scope MemoryStream();
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;
		stream.Position = 0;
		if (mount.Save(locator, stream) case .Err)
			return .Err;

		return .Ok(res.Id);
	}

	/// Builds a small additive sparks system with every initializer and
	/// behavior wired in, so the editor tree exposes the full surface for
	/// inspection. Force behaviors default to neutral values - Gravity at
	/// 0.4 multiplier and Drag at 0.6 stay active to keep the preview
	/// looking like sparks; Wind / Attractor / RadialForce / Turbulence
	/// / Vortex start with zero strength and must be tuned to take effect.
	/// Curve-driven overlife behaviors start with empty curves (no-op
	/// until the user authors keyframes), except Alpha which fades out.
	private static ParticleSystem BuildDefaultSystem()
	{
		let sys = new ParticleSystem(200);
		sys.Emitter.SpawnRate = 20;
		sys.BlendMode = .Additive;

		// --- All 6 initializers ---
		sys.AddInitializer(new LifetimeInitializer() { Lifetime = .(0.8f, 1.6f) });
		sys.AddInitializer(new PositionInitializer() { Shape = .Sphere(0.2f) });
		sys.AddInitializer(new VelocityInitializer() {
			BaseVelocity = .(0, 2, 0),
			Randomness = .(1, 0.5f, 1)
		});
		sys.AddInitializer(new SizeInitializer() { Size = .Constant(.(0.1f, 0.1f)) });
		sys.AddInitializer(new ColorInitializer() {
			Color = .Range(.(1, 0.6f, 0.2f, 1), .(1, 1, 0.4f, 1))
		});
		sys.AddInitializer(new RotationInitializer());

		// --- All 13 behaviors ---
		// Active by default - keep the sparks look.
		sys.AddBehavior(new GravityBehavior() { Multiplier = 0.4f });
		sys.AddBehavior(new DragBehavior() { Drag = 0.6f });

		// Force behaviors neutralized so they don't fight the sparks until
		// the user tunes them. Each is still present in the tree.
		sys.AddBehavior(new WindBehavior() { Force = .Zero, Turbulence = 0 });
		sys.AddBehavior(new AttractorBehavior() { Strength = 0, Radius = 0 });
		sys.AddBehavior(new RadialForceBehavior() { Strength = 0 });
		sys.AddBehavior(new TurbulenceBehavior() { Strength = 0 });
		sys.AddBehavior(new VortexBehavior() { Strength = 0 });

		// Overlife curves - alpha fades out to 0; others start empty
		// (KeyCount == 0 means "inactive", behavior no-ops on update).
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f) });
		sys.AddBehavior(new ColorOverLifetimeBehavior());
		sys.AddBehavior(new SizeOverLifetimeBehavior());
		sys.AddBehavior(new SpeedOverLifetimeBehavior());
		sys.AddBehavior(new RotationOverLifetimeBehavior());

		// Velocity integration + age advance run automatically inside
		// ParticleSystem.Update as a built-in final step (was a manually-
		// added VelocityIntegrationBehavior before).

		return sys;
	}
}
