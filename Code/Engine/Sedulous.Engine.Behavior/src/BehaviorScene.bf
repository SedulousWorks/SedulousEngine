using Sedulous.Scene;

namespace Sedulous.Engine.Behavior;

/// The scene module: the behavior component pool and the system that runs it. Inert until
/// a host wires a run host in.
static class BehaviorScene
{
	public static void AddBehaviorSceneManagers(Scene scene)
	{
		scene.AddSystem<BehaviorComponentManager>();
		scene.AddSystem<BehaviorSystem>();
	}
}
