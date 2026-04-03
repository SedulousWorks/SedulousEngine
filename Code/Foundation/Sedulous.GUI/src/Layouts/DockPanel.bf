using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// Attached properties for DockPanel docking.
public static class DockPanelProperties
{
	private static Dictionary<UIElement, Dock> sDockValues = new .() ~ delete _;

	public static Dock GetDock(UIElement element)
	{
		if (sDockValues.TryGetValue(element, let val))
			return val;
		return .Left;  // Default dock
	}

	public static void SetDock(UIElement element, Dock value)
	{
		sDockValues[element] = value;
		element.InvalidateLayout();
	}

	/// Clears dock property for an element.
	public static void Clear(UIElement element)
	{
		sDockValues.Remove(element);
	}
}

/// A panel that docks children to edges, with the last child filling remaining space.
public class DockPanel : Panel
{
	private bool mLastChildFill = true;

	/// Whether the last child fills the remaining space.
	/// If false, the last child is docked according to its Dock property.
	public bool LastChildFill
	{
		get => mLastChildFill;
		set
		{
			if (mLastChildFill != value)
			{
				mLastChildFill = value;
				InvalidateLayout();
			}
		}
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float usedWidth = 0;
		float usedHeight = 0;
		float maxWidth = 0;
		float maxHeight = 0;

		float remainingWidth = constraints.MaxWidth;
		float remainingHeight = constraints.MaxHeight;

		for (int i = 0; i < Children.Count; i++)
		{
			let child = Children[i];
			if (child.Visibility == .Collapsed)
				continue;

			let dock = DockPanelProperties.GetDock(child);
			let isLast = (i == Children.Count - 1) && mLastChildFill;

			SizeConstraints childConstraints;

			if (isLast)
			{
				// Last child fills remaining space
				childConstraints = SizeConstraints.FromMaximum(remainingWidth, remainingHeight);
			}
			else
			{
				switch (dock)
				{
				case .Left, .Right:
					childConstraints = SizeConstraints.FromMaximum(remainingWidth, remainingHeight);
				case .Top, .Bottom:
					childConstraints = SizeConstraints.FromMaximum(remainingWidth, remainingHeight);
				case .Fill:
					childConstraints = SizeConstraints.FromMaximum(remainingWidth, remainingHeight);
				}
			}

			let childSize = child.Measure(childConstraints);

			switch (dock)
			{
			case .Left, .Right:
				remainingWidth = Math.Max(0, remainingWidth - childSize.Width);
				usedWidth += childSize.Width;
				maxHeight = Math.Max(maxHeight, usedHeight + childSize.Height);
			case .Top, .Bottom:
				remainingHeight = Math.Max(0, remainingHeight - childSize.Height);
				usedHeight += childSize.Height;
				maxWidth = Math.Max(maxWidth, usedWidth + childSize.Width);
			case .Fill:
				maxWidth = Math.Max(maxWidth, usedWidth + childSize.Width);
				maxHeight = Math.Max(maxHeight, usedHeight + childSize.Height);
			}
		}

		return .(Math.Max(maxWidth, usedWidth), Math.Max(maxHeight, usedHeight));
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float left = contentBounds.X;
		float top = contentBounds.Y;
		float right = contentBounds.Right;
		float bottom = contentBounds.Bottom;

		for (int i = 0; i < Children.Count; i++)
		{
			let child = Children[i];
			if (child.Visibility == .Collapsed)
				continue;

			let dock = DockPanelProperties.GetDock(child);
			let isLast = (i == Children.Count - 1) && mLastChildFill;

			RectangleF childRect;

			if (isLast)
			{
				// Last child fills remaining space
				childRect = .(left, top, right - left, bottom - top);
			}
			else
			{
				let childDesired = child.DesiredSize;

				switch (dock)
				{
				case .Left:
					childRect = .(left, top, childDesired.Width, bottom - top);
					left += childDesired.Width;
				case .Top:
					childRect = .(left, top, right - left, childDesired.Height);
					top += childDesired.Height;
				case .Right:
					childRect = .(right - childDesired.Width, top, childDesired.Width, bottom - top);
					right -= childDesired.Width;
				case .Bottom:
					childRect = .(left, bottom - childDesired.Height, right - left, childDesired.Height);
					bottom -= childDesired.Height;
				case .Fill:
					childRect = .(left, top, right - left, bottom - top);
				}
			}

			child.Arrange(childRect);
		}
	}
}
