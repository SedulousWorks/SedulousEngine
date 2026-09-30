using System;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Content;
using Sedulous.Particles;
using Sedulous.Pipeline.Core;

namespace Sedulous.Particles.Pipeline;

/// The particles domain's New Asset creator: an effect from the default seed, under
/// ParticleEffects/ unless a group was picked.
static class ParticleCreators
{
	public static void Register(AssetCreatorRegistry registry)
	{
		registry.Register(new AssetCreator("Particle Effect", "", typeof(ParticleEffectAsset), new (context) =>
			{
				let asset = scope ParticleEffectAsset();
				SeedDefaultEffect(asset.Effect);
				let instance = AssetCreator.CreateWritten(context.TargetOr("ParticleEffects"), "ParticleEffect", typeof(ParticleEffectAsset), asset);
				if (instance != null)
					GlobalLog(.Information, "Pipeline: created particle effect '{}'", instance.GetPath(.. scope .()));
				return instance;
			}));
	}

	/// A new effect: one continuous system rising under gravity, visible the moment it plays.
	public static void SeedDefaultEffect(ParticleEffect effect)
	{
		let sys = effect.AddSystem(2000);
		sys.AddInitializer<LifetimeInitializer>().Lifetime = .(1.5f, 2.5f);
		sys.AddInitializer<VelocityInitializer>().BaseVelocity = .(0.0f, 5.0f, 0.0f);
		sys.AddInitializer<SizeInitializer>();
		sys.AddInitializer<ColorInitializer>();
		sys.AddBehavior<GravityBehavior>();
		sys.Emitter.Mode = .Continuous;
		sys.Emitter.SpawnRate = 120.0f;
	}
}
