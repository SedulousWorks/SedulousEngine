using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// A filled rounded rectangle with an optional border, radii settable per corner, and a width
/// and colour per side when SideWidths or SideColors is set.
class RoundedRectDrawable : Drawable
{
	public Color FillColor = .();
	public Color BorderColor = Color.Transparent;
	public float BorderWidth = 0.0f;
	public CornerRadii Radii = .();
	/// A width per side, in place of BorderWidth (CSS's border-top-width and the rest).
	public BorderWidths? SideWidths;
	/// A colour per side, in place of BorderColor; where two sides meet, the corner splits
	/// between them as CSS draws it.
	public BorderColors? SideColors;

	/// The border's width on each side: SideWidths, or BorderWidth on all four.
	public BorderWidths Widths => SideWidths.HasValue ? SideWidths.Value : .(BorderWidth);
	/// The border's colour on each side: SideColors, or BorderColor on all four.
	public BorderColors Colors => SideColors.HasValue ? SideColors.Value : .(BorderColor);

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

	public override CornerRadii? OutlineRadii(ControlState state) => Radii;

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		if (SideWidths.HasValue || SideColors.HasValue)
		{
			// Sides that differ: VG's box draws them, analytically or tessellated.
			let colors = Colors;
			let bordered = !colors.IsTransparent && !Widths.IsZero;
			if ((FillColor.A > 0.0f) || bordered)
				ctx.VG.DrawBox(bounds, Radii, FillColor, bordered ? Widths : .(), colors);
			return;
		}
		if (ctx.VG.AnalyticBoxes)
		{
			// Fill and border as ONE box: one signed distance gives both, so they cannot
			// disagree at the corners, and the border lies inside the bounds (border box).
			let bordered = (BorderColor.A > 0.0f) && (BorderWidth > 0.0f);
			if ((FillColor.A > 0.0f) || bordered)
				ctx.VG.DrawBox(bounds, Radii, FillColor, .(bordered ? BorderWidth : 0.0f), BorderColor);
			return;
		}

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

	/// Border box: the border is chrome the content has to clear, side by side, so it counts as
	/// padding.
	public override Thickness DrawablePadding
	{
		get
		{
			let widths = Widths;
			return .(widths.Left, widths.Top, widths.Right, widths.Bottom);
		}
	}
}
