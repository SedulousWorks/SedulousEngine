using Sedulous.Core;

namespace Sedulous.UI;

/// Docks each child to an edge, every docked child claiming space from that edge and shrinking
/// what is left for the ones after it.
///
/// Order therefore MATTERS in a way it does not in a frame or a flex: a child docked left
/// before a child docked top takes the full height, and the same pair in the other order gives
/// the full width to the top one instead.
class DockLayout : ViewGroup
{
	/// Gives the last child everything that is left, whatever its own Dock says. The usual
	/// shape of a window: chrome docked to the edges, content filling the middle.
	public bool LastChildFill = false;

	public this() {}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let chrome = ResolveBoxMetrics().Chrome;
		var usedLeft = 0.0f;
		var usedTop = 0.0f;
		var usedRight = 0.0f;
		var usedBottom = 0.0f;
		var maxWidth = 0.0f;
		var maxHeight = 0.0f;
		let count = ChildCount;

		for (int i < count)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let dock = child.Layout.Dock;

			// The margin is handled by the base Measure, so what is passed is the remaining
			// space as the child's MARGIN box availability, and what is aggregated is margin
			// box sizes.
			let remainingWidth = Max(0.0f,
				constraints.MaxWidth - chrome.TotalHorizontal - usedLeft - usedRight);
			let remainingHeight = Max(0.0f,
				constraints.MaxHeight - chrome.TotalVertical - usedTop - usedBottom);

			let isFill = (LastChildFill && (i == count - 1)) || (dock == .Fill);
			child.Measure(isFill ? BoxConstraints.Tight(remainingWidth, remainingHeight)
				: BoxConstraints(0, remainingWidth, 0, remainingHeight));
			let marginBox = child.MarginBoxSize;

			switch (dock)
			{
			case .Left: usedLeft += marginBox.X;
			case .Right: usedRight += marginBox.X;
			case .Top: usedTop += marginBox.Y;
			case .Bottom: usedBottom += marginBox.Y;
			case .Fill: // A fill claims nothing: it takes what the others leave.
			}

			maxWidth = Max(maxWidth, usedLeft + usedRight);
			maxHeight = Max(maxHeight, usedTop + usedBottom);
		}

		// The CHROME was deflated above, padding and border both, so it is the chrome that
		// comes back. Adding only the padding measured a bordered dock short by its border.
		MeasuredSize = .(constraints.ConstrainWidth(maxWidth + chrome.TotalHorizontal),
			constraints.ConstrainHeight(maxHeight + chrome.TotalVertical));
	}

	protected override void OnLayout(float left, float top, float width, float height)
	{
		let chrome = ResolveBoxMetrics().Chrome;
		// The shrinking frame: each docked child takes a bite out of one side of it.
		var dockLeft = chrome.Left;
		var dockTop = chrome.Top;
		var dockRight = width - chrome.Right;
		var dockBottom = height - chrome.Bottom;
		let count = ChildCount;

		for (int i < count)
		{
			let child = GetChildAt(i);
			if (!IsInFlow(child))
				continue;

			let dock = child.Layout.Dock;
			let isFill = (LastChildFill && (i == count - 1)) || (dock == .Fill);

			// Every rectangle below is a MARGIN box: the base Layout insets by the margin once.
			let marginBox = child.MarginBoxSize;
			if (isFill)
			{
				child.Layout(dockLeft, dockTop, Max(0.0f, dockRight - dockLeft),
					Max(0.0f, dockBottom - dockTop));
				continue;
			}

			switch (dock)
			{
			case .Left:
				child.Layout(dockLeft, dockTop, marginBox.X, Max(0.0f, dockBottom - dockTop));
				dockLeft += marginBox.X;
			case .Right:
				child.Layout(dockRight - marginBox.X, dockTop, marginBox.X,
					Max(0.0f, dockBottom - dockTop));
				dockRight -= marginBox.X;
			case .Top:
				child.Layout(dockLeft, dockTop, Max(0.0f, dockRight - dockLeft), marginBox.Y);
				dockTop += marginBox.Y;
			case .Bottom:
				child.Layout(dockLeft, dockBottom - marginBox.Y,
					Max(0.0f, dockRight - dockLeft), marginBox.Y);
				dockBottom -= marginBox.Y;
			case .Fill: // Handled above.
			}
		}
	}
}
