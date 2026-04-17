namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Filled rounded rectangle with optional border.
public class RoundedRectDrawable : Drawable
{
	public Color FillColor;
	public Color BorderColor;
	public float BorderWidth;
	public float CornerRadius;

	public this(Color fill, float cornerRadius = 0, Color borderColor = .Transparent, float borderWidth = 0)
	{
		FillColor = fill;
		CornerRadius = cornerRadius;
		BorderColor = borderColor;
		BorderWidth = borderWidth;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (CornerRadius > 0)
		{
			if (FillColor.A > 0)
				ctx.VG.FillRoundedRect(bounds, CornerRadius, FillColor);
			if (BorderColor.A > 0 && BorderWidth > 0)
				ctx.VG.StrokeRoundedRect(bounds, CornerRadius, BorderColor, BorderWidth);
		}
		else
		{
			if (FillColor.A > 0)
				ctx.VG.FillRect(bounds, FillColor);
			if (BorderColor.A > 0 && BorderWidth > 0)
				ctx.VG.StrokeRect(bounds, BorderColor, BorderWidth);
		}
	}
}
