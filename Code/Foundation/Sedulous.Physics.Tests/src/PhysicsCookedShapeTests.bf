using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// Cooked geometry: hulls and triangle meshes built offline, and the plane, which needs no
/// cooking at all.
class PhysicsCookedShapeTests
{
	/// The corners of a cube, which is the smallest cloud worth hulling.
	private static void CubeCorners(float half, List<Float3> outPoints)
	{
		let ends = scope float[2](-half, half);
		for (let x in ends)
			for (let y in ends)
				for (let z in ends)
					outPoints.Add(.(x, y, z));
	}

	[Test]
	public static void ACookedHullSimulatesLikeTheBoxItWasMadeFrom()
	{
		let corners = scope List<Float3>();
		CubeCorners(0.5f, corners);

		let blob = scope List<uint8>();
		Test.Assert(ShapeCooking.CookConvexHull(corners, blob));
		Test.Assert(!blob.IsEmpty);

		let world = FlatWorld!();

		let drop = scope BodyDesc();
		drop.Position = .(0.0f, 5.0f, 0.0f);
		var shape = ShapeDesc();
		shape.Kind = .Cooked;
		shape.Cooked = blob;
		drop.Shapes.Add(shape);

		let body = world.CreateBody(drop);
		Test.Assert(body.IsValid);

		Simulate(world, 300);
		world.GetBodyTransform(body, let position, ?);
		// Its half extent above the floor, give or take the convex radius.
		Test.Assert(Near(position.Y, 0.5f, 0.05f));
	}

	/// The material slot each triangle was cooked with reaches a ray hit as its surface,
	/// which is what lets a footstep sound know what it landed on.
	[Test]
	public static void ACookedMeshCarriesItsPerFaceSlotsToARayHit()
	{
		// A ground quad of two triangles, the far one slot seven and the near one slot three.
		let positions = scope Float3[4](
			.(-2.0f, 0.0f, -2.0f),
			.(-2.0f, 0.0f, 2.0f),
			.(2.0f, 0.0f, 2.0f),
			.(2.0f, 0.0f, -2.0f));
		let indices = scope uint32[6](0, 1, 3, 1, 2, 3);
		let slots = scope uint32[2](7, 3);

		let blob = scope List<uint8>();
		Test.Assert(ShapeCooking.CookTriangleMesh(positions, indices, slots, blob));

		let world = scope PhysicsWorld();
		let ground = scope BodyDesc();
		ground.Motion = .Static;
		ground.Layer = .Static;
		var shape = ShapeDesc();
		shape.Kind = .Cooked;
		shape.Cooked = blob;
		ground.Shapes.Add(shape);
		Test.Assert(world.CreateBody(ground).IsValid);

		Test.Assert(world.RayCast(.(-1.5f, 1.0f, -1.5f), .(0.0f, -1.0f, 0.0f), 5.0f, let first));
		Test.Assert(first.Surface == 7);
		Test.Assert(Near(first.Normal.Y, 1.0f, 0.01f));

		Test.Assert(world.RayCast(.(1.5f, 1.0f, 1.5f), .(0.0f, -1.0f, 0.0f), 5.0f, let second));
		Test.Assert(second.Surface == 3);

		// The mesh COLLIDES as well as answering queries.
		let body = world.CreateBody(BoxAt!(3.0f));
		Simulate(world, 300);
		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 0.5f, 0.05f));
	}

	/// A cooked shape takes a scale, bytes that are not a shape make no body rather than a
	/// crash, and a good blob gives up its outline geometry.
	[Test]
	public static void ACookedShapeScalesAndGarbageFailsGracefully()
	{
		let corners = scope List<Float3>();
		CubeCorners(0.5f, corners);
		let blob = scope List<uint8>();
		Test.Assert(ShapeCooking.CookConvexHull(corners, blob));

		let world = FlatWorld!();

		let drop = scope BodyDesc();
		drop.Position = .(0.0f, 5.0f, 0.0f);
		var shape = ShapeDesc();
		shape.Kind = .Cooked;
		shape.Cooked = blob;
		shape.Scale = .(2.0f, 2.0f, 2.0f);
		drop.Shapes.Add(shape);

		let body = world.CreateBody(drop);
		Test.Assert(body.IsValid);
		Simulate(world, 300);
		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 1.0f, 0.05f), "the doubled half extent");

		let garbage = scope uint8[4](0xDE, 0xAD, 0xBE, 0xEF);
		let bad = scope BodyDesc();
		var badShape = ShapeDesc();
		badShape.Kind = .Cooked;
		badShape.Cooked = garbage;
		bad.Shapes.Add(badShape);
		Test.Assert(!world.CreateBody(bad).IsValid);

		let triangles = scope List<Float3>();
		Test.Assert(ShapeCooking.ExtractShapeTriangles(blob, triangles));
		Test.Assert((triangles.Count % 3) == 0);
		Test.Assert(!triangles.IsEmpty);

		let none = scope List<Float3>();
		Test.Assert(!ShapeCooking.ExtractShapeTriangles(garbage, none));
	}

	/// A plane is collidable anywhere within its half extent, which is what makes it the
	/// cheap ground for a scene with no authored floor.
	[Test]
	public static void APlaneCatchesBodiesAnywhereWithinItsHalfExtent()
	{
		let world = scope PhysicsWorld();

		let ground = scope BodyDesc();
		ground.Motion = .Static;
		ground.Layer = .Static;
		var plane = ShapeDesc();
		plane.Kind = .Plane;
		ground.Shapes.Add(plane);
		Test.Assert(world.CreateBody(ground).IsValid);

		// Far outside where any box shaped floor would reach, and still well inside the
		// plane's own extent.
		let drop = BoxAt!(5.0f);
		drop.Position = .(800.0f, 5.0f, -650.0f);
		let body = world.CreateBody(drop);

		Simulate(world, 300);
		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 0.5f, 0.05f));

		Test.Assert(world.RayCast(.(-300.0f, 2.0f, 40.0f), .(0.0f, -1.0f, 0.0f), 5.0f, let hit));
		Test.Assert(Near(hit.Normal.Y, 1.0f, 0.01f));
	}
}
