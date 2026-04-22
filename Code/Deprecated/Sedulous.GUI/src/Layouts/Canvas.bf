using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Attached properties for Canvas positioning.
/// Since Beef doesn't have WPF-style attached properties, we use a static dictionary.
public static class CanvasProperties
{
	private static Dictionary<UIElement, float?> sLeftValues = new .() ~ delete _;
	private static Dictionary<UIElement, float?> sTopValues = new .() ~ delete _;
	private static Dictionary<UIElement, float?> sRightValues = new .() ~ delete _;
	private static Dictionary<UIElement, float?> sBottomValues = new .() ~ delete _;

	public static float? GetLeft(UIElement element)
	{
		if (sLeftValues.TryGetValue(element, let val))
			return val;
		return null;
	}

	public static void SetLeft(UIElement element, float? value)
	{
		if (value.HasValue)
			sLeftValues[element] = value;
		else
			sLeftValues.Remove(element);
		element.InvalidateLayout();
	}

	public static float? GetTop(UIElement element)
	{
		if (sTopValues.TryGetValue(element, let val))
			return val;
		return null;
	}

	public static void SetTop(UIElement element, float? value)
	{
		if (value.HasValue)
			sTopValues[element] = value;
		else
			sTopValues.Remove(element);
		element.InvalidateLayout();
	}

	public static float? GetRight(UIElement element)
	{
		if (sRightValues.TryGetValue(element, let val))
			return val;
		return null;
	}

	public static void SetRight(UIElement element, float? value)
	{
		if (value.HasValue)
			sRightValues[element] = value;
		else
			sRightValues.Remove(element);
		element.InvalidateLayout();
	}

	public static float? GetBottom(UIElement element)
	{
		if (sBottomValues.TryGetValue(element, let val))
			return val;
		return null;
	}

	public static void SetBottom(UIElement element, float? value)
	{
		if (value.HasValue)
			sBottomValues[element] = value;
		else
			sBottomValues.Remove(element);
		element.InvalidateLayout();
	}

	/// Clears all canvas properties for an element.
	/// Should be called when an element is removed from a Canvas.
	public static void ClearAll(UIElement element)
	{
		sLeftValues.Remove(element);
		sTopValues.Remove(element);
		sRightValues.Remove(element);
		sBottomValues.Remove(element);
	}
}

/// A panel that positions children using absolute coordinates.
/// Children are positioned using Canvas.Left, Canvas.Top, Canvas.Right, Canvas.Bottom.
public class Canvas : Panel
{
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		// Canvas doesn't constrain its children during measure
		// Children get infinite space to determine their desired size
		float maxRight = 0;
		float maxBottom = 0;

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			// Measure with unconstrained size
			let childSize = child.Measure(SizeConstraints.Unconstrained);

			// Calculate the extent this child would occupy
			float left = CanvasProperties.GetLeft(child) ?? 0;
			float top = CanvasProperties.GetTop(child) ?? 0;

			maxRight = Math.Max(maxRight, left + childSize.Width);
			maxBottom = Math.Max(maxBottom, top + childSize.Height);
		}

		return .(maxRight, maxBottom);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			let childDesired = child.DesiredSize;
			let left = CanvasProperties.GetLeft(child);
			let top = CanvasProperties.GetTop(child);
			let right = CanvasProperties.GetRight(child);
			let bottom = CanvasProperties.GetBottom(child);

			float x, y, width, height;

			// Determine width
			if (left.HasValue && right.HasValue)
			{
				// Both left and right specified: stretch
				x = contentBounds.X + left.Value;
				width = contentBounds.Width - left.Value - right.Value;
			}
			else if (right.HasValue)
			{
				// Only right specified: position from right edge
				width = childDesired.Width;
				x = contentBounds.Right - right.Value - width;
			}
			else
			{
				// Left specified or default to 0
				x = contentBounds.X + (left ?? 0);
				width = childDesired.Width;
			}

			// Determine height
			if (top.HasValue && bottom.HasValue)
			{
				// Both top and bottom specified: stretch
				y = contentBounds.Y + top.Value;
				height = contentBounds.Height - top.Value - bottom.Value;
			}
			else if (bottom.HasValue)
			{
				// Only bottom specified: position from bottom edge
				height = childDesired.Height;
				y = contentBounds.Bottom - bottom.Value - height;
			}
			else
			{
				// Top specified or default to 0
				y = contentBounds.Y + (top ?? 0);
				height = childDesired.Height;
			}

			child.Arrange(.(x, y, Math.Max(0, width), Math.Max(0, height)));
		}
	}
}
