using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The chip that follows the cursor while a panel is being dragged: its title, with an accent
/// underline that reads as "a tab in flight".
///
/// COMPACT on purpose. The drop OUTCOME is shown by the zone indicator's preview wash, so this
/// only has to say what is being dragged. An earlier version drew a small mock window, which
/// read as a stray icon rather than as the panel it represented.
class DockDragPreview : View
{
	private const float PreviewWidth = 160.0f;
	private const float PreviewHeight = 26.0f;

	private String mTitle = new .() ~ delete _;

	public void SetTitle(StringView title) => mTitle.Set(title);

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let borderColor = ResolveStyleColor(.BorderColor, Color.Rgb(65, 70, 85));
		let accent = ResolveStyleColor(.AccentColor, Color.Rgb(80, 150, 240));

		ctx.VG.FillRoundedRect(bounds, 4, ResolveStyleColor(.Background, Color.Rgb(42, 44, 54)));
		ctx.VG.FillRect(.(2, Height - 2, Width - 4, 2), .(accent.R, accent.G, accent.B, 0.9f));

		if (ctx.FontService != null)
		{
			if (let font = ctx.FontService.GetFont(11.0f))
				ctx.VG.DrawText(mTitle, font, .(10, 0, Width - 20, Height), .Left, .Middle,
					ResolveStyleColor(.TextColor, Color.Rgb(220, 225, 235)));
		}

		ctx.VG.StrokeRoundedRect(bounds, 4, borderColor, 1);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		MeasuredSize = .(constraints.ConstrainWidth(PreviewWidth),
			constraints.ConstrainHeight(PreviewHeight));
	}
}
