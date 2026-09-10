using Sedulous.Core;

namespace Sedulous.UI;

/// A container that draws a themed background and STRETCHES every child across its content box.
///
/// The stretching is what separates it from a frame: a panel is a surface its children fill,
/// not a stack they are anchored in.
class Panel : ViewGroup
{
	public this() {}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (let background = ResolveStyleDrawable(.Background))
			background.Draw(ctx, .(0, 0, Width, Height), GetControlState());

		DrawChildren(ctx);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// The margin is handled by the base Measure: children get the LOOSE content box and are
		// aggregated by margin box size.
		let chrome = ResolveBoxMetrics().Chrome;
		let inner = constraints.Deflate(chrome).Loosen();
		var maxWidth = 0.0f;
		var maxHeight = 0.0f;

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			child.Measure(inner);
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
		let contentWidth = Max(0.0f, width - chrome.TotalHorizontal);
		let contentHeight = Max(0.0f, height - chrome.TotalVertical);

		for (int i < ChildCount)
		{
			let child = GetChildAt(i);
			if (child.Visibility == .Gone)
				continue;

			// The whole content box is handed over as the child's MARGIN box; the base Layout
			// insets by the margin once.
			child.Layout(chrome.Left, chrome.Top, contentWidth, contentHeight);
		}
	}
}
