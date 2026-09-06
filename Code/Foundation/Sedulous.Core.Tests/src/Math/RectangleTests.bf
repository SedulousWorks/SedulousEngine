using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Rectangles. Raptor covers these in its "geometry: Rectangle contains and
/// intersects" case; Rectangle.Intersect it does not cover at all.
class RectangleTests
{
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
