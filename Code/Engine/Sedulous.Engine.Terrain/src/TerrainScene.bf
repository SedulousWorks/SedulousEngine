using Sedulous.Scene;

namespace Sedulous.Engine.Terrain;

/// THE terrain manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// renderer wiring, the dispatch id and the provider registration, stays with the subsystem.
static class TerrainScene
{
	public static void AddTerrainSceneManagers(Scene scene)
	{
		scene.AddSystem<TerrainComponentManager>();
	}
}
