using Sedulous.Scene;

namespace Sedulous.Engine.Vegetation;

/// THE vegetation manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// provider registration stays with the subsystem.
static class VegetationScene
{
	public static void AddVegetationSceneManagers(Scene scene)
	{
		scene.AddSystem<TerrainVegetationComponentManager>();
	}
}
