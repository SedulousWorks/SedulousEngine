namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Top-level view representing the entire viewport. One per window.
/// Fills the viewport in logical coordinates (viewport size / DPI scale).
/// PopupLayer is always maintained as the last child for z-order.
public class RootView : ViewGroup
{
	/// Physical viewport size in pixels.
	public Vector2 ViewportSize;

	/// Display scale factor.
	public float DpiScale = 1.0f;

	/// Logical size (ViewportSize / DpiScale).
	public Vector2 LogicalSize => .(ViewportSize.X / DpiScale, ViewportSize.Y / DpiScale);

	// PopupLayer will be added in Phase C7 (Overlay).
	// For now, RootView is a simple full-viewport container.

	/// Measures children with tight viewport constraints.
	protected override void OnMeasure(BoxConstraints constraints)
	{
		let logical = LogicalSize;
		let tight = BoxConstraints.Tight(logical.X, logical.Y);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			child.Measure(tight);
		}

		MeasuredSize = logical;
	}

	/// Layouts children to fill the viewport.
	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			child.Layout(0, 0, width, height);
		}
	}
}
