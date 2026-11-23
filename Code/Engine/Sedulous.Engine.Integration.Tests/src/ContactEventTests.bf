using System;
using Sedulous.Core;
using Sedulous.Physics;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Physics;
using Sedulous.Engine.Behavior;

namespace Sedulous.Engine.Integration.Tests;

/// A real Jolt collision and trigger reaching behaviours: physics posts them to the scene, with
/// nothing between it and the behavior system.
static class ContactEventTests
{
	[Test]
	public static void AJoltCollisionDispatchesOnContactBeginWithAllFourArguments()
	{
		let world = scope ContactWorld();
		world.AddBody("floor", .(0, -0.5f, 0), .Static, .(50, 0.5f, 50));
		let crate = world.AddBody("crate", .(0, 1.4f, 0), .Dynamic, .(0.5f, 0.5f, 0.5f));
		// Records the OTHER entity's name only when the speed is non negative and the normal
		// is unit-ish, proving all four arguments crossed the boundary intact.
		let bumper = world.Class("Bumper", """
			class Bumper
			{
				Entity self;
				Scene@ scene;
				string hit;
				void onContactBegin(Entity other, Float3 point, Float3 normal, float speed)
				{
					float len = normal.X * normal.X + normal.Y * normal.Y + normal.Z * normal.Z;
					if (speed >= 0.0f && len > 0.5f)
						hit = scene.GetEntityName(other);
				}
			}
			""");
		world.Attach(crate, bumper);
		world.Play(180);
		Test.Assert(world.Prop(crate, "hit").AsString == "floor", scope $"got '{world.Prop(crate, "hit").AsString}'");
		Test.Assert(!world.BehaviorOf(crate).Faulted);
	}

	[Test]
	public static void AJoltTriggerDispatchesOnTriggerEnterWithTheOther()
	{
		let world = scope ContactWorld();
		world.AddBody("floor", .(0, -0.5f, 0), .Static, .(50, 0.5f, 50));
		// A kinematic sensor volume with a behaviour; a crate falls through it.
		let volume = world.AddBody("volume", .(0, 2.0f, 0), .Kinematic, .(1, 1, 1), true);
		world.AddBody("faller", .(0, 4.5f, 0), .Dynamic, .(0.25f, 0.25f, 0.25f));
		let sensor = world.Class("Sensor", """
			class Sensor
			{
				Entity self;
				Scene@ scene;
				string sensed;
				void onTriggerEnter(Entity other) { sensed = scene.GetEntityName(other); }
			}
			""");
		world.Attach(volume, sensor);
		world.Play(180);
		Test.Assert(world.Prop(volume, "sensed").AsString == "faller", scope $"got '{world.Prop(volume, "sensed").AsString}'");
		Test.Assert(!world.BehaviorOf(volume).Faulted);
	}
}
