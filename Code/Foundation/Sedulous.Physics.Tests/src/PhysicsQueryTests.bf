using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// The queries: rays, points, overlaps and sweeps, and the group mask that filters them.
class PhysicsQueryTests
{
	[Test]
	public static void ARayHitsTheNearestBodyWithItsUserDataAndNormal()
	{
		let world = FlatWorld!();

		let target = BoxAt!(0.5f, MotionKind.Static);
		target.UserData = 99;
		world.CreateBody(target);

		Test.Assert(world.RayCast(.(0.0f, 10.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 100.0f, let hit));
		// The box rather than the floor beneath it.
		Test.Assert(hit.UserData == 99);
		Test.Assert(Near(hit.Position.Y, 1.0f, 0.02f), "its top face");
		Test.Assert(Near(hit.Normal.Y, 1.0f, 0.02f), "pointing up");

		Test.Assert(!world.RayCast(.(500.0f, 10.0f, 0.0f), .(0.0f, 1.0f, 0.0f), 10.0f, ?));
	}

	[Test]
	public static void APointQueryFindsWhatContainsIt()
	{
		let world = scope PhysicsWorld();
		let body = world.CreateBody(BoxAt!(0.0f, MotionKind.Static));

		let hits = scope List<BodyId>();
		world.QueryPoint(.(0, 0, 0), hits);
		Test.Assert(hits.Count == 1);
		Test.Assert(hits[0] == body);

		world.QueryPoint(.(10, 0, 0), hits);
		Test.Assert(hits.IsEmpty);
	}

	/// An overlap reports each body ONCE however many of its sub shapes were hit, and the
	/// mask keeps a group out of the answer entirely.
	[Test]
	public static void AnOverlapDeduplicatesBodiesAndHonoursTheGroupMask()
	{
		let world = scope PhysicsWorld();

		let bodyA = world.CreateBody(BoxAt!(0.0f, MotionKind.Static));
		let descB = BoxAt!(0.0f, MotionKind.Static);
		descB.Position = .(5.0f, 0.0f, 0.0f);
		descB.Group = 1;
		let bodyB = world.CreateBody(descB);

		var sphere = QueryShape();
		sphere.Kind = .Sphere;
		sphere.Radius = 1.0f;

		let hits = scope List<BodyId>();
		world.ShapeOverlap(sphere, .(0, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.Count == 1);
		Test.Assert(hits[0] == bodyA);

		world.ShapeOverlap(sphere, .(5, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.Count == 1);
		Test.Assert(hits[0] == bodyB);

		// The gap between them.
		world.ShapeOverlap(sphere, .(2.5f, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.IsEmpty);

		var big = QueryShape();
		big.Kind = .Sphere;
		big.Radius = 3.0f;
		world.ShapeOverlap(big, .(2.5f, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.Count == 2);

		// The same sphere with group one masked out.
		world.ShapeOverlap(big, .(2.5f, 0, 0), Quaternion.Identity, hits, ~(uint32)(1 << 1));
		Test.Assert(hits.Count == 1);
		Test.Assert(hits[0] == bodyA);
	}

	/// A box is a query volume too, not only a sphere.
	[Test]
	public static void ABoxOverlapsAsWell()
	{
		let world = scope PhysicsWorld();
		let body = world.CreateBody(BoxAt!(0.0f, MotionKind.Static));

		var volume = QueryShape();
		volume.Kind = .Box;
		volume.HalfExtents = .(0.4f, 0.4f, 0.4f);

		let hits = scope List<BodyId>();
		// Three tenths inside the body.
		world.ShapeOverlap(volume, .(0.7f, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.Count == 1);
		Test.Assert(hits[0] == body);

		world.ShapeOverlap(volume, .(2.0f, 0, 0), Quaternion.Identity, hits);
		Test.Assert(hits.IsEmpty);
	}

	/// A sweep has VOLUME, so it meets what a ray from the same place meets later: the
	/// sphere's leading surface touches before its centre reaches the face.
	[Test]
	public static void ASweepHitsEarlierThanTheRayFromTheSamePlace()
	{
		let world = FlatWorld!();

		let target = BoxAt!(0.5f, MotionKind.Static);
		target.UserData = 42;
		world.CreateBody(target);

		var sphere = QueryShape();
		sphere.Kind = .Sphere;
		sphere.Radius = 0.5f;

		Test.Assert(world.ShapeCast(sphere, .(0.0f, 10.0f, 0.0f), Quaternion.Identity,
			.(0.0f, -1.0f, 0.0f), 100.0f, let hit));
		Test.Assert(hit.UserData == 42, "the box, not the floor below it");
		// It touches the top face at y = 1 once its centre is at 1.5, which is 8.5 of 100.
		Test.Assert(Near(hit.Fraction, 0.085f, 0.005f));
		Test.Assert(Near(hit.Position.Y, 1.0f, 0.05f));

		Test.Assert(world.RayCast(.(0.0f, 10.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 100.0f,
			let rayHit));
		Test.Assert(hit.Fraction < rayHit.Fraction);

		Test.Assert(!world.ShapeCast(sphere, .(500.0f, 10.0f, 0.0f), Quaternion.Identity,
			.(0.0f, 1.0f, 0.0f), 10.0f, ?));
	}
}
