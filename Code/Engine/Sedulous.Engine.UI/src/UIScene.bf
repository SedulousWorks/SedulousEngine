using Sedulous.Scene;

namespace Sedulous.Engine.UI;

/// THE game UI manager set for a scene.
///
/// Injected by the subsystem at runtime AND by a headless consumer that never has one. The
/// per scene root view plumbing is runtime only and stays with the subsystem.
static class UIScene
{
	public static void AddUISceneManagers(Scene scene)
	{
		scene.AddSystem<UICanvasComponentManager>();
		scene.AddSystem<UIBillboardComponentManager>();
		scene.AddSystem<UIWorldPanelComponentManager>();
	}
}
