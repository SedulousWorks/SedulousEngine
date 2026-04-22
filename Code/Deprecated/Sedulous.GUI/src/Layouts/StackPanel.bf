using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// A panel that arranges its children in a single line, either horizontally or vertically.
public class StackPanel : Panel
{
	private Orientation mOrientation = .Vertical;
	private float mSpacing = 0;

	/// The direction in which children are stacked.
	public Orientation Orientation
	{
		get => mOrientation;
		set
		{
			if (mOrientation != value)
			{
				mOrientation = value;
				InvalidateLayout();
			}
		}
	}

	/// The spacing between children.
	public float Spacing
	{
		get => mSpacing;
		set
		{
			if (mSpacing != value)
			{
				mSpacing = value;
				InvalidateLayout();
			}
		}
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float totalSize = 0;
		float maxCrossSize = 0;
		int visibleCount = 0;

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			// Measure child with available constraints
			SizeConstraints childConstraints;
			if (mOrientation == .Horizontal)
			{
				// Horizontal: unlimited width, constrained height
				childConstraints = SizeConstraints(0, constraints.MinHeight, SizeConstraints.Infinity, constraints.MaxHeight);
			}
			else
			{
				// Vertical: constrained width, unlimited height
				childConstraints = SizeConstraints(constraints.MinWidth, 0, constraints.MaxWidth, SizeConstraints.Infinity);
			}

			let childSize = child.Measure(childConstraints);

			if (mOrientation == .Horizontal)
			{
				totalSize += childSize.Width;
				maxCrossSize = Math.Max(maxCrossSize, childSize.Height);
			}
			else
			{
				totalSize += childSize.Height;
				maxCrossSize = Math.Max(maxCrossSize, childSize.Width);
			}

			visibleCount++;
		}

		// Add spacing between children
		if (visibleCount > 1)
			totalSize += mSpacing * (visibleCount - 1);

		if (mOrientation == .Horizontal)
			return .(totalSize, maxCrossSize);
		else
			return .(maxCrossSize, totalSize);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float offset = 0;

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			let childDesired = child.DesiredSize;

			RectangleF childRect;
			if (mOrientation == .Horizontal)
			{
				childRect = .(
					contentBounds.X + offset,
					contentBounds.Y,
					childDesired.Width,
					contentBounds.Height
				);
				offset += childDesired.Width + mSpacing;
			}
			else
			{
				childRect = .(
					contentBounds.X,
					contentBounds.Y + offset,
					contentBounds.Width,
					childDesired.Height
				);
				offset += childDesired.Height + mSpacing;
			}

			child.Arrange(childRect);
		}
	}
}
