namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Dock position for children of a DockLayout.
public enum Dock
{
	Left,
	Top,
	Right,
	Bottom,
	Fill
}

/// Layout that docks children to edges, with the last child optionally
/// filling the remaining space.
public class DockLayout : ViewGroup
{
	public Property<bool> LastChildFill = new .(false) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		LastChildFill.SetOwner(this);
	}

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
		let pad = Padding.Value;
		float usedLeft = 0, usedTop = 0, usedRight = 0, usedBottom = 0;
		float maxW = 0, maxH = 0;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let lp = child.LayoutParams as DockLayout.LayoutParams;
			let dock = (lp != null) ? lp.Dock : Dock.Left;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			let remainW = Math.Max(0, constraints.MaxWidth - pad.TotalHorizontal - usedLeft - usedRight);
			let remainH = Math.Max(0, constraints.MaxHeight - pad.TotalVertical - usedTop - usedBottom);

			bool isFill = (LastChildFill.Value && i == ChildCount - 1) || dock == .Fill;

			BoxConstraints childConstraints;
			if (isFill)
			{
				childConstraints = BoxConstraints.Tight(
					Math.Max(0, remainW - margin.TotalHorizontal),
					Math.Max(0, remainH - margin.TotalVertical));
			}
			else
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
			case .Fill:
			}

			maxW = Math.Max(maxW, usedLeft + usedRight);
			maxH = Math.Max(maxH, usedTop + usedBottom);
		}

		MeasuredSize = .(
			constraints.ConstrainWidth(maxW + pad.TotalHorizontal),
			constraints.ConstrainHeight(maxH + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let pad = Padding.Value;
		float dockLeft = pad.Left;
		float dockTop = pad.Top;
		float dockRight = width - pad.Right;
		float dockBottom = height - pad.Bottom;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			let lp = child.LayoutParams as DockLayout.LayoutParams;
			let dock = (lp != null) ? lp.Dock : Dock.Left;
			let margin = child.LayoutParams?.Margin ?? Thickness();

			bool isFill = (LastChildFill.Value && i == ChildCount - 1) || dock == .Fill;

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

				case .Fill:
				}
			}
		}
	}
}
