using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Spline;

/// Adds the spline tool to every viewport tool set.
class SplineViewportToolProvider : IViewportToolProvider
{
	public void CreateTools(ViewportToolManager manager, in ViewportToolHostContext context)
	{
		manager.Add(new SplineEditTool(context));
	}
}
