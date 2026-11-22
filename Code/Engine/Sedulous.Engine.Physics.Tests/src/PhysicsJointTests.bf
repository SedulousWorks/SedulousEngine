using System;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// Joints: how the other end resolves, and what a motor does.
class PhysicsJointTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	/// How far from upright a rotation is, which is what says a hinge actually turned.
	private static float Uprightness(Quaternion rotation) => Math.Abs(rotation.W);

	[Test]
	public static void AMotorisedHingeSpinsADoorAgainstTheWorld()
	{
		let play = scope PhysicsPlayScene();

		let door = play.Scene.CreateEntity("door");
		play.Scene.SetLocalPosition(door, .(0.0f, 2.0f, 0.0f));
		{
			let body = play.Bodies.Add(door);
			body.HalfExtents = .(1.0f, 1.0f, 0.05f);

			let joint = play.Joints.Add(door);
			// No ancestor body, so it anchors to the WORLD.
			joint.Kind = .Hinge;
			joint.LocalAxis = .(0.0f, 1.0f, 0.0f);
			joint.MotorEnabled = true;
			joint.MotorTargetVelocity = 3.0f;
		}

		play.Start();
		play.Step(120);
		play.Settle();

		// Held at its pivot, and meaningfully turned by the motor.
		Test.Assert(Near(play.Scene.GetWorldPosition(door).Y, 2.0f, 0.02f));
		Test.Assert(Uprightness(play.Scene.GetLocalTransform(door).Rotation) < 0.99f);
	}

	/// The SETUP TRAP: enabling a motor without a target velocity holds the hinge at a
	/// standstill, which reads as "the joint does nothing" when it is in fact a motor
	/// actively holding still. The working recipe needs a NON ZERO target velocity.
	[Test]
	public static void AMotorWithNoTargetVelocityHoldsStill()
	{
		let play = scope PhysicsPlayScene();

		let door = play.Scene.CreateEntity("door");
		play.Scene.SetLocalPosition(door, .(0.0f, 2.0f, 0.0f));

		let body = play.Bodies.Add(door);
		body.HalfExtents = .(1.0f, 1.0f, 0.05f);

		let joint = play.Joints.Add(door);
		joint.Kind = .Hinge;
		// Enabled, but the target velocity stays at its default of nought.
		joint.MotorEnabled = true;

		play.Start();
		play.Step(120);
		play.Settle();

		// Still essentially upright.
		Test.Assert(Uprightness(play.Scene.GetLocalTransform(door).Rotation) > 0.999f);

		// Give it a target and it spins. The motor fields are live, so no rebuild is needed.
		joint.MotorTargetVelocity = 3.0f;
		play.Step(120);
		play.Settle();

		Test.Assert(Uprightness(play.Scene.GetLocalTransform(door).Rotation) < 0.99f);
	}

	/// An unnamed target resolves to the nearest ANCESTOR body, and a named one binds
	/// explicitly.
	[Test]
	public static void UnnamedTargetsUseTheAncestorAndNamedOnesBindExplicitly()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		// A static anchor above, with a bob hanging from it on a rope.
		let anchor = play.Scene.CreateEntity("anchor");
		play.Scene.SetLocalPosition(anchor, .(0.0f, 6.0f, 0.0f));
		{
			let body = play.Bodies.Add(anchor);
			body.Motion = .Static;
			body.Layer = .Static;
			body.HalfExtents = .(0.2f, 0.2f, 0.2f);
		}

		let bob = play.Scene.CreateEntity("bob");
		play.Scene.SetParent(bob, anchor);
		play.Scene.SetLocalPosition(bob, .(0.0f, -1.0f, 0.0f));
		{
			let body = play.Bodies.Add(bob);
			body.Shape = .Sphere;
			body.Radius = 0.25f;

			let joint = play.Joints.Add(bob);
			// Unnamed, so it finds the ancestor.
			joint.Kind = .Distance;
			joint.MaxDistance = 2.0f;
			joint.MinDistance = 0.0f;
		}

		// And an explicitly named pair, welded side by side on the floor.
		let left = play.AddBox(0.5f);
		let right = play.AddBox(0.5f);
		play.Scene.SetLocalPosition(left, .(4.0f, 0.5f, 0.0f));
		play.Scene.SetLocalPosition(right, .(5.2f, 0.5f, 0.0f));
		{
			let joint = play.Joints.Add(right);
			joint.Kind = .Fixed;
			joint.TargetEntity = .(play.Scene.GetEntityId(left));
		}

		play.Start();
		play.Step(300);
		play.Settle();

		// The bob hangs on its rope rather than reaching the floor.
		Test.Assert(Near(play.Scene.GetWorldPosition(bob).Y, 4.0f, 0.05f));

		// The welded pair stays welded: push one and the other follows. It may ROTATE as one
		// rigid unit from an off centre push, so the invariant is the distance between their
		// centres rather than any per axis offset.
		play.Physics.World.AddImpulse(play.Bodies.Get(left).Body, .(0.0f, 0.0f, 4000.0f));
		play.Step(60);
		play.Settle();

		let a = play.Scene.GetWorldPosition(left);
		let b = play.Scene.GetWorldPosition(right);
		Test.Assert(Near(Length(b - a), 1.2f, 0.03f));
	}

	/// A slalom flag: a panel on an upright hinge to the world, a child of its gate, turned to face
	/// back up the course, pushed back toward rest every frame. Run as frames run (a step, the
	/// interpolated pose written, the transforms updated), the scale decomposed from its world
	/// matrix wavered between 1.0 and 0.9999999, which read as a rescale: its body was rebuilt and
	/// its hinge made again at the sagged pose, and the flag slid down its pole and through the
	/// ground.
	[Test]
	public static void AFlagHingedToTheWorldHoldsItsHeightAsFramesRun()
	{
		let play = scope PhysicsPlayScene();
		let gate = play.Scene.CreateEntity("gate");
		play.Scene.SetLocalPosition(gate, .(10.0f, 3.0f, -4.0f));
		let flag = play.Scene.CreateEntity("flag");
		play.Scene.SetParent(flag, gate);
		// Half a turn about up.
		play.Scene.SetLocalTransform(flag, Transform(.(-4.33f, 1.55f, 0.0f), Quaternion(0.0f, 1.0f, 0.0f, 0.0f), .(1.0f, 1.0f, 1.0f)));
		{
			let body = play.Bodies.Add(flag);
			body.HalfExtents = .(0.275f, 0.225f, 0.01f);
			body.Mass = 0.3f;
			body.LinearDamping = 0.6f;
			body.AngularDamping = 3.0f;
			let joint = play.Joints.Add(flag);
			joint.Kind = .Hinge; // no ancestor body: the world
			joint.LocalAnchor = .(-0.3f, 0.0f, 0.0f);
			joint.LocalAxis = .(0.0f, 1.0f, 0.0f);
			joint.LimitMin = -1.3f;
			joint.LimitMax = 1.3f;
		}
		play.Start();
		let startY = play.Scene.GetWorldPosition(flag).Y;
		let flagBody = play.Bodies.Get(flag);
		for (int frame < 600)
		{
			// The gate's spring back to rest: a small push across the panel every frame.
			play.Physics.World.AddImpulse(flagBody.Body, .(0.0f, 0.0f, (frame % 2 == 0) ? 0.002f : -0.002f));
			play.Step();
			play.Settle(0.5f);
		}
		play.Settle();
		let endY = play.Scene.GetWorldPosition(flag).Y;
		Test.Assert(Near(endY, startY, Math.Abs(startY) * 0.01f), scope $"held at {startY}, now {endY}");
	}
}
