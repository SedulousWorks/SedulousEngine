using Sedulous.Scene;

namespace Sedulous.Engine.GUI;

/// The GUI's manager set for a scene.
///
/// Added by the subsystem's scenes and by a headless scene consumer alike, which never has the
/// GUI's context: the trees are the subsystem's, built at runtime.
static class GuiScene
{
	public static void AddGuiSceneManagers(Scene scene)
	{
		scene.AddSystem<GuiCanvasComponentManager>();
		scene.AddSystem<GuiBillboardComponentManager>();
		scene.AddSystem<GuiWorldPanelComponentManager>();
	}
}
