namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Text display view with alignment, word wrap, and ellipsis support.
/// Uses TextAlignment and VerticalAlignment from the Fonts library.
public class Label : View
{
	public Property<String> Text = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Horizontal text alignment.
	public Property<TextAlignment> HAlign = new .(.Left) ~ delete _;

	/// Vertical text alignment.
	public Property<VerticalAlignment> VAlign = new .(.Middle) ~ delete _;

	/// Whether text wraps at the view width.
	public Property<bool> WordWrap = new .(false) ~ delete _;

	/// Whether text is truncated with "..." when it exceeds width.
	public Property<bool> Ellipsis = new .(false) ~ delete _;

	/// Per-instance font size override. When set, overrides the style-resolved FontSize.
	public Property<float?> FontSize = new .(null, .Visual) ~ delete _;

	/// Per-instance font family override. When set (and non-empty),
	/// overrides the style-resolved FontFamily. Owned by this view.
	public Property<String> FontFamily = new .(null, .Visual) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Per-instance text color override. When set, overrides the style-resolved TextColor.
	public Property<Color32?> TextColor = new .(null, .Visual) ~ delete _;

	public this()
	{
		Text.SetOwner(this);
		HAlign.SetOwner(this, .Visual);
		VAlign.SetOwner(this, .Visual);
		WordWrap.SetOwner(this);
		Ellipsis.SetOwner(this, .Visual);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);
		TextColor.SetOwner(this, .Visual);
	}

	public this(StringView text) : this()
	{
		Text.SetSilent(new String(text));
	}

	/// Convenience: set text and return this for chaining.
	public Label SetText(StringView text)
	{
		if (Text.Value == null)
			Text.Value = new String(text);
		else
			Text.Value.Set(text);
		Invalidate();
		return this;
	}

	private bool HasNewlines => Text.Value != null && Text.Value.Contains('\n');

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let fontSize = (FontSize.Value ?? ResolveStyleFloat(.FontSize, 16));
		float textW = 0, textH = fontSize;

		if (Text.Value != null && Text.Value.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
			if (font != null)
			{
				if (WordWrap.Value && font.Shaper != null)
				{
					let maxWidth = (constraints.MaxWidth < float.MaxValue) ? constraints.MaxWidth : 10000.0f;
					textW = maxWidth;

					let positions = scope List<GlyphPosition>();
					float totalHeight = 0;
					if (font.Shaper.ShapeTextWrapped(font.Font, Text.Value, maxWidth, positions, out totalHeight) case .Ok)
						textH = totalHeight;
				}
				else if (HasNewlines)
				{
					let lineHeight = font.Font.Metrics.LineHeight;
					float maxW = 0;
					int lineCount = 0;
					for (let line in Text.Value.Split('\n'))
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
					textW = font.Font.MeasureString(Text.Value);
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
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), FontSize.Value ?? ResolveStyleFloat(.FontSize, 16));
			if (font != null)
				return font.Font.Metrics.Ascent;
		}
		return -1;
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (Text.Value == null || Text.Value.Length == 0) return;
		if (ctx.FontService == null) return;

		let fontSize = (FontSize.Value ?? ResolveStyleFloat(.FontSize, 16));
		let font = ctx.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
		if (font == null) return;

		var textColor = TextColor.Value ?? ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
		if (!IsEffectivelyEnabled)
			textColor = Palette.ComputeDisabled(textColor);

		if (WordWrap.Value)
		{
			float y = 0;
			if (VAlign.Value != .Top && font.Shaper != null)
			{
				let positions = scope List<GlyphPosition>();
				float totalH = 0;
				if (font.Shaper.ShapeTextWrapped(font.Font, Text.Value, Width, positions, out totalH) case .Ok)
				{
					if (VAlign.Value == .Middle)
						y = (Height - totalH) * 0.5f;
					else if (VAlign.Value == .Bottom)
						y = Height - totalH;
				}
			}
			ctx.VG.DrawTextWrapped(Text.Value, font, .(0, y), Width, textColor, HAlign.Value);
		}
		else if (HasNewlines)
		{
			let lineHeight = font.Font.Metrics.LineHeight;
			int lineCount = 0;
			for (let _ in Text.Value.Split('\n'))
				lineCount++;

			let totalH = lineHeight * lineCount;
			float startY = 0;
			if (VAlign.Value == .Middle) startY = (Height - totalH) * 0.5f;
			else if (VAlign.Value == .Bottom) startY = Height - totalH;

			float yy = startY;
			for (let line in Text.Value.Split('\n'))
			{
				let lineStr = scope String(line);
				ctx.VG.DrawText(lineStr, font, .(0, yy, Width, lineHeight), HAlign.Value, .Top, textColor);
				yy += lineHeight;
			}
		}
		else if (Ellipsis.Value)
		{
			let textW = font.Font.MeasureString(Text.Value);
			if (textW <= Width)
			{
				ctx.VG.DrawText(Text.Value, font, .(0, 0, Width, Height), HAlign.Value, VAlign.Value, textColor);
			}
			else
			{
				let ellipsis = "...";
				let ellipsisW = font.Font.MeasureString(ellipsis);
				let availW = Width - ellipsisW;

				if (availW <= 0)
				{
					ctx.VG.DrawText(ellipsis, font, .(0, 0, Width, Height), HAlign.Value, VAlign.Value, textColor);
				}
				else
				{
					let truncated = scope String();
					float w = 0;
					for (let c in Text.Value.RawChars)
					{
						let charStr = scope String();
						charStr.Append(c);
						let charW = font.Font.MeasureString(charStr);
						if (w + charW > availW) break;
						truncated.Append(c);
						w += charW;
					}
					truncated.Append(ellipsis);
					ctx.VG.DrawText(truncated, font, .(0, 0, Width, Height), HAlign.Value, VAlign.Value, textColor);
				}
			}
		}
		else
		{
			ctx.VG.DrawText(Text.Value, font, .(0, 0, Width, Height), HAlign.Value, VAlign.Value, textColor);
		}
	}
}
