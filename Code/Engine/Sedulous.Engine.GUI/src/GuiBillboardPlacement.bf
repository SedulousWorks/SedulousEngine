using Sedulous.Core;

namespace Sedulous.Engine.GUI;

/// Where a billboard shows in a view: the point it hangs from (its bottom centre), in the
/// view's pixels, and its scale. Not shown when the point is behind the camera.
struct GuiBillboardPlacement
{
	public bool Shown = false;
	public Float2 Anchor = .(0.0f, 0.0f);
	public float Scale = 1.0f;

	public this() {}
}
