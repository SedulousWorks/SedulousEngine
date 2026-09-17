using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// Ear clipping, and the fan fast path for convex polygons.
class TriangulatorTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The signed area of the triangles an index list describes.
	private static float TriangulatedArea(Span<Float2> contour, List<uint32> indices)
	{
		var total = 0.0f;
		for (int i = 0; i < indices.Count; i += 3)
		{
			let a = contour[(int)indices[i]];
			let b = contour[(int)indices[i + 1]];
			let c = contour[(int)indices[i + 2]];
			total += (((b.X - a.X) * (c.Y - a.Y)) - ((c.X - a.X) * (b.Y - a.Y))) * 0.5f;
		}
		return total;
	}

	/// Positive counter clockwise, negative clockwise. Everything downstream reads the
	/// sign, so this is the thing that must not drift.
	[Test]
	public static void TheAreaSignFollowsTheWinding()
	{
		let counterClockwise = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		Test.Assert(Near(Triangulator.PolygonArea(counterClockwise), 100.0f));

		let clockwise = scope Float2[](.(0, 10), .(10, 10), .(10, 0), .(0, 0));
		Test.Assert(Near(Triangulator.PolygonArea(clockwise), -100.0f));
	}

	/// The boundary counts as inside: a vertex sitting exactly on an ear's edge still
	/// blocks the clip, because cutting it would strand that vertex outside.
	[Test]
	public static void PointInTriangleIncludesTheBoundary()
	{
		let a = Float2(0, 0);
		let b = Float2(10, 0);
		let c = Float2(0, 10);

		Test.Assert(Triangulator.PointInTriangle(.(1, 1), a, b, c));
		Test.Assert(Triangulator.PointInTriangle(.(5, 0), a, b, c), "on an edge");
		Test.Assert(Triangulator.PointInTriangle(a, a, b, c), "on a vertex");
		Test.Assert(!Triangulator.PointInTriangle(.(6, 6), a, b, c));
		Test.Assert(!Triangulator.PointInTriangle(.(-1, 1), a, b, c));
	}

	[Test]
	public static void AConvexPolygonBecomesAFan()
	{
		let square = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let indices = scope List<uint32>();
		Triangulator.Triangulate(square, .NonZero, indices);

		Test.Assert(indices.Count == 6, "four points, two triangles");
		Test.Assert(Near(TriangulatedArea(square, indices), 100.0f), "the whole square, once");
	}

	/// Whatever the input winding, the triangles come out facing the same way. Otherwise
	/// half the shapes in a scene would be backface culled.
	[Test]
	public static void TheOutputWindingIsConsistentWhicheverWayTheInputWound()
	{
		let counterClockwise = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));
		let clockwise = scope Float2[](.(0, 10), .(10, 10), .(10, 0), .(0, 0));

		let a = scope List<uint32>();
		Triangulator.Triangulate(counterClockwise, .NonZero, a);
		let b = scope List<uint32>();
		Triangulator.Triangulate(clockwise, .NonZero, b);

		Test.Assert(TriangulatedArea(counterClockwise, a) > 0.0f);
		Test.Assert(TriangulatedArea(clockwise, b) > 0.0f, "reversed back to match");
	}

	/// A concave polygon takes the ear clipping path and still covers exactly its own area.
	[Test]
	public static void AConcavePolygonIsFullyCovered()
	{
		// An L shape: area 100 minus the 25 bitten out of the corner.
		let shape = scope Float2[](
			.(0, 0), .(10, 0), .(10, 5), .(5, 5), .(5, 10), .(0, 10));

		let indices = scope List<uint32>();
		Triangulator.Triangulate(shape, .NonZero, indices);

		Test.Assert(indices.Count == 12, "six points, four triangles");
		Test.Assert(Near(TriangulatedArea(shape, indices), 75.0f));
	}

	/// A deeply concave shape still resolves rather than falling back to the fan.
	[Test]
	public static void AStarIsTriangulatedWithoutOverlap()
	{
		let builder = scope PathBuilder();
		ShapeBuilder.BuildStar(.(0, 0), 10, 4, 5, builder);
		let path = builder.ToPath();
		defer delete path;

		let subPaths = scope List<FlattenedSubPath>();
		defer { ClearAndDeleteItems!(subPaths); }
		PathFlattener.Flatten(path, 0.25f, subPaths);

		let points = subPaths[0].Points;
		let indices = scope List<uint32>();
		Triangulator.Triangulate(points, .NonZero, indices);

		Test.Assert(indices.Count == (points.Count - 2) * 3, "n minus two triangles");
		let expected = Abs(Triangulator.PolygonArea(points));
		Test.Assert(Near(Abs(TriangulatedArea(points, indices)), expected, 0.1f));
	}

	/// Fewer than three points is not a polygon.
	[Test]
	public static void ADegenerateContourProducesNoTriangles()
	{
		let indices = scope List<uint32>();
		Triangulator.Triangulate(scope Float2[](.(0, 0), .(1, 1)), .NonZero, indices);
		Test.Assert(indices.IsEmpty);

		Triangulator.Triangulate(.(), .NonZero, indices);
		Test.Assert(indices.IsEmpty);
	}

	/// A self intersecting polygon has no valid ear decomposition. It must still terminate
	/// and produce something bounded rather than looping or dropping the shape.
	[Test]
	public static void ASelfIntersectingPolygonStillTerminates()
	{
		// A bowtie: the two edges cross in the middle.
		let bowtie = scope Float2[](.(0, 0), .(10, 10), .(10, 0), .(0, 10));

		let indices = scope List<uint32>();
		Triangulator.Triangulate(bowtie, .NonZero, indices);

		Test.Assert(!indices.IsEmpty, "the shape is not dropped");
		Test.Assert(indices.Count <= (bowtie.Count - 2) * 3);
		for (let index in indices)
			Test.Assert(index < (uint32)bowtie.Count, "every index is in range");
	}

	/// The base index offsets everything, so several contours can share one vertex buffer.
	[Test]
	public static void TheBaseIndexOffsetsEveryIndex()
	{
		let square = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));

		let indices = scope List<uint32>();
		Triangulator.Triangulate(square, .NonZero, indices, 100);

		for (let index in indices)
			Test.Assert((index >= 100) && (index < 104));
	}

	// ---- holes ----

	/// A hole is bridged into the outer contour, so the merged result covers the outer area
	/// minus the hole's.
	[Test]
	public static void AHoleIsCutOutOfTheOuterContour()
	{
		let outer = scope Float2[](.(0, 0), .(20, 0), .(20, 20), .(0, 20));
		// Wound the other way, which is how a hole states that it is one.
		let hole = scope Float2[](.(5, 5), .(5, 15), .(15, 15), .(15, 5));
		let holes = scope Span<Float2>[](hole);

		let indices = scope List<uint32>();
		let merged = scope List<Float2>();
		Triangulator.TriangulateWithHoles(outer, holes, .EvenOdd, indices, merged);

		Test.Assert(!indices.IsEmpty);
		// Bridging INTRODUCES vertices: the corridor visits two points twice.
		Test.Assert(merged.Count > (outer.Count + hole.Count));

		let area = Abs(TriangulatedArea(merged, indices));
		Test.Assert(Near(area, 300.0f, 1.0f), "four hundred less the hundred cut out");
	}

	/// With no holes it is the plain path, and the merged vertices are just the contour.
	[Test]
	public static void NoHolesIsThePlainPath()
	{
		let outer = scope Float2[](.(0, 0), .(10, 0), .(10, 10), .(0, 10));

		let indices = scope List<uint32>();
		let merged = scope List<Float2>();
		Triangulator.TriangulateWithHoles(outer, .(), .NonZero, indices, merged);

		Test.Assert(merged.Count == outer.Count);
		Test.Assert(Near(Abs(TriangulatedArea(merged, indices)), 100.0f));
	}

	/// Several holes each get their own bridge, cut rightmost first so a later one still
	/// has an unbroken path out.
	[Test]
	public static void SeveralHolesAreEachBridged()
	{
		let outer = scope Float2[](.(0, 0), .(30, 0), .(30, 20), .(0, 20));
		let left = scope Float2[](.(2, 5), .(2, 15), .(8, 15), .(8, 5));
		let right = scope Float2[](.(20, 5), .(20, 15), .(28, 15), .(28, 5));
		let holes = scope Span<Float2>[](left, right);

		let indices = scope List<uint32>();
		let merged = scope List<Float2>();
		Triangulator.TriangulateWithHoles(outer, holes, .EvenOdd, indices, merged);

		Test.Assert(!indices.IsEmpty);
		let area = Abs(TriangulatedArea(merged, indices));
		Test.Assert(Near(area, 600.0f - 60.0f - 80.0f, 2.0f));
	}

	/// A contour too small to be a polygon is refused before anything is merged.
	[Test]
	public static void ADegenerateOuterContourIsRefused()
	{
		let indices = scope List<uint32>();
		let merged = scope List<Float2>();
		Triangulator.TriangulateWithHoles(scope Float2[](.(0, 0), .(1, 1)), .(), .NonZero,
			indices, merged);

		Test.Assert(indices.IsEmpty);
		Test.Assert(merged.IsEmpty);
	}
}
