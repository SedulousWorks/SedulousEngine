using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The vegetation editor's composition, process wide: the scene view's brushes (paint vegetation,
/// paint props) and their panels.
static class VegetationEditor
{
	private static VegetationViewportToolProvider sProvider = null ~ delete _;

	/// The brushes' panels, once for the process.
	public static void RegisterToolPanels() => VegetationToolPanels.Register();

	/// Both brushes into every viewport tool set, once for the process.
	public static void RegisterViewportTools()
	{
		if (sProvider != null)
			return;
		sProvider = new VegetationViewportToolProvider();
		ViewportToolProviderRegistry.Register(sProvider);
	}
}
