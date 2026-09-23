using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Vegetation;

/// Adds both vegetation brushes, the mask one and the prop one, to every viewport tool set
/// that has a scene and a command stack.
class VegetationViewportToolProvider : IViewportToolProvider
{
	public void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context)
	{
		if ((context.Scene == null) || (context.Commands == null))
			return;
		manager.Add(new VegetationPaintTool(context.Scene, context.Commands, context.AssetEdits));
		manager.Add(new VegetationScatterTool(context.Scene, context.Commands));
	}
}
