namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Top-level ViewGroup. Owns per-window state (viewport size, DPI scale)
/// and a PopupLayer that is always the last child (topmost for drawing,
/// first for hit-testing).
public class RootView : ViewGroup
{
	public float DpiScale = 1.0f;
	public Vector2 ViewportSize;

	// Owned as child — ViewGroup destructor handles deletion.
	private PopupLayer mPopupLayer;

	/// The per-window popup/overlay layer.
	public PopupLayer PopupLayer => mPopupLayer;

	public this()
	{
		mPopupLayer = new PopupLayer();
		base.AddView(mPopupLayer);
	}

	/// Adds a child, keeping PopupLayer as the last child for z-order.
	public override void AddView(View child, LayoutParams lp = null)
	{
		if (child == null) return;

		// PopupLayer itself — just use base (already added in constructor).
		if (child is PopupLayer)
		{
			base.AddView(child, lp);
			return;
		}

		// Insert before PopupLayer (last child).
		int insertIndex = ChildCount;
		if (ChildCount > 0 && GetChildAt(ChildCount - 1) === mPopupLayer)
			insertIndex = ChildCount - 1;
		InsertView(child, insertIndex, lp);
	}

	/// Measure fills the viewport.
	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let w = MeasureSpec.Exactly(ViewportSize.X);
		let h = MeasureSpec.Exactly(ViewportSize.Y);
		MeasuredSize = .(ViewportSize.X, ViewportSize.Y);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;
			child.Measure(w, h);
		}
	}

	/// Layout fills the viewport, children fill the root.
	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		let w = right - left;
		let h = bottom - top;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams;
			let margin = (lp != null) ? lp.Margin : Thickness();

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;

			// Default gravity: fill
			let rect = GravityHelper.Apply(.Fill, w, h, childW, childH, margin);
			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}
}
