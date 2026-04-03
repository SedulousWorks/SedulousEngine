using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.GUI;

/// A panel that arranges children in a wrapping flow, starting a new row/column when space runs out.
public class WrapPanel : Panel
{
	private Orientation mOrientation = .Horizontal;
	private float mItemWidth = 0;  // 0 = use child's desired width
	private float mItemHeight = 0;  // 0 = use child's desired height

	/// The direction in which children flow.
	/// Horizontal: children flow left to right, wrap to next row.
	/// Vertical: children flow top to bottom, wrap to next column.
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

	/// Fixed width for all items. 0 means use each child's desired width.
	public float ItemWidth
	{
		get => mItemWidth;
		set
		{
			if (mItemWidth != value)
			{
				mItemWidth = value;
				InvalidateLayout();
			}
		}
	}

	/// Fixed height for all items. 0 means use each child's desired height.
	public float ItemHeight
	{
		get => mItemHeight;
		set
		{
			if (mItemHeight != value)
			{
				mItemHeight = value;
				InvalidateLayout();
			}
		}
	}

	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		float lineSize = 0;  // Size along the primary axis for current line
		float maxLineSize = 0;  // Maximum line size seen
		float totalCrossSize = 0;  // Total size along cross axis
		float currentLineCrossSize = 0;  // Max cross size in current line

		float maxPrimarySize = mOrientation == .Horizontal ? constraints.MaxWidth : constraints.MaxHeight;

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			// Measure with item size constraints if specified
			SizeConstraints childConstraints;
			if (mOrientation == .Horizontal)
			{
				float w = mItemWidth > 0 ? mItemWidth : constraints.MaxWidth;
				float h = mItemHeight > 0 ? mItemHeight : constraints.MaxHeight;
				childConstraints = SizeConstraints.FromMaximum(w, h);
			}
			else
			{
				float w = mItemWidth > 0 ? mItemWidth : constraints.MaxWidth;
				float h = mItemHeight > 0 ? mItemHeight : constraints.MaxHeight;
				childConstraints = SizeConstraints.FromMaximum(w, h);
			}

			let childSize = child.Measure(childConstraints);

			float childPrimarySize = mOrientation == .Horizontal ?
				(mItemWidth > 0 ? mItemWidth : childSize.Width) :
				(mItemHeight > 0 ? mItemHeight : childSize.Height);
			float childCrossSize = mOrientation == .Horizontal ?
				(mItemHeight > 0 ? mItemHeight : childSize.Height) :
				(mItemWidth > 0 ? mItemWidth : childSize.Width);

			// Check if we need to wrap
			if (lineSize + childPrimarySize > maxPrimarySize && lineSize > 0)
			{
				// Finish current line
				maxLineSize = Math.Max(maxLineSize, lineSize);
				totalCrossSize += currentLineCrossSize;

				// Start new line
				lineSize = childPrimarySize;
				currentLineCrossSize = childCrossSize;
			}
			else
			{
				lineSize += childPrimarySize;
				currentLineCrossSize = Math.Max(currentLineCrossSize, childCrossSize);
			}
		}

		// Don't forget the last line
		maxLineSize = Math.Max(maxLineSize, lineSize);
		totalCrossSize += currentLineCrossSize;

		if (mOrientation == .Horizontal)
			return .(maxLineSize, totalCrossSize);
		else
			return .(totalCrossSize, maxLineSize);
	}

	protected override void ArrangeOverride(RectangleF contentBounds)
	{
		float primaryOffset = 0;  // Offset along primary axis
		float crossOffset = 0;  // Offset along cross axis
		float currentLineCrossSize = 0;  // Max cross size in current line

		float maxPrimarySize = mOrientation == .Horizontal ? contentBounds.Width : contentBounds.Height;

		// First pass: calculate line cross sizes
		// Second pass: arrange children
		// (For simplicity, we'll do it in one pass with dynamic line sizing)
		// todo?

		for (let child in Children)
		{
			if (child.Visibility == .Collapsed)
				continue;

			let childDesired = child.DesiredSize;

			float childWidth = mItemWidth > 0 ? mItemWidth : childDesired.Width;
			float childHeight = mItemHeight > 0 ? mItemHeight : childDesired.Height;

			float childPrimarySize = mOrientation == .Horizontal ? childWidth : childHeight;
			float childCrossSize = mOrientation == .Horizontal ? childHeight : childWidth;

			// Check if we need to wrap
			if (primaryOffset + childPrimarySize > maxPrimarySize && primaryOffset > 0)
			{
				// Move to next line
				crossOffset += currentLineCrossSize;
				primaryOffset = 0;
				currentLineCrossSize = 0;
			}

			// Arrange child
			RectangleF childRect;
			if (mOrientation == .Horizontal)
			{
				childRect = .(
					contentBounds.X + primaryOffset,
					contentBounds.Y + crossOffset,
					childWidth,
					childHeight
				);
			}
			else
			{
				childRect = .(
					contentBounds.X + crossOffset,
					contentBounds.Y + primaryOffset,
					childWidth,
					childHeight
				);
			}

			child.Arrange(childRect);

			primaryOffset += childPrimarySize;
			currentLineCrossSize = Math.Max(currentLineCrossSize, childCrossSize);
		}
	}
}
