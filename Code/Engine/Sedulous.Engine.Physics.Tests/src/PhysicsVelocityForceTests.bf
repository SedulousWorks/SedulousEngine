using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// A script's velocity and held force on a body: SetVelocity moves it now (or once a body
/// spawned this frame is built), and SetForce holds a force across every fixed step until let go.
class PhysicsVelocityForceTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	[Test]
	public static void SetVelocityMovesTheBodyAndWaitsForOneNotBuiltYet()
	{
		let play = scope PhysicsPlayScene();
		let @box = play.AddBox(0.0f);
		play.Start();
		play.Physics.SetGravity(.(0, 0, 0));

		play.Physics.SetVelocity(@box, .(3.0f, 0.0f, 0.0f));
		Test.Assert(Near(play.Physics.Velocity(@box).X, 3.0f, 0.01f));
		// Half a second at 3 m/s, a little under for the damping.
		play.Step(30);
		play.Settle(1.0f);
		Test.Assert(Near(play.Scene.GetWorldPosition(@box).X, 1.5f, 0.1f));

		// A body spawned after the start is built at the next step, and takes the velocity then.
		let late = play.AddBox(5.0f);
		play.Scene.UpdateTransforms();
		play.Physics.SetVelocity(late, .(0.0f, 0.0f, 2.0f));
		Test.Assert(play.Bodies.Get(late).HasPendingVelocity);
		play.Step(1);
		Test.Assert(!play.Bodies.Get(late).HasPendingVelocity);
		Test.Assert(play.Physics.Velocity(late).Z > 1.9f);
	}

	[Test]
	public static void SetForceIsHeldEveryStepUntilLetGoAndAStopClearsIt()
	{
		let play = scope PhysicsPlayScene();
		let @box = play.AddBox(0.0f);
		play.Bodies.Get(@box).Mass = 1000.0f;
		play.Start();
		play.Physics.SetGravity(.(0, 0, 0));

		// 1000 N on 1000 kg: one metre per second squared, so about one metre per second after
		// one second of steps.
		play.Physics.SetForce(@box, .(1000.0f, 0.0f, 0.0f));
		play.Step(60);
		let pushed = play.Physics.Velocity(@box).X;
		Test.Assert(Near(pushed, 1.0f, 0.1f));

		// Let go: it coasts rather than keeps accelerating.
		play.Physics.SetForce(@box, .(0, 0, 0));
		play.Step(60);
		Test.Assert(play.Physics.Velocity(@box).X <= pushed);

		play.Physics.SetForce(@box, .(1000.0f, 0.0f, 0.0f));
		play.Scene.Stop();
		Test.Assert(play.Bodies.Get(@box).HeldForce.X == 0.0f, "a held force is run scoped");
	}
}
