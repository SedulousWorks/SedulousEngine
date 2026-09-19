using Sedulous.Scene;

namespace Sedulous.Scene.Resource;

/// The scene module: the spawn system, inert until a host gives it a source.
static class PrefabSpawnScene
{
	public static void AddPrefabSpawnSceneManagers(Scene scene)
	{
		scene.AddSystem<PrefabSpawnSystem>();
	}
}
