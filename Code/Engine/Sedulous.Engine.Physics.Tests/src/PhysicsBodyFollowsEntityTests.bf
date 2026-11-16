using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// A body follows what is done to its entity while live: a move, an edit and a rescale.
static class PhysicsBodyFollowsEntityTests
{
	private static bool Near(float a, float b, float epsilon) => Math.Abs(a - b) <= epsilon;

	/// The body owned its pose: a script or the editor moving the entity was overwritten by the
	/// next step's write-back.
	[Test]
	public static void ADynamicBodyMovedByItsEntitysTransformGoesThere()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let crate = play.AddBox(0.5f);
		play.Start();
		play.Step(30);
		play.Settle();

		play.Scene.SetLocalPosition(crate, .(10.0f, 0.5f, -3.0f));
		play.Scene.UpdateTransforms();
		play.Step(2);
		let body = play.Bodies.Get(crate);
		Test.Assert(body != null);
		var position = Float3();
		var rotation = Quaternion.Identity;
		play.Physics.World.GetBodyTransform(body.Body, out position, out rotation);
		Test.Assert(Near(position.X, 10.0f, 0.1f) && Near(position.Z, -3.0f, 0.1f),
			scope $"moved to {position.X}, {position.Z}");

		// Left alone, it stays where the physics put it: no teleport from its own write-back.
		play.Settle();
		play.Step(30);
		play.Physics.World.GetBodyTransform(body.Body, out position, out rotation);
		Test.Assert(Near(position.X, 10.0f, 0.1f) && Near(position.Y, 0.5f, 0.05f),
			scope $"settled at {position.X}, {position.Y}");
	}

	/// A body was built once: an edit while live did nothing, and a box, sphere, capsule or plane
	/// ignored its entity's scale, so a scaled prefab collided at its unscaled size.
	[Test]
	public static void ABodyEditedWhileLiveIsBuiltAgainAndPrimitivesTakeTheEntitysScale()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let crate = play.AddBox(5.0f, .Static);
		{
			var transform = play.Scene.GetLocalTransform(crate);
			transform.Scale = .(2.0f, 2.0f, 2.0f); // a unit box drawn 2 m on a side
			play.Scene.SetLocalTransform(crate, transform);
		}
		play.Start();
		play.Step(1);

		// Scaled x2, the box's top is at 5 + 1.
		var hit = RayHit();
		Test.Assert(play.Physics.World.RayCast(.(0, 20, 0), .(0, -1, 0), 30.0f, out hit));
		Test.Assert(Near(hit.Position.Y, 6.0f, 0.01f), scope $"top at {hit.Position.Y}");

		// Its half extents edited in play: the body follows (top at 5 + 2 * 1.5).
		play.Bodies.Get(crate).HalfExtents = .(1.5f, 1.5f, 1.5f);
		play.Step(1);
		Test.Assert(play.Physics.World.RayCast(.(0, 20, 0), .(0, -1, 0), 30.0f, out hit));
		Test.Assert(Near(hit.Position.Y, 8.0f, 0.01f), scope $"edited top at {hit.Position.Y}");
		Test.Assert(play.Physics.World.BodyCount == 2, "rebuilt, not added");

		// Rescaled in play: the body follows again.
		{
			var transform = play.Scene.GetLocalTransform(crate);
			transform.Scale = .(1.0f, 1.0f, 1.0f);
			play.Scene.SetLocalTransform(crate, transform);
		}
		play.Scene.UpdateTransforms();
		play.Step(1);
		Test.Assert(play.Physics.World.RayCast(.(0, 20, 0), .(0, -1, 0), 30.0f, out hit));
		Test.Assert(Near(hit.Position.Y, 6.5f, 0.01f), scope $"rescaled top at {hit.Position.Y}");
	}

	/// A jointed body rebuilt by an edit keeps its joint: the joint is made again on the new
	/// body, rather than left on the one the edit destroyed (and the new body falling free).
	[Test]
	public static void AJointedBodyEditedWhileLiveKeepsItsJoint()
	{
		let play = scope PhysicsPlayScene();

		let door = play.Scene.CreateEntity("door");
		play.Scene.SetLocalPosition(door, .(0.0f, 2.0f, 0.0f));
		let body = play.Bodies.Add(door);
		body.HalfExtents = .(1.0f, 1.0f, 0.05f);
		let joint = play.Joints.Add(door);
		// No ancestor body, so it anchors to the WORLD.
		joint.Kind = .Hinge;
		joint.LocalAxis = .(0.0f, 1.0f, 0.0f);

		play.Start();
		play.Step(10);
		play.Settle();
		let before = play.Bodies.Get(door).Body;

		play.Bodies.Get(door).HalfExtents = .(1.0f, 1.0f, 0.1f);
		play.Step(120);
		play.Settle();

		Test.Assert(play.Bodies.Get(door).Body != before, "the edit rebuilt the body");
		Test.Assert(play.Joints.Get(door).Joint.IsValid, "the joint is there");
		Test.Assert(play.Physics.World.JointHolds(play.Joints.Get(door).Joint, play.Bodies.Get(door).Body),
			"on the new body");
		let y = play.Scene.GetWorldPosition(door).Y;
		Test.Assert(Near(y, 2.0f, 0.05f), scope $"held at its pivot, at {y}");
	}
}
