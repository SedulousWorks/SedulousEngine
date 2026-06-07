namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Text display view with alignment, word wrap, and ellipsis support.
/// Uses TextAlignment and VerticalAlignment from the Fonts library.
public class Label : View
{
	public String Text ~ delete _;

	/// Horizontal text alignment.
	public TextAlignment HAlign = .Left;

	/// Vertical text alignment.
	public VerticalAlignment VAlign = .Middle;

	/// Whether text wraps at the view width.
	public bool WordWrap = false;

	/// Whether text is truncated with "..." when it exceeds width.
	public bool Ellipsis = false;

	/// Per-instance font size override. When set, overrides the style-resolved FontSize.
	public float? FontSize;

	/// Per-instance text color override. When set, overrides the style-resolved TextColor.
	public Color? TextColor;

	public this() { }
	public this(StringView text) { Text = new String(text); }

	/// Convenience: set text and return this for chaining.
	public Label SetText(StringView text)
	{
		if (Text == null)
			Text = new String(text);
		else
			Text.Set(text);
		Invalidate();
		return this;
	}

	private bool HasNewlines => Text != null && Text.Contains('\n');

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = (FontSize ?? ResolveStyleFloat(.FontSize, 16));
		float textW = 0, textH = fontSize;

		if (Text != null && Text.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				if (WordWrap && font.Shaper != null)
				{
					let maxWidth = (constraints.MaxWidth < float.MaxValue) ? constraints.MaxWidth : 10000.0f;
					textW = maxWidth;

					let positions = scope List<GlyphPosition>();
					float totalHeight = 0;
					if (font.Shaper.ShapeTextWrapped(font.Font, Text, maxWidth, positions, out totalHeight) case .Ok)
						textH = totalHeight;
				}
				else if (HasNewlines)
				{
					let lineHeight = font.Font.Metrics.LineHeight;
					float maxW = 0;
					int lineCount = 0;
					for (let line in Text.Split('\n'))
					{
						let w = font.Font.MeasureString(scope String(line));
						if (w > maxW) maxW = w;
						lineCount++;
					}
					textW = maxW;
					textH = lineHeight * lineCount;
				}
				else
				{
					textW = font.Font.MeasureString(Text);
					textH = font.Font.Metrics.LineHeight;
				}
			}
		}

		MeasuredSize = .(constraints.ConstrainWidth(textW), constraints.ConstrainHeight(textH));
	}

	public override float GetBaseline()
	{
		if (Context?.FontService != null)
		{
			let font = Context.FontService.GetFont((FontSize ?? ResolveStyleFloat(.FontSize, 16)));
			if (font != null)
				return font.Font.Metrics.Ascent;
		}
		return -1;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Text == null || Text.Length == 0) return;
		if (ctx.FontService == null) return;

		let fontSize = (FontSize ?? ResolveStyleFloat(.FontSize, 16));
		let font = ctx.FontService.GetFont(fontSize);
		if (font == null) return;

		var textColor = TextColor ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		if (!IsEffectivelyEnabled)
			textColor = Palette.ComputeDisabled(textColor);

		if (WordWrap)
		{
			float y = 0;
			if (VAlign != .Top && font.Shaper != null)
			{
				let positions = scope List<GlyphPosition>();
				float totalH = 0;
				if (font.Shaper.ShapeTextWrapped(font.Font, Text, Width, positions, out totalH) case .Ok)
				{
					if (VAlign == .Middle)
						y = (Height - totalH) * 0.5f;
					else if (VAlign == .Bottom)
						y = Height - totalH;
				}
			}
			ctx.VG.DrawTextWrapped(Text, font, .(0, y), Width, textColor, HAlign);
		}
		else if (HasNewlines)
		{
			let lineHeight = font.Font.Metrics.LineHeight;
			int lineCount = 0;
			for (let _ in Text.Split('\n'))
				lineCount++;

			let totalH = lineHeight * lineCount;
			float startY = 0;
			if (VAlign == .Middle) startY = (Height - totalH) * 0.5f;
			else if (VAlign == .Bottom) startY = Height - totalH;

			float yy = startY;
			for (let line in Text.Split('\n'))
			{
				let lineStr = scope String(line);
				ctx.VG.DrawText(lineStr, font, .(0, yy, Width, lineHeight), HAlign, .Top, textColor);
				yy += lineHeight;
			}
		}
		else if (Ellipsis)
		{
			let textW = font.Font.MeasureString(Text);
			if (textW <= Width)
			{
				ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), HAlign, VAlign, textColor);
			}
			else
			{
				let ellipsis = "...";
				let ellipsisW = font.Font.MeasureString(ellipsis);
				let availW = Width - ellipsisW;

				if (availW <= 0)
				{
					ctx.VG.DrawText(ellipsis, font, .(0, 0, Width, Height), HAlign, VAlign, textColor);
				}
				else
				{
					let truncated = scope String();
					float w = 0;
					for (let c in Text.RawChars)
					{
						let charStr = scope String();
						charStr.Append(c);
						let charW = font.Font.MeasureString(charStr);
						if (w + charW > availW) break;
						truncated.Append(c);
						w += charW;
					}
					truncated.Append(ellipsis);
					ctx.VG.DrawText(truncated, font, .(0, 0, Width, Height), HAlign, VAlign, textColor);
				}
			}
		}
		else
		{
			ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), HAlign, VAlign, textColor);
		}
	}
}
