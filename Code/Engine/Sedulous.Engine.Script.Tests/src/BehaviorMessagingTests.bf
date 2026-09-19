using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// Messages between behaviours, events on the scene's bus, and coroutines on the tick.
static class BehaviorMessagingTests
{
	private const String cTalker = """
		class Talker
		{
			Entity self;
			Scene@ scene;
			Entity other;
			int hits = 0;
			string lastWho;
			int pings = 0;
			bool sendOnUpdate = false;
			int hitsWhenSent = -1;
			void onUpdate(float dt)
			{
				if (sendOnUpdate)
				{
					sendOnUpdate = false;
					scene.Scripts.Send(other, "hit", 5);
					scene.Scripts.Send(other, "hit", "me");
					scene.Scripts.Send(other, "ping");
					scene.Scripts.Send(other, "nobodyHandlesThis");
					hitsWhenSent = hits;
				}
			}
			void onHit(int damage) { hits += damage; }
			void onHit(const string &in who) { lastWho = who; }
			void onPing() { pings++; }
		}
		""";

	[Test]
	public static void SendReachesEveryDeclaringBehaviourDeferred()
	{
		let play = scope ScriptPlayScene();
		let talker = play.Class("Talker", cTalker);
		let a = play.AddBehavior(talker, "a");
		let b = play.AddBehavior(talker, "b");
		// Two behaviours on b: both declaring onHit hear it.
		play.Attach(b, talker);
		play.Start();
		play.Step();
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "other", .FromEntity(b, play.Scene));
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "sendOnUpdate", .FromBool(true));

		play.Step();
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(play.BehaviorOf(b, 0).Instance, "hits", ref v);
		Test.Assert(v.AsInt == 5, "the int overload");
		play.Runtime.GetProperty(play.BehaviorOf(b, 1).Instance, "hits", ref v);
		Test.Assert(v.AsInt == 5, "every declaring behaviour of the target");
		play.Runtime.GetProperty(play.BehaviorOf(b, 0).Instance, "lastWho", ref v);
		Test.Assert(v.AsString == "me", "the string overload");
		play.Runtime.GetProperty(play.BehaviorOf(b, 0).Instance, "pings", ref v);
		Test.Assert(v.AsInt == 1, "no payload");
		Test.Assert(play.PropInt(a, "hits") == 0, "the sender itself was not a target");
		// A message with no handler anywhere is a safe no-op: nothing above faulted.
		Test.Assert(!play.BehaviorOf(a).Faulted && !play.BehaviorOf(b, 0).Faulted);
	}

	[Test]
	public static void ASendToAnEntityWithNoScriptsIsANoOp()
	{
		let play = scope ScriptPlayScene();
		let talker = play.Class("Talker", cTalker);
		let a = play.AddBehavior(talker, "a");
		let bare = play.Scene.CreateEntity("bare");
		play.Start();
		play.Step();
		play.Scripts.Send(bare, "hit", 1);
		play.Scripts.Send(EntityHandle.Invalid, "hit", 1);
		play.Step();
		Test.Assert(!play.BehaviorOf(a).Faulted);
	}

	private const String cOrb = """
		class Orb
		{
			Scene@ scene;
			int collected = 0;
			int heard = 0;
			bool emit = false;
			void onUpdate(float dt) { if (emit) { emit = false; scene.Scripts.Emit("OrbCollected", 3); } }
			void onOrbCollected(int value) { heard += value; }
		}
		""";

	[Test]
	public static void EmitReachesEveryDeclaringBehaviourAndTheLevel()
	{
		let play = scope ScriptPlayScene();
		let orb = play.Class("Orb", cOrb);
		let level = play.Class("Level", """
			class Level
			{
				int score = 0;
				int starts = 0;
				void onStart() { starts++; }
				void onOrbCollected(int value) { score += value; }
			}
			""");
		play.Scripts.Settings.Script.SetDirect(level);
		let a = play.AddBehavior(orb, "a");
		let b = play.AddBehavior(orb, "b");
		play.Start();
		play.Step();
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(play.Scripts.Level, "starts", ref v);
		Test.Assert(v.AsInt == 1, "the Level started");

		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "emit", .FromBool(true));
		play.Step();
		// The bus drained after the tick that emitted: the sibling, the emitter itself,
		// and the Level all heard it.
		Test.Assert(play.PropInt(a, "heard") == 3);
		Test.Assert(play.PropInt(b, "heard") == 3);
		play.Runtime.GetProperty(play.Scripts.Level, "score", ref v);
		Test.Assert(v.AsInt == 3);

		// A destroyed subscriber is never touched.
		play.Scene.DestroyEntity(b);
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "emit", .FromBool(true));
		play.Step();
		Test.Assert(play.PropInt(a, "heard") == 6);
	}

	[Test]
	public static void CoroutinesRunOnTheTickAndDieWithTheirBehaviour()
	{
		let play = scope ScriptPlayScene();
		let waiter = play.Class("Waiter", """
			class Waiter
			{
				int fired = 0;
				void onStart() { startCoroutine(ScriptCoroutine(this.later)); }
				void later() { wait(0.5); fired++; }
			}
			""");
		Test.Assert(waiter.UsesCoroutines);
		let a = play.AddBehavior(waiter, "a");
		let b = play.AddBehavior(waiter, "b");
		let c = play.AddBehavior(waiter, "c");
		play.Start();
		play.Step();
		Test.Assert(play.Runtime.CoroutineCount == 3);
		play.Step(10);
		Test.Assert(play.PropInt(a, "fired") == 0, "not yet");

		// b is destroyed and c disabled before their waits elapse: neither fires.
		play.Scene.DestroyEntity(b);
		play.BehaviorOf(c).Enabled = false;
		play.Step(25);
		Test.Assert(play.PropInt(a, "fired") == 1, "a's fired after the wait");
		Test.Assert(play.PropInt(c, "fired") == 0, "c's was cancelled on disable");
		Test.Assert(play.Runtime.CoroutineCount == 0);
	}
}
