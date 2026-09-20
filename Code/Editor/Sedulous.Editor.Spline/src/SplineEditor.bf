using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Spline;

/// The spline editor's composition: its viewport tool provider, registered once for the
/// process.
static class SplineEditor
{
	private static SplineViewportToolProvider sProvider = null ~ delete _;

	public static void RegisterViewportTools()
	{
		if (sProvider != null)
			return;
		sProvider = new SplineViewportToolProvider();
		ViewportToolProviderRegistry.Register(sProvider);
	}
}
