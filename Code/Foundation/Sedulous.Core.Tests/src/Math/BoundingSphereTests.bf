using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// BoundingSphere. Raptor has no direct tests for this.
class BoundingSphereTests
{
	[Test]
	public static void ContainsAndPlaneSide()
	{
		let s = BoundingSphere(Float3.Zero, 2.0f);
		Test.Assert(s.Contains(Float3.Zero) == .Contains);
		Test.Assert(s.Contains(Float3(1.0f, 0.0f, 0.0f)) == .Contains);
		Test.Assert(s.Contains(Float3(3.0f, 0.0f, 0.0f)) == .Disjoint);
		// The test is strict, so a point exactly on the surface is not contained.
		Test.Assert(s.Contains(Float3(2.0f, 0.0f, 0.0f)) == .Disjoint);

		// A plane well clear on the normal side leaves the sphere in front.
		let plane = Plane.FromPointNormal(Float3(0.0f, -5.0f, 0.0f), Float3.UnitY);
		Test.Assert(s.Intersects(plane) == .Front);

		// Well clear on the other side puts it behind.
		let above = Plane.FromPointNormal(Float3(0.0f, 5.0f, 0.0f), Float3.UnitY);
		Test.Assert(s.Intersects(above) == .Back);

		// Through the middle it straddles.
		let through = Plane.FromPointNormal(Float3.Zero, Float3.UnitY);
		Test.Assert(s.Intersects(through) == .Intersecting);

		// Exactly tangent counts as intersecting, since the test is not strict there.
		let tangent = Plane.FromPointNormal(Float3(0.0f, 2.0f, 0.0f), Float3.UnitY);
		Test.Assert(tangent.SignedDistance(s.Center) == -2.0f);
		Test.Assert(s.Intersects(tangent) == .Intersecting);
	}

	[Test]
	public static void MergeEnclosesBoth()
	{
		let a = BoundingSphere(Float3(-1.0f, 0.0f, 0.0f), 1.0f);
		let b = BoundingSphere(Float3(1.0f, 0.0f, 0.0f), 1.0f);
		let m = BoundingSphere.Merge(a, b);

		// Spanning -2..2 on x, so centred at the origin with radius 2.
		Test.Assert(NearlyEqual(m.Center, Float3.Zero, 1.0e-4f));
		Test.Assert(NearlyEqual(m.Radius, 2.0f, 1.0e-4f));

		// The result encloses both originals.
		Test.Assert(Contains(m, a) == .Contains);
		Test.Assert(Contains(m, b) == .Contains);
	}

	/// When one sphere already swallows the other, Merge returns the larger untouched
	/// rather than growing it. Both orders are checked, since the two early exits are
	/// separate branches.
	[Test]
	public static void MergeWithAContainedSphereReturnsTheLarger()
	{
		let big = BoundingSphere(Float3.Zero, 10.0f);
		let small = BoundingSphere(Float3(1.0f, 0.0f, 0.0f), 1.0f);

		let m1 = BoundingSphere.Merge(big, small);
		Test.Assert(NearlyEqual(m1.Radius, 10.0f));
		Test.Assert(NearlyEqual(m1.Center, big.Center));

		let m2 = BoundingSphere.Merge(small, big);
		Test.Assert(NearlyEqual(m2.Radius, 10.0f));
		Test.Assert(NearlyEqual(m2.Center, big.Center));

		// Concentric and identical is one degenerate case, where the distance is zero.
		let same = BoundingSphere.Merge(big, big);
		Test.Assert(NearlyEqual(same.Radius, 10.0f));

		// Concentric with DIFFERENT radii is the case the first shortcut exists for.
		// Identical radii are caught by the second one, so only this reaches the first,
		// and without it the general formula divides by a zero distance and yields NaN.
		let concentric = BoundingSphere.Merge(big, BoundingSphere(Float3.Zero, 1.0f));
		Test.Assert(concentric.Radius == concentric.Radius);   // not NaN
		Test.Assert(NearlyEqual(concentric.Radius, 10.0f));
		Test.Assert(NearlyEqual(concentric.Center, Float3.Zero));

		let concentricFlipped = BoundingSphere.Merge(BoundingSphere(Float3.Zero, 1.0f), big);
		Test.Assert(NearlyEqual(concentricFlipped.Radius, 10.0f));
	}

	[Test]
	public static void FromPointsEnclosesThemAll()
	{
		Float3[?] pts = .(
			Float3(-5.0f, 0.0f, 0.0f), Float3(5.0f, 0.0f, 0.0f),
			Float3(0.0f, -3.0f, 0.0f), Float3(0.0f, 3.0f, 0.0f),
			Float3(0.0f, 0.0f, -1.0f), Float3(0.0f, 0.0f, 1.0f));

		var points = pts;
		let s = BoundingSphere.FromPoints(Span<Float3>(&points[0], points.Count));

		// Every point is inside, allowing for the surface being exclusive.
		for (let p in pts)
			Test.Assert(LengthSquared(p - s.Center) <= s.Radius * s.Radius + 1.0e-3f);

		// X is the widest spread, so the sphere is driven by it.
		Test.Assert(s.Radius >= 5.0f - 1.0e-3f);

		// Empty gives a zero sphere rather than reading past the end.
		Float3[1] none = ?;
		Test.Assert(BoundingSphere.FromPoints(Span<Float3>(&none[0], 0)).Radius == 0.0f);
	}

	/// FromPoints picks its starting axis from the widest spread, so a point set that is
	/// widest in Y or Z takes a different branch from one widest in X.
	[Test]
	public static void FromPointsHandlesEachDominantAxis()
	{
		Float3[?] wideY = .(
			Float3(0.0f, -8.0f, 0.0f), Float3(0.0f, 8.0f, 0.0f),
			Float3(-1.0f, 0.0f, 0.0f), Float3(1.0f, 0.0f, 0.0f));
		Float3[?] wideZ = .(
			Float3(0.0f, 0.0f, -8.0f), Float3(0.0f, 0.0f, 8.0f),
			Float3(-1.0f, 0.0f, 0.0f), Float3(1.0f, 0.0f, 0.0f));

		var y = wideY;
		let sy = BoundingSphere.FromPoints(Span<Float3>(&y[0], y.Count));
		Test.Assert(sy.Radius >= 8.0f - 1.0e-3f);
		for (let p in wideY)
			Test.Assert(LengthSquared(p - sy.Center) <= sy.Radius * sy.Radius + 1.0e-3f);

		var z = wideZ;
		let sz = BoundingSphere.FromPoints(Span<Float3>(&z[0], z.Count));
		Test.Assert(sz.Radius >= 8.0f - 1.0e-3f);
		for (let p in wideZ)
			Test.Assert(LengthSquared(p - sz.Center) <= sz.Radius * sz.Radius + 1.0e-3f);
	}

	[Test]
	public static void ExpandGrowsOnlyWhenNeeded()
	{
		var s = BoundingSphere(Float3.Zero, 1.0f);

		// A point already inside changes nothing.
		s.Expand(Float3(0.5f, 0.0f, 0.0f));
		Test.Assert(NearlyEqual(s.Radius, 1.0f));
		Test.Assert(NearlyEqual(s.Center, Float3.Zero));

		// A point outside grows the sphere just enough to reach it.
		s.Expand(Float3(3.0f, 0.0f, 0.0f));
		Test.Assert(s.Radius >= 2.0f - 1.0e-4f);
		Test.Assert(LengthSquared(Float3(3.0f, 0.0f, 0.0f) - s.Center)
			<= s.Radius * s.Radius + 1.0e-3f);
		// And the original extent is still enclosed.
		Test.Assert(LengthSquared(Float3(-1.0f, 0.0f, 0.0f) - s.Center)
			<= s.Radius * s.Radius + 1.0e-3f);
	}

	[Test]
	public static void SphereAgainstSphere()
	{
		let a = BoundingSphere(Float3.Zero, 2.0f);

		Test.Assert(Intersects(a, BoundingSphere(Float3(3.0f, 0.0f, 0.0f), 2.0f)));
		Test.Assert(!Intersects(a, BoundingSphere(Float3(10.0f, 0.0f, 0.0f), 2.0f)));
		// Exactly touching counts as intersecting.
		Test.Assert(Intersects(a, BoundingSphere(Float3(4.0f, 0.0f, 0.0f), 2.0f)));

		Test.Assert(Contains(a, BoundingSphere(Float3.Zero, 1.0f)) == .Contains);
		Test.Assert(Contains(a, BoundingSphere(Float3(3.0f, 0.0f, 0.0f), 2.0f)) == .Intersects);
		Test.Assert(Contains(a, BoundingSphere(Float3(10.0f, 0.0f, 0.0f), 1.0f)) == .Disjoint);
	}
}
