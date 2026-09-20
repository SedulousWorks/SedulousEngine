using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Terrain;

/// Adds the sculpt and splat brushes to every viewport tool set that has a scene and a
/// command stack.
class TerrainViewportToolProvider : IViewportToolProvider
{
	public void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context)
	{
		if ((context.Scene == null) || (context.Commands == null))
			return;
		manager.Add(new TerrainSculptTool(context.Scene, context.Commands, context.AssetEdits));
		manager.Add(new TerrainSplatTool(context.Scene, context.Commands, context.AssetEdits));
	}
}
