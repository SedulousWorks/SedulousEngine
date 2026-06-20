namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.VG;

/// Filled rounded rectangle with optional border.
/// Supports per-corner radii via CornerRadii.
public class RoundedRectDrawable : Drawable
{
	public Color32 FillColor;
	public Color32 BorderColor;
	public float BorderWidth;
	public CornerRadii Radii;

	/// Uniform corner radius.
	public this(Color32 fill, float cornerRadius = 0, Color32 borderColor = .Transparent, float borderWidth = 0)
	{
		FillColor = fill;
		Radii = .(cornerRadius);
		BorderColor = borderColor;
		BorderWidth = borderWidth;
	}

	/// Per-corner radii.
	public this(Color32 fill, CornerRadii radii, Color32 borderColor = .Transparent, float borderWidth = 0)
	{
		FillColor = fill;
		Radii = radii;
		BorderColor = borderColor;
		BorderWidth = borderWidth;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		if (!Radii.IsZero)
		{
			if (FillColor.A > 0)
				ctx.VG.FillRoundedRect(bounds, Radii, FillColor);
			if (BorderColor.A > 0 && BorderWidth > 0)
				ctx.VG.StrokeRoundedRect(bounds, Radii, BorderColor, BorderWidth);
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
