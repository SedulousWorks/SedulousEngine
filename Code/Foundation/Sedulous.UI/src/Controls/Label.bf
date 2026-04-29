namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;
using System.Collections;

/// Text label. Uses theme for defaults; per-instance overrides take priority.
/// Supports optional word wrapping via the WordWrap property.
/// Handles explicit \n line breaks in both wrapped and non-wrapped modes.
public class Label : View
{
	public String Text ~ delete _;
	public TextAlignment HAlign = .Left;
	public VerticalAlignment VAlign = .Middle;

	/// When true, text wraps at the view's width boundary.
	public bool WordWrap = false;

	/// When true, text that exceeds the view's width is truncated with "...".
	public bool Ellipsis = false;

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

	private bool HasNewlines => Text != null && Text.Contains('\n');

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let fontSize = FontSize;
		float textW = 0, textH = fontSize;

		if (Text != null && Text.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				if (WordWrap && font.Shaper != null)
				{
					let maxWidth = wSpec.Mode == .Exactly ? wSpec.Size : (wSpec.Mode == .AtMost ? wSpec.Size : 10000.0f);
					textW = maxWidth;

					let positions = scope List<GlyphPosition>();
					float totalHeight = 0;
					if (font.Shaper.ShapeTextWrapped(font.Font, Text, maxWidth, positions, out totalHeight) case .Ok)
						textH = totalHeight;
				}
				else if (HasNewlines)
				{
					// Measure each line, take max width and sum heights
					let lineHeight = font.Font.Metrics.LineHeight;
					float maxW = 0;
					int lineCount = 0;
					for (let line in Text.Split('\n'))
					{
						let w = font.Font.MeasureString(line);
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
			ctx.VG.DrawTextWrapped(Text, font, .(0, y), Width, TextColor, HAlign);
		}
		else if (HasNewlines)
		{
			// Draw each line with alignment
			let lineHeight = font.Font.Metrics.LineHeight;
			int lineCount = 0;
			for (let _ in Text.Split('\n'))
				lineCount++;

			let totalH = lineHeight * lineCount;
			float startY = 0;
			if (VAlign == .Middle)
				startY = (Height - totalH) * 0.5f;
			else if (VAlign == .Bottom)
				startY = Height - totalH;

			float y = startY;
			for (let line in Text.Split('\n'))
			{
				let lineStr = scope String(line);
				ctx.VG.DrawText(lineStr, font, .(0, y, Width, lineHeight), HAlign, .Top, TextColor);
				y += lineHeight;
			}
		}
		else if (Ellipsis)
		{
			// Measure text and truncate with "..." if it exceeds the view width
			let textW = font.Font.MeasureString(Text);
			if (textW <= Width)
			{
				ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), HAlign, VAlign, TextColor);
			}
			else
			{
				let ellipsis = "...";
				let ellipsisW = font.Font.MeasureString(ellipsis);
				let availW = Width - ellipsisW;

				if (availW <= 0)
				{
					ctx.VG.DrawText(ellipsis, font, .(0, 0, Width, Height), HAlign, VAlign, TextColor);
				}
				else
				{
					// Find how many characters fit within availW
					let truncated = scope String();
					float w = 0;
					for (let c in Text.RawChars)
					{
						let charStr = scope String();
						charStr.Append(c);
						let charW = font.Font.MeasureString(charStr);
						if (w + charW > availW)
							break;
						truncated.Append(c);
						w += charW;
					}
					truncated.Append(ellipsis);
					ctx.VG.DrawText(truncated, font, .(0, 0, Width, Height), HAlign, VAlign, TextColor);
				}
			}
		}
		else
		{
			ctx.VG.DrawText(Text, font, .(0, 0, Width, Height), HAlign, VAlign, TextColor);
		}
	}
}
