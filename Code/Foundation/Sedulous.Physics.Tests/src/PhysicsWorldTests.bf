using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// The world simulating: gravity, the layer matrix, compounds, kinematic motion, sensors,
/// continuous collision and mass.
class PhysicsWorldTests
{
	[Test]
	public static void ABoxFallsAndRestsOnTheFloor()
	{
		let world = FlatWorld!();

		let drop = BoxAt!(5.0f);
		drop.UserData = 42;
		let body = world.CreateBody(drop);
		Test.Assert(body.IsValid);
		Test.Assert(world.UserData(body) == 42);

		Simulate(world, 240);

		world.GetBodyTransform(body, let position, let rotation);
		// Resting is its half extent above the floor's top face.
		Test.Assert(Near(position.Y, 0.5f, 0.05f));
		Test.Assert(Abs(position.X) < 0.01f);
		Test.Assert(Near(world.LinearVelocity(body).Y, 0.0f, 0.05f));
	}

	/// A heightfield is collidable only within the footprint it was AUTHORED with: the
	/// backend pads the sample count up to its own block size and fills the padding with no
	/// collision values, so collision never widens past the extent asked for.
	[Test]
	public static void AHeightfieldCarriesBodiesOnlyWithinItsFootprint()
	{
		let world = scope PhysicsWorld();

		const uint32 n = 65;
		let samples = scope float[n * n];
		for (int i < samples.Count)
			samples[i] = 2.0f;

		let ground = scope BodyDesc();
		ground.Motion = .Static;
		ground.Layer = .Static;
		var field = ShapeDesc();
		field.Kind = .Heightfield;
		field.HeightSamples = samples;
		field.HeightSampleCount = n;
		field.HeightWorldSize = .(64.0f, 64.0f);
		ground.Shapes.Add(field);
		Test.Assert(world.CreateBody(ground).IsValid);

		let drop = scope BodyDesc();
		var sphere = ShapeDesc();
		sphere.Kind = .Sphere;
		sphere.Radius = 0.5f;
		drop.Shapes.Add(sphere);
		drop.Position = .(0.0f, 10.0f, 0.0f);
		let ball = world.CreateBody(drop);
		Test.Assert(ball.IsValid);

		// Well outside the footprint, so there is nothing under it at all.
		let off = scope BodyDesc();
		off.Shapes.Add(sphere);
		off.Position = .(100.0f, 10.0f, 0.0f);
		let offBall = world.CreateBody(off);
		Test.Assert(offBall.IsValid);

		Simulate(world, 240);

		world.GetBodyTransform(ball, let onPosition, ?);
		Test.Assert(Near(onPosition.Y, 2.5f, 0.1f));
		Test.Assert(Abs(onPosition.X) < 0.1f);

		world.GetBodyTransform(offBall, let offPosition, ?);
		Test.Assert(offPosition.Y < 0.0f);
	}

	/// A heightfield has no mass to move, so a body asked to be dynamic over one is static
	/// instead: it stays put, and a ball still lands on it. The backend would otherwise
	/// assert in a checked build, and in a release one give the body no inertia at all.
	[Test]
	public static void AHeightfieldAskedToBeDynamicIsStatic()
	{
		let world = scope PhysicsWorld();

		const uint32 n = 17;
		let samples = scope float[n * n];
		for (int i < samples.Count)
			samples[i] = 2.0f;

		let ground = scope BodyDesc();
		ground.Motion = .Dynamic; // the authored default, left as it is
		var field = ShapeDesc();
		field.Kind = .Heightfield;
		field.HeightSamples = samples;
		field.HeightSampleCount = n;
		field.HeightWorldSize = .(16.0f, 16.0f);
		ground.Shapes.Add(field);
		let terrain = world.CreateBody(ground);
		Test.Assert(terrain.IsValid);

		let drop = scope BodyDesc();
		var sphere = ShapeDesc();
		sphere.Kind = .Sphere;
		sphere.Radius = 0.5f;
		drop.Shapes.Add(sphere);
		drop.Position = .(0.0f, 10.0f, 0.0f);
		let ball = world.CreateBody(drop);
		Test.Assert(ball.IsValid);

		Simulate(world, 240);

		world.GetBodyTransform(terrain, let groundPosition, ?);
		Test.Assert(Near(groundPosition.Y, 0.0f, 0.001f), "the ground never fell");
		world.GetBodyTransform(ball, let onPosition, ?);
		Test.Assert(Near(onPosition.Y, 2.5f, 0.1f), "and the ball landed on it");
	}

	/// Two statics never pair, since neither can move into the other, and pairing them would
	/// be work done every step for a contact that can never change.
	[Test]
	public static void TwoStaticsNeverPairAndADynamicStillLands()
	{
		let world = FlatWorld!();

		// A static body buried INSIDE the floor, which overlaps it completely.
		world.CreateBody(BoxAt!(0.0f, MotionKind.Static));
		world.Step(Step);

		let events = scope List<ContactEvent>();
		world.DrainContacts(events);
		Test.Assert(events.IsEmpty);

		world.CreateBody(BoxAt!(1.2f));
		Simulate(world, 60);

		events.Clear();
		world.DrainContacts(events);
		var sawBegin = false;
		for (let event in events)
		{
			if (event.Kind == .Begin)
				sawBegin = true;
		}
		Test.Assert(sawBegin);
	}

	/// A trigger SENSES without responding: the events arrive and the body falls straight
	/// through it.
	[Test]
	public static void ATriggerSensesWithoutColliding()
	{
		let world = FlatWorld!();

		let sensor = scope BodyDesc();
		// Kinematic rather than static, because a static sensor would not pair with the
		// static floor and a trigger volume that can move is the useful shape anyway.
		sensor.Motion = .Kinematic;
		sensor.IsTrigger = true;
		sensor.Position = .(0.0f, 2.0f, 0.0f);
		sensor.UserData = 7;
		var volume = ShapeDesc();
		volume.Kind = .Box;
		volume.HalfExtents = .(1.0f, 1.0f, 1.0f);
		sensor.Shapes.Add(volume);
		Test.Assert(world.CreateBody(sensor).IsValid);

		let drop = BoxAt!(5.0f);
		drop.UserData = 42;
		let body = world.CreateBody(drop);

		var entered = false;
		let events = scope List<ContactEvent>();
		for (int i < 240)
		{
			world.Step(Step);
			events.Clear();
			world.DrainContacts(events);
			for (let event in events)
			{
				if ((event.Kind == .TriggerEnter)
					&& ((event.UserA == 7) || (event.UserB == 7))
					&& ((event.UserA == 42) || (event.UserB == 42)))
					entered = true;
			}
		}
		Test.Assert(entered);

		// No response at all: it went through and landed on the floor.
		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 0.5f, 0.05f));
	}

	/// A compound's EXTENT is what rests on the floor, not a point at its origin.
	[Test]
	public static void ACompoundBuildsAndSimulates()
	{
		let world = FlatWorld!();

		let dumbbell = scope BodyDesc();
		dumbbell.Position = .(0.0f, 4.0f, 0.0f);
		var left = ShapeDesc();
		left.Kind = .Sphere;
		left.Radius = 0.5f;
		left.LocalPosition = .(-1.0f, 0.0f, 0.0f);
		var right = left;
		right.LocalPosition = .(1.0f, 0.0f, 0.0f);
		dumbbell.Shapes.Add(left);
		dumbbell.Shapes.Add(right);

		let body = world.CreateBody(dumbbell);
		Test.Assert(body.IsValid);

		Simulate(world, 240);
		world.GetBodyTransform(body, let position, ?);
		Test.Assert(Near(position.Y, 0.5f, 0.1f));
	}

	/// A kinematic move is VELOCITY CORRECT: the body arrives where it was sent and reports
	/// the speed it travelled at, which is what makes it push what it meets.
	[Test]
	public static void AKinematicBodyFollowsItsMoveWithVelocity()
	{
		let world = scope PhysicsWorld();

		let platform = BoxAt!(0.0f, MotionKind.Kinematic);
		platform.Layer = .Kinematic;
		let body = world.CreateBody(platform);

		var position = Float3(0, 0, 0);
		for (int i < 60)
		{
			position.X += Step;
			world.MoveKinematic(body, position, Quaternion.Identity, Step);
			world.Step(Step);
		}

		world.GetBodyTransform(body, let result, ?);
		Test.Assert(Near(result.X, 1.0f, 0.02f));
		Test.Assert(Near(world.LinearVelocity(body).X, 1.0f, 0.1f));
	}

	/// Continuous collision SWEEPS rather than sampling, so a fast small body stops at thin
	/// geometry a discrete one jumps clean over in a single step.
	[Test]
	public static void ContinuousCollisionStopsWhatDiscreteSteppingTunnelsThrough()
	{
		Test.Assert(FireAtWall(false) > 6.0f, "discrete: it sailed through");
		Test.Assert(FireAtWall(true) < 5.0f, "swept: it stopped at the wall");
	}

	private static float FireAtWall(bool continuous)
	{
		let world = scope PhysicsWorld();

		let wall = scope BodyDesc();
		wall.Motion = .Static;
		wall.Layer = .Static;
		wall.Position = .(5.0f, 0.0f, 0.0f);
		var slab = ShapeDesc();
		slab.Kind = .Box;
		// Thin, but no thinner than the default convex radius, which the backend asserts on.
		slab.HalfExtents = .(0.1f, 5.0f, 5.0f);
		wall.Shapes.Add(slab);
		world.CreateBody(wall);

		let bullet = scope BodyDesc();
		bullet.Motion = .Dynamic;
		bullet.Layer = .Dynamic;
		bullet.ContinuousCollision = continuous;
		bullet.Position = .(0.0f, 0.0f, 0.0f);
		var ball = ShapeDesc();
		ball.Kind = .Sphere;
		ball.Radius = 0.05f;
		bullet.Shapes.Add(ball);

		let id = world.CreateBody(bullet);
		// Three and a third units per step, against twenty centimetres of wall.
		world.SetLinearVelocity(id, .(200.0f, 0.0f, 0.0f));

		Simulate(world, 30);
		world.GetBodyTransform(id, let position, ?);
		return position.X;
	}

	/// A LONE shape carrying only a rotation keeps it: a placement is a rotation as much as
	/// an offset, and a bar authored on its side must not collide upright.
	[Test]
	public static void ALoneShapeKeepsItsLocalRotation()
	{
		let world = scope PhysicsWorld();

		let bar = scope BodyDesc();
		bar.Motion = .Static;
		bar.Layer = .Static;
		bar.Position = .(0, 0, 0);

		var slab = ShapeDesc();
		slab.Kind = .Box;
		// Long in X, thin in Y and Z, then laid over onto its Z axis so it stands tall.
		slab.HalfExtents = .(2.0f, 0.1f, 0.1f);
		slab.LocalRotation = Quaternion.FromAxisAngle(.(0, 0, 1), 3.14159265f * 0.5f);
		bar.Shapes.Add(slab);
		Test.Assert(world.CreateBody(bar).IsValid);

		// Rotated, the bar reaches to about two in Y and only a tenth in X. A ray straight
		// down well above it hits; unrotated it would be a tenth tall and this would miss.
		Test.Assert(world.RayCast(.(0.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f, let hit));
		Test.Assert(Near(hit.Position.Y, 2.0f, 0.05f));

		// And it is NOT wide: a ray down at x = 1 passes through where the unrotated bar
		// would have been.
		Test.Assert(!world.RayCast(.(1.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f, ?));
	}

	/// An explicit mass overrides the scalar the density would have given, and leaving it
	/// unset changes nothing at all.
	[Test]
	public static void AnExplicitMassOverridesTheDensityDerivedOne()
	{
		let world = scope PhysicsWorld();

		let dense = world.CreateBody(BoxAt!(1.0f));
		let derived = world.BodyMass(dense);
		// A cubic metre at a thousand kilograms per cubic metre.
		Test.Assert(Near(derived, 1000.0f, 10.0f));

		let overridden = BoxAt!(3.0f);
		overridden.MassOverride = 5.0f;
		Test.Assert(Near(world.BodyMass(world.CreateBody(overridden)), 5.0f, 0.005f));

		Test.Assert(Near(world.BodyMass(world.CreateBody(BoxAt!(5.0f))), derived, 0.005f));

		// A static has no mass to report.
		Test.Assert(world.BodyMass(world.CreateBody(FloorDesc!())) == 0.0f);
	}
}
