using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Resource;
using Sedulous.Engine.Behavior;

namespace Sedulous.Engine.Behavior.Tests;

/// A service of the run a native behavior finds, as a script finds a facade: here, a clock.
class NativeTestClock
{
	public double Now = 3.25;
}

/// A behavior written in native code: an entity's, with a property of its own (Worth), a field
/// that is not one (Spin), its lifecycle and message handlers by the names scripts use, and a
/// service it finds through its run.
[NativeBehavior]
class NativeTestOrb : EntityBehavior
{
	[BehaviorProperty]
	public float Worth = 5.0f;
	public float Spin = 1.0f;
	public int32 Starts = 0;
	public float LastDelta = 0.0f;
	public double StartedAt = -1.0;
	public int32 Pinged = 0;
	public String Named = new .() ~ delete _;
	/// What a crash in OnStart would have printed.
	public String CrashNote = new .() ~ delete _;

	public void OnStart()
	{
		Starts++;
		let clock = FindService<NativeTestClock>();
		StartedAt = (clock != null) ? clock.Now : -2.0;
		Named.Set(Scene.GetEntityName(Entity));
		CrashNote.Set(StringView(CrashNoteScope.Current));
	}

	public void OnUpdate(float deltaTime)
	{
		LastDelta = deltaTime;
	}

	public void OnPing(int32 amount)
	{
		Pinged += amount;
	}

	public void OnHurt(int32 amount)
	{
		if (amount > 10)
			Fault("hurt past mending");
	}
}

/// Native behaviors: classes written in native code the run host makes with no script runtime,
/// called through the same BehaviorObject a script's goes through.
class NativeBehaviorTests
{
	const String cOrb = "Sedulous.Engine.Behavior.Tests.NativeTestOrb";

	[Test]
	public static void ANativeEntityBehaviorRunsItsLifecycleMessagesAndPropertiesByTheNamesScriptsUse()
	{
		let play = scope ScriptPlayScene();
		let clock = scope NativeTestClock();
		play.Host.SetService(clock);
		StringView[3] handlers = .("onStart", "onUpdate", "onPing");
		(StringView name, float value)[2] floats = .(("worth", 5.0f), ("spin", 1.0f));
		let orb = play.NativeClass(cOrb, .Entity, handlers, floats);
		let e = play.AddBehavior(orb, "orb");
		play.BehaviorOf(e).SetOverride(ScriptPropertyNames.HashOf("worth"), .Float(8.0));

		play.Start();
		play.Step(1, 0.25f);
		let instance = play.BehaviorOf(e).Instance;
		Test.Assert(instance != null);
		Test.Assert(play.Host.Scripts.Runtime == null); // no script runtime was made for it
		let object = (instance as NativeBehaviorObject).Object as NativeTestOrb;
		Test.Assert(object != null);

		Test.Assert(play.PropInt(e, "starts") == 1, play.Host.TakeLastError(.. scope .()));
		Test.Assert(Math.Abs(play.PropFloat(e, "lastDelta") - 0.25f) < 0.0001f); // the layer's number, fitted
		Test.Assert(Math.Abs(object.StartedAt - 3.25) < 0.0001); // the clock found through its run
		Test.Assert(play.Prop(e, "named").AsString == "orb"); // its entity
		Test.Assert(Math.Abs(play.PropFloat(e, "worth") - 8.0f) < 0.0001f); // the override, over the default
		Test.Assert(Math.Abs(play.PropFloat(e, "spin") - 1.0f) < 0.0001f); // not a property: not written
		Test.Assert(!instance.SetProperty("spin", .FromFloat(2.0)));
		Test.Assert(object.Spin == 1.0f);

		play.Scripts.Send(e, "Ping", 4.0f); // a script's number, into an int32
		play.Step(1, 0.25f);
		Test.Assert(object.Pinged == 4);
		Test.Assert(object.Starts == 1);
		Test.Assert(!play.BehaviorOf(e).Faulted);
		Test.Assert(object.CrashNote == "NativeTestOrb.onStart on 'orb'"); // what a crash would name
		Test.Assert(CrashNoteScope.Current == null); // and nothing once the call returned
		play.Stop();
	}

	[Test]
	public static void ANativeBehaviorThatFaultsItselfIsDisabledWithItsReason()
	{
		let play = scope ScriptPlayScene();
		StringView[3] handlers = .("onStart", "onPing", "onHurt");
		let orb = play.NativeClass(cOrb, .Entity, handlers);
		let e = play.AddBehavior(orb, "orb");
		play.Start();
		play.Step();
		let object = (play.BehaviorOf(e).Instance as NativeBehaviorObject).Object as NativeTestOrb;

		play.Scripts.Send(e, "Hurt", 3);
		play.Step();
		Test.Assert(!play.BehaviorOf(e).Faulted);
		play.Scripts.Send(e, "Hurt", 30);
		play.Step();
		Test.Assert(play.BehaviorOf(e).Faulted);
		Test.Assert(play.Host.TakeLastError(.. scope .()) == "hurt past mending");

		play.Scripts.Send(e, "Ping", 1);
		play.Step();
		Test.Assert(object.Pinged == 0); // disabled: no handler ran
		play.Stop();
	}

	[Test]
	public static void ANativeClassOfAnotherKindOrNotBuiltInIsRefusedAndTheBehaviorDisabled()
	{
		let play = scope ScriptPlayScene();
		StringView[1] handlers = .("onStart");
		let missing = play.NativeClass("Sedulous.Engine.Behavior.Tests.Nowhere", .Entity, handlers);
		let a = play.AddBehavior(missing, "missing");

		// An EntityBehavior is made where an entity's goes, and refused where a scene's goes.
		let asEntity = play.NativeClass(cOrb, .Entity, handlers);
		let made = play.Host.Instantiate(asEntity, .Entity);
		Test.Assert(made != null);
		made.Release();
		let asScene = play.NativeClass(cOrb, .Scene, handlers);
		Test.Assert(play.Host.Instantiate(asScene, .Scene) == null);
		Test.Assert(play.Host.TakeLastError(.. scope .()).Contains("does not derive from SceneBehavior"));

		play.Start();
		play.Step();
		Test.Assert(play.BehaviorOf(a).Faulted);
		Test.Assert(play.Host.TakeLastError(.. scope .()).Contains("is not built in"));
		play.Stop();
	}
}
