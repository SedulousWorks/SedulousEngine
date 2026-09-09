using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// The joints: what they hold, what they drive, and what they let go of.
class PhysicsJointTests
{
	/// A joint to the world holds a body up, and DESTROYING it wakes the body so gravity
	/// takes it again: removing the constraint alone would leave it asleep and hanging.
	[Test]
	public static void AFixedJointToTheWorldHoldsABodyUpAndReleasesIt()
	{
		let world = scope PhysicsWorld();
		let body = world.CreateBody(BoxAt!(3.0f));

		var desc = JointDesc();
		desc.Kind = .Fixed;
		desc.BodyA = body;
		let joint = world.CreateJoint(desc);
		Test.Assert(joint.IsValid);

		Simulate(world, 120);
		world.GetBodyTransform(body, let held, ?);
		Test.Assert(Near(held.Y, 3.0f, 0.01f));

		world.DestroyJoint(joint);
		Simulate(world, 60);
		world.GetBodyTransform(body, let fallen, ?);
		Test.Assert(fallen.Y < 2.0f);
	}

	/// A hinge's motor spins its body about the axis while the anchor holds it in place, and
	/// the motor can be re-aimed live.
	[Test]
	public static void AMotorisedHingeSpinsItsBody()
	{
		let world = scope PhysicsWorld();
		world.SetGravity(.(0, 0, 0));

		let blade = BoxAt!(2.0f);
		var arm = blade.Shapes[0];
		arm.HalfExtents = .(1.5f, 0.1f, 0.1f);
		blade.Shapes[0] = arm;
		let body = world.CreateBody(blade);

		var desc = JointDesc();
		desc.Kind = .Hinge;
		desc.BodyA = body;
		desc.Anchor = .(0.0f, 2.0f, 0.0f);
		desc.Axis = .(0.0f, 1.0f, 0.0f);
		desc.MotorEnabled = true;
		desc.MotorTargetVelocity = 2.0f;
		desc.MotorLimit = 1.0e6f;
		let joint = world.CreateJoint(desc);
		Test.Assert(joint.IsValid);

		Simulate(world, 120);

		world.GetBodyTransform(body, let position, let rotation);
		Test.Assert(Near(position.Y, 2.0f, 0.01f), "the anchor held it in place");
		// Away from the identity rotation, which is what having spun at all looks like.
		Test.Assert(Abs(rotation.W) < 0.99f);

		// Re-aiming it live must reach the constraint even if the body had settled.
		world.SetJointMotor(joint, true, -2.0f);
		Simulate(world, 10);
		world.GetBodyTransform(body, let after, ?);
		Test.Assert(Near(after.Y, 2.0f, 0.02f));
	}

	/// A distance joint to a world anchor is a rope: the body hangs at the maximum distance
	/// below it rather than falling on.
	[Test]
	public static void ADistanceJointToAWorldAnchorHangsLikeARope()
	{
		let world = scope PhysicsWorld();

		let bob = scope BodyDesc();
		bob.Position = .(0.0f, 3.0f, 0.0f);
		var ball = ShapeDesc();
		ball.Kind = .Sphere;
		ball.Radius = 0.25f;
		bob.Shapes.Add(ball);
		let body = world.CreateBody(bob);

		var desc = JointDesc();
		desc.Kind = .Distance;
		desc.BodyA = body;
		desc.Anchor = .(0.0f, 5.0f, 0.0f);
		desc.MinDistance = 0.0f;
		desc.MaxDistance = 2.0f;
		Test.Assert(world.CreateJoint(desc).IsValid);

		Simulate(world, 300);
		world.GetBodyTransform(body, let position, ?);
		// Two below the anchor, and there is no floor for it to reach anyway.
		Test.Assert(Near(position.Y, 3.0f, 0.09f));
	}

	/// A slider LOCKS everything but its own axis, and its limits stop the travel along it.
	[Test]
	public static void ASliderConstrainsTravelToItsAxisAndLimits()
	{
		let world = scope PhysicsWorld();
		world.SetGravity(.(0, 0, 0));

		let body = world.CreateBody(BoxAt!(1.0f));

		var desc = JointDesc();
		desc.Kind = .Slider;
		desc.BodyA = body;
		desc.Axis = .(1.0f, 0.0f, 0.0f);
		desc.LimitMin = -1.5f;
		desc.LimitMax = 1.5f;
		Test.Assert(world.CreateJoint(desc).IsValid);

		// Shoved in every axis at once, so only the constraint can be what keeps it in line.
		world.AddImpulse(body, .(4000.0f, 3000.0f, 3000.0f));
		Simulate(world, 180);

		world.GetBodyTransform(body, let position, ?);
		Test.Assert(position.X <= 1.55f, "clamped by the limit");
		Test.Assert(Near(position.Y, 1.0f, 0.01f), "off axis, locked");
		Test.Assert(Near(position.Z, 0.0f, 0.01f));
	}
}
