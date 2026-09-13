using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.IO;
using Sedulous.Core.Serialization;
using Sedulous.Engine.Physics;
using Sedulous.Heightfield;
using Sedulous.Physics;
using Sedulous.Physics.Resource;
using Sedulous.Scene;
using Sedulous.Scene.Resource;

namespace Sedulous.Engine.Physics.Tests;

/// The shape kinds a body can take, and what they rest on.
class PhysicsShapeTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	/// A cooked hull drives the body, and the ENTITY's scale applies to it: cooked geometry is
	/// authored at unit scale, so a doubled entity rests twice as high.
	[Test]
	public static void ACookedShapeDrivesABodyThroughTheComponentReference()
	{
		let corners = scope List<Float3>();
		let ends = float[2](-0.5f, 0.5f);
		for (let x in ends)
			for (let y in ends)
				for (let z in ends)
					corners.Add(.(x, y, z));

		let shape = scope CollisionShape();
		Test.Assert(ShapeCooking.CookConvexHull(corners, shape.Blob));

		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let crate = play.AddBox(3.0f);
		{
			let body = play.Bodies.Get(crate);
			Test.Assert(body != null);
			body.Shape = .Cooked;
			body.CollisionShape.SetDirect(shape);

			var transform = play.Scene.GetLocalTransform(crate);
			transform.Scale = .(2.0f, 2.0f, 2.0f);
			play.Scene.SetLocalTransform(crate, transform);
		}

		play.Start();
		play.Step(300);
		play.Settle();

		// The scaled half extent above the floor.
		Test.Assert(Near(play.Scene.GetWorldPosition(crate).Y, 1.0f, 0.08f));
	}

	/// A heightfield is a collision SURFACE with no terrain renderer behind it, which is what
	/// splitting the asset bought.
	[Test]
	public static void AHeightfieldDrivesABodyThroughTheComponentReference()
	{
		let heightfield = scope Heightfield(65, .(64.0f, 64.0f), 0.0f, 4.0f);
		let flat = heightfield.WorldYToSample(2.0f);
		let samples = heightfield.Samples;
		for (int i < samples.Length)
			samples[i] = flat;

		let play = scope PhysicsPlayScene();

		let ground = play.Scene.CreateEntity("heightfield");
		{
			let body = play.Bodies.Add(ground);
			body.Motion = .Static;
			body.Layer = .Static;
			body.Shape = .Heightfield;
			body.Heightfield.SetDirect(heightfield);
		}

		let @box = play.AddBox(10.0f);

		play.Start();
		play.Step(300);
		play.Settle();

		// The surface, plus the box's own half extent.
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 2.5f, 0.1f));
	}

	/// The shape kind itself has to survive the wire, or a heightfield body reloads as a box.
	[Test]
	public static void AHeightfieldBodySurvivesASceneRoundTrip()
	{
		let source = scope Scene("hf-wire");
		source.AddSystem<RigidBodyComponentManager>();

		let entity = source.CreateEntity("hf");
		{
			let body = source.GetSystem<RigidBodyComponentManager>().Add(entity);
			body.Motion = .Static;
			body.Layer = .Static;
			body.Shape = .Heightfield;
		}

		let stream = scope MemoryStream();
		{
			let writer = scope BinarySerializer(stream, .Write);
			SceneSerializer.SerializeScene(writer, source);
			Test.Assert(writer.IsOk);
		}
		stream.Seek(0, .Begin);

		let loaded = scope Scene("hf-wire2");
		loaded.AddSystem<RigidBodyComponentManager>();
		{
			let reader = scope BinarySerializer(stream, .Read);
			SceneSerializer.SerializeScene(reader, loaded);
			Test.Assert(reader.IsOk);
		}

		let reloaded = loaded.FindEntity(source.GetEntityId(entity));
		Test.Assert(reloaded.IsAssigned);

		let body = loaded.GetSystem<RigidBodyComponentManager>().Get(reloaded);
		Test.Assert(body != null);
		Test.Assert(body.Shape == .Heightfield);
	}

	/// A referenced SURFACE wins over the inline fields: the inline restitution says a dead
	/// drop and the material says bounce, and the material is what happens.
	[Test]
	public static void AReferencedMaterialOverridesTheInlineSurfaceFields()
	{
		let bouncy = scope PhysicalMaterial();
		bouncy.Friction = 0.1f;
		bouncy.Restitution = 0.9f;

		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let ball = play.AddBox(3.0f);
		{
			let body = play.Bodies.Get(ball);
			Test.Assert(body != null);
			body.Restitution = 0.0f;
			body.Material.SetDirect(bouncy);
		}

		play.Start();

		// The highest point reached AFTER the first impact. A dead drop stays at rest.
		var impacted = false;
		var apex = 0.0f;
		for (int i < 600)
		{
			play.Step();
			play.Settle();

			let y = play.Scene.GetWorldPosition(ball).Y;
			if (!impacted && (y < 0.6f))
				impacted = true;
			else if (impacted)
				apex = Math.Max(apex, y);
		}

		Test.Assert(apex > 1.0f);
	}

	/// A PLANE is the entity's own local plane, so rotating the entity tilts it.
	[Test]
	public static void ATiltedPlaneMakesBoxesSlideDownhill()
	{
		let play = scope PhysicsPlayScene();

		let ramp = play.Scene.CreateEntity("ramp");
		{
			let body = play.Bodies.Add(ramp);
			body.Motion = .Static;
			body.Layer = .Static;
			body.Shape = .Plane;
			body.Friction = 0.0f;

			var transform = play.Scene.GetLocalTransform(ramp);
			transform.Rotation = Quaternion.FromAxisAngle(.(0.0f, 0.0f, 1.0f), 0.3f);
			play.Scene.SetLocalTransform(ramp, transform);
		}

		let @box = play.AddBox(3.0f);
		play.Bodies.Get(@box).Friction = 0.0f;

		play.Start();
		play.Step(240);
		play.Settle();

		// The tilt raises the positive side, so a frictionless box slides the other way, and
		// it stays ON the plane rather than falling through it.
		let position = play.Scene.GetWorldPosition(@box);
		Test.Assert(position.X < -1.0f);
		Test.Assert(position.Y > -30.0f);
	}

	/// Starting a scene does NOT refresh its world matrices, so the system has to. Building
	/// from never updated matrices would spawn every body at the origin, interpenetrating,
	/// and the depenetration would blast the stack apart.
	[Test]
	public static void BodiesBuildFromAuthoredPositionsWithoutAPriorTransformUpdate()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let left = play.AddBox(0.5f);
		let right = play.AddBox(0.5f);
		play.Scene.SetLocalPosition(left, .(-3.0f, 0.5f, 0.0f));
		play.Scene.SetLocalPosition(right, .(3.0f, 0.5f, 0.0f));

		// DELIBERATELY no transform update before starting.
		play.Scene.Start();
		play.Scene.SetSimulationEnabled(true);

		play.Step(60);
		play.Settle();

		Test.Assert(Near(play.Scene.GetWorldPosition(left).X, -3.0f, 0.05f));
		Test.Assert(Near(play.Scene.GetWorldPosition(right).X, 3.0f, 0.05f));
		Test.Assert(Near(play.Scene.GetWorldPosition(left).Y, 0.5f, 0.05f));
	}
}
