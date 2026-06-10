namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Text button - the most common button type.
/// Has a Text property for direct text access. No child view overhead.
public class Button : ButtonBase
{
	/// The button text.
	public Property<String> Text = new .(null) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Per-instance font size override. When set, overrides the style-resolved FontSize.
	public Property<float?> FontSize = new .(null) ~ delete _;

	/// Per-instance font family override. When set (and non-empty), overrides the style-resolved FontFamily.
	public Property<String> FontFamily = new .(null, .Visual) ~ { if (_.Value != null) delete _.Value; delete _; };

	/// Text button constructor.
	public this(StringView text) : base()
	{
		Text.SetOwner(this);
		FontSize.SetOwner(this);
		FontFamily.SetOwner(this, .Visual);

		Text.SetSilent(new String(text));
	}

	/// Set the button text.
	public void SetText(StringView text)
	{
		if (Text.Value == null)
			Text.Value = new String(text);
		else
			Text.Value.Set(text);
		Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let inner = constraints.Deflate(pad).Loosen();

		float textW = 0, textH = 0;
		let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);

		if (Text.Value != null && Text.Value.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text.Value);
				textH = font.Font.Metrics.LineHeight;
			}
		}
		else
			textH = fontSize;

		MeasuredSize = .(
			constraints.ConstrainWidth(Math.Min(textW, inner.MaxWidth) + pad.TotalHorizontal),
			constraints.ConstrainHeight(Math.Min(textH, inner.MaxHeight) + pad.TotalVertical));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();

		DrawButtonBackground(ctx, bounds, state);

		// Draw text
		if (Text.Value != null && Text.Value.Length > 0 && ctx.FontService != null)
		{
			let fontSize = FontSize.Value ?? ResolveStyleFloat(.FontSize, 16);
			let font = ctx.FontService.GetFont(ResolveStyleFontFamily(FontFamily.Value), fontSize);
			if (font != null)
			{
				let pad = ResolveStyleThickness(.Padding, .(12, 8));
				var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (state.HasFlag(.Disabled))
					textColor = Palette.ComputeDisabled(textColor);

				let textRect = RectangleF(pad.Left, pad.Top,
					Width - pad.TotalHorizontal, Height - pad.TotalVertical);
				ctx.VG.DrawText(Text.Value, font, textRect, .Center, .Middle, textColor);
			}
		}
	}
}
