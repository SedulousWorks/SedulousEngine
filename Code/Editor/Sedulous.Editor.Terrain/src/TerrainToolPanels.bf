using System;
using Sedulous.UI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Terrain;

/// The terrain brush panels' registration; the widgets they compose live in Editor.App.
static class TerrainToolPanels
{
	private static SculptPanelProvider sSculpt = null ~ delete _;
	private static SplatPanelProvider sSplat = null ~ delete _;
	private static HolePanelProvider sHole = null ~ delete _;

	/// Registers every brush panel with the global registry; idempotent, first wins per
	/// tool id.
	public static void Register()
	{
		if (sSculpt == null)
			sSculpt = new SculptPanelProvider();
		if (sSplat == null)
			sSplat = new SplatPanelProvider();
		if (sHole == null)
			sHole = new HolePanelProvider();
		ViewportToolPanelRegistry.Global.Register(sSculpt);
		ViewportToolPanelRegistry.Global.Register(sSplat);
		ViewportToolPanelRegistry.Global.Register(sHole);
	}
}
