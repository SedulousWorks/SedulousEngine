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

	/// A launch sets the vertical speed in the air, where a jump waits for the ground: a
	/// falling character launched mid-air goes back up, then lands as usual.
	[Test]
	public static void ALaunchWorksInTheAirWhereAJumpWaitsForTheGround()
	{
		let play = scope PhysicsPlayScene();
		play.AddFloor();
		let hero = AddHero(play);
		play.Start();
		play.Step(30);
		let character = play.Characters.Get(hero);

		// Up, then past the apex: falling.
		character.JumpSpeed = 5.0f;
		float previous = 0.0f;
		float y = 0.0f;
		for (int i < 60)
		{
			play.Step();
			play.Settle();
			previous = y;
			y = play.Scene.GetWorldPosition(hero).Y;
			if ((i > 5) && (y < previous))
				break;
		}
		Test.Assert(character.Ground == .InAir);
		Test.Assert(y < previous, "falling");

		// A jump in the air is only held for the ground: the fall goes on.
		character.JumpSpeed = 5.0f;
		play.Step(3);
		play.Settle();
		let afterJump = play.Scene.GetWorldPosition(hero).Y;
		Test.Assert(afterJump < y, "a jump does not lift a falling character");
		character.JumpSpeed = 0.0f;

		// A launch does, from where it is.
		character.Launch(6.0f);
		play.Step(6);
		play.Settle();
		Test.Assert(play.Scene.GetWorldPosition(hero).Y > afterJump + 0.2f, "the launch lifts it mid-air");
		Test.Assert(!character.LaunchPending, "consumed by the step");

		// And it comes down to stand again.
		play.Step(180);
		play.Settle();
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

	private static float Dot3(Float3 a, Float3 b) => a.X * b.X + a.Y * b.Y + a.Z * b.Z;

	/// The standard recipe stands still on a slope (a grounded character moves only by its
	/// input); a board drives the whole velocity, integrating gravity along the ground's normal.
	[Test]
	public static void ADrivenCharacterKeepsMomentumDownASlope()
	{
		let play = scope PhysicsPlayScene();
		let tilt = 15.0f * Math.PI_f / 180.0f;
		let slope = play.Scene.CreateEntity("slope");
		var tilted = Transform();
		tilted.Rotation = Quaternion.FromAxisAngle(.(0.0f, 0.0f, 1.0f), tilt); // rises to +x
		play.Scene.SetLocalTransform(slope, tilted);
		let body = play.Bodies.Add(slope);
		body.Motion = .Static;
		body.Layer = .Static;
		body.HalfExtents = .(40.0f, 0.5f, 5.0f);
		let rider = play.Scene.CreateEntity("rider");
		play.Scene.SetLocalPosition(rider, .(15.0f, 15.0f * Math.Tan(tilt) + 1.6f, 0.0f));
		play.Characters.Add(rider);
		play.Start();
		play.Step(60); // falls onto the slope and settles

		let character = play.Characters.Get(rider);
		Test.Assert(character.Ground == .OnGround);
		Test.Assert(Near(character.GroundNormal.X, -Math.Sin(tilt), 0.02f), scope $"{character.GroundNormal}");
		Test.Assert(Near(character.GroundNormal.Y, Math.Cos(tilt), 0.02f));
		let standing = character.CurrPosition.X;
		play.Step(30);
		Test.Assert(Near(character.CurrPosition.X, standing, 0.01f), "the standard recipe holds");
		Test.Assert(Near(character.Velocity.X, 0.0f, 0.05f));

		// Driven: each step, gravity less its part along the normal, added to the velocity it
		// has, which is kept along the ground.
		let gravity = Float3(0.0f, -9.81f, 0.0f);
		let dt = 1.0f / 60.0f;
		for (int i < 60)
		{
			let n = character.GroundNormal;
			var v = character.Velocity;
			if (character.Grounded)
			{
				let along = gravity - n * Dot3(gravity, n);
				v = v - n * Dot3(v, n) + along * dt;
			}
			else
			{
				v = v + gravity * dt;
			}
			character.Drive(v);
			play.Step();
		}
		// One second down a 15 degree slope, frictionless: about g sin 15 = 2.5 m/s, downhill (-x).
		Test.Assert(character.Grounded);
		Test.Assert((character.Velocity.X < -2.0f) && (character.Velocity.X > -3.0f), scope $"{character.Velocity}");
		Test.Assert(character.CurrPosition.X < standing - 1.0f);

		// A move hands control back to the standard recipe, which stops it.
		character.Move(0.0f, 0.0f);
		Test.Assert(!character.Driving);
		play.Step(2);
		let stopped = character.CurrPosition.X;
		play.Step(30);
		Test.Assert(Near(character.CurrPosition.X, stopped, 0.01f));

		// A teleport drops a driven character's momentum as well.
		character.Drive(Float3(-5.0f, 0.0f, 0.0f));
		character.SetPosition(.(15.0f, 15.0f * Math.Tan(tilt) + 1.6f, 0.0f));
		play.Step(1);
		Test.Assert(character.DriveVelocity.X == 0.0f);
		Test.Assert(character.Velocity.X == 0.0f);
	}
}
