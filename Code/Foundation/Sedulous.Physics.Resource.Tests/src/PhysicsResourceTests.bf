using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Resource;

namespace Sedulous.Physics.Resource.Tests;

/// Cooked physics content built into what a collider and a rigid body bind.
class PhysicsResourceTests
{
	private static bool Near(float a, float b, float epsilon = 0.01f) => Abs(a - b) <= epsilon;

	/// The blob survives the round trip through the database, and the outline comes back as
	/// whole triangles rather than as the flat floats it was stored as.
	[Test]
	public static void ACookedShapeBuildsWithItsBlobAndOutline()
	{
		let fixture = scope PhysicsResourceFixture("scratch_physics_shape");
		let id = fixture.CookHull("crate");
		Test.Assert(id != Guid());

		let shape = fixture.Manager.Bind<CollisionShape>(id);
		Test.Assert(shape.Get != null);
		Test.Assert(shape.State == .Ready);

		Test.Assert(shape.Get.Convex);
		Test.Assert(!shape.Get.Blob.IsEmpty);
		Test.Assert(!shape.Get.Outline.IsEmpty);
		Test.Assert((shape.Get.Outline.Count % 3) == 0, "whole triangles");
	}

	/// The point of the blob: a body built from it simulates like the shape it was cooked
	/// from, which is the whole path from the cooker to the world.
	[Test]
	public static void ACookedShapeCarriesStraightIntoAWorld()
	{
		let fixture = scope PhysicsResourceFixture("scratch_physics_shape_world");
		let shape = fixture.Manager.Bind<CollisionShape>(fixture.CookHull("crate"));
		Test.Assert(shape.Get != null);

		let world = scope PhysicsWorld();

		let floor = scope BodyDesc();
		floor.Motion = .Static;
		floor.Layer = .Static;
		floor.Position = .(0.0f, -0.5f, 0.0f);
		var slab = ShapeDesc();
		slab.Kind = .Box;
		slab.HalfExtents = .(50.0f, 0.5f, 50.0f);
		floor.Shapes.Add(slab);
		world.CreateBody(floor);

		let drop = scope BodyDesc();
		drop.Position = .(0.0f, 5.0f, 0.0f);
		var cooked = ShapeDesc();
		cooked.Kind = .Cooked;
		cooked.Cooked = shape.Get.Bytes;
		drop.Shapes.Add(cooked);

		let body = world.CreateBody(drop);
		Test.Assert(body.IsValid);

		for (int i < 300)
			world.Step(1.0f / 60.0f);

		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 0.5f, 0.05f), "resting on its own half extent");
	}

	[Test]
	public static void ACookedSurfaceBuildsIntoItsProperties()
	{
		let fixture = scope PhysicsResourceFixture("scratch_physics_material");
		let id = fixture.CookMaterial("ice", 0.05f, 0.2f, 900.0f);

		let material = fixture.Manager.Bind<PhysicalMaterial>(id);
		Test.Assert(material.Get != null);
		Test.Assert(Near(material.Get.Friction, 0.05f));
		Test.Assert(Near(material.Get.Restitution, 0.2f));
		Test.Assert(Near(material.Get.Density, 900.0f, 0.5f));
	}

	/// Something else stored under the type name is not a shape rather than a shape that
	/// failed to read, so nothing is built from it.
	[Test]
	public static void ARecordOfTheWrongTypeBuildsNothing()
	{
		let fixture = scope PhysicsResourceFixture("scratch_physics_mismatch");
		let id = fixture.CookMaterial("ice", 0.05f, 0.2f, 900.0f);

		// A surface bound as though it were a shape.
		let shape = fixture.Manager.Bind<CollisionShape>(id);
		Test.Assert(shape.Get == null);
	}
}
