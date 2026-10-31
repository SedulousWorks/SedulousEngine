using System;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.UI;

namespace Sedulous.UI.Toolkit;

/// The coloured letter in front of a vector component's number, used as a numeric field's
/// prefix view.
class AxisLabel : View
{
	private String mText = new .() ~ delete _;
	private Color mColor;

	public this(StringView text, Color color)
	{
		mText.Set(text);
		mColor = color;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (ctx.FontService == null)
			return;

		if (let font = ctx.FontService.GetFont(11.0f))
			ctx.VG.DrawText(mText, font, Rectangle(0, 0, Width, Height), .Center, .Middle, mColor);
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		// A single character, so the fallbacks are what one glyph costs rather than a guess at
		// a whole string.
		var width = 12.0f;
		var height = 14.0f;

		if ((Context != null) && (Context.FontService != null))
		{
			if (let font = Context.FontService.GetFont(11.0f))
			{
				width = font.Font.MeasureString(mText);
				height = font.Font.Metrics.LineHeight;
			}
		}

		MeasuredSize = .(constraints.ConstrainWidth(width), constraints.ConstrainHeight(height));
	}
}
