using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Ray and its intersections. Raptor has no direct tests for any of this.
class RayTests
{
	[Test]
	public static void Interpolate()
	{
		let a = Ray(Float3.Zero, Float3.UnitX);
		let b = Ray(Float3(10.0f, 0.0f, 0.0f), Float3.UnitY);

		let mid = a.Interpolate(b, 0.5f);
		Test.Assert(NearlyEqual(mid.position, Float3(5.0f, 0.0f, 0.0f)));
		Test.Assert(NearlyEqual(mid.direction, Float3(0.5f, 0.5f, 0.0f)));

		Test.Assert(NearlyEqual(a.Interpolate(b, 0.0f).position, a.position));
		Test.Assert(NearlyEqual(a.Interpolate(b, 1.0f).position, b.position));
	}

	[Test]
	public static void AgainstAPlane()
	{
		// The plane y = 0 with normal +Y, and a ray dropping onto it from above.
		let plane = Plane.FromPointNormal(Float3.Zero, Float3.UnitY);
		let down = Ray(Float3(0.0f, 5.0f, 0.0f), Float3(0.0f, -1.0f, 0.0f));

		float t = ?;
		Test.Assert(Intersects(down, plane, out t));
		Test.Assert(NearlyEqual(t, 5.0f));

		// Pointing away never hits.
		let up = Ray(Float3(0.0f, 5.0f, 0.0f), Float3.UnitY);
		Test.Assert(!Intersects(up, plane, out t));

		// Parallel to the plane never hits, even when it lies in it.
		let parallel = Ray(Float3(0.0f, 5.0f, 0.0f), Float3.UnitX);
		Test.Assert(!Intersects(parallel, plane, out t));

		// Starting on the plane is a hit at zero.
		let onIt = Ray(Float3.Zero, Float3(0.0f, -1.0f, 0.0f));
		Test.Assert(Intersects(onIt, plane, out t));
		Test.Assert(t == 0.0f);
	}

	[Test]
	public static void AgainstASphere()
	{
		let sphere = BoundingSphere(Float3(0.0f, 0.0f, -10.0f), 2.0f);
		let forward = Ray(Float3.Zero, Float3(0.0f, 0.0f, -1.0f));

		float t = ?;
		Test.Assert(Intersects(forward, sphere, out t));
		Test.Assert(NearlyEqual(t, 8.0f, 1.0e-3f));   // reaches the near surface

		// Pointing away misses even though the sphere is on the line.
		let backward = Ray(Float3.Zero, Float3(0.0f, 0.0f, 1.0f));
		Test.Assert(!Intersects(backward, sphere, out t));

		// Passing to one side misses.
		let beside = Ray(Float3(5.0f, 0.0f, 0.0f), Float3(0.0f, 0.0f, -1.0f));
		Test.Assert(!Intersects(beside, sphere, out t));

		// Starting inside is a hit at zero.
		let inside = Ray(Float3(0.0f, 0.0f, -10.0f), Float3.UnitX);
		Test.Assert(Intersects(inside, sphere, out t));
		Test.Assert(t == 0.0f);
	}

	[Test]
	public static void AgainstAnAABB()
	{
		let bounds = AABB(Float3(-1.0f, -1.0f, -1.0f), Float3(1.0f, 1.0f, 1.0f));

		float t = ?;
		// Straight at a face.
		Test.Assert(Intersects(Ray(Float3(0.0f, 0.0f, 5.0f), Float3(0.0f, 0.0f, -1.0f)),
			bounds, out t));
		Test.Assert(NearlyEqual(t, 4.0f, 1.0e-3f));

		// Away from it.
		Test.Assert(!Intersects(Ray(Float3(0.0f, 0.0f, 5.0f), Float3(0.0f, 0.0f, 1.0f)),
			bounds, out t));

		// Past the side.
		Test.Assert(!Intersects(Ray(Float3(5.0f, 5.0f, 5.0f), Float3(0.0f, 0.0f, -1.0f)),
			bounds, out t));

		// Starting inside gives zero.
		Test.Assert(Intersects(Ray(Float3.Zero, Float3.UnitX), bounds, out t));
		Test.Assert(t == 0.0f);

		// A ray parallel to an axis but outside the slab on that axis misses, which is
		// the branch the zero-direction guard exists for.
		Test.Assert(!Intersects(Ray(Float3(0.0f, 5.0f, 0.0f), Float3.UnitX), bounds, out t));
		// The same direction, inside the slab, hits.
		Test.Assert(Intersects(Ray(Float3(-5.0f, 0.0f, 0.0f), Float3.UnitX), bounds, out t));
		Test.Assert(NearlyEqual(t, 4.0f, 1.0e-3f));
	}
}
