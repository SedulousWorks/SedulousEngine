using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// The terrain editor's composition, on the GUI so far (Raptor's editor-gui spec, 5.3, layer 5,
/// part 3): the scene view's brushes (sculpt, paint layers, cut holes), their panels and the
/// splatmap thumbnails. The Terrain asset page (TerrainEditorPage) stays out of the build, unedited,
/// until its port.
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
