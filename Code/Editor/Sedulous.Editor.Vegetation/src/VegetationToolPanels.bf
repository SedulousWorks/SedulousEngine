using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation;

/// The vegetation brush panels' registration; the widgets they compose live in Editor.App.
static class VegetationToolPanels
{
	private static VegetationPaintPanelProvider sPaint = null ~ delete _;
	private static VegetationScatterPanelProvider sScatter = null ~ delete _;

	/// Idempotent, first wins per tool id.
	public static void Register()
	{
		if (sPaint == null)
			sPaint = new VegetationPaintPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sPaint);

		if (sScatter == null)
			sScatter = new VegetationScatterPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sScatter);
	}
}
