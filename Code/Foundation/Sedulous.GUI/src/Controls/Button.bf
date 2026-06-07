namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;

/// Text button - the most common button type.
/// Has a Text property for direct text access. No child view overhead.
public class Button : ButtonBase
{
	private String mText ~ delete _;

	/// The button text.
	public String Text
	{
		get => mText;
	}

	/// Per-instance font size override. When set, overrides the style-resolved FontSize.
	public float? FontSize;

	/// Text button constructor.
	public this(StringView text) : base()
	{
		mText = new String(text);
	}

	/// Set the button text.
	public void SetText(StringView text)
	{
		if (mText == null)
			mText = new String(text);
		else
			mText.Set(text);
		Invalidate();
	}

	protected override void OnMeasure(BoxConstraints constraints)
	{
		let pad = ResolveStyleThickness(.Padding, .(12, 8));
		let inner = constraints.Deflate(pad).Loosen();

		float textW = 0, textH = 0;
		let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);

		if (mText != null && mText.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(fontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(mText);
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
		if (mText != null && mText.Length > 0 && ctx.FontService != null)
		{
			let fontSize = FontSize ?? ResolveStyleFloat(.FontSize, 16);
			let font = ctx.FontService.GetFont(fontSize);
			if (font != null)
			{
				let pad = ResolveStyleThickness(.Padding, .(12, 8));
				var textColor = ResolveStyleColor(.TextColor, .(220, 225, 235, 255));
				if (state == .Disabled)
					textColor = Palette.ComputeDisabled(textColor);

				let textRect = RectangleF(pad.Left, pad.Top,
					Width - pad.TotalHorizontal, Height - pad.TotalVertical);
				ctx.VG.DrawText(mText, font, textRect, .Center, .Middle, textColor);
			}
		}
	}
}
