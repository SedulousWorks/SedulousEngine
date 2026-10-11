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

	private const String cNeighbour = """
		class Neighbour
		{
			Entity self;
			Scene@ scene;
			Entity other;
			int hits = 0;
			string tag;
			bool sendOnUpdate = false;
			void onUpdate(float dt)
			{
				if (sendOnUpdate)
				{
					sendOnUpdate = false;
					// The entity's own verbs: no scene in sight.
					other.Send("hit", 2);
					other.Send("tag", self.GetName());
					self.SetName(self.GetName() + "!");
					if (!other.IsValid() || !other.IsActive()) hits = -100;
				}
			}
			void onHit(int damage) { hits += damage; }
			void onTag(const string &in who) { tag = who; }
		}
		""";

	/// The entity-first rule at the script's level: what a script says to an entity, it
	/// says on the entity.
	[Test]
	public static void AnEntitySendsAndNamesItself()
	{
		let play = scope ScriptPlayScene();
		let neighbour = play.Class("Neighbour", cNeighbour);
		let a = play.AddBehavior(neighbour, "a");
		let b = play.AddBehavior(neighbour, "b");
		play.Start();
		play.Step();
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "other", .FromEntity(b, play.Scene));
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "sendOnUpdate", .FromBool(true));
		play.Step();
		Test.Assert(play.PropInt(b, "hits") == 2, "other.Send with a payload");
		Test.Assert(play.Prop(b, "tag").AsString == "a", "the sender's own name, through self.GetName");
		Test.Assert(play.Scene.GetEntityName(a) == "a!", "self.SetName wrote the scene's name");
		Test.Assert(play.PropInt(a, "hits") == 0, "IsValid and IsActive answered on the entity");
		Test.Assert(!play.BehaviorOf(a).Faulted && !play.BehaviorOf(b).Faulted);
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

	/// An inactive entity receives nothing: no messages, no bus events (contacts share the
	/// message queue). Reactivated, it hears the next one.
	[Test]
	public static void AnInactiveEntityReceivesNoMessagesAndNoEvents()
	{
		let play = scope ScriptPlayScene();
		let talker = play.Class("Talker", cTalker);
		let orb = play.Class("Orb", cOrb);
		let sender = play.AddBehavior(talker, "sender");
		let target = play.AddBehavior(talker, "target");
		let emitter = play.AddBehavior(orb, "emitter");
		let listener = play.AddBehavior(orb, "listener");
		play.Start();
		play.Step();
		play.Runtime.SetProperty(play.BehaviorOf(sender).Instance, "other", .FromEntity(target, play.Scene));

		play.Scene.SetActive(target, false);
		play.Scene.SetActive(listener, false);
		play.Runtime.SetProperty(play.BehaviorOf(sender).Instance, "sendOnUpdate", .FromBool(true));
		play.Runtime.SetProperty(play.BehaviorOf(emitter).Instance, "emit", .FromBool(true));
		play.Step();
		play.Step();
		Test.Assert(play.PropInt(target, "hits") == 0, "no message to an inactive entity");
		Test.Assert(play.PropInt(listener, "heard") == 0, "no bus event to an inactive entity");
		Test.Assert(play.PropInt(emitter, "heard") == 3, "the active emitter still hears its own");

		play.Scene.SetActive(target, true);
		play.Scene.SetActive(listener, true);
		play.Runtime.SetProperty(play.BehaviorOf(sender).Instance, "sendOnUpdate", .FromBool(true));
		play.Runtime.SetProperty(play.BehaviorOf(emitter).Instance, "emit", .FromBool(true));
		play.Step();
		play.Step();
		Test.Assert(play.PropInt(target, "hits") == 5, "reactivated, it hears the next message");
		Test.Assert(play.PropInt(listener, "heard") == 3, "and the next event");
	}

	/// A Float3 emitted on the bus reaches a handler that takes it by value: a lock's place, a
	/// noise's origin. Emit once took no Float3 at all, and Raptor's binder once handed such a
	/// value to a handle parameter only, so `onSpotted(Float3 at)` got nothing and faulted
	/// (Raptor 4a7f2ccd).
	/// A Float4 too: a noise's origin and its loudness in one event, as Lamplight's guards hear
	/// them (Raptor's `emit("Noise", Float4(x, y, z, loudness))`). Emit once took no Float4, so
	/// the noise had to go as two events, and its delivery turned one into Nil.
	[Test]
	public static void AFloat4EventReachesAHandlerTakingItByValue()
	{
		let play = scope ScriptPlayScene();
		let listener = play.Class("Listener", """
			class Listener
			{
				Scene@ scene;
				bool emit = false;
				float heardX = 0;
				float heardW = 0;
				void onUpdate(float dt) { if (emit) { emit = false; scene.Scripts.Emit("Noise", Float4(1.0f, 2.0f, 3.0f, 0.5f)); } }
				void onNoise(Float4 n) { heardX = n.X; heardW = n.W; }
			}
			""");
		let a = play.AddBehavior(listener, "a");
		play.Start();
		play.Step();
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "emit", .FromBool(true));
		play.Step();

		Test.Assert(!play.BehaviorOf(a).Faulted, "the handler ran without faulting");
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(play.BehaviorOf(a).Instance, "heardX", ref v);
		Test.Assert(v.AsNumber == 1.0, "the place arrived");
		play.Runtime.GetProperty(play.BehaviorOf(a).Instance, "heardW", ref v);
		Test.Assert(v.AsNumber == 0.5, "and the loudness with it");
	}

	[Test]
	public static void AnEventsValueReachesAHandlerTakingItByValue()
	{
		let play = scope ScriptPlayScene();
		let spotter = play.Class("Spotter", """
			class Spotter
			{
				Scene@ scene;
				bool emit = false;
				float seenX = 0;
				float seenZ = 0;
				void onUpdate(float dt) { if (emit) { emit = false; scene.Scripts.Emit("Spotted", Float3(1.0f, 2.0f, 3.0f)); } }
				void onSpotted(Float3 at) { seenX = at.X; seenZ = at.Z; }
			}
			""");
		let a = play.AddBehavior(spotter, "a");
		play.Start();
		play.Step();
		play.Runtime.SetProperty(play.BehaviorOf(a).Instance, "emit", .FromBool(true));
		play.Step();

		Test.Assert(!play.BehaviorOf(a).Faulted, "the handler ran without faulting");
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(play.BehaviorOf(a).Instance, "seenX", ref v);
		Test.Assert(v.AsNumber == 1.0, "the value's x arrived");
		play.Runtime.GetProperty(play.BehaviorOf(a).Instance, "seenZ", ref v);
		Test.Assert(v.AsNumber == 3.0, "the value's z arrived");
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
