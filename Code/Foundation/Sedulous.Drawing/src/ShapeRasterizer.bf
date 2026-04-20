using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.Fonts;
using Sedulous.Images;

namespace Sedulous.Drawing;

/// Tessellates shapes into vertices and indices for rendering
public class ShapeRasterizer
{
	// Fixed UV for solid color drawing - works with any 1x1 texture
	private const float SolidUV = 0.5f;

	// === Filled Shapes ===

	/// Rasterize a filled rectangle
	public void RasterizeRect(RectangleF rect, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let baseIndex = (uint16)vertices.Count;

		// 4 corners
		vertices.Add(.(rect.X, rect.Y, SolidUV, SolidUV, color));                              // Top-left
		vertices.Add(.(rect.X + rect.Width, rect.Y, SolidUV, SolidUV, color));                 // Top-right
		vertices.Add(.(rect.X + rect.Width, rect.Y + rect.Height, SolidUV, SolidUV, color));   // Bottom-right
		vertices.Add(.(rect.X, rect.Y + rect.Height, SolidUV, SolidUV, color));                // Bottom-left

		// 2 triangles
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);
	}

	/// Rasterize a quad from 4 pre-transformed corner points (for rotation support)
	public void RasterizeQuad(Vector2 topLeft, Vector2 topRight, Vector2 bottomRight, Vector2 bottomLeft, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let baseIndex = (uint16)vertices.Count;

		vertices.Add(.(topLeft.X, topLeft.Y, SolidUV, SolidUV, color));
		vertices.Add(.(topRight.X, topRight.Y, SolidUV, SolidUV, color));
		vertices.Add(.(bottomRight.X, bottomRight.Y, SolidUV, SolidUV, color));
		vertices.Add(.(bottomLeft.X, bottomLeft.Y, SolidUV, SolidUV, color));

		// 2 triangles
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);
	}

	/// Rasterize a filled circle using triangle fan
	public void RasterizeCircle(Vector2 center, float radius, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		RasterizeEllipse(center, radius, radius, vertices, indices, color);
	}

	/// Rasterize a filled ellipse using triangle fan
	public void RasterizeEllipse(Vector2 center, float rx, float ry, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let segments = CalculateCircleSegments(Math.Max(rx, ry));
		let baseIndex = (uint16)vertices.Count;

		// Center vertex
		vertices.Add(.(center.X, center.Y, SolidUV, SolidUV, color));

		// Perimeter vertices
		let angleStep = Math.PI_f * 2.0f / segments;
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = i * angleStep;
			let x = center.X + Math.Cos(angle) * rx;
			let y = center.Y + Math.Sin(angle) * ry;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Triangle fan indices
		for (int32 i = 0; i < segments; i++)
		{
			indices.Add(baseIndex);           // Center
			indices.Add(baseIndex + (uint16)(i + 1));
			indices.Add(baseIndex + (uint16)(i + 2));
		}
	}

	/// Rasterize a filled rounded rectangle
	public void RasterizeRoundedRect(RectangleF rect, float radius, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		// Clamp radius to half the smallest dimension
		let maxRadius = Math.Min(rect.Width, rect.Height) * 0.5f;
		var r = Math.Min(radius, maxRadius);

		if (r <= 0)
		{
			RasterizeRect(rect, vertices, indices, color);
			return;
		}

		let segments = CalculateCornerSegments(r);
		let baseIndex = (uint16)vertices.Count;

		// Center vertex for fan
		let centerX = rect.X + rect.Width * 0.5f;
		let centerY = rect.Y + rect.Height * 0.5f;
		vertices.Add(.(centerX, centerY, SolidUV, SolidUV, color));

		// Generate vertices around the rounded rectangle
		// Starting from top-left corner, going clockwise
		let angleStep = (Math.PI_f * 0.5f) / segments;

		// Top-left corner
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f + i * angleStep;
			let x = rect.X + r + Math.Cos(angle) * r;
			let y = rect.Y + r + Math.Sin(angle) * r;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Top-right corner
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f * 1.5f + i * angleStep;
			let x = rect.X + rect.Width - r + Math.Cos(angle) * r;
			let y = rect.Y + r + Math.Sin(angle) * r;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Bottom-right corner
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = i * angleStep;
			let x = rect.X + rect.Width - r + Math.Cos(angle) * r;
			let y = rect.Y + rect.Height - r + Math.Sin(angle) * r;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Bottom-left corner
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f * 0.5f + i * angleStep;
			let x = rect.X + r + Math.Cos(angle) * r;
			let y = rect.Y + rect.Height - r + Math.Sin(angle) * r;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Generate triangle fan indices
		let perimeterCount = (segments + 1) * 4;
		for (int32 i = 0; i < perimeterCount; i++)
		{
			indices.Add(baseIndex);  // Center
			indices.Add(baseIndex + (uint16)(i + 1));
			indices.Add(baseIndex + (uint16)((i + 1) % perimeterCount + 1));
		}
	}

	/// Rasterize a filled arc (pie slice)
	public void RasterizeArc(Vector2 center, float radius, float startAngle, float sweepAngle, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let segments = CalculateArcSegments(radius, Math.Abs(sweepAngle));
		let baseIndex = (uint16)vertices.Count;

		// Center vertex
		vertices.Add(.(center.X, center.Y, SolidUV, SolidUV, color));

		// Arc vertices
		let angleStep = sweepAngle / segments;
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = startAngle + i * angleStep;
			let x = center.X + Math.Cos(angle) * radius;
			let y = center.Y + Math.Sin(angle) * radius;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Triangle fan indices
		for (int32 i = 0; i < segments; i++)
		{
			indices.Add(baseIndex);
			indices.Add(baseIndex + (uint16)(i + 1));
			indices.Add(baseIndex + (uint16)(i + 2));
		}
	}

	// === Stroked Shapes ===

	/// Rasterize a line with thickness
	public void RasterizeLine(Vector2 start, Vector2 end, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color, LineCap cap)
	{
		let direction = end - start;
		let length = direction.Length();

		if (length < 0.0001f)
			return;

		// Perpendicular vector for thickness
		let normal = Vector2(-direction.Y / length, direction.X / length);
		let halfThick = thickness * 0.5f;

		let baseIndex = (uint16)vertices.Count;

		// Main line quad
		let p0 = start - normal * halfThick;
		let p1 = start + normal * halfThick;
		let p2 = end + normal * halfThick;
		let p3 = end - normal * halfThick;

		vertices.Add(.(p0.X, p0.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p1.X, p1.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p2.X, p2.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p3.X, p3.Y, SolidUV, SolidUV, color));

		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);

		// Add line caps
		if (cap != .Butt)
		{
			let dir = direction / length;

			if (cap == .Round)
			{
				// Round cap at start
				RasterizeCapRound(start, -dir, normal, halfThick, vertices, indices, color);
				// Round cap at end
				RasterizeCapRound(end, dir, normal, halfThick, vertices, indices, color);
			}
			else if (cap == .Square)
			{
				// Square cap at start
				RasterizeCapSquare(start, -dir, normal, halfThick, vertices, indices, color);
				// Square cap at end
				RasterizeCapSquare(end, dir, normal, halfThick, vertices, indices, color);
			}
		}
	}

	/// Rasterize a stroked rectangle (stroke centered on rect edges)
	public void RasterizeStrokeRect(RectangleF rect, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let halfThick = thickness * 0.5f;

		// Stroke is centered on the rect edges (standard for 2D graphics)
		let outer = RectangleF(rect.X - halfThick, rect.Y - halfThick, rect.Width + thickness, rect.Height + thickness);
		let inner = RectangleF(rect.X + halfThick, rect.Y + halfThick, rect.Width - thickness, rect.Height - thickness);

		let baseIndex = (uint16)vertices.Count;

		// Outer vertices (clockwise)
		vertices.Add(.(outer.X, outer.Y, SolidUV, SolidUV, color));
		vertices.Add(.(outer.X + outer.Width, outer.Y, SolidUV, SolidUV, color));
		vertices.Add(.(outer.X + outer.Width, outer.Y + outer.Height, SolidUV, SolidUV, color));
		vertices.Add(.(outer.X, outer.Y + outer.Height, SolidUV, SolidUV, color));

		// Inner vertices (clockwise)
		vertices.Add(.(inner.X, inner.Y, SolidUV, SolidUV, color));
		vertices.Add(.(inner.X + inner.Width, inner.Y, SolidUV, SolidUV, color));
		vertices.Add(.(inner.X + inner.Width, inner.Y + inner.Height, SolidUV, SolidUV, color));
		vertices.Add(.(inner.X, inner.Y + inner.Height, SolidUV, SolidUV, color));

		// Top edge
		indices.Add(baseIndex + 0); indices.Add(baseIndex + 1); indices.Add(baseIndex + 5);
		indices.Add(baseIndex + 0); indices.Add(baseIndex + 5); indices.Add(baseIndex + 4);
		// Right edge
		indices.Add(baseIndex + 1); indices.Add(baseIndex + 2); indices.Add(baseIndex + 6);
		indices.Add(baseIndex + 1); indices.Add(baseIndex + 6); indices.Add(baseIndex + 5);
		// Bottom edge
		indices.Add(baseIndex + 2); indices.Add(baseIndex + 3); indices.Add(baseIndex + 7);
		indices.Add(baseIndex + 2); indices.Add(baseIndex + 7); indices.Add(baseIndex + 6);
		// Left edge
		indices.Add(baseIndex + 3); indices.Add(baseIndex + 0); indices.Add(baseIndex + 4);
		indices.Add(baseIndex + 3); indices.Add(baseIndex + 4); indices.Add(baseIndex + 7);
	}

	/// Rasterize a stroked circle
	public void RasterizeStrokeCircle(Vector2 center, float radius, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		RasterizeStrokeEllipse(center, radius, radius, thickness, vertices, indices, color);
	}

	/// Rasterize a stroked ellipse
	public void RasterizeStrokeEllipse(Vector2 center, float rx, float ry, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let segments = CalculateCircleSegments(Math.Max(rx, ry));
		let halfThick = thickness * 0.5f;
		let baseIndex = (uint16)vertices.Count;

		let angleStep = Math.PI_f * 2.0f / segments;

		// Generate outer and inner vertices
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = i * angleStep;
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);

			// Calculate point on ellipse
			let px = cos * rx;
			let py = sin * ry;

			// Normal direction at this point on ellipse (gradient of ellipse equation)
			let nx = cos / rx;
			let ny = sin / ry;
			let nlen = Math.Sqrt(nx * nx + ny * ny);
			let normalX = (float)(nx / nlen);
			let normalY = (float)(ny / nlen);

			// Outer vertex - offset outward along normal
			let outerX = center.X + px + normalX * halfThick;
			let outerY = center.Y + py + normalY * halfThick;
			vertices.Add(.(outerX, outerY, SolidUV, SolidUV, color));

			// Inner vertex - offset inward along normal
			let innerX = center.X + px - normalX * halfThick;
			let innerY = center.Y + py - normalY * halfThick;
			vertices.Add(.(innerX, innerY, SolidUV, SolidUV, color));
		}

		// Generate quad strip indices
		for (int32 i = 0; i < segments; i++)
		{
			let i0 = baseIndex + (uint16)(i * 2);
			let i1 = baseIndex + (uint16)(i * 2 + 1);
			let i2 = baseIndex + (uint16)(i * 2 + 2);
			let i3 = baseIndex + (uint16)(i * 2 + 3);

			indices.Add(i0); indices.Add(i2); indices.Add(i1);
			indices.Add(i1); indices.Add(i2); indices.Add(i3);
		}
	}

	/// Rasterize a stroked rounded rectangle
	public void RasterizeStrokeRoundedRect(RectangleF rect, float radius, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		// Clamp radius to half the smallest dimension
		let maxRadius = Math.Min(rect.Width, rect.Height) * 0.5f;
		var r = Math.Min(radius, maxRadius);

		if (r <= 0)
		{
			RasterizeStrokeRect(rect, thickness, vertices, indices, color);
			return;
		}

		let segments = CalculateCornerSegments(r);
		let halfThick = thickness * 0.5f;
		let baseIndex = (uint16)vertices.Count;
		let angleStep = (Math.PI_f * 0.5f) / segments;

		// Generate outer and inner vertices around the rounded rectangle perimeter
		// Going clockwise: top-left corner, top-right corner, bottom-right corner, bottom-left corner

		// Top-left corner (center at rect.X + r, rect.Y + r)
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f + i * angleStep;
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let cx = rect.X + r;
			let cy = rect.Y + r;

			// Outer vertex
			vertices.Add(.(cx + cos * (r + halfThick), cy + sin * (r + halfThick), SolidUV, SolidUV, color));
			// Inner vertex
			vertices.Add(.(cx + cos * (r - halfThick), cy + sin * (r - halfThick), SolidUV, SolidUV, color));
		}

		// Top-right corner (center at rect.Right - r, rect.Y + r)
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f * 1.5f + i * angleStep;
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let cx = rect.X + rect.Width - r;
			let cy = rect.Y + r;

			vertices.Add(.(cx + cos * (r + halfThick), cy + sin * (r + halfThick), SolidUV, SolidUV, color));
			vertices.Add(.(cx + cos * (r - halfThick), cy + sin * (r - halfThick), SolidUV, SolidUV, color));
		}

		// Bottom-right corner (center at rect.Right - r, rect.Bottom - r)
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = i * angleStep;
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let cx = rect.X + rect.Width - r;
			let cy = rect.Y + rect.Height - r;

			vertices.Add(.(cx + cos * (r + halfThick), cy + sin * (r + halfThick), SolidUV, SolidUV, color));
			vertices.Add(.(cx + cos * (r - halfThick), cy + sin * (r - halfThick), SolidUV, SolidUV, color));
		}

		// Bottom-left corner (center at rect.X + r, rect.Bottom - r)
		for (int32 i = 0; i <= segments; i++)
		{
			let angle = Math.PI_f * 0.5f + i * angleStep;
			let cos = Math.Cos(angle);
			let sin = Math.Sin(angle);
			let cx = rect.X + r;
			let cy = rect.Y + rect.Height - r;

			vertices.Add(.(cx + cos * (r + halfThick), cy + sin * (r + halfThick), SolidUV, SolidUV, color));
			vertices.Add(.(cx + cos * (r - halfThick), cy + sin * (r - halfThick), SolidUV, SolidUV, color));
		}

		// Generate quad strip indices connecting the outline
		let perimeterCount = (segments + 1) * 4;
		for (int32 i = 0; i < perimeterCount; i++)
		{
			let curr = i * 2;
			let next = ((i + 1) % perimeterCount) * 2;

			let i0 = baseIndex + (uint16)curr;       // Current outer
			let i1 = baseIndex + (uint16)(curr + 1); // Current inner
			let i2 = baseIndex + (uint16)next;       // Next outer
			let i3 = baseIndex + (uint16)(next + 1); // Next inner

			// Two triangles forming a quad
			indices.Add(i0); indices.Add(i2); indices.Add(i1);
			indices.Add(i1); indices.Add(i2); indices.Add(i3);
		}
	}

	// === Textured Shapes ===

	/// Rasterize a textured quad
	public void RasterizeTexturedQuad(RectangleF destRect, RectangleF srcRect, uint32 texWidth, uint32 texHeight, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let baseIndex = (uint16)vertices.Count;

		// Calculate UVs from source rect
		let u0 = srcRect.X / texWidth;
		let v0 = srcRect.Y / texHeight;
		let u1 = (srcRect.X + srcRect.Width) / texWidth;
		let v1 = (srcRect.Y + srcRect.Height) / texHeight;

		vertices.Add(.(destRect.X, destRect.Y, u0, v0, color));
		vertices.Add(.(destRect.X + destRect.Width, destRect.Y, u1, v0, color));
		vertices.Add(.(destRect.X + destRect.Width, destRect.Y + destRect.Height, u1, v1, color));
		vertices.Add(.(destRect.X, destRect.Y + destRect.Height, u0, v1, color));

		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);
	}

	/// Rasterize a 9-slice image
	public void RasterizeNineSlice(RectangleF destRect, RectangleF srcRect, NineSlice slices, uint32 texWidth, uint32 texHeight, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		// Source coordinates (X0/Y0 = start, X1/Y1 = after left/top border, X2/Y2 = before right/bottom border)
		let srcX0 = srcRect.X;
		let srcX1 = srcRect.X + slices.Left;
		let srcX2 = srcRect.X + srcRect.Width - slices.Right;

		let srcY0 = srcRect.Y;
		let srcY1 = srcRect.Y + slices.Top;
		let srcY2 = srcRect.Y + srcRect.Height - slices.Bottom;

		// Destination coordinates (corners maintain their pixel size from slices)
		let dstX0 = destRect.X;
		let dstX1 = destRect.X + slices.Left;
		let dstX2 = destRect.X + destRect.Width - slices.Right;

		let dstY0 = destRect.Y;
		let dstY1 = destRect.Y + slices.Top;
		let dstY2 = destRect.Y + destRect.Height - slices.Bottom;

		// Generate 9 quads
		// Row 0
		RasterizeTexturedQuad(.(dstX0, dstY0, slices.Left, slices.Top), .(srcX0, srcY0, slices.Left, slices.Top), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX1, dstY0, dstX2 - dstX1, slices.Top), .(srcX1, srcY0, srcX2 - srcX1, slices.Top), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX2, dstY0, slices.Right, slices.Top), .(srcX2, srcY0, slices.Right, slices.Top), texWidth, texHeight, vertices, indices, color);

		// Row 1
		RasterizeTexturedQuad(.(dstX0, dstY1, slices.Left, dstY2 - dstY1), .(srcX0, srcY1, slices.Left, srcY2 - srcY1), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX1, dstY1, dstX2 - dstX1, dstY2 - dstY1), .(srcX1, srcY1, srcX2 - srcX1, srcY2 - srcY1), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX2, dstY1, slices.Right, dstY2 - dstY1), .(srcX2, srcY1, slices.Right, srcY2 - srcY1), texWidth, texHeight, vertices, indices, color);

		// Row 2
		RasterizeTexturedQuad(.(dstX0, dstY2, slices.Left, slices.Bottom), .(srcX0, srcY2, slices.Left, slices.Bottom), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX1, dstY2, dstX2 - dstX1, slices.Bottom), .(srcX1, srcY2, srcX2 - srcX1, slices.Bottom), texWidth, texHeight, vertices, indices, color);
		RasterizeTexturedQuad(.(dstX2, dstY2, slices.Right, slices.Bottom), .(srcX2, srcY2, slices.Right, slices.Bottom), texWidth, texHeight, vertices, indices, color);
	}

	// === Polygons and Polylines ===

	/// Rasterize a filled polygon using ear clipping triangulation
	public void RasterizePolygon(Span<Vector2> points, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		if (points.Length < 3)
			return;

		let baseIndex = (uint16)vertices.Count;

		// Add all vertices
		for (let point in points)
		{
			vertices.Add(.(point.X, point.Y, SolidUV, SolidUV, color));
		}

		// Simple ear clipping for convex or simple polygons
		TriangulatePolygon(points, baseIndex, indices);
	}

	/// Rasterize a polyline (open path) with line segments
	public void RasterizePolyline(Span<Vector2> points, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color, LineCap cap, LineJoin join)
	{
		if (points.Length < 2)
			return;

		let halfThickness = thickness * 0.5f;

		// Draw each segment
		for (int32 i = 0; i < points.Length - 1; i++)
		{
			let p0 = points[i];
			let p1 = points[i + 1];

			// Calculate direction and normal
			var dir = p1 - p0;
			let len = dir.Length();
			if (len < 0.0001f)
				continue;
			dir = dir / len;
			let normal = Vector2(-dir.Y, dir.X);

			// Line body as quad
			let baseIndex = (uint16)vertices.Count;
			vertices.Add(.(p0.X - normal.X * halfThickness, p0.Y - normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p0.X + normal.X * halfThickness, p0.Y + normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p1.X + normal.X * halfThickness, p1.Y + normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p1.X - normal.X * halfThickness, p1.Y - normal.Y * halfThickness, SolidUV, SolidUV, color));

			indices.Add(baseIndex + 0);
			indices.Add(baseIndex + 1);
			indices.Add(baseIndex + 2);
			indices.Add(baseIndex + 0);
			indices.Add(baseIndex + 2);
			indices.Add(baseIndex + 3);

			// Line join at intermediate points
			if (i > 0 && join != .Miter)
			{
				// TODO: Add proper miter/bevel/round joins
			}
		}

		// Start cap
		if (cap != .Butt && points.Length >= 2)
		{
			var dir = points[1] - points[0];
			let len = dir.Length();
			if (len > 0.0001f)
			{
				dir = dir / len;
				let normal = Vector2(-dir.Y, dir.X);
				if (cap == .Round)
					RasterizeCapRound(points[0], -dir, normal, halfThickness, vertices, indices, color);
				else if (cap == .Square)
					RasterizeCapSquare(points[0], -dir, normal, halfThickness, vertices, indices, color);
			}
		}

		// End cap
		if (cap != .Butt && points.Length >= 2)
		{
			let lastIdx = points.Length - 1;
			var dir = points[lastIdx] - points[lastIdx - 1];
			let len = dir.Length();
			if (len > 0.0001f)
			{
				dir = dir / len;
				let normal = Vector2(-dir.Y, dir.X);
				if (cap == .Round)
					RasterizeCapRound(points[lastIdx], dir, normal, halfThickness, vertices, indices, color);
				else if (cap == .Square)
					RasterizeCapSquare(points[lastIdx], dir, normal, halfThickness, vertices, indices, color);
			}
		}
	}

	/// Rasterize a stroked polygon (closed path)
	public void RasterizeStrokePolygon(Span<Vector2> points, float thickness, List<DrawVertex> vertices, List<uint16> indices, Color color, LineJoin join)
	{
		if (points.Length < 3)
			return;

		let halfThickness = thickness * 0.5f;

		// Draw each edge
		for (int32 i = 0; i < points.Length; i++)
		{
			let p0 = points[i];
			let p1 = points[(i + 1) % points.Length];

			// Calculate direction and normal
			var dir = p1 - p0;
			let len = dir.Length();
			if (len < 0.0001f)
				continue;
			dir = dir / len;
			let normal = Vector2(-dir.Y, dir.X);

			// Edge as quad
			let baseIndex = (uint16)vertices.Count;
			vertices.Add(.(p0.X - normal.X * halfThickness, p0.Y - normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p0.X + normal.X * halfThickness, p0.Y + normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p1.X + normal.X * halfThickness, p1.Y + normal.Y * halfThickness, SolidUV, SolidUV, color));
			vertices.Add(.(p1.X - normal.X * halfThickness, p1.Y - normal.Y * halfThickness, SolidUV, SolidUV, color));

			indices.Add(baseIndex + 0);
			indices.Add(baseIndex + 1);
			indices.Add(baseIndex + 2);
			indices.Add(baseIndex + 0);
			indices.Add(baseIndex + 2);
			indices.Add(baseIndex + 3);
		}
	}

	// === Helper Methods ===

	/// Triangulate a simple polygon using ear clipping
	private void TriangulatePolygon(Span<Vector2> points, uint16 baseIndex, List<uint16> indices)
	{
		let n = points.Length;
		if (n < 3)
			return;

		// For convex polygons, use simple fan triangulation
		// For concave polygons, this is an approximation
		for (int32 i = 1; i < n - 1; i++)
		{
			indices.Add(baseIndex);
			indices.Add(baseIndex + (uint16)i);
			indices.Add(baseIndex + (uint16)(i + 1));
		}
	}

	/// Calculate number of segments for a circle based on radius
	public int32 CalculateCircleSegments(float radius)
	{
		// More segments for larger circles
		return Math.Max(12, (int32)(radius * 0.5f));
	}

	/// Calculate number of segments for a corner arc
	private int32 CalculateCornerSegments(float radius)
	{
		return Math.Max(3, (int32)(radius * 0.25f));
	}

	/// Calculate number of segments for an arc
	public int32 CalculateArcSegments(float radius, float sweepAngle)
	{
		let circumference = radius * sweepAngle;
		int32 minSegments = 3;
		int32 calculatedSegments = (int32)(circumference * 0.5f);
		return Math.Max(minSegments, calculatedSegments);
	}

	/// Rasterize a round line cap
	private void RasterizeCapRound(Vector2 center, Vector2 direction, Vector2 normal, float halfThickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let segments = Math.Max(4, (int32)(halfThickness * 0.5f));
		let baseIndex = (uint16)vertices.Count;

		// Center vertex
		vertices.Add(.(center.X, center.Y, SolidUV, SolidUV, color));

		// Arc from -normal to +normal in the direction of the cap
		let startAngle = Math.Atan2(normal.Y, normal.X);
		let angleStep = Math.PI_f / segments;

		for (int32 i = 0; i <= segments; i++)
		{
			let angle = startAngle + i * angleStep;
			let x = center.X + Math.Cos(angle) * halfThickness;
			let y = center.Y + Math.Sin(angle) * halfThickness;
			vertices.Add(.(x, y, SolidUV, SolidUV, color));
		}

		// Triangle fan
		for (int32 i = 0; i < segments; i++)
		{
			indices.Add(baseIndex);
			indices.Add(baseIndex + (uint16)(i + 1));
			indices.Add(baseIndex + (uint16)(i + 2));
		}
	}

	/// Rasterize a square line cap
	private void RasterizeCapSquare(Vector2 center, Vector2 direction, Vector2 normal, float halfThickness, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let baseIndex = (uint16)vertices.Count;

		// Square cap extends by halfThickness in the direction
		let p0 = center - normal * halfThickness;
		let p1 = center + normal * halfThickness;
		let p2 = center + direction * halfThickness + normal * halfThickness;
		let p3 = center + direction * halfThickness - normal * halfThickness;

		vertices.Add(.(p0.X, p0.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p1.X, p1.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p2.X, p2.Y, SolidUV, SolidUV, color));
		vertices.Add(.(p3.X, p3.Y, SolidUV, SolidUV, color));

		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);
	}

	// === Text Rendering ===

	/// Rasterize a glyph quad (for text rendering)
	/// GlyphQuad contains screen-space coordinates and UVs from the font atlas
	public void RasterizeGlyphQuad(GlyphQuad quad, List<DrawVertex> vertices, List<uint16> indices, Color color)
	{
		let baseIndex = (uint16)vertices.Count;

		// Add 4 vertices using the quad's screen coords and UVs
		vertices.Add(.(quad.X0, quad.Y0, quad.U0, quad.V0, color));  // Top-left
		vertices.Add(.(quad.X1, quad.Y0, quad.U1, quad.V0, color));  // Top-right
		vertices.Add(.(quad.X1, quad.Y1, quad.U1, quad.V1, color));  // Bottom-right
		vertices.Add(.(quad.X0, quad.Y1, quad.U0, quad.V1, color));  // Bottom-left

		// 2 triangles
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 1);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 0);
		indices.Add(baseIndex + 2);
		indices.Add(baseIndex + 3);
	}
}
