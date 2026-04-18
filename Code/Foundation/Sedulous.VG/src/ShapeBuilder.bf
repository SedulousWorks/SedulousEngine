using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Static helper for building common shapes as Paths
public static class ShapeBuilder
{
	/// Build a rounded rectangle path with per-corner radii
	public static void BuildRoundedRect(RectangleF rect, CornerRadii radii, PathBuilder builder)
	{
		let maxRadius = Math.Min(rect.Width, rect.Height) * 0.5f;
		let tl = Math.Min(radii.TopLeft, maxRadius);
		let tr = Math.Min(radii.TopRight, maxRadius);
		let br = Math.Min(radii.BottomRight, maxRadius);
		let bl = Math.Min(radii.BottomLeft, maxRadius);

		let x = rect.X;
		let y = rect.Y;
		let w = rect.Width;
		let h = rect.Height;

		// Start at top edge, after top-left corner
		builder.MoveTo(x + tl, y);

		// Top edge -> top-right corner
		builder.LineTo(x + w - tr, y);
		if (tr > 0)
			ArcCorner(builder, x + w - tr, y + tr, tr, -Math.PI_f * 0.5f, 0);

		// Right edge -> bottom-right corner
		builder.LineTo(x + w, y + h - br);
		if (br > 0)
			ArcCorner(builder, x + w - br, y + h - br, br, 0, Math.PI_f * 0.5f);

		// Bottom edge -> bottom-left corner
		builder.LineTo(x + bl, y + h);
		if (bl > 0)
			ArcCorner(builder, x + bl, y + h - bl, bl, Math.PI_f * 0.5f, Math.PI_f);

		// Left edge -> top-left corner
		builder.LineTo(x, y + tl);
		if (tl > 0)
			ArcCorner(builder, x + tl, y + tl, tl, Math.PI_f, Math.PI_f * 1.5f);

		builder.Close();
	}

	/// Build a circle path using 4 cubic Bezier curves
	public static void BuildCircle(Vector2 center, float radius, PathBuilder builder)
	{
		BuildEllipse(center, radius, radius, builder);
	}

	/// Build an ellipse path using 4 cubic Bezier curves
	public static void BuildEllipse(Vector2 center, float rx, float ry, PathBuilder builder)
	{
		// Cubic Bezier approximation of quarter circle: control point offset = radius * 0.5522847498
		let k = 0.5522847498f;
		let kx = rx * k;
		let ky = ry * k;

		let cx = center.X;
		let cy = center.Y;

		builder.MoveTo(cx + rx, cy);
		builder.CubicTo(cx + rx, cy + ky, cx + kx, cy + ry, cx, cy + ry);
		builder.CubicTo(cx - kx, cy + ry, cx - rx, cy + ky, cx - rx, cy);
		builder.CubicTo(cx - rx, cy - ky, cx - kx, cy - ry, cx, cy - ry);
		builder.CubicTo(cx + kx, cy - ry, cx + rx, cy - ky, cx + rx, cy);
		builder.Close();
	}

	/// Build a regular polygon (e.g., hexagon with sides=6)
	public static void BuildRegularPolygon(Vector2 center, float radius, int sides, PathBuilder builder)
	{
		if (sides < 3) return;

		let angleStep = Math.PI_f * 2.0f / sides;
		// Start from top (-PI/2 rotation so flat side is at bottom for even-sided polygons)
		let startAngle = -Math.PI_f * 0.5f;

		for (int i = 0; i < sides; i++)
		{
			let angle = startAngle + angleStep * i;
			let x = center.X + Math.Cos(angle) * radius;
			let y = center.Y + Math.Sin(angle) * radius;

			if (i == 0)
				builder.MoveTo(x, y);
			else
				builder.LineTo(x, y);
		}

		builder.Close();
	}

	/// Build a star shape
	public static void BuildStar(Vector2 center, float outerRadius, float innerRadius, int points, PathBuilder builder)
	{
		if (points < 3) return;

		let totalPoints = points * 2;
		let angleStep = Math.PI_f * 2.0f / totalPoints;
		let startAngle = -Math.PI_f * 0.5f;

		for (int i = 0; i < totalPoints; i++)
		{
			let angle = startAngle + angleStep * i;
			let r = (i % 2 == 0) ? outerRadius : innerRadius;
			let x = center.X + Math.Cos(angle) * r;
			let y = center.Y + Math.Sin(angle) * r;

			if (i == 0)
				builder.MoveTo(x, y);
			else
				builder.LineTo(x, y);
		}

		builder.Close();
	}

	/// Helper: add a quarter-arc as a cubic Bezier approximation
	private static void ArcCorner(PathBuilder builder, float cx, float cy, float r, float startAngle, float endAngle)
	{
		let sweep = endAngle - startAngle;
		let alpha = (float)(Math.Sin(sweep) * (Math.Sqrt(4.0 + 3.0 * Math.Tan(sweep * 0.5) * Math.Tan(sweep * 0.5)) - 1.0) / 3.0);

		let cosStart = Math.Cos(startAngle);
		let sinStart = Math.Sin(startAngle);
		let cosEnd = Math.Cos(endAngle);
		let sinEnd = Math.Sin(endAngle);

		let x0 = cx + (float)cosStart * r;
		let y0 = cy + (float)sinStart * r;
		let x3 = cx + (float)cosEnd * r;
		let y3 = cy + (float)sinEnd * r;

		let dx0 = -(float)sinStart * r;
		let dy0 = (float)cosStart * r;
		let dx3 = -(float)sinEnd * r;
		let dy3 = (float)cosEnd * r;

		builder.CubicTo(
			x0 + alpha * dx0, y0 + alpha * dy0,
			x3 - alpha * dx3, y3 - alpha * dy3,
			x3, y3
		);
	}
}
