using Sedulous.Core;

namespace Sedulous.Engine.UI;

/// Where a pointer ray met a world panel.
struct WorldPanelHit
{
	public bool Hit = false;
	/// Along the ray, in world units.
	public float Distance = 0.0f;
	/// Nought to one across the panel, with v running DOWN so it matches UI pixels.
	public Float2 Uv = .(0.0f, 0.0f);

	public this() {}
}
