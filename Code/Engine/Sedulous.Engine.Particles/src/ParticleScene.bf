using Sedulous.Scene;

namespace Sedulous.Engine.Particles;

/// THE particle manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// renderer wiring, the dispatch id and the provider registration, stays with the subsystem.
static class ParticleScene
{
	public static void AddParticleSceneManagers(Scene scene)
	{
		scene.AddSystem<ParticleEffectComponentManager>();
	}
}
