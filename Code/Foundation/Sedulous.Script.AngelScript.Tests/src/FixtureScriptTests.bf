using System;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Script;
using Sedulous.Script.Fixture;

namespace Sedulous.Script.AngelScript.Tests;

/// Scripts against the fixture surface: every kind of member the walker emits, reached
/// from AngelScript through the generic trampoline.
static class FixtureScriptTests
{
	private static AngelScriptRuntime Bound(ScriptSurface surface)
	{
		let vm = new AngelScriptRuntime();
		vm.Bind(surface);
		return vm;
	}

	private static void Dump(AngelScriptRuntime vm)
	{
		for (let p in vm.Problems)
			Console.WriteLine("  {}", p);
	}

	private static bool Near(double a, double b) => Math.Abs(a - b) < 1e-4;

	[Test]
	public static void TheFixtureBindsWithoutComplaint()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;
		Dump(vm);
		Test.Assert(vm.Problems.IsEmpty, "every member registered");
	}

	[Test]
	public static void GlobalsStaticsAndValueTypes()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;

		let ok = vm.Compile("t", "t.as", """
			float lerped() { return Lerp(0, 10, 0.25); }
			float dotted() { Vec2 a(1, 2); Vec2 b(3, 4); return Vec2::Dot(a, b); }
			float fields() { Vec2 v(5, 6); v.X = 9; return v.X + v.Y + v.Length; }
			float zero() { return Vec2::Zero.X; }
			""");
		Dump(vm);
		Test.Assert(ok, "compiled");

		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("t", "float lerped()", default, ref r));
		Test.Assert(Near(r.AsFloat, 2.5));
		Test.Assert(vm.Call("t", "float dotted()", default, ref r));
		Test.Assert(Near(r.AsFloat, 11));
		Test.Assert(vm.Call("t", "float fields()", default, ref r), "the struct's fields, written through the setter");
		Test.Assert(Near(r.AsFloat, 15));
		Test.Assert(vm.Call("t", "float zero()", default, ref r));
		Test.Assert(Near(r.AsFloat, 0));
	}

	[Test]
	public static void ClassesByHandle()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;

		let ok = vm.Compile("t", "t.as", """
			int drive(Thing@ t)
			{
				t.Count = 3;
				t.Speed = 2.5;
				t.Go();
				t.Go();
				Vec2 at(7, 8);
				t.GoTo(at);
				t.Move(at, 4);
				t.SetMode(Mode::Auto);
				return t.Count + (t.Ready ? 100 : 0) + int(t.GetMode());
			}
			string label(Thing@ t) { return t.Label() + "!"; }
			bool tryget(Thing@ t) { Vec2 v; bool ok = t.TryGet(6, v); return ok && v.X == 6; }
			float made() { Thing@ t = Thing::Make(); t.Count = 5; Vec2 b = t.Bounds(); return t.Count + b.Y; }
			""");
		Dump(vm);
		Test.Assert(ok, "compiled");

		let thing = scope Thing();
		var arg = ScriptValue[1](.FromObject(thing));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("t", "int drive(Thing@)", arg, ref r), "drive");
		Dump(vm);
		Test.Assert(r.AsInt == 3 + 100 + (int64)Mode.Auto, scope $"got {r.AsInt}");
		Test.Assert((thing.Goes == 2) && Near(thing.Speed, 2.5) && Near(thing.LastTarget.X, 7) && Near(thing.LastSpeed, 4) && (thing.LastMode == .Auto));

		Test.Assert(vm.Call("t", "string label(Thing@)", arg, ref r));
		Test.Assert(r.AsString == "thing!");

		Test.Assert(vm.Call("t", "bool tryget(Thing@)", arg, ref r), "a by-ref out parameter written by the engine");
		Test.Assert(r.AsBool);

		Test.Assert(vm.Call("t", "float made()", default, ref r), "a factory and a struct result");
		Test.Assert(Near(r.AsFloat, 9));
	}

	[Test]
	public static void OverloadsResolveByType()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;
		// Twice(int) and Twice(float) are both instance methods on Thing: AngelScript picks.
		let ok = vm.Compile("t", "t.as", """
			float both(Thing@ t) { return t.Twice(2) + t.Twice(1.5); }
			""");
		Dump(vm);
		Test.Assert(ok);
		let thing = scope Thing();
		var arg = ScriptValue[1](.FromObject(thing));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("t", "float both(Thing@)", arg, ref r));
		Test.Assert(Near(r.AsFloat, 7));
	}

	[Test]
	public static void SceneRolesThroughTheContext()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;

		// The fixture has no Scene type of its own, so the systems are reached by the
		// handles a host passes in, and an entity by the value it passes in.
		let ok = vm.Compile("t", "t.as", """
			int ticks(FixtureSystem@ fixture) { return fixture.Ticks; }
			float widget(const Entity &in e, WidgetComponentManager@ widgets) { WidgetComponent w(e); w.Size = w.Size * 2; widgets.Poke(e); return w.Size; }
			""");
		Dump(vm);
		Test.Assert(ok, "compiled");

		let a = scope Scene("a");
		let b = scope Scene("b");
		let widgetsA = a.AddSystem<WidgetComponentManager>();
		let widgetsB = b.AddSystem<WidgetComponentManager>();
		let system = b.AddSystem<FixtureSystem>();
		system.TickCount = 12;
		// The ambient scene is A throughout; everything below happens in B.
		vm.CallContext.Scene = a;

		var r = ScriptValue.Nil;
		var systemArg = ScriptValue[1](.FromObject(system));
		Test.Assert(vm.Call("t", "int ticks(FixtureSystem@)", systemArg, ref r), "a scene system by handle");
		Dump(vm);
		Test.Assert(r.AsInt == 12);

		let entity = b.CreateEntity("w");
		widgetsB.Add(entity).Size = 4;
		var args = ScriptValue[2](.FromEntity(entity, b), .FromObject(widgetsB));
		Test.Assert(vm.Call("t", "float widget(const Entity &in, WidgetComponentManager@)", args, ref r), "a component through its entity, in the entity's scene");
		Dump(vm);
		Test.Assert(Near(r.AsFloat, 8) && Near(widgetsB.Get(entity).Size, 8));

		// The wrong scene's manager refuses the entity: a script exception, reported.
		args[1] = .FromObject(widgetsA);
		Test.Assert(!vm.Call("t", "float widget(const Entity &in, WidgetComponentManager@)", args, ref r));
		Test.Assert(vm.Problems.Back.Contains("another scene"), vm.Problems.Back);
	}

	/// The entity side of an entity-first method: `e.Poke()` reaches the manager in the
	/// entity's scene, and a verb that did not ask is not there.
	[Test]
	public static void AnEntityFirstMethodIsAMethodOnTheEntity()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;

		let ok = vm.Compile("t", "t.as", """
			void poke(const Entity &in e) { e.Poke(); e.Poke(); }
			""");
		Dump(vm);
		Test.Assert(ok, "compiled");
		Test.Assert(!vm.Compile("u", "u.as", "void nudge(const Entity &in e) { e.Nudge(2.0f); }"), "Nudge stays on the manager");
		ClearAndDeleteItems!(vm.Problems);

		let a = scope Scene("a");
		let b = scope Scene("b");
		a.AddSystem<WidgetComponentManager>();
		let widgetsB = b.AddSystem<WidgetComponentManager>();
		vm.CallContext.Scene = a;
		let entity = b.CreateEntity("w");
		var args = ScriptValue[1](.FromEntity(entity, b));
		var r = ScriptValue.Nil;
		Test.Assert(vm.Call("t", "void poke(const Entity &in)", args, ref r), "poked through the entity");
		Dump(vm);
		Test.Assert((widgetsB.Pokes == 2) && (widgetsB.LastPoked == entity), "B's manager, the entity's scene, not the ambient one");
	}

	[Test]
	public static void AScriptErrorIsReportedNotRaised()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = Bound(s);
		defer delete vm;
		Test.Assert(!vm.Compile("t", "t.as", "int f() { return Nope(); }"));
		Test.Assert(!vm.Problems.IsEmpty && vm.Problems.Back.Contains("t.as"));
	}

	/// A surface bound for some domains only: a pipeline type is not there to a script
	/// compiled against the runtime subset.
	[Test]
	public static void ABindingMayBeRestrictedToDomains()
	{
		let s = scope ScriptSurface();
		FixtureSurface.Populate(s);
		let vm = scope AngelScriptRuntime();
		vm.Bind(s, scope StringView[](ScriptDomains.Runtime));
		Test.Assert(!vm.Compile("t", "t.as", "void f() { Cooker@ c; }"), "the pipeline type is absent");
		Test.Assert(vm.Compile("t", "t.as", "void f() { Thing@ t; }"), "the runtime type is present");

		let all = scope AngelScriptRuntime();
		all.Bind(s);
		Test.Assert(all.Compile("t", "t.as", "void f() { Cooker@ c; }"));
	}
}
