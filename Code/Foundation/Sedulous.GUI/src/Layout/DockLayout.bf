namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Dock position for children of a DockLayout.
public enum Dock
{
	/// Dock to the left edge. Child gets its measured width, full remaining height.
	Left,
	/// Dock to the top edge. Child gets full remaining width, its measured height.
	Top,
	/// Dock to the right edge. Child gets its measured width, full remaining height.
	Right,
	/// Dock to the bottom edge. Child gets full remaining width, its measured height.
	Bottom,
	/// Fill all remaining space.
	Fill
}

/// Layout that docks children to edges, with the last child optionally
/// filling the remaining space.
///
/// Children are processed in order. Each docked child claims space from
/// the corresponding edge, shrinking the remaining area for subsequent
/// children.
public class DockLayout : ViewGroup
{
	/// When true, the last child fills all remaining space
	/// regardless of its Dock setting. Default is false (changed from current UI).
	public bool LastChildFill = false;

	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		public Dock Dock = .Left;

		public this() { }
		public this(Dock dock) { Dock = dock; }
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new DockLayout.LayoutParams();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		float usedLeft = 0, usedTop = 0, usedRight = 0, usedBottom = 0;
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams as DockLayout.LayoutParams;
			let dock = (lp != null) ? lp.Dock : Dock.Left;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			let remainW = Math.Max(0, constraints.MaxWidth - Padding.TotalHorizontal - usedLeft - usedRight);
			let remainH = Math.Max(0, constraints.MaxHeight - Padding.TotalVertical - usedTop - usedBottom);

			bool isFill = (LastChildFill && i == ChildCount - 1) || dock == .Fill;

			BoxConstraints childConstraints;
			if (isFill)
			{
				childConstraints = BoxConstraints.Tight(
					Math.Max(0, remainW - margin.TotalHorizontal),
					Math.Max(0, remainH - margin.TotalVertical));
			}
			else if (dock == .Left || dock == .Right)
			{
				childConstraints = BoxConstraints(
					0, Math.Max(0, remainW - margin.TotalHorizontal),
					0, Math.Max(0, remainH - margin.TotalVertical));
			}
			else // Top or Bottom
			{
				childConstraints = BoxConstraints(
					0, Math.Max(0, remainW - margin.TotalHorizontal),
					0, Math.Max(0, remainH - margin.TotalVertical));
			}

			child.Measure(childConstraints);

			switch (dock)
			{
			case .Left:   usedLeft += child.MeasuredSize.X + margin.TotalHorizontal;
			case .Right:  usedRight += child.MeasuredSize.X + margin.TotalHorizontal;
			case .Top:    usedTop += child.MeasuredSize.Y + margin.TotalVertical;
			case .Bottom: usedBottom += child.MeasuredSize.Y + margin.TotalVertical;
			case .Fill:   // doesn't consume edge space
			}

			maxW = Math.Max(maxW, usedLeft + usedRight);
			maxH = Math.Max(maxH, usedTop + usedBottom);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + Padding.TotalHorizontal),
			constraints.ConstrainHeight(maxH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		float dockLeft = Padding.Left;
		float dockTop = Padding.Top;
		float dockRight = width - Padding.Right;
		float dockBottom = height - Padding.Bottom;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = child.LayoutParams as DockLayout.LayoutParams;
			let dock = (lp != null) ? lp.Dock : Dock.Left;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			bool isFill = (LastChildFill && i == ChildCount - 1) || dock == .Fill;

			if (isFill)
			{
				child.Layout(
					dockLeft + margin.Left,
					dockTop + margin.Top,
					Math.Max(0, dockRight - dockLeft - margin.TotalHorizontal),
					Math.Max(0, dockBottom - dockTop - margin.TotalVertical));
			}
			else
			{
				switch (dock)
				{
				case .Left:
					child.Layout(
						dockLeft + margin.Left,
						dockTop + margin.Top,
						child.MeasuredSize.X,
						Math.Max(0, dockBottom - dockTop - margin.TotalVertical));
					dockLeft += child.MeasuredSize.X + margin.TotalHorizontal;

				case .Right:
					child.Layout(
						dockRight - child.MeasuredSize.X - margin.Right,
						dockTop + margin.Top,
						child.MeasuredSize.X,
						Math.Max(0, dockBottom - dockTop - margin.TotalVertical));
					dockRight -= child.MeasuredSize.X + margin.TotalHorizontal;

				case .Top:
					child.Layout(
						dockLeft + margin.Left,
						dockTop + margin.Top,
						Math.Max(0, dockRight - dockLeft - margin.TotalHorizontal),
						child.MeasuredSize.Y);
					dockTop += child.MeasuredSize.Y + margin.TotalVertical;

				case .Bottom:
					child.Layout(
						dockLeft + margin.Left,
						dockBottom - child.MeasuredSize.Y - margin.Bottom,
						Math.Max(0, dockRight - dockLeft - margin.TotalHorizontal),
						child.MeasuredSize.Y);
					dockBottom -= child.MeasuredSize.Y + margin.TotalVertical;

				case .Fill: // handled above
				}
			}
		}
	}
}
