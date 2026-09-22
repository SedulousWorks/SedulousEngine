using Sedulous.Editor.App;

namespace Sedulous.Editor.Vegetation;

/// The vegetation brush panel's registration; the widgets it composes live in Editor.App.
static class VegetationToolPanels
{
	private static VegetationPaintPanelProvider sPaint = null ~ delete _;

	/// Idempotent, first wins per tool id.
	public static void Register()
	{
		if (sPaint == null)
			sPaint = new VegetationPaintPanelProvider();
		ViewportToolPanelRegistry.Global.Register(sPaint);
	}
}
