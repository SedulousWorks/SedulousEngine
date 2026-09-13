using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Physics;
using Sedulous.Physics;
using Sedulous.Scene;

namespace Sedulous.Engine.Physics.Tests;

/// The walking capsule: moving, jumping, teleporting, and shoving what it meets.
class PhysicsCharacterTests
{
	private static bool Near(float a, float b, float epsilon = 0.001f)
		=> PhysicsPlayScene.Near(a, b, epsilon);

	private static EntityHandle AddHero(PhysicsPlayScene play)
	{
		let hero = play.Scene.CreateEntity("hero");
		play.Scene.SetLocalPosition(hero, .(0.0f, 0.9f, 0.0f));
		play.Characters.Add(hero);
		return hero;
	}

	[Test]
	public static void TheCharacterWalksJumpsAndLands()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let hero = AddHero(play);
		play.Start();

		// Settle onto the floor.
		play.Step(30);
		let character = play.Characters.Get(hero);
		Test.Assert(character.Ground == .OnGround);

		// Walk for a second.
		character.MoveVelocity = .(3.0f, 0.0f, 0.0f);
		play.Step(60);
		play.Settle();
		Test.Assert(Near(play.Scene.GetWorldPosition(hero).X, 3.0f, 0.1f));
		Test.Assert(Near(play.Scene.GetWorldPosition(hero).Y, 0.9f, 0.03f));

		// Jump: it rises, then comes back to standing height.
		character.MoveVelocity = .(0.0f, 0.0f, 0.0f);
		character.JumpSpeed = 5.0f;

		var apex = 0.0f;
		for (int i < 120)
		{
			play.Step();
			play.Settle();
			apex = Math.Max(apex, play.Scene.GetWorldPosition(hero).Y);
		}

		Test.Assert(apex > 1.8f);
		Test.Assert(character.Ground == .OnGround);
		Test.Assert(Near(play.Scene.GetWorldPosition(hero).Y, 0.9f, 0.03f));
	}

	/// A teleport is exact and drops momentum, so what was walking does not drift on after
	/// arriving.
	[Test]
	public static void SettingThePositionTeleportsTheCharacter()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let hero = AddHero(play);
		play.Start();
		play.Step(30);

		let character = play.Characters.Get(hero);
		character.MoveVelocity = .(3.0f, 0.0f, 0.0f);
		play.Step(5);

		character.SetPosition(.(8.0f, 3.0f, -4.0f));
		// The fixed step consumes the request: it snaps, zeroes the velocity and skips the
		// integration so the snap is exact.
		play.Step(1);

		Test.Assert(!character.TeleportPending);
		Test.Assert(Near(character.MoveVelocity.X, 0.0f));
		Test.Assert(Near(character.CurrPosition.X, 8.0f));
		Test.Assert(Near(character.CurrPosition.Z, -4.0f));
		// Both ends of the buffer are the destination, so the interpolation snaps with it.
		Test.Assert(Near(character.PrevPosition.X, 8.0f));

		// From there it falls and settles where it was put, with no horizontal drift.
		play.Step(90);
		play.Settle();

		let landed = play.Scene.GetWorldPosition(hero);
		Test.Assert(Near(landed.X, 8.0f, 0.1f));
		Test.Assert(Near(landed.Z, -4.0f, 0.1f));
		Test.Assert(Near(landed.Y, 0.9f, 0.05f));
	}

	/// The push strength is applied LIVE each step, so a strong character shoves a crate a
	/// weak one would only nudge.
	[Test]
	public static void AStrongCharacterShovesADynamicCrate()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		// Small, so a real shove reads clearly.
		let crate = play.AddBox(0.31f);
		play.Bodies.Get(crate).HalfExtents = .(0.3f, 0.3f, 0.3f);
		play.Scene.SetLocalPosition(crate, .(1.0f, 0.31f, 0.0f));

		let hero = AddHero(play);
		play.Characters.Get(hero).MaxStrength = 8000.0f;

		play.Start();
		play.Step(20);

		let start = play.Scene.GetWorldPosition(crate).X;
		play.Characters.Get(hero).MoveVelocity = .(2.0f, 0.0f, 0.0f);
		play.Step(150);
		play.Settle();

		Test.Assert(play.Scene.GetWorldPosition(crate).X > (start + 0.3f));
	}

	/// A KNOWN GAP, pinned deliberately.
	///
	/// A character walking into a sensor raises NO trigger event: the trigger stream comes
	/// from the world's rigid body contacts, and a character is a swept capsule rather than a
	/// body in that solver, so its overlaps never reach it. This asserts the CURRENT
	/// behaviour; when character to sensor contacts arrive it flips, and this becomes the
	/// test that the event fires.
	[Test]
	public static void ACharacterWalkingIntoATriggerRaisesNothing()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();

		let volume = play.AddBox(0.9f, .Kinematic);
		play.Scene.SetLocalPosition(volume, .(3.0f, 0.9f, 0.0f));
		{
			let sensor = play.Bodies.Get(volume);
			sensor.IsTrigger = true;
			sensor.HalfExtents = .(0.7f, 1.0f, 0.7f);
		}

		let hero = AddHero(play);
		play.Start();
		play.Step(20);

		let recorder = scope RecordingContactListener();
		let listeners = scope List<IContactListener>();
		listeners.Add(recorder);
		play.Physics.SetContactListeners(listeners);

		let character = play.Characters.Get(hero);
		character.MoveVelocity = .(3.0f, 0.0f, 0.0f);

		var entered = false;
		for (int i < 240)
		{
			play.Step(1);
			for (let contact in recorder.Contacts)
			{
				if (contact.Kind != .TriggerEnter)
					continue;

				if (((contact.A == volume) && (contact.B == hero))
					|| ((contact.A == hero) && (contact.B == volume)))
					entered = true;
			}
		}

		// It really did walk through the volume.
		Test.Assert(character.CurrPosition.X > 3.0f);
		// And yet nothing fired, which is the gap.
		Test.Assert(!entered);
	}
}
