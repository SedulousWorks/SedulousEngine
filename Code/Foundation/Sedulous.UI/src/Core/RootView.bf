using Sedulous.Core;

namespace Sedulous.UI;

/// The root of one window's view tree.
///
/// Owns the per window PopupLayer, created on first use and kept as the LAST child so it
/// draws on top and hit tests first.
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

	/// OWNED, created on first access.
	private PopupLayer mPopupLayer = null;

	public ~this()
	{
		// The child list's reference goes with ~ViewGroup; this is the SECOND one, taken in
		// GetPopupLayer so the field stays valid independently of the tree. Without it the
		// layer never reaches zero and outlives its root.
		if (mPopupLayer != null)
		{
			mPopupLayer.ReleaseRef();
			mPopupLayer = null;
		}
	}

	/// The overlay layer for this window, created on first use.
	public PopupLayer GetPopupLayer()
	{
		if (mPopupLayer == null)
		{
			mPopupLayer = new PopupLayer();
			mPopupLayer.AddRef(); // AddView consumes one; the root keeps its own
			base.AddView(mPopupLayer); // the base add, bypassing the keep-last override below
		}
		return mPopupLayer;
	}

	/// The layer if it EXISTS, without creating one. What focus scoping and hit testing ask,
	/// since neither should bring a layer into being just by looking.
	public PopupLayer PeekPopupLayer => mPopupLayer;

	/// Adds a child, keeping the popup layer LAST so it stays on top.
	public override ViewGroup AddView(View child)
	{
		if (child == null)
			return this;

		if (child == mPopupLayer)
			return base.AddView(child); // the layer itself

		var insertIndex = ChildCount;
		if ((ChildCount > 0) && (GetChildAt(ChildCount - 1) == mPopupLayer))
			insertIndex = ChildCount - 1;

		InsertView(child, insertIndex);
		return this;
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
