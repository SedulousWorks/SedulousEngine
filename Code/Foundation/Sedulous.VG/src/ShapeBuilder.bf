using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// Common shapes, emitted into a path builder.
static class ShapeBuilder
{
	/// The control point offset that makes a cubic match a QUARTER circle. There is no
	/// exact cubic for a circular arc; this is the value that minimises the error.
	private const float cQuarterArcK = 0.5522847498f;

	/// A rounded rectangle, clockwise from just past the top left corner.
	///
	/// Each radius is CLAMPED to half the smaller side. Two radii that together exceed a
	/// side would otherwise cross, producing a shape that folds through itself.
	public static void BuildRoundedRect(Rectangle rect, CornerRadii radii, PathBuilder builder)
	{
		let maxRadius = Min(rect.Width, rect.Height) * 0.5f;
		let topLeft = Min(radii.TopLeft, maxRadius);
		let topRight = Min(radii.TopRight, maxRadius);
		let bottomRight = Min(radii.BottomRight, maxRadius);
		let bottomLeft = Min(radii.BottomLeft, maxRadius);

		let x = rect.X;
		let y = rect.Y;
		let w = rect.Width;
		let h = rect.Height;

		builder.MoveTo(x + topLeft, y);

		builder.LineTo(x + w - topRight, y);
		if (topRight > 0.0f)
			ArcCorner(builder, x + w - topRight, y + topRight, topRight, -HalfPi, 0.0f);

		builder.LineTo(x + w, y + h - bottomRight);
		if (bottomRight > 0.0f)
			ArcCorner(builder, x + w - bottomRight, y + h - bottomRight, bottomRight, 0.0f, HalfPi);

		builder.LineTo(x + bottomLeft, y + h);
		if (bottomLeft > 0.0f)
			ArcCorner(builder, x + bottomLeft, y + h - bottomLeft, bottomLeft, HalfPi, Pi);

		builder.LineTo(x, y + topLeft);
		if (topLeft > 0.0f)
			ArcCorner(builder, x + topLeft, y + topLeft, topLeft, Pi, Pi * 1.5f);

		builder.Close();
	}

	public static void BuildCircle(Float2 center, float radius, PathBuilder builder)
		=> BuildEllipse(center, radius, radius, builder);

	/// Four cubics, one per quadrant.
	public static void BuildEllipse(Float2 center, float rx, float ry, PathBuilder builder)
	{
		let kx = rx * cQuarterArcK;
		let ky = ry * cQuarterArcK;
		let cx = center.X;
		let cy = center.Y;

		builder.MoveTo(cx + rx, cy);
		builder.CubicTo(cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry);
		builder.CubicTo(cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy);
		builder.CubicTo(cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry);
		builder.CubicTo(cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy);
		builder.Close();
	}

	/// A regular polygon, starting at the TOP: an even sided one then rests on a flat
	/// side, which is what people expect of a hexagon.
	///
	/// Fewer than three sides is not a polygon, and emits nothing rather than a degenerate
	/// shape the tessellator would have to reject later.
	public static void BuildRegularPolygon(Float2 center, float radius, int32 sides,
		PathBuilder builder)
	{
		if (sides < 3)
			return;

		let angleStep = TwoPi / (float)sides;
		let startAngle = -HalfPi;

		for (int32 i = 0; i < sides; i++)
		{
			let angle = startAngle + (angleStep * (float)i);
			let x = center.X + (Cos(angle) * radius);
			let y = center.Y + (Sin(angle) * radius);

			if (i == 0)
				builder.MoveTo(x, y);
			else
				builder.LineTo(x, y);
		}

		builder.Close();
	}

	/// A star: twice as many vertices as points, alternating between the two radii.
	public static void BuildStar(Float2 center, float outerRadius, float innerRadius,
		int32 points, PathBuilder builder)
	{
		if (points < 3)
			return;

		let totalPoints = points * 2;
		let angleStep = TwoPi / (float)totalPoints;
		let startAngle = -HalfPi;

		for (int32 i = 0; i < totalPoints; i++)
		{
			let angle = startAngle + (angleStep * (float)i);
			let radius = ((i % 2) == 0) ? outerRadius : innerRadius;
			let x = center.X + (Cos(angle) * radius);
			let y = center.Y + (Sin(angle) * radius);

			if (i == 0)
				builder.MoveTo(x, y);
			else
				builder.LineTo(x, y);
		}

		builder.Close();
	}

	/// One corner arc as a cubic. The same construction the arc converter uses, kept here
	/// rather than routed through it because a corner is always a quarter turn and needs
	/// none of the endpoint parameterisation.
	private static void ArcCorner(PathBuilder builder, float cx, float cy, float radius,
		float startAngle, float endAngle)
	{
		let sweep = endAngle - startAngle;
		let half = sweep * 0.5f;
		let alpha = Sin(sweep) * (Sqrt(4.0f + (3.0f * Tan(half) * Tan(half))) - 1.0f) / 3.0f;

		let cosStart = Cos(startAngle);
		let sinStart = Sin(startAngle);
		let cosEnd = Cos(endAngle);
		let sinEnd = Sin(endAngle);

		let x0 = cx + (cosStart * radius);
		let y0 = cy + (sinStart * radius);
		let x3 = cx + (cosEnd * radius);
		let y3 = cy + (sinEnd * radius);

		// The tangents at each end, which the control points travel along.
		let dx0 = -sinStart * radius;
		let dy0 = cosStart * radius;
		let dx3 = -sinEnd * radius;
		let dy3 = cosEnd * radius;

		builder.CubicTo(x0 + (alpha * dx0), y0 + (alpha * dy0),
			x3 - (alpha * dx3), y3 - (alpha * dy3), x3, y3);
	}
}
