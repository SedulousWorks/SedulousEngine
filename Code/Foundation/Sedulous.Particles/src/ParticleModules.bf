using Sedulous.Core.Serialization;

namespace Sedulous.Particles;

/// Populates the serializable registry with every particle module, so a cooked effect can be
/// rebuilt from the type ids in its record.
///
/// [SerializableRegistry] reads the [Serializable] types declared in this namespace off the
/// declarations, which is why there is no hand kept list here the way Raptor keeps one.
[SerializableRegistry]
static class ParticleModules
{
	/// Registers every module. Into the global registry unless another is given.
	///
	/// Call once at startup, before loading a cooked particle effect.
	public static void RegisterModules(SerializableRegistry registry = null)
	{
		let target = (registry != null) ? registry : GlobalSerializableRegistry;
		RegisterAll(target);

		// CollisionBehavior describes ITSELF rather than carrying [Serializable] (its fixed
		// shape arrays are not something the generated body can write), so the generated
		// RegisterAll cannot see it and it is named here.
		target.Register(TypeIdOf("Sedulous.Particles.CollisionBehavior"),
			() => new CollisionBehavior());
	}
}
