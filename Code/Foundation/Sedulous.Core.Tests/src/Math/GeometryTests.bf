using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// AABB, Plane and Rectangle. Raptor groups these as its "geometry" cases.
class GeometryTests
{
	[Test]
	public static void AabbContainsExpandMerge()
	{
		let bounds = AABB(Float3(0.0f, 0.0f, 0.0f), Float3(2.0f, 2.0f, 2.0f));
		Test.Assert(bounds.Contains(Float3(1.0f, 1.0f, 1.0f)));
		Test.Assert(!bounds.Contains(Float3(3.0f, 1.0f, 1.0f)));
		Test.Assert(NearlyEqual(bounds.Center(), Float3(1.0f, 1.0f, 1.0f)));
		Test.Assert(NearlyEqual(bounds.Extents(), Float3(1.0f, 1.0f, 1.0f)));

		// Built from points, via Empty and Expand.
		var grown = AABB.Empty();
		Test.Assert(!grown.IsValid());
		grown.Expand(Float3(-1.0f, 0.0f, 5.0f));
		grown.Expand(Float3(3.0f, 4.0f, -2.0f));
		Test.Assert(grown.IsValid());
		Test.Assert(NearlyEqual(grown.min, Float3(-1.0f, 0.0f, -2.0f)));
		Test.Assert(NearlyEqual(grown.max, Float3(3.0f, 4.0f, 5.0f)));

		let a = AABB(Float3(0.0f, 0.0f, 0.0f), Float3(1.0f, 1.0f, 1.0f));
		let b = AABB(Float3(2.0f, 2.0f, 2.0f), Float3(3.0f, 3.0f, 3.0f));
		Test.Assert(!a.Intersects(b));

		let m = Merge(a, b);
		Test.Assert(NearlyEqual(m.min, Float3.Zero));
		Test.Assert(NearlyEqual(m.max, Float3(3.0f, 3.0f, 3.0f)));
		Test.Assert(m.Intersects(a));
	}

	/// Containment and intersection are inclusive at the boundary. Raptor tests a point
	/// well inside and one well outside, which a strict comparison would also pass.
	[Test]
	public static void AabbBoundariesAreInclusive()
	{
		let bounds = AABB(Float3.Zero, Float3(2.0f, 2.0f, 2.0f));
		Test.Assert(bounds.Contains(Float3.Zero));                      // the min corner
		Test.Assert(bounds.Contains(Float3(2.0f, 2.0f, 2.0f)));         // the max corner
		Test.Assert(bounds.Contains(Float3(0.0f, 1.0f, 2.0f)));         // on two faces

		// Boxes that merely touch do intersect.
		let touching = AABB(Float3(2.0f, 0.0f, 0.0f), Float3(4.0f, 2.0f, 2.0f));
		Test.Assert(bounds.Intersects(touching));
		Test.Assert(touching.Intersects(bounds));

		// Separated on a single axis is enough to miss.
		let apart = AABB(Float3(2.001f, 0.0f, 0.0f), Float3(4.0f, 2.0f, 2.0f));
		Test.Assert(!bounds.Intersects(apart));
	}

	[Test]
	public static void AabbSizeAndFromCenterExtents()
	{
		let bounds = AABB.FromCenterExtents(Float3(1.0f, 2.0f, 3.0f), Float3(0.5f, 1.0f, 1.5f));
		Test.Assert(NearlyEqual(bounds.min, Float3(0.5f, 1.0f, 1.5f)));
		Test.Assert(NearlyEqual(bounds.max, Float3(1.5f, 3.0f, 4.5f)));
		Test.Assert(NearlyEqual(bounds.Center(), Float3(1.0f, 2.0f, 3.0f)));
		Test.Assert(NearlyEqual(bounds.Size(), Float3(1.0f, 2.0f, 3.0f)));
		Test.Assert(NearlyEqual(bounds.Extents(), Float3(0.5f, 1.0f, 1.5f)));

		// Size is twice the extents, which is the pair most easily confused.
		Test.Assert(NearlyEqual(bounds.Size(), bounds.Extents() * 2.0f));
	}

	/// Merging with an Empty bounds has to leave the other bounds alone, which is what makes
	/// Empty's inverted bounds work as an accumulator seed.
	[Test]
	public static void MergingWithEmptyIsIdentity()
	{
		let real = AABB(Float3(-1.0f, -2.0f, -3.0f), Float3(4.0f, 5.0f, 6.0f));
		let merged = Merge(AABB.Empty(), real);
		Test.Assert(NearlyEqual(merged.min, real.min));
		Test.Assert(NearlyEqual(merged.max, real.max));
	}

	[Test]
	public static void PlaneSignedDistance()
	{
		// The XZ plane at y = 0, normal +Y.
		let plane = Plane.FromPointNormal(Float3.Zero, Float3.UnitY);
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(5.0f, 0.0f, -3.0f)), 0.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 2.0f, 0.0f)), 2.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, -4.0f, 0.0f)), -4.0f));

		let unnormalized = Plane(Float3(0.0f, 3.0f, 0.0f), 0.0f);
		Test.Assert(NearlyEqual(Length(unnormalized.Normalized().normal), 1.0f));
	}

	/// Raptor's plane passes through the origin, so d is zero and an implementation that
	/// dropped the point term entirely would pass. This one is offset.
	[Test]
	public static void PlaneThroughAnOffsetPoint()
	{
		let plane = Plane.FromPointNormal(Float3(0.0f, 5.0f, 0.0f), Float3.UnitY);
		Test.Assert(NearlyEqual(plane.d, -5.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 5.0f, 0.0f)), 0.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 7.0f, 0.0f)), 2.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 1.0f, 0.0f)), -4.0f));

		// Normalizing an already-unit plane changes nothing.
		let n = plane.Normalized();
		Test.Assert(NearlyEqual(n.normal, plane.normal));
		Test.Assert(NearlyEqual(n.d, plane.d));

		// A degenerate normal is returned unchanged rather than producing infinities.
		let degenerate = Plane(Float3.Zero, 3.0f);
		Test.Assert(NearlyEqual(degenerate.Normalized().normal, Float3.Zero));
		Test.Assert(NearlyEqual(degenerate.Normalized().d, 3.0f));
	}

	/// Normalizing has to scale d as well as the normal. Raptor's case uses d = 0 and
	/// the offset case above already has a unit normal, so in both of them scaling d is
	/// a no-op: an implementation that left d alone passes. This one has a non-unit
	/// normal and a non-zero d, so the plane it describes only stays put if both scale.
	[Test]
	public static void PlaneNormalizedScalesDistanceToo()
	{
		// 3y + 6 = 0, which is the plane y = -2 with a normal of length 3.
		let unnormalized = Plane(Float3(0.0f, 3.0f, 0.0f), 6.0f);
		let n = unnormalized.Normalized();

		Test.Assert(NearlyEqual(Length(n.normal), 1.0f));
		Test.Assert(NearlyEqual(n.d, 2.0f));

		// Same plane: the point y = -2 is still on it.
		Test.Assert(NearlyEqual(n.SignedDistance(Float3(0.0f, -2.0f, 0.0f)), 0.0f));
		// And distances are now in world units rather than scaled by the normal length.
		Test.Assert(NearlyEqual(n.SignedDistance(Float3.Zero), 2.0f));
		Test.Assert(NearlyEqual(n.SignedDistance(Float3(0.0f, -5.0f, 0.0f)), -3.0f));
	}

	[Test]
	public static void RectangleContainsAndIntersects()
	{
		let r = Rectangle(0.0f, 0.0f, 4.0f, 2.0f);
		Test.Assert(r.Contains(Float2(2.0f, 1.0f)));
		Test.Assert(!r.Contains(Float2(5.0f, 1.0f)));
		Test.Assert(NearlyEqual(r.Center(), Float2(2.0f, 1.0f)));

		Test.Assert(r.Intersects(Rectangle(3.0f, 1.0f, 2.0f, 2.0f)));
		Test.Assert(!r.Intersects(Rectangle(10.0f, 10.0f, 1.0f, 1.0f)));
	}

	/// Contains is inclusive on all four edges. Raptor checks one inside point and one
	/// far outside, so a half-open rectangle would pass its case and differ here.
	[Test]
	public static void RectangleEdgesAreInclusive()
	{
		let r = Rectangle(0.0f, 0.0f, 4.0f, 2.0f);
		Test.Assert(r.Contains(Float2(0.0f, 0.0f)));   // min corner
		Test.Assert(r.Contains(Float2(4.0f, 2.0f)));   // max corner
		Test.Assert(r.Contains(Float2(4.0f, 1.0f)));   // right edge
		Test.Assert(r.Contains(Float2(2.0f, 0.0f)));   // bottom edge
		Test.Assert(!r.Contains(Float2(4.001f, 1.0f)));
		Test.Assert(!r.Contains(Float2(-0.001f, 1.0f)));

		Test.Assert(NearlyEqual(r.Min(), Float2(0.0f, 0.0f)));
		Test.Assert(NearlyEqual(r.Max(), Float2(4.0f, 2.0f)));

		// Rectangles that share an edge intersect.
		Test.Assert(r.Intersects(Rectangle(4.0f, 0.0f, 1.0f, 2.0f)));
	}

	/// Rectangle.Intersect, the overlap rectangle, is not covered by Raptor at all.
	[Test]
	public static void RectangleIntersectComputesTheOverlap()
	{
		let a = Rectangle(0.0f, 0.0f, 4.0f, 4.0f);

		// Partial overlap in both axes.
		let partial = Rectangle.Intersect(a, Rectangle(2.0f, 1.0f, 4.0f, 2.0f));
		Test.Assert(NearlyEqual(partial.x, 2.0f) && NearlyEqual(partial.y, 1.0f));
		Test.Assert(NearlyEqual(partial.width, 2.0f) && NearlyEqual(partial.height, 2.0f));

		// Order does not matter.
		let flipped = Rectangle.Intersect(Rectangle(2.0f, 1.0f, 4.0f, 2.0f), a);
		Test.Assert(NearlyEqual(flipped.x, partial.x) && NearlyEqual(flipped.width, partial.width));

		// One containing the other yields the inner rectangle.
		let inner = Rectangle(1.0f, 1.0f, 2.0f, 2.0f);
		let contained = Rectangle.Intersect(a, inner);
		Test.Assert(NearlyEqual(contained.x, 1.0f) && NearlyEqual(contained.width, 2.0f));

		// Disjoint yields zero size rather than a negative one, on each axis
		// independently: overlapping in x but not y still has to come out empty.
		let disjoint = Rectangle.Intersect(a, Rectangle(10.0f, 10.0f, 1.0f, 1.0f));
		Test.Assert(disjoint.width == 0.0f);
		Test.Assert(disjoint.height == 0.0f);

		let sameXOnly = Rectangle.Intersect(a, Rectangle(1.0f, 10.0f, 2.0f, 1.0f));
		Test.Assert(sameXOnly.height == 0.0f);

		// Touching along an edge overlaps in zero width, not negative.
		let touching = Rectangle.Intersect(a, Rectangle(4.0f, 0.0f, 2.0f, 4.0f));
		Test.Assert(touching.width == 0.0f);
		Test.Assert(NearlyEqual(touching.height, 4.0f));
	}
}
