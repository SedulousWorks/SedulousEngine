using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// A vertical rule between groups of toolbar items.
class ToolbarSeparator : ToolbarItem
{
	public override void OnDraw(UIDrawContext ctx)
	{
		let color = ResolveStyleColor(.BorderColor, Color.Rgb(80, 85, 100));
		let centerX = Width * 0.5f;
		// Inset a fifth at each end, so the rule reads as a divider between items rather than
		// a full height edge of the bar itself.
		let margin = Height * 0.2f;
		ctx.VG.FillRect(Rectangle(centerX, margin, 1.0f, Height - (margin * 2.0f)), color);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(8.0f), constraints.ConstrainHeight(0.0f));
	}
}
