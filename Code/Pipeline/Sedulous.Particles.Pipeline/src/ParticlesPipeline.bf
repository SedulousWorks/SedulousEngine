using Sedulous.Core.Serialization;

namespace Sedulous.Particles.Pipeline;

/// Registration for the particle authoring types.
static class ParticlesPipeline
{
	/// Hand written rather than generated: the asset describes ITSELF, for the same reason the
	/// cooked resource does, so a field walk would never see it.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		target.Register(TypeIdOf("Sedulous.Particles.Pipeline.ParticleEffectAsset"),
			() => new ParticleEffectAsset());
	}
}
