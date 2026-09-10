using Sedulous.Core;

namespace Sedulous.UI;

/// The root of one window's view tree.
///
/// PARTIAL PORT: the viewport and its DPI scale. The popup layer, the AddView override that
/// keeps that layer last for z order, and the draw entry point stay in the ledger.
class RootView : ViewGroup
{
	/// In PHYSICAL pixels, as the window reports them.
	public Float2 ViewportSize = .Zero;
	public float DpiScale = 1.0f;

	public this() {}

	/// The viewport in LOGICAL units, which is the space layout runs in. The root applies the
	/// DPI scale once at draw, so everything above this line can ignore it.
	public Float2 LogicalSize
	{
		get
		{
			// Guarded, because a scale of nought would divide the layout away entirely.
			let dpi = Max(DpiScale, 0.01f);
			return .(ViewportSize.X / dpi, ViewportSize.Y / dpi);
		}
	}
}
