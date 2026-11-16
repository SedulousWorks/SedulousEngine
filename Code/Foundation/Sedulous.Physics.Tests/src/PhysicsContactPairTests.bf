using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// Contacts per body pair: begun once however many sub-shapes touch, kept through the bodies'
/// sleep, and a sensor's ended as a trigger exit.
class PhysicsContactPairTests
{
	private static bool IsPair(ContactEvent event, uint64 a, uint64 b)
		=> ((event.UserA == a) && (event.UserB == b)) || ((event.UserA == b) && (event.UserB == a));

	/// Steps the world `steps` times and counts the events of `kind` between bodies tagged `a` and `b`.
	private static int CountContacts(PhysicsWorld world, int steps, ContactKind kind, uint64 a, uint64 b)
	{
		var count = 0;
		let events = scope List<ContactEvent>();
		for (int i < steps)
		{
			world.Step(Step);
			events.Clear();
			world.DrainContacts(events);
			for (let event in events)
			{
				if ((event.Kind == kind) && IsPair(event, a, b))
					count++;
			}
		}
		return count;
	}

	/// A sensor's contact ended as a plain End: a script listening for its trigger exit never
	/// heard it.
	[Test]
	public static void ABodyFallingThroughASensorLeavesItWithATriggerExit()
	{
		let world = scope PhysicsWorld();
		let floor = FloorDesc!();
		floor.UserData = 1;
		world.CreateBody(floor);
		let sensor = scope BodyDesc();
		sensor.Motion = .Kinematic;
		sensor.IsTrigger = true;
		var volume = ShapeDesc();
		volume.Kind = .Box;
		volume.HalfExtents = .(1.0f, 1.0f, 1.0f);
		sensor.Shapes.Add(volume);
		sensor.Position = .(0.0f, 5.0f, 0.0f); // well above the floor: the box falls clear of it
		sensor.UserData = 7;
		Test.Assert(world.CreateBody(sensor).IsValid);
		let drop = BoxAt!(8.0f);
		drop.UserData = 42;
		Test.Assert(world.CreateBody(drop).IsValid);

		var entered = 0;
		var exited = 0;
		var ended = 0;
		let events = scope List<ContactEvent>();
		for (int i < 240)
		{
			world.Step(Step);
			events.Clear();
			world.DrainContacts(events);
			for (let event in events)
			{
				if (!IsPair(event, 7, 42))
					continue;
				if (event.Kind == .TriggerEnter)
					entered++;
				else if (event.Kind == .TriggerExit)
					exited++;
				else if (event.Kind == .End)
					ended++;
			}
		}
		Test.Assert(entered == 1, scope $"{entered} trigger enters");
		Test.Assert(exited == 1, scope $"{exited} trigger exits");
		Test.Assert(ended == 0, scope $"{ended} plain ends");
	}

	/// The backend removes a pair's contact when its bodies fall asleep; that read as the box
	/// leaving the floor (an End while it lay still on it).
	[Test]
	public static void ABoxThatSettlesAndSleepsOnTheFloorIsStillInContact()
	{
		let world = scope PhysicsWorld();
		let floor = FloorDesc!();
		floor.UserData = 1;
		world.CreateBody(floor);
		let drop = BoxAt!(1.0f);
		drop.UserData = 42;
		let cube = world.CreateBody(drop);
		Test.Assert(cube.IsValid);

		var begun = 0;
		var ended = 0;
		let events = scope List<ContactEvent>();
		for (int i < 600) // ten seconds: long past the box falling asleep
		{
			world.Step(Step);
			events.Clear();
			world.DrainContacts(events);
			for (let event in events)
			{
				if (!IsPair(event, 1, 42))
					continue;
				if (event.Kind == .Begin)
					begun++;
				else if (event.Kind == .End)
					ended++;
			}
		}
		Test.Assert(begun == 1, scope $"{begun} begins");
		Test.Assert(ended == 0, scope $"{ended} ends while it lay there");
		Test.Assert(!world.IsBodyActive(cube), "it did fall asleep: the case under test happened");

		// Lifted off the floor, it does leave: the kept contact ends.
		world.SetBodyTransform(cube, .(0.0f, 10.0f, 0.0f), .Identity);
		Test.Assert(CountContacts(world, 30, .End, 1, 42) == 1);
	}

	/// Contacts arrived per sub-shape: a two-box compound landing flat raised two Begins.
	[Test]
	public static void ACompoundsTwoChildrenLandingTogetherBeginOneContact()
	{
		let world = scope PhysicsWorld();
		let floor = FloorDesc!();
		floor.UserData = 1;
		world.CreateBody(floor);
		let twin = scope BodyDesc();
		twin.Motion = .Dynamic;
		twin.Layer = .Dynamic;
		for (let x in scope float[](-1.0f, 1.0f))
		{
			var child = ShapeDesc();
			child.Kind = .Box;
			child.HalfExtents = .(0.5f, 0.5f, 0.5f);
			child.LocalPosition = .(x, 0.0f, 0.0f);
			twin.Shapes.Add(child);
		}
		twin.Position = .(0.0f, 1.0f, 0.0f);
		twin.UserData = 42;
		Test.Assert(world.CreateBody(twin).IsValid);
		let begun = CountContacts(world, 120, .Begin, 1, 42);
		Test.Assert(begun == 1, scope $"{begun} begins");
	}
}
