using Sedulous.Core;

namespace Sedulous.Engine.GUI;

/// Where a pointer ray met a world panel.
struct GuiPanelHit
{
	public bool Hit = false;
	/// Along the ray, in world units.
	public float Distance = 0.0f;
	/// Nought to one across the panel, with v running DOWN so it matches a GUI's pixels.
	public Float2 Uv = .(0.0f, 0.0f);

	public this() {}
}
