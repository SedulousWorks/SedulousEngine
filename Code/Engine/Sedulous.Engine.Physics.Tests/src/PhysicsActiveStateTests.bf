using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// The effective active edges: what enters the world, what leaves it, and what comes back.
class PhysicsActiveStateTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	/// An entity that starts inactive NEVER gets a body, and activating builds one.
	[Test]
	public static void AnEntityStartedInactiveGetsNoBodyUntilItActivates()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(5.0f);

		// Inactive BEFORE the start, which is the scene saved that way.
		play.Scene.SetActive(@box, false);
		play.Start();

		Test.Assert(play.Physics.World != null);
		// The floor alone.
		Test.Assert(play.Physics.World.BodyCount == 1);
		Test.Assert(!play.Bodies.Get(@box).Body.IsValid);

		// It does not fall, there being nothing in the world to fall.
		play.Step(60);
		play.Settle();
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 5.0f));

		// The activation edge builds the body, and it lands.
		play.Scene.SetActive(@box, true);
		play.Step(240);
		Test.Assert(play.Physics.World.BodyCount == 2);
		play.Settle();
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 0.5f, 0.05f));
	}

	/// Deactivating LEAVES the world rather than merely skipping a sync: the backend steps
	/// everything it holds, so a skipped sync would leave the body falling invisibly.
	[Test]
	public static void DeactivatingLeavesTheWorldAndReactivatingResumes()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let @box = play.AddBox(8.0f);
		play.Start();
		Test.Assert(play.Physics.World.BodyCount == 2);

		play.Step(30);
		play.Settle();
		let midFall = play.Scene.GetWorldPosition(@box).Y;
		Test.Assert(midFall < 8.0f);

		play.Scene.SetActive(@box, false);
		play.Step(60);
		Test.Assert(play.Physics.World.BodyCount == 1);
		Test.Assert(!play.Bodies.Get(@box).Body.IsValid);

		play.Settle();
		// Frozen exactly where it was.
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, midFall, 0.01f));

		// Re-created at the CURRENT pose with its momentum cleared.
		play.Scene.SetActive(@box, true);
		play.Step(240);
		Test.Assert(play.Physics.World.BodyCount == 2);
		play.Settle();
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).Y, 0.5f, 0.05f));
	}

	/// A joint drops when its explicit TARGET deactivates, even though the joint's own entity
	/// stays active, and returns when the target does.
	[Test]
	public static void AJointDropsWithItsTargetAndReturnsWithIt()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let left = play.AddBox(0.5f);
		let right = play.AddBox(0.5f);
		play.Scene.SetLocalPosition(left, .(4.0f, 0.5f, 0.0f));
		play.Scene.SetLocalPosition(right, .(5.2f, 0.5f, 0.0f));

		let joint = play.Joints.Add(right);
		joint.Kind = .Fixed;
		joint.TargetEntity = .(play.Scene.GetEntityId(left));

		play.Start();
		play.Step(1);
		Test.Assert(play.Joints.Get(right).Joint.IsValid);

		// The TARGET deactivates while the joint's own entity stays active.
		play.Scene.SetActive(left, false);
		play.Step(1);
		Test.Assert(!play.Joints.Get(right).Joint.IsValid);
		Test.Assert(play.Bodies.Get(right).Body.IsValid);

		play.Scene.SetActive(left, true);
		// TWO steps: joints reconcile BEFORE bodies, so the reactivation tick recreates the
		// BODY and the tick after that rebuilds the joint, through the silent retry.
		play.Step(2);
		Test.Assert(play.Joints.Get(right).Joint.IsValid);
	}
}
