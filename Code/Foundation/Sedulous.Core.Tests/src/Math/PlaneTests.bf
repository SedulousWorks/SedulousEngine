using System;
using Sedulous.Core;

namespace Sedulous.Core.Tests;

/// Planes: signed distance, normalization, construction.
class PlaneTests
{
	[Test]
	public static void PlaneSignedDistance()
	{
		// The XZ plane at y = 0, normal +Y.
		let plane = Plane.FromPointNormal(Float3.Zero, Float3.UnitY);
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(5.0f, 0.0f, -3.0f)), 0.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 2.0f, 0.0f)), 2.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, -4.0f, 0.0f)), -4.0f));

		let unnormalized = Plane(Float3(0.0f, 3.0f, 0.0f), 0.0f);
		Test.Assert(NearlyEqual(Length(unnormalized.Normalized().Normal), 1.0f));
	}

	/// A plane through the origin would not tell: d is zero there and an implementation
	/// that dropped the point term entirely would pass. This one is offset.
	[Test]
	public static void PlaneThroughAnOffsetPoint()
	{
		let plane = Plane.FromPointNormal(Float3(0.0f, 5.0f, 0.0f), Float3.UnitY);
		Test.Assert(NearlyEqual(plane.D, -5.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 5.0f, 0.0f)), 0.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 7.0f, 0.0f)), 2.0f));
		Test.Assert(NearlyEqual(plane.SignedDistance(Float3(0.0f, 1.0f, 0.0f)), -4.0f));

		// Normalizing an already-unit plane changes nothing.
		let n = plane.Normalized();
		Test.Assert(NearlyEqual(n.Normal, plane.Normal));
		Test.Assert(NearlyEqual(n.D, plane.D));

		// A degenerate normal is returned unchanged rather than producing infinities.
		let degenerate = Plane(Float3.Zero, 3.0f);
		Test.Assert(NearlyEqual(degenerate.Normalized().Normal, Float3.Zero));
		Test.Assert(NearlyEqual(degenerate.Normalized().D, 3.0f));
	}

	/// Normalizing has to scale d as well as the normal. A plane with d = 0, or the offset
	/// case above with its unit normal, would not tell: scaling d is a no-op in both, so an
	/// implementation that left d alone passes. This one has a non-unit normal and a
	/// non-zero d, so the plane it describes only stays put if both scale.
	[Test]
	public static void PlaneNormalizedScalesDistanceToo()
	{
		// 3y + 6 = 0, which is the plane y = -2 with a normal of length 3.
		let unnormalized = Plane(Float3(0.0f, 3.0f, 0.0f), 6.0f);
		let n = unnormalized.Normalized();

		Test.Assert(NearlyEqual(Length(n.Normal), 1.0f));
		Test.Assert(NearlyEqual(n.D, 2.0f));

		// Same plane: the point y = -2 is still on it.
		Test.Assert(NearlyEqual(n.SignedDistance(Float3(0.0f, -2.0f, 0.0f)), 0.0f));
		// And distances are now in world units rather than scaled by the normal length.
		Test.Assert(NearlyEqual(n.SignedDistance(Float3.Zero), 2.0f));
		Test.Assert(NearlyEqual(n.SignedDistance(Float3(0.0f, -5.0f, 0.0f)), -3.0f));
	}
}
