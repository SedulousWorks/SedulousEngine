using System;
using System.Collections;
using System.Threading;
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

	/// The backend's process wide bring up is shared by every world and every cook. The cook
	/// driver cooks collision shapes on parallel job workers with no world alive: each cook
	/// acquires the backend, and none may use it before the first has finished bringing it up.
	[Test]
	public static void TriangleMeshesCookInParallelWithNoWorldKeepingTheBackendUp()
	{
		Float3[4] positions = .(.(-2, 0, -2), .(-2, 0, 2), .(2, 0, 2), .(2, 0, -2));
		uint32[6] indices = .(0, 1, 3, 1, 2, 3);
		int cooked = 0;
		bool go = false;

		let threads = scope List<Thread>();
		defer { for (let thread in threads) delete thread; }
		for (int t < 8)
		{
			let thread = new Thread(new [&]() =>
				{
					while (!Volatile.Read(ref go)) {} // all at once: the bring up is where they collide
					for (int i < 25)
					{
						let blob = scope List<uint8>();
						if (ShapeCooking.CookTriangleMesh(positions, indices, .(), blob) && !blob.IsEmpty)
							Interlocked.Increment(ref cooked);
					}
				});
			thread.Start(false);
			threads.Add(thread);
		}
		Volatile.Write(ref go, true);
		for (let thread in threads)
			thread.Join();

		Test.Assert(cooked == 8 * 25, scope $"{cooked} of {8 * 25} cooked");
	}

	/// The y of the cross of a triangle's two edges: positive when it faces up.
	private static float NormalY(List<Float3> triangles, int i)
	{
		let a = triangles[i + 1] - triangles[i];
		let b = triangles[i + 2] - triangles[i];
		return a.Z * b.X - a.X * b.Z;
	}

	/// The navigation bake reads level geometry from the bodies themselves: the triangles come
	/// out in world space, facing out, a compound's leaves each placed, only what touches the
	/// box asked for, and a body whose shape cannot build counted rather than dropped silently.
	/// No world.
	[Test]
	public static void BodiesGiveTheirWorldTrianglesTouchingABoxCompoundsAndPlanesIncluded()
	{
		let everywhere = AABB(.(-50, -50, -50), .(50, 50, 50));

		// A two unit cube raised one: twelve triangles between y nought and two, its top up.
		let cubeBody = scope BodyDesc();
		cubeBody.Motion = .Static;
		cubeBody.Layer = .Static;
		cubeBody.Position = .(3, 1, 0);
		var cube = ShapeDesc();
		cube.HalfExtents = .(1, 1, 1);
		cubeBody.Shapes.Add(cube);
		let triangles = scope List<Float3>();
		Test.Assert(PhysicsWorld.AppendBodyTriangles(scope BodyDesc[](cubeBody), everywhere, triangles) == 0);
		Test.Assert(triangles.Count == 36, scope $"{triangles.Count}");
		int upward = 0;
		for (int i = 0; i < triangles.Count; i += 3)
		{
			for (int v < 3)
			{
				let p = triangles[i + v];
				Test.Assert((p.X >= 1.999f) && (p.X <= 4.001f) && (p.Y >= -0.001f) && (p.Y <= 2.001f));
			}
			if ((triangles[i].Y > 1.99f) && (triangles[i + 1].Y > 1.99f) && (triangles[i + 2].Y > 1.99f))
			{
				Test.Assert(NormalY(triangles, i) > 0.0f);
				upward++;
			}
		}
		Test.Assert(upward == 2);

		// Two boxes as one compound body, each placed: both leaves give their triangles, the
		// left one's spanning x from nought to two.
		let pair = scope BodyDesc();
		pair.Motion = .Static;
		pair.Position = .(3, 1, 0);
		var left = cube;
		left.LocalPosition = .(-2, 0, 0);
		var right = cube;
		right.LocalPosition = .(2, 0, 0);
		pair.Shapes.Add(left);
		pair.Shapes.Add(right);
		triangles.Clear();
		Test.Assert(PhysicsWorld.AppendBodyTriangles(scope BodyDesc[](pair), everywhere, triangles) == 0);
		Test.Assert(triangles.Count == 72);
		float leastX = float.MaxValue;
		for (let p in triangles)
			leastX = Math.Min(leastX, p.X);
		Test.Assert(Math.Abs(leastX) < 0.001f, scope $"{leastX}");

		// A ground plane as wide as a level allows: its triangles touch the box asked for and
		// face up.
		let ground = scope BodyDesc();
		ground.Motion = .Static;
		var plane = ShapeDesc();
		plane.Kind = .Plane;
		plane.PlaneHalfExtent = 1000.0f;
		ground.Shapes.Add(plane);
		triangles.Clear();
		Test.Assert(PhysicsWorld.AppendBodyTriangles(scope BodyDesc[](ground), AABB(.(-5, -1, -5), .(5, 1, 5)), triangles) == 0);
		Test.Assert(!triangles.IsEmpty);
		for (int i = 0; i < triangles.Count; i += 3)
			Test.Assert(NormalY(triangles, i) > 0.0f);
		for (let p in triangles)
			Test.Assert(Math.Abs(p.Y) < 0.001f);

		// A cooked hull whose centre of mass is off its origin (a cube from nought to two): Jolt
		// gives its triangles about that centre, and they come back where the hull is.
		let hullBlob = scope List<uint8>();
		Test.Assert(ShapeCooking.CookConvexHull(scope Float3[](.(0, 0, 0), .(2, 0, 0), .(0, 2, 0), .(0, 0, 2), .(2, 2, 0), .(2, 0, 2), .(0, 2, 2), .(2, 2, 2)), hullBlob));
		let hull = scope BodyDesc();
		hull.Motion = .Static;
		var hullShape = ShapeDesc();
		hullShape.Kind = .Cooked;
		hullShape.Cooked = hullBlob;
		hull.Shapes.Add(hullShape);
		triangles.Clear();
		Test.Assert(PhysicsWorld.AppendBodyTriangles(scope BodyDesc[](hull), everywhere, triangles) == 0);
		Test.Assert(!triangles.IsEmpty);
		var hullExtent = AABB.Empty();
		for (let p in triangles)
			hullExtent.Expand(p);
		Test.Assert((Math.Abs(hullExtent.Min.X) < 0.05f) && (Math.Abs(hullExtent.Max.Y - 2.0f) < 0.05f), scope $"{hullExtent.Min} {hullExtent.Max}");

		// Nothing of a body outside the box; a shape that does not build is counted.
		let broken = scope BodyDesc();
		broken.Position = .(3, 1, 0);
		var flat = cube;
		flat.HalfExtents = .(0, 1, 1);
		broken.Shapes.Add(flat);
		triangles.Clear();
		Test.Assert(PhysicsWorld.AppendBodyTriangles(scope BodyDesc[](cubeBody, broken), AABB(.(-5, -1, 25), .(5, 1, 35)), triangles) == 1);
		Test.Assert(triangles.IsEmpty);
	}
}
