using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// A character is in the world through an inner body of its capsule, and a ray or sweep passes
/// out of the body it starts inside, so the character's own probes still work.
class PhysicsCharacterBodyTests
{
	/// A character standing on the floor at `x` (capsule centre 0.9 above it), settled.
	private static CharacterId StandingCharacter(PhysicsWorld world, float x, uint64 userData)
	{
		var desc = CharacterDesc();
		desc.Position = .(x, 0.9f, 0.0f);
		desc.UserData = userData;
		let id = world.CreateCharacter(desc);
		for (int i < 10)
		{
			world.SetCharacterVelocity(id, .(0.0f, -1.0f, 0.0f));
			world.Step(Step);
			world.UpdateCharacter(id, Step);
		}
		return id;
	}

	/// A character had no body of its own: rays, overlaps and other bodies passed through it.
	[Test]
	public static void ARayFindsACharacterAndARayFromInsideItDoesNot()
	{
		let world = scope PhysicsWorld();
		let floor = FloorDesc!();
		floor.UserData = 1;
		world.CreateBody(floor);
		let character = StandingCharacter(world, 0.0f, 77);
		Test.Assert(character.IsValid);

		var hit = RayHit();
		Test.Assert(world.RayCast(.(-5.0f, 0.9f, 0.0f), .(1.0f, 0.0f, 0.0f), 10.0f, out hit));
		Test.Assert(hit.UserData == 77, scope $"hit user {hit.UserData}");
		Test.Assert(Near(hit.Position.X, -0.35f, 0.02f), scope $"the capsule's surface, at {hit.Position.X}");

		// From the character's own centre, down: out of its capsule, onto the floor.
		Test.Assert(world.RayCast(world.CharacterPosition(character), .(0.0f, -1.0f, 0.0f), 5.0f, out hit));
		Test.Assert(hit.UserData == 1, scope $"hit user {hit.UserData}");

		// The same ray told to pass the floor over finds nothing.
		Test.Assert(!world.RayCast(world.CharacterPosition(character), .(0.0f, -1.0f, 0.0f), 5.0f, out hit,
			0xFFFFFFFF, false, 1));

		// An overlap at the character finds it.
		let found = scope List<BodyId>();
		var probe = QueryShape();
		probe.Kind = .Sphere;
		probe.Radius = 0.2f;
		world.ShapeOverlap(probe, world.CharacterPosition(character), .Identity, found);
		var sawCharacter = false;
		for (let id in found)
			sawCharacter = sawCharacter || (world.UserData(id) == 77);
		Test.Assert(sawCharacter);
	}

	[Test]
	public static void RaysAndSweepsPassOutOfTheBodyTheyStartInside()
	{
		let world = scope PhysicsWorld();
		let floor = FloorDesc!();
		floor.UserData = 1;
		world.CreateBody(floor);
		let crate = BoxAt!(2.0f, MotionKind.Static);
		crate.UserData = 9;
		Test.Assert(world.CreateBody(crate).IsValid);

		// From the crate's middle, down: the floor, not the crate at distance nought.
		var hit = RayHit();
		Test.Assert(world.RayCast(.(0.0f, 2.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 5.0f, out hit));
		Test.Assert(hit.UserData == 1, scope $"hit user {hit.UserData}");
		// From above, the crate is solid as ever.
		Test.Assert(world.RayCast(.(0.0f, 5.0f, 0.0f), .(0.0f, -1.0f, 0.0f), 10.0f, out hit));
		Test.Assert(hit.UserData == 9, scope $"hit user {hit.UserData}");
		Test.Assert(Near(hit.Position.Y, 2.5f, 0.025f), scope $"the crate's top, at {hit.Position.Y}");

		// A small sphere swept down from inside the crate leaves it and lands on the floor.
		var ball = QueryShape();
		ball.Kind = .Sphere;
		ball.Radius = 0.1f;
		Test.Assert(world.ShapeCast(ball, .(0.0f, 2.0f, 0.0f), .Identity, .(0.0f, -1.0f, 0.0f), 5.0f, out hit));
		Test.Assert(hit.UserData == 1, scope $"hit user {hit.UserData}");
	}

	/// Without a character-vs-character check, two characters walked through one another.
	[Test]
	public static void TwoCharactersWalkingIntoEachOtherStopAtEachOther()
	{
		let world = scope PhysicsWorld();
		world.CreateBody(FloorDesc!());
		let left = StandingCharacter(world, -2.0f, 1);
		let right = StandingCharacter(world, 2.0f, 2);
		for (int i < 180)
		{
			world.SetCharacterVelocity(left, .(2.0f, -1.0f, 0.0f));
			world.SetCharacterVelocity(right, .(-2.0f, -1.0f, 0.0f));
			world.Step(Step);
			world.UpdateCharacter(left, Step);
			world.UpdateCharacter(right, Step);
		}
		let gap = world.CharacterPosition(right).X - world.CharacterPosition(left).X;
		Test.Assert(gap > 0.6f, scope $"gap {gap}: two radii (0.35 each), less a small contact slack");
	}
}
