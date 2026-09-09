using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// A filled rounded rectangle with an optional border, radii settable per corner.
class RoundedRectDrawable : Drawable
{
	public Color FillColor = .();
	public Color BorderColor = Color.Transparent;
	public float BorderWidth = 0.0f;
	public CornerRadii Radii = .();

	public this() {}

	/// One radius on every corner.
	public this(Color fill, float cornerRadius = 0.0f, Color borderColor = Color.Transparent,
		float borderWidth = 0.0f)
	{
		FillColor = fill;
		BorderColor = borderColor;
		BorderWidth = borderWidth;
		Radii = .(cornerRadius);
	}

	/// A radius per corner.
	public this(Color fill, CornerRadii radii, Color borderColor = Color.Transparent,
		float borderWidth = 0.0f)
	{
		FillColor = fill;
		BorderColor = borderColor;
		BorderWidth = borderWidth;
		Radii = radii;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		// The border stroke is INSET by half its width so the whole border lands INSIDE the
		// bounds, which is what border box painting means. A vector graphics stroke is centred
		// on its path, so leaving it un-inset would hang half the border outside the view,
		// where clipping would amputate it and a neighbour's border would overlap it.
		let inset = BorderWidth * 0.5f;
		let borderRect = Rectangle(bounds.X + inset, bounds.Y + inset,
			Max(0.0f, bounds.Width - BorderWidth), Max(0.0f, bounds.Height - BorderWidth));

		if (!Radii.IsZero)
		{
			if (FillColor.A > 0.0f)
				ctx.VG.FillRoundedRect(bounds, Radii, FillColor);

			if ((BorderColor.A > 0.0f) && (BorderWidth > 0.0f))
			{
				// The radii shrink with the inset, so the stroke stays concentric with the
				// fill rather than bulging at the corners.
				var radii = Radii;
				radii.TopLeft = Max(0.0f, radii.TopLeft - inset);
				radii.TopRight = Max(0.0f, radii.TopRight - inset);
				radii.BottomRight = Max(0.0f, radii.BottomRight - inset);
				radii.BottomLeft = Max(0.0f, radii.BottomLeft - inset);
				ctx.VG.StrokeRoundedRect(borderRect, radii, BorderColor, BorderWidth);
			}
			return;
		}

		if (FillColor.A > 0.0f)
			ctx.VG.FillRect(bounds, FillColor);
		if ((BorderColor.A > 0.0f) && (BorderWidth > 0.0f))
			ctx.VG.StrokeRect(borderRect, BorderColor, BorderWidth);
	}

	/// Border box: the border is chrome the content has to clear, so it counts as padding.
	public override Thickness DrawablePadding => .(BorderWidth, BorderWidth, BorderWidth,
		BorderWidth);
}
