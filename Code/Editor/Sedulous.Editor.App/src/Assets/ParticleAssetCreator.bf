namespace Sedulous.Editor.App;

using System;
using System.IO;
using Sedulous.Editor.Core;
using Sedulous.Particles;
using Sedulous.Particles.Resources;
using Sedulous.Resources;

/// Creates a default particle effect asset.
///
/// Ships a minimal one-system "Sparks"-style default so freshly created
/// .particlefx files render something visible on first open. Until an
/// editing surface for systems lands, this is the only way to get a
/// non-empty effect without writing code.
class ParticleAssetCreator : IAssetCreator
{
	public StringView DisplayName => "Particle Effect";
	public StringView Category => "Rendering";
	public StringView Extension => ".particlefx";

	public Result<Guid> Create(StringView path, EditorContext context)
	{
		let provider = context.ResourceSystem?.SerializerProvider;
		if (provider == null)
			return .Err;

		let effect = new ParticleEffect("New Effect");
		effect.AddSystem(BuildDefaultSystem());

		let res = new ParticleEffectResource(effect);
		defer delete res;
		res.Name.Set("New Effect");

		let stream = scope FileStream();
		if (stream.Create(path, .Write) case .Err)
			return .Err;
		if (res.WriteToStream(stream, provider) case .Err)
			return .Err;

		return .Ok(res.Id);
	}

	/// Builds a small additive sparks system: ~20 particles/sec, sphere
	/// emitter, upward velocity with mild gravity, white-to-orange color
	/// fading out over ~1.5s. Visible immediately without requiring a
	/// texture (the renderer falls back to a default sprite).
	private static ParticleSystem BuildDefaultSystem()
	{
		let sys = new ParticleSystem(200);
		sys.Emitter.SpawnRate = 20;
		sys.BlendMode = .Additive;

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

		sys.AddBehavior(new GravityBehavior() { Multiplier = 0.4f });
		sys.AddBehavior(new DragBehavior() { Drag = 0.6f });
		sys.AddBehavior(new AlphaOverLifetimeBehavior() { Curve = .FadeOut(1.0f) });
		sys.AddBehavior(new VelocityIntegrationBehavior());

		return sys;
	}
}
