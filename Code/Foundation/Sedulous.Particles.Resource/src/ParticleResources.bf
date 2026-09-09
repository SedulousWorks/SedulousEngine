using Sedulous.Core.Serialization;
using Sedulous.Particles;
using Sedulous.Resource;

namespace Sedulous.Particles.Resource;

/// Registration for the cooked particle effect.
///
/// The MODULES are registered by the Particles module itself, which owns their identities;
/// this adds the record that holds them. The leaf families a system references, textures,
/// meshes and materials, register themselves in their own modules.
static class ParticleResources
{
	/// Registers the cooked effect and every particle module. Into the global registry unless
	/// another is given.
	///
	/// The MODULES always go into the global table as well. An effect's Serialize is handed a
	/// serializer and nothing else, so the polymorphic module read cannot reach an injected
	/// registry; a caller running its own table would otherwise cook an effect whose modules
	/// never come back, which is a silent loss rather than an error.
	public static void RegisterAll(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		ParticleModules.RegisterModules(target);
		if (target != GlobalSerializableRegistry)
			ParticleModules.RegisterModules(GlobalSerializableRegistry);
		// The resource describes itself rather than carrying [Serializable], so it is named
		// here for the same reason CollisionBehavior is.
		target.Register(TypeIdOf("Sedulous.Particles.Resource.ParticleEffectResource"),
			() => new ParticleEffectResource());
	}

	/// The manager does not take ownership, so the caller keeps the factory alive for as long
	/// as it keeps the manager.
	public static void AddFactories(ResourceManager manager, ParticleEffectFactory effects)
	{
		manager.AddFactory(effects);
	}
}
