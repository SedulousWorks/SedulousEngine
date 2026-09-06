using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// BoundingFrustum. Raptor has no direct tests for this, and it is the highest-stakes
/// file in the batch: an inverted plane sign culls either everything or nothing, and
/// both look plausible until someone notices the scene is empty.
///
/// The fixture is a camera at the origin looking down -Z with a 90 degree vertical FOV,
/// square aspect, near 1 and far 100. That makes the frustum half-extent equal to the
/// depth, so the expected answers are exact rather than approximate.
class BoundingFrustumTests
{
	private const float cNear = 1.0f;
	private const float cFar = 100.0f;

	private static BoundingFrustum MakeFrustum()
	{
		let proj = Float4x4.PerspectiveFovRH(DegreesToRadians(90.0f), 1.0f, cNear, cFar);
		return .(proj);
	}

	[Test]
	public static void ContainsPointsInsideAndRejectsPointsOutside()
	{
		let f = MakeFrustum();

		// Straight ahead, between the near and far planes.
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -10.0f)) == .Contains);
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -50.0f)) == .Contains);

		// Behind the camera.
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, 10.0f)) == .Disjoint);
		// Nearer than the near plane.
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -0.5f)) == .Disjoint);
		// Beyond the far plane.
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -200.0f)) == .Disjoint);
	}

	/// At 90 degrees and square aspect the half-extent equals the depth, so at z = -10
	/// the frustum spans exactly -10..10 on both axes. That makes the side planes
	/// checkable to the unit rather than by eye.
	[Test]
	public static void SidePlanesAreWhereTheProjectionPutsThem()
	{
		let f = MakeFrustum();

		Test.Assert(f.Contains(Float3(9.0f, 0.0f, -10.0f)) == .Contains);
		Test.Assert(f.Contains(Float3(11.0f, 0.0f, -10.0f)) == .Disjoint);
		Test.Assert(f.Contains(Float3(-9.0f, 0.0f, -10.0f)) == .Contains);
		Test.Assert(f.Contains(Float3(-11.0f, 0.0f, -10.0f)) == .Disjoint);

		Test.Assert(f.Contains(Float3(0.0f, 9.0f, -10.0f)) == .Contains);
		Test.Assert(f.Contains(Float3(0.0f, 11.0f, -10.0f)) == .Disjoint);
		Test.Assert(f.Contains(Float3(0.0f, -9.0f, -10.0f)) == .Contains);
		Test.Assert(f.Contains(Float3(0.0f, -11.0f, -10.0f)) == .Disjoint);

		// The cone widens with depth: what is outside at z = -10 is inside at z = -50.
		Test.Assert(f.Contains(Float3(11.0f, 0.0f, -50.0f)) == .Contains);
	}

	/// The planes point outward, so a point inside is on the negative side of every one.
	/// This is the invariant an inverted extraction breaks, and it breaks it for all six
	/// at once, which is why culling then keeps or discards everything.
	[Test]
	public static void PlanesPointOutward()
	{
		let f = MakeFrustum();
		let inside = Float3(0.0f, 0.0f, -10.0f);

		for (int i < BoundingFrustum.PlaneCount)
			Test.Assert(f.planes[i].SignedDistance(inside) < 0.0f);

		// And the plane normals are unit length after extraction.
		for (int i < BoundingFrustum.PlaneCount)
			Test.Assert(NearlyEqual(Length(f.planes[i].normal), 1.0f, 1.0e-4f));
	}

	/// The eight corners have to be the actual frustum corners: on the near or far
	/// plane, and at the depth-scaled half-extent. A corner solver that paired the wrong
	/// planes still produces eight finite points, so their positions must be checked.
	[Test]
	public static void CornersLieOnTheNearAndFarPlanes()
	{
		let f = MakeFrustum();

		var nearCount = 0;
		var farCount = 0;
		for (int i < BoundingFrustum.CornerCount)
		{
			let c = f.corners[i];
			// Every corner sits on the near or the far plane.
			let onNear = NearlyZero(f.Near.SignedDistance(c), 1.0e-2f);
			let onFar = NearlyZero(f.Far.SignedDistance(c), 1.0e-2f);
			Test.Assert(onNear || onFar);
			if (onNear) nearCount++;
			if (onFar) farCount++;
		}
		Test.Assert(nearCount == 4);
		Test.Assert(farCount == 4);

		// The near corners are at depth 1 with half-extent 1; the far ones at 100.
		for (int i < BoundingFrustum.CornerCount)
		{
			let c = f.corners[i];
			let depth = -c.z;
			Test.Assert(NearlyEqual(Abs(c.x), depth, 1.0e-2f));
			Test.Assert(NearlyEqual(Abs(c.y), depth, 1.0e-2f));
		}
	}

	[Test]
	public static void AgainstSpheres()
	{
		let f = MakeFrustum();

		// Fully inside.
		Test.Assert(Contains(f, BoundingSphere(Float3(0.0f, 0.0f, -10.0f), 1.0f)) == .Contains);
		// Fully outside, behind the camera.
		Test.Assert(Contains(f, BoundingSphere(Float3(0.0f, 0.0f, 50.0f), 1.0f)) == .Disjoint);
		// Straddling the near plane.
		Test.Assert(Contains(f, BoundingSphere(Float3(0.0f, 0.0f, -1.0f), 2.0f)) == .Intersects);

		Test.Assert(Intersects(f, BoundingSphere(Float3(0.0f, 0.0f, -10.0f), 1.0f)));
		Test.Assert(!Intersects(f, BoundingSphere(Float3(0.0f, 0.0f, 50.0f), 1.0f)));
		// The argument order does not matter.
		Test.Assert(Intersects(BoundingSphere(Float3(0.0f, 0.0f, -10.0f), 1.0f), f));
	}

	[Test]
	public static void AgainstBoxes()
	{
		let f = MakeFrustum();

		let inside = AABB(Float3(-1.0f, -1.0f, -11.0f), Float3(1.0f, 1.0f, -9.0f));
		Test.Assert(Contains(f, inside) == .Contains);
		Test.Assert(Intersects(f, inside));

		let behind = AABB(Float3(-1.0f, -1.0f, 9.0f), Float3(1.0f, 1.0f, 11.0f));
		Test.Assert(Contains(f, behind) == .Disjoint);
		Test.Assert(!Intersects(f, behind));

		// Straddling the near plane.
		let straddling = AABB(Float3(-1.0f, -1.0f, -2.0f), Float3(1.0f, 1.0f, 2.0f));
		Test.Assert(Contains(f, straddling) == .Intersects);

		// The argument order does not matter.
		Test.Assert(Intersects(inside, f));
	}

	/// A frustum against itself reports Intersects rather than Contains, because its own
	/// corners lie exactly on its own planes and the corner classification finds some
	/// marginally on each side. That is the honest answer for a boundary-touching case;
	/// what matters is that it is never Disjoint.
	[Test]
	public static void AgainstOtherFrusta()
	{
		let f = MakeFrustum();
		Test.Assert(Contains(f, f) != .Disjoint);
		Test.Assert(Intersects(f, f));

		// A narrower frustum with the same near and far sits inside the wider one.
		let narrow = BoundingFrustum(
			Float4x4.PerspectiveFovRH(DegreesToRadians(45.0f), 1.0f, cNear + 1.0f, cFar - 1.0f));
		Test.Assert(Contains(f, narrow) != .Disjoint);
	}

	[Test]
	public static void AgainstRays()
	{
		let f = MakeFrustum();
		float t = ?;

		// Starting inside is an immediate hit.
		Test.Assert(Intersects(f, Ray(Float3(0.0f, 0.0f, -10.0f), Float3(0.0f, 0.0f, -1.0f)),
			out t));
		Test.Assert(t == 0.0f);

		// From the camera, straight ahead, reaching the near plane.
		Test.Assert(Intersects(f, Ray(Float3.Zero, Float3(0.0f, 0.0f, -1.0f)), out t));

		// Pointing away from the frustum entirely.
		Test.Assert(!Intersects(f, Ray(Float3(0.0f, 0.0f, 10.0f), Float3(0.0f, 0.0f, 1.0f)),
			out t));

		// The argument order does not matter.
		Test.Assert(Intersects(Ray(Float3(0.0f, 0.0f, -10.0f), Float3(0.0f, 0.0f, -1.0f)), f,
			out t));
	}

	[Test]
	public static void BoundingSphereOfAFrustumEnclosesItsCorners()
	{
		let f = MakeFrustum();
		let s = BoundingSphereFromFrustum(f);

		for (int i < BoundingFrustum.CornerCount)
			Test.Assert(LengthSquared(f.corners[i] - s.center) <= s.radius * s.radius + 1.0e-1f);
	}

	/// SetMatrix must replace the previous planes rather than blend with them.
	[Test]
	public static void SetMatrixReplacesTheFrustum()
	{
		var f = MakeFrustum();
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -50.0f)) == .Contains);

		// A much shallower far plane now excludes what used to be inside.
		f.SetMatrix(Float4x4.PerspectiveFovRH(DegreesToRadians(90.0f), 1.0f, 1.0f, 20.0f));
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -50.0f)) == .Disjoint);
		Test.Assert(f.Contains(Float3(0.0f, 0.0f, -10.0f)) == .Contains);
	}
}
