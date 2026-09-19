using Sedulous.Scene;

namespace Sedulous.Engine.Script;

/// The scene module: the script component pool and the system that runs it. Inert until
/// a host wires a run host in.
static class ScriptScene
{
	public static void AddScriptSceneManagers(Scene scene)
	{
		scene.AddSystem<ScriptComponentManager>();
		scene.AddSystem<ScriptSceneSystem>();
	}
}
