using System;
using Sedulous.Core;
using Sedulous.Fonts;

namespace Sedulous.UI;

/// A push button with a text label.
class Button : ButtonBase
{
	public Property<String> Text = new .() ~ delete _;
	/// Null defers to the cascade's font size.
	public Property<float?> FontSize = new .() ~ delete _;
	/// Empty defers to the cascade's family.
	public Property<String> FontFamily = new .() ~ delete _;

	public this(StringView text)
	{
		Text.SetOwner(this);
		FontSize.SetOwner(this);
		// VISUAL: changing the family redraws the text but cannot move anything.
		FontFamily.SetOwner(this, .Visual);
		Text.SetSilent(new String(text));
	}

	public ~this()
	{
		delete Text.Value;
		delete FontFamily.Value;
	}

	public void SetText(StringView text)
	{
		let replacement = new String(text);
		let previous = Text.Value;
		Text.Value = replacement;
		if (previous != replacement)
			delete previous;
		Invalidate();
	}

	/// A button's own padding when no sheet declares one, so it is comfortable untheme d.
	protected override Thickness DefaultStylePadding() => .(12.0f, 8.0f);

	/// CONTENT only: the base Measure handles the chrome, so the padding is neither deflated
	/// nor added back here.
	protected override Float2 OnMeasureContent(BoxConstraints contentConstraints)
	{
		let fontSize = EffectiveFontSize;

		var textWidth = 0.0f;
		var textHeight = 0.0f;
		let text = Text.Value;

		if (!text.IsEmpty && (Context != null) && (Context.FontService != null))
		{
			let family = scope String();
			ResolveStyleFontFamily(family, FontFamily.Value);
			if (let font = Context.FontService.GetFont(family, fontSize))
			{
				textWidth = font.Font.MeasureString(text);
				textHeight = font.Font.Metrics.LineHeight;
			}
		}
		else
		{
			// No font service, in a headless run or a test: the font size is the best estimate
			// of the height, and nothing is measured for the width.
			textHeight = fontSize;
		}

		return .(Min(textWidth, contentConstraints.MaxWidth),
			Min(textHeight, contentConstraints.MaxHeight));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = Rectangle(0, 0, Width, Height);
		let state = GetControlState();
		DrawButtonBackground(ctx, bounds, state);

		let text = Text.Value;
		if (text.IsEmpty || (ctx.FontService == null))
			return;

		let family = scope String();
		ResolveStyleFontFamily(family, FontFamily.Value);
		let font = ctx.FontService.GetFont(family, EffectiveFontSize);
		if (font == null)
			return;

		// The SAME chrome the base deflated at measure, so the text stays clear of a themed
		// border rather than sitting on it.
		let chrome = ResolveBoxMetrics().Chrome;
		var textColor = ResolveStyleColor(.TextColor,
			Color(220 / 255.0f, 225 / 255.0f, 235 / 255.0f, 1.0f));
		if (state.HasFlag(.Disabled))
			textColor = Palette.ComputeDisabled(textColor);

		let textRect = Rectangle(chrome.Left, chrome.Top, Width - chrome.TotalHorizontal,
			Height - chrome.TotalVertical);

		// Ellipsised when it does not fit, which a button shrunk by its layout will be.
		let shown = scope String();
		TruncateToWidth(font.Font, text, textRect.Width, shown);
		ctx.VG.DrawText(shown, font, textRect, .Center, .Middle, textColor);
	}

	private float EffectiveFontSize =>
		(FontSize.Value != null) ? FontSize.Value.Value : ResolveStyleFloat(.FontSize, 16.0f);
}
