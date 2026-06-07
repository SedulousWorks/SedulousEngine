namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;
using System;

/// Top-level view representing the entire viewport.
/// One per window. Fills the viewport, lays out children, and owns a
/// PopupLayer that is always the last child (topmost for drawing and
/// hit-testing).
public class RootView : ViewGroup
{
	/// Physical viewport size in pixels.
	public Vector2 ViewportSize;

	/// DPI scale factor (1.0 = 96dpi, 2.0 = 192dpi).
	public float DpiScale = 1.0f;

	/// Viewport size in logical (layout) coordinates - the space that LocalToScreen,
	/// Bounds, and MeasuredSize live in. Always use this when comparing positions
	/// produced by the layout system against the viewport extent; comparing those
	/// against ViewportSize directly breaks at non-1.0 DPI scales.
	public Vector2 LogicalSize
	{
		get
		{
			let dpi = Math.Max(DpiScale, 0.01f);
			return .(ViewportSize.X / dpi, ViewportSize.Y / dpi);
		}
	}

	// Owned as child - ViewGroup destructor handles deletion.
	private PopupLayer mPopupLayer;

	/// The per-window popup/overlay layer.
	public PopupLayer PopupLayer => mPopupLayer;

	public this()
	{
		mPopupLayer = new PopupLayer();
		base.AddView(mPopupLayer);
	}

	/// Adds a child, keeping PopupLayer as the last child for z-order.
	public override ViewGroup AddView(View child, LayoutParams lp = null)
	{
		if (child == null) return this;

		// PopupLayer itself - just use base (already added in constructor).
		if (child is PopupLayer)
			return base.AddView(child, lp);

		// Insert before PopupLayer (last child).
		int insertIndex = ChildCount;
		if (ChildCount > 0 && GetChildAt(ChildCount - 1) === mPopupLayer)
			insertIndex = ChildCount - 1;
		InsertView(child, insertIndex, lp);
		return this;
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// RootView fills the viewport in logical coordinates (physical / DpiScale).
		let logicalW = ViewportSize.X / Math.Max(DpiScale, 0.01f);
		let logicalH = ViewportSize.Y / Math.Max(DpiScale, 0.01f);
		MeasuredSize = .(logicalW, logicalH);

		// Measure children with tight viewport constraints
		let childConstraints = BoxConstraints.Tight(logicalW, logicalH);
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Measure(childConstraints);
		}
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		// Layout children to fill viewport
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility != .Gone)
				child.Layout(0, 0, width, height);
		}
	}
}
