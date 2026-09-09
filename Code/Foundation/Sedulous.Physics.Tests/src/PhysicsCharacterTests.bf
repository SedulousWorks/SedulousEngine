using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Physics;
using static Sedulous.Physics.Tests.PhysicsFixture;

namespace Sedulous.Physics.Tests;

/// The character controller: walking, climbing what it can step over, and shoving what it
/// cannot.
class PhysicsCharacterTests
{
	[Test]
	public static void TheCharacterWalksClimbsStepsAndPushesLightBodies()
	{
		let world = FlatWorld!();

		// A ledge ahead, low enough to step onto, running x from two to ten.
		let ledge = scope BodyDesc();
		ledge.Motion = .Static;
		ledge.Layer = .Static;
		ledge.Position = .(6.0f, 0.15f, 0.0f);
		var slab = ShapeDesc();
		slab.Kind = .Box;
		slab.HalfExtents = .(4.0f, 0.15f, 2.0f);
		ledge.Shapes.Add(slab);
		Test.Assert(world.CreateBody(ledge).IsValid);

		// A light crate ON the ledge, whose face is half a unit up: too tall to stair over,
		// so a walking character has to PUSH it.
		let crate = BoxAt!(0.8f);
		var small = crate.Shapes[0];
		small.HalfExtents = .(0.25f, 0.25f, 0.25f);
		crate.Shapes[0] = small;
		crate.Position = .(5.2f, 0.56f, 0.0f);
		crate.Density = 100.0f;
		let cratebody = world.CreateBody(crate);

		var desc = CharacterDesc();
		// The capsule's CENTRE, so its feet are on the floor.
		desc.Position = .(0.0f, 0.9f, 0.0f);
		// The default hundred newtons barely beats the crate's friction.
		desc.MaxStrength = 800.0f;
		let character = world.CreateCharacter(desc);
		Test.Assert(character.IsValid);

		// Settle onto the floor.
		for (int i < 30)
		{
			world.SetCharacterVelocity(character, .(0.0f, -1.0f, 0.0f));
			world.Step(Step);
			world.UpdateCharacter(character, Step);
		}
		Test.Assert(world.GetCharacterGround(character) == .OnGround);
		Test.Assert(Near(world.CharacterPosition(character).Y, 0.9f, 0.02f));

		// Walk into the ledge and climb onto it.
		for (int i < 72)
		{
			world.SetCharacterVelocity(character, .(3.0f, 0.0f, 0.0f));
			world.Step(Step);
			world.UpdateCharacter(character, Step);
		}
		let onLedge = world.CharacterPosition(character);
		Test.Assert(Near(onLedge.X, 3.6f, 0.15f));
		Test.Assert(Near(onLedge.Y, 1.2f, 0.03f), "standing on the ledge");
		Test.Assert(world.GetCharacterGround(character) == .OnGround);

		// Keep walking into the crate: it is SHOVED rather than climbed.
		for (int i < 90)
		{
			world.SetCharacterVelocity(character, .(3.0f, 0.0f, 0.0f));
			world.Step(Step);
			world.UpdateCharacter(character, Step);
		}
		world.GetBodyTransform(cratebody, let cratePosition, ?);
		Test.Assert(cratePosition.X > 5.5f);
		Test.Assert(Near(world.CharacterPosition(character).Y, 1.2f, 0.05f),
			"still walking the ledge");
	}

	/// Every call on a stale or never valid handle is a no-op, since a handle outliving what
	/// it named is ordinary rather than a caller's mistake.
	[Test]
	public static void AStaleCharacterHandleIsSafeToCallOn()
	{
		let world = scope PhysicsWorld();

		var desc = CharacterDesc();
		desc.Position = .(0.0f, 1.0f, 0.0f);
		let character = world.CreateCharacter(desc);
		Test.Assert(character.IsValid);

		world.DestroyCharacter(character);

		world.SetCharacterVelocity(character, .(1, 0, 0));
		world.SetCharacterStrength(character, 10.0f);
		world.SetCharacterPosition(character, .(5, 5, 5));
		world.UpdateCharacter(character, Step);
		Test.Assert(world.CharacterVelocity(character) == Float3(0, 0, 0));
		Test.Assert(world.CharacterPosition(character) == Float3(0, 0, 0));
		Test.Assert(world.GetCharacterGround(character) == .InAir);

		// A slot freed is a slot REUSED, which is what keeps a churn of characters bounded.
		let next = world.CreateCharacter(desc);
		Test.Assert(next.IsValid);
		Test.Assert(next.Value == character.Value);
	}
}
