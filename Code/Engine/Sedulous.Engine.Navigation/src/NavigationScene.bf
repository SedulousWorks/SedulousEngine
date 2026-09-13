using Sedulous.Scene;

namespace Sedulous.Engine.Navigation;

/// THE navigation manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one, so a
/// manager added here reaches both rather than only the path someone remembered.
static class NavigationScene
{
	public static void AddNavigationSceneManagers(Scene scene)
	{
		scene.AddSystem<NavMeshZoneComponentManager>();
		scene.AddSystem<NavAgentComponentManager>();
		scene.AddSystem<NavigationSceneSystem>();
	}
}
