using Sedulous.Core;

namespace Sedulous.UI;

/// Stacks its children on top of one another, each anchored independently by its own Gravity.
///
/// The simplest container there is, and the shape the base ViewGroup's default measure already
/// takes: what FrameLayout adds is the gravity, which is what turns a stack into an anchored
/// one.
class FrameLayout : ViewGroup
{
	public this() {}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// A fixed size and the margin are handled by the base Measure, leaving the parent only
		// the loose against fill decision. The chrome is the MERGED metrics, so a stylesheet's
		// padding and borders count here as well as the group's own field.
		let chrome = ResolveBoxMetrics().Chrome;
		let inner = constraints.Deflate(chrome);
		var maxWidth = 0.0f;
		var maxHeight = 0.0f;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			child.Measure(AvailForChild(inner.MaxWidth, inner.MaxHeight, child));
			let marginBox = child.MarginBoxSize;
			maxWidth = Max(maxWidth, marginBox.X);
			maxHeight = Max(maxHeight, marginBox.Y);
		}

		MeasuredSize = .(constraints.ConstrainWidth(maxWidth + chrome.TotalHorizontal),
			constraints.ConstrainHeight(maxHeight + chrome.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let chrome = ResolveBoxMetrics().Chrome;
		let contentWidth = width - chrome.TotalHorizontal;
		let contentHeight = height - chrome.TotalVertical;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			// Gravity positions the MARGIN box; the base Layout then insets to the border box,
			// so a gravity and a margin compose rather than fight.
			let marginBox = child.MarginBoxSize;
			var rect = GravityHelper.Apply(child.Layout.Gravity, contentWidth, contentHeight,
				marginBox.X, marginBox.Y);
			rect.X += chrome.Left;
			rect.Y += chrome.Top;
			child.Layout(rect.X, rect.Y, rect.Width, rect.Height);
		}
	}
}
