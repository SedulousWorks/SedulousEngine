using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Script;

namespace Sedulous.Engine.Script.Tests;

/// The behaviour lifecycle: the deferred start, the active edges, the enable edges,
/// destroy, faults, reload, throttling.
static class BehaviorLifecycleTests
{
	private const String cCounter = """
		class Counter
		{
			int starts = 0;
			int updates = 0;
			int enables = 0;
			int disables = 0;
			int destroys = 0;
			float total = 0;
			void onStart() { starts++; }
			void onUpdate(float dt) { updates++; total += dt; }
			void onEnable() { enables++; }
			void onDisable() { disables++; }
			void onDestroy() { destroys++; }
		}
		""";

	[Test]
	public static void OnStartOnceDeferredToTheFirstSimulatedTick()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let e = play.AddBehavior(counter);

		Test.Assert(play.BehaviorOf(e).Instance == null, "nothing before the scene starts");
		play.Start();
		Test.Assert(play.BehaviorOf(e).Instance == null, "nothing on start either: the first TICK instantiates");
		play.Step();
		Test.Assert(play.BehaviorOf(e).Instance != null);
		Test.Assert(play.PropInt(e, "starts") == 1);
		Test.Assert(play.PropInt(e, "enables") == 1, "enable precedes start");
		Test.Assert(play.PropInt(e, "updates") == 1, "and the first update follows in the same tick");
		play.Step(3);
		Test.Assert(play.PropInt(e, "starts") == 1);
		Test.Assert(play.PropInt(e, "updates") == 4);
		Test.Assert(Math.Abs(play.PropFloat(e, "total") - 4.0f / 60.0f) < 1e-4f, "dt delivered");
	}

	[Test]
	public static void AnInactiveEntityFreezesItsBehaviours()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let e = play.AddBehavior(counter);
		play.Scene.SetActive(e, false);
		play.Start();
		play.Step(2);
		Test.Assert(play.BehaviorOf(e).Instance == null, "starts inactive: never instantiated");

		play.Scene.SetActive(e, true);
		play.Step();
		Test.Assert((play.PropInt(e, "starts") == 1) && (play.PropInt(e, "updates") == 1), "activation starts it");

		play.Scene.SetActive(e, false);
		play.Step(3);
		Test.Assert(play.PropInt(e, "updates") == 1, "deactivation freezes updates");
		Test.Assert((play.PropInt(e, "disables") == 0) && (play.PropInt(e, "destroys") == 0), "with NO lifecycle events");
		play.Scene.SetActive(e, true);
		play.Step();
		Test.Assert((play.PropInt(e, "updates") == 2) && (play.PropInt(e, "starts") == 1), "resumes, no second start");
	}

	[Test]
	public static void EnableEdgesDispatchAndDisabledSkipsTheTick()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let e = play.AddBehavior(counter);
		play.Start();
		play.Step();
		Test.Assert(play.PropInt(e, "enables") == 1);

		play.BehaviorOf(e).Enabled = false;
		play.Step(2);
		Test.Assert(play.PropInt(e, "disables") == 1);
		Test.Assert(play.PropInt(e, "updates") == 1, "a disabled behaviour is not ticked");

		play.BehaviorOf(e).Enabled = true;
		play.Step();
		Test.Assert((play.PropInt(e, "enables") == 2) && (play.PropInt(e, "updates") == 2));
		Test.Assert(play.PropInt(e, "starts") == 1, "re-enabling is not a restart");
	}

	[Test]
	public static void OnDestroyFiresOnEntityDestroyAndOnSceneStop()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let a = play.AddBehavior(counter, "a");
		let b = play.AddBehavior(counter, "b");
		play.Start();
		play.Step();
		Test.Assert(play.Scripts.InstanceCount == 2);

		// The destroy releases the instance, which is gone, so the count is what says so:
		// the released object is not touched again.
		play.Scene.DestroyEntity(b);
		Test.Assert(play.Scripts.InstanceCount == 1, "released with its entity");

		// Stop: the survivor's onDestroy fires and its instance goes.
		let aInstance = play.BehaviorOf(a).Instance;
		Test.Assert(aInstance != null);
		play.Stop();
		Test.Assert(play.BehaviorOf(a).Instance == null);
		Test.Assert(play.Scripts.InstanceCount == 0);
		Test.Assert(!play.BehaviorOf(a).Started);

		// A restart builds afresh, and starts again.
		play.Start();
		play.Step();
		Test.Assert(play.PropInt(a, "starts") == 1, "a fresh instance starts once");
	}

	[Test]
	public static void AFaultingBehaviourIsDisabledAndSiblingsKeepRunning()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let faulty = play.Class("Faulty", """
			class Faulty
			{
				int updates = 0;
				void onUpdate(float dt) { updates++; int[] a; a[3] = 1; }
			}
			""");
		let e = play.Scene.CreateEntity("e");
		play.Attach(e, faulty);
		play.Attach(e, counter);
		play.Start();
		play.Step(3);
		let first = play.BehaviorOf(e, 0);
		Test.Assert(first.Faulted, "the fault disabled it");
		var v = ScriptValue.Nil;
		play.Runtime.GetProperty(first.Instance, "updates", ref v);
		Test.Assert(v.AsInt == 1, "it ran once, faulted, and was not ticked again");
		let second = play.BehaviorOf(e, 1);
		play.Runtime.GetProperty(second.Instance, "updates", ref v);
		Test.Assert(v.AsInt == 3, "the sibling kept running");
	}

	[Test]
	public static void AReloadRebuildsTheInstanceAndReappliesOverrides()
	{
		let play = scope ScriptPlayScene();
		let v1 = play.Class("Mover", "class Mover { float speed = 1; int version = 1; int starts = 0; void onStart() { starts++; } }");
		let e = play.AddBehavior(v1);
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("speed"), .Float(9));
		play.Start();
		play.Step();
		Test.Assert((play.PropFloat(e, "speed") == 9) && (play.PropInt(e, "version") == 1));

		// The product behind the reference swaps: a hot reload.
		let v2 = play.Class("Mover", "class Mover { float speed = 1; int version = 2; int starts = 0; void onStart() { starts++; } }");
		play.BehaviorOf(e).Script.SetDirect(v2);
		play.Step();
		Test.Assert(play.PropInt(e, "version") == 2, "the new class");
		Test.Assert(play.PropFloat(e, "speed") == 9, "the override re-applied");
		Test.Assert(play.PropInt(e, "starts") == 1, "a fresh instance started once");
		Test.Assert(play.Host.Generation == 2, "v1, v2: one generation per change");
	}

	[Test]
	public static void UpdateIntervalThrottlesAndDeliversTheAccumulatedDt()
	{
		let play = scope ScriptPlayScene();
		let counter = play.Class("Counter", cCounter);
		let e = play.AddBehavior(counter);
		play.BehaviorOf(e).UpdateInterval = 0.1f;
		play.Start();
		// 60 ticks of 1/60: onUpdate every 6 ticks, ten times, each with ~0.1 banked.
		play.Step(60);
		let updates = play.PropInt(e, "updates");
		Test.Assert((updates >= 9) && (updates <= 10), scope $"got {updates}");
		Test.Assert(Math.Abs(play.PropFloat(e, "total") - 1.0f) < 0.02f, "the accumulated time adds up to the whole second");
	}
}
