using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// Contacts through the neutral ingress: a collision's four arguments reach both sides, a
/// trigger's one does, a dead side is skipped, and delivery waits for the drain.
static class BehaviorContactTests
{
	private const String cBumper = """
		class Bumper
		{
			Entity self;
			Scene@ scene;
			string hit;
			string left;
			string sensed;
			string unsensed;
			float speed = -1.0f;
			float normalLength = 0.0f;
			float pointY = 0.0f;
			int contacts = 0;
			void onContactBegin(Entity other, Float3 point, Float3 normal, float speed)
			{
				contacts++;
				hit = scene.GetEntityName(other);
				this.speed = speed;
				normalLength = normal.X * normal.X + normal.Y * normal.Y + normal.Z * normal.Z;
				pointY = point.Y;
			}
			void onContactEnd(Entity other, Float3 point, Float3 normal, float speed) { left = scene.GetEntityName(other); }
			void onTriggerEnter(Entity other) { sensed = scene.GetEntityName(other); }
			void onTriggerExit(Entity other) { unsensed = scene.GetEntityName(other); }
		}
		""";

	[Test]
	public static void ACollisionReachesBothSidesWithAllFourArguments()
	{
		let play = scope ScriptPlayScene();
		let bumper = play.Class("Bumper", cBumper);
		let crate = play.AddBehavior(bumper, "crate");
		let floor = play.AddBehavior(bumper, "floor");
		play.Start();
		play.Step();

		play.Scripts.DeliverContact(crate, floor, .Begin, .(0, 0.5f, 0), .(0, 1, 0), 2.5f);
		Test.Assert(play.PropInt(crate, "contacts") == 0, "queued, not delivered inside the caller");
		play.Step();

		Test.Assert(play.Prop(crate, "hit").AsString == "floor", "the crate sees the floor as the other");
		Test.Assert(play.Prop(floor, "hit").AsString == "crate", "the floor sees the crate");
		Test.Assert(play.PropInt(crate, "contacts") == 1);
		Test.Assert(Math.Abs(play.PropFloat(crate, "speed") - 2.5f) < 0.001f, "the speed crossed");
		Test.Assert(Math.Abs(play.PropFloat(crate, "normalLength") - 1.0f) < 0.001f, "the normal crossed");
		Test.Assert(Math.Abs(play.PropFloat(crate, "pointY") - 0.5f) < 0.001f, "the point crossed");

		play.Scripts.DeliverContact(crate, floor, .End, .(0, 0.5f, 0), .(0, 1, 0), 0.0f);
		play.Step();
		Test.Assert(play.Prop(floor, "left").AsString == "crate");
		Test.Assert(!play.BehaviorOf(crate).Faulted && !play.BehaviorOf(floor).Faulted);
	}

	[Test]
	public static void ATriggerCarriesOnlyTheOtherEntity()
	{
		let play = scope ScriptPlayScene();
		let bumper = play.Class("Bumper", cBumper);
		let volume = play.AddBehavior(bumper, "volume");
		let faller = play.AddBehavior(bumper, "faller");
		play.Start();
		play.Step();

		play.Scripts.DeliverContact(volume, faller, .TriggerEnter, .(0, 0, 0), .(0, 0, 0), 0.0f);
		play.Scripts.DeliverContact(faller, volume, .TriggerExit, .(0, 0, 0), .(0, 0, 0), 0.0f);
		play.Step();

		Test.Assert(play.Prop(volume, "sensed").AsString == "faller");
		Test.Assert(play.Prop(faller, "sensed").AsString == "volume");
		Test.Assert(play.Prop(volume, "unsensed").AsString == "faller");
		Test.Assert(play.PropInt(volume, "contacts") == 0, "a trigger is not a collision");
		Test.Assert(!play.BehaviorOf(volume).Faulted && !play.BehaviorOf(faller).Faulted);
	}

	[Test]
	public static void AnUnassignedSideAndAnEntityWithNoScriptsAreSkipped()
	{
		let play = scope ScriptPlayScene();
		let bumper = play.Class("Bumper", cBumper);
		let crate = play.AddBehavior(bumper, "crate");
		let bare = play.Scene.CreateEntity("bare");
		play.Start();
		play.Step();

		// The other side went away after a destroy: the crate still hears the end.
		play.Scripts.DeliverContact(crate, EntityHandle.Invalid, .End, .(0, 0, 0), .(0, 1, 0), 0.0f);
		// A contact with an entity carrying no behaviours delivers to the crate alone.
		play.Scripts.DeliverContact(bare, crate, .Begin, .(0, 0, 0), .(0, 1, 0), 1.0f);
		play.Step();

		Test.Assert(play.Prop(crate, "left").IsNil || (play.Prop(crate, "left").AsString == ""), "an unassigned other has no name, and nothing faulted");
		Test.Assert(play.Prop(crate, "hit").AsString == "bare");
		Test.Assert(!play.BehaviorOf(crate).Faulted);
	}
}
