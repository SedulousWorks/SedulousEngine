using Sedulous.Core;

namespace Sedulous.UI;

/// The root of one window's view tree.
///
/// PARTIAL PORT: the viewport, its DPI scale, and the measure and arrange that give every
/// child the whole of it. The popup layer and the AddView override that keeps that layer last
/// for z order stay in the ledger until the Overlay subsystem lands.
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

	/// The root's size is the VIEWPORT's, whatever its children measure to, and every child is
	/// measured TIGHT against it: a root is a window, not a box that shrinks to fit.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let logical = LogicalSize;
		MeasuredSize = logical;

		let childConstraints = BoxConstraints.Tight(logical.X, logical.Y);
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Measure(childConstraints);
		}
	}

	/// Every child fills the root. Screens and layers STACK rather than flow, so a root gives
	/// each the whole viewport and lets the child decide what to do inside it.
	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Layout(0, 0, width, height);
		}
	}
}
