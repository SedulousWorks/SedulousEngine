using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Vegetation.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// The vegetation editor's composition: its asset serializables and, process wide, the
/// scene viewport brush.
static class VegetationEditor
{
	private static VegetationViewportToolProvider sProvider = null ~ delete _;

	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		VegetationPipeline.RegisterAll();
	}

	/// The brush's floating panel, once for the process.
	public static void RegisterToolPanels() => VegetationToolPanels.Register();

	/// The paint brush into every viewport tool set, once for the process.
	public static void RegisterViewportTools()
	{
		if (sProvider != null)
			return;
		sProvider = new VegetationViewportToolProvider();
		ViewportToolProviderRegistry.Register(sProvider);
	}
}
