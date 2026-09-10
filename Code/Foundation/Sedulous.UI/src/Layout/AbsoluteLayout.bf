using Sedulous.Core;

namespace Sedulous.UI;

/// Places every child at an explicit offset, taken from its Left and Top.
///
/// Distinct from the `position: absolute` children the BASE group already places: those are
/// out of flow inside an ordinary container, where here the offset IS the layout and every
/// child is placed that way.
class AbsoluteLayout : ViewGroup
{
	public this() {}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		var maxRight = 0.0f;
		var maxBottom = 0.0f;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			// A Wrap child measures UNBOUNDED: absolute placement gives it no natural box to
			// shrink against, so it takes the size it wants and the group grows to reach it.
			// Match still fills the content area.
			let availableWidth = Max(0.0f, constraints.MaxWidth - Padding.TotalHorizontal);
			let availableHeight = Max(0.0f, constraints.MaxHeight - Padding.TotalVertical);
			let layout = child.Layout;
			let fillWidth = layout.Width.Value.kind == .Match;
			let fillHeight = layout.Height.Value.kind == .Match;
			child.Measure(.(fillWidth ? availableWidth : 0.0f,
				fillWidth ? availableWidth : FloatMax,
				fillHeight ? availableHeight : 0.0f,
				fillHeight ? availableHeight : FloatMax));

			let marginBox = child.MarginBoxSize;
			maxRight = Max(maxRight, layout.Left.Value + marginBox.X);
			maxBottom = Max(maxBottom, layout.Top.Value + marginBox.Y);
		}

		MeasuredSize = .(constraints.ConstrainWidth(maxRight + Padding.TotalHorizontal),
			constraints.ConstrainHeight(maxBottom + Padding.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let layout = child.Layout;
			let offsetX = layout.Left.Value;
			let offsetY = layout.Top.Value;

			// Margin box rectangles: the base Layout insets by the margin itself.
			let marginBox = child.MarginBoxSize;
			var childWidth = marginBox.X;
			var childHeight = marginBox.Y;
			// A Match child fills what is LEFT from its offset, not the whole content box: it
			// starts where it was placed and runs to the far edge.
			if (layout.Width.Value.kind == .Match)
				childWidth = Max(0.0f, width - Padding.TotalHorizontal - offsetX);
			if (layout.Height.Value.kind == .Match)
				childHeight = Max(0.0f, height - Padding.TotalVertical - offsetY);

			child.Layout(Padding.Left + offsetX, Padding.Top + offsetY, childWidth, childHeight);
		}
	}
}
