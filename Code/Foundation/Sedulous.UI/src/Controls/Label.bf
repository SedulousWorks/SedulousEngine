namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Text label. Draws a single-line string using the font service.
public class Label : View
{
	public String Text ~ delete _;
	public Color TextColor = .(220, 220, 220, 255);
	public float FontSize = 16;
	public TextAlignment HAlign = .Left;
	public VerticalAlignment VAlign = .Middle;

	public void SetText(StringView text)
	{
		if (Text == null)
			Text = new String(text);
		else
			Text.Set(text);
		InvalidateLayout();
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float textW = 0, textH = FontSize;

		if (Text != null && Text.Length > 0)
		{
			if (Context?.FontService != null)
			{
				let font = Context.FontService.GetFont(FontSize);
				if (font != null)
				{
					textW = font.Font.MeasureString(Text);
					textH = font.Font.Metrics.LineHeight;
				}
			}
		}

		MeasuredSize = .(wSpec.Resolve(textW), hSpec.Resolve(textH));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Text == null || Text.Length == 0) return;
		if (ctx.FontService == null) return;

		let font = ctx.FontService.GetFont(FontSize);
		if (font == null) return;

		ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), HAlign, VAlign, TextColor);
	}
}
