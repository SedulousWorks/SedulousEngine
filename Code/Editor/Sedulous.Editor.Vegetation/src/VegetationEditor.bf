using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation;

/// The vegetation editor's composition: the scene view's brushes (paint vegetation, paint props) and
/// their panels, process wide, and the vegetation mask's page.
static class VegetationEditor
{
	private static VegetationViewportToolProvider sProvider = null ~ delete _;

	/// The vegetation mask page; a page asks `services` (borrowed: the editor's, or a test's, which
	/// outlives the context) for its services when it is made.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		context.Pages.Register(new VegetationMaskPageFactory(services));
	}

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
