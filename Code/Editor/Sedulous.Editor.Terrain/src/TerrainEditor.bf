using Sedulous.Terrain.Pipeline;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// The terrain editor's composition on the GUI: the scene view's brushes (sculpt, paint layers,
/// cut holes), their panels, the
/// splatmap thumbnails and the Terrain asset page.
static class TerrainEditor
{
	private static TerrainViewportToolProvider sProvider = null ~ delete _;

	/// The terrain's part of the scene view: its brushes, their panels and the splatmap
	/// thumbnails. Call once at editor start; the brushes and panels are process wide.
	public static void RegisterSceneTools(EditorContext context)
	{
		RegisterViewportTools();
		RegisterToolPanels();
		if (context.Thumbnails != null)
			context.Thumbnails.RegisterGenerator(new SplatmapThumbnailGenerator());
	}

	/// The terrain page; a page asks `services` (borrowed: the editor's, or a test's, which outlives
	/// the context) for its services when it is made.
	public static void Register(EditorContext context, AssetPageServicesSource services)
	{
		context.Pages.Register(new TerrainEditorPageFactory(services));
		ImageFilePreviewFactory.Register(context, typeof(SplatmapAsset));
	}

	/// The brushes into every viewport tool set, once for the process.
	public static void RegisterViewportTools()
	{
		if (sProvider != null)
			return;
		sProvider = new TerrainViewportToolProvider();
		ViewportToolProviderRegistry.Register(sProvider);
	}

	/// The brushes' panels, once for the process.
	public static void RegisterToolPanels() => TerrainToolPanels.Register();
}
