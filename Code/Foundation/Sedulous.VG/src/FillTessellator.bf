using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Turns filled paths into triangles, with an analytically antialiased fringe.
///
/// The fringe is a ring of quads around the shape, running from full coverage on the inside
/// to zero on the outside. That is what gives smooth edges with no multisampling: the
/// hardware interpolates the coverage and the shader multiplies alpha by it.
static class FillTessellator
{
	/// How wide the antialiased fringe is, in pixels. Under one, so the ring straddles the
	/// true edge rather than growing the shape.
	public const float FringeWidth = 0.75f;

	/// How wide the baked gradient ramp is.
	///
	/// Public because the cover quad emitted for a stencil fill has to carry the SAME per
	/// vertex gradient data the tessellated path would, and it is built elsewhere.
	public const float GradientLutWidth = 256.0f;

	/// Below this, two points are the same point.
	private const float cEpsilon = 0.0001f;

	/// A ramp parameter as a lookup coordinate at a TEXEL CENTRE.
	///
	/// Centred so the endpoint stops come out exact under a clamping sampler: sampling at
	/// zero would land half a texel outside the ramp and blend with the edge.
	public static float LutU(float t)
		=> (0.5f + (Clamp(t, 0.0f, 1.0f) * (GradientLutWidth - 1.0f))) / GradientLutWidth;

	/// What to write as a vertex's texture coordinate for a gradient.
	public static Float2 GradientTexCoord(VGGradientTess mode, IVGFill fill, Float2 point,
		Rectangle bounds)
	{
		switch (mode)
		{
		case .LinearLut:
			// Pad compresses to texel centres because its sampler clamps. Repeat and
			// reflect emit the RAW parameter instead and let the sampler's own wrap or
			// mirror apply the spread per pixel: clamping per vertex would flatten the
			// tiling into a single span.
			if (fill.Spread != .Pad)
				return .(fill.GetParameterAt(point, bounds), 0.5f);
			return .(LutU(fill.GetParameterAt(point, bounds)), 0.5f);

		case .RadialCoord, .ConicCoord:
			return fill.GradientCoord(point, bounds);

		case .Gouraud:
			return .(VGVertex.SolidUV, VGVertex.SolidUV);
		}
	}

	/// Tessellates a path filled with one colour.
	public static void Tessellate(Path path, FillRule fillRule, Color color, bool antiAlias,
		List<VGVertex> vertices, List<uint32> indices, float tolerance = 0.25f,
		float fringeWidth = FringeWidth)
	{
		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, tolerance, subPaths);

		for (let subPath in subPaths)
		{
			if (!UsablePointCount(subPath, let count))
				continue;

			let points = Span<Float2>(subPath.Points.Ptr, count);

			if (antiAlias)
			{
				TessellateWithAA(points, fillRule, color, vertices, indices, fringeWidth);
				continue;
			}

			let baseIndex = (uint32)vertices.Count;
			for (let point in points)
				vertices.Add(VGVertex.Solid(point, color));
			Triangulator.Triangulate(points, fillRule, indices, baseIndex);
		}
	}

	/// Tessellates a path filled with a style.
	///
	/// `gradientTess` says what the vertices carry: with anything but Gouraud they carry a
	/// texture coordinate and white, and the caller has baked and bound a ramp so the
	/// fragment shader samples it per pixel. Gouraud interpolates the colour itself across
	/// the triangle, which is exact only for a linear gradient.
	public static void TessellateWithFill(Path path, FillRule fillRule, IVGFill fill,
		bool antiAlias, List<VGVertex> vertices, List<uint32> indices, float tolerance = 0.25f,
		float fringeWidth = FringeWidth, VGGradientTess gradientTess = .Gouraud)
	{
		// A fill with nothing to interpolate is just a colour, and takes the cheaper path.
		if (!fill.RequiresInterpolation)
		{
			Tessellate(path, fillRule, fill.BaseColor, antiAlias, vertices, indices, tolerance,
				fringeWidth);
			return;
		}

		let bounds = path.GetBounds();

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, tolerance, subPaths);

		for (let subPath in subPaths)
		{
			if (!UsablePointCount(subPath, let count))
				continue;

			let points = Span<Float2>(subPath.Points.Ptr, count);

			if (antiAlias)
			{
				TessellateWithAAFill(points, fillRule, fill, bounds, vertices, indices,
					fringeWidth, gradientTess);
				continue;
			}

			let baseIndex = (uint32)vertices.Count;
			for (let point in points)
			{
				if (gradientTess != .Gouraud)
				{
					vertices.Add(.(point, GradientTexCoord(gradientTess, fill, point, bounds),
						.White));
				}
				else
				{
					vertices.Add(VGVertex.Solid(point, fill.GetColorAt(point, bounds)));
				}
			}
			Triangulator.Triangulate(points, fillRule, indices, baseIndex);
		}
	}

	/// How many of a subpath's points to use, dropping a trailing repeat of the first.
	///
	/// A contour that ends where it started would give the triangulator a zero length edge,
	/// whose normal is undefined and whose ear test never resolves.
	private static bool UsablePointCount(FlattenedSubPath subPath, out int count)
	{
		count = subPath.Points.Count;
		if (count < 3)
			return false;

		if (Distance(subPath.Points[0], subPath.Points[count - 1]) < cEpsilon)
			count--;

		return count >= 3;
	}

	/// The outward normal at each point, averaged from the two edges meeting there.
	///
	/// Averaged rather than per edge so the fringe is CONTINUOUS around a corner: two
	/// independent edge normals would leave a wedge shaped gap on the outside of every
	/// turn.
	private static void ComputeFringeNormals(Span<Float2> points, List<Float2> normals)
	{
		let n = points.Length;
		normals.Resize(n);

		// Which side is out depends on the winding, so the sign comes from the area.
		let sign = (Triangulator.PolygonArea(points) > 0.0f) ? 1.0f : -1.0f;

		for (int i = 0; i < n; i++)
		{
			let previous = (i + n - 1) % n;
			let next = (i + 1) % n;

			var e0 = points[i] - points[previous];
			var e1 = points[next] - points[i];
			let length0 = Length(e0);
			let length1 = Length(e1);
			if (length0 > cEpsilon)
				e0 = e0 / length0;
			if (length1 > cEpsilon)
				e1 = e1 / length1;

			let n0 = Float2(e0.Y, -e0.X) * sign;
			let n1 = Float2(e1.Y, -e1.X) * sign;

			var average = (n0 + n1) * 0.5f;
			let averageLength = Length(average);

			if (averageLength > cEpsilon)
			{
				average = average / averageLength;

				// Lengthened like a miter, so the fringe keeps its width THROUGH a corner
				// rather than pinching to a point. Clamped, because a sharp corner's miter
				// grows without bound and would throw a spike off the shape.
				let dot = (n0.X * average.X) + (n0.Y * average.Y);
				if (dot > 0.1f)
					average = average * Min(1.0f / dot, 3.0f);
			}
			else
			{
				// The two edges double back on each other, so there is no average
				// direction. One of them is as good an answer as exists.
				average = n0;
			}

			normals[i] = average;
		}
	}

	/// Emits the filled interior and the fringe ring around it.
	///
	/// The interior is inset by half the fringe and the ring straddles the true edge, so the
	/// shape neither grows nor shrinks.
	private static void EmitFringeRing(Span<Float2> points, FillRule fillRule, List<Float2> normals,
		List<Color> innerColors, List<Color> outerColors, List<VGVertex> vertices,
		List<uint32> indices, float fringeWidth, List<Float2> texCoords)
	{
		let n = points.Length;
		let innerBase = (uint32)vertices.Count;

		let innerPoints = scope List<Float2>();
		innerPoints.Resize(n);
		for (int i = 0; i < n; i++)
		{
			innerPoints[i] = points[i] - (normals[i] * (fringeWidth * 0.5f));
			if (texCoords != null)
				vertices.Add(.(innerPoints[i], texCoords[i], innerColors[i], 1.0f));
			else
				vertices.Add(VGVertex.Solid(innerPoints[i], innerColors[i], 1.0f));
		}

		Triangulator.Triangulate(innerPoints, fillRule, indices, innerBase);

		let outerBase = (uint32)vertices.Count;
		for (int i = 0; i < n; i++)
		{
			let outerPoint = points[i] + (normals[i] * (fringeWidth * 0.5f));
			// Coverage ZERO on the outside: the fringe fades out across the ring.
			if (texCoords != null)
				vertices.Add(.(outerPoint, texCoords[i], outerColors[i], 0.0f));
			else
				vertices.Add(VGVertex.Solid(outerPoint, outerColors[i], 0.0f));
		}

		// Two triangles per edge, joining the inner ring to the outer one.
		for (int i = 0; i < n; i++)
		{
			let j = (uint32)((i + 1) % n);
			let i0 = innerBase + (uint32)i;
			let i1 = innerBase + j;
			let o0 = outerBase + (uint32)i;
			let o1 = outerBase + j;

			indices.Add(i0);
			indices.Add(i1);
			indices.Add(o1);
			indices.Add(i0);
			indices.Add(o1);
			indices.Add(o0);
		}
	}

	private static void TessellateWithAA(Span<Float2> points, FillRule fillRule, Color color,
		List<VGVertex> vertices, List<uint32> indices, float fringeWidth)
	{
		let n = points.Length;

		let normals = scope List<Float2>();
		ComputeFringeNormals(points, normals);

		// The outer ring keeps the colour and loses the ALPHA, so the fade is in
		// transparency rather than toward black.
		let transparent = Color(color.R, color.G, color.B, 0.0f);

		let innerColors = scope List<Color>();
		let outerColors = scope List<Color>();
		innerColors.Resize(n);
		outerColors.Resize(n);
		for (int i = 0; i < n; i++)
		{
			innerColors[i] = color;
			outerColors[i] = transparent;
		}

		EmitFringeRing(points, fillRule, normals, innerColors, outerColors, vertices, indices,
			fringeWidth, null);
	}

	private static void TessellateWithAAFill(Span<Float2> points, FillRule fillRule, IVGFill fill,
		Rectangle bounds, List<VGVertex> vertices, List<uint32> indices, float fringeWidth,
		VGGradientTess gradientTess)
	{
		let n = points.Length;

		let normals = scope List<Float2>();
		ComputeFringeNormals(points, normals);

		let innerColors = scope List<Color>();
		let outerColors = scope List<Color>();
		innerColors.Resize(n);
		outerColors.Resize(n);

		if (gradientTess != .Gouraud)
		{
			// The gradient rides in the texture coordinate and the colours carry white.
			// The outer ring still fades, through the coverage the ring emitter sets.
			let texCoords = scope List<Float2>();
			texCoords.Resize(n);
			for (int i = 0; i < n; i++)
			{
				innerColors[i] = .White;
				outerColors[i] = .White;
				texCoords[i] = GradientTexCoord(gradientTess, fill, points[i], bounds);
			}

			EmitFringeRing(points, fillRule, normals, innerColors, outerColors, vertices, indices,
				fringeWidth, texCoords);
			return;
		}

		for (int i = 0; i < n; i++)
		{
			let color = fill.GetColorAt(points[i], bounds);
			innerColors[i] = color;
			outerColors[i] = .(color.R, color.G, color.B, 0.0f);
		}

		EmitFringeRing(points, fillRule, normals, innerColors, outerColors, vertices, indices,
			fringeWidth, null);
	}
}
