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

	/// A class first used after others started builds the run's next module generation, and
	/// the behaviours built from the earlier one keep reading their globals: the earlier
	/// module stays until the run's teardown.
	[Test]
	public static void AnEarlierGenerationKeepsItsGlobalsWhenALaterClassLoads()
	{
		let play = scope ScriptPlayScene();
		let reader = play.Class("Reader", """
			Float3 kOffset = Float3(1, 2, 3);
			class Reader
			{
				float seen = 0;
				void onUpdate(float dt) { seen = kOffset.Y; }
			}
			""");
		let first = play.AddBehavior(reader, "first");
		play.Start();
		play.Step();
		Test.Assert(play.PropFloat(first, "seen") == 2.0f, "the global read on the first generation");
		let generation = play.Host.Generation;

		// A class the run has not loaded yet: its first use builds the next generation.
		let latecomer = play.Class("Latecomer", """
			class Latecomer
			{
				int updates = 0;
				void onUpdate(float dt) { updates++; }
			}
			""");
		let late = play.AddBehavior(latecomer, "late");
		play.Step(2);
		Test.Assert(play.Host.Generation > generation, "the latecomer built a new generation");
		Test.Assert(play.Prop(late, "updates").AsInt >= 1, "and runs");
		Test.Assert(!play.BehaviorOf(first).Faulted, "the earlier behaviour still reads its global");
		Test.Assert(play.PropFloat(first, "seen") == 2.0f);
	}

	/// An entity never assigned has no scene: IsValid answers false for it, where it failed the
	/// handler ("the entity has no scene"), so a behaviour checking a lazily found entity each
	/// frame (Snowline's board, its rider's mesh) was disabled on its first update.
	[Test]
	public static void AnUnassignedEntityIsNotValidAndTheHandlerRunsOn()
	{
		let play = scope ScriptPlayScene();
		let probe = play.Class("Probe", """
			class Probe
			{
				Entity self;
				private Entity m_later;
				bool unassigned = true;
				bool made = true;
				bool real = false;
				int updates = 0;
				void onUpdate(float dt)
				{
					unassigned = m_later.IsValid();
					made = Entity().IsValid();
					real = self.IsValid();
					updates++;
				}
			}
			""");
		let e = play.AddBehavior(probe, "probe");
		play.Start();
		play.Step(2);
		Test.Assert(!play.BehaviorOf(e).Faulted, "the handler ran on");
		Test.Assert(play.PropInt(e, "updates") == 2);
		Test.Assert(!play.Prop(e, "unassigned").AsBool && !play.Prop(e, "made").AsBool, "no scene: not valid");
		Test.Assert(play.Prop(e, "real").AsBool, "a live entity still is");
	}

	/// A world position read inside onUpdate is this frame's: a behaviour that moves a parent
	/// reads the child's new world position at once, where it read last frame's from the cache.
	[Test]
	public static void AWorldPositionReadInOnUpdateIsThisFrames()
	{
		let play = scope ScriptPlayScene();
		let parent = play.Scene.CreateEntity("Parent");
		let child = play.Scene.CreateEntity("Child");
		play.Scene.SetParent(child, parent);
		play.Scene.SetLocalPosition(child, .(5.0f, 0.0f, 0.0f));
		let mover = play.Class("Mover", """
			class Mover
			{
				Scene@ scene;
				float seen = 0;
				void onUpdate(float dt)
				{
					Entity p = scene.FindEntityByName("Parent");
					Entity c = scene.FindEntityByName("Child");
					p.SetLocalPosition(Float3(20, 0, 0));
					seen = c.GetWorldPosition().X;
				}
			}
			""");
		let e = play.AddBehavior(mover, "mover");
		play.Start();
		play.Step();
		Test.Assert(Math.Abs(play.PropFloat(e, "seen") - 25.0f) < 0.01f, scope $"the child's fresh world position, read {play.PropFloat(e, "seen")}");
	}

	/// A child's turn in the world is its parent's after its own, scale aside, and its scale
	/// theirs times its own: a guard's lantern, a child tipped down, aims where the guard's turn
	/// and its own send it.
	[Test]
	public static void WorldRotationComposesTheAncestorsTurnsAndWorldScaleTheirScales()
	{
		let play = scope ScriptPlayScene();
		let parent = play.Scene.CreateEntity("Parent");
		let child = play.Scene.CreateEntity("Child");
		play.Scene.SetParent(child, parent);
		play.Scene.SetLocalTransform(parent, .(.(0, 0, 0), Quaternion.FromAxisAngle(.(0, 1, 0), 1.2f), .(2, 2, 2)));
		play.Scene.SetLocalTransform(child, .(.(0, 0, 0), Quaternion.FromAxisAngle(.(1, 0, 0), -0.4f), .(1.5f, 1.5f, 1.5f)));
		let reader = play.Class("Reader", """
			class Reader
			{
				Scene@ scene;
				bool turned = false;
				bool composed = false;
				bool scaled = false;
				bool deadIsIdentity = false;
				void onUpdate(float dt)
				{
					Entity p = scene.FindEntityByName("Parent");
					Entity c = scene.FindEntityByName("Child");
					Float3 f = Float3(0.0f, 0.0f, -1.0f);
					Float3 world = RotateVector(c.GetWorldRotation(), f);
					Float3 own = RotateVector(p.GetLocalTransform().Rotation, RotateVector(c.GetLocalTransform().Rotation, f));
					Float3 d = world - own;
					turned = world.Z > -0.99f;
					composed = Dot(d, d) < 1e-8f;
					Float3 s = c.GetWorldScale();
					scaled = (s.X > 2.999f) && (s.X < 3.001f) && (s.Y > 2.999f) && (s.Z < 3.001f);
					Float3 none = RotateVector(scene.GetWorldRotation(Entity()), f);
					deadIsIdentity = (none.Z < -0.999f) && (scene.GetWorldScale(Entity()).X == 1.0f);
				}
			}
			""");
		let e = play.AddBehavior(reader, "reader");
		play.Start();
		play.Step();
		Test.Assert(play.Prop(e, "turned").AsBool, "the child is turned in the world");
		Test.Assert(play.Prop(e, "composed").AsBool, "its world turn is its parent's after its own");
		Test.Assert(play.Prop(e, "scaled").AsBool, "its world scale is theirs multiplied");
		Test.Assert(play.Prop(e, "deadIsIdentity").AsBool, "an invalid entity reads identity and one");
	}

	[Test]
	public static void AReloadRebuildsTheInstanceAndReappliesOverrides()
	{
		let play = scope ScriptPlayScene();
		let v1 = play.Class("Mover", "class Mover { [1.0] float speed; int version = 1; int starts = 0; void onStart() { starts++; } }");
		let e = play.AddBehavior(v1);
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("speed"), .Float(9));
		play.Start();
		play.Step();
		Test.Assert((play.PropFloat(e, "speed") == 9) && (play.PropInt(e, "version") == 1));

		// The product behind the reference swaps: a hot reload.
		let v2 = play.Class("Mover", "class Mover { [1.0] float speed; int version = 2; int starts = 0; void onStart() { starts++; } }");
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

	/// The run host outlives the class products it compiled: a hot reload frees a product,
	/// and the next class loaded through the same host must not read it (an editor's game
	/// instance keeps its host across plays, and a cook between two plays frees the classes
	/// of the first). A reload's new source is what compiles.
	[Test]
	public static void ARunHostOutlivesTheClassProductsItCompiled()
	{
		let play = scope ScriptPlayScene();
		let first = play.Class("Walker", "class Walker { Entity self; Scene@ scene; int steps = 1; }", "Walker.as");
		Test.Assert(play.Host.EnsureClassLoaded(first));
		play.Free(first);

		let other = play.Class("Runner", "class Runner { Entity self; Scene@ scene; }", "Runner.as");
		Test.Assert(play.Host.EnsureClassLoaded(other), "a new class loads past a freed product");

		let rebuilt = play.Class("Walker", "class Walker { Entity self; Scene@ scene; int steps = 2; }", "Walker.as");
		let walker = play.Host.Instantiate(rebuilt);
		Test.Assert(walker != null);
		var steps = ScriptValue.Nil;
		Test.Assert(play.Host.Runtime.GetProperty(walker, "steps", ref steps));
		Test.Assert(steps.AsInt == 2, "the rebuilt source compiled");
		play.Host.Runtime.Release(walker);
	}
}
