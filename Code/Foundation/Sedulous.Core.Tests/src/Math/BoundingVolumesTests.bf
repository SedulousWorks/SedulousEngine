using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// The cross-type bounding volume tests that do not belong to a single type: AABB
/// against planes and spheres, TransformAABB, GetCorners, and the ContainmentType forms.
class BoundingVolumesTests
{
	[Test]
	public static void ApproxHelpers()
	{
		Test.Assert(ApproxZero(0.0f));
		Test.Assert(ApproxZero(1.0e-8f));
		Test.Assert(!ApproxZero(1.0e-6f));
		Test.Assert(ApproxNonZero(1.0e-6f));
		Test.Assert(!ApproxNonZero(1.0e-8f));

		// Exact equality counts as greater; otherwise it needs a real gap AND the order.
		Test.Assert(ApproxGreater(1.0f, 1.0f));
		Test.Assert(ApproxGreater(2.0f, 1.0f));
		Test.Assert(!ApproxGreater(1.0f, 2.0f));
		// Greater, but by less than the tolerance, does not count. This has to be tried
		// at a small magnitude: the next float above 1.0 is about 1.19e-7 away, which is
		// already larger than the 1e-7 tolerance, so at magnitude 1 the case cannot be
		// expressed at all. At 1e-3 the spacing is about 1.2e-10 and a 1e-8 gap is real.
		Test.Assert(0.001f + 1.0e-8f != 0.001f);
		Test.Assert(!ApproxGreater(0.001f + 1.0e-8f, 0.001f));
		// A gap above the tolerance does count.
		Test.Assert(ApproxGreater(0.001f + 1.0e-6f, 0.001f));
	}

	[Test]
	public static void ClampVecIsComponentWise()
	{
		let lo = Float3(-1.0f, -1.0f, -1.0f);
		let hi = Float3(1.0f, 1.0f, 1.0f);

		Test.Assert(NearlyEqual(ClampVec(Float3(0.0f, 0.0f, 0.0f), lo, hi), Float3.Zero));
		Test.Assert(NearlyEqual(ClampVec(Float3(5.0f, -5.0f, 0.5f), lo, hi),
			Float3(1.0f, -1.0f, 0.5f)));
	}

	[Test]
	public static void BoxAgainstPlane()
	{
		let b = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));

		// A plane well below, normal up: the box is entirely in front.
		Test.Assert(Intersects(b, Plane.FromPointNormal(Float3(0.0f, -5.0f, 0.0f), Float3.UnitY))
			== .Front);
		// Well above: entirely behind.
		Test.Assert(Intersects(b, Plane.FromPointNormal(Float3(0.0f, 5.0f, 0.0f), Float3.UnitY))
			== .Back);
		// Through the middle: straddling.
		Test.Assert(Intersects(b, Plane.FromPointNormal(Float3.Zero, Float3.UnitY))
			== .Intersecting);

		// A diagonal normal exercises the per-axis corner selection rather than one axis.
		let diagonal = Plane.FromPointNormal(Float3(2.0f, 2.0f, 2.0f),
			Normalized(Float3(1.0f, 1.0f, 1.0f)));
		Test.Assert(Intersects(b, diagonal) == .Back);
	}

	/// The per-axis corner selection is invisible on a symmetric box: swapping min for
	/// max on an axis gives the same answer when the box is centred on the origin. This
	/// uses an asymmetric box and a normal dominated by that axis, where picking the
	/// wrong corner changes the verdict.
	[Test]
	public static void BoxAgainstPlanePicksThePerAxisCorner()
	{
		// Far from the origin on x, and thin, so the two candidate corners are far apart
		// relative to the plane's distance.
		let b = AABB(Float3(10.0f, -1.0f, -1.0f), Float3(20.0f, 1.0f, 1.0f));

		// A plane at x = 15 with normal +X cuts the box, and only the correct corner
		// pair reports that.
		let cutting = Plane.FromPointNormal(Float3(15.0f, 0.0f, 0.0f), Float3.UnitX);
		Test.Assert(Intersects(b, cutting) == .Intersecting);

		// Just clear of the near face: the whole box is in front.
		let beforeIt = Plane.FromPointNormal(Float3(9.0f, 0.0f, 0.0f), Float3.UnitX);
		Test.Assert(Intersects(b, beforeIt) == .Front);

		// Just clear of the far face: the whole box is behind.
		let afterIt = Plane.FromPointNormal(Float3(21.0f, 0.0f, 0.0f), Float3.UnitX);
		Test.Assert(Intersects(b, afterIt) == .Back);

		// And with the normal reversed, front and back swap.
		let reversed = Plane.FromPointNormal(Float3(9.0f, 0.0f, 0.0f), -Float3.UnitX);
		Test.Assert(Intersects(b, reversed) == .Back);
	}

	[Test]
	public static void BoxAgainstSphere()
	{
		let b = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));

		Test.Assert(Intersects(b, BoundingSphere(Float3.Zero, 0.5f)));
		Test.Assert(Intersects(b, BoundingSphere(Float3(2.0f, 0.0f, 0.0f), 1.5f)));
		Test.Assert(!Intersects(b, BoundingSphere(Float3(5.0f, 0.0f, 0.0f), 1.0f)));
		// Exactly touching counts.
		Test.Assert(Intersects(b, BoundingSphere(Float3(2.0f, 0.0f, 0.0f), 1.0f)));
		// The argument order does not matter.
		Test.Assert(Intersects(BoundingSphere(Float3.Zero, 0.5f), b));

		// A sphere nearest a corner rather than a face is what the clamp is for: it sits
		// sqrt(3) from the corner along the diagonal, so a per-axis test would be wrong.
		let cornerward = BoundingSphere(Float3(2.0f, 2.0f, 2.0f), 1.0f);
		Test.Assert(!Intersects(b, cornerward));
		Test.Assert(Intersects(b, BoundingSphere(Float3(2.0f, 2.0f, 2.0f), 1.8f)));
	}

	[Test]
	public static void ContainmentTypeForms()
	{
		let b = AABB(Float3(-2.0f, -2.0f, -2.0f), Float3(2.0f, 2.0f, 2.0f));

		Test.Assert(ContainsCT(b, Float3.Zero) == .Contains);
		Test.Assert(ContainsCT(b, Float3(5.0f, 0.0f, 0.0f)) == .Disjoint);

		Test.Assert(ContainsCT(b, BoundingSphere(Float3.Zero, 0.5f)) == .Contains);
		Test.Assert(ContainsCT(b, BoundingSphere(Float3(1.9f, 0.0f, 0.0f), 0.5f)) == .Intersects);
		Test.Assert(ContainsCT(b, BoundingSphere(Float3(10.0f, 0.0f, 0.0f), 0.5f)) == .Disjoint);

		Test.Assert(ContainsCT(b, AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f)))
			== .Contains);
		Test.Assert(ContainsCT(b, AABB(Float3(1.0f, 1.0f, 1.0f), Float3(5.0f, 5.0f, 5.0f)))
			== .Intersects);
		Test.Assert(ContainsCT(b, AABB(Float3(10.0f, 10.0f, 10.0f), Float3(12.0f, 12.0f, 12.0f)))
			== .Disjoint);
	}

	[Test]
	public static void SphereContainsBox()
	{
		let b = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));

		// A sphere enclosing every corner, which are at distance sqrt(3).
		Test.Assert(Contains(BoundingSphere(Float3.Zero, 2.0f), b) == .Contains);
		// One reaching the faces but not the corners.
		Test.Assert(Contains(BoundingSphere(Float3.Zero, 1.2f), b) == .Intersects);
		// One nowhere near.
		Test.Assert(Contains(BoundingSphere(Float3(10.0f, 0.0f, 0.0f), 1.0f), b) == .Disjoint);
	}

	[Test]
	public static void CornersAndSphereBox()
	{
		let b = AABB(Float3(-1.0f, -2.0f, -3.0f), Float3(1.0f, 2.0f, 3.0f));
		Float3[8] corners = ?;
		GetCorners(b, ref corners);

		// Sedulous's order: index 0 is (min.x, max.y, max.z), index 7 is all min.
		Test.Assert(NearlyEqual(corners[0], Float3(-1.0f, 2.0f, 3.0f)));
		Test.Assert(NearlyEqual(corners[7], Float3(-1.0f, -2.0f, -3.0f)));
		Test.Assert(NearlyEqual(corners[1], Float3(1.0f, 2.0f, 3.0f)));

		// All eight are distinct and inside the box.
		for (int i < 8)
		{
			Test.Assert(b.Contains(corners[i]));
			for (int j = i + 1; j < 8; j++)
				Test.Assert(!(corners[i] == corners[j]));
		}

		// A sphere's bounding box is the cube around it.
		let fromSphere = BoundingBoxFromSphere(BoundingSphere(Float3(1.0f, 2.0f, 3.0f), 2.0f));
		Test.Assert(NearlyEqual(fromSphere.min, Float3(-1.0f, 0.0f, 1.0f)));
		Test.Assert(NearlyEqual(fromSphere.max, Float3(3.0f, 4.0f, 5.0f)));
	}

	[Test]
	public static void TransformAABBFollowsTranslationAndScale()
	{
		let b = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));

		let translated = TransformAABB(b, Float4x4.Translation(Float3(10.0f, 0.0f, 0.0f)));
		Test.Assert(NearlyEqual(translated.min, Float3(9.0f, -1.0f, -1.0f)));
		Test.Assert(NearlyEqual(translated.max, Float3(11.0f, 1.0f, 1.0f)));

		let scaled = TransformAABB(b, Float4x4.Scale(Float3(2.0f, 3.0f, 4.0f)));
		Test.Assert(NearlyEqual(scaled.min, Float3(-2.0f, -3.0f, -4.0f)));
		Test.Assert(NearlyEqual(scaled.max, Float3(2.0f, 3.0f, 4.0f)));
	}

	/// Rotating an axis-aligned box gives a larger axis-aligned box, because the result
	/// must enclose the rotated original. 45 degrees about Z grows the x and y extent by
	/// sqrt(2) and leaves z alone, which the absolute row sums are what produce.
	[Test]
	public static void TransformAABBGrowsUnderRotation()
	{
		let b = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));
		let rotated = TransformAABB(b, Float4x4.RotationZ(DegreesToRadians(45.0f)));

		let root2 = Sqrt(2.0f);
		Test.Assert(NearlyEqual(rotated.max.x, root2, 1.0e-4f));
		Test.Assert(NearlyEqual(rotated.max.y, root2, 1.0e-4f));
		Test.Assert(NearlyEqual(rotated.max.z, 1.0f, 1.0e-4f));

		// A quarter turn maps the box onto itself, so the bound does not grow.
		let quarter = TransformAABB(b, Float4x4.RotationZ(DegreesToRadians(90.0f)));
		Test.Assert(NearlyEqual(quarter.max, Float3(1.0f, 1.0f, 1.0f), 1.0e-4f));

		// The result always encloses the transformed corners.
		let m = Float4x4.RotationZ(DegreesToRadians(30.0f))
			* Float4x4.Translation(Float3(5.0f, 0.0f, 0.0f));
		let general = TransformAABB(b, m);
		Float3[8] corners = ?;
		GetCorners(b, ref corners);
		for (int i < 8)
			Test.Assert(general.Contains(TransformPoint(corners[i], m)));
	}
}
