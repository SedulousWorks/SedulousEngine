namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Text label. Uses theme for defaults; per-instance overrides take priority.
public class Label : View
{
	public String Text ~ delete _;
	public TextAlignment HAlign = .Left;
	public VerticalAlignment VAlign = .Middle;

	// Nullable per-instance overrides - null = use theme.
	private Color? mTextColor;
	private float? mFontSize;

	public Color TextColor
	{
		get
		{
			if (mTextColor.HasValue) return mTextColor.Value;
			let theme = Context?.Theme;
			if (theme == null) return .(220, 225, 235, 255);
			// Try StyleId-specific key first, then fall back to Label default.
			if (StyleId != null && theme.HasKey(scope $"{StyleId}.Foreground"))
				return theme.GetColor(scope $"{StyleId}.Foreground");
			return theme.GetColor("Label.Foreground", .(220, 225, 235, 255));
		}
		set => mTextColor = value;
	}

	public float FontSize
	{
		get => mFontSize ?? Context?.Theme?.GetDimension("Label.FontSize", 16) ?? 16;
		set { mFontSize = value; InvalidateLayout(); }
	}

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
		let fontSize = FontSize;
		float textW = 0, textH = fontSize;

		if (Text != null && Text.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		MeasuredSize = .(wSpec.Resolve(textW), hSpec.Resolve(textH));
	}

	public override float GetBaseline()
	{
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(FontSize);
			if (font != null)
				return font.Font.Metrics.Ascent;
		}
		return -1;
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
