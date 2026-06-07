namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Main-axis content distribution.
public enum Justify { Start, End, Center, SpaceBetween, SpaceAround, SpaceEvenly }

/// Cross-axis alignment.
public enum Align { Start, End, Center, Stretch, Baseline }

/// CSS Flexbox-inspired container. Replaces LinearLayout with grow/shrink
/// distribution, justify content, and cross-axis alignment.
public class FlexLayout : ViewGroup
{
	/// Main axis direction.
	public Property<Orientation> Direction = new .(.Horizontal) ~ delete _;

	/// How to distribute extra space on the main axis.
	public Property<Justify> JustifyContent = new .(.Start) ~ delete _;

	/// Default cross-axis alignment for children.
	public Property<Align> AlignItems = new .(.Stretch) ~ delete _;

	/// Spacing between children on the main axis.
	public Property<float> Spacing = new .(0) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		Direction.SetOwner(this);
		JustifyContent.SetOwner(this);
		AlignItems.SetOwner(this);
		Spacing.SetOwner(this);
	}

	public class LayoutParams : Sedulous.GUI.LayoutParams
	{
		/// How much extra main-axis space this child absorbs (0 = fixed).
		public float Grow = 0;

		/// How much this child shrinks when space is insufficient (0 = no shrink).
		public float Shrink = 0;

		/// Cross-axis override for this child (null = use parent's AlignItems).
		public Align? AlignSelf;

		/// Cross-axis gravity (for positioning within allocated cross-axis space).
		public Gravity Gravity = .None;
	}

	protected override Sedulous.GUI.LayoutParams CreateDefaultLayoutParams()
		=> new FlexLayout.LayoutParams();

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = Padding.Value;
		let inner = constraints.Deflate(pad);

		if (Direction.Value == .Horizontal)
			MeasureHorizontal(inner, constraints);
		else
			MeasureVertical(inner, constraints);
	}

	private static BoxConstraints MakeChildConstraintsLooseCross(BoxConstraints parent, View child, bool isHorizontal)
	{
		let lp = child.LayoutParams;
		let margin = (lp != null) ? lp.Margin : Thickness();
		let dpiScale = child.Root?.DpiScale ?? 1.0f;

		let availW = Math.Max(0, parent.MaxWidth - margin.TotalHorizontal);
		let availH = Math.Max(0, parent.MaxHeight - margin.TotalVertical);

		var widthSpec = (lp != null) ? lp.Width : SizeSpec.Wrap;
		var heightSpec = (lp != null) ? lp.Height : SizeSpec.Wrap;

		if (isHorizontal && heightSpec case .Match)
			heightSpec = .Wrap;
		else if (!isHorizontal && widthSpec case .Match)
			widthSpec = .Wrap;

		float minW, maxW, minH, maxH;

		switch (widthSpec)
		{
		case .Fixed(let unit): let w = unit.Resolve(dpiScale); minW = w; maxW = w;
		case .Match:           minW = availW; maxW = availW;
		case .Wrap:            minW = 0; maxW = availW;
		}

		switch (heightSpec)
		{
		case .Fixed(let unit): let h = unit.Resolve(dpiScale); minH = h; maxH = h;
		case .Match:           minH = availH; maxH = availH;
		case .Wrap:            minH = 0; maxH = availH;
		}

		return .(minW, maxW, minH, maxH);
	}

	private void MeasureHorizontal(BoxConstraints inner, BoxConstraints outer)
	{
		let pad = Padding.Value;
		let spacing = Spacing.Value;
		float totalFixed = 0;
		float maxCross = 0;
		float totalGrow = 0;
		int visibleCount = 0;
		bool hasMatchCross = false;

		let looseInner = BoxConstraints(inner.MinWidth, inner.MaxWidth, 0, inner.MaxHeight);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			visibleCount++;

			let flp = child.LayoutParams as FlexLayout.LayoutParams;
			let grow = (flp != null) ? flp.Grow : 0;
			let heightSpec = (child.LayoutParams != null) ? child.LayoutParams.Height : SizeSpec.Wrap;

			if (grow > 0)
			{
				totalGrow += grow;
				continue;
			}

			let looseChild = MakeChildConstraintsLooseCross(looseInner, child, true);
			child.Measure(looseChild);
			let margin = child.LayoutParams?.Margin ?? Thickness();
			totalFixed += child.MeasuredSize.X + margin.TotalHorizontal;

			maxCross = Math.Max(maxCross, child.MeasuredSize.Y + margin.TotalVertical);
			if (heightSpec case .Match)
				hasMatchCross = true;
		}

		if (visibleCount > 1)
			totalFixed += spacing * (visibleCount - 1);

		if (totalGrow > 0)
		{
			let isMainAxisDefinite = inner.MaxWidth < 100000;
			let remaining = isMainAxisDefinite ? Math.Max(0, inner.MaxWidth - totalFixed) : 0;

			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility.Value == .Gone) continue;

				let flp = child.LayoutParams as FlexLayout.LayoutParams;
				let grow = (flp != null) ? flp.Grow : 0;
				if (grow <= 0) continue;

				let heightSpec = (child.LayoutParams != null) ? child.LayoutParams.Height : SizeSpec.Wrap;
				let margin = child.LayoutParams?.Margin ?? Thickness();

				if (isMainAxisDefinite)
				{
					let childMain = remaining * grow / totalGrow;
					let childConstraints = BoxConstraints(
						childMain - margin.TotalHorizontal, Math.Max(0, childMain - margin.TotalHorizontal),
						0, Math.Max(0, inner.MaxHeight - margin.TotalVertical));
					child.Measure(childConstraints);
					totalFixed += childMain;
				}
				else
				{
					let looseChild = MakeChildConstraintsLooseCross(looseInner, child, true);
					child.Measure(looseChild);
					totalFixed += child.MeasuredSize.X + margin.TotalHorizontal;
				}

				maxCross = Math.Max(maxCross, child.MeasuredSize.Y + margin.TotalVertical);
				if (heightSpec case .Match)
					hasMatchCross = true;
			}
		}

		if (hasMatchCross && maxCross > 0)
		{
			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility.Value == .Gone) continue;

				let heightSpec = (child.LayoutParams != null) ? child.LayoutParams.Height : SizeSpec.Wrap;
				if (heightSpec case .Match)
				{
					let margin = child.LayoutParams?.Margin ?? Thickness();
					let crossH = Math.Max(0, maxCross - margin.TotalVertical);
					let childConstraints = BoxConstraints(
						child.MeasuredSize.X, child.MeasuredSize.X,
						crossH, crossH);
					child.Measure(childConstraints);
				}
			}
		}

		MeasuredSize = .(
			outer.ConstrainWidth(totalFixed + pad.TotalHorizontal),
			outer.ConstrainHeight(maxCross + pad.TotalVertical));
	}

	private void MeasureVertical(BoxConstraints inner, BoxConstraints outer)
	{
		let pad = Padding.Value;
		let spacing = Spacing.Value;
		float totalFixed = 0;
		float maxCross = 0;
		float totalGrow = 0;
		int visibleCount = 0;
		bool hasMatchCross = false;

		let looseInner = BoxConstraints(0, inner.MaxWidth, inner.MinHeight, inner.MaxHeight);

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			visibleCount++;

			let flp = child.LayoutParams as FlexLayout.LayoutParams;
			let grow = (flp != null) ? flp.Grow : 0;
			let widthSpec = (child.LayoutParams != null) ? child.LayoutParams.Width : SizeSpec.Wrap;

			if (grow > 0)
			{
				totalGrow += grow;
				continue;
			}

			let looseChild = MakeChildConstraintsLooseCross(looseInner, child, false);
			child.Measure(looseChild);
			let margin = child.LayoutParams?.Margin ?? Thickness();
			totalFixed += child.MeasuredSize.Y + margin.TotalVertical;

			maxCross = Math.Max(maxCross, child.MeasuredSize.X + margin.TotalHorizontal);
			if (widthSpec case .Match)
				hasMatchCross = true;
		}

		if (visibleCount > 1)
			totalFixed += spacing * (visibleCount - 1);

		if (totalGrow > 0)
		{
			let isMainAxisDefinite = inner.MaxHeight < 100000;
			let remaining = isMainAxisDefinite ? Math.Max(0, inner.MaxHeight - totalFixed) : 0;

			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility.Value == .Gone) continue;

				let flp = child.LayoutParams as FlexLayout.LayoutParams;
				let grow = (flp != null) ? flp.Grow : 0;
				if (grow <= 0) continue;

				let widthSpec = (child.LayoutParams != null) ? child.LayoutParams.Width : SizeSpec.Wrap;
				let margin = child.LayoutParams?.Margin ?? Thickness();

				if (isMainAxisDefinite)
				{
					let childMain = remaining * grow / totalGrow;
					let childConstraints = BoxConstraints(
						0, Math.Max(0, inner.MaxWidth - margin.TotalHorizontal),
						childMain - margin.TotalVertical, Math.Max(0, childMain - margin.TotalVertical));
					child.Measure(childConstraints);
					totalFixed += childMain;
				}
				else
				{
					let looseChild = MakeChildConstraintsLooseCross(looseInner, child, false);
					child.Measure(looseChild);
					totalFixed += child.MeasuredSize.Y + margin.TotalVertical;
				}

				maxCross = Math.Max(maxCross, child.MeasuredSize.X + margin.TotalHorizontal);
				if (widthSpec case .Match)
					hasMatchCross = true;
			}
		}

		if (hasMatchCross && maxCross > 0)
		{
			for (int i = 0; i < ChildCount; i++)
			{
				let child = GetChildAt(i);
				if (child.Visibility.Value == .Gone) continue;

				let widthSpec = (child.LayoutParams != null) ? child.LayoutParams.Width : SizeSpec.Wrap;
				if (widthSpec case .Match)
				{
					let margin = child.LayoutParams?.Margin ?? Thickness();
					let crossW = Math.Max(0, maxCross - margin.TotalHorizontal);
					let childConstraints = BoxConstraints(
						crossW, crossW,
						child.MeasuredSize.Y, child.MeasuredSize.Y);
					child.Measure(childConstraints);
				}
			}
		}

		MeasuredSize = .(
			outer.ConstrainWidth(maxCross + pad.TotalHorizontal),
			outer.ConstrainHeight(totalFixed + pad.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		if (Direction.Value == .Horizontal)
			LayoutHorizontal(width, height);
		else
			LayoutVertical(width, height);
	}

	private void LayoutHorizontal(float width, float height)
	{
		let pad = Padding.Value;
		let spacing = Spacing.Value;
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;

		float totalMain = 0;
		int visibleCount = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			visibleCount++;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			totalMain += child.MeasuredSize.X + margin.TotalHorizontal;
		}
		if (visibleCount > 1)
			totalMain += spacing * (visibleCount - 1);

		float startOffset = 0;
		float gap = spacing;
		ComputeJustify(JustifyContent.Value, contentW, totalMain, visibleCount, ref startOffset, ref gap);

		var xPos = pad.Left + startOffset;
		bool first = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			if (!first) xPos += gap;
			first = false;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let flp = child.LayoutParams as FlexLayout.LayoutParams;
			let align = (flp?.AlignSelf != null) ? flp.AlignSelf.Value : AlignItems.Value;

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;
			let availCross = contentH - margin.TotalVertical;

			var yPos = pad.Top + margin.Top;
			var finalH = childH;

			switch (align)
			{
			case .Start:    yPos = pad.Top + margin.Top;
			case .End:      yPos = pad.Top + contentH - margin.Bottom - childH;
			case .Center:   yPos = pad.Top + margin.Top + (availCross - childH) * 0.5f;
			case .Stretch:  yPos = pad.Top + margin.Top; finalH = availCross;
			case .Baseline:
				let bl = child.GetBaseline();
				if (bl >= 0) yPos = pad.Top + margin.Top;
				else yPos = pad.Top + margin.Top;
			}

			child.Layout(xPos + margin.Left, yPos, childW, Math.Max(0, finalH));
			xPos += childW + margin.TotalHorizontal;
		}
	}

	private void LayoutVertical(float width, float height)
	{
		let pad = Padding.Value;
		let spacing = Spacing.Value;
		let contentW = width - pad.TotalHorizontal;
		let contentH = height - pad.TotalVertical;

		float totalMain = 0;
		int visibleCount = 0;
		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;
			visibleCount++;
			let margin = child.LayoutParams?.Margin ?? Thickness();
			totalMain += child.MeasuredSize.Y + margin.TotalVertical;
		}
		if (visibleCount > 1)
			totalMain += spacing * (visibleCount - 1);

		float startOffset = 0;
		float gap = spacing;
		ComputeJustify(JustifyContent.Value, contentH, totalMain, visibleCount, ref startOffset, ref gap);

		var yPos = pad.Top + startOffset;
		bool first = true;

		for (int i = 0; i < ChildCount; i++)
		{
			let child = GetChildAt(i);
			if (child.Visibility.Value == .Gone) continue;

			if (!first) yPos += gap;
			first = false;

			let margin = child.LayoutParams?.Margin ?? Thickness();
			let flp = child.LayoutParams as FlexLayout.LayoutParams;
			let align = (flp?.AlignSelf != null) ? flp.AlignSelf.Value : AlignItems.Value;

			let childW = child.MeasuredSize.X;
			let childH = child.MeasuredSize.Y;
			let availCross = contentW - margin.TotalHorizontal;

			var xPos = pad.Left + margin.Left;
			var finalW = childW;

			switch (align)
			{
			case .Start:    xPos = pad.Left + margin.Left;
			case .End:      xPos = pad.Left + contentW - margin.Right - childW;
			case .Center:   xPos = pad.Left + margin.Left + (availCross - childW) * 0.5f;
			case .Stretch:  xPos = pad.Left + margin.Left; finalW = availCross;
			case .Baseline: xPos = pad.Left + margin.Left;
			}

			child.Layout(xPos, yPos + margin.Top, Math.Max(0, finalW), childH);
			yPos += childH + margin.TotalVertical;
		}
	}

	private static void ComputeJustify(Justify justify, float containerSize, float totalChildSize,
		int childCount, ref float startOffset, ref float gap)
	{
		let freeSpace = Math.Max(0, containerSize - totalChildSize);

		switch (justify)
		{
		case .Start:
		case .End:
			startOffset = freeSpace;
		case .Center:
			startOffset = freeSpace * 0.5f;
		case .SpaceBetween:
			if (childCount > 1)
				gap += freeSpace / (childCount - 1);
		case .SpaceAround:
			if (childCount > 0)
			{
				let around = freeSpace / childCount;
				startOffset = around * 0.5f;
				gap += around;
			}
		case .SpaceEvenly:
			if (childCount > 0)
			{
				let even = freeSpace / (childCount + 1);
				startOffset = even;
				gap += even;
			}
		}
	}
}
