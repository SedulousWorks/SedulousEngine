namespace Sedulous.UI;

using System;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.VG;

/// Button with a background drawable and a text label.
/// No click handler yet (Phase 3 wires input). ControlState is computed
/// from flags for drawable state selection.
public class Button : View
{
	public String Text ~ delete _;
	public Color TextColor = .(240, 240, 240, 255);
	public float FontSize = 16;
	public Drawable Background ~ delete _;
	public Thickness Padding = .(12, 8);

	// Visual state flags (set by InputManager in Phase 3).
	public bool IsHovered;
	public bool IsPressed;

	public this()
	{
		IsFocusable = true;
	}

	public void SetText(StringView text)
	{
		if (Text == null)
			Text = new String(text);
		else
			Text.Set(text);
		InvalidateLayout();
	}

	public ControlState GetControlState()
	{
		if (!IsEffectivelyEnabled) return .Disabled;
		if (IsPressed) return .Pressed;
		if (IsHovered) return .Hover;
		return .Normal;
	}

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		float textW = 0, textH = FontSize;

		if (Text != null && Text.Length > 0 && Context?.FontService != null)
		{
			let font = Context.FontService.GetFont(FontSize);
			if (font != null)
			{
				textW = font.Font.MeasureString(Text);
				textH = font.Font.Metrics.LineHeight;
			}
		}

		let w = textW + Padding.TotalHorizontal;
		let h = textH + Padding.TotalVertical;
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let bounds = RectangleF(0, 0, Width, Height);
		let state = GetControlState();

		// Draw background
		if (Background != null)
			Background.Draw(ctx, bounds, state);

		// Draw label
		if (Text != null && Text.Length > 0 && ctx.FontService != null)
		{
			let font = ctx.FontService.GetFont(FontSize);
			if (font != null)
			{
				let contentBounds = RectangleF(
					Padding.Left, Padding.Top,
					Width - Padding.TotalHorizontal,
					Height - Padding.TotalVertical);
				ctx.VG.DrawText(Text, font, contentBounds, .Center, .Middle, TextColor);
			}
		}
	}
}
