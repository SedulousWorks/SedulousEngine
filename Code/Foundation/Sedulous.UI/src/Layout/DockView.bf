namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;

/// Dock position for children of a DockView.
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
/// filling the remaining space. Equivalent to WPF DockPanel.
///
/// Children are processed in order. Each docked child claims space from
/// the corresponding edge, shrinking the remaining area for subsequent
/// children. The last child fills whatever space is left when
/// LastChildFill is true (default).
///
/// Dock position is specified via DockView.LayoutParams.Dock.
public class DockView : ViewGroup
{
	/// When true (default), the last child fills all remaining space
	/// regardless of its Dock setting.
	public bool LastChildFill = true;

	/// LayoutParams for DockView children. Specifies which edge to dock to.
	public class LayoutParams : Sedulous.UI.LayoutParams
	{
		public Dock Dock = .Left;

		public this() { }
		public this(Dock dock) { Dock = dock; }
	}

	public override Sedulous.UI.LayoutParams CreateDefaultLayoutParams()
	{
		return new LayoutParams();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float usedLeft = 0, usedTop = 0, usedRight = 0, usedBottom = 0;
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = GetDockLayoutParams(child);
			let dock = lp?.Dock ?? .Left;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			let remainW = Math.Max(0, wSpec.Size - Padding.TotalHorizontal - usedLeft - usedRight);
			let remainH = Math.Max(0, hSpec.Size - Padding.TotalVertical - usedTop - usedBottom);

			// Last child fills if LastChildFill is true.
			bool isFill = (LastChildFill && i == ChildCount - 1) || dock == .Fill;

			MeasureSpec childW, childH;
			if (isFill)
			{
				childW = .Exactly(Math.Max(0, remainW - margin.TotalHorizontal));
				childH = .Exactly(Math.Max(0, remainH - margin.TotalVertical));
			}
			else if (dock == .Left || dock == .Right)
			{
				childW = MakeChildMeasureSpec(.AtMost(remainW), margin.TotalHorizontal,
					child.LayoutParams?.Width ?? Sedulous.UI.LayoutParams.WrapContent);
				childH = .Exactly(Math.Max(0, remainH - margin.TotalVertical));
			}
			else // Top or Bottom
			{
				childW = .Exactly(Math.Max(0, remainW - margin.TotalHorizontal));
				childH = MakeChildMeasureSpec(.AtMost(remainH), margin.TotalVertical,
					child.LayoutParams?.Height ?? Sedulous.UI.LayoutParams.WrapContent);
			}

			child.Measure(childW, childH);

			switch (dock)
			{
			case .Left:  usedLeft += child.MeasuredSize.X + margin.TotalHorizontal;
			case .Right: usedRight += child.MeasuredSize.X + margin.TotalHorizontal;
			case .Top:   usedTop += child.MeasuredSize.Y + margin.TotalVertical;
			case .Bottom: usedBottom += child.MeasuredSize.Y + margin.TotalVertical;
			case .Fill:  // doesn't consume edge space
			}

			maxW = Math.Max(maxW, usedLeft + usedRight);
			maxH = Math.Max(maxH, usedTop + usedBottom);
		}

		MeasuredSize = .(
			wSpec.Resolve(maxW + Padding.TotalHorizontal),
			hSpec.Resolve(maxH + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float right, float bottom)
	{
		float dockLeft = Padding.Left;
		float dockTop = Padding.Top;
		float dockRight = right - left - Padding.Right;
		float dockBottom = bottom - top - Padding.Bottom;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone) continue;

			let lp = GetDockLayoutParams(child);
			let dock = lp?.Dock ?? .Left;
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

	private LayoutParams GetDockLayoutParams(View child)
	{
		return child.LayoutParams as LayoutParams;
	}
}
