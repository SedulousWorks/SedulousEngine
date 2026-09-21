using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Axis-aligned bounding boxes: contains, expand, merge.
class AABBTests
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
		Test.Assert(NearlyEqual(grown.Min, Float3(-1.0f, 0.0f, -2.0f)));
		Test.Assert(NearlyEqual(grown.Max, Float3(3.0f, 4.0f, 5.0f)));

		let a = AABB(Float3(0.0f, 0.0f, 0.0f), Float3(1.0f, 1.0f, 1.0f));
		let b = AABB(Float3(2.0f, 2.0f, 2.0f), Float3(3.0f, 3.0f, 3.0f));
		Test.Assert(!a.Intersects(b));

		let m = Merge(a, b);
		Test.Assert(NearlyEqual(m.Min, Float3.Zero));
		Test.Assert(NearlyEqual(m.Max, Float3(3.0f, 3.0f, 3.0f)));
		Test.Assert(m.Intersects(a));
	}

	/// Containment and intersection are inclusive at the boundary. A point well inside and
	/// one well outside would not tell, since a strict comparison also passes those.
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
		Test.Assert(NearlyEqual(bounds.Min, Float3(0.5f, 1.0f, 1.5f)));
		Test.Assert(NearlyEqual(bounds.Max, Float3(1.5f, 3.0f, 4.5f)));
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
		Test.Assert(NearlyEqual(merged.Min, real.Min));
		Test.Assert(NearlyEqual(merged.Max, real.Max));
	}
}
