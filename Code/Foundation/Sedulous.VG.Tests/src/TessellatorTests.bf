using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Turning paths into triangles: the filled interior, the antialiased fringe, and strokes
/// with their joins and caps.
class TessellatorTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	private static Path Rect(float x, float y, float w, float h)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x, y);
		builder.LineTo(x + w, y);
		builder.LineTo(x + w, y + h);
		builder.LineTo(x, y + h);
		builder.Close();
		return builder.ToPath();
	}

	// ---- fills ----

	[Test]
	public static void ARectangleWithoutAntiAliasingIsTwoTriangles()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, false, vertices, indices);

		Test.Assert(vertices.Count == 4);
		Test.Assert(indices.Count == 6);
		for (let vertex in vertices)
		{
			Test.Assert(vertex.Coverage == 1.0f, "opaque throughout without a fringe");
			Test.Assert(vertex.Color == Color.Red);
		}
	}

	/// Antialiasing adds an inner ring and an outer ring, so the vertex count doubles and
	/// the index count grows by the ring's quads.
	[Test]
	public static void AntiAliasingAddsAFringeRing()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let plain = scope List<VGVertex>();
		let plainIndices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, false, plain, plainIndices);

		let aa = scope List<VGVertex>();
		let aaIndices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, true, aa, aaIndices);

		Test.Assert(aa.Count == plain.Count * 2, "an inner ring and an outer one");
		Test.Assert(aaIndices.Count > plainIndices.Count);
	}

	/// The fringe fades in ALPHA rather than toward black, and the outer ring carries zero
	/// coverage so the shader can multiply it out.
	[Test]
	public static void TheFringeFadesInAlphaAtZeroCoverage()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .(1, 0, 0, 1), true, vertices, indices);

		var opaque = 0;
		var faded = 0;
		for (let vertex in vertices)
		{
			if (vertex.Coverage == 1.0f)
			{
				opaque++;
				Test.Assert(vertex.Color.A == 1.0f);
			}
			else
			{
				faded++;
				Test.Assert(vertex.Coverage == 0.0f);
				Test.Assert(vertex.Color.A == 0.0f, "transparent, not black");
				Test.Assert(vertex.Color.R == 1.0f, "and still red");
			}
		}
		Test.Assert((opaque > 0) && (opaque == faded));
	}

	/// The ring STRADDLES the true edge, so an antialiased shape neither grows nor shrinks:
	/// the inner ring is inside the original and the outer one is outside it.
	[Test]
	public static void TheFringeStraddlesTheTrueEdge()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, true, vertices, indices);

		var minX = FloatMax;
		var maxX = -FloatMax;
		for (let vertex in vertices)
		{
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
		}

		let half = FillTessellator.FringeWidth * 0.5f;
		Test.Assert(minX < 0.0f && minX > -(half + 0.5f), "just outside the left edge");
		Test.Assert(maxX > 10.0f && maxX < (10.0f + half + 0.5f));
	}

	/// A subpath with fewer than three usable points cannot be filled, and is skipped
	/// rather than producing degenerate triangles.
	[Test]
	public static void ADegenerateSubPathFillsNothing()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		let path = builder.ToPath();
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, false, vertices, indices);

		Test.Assert(vertices.IsEmpty);
		Test.Assert(indices.IsEmpty);
	}

	/// Every subpath is tessellated, so a shape made of several contours fills as one.
	[Test]
	public static void EverySubPathIsTessellated()
	{
		let builder = scope PathBuilder();
		builder.MoveTo(0, 0);
		builder.LineTo(10, 0);
		builder.LineTo(10, 10);
		builder.Close();
		builder.MoveTo(20, 20);
		builder.LineTo(30, 20);
		builder.LineTo(30, 30);
		builder.Close();
		let path = builder.ToPath();
		defer delete path;

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Red, false, vertices, indices);

		Test.Assert(vertices.Count == 6, "three points each");
		Test.Assert(indices.Count == 6);
	}

	// ---- fills with a style ----

	/// A fill with nothing to interpolate takes the plain colour path, which is cheaper and
	/// produces the same geometry.
	[Test]
	public static void ASolidFillTakesThePlainPath()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;
		let fill = scope VGSolidFill(.Green);

		let styled = scope List<VGVertex>();
		let styledIndices = scope List<uint32>();
		FillTessellator.TessellateWithFill(path, .NonZero, fill, false, styled, styledIndices);

		let plain = scope List<VGVertex>();
		let plainIndices = scope List<uint32>();
		FillTessellator.Tessellate(path, .NonZero, .Green, false, plain, plainIndices);

		Test.Assert(styled.Count == plain.Count);
		Test.Assert(styledIndices.Count == plainIndices.Count);
		Test.Assert(styled[0].Color == Color.Green);
	}

	/// The Gouraud path writes the fill's own colour per vertex, which is exact only for a
	/// linear gradient but is what a path with no dedicated shader gets.
	[Test]
	public static void TheGouraudPathWritesPerVertexColours()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let fill = scope VGLinearGradientFill(.(0, 0), .(10, 0));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.TessellateWithFill(path, .NonZero, fill, false, vertices, indices);

		// The left corners are red and the right ones blue.
		var sawRed = false;
		var sawBlue = false;
		for (let vertex in vertices)
		{
			if (vertex.Position.X < 5.0f)
				sawRed = sawRed || (vertex.Color.R > 0.9f);
			else
				sawBlue = sawBlue || (vertex.Color.B > 0.9f);
		}
		Test.Assert(sawRed && sawBlue);
	}

	/// A gradient with a dedicated shader carries WHITE and a texture coordinate instead,
	/// so the ramp is sampled per pixel rather than interpolated between corners.
	[Test]
	public static void AGradientTessPathCarriesWhiteAndACoordinate()
	{
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		let fill = scope VGRadialGradientFill(.(5, 5), 5.0f);
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();
		FillTessellator.TessellateWithFill(path, .NonZero, fill, false, vertices, indices,
			0.25f, FillTessellator.FringeWidth, .RadialCoord);

		for (let vertex in vertices)
		{
			Test.Assert(vertex.Color == Color.White, "the colour is the shader's job");
			// The coordinate is the offset from the centre over the radius, whose length
			// the shader takes as the parameter.
			Test.Assert(Near(Length(vertex.TexCoord),
				fill.GetParameterAt(vertex.Position, path.GetBounds())));
		}
	}

	/// A padded linear gradient maps to TEXEL CENTRES, so its endpoint stops come out exact
	/// under a clamping sampler.
	[Test]
	public static void APaddedLinearGradientMapsToTexelCentres()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(10, 0));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);

		let bounds = Rectangle(0, 0, 10, 10);
		let atStart = FillTessellator.GradientTexCoord(.LinearLut, fill, .(0, 0), bounds);
		let atEnd = FillTessellator.GradientTexCoord(.LinearLut, fill, .(10, 0), bounds);

		Test.Assert(Near(atStart.X, FillTessellator.LutU(0.0f)));
		Test.Assert(Near(atEnd.X, FillTessellator.LutU(1.0f)));
		Test.Assert(atStart.X > 0.0f, "half a texel in, not on the edge");
		Test.Assert(atEnd.X < 1.0f);
	}

	/// A repeating one emits the RAW parameter and lets the sampler wrap it: clamping per
	/// vertex would flatten the tiling into a single span.
	[Test]
	public static void ARepeatingGradientEmitsTheRawParameter()
	{
		let fill = scope VGLinearGradientFill(.(0, 0), .(10, 0));
		fill.AddStop(0.0f, .Red);
		fill.AddStop(1.0f, .Blue);
		fill.Spread = .Repeat;

		let bounds = Rectangle(0, 0, 30, 10);
		let far = FillTessellator.GradientTexCoord(.LinearLut, fill, .(30, 0), bounds);

		Test.Assert(Near(far.X, 3.0f), "three tiles out, uncompressed");
	}

	// ---- strokes ----

	[Test]
	public static void AStraightLineIsAQuad()
	{
		let points = scope Float2[](.(0, 0), .(10, 0));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), false, .Red, vertices, indices);

		Test.Assert(vertices.Count == 4, "two per point");
		Test.Assert(indices.Count == 6);

		// One unit either side of the line, which is half of a width of two.
		for (let vertex in vertices)
			Test.Assert(Near(Abs(vertex.Position.Y), 1.0f));
	}

	[Test]
	public static void AntiAliasingAddsTwoFringeRings()
	{
		let points = scope Float2[](.(0, 0), .(10, 0));

		let plain = scope List<VGVertex>();
		let plainIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), false, .Red, plain, plainIndices);

		let aa = scope List<VGVertex>();
		let aaIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), true, .Red, aa, aaIndices);

		Test.Assert(aa.Count == 8, "four rings of two points");
		Test.Assert(aaIndices.Count == plainIndices.Count * 3, "three strips instead of one");

		var faded = 0;
		for (let vertex in aa)
		{
			if (vertex.Coverage == 0.0f)
			{
				faded++;
				Test.Assert(vertex.Color.A == 0.0f);
			}
		}
		Test.Assert(faded == 4, "the two outer rings");
	}

	/// A closed polyline strokes its final edge too, so it has one more segment than an
	/// open one through the same points.
	[Test]
	public static void AClosedStrokeWalksItsFinalEdge()
	{
		let square = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));

		let open = scope List<VGVertex>();
		let openIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(square, false, .(2.0f), .(), false, .Red, open, openIndices);

		let closed = scope List<VGVertex>();
		let closedIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(square, true, .(2.0f), .(), false, .Red, closed,
			closedIndices);

		Test.Assert(closedIndices.Count == openIndices.Count + 6, "one more quad");
	}

	/// A closed path has no ends, so it gets no caps whatever the style says.
	[Test]
	public static void AClosedPathTakesNoCaps()
	{
		let square = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));

		let butt = scope List<VGVertex>();
		let buttIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(square, true, .(2.0f, .Butt, .Miter), .(), false, .Red,
			butt, buttIndices);

		let round = scope List<VGVertex>();
		let roundIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(square, true, .(2.0f, .Round, .Miter), .(), false, .Red,
			round, roundIndices);

		Test.Assert(round.Count == butt.Count, "no cap geometry either way");
	}

	/// Round and square caps add geometry past the ends; a butt cap is their absence.
	[Test]
	public static void CapsAddGeometryPastTheEnds()
	{
		let points = scope Float2[](.(0, 0), .(10, 0));

		int VertexCountFor(VGLineCap cap)
		{
			let vertices = scope List<VGVertex>();
			let indices = scope List<uint32>();
			StrokeTessellator.Tessellate(points, false, .(4.0f, cap, .Miter), .(), false, .Red,
				vertices, indices);
			return vertices.Count;
		}

		let butt = VertexCountFor(.Butt);
		Test.Assert(VertexCountFor(.Square) == butt + 8, "a quad at each end");
		Test.Assert(VertexCountFor(.Round) > butt + 8, "a fan at each end");
	}

	/// A square cap extends by HALF the stroke width, which is what makes two of them meet
	/// flush at a right angle.
	[Test]
	public static void ASquareCapExtendsByHalfTheWidth()
	{
		let points = scope Float2[](.(0, 0), .(10, 0));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(points, false, .(4.0f, .Square, .Miter), .(), false, .Red,
			vertices, indices);

		var minX = FloatMax;
		var maxX = -FloatMax;
		for (let vertex in vertices)
		{
			minX = Min(minX, vertex.Position.X);
			maxX = Max(maxX, vertex.Position.X);
		}

		Test.Assert(Near(minX, -2.0f), "back past the start");
		Test.Assert(Near(maxX, 12.0f), "and forward past the end");
	}

	/// A bevel join adds one triangle per visible corner; a round one adds a fan.
	[Test]
	public static void JoinsAddGeometryAtVisibleCorners()
	{
		let corner = scope Float2[](.(0, 0), .(10, 0), .(10, 10));

		int VertexCountFor(VGLineJoin join)
		{
			let vertices = scope List<VGVertex>();
			let indices = scope List<uint32>();
			StrokeTessellator.Tessellate(corner, false, .(4.0f, .Butt, join), .(), false, .Red,
				vertices, indices);
			return vertices.Count;
		}

		let miter = VertexCountFor(.Miter);
		Test.Assert(VertexCountFor(.Bevel) == miter + 3, "one triangle at the one corner");
		Test.Assert(VertexCountFor(.Round) > miter + 3);
	}

	/// A near straight corner needs no join geometry: there is no visible wedge to fill.
	[Test]
	public static void ANearlyStraightCornerNeedsNoJoin()
	{
		let straight = scope Float2[](.(0, 0), .(10, 0), .(20, 0));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(straight, false, .(4.0f, .Butt, .Bevel), .(), false, .Red,
			vertices, indices);

		Test.Assert(vertices.Count == 6, "two per point and nothing added");
	}

	/// A dash pattern strokes each dash as its OWN open polyline, so each gets its own caps.
	[Test]
	public static void ADashPatternStrokesEachDashSeparately()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));
		let pattern = scope float[](10, 10);

		let solid = scope List<VGVertex>();
		let solidIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), false, .Red, solid,
			solidIndices);

		let dashed = scope List<VGVertex>();
		let dashedIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), pattern, false, .Red, dashed,
			dashedIndices);

		Test.Assert(dashed.Count == 5 * 4, "five dashes of four vertices");
		Test.Assert(dashed.Count > solid.Count);
	}

	/// A pattern of ONE is not a dash pattern: it never alternates, so it is ignored and
	/// the stroke is drawn solid in one piece.
	[Test]
	public static void AOneElementPatternIsIgnored()
	{
		let points = scope Float2[](.(0, 0), .(100, 0));

		let solid = scope List<VGVertex>();
		let solidIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), false, .Red, solid,
			solidIndices);

		let single = scope List<VGVertex>();
		let singleIndices = scope List<uint32>();
		StrokeTessellator.Tessellate(points, false, .(2.0f), scope float[](10), false, .Red,
			single, singleIndices);

		Test.Assert(single.Count == solid.Count);
	}

	/// Fewer than two points is not a line.
	[Test]
	public static void ADegenerateStrokeProducesNothing()
	{
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(scope Float2[](.(0, 0)), false, .(2.0f), .(), false, .Red,
			vertices, indices);
		Test.Assert(vertices.IsEmpty);

		StrokeTessellator.Tessellate(.(), false, .(2.0f), .(), true, .Red, vertices, indices);
		Test.Assert(vertices.IsEmpty);
	}

	/// A zero length edge has no direction. It must not produce a NaN position.
	[Test]
	public static void AZeroLengthEdgeProducesFinitePositions()
	{
		let points = scope Float2[](.(0, 0), .(0, 0), .(10, 0));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(points, false, .(2.0f), .(), true, .Red, vertices, indices);

		Test.Assert(!vertices.IsEmpty);
		for (let vertex in vertices)
		{
			Test.Assert(!vertex.Position.X.IsNaN && !vertex.Position.Y.IsNaN);
			Test.Assert(Abs(vertex.Position.X) < 1000.0f);
		}
	}

	/// A very sharp corner would send a miter to infinity. The limit turns it into a flat
	/// cut instead, so nothing escapes the shape.
	[Test]
	public static void ASharpMiterIsClamped()
	{
		// A hairpin: the line doubles almost straight back on itself.
		let hairpin = scope Float2[](.(0, 0), .(100, 0), .(0, 1));
		let vertices = scope List<VGVertex>();
		let indices = scope List<uint32>();

		StrokeTessellator.Tessellate(hairpin, false, .(4.0f, .Butt, .Miter, 4.0f), .(), false,
			.Red, vertices, indices);

		for (let vertex in vertices)
			Test.Assert(Abs(vertex.Position.X) < 200.0f, "no spike off to infinity");
	}
}
