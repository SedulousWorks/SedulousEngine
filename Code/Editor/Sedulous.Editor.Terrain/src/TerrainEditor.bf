using Sedulous.Runtime.Client;
using Sedulous.UI.Runtime;
using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The terrain editor's composition: the asset serializables, its page, the splatmap
/// thumbnail when the context has a thumbnail service, and, process wide, the scene
/// viewport brushes with their panels.
static class TerrainEditor
{
	private static TerrainViewportToolProvider sProvider = null ~ delete _;

	public static void Register(EditorContext context, IApplicationHost host, UIHost uiHost)
	{
		TerrainPipeline.RegisterAll();
		context.Pages.Register(new TerrainEditorPageFactory(host, uiHost));
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new SplatmapThumbnailGenerator());
	}

	/// The sculpt and splat brushes into every viewport tool set, once for the process.
	public static void RegisterViewportTools()
	{
		if (sProvider != null)
			return;
		sProvider = new TerrainViewportToolProvider();
		ViewportToolProviderRegistry.Register(sProvider);
	}

	/// The brushes' floating panels, once for the process.
	public static void RegisterToolPanels() => TerrainToolPanels.Register();
}
